<!-- template-version: 1.7 -->
# Completion Phase Templates

> Loaded by the `task-plan-phase-completion` skill when present.
> Customize delegation templates and the retrospective format for your team.

## Reconcile plan.md

> **First step of the completion phase. Runs before review, context-update, retrospective, and commit.** This is the single source of truth for plan.md reconciliation; other surfaces (`agents/manager.agent.md`, `skills/pr-discipline/SKILL.md`, `skills/task-retrospective/SKILL.md`) refer to this section by name rather than re-describing the checks.
>
> Reconciliation is gated, not encouraged. Author-discipline checks degrade quickly — a "remember to update plan.md" rule does not fire on the 30% of tasks where it matters most (the messy ones). Run the five sub-checks below before any review/PR/retro work; each should take under two minutes.

Re-read `plan.md` end-to-end against the actual final state, and update each section:

1. **Progress**: Check each Progress item against actual outcomes. Mark completed steps `[x]`; for any item that was deferred, split, or dropped, add a one-line outcome note (`— deferred to follow-up`, `— merged into step N`, `— dropped: reason`).
2. **Decisions**: Add any late decisions that were made during implementation but never recorded. Decisions written before the final approach was settled should be updated (or annotated as superseded) to match what was actually shipped.
3. **Key Files**: Update to match the actual diff. Add late-added paths; remove paths that were planned but never touched; note any path that was created and later deleted within the task.
4. **Open Questions**: Close out any questions that were resolved during implementation. Questions that remain open at task close should be converted to follow-up items (linked tickets or `.context/tasks/` follow-ups), not left open in the closing plan.
5. **Constraints**: Add any constraints discovered during implementation that aren't yet captured — schema requirements, ordering dependencies, platform-specific behavior, or quality gates the task uncovered.

The reconciled `plan.md` is the input the retrospective reads from. A stale plan corrupts the retro and misleads reviewers — both downstream steps presume reconciliation has happened.

## @reviewer Delegation Template

> Run @reviewer here ONLY if code changed since the plan.md `## Review Checkpoint`
> (see phase-implementation § Pre-Completion Review) — i.e. an @coder or @tester
> step ran after the checkpoint, or no checkpoint exists (fail-closed: if you
> cannot point to a checkpoint covering the current changed-file set, run the
> review). If the checkpoint already covers the current changed files, the review
> gate is satisfied — do not re-review.

```
Feature: [description]
Ticket: [TICKET-ID]
Changed files:
  - [path/to/file]: [what changed]
Relevant standards:
  - [.context/standards/code-style.md]
  - [.context/standards/naming-conventions.md]
Review focus:
  - [area of particular concern]
```

## Context Update Checklist

> Review after every task completion. Check each item.

- [ ] Domain files updated for changed behavior (`.context/domains/`)
- [ ] Architecture files updated for new patterns (`.context/architecture/`)
- [ ] Standards files updated for new conventions (`.context/standards/`)
- [ ] Testing files updated for new test patterns (`.context/testing/`)
- [ ] `decisions/` updated for architectural decisions
- [ ] `.claude/claude.md` updated ONLY for project-wide changes

## Retrospective Template

> Append via the `append-retrospective-entry` script — do not edit
> `retrospectives.md` by hand.

```markdown
### [TASK-ID]: [Short description]

- **Avoid**: [friction point or mistake encountered]
- **Repeat**: [approach or pattern to repeat]
- **Updated**: [file]: [what to add or change]
```

## Two-Stage Retrospective Handoff

> The retrospective ceremony is a two-stage flow. The manager runs Stage 1; @context-specialist runs Stage 2. Invoke `task-retrospective` for the full checklist — this section defines only the handoff mechanics.

**Stage 1 (manager)**: Answer Q1 (Avoid) and Q2 (Repeat) by reflecting on the task. Identify which `.context/` files need updating (Q3 planning). Draft the complete retrospective entry text, leaving an `[specialist to complete]` placeholder in the **Updated** field.

**Stage 2 (handoff to @context-specialist)**: Delegate to `@context-specialist` with `mode: maintenance`, providing the drafted entry text, the list of `.context/` files to update, and instructions to (i) run the `append-retrospective-entry` script from the `context-maintenance` skill's `scripts/` folder, (ii) replace the **Updated** placeholder with the actual files touched and the pruning result before the entry is inserted, and (iii) stage its writes with `git add` only — the manager owns the commit. Wait for the specialist's structured report (files modified, entries promoted, entries pruned), then record it in session state.

## Completion Summary Template

```markdown
## Completion Summary
**Accomplished:** [1–2 sentence description]
**Files changed:** [N files — list key ones]
**Tests:** [N added, all passing / N added, M failing — details]
**Follow-up work:** [technical debt or follow-up tasks, or "none"]
```
