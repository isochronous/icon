---
name: initialize-monorepo
description: >
  Use when bootstrapping or upgrading agent-system context across an entire
  monorepo — discovers all sub-project area roots, creates a feature branch,
  runs initialize-repo or upgrade-repo on each area in isolated sessions, then
  generates root-level cross-project context and raises a pull request for
  human review. Run once per monorepo, or when new sub-projects have been added.
user-invocable: false
---

# Initialize Monorepo

Bootstrap agent-system context for every functional area in a monorepo, then
generate root-level cross-project context. Each area runs in an isolated session
so one project's context does not pollute another. All work happens on a feature
branch — nothing lands on the integration branch without a human reviewing and
merging a PR.

---

## initialize-monorepo: Step 0: Branch Guard

Before touching any files, determine the repository's integration branch and
create a dedicated feature branch. All later steps work exclusively on it.

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Detect integration branch
INTEGRATION_BRANCH=""
for candidate in develop main master; do
  if git show-ref --verify --quiet "refs/remotes/origin/$candidate"; then
    INTEGRATION_BRANCH="$candidate"
    break
  fi
done
[ -z "$INTEGRATION_BRANCH" ] && INTEGRATION_BRANCH="$(git remote show origin | grep 'HEAD branch' | awk '{print $NF}')"
[ -z "$INTEGRATION_BRANCH" ] && { echo "ERROR: Cannot detect integration branch"; exit 1; }

FEATURE_BRANCH="chore/initialize-agent-context"

if git show-ref --verify --quiet "refs/heads/$FEATURE_BRANCH"; then
  git checkout "$FEATURE_BRANCH"
  echo "Resumed existing branch: $FEATURE_BRANCH"
else
  git fetch origin
  git checkout -b "$FEATURE_BRANCH" "origin/$INTEGRATION_BRANCH"
  echo "Created branch: $FEATURE_BRANCH (from $INTEGRATION_BRANCH)"
fi
```

Record `INTEGRATION_BRANCH` and `FEATURE_BRANCH` — both are needed in later steps
and in every sub-session prompt.

---

## initialize-monorepo: Step 1: Discover Project Area Roots

A **project area root** is a directory grouping a coherent set of source files
understood together. The right granularity varies by repository type — use the
first matching rule below.

### Rule 1: .NET Solution repos

If the repo contains one or more `.sln` files, the project areas are the
**solution group folders** — NOT individual `.csproj` files. Solution groups are
top-level logical folders (e.g. `<service-a>`, `<service-b>`, `<data-provider>`,
`<integrations>`), each holding multiple related `.csproj` projects.

To identify the solution group directories:

```bash
# Find the .sln file (commonly at repo root or under src/)
SLN=$(find "$REPO_ROOT" -maxdepth 3 -name "*.sln" ! -path "*/.git/*" | head -1)

# Extract all .csproj paths from the solution, derive the group directory
# (the first path segment relative to the solution file's directory)
SLN_DIR="$(dirname "$SLN")"
grep '\.csproj"' "$SLN" \
  | grep -oP '"[^"]+\.csproj"' | tr -d '"' \
  | sed 's|\\|/|g' \
  | xargs -I{} dirname {} \
  | awk -F'/' '{print $1}' \
  | sort -u \
  | while read group; do
      dir="$SLN_DIR/$group"
      [ -d "$dir" ] && echo "$dir"
    done
