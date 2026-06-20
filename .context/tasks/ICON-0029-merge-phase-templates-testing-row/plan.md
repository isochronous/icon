## Task: ICON-0029
## Branch: feature/ICON-0029-merge-phase-templates-testing-row
## Objective: Close M-I-A (GitLab #14) — `skills/merge-phase-templates/SKILL.md` Step 2 routing table is missing a `phase-testing.md` row. Testing-related custom content from a deprecated `task-workflow-template.md` is currently routed to `phase-completion.md` by the catch-all row, conflating testing and completion. Fix: add a 5th row for `phase-testing.md` and narrow the `phase-completion.md` row to its proper scope.
## Folder: .context/tasks/ICON-0029-merge-phase-templates-testing-row/

## Decisions
- **Match the existing table's style.** Issue body suggests exact replacement headers/prose but also notes "(Exact column headers and prose to follow the existing table's style.)" The current table uses `| Custom content describes | Route to |` headers and prose with `@-references` (e.g., "@researcher / @planner work"). Keep that style; do not adopt the issue's draft headers verbatim.
- **Insert the new row between Implementation and the existing Testing/Completion catch-all.** Phase order matches the 6-file canonical phase set in `context-specialist-impl-leaf/SKILL.md`: investigation → architecture → implementation → testing → completion → (base).
- **Narrow the catch-all row** so testing-related categories (Testing, @tester) leave that row and live in the new phase-testing row.

## Key Files
- `skills/merge-phase-templates/SKILL.md` — Step 2 routing table (currently 5 rows). After: 6 rows (investigation, architecture, implementation, **testing (new)**, completion (narrowed), base).
- `CHANGELOG.md` — `[Unreleased]` entry under `### Fixed` (this IS a shipped skill — affects every `upgrade-repo` run against a customized old-format template).

## Progress
- [x] Branch + task folder created, plan.md drafted
- [x] @coder dispatched (Sonnet) — table row split into 6 rows; acceptance checks all passed
- [x] @reviewer (Sonnet) — flagged one Moderate at the "Routing Ambiguity Examples" table on line 81 (still missed `phase-testing` as a candidate destination). Fixed: ambiguity row now lists `phase-implementation, phase-testing, or phase-completion`.
- [x] CHANGELOG.md `[Unreleased]` entry under `### Fixed`
- [x] task-retrospective — manager drafted Q1+Q2 (same-file downstream sweep / single-pass reviewer); @context-specialist staged retro entry (15-cap reached, ICON-0001 pruned), no `.context/` promotions
- [ ] Commit, push, open MR closing #14 ← IN PROGRESS

## Open Questions / Blockers
- None.

## Constraints
- ICON is pure-content; verification is grep + reading.
- Acceptance: `grep -c 'phase-testing.md' skills/merge-phase-templates/SKILL.md` returns ≥ 1; `grep -n 'Testing, code review, retrospective, completion' skills/merge-phase-templates/SKILL.md` returns 0 (the old catch-all wording is gone).
