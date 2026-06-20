---
name: icon-status
description: >
  Use when re-orienting in a repo — shows active task, current branch, recent retrospectives, and context coverage. Run when returning to a repo after a break or before planning new work.
user-invocable: true
---

# ICON Status

## Overview

Emit a concise plugin-state dashboard for the current repo: active task, recent
retrospectives, and context health. Use before planning new work or after
returning to a repo after a break.

## When to Use

- Returning to a repo after a break and want to know where things stand
- About to plan new work and need to check context health

**Do not use** to inspect a specific task's details — read `.context/tasks/<TASK-DIR>/plan.md`
directly for that.

---

## icon-status: Step 1: Fresh-repo guard

Check whether `.context/` exists in the current working directory.

```bash
[ -d ".context" ] || echo "NOT_INITIALIZED"
```

If `.context/` does not exist, emit the following message and **halt — do not
attempt to render the dashboard**:

```
This repo is not yet ICON-initialized. Run `/icon-init` to set up — it detects your repo type automatically.
```

---

## icon-status: Step 2: Gather data

Run each block below. Every block handles missing data gracefully — if a file or
directory is absent, emit an appropriate "not found" note rather than silently
producing empty output.

### Repo name

```bash
REPO_NAME=$(git remote get-url origin 2>&1 | grep -v "^fatal" | sed 's|.*[/:]||' | sed 's|\.git$||')
[ -z "$REPO_NAME" ] && REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>&1 | grep -v "^fatal")")
[ -z "$REPO_NAME" ] && REPO_NAME="(unknown)"
echo "$REPO_NAME"
```

### Current branch and active task

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>&1 | grep -v "^fatal")
TASK_ID=$(printf '%s' "$BRANCH" | grep -oE '[A-Z]+-[0-9]+' | head -1)
echo "BRANCH=$BRANCH"
echo "TASK_ID=$TASK_ID"
```

- If `$BRANCH` is `main`, `dev`, or `master`: active task section reads
  "No active task branch."
- Otherwise: report `$TASK_ID` (if matched) and check whether a `plan.md` exists:

```bash
if [ -n "$TASK_ID" ]; then
  PLAN_FILE=$(find .context/tasks -maxdepth 2 -name "plan.md" -path "*${TASK_ID}*" 2>&1 | grep -v "^find:" | head -1)
  if [ -n "$PLAN_FILE" ]; then
    echo "PLAN_FILE=$PLAN_FILE"
  else
    echo "PLAN_FILE=(none)"
  fi
fi
```

### Recent retrospectives (last 3 entries)

```bash
if [ -f ".context/retrospectives.md" ]; then
  grep -E '^### [A-Z]+-[0-9]+' .context/retrospectives.md | head -3
else
  echo "(no retrospectives.md)"
fi
```

If no lines match, skip the "Recent retrospectives" section in the dashboard
output entirely.

### Context health

```bash
for d in domains standards workflows architecture testing styling; do
  if [ -d ".context/$d" ]; then
    COUNT=$(find ".context/$d" -maxdepth 1 -name '*.md' -type f | wc -l)
    echo "  .context/$d/ — $COUNT files"
  fi
done
```

### iconrc.json

```bash
if [ -f ".context/iconrc.json" ]; then
  ICONRC_VERSION=$(python3 -c 'import json,sys; print(json.load(open(".context/iconrc.json")).get("version","?"))')
  echo "  .context/iconrc.json — version $ICONRC_VERSION"
fi
```

### Suggestions

Evaluate the following signals and collect any that apply into a suggestions list:

```bash
# Signal 1: .context/domains/ missing or empty
if [ ! -d ".context/domains" ]; then
  echo "- No .context/domains/ directory — run /upgrade-repo to bring context current."
else
  DOMAIN_COUNT=$(find ".context/domains" -maxdepth 1 -name '*.md' -type f | wc -l)
  if [ "$DOMAIN_COUNT" -eq 0 ]; then
    echo "- .context/domains/ has no files — run /upgrade-repo to bring context current."
  fi
fi
```

```bash
# Signal 3: task branch with a stale plan.md (not modified in 48h)
if [ -n "$TASK_ID" ] && [ -n "$PLAN_FILE" ] && [ "$PLAN_FILE" != "(none)" ]; then
  MTIME=$(find "$PLAN_FILE" -maxdepth 0 -mmin +2880 2>&1 | grep -v "^find:")
  if [ -n "$MTIME" ]; then
    echo "- plan.md stale — not modified in 48h. Still working on this?"
  fi
fi
```

If no suggestions apply, omit the Suggestions section from the dashboard output.

---

## icon-status: Step 3: Render the dashboard

Assemble the gathered data into the following format. **Emoji is approved for this
readout.** Omit any section entirely when it has no data (e.g., no retrospectives,
no suggestions).

```
📋 ICON Status — <REPO_NAME>

Active task: <TASK_ID> (branch: <BRANCH>)
Plan: .context/tasks/<TASK-DIR>/plan.md

Recent retrospectives (last 3):
  <entry 1>
  <entry 2>
  <entry 3>

Context health:
  .context/domains/   — N files
  .context/standards/ — N files
  .context/iconrc.json — version X.Y

Suggestions:
  - <zero or more>
```

**Section rules:**

| Section | Omit when |
|---------|-----------|
| Active task | Branch is `main`, `dev`, or `master` — replace with "No active task branch." |
| Plan line | No `plan.md` found for the task ID |
| Recent retrospectives | No task-ID headings (`### PROJ-123` style) found in `retrospectives.md` |
| Context health | No `.context/` subdirectories found at all |
| Suggestions | No signals triggered |

---

## Common Mistakes

| Mistake | What happens | Correct behavior |
|---------|-------------|-----------------|
| Running on a repo with no `.context/` | Skill halts at Step 1 with the `/icon-init` suggestion | Correct — Step 1 is a hard stop |
| Branch is `dev` or `main` | "No active task branch" appears | Correct — not an error |