```

Additionally, any directory with an `angular.json` (Angular app) or a standalone
`package.json` without a `workspaces` array (standalone Node app) is a separate
project area, even inside a .NET repo.

**Do not** list individual `.csproj` directories as project roots — a .NET solution
may contain 50–100 of them. The solution group is the correct unit.

### Rule 2: npm workspace / Nx / Turborepo repos

Read `workspaces` from the root `package.json` (npm/Yarn) or `projects` from
`nx.json` / `turbo.json`. Each workspace entry is a project area root.
Exclude `node_modules`, `dist`, `build`, `.cache`.

### Rule 3: All other repos (Maven multi-module, Go workspace, etc.)

Look for primary manifest files (`pom.xml`, `go.mod`, `Cargo.toml`,
`pyproject.toml`, `Gemfile`) at depth 1–2 from the repo root only — no deeper.
Exclude aggregator roots (a `pom.xml` with only `<modules>` and no `<src>`, a
`Cargo.toml` with only `[workspace]`).

### Result

Produce a flat, deduplicated list. Example for a .NET solution:

| # | Area Path | Notes |
|---|-----------|-------|
| 1 | `src/<service-a>` | <.NET solution group> |
| 2 | `src/<service-b>` | <.NET solution group> |
| 3 | `src/<your-webapp>` | <Angular app> |

---

## initialize-monorepo: Step 2: Classify Each Area

For each area path in `AREA_LIST`, determine whether it needs initialization or
upgrade:

- Apply the **Entry-Point Detection Primitive** (canonical definition:
  `skills/context-specialist-detect-tree-position/SKILL.md` § "Entry-Point
  Detection Primitive (callable)"). Use the **detection form** with `$dir=$area`.
  Read that section for the exact conditional, then run it against each area.
- If the detection-form check passes (entry-point file present AND `.context/`
  directory present): the action is `upgrade-repo`.
- Otherwise: `initialize-repo`.

`.claude/claude.md` is the canonical agent entry point;
`.github/copilot-instructions.md` is the legacy fallback — both accepted by the
primitive.

Build a decision table before proceeding:

| Area Path | Action |
|-----------|--------|
| `src/<service-a>` | `initialize-repo` |
| `src/<service-b>` | `upgrade-repo` |

---

## initialize-monorepo: Step 3: Run Isolated Sessions (Max 3 Parallel)

For each area, dispatch a **background agent** via the task tool. Never exceed
**3 concurrent agents** — `initialize-repo` is context-intensive and quality
degrades under load.

Each background agent runs in its own isolated context window automatically. You
are notified when each completes — use `read_agent` to retrieve the result.

### Dispatch pattern

Dispatch a background `ICON:context-specialist` agent per area with the appropriate
prompt below (substituting the real paths), up to 3 at a time. After each completion
notification, verify the area (Step 4 criteria) and dispatch the next pending area,
if any.

### Prompt — `initialize-repo` areas

```
You are @context-specialist. Initialize agent-system context for one functional
area of a monorepo.

tree_position: leaf
git_root: <REPO_ROOT>
working_directory: <AREA_PATH>
feature_branch: chore/initialize-agent-context

The feature branch already exists — do not create a new branch and do not
switch branches.

Load and execute the `context-specialist-impl-leaf` skill.
Work autonomously — do not pause for user confirmation or input at any point.
Infer all values from the codebase: manifest files, git log, source code,
CI configuration, and any sibling directories that reveal shared patterns.

Complete all steps in full, populating every .context file exhaustively with
real class names, real file paths, and real code examples drawn from the actual
source files in <AREA_PATH>. If any decision is ambiguous, make the most
reasonable inference and continue.

When committing, use the existing commit convention detected from
`git log --oneline -20` at the git root. Commit only files inside <AREA_PATH>.

Run to completion without stopping.
```

Replace `<REPO_ROOT>` and `<AREA_PATH>` with the actual absolute paths.

### Prompt — `upgrade-repo` areas

```
You are @context-specialist. Upgrade agent-system context for one functional
area of a monorepo.

tree_position: leaf
git_root: <REPO_ROOT>
working_directory: <AREA_PATH>
feature_branch: chore/initialize-agent-context
mode: upgrade

The feature branch already exists — do not create a new branch and do not
switch branches.

Load and execute the `upgrade-repo` skill — Phase 1 (audit), Phase 2
(infrastructure upgrade), Phase 3 (content currency, per the
canonical sample-check spec inside `upgrade-repo` Phase 3), and Phase 4
(verify and commit). Do not touch META.md, retrospectives.md, or tasks/.
Infer all values from the codebase and git history.

When committing, use the existing commit convention detected from
`git log --oneline -20` at the git root. Commit only files inside <AREA_PATH>.

