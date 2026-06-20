# Cross-Cutting Audit — Raw Findings

## Summary

The cross-cutting state at v1.19.0 + [Unreleased] (ICON-0056/0057) is **healthy and improving**, but the audit-to-fix economy has a structural leak that the ICON-0046→ICON-0058 delta makes unmistakable. The two headline hardening moves of this interval — `task-retrospective` → Hardcoded (ICON-0056) and the itemized non-skippable close-gate (ICON-0057) — are the strongest process changes in two cycles and are mechanically sound (Domain 01 Observation 1; Domain 02 Observation 1). Movement since ICON-0046 is net-positive: ~7 prior Minors confirmed fixed by the ICON-0048 sweep, no new Criticals, and frontmatter/scope-termination/common-constraints-sync invariants remain clean across all 9 agents (Domain 01 Patterns 2–4).

The dominant cross-cutting story is **partial-fix recurrence**: the same two failure classes ICON-0046 named — *sweep-incompleteness* (fix the cited literal, miss the siblings) and *audit-recommendation-to-task-scope drift* (the suggested follow-up task silently re-scopes away from the named Moderate) — both fired again this cycle. Five `keep-last-10` / "the 15th" literal-sweep misses surfaced (Domains 03/05), the `ecological-impact` ADR-004 Moderate is now a **third-cycle carry-forward with zero structural remediation** (Domain 04 M-U-1), and the verification-gate ownership question that ICON-0046 flagged as a double-invocation is now a **triple-invocation** (Domains 01/02). One genuinely net-new Moderate appeared on the consumer-template surface: `context_template/phase-completion.md` ships a retrospective format the append script will reject (Domain 02 M-P-0058-1).

On the token surface, the manager has crossed from "tight" (ICON-0046: 97.1% of session cap, 247 words headroom) to "comfortable on session, structurally over on component" (54.7% of session cap, **136.7% of the 40% per-component cap**, +500 words cumulative from the ICON-0033 baseline = 5.9% of cap). The ADR-008 per-MR trigger design that lets this cumulative drift accumulate undetected is the highest-impact token finding.

