<!-- template-version: 1.0 -->
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

## Decisions
- [Decision made]: [Rationale — why this approach over alternatives]

## Key Files
- [path/to/file]: [What it does or how it was changed]

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