Run to completion without stopping.
```

Replace `<REPO_ROOT>` and `<AREA_PATH>` with the actual absolute paths.

---

## initialize-monorepo: Step 4: Verify Each Area

After all sessions finish, check each area:

- For every area in `AREA_LIST`, apply the **Entry-Point Detection Primitive**
  (canonical definition:
  `skills/context-specialist-detect-tree-position/SKILL.md` § "Entry-Point
  Detection Primitive (callable)"). Use the **verification form** with
  `$dir=$area`. Read that section for the exact soft-fail check, then run it
  against each area. The verification form accumulates failures into the
  caller-owned `FAILURES` array.
- Also verify the following per area; on miss, emit a `MISSING …: $area` message
  and mark the area failed:
  - `$area/.context/` directory exists
  - `$area/.context/domains/` directory exists
  - `$area/.context/overview.md` file exists
- If `FAILURES` is non-empty after the loop: re-run those areas with the same
  logic as Step 3.

Do not proceed to Step 5 until every area passes. The root session reads each
area's `.context/overview.md` — gaps cause incomplete cross-project context.

---

## initialize-monorepo: Step 5: Root-Level Context Discovery

After all areas pass, generate cross-project context at the **repository root**.
Dispatch one final background `ICON:context-specialist` agent at the repo root
with the prompt below.

### Root session prompt

```
You are @context-specialist. Generate root-level context for a monorepo.

tree_position: root
git_root: <REPO_ROOT>
working_directory: <REPO_ROOT>
feature_branch: chore/initialize-agent-context
area_paths: <COMMA_SEPARATED_AREA_PATHS>
repo_type: monorepo

The feature branch already exists — do not create a new branch.

Load and execute the `context-specialist-impl-root` skill.
Work autonomously — do not pause for user confirmation or input.

The individual functional areas already have their own .context/ folders —
do not modify them. Your job is cross-project and infrastructure-level context
at the repository root only.

Read each area's .context/overview.md before generating root content.
Commit using the repo's commit convention. Run to completion without stopping.
```

Replace `<COMMA_SEPARATED_AREA_PATHS>` with the actual list.

---

## initialize-monorepo: Step 6: Push Branch and Open Pull Request

After the root session succeeds, push the feature branch and raise a pull request
for review.

```bash
git push --set-upstream origin "$FEATURE_BRANCH"
```

If possible with available tools, then create a pull request targeting `$INTEGRATION_BRANCH`:

- **Title**: `chore: initialize agent-system context`
- **Description**:
  ```
  This PR was generated by the initialize-monorepo skill.

  ## What this adds
  - .claude/claude.md and .context/ for each functional area:
    <list areas>
  - Root-level files in .context/ (projects.md, overview.md, decisions/)
    plus architecture/, domains/, and workflows/

  ## Review checklist
  - [ ] .claude/claude.md at each area accurately reflects the codebase
  - [ ] .context/overview.md at root correctly describes the full system
  - [ ] `projects.md` in .context/ lists all areas with correct paths
  - [ ] No sensitive information (secrets, credentials) was captured
  - [ ] Commit history looks clean (no accidental large files)
  ```

**Do not merge this PR yourself.** Surface the PR URL to the user and ask
them to review before merging.

---

## initialize-monorepo: Step 7: Clean Up

Surface any area agent failures to the user with a summary of which areas
succeeded and which need re-running. Do not silently swallow failures.

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using individual `.csproj` files as project roots in a .NET solution | Use solution group directories (e.g. `src/<service-a>`) — typically 8–12 groups, not 50+ files |
| Running more than 3 sessions in parallel | Hard cap at 3; quality and rate limits both degrade above it |
| Forgetting to pass `REPO_ROOT` and `AREA_PATH` in sub-session prompts | Each session needs both — the area session works in the area but commits relative to the git root |
| Starting root context before all area sessions finish | Do not dispatch the root agent until all areas completed and passed Step 4 |
| Root context duplicating per-area detail | Root covers cross-area relationships only; link to area paths |
| Omitting `projects.md` from root context | It is the primary navigation artifact for `@manager` and `resolve-repo-context` |
| Not verifying areas before Step 5 | Root prompt reads area `overview.md` files — missing ones create gaps |
| Committing directly to the integration branch | Step 0 creates `chore/initialize-agent-context`; sub-session prompts must reinforce it |
| Merging the PR without human review | Always surface the PR URL and stop — do not self-merge |
