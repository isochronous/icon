<!-- template-version: 1.1 -->
# Plan Document Format

> The `task-plan` skill reads this file to determine the required `plan.md`
> format for this repository. This template supersedes the skill's built-in
> default when present.
>
> The core sections (Task, Branch, Objective, Folder, Decisions, Key Files,
> Progress, Open Questions/Blockers, Constraints) are required — agents depend
> on these exact headings to parse the plan. Repo-specific sections may be
> added after Constraints if a task needs them.

## Template

```markdown
## Task: ICON-NNNN
## Branch: feature/ICON-NNNN-short-description
## Objective: [What we're accomplishing and why]
## Folder: .context/tasks/ICON-NNNN-short-description/

## Decisions
- [Decision made]: [Rationale — why this approach over alternatives, naming the relevant ADR or standard if applicable]

## Key Files
- [path/to/file]: [What it does or how it was changed]

## Progress
- [x] Completed step — [brief outcome or note]
- [ ] Current step ← IN PROGRESS
- [ ] Upcoming step

## Open Questions / Blockers
- [Anything the next agent or developer needs to resolve or be aware of]

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- [Additional constraints from user, context, or discovered during work]
```

## Section Guidance

- **Task / Branch / Folder** — Use the ICON-NNNN four-digit zero-padded format. Branch and folder names share the short-description slug.
- **Objective** — One or two sentences. Lead with the user-visible outcome, then the motivation. Avoid implementation details — those belong in Decisions and Progress.
- **Decisions** — Record every non-obvious choice and the reason for it. Future agents should not re-litigate decided questions. If you chose A over B, say why. Reference the relevant ADR (`ADR-NNN`) or standards file when the choice is constrained by one.
- **Key Files** — List every file touched or about to be touched. A resuming agent should be able to orient in the codebase from this list alone. For ICON tasks, this typically spans `agents/`, `skills/`, `commands/`, `hooks/`, `shared/`, `context_template/`, `.claude-plugin/plugin.json`, `.mcp.json`, and `CHANGELOG.md`.
- **Progress** — Check off steps as they complete. Add a brief outcome note — not just ✓ but what the result was. Mark exactly one step as `← IN PROGRESS` at any time.
- **Open Questions / Blockers** — Ambiguities, risks, or things the next agent needs to decide. Do not carry these only in memory.
- **Constraints** — ICON-wide constraints (pure-content, version SSOT, credential placeholders) should be listed when relevant. Add task-specific constraints (backwards-compatibility requirements with already-released plugin versions, MCP server registry shape, etc.) as they surface.
