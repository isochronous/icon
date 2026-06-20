---
name: initialize-multimodule
description: >
  Use when setting up agent-system context for a multi-module directory for
  the first time — a parent folder containing multiple independent repos or
  project folders with no formal monorepo manifest (no nx.json, no workspace
  package.json with workspaces field, no .sln at root). Distinct from a
  monorepo. Use when sub-projects are independent git repos or standalone
  projects that happen to share a parent directory.
user-invocable: false
---

# Initialize Multi-Module Directory

Bootstrap agent-system context for every sub-project in a multi-module
directory. A **multi-module directory** is not a monorepo — it has no
formal manifest tying sub-projects together (`nx.json`, root `package.json`
with `workspaces`, `.sln`). Each sub-project is independent and may have
its own git history.

Each sub-project runs in its own isolated session. Root-level context generation
(overview.md, projects.md map, create-iconrc via `context-specialist-impl-root`,
optional README) happens after all sub-projects complete.

All work happens on a per-repo feature branch — nothing lands on an integration
branch without a human reviewing and merging a merge request.

---

## initialize-multimodule: Step 0: Branch Guard

Before touching any files, confirm the working tree is safe to operate on. A
multi-module init touches many tracked files across sub-projects — running it
on top of an in-progress task branch (or a dirty tree) can clobber unrelated
work.

```bash
# Both commands must be run from inside a git working tree. If git itself
# errors (not a git repo), surface the error and stop — do not silence stderr.
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
DIRTY_FILES="$(git status --porcelain)"
```

If the directory is not a git repo at all, `git rev-parse` will fail loudly;
let it — a multi-module bootstrap that cannot record commits has nothing to
do.

**Halt conditions** — stop immediately if any apply, unless `--force` was
passed:

- `CURRENT_BRANCH` is not one of `main`, `master`, `dev`, or `develop` (i.e.
  the user is on a task/feature branch that may already have unrelated work
  in progress).
- `DIRTY_FILES` is non-empty (uncommitted or untracked changes that init
  could overwrite).

When halting, surface a clear message and do not proceed:

```
Refusing to run on branch '<CURRENT_BRANCH>' / with uncommitted changes.
This skill modifies tracked files across all sub-projects and would risk
clobbering in-progress work.

Options:
  1. Switch to main/master/dev/develop and clean the working tree, then re-run.
  2. Commit or stash your in-progress work first.
  3. Re-run with --force if you understand the risk and want to proceed anyway.
```

**Flag handling:** Accept a `--force` argument. If `--force` is present, skip
this guard entirely and proceed to Step 1. Otherwise, if either halt condition
triggers, **stop this skill's execution** — do not proceed to structure
confirmation or any subsequent step.

> Note: this guard is independent of the structural pre-check in Step 1; the
> two checks must both pass before any sub-project work begins.

---

## initialize-multimodule: Step 1: Confirm Multi-Module Structure

Verify this directory is genuinely multi-module and not a monorepo. If a
monorepo manifest is found, stop and route to `initialize-monorepo`.

```bash
ROOT_DIR="$(pwd)"

[ -f "$ROOT_DIR/nx.json" ]     && echo "ERROR: nx.json found — use initialize-monorepo" && exit 1
[ -f "$ROOT_DIR/turbo.json" ]  && echo "ERROR: turbo.json found — use initialize-monorepo" && exit 1
find "$ROOT_DIR" -maxdepth 1 -name "*.sln" | grep -q . \
  && echo "ERROR: .sln found — use initialize-monorepo" && exit 1

if [ -f "$ROOT_DIR/package.json" ]; then
  grep -q '"workspaces"' "$ROOT_DIR/package.json" \
    && echo "ERROR: workspace package.json found — use initialize-monorepo" && exit 1
fi
```

If none of the above triggers, proceed.

---

## initialize-multimodule: Step 2: Discover Sub-Projects

Scan the multi-module root recursively (up to **5 levels deep**) for
directories that contain a project manifest or agent-system entry point
(`.claude/claude.md` canonical; `.github/copilot-instructions.md` legacy).
Skip `node_modules`, dot-directories (e.g. `.git`), `vendor`, `dist`,
and `build` directories.

**Manifest indicators (any one is sufficient):** `package.json`, `pom.xml`,
`*.csproj`, `go.mod`, `Cargo.toml`, `requirements.txt`, `pyproject.toml`,
`Gemfile`, `build.gradle`, `.claude/claude.md` (canonical),
`.github/copilot-instructions.md` (legacy)

