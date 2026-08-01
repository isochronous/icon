## Task: ICON-0099
## Branch: feature/ICON-0099-migrate-fenced-blocks-waves-1-2
## Objective: Migrate the remaining deterministic fenced code blocks under ADR-017 — wave 1 (the four `python3` heredocs in `plugin-design`, `icon-status`'s 9 blocks, `icon-audit`'s 1 block) and wave 2 (the ~11,000 B of cross-skill duplicated blocks, as one unit). Wave 1's first item is a live Windows bug: `python3` does not execute on a stock Windows box, so those `plugin-design` audit phases do not run there at all.
## Folder: .context/tasks/ICON-0099-migrate-fenced-blocks-waves-1-2/

GitHub issue: #59. Follows #23/#58 (ICON-0098), which settled ADR-017 and proved it on `icon-init`.

## Phase State
- **Phase plan**: investigation → implementation → testing → **architecture** → implementation → testing → completion
- **Completed**: investigation, implementation, testing, architecture, implementation (re-run), testing (re-run)
- **Current**: completion   (status: in-progress)
- **Next**: (none — close)
- **Loaded skill**: task-plan-phase-completion
- **Branch**: feature/ICON-0099-migrate-fenced-blocks-waves-1-2
- **Attempts (current phase)**: 1

**Re-opened 2026-08-01 by explicit maintainer decision.** PR #65 was open and awaiting review when the maintainer challenged the premise the whole task was built on: *"Why are we putting huge code blocks in skill files instead of just adding scripts to skills?"* The challenge holds. An `architecture` phase is inserted to correct ADR-017 before the implementation is redone against the corrected rule. PR #65 stays open and unmerged.

## Decisions

### OVERTURNED 2026-08-01 — ADR-017's inline-`node -e` default

**The maintainer overturned the premise this task executed on.** Everything below in this section describing wave-1 dispositions as inline `node -e` was applied faithfully to ADR-017 as written; ADR-017 as written is what is now judged wrong. Kept as the record of what was done and why, not as current direction.

Measured at PR #65's HEAD:

| File | Before | After | Factor |
|---|---|---|---|
| `skills/icon-status/SKILL.md` | 8,076 B | 18,534 B | 2.3× |
| `skills/plugin-design/audit-phase-consistency.md` | 6,343 B | 17,580 B | 2.8× |
| `skills/plugin-design/audit-phase-structure.md` | 3,661 B | 11,245 B | 3.1× |

21 inline `node -e` sites repo-wide, **14,842 B of program bodies**, largest single program **2,067 B** — against **3** committed `.mjs` files in the entire repo (`hooks/` ×2, `icon-init/scripts/` ×1).

**Size is NOT the argument, and ADR-017 is right to disqualify it.** The three files grew ~29 kB while holding ~14 kB of code; roughly half the growth is the prose contract, which ADR-017 obliges to survive extraction either way. Moving code to scripts recovers 40–50% of the growth, not all of it.

**The arguments that do land are the ones ADR-017 never weighed:**

