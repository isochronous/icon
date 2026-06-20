## Task: ICON-0077
## Branch: feature/ICON-0077-impl-branch-verify-step
## Objective: Add a Verify step to `context-specialist-impl-branch` (parity with `impl-leaf` Step 5 / `impl-root` Step 15) so a branch-node `.context/` generation that completes with missing/placeholder content is caught before commit. Closes #44 (carry-forward from ICON-0071/#36; original audit IO-02/IO-58-02).

## Folder: .context/tasks/ICON-0077-impl-branch-verify-step/

## Decisions
- **Model on impl-root's verify, NOT impl-leaf's**: a branch node is a *lighter root* — it generates `overview.md`, `projects.md`, conditional `decisions/`, conditional `architecture/patterns.md`, conditional `domains/`, plus template `META.md`/`.gitignore`. It does NOT generate domain files with real class names, standards files, hooks, `claude.md`, `rules-index.md`, `iconrc.json`, or `retrospectives.md` — so leaf's "real class name / real code snippet" checks and the hook/`.gitattributes`/rules-index/task-plan checks DO NOT apply and must be excluded.
- **Conditional items use impl-root's "exists (or explicitly omitted with reason)" pattern** for the optionally-generated files (decisions/, architecture/patterns.md, domains/).
- **Placement**: insert `## context-specialist-impl-branch: Step 9: Verify` after the current item 8 (Generate domain files) and renumber the existing Commit to Step 10 (matching the skill-name-prefixed `##` heading convention used by impl-leaf/impl-root).
- **dead-ref gate**: any reference to a conditionally-present path (e.g. `architecture/patterns.md`) should use the `<!-- pre-commit:dead-ref-ok-start/end -->` guards exactly as impl-root's verify does (impl-root guards its `architecture/patterns.md` line) — this is the established, correct use of the marker (a conditionally-existing template path), distinct from the ICON-0076 case (a permanent live-doc ref, which should be by-name).
- **No `context_template/` change** (impl-branch is standalone, not templated) → no iconrc bump. impl-branch already has its README row (O-V1 passes).

## Key Files
- `skills/context-specialist-impl-branch/SKILL.md`: CHANGE — add the Verify step (per the spec below) before Commit; renumber Commit to Step 10.
- `CHANGELOG.md`: CHANGE — `[Unreleased]` entry (consumer-shipped skill).

## Verify-step content (from Explore; adapt wording to the skill's voice)
Heading `## context-specialist-impl-branch: Step 9: Verify`, then "Confirm all expected files are present and non-empty:":
1. `.context/META.md` exists (copied from template, not recreated).
2. `.context/.gitignore` exists (copied from template, not recreated).
3. `.context/overview.md` exists and contains the sub-project table with ≥1 real sub-project row.
4. `.context/projects.md` exists and lists every sub-project discovered in Step 1.
5. decisions/ — if cross-project decisions found: `decisions/` has `README.md` + ≥1 ADR; else confirm intentionally omitted (note reason).
6. architecture/patterns.md — if 2+ sub-projects share patterns: exists with real content; else confirm intentionally omitted. (dead-ref-guard this path ref.)
7. domains/ — if cross-cutting concepts exist: ≥1 `domains/<domain>.md`; else confirm intentionally omitted.
Close with the "**Flag any gaps**" paragraph (mirror impl-leaf/impl-root wording).

## Progress
- [x] Create branch + task folder + initial plan.md
- [x] Read-only Explore — impl-leaf Step 5, impl-root Step 15, impl-branch current 9-step structure (ends at Commit, no verify), what a branch node generates, gates (findings in Decisions)
- [x] @coder applies the verify step — Step 9 Verify (7 branch-appropriate checks) + renumbered Commit; dead-ref guard on generated paths; hook green
- [x] @reviewer checkpoint — APPROVE-WITH-FIXES, 0 Critical; checklist correct for a branch node (no leaf-only checks), conditional "exists-or-omitted" pattern correct. Moderate fix applied: the new steps had used `##` headings while Process is a flat list (my spec error) → restructured Verify/Commit to flat list items 9/10 inside `## Process`. dead-ref guard narrowed (META.md/.gitignore are templated → outside guard). Minor (commit-message example) left — impl-branch's commit line is sufficient.
- [x] changelog-entry — done by coder (### Added, ICON-0077)
- [x] Reconcile plan.md
- [x] Retrospective (two-stage) — entry inserted (ICON-0067 pruned → archived); promoted dead-ref-marker correct-vs-wrong-use clarifier to writing-skills
- [x] Commit + push + open MR — MR !61 opened (label carry-forward, remove_source_branch)
- [ ] PAUSE — awaiting user go-ahead to merge !61 → delete branch → next item (#45)

## Review Checkpoint
@reviewer APPROVED the diff (impl-branch Verify step + CHANGELOG), APPROVE-WITH-FIXES, 0 Critical — verified the checklist is branch-appropriate (mirrors impl-root, excludes leaf-only checks) and the dead-ref guard use is legitimate (generated output paths). The post-checkpoint edits were the two reviewer-requested fixes (restructure to flat list to match the skill's own format; narrow the dead-ref guard) — re-verified hook green — so this covers the complete changed-file set.

## Open Questions / Blockers
- None. Spec is fully determined by the impl-root template.

## Constraints
- ICON pure-content (ADR-005); verification = grep for the new step + pre-commit green (dead-ref / placeholder / O-V1 gates; secret-scan/shellcheck N/A — markdown only).
- `.claude-plugin/plugin.json` SSOT — do NOT bump.
