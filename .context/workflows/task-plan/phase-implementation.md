<!-- template-version: 1.2 -->
# Implementation Phase Templates

> Loaded by the `task-plan-phase-implementation` skill when present.
> These templates supersede the skill's built-in defaults for this repo.

## @coder Dispatch Template

```
Step [N]: [description]
Ticket: ICON-NNNN
Files to create/modify:
  - [path/to/file]: [what to do]
Patterns to follow:
  - [reference to .context/standards/skill-decomposition.md when touching skills]
  - [reference to .context/standards/changelog-discipline.md when touching CHANGELOG.md]
  - [reference to .context/domains/skill-system.md, mcp-servers.md, or plugin-resource-paths.md as relevant]
  - [reference to commit-conventions in .context/workflows/commit-conventions.md]
Research/architecture findings: [summary or "N/A"]
Constraints:
  - ICON is pure-content — no compile/lint/test commands; verification is structural (JSON parses, paths resolve, common-constraints byte-equal across agents).
  - `.claude-plugin/plugin.json` `version` is the SSOT — do not bump it during a feature commit; that belongs to `/release-plugin`.
  - If editing an agent file, never edit the embedded `common-constraints` block directly; edit `shared/common-constraints.md` — the `.githooks/pre-commit` hook re-injects the block into every agent file at commit time and re-stages any updated files automatically.
Acceptance criteria:
  - [specific, verifiable outcome]
  - All created/modified files committed on the task branch with a conventional-commits message.
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

> Paste this block into plan.md `## Decisions` when recording a plan deviation.

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
