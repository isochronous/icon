## Task: ICON-0062
## Branch: feature/ICON-0062-release-aware-gate-clear-reinject
## Objective: Two user-directed infra follow-ups from this session: (1) make the ICON-0044 template-version pre-commit gate release-aware so stacked same-release commits don't force redundant template bumps (the cause of the ICON-0059/0060 double-bump); (2) make the SessionStart manager-role hook re-inject after /clear (the matcher currently omits `clear`).
## Folder: .context/tasks/ICON-0062-release-aware-gate-clear-reinject/

## Decisions
- Stacked on `feature/ICON-0061-sessionstart-hook-bootstrap` (continues the ordered stack !42→!43→!44→this). MR targets the ICON-0061 branch; auto-retargets to main as earlier MRs merge.
- Gate baseline = template iconrc version at `git merge-base HEAD <default_branch>` (the release baseline since this branch diverged from main). Error only if the staged version EQUALS the baseline (cycle hasn't bumped yet); if it already differs, the bump is present in this branch's history → allow without re-bump. This fixes the stacked case without weakening the "you forgot to bump entirely" protection.
- Robust fallback: if merge-base / default branch / baseline version can't be resolved, fall back to the existing HEAD-comparison behavior — never weaker than today when uncertain.
- /clear: add `clear` to the SessionStart matcher token; the hook injects regardless of source, so no per-source logic needed. Bootstrap text already injected-fresh-each-time is accurate; no persistence claim needed.

## Key Files
- `.githooks/pre-commit` (ICON-0044 gate block, ~lines 57–116): change the version-comparison baseline from HEAD to merge-base-with-default-branch. (repo-internal → no CHANGELOG.)
- `hooks/hooks.json` (SessionStart matcher): `startup|resume` → `startup|resume|clear`. (consumer-shipped → CHANGELOG.)
- `hooks/inject-manager-role.mjs` (header comment): ensure it accurately states the hook re-fires on /clear (reference only; behavior unchanged).
- `CHANGELOG.md` `[Unreleased]`: one bullet for the /clear re-injection (consumer behavior change). Gate change = no entry (internal `.githooks/`).

## Progress
- [x] Establish task: branch off ICON-0061 (stacked) + folder + plan.md
- [x] @coder A: release-aware gate — baseline = version at `git merge-base HEAD <default_branch>` (tries main → origin/main → master, else HEAD-fallback). Verified: stacked already-bumped passes; staged==baseline blocks; bump-only passes; all fallback paths route to HEAD-comparison (never weaker); clean tree exit 0.
- [x] @coder B: /clear matcher in hooks.json → `startup|resume|clear`; hook header comment updated; `clear` confirmed valid SessionStart source; JSON valid; hook still emits bootstrap
- [x] @reviewer: APPROVED — 0 Critical, 0 Moderate, 3 Minor (naming clarity, grep spacing assumption, master-fallback scope — all safe, no action). Reviewer built a throwaway repo and proved every failure path falls back to HEAD-comparison.
- [x] CHANGELOG: /clear bullet (ICON-0062) under ### Fixed; gate change = no entry (.githooks internal)
- [ ] Promote "one template bump per release" + release-aware-gate behavior to `.context/` (specialist places per context-document-guidelines; from a wrongly-placed personal memory per user direction) ← at retro stage
- [ ] Reconcile plan; retrospective (manager draft → @context-specialist insert) ← IN PROGRESS
- [x] Committed (e3e3843, c30c08d, 18d39bb), pushed; MR !46 → https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/merge_requests/46 (targets ICON-0061 branch)

## Outcome
- Gate is now branch-divergence-aware: stacked same-release branches share a merge-base and ride one template bump; a branch cut from an already-advanced main still bumps. Fixes the ICON-0059/0060 redundant double-bump. Fallback to HEAD-comparison whenever the baseline can't be resolved (never weaker).
- SessionStart hook re-injects the manager role on /clear (matcher now startup|resume|clear).

## Open Questions / Blockers
- Confirm `clear` (and possibly `compact`) is the correct SessionStart source matcher token in Claude Code — the hook's own header comment references source "clear", strong signal it's valid; coder to confirm.

## Constraints
- ICON is pure-content (ADR-005); `.githooks/pre-commit` (bash) and `hooks/*.mjs` (node) are runnable → verify by execution.
- Do NOT weaken any existing pre-commit gate; the release-aware change must still block a template change that was never bumped this cycle.
- `.claude-plugin/plugin.json` is the version SSOT (ADR-003) — untouched.
