<!-- template-version: 1.0 -->
# Testing Phase Templates

> Loaded by the `task-plan-phase-testing` skill when present.
> Customize the delegation template and test scenarios for your team's workflow.

## @tester Delegation Template

```
What to test: [feature, module, or failure description]
Ticket: [TICKET-ID]
Files involved:
  - [path/to/file]: [what it does]
Test requirements:
  - [requirement 1]
  - [requirement 2]
Existing test patterns: [reference to .context/testing/ files]
Specific scenarios to cover:
  - [scenario 1 — happy path]
  - [scenario 2 — error/edge case]
  - [scenario 3 — boundary condition]
Success criteria:
  - All specified scenarios have passing tests
  - [coverage target, if specified]
```

## Test Status Tracker

> Paste this table into plan.md when dispatching @tester.

| Test Area | Status | Notes |
|-----------|--------|-------|
| Unit — [component] | ⏸️ Pending | — |
| Integration — [flow] | ⏸️ Pending | — |
| Coverage | ⏸️ Pending | — |
| Bugs found | — | — |

Status: ⏸️ Pending · 🔄 In Progress · ✅ Done · ❌ Blocked
