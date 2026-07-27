## Task: ICON-0093
## Branch: feature/ICON-0093-shipped-content-portability
## Objective: Make ICON's shipped consumer-facing content portable and project-neutral — replace the GNU-only `grep -oP` in monorepo project discovery with a POSIX form, generalize the shipped `commit-conventions.md` template so it no longer hardcodes a predecessor project's ticket prefix, and extend `.context/standards/shell-portability.md` to name the rules these violations demonstrate. Closes GitHub issue #17 (Milestone 1, first item on ROADMAP.md).
## Folder: .context/tasks/ICON-0093-shipped-content-portability/

## Phase State
- **Phase plan**: investigation → implementation → completion
- **Completed**: investigation, implementation
- **Current**: completion   (status: in-progress)
- **Next**: (none — completion is last)
- **Loaded skill**: task-plan-phase-completion
- **Branch**: feature/ICON-0093-shipped-content-portability
- **Attempts (current phase)**: 1

## Decisions
- Task ID derived as `ICON-0093` from `local_task_id_prefix` and the next free slot in `.context/tasks/`, NOT from the GitHub issue number (#17) — per `.context/workflows/commit-conventions.md` § Task ID Generation.
- Phase plan omits `architecture` and `testing`: the issue prescribes three concrete, non-structural edits, and ICON is a pure-content repo with no test runner (ADR-005). Verification is the `.githooks/pre-commit` gate set plus @reviewer.
- Investigation phase is required despite the issue naming exact line numbers: this is an audit follow-up filed against ICON-0089, and `.context/workflows/task-start-conventions.md` mandates a stale-ticket current-state check before planning against baked-in line numbers. Result: all four claims VERIFIED, zero drift — cited line numbers still accurate.
- **Scope = shipped content only** (user decision, this turn). Every live non-portable-shell violation in the consumer-shipped trees is fixed, because issue #17's closing line makes clearing live violations the precondition for the Milestone-4 automated check. ICON's own `.context/workflows/commit-conventions.md:58,89` carries the same `grep -oP` construct but is NOT shipped — out of scope, to be filed as a follow-up issue at task close. `.githooks/` is exempt by its own declared contract (header lines 42–47: local-only, does not ship).
- **`grep -oP` is not one fix but three shapes**, and pattern-matching one onto another produces silently-broken shell:
  - `initialize-monorepo/SKILL.md:82` — pattern `"[^"]+\.csproj"` uses zero PCRE features → pure `-oP`→`-oE` flag swap, behavior-identical.
  - `upgrade-repo/SKILL.md:492,493` — pattern `[\d.]+` uses `\d` → flag swap AND `\d`→`[0-9]` translation.
  - template `commit-conventions.md:74` — uses `\K`, which has **no POSIX ERE equivalent at all** → must be re-expressed with a different tool (sed capture group), not a flag swap.
- **`sed -i` with no backup-suffix arg** (`upgrade-repo/SKILL.md:495`) is in scope: GNU accepts zero args after `-i`, BSD/macOS consumes the next token as the backup suffix, so the same line either errors or eats the script argument. Fixing it is what keeps the new shell-portability rule from shipping with a live violation against it.
- **Template genericization copies `branching.md`'s existing convention; it does not invent one.** Dominant: `TICKET` as the placeholder prefix, with `PROJ` as the secondary "the prefix itself is swappable" example. This is also the convention `.context/standards/skill-decomposition/process-doc-sweeps.md:40` names by contract for exactly these two files.
- **The two `commit-conventions.md` files are intentionally divergent and must NOT be synced.** `process-doc-sweeps.md:40` (ICON-0074 exception) names `branching.md` and `commit-conventions.md` as the known divergent pair: live copies are ICON-specific, template copies are generic consumer scaffolds. Only `context_template/context/workflows/commit-conventions.md` is edited here.
- **The hardcoded-`MKT` defect does NOT get a `shell-portability.md` rule** — it is a template-genericity concern, already governed by `process-doc-sweeps.md`. Only the shell constructs (`grep -P`, `sed -i`) become new numbered rules there.
- **No `## Related` section is added to the two template files.** Neither `context_template/.../commit-conventions.md` nor `context_template/.../branching.md` has the knowledge-graph seam today; adding one to just the edited file would create asymmetry in the shipped scaffold and is outside this task's remit.
- **`sed -i` replacement uses temp-file-and-`mv`, not `sed -i.bak`** (@coder's call, accepted): the `.bak` form is portable but leaves a stray backup in the consumer's `.context/` after every `/upgrade-repo` run, with no cleanup path in the script. `sed … > FILE.tmp && mv FILE.tmp FILE` avoids `-i` entirely and leaves the directory as it was.
- **Line 74's extraction moves from `grep` to a `sed` capture group**, not to `grep -oE`. Demonstrated, not assumed: `echo "TICKET-0042-x" | grep -oE 'TICKET-\K[0-9]+'` exits 1 with no output — re-flagging a `\K` pattern yields a silently non-matching regex, which is *worse* than the original (the original at least fails loudly on BSD). Final form `sed -n 's/^TICKET-\([0-9][0-9]*\).*/\1/p'` uses `[0-9][0-9]*` rather than `[0-9]\+` because `\+` is itself a GNU BRE extension, and `tail -n 1` rather than `tail -1` for POSIX conformance.
- **Four-digit zero-padded task IDs are KEPT in the template** (@coder's judgement call, accepted): `commit-conventions.md` defines an ID-*generation procedure* whose `sort -n | tail` algorithm depends on stable width, while `branching.md` shows branch-name *examples*. Loosening `NNNN` to `TICKET-123` would break the procedure's internal consistency to chase a cosmetic match with a different file. Prefix genericized; width left alone.
- **Scope extended mid-implementation to the rest of the same file's project-specific identity** (manager decision, after @coder surfaced it). Issue #17's opening sentence scopes the task as content that "either only work[s] on Linux **or describe[s] a different project**" — `MKT` was the named instance, not the whole class. The non-task example commits (`feat: add ecological-impact and start-worktree skills (1.5.0)`, `fix(marketplace): …`), the "scopes in use" list, and a hardcoded Copilot co-author trailer are the same `process-doc-sweeps.md:40` violation in the same file. Two sharpeners: `ecological-impact` was **deleted from ICON in ICON-0092/PR #13**, so that example cites a skill that no longer exists; and a single-tool co-author trailer independently violates ADR-004 (tool-agnostic content) in a shipped scaffold. Fixing the prefix while leaving these would end the task with the file still failing the contract the task exists to enforce.

## Key Files
- `skills/initialize-monorepo/SKILL.md` **:82** — `| grep -oP '"[^"]+\.csproj"' | tr -d '"' \`. Pure flag swap to `-oE`. Finding C2 / `C-89-03-02`. File has no `## Related` section.
- `skills/upgrade-repo/SKILL.md` **:492, :493** — `grep -oP '[\d.]+'` ×2; **:495** — `sed -i "s/…/…/" .context/iconrc.json`. Flag swap + `\d`→`[0-9]`; `sed -i` needs a portable form.
- `context_template/context/workflows/commit-conventions.md` — shipped consumer scaffold. `MKT` (a predecessor project's real prefix) at **:12, :15, :20-23, :55, :58, :63-65, :74, :77, :84-85, :93-94, :121-124**; **:74** is also the `\K` command. Finding `M-89-03-04`. No `## Related` section — do not add one.
- `context_template/context/workflows/branching.md`: **reference only, DO NOT EDIT.** Source of the `TICKET` / `PROJ` placeholder convention to copy. Its `## Related Ticket` at :158 is a PR-template sub-heading, not a knowledge-graph seam.
- `.context/workflows/commit-conventions.md`: **DO NOT EDIT** — the ICON-specific live sibling, exempt from the sweep. Same path suffix as the template file; the collision risk is the top implementation hazard.
- `context_template/context/iconrc.json`: template schema version, currently `"1.12"` → must be bumped in the same commit as any `context_template/` change (`.githooks/pre-commit` hard-blocks otherwise).
- `.context/standards/shell-portability.md`: six numbered rules today (`### N. <imperative title>`, prose mechanism, BROKEN-vs-correct fence, closing precedent cite `(ICON-NNNN: …)`). Gains rules 7 and 8. Has a `## Related` section at :64.
- `.context/standards/skill-decomposition/process-doc-sweeps.md` **:40**: the ICON-0074 exception naming `branching.md` + `commit-conventions.md` as the intentionally-divergent pair, and `TICKET-NNN` as the scaffold convention. Read-only input.
- `CHANGELOG.md`: `[Unreleased]` entry at task close.

## Phase Handoff Log

### Handoff: investigation → implementation   (commit: <trailer-marked>)
**Sub-agent outputs**:
- Explore agent, read-only sweep of `skills/`, `agents/`, `commands/`, `hooks/`, `context_template/`, `shared/`, `.githooks/`, `.context/`, `.claude/`. All four claims **VERIFIED, zero line drift** from the ICON-0089 audit citations.
- Claim 1: `initialize-monorepo/SKILL.md:82` pattern `"[^"]+\.csproj"` is already valid POSIX ERE — negated bracket class, `+`, escaped `\.`, literals. No `\d`/`\w`/`\K`/lookaround/lazy/`\s`. `-oP`→`-oE` is behavior-identical.
- Claim 2 sweep: three further shipped violations — `upgrade-repo/SKILL.md:492,493` (`grep -oP '[\d.]+'`, `\d` is PCRE-only) and `:495` (`sed -i` no-backup-arg). Explicitly cleared as **false positives**: `sed -E` (accepted by both GNU and BSD sed, unlike `-r`) at `upgrade-repo/SKILL.md:269` and `prune-context.sh:51`; `stat -c` at `prune-context.sh:72,107` (already chains a `stat -f` BSD fallback then an `echo` degrade); all `mktemp` uses across `context-maintenance/`, `post-incident-review/`, `task-retrospective/` scripts. Zero hits for `readlink -f`, `date -d`, `xargs -r`, `find -printf`, `head -n -N`, BRE `\+`/`\|`, `echo -e`, `sort -V`.
- Claim 3: `MKT` confirmed to be a real predecessor prefix, not a placeholder — ICON's own `.context/workflows/commit-conventions.md:21` states "Pre-split history (this same repo, prior to MKT-0095) used the marketplace `MKT-NNNN` prefix". The shipped scaffold copies that history into every fresh consumer install. `:74` is doubly non-portable: `-P` is a GNU-only flag AND `\K` is Perl-only with no ERE equivalent.
- Claim 4: six existing rules confirmed — (1) no gawk extensions, (2) prefer pure bash for non-trivial parsing, (3) live-test file-writing shell blocks, (4) `grep` with a leading-`-` pattern needs `-e` and an `if grep` guard is untrustworthy, (5) `${VAR+x}` for presence tests, (6) parenthesize PowerShell `-replace` in a method-call arg list. None names `grep -P` or `sed -i`.

**Reviewer findings**: N/A this phase (read-only investigation, no diff).

**Verification evidence**: `git checkout -b feature/ICON-0093-shipped-content-portability` → `Switched to a new branch 'feature/ICON-0093-shipped-content-portability'`. `gh issue view 17` → state `OPEN`, label `bug`, title "Make shipped content portable and free of a stale project prefix". Working tree clean at branch creation.

**Decisions delta**: scope fixed to shipped content only (user-decided); three distinct `grep -oP` fix shapes identified; `sed -i` pulled in scope; genericization convention sourced from `branching.md` rather than invented; the two `commit-conventions.md` files confirmed intentionally divergent; `MKT` defect kept out of `shell-portability.md`; no `## Related` added to template files. All mirrored into `## Decisions`.

**Key files delta**: no files edited. `plan.md` created and revised. Full target list with verified line numbers mirrored into `## Key Files`.

**What the next phase needs**: the exact-line edit list in `## Key Files`; the three-shapes distinction (a naive `-oP`→`-oE` sweep breaks two of the four sites); the DO-NOT-EDIT list (`branching.md`, `.context/workflows/commit-conventions.md`, `.githooks/`); the mandatory `context_template/context/iconrc.json` `1.12`→`1.13` bump staged in the same commit; the `### N.` rule shape for `shell-portability.md`.

### Handoff: implementation → completion   (commit: <trailer-marked>)
**Sub-agent outputs**:
- 8 @coder dispatches (4 implementation + 3 remediation rounds + 1 final), 4 @reviewer passes (3 full at tier complex, 1 narrow confirmation), 1 @context-specialist maintenance pass. Every shell fix was **executed against fixtures on both success and failure paths**, not reviewed — that discipline is what caught all three remediation-introduced defects.
- Final @reviewer verdict: **approved**, with the explicit statement that issue #17's precondition (every live non-portable violation in shipped content cleared) is now met, verified by execution rather than reading.

**Reviewer findings**: Round 1 — 5 Moderate + 7 Minor, all remediated. Round 2 — 4 Moderate + 6 Minor, all remediated, including one regression round 1's own remediation introduced. Round 3 — shipped content approved, 1 Moderate in the standard, remediated. Round 4 (narrow) — no findings.

**Verification evidence**: `[check-rules-index] OK: all rule units indexed and all index rows resolve`; `[context-graph] OK: 49 nodes, no dangling references, no orphans`; `grep -rn MKT skills/ context_template/` → exit 1, zero hits; `.sh` trio and `.ps1` trio each byte-identical by checksum after every round; `.githooks/pre-commit` passed on all four commits (shellcheck skipped locally — not installed — and enforced in CI). ID generator executed across `0009→0010`, `0042→0043`, `0099→0100`, `9999→10000`, unset→`0001`. `mktemp` randomization confirmed across repeated runs with no leftovers. CDPATH regression reproduced under `CDPATH="."` and confirmed fixed. Rule 8's fail-open form reproduced under `set -euo pipefail` (script continued past a failed edit, exit 0) and confirmed fixed (exit 1, execution halts).

**Decisions delta**: scope extended twice with recorded reasoning (rest of the template's ICON identity; 10 further stale-prefix sites in `skills/`); `sed -i` replaced with temp-file-and-`mv` rather than `-i.bak`; four-digit padding retained; `**Types in use**` left concrete; `[.]` over `\.` with the rationale corrected to name bash semantics rather than a tooling artifact. All mirrored into `## Decisions`.

**Key files delta**: 13 files across `skills/`, `context_template/`, and `.context/standards/`, plus `CHANGELOG.md`, `retrospectives.md`, `retrospectives-archive.md`. Mirrored into `## Key Files`.

**What the next phase needs**: nothing — `completion` is the last phase. Three follow-up issues are recorded above and must be filed before the task is reported closed.

**Retro Stage-1 draft**: appended to `.context/retrospectives.md` as "ICON-0093: A portability fix that is read rather than run is a hypothesis" — Avoid: three consecutive rounds shipped a fix that had never been executed, and a sweep's self-report of completeness is not evidence. Repeat: classify before substituting (the three `grep -oP` shapes), and brief every re-review to assume the previous remediation introduced a regression. Updated: `shell-portability.md` § Testing Pattern.

## Progress
- [x] Investigation: verify all findings against live files — all four claims VERIFIED, zero drift; sweep found 3 additional shipped violations and cleared 5 false positives
- [x] Update this plan with investigation findings before any edit — Decisions, Key Files, Handoff Log written
- [x] Resolve scope question with user — shipped content only; ICON's own docs deferred to a follow-up issue
- [x] Implementation A — shell fixes in `skills/`: `initialize-monorepo:82` flag swap; `upgrade-repo:492,493` flag swap + `\d`→`[0-9]`; `upgrade-repo:495` `sed -i` → temp-file-and-`mv`
- [x] Implementation B — `context_template/.../commit-conventions.md` genericized: 20 `MKT` sites → `TICKET`/`PROJ`; line 74 `\K` command rewritten as a `sed` capture group; `iconrc.json` `1.12`→`1.13`
- [x] Implementation B2 — same file swept for the rest of its ICON identity: example commits, "scopes in use" list → derivation guidance, Copilot co-author trailer → `<assistant-name>` shape
- [x] Implementation C — `shell-portability.md` rules 7 (`grep -P`, with the three-shapes triage) and 8 (`sed -i` backup-suffix); rules-index needed no change
- [x] Implementation D — 10 further stale-prefix sites cleared from `skills/`: 7 parity copies of the retrospective example (`.sh`/`.ps1` byte-parity verified held before AND after), `create-iconrc:48` → `LOCAL-0092`, `upgrade-repo:633` re-expressed as an observable file-shape condition
- [x] Repo-wide verification: `grep -rn "MKT" skills/ context_template/` → exit 1, zero hits
- [x] @reviewer pass over the full diff — verdict **Changes requested**: 5 Moderate + 7 Minor. Shipped shell verified correct against fixtures and could not be broken; the defects were in the *standard* this task adds, plus two missed violations
- [x] Remediation round 1 (3 parallel dispatches) — Rules 7/8 mechanisms corrected; `mktemp -p` + `realpath` replaced; `sed` temp-file cleanup added; template polish incl. the octal ID-generation bug
- [x] Re-review (round 2, tier complex) — **Changes requested**: 4 Moderate + 6 Minor, including a **CDPATH regression introduced by round 1's own remediation**, and the finding that the `mktemp` fix had traded a loud macOS failure for a silent one
- [x] Remediation round 2 (2 parallel dispatches) — `mktemp` template `X`s moved to trailing + suffix dropped; `CDPATH= cd --` hardening; gawk `\#` warning removed; Rule 8 fence updated; `$MAX` wired; `upgrade-repo` `if`/`else` so failure exits non-zero
- [x] Re-review (round 3, tier complex) — shipped content **approved**, issue #17's precondition confirmed met by execution; **1 Moderate remained**: Rule 8's own fence was fail-open (`|| rm -f` returns 0, so a failed edit reads as success under `set -e`) — introduced by round 2's remediation
- [x] Remediation round 3 — Rule 8 fence → `|| { rm -f file.tmp; exit 1; }` plus an explicit caution naming the fail-open trap; `initialize-monorepo:76` `head -1` → `head -n 1`
- [x] Confirmation pass over the final 2-file delta (fail-closed on post-checkpoint change) — **approved**; the reviewer additionally ran the *old* fail-open form under `set -euo pipefail` as a contrast test and reproduced the silent continue-past-failure, confirming the fix closes it
- [x] `CHANGELOG.md` — two `### Fixed` entries under `[Unreleased]`; distinct subjects from the existing ICON-0088/0091/0092 entries, so appended rather than merged per the cumulative-effect rule
- [x] Retrospective — entry appended via `append-retrospective-entry.sh` (never hand-edited); the script run was itself a live exercise of this task's changes to it, and completed without incident (`10 -> 10 entries, pruned 1 oldest entry (cap 10)`). ICON-0083 rotated out to `retrospectives-archive.md`. Lesson promoted into `shell-portability.md` § Testing Pattern
- [x] Commits — four atomic commits, split by concern; the two files carrying both portability and prefix changes were split at hunk level rather than bundled
- [x] Filed follow-up issues #46 (GNU-only constructs in ICON's own non-shipped docs, incl. the 9 residual `head -1`), #47 (`context_template/UPDATE_LOG.md` ships ICON history — needs a design call, not a substitution), #48 (shellcheck never sees fenced bash in `.md`, feeds M4 #26)
- [ ] Push branch and open PR ← IN PROGRESS

## Review Checkpoint
- **Stamped**: after Implementation A–D, before remediation. @reviewer (tier complex) covered all 5 files then in the changed set.
- **Superseded**: remediation dispatches changed code after this stamp, so the close-gate requires a re-run over the post-checkpoint diff. Do not treat this checkpoint as covering the final state.
- **Verified clean by @reviewer, with evidence** — do not re-litigate: `grep -oE '"[^"]+\.csproj"'` behavior-identical to the `-oP` original on a real `.sln` fixture; `[0-9.]+` a faithful translation of `[\d.]+` (and the naive re-flag `-oE '[\d.]+'` reproduced as emitting `.` — the exact silent breakage Rule 7 warns about); the `sed -n 's/^TICKET-\([0-9][0-9]*\).*/\1/p'` rewrite equivalent to `grep -oP 'MKT-\K[0-9]+'` across no-suffix, short-width, foreign-prefix and junk fixtures, and *strictly better* because `^`-anchoring now excludes foreign prefixes the unanchored `grep` would have matched; `.sh`/`.ps1` byte-parity held before AND after across all six copies; the live `.context/workflows/commit-conventions.md` confirmed untouched; `plugin.json` untouched; `grep -rn MKT` over all shipped trees → exit 1.

## Open Questions / Blockers
- ~~Does `commit-conventions.md` generalization need a new placeholder convention?~~ Resolved: `branching.md` already establishes `TICKET` (dominant) + `PROJ` (secondary), and `process-doc-sweeps.md:40` names `TICKET-NNN` by contract.
- ~~Are there other GNU-only occurrences beyond the cited line?~~ Resolved: three more in shipped content, all now in scope.
- **Digit-width judgement call, delegated to @coder**: `commit-conventions.md` prescribes zero-padded four-digit IDs (`MKT-0023`) while `branching.md` uses unpadded (`TICKET-123`). These are different conventions in different files, not an inconsistency to flatten — the ID-generation section is inherently more prescriptive than branch-name examples. Genericize the *prefix* without silently loosening the *width* prescription.
- **Coverage gap noted, not fixed here**: `.githooks/pre-commit`'s shellcheck gate only fires on staged `*.sh` files, so fenced bash inside `SKILL.md` files — which is exactly where three of the four violations live — is never shellchecked. Relevant to Milestone 4 (#26 portability-check); out of scope for this task.

### Follow-up issues to file before closing
1. **ICON's own `.context/workflows/commit-conventions.md:58,89`** carries `grep -P` and the identical doubly-non-portable `grep -oP 'ICON-\K[0-9]+'`. Not shipped, so out of this task's user-set scope — but it breaks for any ICON maintainer on macOS exactly as the consumer-facing bug did.
2. **`context_template/UPDATE_LOG.md` ships ICON's internal history to consumers** — "Major overhaul of all agent definitions", "Copilot Memories not adopted: No IntelliJ support… 28-day expiration", Anthropic doc URLs. Same `process-doc-sweeps.md:40` violation as the `MKT` defect, in a different file. Deliberately **not** folded in: unlike a substitution, this needs a design call on whether the file belongs in `context_template/` at all, since a consumer has no use for ICON's template revision history.
3. **`.githooks/pre-commit` shellcheck gate never sees fenced bash in `.md` files** — the coverage gap above. Feeds Milestone 4 #26.

### `mktemp` — primary-source research, recorded so it is not re-derived
The `mktemp -p "$retro_dir" .retro_tmp_XXXXXX.md` line carried **two independent** portability defects, and the second is the dangerous one:

- **`-p` availability floor.** `-p` was added to FreeBSD `mktemp` in commit `ac6f924e` (2022-10-31); `releng/13.1` lacks it, `releng/13.2` has it. On macOS, Apple's shipped `shell_cmds` optstring is `"dqt:u"` through 279.120.2 and `"dp:qt:u"` from 302.0.1 — mapping via `distribution-macOS` `release.json`: macos-13.0 → 278, macos-13.5 → 279.120.2, macos-14.0 → 302.0.1. **Floor = macOS 14.0 Sonoma / FreeBSD 13.2.** Every macOS ≤ 13.x hard-errors `illegal option -- p`. (The man page HISTORY section is useless for dating this — it only mentions OpenBSD 2.1 / FreeBSD 2.2.7 and never mentions `-p`.)
- **Template shape, which survives even where `-p` works.** On macOS 14+/FreeBSD 13.2+, `-p` resolves the directory correctly but `mkstemp()` substitutes **zero** X's because of the trailing `.md`, creating a file named literally `.retro_tmp_XXXXXX.md` and exiting **0**. The next run then fails `mkstemp failed: File exists`.

So the line failed **loudly** on older macOS and **silently** on newer — and the newer, more dangerous behavior is the one that looks green under Linux CI plus a one-shot manual test on Sonoma. Correcting only `-p` (the first remediation) would have moved every consumer from the loud failure into the silent one.

The fix dispatched — `CDPATH= cd -- "$retro_dir" && mktemp .retro_tmp_XXXXXX`, with the `cd` supplying the directory instead of `-p`, and the `X`s trailing — sidesteps both defects and needs no version floor. Also noted from the same research, in case a future task reaches for `-p`: BSD blindly concatenates absolute templates (`/dir//abs/path`) where GNU hard-errors, and `-p ""` falls back to `$TMPDIR` then **CWD** on BSD versus `$TMPDIR` then `/tmp` on GNU.

### Why `[.]` and not `\.` in the `sed` version pattern — corrected rationale
`skills/upgrade-repo/SKILL.md` builds `INSTALLED_VER_RE=${INSTALLED_VER//./[.]}` so a version `1.12` cannot also match `1x12`. @coder originally recorded the reason as "unreliable backslash-doubling behavior through this environment's shell layer" — **that attribution is wrong and would mislead the next maintainer into thinking it was a tooling artifact.** It is a real bash semantic, reproducible on any bash: the replacement text of `${var//pat/repl}` does its own backslash processing, so the escape is consumed before `sed` ever sees it.

```
a  (\.)   = 1.12      vs 1x12 -> MATCHED   ← escape lost, false match
b  (\\.)  = 1\.12     vs 1x12 -> nomatch
c  ("\.") = 1\.12     vs 1x12 -> nomatch
d  ([.])  = 1[.]12    vs 1x12 -> nomatch
```

`[.]` is the right pick because it sidesteps the double-escaping question entirely rather than solving it — but it is a choice about bash, not about tooling.

Relatedly: `${var//pat/repl}` and `$((10#$MAX + 1))` are bash-only, not POSIX `sh`. Verified acceptable, on four grounds — the fence tag is ```` ```bash ````; `shell-portability.md:3` scopes itself to "**Bash** code shipped inside a `skills/*/SKILL.md`"; rule 1 of that standard *prescribes* `[[ =~ ]]` + `BASH_REMATCH` as the portable remedy; and the identical `${var//pat/repl}` construct already ships at `skills/generate-phase-launcher/references/launcher-templates.md:87`, in a template that emits `#!/usr/bin/env bash`.

### Review findings — disposition
- **M1** `shell-portability.md` Rule 8 mis-states its own mechanism, in inverted words ("unconditional on the sed succeeding") **and** claims a failed `sed` truncates the original via the redirect. Proven false: the redirect targets `file.tmp`, so the original survives regardless of `&&`. What `&&` buys is preventing a partial temp being `mv`'d over a good original. → **fixing**.
- **M2** Rule 7's prescribed fence `sed -E 's/^MKT-([0-9]+).*/\1/'` lacks `-n`/`p`, so it passes non-matching lines straight through — the shipped fix at `commit-conventions.md:74` is correct but the rule documenting it is not. → **fixing** (and dropping the stale `MKT` from the example, in the rule that documents removing it).
- **M3** `mktemp -p` is a GNU extension, live in all three shipped `append-retrospective-entry.sh` copies — **wrongly recorded in this plan as a cleared false positive**. Fails loudly under `set -euo pipefail` rather than corrupting data, but the helper three shipped skills call at every task close is dead on macOS. → **fixing**.
- **M4** `realpath` is not POSIX and is absent on macOS < 12.3; same three files, pre-existing on `main`, listed in neither the found nor the cleared set. → **fixing**.
- **M1+M3+M4 together invalidate this plan's earlier claim** that "every live non-portable-shell violation in the shipped trees is fixed." That claim was wrong when written; issue #17's stated precondition for the Milestone-4 check was not actually met. Recorded rather than quietly corrected — the sweep's *self-report of completeness* was the failure, not any individual miss.
- **M5** the `sed > tmp && mv` form leaves a 0-byte `.tmp` in the consumer's tracked tree on the failure path, undercutting the stated reason it was chosen over `sed -i.bak`. → **fixing**.
- **Minor, accepted**: malformed `Co-authored-by: <assistant-name> <assistant-email>` trailer (git wants `Name <email>`); "wherever `TICKET` appears below" when it also appears above; "Examples from the actual log" heading invented examples; Rule 7's `\d` mechanism imprecise for its own bracket-expression example (inside `[...]` POSIX gives backslash no meaning, so `[\d.]` matches `\`, `d`, or `.` — evidenced by `grep -oE '[\d.]+'` printing `.`); **and a real latent bug at `commit-conventions.md:76`** — the procedure now extracts zero-padded strings, and bash reads those as octal (`$((0042+1))` → 35; `$((0009+1))` → hard error), so the documented ID generator produces wrong IDs or crashes. Adjacent to a line already rewritten this task. → **all fixing**.
- **Minor, judgement delegated**: `**Types in use**: feat, fix, chore, docs, refactor` left concrete while the adjacent `**Scopes**` became derivation guidance. Types are a near-universal fixed vocabulary in a way scopes are not, so this may legitimately stay — @coder to decide and record reasoning rather than reflexively mirroring.
- **Deferred to completion phase**: `CHANGELOG.md` `[Unreleased]` already carries "(schema 1.11→1.12)" from ICON-0088; this task takes it to 1.13. Per `changelog-discipline`'s cumulative-effect rule that existing entry gets reconciled, not a second one appended.

## Constraints
- ICON is pure-content: no build step, no test runner, no package manager (ADR-005). Committed, dependency-free scripts run in place ARE in scope.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003. Do NOT bump it; this task is not a release.
- Any commit staging `context_template/` changes MUST bump `context_template/context/iconrc.json` `version` in the same commit (`.githooks/pre-commit` enforces this).
- Release guard: do not bump the plugin version, rename `[Unreleased]`, tag, or move `latest`. This task ends at an open PR.
- `python3` is not an assumed runtime; shipped shell must run on both GNU and BSD/macOS userlands (`.context/standards/shell-portability.md`).
