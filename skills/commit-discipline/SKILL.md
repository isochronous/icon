---
name: commit-discipline
description: >
  Use when committing changes or when uncommitted changes span multiple concerns — including when "and" is needed to describe a single commit, when "wip" / "fix" / "updates" is being typed as a commit message, when changes have accumulated across days without commits, or when committing code that hasn't been verified to compile or pass tests. For pull-request workflow, see `pr-discipline`.
user-invocable: false
---

# Commit Discipline

## Overview

**Every commit should be a safe rollback point.** Atomic commits with meaningful messages make debugging, reviewing, and reverting possible. Monolithic commits make all three impossible.

## Before You Commit: Read This Project's Conventions

Every project has its own commit format. Before writing any commit message,
check for this project's recorded conventions:

```
.context/workflows/commit-conventions.md
```

If the file exists, use **exactly** the format documented there — ticket prefix,
case, separator, and any footer conventions. The examples in that file are drawn
from the actual git history of this repo and override the generic examples below.

If the file does not exist (e.g., `initialize-repo` has not been run yet), infer
the format from `git log --oneline -10` and apply what you observe. If the log is
empty or ambiguous, fall back to the structure described in Rule 3 below.

---

## When to Invoke

- You are about to commit changes
- You have completed a logical unit of work
- You notice uncommitted changes accumulating across multiple concerns

(For pull-request workflow — opening, descriptions, review feedback, merge conflicts — see `pr-discipline`.)

## The Rules

### commit-discipline: Rule 1: Commit Atomically

One logical change per commit. A commit should do ONE thing and do it completely.

**Atomic means:**
- All files in the commit serve the same purpose
- The commit could be reverted without breaking unrelated functionality
- The commit message can describe the change in one sentence without "and"

```
# ✅ Atomic commits
PROJ-101: Resolve null pointer in UserService.getProfile()
PROJ-202: Add email validation to registration form
PROJ-303: Add integration tests for payment webhook
PROJ-404: Extract date formatting into shared utility

# ❌ Non-atomic (multiple concerns)
PROJ-101: Resolve null pointer and add email validation and update tests
update: various fixes and improvements
```

**If you need "and" in the message, split the commit.**

### commit-discipline: Rule 2: Commit at Verified Checkpoints

Commit after each green state — when tests pass and the change is verified:

- After implementing a feature and verifying it works
- After fixing a bug and confirming the fix
- After each RED → GREEN → REFACTOR cycle in TDD
- After a refactor that passes all existing tests

**Never commit:**
- Code that doesn't compile/parse
- Changes you haven't tested or verified
- Partial implementations that leave the codebase broken

### commit-discipline: Rule 3: Write Meaningful Messages

Messages should explain WHAT changed and WHY, in a format useful to future developers (including agents).

**Default structure** (override with whatever `commit-conventions.md` specifies):
```
<Issue ID>[, <Issue ID>]: Brief description of what changed

<optional body: why this change was necessary, context that isn't obvious from the diff>

<optional footer: references, breaking changes>
```

**Good messages answer:** "If I read only this message (not the diff), do I understand what happened and why?"

```
# ✅ Good: What + Why
PROJ-101: Prevent duplicate webhook processing

Webhooks were being processed multiple times when the provider
retried on timeout. Added idempotency check using event ID.

# ✅ Good: Self-explanatory
PROJ-202: Extract rate limiter from API handler into middleware

# ✅ Good: Multiple tickets
PROJ-303, PROJ-304: Add email validation to registration and profile forms

# ❌ Bad: No ticket ID
fix: add check

# ❌ Bad: Describes the diff (useless)
PROJ-101: Change line 42 in UserService.java

# ❌ Bad: Too vague
PROJ-101: Updates
```

### commit-discipline: Rule 4: Branch Hygiene

- Work on feature/fix branches, not directly on main/master or dev
- Branch names should be descriptive: `feat/user-registration`, `fix/webhook-duplicates`
- Keep branches focused — one feature or fix per branch
- Rebase or merge from main regularly to avoid drift

**For pull-request workflow** (opening, descriptions, review feedback, merge conflicts): see `pr-discipline`.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Giant "work in progress" commit at end of day | Commit incrementally as each piece is verified |
| Committing generated files (build output, lock files unintentionally) | Use `.gitignore`. Review `git status` before committing |
| Empty or meaningless messages ("fix", "wip", "asdf") | Take 10 seconds to write a real message |
| Committing secrets or credentials | Check diffs for API keys, passwords, tokens before every commit |
| Mixing refactoring with feature work in one commit | Refactor first (commit), then add feature (commit) |
| Deriving a GitHub issue reference from a PR number or any other unrelated identifier (e.g., "PR 2942" → "#2942") | If no issue reference was provided by the user, use a local task ID (from `local_task_id_prefix` in `.iconrc`) or ask the user for the issue number before committing. Never construct an issue reference by reusing a numeric identifier from another system. |

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I'll clean up the commits later with rebase" | You won't. Write good commits now. |
| "It's just a small project, commit hygiene doesn't matter" | Small projects become big projects. Habits transfer. |
| "Nobody reads commit messages" | Agents read them. Future-you reads them. Reviewers read them. |
| "Atomic commits are slower" | Debugging monolithic commits is slower. |
| "Just one commit with everything is fine for this branch" | A reviewer cannot revert one concern out of a bundled commit. Split. |
| "It compiles — that's enough to commit" | Compile is not test. Verify before committing; commit at green states. |
| "I'll add a ticket ID later" | Commits without ticket IDs are unsearchable. Add it now. |

## Red Flags — STOP and Re-Stage

If you catch yourself doing any of these, the commit is not ready:

- About to type "and" in the commit subject — split the commit.
- About to use "wip", "fix", "updates", "asdf", or "various changes" as the message.
- About to commit code that hasn't been verified to compile or pass tests.
- Uncommitted changes span more than one logical concern (refactor + feature, two unrelated bug fixes, etc.).
- About to push directly to `main`, `master`, or `dev` without a feature branch.
- About to `--amend` a commit that has already been pushed.
- About to use `--force` or `--force-with-lease` without explicit user instruction.
- About to leave newly-created files untracked instead of including them in the commit.
- About to use an issue reference that was derived from a PR number rather than provided by the user — fabricated IDs look legitimate but are unsearchable and misleading.

**All of these mean: stop, re-stage, and write the commit you would want to read on a debugging trail in six months.**
