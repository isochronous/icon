# Cross-Cutting Audit — Raw Findings

**Domain**: 06 — Cross-cutting synthesis (consumes 01–05)
**Audit**: ICON-0089 (2026-07-26) · plugin v2.0.0 + `[Unreleased]` (ICON-0088) · branch `feature/ICON-0089-icon-audit`
**Prior baseline**: ICON-0058 (2026-06-10, v1.19.0 + `[Unreleased]`), verdict STRONG (holding), 0C / 3M / ~17Min
**Inputs**: `research/01-agents.md` … `research/05-infrastructure.md` (all read in full), `.context/tasks/ICON-0058-icon-audit/audit-report.md` + its `research/06-cross-cutting.md`, `.context/retrospectives.md`, `.context/retrospectives-archive.md`, `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `.context/decisions/`

---

## Summary

ICON-0058's central prescription was one sentence: *"the codebase needs mechanical reach-at-the-moment-of-need infrastructure more than it needs more prose."* This interval executed it, and the results are measurable and one-sided. All five Focus-2 mechanisms shipped — `.context/rules-index.md` exists at 45 lines / 597 words and is read at `agents/manager.agent.md:93`; the rule-coverage gate is at `:57`; the `### Applicable Rules` warmstart field is at `:156`; the pre-write governing-rule lookup is Hardcoded at `:233`. The disposition-ledger recommendation shipped as `synthesis-template.md:160-164` plus a quality-checklist item at `.claude/skills/icon-audit/SKILL.md:152`. `.githooks/pre-commit` grew from 3 invariant classes to 10. And every domain that looked independently reported the same correlation: **the invariants that are gated are clean, and every defect this cycle is in ungated space** (01 Observation 1, 04 Observation 2, 05 Observation 2 — three unco-ordinated observations of one effect).

Two things complicate the good news, and both are only visible from the synthesis seat.

First, **the audit's own feedback loop is the least-mechanized surface in the system and it has failed end to end** (X-89-1). ICON-0058 pre-assigned six follow-up task IDs and recorded them as filed GitLab work items `#31`–`#36` (`ICON-0058/audit-report.md:289`). Four of those six IDs were consumed by unrelated work; `gh issue list --state all` returns `[]` — the repo has zero issues, so none were migrated in the GitHub-only conversion; no brief's `## Prior-Audit Pointer` instructs anyone to read the prior dispositions table; and `.claude/skills/icon-audit/SKILL.md:124,151` still routes new follow-ups to GitLab. The recommended work nonetheless *all got done* — under later, different IDs (ICON-0068, 0069, 0080, 0088). That is the honest and uncomfortable result: **the ledger did not close the loop; the recommendations closed anyway, by a mechanism that is not the ledger.**

Second, **two mechanized controls in this repo are verifiably wrong in ways that produce justified false confidence** — and one of them caused a Critical. `.context/retrospectives.md` holds 11 entries against `ENTRY_CAP=10`, and the cross-check ICON-0088 promoted and shipped to consumers (heading count vs `awk RS=""` record count) reports *clean*, because both counts equal 11 (x-89-1). Both domain 02 (S1) and domain 05 (SO-8) propose mechanizing that check exactly as specified — so both would ship a gate that passes on a file it was written to protect. Separately, a `<!-- context-graph:orphan-ok -->` marker added to `context_template/context/workflows/task-workflow-template.md` purely to satisfy ICON's own graph gate is the proximate cause of C-89-03-01, the Critical affecting the entire pre-2.0.0 installed base.

Raw counts across domains: **5 Critical / 25 Moderate / 39 Minor / ~34 script-offload candidates**, against ICON-0058's 0 / 3 / ~17. I do **not** read that as an eightfold quality regression, and § *The Reach of Mechanization* argues why: the interval was the largest in ICON's history (2.0.0 breaking release), and three of the five Criticals sit in code paths — `upgrade-repo` Phase 1/2, `initialize-monorepo` `.sln` discovery, `impl-root` Step 4 — that no prior audit inspected at this depth and that `/upgrade-repo` has never been executed against (`.context/iconrc.json:2` = 1.2 vs `context_template/context/iconrc.json:2` = 1.12). The count moved mostly because the *inspection floor* moved.

This report's cross-cutting tally: **0 Critical / 3 Moderate / 3 Minor / 7 improvement opportunities**, plus a consolidated 20-entry roadmap covering all 34 upstream candidates.

---

## Defect Findings

Cross-cutting defects are systemic by nature. Per the brief's Non-Goals I do not re-tier domain-local defects; each finding below is either a synthesis-only observation or an extension that no single domain could make. Scope is labelled per finding.

### Critical

**None at the cross-cutting layer.** The five Criticals this cycle (03: C-89-03-01/02/03; 05: C-I-1/C-I-2) are domain-owned and correctly tiered there. The cross-cutting observation about them is not a sixth Critical but a *pattern* — see X-89-3.

---

### Moderate

#### X-89-1 — The audit → follow-up → next-audit loop is broken at every link (scope: process/systemic; spans all domains)

- **Locations**:
  - Ledger written: `.context/tasks/ICON-0058-icon-audit/audit-report.md:284-291` (`## Post-Review Dispositions`), specifically `:289` — *"Filed as GitLab work items (2026-06-10): ICON-0059 → #31, ICON-0060 → #32, ICON-0061 → #33, ICON-0062 → #34, ICON-0063 → #35, ICON-0064 → #36."*
  - Mechanism promoted: `.claude/skills/icon-audit/synthesis-template.md:160-164`; quality checklist `.claude/skills/icon-audit/SKILL.md:152`.
  - Ledger never read back: `## Prior-Audit Pointer` appears at `briefs/01-agents.md:15`, `briefs/02-process-skills.md:14`, `briefs/03-context-specialist-init.md:17`, `briefs/04-utility-skills.md:18`, `briefs/05-infrastructure.md:37`, `briefs/06-cross-cutting.md:19` — **none of the six names `## Post-Review Dispositions`**. `.claude/skills/icon-audit/scripts/structural-check.sh:70` asserts the heading exists in every brief, so the skeleton is already gate-enforced and trivially extensible; the content of the section was simply never updated to consume the ledger the same skill produces.
  - Filing target dead: `.claude/skills/icon-audit/SKILL.md:124` and `:151` still say "file as **GitLab** issues" (domain 05 m-I-1 owns the residue; the loop consequence is mine).
- **Finding — three independent breaks, verified:**
  1. **Pre-assigned task IDs are a shared first-come namespace, so the linkage is broken by construction.** ICON-0058 recommended ICON-0061 = "verification/close-gate consolidation", ICON-0062 = "Focus-2 discoverability", ICON-0063 = "token governance + disposition ledger", ICON-0064 = "hygiene sweep". On disk: `.context/tasks/ICON-0061-sessionstart-hook-bootstrap/`, `ICON-0062-release-aware-gate-clear-reinject/`, `ICON-0063-context-knowledge-hygiene/`, `ICON-0064-memory-to-context-migration/`. **Four of six re-scoped.** Only ICON-0059 and ICON-0060 executed their recommended scope (`CHANGELOG.md:90-93`, `:77`).
  2. **The durable linkage is unreachable.** `gh issue list --state all --limit 40` → `[]`. The repository has no issues at all, open or closed, so `#31`–`#36` were never recreated on GitHub. The 2.0.0 GitHub-only conversion (ICON-0080) swept skills, agents, docs, and CI — it did not sweep the audit trail.
  3. **Nothing reads the ledger.** This cycle's dispatch derived carry-forward status from the prior *report body*, not from its dispositions table — which is precisely how the stale premise recorded at `plan.md:20` (the `ecological-impact` "fourth-cycle carry-forward" that ICON-0059 had already closed at `CHANGELOG.md:91`) entered the brief.
- **Honest counterweight, and it matters**: despite all three breaks, the ICON-0058 recommendation close rate this cycle is **high** — domain 04 closed 4 of 5, domain 03 closed 6, domain 02 closed both, domain 01 closed 2, domain 05 closed 7. The work happened. But it happened via later, differently-numbered tasks, which means the ledger contributed nothing to the outcome and the *reason* things closed is something else (see § The Reach of Mechanization, mechanism tiers).
- **ADR check**: ADR-010 governs the *carry-forward re-tier registry*, which is a different and narrower artifact (accepted-watch items only); `synthesis-template.md:162` says so explicitly. No ADR protects this gap.
- **Risk**: Moderate. It converts every unaccepted finding into rediscovery work, and it is the mechanism by which a stale premise reached five sub-agents this cycle. It also means the audit — the one process explicitly chartered to catch drift — has no drift detection on itself.
- **Classification**: **Still present, mechanism shipped but non-functional** vs ICON-0058 M3 / X-CC-M1. ICON-0058 diagnosed the disease correctly and shipped a treatment that is write-only.

---

#### X-89-2 — Session-per-phase invalidated ADR-008's scope carve-out; the measured phase session is ~29% over a ceiling that excludes its two largest contributors by rule (scope: 01 + 02; token governance)

- **Locations**: `.context/decisions/008-always-loaded-token-budget.md:14` (8,500-word manager ceiling), `:31` (*"Phase skills, sub-agent files, and on-demand skills are **NOT** in the always-loaded set and do not count toward the trigger"*), `:45` (session total 8,685 = 102.2%, accepted with rationale); `.context/decisions/013-session-lifecycle-cold-resume.md` (the session-per-phase model); `agents/manager.agent.md:41,:83`.
- **Measured live this audit** (`wc -w`, all figures reproducible):

  | Component | Words | In ADR-008 inventory? |
  |---|---|---|
  | `agents/manager.agent.md` | 4,620 | yes |
  | `shared/common-constraints.md` × 9 | 3,321 | yes |
  | `skills/using-skills/SKILL.md` | 744 | yes |
  | **ADR-008 manager session total** | **8,685** | **102.2% of 8,500** |
  | `skills/task-plan/SKILL.md` | 817 | **no** — on-demand carve-out |
  | `skills/task-plan-phase-completion/SKILL.md` | 1,459 | **no** — phase-skill carve-out |
  | **Completion-phase session total** | **10,961** | **129.0% of 8,500** |
  | `skills/manager-routing-guide/SKILL.md` (any delegation) | 1,455 | no |
  | **…with one routing decision** | **12,416** | **146.1%** |

  Other phases: investigation 10,450 (122.9%), implementation 10,313 (121.3%), testing 10,281 (121.0%), architecture 10,195 (119.9%).
