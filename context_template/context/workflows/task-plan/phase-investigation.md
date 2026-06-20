<!-- template-version: 1.0 -->
# Investigation Phase Templates

> Loaded by the `task-plan-phase-investigation` skill when present.
> Customize the templates below for your team's workflow. Replace placeholder
> text with your actual ticket format, agent names, and project-specific
> context files.

## Additional Context Files

> Add project-specific files that agents should read during investigation,
> in addition to the standard checklist in the phase skill.

- <!-- example: .context/architecture/api-conventions.md -->
- <!-- example: .context/domains/[your-key-domain].md -->

## @researcher Delegation Template

```
Topic: [specific library/framework/technology]
Current version: [X.Y.Z] → Target version: [A.B.C]
Ticket: [TICKET-ID]
Questions:
  - [Question 1]
  - [Question 2]
Decision this research will inform: [what choice depends on findings]
Constraints:
  - [relevant constraint]
```

## @planner Delegation Template

```
Task: [TICKET-ID] — [brief title]
Objective: [what we're accomplishing and why]
Affected modules: [list]
Complexity: Simple / Medium / Complex
Context:
  - [key constraint from .context/decisions/]
  - [relevant pattern from .context/architecture/]
Research findings: [summary or "N/A"]
Open questions for planner:
  - [anything still ambiguous]
```
