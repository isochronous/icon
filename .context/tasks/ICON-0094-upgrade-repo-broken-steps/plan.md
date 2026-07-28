## Task: ICON-0094
## Branch: feature/ICON-0094-upgrade-repo-broken-steps
## Objective: Fix seven discrete defects in `/upgrade-repo` (and the `find-context-template` guard it depends on) that cause silent failures, false findings, and destructive advice when upgrading an already-installed consumer repo. Closes GitHub issue #15 (ROADMAP.md Milestone 1, second item).
## Folder: .context/tasks/ICON-0094-upgrade-repo-broken-steps/

## Phase State
- **Phase plan**: investigation → implementation → completion
- **Completed**: investigation
- **Current**: implementation   (status: in-progress)
- **Next**: completion
- **Loaded skill**: task-plan-phase-implementation
- **Branch**: feature/ICON-0094-upgrade-repo-broken-steps
- **Attempts (current phase)**: 1

## Line-number baseline
ICON-0093 added **+6 lines** at old `489–500` of `skills/upgrade-repo/SKILL.md` (now 665 lines). Everything at/after old `501` shifted **+6**; everything before `489` is unchanged. So the issue's `:75-98`, `:110`, `:175`, `:434-443`, `:108-181` are still accurate; `:619-627` → **`:623-633`**; `:491-500`/`:502-513` → **`:491-506`**/**`:508-519`**.

