## Task: ICON-0092
## Branch: feature/ICON-0092-remove-ecological-impact
## Objective: Remove the `ecological-impact` skill from the plugin, per maintainer triage of the ICON-0089 audit. Repairing it was the alternative; removal was chosen instead.
## Folder: .context/tasks/ICON-0092-remove-ecological-impact/

## Phase State
- **Phase plan**: implementation → completion
- **Completed**: —
- **Current**: implementation   (status: in-progress)
- **Next**: completion
- **Loaded skill**: task-plan-phase-implementation
- **Branch**: feature/ICON-0092-remove-ecological-impact
- **Attempts (current phase)**: 1

## Decisions
- **Removal rather than repair — maintainer's call at triage.** The ICON-0089 audit's finding M-U-1 was that `skills/ecological-impact/SKILL.md:210-227`'s worked example disagreed with its own formulas by **1000×**, was internally inconsistent on milliTrees, carried a ~6.6×-wrong car equivalent, and had a headline rate ~**57× its own cited source**. Four consecutive audits read that block without checking the arithmetic. Removal costs less than repair and eliminates a whole class of unverifiable numeric claims.
- **Branched off `feature/ICON-0091-amend-adr-005`, not `main`.** Both tasks add a bullet to the same `## [Unreleased]` CHANGELOG block; stacking avoids a near-certain conflict on adjacent lines. ICON-0091 must merge first. Rebase onto `main` after it lands.
- **`context_template/context/workflows/commit-conventions.md:37,102,125` deliberately NOT edited.** All three hits are the same historical commit-message *example* — `feat: add ecological-impact and start-worktree skills (1.5.0)` — illustrating the release-commit format. It is accurate history and remains a valid format example after the skill is gone. Editing `context_template/` would additionally force a template-schema version bump (`.githooks/pre-commit` enforces it), propagating a no-op change to every consumer running `/upgrade-repo`. Not worth it.
- **Historical records left intact**: `.context/retrospectives.md`, `.context/standards/skill-decomposition/verify-design-claims-against-artifacts.md`, and existing `CHANGELOG.md` entries mention the skill as past fact. Records describe what happened; they are not stale merely because the subject was later removed.

## Key Files
- `skills/ecological-impact/` — **delete** (`SKILL.md`, `formulas-reference.md`).
- `README.md:162` — remove the skills-table row. Load-bearing: `.githooks/pre-commit` O-V1 gate ties `skills/<name>/` to a README row.
- `CHEATSHEET.md:203` — remove the `/ecological-impact` row.
- `.claude/skills/icon-audit/briefs/04-utility-skills.md:5` — remove from the domain-04 investigation list so future audits don't hunt for a skill that no longer exists.
- `CHANGELOG.md` — one `### Removed` bullet under `## [Unreleased]`.
- `.claude-plugin/plugin.json` — verify whether it enumerates skills explicitly; update only if it does.

## Progress
- [x] Survey references — 7 files mention the skill outside its own directory; 3 need edits, 4 are correctly left alone
- [x] Deleted the skill (`git rm -r`, 2 files) and updated the 3 reference sites + CHANGELOG `### Removed` (sub-heading created; it did not exist)
- [x] Verified: `context-graph --check` green (49 nodes), `check-rules-index` green, manifest parses at 2.0.0 unchanged. `grep -ril ecological` returns only historical records, each justified. No command or agent routed to the skill; `.claude-plugin/plugin.json` does not enumerate skills, so it needed no edit.
- [ ] Rebase onto the corrected ICON-0091 once its review fixes land ← IN PROGRESS
- [ ] @reviewer, retrospective, PR

## Open Questions / Blockers
- **Consumer impact**: this removes a user-invocable skill. Anyone invoking `/ecological-impact` loses it at the next `latest` move. That is a user-facing removal and should be reflected in release-note tone whenever the next release is cut — **not** in this task (release guard).

## Constraints
- ICON is pure-content (ADR-005) — verification is the structural checkers plus `.githooks/pre-commit`.
- **Release guard**: no `.claude-plugin/plugin.json` version bump, no `[Unreleased]` rename, no tag, no `latest` move.
- `context_template/` untouched — see Decisions. No template-schema bump owed.
- Do not act on any other ICON-0089 finding; the remaining dispositions are with the maintainer.
