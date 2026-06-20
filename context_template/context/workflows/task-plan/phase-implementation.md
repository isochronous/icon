<!-- template-version: 1.1 -->
# Implementation Phase Templates

> Loaded by the `task-plan-phase-implementation` skill when present.
> Customize the dispatch template and progress tracker for your team's workflow.

## @coder Dispatch Template

```
Step [N]: [description]
Ticket: [TICKET-ID]
Files to create/modify:
  - [path/to/file]: [what to do]
Patterns to follow:
  - [reference to .context/standards/ file]
  - [reference to .context/architecture/ file]
Research/architecture findings: [summary or "N/A"]
Acceptance criteria:
  - [specific, verifiable outcome]
  - Commit all created/modified files
```

## Implementation Progress Tracker

> Paste this table into plan.md to track step-by-step status.
> Update the Status column as each step progresses.

| Step | Description | Status | Outcome |
|------|-------------|--------|---------|
| 1 | [step description] | ⏸️ Pending | — |
| 2 | [step description] | ⏸️ Pending | — |

Status: ⏸️ Pending · 🔄 In Progress · ✅ Done · ❌ Blocked

## Deviation Log Entry

> Paste this block into plan.md ## Decisions when recording a plan deviation.

```markdown
### Deviation — Step [N]
**Original plan:** [what was planned]
**Actual approach:** [what was done instead]
**Reason:** [why the deviation occurred]
**Impact on subsequent steps:** [none / steps X, Y affected — describe]
```

## Pre-Completion Review

When all implementation and testing steps are done, and BEFORE handing off to
completion or reporting the work done, dispatch @reviewer over the full
changed-file set. Resolve critical and moderate findings by routing fixes back
to @coder (which re-opens implementation). Then record a `## Review Checkpoint`
line in `plan.md` naming the reviewed step and the findings-resolution status.
This is the primary review — it runs before the task is reported done.