1. **The PowerShell 5.1 defect (#62) exists *only* because of inline delivery.** A program passed as a single-quoted shell word loses its embedded `"` on 5.1. Verified this session: `node "<path>.mjs"` runs clean on 5.1. The default created a 21-site portability bug that the disfavoured exception does not have.
2. **Every program body is banned from containing an apostrophe** — a language restriction imposed by the delivery mechanism. ICON-0097 shipped a break on the name `Siobhan O'Brien`.
3. **Nothing can be tested directly.** Every verification round had to extract fences from markdown and re-run them as shell words to test what ships.
4. **Six review rounds were spent reading JavaScript inside markdown diffs.**

**The precise gap in ADR-017**: its four `.mjs` triggers — cross-fence state, mutation, reuse, unavoidable apostrophe — are all *fence-specific correctness hazards*. **None asks whether the block is a program or a command.** A 2 kB parser with a recursive walk and a visited set is a program; it classified inline because no trigger fired.

**Live counter-considerations the architecture phase must resolve, not wave away**: Copilot CLI path reconstruction is still *designed for, untested* with a hard-coded marketplace slug, and flipping the default makes it load-bearing for many more sites; shared blocks ship n copies (`skills cannot share scripts`); and there is no JS correctness linter either way (#48).

### Architecture phase outcome — two corrections, one record (ADR-018)

Design artifact: `.context/tasks/ICON-0099-.../adr-017-amendment-design.md`.

**Correction 1 — the body test.** A deterministic block is a **program** if it has a **body**: a named callable it declares and calls, or a braced `if`/`for`/`try`/`catch` body holding two or more statements. No body → **command**, stays inline. Applied to all 22 sites: **18 programs, 4 commands, zero ambiguous**. Structural, not numeric — and provably not size in disguise: one site converts at 269 B while a 402 B site stays inline, and no byte threshold reproduces the partition. Three alternatives were rejected on corpus evidence ("defines a function" splits two sites purely on whether an arrow was hoisted, and is gameable by inlining it; "control flow beyond a single guard" has five arguable members).

**Correction 2 — the degradation-path precondition is a second defect of the same shape.** The manager challenged the architect's first-pass finding that this precondition blocked 12 of 19 conversions. **Measured on three shells with `node` off `PATH`**, running `plugin-design` site 15 verbatim against `icon-init`'s committed `.mjs` verbatim:

| Shell | Inline `node -e` | `node "<path>.mjs"` |
|---|---|---|
| bash | 127 · empty stdout · `node: command not found` | **identical** |
| PowerShell 7 | `CommandNotFoundException` · `$LASTEXITCODE` stale | **identical** |
| Windows PowerShell 5.1 | `CommandNotFoundException` · `$LASTEXITCODE` stale | **identical** |

Byte-identical on all three channels. ICON-0096's `$LASTEXITCODE` staleness — ADR-017's *second* stated ground — applies equally to both forms.

The diagnosis: ADR-017's *"self-defeating detector"* argument establishes only that **the guard must be prose**, and that is not a `.mjs` property — an inline `node -e` reporting Node's absence is equally self-defeating. A second obligation was appended to a paragraph whose argument never reached it. **Filed against *delivery mechanism* when the hazard is *Node dependence*** — the same misfiling the body test corrects.

> **SUPERSEDED — the @architect's proposed replacement, withdrawn in place.** It read: *the prose Node-presence guard applies to both dispositions; the degradation path is an obligation on the skill, not a precondition on the migration; and "do not invent one" becomes "do not invent one silently."* The maintainer's answer replaced it and the architect withdrew this formulation itself (`adr-017-amendment-design.md:499-503`). **The live rule is § The settled invocation guard below** — route to `check-node-runtime`, which already ships the behaviour both formulations were reinventing. Kept here because the reasoning that got here is what justified deleting the precondition at all.

**Both corrections land as one record, ADR-018, scope-superseding ADR-017.** They are not separable: ADR-018 makes `.mjs` the default for programs, and an unamended neighbour would block 12 of the 19 conversions that creates — ADR-018 would be inert. Precedent for the form is ADR-014 → ADR-015. An amendment was rejected because ADR-017's `## Amendments` already holds two entries from this task, **both opening "The Decision has not changed."**

**Copilot risk, unresolved and now observed rather than hypothetical.** Copilot CLI is not installed here, so neither of ADR-017's two settling tests is runnable. But this machine's Claude Code marketplace slug is **`icon-local`, not the hard-coded `icon-marketplace`**, and the install path carries an undocumented **version segment** the reconstruction has no analogue for. `.mjs` adds exactly one failure mode over inline — an unresolved path, failing loudly with `Cannot find module` — and that is this exposure.

**No candidate is shared cross-skill** (SHA-256 over all 22; the one duplicate pair is both-inside-`plugin-design`), so **no `.githooks/pre-commit` parity registration is needed in any wave**.

Also surfaced: `icon-status` sites 04 and 10 duplicate the same named `scan` walker — a consolidation motive that is not a size argument. Sites 18 and 19 mutate state and are inline today, i.e. ADR-017 trigger 2 already fired on them and was never applied; they predate the ADR.

### The settled invocation guard — two clauses, and the second is easy to miss

**Clause 1** applies to **both** dispositions (the §4.0 measurement showed the Node-absence exposure identical): run `node -v`, read its **output** not its exit status; if absent, invoke **`check-node-runtime`**, which reports what stops working and offers a per-platform install without running one. No bootstrap circularity — that skill's detector is `node -v` and every interpretation step is a prose table, so it needs no Node and is reachable in exactly the case it detects.

*"Never gates"* and *"report not-run"* are compatible, not in tension: the prohibition is scoped to the **session**, the false-pass fix to **one block's result**. `check-node-runtime`'s own Common Mistakes already asserts the stronger form — *"Reporting nothing when Node is present — a silent pass is indistinguishable from the skill never running."*

**Clause 2 — any block whose documented pass state is silence must emit an affirmative token instead.** Node being present does **not** establish that the block ran. Two measured modes produce empty stdout with Node present: inline PowerShell 5.1 quote-stripping, and, for `.mjs`, an unresolved path (`Cannot find module`, exit 1). Clause 1 cannot reach either. **This binds at `icon-status`'s Step 1 guard whether or not it ever converts** — that site stays inline permanently as a command.

### The hardened Copilot reconstruction

The earlier mitigation for the unverified Copilot path was "keep the scope narrow." Scope is no longer narrow, so **the reconstruction itself becomes the mitigation**: 482 B / 8 lines, discovering the marketplace directory by glob rather than naming it, with `MARKETPLACE_NAME` demoted from a guess to a **pin**, a second glob handling the undocumented version segment as a fallback so the documented layout still wins, and **ambiguity failing closed with the match count**.

Verified against eight fixtures built as real directory trees with real `.mjs` files — canonical layout, the `icon-local` slug case, a version segment, an empty slug, a spaced path, no install, two marketplaces, both shapes at once — exit 0 on the five resolvable cases and **exit 1 on all three ambiguous/absent ones**, plus recovery checks (ambiguous + a correct pin resolves; a wrong pin fails closed). Passes under POSIX `sh`.

Three constraint findings: `${MARKETPLACE_NAME:-*}` would have **violated `shell-portability` Rule 5** — the rule's stated live case is a fork setting the value deliberately empty, which `:-` discards and the `if`/`then` form preserves. `set -- $MATCHES` was rejected as not space-safe, and Windows home directories have spaces. Globbing only, so no `find` and no `-maxdepth`/`-quit` portability question.

A heavier 28-line/970 B two-pass resolver passed the same fixtures and was **rejected on cost** — ≈18 kB across 19 sites, more than the 14,545 B of program bodies the migration removes. Hoisting the resolver per-skill halves that but **creates trigger-1 cross-fence state in its most dangerous form**: a stale `SKILL_DIR` from a *different* skill resolves to a real directory and runs the wrong script silently.

**Residual exposure, stated not waved**: the fixtures are built from ICON's own documentation, not a real Copilot install. The hardening buys a loud, actionable, closed failure on a wrong guess. **It does not make the layout verified**, and ADR-017's two settling tests remain unrun.

### Final scope and cost

**All 19 program sites convert** — `icon-status` 8, `plugin-design` 9 (8 by the body test + one on ADR-017's existing trigger 2), `initialize-workspace` 1, `icon-audit` 1. No site exempted. Sites 02, 20 and 21 stay inline as **commands**, which is the rule applied correctly rather than conservatively.

Per-site cost ≈600 B (hardened fence pair); ≈11.4 kB added against ≈14.5 kB removed — **net roughly flat, which is what ADR-017 says to expect.** Size is not the win and must not be reported as one.

**#62 shrinks from "22 sites, one silently wrong" to "3 sites, all loud."** Site 02's token inversion is in scope here (Clause 2); the two survivors are `JSON.parse` checks whose 5.1 failure is a visible parse error.

**Open consequence for the ADR to address**: the invocation preamble itself becomes duplicated across ~6 skills. It is not byte-identical between them (skill and script names differ), so the `.githooks/pre-commit` parity check cannot police it as-is — the exact drift shape ADR-017's own Context section names, created by ADR-018.

### Original decisions (applied as written; superseded above where they conflict)
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
- [x] Implementation: wave 1 — `plugin-design`, all four `python3` heredocs gone, 5 blocks inline, 2 PowerShell twins retired (commit `4646892`)
- [x] Implementation: wave 1 — `icon-status`, 10 blocks inline, three dead cross-fence chains cured (commit `a814893`)
- [x] Implementation: wave 1 — `.claude/skills/icon-audit`, 1 block inline + 3 fidelity fixes (commit `ce5e956`)
- [x] Implementation: back-port `upgrade-repo`'s two `.gitattributes` guards into `impl-leaf` and `impl-root` — all three copies now byte-identical (commit `5448e00`)
- [x] `.context/` correction: ADR-017's falsified "two copies already drifted" sentence, plus a second occurrence in its Decision section and one in ICON-0098's `plan.md` (commit `c234e84`)
- [x] Testing: independent adversarial re-verification by @tester and @reviewer in parallel — both found real defects; 4 Moderate + 6 lower, plus one High-severity pre-existing class
- [x] Round 2: remediation of all findings across three parallel dispatches (commits `5a7ebdb`, `c308b74`, `ca32027`)
- [x] Completion (first pass): re-review, changelog, retrospective, three lesson promotions, follow-ups #62/#63/#64, **PR #65 opened**
- [x] Architecture: design the ADR-017 correction — body test settled, degradation-path precondition falsified as a second defect of the same shape
- [x] Maintainer settles the degradation path outright: *"tell the user node is required and offer to install it."* Verified `check-node-runtime` already does exactly that (Step 4 reports, Step 5 offers a per-platform install without running it). The path is **one uniform behaviour that already ships**, not something a skill must possess or invent — so **no site is blocked** and all 19 program sites convert.
- [x] Architecture: invocation guard restated around `check-node-runtime`; Copilot reconstruction hardened and verified on eight directory fixtures
- [x] **ADR-018** written, scope-superseding ADR-017; `executable-content.md` split into a four-file folder in the same pass when it crossed both gates
- [x] Implementation (re-run): 19 program sites converted — `icon-status` 8, `plugin-design` 9, `initialize-workspace` 1, `icon-audit` 1
- [x] Testing (re-run): differential + mutation verification per skill, then an independent review round that re-ran 48 comparisons itself
- [x] Round 8 review: **approved with comments**; five must-fixes cleared (two Clause-2 gaps, the CHANGELOG entry, two stale ADR-018 claims, and the issue corrections)
- [x] Follow-ups filed: #66 (parity check, 18 copies), #67 (one Copilot fence per skill), #68 (arity hazard), #69 (the sibling Clause-2 defect); #62, #63 and #64 corrected
- [ ] Completion: retrospective addendum, update PR #65 ← IN PROGRESS

## Final outcome

**The maintainer's objection is answered at the corpus level and not at the file level, and both halves need saying.**

- **22,934 B of program bodies left the markdown.** 19 sites are now committed `.mjs` under `scripts/`, reviewable and runnable directly instead of extractable-then-runnable.
- **`skills/icon-status/SKILL.md` is 30,435 B — 90% over the cap and larger than when the objection was raised.** The review's line-class accounting shows the *entire* net markdown growth across the branch is the Copilot invocation preamble: ≈11.4 kB in 18 fences, matching ADR-018's own prediction to within a few hundred bytes. Program bodies out (−5,171 B in this file), outcomes tables and contract prose in (+5,607 and +4,740), Copilot fences in (+5,552).
- **The fix exists and is ticketed as #67** — a single Copilot fence per skill invoking all its scripts in one process. Zero cross-fence state, so ADR-018's trigger-1 objection to hoisting does not reach it; takes this file from 5,552 B of fences to ~900 B. ADR-018 never considered it.
- **#62 is measurably closed for the 19 converted sites**, verified on PowerShell 5.1.26100 with a positive control showing the old inline form still failing. Three command sites remain, all loud; the most dangerous of them — `icon-status`'s silence-is-the-pass hard-stop guard — was fixed here.

**Eight review rounds.** Every one found real defects. Rounds 3, 5 and 7 each found defects *introduced by the immediately preceding remediation*, which is ICON-0094's lesson recurring and now has its own entry.

## Review Checkpoint

- **Round 1** (@reviewer, tier `complex`, over `1b8d651..c234e84`): **changes requested** — 4 Moderate, 5 Minor. Verdict recorded: *"The migration itself is sound and I would approve it on the strength of the semantics work once those land."*
- **Round 1** (@tester, tier `complex`, independent and parallel): 1 High (pre-existing class), 1 Moderate, 4 Low. Mutation-tested every semantics item and found **one fixture that does not discriminate**.
- **Round 2** remediation: commits `5a7ebdb`, `c308b74`, `ca32027`. Every Moderate and Minor addressed; the High goes to its own ticket (below) with the prose corrected to state the measured truth in the meantime.
- **Round 3** (@reviewer, over `c234e84..HEAD`): **changes requested** — 4 Moderate, 7 Minor. Every one of the four Moderates was **introduced by round 2's own prose**, not by the migration. The reviewer's framing is the durable lesson: *"The seven verifiable measurements round 2 made all reproduce exactly. What did not survive is the generalization round 2 wrapped around three of them — four new unconditional claims, each falsified by a counter-example I could construct in under a minute."*
- **Round 4** remediation: commits `d831e04`, `f129326`, `5dd1026`. Dispatched with an explicit instruction to attempt falsification before writing any sentence containing *every / never / only / all*, and to report the attempt. **It worked** — both coders falsified universals in their own drafts and corrected them before finishing (one wrote "this is the one block where a failure to run is indistinguishable from a pass" and found three more; another wrote "loses every line, including the ones already computed" and measured a mutant keeping 95 of 164 bytes).
- **Round 5** (@reviewer, over `ca32027..HEAD`): **approve with changes** — 0 Critical, 3 Moderate, 7 Minor. All three Moderates were single-sentence prose, again introduced by the preceding round. The link-policy code change was verified correct: *"I could not make the visited set drop a real file in 85 fixture trials plus a validated positive control."* Verdict quote: *"Five rounds is enough — the remaining defect surface is sentences, not semantics."*
- **Round 6** remediation: commits `58f88d6`, `f6b6e2f`. All three Moderates plus five cheap Minors. The one deferred item — widening the `realpathSync` catch — the reviewer classified explicitly as a follow-up, not a blocker: pre-existing, loud rather than silent, reachable only on a pathological tree.
- **Round 7** (@reviewer, close-gate check over `5dd1026..HEAD`): **changes requested**, narrowly — 2 Moderate, both single-clause prose in `.context/`, neither touching a shipped surface or any executable behaviour. Cleared in `0da3301`. *That round's findings were the newly-written `claim-scope.md` over-claiming on its own first use.*
- **Round 8** (@reviewer, over the ADR-018 conversions `f147e0a..HEAD`): **approved with comments** — 0 Critical, 5 Moderate, 6 Minor. All five cleared in `f07c85f` and `f61fbc0`. The reviewer re-ran 48 differential comparisons itself rather than accepting the converting agents' matrices, and verified the PowerShell 5.1 win on 5.1.26100 with a positive control. Verdict: *"Nothing imperfect remains that justifies an eighth round."*
- **Two reviewers destroyed repo files during their own runs** by invoking `update-plugin-json.mjs` / `update-readme.mjs` with no arguments from the repo root — the arity hazard now ticketed as #68. Both detected it, restored from the HEAD blob, and disclosed it. Manager verified: `git hash-object` matches HEAD exactly for both files.

**Round 6 closed the loop the task had been failing at.** Both agents falsified a premise they were *handed*, not just their own drafts:
- The coder was told adding `|| err.code === "EISDIR"` would make the word "unreadable" true. It does not — an exclusively locked file throws `EBUSY`, and "unreadable" is wider than any code enumeration. It applied the guard **and** narrowed the prose to the enumeration actually implemented.
- The context-specialist's first fix (moving the mis-parented paragraph) would have broken entry 2's own *"the two bullets immediately above"* reference — trading one false attribution for another. It reverted and named the commit in place instead.

## The over-generalization pattern — this task's main durable lesson

Five times in one task, an agent measured something correctly and then wrote a universal the measurement did not support (the count matched the table's rows when written; both are five):

| Round | Correct measurement | Unsupported universal written around it |
|---|---|---|
| 1 | `impl-leaf` and `impl-root` are byte-identical; `upgrade-repo` diverged | ADR-017's *"two copies already drifted"* |
| 2 | The back-port made all three identical | The correction, written 14 s later, kept the **present tense** — and its amendment added a *new* false claim that the copies still "carry" the bug |
| 2 | Folding is load-bearing for the description-quality check | *"It changes no outcome for this block"* — false for an empty block scalar |
| 2 | `rglob` yields a symlinked dir without recursing | *"matching `pathlib.rglob`"* — false for a Windows junction, silently |
| 2 | The fences fail loudly on PowerShell 5.1 | *"never with a wrong answer"* — false wherever silence is the pass |

The remedy is already written down at `skills/context-document-guidelines/correcting-a-stale-adr.md:34-35`: *"Prefer a description of what the repo does… over a universal that one counter-example falsifies."* It was not applied, including by the round that was citing it. What made round 4 different was an **explicit instruction to attempt falsification before writing the sentence, and to report the attempt** — which converted the rule from something to remember into a step with an output.

## Size: three files are now over ADR-016's advisory cap

| File | Before | After | Cap | Gate 2 |
|---|---|---|---|---|
| `skills/icon-status/SKILL.md` | 8,076 B | **18,955 B** | 16,000 | no — one linear procedure |
| `skills/plugin-design/audit-phase-consistency.md` | 6,343 B | **16,450 B** | 8,000 | no — four checks, one invocation |
| `skills/plugin-design/audit-phase-structure.md` | 3,661 B | **11,444 B** | 8,000 | no — same |

Growth is ADR-017's expected and stated cost, and nothing was relocated to a `.mjs` or trimmed from a contract to manage a number (ADR-017 § Disqualified). Gate 2's prescribed answer for all three is *"record the finding; do not split"*, and that is what was done.

**But the round-3 reviewer's challenge stands and is recorded rather than dismissed**: *"'Did you shrink a file dishonestly' was the wrong question to ask at gate 2 — the honest answer is no, but nobody asked whether tripling two companions warrants a split."* `icon-status` is now ~2.35× its pre-task size and past the post-compaction retention limit ADR-016's cap was derived from, so content will be silently dropped on compaction. That deserves a deliberate decision rather than a gate-2 default, and is ticketed.

## The PowerShell 5.1 finding — the largest thing this task learned

The @tester measured that **Windows PowerShell 5.1 does not escape embedded `"` when building a native command line**, so Node receives an inline `node -e` program with its quotes stripped:

```
=== PS5.1 ===                                    === PS7 / bash ===
process.stdout.write(HELLO\n)                    HELLO
                     ^^^^^^  quotes stripped
SyntaxError: Invalid or unexpected token         exit 0
```

**Every inline `node -e` fence containing a `"` fails on PowerShell 5.1** — exit 1, zero stdout, a visible SyntaxError. Reproduced through two independent invocation paths (`-File` and `-Command`) on 5.1.26100.

This matters more than one task's diff, for three reasons:

1. **ADR-017's untagged-fence contract does not survive contact with it as written.** The ADR's claim — *"byte-identical in bash, sh, zsh, PowerShell 5.1 and 7, and cmd"* — is stated about `node "${CLAUDE_SKILL_DIR}/scripts/<name>.mjs"`, a single-line invocation with no embedded quotes, where it is **true**. It does not extend to multi-line `node -e` programs, which is what the ADR simultaneously makes the *default* disposition. The gap is in the ADR, not in this migration.
2. **It is pre-existing and this task widened it.** 8 such sites existed at `1b8d651`; the branch takes it to 22. It also **deleted 3 native-PowerShell twins that did work on 5.1**, so for `plugin-design` specifically this is a net regression on that shell.
3. **`shell-portability/testing-pattern.md` measures `$LASTEXITCODE` on "7.6.3 and 5.1"**, so 5.1 is inside ICON's stated support scope, not outside it.

**Decision: ticket it, do not fix it here, and correct the prose that claims otherwise.** Per the maintainer's bug policy the cause is apparent but the fix is *not* obvious — the candidates are (a) eliminate `"` from all 22 program bodies, which needs a verified alternative quoting form, (b) amend ADR-017's shell claim and scope inline `node -e` to bash/pwsh 7, or (c) reintroduce PowerShell twins, which contradicts ADR-017's standing no-new-twins policy. That is a design call across 22 sites and an ADR, not a fix.

**The twins are deliberately not restored.** A partial restoration would leave `plugin-design` working on 5.1 while `icon-status` and `icon-audit` do not — a worse state than a uniform, documented, loudly-failing gap with a ticket. The failure mode is loud and closed in every case: SyntaxError, exit 1, empty stdout, never a wrong answer.

All four migrated files now state the measured requirement — bash or PowerShell 7 — in place of the "identical in every shell" claim they carried.

## Findings recorded, not acted on

**ADR-016 size-gate advisories** (the gate is advisory until #24 lands a CI backstop; both were answered per the gate's own gate-2 instruction):
- `skills/plugin-design/audit-phase-consistency.md` — 9,776 B against the 8,000 B companion cap. Gate 2 answered **no** (all four checks run in one invocation, so there are not 2+ invocation-scoped conditions), therefore **recorded, not split**. Growth is the expected ADR-017 cost.
- `skills/context-specialist-impl-leaf/SKILL.md` — 19,271 B against the 16,000 B cap. **Pre-existing**; this task's guard back-port added ~739 B to a file already over. Not this task's to split.
- `skills/icon-status/SKILL.md` — 15,723 B **at the migration commit `a814893`**, i.e. 277 B of headroom at that point. The four remediation rounds' prose then took it past the cap; see § Size below for the final figure and the disposition. Recorded here as the historical reading, not the current one.

**Two crash bugs in the `plugin-design` originals that the classification did not name** — the description-quality check and the dead-ref check each aborted *entirely* on one bad input (an `AttributeError` on a string-valued frontmatter, a `PermissionError` on a directory named `*.md`), losing every finding rather than one. Both fixed by the port as a side effect.

**S12 was wrong on this runtime, and measurement overturned it.** The classification warned that GNU `find -mmin +2880` truncates, so a naive `(now-mtime)/60000 > 2880` fires a minute early. Measured on findutils 4.10.0: modern `find` compares exact timestamps, so the naive mapping *is* the faithful one and the "corrected" floored form would have fired up to a minute **late**. The unfloored form shipped, bracketed by fixtures at 2,880.4 and 2,879.6 minutes.

**An axis S10 did not name, and it is sharper than the one it did.** `find <symlinked-dir> -maxdepth 1` does not descend, because `find -P` lstats its top-level arguments. So `icon-status`'s original context-health block was internally contradictory: `[ -d ]` said "report this directory", `find` reported it empty. On a symlinked `.context/domains` holding two files it printed `— 0 files` *and* emitted a false "run /upgrade-repo" suggestion. The port diverges deliberately — reproducing it would mean adding an `lstatSync` purely to preserve a defect.

**One process miss, self-caught**: a verification run used `2>$null`, the banned suppression pattern (ADR-007). The agent discarded that run and re-ran with stderr to a file — which is how the bash/PowerShell **stderr** parity got measured at all.

## Open Questions / Blockers
- None blocking. The wave-2 scope conflict is resolved (see Decisions); the degradation-path question is resolved (not engaged — every disposition is inline).

### Follow-ups to file at close
Wave-2 deferral (the ticket's own scope, moved rather than dropped):
1. **Sets A and C onto #61** — both have a member in `skills/upgrade-repo/`, so they migrate when #61 does. Set A's *bug* is already fixed here; only its migration moves.
2. **Set B as its own ticket**, carrying the counter-evidence so it is not simply re-proposed: its three copies are already byte-identical (nothing to detect), and none of the three `initialize-*` skills has a Node-absence degradation path, which ADR-017 makes a hard precondition for the committed `.mjs` both its triggers would require.

Found in passing, none in this task's scope:
3. **Nine `agents/*.agent.md` declare no `name:` key** — a real self-audit finding that both the original and the ported check report. Either add the key or amend the check.
4. **15 dead references and 8 unresolved skill references live in the repo today** — pre-existing, both implementations agree on them.
5. **`skills/plugin-design/audit-mode.md:16-24` / `:30-38`** — a bash/PowerShell twin pair still unmigrated; missed by #59's enumeration.
6. **`skills/plugin-design/audit-phase-structure.md` check 2 (`$schema`) has no snippet** at all.
7. **`.githooks/pre-commit:33` header comment is stale**, and so is `:512`'s `# … ANY of the six tracked copies` narration plus the `three copies (…)` enumeration at `:28-31` — none of them gated, all of them drift-prone. Pairs naturally with #30's registry-driven checks.
8. **Node absence now degrades the whole `icon-status` dashboard**, not the two lines the original degraded. Widening the degradation path was out of scope for a migration (ADR-017 forbids inventing one), so it was left as-is and needs its own decision.

## Constraints
- ICON is pure-content: no build step, no test runner, no package manager (ADR-005). Committed, dependency-free scripts run in place ARE in scope.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- Any staged change under `context_template/` requires bumping `context_template/context/iconrc.json` `version` in the same commit (pre-commit invariant). Wave 1/2 scope is not expected to touch it; ADR-017 exclusion E1 excludes `context_template/` from migration entirely.
- `.mjs` scripts: ESM, `node:`-prefixed imports, never `require`, no shebang, standard library only. Detectors/validators fail **closed** (inverting the hooks' fail-open posture).
- Claude Code invocation fence is **untagged** (`node "${CLAUDE_SKILL_DIR}/scripts/<name>.mjs"`); the Copilot CLI fence is the only bash survivor. No PowerShell Copilot variant ships.
- The prose contract must survive migration — if a section shrinks to "run the script", the migration failed (ADR-017).
