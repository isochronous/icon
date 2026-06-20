<!-- template-version: 1.6 -->
# Completion Phase Templates

> Loaded by the `task-plan-phase-completion` skill when present.
> These templates supersede the skill's built-in defaults for this repo.

## Reconcile plan.md

> **First step of the completion phase. Runs before review, context-update, retrospective, and commit.** This is the single source of truth for plan.md reconciliation; other surfaces (`agents/manager.agent.md`, `skills/mr-discipline/SKILL.md`, `skills/task-retrospective/SKILL.md`) refer to this section by name rather than re-describing the checks.
>
> Reconciliation is gated, not encouraged. Author-discipline checks degrade quickly — a "remember to update plan.md" rule does not fire on the 30% of tasks where it matters most (the messy ones). Run the five sub-checks below before any review/MR/retro work; each should take under two minutes.

Re-read `plan.md` end-to-end against the actual final state, and update each section:

1. **Progress**: Check each Progress item against actual outcomes. Mark completed steps `[x]`; for any item that was deferred, split, or dropped, add a one-line outcome note (`— deferred to follow-up`, `— merged into step N`, `— dropped: reason`).
2. **Decisions**: Add any late decisions that were made during implementation but never recorded. Decisions written before the final approach was settled should be updated (or annotated as superseded) to match what was actually shipped.
3. **Key Files**: Update to match the actual diff. Add late-added paths; remove paths that were planned but never touched; note any path that was created and later deleted within the task.
4. **Open Questions**: Close out any questions that were resolved during implementation. Questions that remain open at task close should be converted to follow-up items (linked tickets or `.context/tasks/` follow-ups), not left open in the closing plan.
5. **Constraints**: Add any constraints discovered during implementation that aren't yet captured — schema requirements, ordering dependencies, platform-specific behavior, or quality gates the task uncovered.

The reconciled `plan.md` is the input the retrospective reads from. A stale plan corrupts the retro and misleads reviewers — both downstream steps presume reconciliation has happened.

**Final-state edits need their own commit.** Some `plan.md` fields can only be filled *after* the task artifacts commit and push — the commit SHA and the MR number describe the commit, so they cannot live inside it. Editing `plan.md` to record them and then stopping leaves the branch with a dangling, uncommitted plan. Either:

- (a) finish the entire reconcile (Outcome, all checkboxes) **before** the artifacts commit and omit the commit SHA from `plan.md`, so the reconciled plan ships inside that commit; or
- (b) follow the post-commit `plan.md` edit with a small `ICON-NNNN: reconcile plan.md to final state` commit and push.

Do not leave the SHA/MR edit uncommitted on the branch.

## @reviewer Delegation Template

> Run @reviewer here ONLY if code changed since the plan.md `## Review Checkpoint`
> (see phase-implementation § Pre-Completion Review) — i.e. an @coder or @tester
> step ran after the checkpoint, or no checkpoint exists (fail-closed: if you
> cannot point to a checkpoint covering the current changed-file set, run the
> review). If the checkpoint already covers the current changed files, the review
> gate is satisfied — do not re-review.

```
Feature: [description]
Ticket: ICON-NNNN
Changed files:
  - [path/to/file]: [what changed]
Relevant standards:
  - .context/standards/skill-decomposition.md (if skills/agents touched)
  - .context/standards/changelog-discipline.md (if CHANGELOG.md touched)
  - .context/workflows/commit-conventions.md
  - .context/workflows/branching.md
Review focus:
  - [area of particular concern — e.g., thin-router boundary, dispatcher-prompt variable convention, common-constraints byte-equality, MCP credential placeholders]
```

## Update CHANGELOG [Unreleased]

> **Runs after `@reviewer` delegation and before commit.** At task close, add or update an entry in the `## [Unreleased]` block at the top of `CHANGELOG.md` (repo root) summarizing the user-visible or maintainer-visible change this task introduces.

For the full procedure — including how to decide between internal vs user-facing tone, and how to write each entry — invoke the `changelog-entry` skill (`.claude/skills/changelog-entry/SKILL.md`). For form rules (one sentence per entry, no block-level formatting, ticket IDs at end), see `.context/standards/changelog-discipline.md`.

**Cumulative-effect rule (summary):** If this task's change relates to a subject already described in an existing `[Unreleased]` entry, edit or remove that existing entry to reflect the new end state — do not append a second entry covering the same subject. See the `changelog-entry` skill for worked examples.

**Legitimate skip:** Purely internal tasks — refactors, hygiene, changes with no user-visible or maintainer-visible behavior change and no on-disk file change consumers would see — may produce no CHANGELOG entry. The `changelog-entry` skill's procedure decides.

## Context Update Checklist

> Review after every task completion. Check each item that applies — items
> referencing excluded directories (`architecture/`, `testing/`, `styling/`)
> are intentionally absent.

- [ ] Domain files updated for changed behavior (`.context/domains/skill-system.md`, `mcp-servers.md`, `plugin-resource-paths.md`)
- [ ] Standards files updated for new conventions (`.context/standards/skill-decomposition.md`, `changelog-discipline.md`)
- [ ] Workflow files updated for process changes (`.context/workflows/`)
- [ ] `decisions/` updated with a new ADR file for project-wide architectural decisions, and `decisions/README.md` log row added (never delete or rewrite past ADRs — supersede instead)
- [ ] `retrospectives.md` appended via `append-retrospective-entry` script (never hand-edited)
- [ ] `overview.md` or `META.md` updated if the repo's high-level shape or directory structure changed
- [ ] `.claude/claude.md` updated ONLY for project-wide changes that every consumer of the repo needs to know

## Retrospective Template

> Append via the `append-retrospective-entry` script — do not edit
> `retrospectives.md` by hand.

```markdown
### ICON-NNNN: [Short description]

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
**Validation:** [structural checks performed, runtime smoke checks run — paste key output]
**Follow-up work:** [technical debt, deferred items, or "none"]
**Release impact:** [CHANGELOG.md `[Unreleased]` entry added / N/A]
```
