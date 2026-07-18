---
name: task-plan
description: >
  Use when creating or updating a task plan.md file. Applies to medium and complex tasks where plan.md is the authoritative handoff record.
user-invocable: false
---

# Task Plan

`plan.md` is a handoff document, not a progress tracker. It must contain enough context for a different person or agent on a different machine to resume the task cold — without access to conversation history.

## Format Selection

Before using the format below, check in this order:

1. **`.context/workflows/task-plan/base.md`** — if it exists, use it. This is the team's customized plan template; it supersedes the built-in format.
2. **Built-in format below** — only if `base.md` is absent.

## Phase Skills (On-Demand)

For medium and complex tasks, phase skills provide structured guidance for the
task's primary concern. The manager identifies the concern at task start and
loads ONE matching skill — not all skills in sequence.

| Primary concern | Skill | When to load |
|-----------------|-------|--------------|
| Scope unclear; research needed | `task-plan-phase-investigation` | Task scope undefined; approach unknown |
| Primary work is structural decisions | `task-plan-phase-architecture` | Architecture question is the key work |
| Primary work is writing code | `task-plan-phase-implementation` | Path is clear; ready to dispatch @coder |
| Primary work is tests | `task-plan-phase-testing` | Fixing tests, adding coverage, TDD |
| Closing any task | `task-plan-phase-completion` | After primary work is done |

Phase skills are `user-invocable: false`. They are invoked by the manager agent,
not by users directly.

For simple tasks, use the plan format below directly without invoking any phase
skills.

## task-plan: Phase Plan & Phase-Per-Session Model

Medium and complex tasks record a **per-task phase plan** in `plan.md`
`## Phase State`: an ordered **subsequence** of the canonical five phases
(`investigation → architecture → implementation → testing → completion`), with
`completion` always last. A pure refactor might be
`[implementation, testing, completion]`; an investigation-heavy task uses all
five. The manager writes the phase plan when the task is created; it changes only
on an explicit re-open (re-mark the target phase `pending` and re-append it — an
explicit, recorded edit, not an implicit jump).

Each phase can run in its own **fresh session**. This is opt-in and
launcher-driven: a phase launcher reads the lean `## Phase State` pointer, runs
the next `pending` phase in a fresh session via the entrypoint, then stops. A
human driving **interactively** still runs phases back-to-back in one session —
but **always writes the `## Phase Handoff Log` block + `## Phase State` update at
each boundary**, so the hardened, resumable artifact is produced universally.

Every phase resumes **reconstruct-first**: its opening step reads `## Phase State`
+ the preceding handoff and validates a fail-closed entry contract before doing
any work; its closing step writes the handoff block, updates Phase State, and
commits with a `Phase-Handoff: <phase>` trailer. This skill is a router — the
`## Phase State` / `## Phase Handoff Log` shape and Section Guidance live in
`.context/workflows/task-plan/base.md`; the per-phase entry contract and
write/commit steps live in each phase's `phase-<name>.md` template and its
`task-plan-phase-<name>` skill.

## task-plan: Template-Override Rule

If the repo has a local `.context/workflows/task-plan/phase-<name>.md`
(for any phase: `phase-investigation`, `phase-architecture`,
`phase-implementation`, `phase-testing`, `phase-completion`), read and
apply it — the local file supersedes the guidance in the corresponding
phase skill (including any triggers, delegation templates, checklists,
decision-capture blocks, or status-tracking tables defined in the skill).
Repos customize these templates to match team conventions. This rule
applies to every section in every phase skill; individual sections do not
restate it.

## Built-in Format (Fallback)

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

## Investigation-First Plans

Plans do not need to be fully formed at creation. For bugs and investigation-heavy tasks where the root cause is unknown, a two-step plan is valid and correct:

```markdown
## Progress
- [ ] Investigate: [describe the symptom] ← IN PROGRESS
- [ ] Update this plan with findings and next steps from investigation
```

Do not defer creating the task folder and `plan.md` until the investigation is complete. Create it immediately with these two steps, then revise it once you know what you're dealing with. The second step is a standing commitment: after investigation, the plan gets updated before any fix work begins.

## task-plan: When to Update

- Create before any work begins — do not start implementing without it
- Update **Decisions** the moment a choice is made
- Update **Progress** as each step completes
- Update **Open Questions** when a new ambiguity or blocker is discovered
- Update **Key Files** as files are identified or changed