## Decisions
- Task ID `ICON-0094` derived from `local_task_id_prefix` + next free slot in `.context/tasks/`, NOT from the issue number (#15) — `.context/workflows/commit-conventions.md` § Task ID Generation.
- Phase plan omits `architecture` and `testing`: seven bounded, independently-scoped defect fixes in a pure-content repo with no test runner (ADR-005). Verification is execution against fixtures + the `.githooks/pre-commit` gate set + @reviewer.
- Investigation is mandatory before any edit, for two reasons beyond the standard stale-ticket check (`.context/workflows/task-start-conventions.md`): the ticket is an audit follow-up with baked-in line numbers, **and ICON-0093 (merged this session, PR #49) edited `skills/upgrade-repo/SKILL.md` at lines 492–506 and 633** — squarely inside the range this ticket cites. Result: all seven defects VERIFIED except D2, which is partly closed, and D6, whose supporting evidence has drifted.

### Corrections to the ticket — do not implement it as written
- **D2's remedy in the ticket is backwards.** It says "rewrite the version-sync step with portable commands, **or reuse the PowerShell branch below it**". ICON-0093 already made the bash branch portable, and the bash branch is now the **stronger** of the two: it escapes the regex metacharacter (`${INSTALLED_VER//./[.]}`) and has a failure path that exits non-zero. The PowerShell branch has **neither** — it interpolates `$InstalledVer` raw into a `-replace` regex, and it has no error branch at all, so `Set-Content` failing still falls through to an unconditional success `Write-Host`. **The ticket's own stated symptom — "prints a success message while the version never changes" — is still live, in PowerShell, on the platform the ticket did not name.** Reusing PowerShell as the model would be a regression. **Do not touch bash `:491-506`.**
- **D6's stated consequence is wrong about the mechanism.** The ticket says missing footers "disable the dangling-reference detection". They do not — dangling detection runs over every resolved markdown link regardless of `## Related`. The real mechanism is worse: `domains/*.md` are content-kind, are **not** covered by `rules-index.md` (which indexes `standards/`/`workflows/`/`decisions/`), so in a pre-2.0.0 repo **every `domains/` file is an orphan** → `context-graph --check` exits 1 → `context-maintenance` invokes it as `… || exit 1` under a fail-closed contract → **the Phase 1 audit aborts on the orphan flood before reporting anything else.** The check is not blinded; it is permanently red until a human hand-applies what no skill emits.
- **D6's evidence has drifted.** "In this repo exactly one context file had them" is no longer true — commit `f6e134b` added footers to 19 docs; 22 files now carry them and the graph is green at 49 nodes. Do not justify the work on ICON's own tree being broken. **The correct evidence is that `f6e134b` had to be done by hand, because no skill emits the seam.**
- **Ticket D-numbers ≠ ICON-0090 audit D-numbers.** Mapping: ticket D1=audit D1(§2); ticket D2=the §3.7/§4 predicted-defect, **not** audit D2; ticket D3=audit D2(§3.9); ticket D4=audit D5(§3.6); ticket D5=audit D9(§1); ticket D6=audit D6(§3.13); ticket D7=audit D7(§3.2). Audit D3/D4/D8 are the "version model" the issue's opening line explicitly defers — **out of scope**.

### Scope decisions
- **No `context_template/` change, and therefore no `iconrc.json` bump.** Every fix is to skill *instructions*. Two specific temptations to refuse: D4 must NOT change `context_template/context/workflows/prune-context.sh` (its generic default is correct *as a template default*; the bug is the upgrade overwriting a customized copy with it), and D6 must NOT add `## Related` footers to the nine template content docs — ICON-0093 already considered and rejected exactly that for asymmetry, and it would not fix D6 anyway, since the footers must be derived from the *consumer's* file graph, which a template copy cannot do by definition.
- **D6's success criterion is `context-graph --check` exits 0 — not "every file has a footer".** Authority is `context-graph.sh:98-127`. In scope: `.md` under `domains/`, `standards/`, `workflows/`, `architecture/`, `testing/`, `styling/`, **including sub-directory files**. Out of scope: `README.md` at any depth (it is what *provides* `covers` edges), `overview.md`/`projects.md`/`rules-index.md` (always-reachable roots), `META.md` (not a node at all), `retrospectives*.md`, `iconrc.json`, everything under `tasks/`. And **ADRs are content-kind and orphan-checked but must NOT get a footer** (`context-document-guidelines:217`) — they earn reachability from `rules-index.md` rows and `**Supersedes**` bold-fields. ICON's own tree proves a footer is not the only way to be non-orphan: seven content docs have none and the graph is green, reachable via rules-index rows. Framing the criterion this way also stops a well-meaning agent bolting tenuous links onto scaffolds, which pollutes the graph the seam exists to serve.
- **D1 is worse than the ticket describes** and the fix must address four independent causes, not one: no non-zero exit anywhere (all four checks end in `echo`/`Write-Host`); the section is framed as troubleshooting *between* two other sections, so the skill's own documented read-and-use path never reaches it; the Claude Code bash check `[ -z "$TEMPLATE_DIR" ]` is **dead code** (`$TEMPLATE_DIR` is `"${CLAUDE_PLUGIN_ROOT}/context_template"`, never empty — it is `/context_template`, 16 chars, when unset) while its PowerShell twin correctly tests `$env:CLAUDE_PLUGIN_ROOT`; and the Copilot bash guard `[ ! -d "$TEMPLATE_DIR" ] && echo …` **exits 1 when the directory exists**, so pasting it into a `set -euo pipefail` caller aborts on the success path.
- **D1's two silent consequences are the ones worth fixing**, not the loud `ItemNotFoundException`: `upgrade-repo:120-129` misclassifies stock files as CUSTOMIZED (with a bogus `$TEMPLATE_DIR`, `diff` exits 2, its stderr suppressed, and the `if` reads any non-zero as "differs" — shell-portability Rule 4's failure class applied to `diff`); and `upgrade-repo:492-506` **writes an empty version and reports success** (`TEMPLATE_VER=""`, `[ "1.2" != "" ]` is true, `sed`/`mv` both succeed, output reads `iconrc.json version: 1.2 → ` while leaving `"version": ""` in the consumer's file). **That corruption path survived ICON-0093** — the `if`/`else` it added guards `sed` failure, not an empty template version.
- **D4 is the destructive one and has a trap.** "Move the `cp` inside the condition" fixes the wording and leaves the behavior wrong: on the common path (script present *with* a named `INTEGRATION_BRANCHES`) the correct action is not "skip the copy" but **extract → copy → restore**. Skipping the copy means consumers never receive genuine script-logic updates. Both halves are required to satisfy the mistakes table at `:661` (preserve the regex) *and* `:443`'s legitimate intent (ship current logic). There is also a **second, independent unconditional write** to the same variable at `:453-454` — any fix that ignores it leaves half the hazard.
- **D3's distinguishing signal is position, not pattern.** A real ticket prefix sits at the **start** of a commit subject; `ADR-005` style document references appear mid-subject and are unreachable by refining `[A-Za-z]{2,}-\d+`. Verified live: `git log --format='%s' -100 | grep -oE '^[A-Za-z]{2,}-[0-9]+'` drops `ADR` entirely with zero loss of real signal. Note `--format='%s'`, not `--oneline` — the latter's leading SHA defeats `^` anchoring. And the prose must be written with **`[0-9]+`, not `\d+`**: a coder transliterating `\d` into `grep -oE` walks straight into shell-portability Rule 7's silent-mismatch case.

## Key Files
- `skills/upgrade-repo/SKILL.md` — the primary target. Cited defect sites: `:75-98` (unguarded root write), `:104` (template-path caller), `:110` (directory checklist), `:175` (prefix collision), `:434-443` (pruning script), `:491-500` vs `:502-513` (version sync), `:619-627` (verify step). **Line numbers are pre-ICON-0093 and have shifted** — investigation must re-derive them.
- `skills/find-context-template/SKILL.md` `:59-99` — the template-locating checks that exist but are advisory; must become a mandatory non-zero-exit guard.
- Callers of that guard: `context-specialist-impl-leaf:113`, `context-specialist-impl-root:219`, `context-specialist-impl-branch:108`, `upgrade-repo:104`.
- `context-specialist-impl-leaf:287-294`, `context-specialist-impl-root:206-213` — the working `## Related` footer generation to model the missing `/upgrade-repo` step on.
- `.context/tasks/ICON-0090-dogfood-upgrade-repo/upgrade-audit.md` — the dogfood run that observed every one of these (defects D1, D2, D5, D6, D7, D9; findings `M-89-03-01`, `M-89-03-03`).
- `context_template/context/iconrc.json` — currently `1.13`; bump required in the same commit **only if** `context_template/` is touched.
- `CHANGELOG.md` — `[Unreleased]` entry at task close.

## Phase Handoff Log

### Handoff: implementation → completion   (commit: <trailer-marked>)
**Sub-agent outputs**: 1 Explore investigation, 11 @coder dispatches across 3 implementation waves and 5 remediation rounds, 6 @reviewer passes (5 full at tier complex, 1 narrow confirmation). Final verdict **approved**, executed in both shells and both PowerShell strictness modes.

**Reviewer findings**: R1 1 Critical / 3 Moderate / 7 Minor · R2 1 Critical / 1 Moderate / 2 Minor · R3 3 Moderate / 5 Minor · R4 1 Critical / 2 Moderate / 4 Minor · R5 1 Moderate · confirmation pass 0. All Criticals and Moderates remediated; 5 Minors declined with recorded reasons.

**Verification evidence**: `[check-rules-index] OK: all rule units indexed and all index rows resolve`; `[context-graph] OK: 49 nodes, no dangling references, no orphans`; `manifest OK ICON 2.0.0`; `git status --porcelain context_template/ .claude-plugin/` → empty. R5's independent matrix: 208 D4 runs (26 cases × 2 EOL × 2 shells × 2 strictness modes) with 26/26 passing in all 8 configurations and byte-identical cross-shell output; 144 cross-EOL runs; 72 guard runs across 9 hardened blocks with zero fail-opens; 3-pass idempotency 24/24 stable. Denylist measured before/after: `agree=77 UNSAFE=22 OVER-REJECT=2` → `agree=118 UNSAFE=1 OVER-REJECT=3`, 0 regressions across 36 realistic branch regexes.

**Decisions delta**: two ticket instructions corrected as wrong-as-written (D2's "reuse the PowerShell branch" would have been a regression; D6's stated mechanism was wrong); D6 scoped by `context-graph`'s own classifier with ADRs excluded and the success criterion set to a green graph rather than a footer on every file; four pre-existing fail-opens folded in rather than split; the `.mjs` migration decision and its follow-on actions recorded above. All mirrored into `## Decisions`.

**Key files delta**: `skills/upgrade-repo/SKILL.md` (the bulk), `skills/find-context-template/SKILL.md`, `skills/create-iconrc/SKILL.md`, and one caller sentence each in the three `context-specialist-impl-*` skills. No `context_template/` change, so no `iconrc.json` bump. Plus `CHANGELOG.md` and this plan.

**What the next phase needs**: nothing — `completion` is last. Three follow-on actions are owed *after* merge and are recorded under the `.mjs` decision above: widen #23's scope, reorder the roadmap to put M3 next, stop writing new PowerShell twins.

**Retro Stage-1 draft**: see `.context/retrospectives.md` — "ICON-0094: The failure path adjacent to the fix".

### Handoff: investigation → implementation   (commit: <trailer-marked>)
**Sub-agent outputs**: one Explore pass (tier complex) over `skills/upgrade-repo`, `find-context-template`, the three `context-specialist-impl-*`, `create-iconrc`, `context-maintenance/scripts/context-graph.{sh,ps1}`, `context-document-guidelines`, `.githooks/pre-commit`, and the ICON-0090 dogfood audit. All seven defects addressed; line drift re-derived from scratch. Full report preserved at `.context/tasks/ICON-0094-upgrade-repo-broken-steps/investigation-report.md`.

**Reviewer findings**: N/A this phase (read-only).

**Verification evidence**: `git checkout -b feature/ICON-0094-upgrade-repo-broken-steps` → switched, tree clean. D3 reproduced live on ICON: `git log --oneline -100 | grep -oE '[A-Za-z]{2,}-[0-9]+' | sed 's/-[0-9]*$//' | sort | uniq -c` → `70 ICON / 7 ADR / 1 adr`, and the anchored form → `55 ICON` only. `context-graph --check .context` → `OK: 49 nodes, no dangling references, no orphans` (so ICON's own tree is healed; the skill gap is not). Zero occurrences of `## Related`, `context-graph`, `graph`, `seam`, or `orphan` in `skills/upgrade-repo/SKILL.md`, confirming D6.

**Decisions delta**: ticket corrections for D2 and D6 (both would produce wrong work if implemented as written); no `context_template/` change and no iconrc bump; D6 scoped by `context-graph`'s own classifier with ADRs excluded; D1 widened to four causes; D4 identified as extract→copy→restore, not skip-the-copy. All mirrored into `## Decisions`.

**Key files delta**: no files edited. `plan.md` created and revised; investigation report persisted.

**What the next phase needs**: the wave plan below; the three hook-gate traps in `## Open Questions`; the rule that ICON is a degenerate test target for `/upgrade-repo` (in a dogfood run `$TEMPLATE_DIR` resolves to ICON's own working tree — verification must use a scratch fixture, not `.context/`).

## Progress
- [x] Investigation — all 7 defects addressed; line drift re-derived; two ticket instructions found wrong-as-written
- [x] Update this plan with findings before any edit
- [x] **Wave A** (3 agents, disjoint), all verified by execution:
  - **D1** — `find-context-template` advisory section → mandatory `## Validate` step exiting non-zero across all four shells, testing `$TEMPLATE_DIR/context` rather than the variable; dead `-z` check deleted and its false prose corrected; the four caller sentences plus `create-iconrc:60` now name the guard and require halting. Two additions beyond spec, both sound: PowerShell tests `-PathType Container` so a `context` *file* can't pass PS while failing bash (a latent parity gap), and `create-iconrc` uses `${TEMPLATE_DIR-}` so the guard survives `set -u` long enough to report a never-set variable.
  - **D5** — root `claude.md` redirect now behind the house show-and-confirm pattern, with the redirect body shown and a stated reason to decline; `[ -f ]` guards byte-identical.
  - **D3** — collision check rewritten as a `**Special check**` block with bash *and* PowerShell: `git log --format='%s'` (not `--oneline`, whose SHA defeats `^`), anchored `^[A-Za-z]{2,}-[0-9]+`, local prefix removed from the set before comparison, finding names the external prefix. Handoff to `create-iconrc`'s `forbidden_prefixes` made explicit. @coder declined the optional `decisions/NNN-*.md` cross-check as not worth a second data-source dependency for one edge case — accepted.
- [ ] **Wave B** (2 agents): D4+D2 (contiguous Phase 2 territory, one owner) ← IN PROGRESS · D7+D6 ✅
  - **D7** — `decisions/` added to the Phase 1 checklist with a sentence naming *why* it was invisible; new Phase 2 "Restore `decisions/` if absent" step (bash + PowerShell, `excludes`-honouring, idempotent) placed **before** rules-index generation.
  - **D6** — new Phase 1 audit bullet + new Phase 2 "Emit the `## Related` graph seam" step after rules-index generation.
  - **The hard number investigation could not produce, now measured.** Synthetic pre-2.0.0 fixture (16 content docs, zero footers, no rules-index): **14 of 16 orphaned, exit 1, zero dangling refs** — confirming the mechanism is an orphan flood, not blinded dangling detection, and that it is what keeps `context-maintenance`'s `… || exit 1` permanently red. Recovery in the step's own order: rules-index generation 14→8 orphans, footers 8→1, one `orphan-ok` marker → `OK: 21 nodes`, exit 0. The two ADRs were **not** orphaned (covered by `decisions/README.md`), independently confirming the ADR-exclusion rule.

### Finding: a footer creates out-edges; orphan status turns on the in-edge
@coder's first draft said "append a footer to each flagged doc" — and the fixture proved that insufficient: after all 8 footers, `styling/style-guide.md` was **still an orphan**, because a `## Related` section points *outward* and orphan status depends on some *other* doc naming it. The new step says so explicitly, and its escape-hatch trigger is "no other doc's body names it" rather than "no relationships at all".

**Both sibling implementations carry the same phrasing** (`context-specialist-impl-leaf:291`, `impl-root:210`). It does not bite there — they generate a whole tree at once, so in-edges appear as a side effect — but the wording is equally imprecise. **Not fixed here** (out of this task's scope, and they are not broken in their own context); candidate follow-up.
- [x] **Wave C** — consolidated Phase 4 pass: item 1 reworded so it can actually fail after a blind overwrite (it now names the template default explicitly), item 6 accepts the declined-prompt path, item 10 appended for the graph seam. List contiguous 1..10.
- [x] **@reviewer round 1** (tier complex) — every new fenced block extracted from the shipped markdown and executed on bash 5.3 and PowerShell 7. Verdict **changes requested**: 1 Critical, 3 Moderate, 7 Minor.
- [x] Remediation round 1 (2 agents) — Critical 1 fixed three ways (selector anchored on `CURRENT_BRANCH`; capture runs to the closing `]]`; captured value validated before writing, refusing loudly on no-match/unparseable/unusable); Moderates 2–4 and Minors 5, 6, 8, 11 all fixed
- [x] **@reviewer round 2** (tier complex, execution-based) — **changes requested** again: 1 Critical, 1 Moderate, 2 Minor. Six of seven ticket items confirmed satisfied; **D4 not**.
- [x] Remediation round 2 (2 agents) — row-1 selector relaxed to catch `export`/indented assignments; row-2 discrimination rebuilt as a single pass that skips comments, counts live assignments and `=~` occurrences, and validates the capture in four stages; PowerShell guards fixed to lead with `-not (Test-Path Variable:\TEMPLATE_DIR)` — **90/90** across both shells and both strictness modes
- [x] **@reviewer round 3** — 3 Moderate, 5 Minor, **no Critical**. Attacked 37 fixtures × 2 shells and could not produce a shape that destroys a good value while reporting success on the mainline LF/POSIX path.
- [x] Remediation round 3 — all 8 findings addressed (finding 8's *handling* declined with reasoning, message fixed)
- [x] **@reviewer round 4** — 1 Critical, 2 Moderate, 4 Minor. Row-2 operand anchoring (round 1's Critical in its third disguise) attacked with 28 fixtures × 4 EOL combinations × 2 shells and **could not be broken**. CRLF handling exact at 240/240.
- [x] Remediation round 4 — **systematic error-path sweep**, per @reviewer's recommendation, rather than three point fixes
- [x] **@reviewer round 5** — **1 Moderate**, and it was precisely the one row the round-4 sweep resolved by *reasoning* instead of executing. Happy paths verified clean across 208 D4 runs, 144 cross-EOL runs, 72 idempotency runs — zero regressions, zero cross-shell byte disagreement. @reviewer explicitly declined to manufacture further findings.
- [x] Remediation round 5 — the audit-block guard (a paste of the guard already used at four other sites), the missing-key guard widened, and a documenting comment on the block deliberately left alone
- [x] **@reviewer confirmation pass** — **approved**, executed in both shells and both PowerShell strictness modes; regression spot-check on two untouched hardened guards and a D4 row-1 byte comparison found no divergence
- [x] `CHANGELOG.md` — three `### Fixed` entries under `[Unreleased]`; distinct subject from the existing ICON-0088/0091/0092/0093 entries, so appended rather than merged
- [ ] Retrospective, commit, PR ← IN PROGRESS

### Round-5 finding — the sweep's own boundary
`:152-164`'s PowerShell audit block reported a genuinely CUSTOMIZED `task-workflow-template.md` as **stock** on an unresolved `$TEMPLATE_DIR` — in **default (non-StrictMode)** PowerShell, which is what a consumer actually runs. `Get-Content` errors non-terminating and yields `$null`; `Compare-Object` then fails parameter binding leaving `$diff = $null`; `if ($null -eq $diff)` is the "stock" branch. A null result is indistinguishable from "no differences".

Not report-only in consequence: Phase 2 handles "stock" with an unconditional `git rm` and no migration, so the team's customizations are deleted. **The bash twin's false finding pointed the safe way (CUSTOMIZED ⇒ migrate first); PowerShell's pointed the destructive way.** Same repo, two shells, opposite advice.

@reviewer's own framing of why this was the only finding: *"the decision is wrong, but the instinct to enumerate it was right — it was the only row resolved by reasoning instead of execution, and it is the only row that turned out to be a defect."*

### The pattern, named by @reviewer in round 4 — the most useful artifact of this task
> **Each round has fixed the happy path it was aimed at and left the failure path adjacent to it unguarded — first the extractor, then the guard, then the diagnostic, now the handler.**

Round 4's Critical was a `catch` block interpolating `$TEMPLATE_DIR` — *the very variable whose absence caused the failure* — so under `Set-StrictMode` the catch itself threw, `exit 1` never ran, and execution fell through to the success message. `:1245`'s own comment says reporting `Restored:` in that case "is the ticket's own headline symptom". **The code did what its own comment forbade.**

The round-5 remediation was therefore scoped as a class sweep: read every `catch {}`, `else {}`, `|| {}` and refusal path in all 23 fenced blocks and ask of each — *can this handler itself fail, and if it does, what prints next?*

### Round-4 findings — disposition
- **CRITICAL — D7's PowerShell restore fail-open** (never-set `$TEMPLATE_DIR` + StrictMode): `Restored:` at exit 0 with `.context/decisions` absent. Permanent damage — `rules-index.md` is generated next and never overwritten, baking in an ADR-less index. → fixed; 8/8 PowerShell combinations now exit 1.
- **MODERATE — the `:992` twin**: `Preserving` *and* `Restored` at exit 0 having copied nothing. → fixed.
- **MODERATE — unguarded cleanup before `exit 1`** at `:1024`: a terminating error in the cleanup abandons the catch, so `Restored:` printed at exit 0 while the disk carried the template default and the consumer's value was destroyed. bash failed closed on the identical injection. → fixed.
- **MODERATE — the ERE/.NET subset claim was still false**: 18 violations across 13 shapes, including lazy quantifiers (`^(release/.+?)$`) and top-level half-deleted alternation (`main|`, `|develop`) — the rule's own stated motivation, written without parens. → both halves done: cheap rules added, **and** the false invariant in the shipped comment rewritten to a best-effort claim. Measured before/after: `agree=77 UNSAFE=22 OVER-REJECT=2` → `agree=118 UNSAFE=1 OVER-REJECT=3`, with 0 regressions across 36 realistic branch regexes. Trade accepted deliberately: 3 loud refusals in exchange for 22 silent repo-wide pruning disablements, both residuals documented in the shipped comment.
- **MINOR — over-rejection of an escaped backslash** (`^(a&b|c\\d)$` is valid ERE) → fixed via `(?<!\\)(?:\\\\)*\\`.
- **MINOR — the corrected grammar premise named the wrong rejecting step**: the whitespace shape exits at the *parse* error, not the validity probe. Outcome right, mechanism off by one — **the third time an unexecuted mechanism claim reached a comment in this file.** → corrected.
- **MINOR ×2 — declined and recorded**: a decoy `=~` inside a string when it is the file's *only* match (needs a shell tokenizer to distinguish; @reviewer explicitly did not ask for a parser); a trailing-newline edge that is unreachable with the shipped template.

### Four further fail-opens the sweep found, beyond the three reported
Two are in **pre-existing** content, not introduced by this task:
- **b13 legacy rename** — `git` absent ⇒ `$LASTEXITCODE` unset ⇒ StrictMode abandons the check ⇒ prints `Renamed …` *and* `No existing INTEGRATION_BRANCHES`, then copies the template default while the consumer's real value sits in the un-renamed legacy file. Exit 0. bash twin was already clean.
- **b19/b20 task-plan installer** — `Installed: … (6 files)` over an empty directory, exit 0, **both shells**. Hardcoded count.
- **b16 `.gitattributes`** — `Ensured …` printed after an append that wrote nothing.
- **b18 version sync (PowerShell)** — silent skip at exit 0 where bash exits 1.

**Scope note for the PR**: b15, b16, b19, b20 are pre-existing, so the diff now reaches beyond this task's six original regions. Kept rather than split — issue #15's framing is "silent failures and false findings", and these are exactly that, in the same file, found by the sweep the ticket's own defects motivated.

### Mid-task user decision: `.mjs` becomes the standard, and M3 moves next
The user raised, mid-implementation, that ICON is migrating to `.mjs` scripts as a standard, and asked why this task was fixing PowerShell. **The challenge was substantially correct and should have been surfaced by me, not by them** — the investigation report explicitly listed `.sh`/`.ps1` parity obligations for these fixes, and ROADMAP.md's Milestone 3 was read at session start. That was the moment to ask whether to invest in PowerShell parity or write bash-first pending migration.

**What is and isn't duplicated work.** #23's scope is *script files* — the `.sh`/`.ps1` pairs under `skills/*/scripts/`, `prune-context.sh`, the structural checker; it enumerates them. Nearly all of this task's PowerShell work is in **fenced blocks inside `skills/upgrade-repo/SKILL.md`**, which #23 does not list. So literally, not redone by #23 as scoped.

**Why that reading is too generous.** #23's *rationale* — "that convention has drifted three times", "every shell script is linted automatically and no PowerShell linter exists anywhere, so half of each pair is verified and half is not" — describes this task exactly. After round 1, **every Critical and Moderate was PowerShell-specific or a bash/PowerShell divergence**: round 2's guard failing open, round 3's missing `[regex]::Escape` and absent failure path, round 4's `catch` throwing under StrictMode, round 5's `Compare-Object` null-binding read as "no differences". Roughly half the review cycles went into PowerShell behaviour a Node migration deletes.

**Decision (user, this turn): land ICON-0094 as-is, then move Milestone 3 to the front of the roadmap.** Rationale for landing: the defects are live for consumers now, the work is verified, and M3 has not started (#22 is its prerequisite and is not built). Rationale for reordering: every further M1/M2 fix inside a `SKILL.md` incurs the same doubled cost, so migrating first makes all remaining roadmap work cheaper. Costs a roadmap reorder and delays #14/#16/#18.

**Follow-on actions owed after this PR merges** (not part of this task's diff):
1. Comment on #23 widening its scope to fenced `SKILL.md` blocks, citing this task's five rounds as evidence.
2. Reorder ROADMAP.md so M3 (#22 → #21 → #23) precedes the remainder of M1 and M2.
3. Stop writing new PowerShell twins in subsequent roadmap tasks pending the migration.

### Harness trap #5, new and worth carrying furthest
**`exit N` inside a dot-sourced script does not propagate through `pwsh -File` — it reports 0.** Every PowerShell exit-code assertion made by dot-sourcing is meaningless. The harness was rebuilt to *concatenate* blocks into the driver. Two prior rounds' PowerShell exit-code claims were made this way and should be treated as unverified where not since re-run.

### Round-3 findings — disposition
- **MODERATE 1 — the new `decisions/` restore step reported success it did not perform**, both shells, rc=0, with `.context/decisions` absent. **The ticket's own headline symptom, reproduced in code added by the fix for that ticket.** Reachable exactly when `find-context-template`'s guard was skipped — the case everything else this round hardened against. Durable consequence: `rules-index.md` is generated next and never overwritten once created, so a silent no-op bakes in an ADR-less index permanently. → fixed with D4's own `|| { …; exit 1; }` / `try`/`catch` shape.
- **MODERATE 2 — the .NET normalisation comment's central claim was false, and PowerShell was the unsafe side.** `(?:`, `\d`, `(?i)`, `(?<x>`, `^*` are all rejected by bash ERE and accepted by .NET. Bash is the runtime that consumes the value: an ERE-invalid pattern makes the guard's negated test return 2, `!` inverts it to true, and `prune-context.sh` takes the early `exit 0` — **pruning disabled repo-wide**. So PowerShell would ship a hook that never prunes while bash cleanly refused the same repo. → fixed with a denylist making PowerShell's accept-set a subset of bash's.
- **MODERATE 3 — CRLF.** Reported as one stray `\r` on a row-1 line; **found to be larger**. With a CRLF *template* (the ordinary Windows case — `git ls-files --eol` reports `i/lf w/crlf`, and `core.autocrlf=true` is the Windows default) bash and PowerShell diverged on **all 18 restoring fixtures**, and PowerShell contradicted *itself*: row 4's `Copy-Item` kept CRLF while rows 1/2 normalised to LF. → fixed by stripping CR from the saved value and having the replaced line adopt the destination line's own terminator.
- **MINOR 4 — round 1's Critical in its third disguise**: row 2 anchored on the *substring* `CURRENT_BRANCH` rather than on it being the `=~` left operand, so `if [ -n "$CURRENT_BRANCH" ] && [[ "$CACHE_DAYS" =~ ^[0-9]+$ ]]` restored the TTL regex at rc=0. Rated Minor only because no such shape exists in ICON's history. → fixed, plus a second bug the substring fix alone would have relocated (parsing now starts from the *matched* `=~`, not the line start).
- **MINOR 5 — the `[[ ]]` grammar premise was factually wrong.** "An unquoted operand containing whitespace is a syntax error" is false: whitespace is legal wherever paren depth > 0 (`[[ "$b" =~ ^(main| dev)$ ]]` matches). The approach survives — any capture stopping at such whitespace leaves an unbalanced `(` that the validity probe rejects — but the stated justification was not the reason it worked, and that comment is the load-bearing rationale for the entire capture regex. → reworded to the true reason.
- **MINOR 6, 7, 8** — false prose about `decisions/` shipping an ADR template (it ships `README.md` only); PowerShell restore made atomic via `.tmp` + `Move-Item -Force`; finding 8's handling declined (distinguishing a comment `#` from a literal `#` inside a regex is exactly the guessing this section refuses everywhere else) with only the misleading message fixed.

### @coder departed from three specified fixes, each measured — all accepted
- `\\[A-Za-z]` as I specified would have **over-rejected**: bash *does* accept `\w \W \s \S \b \B`. Narrowed to `\\(?![wWsSbB])[A-Za-z]`.
- `^[*+?{]` **does not catch its own example** `^*main$`, which starts with `^`. Corrected to `^\^?[*+?{]` plus `[(|][*+?{]`, keeping `^[^*]$` accepted.
- Added an empty-alternation rule not on my list — bash rejects `^(main|)$`, .NET accepts it; same defect class, and it is what a half-deleted branch name leaves behind.

A specified fix is a hypothesis too. Measuring it before applying it is the behaviour to keep.

### Harness traps accumulated across rounds — carry forward
1. This host checks out CRLF, and **both `sed` and `awk` silently strip `\r` on output** while `cmp`, `od` and `tr` do not. Two agents produced false results this way. Where the defect under test *is* about line endings, a `sed`/`awk` step anywhere in the pipeline masks it.
2. POSIX exempts non-final commands in an `&&` list from `set -e`, so a guard's inversion can look absent until tested the way a caller actually consumes it.
3. `bash` is not on PATH in the PowerShell tool, so a fixture-rebuild script silently never ran and a whole PowerShell round tested stale fixtures.
4. Slicing an expectation through an interpreter can corrupt it (`awk` collapsing `\&`) — slice expectations directly from the committed fixture.

### Round-2 findings — disposition
- **CRITICAL — the row-2 path still corrupts on two reachable shapes, both at exit 0 with `Restored:` printed.**
  - **Shape A — a commented-out branch test above the live one.** The selector takes the first *textual* `CURRENT_BRANCH.*=~` match, comment or not. A repo that narrowed to `^(main)$` and left the old line commented — an ordinary editing habit — gets pruning silently re-armed on `dev`/`develop`/`trunk`.
  - **Shape B — a row-1 bug surfacing in row 2, and worse.** Row 1's selector is `^`-anchored, so it **misses `export INTEGRATION_BRANCHES=` and any indented assignment**. Those repos *do* have a named variable and belong in row 1, but fall through to row 2, which matches the stock `if [[ ! "$CURRENT_BRANCH" =~ $INTEGRATION_BRANCHES ]]` line and captures the **literal variable reference**. The regex-validity probe passes, because `$INTEGRATION_BRANCHES` is a valid ERE. Result: the real value is destroyed *and* the consumer's post-commit hook errors on every commit with `INTEGRATION_BRANCHES: unbound variable`. A lowercase `integration_branches=` is a third trigger, where the shells **diverge** — bash corrupts, PowerShell restores the lowercase line but drops the uppercase one the guard reads; both end broken.
  - Phase 4 item 1 catches Shape A only if the commented value happens to equal the template default, and Shape B not at all — because a value *was* restored. → **fixing both halves**: row 2 must skip comments and refuse on a bare-variable capture; row 1's selector must stop kicking named-variable scripts into row 2 in the first place, with the PowerShell selector's case sensitivity aligned to bash's.
- **MODERATE — the PowerShell guard fix *relocated* the fail-open rather than removing it.** Under `Set-StrictMode`, the throw moved from `Join-Path` to the null-check added to fix it; the `if` condition never yields, the body is skipped, execution continues at **exit 0**. The previous agent's report that StrictMode gives "a harder failure" is contradicted by execution — it is **softer**: a silent continuation, not a hard stop. The shipped prose asserting the reorder closes the hole must be corrected alongside the code. → **fixing**, leading with `-not (Test-Path Variable:\TEMPLATE_DIR)` — which `create-iconrc:70` already computes one line above.
- **MINOR 3 — greedy/lazy divergence.** bash `(.*[^[:space:]])` matches to the **last** `]]`; PowerShell `(.+?)` to the **first**. Neither writes a wrong value, but the same repo upgrades on one shell and hard-stops on the other (trailing `# see [[branching]]` comment: bash refuses, PowerShell restores; a regex containing `[]]`: the reverse). ADR-004. → **fixing**.
- **MINOR 4 — guard-shape inconsistency**: `find-context-template:90` uses bare `"$TEMPLATE_DIR"` where `create-iconrc:62` uses `${TEMPLATE_DIR-}`. Fail-closed either way, so cosmetic — but the block's own diagnostic is more useful than bash's `unbound variable`. → **fixing**.

### Mechanism dispute — adjudicated in @coder's favour
@reviewer independently reproduced it and reversed round 1's framing. `^[A-Za-z]` (balanced) does match every branch, **but it is not producible** by a capture stopping before `]`; every realistic branch regex truncates to an *unbalanced, invalid* pattern:
```
^(main|rel-[0-9]+)$        -> ^(main|rel-[0-9    INVALID (rc=2)
^release/[0-9]{4}$         -> ^release/[0-9      INVALID (rc=2)
```
and an invalid regex makes the guard's negated test true on every branch → early `exit 0` → **pruning disabled repo-wide**. Only the balanced form over-prunes, and the balanced form was unreachable.

**The retrospective lesson is therefore "silent corruption that disables the safety mechanism", not "over-pruning that deletes task folders."** One nuance worth keeping: it is not *fully* silent — bash prints `brackets not balanced` to stderr on every commit — which is why the new code's decision to leave that diagnostic visible is correct rather than untidy.

### Correction to the review's Critical framing — carry forward
@reviewer stated the truncated `^[A-Za-z]` "matches every branch", causing `rm -rf` of task folders on feature branches. **Not reproducible, and not reachable.** The old capture class stops *before* the first `]`, which necessarily leaves the `[` unclosed, so every bracket-containing shape truncates to an **invalid** regex (`rc=2`):
```
^(main|rel-[0-9]+)$  -> ^(main|rel-[0-9   INVALID
^[A-Za-z]+/main$     -> ^[A-Za-z          INVALID
```
An invalid value makes `[[ ! "$CURRENT_BRANCH" =~ $BAD ]]` true on every branch → early `exit 0` → **pruning silently disabled repo-wide**. So both bugs converge on the *same* consequence; only one of the two stated outcomes exists. Defect, severity and fix are unchanged — silent corruption of a consumer customization, reported as `Restored:` at exit 0.

Worth recording *how* this was caught: @coder had copied the review's wording into a shipped code comment, then its own experiment contradicted it. A reviewer's mechanism claim is a hypothesis until executed, exactly as much as a coder's.

### Two process notes from remediation, both near-misses
- A `r2_meta` byte-equality check read FAIL until traced to **awk collapsing `\&` in the expectation string**, not in the code under test. Fixed by slicing the expectation directly from the committed fixture rather than round-tripping it through shell quoting — the harness, not the subject, was wrong.
- A PowerShell rerun silently tested **stale post-run fixtures**, because `bash` is not on PATH in the PowerShell tool so the fixture-rebuild script never ran. Exposed only because Row 4 printed `Preserving` instead of `No existing`. Reported results are from rebuilt fixtures.

## Review Checkpoint
- **Stamped**: after Waves A–C, before remediation. Superseded by remediation — the close-gate requires a re-run over the post-checkpoint diff.
- **Verified clean by @reviewer, with executed evidence — do not re-litigate**: D4 rows 1/3/3b/4 and all failure paths (a value containing `^ $ ( ) | & \` survived byte-exactly, and `diff` vs template confirmed *only* line 24 differs, so template logic genuinely lands); the legacy rename preserves the `.githooks/post-commit` reference; both-present and template-lacks-variable both exit 1 with the original intact and no stray `.tmp`; D2's four claims (`1.2` no longer clobbers a nested `1x2`, read-only target exits 1, empty template version aborts, and the bash hunk is a **pure insertion** — `@@ -493,0 +730,7 @@`, zero lines removed — so ICON-0093's body is untouched); D3's anchored extraction on real and synthetic histories with character-identical PowerShell output; D6's scope boundary reproduced on a fixture including that an *inbound* footer clears three orphans at once while the orphan's *own* footer clears its target instead; D7's ordering, idempotence and `excludes`; Phase 4 numbering; `context_template/` and `.claude-plugin/` untouched; no `grep -P`, `sed -i`, `if <tool>` guard, `/dev/null`, or `|| rm -f` shortcut in any added line; hunk map matches the six assigned regions exactly — **no agent strayed into another's work**.

### Review findings — disposition
- **CRITICAL 1 — D4 row 2 writes a corrupted `INTEGRATION_BRANCHES` while reporting success, on both shells.** Two stacked bugs: the extractor takes the **first** `=~` in the file, which is the cache-TTL test (`$PARSED =~ ^[0-9]+$`) not the branch test; and the capture class excludes `]`, truncating any regex containing a bracket expression. Observed: real value `^(trunk|release/.*)$` → restored as `^[0-9`, exit 0, with `Preserving existing value:` printed. **Destructive both ways** — a truncated `^[A-Za-z]` matches *every* branch, so the pruner `rm -rf`s 90-day-old `.context/tasks/` folders on feature branches; a truncated `^[0-9` is an unbalanced bracket that disables pruning entirely. Phase 4 item 1 cannot catch it, because a value *was* restored. → **fixing**: anchor on `CURRENT_BRANCH`, capture to the closing `]]`, validate the capture is a usable regex before writing, and fall through to the existing refuse-to-copy path rather than guessing.
- **MODERATE 2 — the PowerShell Validate guard fails OPEN in the exact case it exists for.** `Join-Path $TEMPLATE_DIR 'context'` throws a *non-terminating* error on null/empty, so `Test-Path` never runs, the `if` body is skipped, and execution continues at exit 0. The bash twin fails closed in both cases. → **fixing** with a short-circuited `[string]::IsNullOrWhiteSpace` check first.
- **MODERATE 3 — `create-iconrc`'s guard is bash-only** (`grep -c '^```powershell'` → 0). Pre-existing, but this task is what promoted the block from advisory to mandatory, which is what makes one unguarded shell a gap now. → **fixing**.
- **MODERATE 4 — row 4's deferred half is unreachable when `branching.md` already exists.** The deferred instruction sits under "for any missing new required files", so a repo lacking `prune-context.sh` but *having* `branching.md` never sets the value and ships the broad default `^(main|master|dev|develop|trunk)$`. → **fixing**.
- **Minor, accepted → fixing**: 5 (`LOCAL_PREFIX` mis-parses a minified single-line `iconrc.json`, yielding the bogus `Local prefix 'excludes' collides…` — the very class D3 exists to eliminate); 6 (`grep -vixF` lacks `-e`, Rule 4a, and the charclass admits a leading `-`); 8 (`read -r` loop drops a final line with no trailing newline — currently unreachable, robustness only); 11 (D6's bold lead says "append a footer to each flagged doc" while the next paragraph correctly says the clearing footer is the one on whichever doc *names* it — lead with the inbound rule so headline and correction agree).
- **Minor, declined with reason**: 7 (`excludes` prose-only in the `decisions/` restore — consistent with the file's global convention at `:126`); 9 (case-folded prefix in the report — harmless, `forbidden_prefixes` compares case-insensitively); 10 (cross-skill line-number citation — a rot risk, not a defect).
- **Disclosed by @coder, accepted**: one `>/dev/null` and one `/tmp` use in throwaway test harnesses (not shipped content, stderr never suppressed), self-corrected mid-task. Re-flagged in the remediation brief.
- **Platform gap @reviewer could not close**: this filesystem does not honour `chmod`, so whether `mv "$DEST.tmp" "$DEST"` drops the executable bit on a POSIX host is unverified. No regression either way — the template is `100644` in git and `.githooks/post-commit` invokes the script via `bash …` — but `context-specialist-impl-leaf:126` does `chmod +x` and `impl-root:302` verifies executability, so the two paths are inconsistent. Noted, not fixed.
- [ ] Completion: reconcile plan.md, changelog, retrospective, commit, PR

## Open Questions / Blockers
### Hook-gate traps the implementation will hit
- **The `.context/` dead-ref resolver is the highest-probability blocker for D6.** Every `.context/<subdir>/<file>.<ext>` string written into a `skills/*.md` file is validated against `context_template/context/<subdir>/<file>.<ext>`, and it is **fence-blind** — a path inside backticks or a ```` ```bash ```` fence is checked identically to prose. An illustrative consumer path like `.context/domains/payments.md` fails the hook. Use paths that exist in the template, keep illustrations at directory granularity (`.context/domains/` does not match the regex — only `<name>.<ext>` forms do), or bracket in `<!-- pre-commit:dead-ref-ok-start -->` … `<!-- pre-commit:dead-ref-ok-end -->` (precedent at `:151/:171`, `:214/:432`).
- **The cap-literal check will block an innocuous reflow.** `upgrade-repo:651` contains "Remove entries older than the 10th." inside a fenced block; the hook regex `older than the [0-9]+th` matches it and compares `10` against `ENTRY_CAP`. Do not reflow the Retrospectives File Migration section.
- **shellcheck never sees fenced bash in `SKILL.md`** — locally or in CI (issue #48, filed during ICON-0093). Every new shell block in D1/D2/D3/D4 has **no automated safety net**; live-fixture testing per shell-portability Rule 3 is the only backstop.

### Corrections to the investigation report (kept here; the report is preserved as-written)
- **§D1 cause 3 says `/context_template` is "16 characters". It is 17.** Caught by @coder measuring it rather than trusting the number, after briefly copying it into shipped prose. Replaced with "non-empty" — the count carries no weight and would only rot. The report's argument is unaffected.
- **A near-miss worth keeping.** @coder's first control run appeared to show the old `[ ! -d … ] && echo` form *not* aborting under `set -euo pipefail`, which would have made cause 4 look non-reproducible. The cause was the test harness: **POSIX exempts non-final commands in an `&&` list from `set -e`.** Re-tested the way a caller actually consumes a fence — run as its own script, and sourced — the inversion reproduced both ways (exit 1 on the success path). This is the ICON-0093 Testing Pattern lesson firing exactly as intended: the first result was the *wrong failure mode*, not the absence of one.

### Verification constraint
- **ICON is a degenerate test target for `/upgrade-repo`.** ICON-0090 §2 recorded that in a dogfood run `$TEMPLATE_DIR` resolves to ICON's own working tree — template source and upgrade target are the same tree. Any live verification of D1/D4/D7 done inside this repo tests an aliasing case, not a consumer case. **Use a scratch fixture repo under the scratchpad.**

### Gaps investigation could not close (read-only pass)
- `[regex]::Escape` for D2 not executed against a real `iconrc.json` on PowerShell 7.
- No `sed`-based `INTEGRATION_BRANCHES` extract-and-restore tested against a value containing `^ $ | ( )` — the escaping is the most likely place a D4 fix breaks silently.
- `context-graph --check` behavior on a synthetic pre-2.0.0 `.context/` with zero footers was **inferred** from `classify()` and the rules-index coverage boundary, not reproduced. Building that fixture is the cheapest way to get a hard number for D6.

## Constraints
- ICON is pure-content: no build step, no test runner, no package manager (ADR-005). Committed, dependency-free scripts run in place ARE in scope.
- `.claude-plugin/plugin.json` is the version SSOT (ADR-003). Do NOT bump; this task is not a release.
- Shipped shell must run on GNU, BSD/macOS, and busybox — `.context/standards/shell-portability.md`, **including its new rules 7 and 8 and the Testing Pattern lesson added by ICON-0093**: a portability fix must be executed in the exact form the document prints, and a fix can trade a loud failure for a silent one.
- `.sh`/`.ps1` parity pairs must stay byte-identical within their group (enforced by `.githooks/pre-commit` check 2).
- Release guard: no version bump, no tag, no `latest` move. This task ends at an open PR.
- Defect 4 (pruning script) is destructive-in-effect — the fix must **preserve** a consumer's customized branch list, not restore a default. Treat any change that could overwrite consumer customization as requiring explicit verification.