- **Finding**: ADR-008's carve-out at `:31` was sound when phase skills were optional, on-demand, and small. Under ADR-013, **exactly one phase skill loads per session as a matter of design**, and `task-plan` loads with it as the router (`skills/task-plan/SKILL.md:59` — *"This skill is a router"*). Two files that the ADR classifies as "not always-loaded" are now unconditionally present in every phase session. The budget therefore measures a session shape that no longer occurs. Domain 02 raised this as an open question (Observation 3: *"one phase skill loads per session as a matter of design, which is closer to 'always-loaded per session' than the carve-out assumed"*) and correctly deferred it to synthesis; the measurement above is the answer.
- **Why this is a defect and not merely an improvement**: the carve-out is what makes m-P-0089-2 unreportable as a budget violation — `task-plan-phase-completion` grew 832 → 1,459 words (+75%) between audits with, in domain 02's words, *"no trigger, no snapshot, and no gate of any kind"* observing it. A governance rule whose scope definition excludes the growth it exists to detect is not a governance rule. And the growth is not hypothetical: the single largest contributor is a ~200-word merge-coalescing hazard paragraph at `:105`, triplicated across three files (domain 02 S1).
- **Countervailing evidence, reported honestly**: (a) the 9 × `common-constraints` figure is ADR-008's own accounting — a phase session that dispatches fewer than nine agents loads fewer copies, so 10,961 is an upper bound under the ADR's convention, not a floor; (b) since ICON-0061 the SessionStart hook injects a <2KB bootstrap rather than the full manager body (`CHANGELOG.md:94`), so the manager's 4,620 words enter context via a read rather than an injection — still in-context, but the loading mechanism differs from what ADR-008 assumed; (c) the manager itself is *shrinking* (5,126 → 4,976 → 4,620, `ADR-008:44`). None of these changes the conclusion that the budget's scope no longer matches the session model.
- **ADR check**: consulted before tiering, per the brief. ADR-008's per-component overage is accepted-with-rationale at `:44` and is **not** re-tiered here. What is tiered is the *scope definition* at `:31`, which no ADR protects and which ADR-013 silently invalidated.
- **Risk**: Moderate. No correctness risk today; the risk is that the only budget in the system is measuring the wrong surface, so the next several phase-skill additions land unopposed — which is exactly the +75% that already happened.
- **Classification**: **Net-new.** ICON-0058 measured the manager at 54.7% of session cap with headroom; session-per-phase did not exist. Remediation is IO-X-1.

---

#### X-89-3 — The enforcement layer that produces every clean result in this audit is architecturally advisory (scope: 05 + all; systemic)

