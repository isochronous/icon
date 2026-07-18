---
name: task-plan-phase-completion
description: >
  Internal task-plan phase skill. Do not invoke without explicit direction.
user-invocable: false
---

# Phase: Completion

Load this skill after the primary concern skill's work is done — for any task
type. It covers the universal closing steps: code review, context updates,
retrospective, and completion summary. **Keep this skill minimal** — it loads at
the end of every task; token cost matters.

**Template-override rule**: apply `.context/workflows/task-plan/phase-<name>.md` if present — see `task-plan` for the full policy.

## task-plan: Completion: Phase Entry (Reconstruct-First)

**Run this FIRST, before any completion work.** Each phase resumes from the
committed `plan.md`, not session memory. Read `## Phase State`, confirm this run's
phase matches `Current`/`Next` and every earlier phase is `done` (`completion` is
always last), then read the preceding handoff block plus the cumulative
`## Decisions` / `## Key Files` / `## Constraints`. Validate this phase's entry
contract (verification evidence + a `## Review Checkpoint` covering the current
changed files) and **fail closed** — if a required input is missing, a
prerequisite phase is not `done`, `HEAD` lacks the expected `Phase-Handoff:`
trailer, or the tree is unexpectedly dirty, STOP and surface the gap; do not
re-derive to backfill. Full protocol and entry contract: `phase-completion.md`
`## Phase Entry`; `## Phase State` / `## Phase Handoff Log` shapes: `base.md`
Section Guidance.

## task-plan: Completion: Reconcile plan.md

> **First step of the completion phase. Runs before review, context-update,
> retrospective, and commit.** Reconciliation is gated, not encouraged.
> Author-discipline checks degrade quickly — a "remember to update plan.md" rule
> does not fire on the 30% of tasks where it matters most (the messy ones). Run
> the five sub-checks below before any review/PR/retro work; each should take
> under two minutes.

Re-read `plan.md` end-to-end against the actual final state, and update each section:

1. **Progress**: Check each item against actual outcomes. Mark completed steps `[x]`; for any deferred, split, or dropped item, add a one-line outcome note (`— deferred to follow-up`, `— merged into step N`, `— dropped: reason`).
2. **Decisions**: Add any late decisions made during implementation but never recorded. Decisions written before the final approach settled should be updated (or annotated as superseded) to match what shipped.
3. **Key Files**: Update to match the actual diff. Add late-added paths; remove paths planned but never touched; note any path created and later deleted within the task.
4. **Open Questions**: Close out any resolved during implementation. Questions still open at task close should become follow-up items (linked tickets or `.context/tasks/` follow-ups), not left open in the closing plan.
5. **Constraints**: Add any discovered during implementation that aren't yet captured — schema requirements, ordering dependencies, platform-specific behavior, or quality gates the task uncovered.

The reconciled `plan.md` is what the retrospective reads from. A stale plan corrupts the retro and misleads reviewers — both downstream steps presume reconciliation has happened.

## task-plan: Completion: @reviewer Delegation Structure

Run @reviewer here ONLY if code changed since the plan.md `## Review Checkpoint`
(see `task-plan-phase-implementation` § Pre-Completion Review) — i.e. an @coder or
@tester step ran after the checkpoint, or no checkpoint exists (fail-closed: if
you cannot point to a checkpoint covering the current changed-file set, run the
review). If the checkpoint already covers the current changed files, the review
gate is satisfied — do not re-review.

```
Feature: [description]
All changed files:
  - [path/to/file]: [what changed]
Relevant standards: [.context/standards/ references]
Review focus: [specific concern — security boundary, performance path, etc.]
```

Address all critical and moderate findings. Document minor findings in
`plan.md` `## Open Questions / Blockers` for follow-up.

## task-plan: Completion: Context Update Checklist

After review and before closing the task, assess each item:

