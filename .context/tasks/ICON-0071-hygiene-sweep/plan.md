## Task: ICON-0071
## Branch: feature/ICON-0071-hygiene-sweep
## Objective: Implement GitLab work item #36 (ICON-0058 audit, Tier 3 — low-risk hygiene, batch-fixable): a sweep of ~6 small findings plus optional carry-forwards. Each is a one-to-few-line edit. INCLUDES m16 — the release-side root cause of the template-version drift surfaced during ICON-0070 — which should be expanded beyond the narrow doc-sweep note to actually let releases consolidate the template iconrc version.
## Folder: .context/tasks/ICON-0071-hygiene-sweep/

## Decisions
- Local task ID **ICON-0071** (next free; #36 carries no pre-baked ID). References #36.
- **Stale-ticket discipline**: the ticket is from 2026-06-10; line numbers are audit-time and this session heavily edited CHANGELOG/manager/etc. Re-verify EVERY finding's current state before fixing (per `.context/workflows/task-start-conventions.md`). Some may be already-resolved or shifted (esp. m17 CHANGELOG — ICON-0070 just added a `### Changed` heading; m5 cap literal).
- **m16 expansion**: ICON-0070 surfaced that the per-MR template-iconrc bump accumulates because (a) the pre-commit gate compares against the `main` merge-base not the last release tag, and (b) `release-plugin` has ZERO template-version handling. The audit's m16 only names the Step-1 doc-sweep cross-check; expand to give release-plugin a consolidation/cross-check step so the drift is actually fixable at release. @architect to scope.

## Findings to re-verify + fix (current-state unknown — confirm first)
- **m5** — stale `15`→`10` retrospective-cap literal: `skills/upgrade-repo/SKILL.md` (~:616), `context_template/context/retrospectives.md` (~:1), and the three `append-retrospective-entry.sh` copies (script `ENTRY_CAP=10` already correct). NOTE: ICON-0060 already fixed some of these — re-verify which (if any) literals remain at 15.
- **m7** — phantom "plugin-lint Check A/B" labels (3 sites: `skills/icon-init/SKILL.md` ~:225,245; `skills/icon-status/SKILL.md` ~:214) → replace with real `shared/common-constraints.md § Shell command self-check` citations.
- **m15** — `.mcp.json` lacks `$schema` (:1) → add ONLY if a hosted MCP-config schema actually exists (else note N/A).
- **m16** — `release-plugin` omits the `context_template/iconrc.json` version handling (`.claude/skills/release-plugin/SKILL.md` ~:65). Expand per above.
- **m17** — duplicate `### Changed` heading in CHANGELOG (`[1.19.0]`/`[Unreleased]`, ~:25,29) → consolidate; add a dedup guard to `release-plugin` Step 5. RE-VERIFY: the [Unreleased] block changed a lot this session.
- **O-D2** — README hook-install reminder (`git config core.hooksPath .githooks`), currently only in `CONTRIBUTING.md`.
- **Carry-forwards (optional, bandwidth-permitting or split out)**: m6 (`upgrade-repo` ~:124 diff stderr suppression — ADR-007), `impl-branch` verify gap, multimodule root-context asymmetry.

## Re-verification (read-only Explore) + dispositions
- **m5** (cap 15→10): ✅ RESOLVED by ICON-0060 — all `.sh`/`.ps1` scripts (`ENTRY_CAP=10`), `upgrade-repo` (:623 "10th"), `context_template/context/retrospectives.md` (:1 "10th") correct. No action.
- **m15** (.mcp.json `$schema`): **N/A** — cached research (`.context/cache/claude-code-plugin-mcp-schemas-2026-05-23.md`) confirms no hosted MCP-config schema URL exists (schemastore 404s; gleanwork npm-only). Recommendation on record: skip. No action.
- **m17** (dup `### Changed`): ✅ RESOLVED — CHANGELOG clean today (no block has two same headings). But the **preventive dedup guard** for `release-plugin` Step 5 (O-V4) was never added → fold into the m16 release-plugin work.
- **m7** (phantom "plugin-lint Check A/B"): ⚠️ STILL OPEN — `skills/icon-init/SKILL.md:225` (Check B), `:245` (Check A); `skills/icon-status/SKILL.md:214` (Check B). Target valid: `shared/common-constraints.md` "**Shell command self-check**" bullet. Trivial → @coder.
- **O-D2** (README hook-install): ⚠️ STILL OPEN for `README.md` (no `core.hooksPath`); `CONTRIBUTING.md:50` has it. Trivial → @coder.
- **m16** (release-plugin iconrc): ⚠️ STILL OPEN — `.claude/skills/release-plugin/SKILL.md` has ZERO iconrc/template-version handling (Step 1 doc-sweep covers only README/claude.md/commands; Step 5 has no dedup). Structural → @architect. The drift root cause from ICON-0070. Released model = released+1 per cycle; main drifted then consolidated to 1.6. Fix approach (Explore-recommended): add a release-time consolidate/verify step (template iconrc on main = last-release-tag version + 1; reset if drifted higher — the gate allows it since a release commit compares against its own merge-base).
- **m6** (upgrade-repo:124 `>/dev/null 2>&1`, ADR-007): STILL OPEN but **previously user-accepted as will-not-do** (ICON-0048) → **SKIP** (respect prior decision; note in plan).
- **Carry-forwards** (impl-branch verify gap; multimodule root-context asymmetry): genuine but small-structural, not blocking → **SPLIT to a follow-up task** (per the ticket's own "or split them out" + Explore rec).

## IN SCOPE for ICON-0071: m7 + O-D2 (trivial, @coder) · m16 + m17-dedup-guard (structural, @architect→@coder). OUT: m5/m15/m17-dup (resolved/N/A), m6 (will-not-do), carry-forwards (split).

## Progress
- [x] Confirm next free ID (0071), create branch + folder + plan.md
- [x] Read-only re-verification — dispositions above (3 resolved/N/A, m7+O-D2+m16+m17-guard open, m6 skip, carry-forwards split)
- [x] @architect designed m16 (consolidate-at-release: new release-plugin Step 6 reads last-release-tag template version, resets if drifted to released+1; reuses Step 2's `$LAST_RELEASE_SHA`) + m17 dedup guard (Step 5 awk check). Maintainer-only, no context_template touch, no iconrc bump.
- [x] @coder applied m7 (3 sites: output-suppression → cites `common-constraints § Shell command self-check`; 2 presence-test sites rephrased inline since `${VAR+x}` convention is undocumented — minor gap flagged) + O-D2 (README `## Contributing` with `core.hooksPath`); separate @coder applied m16 + m17-guard + step renumbering (1..11 reconciled). All staged, hook EXIT 0.
- [x] @reviewer checkpoint over the full diff — **APPROVED w/ comments**, 0 critical / 0 moderate; both minor items APPLIED (Step 6 rationale corrected to cite the gate's equality-only block; awk increment hardened to fail loudly on non-`MAJOR.MINOR`). See `## Review Checkpoint`.
- [x] changelog-entry — terse one-line `### Fixed` (m7 plugin-lint cleanup); O-D2/m16/m17 internal/maintainer → omitted from consumer changelog
- [x] reconcile plan.md; task-retrospective (entry inserted, cap pruned ICON-0061; nothing to promote — lessons already covered)
- [x] Commit `f244581` (pre-commit EXIT 0); push; open MR — **!55** (https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/merge_requests/55), targets `main`, Closes #36
- [x] Close-gate verification (Checkpoint 1 scope) — all 5 PASS

### ROOT-CAUSE FOLLOW-ON (user-directed, after #36's m16 shipped as symptom-fix)
- [x] @architect designed the gate-baseline fix (release-tag → merge-base → HEAD 3-tier; equality condition preserved); release-plugin Step 6 demoted to verify; branching.md updated
- [x] @coder applied across `.githooks/pre-commit` + `release-plugin/SKILL.md` + `branching.md`; full scenario matrix passed in scratch repos (1st-MR-FAIL, 2nd-MR-PASS cross-MR fix, stacked, Tier-2/3 fallbacks, `bash -u`); equality block byte-unchanged; real-tree hook EXIT 0
- [x] @reviewer Checkpoint 2 — **APPROVED, 0 findings at every severity** (re-run after a session-limit interrupted the first attempt); independent scratch scenarios incl. the decisive 2b cross-MR case
- [x] reconcile plan; amend retro (root-cause + gate-scenario-test lessons); commit `91f2fa3`; push; close-gate PASS
- [x] **latest-tag simplification (user-directed)**: @architect (safety proof: never weaker) → @coder (unify gate + release-plugin onto `latest`, retire `git describe`/`$LAST_RELEASE_SHA`; 8-scenario scratch matrix) → @reviewer Checkpoint 3 APPROVED (0 findings + 1 cosmetic nit) → commit `823c234`; push; re-run close-gate — all 5 PASS (0 live git describe, 0 LAST_RELEASE_SHA, latest-tag baseline + guard, equality block intact, steps 1–11, bash -n clean, hook EXIT 0). MR !55 to update next.

## Close-Gate (non-skippable, 5 items) — RE-RUN after the root-cause gate fix
1. **@reviewer covered every code change** — ✅ Checkpoint 1 (m7/O-D2/m17 + m16-consolidation) + Checkpoint 2 (the gate-baseline root-cause fix, which supersedes m16-consolidation) together cover the full current changed-file set; both approved, Checkpoint 2 = 0 findings.
2. **Project lint ran / output shown** — ✅ N/A pure-content (ADR-005); pre-commit hook EXIT 0 + `bash -n` clean.
3. **Code changes covered by tests** — ✅ N/A per `testing-discipline` (no-test repo); the load-bearing hook change was scenario-tested in scratch repos (6+ scenarios + `bash -u`), evidence in Checkpoint 2.
4. **verification-checklist passed** — ✅ re-run at close over the gate fix; Gates 1–4 pass with fresh output (describe-baseline + equality-check present, Step 6 reset gone, steps 1–11, branching.md updated, bash -n clean, hook EXIT 0).
5. **commit/MR format match discovered conventions** — ✅ `commit-conventions.md` Pattern 1; MR !55 title matches.

## m16 ROOT-CAUSE pivot (user-directed): fix the gate, not the symptom
The shipped m16 (release-time consolidation) treats the symptom. **Root cause**: the ICON-0044 gate's baseline = `git merge-base HEAD main`'s version, failing only on equality — so each merged MR advances main's version, the next MR inherits it as merge-base, and is forced to re-bump → per-MR accumulation. ICON-0062 chose merge-base deliberately but only to fix STACKED COMMITS on one branch (ICON-0059/0060 double-bump); it didn't anticipate the cross-MR case.
**Fix**: change the gate baseline to **the last release tag's** template iconrc version. Then the 1st template-touching MR of a cycle bumps (released→released+1) and every later MR passes unchanged (≠ released) → one bump per release automatically; nothing to consolidate. Preserves the "forgot-to-bump entirely" protection (1st MR: staged==released → FAIL). Keep ICON-0062's fallback chain: last-release-tag unresolvable → merge-base → HEAD (never weaker). Strictly improves on ICON-0062 (handles stacked AND cross-MR).
**Consequence**: release-plugin Step 6 (consolidation/reset) becomes unnecessary → **demote to a lightweight verify** (confirm template version == released+1; flag if not) to avoid re-renumbering and keep a cheap safety check. m17 dedup guard unaffected.
**Re-review (Checkpoint 2) required** — reopens implementation after Checkpoint 1; load-bearing hook change → scenario-test hard (1st-MR-must-bump, 2nd-MR-no-bump, stacked-commit, no-tag fallback).

## Simplification (user-directed): key off the `latest` tag, not computed last-release
**User point**: rely on the already-maintained `latest` tag instead of computing "last release" two different ways. Facts: `latest` is force-moved every release (release-plugin Step 9 `git tag -f latest`); it's the marketplace's canonical `ref`; today the gate uses `git describe --tags` and release-plugin Step 2 greps commit msgs for `(X.Y.Z)` — two mechanisms for one thing.
**Reachability reconciliation**: @architect rejected *global-newest tag-sort* (Checkpoint 2) over unmerged/out-of-order side-branch tags — but ADR-002 main-only means no such side branches. `latest` == nearest reachable release for any branch cut from main. Only divergence = a branch open ACROSS a release; even then the gate fails SAFE (equality → "bump", never a false pass). Net: `latest` is simpler, already-maintained, and the consumer-facing source of truth.
**Decision**: unify both the gate (Tier-1 baseline = `git show latest:…iconrc`) and release-plugin (drop the Step-2 commit-grep / `$LAST_RELEASE_SHA` in favor of `latest`) onto the `latest` tag. Keep the never-weaker fallback chain (latest unresolved → merge-base → HEAD). @architect to design; **Checkpoint 3 re-review** (load-bearing, reopens implementation).
- **@architect**: APPROVED with explicit safety proof — `latest` is never weaker than `git describe` (gate errors only on equality → worst case spurious bump, never false PASS); confirmed Step 9 moves `latest` AFTER Steps 2–8 so `latest`==previous-release throughout the flow. 3-tier fallback preserved.
- **@coder**: applied verbatim across `.githooks/pre-commit` (Tier-1 → `latest`), `release-plugin/SKILL.md` (retired `$LAST_RELEASE_SHA`), `branching.md`. 8-scenario scratch matrix all pass incl. #3 mid-flight fail-safe (spurious FAIL, no false PASS), #4/#5 fallback tiers, `bash -u` safe; equality block byte-identical. Two grep-acceptance counts intentionally off — spec's NEW prose keeps *historical* `git describe` reference + a comment mention of the `rev-parse` guard; zero LIVE `git describe` usage (verified).

## Review Checkpoint 3 (latest-tag baseline unification — re-review after the simplification reopened)
- **Reviewer**: @reviewer, `code-quality-rules`. **Verdict: Approved — 0 critical / 0 moderate / 0 minor / 1 cosmetic nit (no action).** Covers the 3 files (gate Tier-1 → `latest`, release-plugin `$LAST_RELEASE_SHA` retired, branching.md).
- **Verified (independent scratch scenarios)**: NO false-PASS possible (gate errors only on equality → wrong baseline ⇒ spurious bump, never lets unbumped content through); equality block **byte-identical** to HEAD; 3-tier fallthrough never-empty (Tier-1 sets only on `rev-parse`+version success → Tier-2 merge-base → Tier-3 HEAD); `set -u` safe (`_latest_ver` never read-before-assign); `>/dev/null` on `rev-parse --verify --quiet` discards stdout SHA not stderr (not ADR-007 regression); `$LAST_RELEASE_SHA` fully retired (grep=0); Step 2 ordering claim correct (Step 9 moves `latest` after Step 2); Step 6 verify-only; steps 1..11; Step 5 untouched; branching.md's only `git describe` is the historical supersession note; scope = 3 files+plan, no context_template/iconrc/plugin.json/CHANGELOG; `bash -n` clean, real-tree hook EXIT 0.

## Review Checkpoint 2 (m16 root-cause: release-tag gate baseline — superseded by the latest-tag unification in Checkpoint 3 above)
- **Reviewer**: @reviewer (ICON:reviewer.agent), `code-quality-rules`. **Verdict: Approved — 0 critical / 0 moderate / 0 minor / 0 nit.** (First attempt was interrupted by a session limit before output; re-run completed.) Covers the 3 gate-fix files (`.githooks/pre-commit` baseline block, `release-plugin` Step 6 demote, `branching.md` cadence section).
- **Verified (independent scratch-repo scenarios)**: Tier-1 release-tag baseline reachability-correct; **equality fail-condition byte-identical** to HEAD; 3-tier fallthrough correct (each tier sets `_compare_ver` only on success, Tier-3 always sets it; never empty → never skips gate); **decisive cross-MR fix (scenario 2b: merge-base=1.6 staged=1.6 tag=v1.5 → PASS** where old merge-base baseline FAILED); forgot-to-bump preserved (1st-MR staged==released → FAIL); Tier-2/3 fallbacks intact (labels `merge-base`/`HEAD`); `set -u` safe (Tier-2 vars confined); no new `2>/dev/null` (all 4 match the block's git-probe convention); Step 6 reset language gone (`grep -i "reset it to"`=0), steps 1..11, Step 5 untouched; branching.md accurate + ICON-0071 attribution; scope = 3 files+plan, no context_template/iconrc/plugin.json/CHANGELOG; `bash -n` clean, real-tree hook EXIT 0.

## Review Checkpoint 1 (initial m7/O-D2/m16-consolidation/m17 — m16 consolidation SUPERSEDED by the root-cause gate fix above)
- **Reviewer**: @reviewer (ICON:reviewer.agent), `code-quality-rules`. **Verdict: Approved.** Covers the full diff (m7 ×3 sites, O-D2 README, m16 release-plugin Step 6 + renumbering, m17 dedup guard) + the two applied minor fixes. No @coder/@tester step after the fixes change behavior → satisfies close-gate review.
- **Findings**: 0 critical, 0 moderate. 2 minor — BOTH applied: (1) Step 6 "reset is safe" rationale corrected (gate blocks on equality, not non-increase — verified against `.githooks/pre-commit:167`); (2) awk increment now self-enforces `NF==2` (fails loudly on multi-segment). m7 presence-test inline rephrasing confirmed accurate (no invented tool).
- **Verified (independent)**: step headings contiguous 1..11 with all 14 cross-refs reconciled (stepwise-renumber hazard checked hard); `$LAST_RELEASE_SHA` reused correctly (Step 2 defines, Step 6 after); awk increment correct for MAJOR.MINOR; conditional `git add` is a proper no-op when unchanged; m17 awk resets `seen` per `## [` block and prints nothing on clean CHANGELOG; zero `plugin-lint` refs remain; scope = 4 files (+plan), no context_template/plugin.json/CHANGELOG touch, no iconrc bump; pre-commit EXIT 0.

## Open Questions / Blockers
- m16 scope: just the doc-sweep cross-check, or also make release-plugin actually CONSOLIDATE the template version (e.g. set it to released+1, or compare against the last release tag)? The latter is the real drift fix. @architect to recommend without over-scoping a hygiene task.
- Carry-forwards: include m6/impl-branch/multimodule, or split to a separate ticket? Decide after sizing.

## Constraints
- ICON pure-content (no build/test/lint) — ADR-005. Verification = grep + pre-commit hook.
- **rules-index freshness (ICON-0069)**: no new top-level `standards/`/`workflows/`/`decisions/` file expected; if one is added it needs a row.
- **template-version gate (ICON-0044)**: m5/O-D2 may touch `context_template/` (retrospectives.md) → would require a `context_template/context/iconrc.json` bump. Released template version is **1.5**, main now **1.6** (consolidated in ICON-0070). If this task touches `context_template/`, set iconrc to keep the single-release-bump model (stay 1.6 if gate allows ≠ merge-base, else next) — and this is exactly the m16 territory.
- CHANGELOG entries terse (user feedback). Manager owns plan.md + git; specialists do source edits.
