---
name: task-plan-phase-investigation
description: >
  Internal task-plan phase skill. Do not invoke without explicit direction.
user-invocable: false
---

# Phase: Investigation

Load this skill when the task's **primary concern is understanding scope or
gathering research**. For tasks where the path is already clear (implementation,
testing), skip this skill and load the appropriate concern skill directly. For
simple tasks (single-component fix, established pattern), skip phase skills
entirely.

**Template-override rule**: apply `.context/workflows/task-plan/phase-<name>.md` if present — see `task-plan` for the full policy.

## task-plan: Investigation: Phase Entry (Reconstruct-First)

**Run this FIRST, before any investigation work.** Each phase resumes from the
committed `plan.md`, not from session memory. Read `## Phase State`, confirm this
run's phase matches `Current`/`Next` and that every earlier phase in the Phase
plan is `done`, then read the preceding handoff block plus the cumulative
`## Decisions` / `## Key Files` / `## Constraints`. Validate this phase's entry
contract and **fail closed** — if a required input is missing, a prerequisite
phase is not `done`, `HEAD` lacks the expected `Phase-Handoff:` trailer, or the
tree is unexpectedly dirty, STOP and surface the gap; do not re-derive to
backfill. Investigation is the entry phase, so it usually has no preceding
handoff or trailer. The full protocol and per-phase entry contract live in the
`phase-investigation.md` template `## Phase Entry` section; the `## Phase State`
and `## Phase Handoff Log` shapes are defined in `base.md` Section Guidance.

## task-plan: Investigation: Context Gathering Checklist

Before forming any hypothesis or plan, read in order:

1. `.claude/claude.md` (or `.github/copilot-instructions.md` on repos still on the legacy path) — project overview, tech stack, key commands
2. `.context/overview.md` — system architecture, module roles
3. `.context/decisions/` — prior choices that constrain this task
4. `.context/retrospectives.md` — scan for lessons relevant to this type of task
5. Relevant `.context/domains/` files — entities, rules, API patterns for touched areas
6. Existing task folder (`plan.md`) if re-entering after compaction

## task-plan: Investigation: Complexity Assessment

Rate before planning:

| Rating | Criteria |
|--------|----------|
| **Simple** | Single component, no architectural questions, established patterns |
| **Medium** | Multiple components, requires sequencing, one or two architectural questions |
| **Complex** | Module-level changes, new patterns, migrations, cross-service boundaries, significant unknowns |

- Simple → skip task folder, track inline.
- Medium or Complex → create task folder and `plan.md` immediately (invoke `task-plan` skill), before any other work.

## task-plan: Investigation: When to Delegate to @researcher

**Delegate when:**
- Working with a specific library or framework version and currency matters
- Upgrading a dependency with potential breaking changes
- Adopting a pattern whose current best-practice form is uncertain
- Integrating an external service and the current API/SDK is unfamiliar

**Skip when:**
- The approach is already documented in `.context/`
- This is a purely internal refactor with no external dependency questions
- The task is a bug fix with a clear root cause

## task-plan: Investigation: @researcher Delegation Structure

Every researcher delegation must include all of these fields:

```
Topic: [specific library/framework/technology]
Current version: [X.Y.Z] → Target version: [A.B.C] (if applicable)
Questions:
  - [Specific question 1]
  - [Specific question 2]
Decision this research will inform: [What choice depends on the findings]
Constraints: [Any relevant constraints from the task]
```

## task-plan: Investigation: @planner Delegation Structure

Every planner delegation must include all of these fields:

```
Task: [TASK-ID and description]
Objective: [What we're accomplishing and why]
Affected areas: [Modules/files/domains involved]
Complexity: Simple / Medium / Complex
Relevant context:
  - [Key constraint or pattern from .context/]
  - [Key constraint or pattern from .context/]
Research findings: [Summary of @researcher output, or "N/A — no research needed"]
Open questions for planner: [Anything still ambiguous that planner should address]
```

## task-plan: Investigation: Investigation-First Plans

If the root cause or scope is unknown at the start (bugs, poorly-scoped requests), use a two-step plan immediately — do not wait for the investigation to complete:

```markdown
## Progress
- [ ] Investigate: [describe the symptom or unknown] ← IN PROGRESS
- [ ] Update this plan with findings and next steps
```

Create the task folder and `plan.md` with these two steps. After investigation, replace them with the full plan before any fix work begins.

## task-plan: Investigation: Exit Criteria

Investigation is complete when all of these are true:

- Scope is fully understood — all affected files and modules identified
- All significant unknowns are resolved or explicitly logged as Open Questions
- The plan contains sequenced steps with file-level granularity
- Dependencies between steps are identified
- Acceptance criteria are defined for each step

Do not proceed to architecture or implementation while open questions remain that could change the plan's structure.

## task-plan: Investigation: Phase Exit (Handoff Write)

**Run this LAST, at the phase boundary.** Phase boundaries are commit points.
Append one `### Handoff: investigation → <next-phase>` block to
`## Phase Handoff Log` (append-only — never rewrite earlier blocks) capturing the
sub-agent outputs, verification evidence, the Decisions/Key Files deltas, and
**What the next phase needs**; mirror the deltas into their sections. Update
`## Phase State` (advance `Completed`/`Current`/`Next`, set the `Current` status,
record the next loaded skill, reset `Attempts` to `0`). Then commit `plan.md` plus all
artifact deltas with the trailer `Phase-Handoff: investigation` — uncommitted
work at a boundary is an incomplete handoff and the next phase fails closed. The
full write/commit steps live in the `phase-investigation.md` template
`## Phase Exit / Handoff` section; block shape is defined in `base.md` Section
Guidance and `context-document-guidelines`.

## task-plan: Investigation: Relationship to Other Skills

- **`systematic-debugging`**: When the task is a bug with unclear root cause,
  invoke `systematic-debugging` during investigation to trace the root cause
  before planning a fix.
- **`design-first`**: When investigation reveals multiple valid implementation
  approaches, invoke `design-first` to explore and select one before planning.
- **`task-plan`**: Governs `plan.md` format and update triggers. This skill
  governs HOW to investigate; `task-plan` governs the plan document.
- **`task-plan-phase-implementation`**: Load after investigation when the
  primary work shifts to writing code.
- **`task-plan-phase-testing`**: Load after investigation when the primary work
  shifts to tests.

**Does NOT cover:** architecture review, implementation phase, testing phase,
retrospective.
