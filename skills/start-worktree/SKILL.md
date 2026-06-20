---
name: start-worktree
description: >
  Use when the user explicitly requests worktree isolation or states they are working in the repo concurrently with the agent. A manager agent may also invoke this when dispatching parallel agents to the same repository.
user-invocable: true
---

# Start Worktree

## Overview

Git Worktrees let you check out a branch into a **separate directory** alongside
your main clone. The agent works in its own directory; you work in yours — same
repo, no conflicts.

**Key fact**: a worktree is not a new clone. It shares the `.git` database.
Commits, branches, and pushes are all visible across every worktree immediately.

---

## When to Use

- You are actively editing files in the repo while an agent is running
- You want an agent to work on a feature branch without touching your current work
- You need parallel development in the same repository across two sessions
- The agent's branch work is unrelated to your current branch

## When NOT to Use

- No conflict risk (you're not actively in the repo)
- One-off investigation that doesn't produce commits
- The agent only needs to read files, not write them

## start-worktree: Step 1: Choose a Location

Place the worktree **adjacent** to the main repo — not inside it:

```
~/code/
├── my-repo/          ← your main checkout
└── my-repo-TASK-123/ ← agent's worktree
```

Use the naming convention `<repo-name>-<task-id-or-purpose>`:

```bash
# Find your repo's root name
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_ROOT")
WORKTREE_DIR="${REPO_ROOT}/../${REPO_NAME}-TASK-123"
```

**Never place a worktree inside the main repo directory.** Git will reject it,
and if it didn't, tool discovery would break.

## start-worktree: Step 2: Create the Worktree

### New branch (most common — new task):

```bash
git worktree add "$WORKTREE_DIR" -b feature/TASK-123-short-description
```

### Existing branch (resuming work):

```bash
git worktree add "$WORKTREE_DIR" feature/TASK-123-short-description
```

### Verify creation:

```bash
git worktree list
# Expected output shows both your main checkout and the new worktree path
```

## start-worktree: Step 3: Navigate to the Worktree

All agent work happens **from the worktree directory**, not the main repo:

```bash
cd "$WORKTREE_DIR"
pwd  # confirm you're in the right place
git branch --show-current  # confirm you're on the right branch
```

Confirm the project's `.context/` and `.claude/claude.md` (or `.github/copilot-instructions.md` on repos still on the legacy path) are
visible here (they will be — the worktree shares the same files):

```bash
ls .context/ && (ls .claude/claude.md || ls .github/copilot-instructions.md)
```

## start-worktree: Step 4: Record the Worktree Path

If a task folder exists (`.context/tasks/TASK-123/`), record the worktree path
in `plan.md` so future agent turns know where to resume work:

```markdown
## Worktree
Path: /Users/name/code/my-repo-TASK-123
Branch: feature/TASK-123-short-description
```

---

## start-worktree: Step 5: Start Work in the Worktree

The worktree changes WHERE you work, not HOW. All normal agent workflows apply:

- The manager must re-read `.claude/claude.md` (or `.github/copilot-instructions.md` on repos still on the legacy path) and `.context/` on first turn — the CWD has changed, so cached context from the main worktree does not carry over.
- Agents must invoke `using-skills` before beginning any implementation task, exactly as they would from the main checkout.
- Commits made here appear in the shared `.git` database immediately and are visible from the main checkout.

Push the branch from the worktree as you would from any checkout:

```bash
git push -u origin feature/TASK-123-short-description
```

## start-worktree: Step 6: Clean Up When Done

After the branch is merged (or abandoned), remove the worktree:

```bash
# From the main repo directory (not the worktree itself)
cd "$REPO_ROOT"
git worktree remove "$WORKTREE_DIR"

# If the branch is no longer needed:
git branch -d feature/TASK-123-short-description
```

If the worktree directory still exists after removal (e.g., due to untracked files):

```bash
git worktree remove --force "$WORKTREE_DIR"
```

If the directory was already deleted manually (e.g., via Finder or `rm -rf`), prune the stale metadata:

```bash
git worktree prune
```

List remaining worktrees to confirm cleanup:

```bash
git worktree list
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Creating worktree inside the main repo | Always use `../` to place it adjacent |
| Forgetting to `cd` into the worktree | Verify with `pwd` and `git branch --show-current` before any work |
| Trying to check out the same branch in two worktrees | Each branch can only be active in one worktree at a time; create a new branch |
| Leaving stale worktrees after merge | Run `git worktree prune` or `git worktree remove` when done |
| Assuming context files are missing | Worktrees share all tracked files — `.context/` and the canonical instructions file (`.claude/claude.md` or `.github/copilot-instructions.md`) are always present |
| Running builds/tests from main repo while agent uses worktree | Builds may share output dirs (`target/`, `node_modules/`) — check for conflicts by comparing build output paths in both worktrees |
| Skipping context re-read because "I was just working in this repo" | The CWD changed. Re-read `.claude/claude.md` (or `.github/copilot-instructions.md` on repos still on the legacy path) and `.context/` on first turn in the worktree. |

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I'll just be careful not to edit the same files" | You won't. Use a worktree. |
| "It's faster to skip the worktree setup" | One git conflict costs more time than worktree setup. |
| "The agent finished quickly, no need to clean up" | Stale worktrees cause `git worktree list` noise and can block future branch operations. Remove them. |
| "I already have context loaded — no need to re-read .context/" | The worktree is a different CWD. Context must be re-read on first turn. Cached context from the main checkout does not carry over. |