```bash
SUB_PROJECTS=()
while IFS= read -r dir; do
  # Check well-known manifest filenames
  for manifest in package.json pom.xml go.mod Cargo.toml requirements.txt \
                  pyproject.toml Gemfile build.gradle; do
    if [ -f "$dir/$manifest" ]; then SUB_PROJECTS+=("$dir"); continue 2; fi
  done

  # Check for .csproj files
  find "$dir" -maxdepth 1 -name "*.csproj" | grep -q . \
    && { SUB_PROJECTS+=("$dir"); continue; }

  # Check for agent-system entry point (canonical then legacy)
  [ -f "$dir/.claude/claude.md" ] && { SUB_PROJECTS+=("$dir"); continue; }
  [ -f "$dir/.github/copilot-instructions.md" ] && SUB_PROJECTS+=("$dir")
done < <(find "$ROOT_DIR" -mindepth 1 -maxdepth 5 \
  \( -name "node_modules" -o -name ".*" -o -name "vendor" \
     -o -name "dist" -o -name "build" \) -prune \
  -o -type d -print)
```

Produce a flat, deduplicated list before proceeding to Step 3.

---

## initialize-multimodule: Step 3: Classify Each Sub-Project

For each sub-project in `SUB_PROJECTS`, determine whether it needs
initialization or upgrade:

