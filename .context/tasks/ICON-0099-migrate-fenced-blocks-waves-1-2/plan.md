## Task: ICON-0099
## Branch: feature/ICON-0099-migrate-fenced-blocks-waves-1-2
## Objective: Migrate the remaining deterministic fenced code blocks under ADR-017 — wave 1 (the four `python3` heredocs in `plugin-design`, `icon-status`'s 9 blocks, `icon-audit`'s 1 block) and wave 2 (the ~11,000 B of cross-skill duplicated blocks, as one unit). Wave 1's first item is a live Windows bug: `python3` does not execute on a stock Windows box, so those `plugin-design` audit phases do not run there at all.
## Folder: .context/tasks/ICON-0099-migrate-fenced-blocks-waves-1-2/

GitHub issue: #59. Follows #23/#58 (ICON-0098), which settled ADR-017 and proved it on `icon-init`.

## Phase State
- **Phase plan**: investigation → implementation → testing → completion
- **Completed**: (none)
- **Current**: investigation   (status: in-progress)
- **Next**: implementation
- **Loaded skill**: task-plan-phase-investigation
- **Branch**: feature/ICON-0099-migrate-fenced-blocks-waves-1-2
- **Attempts (current phase)**: 1

## Decisions
- Scope taken verbatim from issue #59 (waves 1 and 2). `skills/upgrade-repo/SKILL.md` (#61) and the `.sh`/`.ps1` script files (#60) are explicitly OUT — they are separately ticketed and #61 is blocked on #42's split.
- Wave 2 migrates **as a whole set or not at all** (ADR-017 § Cross-skill duplication). A half-migrated copy-set is worse than either end state, and the set intersects the `.githooks/pre-commit` byte-parity check's population, which must be updated in the same commit.
- Phase plan includes a distinct **testing** phase because ICON-0098's retro (Rule 10, `shell-portability`) makes differential verification against the pre-migration implementation mandatory, not optional — porting by shape rather than semantics is the known failure mode for exactly this work.
- Size reduction is NOT an acceptance criterion (ADR-017 § Migration is not cap-evasion). A migrated `SKILL.md` may grow; reporting a byte reduction as the win means the record was applied incorrectly.

## Key Files
- `skills/plugin-design/audit-phase-structure.md`: one `python3` heredoc (~:42) — wave 1, bug fix
- `skills/plugin-design/audit-phase-consistency.md`: three `python3` heredocs (~:19, :53, :110) — wave 1, bug fix
- `skills/icon-status/SKILL.md`: 9 deterministic blocks — wave 1
- `.claude/skills/icon-audit/`: 1 deterministic block, maintainer-only — wave 1
- (wave 2 file set — to be enumerated in investigation)
- `.githooks/pre-commit`: byte-parity check population must gain any wave-2 copy-set
- `CHANGELOG.md`: `[Unreleased]` entry at close

## Phase Handoff Log

## Progress
- [ ] Investigation: enumerate and classify every candidate block in waves 1 and 2 against ADR-017's four tiers; identify wave 2's exact copy-set and its parity-check implications ← IN PROGRESS
- [ ] Update this plan with the investigation's classification table and per-site disposition before any edit
- [ ] Implementation: wave 1 (plugin-design bug fix first, then icon-status, then icon-audit)
- [ ] Implementation: wave 2 copy-set as one unit, incl. `.githooks/pre-commit` parity registration
- [ ] Testing: differential verification of each migrated site against its `git show HEAD:`-extracted original
- [ ] Completion: reconcile plan, @reviewer, changelog, retrospective, PR

## Open Questions / Blockers
- Wave 2's exact membership is not enumerated in the issue (only "~11,000 B of blocks copied across skills"). Investigation must produce the definitive copy-set before any of it is touched.
- Whether any wave-1 or wave-2 site trips an ADR-017 `.mjs` trigger (cross-fence state, mutation, ≥2 invocations, unavoidable `'`) versus staying inline `node -e` — decided per site in investigation, recorded here.
- Whether the migrated skills have an existing degradation path for Node-absent. ADR-017: *"If a skill has no such state, it is not ready to migrate."*

## Constraints
- ICON is pure-content: no build step, no test runner, no package manager (ADR-005). Committed, dependency-free scripts run in place ARE in scope.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- Any staged change under `context_template/` requires bumping `context_template/context/iconrc.json` `version` in the same commit (pre-commit invariant). Wave 1/2 scope is not expected to touch it; ADR-017 exclusion E1 excludes `context_template/` from migration entirely.
- `.mjs` scripts: ESM, `node:`-prefixed imports, never `require`, no shebang, standard library only. Detectors/validators fail **closed** (inverting the hooks' fail-open posture).
- Claude Code invocation fence is **untagged** (`node "${CLAUDE_SKILL_DIR}/scripts/<name>.mjs"`); the Copilot CLI fence is the only bash survivor. No PowerShell Copilot variant ships.
- The prose contract must survive migration — if a section shrinks to "run the script", the migration failed (ADR-017).
