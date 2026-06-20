<!-- template-version: 1.0 -->
# Architecture Phase Templates

> Loaded by the `task-plan-phase-architecture` skill when present.
> Customize the triggers list and delegation template for your team's
> architectural conventions.

## Additional Architecture Review Triggers

> These supplement the standard decision matrix in the phase skill.
> Add project-specific triggers below.

- <!-- example: Changes to [YourSharedLibrary] public API -->
- <!-- example: New [YourFramework] module added -->
- <!-- example: Changes to [YourAuthService] or token handling -->

## @architect Delegation Template

```
Change proposed: [description of what the plan calls for]
Architecture context:
  - [key fact from .context/architecture/patterns.md]
  - [key constraint from .context/decisions/]
Specific questions:
  - [question about fit with existing module structure]
  - [question about coupling or dependency impact]
Constraints:
  - [hard requirements from the user or .context/decisions/]
Ticket: [TICKET-ID]
```

## Architecture Decision Capture

> Paste this block into plan.md when recording an architecture decision.

```markdown
### Architecture Decision — [short title]
**Date:** [YYYY-MM-DD]
**Decision:** [Approve / Approve with modifications / Reject]
**Rationale:** [why]
**Modifications required:** [if any, or "none"]
**Risks flagged:** [if any, or "none"]
```
