---
name: initialize-workspace
description: >
  Use when bootstrapping or upgrading agent-system context across all projects in
  a VS Code multi-root workspace (.code-workspace file) — parses the workspace
  folder list, runs initialize-repo or upgrade-repo on each project folder in
  isolated sessions (skipping resource-only folders), then generates workspace-level
  cross-project context at the first folder. Run once per workspace, or when new
  projects have been added.
user-invocable: false
---

# Initialize Workspace

Bootstrap the full agent-system context for every project folder in a VS Code
multi-root workspace, then generate workspace-level cross-project context at the
workspace root (first folder). Discovery comes from parsing the `.code-workspace`
JSON file directly — no filesystem scanning required.

Each project folder runs in its own isolated session to prevent context from one
project polluting another. Folders that contain only documentation or data (no
build manifests, no source code) are classified as resources and skipped.

All work happens on a per-repo feature branch — nothing lands on an integration
branch without a human reviewing and merging a merge request.

---

## initialize-workspace: Step 0: Locate workspace file and parse folders

The agent is invoked from the workspace container directory — the folder that
holds the `.code-workspace` file.

```bash
WORKSPACE_FILE=$(find "$PWD" -maxdepth 1 -name "*.code-workspace" | head -1)
[ -z "$WORKSPACE_FILE" ] && { echo "ERROR: No .code-workspace file found in $PWD"; exit 1; }
WORKSPACE_DIR="$(dirname "$WORKSPACE_FILE")"
```

