---
name: task-plan-phase-architecture
description: >
  Internal task-plan phase skill. Do not invoke without explicit direction.
user-invocable: false
---

# Phase: Architecture

Load this skill when the task's **primary concern is evaluating or making
architectural decisions**. For implementation tasks that encounter an
architectural question mid-work, use `task-plan-phase-implementation` — it
includes guidance on when to invoke @architect for structural questions that
arise during implementation. This skill is for tasks where the architecture
question IS the primary work, not a checkpoint within it.

**Template-override rule**: apply `.context/workflows/task-plan/phase-<name>.md` if present — see `task-plan` for the full policy.

## task-plan: Architecture: When to Consult @architect

| Trigger | Required? |
|---------|-----------|
| New module or bounded context | Required |
| Changes to a shared/core library | Required |
| New external API or service integration | Required |
| Database schema changes | Required |
| Authentication or authorization changes | Required |
| New design pattern not previously used in this codebase | Required |
| Significant refactor crossing module boundaries | Required |
| New dependency with broad transitive impact | Required |
| Medium refactor within a single module | Optional |
| New pattern that follows an established example exactly | Optional |
| Single-component change, pure UI change | Skip |
| Simple fix following established patterns | Skip |

## task-plan: Architecture: @architect Delegation Structure

Every architect delegation must include all of these fields:

```
Change proposed: [Description of what the plan calls for]
Current architecture context:
  - [Key fact from .context/architecture/]
  - [Relevant pattern from .context/standards/]
Specific questions:
  - [Question about fit with existing module structure]
  - [Question about coupling or dependency impact]
  - [Question about testability or risk]
Constraints:
  - [Hard requirements from the user or from .context/decisions/]
```

## task-plan: Architecture: Applying Architect Output

After receiving the architect's assessment:

1. Record the decision in `plan.md` `## Decisions` section:
   - The recommendation (Approve / Approve with modifications / Reject)
   - Any modifications required before implementation
   - Risks flagged and their mitigations
2. If architect **approves with modifications**: update the plan's implementation steps before dispatching to @coder.
3. If architect **rejects**: return to @planner with the architect's rationale and revise the approach.
4. If architect **approves**: proceed to implementation with the architectural guidance noted in `plan.md`.

## task-plan: Architecture: Relationship to Other Skills

- **`design-first`**: A user-invocable skill for starting an architectural
  change; no agent currently invokes it as part of this workflow.
- **`task-plan`**: Record all architecture decisions in `plan.md` via `task-plan`.
- **`task-plan-phase-implementation`**: Load after architecture approval when
  the primary work shifts to writing code.

**Does NOT cover:** investigation, implementation phase, testing phase, completion.
