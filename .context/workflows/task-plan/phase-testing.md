<!-- template-version: 1.1 -->
# Testing Phase Templates

> Loaded by the `task-plan-phase-testing` skill when present.
> These templates supersede the skill's built-in defaults for this repo.
>
> **ICON has no test runner.** `iconrc.json` excludes `.context/testing/` because
> the plugin is pure-content. "Testing" for ICON tasks means **structural
> validation** (JSON parses, manifest paths resolve, files have expected shape)
> and **runtime smoke checks** (invoking the changed skill/agent/command in a
> live session and observing correct behavior). Adapt the templates accordingly.

## @tester Delegation Template

```
What to validate: [skill, agent, command, hook, or template change to verify]
Ticket: ICON-NNNN
Files involved:
  - [path/to/file]: [what it does and what changed]
Structural checks:
  - JSON files parse (`.claude-plugin/plugin.json`, `.mcp.json`, `.context/iconrc.json` if touched)
  - Skill frontmatter `name:` matches the containing directory name
  - Agent files include `shared/common-constraints.md` verbatim (byte-equal) if relevant
  - Manifest references resolve to real paths under `agents/`, `skills/`, `commands/`, `hooks/`
  - `context_template/` changes preserve `.context/` structure expected by initializer skills
Runtime smoke checks:
  - [scenario 1 — happy path: invoke the skill / agent / command in a session and confirm expected behavior]
  - [scenario 2 — error/edge case: trigger the failure path the change is meant to handle]
  - [scenario 3 — cross-cutting: if context_template/ or common-constraints changed, run /icon-init or re-inject into a sample target and confirm output]
Success criteria:
  - All structural checks pass.
  - All runtime smoke checks produce the expected output / observed behavior — copy the relevant transcript snippet into plan.md.
```

## Validation Status Tracker

> Paste this table into plan.md when dispatching @tester.

| Validation Area | Status | Notes |
|-----------------|--------|-------|
| Structural — [JSON / frontmatter / refs] | ⏸️ Pending | — |
| Runtime smoke — [skill or command invocation] | ⏸️ Pending | — |
| Cross-cutting — [context_template / common-constraints] | ⏸️ Pending | — |
| Issues found | — | — |

Status: ⏸️ Pending · 🔄 In Progress · ✅ Done · ❌ Blocked
