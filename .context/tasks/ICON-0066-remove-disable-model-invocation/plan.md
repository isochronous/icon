## Task: ICON-0066
## Branch: feature/ICON-0066-remove-disable-model-invocation
## Objective: Internal ICON skills marked `disable-model-invocation: true` cannot be invoked by Claude even when an agent definition explicitly instructs it to. Remove the `disable-model-invocation` property from those internal/orchestration skills so agents can invoke them. Genuinely user-only slash-command skills must keep the property.

## Folder: .context/tasks/ICON-0066-remove-disable-model-invocation/

## Decisions
- Scope split — internal vs user-only: Skills meant to be invoked BY agents/orchestrators (internal phase skills, routing guides, context-specialist sub-skills, etc.) must lose `disable-model-invocation`. Skills that are user-only slash commands (`/ICON:manager`, `/ICON:pm`, `enable-manager-default`, `disable-manager-default`) must KEEP it — auto-invoking those mid-session would be wrong. Boundary to be confirmed after enumeration.

## Key Files
- skills/initialize-multimodule/SKILL.md: `disable-model-invocation: true` line REMOVED; `user-invocable: false` retained.
- skills/initialize-monorepo/SKILL.md: `disable-model-invocation: true` line REMOVED; `user-invocable: false` retained.
- skills/initialize-workspace/SKILL.md: `disable-model-invocation: true` line REMOVED; `user-invocable: false` retained.
- CHANGELOG.md: added `### Fixed` entry under `[Unreleased]` (ICON-0066).

## Progress
- [x] Investigate: enumerate + classify every skill setting `disable-model-invocation` — Explore agent grepped all *.md recursively: 5 hits. Only 3 set `true` (the three initialize-* skills, all `user-invocable: false`, dispatched by /icon-init → currently invocable by no one = the bug). `.claude/skills/release-plugin` and `changelog-entry` set it to `false` (no-op). Zero ambiguous, zero under context_template/.
- [x] Update plan with classified list — scope is the 3 initialize-* files; no user-only skill has `true`, so no boundary question needed.
- [x] Remove `disable-model-invocation: true` line from the 3 initialize-* SKILL.md files (@coder) — done; manager verified diff: exactly one line removed per file, `user-invocable: false` retained, `grep` shows 0 matches in skills/.
- [x] @reviewer over the diff (pre-completion Review Checkpoint) — **Approved**, 0 critical/moderate. See Review Checkpoint below.
- [x] Changelog entry (`### Fixed`) + lint (`.githooks/pre-commit` exit 0, clean) + verification-checklist — all done; evidence captured. No test framework (ICON pure-content, ADR-005); verification = grep 0-matches + frontmatter validity + reviewer semantics + clean gate.
- [x] Retrospective (two-stage) — entry inserted (pruned oldest: ICON-0056); lesson promoted to `.context/domains/skill-system.md`.
- [x] Commit all artifacts (2 commits: 43f6297 fix, 9f4e19a close) + push + open MR
- [x] MR opened: !50 — https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/merge_requests/50

## Review Checkpoint
- Reviewer: @reviewer (ICON:reviewer.agent), verdict **Approved**. Covers the full changed-file set (the 3 `initialize-*` SKILL.md edits). No @coder/@tester step has run since — so this checkpoint satisfies the close-gate review requirement; no re-run needed at close unless code changes after this point.
- Independently confirmed: completeness (only those 3 skills had `true`; the two `.claude/skills/` hits are `false` no-ops, correctly untouched), frontmatter validity, semantics (`user-invocable: false` + absent property ⇒ model can invoke, user cannot), and that `README.md:196-199` and `skills/icon-init/SKILL.md:14` docs are NOT stale.
- Minor notes (non-blocking): plan Key-Files line numbers are historical pre-fix state; changelog entry pending (next step).

## Scope Addition (user-directed, post-MR-!50)
The prune-context pre-commit hook deletes `.context/cache/.gitkeep` on every commit, misclassifying the directory-keeper as a stale cache file. User explicitly directed folding the fix into THIS branch despite it being a separate concern (accepts the scope mix). Goal: make the prune logic ignore `.gitkeep` (or dir-keeper files) so it is never pruned.

## Added Progress
- [x] Investigate fix surface — Explore mapped it: prune loop identical in both `prune-context.sh` copies (lines 64–85); bug is `find -maxdepth 1 -type f` (line 79) including `.gitkeep`, which has an old ICON-0001 commit ts → exceeds 30-day cutoff → pruned. Invoked from `.githooks/post-commit` (not pre-commit). Template gate: editing `context_template/` requires bumping `context_template/context/iconrc.json` 1.5→1.6 (release-aware vs merge-base with main), staged with the script. No prune test harness exists. Copies differ ONLY in `INTEGRATION_BRANCHES` — must stay differentiated.
- [x] @coder: dotfile-skip guard added in BOTH `prune-context.sh` copies (line 65); `context_template/context/iconrc.json` bumped 1.5→1.6. Scratch-repo proof: `.gitkeep` survives, stale `stale.md` still pruned. Manager verified diff; cross-copy diff shows only `INTEGRATION_BRANCHES` differs.
- [x] @reviewer — **Approved**, 0 critical/moderate. Verified basename-on-absolute-paths, two-copy consistency, gate passes (1.5→1.6 vs merge-base baseline 1.5), task-prune section iterates dirs (no guard needed), ADR-003 plugin.json is a separate SSOT (no bump here). Note: stage iconrc.json with the script in one commit.
- [x] Changelog (`### Fixed` second bullet) added; durable hook-authoring note promoted to `.context/domains/hooks.md` (@context-specialist).
- [ ] Commit (scripts + iconrc + changelog + hooks.md note + plan, staged together for the gate) + push (updates MR !50) ← IN PROGRESS

## Decisions (added)
- Fix breadth: skip ANY dotfile in the cache prune (`[[ "$(basename "$file")" == .* ]] && continue`), not just `.gitkeep` — no legitimate cache file is a dotfile, and this future-proofs `.keep`/`.placeholder` dir-keepers. Idiomatic and minimal.
- Folded into ICON-0066 branch/MR !50 at user's explicit direction despite being a separate concern (user accepted the scope mix).

## Open Questions / Blockers
- (resolved for original scope) context_template/ had no SKILL.md → original disable-model-invocation change did not trip the template-version gate. The hook fix DOES touch context_template/ → bump required.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- Template-version bump required if any `context_template/` file changes — ICON-0062 release-aware pre-commit gate.
- Do not alter `user-invocable` semantics; only `disable-model-invocation` is in scope.