Parse the `folders` array. Each entry has a `path` key that may be relative
(relative to the workspace file's directory) or absolute:

```bash
python3 -c "
import json, os, sys
ws = json.load(open('$WORKSPACE_FILE'))
ws_dir = '$WORKSPACE_DIR'
for i, f in enumerate(ws.get('folders', [])):
    raw = f['path']
    resolved = os.path.realpath(os.path.join(ws_dir, raw))
    print(f'{i+1}\t{resolved}\t{raw}')
"
```

The **first folder** is the workspace root — it receives workspace-level context
in Step 6 regardless of its own project classification.

Produce a resolution table before proceeding:

| # | Folder Path | Raw Entry |
|---|-------------|-----------|
| 1 | `/dev/<workspace>` | `.` (workspace root) |
| 2 | `/dev/<service-a>` | `../<service-a>` |
| 3 | `/dev/<service-b>` | `../<service-b>` |
| 4 | `/dev/<resource-folder>` | `../<resource-folder>` |

---

## initialize-workspace: Step 1: Branch guard (per git repo)

Folders can belong to separate git repositories. Branch management is
**per unique git root** — one branch per repo, not one branch for the workspace.

For each folder, resolve its git root:

```bash
GIT_ROOT=$(git -C "$FOLDER_PATH" rev-parse --show-toplevel)
```

Collect the unique set of `GIT_ROOT` values. For each unique git root:

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

Record a per-repo map: `GIT_ROOT → INTEGRATION_BRANCH`. This is needed when
composing sub-session prompts (Step 4) and when pushing branches (Step 7).

If a folder is not inside any git repo, note it but do not fail — context files
can still be created; they just cannot be committed.

---

## initialize-workspace: Step 2: Classify folders

For each folder, classify it as **project** or **resource**:

- **Project**: Has at least one of `package.json`, `pom.xml`, `*.csproj`,
  `go.mod`, `Cargo.toml`, `requirements.txt`, `pyproject.toml`, `Gemfile`,
  `build.gradle`, `angular.json`, or a `src/` directory containing source
  files. Projects build independently and have domain logic.

- **Resource**: Only documentation or data — `.md`, `.txt`, `.html`, `.json`,
  `.csv`, `.xml`, images, PDFs. No build manifests, no `src/` with code.
  Examples: seed-data folders, locale files, schema references, online help.

The **workspace root** (first folder) is always treated as a project regardless
of classification — it receives workspace-level context in Step 6.

Build a decision table before proceeding:

| # | Folder | Classification | Action |
|---|--------|---------------|--------|
| 1 | `/dev/<workspace>` | workspace root | project-level context (Step 4) + workspace-level context (Step 6) |
| 2 | `/dev/<service-a>` | project | initialize-repo or upgrade-repo |
| 3 | `/dev/<service-b>` | project | initialize-repo or upgrade-repo |
| 4 | `/dev/<resource-folder>` | resource | skip |

---

## initialize-workspace: Step 3: Classify project action (initialize vs upgrade)

For each project folder in `PROJECT_FOLDERS` (workspace root included):

- Apply the **Entry-Point Detection Primitive** (canonical definition:
  `skills/context-specialist-detect-tree-position/SKILL.md` § "Entry-Point
  Detection Primitive (callable)"). Use the **detection form** with
  `$dir=$folder`. Read that section to obtain the exact conditional, then run
  it against each folder.
- If the primitive's detection-form check passes for the folder (entry-point
  file present AND `.context/` directory present): the action is
  `upgrade-repo`.
- Otherwise: the action is `initialize-repo`.

`.claude/claude.md` is the canonical agent entry point;
`.github/copilot-instructions.md` is the legacy fallback — both are accepted
by the primitive.

The workspace root follows the same check. Even if it needs `upgrade-repo`,
it still gets workspace-level context in Step 6.

---

## initialize-workspace: Step 4: Run isolated sessions (max 3 parallel)

Dispatch a **background agent** (via task tool) for each project folder. Hard
cap: **3 concurrent agents**. After each completion notification, verify the
folder (Step 5 criteria) and dispatch the next pending folder if any remain.

- `initialize-repo` projects → use `agent_type: "ICON:context-specialist"` (prompt in Step 4a)
- `upgrade-repo` projects → use `agent_type: "ICON:context-specialist"` (prompt in Step 4b)

Each sub-session must receive:

- `PROJECT_PATH` — absolute path of the project folder
- `GIT_ROOT` — the git repository root for that folder (may differ from `PROJECT_PATH`)
- The branch name: `chore/initialize-agent-context`
- The integration branch for that git repo

> **Note on path separation**: In a workspace, a project folder may be a
> sub-directory of its git repo, or the repo root itself. Always pass both
> paths — sub-sessions run `git log` from `GIT_ROOT` for history and commit
> from `GIT_ROOT` but scope file changes to `PROJECT_PATH`.

### initialize-workspace: Step 4a: Prompt for initialize-repo projects

```
You are @context-specialist. Initialize agent-system context for one project
in a VS Code workspace.

tree_position: leaf
git_root: <GIT_ROOT>
working_directory: <PROJECT_PATH>
feature_branch: chore/initialize-agent-context

The feature branch already exists — do not create a new branch and do not
switch branches.

Load and execute the `context-specialist-impl-leaf` skill. Work autonomously —
do not pause for user confirmation or input at any point. Infer all values
from the codebase.

Complete all steps in full, populating every .context file exhaustively with
real class names, real file paths, and real code examples drawn from the
actual source files. If any decision is ambiguous, make the most reasonable
inference and continue.

When detecting commit conventions and branch patterns, run git log from
<GIT_ROOT>, not from <PROJECT_PATH>, so you see the full repo history.

When committing, commit only the files you create inside <PROJECT_PATH>. Use
<GIT_ROOT> as the working directory for git operations.

Run to completion without stopping.
```

### initialize-workspace: Step 4b: Prompt for upgrade-repo projects

```
You are @context-specialist. Upgrade agent-system context for one project
in a VS Code workspace.

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
Infer all values from the codebase and git history.

When detecting commit conventions, run git log from <GIT_ROOT>.
When committing, commit only the files you modify inside <PROJECT_PATH>. Use
<GIT_ROOT> as the working directory for git operations.

Run to completion without stopping.
```

---

## initialize-workspace: Step 5: Verify each project

After all sessions finish, check every project folder (including workspace root):

- For every project in `PROJECT_LIST`, apply the **Entry-Point Detection Primitive**
  (canonical definition: `skills/context-specialist-detect-tree-position/SKILL.md`
  § "Entry-Point Detection Primitive (callable)"). Use the **verification form**
  with `$dir=$project`. Read that section to obtain the exact soft-fail check,
  then run it against each project. The verification form accumulates failures
  into the caller-owned `FAILURES` array.
- In addition to the entry-point check, verify the following per project; on
  miss, emit a `MISSING …: $project` message and mark the project as failed:
  - `$project/.context/` directory exists
  - `$project/.context/domains/` directory exists
  - `$project/.context/overview.md` file exists
- If `FAILURES` is non-empty after the loop: re-dispatch the sessions for
  those projects with the same prompts as Step 4.

Do not proceed to Step 6 until every project passes. The workspace-level
context session reads each project's `overview.md` — missing files cause
gaps in the cross-project context.

---

## initialize-workspace: Step 6: Workspace-level context (first folder)

After all project sessions pass, dispatch one final background `ICON:context-specialist`
agent at the **workspace root** (first folder):

```
You are @context-specialist. Generate workspace-level context for a VS Code multi-root workspace.

tree_position: root
git_root: <WORKSPACE_GIT_ROOT>
working_directory: <WORKSPACE_ROOT>
feature_branch: chore/initialize-agent-context
area_paths: <COMMA_SEPARATED_PROJECT_PATHS>
repo_type: workspace

The feature branch already exists — do not create a new branch.

Load and execute the `context-specialist-impl-root` skill.
Work autonomously — do not pause for user confirmation or input.

The individual project folders already have their own .context/ folders —
do not modify them. Your job is cross-project and workspace-level context
at the workspace root only.

Read each project's .context/overview.md before generating root content.
Commit using the repo's commit convention. Run to completion without stopping.
```

---

## initialize-workspace: Step 7: Push and open merge requests

Push and MR creation is **per git repo** — one MR per unique git root:

```bash
for GIT_ROOT in "${UNIQUE_GIT_ROOTS[@]}"; do
  git -C "$GIT_ROOT" push --set-upstream origin chore/initialize-agent-context
done
```

For each git repo, open a merge request targeting that repo's integration branch.
Follow the MR description format from the `mr-discipline` skill (Summary,
Why, How to Test, Risks). For example:

```markdown
## Summary
- Added .claude/claude.md and .context/ for: <service-a>, <service-b>
- Added workspace-level files in .context/ (projects.md, overview.md,
  decisions/) plus architecture/ and domains/ at the workspace root

## Why
Bootstraps the agent-system context so @manager can route tasks to
the correct project via resolve-repo-context, and specialist agents have domain knowledge available from
the first task.

## How to Test
Review each project's .claude/claude.md and .context/overview.md for
accuracy. Verify `projects.md` in .context/ lists all projects with correct paths.
Check that no credentials or sensitive information were captured.

## Risks
AI-inferred context may contain inaccuracies. Each file should be reviewed by
a developer who knows the codebase before merging.
```

**Do not merge these MRs yourself.** Surface all MR URLs to the user and stop.

---

## initialize-workspace: Step 8: Report

Summarize:

- Projects initialized: list with `initialize-repo` or `upgrade-repo` label
- Resources skipped: list with reason
- Verification: pass/fail per project
- MR URLs (one per git repo)
- Any failures requiring manual follow-up

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Treating resource folders (docs-only, data-only) as projects | Classify first (Step 2) — no build manifests and no `src/` code means skip |
| Skipping workspace-level context for the first folder | First folder always gets Step 6 regardless of classification |
| Creating one branch across all repos | Branch management is per-repo (Step 1) — a workspace spans multiple git roots |
| Running `git log` from `PROJECT_PATH` instead of `GIT_ROOT` | The project folder may not be the repo root; use `GIT_ROOT` for full history |
| Starting Step 6 before all project sessions pass Step 5 | Workspace session reads each project's `overview.md` — missing files cause gaps |
| Opening one MR for the whole workspace | Open one MR per git repo targeting that repo's integration branch |
| Resolving relative `.code-workspace` paths relative to CWD | Relative paths are relative to the `.code-workspace` file's own directory — use `os.path.realpath` |
| Merging MRs without human review | Always surface MR URLs and stop — do not self-merge |
