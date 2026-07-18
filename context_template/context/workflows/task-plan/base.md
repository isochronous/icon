<!-- template-version: 1.1 -->
<!-- orphan-ok rationale: scaffold stub read programmatically by the task-plan skill, not linked from a knowledge doc. A populated repo indexes it via rules-index. -->
<!-- context-graph:orphan-ok -->
# Plan Document Format

> Customize the template below for your team's workflow. The `task-plan` skill
> reads this file to determine the required `plan.md` format for this repository.
>
> Keep the core sections (Task, Branch, Objective, Folder, Decisions, Key Files,
> Progress, Open Questions/Blockers, Constraints) — agents depend on these
> headings. Add team-specific sections after Constraints.

## Template

```markdown
## Task: [TASK-ID]
## Branch: [BRANCH-NAME]
## Objective: [What we're accomplishing and why]
## Folder: .context/tasks/[TASK-ID-short-description]/

## Phase State
- **Phase plan**: investigation → architecture → implementation → testing → completion
- **Completed**: investigation, architecture
- **Current**: implementation   (status: in-progress | done | blocked | pending)
- **Next**: testing
- **Loaded skill**: task-plan-phase-implementation
- **Branch**: [BRANCH-NAME]
- **Attempts (current phase)**: 1

## Decisions
- [Decision made]: [Rationale — why this approach over alternatives]

## Key Files
- [path/to/file]: [What it does or how it was changed]

## Phase Handoff Log

### Handoff: architecture → implementation   (commit: <trailer-marked>)
**Sub-agent outputs**:
- [sub-agent] assessment: [verbatim recommendation + rationale, or a faithful quote of the load-bearing parts — not a lossy one-line summary]
**Reviewer findings**: [each finding + resolution status, or "N/A this phase"]
**Verification evidence**: [checks run + pass/fail; smoke/test output — the actual output, copied, not "passed"]
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
[Key constraints from user, context, or discovered during work]
```

## Section Guidance

- **Phase State** — The lean pointer a cold session (or a phase launcher) reads
  to resume without scanning the whole plan. Written when the task is created —
  the manager records the per-task **Phase plan**, an ordered subsequence of
  `investigation → architecture → implementation → testing → completion`
  (`completion` always last) — and updated at every phase boundary: advance
  `Completed`/`Current`/`Next`, set the `Current` status, record the loaded
  skill, and reset `Attempts` to `0`. **Attempts ownership**: this counts how
  many times the current phase has been *launched*. In automated single-shot /
  cron launches the **phase launcher owns the counter** — it increments and
  commits `Attempts` before each launch, so a persistently failing phase is
  bounded even when its session fails closed and commits nothing; a successful
  phase exit resets it to `0`. (In-process launchers use their own counter and
  treat persisted `Attempts` as a secondary guard; interactive runs need not
  maintain it.) `Branch` is the integrity anchor; do not store a commit SHA here
  (the branch tip is the state). Keep it lean and parsable.
- **Phase Handoff Log** — Append-only, one `###` block per phase as it completes.
  Capture the state that would otherwise live only in session memory: verbatim
  sub-agent outputs, reviewer findings + resolution, verification evidence
  (copied output, not "passed"), the Decisions/Key Files deltas (also mirrored
  into their sections), and **What the next phase needs** (the warmstart the
  following phase reconstructs from). The completion block also carries the
  Retro Stage-1 draft. Never rewrite or prune earlier blocks. Phase boundaries
  are commit points: the boundary commit carries a `Phase-Handoff: <phase>`
  trailer that phase entry verifies. Uncommitted work at a boundary means an
  incomplete handoff.
- **Decisions** — Record every non-obvious choice and the reason for it.
  Future agents should not re-litigate decided questions. If you chose A over B,
  say why.
- **Key Files** — List every file touched or about to be touched. A resuming
  agent should be able to orient in the codebase from this list alone.
- **Progress** — Check off steps as they complete. Add a brief outcome note —
  not just ✓ but what the result was.
- **Open Questions / Blockers** — Ambiguities, risks, or things the next agent
  needs to decide. Do not carry these only in memory.
- **Constraints** — API limitations, backwards-compatibility requirements, user
  constraints discovered mid-task.