- [ ] **Domain files**: Did this task reveal new behavior, entities, or rules in any domain? If yes, update `.context/domains/[domain].md`.
- [ ] **Architecture files**: Did this task introduce or change a pattern? If yes, update `.context/architecture/patterns-template.md`.
- [ ] **Standards files**: Did this task establish a new convention? If yes, update the appropriate `.context/standards/` file.
- [ ] **Testing files**: Did this task reveal a new testing pattern? If yes, update `.context/testing/`.
- [ ] **decisions/**: Did this task make a significant architectural decision not yet recorded? If yes, add it.
- [ ] **`.claude/claude.md`** (or `.github/copilot-instructions.md` on repos still on the legacy path): Update ONLY for project-wide changes (new tech stack items, key command changes, high-level convention shifts). Do NOT add area-specific detail here.

For all context updates — broad or narrow — delegate to **@context-specialist** with `mode: maintenance`. See [`./agent-vs-skill-invocation.md`](./agent-vs-skill-invocation.md) for the SSOT.

## task-plan: Completion: Retrospective

**Ordering**: Inside the completion phase, the retrospective runs after the
review and context-update steps above and before the Completion Summary below.
`task-retrospective` is invoked from within phase-completion, not as a separate
phase after it.

Invoke the `task-retrospective` skill for the full process.

At minimum, answer these three questions:

1. What mistake or friction did we encounter that we should avoid next time?
2. What pattern or approach worked well that we should repeat?
3. What should be updated in `.context/` based on this experience?

Record findings in `.context/retrospectives.md` (rolling log; keeps the most recent 10 entries — enforced by the append script's `ENTRY_CAP`). Promote each lesson to the appropriate `.context/` subdirectory. The ceremony is driven by the `task-retrospective` skill — manager drafts Q1+Q2, dispatches `@context-specialist` (`mode: maintenance`) to insert the entry and apply context updates.

## task-plan: Completion: Two-Stage Retrospective Handoff

The retrospective is a two-stage flow. **Stage 1 (manager)**: answer Q1 (Avoid) and Q2 (Repeat), identify the `.context/` files to update, and draft the complete entry text with an `[specialist to complete]` placeholder in the **Updated** field. **Stage 2 (@context-specialist, `mode: maintenance`)**: delegate the drafted text and file list, instructing it to (i) run the `append-retrospective-entry` script, (ii) replace the **Updated** placeholder with the actual files touched and pruning result, and (iii) stage its writes with `git add` only — the manager owns the commit. The manager waits for the specialist's structured report and records it in session state.

## task-plan: Completion: Completion Summary

Write a brief completion summary:

```markdown
## Completion Summary
**Accomplished:** [1–2 sentences]
**Files changed:** [count and key paths]
**Tests:** [count added, pass/fail status]
**Follow-up work:** [technical debt or follow-up tasks, or "none"]
```

## task-plan: Completion: Phase Exit (Handoff Write)

**Run this LAST — completion is the final phase; its exit closes the task.**
Append one `### Handoff: completion` block to `## Phase Handoff Log` (append-only
— never rewrite earlier blocks) capturing the reviewer findings + resolution, the
final verification evidence, the Decisions/Key Files deltas, and — unique to this
block — the **Retro Stage-1 draft** (Avoid / Repeat / Updated) persisted here
instead of held in session state. Update `## Phase State`: move completion to
`Completed`, set its status `done`, set `Next` to none / task complete. Since a
commit cannot contain its own SHA, do not embed the handoff SHA in `plan.md` —
either finish the Reconcile plan.md checklist before the artifacts commit
(omitting the SHA), or follow it with a small `ICON-NNNN: reconcile plan.md to
final state` commit; carry the `Phase-Handoff: completion` trailer on the boundary commit. Full
write/commit steps: `phase-completion.md` `## Phase Exit / Handoff`; block shape:
`base.md` Section Guidance and `context-document-guidelines`.

## task-plan: Completion: Relationship to Other Skills

- **`task-retrospective`**: Invoke for the full retrospective process.
- **`@context-specialist` (mode: maintenance)**: Delegate all `.context/` writes — broad or narrow. See [`./agent-vs-skill-invocation.md`](./agent-vs-skill-invocation.md). (Direct `context-maintenance` invocation is reserved for the specialist itself; the manager does not invoke it.)
- **`commit-discipline`**: Invoke for the final commit of completion docs, retro
  entries, and context updates.
- **`task-plan-phase-testing`**: If testing was not yet done, load that skill
  before running completion.

**Does NOT cover:** investigation, architecture review, implementation phase,
testing phase.