The user's Focus-2 question — *why `.context/` rule/workflow knowledge fails to reach agents at the moment of need* — has a clean structural root cause that this audit's own evidence corroborates: **`.context/domains/` is privileged in the discovery path (it appears in the manager's research-need gate, the warmstart template, and the Anti-Rationalization table), while `standards/`, `workflows/`, and `decisions/` appear only in an ad-hoc flat subdirectory list that each agent re-reads at its own discretion — and `decisions/` appears in zero agent files at all.** The recurring failure classes this very audit catalogs (keep-last-10 misses, ADR carve-outs re-flagged each cycle, README-registration gaps) are the operational symptom of that asymmetry.

---

## Defect Findings

Cross-cutting defects are systemic by nature; each finding below is labeled with its scope (which domains/surfaces it spans). Per the Non-Goals, these are **synthesis observations over the domain briefs**, not re-audits — domain-local defects are cited by reference, not re-tiered here.

### Critical

None observed. No domain brief reports a Critical; the synthesis surfaces none.

### Minor

**X-CC-1 — Sweep-incompleteness recurred as a cross-domain pattern (scope: Domains 02/03/05; systemic)**

- **Location**: `skills/upgrade-repo/SKILL.md:616`; `context_template/context/retrospectives.md:1`; `skills/context-maintenance/scripts/append-retrospective-entry.sh:6` (+ two byte-equal copies at `skills/task-retrospective/scripts/...:6`, `skills/post-incident-review/scripts/...:6`)
- **Finding**: The ICON-0041/0048 cap reduction (15→10) corrected the two prose files the audit named (`agent-vs-skill-invocation.md:23`, `context-maintenance/append-retrospective-entry.md:3,:32`) but left **five** sibling sites carrying the stale "15th" / "cap (15)" literal. Domain 03 (m-58-03-01, m-58-03-02), Domain 05 (m-infra-5), and Domain 02 (M-P-0058-1's adjacency) independently surfaced facets of the same literal. This is the exact Pattern A that ICON-0046's cross-cutting section and the ICON-0048 retro both named — and the ICON-0015 O-V4 placeholder/literal-grep gate that would have caught it mechanically **remains unimplemented across two+ cycles**.
- **Scope note**: This is filed by reference; the per-file Minors are owned by Domains 03/05. The cross-cutting finding is that the *mitigation* (a literal-sweep hook gate) is the unaddressed root cause, not any individual stale comment.
- **ADR check**: ADR-007 carves out only `2>/dev/null` in autonomous scripts — comment accuracy is not carved out, so the script-header copies are in scope. Not protected by ADR-010.
- **Classification**: Minor (systemic; documentation-accuracy + consumer-template multiplier). Highest-multiplier site is `context_template/context/retrospectives.md:1` — copied verbatim to every newly-initialized consumer repo.

**X-CC-2 — Triple verification-checklist invocation in the task-close path (scope: Domains 01/02; systemic regression)**

- **Location**: `agents/manager.agent.md:203` (Step 2), `:210` (close-gate item 4), `:233` (Hardcoded restatement); `skills/task-retrospective/SKILL.md:127-130` (Steps 6–7)
- **Finding**: ICON-0046 flagged a *double* `verification-checklist` invocation (m-P-NEW-3, improvement O-S1). The recommended fix was never executed (ICON-0049 re-scoped to characterization-testing). ICON-0057 then added the close-gate's item 4 on top of the existing double, producing a **triple** invocation with no note in any of the three sites explaining the intent. Domains 01 (m-A-0058-1) and 02 (m-P-0058-1) both surface this; the cross-cutting framing is that a flagged improvement that was never executed *worsened* across the interval because a new feature was layered on the unresolved structure.
- **ADR check**: Not protected by ADR-010; m-P-NEW-3 was an active improvement opportunity, not an accepted carry-forward.
- **Classification**: Minor (redundancy is safe — the close-gate is authoritative — but the unintended escalation erodes confidence that the documents are maintained holistically).

**X-CC-3 — README discoverability surface is the persistently-late registration step (scope: Domains 04/07; recurring class)**

- **Location**: `README.md:184-213` (Internal Skills table) — missing `characterization-testing` (ICON-0049) and `mcp-tools-first` (frontmatter fixed ICON-0048, table entry never added)
- **Finding**: Two consecutive `user-invocable: false` skills wired into `using-skills` routing but never added to the README Internal Skills table. Domain 04 (m-U-5) tiers this Minor; Domain 07 (M-07-1) tiers it Moderate specifically because it is a *recurrence of a named ICON-0046 defect class on a new contributed surface* with the registration step never on the task's radar (ICON-0049 retro confirms). The cross-cutting synthesis adopts Domain 07's read: the *class* is unmitigated (no pre-merge registration gate exists), so it remains available to re-fire on every new skill. Surface-level it's Minor per skill; structurally it is the second-most-recurrent vector after sweep-incompleteness.
- **Classification**: Minor per-instance / systemic-class. The mechanism that would close the class (IO-CC-V1 below) is the actual finding.

### Moderate

**X-CC-M1 — Audit-recommendation-to-task-scope drift leaves Moderates structurally unremediated across cycles (scope: systemic; process-level)**

- **Location**: `ecological-impact/SKILL.md:4,:12,:17,:21,:43-74,:149,:208` (Domain 04 M-U-1); evidenced against `.context/tasks/ICON-0046-icon-audit/audit-report.md:98` (O-T3 recommended ICON-0047) and ICON-0047/0049 retros (`.context/retrospectives.md:31-34,:21-24`)
- **Finding**: The single ICON-0046 Moderate (`ecological-impact` Copilot-product coupling, ADR-004) is now in its **third consecutive audit cycle with zero structural change** to the Option-A path. ICON-0046 recommended ICON-0047 as the follow-up; ICON-0047 addressed `writing-skills` instead. The deeper cross-cutting defect is not the skill — it's that the **audit-report → follow-up-task handoff is informal**: a Moderate labeled with a suggested task ID does not become that task's scope unless the user explicitly accepts it, and planning-time scope decisions silently override the audit recommendation. Domain 04 Observation 1 names this precisely. The same mechanism let X-CC-2 (verification triple) and the O-V4 literal-grep gate (X-CC-1) persist across cycles.
- **ADR check**: ADR-004 governs the underlying skill defect (not carved out). The *process* finding is novel to the cross-cutting lens and not addressed by any ADR.
- **Classification**: **Moderate** — this is the systemic vector behind three separate multi-cycle carry-forwards. It is the cross-cutting root cause that, unaddressed, will reproduce the carry-forward pattern after this audit too. Tiered Moderate (not Minor) because it converts otherwise-trivial fixes into permanent backlog. The concrete remediation is IO-CC-V2 (audit-finding → follow-up-task disposition ledger).

---

## Improvement Opportunities

Organized by the five standard synthesis categories. The Focus-2 mechanisms (M1–M5 in that section) are additional and not duplicated here; where a standard item overlaps a Focus-2 mechanism it is cross-referenced.

### Category 1 — Token Efficiency

**IO-CC-T1 — Close the ADR-008 cumulative-drift gap (manager at 54.7% session / 136.7% per-component).**
The manager grew +500 words from the ICON-0033 baseline (4,148 → 4,648) — 5.9% of the session cap — yet no single MR tripped the ADR-008 per-MR 5% (425-word) trigger. The per-MR design lets cumulative drift accumulate undetected, which is exactly what it was meant to prevent on a cumulative basis. Recommend amending ADR-008 (`.context/decisions/008-always-loaded-token-budget.md`) to add: "A re-inventory is triggered whenever any audit cycle measures cumulative growth-from-baseline ≥5% of cap, independent of the per-MR gate." Pairs with a principled content review of `manager.agent.md` for extract-to-on-demand candidates (the Task Completion section is the natural cut — it only fires at task close). **Effort: trivial (ADR amendment) → low (content review). Impact: high — prevents a session-cap breach at the next substantive manager change.** (Domain 01 IO-A-0058-4.)

**IO-CC-T2 — Quantify the `task-plan-phase-completion` "Keep this skill minimal" claim.**
At 832 words it is the largest of the five phase skills while instructing "keep this minimal" with no measurable ceiling (`skills/task-plan-phase-completion/SKILL.md:12-13`). Add `<!-- target ≤ 850 words -->` or rephrase to "each new step must justify its token cost." A skill that claims minimalism while leading its peer group erodes trust in every size claim in the ecosystem. **Effort: trivial. Impact: low.** (Domain 02 m-P-0058-3 / IO-P-0058-3.)

### Category 2 — Discoverability

**IO-CC-D1 — Register `characterization-testing` and `mcp-tools-first` in the README Internal Skills table (closes X-CC-3 surface).**
Both are `user-invocable: false`, wired into routing, absent from `README.md:184-213`. Add both rows. This is the second half of the discoverability fix the ICON-0048 frontmatter change began. **Effort: trivial. Impact: medium.** (Domains 04 IO-U-2, 07 IO-07-D1.)

**IO-CC-D2 — Replace live DataScan Confluence URLs in `sprint-goals` and `rfc` body prose with placeholders.**
`sprint-goals/SKILL.md:20,:196` and `rfc/SKILL.md:19` embed `onedatascan.atlassian.net` URLs that 404 for every non-DataScan consumer. ADR-010 m9 covers example *shapes*, not reference URLs in mandatory-reference prose. **Effort: trivial. Impact: low-medium.** (Domain 04 IO-U-3.) **Note:** per the standing project decision that the ICON repo IS DataScan's production plugin, confirm with the user whether these specific URLs are intentional production state before treating as a defect — the *mechanism* (placeholder for forks) is the portable recommendation regardless.

### Category 3 — Consolidation

**IO-CC-C1 — Resolve the triple-verification (closes X-CC-2).**
Remove `verification-checklist` from `task-retrospective` Steps 6–7 with a one-line standalone-invocation note, and collapse manager Step 2 into the close-gate's item 4 — leaving the close-gate as the single authoritative gate. A future task must own *both* removals atomically (the partial-fix history of this exact finding is the cautionary tale). **Effort: trivial. Impact: low-medium.** (Domains 01 IO-A-0058-1, 02 IO-P-0058-2.)

**IO-CC-C2 — Replace the phantom "plugin-lint Check A/B" labels with real rule citations.**
Three sites (`skills/icon-init/SKILL.md:225,:245`; `skills/icon-status/SKILL.md:214`) cite a numbered catalog that exists nowhere on disk. Replace with `common-constraints.md § Shell command self-check` citations. Two-cycle carry-forward. **Effort: trivial. Impact: low.** (Domains 03 IO-58-01, 04 IO-U-6.)

### Category 4 — Missing Skills / Workflow Gaps

**IO-CC-M1 — Implement the ICON-0015 O-V4 literal-grep pre-commit gate (closes X-CC-1's root cause).**
A two-phase `.githooks/pre-commit` block — (i) grep staged `skills/`/`agents/` files for unresolved `<…>` placeholders; (ii) grep for cap/version literals that disagree with the `ENTRY_CAP=N` constants in `scripts/` — mechanically encodes the sweep discipline. Pattern A (sweep-incompleteness) has fired in 6+ cycles; this gate is the single highest-recurrence-closing mechanism in the codebase. **Effort: low. Impact: high.** (Domains 03 pattern-observation, 07 IO-07-V1 adjacency.)

**IO-CC-M2 — Canonicalize the `context_template/phase-completion.md` Retrospective Template (closes Domain 02 Moderate M-P-0058-1).**
The shipped template uses `## Retrospective — [TASK-ID]` (double-hash) which `append-retrospective-entry.sh:115-118` rejects (requires `### `). Every consumer following the template silently fails entry insertion and loses the rolling-log cap. Replace with the canonical `### [TASK-ID]: …` / `**Avoid**`/`**Repeat**`/`**Updated**` form; bump template-version comment. **Effort: trivial. Impact: high (consumer-correctness).** (Domain 02 IO-P-0058-1.)

### Category 5 — Self-Verification / Automate the Retrospective Wisdom

**IO-CC-V1 — Add a skill-registration invariant to `.githooks/pre-commit` + a `CONTRIBUTING.md` intake checklist (closes X-CC-3 class).**
For each `skills/<name>/SKILL.md`, assert `<name>` appears in `README.md` (Skills or Internal Skills table). Pair with a 3-item "new-skill integration checklist" in `CONTRIBUTING.md` (README row / `using-skills` routing / consuming-agent workflow). This mechanically closes the recurring registration gap that has now fired on `mcp-tools-first` and `characterization-testing`. **Effort: low. Impact: high.** (Domain 07 IO-07-V1 / IO-07-M1.)

**IO-CC-V2 — Establish an audit-finding → follow-up-task disposition ledger (closes X-CC-M1).**
The informal audit-report → suggested-task handoff is the mechanism behind three multi-cycle carry-forwards. Add a lightweight ledger (a section in the audit report, or `.context/decisions/`-adjacent table) recording, per finding: tier, recommended task, **accepted / deferred / rejected + reason**. A finding that is silently re-scoped away (ecological-impact across ICON-0047) becomes visible as a *deferred* item the next audit checks, rather than re-deriving it from scratch each cycle. This generalizes ADR-010's carry-forward registry from "accepted watch items" to "all unclosed findings." **Effort: low. Impact: high — converts the carry-forward leak into a tracked backlog.**

**IO-CC-V3 — Add a `### Changed`-deduplication guard to `release-plugin` Step 5.**
`CHANGELOG.md:25,29` carries a duplicate `### Changed` heading in `[1.19.0]` (parallel-branch merge artifact). The ICON-0056 `[Unreleased]`-absorption guard does not cover within-block subsection duplication. **Effort: trivial. Impact: medium.** (Domain 05 IO-I-C.)

---

## Token Economics Analysis

**Always-loaded surface (every manager session):**

| Component | Words | Notes |
|---|---|---|
| `agents/manager.agent.md` (full body, injected verbatim by the SessionStart hook) | **4,648** | 54.7% of the 8,500-word ADR-008 manager session cap; **136.7% of the 40% per-component cap (3,400 words)**. +500 from ICON-0033 baseline. |
| `shared/common-constraints.md` (embedded byte-equal inside the manager body via sync) | 421 | Counted within the 4,648 (it is a spliced block, not a separate load). The ICON-0057 Context Economy rule lives here. |
| SessionStart hook prefix (`inject-manager-role.mjs:76-77`) | ~70 | Discipline-lead injected ahead of the body. |

**Always-loaded surface (every PM session):** `agents/product-manager.agent.md` = **2,735 words** — 39.1% of the 7,000-word PM session cap; under the 40% per-component cap. Healthy headroom.

**On-demand (loaded only when invoked):** all 51 `skills/` + 3 maintainer `.claude/skills/`, the `manager-routing-guide` (correctly deferred — loaded only at routing decisions), all phase-`*.md` workflow files, `task-retrospective`, `verification-checklist`. This deferral discipline is sound and is the main reason the session cap is not threatened despite 51 skills.

**Highest-impact trim candidates (ranked):**
1. **Manager Task Completion section → on-demand companion.** It fires only at task close yet loads on *every* turn of *every* session. Extracting it to a `task-close-protocol` doc loaded at retro time is the single largest principled cut available (the close-gate + retro + reconcile prose is ~250 words). Caveat: the close-gate's value is partly *being unavoidable*, so any extraction must keep the Hardcoded one-liner inline and move only the elaboration. (Ties to IO-CC-T1.)
2. **The ADR-008 trigger amendment itself** — not a trim, but the governance change that stops the bleed. Highest leverage per word of effort.
3. **`task-plan-phase-completion` (832 words, on-demand)** — not always-loaded, but it loads at the end of *every* task; the IO-CC-T2 ceiling caps its growth.

**Headline token-economics finding:** the manager is comfortable against the *session* cap (3,852 words headroom) but **structurally over the 40% per-component cap and accreting ~5%/baseline-interval undetected** because ADR-008's gate is per-MR, not cumulative. This is the worsening of ICON-0046's O-T1, and the per-MR-vs-cumulative blind spot is the net-new framing.

---

## Discoverability UX Analysis

*(User-facing skill discoverability. Agent-facing rule discoverability is the separate Focus-2 section below.)*

**README skills table (`README.md:152-213`):** Two-tier split (user-invocable `### Skills` vs `#### Internal Skills`) is the right structure and is mostly well-maintained. **Gap:** the Internal Skills table is the persistently-late surface — `characterization-testing` and `mcp-tools-first` are both absent (X-CC-3 / IO-CC-D1). Every *other* internal skill is present, which is what makes the omission a discoverability defect rather than a stylistic choice.

**`using-skills` common-workflows / routing table:** Healthy. `characterization-testing` is correctly wired into the priority list, a routing example, and the Rigid list (`skills/using-skills/SKILL.md:71,77,84`) — Domain 07 confirms bidirectional wiring with `tester.agent.md`. The README lag is *downstream* of correct `using-skills` wiring, reinforcing that the README-table step is the one consistently omitted.

**Onboarding flow (README → install → `/icon-init` → workflow):** Coherent. One gap surfaced by Domain 05 (IO-I-D): `README.md` has **no pre-commit hook installation instruction** (`git config core.hooksPath .githooks`), which lives only in `CONTRIBUTING.md:50-52`. A contributor cloning without reading CONTRIBUTING silently bypasses all four invariant gates — including the common-constraints sync and the (proposed) literal-grep and skill-registration gates. This makes the hook-install gap a *force-multiplier* on every self-verification mechanism this audit recommends.

**Missing skill-workflow chains in `using-skills`:** none net-new this cycle; the tester→characterization-testing→testing-discipline chain is the one addition and it is clean.

---

## Retrospective Pattern Analysis

`.context/retrospectives.md` is a 10-entry rolling log (cap=10, ICON-0043 through ICON-0057). Within this window plus the cross-cycle audit record, three failure classes meet the 3+-appearance threshold:

**Pattern 1 — "Manager bypasses the skill that governs the artifact it's about to produce" (3 instances; promote-candidate already named).**
- ICON-0047 (`retrospectives.md:32`): manager edited `writing-skills` without invoking `using-skills`/RED-phase — "the discipline applies to the skill you're editing."
- ICON-0054 (`:12`): manager tried to write a free-form `retrospective.md`, bypassing `task-retrospective` — user rejected. The retro itself calls this the *second occurrence* of the axis and a "promote-candidate if a third instance appears."
- ICON-0051 (`:17`): started implementation on a branch before creating the task folder / `plan.md` / CHANGELOG entry — the same "skip the governing artifact discipline" shape on the workflow-artifact axis.
- **Evaluation:** This has reached the promotion threshold the ICON-0054 retro itself set. It warrants either a **Hardcoded manager rule** ("before producing any named workflow artifact — plan, retro, changelog, MR — invoke the skill that owns its format BEFORE the first write") or an Anti-Rationalization row. This is *also* the strongest evidence for Focus-2 mechanism M3 (pre-write rule lookup), because the failure is precisely "the governing rule existed but wasn't reached at write time."

**Pattern 2 — Sweep-incompleteness / partial-fix-of-the-literal (4+ instances across cycles).**
- ICON-0048 (`:27`): "the audit cites one line, but the contradiction frequently propagates" — caught two propagations of m-A-NET-NEW-3.
- ICON-0044, ICON-0040, ICON-0043 (`:47,:52`): "exhaustively enumerate the filter's branches"; porting-introduces-bugs; ICON-internal logic carried into generic skills — all variants of "fixed the named thing, missed the structural siblings."
- This cycle: five `keep-last-10` literal misses (X-CC-1).
- **Evaluation:** Warrants the **O-V4 literal-grep hook gate (IO-CC-M1)** — a *mechanical* gate, since four cycles of retro-wisdom have not prevented recurrence. This is the textbook "retrospective wisdom that should be automated."

**Pattern 3 — New-skill registration / integration gap (3 instances).**
- ICON-0046 (`mcp-tools-first`), ICON-0049 (`characterization-testing` — both the `tester.agent.md` wiring gap *and* the uncaught README gap, `:22`), and the standing class Domain 07 traces.
- **Evaluation:** Warrants the **skill-registration pre-commit invariant + CONTRIBUTING intake checklist (IO-CC-V1)**. Three instances, two of them on outside-contributor surfaces, is a clear automation trigger.

All three patterns share one meta-shape: **a rule or discipline that already exists in the corpus is not reached at the moment it applies.** That is the same root cause Focus-2 isolates — which is why the highest-leverage interventions (M1 rule index, IO-CC-M1 literal gate, IO-CC-V1 registration gate) are all *mechanical reach-at-the-moment-of-need* fixes rather than more prose.

---

## Rule/Workflow Discoverability Gap (Focus 2)

> **User's core question:** relevant information in `.context/` is not discovered by the manager or sub-agents at the moment of need — and the miss is worse for *rule/workflow* knowledge than for *codebase* knowledge.

### 1. Root-Cause Analysis

The asymmetry is real and structural. Tracing the actual mechanics:

**(a) `domains/` is privileged in the discovery path; `standards/`/`workflows/`/`decisions/` are not.**
- The manager's **research-need gate** (Session Start Step 7, `manager.agent.md:59`) keys *only* on `.context/domains/`: "The task touches an area of the codebase not covered in `.context/domains/`." There is no parallel gate asking "does this task touch a rule/workflow not yet surfaced from `standards/`/`workflows/`/`decisions/`?"
- The **warmstart Domain section** (`manager.agent.md:147`) reads "Relevant excerpts from `.context/domains/` files" — `domains/` is a named, required field. Rules get only the thin **Project section** line "Conventions: [relevant items from `.context/standards/`]" (`:138`) — `standards/` only, and *no `workflows/` or `decisions/` field at all*.
- The manager's **Anti-Rationalization table** (`manager.agent.md:260`) reinforces `.context/domains/` by name as the alternative to source investigation. No AR row reinforces consulting `standards`/`workflows`/`decisions`.
- **`decisions/` appears in zero agent files.** A repo-wide grep of `agents/` for `decisions/` returns nothing. ADRs are surfaced *only* if an agent happens to read the flat subdirectory list at `manager.agent.md:93` and then *chooses* to open `decisions/`. Codebase facts live in `domains/` (privileged); rules live in `standards/`/`workflows/`/`decisions/` (ad hoc). **That is the asymmetry the user observed, and it is encoded directly in the manager's discovery structure.**

**(b) Discovery of rule dirs is "read relevant files," never "enumerate."**
The only place all three rule dirs appear together is the flat list at `manager.agent.md:93`: "Read relevant files from `.context/` subdirectories: `domains/` …, `standards/` …, `workflows/` …" — note "Read *relevant* files," which delegates the selection judgment to the agent with no enumeration step. There is no instruction to *list* `standards/`/`workflows/`/`decisions/` and decide applicability per file. Compare: `domains/` gets an explicit coverage *test* (Step 7) that forces the manager to reason about whether coverage exists; rules get no such forcing function.

**(c) The warmstart hands sub-agents only what the manager pre-selected — and the template omits rule fields.**
Sub-agents operate in isolated context windows and **only receive what the warmstart prompt contains** (`manager.agent.md:130-156`). The template has a `### Domain` block (domains excerpts) but **no `### Applicable Rules` block**. So even when the manager *has* read a relevant ADR or standard, there is no template field obligating it to pass that rule down. Sub-agent rule-misses are therefore *downstream* of (and worse than) manager misses: the sub-agent can't rediscover an ADR it was never handed, because most sub-agents don't re-scan `.context/` (and several have their own narrow read-lists — `coder.agent.md:31` reads `standards/` but not `decisions/`; `reviewer.agent.md:17` reads `standards/`+`testing/` but not `decisions/`; `architect.agent.md:22` reads `architecture/`+`standards/`+`domains/` but not `decisions/`). The result: a rule encoded in a consumer's `.context/decisions/` is effectively invisible to every sub-agent unless the manager manually copies it into free-form prose.

**(d) There is no auto-loaded index/manifest of `.context/` rules.**
The SessionStart hook (`hooks/inject-manager-role.mjs:79-87`) injects the *entire `manager.agent.md`* and nothing else — no rule index, no ADR table, no standards list. The ICON repo's own `.context/decisions/README.md:28-41` *has* a clean Decision Log index table — but (i) nothing auto-loads it, and (ii) there is no instruction telling agents that a consumer repo's `.context/decisions/README.md` (or `standards/`/`workflows/`) should be enumerated at session start. So each agent must *rediscover* the rule surface from the flat subdirectory list every time. The index exists; the wiring to reach it does not.

**Net root cause:** codebase facts are discovered because `domains/` is woven into the *forcing functions* (gate + warmstart field + AR row); rules are under-discovered because `standards/`/`workflows/`/`decisions/` live only in a passive, judgment-delegated subdirectory enumeration with no gate, no required warmstart field, and no index. The Wave-1 evidence confirms the cost: ADR carve-outs (ADR-007/009/010) have to be **re-stated verbatim in every audit brief** precisely because nothing surfaces them automatically; agents repeatedly miss the keep-last-10 rule (five sites this cycle) because the rule lives in script constants + prose with no index binding them; and the "manager bypasses the governing skill" retro pattern (3×) is the same "the rule existed but wasn't reached at write time" shape.

### 2. Concrete, Portable Mechanism Proposals

All proposals are portable across Claude Code and Copilot CLI (markdown + agent-prompt + git-hook mechanisms only; no tool-proprietary APIs). Each is grounded in a current-state file:line gap.

**M1 — `.context/rules-index.md` auto-enumerated at Context Discovery (highest leverage).**
- **Mechanism:** Ship a convention (and a `context-specialist`/`upgrade-repo` step that generates it) for a `.context/rules-index.md` — a single table listing every file under `standards/`, `workflows/`, and `decisions/` with a one-line "applies when…" trigger per row (mirroring the ADR Decision Log table that *already exists* at `.context/decisions/README.md:28-41`, generalized across all three rule dirs). Add a Context Discovery sub-step instructing the manager to **read `.context/rules-index.md` in full at session start** (it is small and bounded — an index, not the rule bodies) and open only the rows whose trigger matches the task.
- **Where it lives:** new file `context_template/context/rules-index.md` (template) + generation step in `context-specialist-impl-*`/`upgrade-repo` + a one-line read instruction at `manager.agent.md:93`.
- **Effort:** medium (template + generator + manager wiring). **Impact:** high.
- **Failure-mode closed:** rules-under-discovered-because-no-index. This is the **single highest-leverage** mechanism: it converts the passive "read relevant files" into an enumerated, trigger-matched lookup, exactly as `domains/` already gets a forcing function — without loading rule *bodies* into the always-loaded surface (preserving ADR-008 budgets).

**M2 — A rule-coverage gate in the manager's research-need check (parity with the `domains/` gate).**
- **Mechanism:** Add a third gate to Session Start Step 7 (alongside Codebase-exploration and External-research): **"Rule/workflow surfacing — before delegating, enumerate `.context/decisions/`, `.context/standards/`, and `.context/workflows/` (via `rules-index.md` if present) and identify any rule whose trigger matches this task type."** This gives rules the same *forcing function* `domains/` has at `manager.agent.md:59`.
- **Where it lives:** `agents/manager.agent.md:56-71` (Step 7).
- **Effort:** low (prose addition). **Impact:** high.
- **Failure-mode closed:** the asymmetric absence of a rule-coverage test — the structural root cause from §1(a).

**M3 — A required `### Applicable Rules` warmstart field (closes the sub-agent-miss gap).**
- **Mechanism:** Add an `### Applicable Rules` block to the Delegation warmstart template, REQUIRING the manager to pass the specific ADRs/standards/workflows that bear on this delegation (e.g., "ADR-004 tool-agnostic content applies — no runtime-specific literals"). Make it parallel to the existing `### Domain` block so it is structurally unskippable.
- **Where it lives:** `agents/manager.agent.md:133-156` (warmstart template), expanding `:138`'s thin "Conventions" line into a first-class block.
- **Effort:** low. **Impact:** high.
- **Failure-mode closed:** sub-agents only get what the warmstart hands them (§1c). This is the mechanism that fixes *sub-agent-level* misses specifically, since they cannot rediscover an unpassed rule.

**M4 — Pre-write "governing-rule lookup" Hardcoded rule (closes the retro Pattern-1 class).**
- **Mechanism:** Add a Hardcoded manager rule: "Before producing or editing any named `.context/` artifact or governed file (plan, retrospective, changelog, MR, skill), consult `.context/rules-index.md` (or `decisions/`/`standards/`/`workflows/` directly) for the rule that governs that artifact's format BEFORE the first write." Generalize the audit's *existing* discipline — the audit already mandates reading `.context/decisions/` before tiering — to all governed writes.
- **Where it lives:** `agents/manager.agent.md` Hardcoded tier (near `:221-233`) + optional AR row.
- **Effort:** trivial. **Impact:** medium-high.
- **Failure-mode closed:** the 3× "manager bypasses the governing skill/rule at write time" retro pattern (ICON-0047/0051/0054). This is the *behavioral* complement to M1's *structural* index.

**M5 — A using-skills-style routing table for `.context/` rules (portable, no new file if M1 declined).**
- **Mechanism:** Add a "Rule routing" subsection to `using-skills` (or `manager-routing-guide`) that maps task *types* to the rule dirs to consult — e.g., "task edits a skill → `writing-skills` + `standards/skill-decomposition.md`"; "task touches CHANGELOG → `standards/changelog-discipline.md`"; "task adds shell → `standards/shell-portability.md` + ADR-007." This piggybacks on the routing surface agents *already* consult, so it inherits an existing forcing function.
- **Where it lives:** `skills/using-skills/SKILL.md` or `skills/manager-routing-guide/SKILL.md`.
- **Effort:** low. **Impact:** medium.
- **Failure-mode closed:** rules-not-reached-because-no-routing — and it requires no new always-loaded surface, since `using-skills` is already MANDATORY-before-task.

### 3. Connection to Wave-1 Evidence

- **ADR carve-outs re-stated in every brief:** ADR-007/009/010 are spelled out verbatim in the dispatch brief (`06-cross-cutting.md` ADR pointer) *because nothing surfaces them automatically at tiering time*. M1+M2 would let any audit agent reach `.context/decisions/README.md:28-41` (which already indexes them) by enumeration rather than by the brief author hand-copying each carve-out. The audit's own "read `.context/decisions/` before tiering" instruction is M4 applied to one workflow — **generalizing it is the recommendation.**
- **keep-last-10 missed in 5 sites (X-CC-1, Domains 03/05):** the rule that the cap is 10 lives in `ENTRY_CAP=10` script constants + scattered prose with no index binding them. M1's `rules-index.md` (or IO-CC-M1's literal-grep gate) is the reach-at-the-moment-of-need fix; the two are complementary (index for humans/agents, hook for mechanical enforcement).
- **"manager bypasses the governing skill" (3× retro, Pattern 1):** M4 directly targets this — every instance was "the governing rule existed but the manager didn't reach it before the first write."
- **README-registration recurrence (X-CC-3):** the *user-facing* analog of the same class — a required step (registration) that isn't reached because no forcing function binds it. IO-CC-V1's hook gate is the registration-surface equivalent of M2's rule-surface gate.

**Single highest-leverage mechanism: M1** (`.context/rules-index.md` auto-enumerated at Context Discovery). It is portable, preserves ADR-008 token budgets (index not bodies), reuses an index structure that already exists for ADRs, and is the structural fix that makes M2/M3/M4 cheap to add on top. It directly inverts the root-cause asymmetry: it gives `standards/`/`workflows/`/`decisions/` the same enumerated-forcing-function status that `domains/` already enjoys.

---

## ICON-0046 Delta

### Fixed since ICON-0046

| ICON-0046 ID | Description | Evidence (by domain) |
|---|---|---|
| m-A-NET-NEW-1/2/3 | context-specialist description / Discretionary heading / audit-write parenthetical | Confirmed fixed by ICON-0048 (Domains 01, 03) |
| m-P-NEW-1/2 | `keep-last-15` prose in two named files | Confirmed fixed by ICON-0048 (Domain 02) |
| m-U-net2 | `mcp-tools-first` missing `user-invocable` key | Confirmed fixed by ICON-0048 (Domain 04) |
| m-new-01 | `impl-root` Step 15 `patterns-template.md` → `patterns.md` | Confirmed fixed by ICON-0048 (Domain 03) |
| m-infra-2 / IO-I2 | pre-commit hook header invariant ordering | Confirmed fixed (Domain 05) |

Cross-cutting note: the ICON-0048 sweep closed ~7 of ICON-0046's named Minors — a high close rate — but the *unnamed structural siblings* of those literals (X-CC-1) were left, reproducing the very sweep-incompleteness pattern ICON-0046's cross-cutting section flagged.

### Still present or partial

| ICON-0046 ID | Status |
|---|---|
| **O-T1 (ADR-008 per-component overage)** | **Worsening.** Manager 50.8%→54.7% of session cap; per-component 136.7%; +500 cumulative undetected by the per-MR gate. See IO-CC-T1. |
| **O-S1 / m-P-NEW-3 (double-verification)** | **Worsened to triple.** ICON-0057 added a third invocation. See X-CC-2 / IO-CC-C1. |
| **M-U-NET1 (ecological-impact ADR-004)** | **Third-cycle carry-forward, zero structural change.** The single ICON-0046 Moderate. See X-CC-M1. |
| **O-S2 / m-new-03 (plugin-lint Check A/B)** | Still present, now 3 sites. See IO-CC-C2. |
| **O-M1 / O-V4 (literal-grep hook gate)** | Still unimplemented; this cycle produced 5 new literal-miss instances. See IO-CC-M1. |
| **O-T2 (phase-completion "minimal" bound)** | Still unbounded at 832 words. See IO-CC-T2. |
| **IO-A-4 (PM Turn Start) / IO-A-7 (web_search platform note) / IO-02 (impl-branch verify) / IO-03 (multimodule root-context)** | Still present per Domains 01/03. |

### Net-new drift classes

1. **Within-block CHANGELOG subsection duplication** (`CHANGELOG.md:25,29` duplicate `### Changed`) — a *new* failure mode distinct from the `[Unreleased]`-absorption bug the ICON-0056 guard covers; arises from parallel feature branches each appending their own subsection. (Domains 05/07.) See IO-CC-V3.
2. **Consumer-template retrospective-format incompatibility** (`context_template/phase-completion.md` `##` vs append-script `### `) — first observable this cycle because no prior audit checked the template format against the script's validation logic. A consumer-population correctness defect, not an ICON-internal hygiene one. (Domain 02 M-P-0058-1.) See IO-CC-M2.
3. **Agent-body skill-routing conditionals** (`tester.agent.md:19` Step 2 now contains routing logic that previously lived only in `using-skills`) — net-new *pattern* (Domain 01 Observation 5); benign today, but if extended it risks agent-body routing drift duplicating/contradicting the `using-skills` catalog. Watch-only.
4. **Close-gate lint-evidence requirement with no production step** (`manager.agent.md:210` item 2 demands lint output that no Task Completion step assigns) — net-new structural gap introduced by ICON-0057. (Domain 01 m-A-0058-2.)

### Audit-process observation

This cycle confirms the ICON-0046 audit-process warning verbatim: the high ICON-0048 close-rate closed *literals* while leaving *structural causes*, reproducing both named recurring patterns. The cross-cutting prescription is unchanged and now reinforced by a third data point — **the codebase needs mechanical reach-at-the-moment-of-need infrastructure (literal-grep gate IO-CC-M1, skill-registration gate IO-CC-V1, rule-index M1) more than it needs more prose.** Three of the five Category-5 self-verification opportunities and the entire Focus-2 section converge on this single conclusion: ICON's retrospective wisdom is sound but under-automated, and the rule-discoverability asymmetry is the structural reason that wisdom doesn't reach agents at the moment it applies.
