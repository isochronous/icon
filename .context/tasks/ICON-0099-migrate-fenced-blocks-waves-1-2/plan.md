## Task: ICON-0099
## Branch: feature/ICON-0099-migrate-fenced-blocks-waves-1-2
## Objective: Migrate the remaining deterministic fenced code blocks under ADR-017 — wave 1 (the four `python3` heredocs in `plugin-design`, `icon-status`'s 9 blocks, `icon-audit`'s 1 block) and wave 2 (the ~11,000 B of cross-skill duplicated blocks, as one unit). Wave 1's first item is a live Windows bug: `python3` does not execute on a stock Windows box, so those `plugin-design` audit phases do not run there at all.
## Folder: .context/tasks/ICON-0099-migrate-fenced-blocks-waves-1-2/

GitHub issue: #59. Follows #23/#58 (ICON-0098), which settled ADR-017 and proved it on `icon-init`.

## Phase State
- **Phase plan**: investigation → implementation → testing → completion
- **Completed**: investigation
- **Current**: implementation   (status: pending)
- **Next**: testing
- **Loaded skill**: task-plan-phase-implementation
- **Branch**: feature/ICON-0099-migrate-fenced-blocks-waves-1-2
- **Attempts (current phase)**: 0

## Decisions
- Scope taken verbatim from issue #59 (waves 1 and 2). `skills/upgrade-repo/SKILL.md` (#61) and the `.sh`/`.ps1` script files (#60) are explicitly OUT — they are separately ticketed and #61 is blocked on #42's split.
- Wave 2 migrates **as a whole set or not at all** (ADR-017 § Cross-skill duplication). A half-migrated copy-set is worse than either end state, and the set intersects the `.githooks/pre-commit` byte-parity check's population, which must be updated in the same commit.
- Phase plan includes a distinct **testing** phase because ICON-0098's retro (Rule 10, `shell-portability`) makes differential verification against the pre-migration implementation mandatory, not optional — porting by shape rather than semantics is the known failure mode for exactly this work.
- Size reduction is NOT an acceptance criterion (ADR-017 § Migration is not cap-evasion). A migrated `SKILL.md` may grow; reporting a byte reduction as the win means the record was applied incorrectly.
- **Every wave-1 disposition is inline `node -e`; zero committed `.mjs`.** No ADR-017 trigger fires anywhere in wave 1 once `icon-status`'s cross-fence state is *cured* rather than accommodated (below). Consequences: no `.githooks/pre-commit` change is required for wave 1, and the Node-absent degradation-path gate is not engaged — that gate is part of ADR-017 § The invocation contract, which governs committed `.mjs`; the Deterministic row's test column (*"no runtime guard"*) and Alternatives Considered 4 (*"none of that overhead"*) both exempt inline `node -e`. Manager accepted the @architect's reading. `plan.md`'s earlier blanket statement of that precondition was too broad and is corrected here.
- **Inline `node -e` runs as CommonJS and must use `require("fs")`.** The "never `require`" rule in ADR-017 is scoped to `.mjs` files (which are ESM and have no `require`). All four shipped inline precedents use `require`. A coder applying the `.mjs` rule inline produces a program that does not run.
- **`icon-status`'s three cross-fence state chains are cured, not migrated around.** `TASK_ID`, `PLAN_FILE` and `ICONRC_STATE` are each set in one fence and read in another; Claude Code's Bash tool does not persist shell state between fences, so the `plan.md` lookup and Suggestions signals 3 and 4 never fire today — a live dead-code defect, and precisely ADR-017 trigger 1's stated failure mode. Making each fence re-derive its own inputs makes trigger 1's condition literally false, so no `.mjs`, no invocation preamble and no new file are needed.
- **Wave 2's migration is deferred; its live bug is fixed here instead.** Maintainer policy, stated 2026-07-31: *a bug found during a ticket is fixed in that ticket when the cause is immediately apparent and the fix is obvious; otherwise it is filed as a follow-up.* Applied to the three deterministic copy-sets the investigation actually found:
  - **Set A** (`.gitattributes` union-merge — `context-specialist-impl-leaf`, `context-specialist-impl-root`, `upgrade-repo`): the *migration* is deferred (a member lives in `skills/upgrade-repo/`, out of scope per #61, and ADR-017 forbids a half-migrated set). The *bug* is fixed here: `upgrade-repo`'s copy was hardened at some point and the other two never were, so both carry an unchecked `git rev-parse --show-toplevel` that makes `GA` the literal `/.gitattributes` outside a work tree, plus an `Ensured …` success line that prints even when nothing was written. Cause apparent, fix obvious → back-port both guards, which also makes all three copies byte-identical.
  - **Set C** (root `claude.md` redirect — `context-specialist-impl-leaf`, `upgrade-repo`): deferred to #61 for the same out-of-scope-member reason. No defect found.
  - **Set B** (integration-branch detect + checkout — the three `initialize-*` skills): fully in scope, but deferred to its own ticket on evidence. Its copies are already byte-identical, so a parity registration would guard a divergence that has not occurred; and none of the three skills has a Node-absence degradation path, which ADR-017 makes a hard precondition for the committed `.mjs` both its triggers would require.
- **The ticket's `~11,000 B` wave-2 figure is wrong by ~2.5×.** Measured deterministic wave-2 mass is **4,402 B in scope** (6,246 B including the out-of-scope `upgrade-repo` members). The 11,000 B almost certainly counted **Set H** — duplicated untagged sub-session prompt text and `markdown` PR-body templates across the three `initialize-*` skills, summing to 11,271 B (within 3%) — which contains no commands at all and which ADR-017 does not govern.
- **ADR-017's drift claim is directionally right, factually wrong.** It states *"two copies already drifted"* of the `.gitattributes` block. Measured: `impl-leaf` and `impl-root` are byte-identical at 785 B each; exactly **one** copy diverged (`upgrade-repo`), and it diverged *upward* — the divergence is the hardening pass named above. The ADR text needs correcting.
- **Fidelity reduction in `plugin-design`, stated rather than hidden**: `yaml.safe_load` has no Node standard-library equivalent, and 100% of ICON's frontmatter (all 50 `skills/*/SKILL.md`, all 9 `agents/*.agent.md`) uses folded scalars (`description: >`). The port must fold `>`/`|` blocks or it reports "empty description" for every file — a 100% false-positive self-audit. Two findings (`YAML parse error`, `not a mapping`) are genuinely unrecoverable without a parser and are dropped **in prose**, matching the fidelity the existing PowerShell twin already ships.

## Key Files
- `.context/tasks/ICON-0099-.../wave-1-classification.md`: @architect's per-block classification of all 24 wave-1 fences, the 24 Rule-10 semantics items (S1–S24), and the per-site sequence. **The implementation brief for wave 1 — read it, don't re-derive it.**
- `.context/tasks/ICON-0099-.../wave-2-copy-sets.md`: @architect's three-pass sweep of 87 files / 341 fences, the eight copy-sets, the measured drift diffs, and the `.githooks/pre-commit` parity analysis.
- `skills/plugin-design/audit-phase-structure.md`: one `python3` heredoc at `:42` (verified) — wave 1, bug fix
- `skills/plugin-design/audit-phase-consistency.md`: three `python3` heredocs at `:19, :53, :110` (verified) — wave 1, bug fix. Checks 1 and 3 ship bash + `python3` and **no PowerShell variant**, so they are absent on Windows rather than merely broken.
- `skills/icon-status/SKILL.md`: **10** deterministic blocks, not 9 — #59 counted Step 2's nine and missed the Step 1 fresh-repo guard at `:29-31`. Also holds the three dead cross-fence state chains.
- `.claude/skills/icon-audit/SKILL.md`: exactly 1 fence, at `:32-54`, maintainer-only. The six briefs and the synthesis template contain zero.
- `skills/context-specialist-impl-leaf/`, `skills/context-specialist-impl-root/`: the two unhardened `.gitattributes` copies (785 B each, byte-identical) — bug fix rolled into this task.
- `.githooks/pre-commit`: **unchanged by this task.** Wave 1 creates no `.mjs` and duplicates nothing cross-skill; wave 2's migration is deferred. Parity population stays at one group / six files.
- `CHANGELOG.md`: `[Unreleased]` entry at close

## Phase Handoff Log

### Handoff: investigation → implementation   (commit: <trailer-marked>)
**Sub-agent outputs**: two parallel @architect dispatches (tier `complex`), both read-only, each producing one artifact. Full reports at `wave-1-classification.md` (55,959 B) and `wave-2-copy-sets.md` (35,030 B) — **treated as the implementation briefs, not summarized away.** Load-bearing conclusions, verbatim in substance:
- Wave 1: *"24 fenced blocks across the three sites, all classified. 15 migrate to inline `node -e`; zero committed `.mjs`. 4 are Illustrative, 1 is E2-excluded, 1 is already compliant, 3 are PowerShell twins retired by their bash sibling's port."*
- Wave 1: *"The four `python3` line numbers are correct… These are the last live `python3` invocations in the entire repo."*
- Wave 1 Rule-10 exhibit: *"`icon-status:95-102` needs two different Node idioms in one six-line block: `[ -d ]` follows symlinks (→ `statSync().isDirectory()`), while `find -type f` does not and `-name '*.md'` matches dot-entries (→ `Dirent.isFile()`). Same shape as the ICON-0098 defect."*
- Wave 1 trap: *"`str.split(\"---\", 2)` is maxsplit; `String.split(\"---\", 2)` is a result cap that discards the remainder. Verified on this machine. Copying Python's literal `2` makes `parts.length < 3` unconditionally true → every file reported 'missing frontmatter'. Invisible in a diff review."*
- Wave 2: *"Eight cross-skill copy-sets exist. Three are deterministic; two of those are blocked by this task's own scope boundary."* Measured mass 4,402 B in scope, against the ticket's ~11,000 B.
- Wave 2: *"Population today is one group, six files… Registration is a refactor, not a row. `script_parity_needed` is a single scalar; `canonical_sh`/`script_copies_sh` are single-group variables — there is no group table."* (`.githooks/pre-commit:512-522`, `:608-638`.)

**Reviewer findings**: N/A this phase — read-only investigation, no code changed.

**Verification evidence**: `git status --short` after both dispatches showed only the two new artifacts plus the manager's `plan.md`; no source file modified. Wave-1 line numbers re-verified against live files rather than inherited from #59, and the block count corrected upward (9 → 10). Wave-2 membership derived from three independent sweep passes (exact-hash, Jaccard clustering, 4-line shared-run indexing), the third finding nothing the second missed.

**Decisions delta**: mirrored in full into `## Decisions` — the all-inline wave-1 disposition and its two corollaries (no pre-commit change; the degradation-path gate not engaged), the CJS/`require` correction for inline `node -e`, curing rather than accommodating `icon-status`'s cross-fence state, the stated `yaml.safe_load` fidelity reduction, the wave-2 deferral under the maintainer's bug-vs-follow-up policy, the corrected byte figure, and the falsified ADR-017 drift claim.

**Key files delta**: mirrored in full into `## Key Files`.

**What the next phase needs**:
1. Wave 1 in three separate commits, in the order `plugin-design` → `icon-status` → `icon-audit`. `plugin-design` is first because it is the only live consumer-facing bug and carries the highest-risk fidelity decision; `icon-audit` is last and is the pre-made drop candidate if `plugin-design`'s fidelity call needs a design round-trip.
2. Every disposition is **inline `node -e`**, which is **CommonJS** — `require("fs")`, never `import`. No new file, no invocation preamble, no runtime guard, no `${CLAUDE_SKILL_DIR}` fence.
3. The Rule-10 semantics items S1–S24 in `wave-1-classification.md` are the acceptance surface. Each names a specific way a naive port goes wrong.
4. The `.gitattributes` guard back-port into `impl-leaf` and `impl-root` — a fourth, separate commit. Not a migration.
5. A separate @context-specialist dispatch corrects ADR-017's falsified drift sentence.
6. Follow-up issues to file at close: sets A and C onto #61; set B as its own ticket carrying the counter-evidence.

## Progress
- [x] Investigation: enumerate and classify every candidate block in waves 1 and 2 against ADR-017's four tiers — 24 wave-1 fences classified, 8 wave-2 copy-sets found, 3 of them deterministic
- [x] Update this plan with the classification and per-site disposition before any edit
- [x] Maintainer decision on the wave-2 scope conflict — bug fixed here, migration deferred
- [ ] Implementation: wave 1 — `plugin-design` (the `python3` bug + the four heredocs) ← IN PROGRESS
- [ ] Implementation: wave 1 — `icon-status` (10 blocks; cure the three dead cross-fence chains)
- [ ] Implementation: wave 1 — `.claude/skills/icon-audit` (1 block)
- [ ] Implementation: back-port `upgrade-repo`'s two `.gitattributes` guards into `impl-leaf` and `impl-root`
- [ ] `.context/` correction: ADR-017's falsified "two copies already drifted" sentence (dispatched in-task, not deferred)
- [ ] Testing: differential verification of each migrated site against its `git show HEAD:`-extracted original
- [ ] Completion: reconcile plan, @reviewer, changelog, retrospective, follow-up issues, PR

## Open Questions / Blockers
- None blocking. The wave-2 scope conflict is resolved (see Decisions); the degradation-path question is resolved (not engaged — every disposition is inline).
- Carried to close, not blocking: three follow-up issues to file — sets A and C onto #61, and set B as its own ticket with the byte-identical/no-degradation-path counter-evidence recorded so it is not simply re-proposed.

## Constraints
- ICON is pure-content: no build step, no test runner, no package manager (ADR-005). Committed, dependency-free scripts run in place ARE in scope.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- Any staged change under `context_template/` requires bumping `context_template/context/iconrc.json` `version` in the same commit (pre-commit invariant). Wave 1/2 scope is not expected to touch it; ADR-017 exclusion E1 excludes `context_template/` from migration entirely.
- `.mjs` scripts: ESM, `node:`-prefixed imports, never `require`, no shebang, standard library only. Detectors/validators fail **closed** (inverting the hooks' fail-open posture).
- Claude Code invocation fence is **untagged** (`node "${CLAUDE_SKILL_DIR}/scripts/<name>.mjs"`); the Copilot CLI fence is the only bash survivor. No PowerShell Copilot variant ships.
- The prose contract must survive migration — if a section shrinks to "run the script", the migration failed (ADR-017).
