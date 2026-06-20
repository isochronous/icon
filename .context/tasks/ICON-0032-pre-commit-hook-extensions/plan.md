## Task: ICON-0032
## Branch: feature/ICON-0032-pre-commit-hook-extensions
## Objective: Extend `.githooks/pre-commit` with two new diff-style invariant checks — (A) angle-bracket placeholder grep + `.context/<subdir>/<file>.<ext>` reference resolver across `agents/`/`skills/`/`shared/`/`commands/`, and (B) byte-equality gate on the three duplicated `append-retrospective-entry.{sh,ps1}` script copies — mechanically enforcing Pattern A (cross-surface sweep depth) and closing M-U-A, M-CC-NET3, m-U-J as collateral. Closes GitLab issue #17.

## Folder: .context/tasks/ICON-0032-pre-commit-hook-extensions/

## Decisions
- **Scale-back during MR review (2026-05-21)**: Placeholder-grep check dropped from the hook after user feedback. Kept: dead-ref resolver + script-parity gate. **Why**: the placeholder check would have required 25 marker annotations across the repo (15 per-file + 10 per-line), most matches are legitimate template notation (XML refs, naming-convention examples, dispatch substitution slots, CLI usage docs), and the bug class it was foreclosing (M-U-A — unfilled `<path-to-prior-audit-report.md>` placeholders surviving copy-paste) was caught once in 8 audit cycles by human review. The cost (ongoing annotation discipline + every new author learning the marker convention) was disproportionate to the catch frequency. The dead-ref resolver and script-parity gate have clearer cost/benefit (real broken refs + real divergence prevention) and stay. Inverse-signal alternative ("affirmative TODO marker for intentional fill-ins") was rejected as a connectors-style abstraction without demonstrated need. See architecture.md § Addendum: 2026-05-21 Scale-back for the full record.
- **Dead-ref fixes retained**: All 13 dead-`.context/<sub>/<file>.<ext>` references found during implementation stay fixed. They are independent of the placeholder check and benefit consumers regardless — installed plugin instances no longer cite files that don't ship in `context_template/`.
- **Single PR, single hook extension**: Per issue #17, both sub-tasks share the diff-style-invariant mechanism. Branch checks by staged file path (agents/skills/shared/commands triggers ref check; script pair triggers parity check). Rationale: cohesive infrastructure addition, one CHANGELOG entry, one retro.
- **Separate awk pass for placeholder check** (not merged into existing common-constraints awk): Per architecture § Section 2. The existing pass mutates files (in-block content drop + replacement); the new check is read-only (grep-style). Mixing produces a state machine that's hard to fixture-test. Fence-detection logic copy-pasted from lines 107–166 with "Keep in sync" header comment. ICON-0013 state-machine-complexity lesson.
- **Three marker forms recognized**: `<!-- icon:allow-placeholders [file] -->` (markdown), `# icon:allow-placeholders [file]` (shell/ps1), `// icon:allow-placeholders [file]` (js/ts). Per-file form (with `file` keyword) suppresses placeholder check for entire file; per-line form (without `file`) suppresses only the line it appears on. HTML-comment syntax for markdown chosen because (a) zero existing occurrences in the repo, (b) invisible in rendered output, (c) survives inside backticks. Shell `#` and JS `//` forms added so script files can also be opted out. JS recognition added in fix-up pass after reviewer Pass 1 flagged the `.js` exclusion as scope-narrow.
- **`in_allow_block` is monotonic and gated on `inside_fence==0`**: Per architecture § Section 2 matrix invariant #2. A per-file marker INSIDE a fenced code block does NOT activate the file-wide allow — prevents code-block examples that contain the marker syntax as literal text (like this design doc) from accidentally suppressing the check. Verified by fixture `marker-inside-fence-does-not-activate.md`.
- **Ref resolver is fence-blind**: Per architecture § Section 3. A path-in-backticks like `` `.context/architecture/patterns.md` `` is just as load-bearing as the same path in plain prose — skipping fenced content would silently exempt the most common citation style (backtick-quoted paths in skill SKILL.md files). The `<!-- icon:allow-placeholders -->` markers do NOT apply to the ref check. (If a legitimately-dead ref ever surfaces, the future marker class would be `<!-- icon:allow-dead-ref -->` — out of scope for this task.)
- **Resolver regex**: `\.context/[a-zA-Z0-9_/-]+\.[a-zA-Z0-9]+` — requires a filename with extension. Bare directory references like `.context/architecture/` (no filename) are NOT flagged per issue spec. Path mapping: `.context/<X>` → `context_template/context/<X>` (the distribution mirror).
- **All three script pairs gated** (not just the two in issue #17): A third copy exists at `skills/context-maintenance/scripts/append-retrospective-entry.{sh,ps1}` that the issue author didn't see (Brief 04 of the audit only compared two pairs). Closing the third-copy hole costs one extra `diff -q` per format; leaving it open would have created a latent divergence class.
- **Canonical source: post-incident-review**: chosen because Brief 04 of the audit used it as the comparison baseline. The choice is mechanical — if any of the three diverge, the hook fails regardless of which is canonical; the canonical name just appears in the error message.
- **Script-parity uses accumulate-then-report, not fail-fast** (improvement over architecture spec): Mirror the placeholder check's accumulation pattern so a single hook run shows all divergences. UX win, not a regression. Surfaced by reviewer Pass 1.
- **Dead-ref Option 7B (rewrite-to-split) for legacy paths, NOT a second marker class**: Per architecture § Section 7. Rewrites the prose so the dead path is split between sentence parts (directory + filename never joined) instead of introducing `<!-- icon:allow-dead-ref -->`. Keeps hook semantics tight; the first new marker class is enough to introduce in one task. Pattern was applied uniformly to all 13 dead-ref instances found, not just the architect-enumerated 3 — the same rewrite pattern works for all.
- **Three-surface bypass named**: `.githooks/` is local-only repo infrastructure (not shipped to consumers); the three-surface sweep rule (`.context/workflows/` ↔ `context_template/` ↔ `skills/<phase>/SKILL.md`) does NOT apply. Documented in the hook header comment per ICON-0026 "Exception — repo-local conventions" precedent.

## Pre-flight inventory (audit findings, frozen at task start)

**Placeholders outside fenced blocks** (Check 1): ~20 files matched `<[a-z][a-z0-9-]+>` outside fences. EVERY single match was legitimate — dispatch templates, naming conventions, XML element references, CLI usage docs, and synthesis-template fill-in blanks. Implication: the exception-marker design was load-bearing. Without a working marker, the hook would have been unusable. Final count of files marked: 15 per-file + 10 per-line = 25 files.

**Dead `.context/<subdir>/<file>.<ext>` refs** (Check 2): pre-flight surfaced 3 known instances (refs 1 & 2 to `architecture/patterns.md`, ref 3 to `workflows/prune-old-tasks.sh`). During @coder implementation, a fence-blind regex sweep surfaced **10 additional instances** (7 `.context/projects.md` references in initialize-* skills, 2 example task paths in product-manager.agent.md, 1 example domain-file path in task-retrospective/SKILL.md). All 13 fixed using the Option 7B split-path rewrite pattern (no new marker class). `manager.agent.md:151` confirmed clean (ICON-0028 fix is live).

**Script-pair byte-equality** (Check 3): All three copies (`post-incident-review`, `task-retrospective`, `context-maintenance`) currently byte-identical. Gated all three pairs (six files total).

## Key Files

**Hook (1 file)**
- `.githooks/pre-commit` — extended with placeholder-check awk pass (separate, read-only, fence-aware via copy-paste of lines 107–166 with "Keep in sync" comment), `.context/` ref resolver (fence-blind), script-parity diff (accumulate-then-report across 3 pairs), path-prefix branching, and updated header comment per architecture § Section 6.

**Dead-ref fixes (7 files)**
- `skills/context-specialist-impl-root/SKILL.md` — re-point line 257 `patterns.md` → `patterns-template.md`; 3 `.context/projects.md` Option-7B rewrites.
- `skills/task-plan-phase-completion/SKILL.md` — re-point line 59 `patterns.md` → `patterns-template.md`.
- `skills/upgrade-repo/SKILL.md` — migration paragraph rewritten so `prune-old-tasks.sh` no longer joins `.context/workflows/`.
- `agents/product-manager.agent.md` — example task paths rewritten with `{YYYY-MM-DD}` placeholders (curly braces avoid the regex character class).
- `skills/task-retrospective/SKILL.md` — `.context/domains/payments.md` example rewritten to "a domain file under `.context/domains/`".
- `skills/initialize-monorepo/SKILL.md` — two `.context/projects.md` references split.
- `skills/initialize-workspace/SKILL.md` — two `.context/projects.md` references split.

**Per-file marker applied (15 files)**
- `skills/plugin-audit/synthesis-template.md` (wall-to-wall placeholders).
- `skills/plugin-audit/SKILL.md`.
- `skills/plugin-audit/briefs/01-agents.md` … `06-cross-cutting.md` (6 brief files).
- `skills/context-maintenance/SKILL.md`.
- Six script files: `skills/{post-incident-review,task-retrospective,context-maintenance}/scripts/append-retrospective-entry.{sh,ps1}` — `# icon:allow-placeholders file`. All three .sh copies and all three .ps1 copies remain byte-identical after marker addition (verified by hook's script-parity check).

**Per-line marker applied (10 files)**
- `agents/researcher.agent.md` (line 25), `skills/start-worktree/SKILL.md` (line 44), `skills/context-specialist-impl-leaf/SKILL.md` (lines 33–34), `skills/initialize-multimodule/SKILL.md` (line 437), `skills/initialize-monorepo/SKILL.md` (lines 114–115), `skills/context-specialist-impl-root/SKILL.md` (line 12), `skills/writing-skills/SKILL.md` (line 138), `skills/context-specialist-detect-tree-position/SKILL.md` (lines 22, 51), `skills/context-specialist-impl-branch/SKILL.md` (line 86), `skills/merge-phase-templates/SKILL.md` (line 54).

**Fix-up after reviewer Pass 1 (2 files)**
- `.githooks/pre-commit` — added `//` marker recognition (mirrors `#` clause), widened path-prefix case branch to include `.js`, extended fix-message to name three marker forms.
- `skills/writing-skills/render-graphs.js` — applied per-line `// icon:allow-placeholders` markers to lines 7, 8, 90.
- `.context/tasks/ICON-0032-pre-commit-hook-extensions/fixtures/marker-inside-fence-does-not-activate.md` — rewrote "Expected hook behavior" prose so trigger pattern doesn't appear outside the fence.

**Fixtures (13 files under `.context/tasks/ICON-0032-pre-commit-hook-extensions/fixtures/`)**
- `README.md` — fixture suite index + driver-verification note (ICON-0013 lesson).
- `placeholder-outside-fence-fails.md`, `placeholder-inside-fence-passes.md`, `placeholder-with-per-line-marker-passes.md`, `placeholder-in-file-marker-passes.md`, `marker-inside-fence-does-not-activate.md`, `dead-context-ref-fails.md`, `dead-context-ref-in-backticks-fails.md`, `valid-context-ref-passes.md`, `bare-directory-ref-passes.md`, `script-parity-identical-passes.md`, `script-parity-divergence-fails.md`, `script-parity/README.md` — fixture-as-spec naming per ICON-0013.

**Task artifacts (2 files)**
- `.context/tasks/ICON-0032-pre-commit-hook-extensions/architecture.md` — primary spec written by @architect, 514 lines, seven sections.
- `.context/tasks/ICON-0032-pre-commit-hook-extensions/plan.md` — this file.

Total: 47 files changed (14 new fixtures + architecture.md + plan.md, 31 modified).

## Progress
- [x] Read issue #17, retrospectives (ICON-0011, 0013, 0028, 0030), and existing `.githooks/pre-commit`
- [x] Pre-flight audit: enumerate current placeholder + ref state in agents/skills/shared/commands (Explore subagent, Sonnet)
- [x] @architect: design the hook extension — `architecture.md` 514 lines, seven sections (marker convention, fence-strip reuse + N-flag matrix, ref resolver, script-parity, path-prefix branching, header comment, dead-ref resolutions)
- [x] @coder: implement hook + fixtures + dead-ref fixes + markers. Hook exit 0 against 46 staged files. 10 additional dead refs caught beyond architect's 3 (Option 7B pattern, no new marker class). `.js` initially excluded — flagged in reviewer Pass 1.
- [x] @tester: all 11 fixtures pass — 9 single-file + 2 driver scenarios. Driver-corruption sanity check (ICON-0013 repeat): commenting out `inside_fence=1` on fence-open flipped `placeholder-inside-fence-passes.md` from 0 to 1 and surfaced multiple real-tree fence-protected placeholders — proves the invariant is load-bearing across the tree.
- [x] @reviewer Pass 1: Approved with comments. Two Moderates — (M1) `.js` exclusion is out-of-spec scope-narrow; (M2) `marker-inside-fence-does-not-activate.md` had unintended secondary placeholder match in docs prose. Architecture compliance 6/7 (Section 5 partial). Critical findings: none.
- [x] @coder fix-up: M1 — added `//` marker recognition + widened path-prefix case + applied markers to render-graphs.js lines 7, 8, 90. M2 — rewrote fixture's "Expected hook behavior" stanza. Both verified with synthetic tests; hook exit 0 against final staged tree.
- [x] @reviewer Pass 2: APPROVE. Both M1 and M2 verified with cited evidence. No regressions. Hook final run exit 0.
- [x] Manager: reconcile plan.md against final state
- [x] Run `task-retrospective` skill; delegate context updates to @context-specialist mode:maintenance — ICON-0032 entry inserted; ICON-0004 evicted per rolling-log cap
- [x] Manager: add `[Unreleased]` CHANGELOG entry via `changelog-entry` skill
- [x] Manager: commit task artifacts in commit `27c6b93`; push branch; open MR !16
- [x] **MR review feedback (user, 2026-05-21)**: Scale back to dead-ref + script-parity only; drop placeholder check
- [ ] @coder: remove placeholder-check awk + marker recognition; remove 25 markers across the tree; delete 5 placeholder fixtures; update hook header comment ← IN PROGRESS
- [ ] @tester: re-verify scaled-back hook against remaining 6 fixtures
- [ ] @reviewer: review scale-back diff
- [ ] Manager: update CHANGELOG; commit scale-back as second commit on branch; push to MR

## Open Questions / Blockers
None. All Pass 1 findings closed in Pass 2.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- Cross-platform shell: hook runs on Linux/macOS/WSL; avoid GNU-only flags (`sort -V`, `grep -P`, etc.) — see ICON-0030 retro.
- No stderr suppression: never `2>/dev/null` or `>/dev/null` inside the hook — see common-constraints, ICON-0030 retro.
- State-machine matrix: hook awk's new flags (`in_allow_block`) enumerated in architecture § Section 2 transition matrix — see ICON-0013 retro (fence-leak Critical bug class).
- Fixture-as-spec naming: each fixture filename names the case it guards — see ICON-0013 retro.
- Three-surface check N/A here: `.githooks/` is local-only repo infrastructure. Documented in hook header comment per ICON-0026 "Exception — repo-local conventions" precedent.
- **Discovered during implementation**: `system("test -f ...")` in the resolver awk spawns one subprocess per `.context/` reference (~130 calls per full re-stage). Currently runs under a second; if hook ever crosses a noticeable latency threshold, a single `find ... -print0` indexing pass upfront would amortize the cost. Documented as Minor in reviewer Pass 1.
- **Discovered during implementation**: PowerShell `@" ... "@` here-string contains `<retro-file>` placeholders that appear in user-facing `--help` output. A trailing per-line marker would leak the marker into help text. Use per-file markers for any script with heredoc/here-string user-output. Applied to all 6 `append-retrospective-entry.{sh,ps1}` copies.
