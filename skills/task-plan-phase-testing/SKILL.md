---
name: task-plan-phase-testing
description: >
  Internal task-plan phase skill. Do not invoke without explicit direction.
user-invocable: false
---

# Phase: Testing

Load this skill when the task's **primary concern is test quality**: fixing
failing tests, adding coverage to under-tested code, or driving a feature
implementation test-first (TDD). Where testing is just a trailing step after
implementation — not the primary concern — load `task-plan-phase-completion`
instead, which covers light validation.

**Template-override rule**: apply `.context/workflows/task-plan/phase-<name>.md` if present — see `task-plan` for the full policy.

## task-plan: Testing: Phase Entry (Reconstruct-First)

**Run this FIRST, before any testing work.** Each phase resumes from the committed
`plan.md`, not session memory. Read `## Phase State`, confirm this run's phase
matches `Current`/`Next` and every earlier phase is `done`, then read the
preceding handoff block plus the cumulative `## Decisions` / `## Key Files` /
`## Constraints`. Validate this phase's entry contract (changed-file set +
implementation outcomes + `## Review Checkpoint` status) and **fail closed** — if
a required input is missing, a prerequisite phase is not `done`, `HEAD` lacks the
expected `Phase-Handoff:` trailer, or the tree is unexpectedly dirty, STOP and
surface the gap; do not re-derive to backfill. Full protocol and entry contract:
`phase-testing.md` `## Phase Entry`; `## Phase State` / `## Phase Handoff Log`
shapes: `base.md` Section Guidance.

## task-plan: Testing: When to Load This Skill

Load `task-plan-phase-testing` when the task matches any of these:

- **Failing tests**: Task is "fix the failing test suite" or "fix N broken tests"
- **Coverage**: Task is "add tests for X" or "bring coverage above N%"
- **TDD**: Task drives implementation via tests written first
- **Test refactor**: Task is cleaning up or restructuring existing tests

Do NOT load this skill when:
- Testing is one final verification step after implementation (use completion)
- The codebase has no tests and adding tests is not the stated goal

## task-plan: Testing: @tester Delegation Structure

Every tester delegation must include all of these fields. The @tester agent
invokes `testing-discipline` internally; you do not need to.

```
What to test: [feature, module, or failure description]
Files involved:
  - [path/to/file]: [what it does]
Test requirements from the plan: [list from plan.md acceptance criteria]
Existing test patterns: [reference to .context/testing/ files]
Specific scenarios to cover:
  - [scenario 1 — happy path]
  - [scenario 2 — error/edge case]
  - [scenario 3 — boundary condition]
Success criteria:
  - All specified scenarios have passing tests
  - No test smells (no mocking internals, no testing implementation details)
  - [coverage target, if any]
```

## task-plan: Testing: Test Status Tracking

Add this table to `plan.md` `## Progress` section when dispatching @tester:

```markdown
| Test Area | Status | Notes |
|-----------|--------|-------|
| Unit — [component] | ⏸️ Pending | — |
| Integration — [flow] | ⏸️ Pending | — |
| Coverage | ⏸️ Pending | — |
| Bugs found | — | — |
```

Status: ⏸️ Pending · 🔄 In Progress · ✅ Done · ❌ Blocked

Update after @tester completes. If bugs are found, route each to a @coder step before proceeding.

## task-plan: Testing: Debugging Failing Tests

When tests are failing and the root cause is unclear:

1. If @tester fails to identify the cause after one pass, invoke
   `systematic-debugging` before re-dispatching.
2. When `@tester` stalls on the same failure, invoke `systematic-debugging` —
   that skill owns the numeric trigger. The root cause is structural, not
   incidental, at that point.
3. Document each debugging step in `plan.md` `## Decisions` as it runs.

## task-plan: Testing: Phase Exit (Handoff Write)

**Run this LAST, at the phase boundary.** Phase boundaries are commit points.
Append one `### Handoff: testing → <next-phase>` block to `## Phase Handoff Log`
(append-only — never rewrite earlier blocks) capturing the @tester outcomes,
reviewer findings + resolution, verification evidence (the actual
structural-check and runtime-smoke transcript snippets, copied — not "passed"),
the Decisions/Key Files deltas, and **What the next phase needs**; mirror the
deltas into their sections. Update `## Phase State` (advance
`Completed`/`Current`/`Next`, set the `Current` status, record the next loaded
skill, reset `Attempts` to `0`). Then commit `plan.md` plus all artifact deltas
with the trailer `Phase-Handoff: testing` — uncommitted work at a boundary is an
incomplete handoff and the next phase fails closed. Full write/commit steps:
`phase-testing.md` `## Phase Exit / Handoff`; block shape: `base.md` Section
Guidance and `context-document-guidelines`.

## task-plan: Testing: Relationship to Other Skills

- **`testing-discipline`**: @tester invokes this internally. You do not need to.
- **`systematic-debugging`**: Invoke when tests fail and root cause is unclear
  after the first @tester pass, or when `@tester` stalls — that skill owns the
  numeric trigger.
- **`task-plan-phase-implementation`**: If fixing tests requires code changes,
  delegate those via the implementation skill, then return to testing.
- **`task-plan-phase-completion`**: Load after testing is done to close the task:
  code review, context updates, retrospective.

**Does NOT cover:** investigation, architecture review, implementation phase, retrospective,
context updates, completion summary.
