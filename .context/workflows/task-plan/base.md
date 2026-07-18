<!-- template-version: 1.2 -->
# Plan Document Format

> The `task-plan` skill reads this file to determine the required `plan.md`
> format for this repository. This template supersedes the skill's built-in
> default when present.
>
> The core sections (Task, Branch, Objective, Folder, Decisions, Key Files,
> Progress, Open Questions/Blockers, Constraints) are required — agents depend
> on these exact headings to parse the plan. Repo-specific sections may be
> added after Constraints if a task needs them.
>
> `Phase State` and `Phase Handoff Log` are additive phase-handoff sections
> (see ADR-013 / the session-per-phase design). They carry the cross-session
> cold-resume state; they supplement — never replace — the required core
> sections above.

## Template

```markdown
## Task: ICON-NNNN
## Branch: feature/ICON-NNNN-short-description
## Objective: [What we're accomplishing and why]
## Folder: .context/tasks/ICON-NNNN-short-description/

## Phase State
- **Phase plan**: investigation → architecture → implementation → testing → completion
- **Completed**: investigation, architecture
- **Current**: implementation   (status: in-progress | done | blocked | pending)
- **Next**: testing
- **Loaded skill**: task-plan-phase-implementation
- **Branch**: feature/ICON-NNNN-slug
- **Attempts (current phase)**: 1

## Decisions
- [Decision made]: [Rationale — why this approach over alternatives, naming the relevant ADR or standard if applicable]

## Key Files
- [path/to/file]: [What it does or how it was changed]

## Phase Handoff Log

### Handoff: architecture → implementation   (commit: <trailer-marked>)
**Sub-agent outputs**:
- @architect assessment: [verbatim recommendation + rationale, or a faithful quote of the load-bearing parts — not a lossy one-line summary]
**Reviewer findings**: [each finding + resolution status, or "N/A this phase"]
**Verification evidence**: [structural checks run + pass/fail; runtime smoke transcript snippets — the actual output, copied, not "passed"]
**Decisions delta**: [decisions made this phase — also mirrored into ## Decisions]
**Key files delta**: [files touched this phase — also mirrored into ## Key Files]
**What the next phase needs**: [the warmstart synthesis, written down instead of re-derived from memory: entry inputs the next phase must have]
**Retro Stage-1 draft** (completion-phase block only): [Avoid / Repeat / Updated draft, persisted here instead of "in session state"]

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
- **Phase State** — The lean, machine-parsable pointer a cold session (or a phase launcher) reads to resume without scanning the whole plan. Written when the task is created (the manager records the per-task **Phase plan** — an ordered subsequence of `investigation → architecture → implementation → testing → completion`, with `completion` always last) and updated at every phase boundary: advance `Completed`/`Current`/`Next`, set the `Current` status, record the `Loaded skill`, and reset `Attempts` to `0` for the new phase. **Attempts ownership**: this field counts how many times the current phase has been *launched*. In automated single-shot / cron launches the **phase launcher owns the counter** — it increments and commits `Attempts` before each launch, so a persistently failing phase is bounded even when its session fails closed and commits nothing; a successful phase exit resets it to `0`. (An in-process launcher bounds retries with its own in-process counter and treats persisted `Attempts` as a secondary guard; an interactive single-session run need not maintain it.) `Branch` is the integrity anchor — no commit SHA is stored here (a commit cannot contain its own SHA); the branch tip IS the state. Keep this section lean so it can be parsed cheaply.
- **Phase Handoff Log** — Append-only. Append exactly one `###` block per phase as that phase completes, capturing the heavy state that would otherwise live only in session memory: verbatim sub-agent outputs, reviewer findings + resolution, verification evidence (copied output, not "passed"), the Decisions/Key Files deltas (also mirrored into their sections), and **What the next phase needs** (the warmstart the following phase reconstructs from). The completion-phase block additionally carries the **Retro Stage-1 draft**. Never rewrite or prune earlier blocks — each is the durable record of a boundary. Phase boundaries are commit points: the boundary commit that includes the new handoff block (plus the Phase State update and all source/artifact deltas) carries a `Phase-Handoff: <phase>` trailer (e.g. `Phase-Handoff: implementation`), which phase entry verifies on `HEAD`. Uncommitted work at a boundary means an incomplete handoff — the next phase fails closed.
- **Decisions** — Record every non-obvious choice and the reason for it. Future agents should not re-litigate decided questions. If you chose A over B, say why. Reference the relevant ADR (`ADR-NNN`) or standards file when the choice is constrained by one.
- **Key Files** — List every file touched or about to be touched. A resuming agent should be able to orient in the codebase from this list alone. For ICON tasks, this typically spans `agents/`, `skills/`, `commands/`, `hooks/`, `shared/`, `context_template/`, `.claude-plugin/plugin.json`, `.mcp.json`, and `CHANGELOG.md`.
- **Progress** — Check off steps as they complete. Add a brief outcome note — not just ✓ but what the result was. Mark exactly one step as `← IN PROGRESS` at any time.
- **Open Questions / Blockers** — Ambiguities, risks, or things the next agent needs to decide. Do not carry these only in memory.
- **Constraints** — ICON-wide constraints (pure-content, version SSOT, credential placeholders) should be listed when relevant. Add task-specific constraints (backwards-compatibility requirements with already-released plugin versions, MCP server registry shape, etc.) as they surface.
