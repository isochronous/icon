---
name: pr-discipline
description: >
  Use when opening a pull request, writing a PR description, addressing review feedback, or resolving merge conflicts — including when about to open a PR without self-reviewing the diff, when writing the description as an afterthought, when force-pushing over reviewer feedback, when accepting "ours" or "theirs" in a merge conflict without reading both sides, or when a PR exceeds 20 files without a guided description.
user-invocable: false
---

# PR Discipline

## Overview

**A PR is a contract with the reviewer.** Before opening one, the diff should be self-reviewed, the build green, the description complete. After opening, every comment gets addressed and every fix lands as a new commit — not a force-push that invalidates the review trail.

## When to Use

- About to open a pull request
- Writing or refining a PR description
- Responding to review feedback
- Resolving merge conflicts on a PR branch

## When NOT to Use

- For commit-message format and atomicity → use `commit-discipline`.
- For evaluating someone else's PR → use `code-quality-rules`.

## Opening a PR

Before opening, complete this checklist:

- **Reconcile `plan.md` (if one exists for this branch's task)**: Confirm it was reconciled against the final state per `.context/workflows/task-plan/phase-completion.md § Reconcile plan.md`. Stale plans mislead reviewers and corrupt retro extraction. Surface this as a self-review question on the PR template ("plan.md reconciled? y/n") for spot-checking.
- **Self-review the diff**: Read every changed file as the reviewer would. Fix anything you'd flag.
- **Verify the branch builds and tests pass**: Include the evidence in the description.
- **Check for unintended changes**: Stray formatting, debug code, unrelated refactors — remove them or split into separate PRs.

## Writing the Description

- **Title**: Same format as commit messages — read `.context/workflows/commit-conventions.md` and apply **exactly** that format (issue prefix, case, separator). If absent, fall back to `Issue #123: Brief description`.
- **Link to story/task**: Reference the GitHub issue (`#123`) or `.context/tasks/` artifact.
- **What changed and why**: Summarize the approach, not the diff. Explain what the diff doesn't show (design decisions, rejected alternatives, context).
- **How to test**: Steps a reviewer can follow. Include commands, URLs, or test names.
- **Risks and trade-offs**: Call out anything the reviewer should scrutinize closely.
- **Screenshots or recordings**: For UI changes, before/after screenshots are mandatory.

```markdown
## Summary
- Added idempotency check to webhook processing using event ID

## Why
Webhooks were being processed multiple times when the provider
retried on timeout, causing duplicate transactions.

## How to Test
1. Run `npm test -- --grep "webhook"` — all pass
2. POST the same webhook payload twice — second returns 200 but no-ops

## Risks
- Redis dependency added for idempotency cache — requires REDIS_URL in env
```

Closing the linked issue: include a closing keyword (`Closes #123`, `Fixes #123`) so the issue auto-closes on merge.

## PR Size

- Prefer small, reviewable PRs. If a PR changes 20+ files, consider splitting.
- If splitting isn't practical, use the description to walk the reviewer through the changes in logical order.

## Handling Review Feedback

- Address every comment — resolve, reply, or discuss. Don't leave comments hanging.
- Push fixes as new commits (not force-push or amend) so reviewers see what changed since their review.
- Before re-requesting review, check whether any addressed feedback changed documented behavior. If any feedback-driven change makes an existing `.context/` statement false, incomplete, or missing — invoke `context-maintenance`. Resolve the mismatch in the same feedback cycle, not after approval.
- Re-request review after addressing feedback.

## Merge Conflicts

- Resolve by rebasing or merging from the target branch — don't blindly accept "ours" or "theirs".
- After resolving, re-run tests to confirm the resolution didn't break anything.

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I'll add the description after I open it" | Reviewers get notified immediately; an empty description sets the wrong expectation. Write it first. |
| "The diff is self-explanatory" | The diff shows what changed, not why. Reviewers need the why. |
| "I'll let CI confirm tests pass" | Open with green CI evidence, not faith. Failures during review burn reviewer cycles. |
| "Force-push after addressing feedback keeps history clean" | Force-push erases the review trail. New commits are how reviewers track what changed since their last pass. |
| "I'll just accept ours / theirs in the conflict" | Blind resolution silently drops the other side. Read both, choose deliberately, re-test. |
| "20+ files but all related — one PR is fine" | Reviewers fatigue. Split when you can; if you can't, walk the reviewer through the order. |
| "I addressed the comment in code; no reply needed" | Silence reads as ignored. Resolve or reply — never both-ignore. |
| "It was an internal refactor — behavior didn't change" | If `.context/` describes that constraint, invariant, or decision, the docs can be wrong without any user-facing change. Invoke `context-maintenance`. |
| "I'll update `.context/` after the reviewer approves" | Re-requesting review against stale docs preserves the mismatch. Update context in the same feedback cycle before re-requesting. |

## Red Flags — STOP and Re-Open Properly

If you catch yourself doing any of these, the PR is not ready or the response is not done:

- A `plan.md` exists for this branch's task and you have not confirmed it was reconciled against the final state per `.context/workflows/task-plan/phase-completion.md § Reconcile plan.md`.
- About to open a PR without having read every changed file as the reviewer would.
- About to publish the PR before writing the description.
- About to force-push or amend after a reviewer has already commented.
- About to accept "ours" or "theirs" in a merge conflict without reading both sides.
- About to leave a review comment unresolved without a reply.
- PR is 20+ files and you have no plan to guide the reviewer through them.
- About to re-request review after addressing feedback that changed documented behavior without invoking `context-maintenance`.

**All of these mean: pause. Open / merge / respond properly, not faster.**