- Apply the **Entry-Point Detection Primitive** (canonical definition:
  `skills/context-specialist-detect-tree-position/SKILL.md` § "Entry-Point
  Detection Primitive (callable)"). Use the **detection form** with
  `$dir=$proj`. Read that section to obtain the exact conditional, then run
  it against each sub-project.
- If the primitive's detection-form check passes for the sub-project
  (entry-point file present AND `.context/` directory present): the action
  is `upgrade-repo`.
- Otherwise: the action is `initialize-repo`.

`.claude/claude.md` is the canonical agent entry point;
`.github/copilot-instructions.md` is the legacy fallback — both are accepted
by the primitive.

Build a decision table before dispatching:

| Sub-Project Path | Action |
|-----------------|--------|
| `<service-a>/` | `initialize-repo` |
| `<service-b>/` | `upgrade-repo` |

---

## initialize-multimodule: Step 4: Branch creation per sub-repo

Sub-projects in a multi-module directory may belong to separate git repositories
(or to none at all). Branch management is **per unique git root** — one branch
per repo, not one branch for the multi-module container.

For each sub-project, resolve its git root:

```bash
GIT_ROOT=$(git -C "$proj" rev-parse --show-toplevel)
```

Collect the unique set of `GIT_ROOT` values across `SUB_PROJECTS`. For each
unique git root:

1. Detect the integration branch:

   ```bash
   INTEGRATION_BRANCH=""
   for candidate in develop main master; do
     if git -C "$GIT_ROOT" show-ref --verify --quiet "refs/remotes/origin/$candidate"; then
       INTEGRATION_BRANCH="$candidate"; break
     fi
   done
   [ -z "$INTEGRATION_BRANCH" ] && \
     INTEGRATION_BRANCH=$(git -C "$GIT_ROOT" remote show origin | grep 'HEAD branch' | awk '{print $NF}')
   [ -z "$INTEGRATION_BRANCH" ] && { echo "ERROR: Cannot detect integration branch for $GIT_ROOT"; exit 1; }
   ```

2. Create (or check out) `chore/initialize-agent-context` from the integration branch:

   ```bash
   FEATURE_BRANCH="chore/initialize-agent-context"
   if git -C "$GIT_ROOT" show-ref --verify --quiet "refs/heads/$FEATURE_BRANCH"; then
     git -C "$GIT_ROOT" checkout "$FEATURE_BRANCH"
   else
     git -C "$GIT_ROOT" fetch origin
     git -C "$GIT_ROOT" checkout -b "$FEATURE_BRANCH" "origin/$INTEGRATION_BRANCH"
   fi
   ```

Record a per-repo map: `GIT_ROOT → INTEGRATION_BRANCH`. This map is needed when
composing sub-session prompts (Step 5) and when pushing branches (Step 9).

If a sub-project is not inside any git repo, note it but do not fail — context
files can still be created; they just cannot be committed. Such sub-projects
are excluded from the push + MR step.

**Flag handling:** `--force` (consistent with Step 0) skips the branch guard but
does not skip this step — branch creation is required for any sub-project that
does live in a git repo.

---

## initialize-multimodule: Step 5: Run Isolated Sessions (Max 3 Parallel)

Dispatch a background `ICON:context-specialist` agent per sub-project using the task tool. Never
exceed **3 concurrent agents** — `initialize-repo` is context-intensive and
quality degrades under load.

After each completion notification, verify (Step 6) and dispatch the next
pending sub-project if any remain.

Each sub-session must receive:

- `PROJECT_PATH` — absolute path of the sub-project
- `GIT_ROOT` — the git repository root for that sub-project (may differ from `PROJECT_PATH`)
- The branch name: `chore/initialize-agent-context`
- The integration branch for that git repo

> **Note on path separation**: In a multi-module directory, a sub-project may be
> a sub-directory of its git repo, or the repo root itself. Always pass both
> paths — sub-sessions run `git log` from `GIT_ROOT` for history and commit
> from `GIT_ROOT` but scope file changes to `PROJECT_PATH`.

### Prompt — `initialize-repo` sub-projects

```
You are @context-specialist. Initialize agent-system context for one sub-project
in a multi-module directory.

tree_position: leaf
git_root: <GIT_ROOT>
working_directory: <PROJECT_PATH>
feature_branch: chore/initialize-agent-context

The feature branch already exists — do not create a new branch and do not
switch branches.

Load and execute the `context-specialist-impl-leaf` skill.
Work autonomously — do not pause for user confirmation or input at any point.
Infer all values from the codebase: manifest files, git log, source code,
CI configuration.

Complete all steps in full, populating every .context file exhaustively with
real class names, real file paths, and real code examples drawn from the actual
source files in <PROJECT_PATH>.

When detecting commit conventions and branch patterns, run git log from
<GIT_ROOT>, not from <PROJECT_PATH>, so you see the full repo history.

When committing, commit only the files you create/modify inside <PROJECT_PATH>.
Use <GIT_ROOT> as the working directory for git operations.

Run to completion without stopping.
```

### Prompt — `upgrade-repo` sub-projects

```
You are @context-specialist. Upgrade agent-system context for one sub-project
in a multi-module directory.

tree_position: leaf
git_root: <GIT_ROOT>
working_directory: <PROJECT_PATH>
feature_branch: chore/initialize-agent-context
mode: upgrade

The feature branch already exists — do not create a new branch and do not
switch branches.

Load and execute the `upgrade-repo` skill — Phase 1 (audit), Phase 2
(infrastructure upgrade), Phase 3 (content currency, per the
canonical sample-check spec inside `upgrade-repo` Phase 3), and Phase 4
(verify and commit). Do not touch META.md, retrospectives.md, or tasks/.

When detecting commit conventions, run git log from <GIT_ROOT>, not from
<PROJECT_PATH>.

When committing, commit only the files you modify inside <PROJECT_PATH>. Use
<GIT_ROOT> as the working directory for git operations.

Run to completion without stopping.
```

Replace `<GIT_ROOT>` and `<PROJECT_PATH>` with the actual absolute paths.

---

## initialize-multimodule: Step 6: Verify Each Sub-Project

After all sessions complete, verify each sub-project before proceeding:

- For every sub-project in `SUB_PROJECTS`, apply the **Entry-Point Detection Primitive**
  (canonical definition: `skills/context-specialist-detect-tree-position/SKILL.md`
  § "Entry-Point Detection Primitive (callable)"). Use the **verification form**
  with `$dir=$proj`. Read that section to obtain the exact soft-fail check, then
  run it against each sub-project. The verification form accumulates failures
  into the caller-owned `FAILURES` array.
- In addition to the entry-point check, verify the following per sub-project;
  on miss, emit a `MISSING …: $proj` message and mark the sub-project as
  failed:
  - `$proj/.context/` directory exists
  - `$proj/.context/domains/` directory exists
  - `$proj/.context/overview.md` file exists
- If `FAILURES` is non-empty after the loop: re-run those sub-projects.

Do not proceed to Step 7 until all sub-projects pass.

---

## initialize-multimodule: Step 7: Root-Level Context Discovery

After all sub-projects pass verification, generate cross-project context at the
**multi-module root**. Dispatch one background `ICON:context-specialist` agent
at the root with the prompt below.

### Root session prompt

```
You are @context-specialist. Generate root-level context for a multi-module directory.

tree_position: root
git_root: <REPO_ROOT>
working_directory: <REPO_ROOT>
feature_branch: chore/initialize-agent-context
area_paths: <COMMA_SEPARATED_SUB_PROJECT_PATHS>
repo_type: multi-module

The feature branch already exists — do not create a new branch.

Load and execute the `context-specialist-impl-root` skill.
Work autonomously — do not pause for user confirmation or input.

The individual sub-projects already have their own .context/ folders —
do not modify them. Your job is cross-project and infrastructure-level context
at the multi-module root only.

Read each sub-project's .context/overview.md before generating root content.
Commit using the repo's commit convention. Run to completion without stopping.
```

Replace `<REPO_ROOT>` with the actual root path and `<COMMA_SEPARATED_SUB_PROJECT_PATHS>` with the flat list of leaf sub-project paths discovered in Step 2.

---

## initialize-multimodule: Step 8: Root README (conditional)

Check whether a root-level README already exists:

```bash
find "$ROOT_DIR" -maxdepth 1 -name "README*" | grep -q . \
  && echo "README exists — skip" \
  || echo "No README found"
```

If no README exists, **ask the user before creating one**:

> No root README was found. Would you like me to create a brief
> `README.md` listing the sub-projects and their descriptions?
> (yes / no)

If confirmed, create a minimal `README.md`. Populate the description
column from each sub-project's `.context/overview.md` (first sentence):

```markdown
# <directory-name>

Multi-module directory containing the following independent projects:

| Project | Path | Description |
|---------|------|-------------|
| <service-a> | <service-a>/ | <derived from overview.md> |

Each project has its own `.claude/claude.md` (or `.github/copilot-instructions.md` for pre-migration repos) and `.context/` folder.
```

---

## initialize-multimodule: Step 9: Push and open merge requests

Push and MR creation is **per git repo** — one MR per unique git root. Iterate
over the unique `GIT_ROOT` values recorded in Step 4:

```bash
for GIT_ROOT in "${UNIQUE_GIT_ROOTS[@]}"; do
  git -C "$GIT_ROOT" push --set-upstream origin chore/initialize-agent-context
done
```

For each git repo, open a merge request targeting that repo's integration branch
(the value recorded in the Step 4 `GIT_ROOT → INTEGRATION_BRANCH` map). Use
whichever MR creation method is available — `glab`, `gh`, or the GitLab/GitHub
web UI — surface the URL once the MR exists.

Follow the MR description format from the `mr-discipline` skill (Summary, Why,
How to Test, Risks). For example:

```markdown
## Summary
- Added .claude/claude.md and .context/ for sub-projects in this repo:
  <list sub-projects from this git root>

## Why
Bootstraps the agent-system context so @manager can route tasks to the correct
sub-project via resolve-repo-context, and specialist agents have domain knowledge
available from the first task.

## How to Test
Review each sub-project's .claude/claude.md and .context/overview.md for
accuracy. Check that no credentials or sensitive information were captured.

## Risks
AI-inferred context may contain inaccuracies. Each file should be reviewed by a
developer who knows the codebase before merging.
```

Sub-projects that are not inside any git repo are excluded from this step —
their context files exist on disk but cannot be pushed.

**Do not merge these MRs yourself.** Surface all MR URLs to the user and stop.

---

## initialize-multimodule: Step 10: Surface Results

Report outcome to the user:

- Sub-projects that succeeded and which action was taken (`initialize-repo` / `upgrade-repo`)
- Any sub-projects that failed and the specific error
- Confirmation that root-level context was generated by the `context-specialist-impl-root` dispatch
- Whether a root README was created or skipped
- MR URLs (one per unique git repo) from Step 9
- Sub-projects skipped from push + MR because they are not inside any git repo

Do not silently swallow failures.

---

## Distinguishing Multi-Module from Monorepo

| Signal | Route to |
|--------|----------|
| Root `nx.json` or `turbo.json` | `initialize-monorepo` |
| Root `package.json` with `"workspaces"` field | `initialize-monorepo` |
| `.sln` file at root | `initialize-monorepo` |
| Root `pom.xml` with `<modules>` only (no `<src>`) | `initialize-monorepo` |
| No root manifest; each sub-dir is independent | **this skill** |
| Sub-dirs are separate git repos | **this skill** |

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Running on a monorepo | Step 1 structure check catches this — route to `initialize-monorepo` |
| Running on top of in-progress work | Step 0 branch guard halts on a task branch or dirty tree; use `--force` only if you are sure |
| Recursing too shallow and missing nested projects | Default scans up to 5 levels deep; adjust `-maxdepth` if your structure goes deeper |
| Exceeding 3 parallel agents | Hard cap at 3 — dispatch the next only after one completes |
| Creating root README without user confirmation | Always ask first (Step 8) |
| Skipping Step 6 before Step 7 | The root context dispatch reads sub-project `.context/overview.md` — missing ones create gaps |
| Starting root context before all sub-project sessions finish | Do not dispatch the root agent until all sub-project agents have completed and passed Step 6 verification |
| Creating one branch across all sub-repos | Branch management is per git root (Step 4) — a multi-module directory may span multiple repos |
| Committing to sub-project integration branches without an MR | Step 9 push + MR is mandatory; the manager-only MR-merge instruction applies |
