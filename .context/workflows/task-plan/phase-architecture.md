<!-- template-version: 1.1 -->
# Architecture Phase Templates

> Loaded by the `task-plan-phase-architecture` skill when present.
> These templates supersede the skill's built-in defaults for this repo.

## Additional Architecture Review Triggers

> ICON has no compiled application architecture, but the plugin still has
> structural decisions that warrant an architecture pass. These supplement
> the standard decision matrix in the phase skill.

- Changes to **agent definitions** — new agent, removed agent, altered routing relationship, or changes to the verbatim-injected `shared/common-constraints.md` block (affects all nine agents simultaneously).
- Changes that **add a new skill family or reshape an existing one** — restructuring the `task-plan-phase-*` skills, the `context-specialist-*` internals, or the `initialize-*` family triggers a thin-router / decomposition review per `.context/standards/skill-decomposition.md`.
- Changes to **`context_template/`** — the template tree is what `/icon-init` copies into target projects, so any change ships to every newly-initialized consumer repo.
- Changes to **`.claude-plugin/plugin.json` schema** (not version bumps) or **`.mcp.json` server registry** — the manifest is the version SSOT and the MCP registry shapes credential and tool-loading behavior across all consumers.
- Changes to **hooks/** — `SessionStart` `inject-manager-role.mjs` (wired by `hooks/hooks.json`) runs in every consumer repo; any behavior change is cross-cutting. See `.context/domains/hooks.md` for the plugin-scope vs user-scope wiring rules.
- Changes to a **slash command's contract** — the namespaced `ICON:` slash commands are the user-facing API surface; renaming, splitting, or merging commands warrants a routing review.

## @architect Delegation Template

```
Change proposed: [description of what the plan calls for]
Architecture context:
  - [key fact from .context/standards/skill-decomposition.md — name the section]
  - [key fact from .context/domains/skill-system.md or domains/mcp-servers.md]
  - [key constraint from .context/decisions/ — name the ADR (e.g., ADR-002 main-only branching)]
Specific questions:
  - [question about thin-router boundaries, dispatcher-prompt variable convention, or agent/skill role overlap]
  - [question about cross-cutting impact: does this change ripple through context_template/, all agents, or every consumer repo?]
Constraints:
  - ICON is pure-content (no build step) — proposals must not require a compile/test pipeline.
  - Credentials use placeholders in committed files (`<TOKEN>`) per ADR-006 — never commit real secrets.
  - [other hard requirement from the user or .context/decisions/]
Ticket: ICON-NNNN
```

## Architecture Decision Capture

> Paste this block into plan.md when recording an architecture decision made
> during this phase. If the decision is durable and project-wide, also promote
> it to `.context/decisions/` as a new ADR.

```markdown
### Architecture Decision — [short title]
**Date:** [YYYY-MM-DD]
**Decision:** [Approve / Approve with modifications / Reject]
**Rationale:** [why]
**Modifications required:** [if any, or "none"]
**Risks flagged:** [if any, or "none"]
**Promote to ADR?:** [yes — ADR-NNN drafted / no — task-scoped only]
```