- **Locations**: `.githooks/pre-commit` (10 invariant classes, enumerated at 05 M-I-1); `CONTRIBUTING.md:52` and `README.md:247` (the `git config core.hooksPath .githooks` instruction — the *only* thing that arms them); `.github/workflows/security.yml:13-54` (three jobs: gitleaks, semgrep, shellcheck).
- **Finding — this extends domain 05's Observation 4 rather than restating it.** Domain 05 established that enforcement strength is inversely correlated with consequence (a logging helper gets a byte-parity gate; credential detection gets a comment; the release path gets nothing). The cross-cutting extension is one level up: **there is no tier beneath the advisory one.** Verified this audit:
  - `grep -n 'structural-check\|check-rules-index\|context-graph' .github/workflows/*.yml` → **no matches**. Not one of the ten pre-commit invariants is re-run anywhere in CI.
  - The three CI jobs are `secret-scan`, `sast`, `shellcheck` (`security.yml:14,25,37`) — all *scanning*, none *invariant enforcement*.
  - Arming the hooks is a single per-clone config command documented in two prose files. (It *is* set in this working copy — `git config --get core.hooksPath` → `.githooks` — so the audit's own gate runs are valid; the exposure is every other clone.)
  - `--no-verify` bypasses all ten with no record anywhere.
- **Why this is the cross-cutting finding and not a domain-05 one**: every positive result in this cycle's five reports is downstream of this layer. `common-constraints` byte-equal ×9 (01), script parity byte-identical ×6 (05), README 50/50 (04), `context-graph --check` clean at 49 nodes (03/05), `check-rules-index` clean (03), zero dead `.context/` refs (01). Domain 05 is right that *"where ICON has built a mechanical gate, that class of finding has gone to zero and stayed there"* — and the qualification is that the gate holds only in clones where someone typed one command. The audit cannot distinguish "invariant holds" from "invariant holds in the clones we looked at."
- **Consequence for the roadmap** (developed in § *Consolidated Script-Offload Roadmap*, R-0): the two-tier architecture domain 05 recommends does not currently exist. Adding an eleventh gate to a stack with no backstop increases the surface without increasing the guarantee.
- **Risk**: Moderate. Latent — no observed bypass incident. But it is the multiplier on every candidate in the roadmap, which is why it is tiered rather than left as an observation. ICON-0058 flagged the README-instruction half (IO-I-D / O-D2) and it shipped (`README.md:247`); the CI-backstop half was never raised because CI did not exist at ICON-0058.
- **Classification**: **Net-new** (CI did not exist at ICON-0058; `ICON-0058/audit-report.md:6` scopes the pre-commit hook at "3 invariant classes" with no CI).

---

### Minor

#### x-89-1 — `.context/retrospectives.md` is over its own cap, and the check written to catch that reports clean (scope: 02 + 05; corrects two upstream candidates)

- **Locations**: `.context/retrospectives.md` (56 lines, 11 entries); `ENTRY_CAP=10` at `skills/task-retrospective/scripts/append-retrospective-entry.sh:41`, `skills/context-maintenance/scripts/append-retrospective-entry.sh:41`, `skills/post-incident-review/scripts/append-retrospective-entry.sh:41`; prune logic at `append-retrospective-entry.sh:160-163` (*"Keep cap-1 old entries so the post-insert count equals cap"*); the shipped check at `.context/retrospectives.md:4` and `context_template/context/workflows/task-plan/phase-completion.md` (schema 1.12, `CHANGELOG.md` `[Unreleased]`).
- **Verified**:
  ```
  grep -c '^### ' .context/retrospectives.md        → 11
  awk 'BEGIN{RS=""} END{print NR}' …/retrospectives.md → 11
  ```
  The two counts **agree**, so ICON-0088's "cheap detection" cross-check — *"confirm `grep -c '^### '` and an `awk RS=""` record count agree; a mismatch means a separator was coalesced"* — passes. The file is nonetheless carrying 11 entries against a cap of 10. `git show` at `HEAD`, `HEAD~1`, `ae4cf39` (ICON-0088 merge) and `7836a6f` (2.0.0) all return 11: the over-retention predates ICON-0088's separator repair and survived it.
- **Finding**: ICON-0088 correctly diagnosed the `merge=union` coalescing hazard, correctly repaired the coalesced separator between the ICON-0086 and ICON-0087 entries, and shipped a detector — **for the symptom, not the harm**. Restoring the separator made the two parsers agree; it did not prune the entry the mis-parse had over-retained. The invariant that matters is `entry_count ≤ ENTRY_CAP`; the check asserts `heading_count == record_count`, which is a *proxy* that is now satisfied by a file in violation.
- **Direct consequence for this cycle's roadmap**: domain 02 **S1** and domain 05 **SO-8** both propose mechanizing this check, and both specify it as the equality assertion. As specified, either gate would run green on `.context/retrospectives.md` today. The merged roadmap entry **R-9** carries the correction: assert `count ≤ ENTRY_CAP` **and** the heading/record equality, sourcing the cap from the script constant rather than hardcoding it (the anchoring pattern `O-M1b` already uses at `.githooks/pre-commit:650-700`).
- **Severity rationale**: Minor, not Moderate — `append-retrospective-entry.sh:161-163` self-heals (`keep = cap - 1` when `n >= cap`), so the next retrospective append converges the file to 10. The finding's weight is in the gate-specification correction, not the file state.
- **Classification**: **Net-new.**

#### x-89-2 — Maintainer-only skills are registered nowhere and sit outside the gate that would have caught it (scope: 04 + discoverability)

- **Locations**: `.claude/skills/` contains exactly three skills — `changelog-entry/`, `icon-audit/`, `release-plugin/`; the O-V1 registration gate at `.githooks/pre-commit:704-732` iterates `"$repo_root"/skills/*/` only (`:715`).
- **Verified registration counts** (backticked-name occurrences): `icon-audit` — README 0, CONTRIBUTING 0. `changelog-entry` — README 0, CONTRIBUTING 0. `release-plugin` — README 0, CONTRIBUTING 1 (`CONTRIBUTING.md:70`).
- **Finding**: Domain 04's headline positive is correct and important — 50 of 50 skills under `skills/` carry a README row, zero misses, and the gate is provably load-bearing (it blocked ICON-0080's rename commit, `.context/retrospectives.md:43`). The synthesis correction is that the gate's population is `skills/*/`, so the three maintainer skills are outside both the README tables and the enforcement. **`icon-audit` — the skill that produces this report — is discoverable in the repo's documentation zero times.** A maintainer's only route to it is knowing it exists.
- **Why it is a discoverability finding and not just a registration nit**: `CONTRIBUTING.md` is the onboarding surface for new maintainers and it documents the release skill by name once, in passing, in the last line of the file. Nothing tells a contributor that an audit skill, a changelog-entry skill, or their invocation conventions exist.
- **Note for the roadmap**: domain 04's **SO-1** already scopes its frontmatter gate to *"staged `skills/*/SKILL.md` **and** `.claude/skills/*/SKILL.md`"* — correctly anticipating this blind spot for its own check. Widening O-V1's glob to match is a one-line change and is folded into R-10.
- **Classification**: **Net-new.** (ICON-0058's m14 / X-CC-3 was the `skills/` half and is **fixed**.)

#### x-89-3 — The audit's own dispatch inputs are hand-authored and unverified; two errors reached sub-agents this cycle (scope: process)

- **Locations**: `plan.md:20` (the recorded brief-premise correction); `plan.md:68` (Phase 1 Baseline Preamble, scale inventory).
- **Two instances, one class:**
  1. **Stale carry-forward premise.** The dispatch prompt asserted the `ecological-impact` / ADR-004 Moderate was a three-cycle carry-forward heading for a fourth. False — ICON-0059 closed it (`CHANGELOG.md:91`), verified on disk by domain 04, which had to spend part of its report refuting its own brief (Observation 3). Recorded and corrected at `plan.md:20`, to the manager's credit.
  2. **Inaccurate scale inventory.** `plan.md:68` states *"3 maintainer-only under `.claude/skills/`: `icon-audit`, `release-plugin`, `security-review`, plus `changelog-entry` and `work-roadmap-auto`"* — which names five while claiming three. Verified: `.claude/skills/` holds `changelog-entry`, `icon-audit`, `release-plugin`. `security-review` is a **shipped** skill (`skills/security-review/SKILL.md`, `user-invocable: true`, correctly in the README user table); `work-roadmap-auto` does not exist anywhere in the repo (`find . -name SKILL.md -path '*work-roadmap-auto*'` → 0). This is the inventory five sub-agents were told to treat as the agreed baseline.
- **Finding**: both are the *same* class as the defects the audit exists to find — a hand-authored statement of fact that drifted from the tree — occurring in the audit's own inputs. Both are also trivially derivable: carry-forward status from `CHANGELOG.md`, the scale inventory from `ls`. `plan.md:20` already draws the right lesson for the first ("future audit dispatches derive carry-forward status from the CHANGELOG rather than from the prior report alone"); the second shows it is a class, not an incident.
- **Severity**: Minor. Neither error changed a domain's conclusions — domain 04 caught the first, and the second is inert. The cost is one domain's wasted effort and a baseline five agents could not rely on.
- **Classification**: **Net-new** as a named class. (ICON-0058's M3 is adjacent but concerns *outputs* — recommendations lapsing — where this concerns *inputs*.)

---

## Improvement Opportunities

Organized by the five standard synthesis categories. Seven items; the mandate is three.

### Category 1 — Token Efficiency

#### IO-X-1 — Re-scope ADR-008 to the session shape ADR-013 actually produces

**Closes X-89-2.** ADR-008's `:31` carve-out predates session-per-phase. Amend it to define **two** measured surfaces rather than one:

- *Dispatcher surface* (unchanged): manager/PM + 9 × `common-constraints` + `using-skills`. Keep the 8,500 / 7,000 ceilings.
- *Phase-session surface* (new): dispatcher surface **+ `task-plan` + the loaded phase skill**, with its own ceiling set from the measured distribution (10,195–10,961 today) plus modest headroom, on ADR-008's own stated "descriptive-with-modest-headroom" principle (`:14`).

This does three things at once: it makes the budget measure a session that occurs; it gives `task-plan-phase-completion`'s +75% growth a trigger for the first time; and it supplies the enforcement surface domain 02's IO-P-0089-3 (declared per-skill token tier) needs. Pair with the R-14 gate, which must be **baseline-relative**, not cap-relative — see the R-14 adjudication.

The honest tension to put to the maintainer alongside it, because it is the reason ADR-008's discharge has gone unscheduled for three cycles (01 IO-A-0089-6): `.context/standards/terseness-calibration.md` (ICON-0083) forbids de-duplicating *reinforcing* redundancy without sign-off, and the manager's largest reducible block is exactly that — the close-gate stated three times (`manager.agent.md:218`, `:244`, and AR rows `:263-264`), a deliberate reliability choice ICON-0083 declined to cut (`.context/retrospectives.md:29`). ADR-008 and `terseness-calibration` are in unresolved tension. Ask for one ruling — raise the ceiling with fresh rationale acknowledging tiered restatement is load-bearing, **or** authorize a targeted extraction — rather than carrying a fourth cycle of "accepted, discharge unscheduled."

**Effort**: low (ADR amendment) → medium (if a reduction is authorized). **Impact**: high.

### Category 2 — Discoverability

#### IO-X-2 — Give the maintainer surface a home, and widen O-V1 to cover it

**Closes x-89-2.** Add a `#### Maintainer Skills` table to `README.md` after the Internal Skills table (`:213`) — or, if the maintainer prefers to keep `README.md` consumer-facing, a section in `CONTRIBUTING.md` — listing `icon-audit`, `release-plugin`, `changelog-entry` with one-line purposes and the fact that they are not shipped to consumers. Then widen `.githooks/pre-commit:715` from `skills/*/` to include `.claude/skills/*/` so the class cannot reopen. The gate change is one line and the population passes the moment the table exists.

**Effort**: trivial. **Impact**: medium.

#### IO-X-3 — Close three gaps in the README intent index

`README.md:38-48` is a good structure — a nine-row "what do you want to do?" table that front-loads intent over inventory. Three gaps:

1. **No row for "something is wrong / I want to report it."** `CONTRIBUTING.md:5-14` is the answer and the index does not point to it; the only link to `CONTRIBUTING.md` is at `README.md:247`, below the skills tables.
2. **No row for headless / cron / CI execution.** `generate-phase-launcher` is a flagship 2.0.0 capability (ADR-013) and appears only as a skills-table row at `:163` with a 40-word description. A reader with that intent has no path to it.
3. **`CHEATSHEET.md` is an orphan** — domain 05 m-I-4 verified zero inbound references from any Markdown outside `.context/`. The intent index is its natural entry point, and the "I want a quick command reference" row does not exist.

Adding three rows costs three lines and materially widens the funnel. (Domain 05 owns the `CHEATSHEET.md` staleness defect; this is the wiring half.)

**Effort**: trivial. **Impact**: medium.

### Category 3 — Consolidation

#### IO-X-4 — Adopt "declarative data + thin checker" as the stated architecture for gates, and pair it with the authoring rule

Three domains arrived independently at the same architectural conclusion without co-ordination, and none framed it as general:

- Domain 03: *"a manifest (IO-89-03-01) is the prerequisite rather than another gate"* — the required-file set must exist as data before `check-context-complete.sh` can exist.
- Domain 04: on `O-M1b`, *"the gap is generality, not existence"* — one hardcoded literal and four bespoke regexes want to be a registry.
- Domain 05: on script parity, *"the generalized version is the reusable half"* — a hardcoded triple wants to be `parity-groups.json`.

That convergence is the strongest architectural signal in this cycle and it should be written down: **a gate's expected values live in a versioned data file; the checker is a thin loop over it.** The payoff is compounding — a new invariant becomes a JSON object rather than a hook edit, the data file is reviewable in isolation, and (per § *The Reach of Mechanization*) an anchored gate resists displacement in a way an instance gate does not.

Pair it with domain 02's **IO-P-0089-1** (*"prose describing a deterministic check must cite the script that performs it"*), which is the authoring-side counterpart: IO-P-0089-1 stops new prose-carried checks from being written; IO-X-4 says what to build instead. Together they are the durable form of this cycle's directive.

**Effort**: low (one section in `writing-skills` or a new `standards/` unit). **Impact**: high.

### Category 4 — Missing Skills / Workflow Gaps

#### IO-X-5 — Nothing owns "adding a gate," and the evidence says it needs an owner

Adding a gate to ICON today requires, in order: choosing a venue (pre-commit / CI / skill / harness hook); choosing fail-open vs fail-closed (`.context/standards/secure-coding.md` Rule 11 covers this — the one part that *is* documented); implementing the 3-value exit contract; choosing and documenting an escape-hatch marker; deciding whether the check needs whole-tree or staged-file scope; and updating four documentation surfaces (`.githooks/pre-commit:19-40` header, `CONTRIBUTING.md:52`, `.context/domains/hooks.md:120-128`, and the gate's own banner comment).

That last step has now failed in three consecutive audits — ICON-0046 m-infra-2 → fixed → ICON-0089 M-I-1 (3 of 10 documented, wrong order) + m-I-3 (4 of 10) + M-I-2 (1 of 2 hooks). Seven gates were added across ICON-0069/0075/0081 and O-M1a/O-M1b/O-V1; **zero** updated all four surfaces. That is a documented, repeated, procedure-shaped failure with no owning skill or standard — the definition of a missing-skill gap.

Proposal: a `standards/gate-authoring.md` unit (with a `rules-index.md` row so it is index-reachable) capturing the venue decision table, the Rule 11 fail-open/closed rule by reference, the exit contract, the marker convention, and the documentation obligation. If R-15 (gate-doc generator) ships, the last item collapses to "run the generator" — which is the right relationship between the two.

**Effort**: low. **Impact**: medium-high, and rising with every roadmap item built.

### Category 5 — Self-Verification / Automate the Retrospective Wisdom

#### IO-X-6 — Repair the audit feedback loop (three concrete changes)

**Closes X-89-1.**

1. **Make the ledger readable.** Extend the invariant `## Prior-Audit Pointer` preamble in all six briefs with one sentence: *"Read the prior report's `## Post-Review Dispositions` table before its findings sections; a finding recorded as deferred is a tracked item, and a finding recorded as accepted with a follow-up link should be verified closed before being re-derived."* `structural-check.sh:70` already asserts the heading exists in every brief, so the six-way sweep is gate-protected against partial application — a rare case where the mechanism to keep a sweep complete is already in place.
2. **Stop pre-assigning sequential task IDs.** `ICON-NNNN` is a first-come namespace; recording "ICON-0061" as a recommendation guarantees the link breaks the moment anyone starts a task. Record the recommendation by *scope description* and link a durable issue number, or nothing.
3. **Reconstitute or explicitly close ICON-0058's six follow-ups.** `gh issue list --state all` is empty. Either file the still-open items as GitHub issues, or record in this cycle's `## Post-Review Dispositions` that `#31`–`#36` are superseded by observed closure (with the closing task IDs — ICON-0059, 0060, 0068, 0069, 0080, 0088 — which this report has established). Leaving them unresolvable is what makes the next audit re-derive them. Note this depends on domain 05's m-I-1 fix (`SKILL.md:124,151` GitLab → GitHub) landing first, or the next cycle files into the same void.

**Effort**: low. **Impact**: high — it is the only item that makes the *other* improvement opportunities durable across cycles.

#### IO-X-7 — Run the audit's own checkers in CI

`.claude/skills/icon-audit/scripts/structural-check.sh`, `skills/context-maintenance/scripts/check-rules-index.sh`, and `skills/context-maintenance/scripts/context-graph.sh --check` are the three read-only, whole-tree, 3-value-exit-contract checkers ICON already owns. Two of the three are wired into `.githooks/pre-commit` (`:737`, `:758`); `structural-check.sh` is wired nowhere and runs only when a human types the command. All three took under a second in this audit and all three passed. Adding them to `.github/workflows/` costs one job and is the cheapest possible down-payment on R-0.

Note the scope caveat domain 01 raised (Observation 5): `structural-check.sh` B.1–B.6 validate only the `icon-audit` skill's own files. Putting it in CI does not fix that; R-10 does. Do both — the CI wiring is independently worth it and does not depend on the scope fix.

**Effort**: trivial. **Impact**: medium (high once R-10 widens what it checks).

---

## Consolidated Script-Offload Roadmap

All **34** upstream candidates, deduplicated into **20** entries. Every upstream ID appears exactly once. Where several domains proposed the same underlying gate, every proposing domain is named — independent convergence is itself evidence of leverage, and three entries (R-2, R-4, R-12) were proposed by two or three domains that never saw each other's work.

### Ranking criteria (stated explicitly)

Five factors, scored, summed. The scoring is a discipline for making the trade-offs visible, not a precision instrument — read the score as a band, and read the *reasons* as the argument.

| Factor | 3 | 2 | 1 | 0 |
|---|---|---|---|---|
| **E — Evidence** | Failure occurred **and** a retro/CHANGELOG documents it, usually naming the gate gap | Failure occurred, found by this audit, previously undocumented | Theorized only; class evidence from an adjacent failure | — |
| **B — Blast radius** | Consumer-facing or irreversible (release, installed base) | Maintainer correctness / security | Internal hygiene, render-only | — |
| **F — Fail-closed today** | — | Population passes clean now; ship at exit-1 immediately | Needs live violations fixed or an advisory period first | Blocked on a prerequisite artifact |
| **X — Effort (inverted)** | Low, and **extends existing tooling** | Low-medium, new file | Medium+ or multi-file | — |
| **D — Displacement resistance** | — | **Anchored** — derives the expected value from a source of truth (a script constant, a directory listing, a manifest) | **Instance** — asserts a fixed string or shape an author can route around | — |

*D is my addition and it is load-bearing: see § The Reach of Mechanization. An anchored gate compounds; an instance gate displaces.*

### R-0 — Prerequisites (rank ahead of everything; neither is a gate)

| # | Item | Why it precedes the roadmap |
|---|---|---|
| **R-0a** | **Amend or supersede ADR-005** (05 IO-I-D; closes 05 M-I-6) | `.context/decisions/005-no-build-step.md` is `Status: Accepted` with no supersede field and states at `:8` "two shell hooks", at `:19` "no CI flakiness", and at `:28` rejects Node tooling — all four false. **Every item below currently argues against a live decision record.** One ADR, low effort, unblocks the program. |
| **R-0b** | **One CI job that re-runs the existing ten pre-commit invariants** (X-89-3; extends 05's architecture recommendation) | The two-tier architecture domain 05 recommends does not exist yet — CI scans, it does not enforce invariants (verified: no matches for `structural-check`/`check-rules-index`/`context-graph` in `.github/workflows/*.yml`). Until this exists, adding an eleventh gate to an opt-in, `--no-verify`-bypassable stack raises the surface without raising the guarantee. This single job converts ten existing gates from advisory to authoritative — a larger marginal gain than any individual candidate below. Bounded work: `context-graph.sh` and `check-rules-index.sh` already take a repo root; common-constraints sync, script parity, README registration, cap-literal, and placeholder sentinel are trivially whole-tree; only the staged-file-scoped dead-ref resolver and the iconrc gate need a whole-tree mode written. |

### Ranked roadmap

| Rank | ID | Merged from | E | B | F | X | D | Σ | Venue | Fail-closed |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | **R-1** Release pre-flight (CI-green, sync, versions) + JSON validity gate | 05 SO-2, 05 SO-1 | 3 | 3 | 2 | 2 | 2 | **12** | skill-invoked (release) + CI | Yes |
| 2 | **R-2** Shipped-shell / runtime portability lint (`grep -P`, `sed -i`, `python3`, bash-4-isms) | 03 SO-4, 05 SO-6 | 3 | 3 | 1 | 3 | 2 | **12** | **CI authoritative** + pre-commit armed | Yes, after live fixes |
| 3 | **R-3** Banned-literal / declared-literal registry (generalize `O-M1b`) | 04 SO-4, 05 SO-5 | 3 | 2 | 1 | 3 | 2 | **11** | **CI authoritative** + pre-commit armed | Yes, after allowlists |
| 4 | **R-4** Markdown table column-count gate | 01 SO-A-1, 02 S3 | 3 | 1 | 2 | 3 | 2 | **11** | pre-commit | Yes, today |
| 5 | **R-6** Dogfood gate — ICON's own `iconrc` schema vs template | 03 SO-8 | 2 | 2 | 2 | 3 | 2 | **11** | pre-commit or CI | Warn→fail on >1 minor |
| 6 | **R-9** Retrospective log integrity (**corrected**) | 02 S1, 05 SO-8 | 3 | 2 | 2 | 3 | 2 | **11** | pre-commit (+ ships to consumers) | Yes |
| 7 | **R-11** Skill frontmatter schema conformance | 04 SO-1 | 3 | 2 | 1 | 3 | 2 | **11** | pre-commit | Yes, after IO-U-1 |
| 8 | **R-10** Structural conformance (agents + phase skills + isolation roster + widen O-V1) | 01 SO-A-3, 01 SO-A-5, 02 S8 | 2 | 1 | 2 | 3 | 2 | **10** | `structural-check.sh` + pre-commit + CI | Partly today |
| 9 | **R-14** ADR-008 word-budget gate | 01 SO-A-2, 02 S5 | 3 | 1 | 1 | 3 | 2 | **10** | pre-commit advisory + **CI baseline-relative** | CI yes, hook no |
| 10 | **R-16** Secret-pattern parity → generalized `parity-groups.json` | 05 SO-4 | 1 | 2 | 2 | 3 | 2 | **10** | pre-commit | Yes |
| 11 | **R-17** Supply-chain pin completeness (`image:` alongside `uses:`) | 05 SO-7 | 2 | 2 | 2 | 3 | 1 | **10** | CI (widen semgrep rule) | Yes |
| 12 | **R-5** `.context/` completeness program (manifest → checker → scope-aware monotonic version gate) | 03 SO-1, 03 SO-2, 03 SO-3 | 3 | 3 | 1 | 1 | 2 | **10** | pre-commit (ICON) + advisory (consumers) | After the manifest |
| 13 | **R-15** Generate gate documentation from the gate source | 05 SO-3 | 3 | 1 | 2 | 1 | 2 | **9** | pre-commit `--check` | Yes |
| 14 | **R-7** Per-release stock-template fingerprint registry | 03 SO-5 | 2 | 3 | 1 | 1 | 2 | **9** | release script + consumer lookup | Yes (release side) |
| 15 | **R-18** Doc-size exemption list as data | 03 SO-6 | 2 | 1 | 1 | 3 | 2 | **9** | pre-commit (ICON) + advisory (consumers) | ICON only |
| 16 | **R-8** Phase entry/exit contract verifier + `plan.md` section presence | 02 S2, 02 S7 | 1 | 2 | 1 | 1 | 2 | **7** | skill-invoked (phase entry) — *justified exception* | Yes |
| 17 | **R-12** Ordered-sequence / `Step N` integrity — **narrow form only** | 01 SO-A-4, 02 S4, 04 SO-2 | 3 | 1 | 1 | 1 | 1 | **7** | pre-commit | Yes, after 3 edits |
| 18 | **R-13** Reference integrity (`skills`→`skills` path-coupling + `.context/` by-name rot) | 04 SO-3, 03 SO-7 | 2 | 1 | 1 | 1 | 2 | **7** | CI + pre-commit, advisory first | Eventually |
| 19 | **R-20** `## Review Checkpoint` coverage vs changed-file set | 02 S6 | 1 | 2 | 0 | 1 | 2 | **6** | folds into R-8 | **Blocked** on M-P-0089-4 |
| 20 | **R-19** Skill size gate | 04 SO-5 | 2 | 1 | 0 | 2 | 1 | **6** | — | **Recommend not building** |

**Coverage check**: 2+2+2+2+3+1+1+2+2+3+1+3+2+2+1+1+1+1+1+1 = **34**. All upstream candidates accounted for.

### If you only do three

**R-0a + R-0b first** (neither is on the list because neither is a gate — one is an ADR, one is a CI job), then **R-1**, **R-2**, **R-4**.

- **R-1** is the only irreversible operation in the repo and currently has zero mechanical gates while an ordinary commit passes ten. ICON-0087 proved the failure is not hypothetical (`security` CI red on every PR and on `main` for many cycles, unnoticed until the user asked, three real findings).
- **R-2** is the cheapest Critical-preventing item on the list: `grep -oE` in place of `grep -oP` at `skills/initialize-monorepo/SKILL.md:82` closes C-89-03-02 outright, and the same deny-list catches M-89-03-01, M-I-8, and M-I-5. Note that `.context/standards/shell-portability.md` currently names none of `grep -P`, `sed -i`, or `python3` — building the lint would *drive* the standard to cover the rules its own violations demonstrate.
- **R-4** is ten lines of awk, reuses the hook's existing staged-file scope block (`.githooks/pre-commit:527-530`) and its CommonMark fence helper (`:14-17`), passes clean on the entire corpus today, and closes a failure that is **silent at render** — the worst detectability class there is, and one the ICON-0088 retro names in its own words as ungated.

### Venue architecture — stress-tested

Domain 05's recommendation, restated: **(i)** pre-commit for fast local feedback, **(ii)** GitHub Actions as authority for anything whose correctness depends on the whole tree or the pushed state, **(iii)** avoid skill-invoked scripts because they reintroduce the reach problem, **(iv)** harness hooks fail open and therefore cannot be correctness gates; plus a single portable `.mjs` as the default for all new checks.

**Agree on (iv), unreservedly.** `hooks/guardrail-pretooluse.mjs:6-11` fails open by design and correctly; a fail-open control is a runtime mitigation, never a correctness gate. Domain 05's own latent finding reinforces it — `:61` lowercases `toolName` for the `isBash` test while `:71`/`:104` test `writeTools.includes(toolName)` case-sensitively, so a harness emitting a differently-cased write-tool name would silently disable `secret-in-write` with no signal. That is exactly what fail-open means: correct today, silently wrong tomorrow, no alarm either way.

**Agree on (iii), and I can strengthen it with evidence domain 05 did not cite.** ICON already runs the experiment. `.claude/skills/icon-audit/scripts/structural-check.sh` is a skill-invoked script, and it exhibits *both* predicted failure modes: it runs only when a human types the command (verified absent from `.github/workflows/*.yml`), **and** its checks B.1–B.6 validate only the invoking skill's own files (01 Observation 5) — a skill-invoked script tends to inherit the invoking skill's scope. Reach failure and scope failure, in the same artifact.

**Agree on (ii), with a sharper rationale than "authority."** For R-2 and R-3 this is not a preference, it is a **correctness constraint**: their entire value is catching a site the current commit does not touch, and a staged-file-scoped hook is definitionally blind to that. `.claude/skills/icon-audit/SKILL.md:124,151` (GitLab residue, two releases after the conversion) is a live instance — no commit-scoped gate could ever have caught it, because no one has touched that file since.

**Refine (i) — this is my one substantive dissent, and it is about sequencing.** Domain 05 names pre-commit's two defects (opt-in per clone, `--no-verify`) but treats them as costs of an otherwise-working fast tier. X-89-3 establishes the stronger claim: with **no CI backstop for any of the ten invariants**, pre-commit is not the fast tier of a two-tier system — it is the *only* tier, and it is advisory. So the recommendation should be ordered rather than parallel: **build R-0b before the eleventh gate.** One job that re-runs the existing ten is a bigger marginal gain than any single new check, and it changes the character of every subsequent addition.

**Agree on the single portable `.mjs` default**, with one supporting datum domain 05 did not use and one caveat it did. The datum: m-P-0089-5 — `check-rules-index.sh` ships without the `.ps1` sibling both its `scripts/` neighbours have, while `context-maintenance/SKILL.md:299` explicitly documents "both the `.sh` and `.ps1` variants" for `context-graph`. That is a **third** instance of the pair convention producing drift or asymmetry, alongside the parity-gate's own origin story and SO-4's unguarded second duplication. Three instances settles it. The caveat is R-0a: ADR-005 currently rejects "a Node toolchain," so the `.mjs` default is blocked on the ADR, not on the technical argument. And domain 05 is right that this is a one-way door going forward, not a rewrite campaign — the existing pairs are parity-gated and work.

**One justified exception to (iii)**: **R-8** (phase entry/exit verifier) is correctly skill-invoked. Its trigger is a *workflow moment* (entering a phase in a fresh session), not a file change, so neither pre-commit nor CI can fire it. This is the same carve-out domain 05 grants the release flow, and it is the second and last legitimate member of that class. It should carry the same reinforcement domain 05 prescribes for R-1 — the invocation stated as the literal first action of each phase skill's Phase Entry, `|| exit 1`, not as prose an agent may summarize.

### What the roadmap costs

Twenty entries, ten proposing-domains' worth of enthusiasm, and a maintainer who has to live with all of it. The costs, named:

**1. Documentation cost is superlinear unless R-15 ships early.** Every gate must be described in four places (`.githooks/pre-commit:19-40`, `CONTRIBUTING.md:52`, `.context/domains/hooks.md:120-128`, and its own banner). That obligation has failed three cycles running and is currently at 3-of-10, 4-of-10, and 1-of-2 respectively. Ten more gates makes it 3-of-20. **R-15 is not rank-13 work if more than two other items ship** — it is a prerequisite, and IO-X-5 (gate-authoring standard) is its companion. This is the single most under-priced item on the list.

**2. Every gate ships a new bypass token, and nobody counts them.** Inventoried this audit: **25 occurrences** of `<!-- pre-commit:dead-ref-ok-start/end -->` and `<!-- context-graph:orphan-ok -->` across ~13 tracked files (excluding `.context/tasks/`), plus the `<!-- ICON-PLACEHOLDER -->` sentinel. The roadmap proposes at least three more marker families (`# portability-ok:`, `<!-- icon-seq-ok -->`, and R-3's allowlist globs). There is no inventory, no review, no expiry, and no gate on the gates' escape hatches.

   And this is not theoretical. **A suppression marker added to satisfy one gate is the proximate cause of a Critical in this very audit.** Commit `2866f2b` prepended two `context-graph:orphan-ok` lines to `context_template/context/workflows/task-workflow-template.md` *solely* to satisfy ICON's own graph gate; that edit is what makes `upgrade-repo`'s stock-vs-customized diff (`skills/upgrade-repo/SKILL.md:119-145`) misclassify every byte-perfect stock copy in the pre-2.0.0 installed base as CUSTOMIZED (C-89-03-01). Domain 03 spotted the mechanism in passing (SO-5(b): *"a case of one gate breaking another skill"*); the cross-cutting weight is that **the marker was the minimum-effort way to make a gate green, and minimum-effort-to-green is what gates train for.** Cheap mitigation: a CI *report* (not a gate) enumerating every suppression marker in the tree, plus one line in the audit brief. Cost: near zero. Value: it makes the bypass surface visible before it is load-bearing.

**3. False positives concentrate in three entries.** R-3 needs allowlists for legitimate historical references (CHANGELOG entries, superseded ADRs, the `security.yml:1-5` port comment, the `glpat-` detection pattern name, the `.mr-2` CSS class in the style template) — domain 05 enumerated these correctly. R-13 needs an allowlist for `writing-skills:255-258`'s deliberate naming-guidance examples. R-12 needs fence-blindness handling for the illustrative `Step N` strings inside `writing-skills`' own code fences. All three want an advisory period. Budget for it; a gate that cries wolf in week one gets `--no-verify`'d in week two, and there is currently no CI backstop to notice.

**4. Two candidates I would not build.**

   - **R-19 (skill size gate) — do not build.** Its entire violation population is one file: `writing-skills` at 532 lines against its own 500-line rule at `:208`. The next largest skill in domain 04's scope is `rfc` at 349. A gate whose finding set is a single known file is a bug report with CI attached — and `writing-skills:271` ("Complex discipline skills: can go longer, but earn every line") already self-exempts the word axis, so the gate first needs a per-skill declared-budget convention (02 IO-P-0089-3) that does not exist. Build the convention if the *signal* is wanted; fix the one file via domain 04's IO-U-3 split. Do not build the gate.
   - **R-12's broad form — do not build.** Domain 01 already declined the full ordered-list resolver, and I concur with an added reason: it is the most displaceable entry on the list (D=1). A gate asserting numbering hygiene trains an author under deadline to renumber until green without checking the referent — the failure moves rather than closing. Domain 01's **narrow** variant (require `<Section Name> Step N` qualification) is three edits repo-wide (`manager.agent.md:91`, `:92`, `context-specialist.agent.md:82`), is pure regex, and buys the readable half honestly. Build that; skip the resolver. Note the honest limit domain 01 already stated: the qualifier rule prevents *ambiguity* and makes staleness reviewable; it does not detect a stale ordinal after renumbering. Accept that.

**5. The corrected specification for R-9, restated so it is not lost.** Assert **both** `heading_count == awk-RS="" record_count` (the coalescing detector, as domains 02 and 05 specified) **and** `heading_count ≤ ENTRY_CAP`, with the cap read from `append-retrospective-entry.sh:41` rather than hardcoded. Per x-89-1, the equality assertion alone runs green on `.context/retrospectives.md` right now, at 11 entries against a cap of 10.

---

## The Reach of Mechanization

The brief asks the hard version of the question, so here is the direct answer before the argument: **mechanization's reach is real, durable, and larger than the escalation evidence suggests — but only for gates anchored to a source of truth, and only up to the level of abstraction at which the invariant has a written representation.** The abstraction-level escalation domain 03 observed is **not** displacement. It is a detection-ceiling effect, and it is the expected and desirable consequence of closing a lower layer.

### The evidence, and what it actually shows

Three closure mechanisms are observable in ICON's record with sharply different durability. This is the useful comparison, and it is only available from the synthesis seat because each domain saw one facet.

**Tier 1 — a script gate. Closed once; stayed closed under maximum stress.** The README skill-registration class recurred across ICON-0046 (`mcp-tools-first`) and ICON-0058 (`characterization-testing`). Two remedies were tried. ICON-0060 shipped a **prose checklist** into `CONTRIBUTING.md:54-57`; the class had already recurred once by then and the checklist was not the thing that stopped it. ICON-0080 shipped a **fail-closed gate** at `.githooks/pre-commit:704-732`. Result this cycle: **50 of 50 skills registered, zero misses** — and `.context/retrospectives.md:43` records the gate *firing in anger* during the highest-churn task in the interval (ICON-0080 renamed three skills and deleted three more): *"the README skill-registration gate blocked committing the renamed skills until README was updated."* A rename storm is precisely the event that beat the prose checklist, and the gate held.

**Tier 2 — a precise specification. Closed once, immediately, incompletely.** Domain 04 Observation 3: ICON-0058's IO-U-1 named four numbered edits with exact target lines for `ecological-impact`, and ICON-0059 — the very next task — executed that specification (`CHANGELOG.md:91`). Where the ICON-0046 → ICON-0047 handoff drifted to a different skill, a sufficiently concrete recommendation did not. But the sweep **stopped at the files the recommendation named**: `README.md:162` still describes the skill as measuring "a **Copilot** session," thirty tasks later (m-U-7). Precision buys a single execution; it does not buy a boundary.

**Tier 3 — a process ledger. Did not function.** X-89-1: four of six pre-assigned IDs re-scoped, six issue links unreachable, no brief reads the table, the filing target is a tracker ICON abandoned. The recommendations closed anyway — via Tier 2 in one case and via unrelated later tasks in the rest.

The ordering is unambiguous, and it is the empirical core of this cycle's directive. But it does not license "mechanize everything," and the next three sections say why.

### The escalation is a ceiling, not a displacement — and the brief's framing needs one correction

Domain 03's observation is exact and worth quoting: ICON-0058 predicted a literal-grep gate would close sweep-incompleteness. *"That prediction held in the affirmative: all five 'the 15th' instances and all three 'plugin-lint Check' instances were swept clean this interval. But the class did not disappear — it moved up a level of abstraction. This cycle's equivalent findings are not stale literals; they are stale obligations (C-89-03-03, M-89-03-02, M-89-03-03), which no literal grep can see."*

The correction the synthesis lens supplies: **the gate was never built.** ICON-0015's O-V4 literal-grep gate remains unimplemented — domain 05 confirms it is now 4+ cycles open, and domain 04 establishes that only a *partial* implementation exists (`O-M1b` at `.githooks/pre-commit:650-700`, one literal, four bespoke regexes). The literals were swept **by hand**, under ICON-0060 (`CHANGELOG.md:92`).

So the escalation happened without a gate. Whatever caused it, a gate did not. That falsifies the displacement hypothesis in its strong form and points at the real mechanism: **fixing a failure class at level N does not create level N+1; it *reveals* it.** The stale obligations in `impl-root` were there the whole time. ICON-0046 and ICON-0058 did not miss them out of carelessness — they were downstream of a noisier, cheaper-to-find class that consumed the audit's attention. Clear the literals and the audit's marginal attention moves to the next layer down, where it finds what was always there.

That reframing is not cosmetic. It changes the expected value of the roadmap:

- Under **displacement**, twenty gates buy twenty relocated failures and the program is close to worthless.
- Under **detection-ceiling**, twenty gates buy twenty permanently-closed classes *plus* visibility into a layer that was previously invisible — at the cost of an audit that must work harder and will report *more* findings, not fewer, for several cycles.

The second model predicts exactly what this cycle observed: 0 → 5 Criticals and 3 → 25 Moderates against a *rising* mechanical-invariant pass rate. Every gated invariant in the repo is clean (script parity byte-identical ×6, `common-constraints` byte-equal ×9, `context-graph --check` clean at 49 nodes, `check-rules-index` clean, `structural-check` 5/5, README 50/50, zero dead `.context/` refs, zero residual GitLab/Jira terms in `agents/` and `skills/`) while the finding count went up eightfold. Under the displacement model those two facts contradict each other. Under the ceiling model they are the same fact.

**The honest caveat**: I cannot fully separate "deeper inspection" from "genuine regression." The interval was the largest in ICON's history — a breaking 2.0.0 release adding session-per-phase, a knowledge graph, model-aware isolated delegation, CI, a second harness hook, and seven pre-commit gates. Some of the 25 Moderates are real new debt introduced by that velocity; domain 02's Observation 1 makes the case crisply that all four of its net-new Moderates are *seams* left by session-per-phase — new work, incompletely swept. What I can say with confidence is that the three Criticals in domain 03 are **not** new: `upgrade-repo` Phase 1's stock-vs-customized diff, `initialize-monorepo`'s `.sln` parsing, and `impl-root`'s missing `claude.md` redirect are all long-standing, and `M-89-03-07` (ICON's own `.context/iconrc.json` at schema 1.2 against a 1.12 template) proves why they were never found: **`/upgrade-repo` has never been executed against ICON itself.** They could only ever surface by someone reading the code, which is what happened this cycle.

### What is mechanizable in principle — a sharper line than "obligations aren't"

Domain 03 writes that stale obligations are unmechanizable because *"there is no literal to grep for."* That is true as stated and slightly too pessimistic as a general claim. The precise version:

> **A class becomes mechanizable exactly when its invariant has a representation the checker can compare against. Most of this cycle's "no grep can see this" findings are really "no grep can see this *yet*, because the thing to compare against does not exist as a comparable."**

Test it against the actual findings:

- *"Root init must produce what leaf init produces"* — unmechanizable as prose, mechanizable the moment the required-file set is a manifest keyed by `tree_position`. Domain 03 reached this independently and it is the whole reason IO-89-03-01 is scoped as a *prerequisite* rather than a gate. The obligation is currently written out in prose **six times** (`impl-leaf:298-314`, `impl-branch:120-130`, `impl-root:289-303`, `upgrade-repo:108-181` and `:619-627`, `initialize-repo`'s 3-item check) — six copies is not "unrepresentable," it is "represented six times, comparably zero."
- *"Every isolated specialist has a warmstart-in / report-out contract"* — ADR-015 asserts it of seven agents; `manager-routing-guide/SKILL.md:104-114` already holds the authoritative roster as a table. Parse the roster, assert the sections. Domain 01's SO-A-5 is exactly that, and domain 01 correctly notes it is the same shape as the O-V1 gate that has held through a rename storm.
- *"The removal is complete"* — unmechanizable as a judgment, mechanizable as `banned-literals.json` + whole-tree CI. The obligation is even *written down twice* in the retro log (`.context/retrospectives.md:8`, `:43`) as "give sweep coders a whole-tree grep mandate" — which is a script specification expressed in English.

This is why three domains independently converged on **declarative data + thin checker** (IO-X-4). The bottleneck is not checker technology. It is that ICON's invariants live as prose restated at N satellite sites, and prose restated at N sites is the *cause* of the drift as well as the reason it can't be checked. ICON-0088 promoted exactly this rule — *"Satellites point by reference; only the canonical site enumerates"* (`.context/retrospectives.md:2`) — and then, in the same entry, recorded that it was *"Caught by @reviewer, not by any gate."* The rule and its own unenforceability shipped together.

### What is genuinely not mechanizable

Three categories, and every domain drew the line in the same place without co-ordination — all five wrote an explicit `(d) residual judgment` section, and domain 01 added a rejected-candidates note. That uniformity is itself evidence the line is real.

1. **Truth about the world, as opposed to internal consistency.** M-U-1's worked example disagrees with its own formulas by 1000× — that *is* mechanizable, and domain 04's IO-U-4 (generate the example from the constants) is the right answer. But whether `0.001 kWh` per 1,000 tokens is the correct constant, when `:103` cites a basis implying ~57× less, is a claim about energy consumption. A script can make a document self-consistent; it cannot make it true. Note the sharp implication: **generating the example would have made the skill consistently and confidently wrong** — the 1000× internal break is currently the only visible symptom of the 57× external error.
2. **Whether a rule should apply, and at what tier.** Accept-with-rationale vs trim (ADR-008); which section to extract from an over-budget file; whether a flagged construct is genuinely unavoidable; whether a numbering gap is deliberate. ADR-010's re-tier registry exists specifically to keep this human, and the brief's own consult-before-tiering rule is that principle applied to the audit.
3. **Whether a relationship should exist at all.** A reference-integrity gate can prove `manager-routing-guide:79` resolves; it cannot say whether one skill should reach into another skill's directory. `writing-skills:314` leaves the resolution deliberately open ("copy it into the skill that needs it, **or** reference a sibling skill"), and it should stay open.

### The failure modes of mechanization itself

This is where I most want to resist the cycle's own enthusiasm, because ICON supplies three verified instances and they are not the ones the roadmap protects against.

**A gate can encode its author's blind spot and then verify itself against it.** M-I-4 is the cleanest example I have seen anywhere. ICON-0087 pinned every `uses:` to a 40-char SHA, mechanized it via the semgrep `github-actions-mutable-action-tag` rule, codified it at `secure-coding.md:29`, and specified a **completeness grep** — `uses:\s*\S+@(v?[0-9]+|main|master)` — to prove nothing was missed. Three layers. All three matched `uses:` only. All three were blind to `container: image:`, which is where third-party code actually executes against the checkout (`security.yml:18,29,41`, all tag-pinned). The verification step confirmed the blind spot rather than revealing it. **This is worse than no gate, because it manufactures justified confidence.** The general lesson: a completeness check written by the same author as the rule inherits the rule's scope error, and no amount of rigor in *executing* it recovers the missing scope.

**A gate can assert a proxy instead of the invariant.** x-89-1. ICON-0088 shipped a heading-count-vs-record-count cross-check into `context_template/` (schema 1.12) for every consumer. It detects the coalescing *mechanism* and is currently green on a file that violates the *cap* it exists to protect. Both domains proposing to mechanize it would have shipped the same defect.

**A gate can be inert and nobody notices.** ADR-005's `python3 -c "import json; …"` is declared at `.claude/claude.md:14` and `005-no-build-step.md:19` as *the* validation for this repo; domain 05 verified `python3` resolves to the Windows Store stub on the maintainer's machine and does not execute. The `security` CI was red for many cycles unread (`.context/retrospectives.md:12`). `shellcheck` is not installed on the maintainer's box, so that pre-commit gate silently skips. Three controls, all believed active, none of them running.

And the structural cost, from X-89-3: all ten pre-commit invariants are opt-in per clone and `--no-verify`-bypassable with **no CI backstop whatsoever**. Every clean result quoted in the Tier-1 argument above is contingent on one config command.

### The design rule this yields

Putting the failure modes together with the escalation analysis:

> **Anchored gates compound. Instance gates displace. Proxy gates lie.**
>
> - **Anchored** — derives its expected value from a source of truth (a directory listing, a script constant, a manifest, a live CI status). `O-V1` is anchored to `skills/*/` and survived a rename storm precisely *because* renaming a skill changes the anchor rather than evading a pattern. `O-M1b` is anchored to `ENTRY_CAP=10` and cannot be routed around by rewording.
> - **Instance** — asserts a fixed string or shape. A gate banning the literal `the 15th` is satisfied by writing "fifteen." Useful, cheap, and permanently one edit from being circumvented by an author optimizing for green.
> - **Proxy** — asserts something *correlated* with the invariant. This is the dangerous class, because it produces a green signal that reads as a guarantee. Both current instances (M-I-4's `uses:`-only completeness grep, x-89-1's count-equality check) were written by careful authors who had just diagnosed the failure correctly.
>
> Before shipping any gate, state the invariant in one sentence, then ask whether the check *is* that sentence or merely correlates with it.

That rule is falsifiable against ICON's own record, it explains why the one gate that stayed closed stayed closed, it explains both of the repo's currently-broken controls, and it supplies the `D` column in the roadmap ranking. It is also the thing I would most want carried into the synthesis report, because it is the difference between building twenty gates and building twenty gates that hold.

**Final answer to the meta-question, in one paragraph.** Mechanization's reach in ICON is: *every invariant that can be written as data, checked against a live source of truth, and run somewhere unbypassable.* That is a large fraction of this cycle's findings — considerably larger than domain 03's "no grep can see this" framing implies, because the limiting factor is representation, not detection. It excludes truth-about-the-world, tier judgment, and should-this-relationship-exist, and every domain correctly refused those. The abstraction-level escalation is not displacement and is not an argument against the program; it is the signature of a detection floor rising, and it predicts that the next two audits will report *more* findings at *higher* abstraction while the mechanical layer stays clean. The real risks are not that gates fail to catch things — it is that gates encode blind spots and then confirm them, that they assert proxies and read as guarantees, and that ICON's entire enforcement layer is currently one un-run config command away from being decorative. Fix that layer (R-0b) and amend the ADR that forbids fixing it (R-0a) before building the eleventh gate.

---

## Token Economics Analysis

### Always-loaded (every manager session) — ADR-008 inventory, measured live

| Component | Words | Share of 8,500 |
|---|---|---|
| `agents/manager.agent.md` | 4,620 | 54.4% (**136% of the 3,400 per-component cap**) |
| `shared/common-constraints.md` × 9 | 3,321 | 39.1% |
| `skills/using-skills/SKILL.md` | 744 | 8.8% |
| **Manager session total** | **8,685** | **102.2% — over budget** |
| PM session total (2,394 + 3,321 + 744) | **6,459** | 92.3% of 7,000 — within budget |

Exact agreement with `ADR-008:43-46` and with domain 01's independent measurement. The ADR is accurate; the *state* is the finding, and it is accepted-with-rationale at `:44-45` with the discharge named as "a separate, not-yet-scheduled task."

### Per-phase session (ADR-013) — the surface ADR-008 does not measure

| Phase | Dispatcher surface | + `task-plan` | + phase skill | Total | vs 8,500 |
|---|---|---|---|---|---|
| architecture | 8,685 | 817 | 693 | 10,195 | 119.9% |
| testing | 8,685 | 817 | 779 | 10,281 | 121.0% |
| implementation | 8,685 | 817 | 811 | 10,313 | 121.3% |
| investigation | 8,685 | 817 | 948 | 10,450 | 122.9% |
| **completion** | 8,685 | 817 | **1,459** | **10,961** | **129.0%** |
| completion + one routing decision (`manager-routing-guide`, 1,455) | | | | **12,416** | **146.1%** |

Both additive components are excluded from the budget by `ADR-008:31`. This is X-89-2 and its remedy is IO-X-1. Caveats stated there (the 9× `common-constraints` figure is the ADR's own convention and is an upper bound; the ICON-0061 bootstrap changed how the manager body enters context, not whether it does).

### Highest-impact trim candidates, ranked

1. **`task-plan-phase-completion` (1,459 words, +75% since ICON-0058).** The largest single trim available anywhere in the per-session surface, and the only one with a *self-declared* budget to trim against (`:12-13` — *"Keep this skill minimal — it loads at the end of every task; token cost matters"*). ~200 of those words are the merge-coalescing hazard paragraph at `:105`, triplicated across three files — and R-9 retires it, converting ~600 words of prose into ten lines of shell. This is the cleanest instance in the audit of a trim and a gate being the same work.
2. **The phase entry/exit contract, restated ten times** (02 IO-P-0089-2 — five phase skills × two template trees, ~90% identical). R-8 collapses it to one script invocation plus a phase-specific payload. Same pattern: the mechanization *is* the trim.
3. **The manager's Anti-Rationalization table** (21 rows, `:261-281`) is the next extraction candidate after the Task Completion elaboration already moved under ICON-0070 — but this is exactly where ICON-0083's reinforcement rule bites, and it must not be cut without the maintainer ruling IO-X-1 asks for.
4. **Not a trim, but the highest leverage per word of effort**: the IO-X-1 scope amendment. A budget measuring the wrong surface produces no friction signal at all, which is ADR-008's entire stated purpose (`:10` — *"the audit cycle is the only friction signal, and the cycle fires on retrospective discovery rather than at the moment of growth"*).

### The ICON-0083 tension, stated plainly

Three of this report's improvement opportunities add words. `.context/standards/terseness-calibration.md` forbids de-duplicating reinforcing redundancy without sign-off; ADR-008 forbids growth. Both are correct and they conflict, and the conflict is *why* nothing has been scheduled for three cycles. The resolution is not a technical one — it is a single maintainer decision, and IO-X-1 frames it as such rather than carrying a fourth cycle of deferral. Worth noting the countervailing data honestly: the manager is **shrinking** (5,126 → 4,976 → 4,620, net −506, of which −356 came in ICON-0083 alone). The trend is favourable; the ceiling is still breached; the detector is still a human reading an ADR.

---

## Discoverability UX Analysis

### README skills tables — healthy, and gate-earned

Verified this audit by extracting both tables and cross-checking every row against on-disk `user-invocable` flags:

- `### Skills` table: **21 rows**, every one resolving to a `skills/<name>/SKILL.md` with `user-invocable: true`. Zero mismatches.
- `#### Internal Skills` table: **29 rows**. 21 + 29 = 50 = the exact count of `skills/*/`. Zero drift in either direction.

This is a genuinely strong result and it is directly attributable to the `O-V1` gate (`.githooks/pre-commit:704-732`), which held through ICON-0080's three renames and three deletions. ICON-0058's X-CC-3 / m14 is **fixed**, and fixed durably rather than incidentally.

**The one gap** is x-89-2: the gate's population is `skills/*/`, so the three maintainer skills in `.claude/skills/` are outside both tables and outside enforcement. `icon-audit` appears in `README.md` and `CONTRIBUTING.md` zero times. Remedy: IO-X-2.

### `using-skills` common-workflows and routing

`skills/using-skills/SKILL.md` (744 words) is tight and well-targeted: a 12-row rationalization table (`:40-53`), a five-item red-flags list (`:55-65`), a four-tier priority order (`:69-74`), and three concrete chain examples (`:76-78`). The `<SUBAGENT-STOP>` guard at `:8-10` is a good ADR-008-conscious touch — it prevents nine dispatched sub-agents from each re-running the catalog check.

**Two observations, neither tiered:**

1. **The chain at `:78` encodes the session-per-phase model correctly** — *"`task-plan` → `task-plan-phase-investigation` → `task-plan-phase-implementation` → `task-plan-phase-completion` → `task-retrospective`"* — which is the *sequence* model. This puts `using-skills` on the correct side of the contradiction domain 02 filed as M-P-0089-1, where `task-plan/SKILL.md:19-36` still describes the superseded one-skill-only selection model. Worth noting for the fix: the router is wrong and the always-loaded surface is right, so an agent that reads `using-skills` first and `task-plan` second gets contradicted by the more specific document.
2. **`:80` is the whole discovery mechanism**: *"To find which skills apply: read each skill's description. Descriptions name their triggers."* That single sentence is why domain 04's M-U-3 (three Format-type skills whose descriptions summarise workflow rather than naming triggers) and m-U-10 (`github-issue` and `post-meeting` with no trigger surface in frontmatter *or* body) are discoverability defects and not style nits — those two skills are unreachable by the documented mechanism. R-11's frontmatter gate is the mechanical half; domain 04's IO-U-5 is the content half.

### Onboarding funnel

`README.md:34-48`'s intent index is the right structure and it is better than most. The three gaps are IO-X-3 (no defect-reporting row, no headless-execution row, `CHEATSHEET.md` orphaned). One further note: `CONTRIBUTING.md:52` and `README.md:247` both carry the `git config core.hooksPath .githooks` instruction — ICON-0058's O-D2 shipped — but per X-89-3 those two prose lines are the *only* thing arming the entire enforcement layer, and the project has no way to verify a given clone did it. That makes the onboarding gap a force-multiplier on every gate in the roadmap, exactly as ICON-0058 predicted, and it is the strongest argument for R-0b.

### Rule discoverability (ICON-0058's Focus 2) — resolved

For the record, because it was the prior cycle's headline: the asymmetry ICON-0058 diagnosed is **closed**. `.context/rules-index.md` exists (45 lines / 597 words — index only, not bodies, preserving the ADR-008 economics M1 promised); it is read at Context Discovery (`manager.agent.md:93`); the rule-coverage gate is in the research-need check (`:57`); `### Applicable Rules` is a first-class warmstart block (`:156-157`) that @architect and @planner both name in their input contracts (`architect.agent.md:18`, `planner.agent.md:20`); and the pre-write governing-rule lookup is Hardcoded (`:233`). `decisions/` now appears in agent files, where ICON-0058 measured zero occurrences. All five mechanisms M1–M5 landed. This is the largest single closure in the delta and it should be credited plainly in the synthesis.

---

## Retrospective Pattern Analysis

Corpus: `.context/retrospectives.md` (11 entries, ICON-0078 → ICON-0088 — note the over-cap state, x-89-1) plus `.context/retrospectives-archive.md` (15 entries, ICON-0063 → ICON-0077). 26 entries total across the interval.

### Pattern 1 — "The remedy for an ungated failure is prose, and the retro says so in the same breath" (4 instances, meets the 3+ threshold)

Four entries in the rolling log record a failure and, *in the entry itself*, state that no gate caught it:

- `.context/retrospectives.md:2` trap (2) — satellite enumeration going stale: *"Caught by @reviewer, not by any gate."*
- `:2` trap (3) — 3-cell row in a 2-column table, entire column vanishes at render: *"no gate catches column-count mismatch."*
- `:2` trap (4) / `:4` item (4) — `merge=union` separator coalescing: *"undetected by any pre-commit gate."*
- `:55` (ICON-0078) — stale `Step 8` after renumbering: *"caught by @reviewer, not by any gate … the dangling-reference class is invisible to the pre-commit hooks."*

In all four the shipped remedy was **promoted prose** — a standards section, a companion invariant row, a 200-word hazard paragraph triplicated across three files. In at least three the check is a one-liner (R-4, R-9, and R-12's narrow form). Domain 02 identified this as the domain's "remedy reflex"; the cross-cutting weight is that the retrospective process is *diagnosing* mechanizability correctly and then *not acting on the diagnosis*, four times in one rolling window.

**Evaluation**: this is the strongest possible argument for domain 02's **IO-P-0089-1** — *"prose describing a deterministic check must cite the script that performs it, or record why one is impractical."* It converts the reflex from "write a warning paragraph" to "write a gate, cite it in one line," and it would have prevented three of the eight candidates in domain 02 from ever becoming prose. Paired with IO-X-4 (what to build instead), this is the durable form of the cycle's directive. **Warrants a standard**, not another retro entry.

### Pattern 2 — "A claimed guarantee is a hypothesis until you trace the mechanism that enforces it" (5+ occurrences; already promoted, and still firing)

`.context/standards/skill-decomposition/verify-design-claims-against-artifacts.md` is at occurrence count **six** by its own record (`.context/retrospectives.md:20`). Instances in the current window: ICON-0082's advertised bounded-retry with nothing incrementing `Attempts` (`:33`); ICON-0085's false harness-capability premise that *"passed BOTH design and @reviewer"* (`:18`); ICON-0073's verify-external-tool-behavior-by-execution corollary.

**Evaluation**: already promoted, correctly, and still generating findings — including two in *this* audit that fit it exactly. M-I-5 (the documented `python3 -c` validation that does not execute) and M-I-4 (the completeness grep that encoded the same blind spot as the rule it verified) are both "a claimed control is a hypothesis until you trace it firing." The standard exists and is well-written; the gap is reach, not content. Worth noting that the standard's own corollary structure — "claimed-bound corollary," "harness-capability corollary" — invites a third: a **claimed-control corollary**: *a documented validation command is a hypothesis until someone runs it on the machine that is supposed to run it.* One paragraph, sixth-occurrence precedent, and it would have caught M-I-5.

### Pattern 3 — "Sweep incompleteness: a feature removal is complete only when every dependent reference is swept" (5+ occurrences across both files)

`.context/retrospectives.md:8` (ICON-0086), `:43` (ICON-0080), plus ICON-0074/0077 in the archive. The rule is promoted (`skill-decomposition/process-doc-sweeps.md`) and stated in operational form twice: *"A repo-wide grep for the feature's own identifiers … is what makes the removal complete"* and *"give sweep coders a whole-tree grep mandate, not just a hand-curated file list."*

**Evaluation**: this is the pattern that has been promoted, restated, and re-violated the most. Live instances this cycle: `.claude/skills/icon-audit/SKILL.md:124,151` (GitLab, two releases post-conversion), `README.md:162,172`, `context_template/…/commit-conventions.md:74` (`MKT-`), `skills/icon-init/SKILL.md:215` (orphaned Step 5a), `skills/icon-status/SKILL.md:118,130` (Signal 1 → Signal 3), `.context/standards/shell-portability.md` Rule 5 (cites two removed mechanisms). Six live instances of a rule promoted three times.

Note the shape precisely: **"whole-tree grep mandate" is a script specification written in English.** It is the clearest case in the corpus of retrospective wisdom that should be automated and has not been — and it is R-3, ranked 3, with the added observation that R-3 *must* be CI-authoritative because a staged-file hook is structurally blind to the sites the current commit does not touch.

### Pattern 4 (net-new this cycle) — "A rule needing a special case for a member of its own domain has the wrong boundary axis"

Single high-quality instance (ICON-0088, `.context/retrospectives.md:2`), already promoted to `.context/standards/skill-decomposition/boundary-axis-selection.md`. Below the 3+ threshold, so no action is warranted — but I flag it because it is directly relevant to this cycle's roadmap and to X-89-2. The promoted rule includes *"prefer an axis coinciding with an already-enforced mechanism over one orthogonal to any."* That is the same insight as IO-X-4 and the same insight as the anchored-vs-instance distinction, arrived at from a third direction (rule design rather than gate design). Three independent derivations of one principle in one interval is worth naming in the synthesis.

### Cross-pattern meta-shape

All four patterns are the ICON-0058 meta-finding — *a rule that exists in the corpus is not reached at the moment it applies* — with one addition this cycle supplies. ICON-0060 (reach automation), ICON-0069 (rules-index), and ICON-0088 (binding urgency) each attacked **reach**: making the right rule easier to find or harder to defer. Domain 02 makes the observation that closes the loop: *"a rule expressed as prose must be reached to fire, so improving reach has a ceiling that a rule expressed as a gate does not have."* Three cycles of reach work have hit that ceiling. **Representation, not reach, is the next axis** — and that is precisely what the 20-entry roadmap is.

---

## ICON-0058 Delta

### Fixed since ICON-0058

| ICON-0058 ID | Description | Evidence |
|---|---|---|
| **Focus 2 / M1** | `.context/rules-index.md` — index of `standards`/`workflows`/`decisions` with per-row triggers, auto-read at Context Discovery | **Shipped** (ICON-0069). File exists, 45 lines / 597 words, 7 standards + 5 workflows + 15 ADR rows; read instruction at `agents/manager.agent.md:93`. Index-only design preserved the ADR-008 economics as M1 promised. |
| **Focus 2 / M2** | Rule-coverage gate in the manager's research-need check | **Shipped.** `agents/manager.agent.md:57`. |
| **Focus 2 / M3** | Required `### Applicable Rules` warmstart field | **Shipped.** `agents/manager.agent.md:156-157`; named in the input contracts at `architect.agent.md:18` and `planner.agent.md:20`. |
| **Focus 2 / M4** | Pre-write governing-rule lookup, Hardcoded | **Shipped.** `agents/manager.agent.md:233`. |
| **Focus 2 §1(a)** | *"`decisions/` appears in zero agent files"* | **Closed.** Now present at `manager.agent.md:57`, `:93`, `:157`. |
| **M1 (Moderate)** | `context_template/phase-completion.md` retrospective template incompatible with the append script's `### ` validation | **Fixed both copies** (ICON-0059, `CHANGELOG.md:90`). Domain 02 verified. |
| **M2 (Moderate)** | `ecological-impact` Copilot coupling — the "third-cycle carry-forward" | **Fixed by ICON-0059**, the very next task (`CHANGELOG.md:91`). **The dispatch brief's premise that this was heading for a fourth cycle was false**; corrected at `plan.md:20`. Residue only (`README.md:162`, m-U-7). |
| **m14 / X-CC-3** | README skill-registration gap (recurring class) | **Fixed and mechanized** (ICON-0080). `.githooks/pre-commit:704-732`; **50/50 registered, zero misses**; gate confirmed firing in anger at `.context/retrospectives.md:43`. The one class this audit can call permanently closed. |
| **m1 / X-CC-2** | Triple `verification-checklist` invocation | **Fixed** (ICON-0068). Single owner at `manager.agent.md:214`; standalone fallback documented at `task-retrospective/SKILL.md:129`. |
| **m5 / X-CC-1** | 15→10 cap literal in 4+ sibling sites | **Fixed** (ICON-0060, `CHANGELOG.md:92`). Repo-wide grep for `the 15th` / `cap (15)` returns zero outside `.context/tasks/`. Fixed **by hand** — the O-V4 gate that would have prevented it was not built (see § The Reach of Mechanization). |
| **m7 / O-S2** | Phantom "plugin-lint Check A/B" labels, 3 sites | **Fixed** (ICON-0071). Zero hits repo-wide. |
| **O-V3** | Audit-finding disposition ledger | **Mechanism shipped** as `synthesis-template.md:160-164` + checklist item `SKILL.md:152` — **but write-only in practice.** See X-89-1. Counted here as shipped, not as closed. |
| **O-D2 / IO-I-D** | README pre-commit hook-install reminder | **Fixed.** `README.md:247`. |
| **O-V4 / IO-I-C** | CHANGELOG `### Changed` dedup guard in the release flow | **Fixed.** `.claude/skills/release-plugin/SKILL.md:135-141`, with a runnable `awk` and an explicit "must print nothing" assertion. Domain 05 verified it returns empty today. |
| **IO-58-02 / IO-58-03** | `impl-branch` verify step; `initialize-multimodule` root asymmetry | **Fixed** (ICON-0077, ICON-0078). |
| **Section-level** | Third-party contribution integration (Focus 1) | No longer a distinct concern this cycle — no domain reported a contribution-integration defect, and the registration gate that closed Focus 1's headline finding is the one gate confirmed holding. |

### Still present or partial

| ICON-0058 ID | Current status |
|---|---|
| **M3 / X-CC-M1** — audit-recommendation-to-task-scope drift | **Still present; the remedy shipped and does not function.** 4 of 6 pre-assigned IDs re-scoped; `gh issue list --state all` → `[]`; no brief reads the ledger; the filing target is still GitLab. **Escalated in specificity** and re-filed as **X-89-1**. Honest qualifier: the recommendations closed anyway, by other means. |
| **O-T1 / IO-CC-T1** — ADR-008 cumulative drift | **Measurement half fixed, remediation half not, and the scope is now wrong.** ICON-0088 added the cumulative-drift trigger (`ADR-008:24`) and a fresh snapshot; that surfaced a *new* session-total overage (8,685 / 8,500 = 102.2%, `:45`) with discharge named "not-yet-scheduled." ADR-013 additionally invalidated the scope carve-out at `:31`. Re-filed as **X-89-2** + **IO-X-1** (and 01 M-A-0089-2 / IO-A-0089-6). Third consecutive cycle. |
| **O-M1 / IO-CC-M1 / ICON-0015 O-V4** — literal-grep gate | **Still unimplemented, now 4+ cycles** — but **partial**, not absent: `O-M1b` (`.githooks/pre-commit:650-700`) implements it for one literal with four bespoke regexes. Reporting it as "unimplemented" overstates; as "done" understates. Generalization is **R-3**, ranked 3. |
| **O-T2 / m4** — `task-plan-phase-completion` unbounded "keep minimal" | **Still present and regressed**: 832 → **1,459 words** (+75%). ICON-0058's proposed ≤850-word ceiling was never added and the file now exceeds that figure by 72%. No budget observes it, by ADR-008's own carve-out — which X-89-2 argues is the real defect. |
| **m8 / O-S4** — `writing-skills` over its own 500-line cap | **Still present and regressed**: 524 → **532 lines**. Third cycle. R-19 is the gate proposal and I recommend **not** building it; domain 04's IO-U-3 split is the right fix. |
| **m6** — `upgrade-repo:122` agent-invoked `> /dev/null 2>&1` | **Still present, third cycle**, and now **materially load-bearing** for Critical C-89-03-01 (it swallows the `diff` error that causes the misclassification). ADR-007's carve-out does not apply — agent-invoked. Meets ADR-010 Part B: fix it or register it, do not carry it silently to a fourth. |
| **m3** — phase-skill `Does NOT cover` footer gaps | **Still present, unchanged, third cycle.** Proposed for mechanization (R-10) rather than a fourth manual report. |
| **m2** — close-gate lint-evidence ownership | **Partial.** ICON-0068 added the pure-content N/A escape; the lint-owning-agent gap persists for repos with a lint command. |
| **m9** — `plugin-design` "plugin-agnostic" self-contradiction | **Still present**, `skills/plugin-design/SKILL.md:14`, three cycles. Out of every 2026-07 brief's `## Scope`; domain 04 flagged it for synthesis to assign ownership. **Recommend assigning it explicitly** — it has now survived three cycles partly by falling between briefs, which is a small instance of X-89-1's class. |
| **IO-58-04** — `icon-init` / `detect-tree-position` 4→3 mapping undocumented | **Still present and worse** — a third divergent copy of the signal list now exists at `resolve-repo-context:60-64`. |
| **m10 / m11** — DataScan org URLs | **Disposition superseded by events.** ICON-0058 accepted these as intentional production state; ADR-011 is now `Status: Superseded by ICON-0080` and ADR-010 m9 is Closed, so the sanction is gone. The URLs went with the conversion — but removing them stranded `ORG-004`/`RFC-001` as undefined normative identifiers in nine places (04 M-U-2). **A closed finding reopened at a different layer by the fix for something else** — the same shape as x-89-1 and worth noting as a pattern. |
| **ICON-0058 "no CI config present"** | **Superseded.** CI exists (`.github/workflows/security.yml`) — and adds *scanning*, not invariant enforcement. That gap is **X-89-3**. |

### Net-new drift classes

1. **X-89-1 (Moderate)** — the audit → follow-up → next-audit loop is broken at all three links: pre-assigned task IDs (4/6 re-scoped), issue linkage (`gh issue list --state all` → `[]`), and read-back (no brief's `## Prior-Audit Pointer` names the dispositions table). `ICON-0058/audit-report.md:289`; `briefs/0{1..6}-*.md`; `.claude/skills/icon-audit/SKILL.md:124,151`.
2. **X-89-2 (Moderate)** — ADR-013's session-per-phase model invalidated ADR-008's scope carve-out (`:31`); the measured completion-phase session is 10,961 words against an 8,500 ceiling that excludes its two largest additive components by rule.
3. **X-89-3 (Moderate)** — the entire enforcement layer is advisory: ten pre-commit invariants, opt-in per clone, `--no-verify`-bypassable, **zero CI backstop** (verified — no invariant checker appears in `.github/workflows/*.yml`). Every clean mechanical result in this audit is contingent on one config command.
4. **x-89-1 (Minor)** — `.context/retrospectives.md` holds 11 entries against `ENTRY_CAP=10`, and the ICON-0088 cross-check reports clean because both counts equal 11. **Corrects the specification of two upstream candidates** (02 S1, 05 SO-8 → R-9).
5. **x-89-2 (Minor)** — the three `.claude/skills/` maintainer skills are registered in no README or CONTRIBUTING table and sit outside the O-V1 gate's `skills/*/` population; `icon-audit` is documented zero times.
6. **x-89-3 (Minor)** — the audit's own dispatch inputs are hand-authored and unverified; two errors reached five sub-agents this cycle (the stale `ecological-impact` carry-forward premise, and a maintainer-skill inventory naming two skills that are not there).
7. **Proxy-gate class (methodological, net-new)** — two verified instances of a mechanized control that asserts something *correlated* with its invariant and therefore reports green on a violation: M-I-4's `uses:`-only completeness grep, and x-89-1's count-equality check. Distinct from a gate that is *absent* or *bypassed*, and more dangerous than either because it produces justified confidence. Drives the `D` column in the roadmap and the design rule in § The Reach of Mechanization.

---

## Verification Evidence

All commands read-only; no plugin source modified. Only this file was written.

| Check | Command | Result |
|---|---|---|
| Always-loaded word counts | `wc -w agents/manager.agent.md agents/product-manager.agent.md shared/common-constraints.md skills/using-skills/SKILL.md` | 4,620 / 2,394 / 369 / 744 — session totals 8,685 (mgr), 6,459 (PM); exact agreement with `ADR-008:43-46` and domain 01 |
| Phase-session surface | `wc -w skills/task-plan/SKILL.md skills/task-plan-phase-*/SKILL.md skills/manager-routing-guide/SKILL.md` | task-plan 817; phase skills 693/779/811/948/1,459; routing-guide 1,455 |
| Retrospective cap | `grep -c '^### '` and `awk 'BEGIN{RS=""} END{print NR}'` on `.context/retrospectives.md` | **11 and 11** — agree, and both exceed `ENTRY_CAP=10` (`append-retrospective-entry.sh:41`, all three copies) |
| Over-cap persistence | `git show <rev>:.context/retrospectives.md \| grep -c '^### '` at `HEAD`, `HEAD~1`, `ae4cf39`, `7836a6f` | 11 at every revision — predates and survived the ICON-0088 repair |
| Prune self-heal | read `append-retrospective-entry.sh:160-163` | `keep = cap - 1` when `n >= cap` — converges on next append; severity Minor |
| Follow-up issue linkage | `gh issue list --state all --limit 40 --json number,title,state` | `[]` — zero issues, open or closed |
| Follow-up task re-scoping | `ls -d .context/tasks/ICON-006{1,2,3,4}-*` + `grep "ICON-00NN" CHANGELOG.md` | 4 of 6 pre-assigned IDs used for unrelated work |
| Dispositions read-back | `grep -rn 'Post-Review Dispositions' .claude/skills/icon-audit/` | Present only in `synthesis-template.md:160,162,164` and `SKILL.md:152`; **absent from all six briefs** |
| Focus-2 mechanisms | `grep -rn 'rules-index\|Applicable Rules\|governing' agents/` | M1–M4 all present: `manager.agent.md:57,93,156,233`; `architect:18`; `planner:20` |
| README table integrity | extract both tables, resolve each row against `skills/*/SKILL.md` `user-invocable` | 21 user rows (all `true`) + 29 internal rows = 50 = `ls -d skills/*/`; **zero mismatches** |
| Maintainer-skill registration | `ls -d .claude/skills/*/`; backticked-name counts in README/CONTRIBUTING | 3 skills (`changelog-entry`, `icon-audit`, `release-plugin`); icon-audit 0/0, changelog-entry 0/0, release-plugin 0/1 |
| O-V1 gate scope | read `.githooks/pre-commit:704-732` | iterates `"$repo_root"/skills/*/` only — `.claude/skills/` out of population |
| CI invariant backstop | `grep -n 'structural-check\|check-rules-index\|context-graph' .github/workflows/*.yml` | **No matches.** Jobs are `secret-scan`, `sast`, `shellcheck` (`security.yml:14,25,37`) |
| Local hook arming | `git config --get core.hooksPath` | `.githooks` — set in this clone; domain gate runs are valid |
| Suppression-marker inventory | `grep -rn 'pre-commit:dead-ref-ok\|context-graph:orphan-ok\|ICON-PLACEHOLDER'` excl. `.context/tasks/` | **25 occurrences** across ~13 files, no inventory or review anywhere |
| Baseline-preamble inventory | `ls -d .claude/skills/*/`; `find . -name SKILL.md -path '*work-roadmap-auto*'`; `grep user-invocable skills/security-review/SKILL.md` | `security-review` is a shipped skill (`user-invocable: true`), `work-roadmap-auto` is absent from the repo — `plan.md:68` is inaccurate |
| Upstream candidate coverage | manual merge map, each of the 34 IDs assigned exactly once | 34 → 20 entries; sum verified in the roadmap table |
