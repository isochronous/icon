# ICON Plugin Audit Report — ICON-0058

**Task:** ICON-0058  
**Date:** 2026-06-10  
**Plugin version audited:** `v1.19.0` + `[Unreleased]` (ICON-0056 retrospective→Hardcoded; ICON-0057 itemized close-gate + Context Economy rule), on branch `feature/ICON-0058-icon-audit` off `main`.  
**Scope:** 9 agents, 51 skills under `skills/` + 3 maintainer-only skills under `.claude/skills/`, 1 plugin manifest (`.claude-plugin/plugin.json`), 1 MCP registry (`.mcp.json`), SessionStart hook + `inject-manager-role.mjs`, `.githooks/pre-commit` (3 invariant classes), `CONTRIBUTING.md`, 11 ADRs.  
**Method:** 5 standard domain agents (01–05) + 1 custom third-party-integration agent (07) in parallel → cross-cutting synthesis agent (06, consuming 01–05 + 07) → this synthesis. Baseline for delta: **ICON-0046** (2026-05-27, v1.17.2, verdict STRONG).  
**User directives (this cycle):** **Focus 1** — verify recently-merged third-party contributions are up to standard and well integrated (custom brief 07; § Focus 1 below). **Focus 2** — diagnose why `.context/` rule/workflow knowledge is not discovered by the manager and sub-agents, and propose fixes (§ Focus 2 below).  
**Raw findings:** `./research/01-agents.md` … `06-cross-cutting.md`, `07-third-party-integration.md`.

> Out of scope per user direction: the unmerged contribution branches `origin/dw/copilot-containers` and `origin/dw/devops-addition` were not read or evaluated.

---

## Executive Summary

**Overall health: STRONG (holding).** The plugin remains in strong condition and moved net-positive since ICON-0046. The ICON-0048 sweep closed ~7 of the prior cycle's named Minors; the two flagship hardening moves of this interval — `task-retrospective` → Hardcoded (ICON-0056) and the itemized non-skippable close-gate (ICON-0057) — are the strongest process changes in two cycles and are mechanically sound. Frontmatter, scope-termination, and common-constraints-sync invariants are clean across all 9 agents. No Critical findings. The third-party contribution set (Focus 1) is in **good integration health** — every merged contribution is structurally conformant, with one recurring-class registration gap and two intra-skill doc contradictions.

The cycle surfaces **3 Moderate and ~17 Minor** findings. The dominant story is one the prior audit already named and this cycle confirms: **a rule or discipline that already exists in the corpus is not reached at the moment it applies.** That single meta-shape unifies almost every finding — the recurring sweep-incompleteness (the 15→10 literal missed in 4+ more sites), the README-registration gap recurring on a second skill, the verification-gate that grew from double to triple, the audit-Moderate that has survived three cycles untouched, and — most directly — the Focus-2 rule-discoverability asymmetry. The prescription is consistent across the whole report: **ICON needs mechanical reach-at-the-moment-of-need infrastructure (a rule index, a literal-grep gate, a skill-registration gate) more than it needs more prose.**

The remaining issues cluster into four themes:

1. **Rule/workflow discoverability asymmetry (Focus 2).** `.context/domains/` is woven into the manager's forcing functions (research-need gate, warmstart field, anti-rationalization row); `standards/`/`workflows/`/`decisions/` live only in a passive "read relevant files" list with no gate, no required warmstart field, and no index — and `decisions/` appears in **zero** agent files. This is the structural reason rule knowledge under-reaches agents while codebase knowledge reaches them.
2. **Partial-fix / sweep-incompleteness recurrence.** The 15→10 cap literal, fixed in two named files by ICON-0048, persists in 4+ sibling sites including the consumer-shipped template. The ICON-0015 O-V4 literal-grep gate that would catch this mechanically remains unimplemented across 3+ cycles.
3. **Audit-recommendation-to-task-scope drift (a process Moderate).** The informal audit-report → follow-up-task handoff lets named Moderates silently fall out of scope. The `ecological-impact` ADR-004 Moderate is now a **third-cycle carry-forward with zero structural change** because its assigned follow-up (ICON-0047) was re-scoped to a different skill.
4. **Token drift under a per-MR-only gate.** The manager grew +500 words from the ICON-0033 baseline (now 54.7% of the session cap but **136.7% of the 40% per-component cap**) without any single MR tripping ADR-008's per-MR trigger — a cumulative-drift blind spot.

### Scorecard

| Rule | Verdict | Movement vs ICON-0046 |
|------|---------|------------------------|
| RULE 1 — PROMPT vs SKILL SEPARATION | ✅ PASS | Held. Connor's Jira-ID guard correctly placed in the manager prompt; watch the net-new agent-body routing conditional in `tester.agent.md:19` (Domain 01 Obs 5). |
| RULE 2 — SINGLE SOURCE OF TRUTH | ⚠️ WARNING | Slipped. Verification-checklist double→triple; README-registration lag on a 2nd skill; 15→10 literal un-swept in 4+ sites. The underlying cause is the Focus-2 rule-discoverability asymmetry. |
| RULE 3 — SUB-AGENT JOB CLARITY | ✅ PASS | Held. Scope-termination language uniform across all 7 sub-agents. |
| RULE 4 — SKILL RESPONSIBILITY | ⚠️ WARNING | Held/partial. `ecological-impact` ADR-004 coupling (3rd cycle); `writing-skills` over its own line cap (524); `phase-completion` "keep minimal" at 832 words. |
| RULE 5 — ORCHESTRATOR CLARITY | ✅ PASS (note) | Improved on process backbone (close-gate), but close-gate lint-evidence has no assigned owner and manager token drift is ungated cumulatively. |

### Top-line counts

- **Defects**: **0 Critical**, **3 Moderate**, **~17 Minor** (deduplicated; several Minors are one fix-class spanning multiple files).
- **Improvement Opportunities**: **~30** across the 5 standard categories, including **5 Focus-2 discoverability mechanisms** and **2 third-party-intake mechanisms**.
- **ICON-0046 delta**: ~7 fixed (ICON-0048 sweep); ~9 still-present-or-partial (3 worsened); 4 net-new drift classes.

---

## Critical Findings (0)

None observed. No domain agent reported a Critical; the synthesis surfaces none.

---

## Moderate Findings (3)

*Full rationale and file:line references in the research files. This is a consolidated inventory for triage.*

### Consumer-correctness (1)

| # | Finding | Location |
|---|---------|----------|
| **M1** | `context_template/phase-completion.md` ships a Retrospective Template in `## Retrospective — [TASK-ID]` (double-hash) form, but `append-retrospective-entry.sh` validates entries must begin with `### ` (triple-hash). Every consumer repo following the shipped template gets exit-code-1 from the script — entries silently fail to insert and the rolling-log cap goes unenforced. The ICON repo's own `.context/workflows/task-plan/phase-completion.md:68–79` has the same mismatch. | `context_template/context/workflows/task-plan/phase-completion.md:53–62`; `skills/context-maintenance/scripts/append-retrospective-entry.sh:115–118,126` (Domain 02 M-P-0058-1) |

### Tool-agnosticism (1)

| # | Finding | Location |
|---|---------|----------|
| **M2** | `ecological-impact` Option-A calculation path is inoperable for Claude Code consumers — "Remaining Reqs" status-bar UI, the GitHub Copilot billing quota table, and the "Copilot Ecological Impact Report" output header are all GitHub-Copilot-specific (ADR-004 violation). The calculation core (Steps 2–6) is generic; only Step-1 Option A is broken. **Third consecutive audit cycle with zero structural change** — its assigned follow-up (ICON-0047) was re-scoped. | `skills/ecological-impact/SKILL.md:4,12,17,21,43–74,149,208` (Domain 04 M-U-1) |

### Process / systemic (1)

| # | Finding | Location |
|---|---------|----------|
| **M3** | **Audit-recommendation-to-task-scope drift.** The audit-report → suggested-follow-up-task handoff is informal: a Moderate labeled with a suggested task ID does not become that task's scope unless the user explicitly accepts it, and planning-time scope decisions silently override the recommendation. This single mechanism is the cause behind three multi-cycle carry-forwards (M2 ecological-impact, the verification-triple, the O-V4 literal gate). Tiered Moderate because it converts otherwise-trivial fixes into permanent backlog. | systemic; evidenced at `.context/tasks/ICON-0046-icon-audit/audit-report.md` recommendations vs ICON-0047/0049 retros (Domain 06 X-CC-M1) |

> **Tiering note:** Domain 07 argued the `characterization-testing` README-registration gap (M-07-1) as a 4th Moderate on recurrence-of-class grounds. Domains 04 and 06 tiered it Minor per-instance with the *unmitigated class* as the real finding. This report adopts Minor-per-instance (m13 below) and routes the class fix to Tier 2 (IO-V1/IO-M2).

---

## Minor Findings (~17)

Condensed; details and full file:line in the research files.

**Verification / close-gate (Domains 01, 02):**
- **m1 — Triple `verification-checklist` invocation.** ICON-0046 flagged a *double* invocation (manager Step 2 + retro Steps 6–7); the fix was never executed and ICON-0057's close-gate added a *third* with no note explaining intent. Redundancy is safe (close-gate is authoritative) but erodes confidence the docs are maintained holistically. `agents/manager.agent.md:203,210,233`; `skills/task-retrospective/SKILL.md:127–130`.
- **m2 — Close-gate lint-evidence requirement has no assigned owner.** The Hardcoded close-gate demands "project lint ran and output shown," but no Task Completion step assigns lint execution: the coder runs *build*, the reviewer defers to linters, and the manager is barred from shell commands. Can stall doc-only/context-only closes. `agents/manager.agent.md:210,233`.

**Process-skill footers (Domain 02):**
- **m3 — `Does NOT cover` footer gaps:** investigation omits "completion"; architecture omits "retrospective". `skills/task-plan-phase-investigation/SKILL.md:123`; `skills/task-plan-phase-architecture/SKILL.md:73`. (Carry-forward IO-P-2.)
- **m4 — `phase-completion` "Keep this skill minimal" has no measurable bound** — it is the *largest* phase skill at 832 words. `skills/task-plan-phase-completion/SKILL.md:12–13`. (Carry-forward IO-P-3.)

**Sweep-incompleteness — 15→10 cap literal (Domains 03, 05; one fix-class, 4+ sites):**
- **m5 — Stale "the 15th" / "cap (15)" literal** survives in `skills/upgrade-repo/SKILL.md:616`, the consumer-shipped `context_template/context/retrospectives.md:1`, and all three byte-equal `append-retrospective-entry.sh:6` copies — while `ENTRY_CAP=10` is correct. Highest-multiplier site is the template (copied to every new repo). Net-new instances of the Pattern-A sweep-incompleteness ICON-0046 named.

**Other stderr / label hygiene (Domains 03, 04):**
- **m6 — Agent-invoked `diff … > /dev/null 2>&1`** (ADR-007 in-scope) silently misclassifies a missing template as "CUSTOMIZED". `skills/upgrade-repo/SKILL.md:124`. (Carry-forward m-new-02.)
- **m7 — Phantom "plugin-lint Check A/B" labels** cite a numbered catalog that exists nowhere on disk (3 sites). `skills/icon-init/SKILL.md:225,245`; `skills/icon-status/SKILL.md:214`. (Carry-forward, now 3 sites.)

**Utility-skill self-consistency (Domain 04):**
- **m8 — `writing-skills` violates its own caps:** 524 lines vs its "under 500 lines" rule (line 210, reopened by ICON-0047's `Where Skills Live` addition) and 3,160 words vs "aim for < 500 words". `skills/writing-skills/SKILL.md:210,265`.
- **m9 — `plugin-design` claims "plugin-agnostic" in the same sentence that scopes it to "any Claude Code plugin".** `skills/plugin-design/SKILL.md:14`. (Carry-forward m-U-net4.)

**Org-URL portability (Domain 04):**
- **m10 — `sprint-goals` embeds live DataScan Confluence URL** (2 sites) that 404s for non-DataScan consumers. `skills/sprint-goals/SKILL.md:20,196`. (Carry-forward; see Open Questions — may be intentional production state.)
- **m11 — `rfc` embeds live DataScan Confluence URLs** in the overview reference line. `skills/rfc/SKILL.md:19`. (Net-new surface post-ICON-0051.) (See Open Questions.)

**Third-party `rfc` rewrite inconsistencies (Domain 07 — Focus 1):**
- **m12 — `rfc/SKILL.md:312` calls the example "Confluence wiki markup"** — it is pure Markdown; contradicts `:142` and the example itself. Net-new from ICON-0051.
- **m13 — `rfc/SKILL.md:182` says labels use `*bold*`** (italic) while the schema, example, and Formatting checklist all use `**bold**`. An author following `:182` literally emits italic labels. Net-new from ICON-0051.

**Discoverability registration (Domains 04, 07 — Focus 1):**
- **m14 — `characterization-testing` and `mcp-tools-first` are both absent from the README Internal Skills table** despite being wired into routing. Recurrence of the ICON-0046 registration-gap class on a contributed surface. `README.md:184–213`.

**Infra / release (Domain 05):**
- **m15 — `.mcp.json` lacks `$schema`** (plugin.json has one since ICON-0038). `.mcp.json:1`. (Carry-forward.)
- **m16 — `release-plugin` Step 1 doc-sweep omits the `context_template/iconrc.json` version-bump cross-check.** `.claude/skills/release-plugin/SKILL.md:65`. (Carry-forward.)
- **m17 — Duplicate `### Changed` heading in the `[1.19.0]` / `[Unreleased]` CHANGELOG block** (ICON-0049 and ICON-0051 each appended their own; never consolidated). `CHANGELOG.md:25,29`. Net-new; second `### Changed` is invisible to heading-based parsers.

---

## Focus 1 — Third-Party Contribution Integration

**Verdict: Good integration health.** Every merged third-party contribution is structurally sound, conformant to the folded-block-scalar frontmatter convention, and carries correct anti-rationalization tables, name-prefixed step headings, a correctly-versioned one-bullet-per-change CHANGELOG entry, and a substantive retrospective. No foreign authoring patterns were introduced — strong evidence the `CONTRIBUTING.md` `New task: … / task complete` flow is being followed by outside contributors. The gaps that slipped through are precisely the ones not yet *mechanically* enforced.

### Integration-Completeness Matrix (condensed — full version in `research/07`)

| Contribution | README | using-skills | Caller wiring | CHANGELOG | Retro | Authoring std |
|---|---|---|---|---|---|---|
| `mr-feedback-triage` (Connor, ICON-0046) | ✅ | n/a | n/a | ✅ | ✅ | ✅ |
| `mr-discipline` hardening (Connor, ICON-0046) | ✅ | n/a | ✅ | ✅ | ✅ | ✅ |
| manager Jira-ID guard + `commit-discipline` (Connor, ICON-0042) | n/a | ✅ | ✅ (3-layer) | ✅ | ✅ | ✅ |
| `characterization-testing` (Arvind, ICON-0049) | ❌ **m14** | ✅ | ✅ | ✅ | ✅ | ✅ |
| `tester.agent.md` Step 2 (Arvind, ICON-0049) | n/a | ✅ | ✅ | ✅ | ✅ | ✅ |
| `rfc` schema rewrite (Matthew, ICON-0051) | ✅ | ✅ | n/a | ✅ | ✅ | ⚠️ **m12, m13** |
| `.mcp.json` mcp-atlassian (Tom Stear) | n/a | n/a | n/a | n/a | n/a | ✅ shape* |

\* Tom Stear's version-pin line was subsequently rewritten by a maintainer commit (MKT-0080), so it is no longer line-attributable at HEAD — an attribution nuance, not a defect.

**What's solid:** Connor's two contributions are fully up-to-standard, including textbook three-layer enforcement on the Jira-ID-fabrication guard (Session-Start gate + commit-time gate + AR row). The `rfc` metadata-table schema itself is correct at both scaffold and refactor paths. CHANGELOG and retro hygiene is excellent across the board.

**What slipped (all mechanically-preventable):**
- **m14** — `characterization-testing` wired everywhere except the README table. The ICON-0049 retro shows the registration step was never on the task's radar — a process gap, not a slip.
- **m12 / m13** — the `rfc` rewrite left two internal contradictions (Confluence-vs-Markdown descriptor; `*bold*`-vs-`**bold**`).

**Highest-leverage Focus-1 fixes:** a **`CONTRIBUTING.md` new-skill integration checklist** (IO-M2) and a **pre-commit skill-registration invariant** (IO-V1) — together they close the registration class at both the self-review and the commit gate. See Fix Tiers.

---

## Focus 2 — Rule/Workflow Discoverability Gap

> **Your question:** relevant `.context/` information is not discovered by the manager or sub-agents at the moment of need — and the miss is worse for *rule/workflow* knowledge than for *codebase* knowledge.

**The asymmetry is real and structural — it is encoded directly in the manager's discovery design.**

### Root cause

`.context/domains/` (codebase facts) is **privileged** — it is woven into three independent forcing functions:
- the manager's **research-need gate** keys explicitly on domains coverage (`manager.agent.md:59`),
- the **warmstart template** has a required `### Domain` field (`:147`),
- the **Anti-Rationalization table** names `.context/domains/` as the alternative to source investigation (`:260`).

`.context/standards/`, `workflows/`, and `decisions/` (rule/workflow knowledge) get **none** of these. They appear only in a single passive line — "Read *relevant* files from `.context/` subdirectories…" (`:93`) — which delegates selection judgment to the agent with no enumeration step, no coverage gate, and no required warmstart field. Three compounding facts:

1. **`decisions/` appears in zero agent files.** ADRs are reached only if an agent happens to read the flat subdirectory list and *chooses* to open `decisions/`. (This is exactly why every audit brief must re-state the ADR-007/009/010 carve-outs verbatim — nothing surfaces them automatically.)
2. **Sub-agent misses are strictly worse than manager misses.** Sub-agents run in isolated context and get only what the warmstart hands them. The template has a `### Domain` block but **no `### Applicable Rules` block** — so even when the manager *has* read a relevant ADR, no field obligates passing it down. Several sub-agents' own read-lists omit `decisions/` (`coder`, `reviewer`, `architect`).
3. **A clean ADR index already exists** (`.context/decisions/README.md:28–41`) but nothing auto-loads or enumerates it; the SessionStart hook injects only the manager body.

**Net:** codebase facts are discovered because `domains/` has forcing functions; rules are under-discovered because the rule dirs have none. This same "the rule existed but wasn't reached at the moment it applied" shape is the root cause behind three separate retrospective patterns this audit catalogued (the 3× "manager bypasses the governing skill", the 4+-cycle sweep-incompleteness, the README-registration recurrence).

### Recommended mechanisms (portable across Claude Code and Copilot CLI)

| # | Mechanism | Where it lives | Effort / Impact | Closes |
|---|-----------|----------------|-----------------|--------|
| **M1 (top pick)** | **`.context/rules-index.md`** — a single table listing every file under `standards/`/`workflows/`/`decisions/` with a one-line "applies when…" trigger, auto-read at Context Discovery (index only, not rule bodies — preserves ADR-008 budgets). Generalizes the ADR Decision-Log table that already exists. | new `context_template/context/rules-index.md` + generator step in `context-specialist`/`upgrade-repo` + read instruction at `manager.agent.md:93` | medium / **high** | rules-under-discovered-because-no-index |
| **M2** | **Rule-coverage gate** added to the manager's research-need check (Step 7) — parity with the existing `domains/` gate. | `manager.agent.md:56–71` | low / **high** | the asymmetric absence of a rule-coverage test |
| **M3** | **Required `### Applicable Rules` warmstart field** — obligates the manager to pass the ADRs/standards bearing on each delegation, parallel to `### Domain`. | `manager.agent.md:133–156` | low / **high** | sub-agent-level misses (can't rediscover an unpassed rule) |
| **M4** | **Pre-write governing-rule lookup** (Hardcoded) — before producing any governed artifact (plan, retro, changelog, MR, skill), consult the rule that governs its format first. Generalizes the audit's existing "read `decisions/` before tiering" discipline. | `manager.agent.md` Hardcoded tier | trivial / med-high | the 3× "manager bypasses the governing skill" retro pattern |
| **M5** | **Rule-routing table** in `using-skills`/`manager-routing-guide` mapping task *types* → rule dirs to consult (piggybacks on a surface agents already consult). | `using-skills` or `manager-routing-guide` | low / medium | rules-not-reached-because-no-routing |

**Recommendation:** **M1 is the single highest-leverage move** — it gives the rule dirs the same enumerated forcing-function status `domains/` already enjoys, reuses an index shape that already exists, and makes M2–M4 cheap to layer on. M4 is a near-free behavioral complement worth pairing with it. If you want a phased path: **M4 now (trivial), M1+M2 next (the structural fix), M3 with the warmstart pass.**

---

## Improvement Opportunities (~30)

*Positive-design suggestions; none are defects. Each is a judgment call you can accept, defer, or reject.*

### Category 1 — Token Efficiency / Slim the Always-Loaded Surface
- **O-T1 · Close the ADR-008 cumulative-drift gap.** Amend ADR-008 so a re-inventory triggers whenever any audit measures cumulative growth-from-baseline ≥5% of cap, independent of the per-MR gate; pair with extracting the manager's always-loaded Task Completion elaboration to an on-demand companion (keep the Hardcoded one-liner inline). **Effort: trivial→low. Impact: high.**
- **O-T2 · Quantify `phase-completion`'s "keep minimal" claim** (`<!-- target ≤ 850 words -->` or rephrase). **Effort: trivial. Impact: low.**

### Category 2 — Discoverability / Onboarding UX
- **O-D1 · Register `characterization-testing` + `mcp-tools-first` in the README Internal Skills table** (closes m14). **Effort: trivial. Impact: medium.**
- **O-D2 · Add a pre-commit-hook install reminder to `README.md`** (`git config core.hooksPath .githooks`) — currently only in `CONTRIBUTING.md`, so a clone-without-reading bypasses all invariant gates (a force-multiplier on every self-verification mechanism here). **Effort: trivial. Impact: medium.**
- **O-D3 · The 5 Focus-2 mechanisms (M1–M5)** are themselves the agent-facing discoverability improvements — see § Focus 2.

### Category 3 — Consolidation / Structural Simplification
- **O-S1 · Resolve the triple-verification atomically** (remove from retro Steps 6–7 + collapse manager Step 2 into the close-gate). The partial-fix history of *this exact finding* is the cautionary tale — do both removals in one change. **Effort: trivial. Impact: low-medium.**
- **O-S2 · Replace phantom "plugin-lint Check A/B" labels with real `common-constraints.md` citations** (3 sites). **Effort: trivial. Impact: low.**
- **O-S3 · Fix the two `rfc/SKILL.md` internal contradictions** (m12, m13). **Effort: trivial. Impact: low-medium.**
- **O-S4 · Resolve `writing-skills`/`plugin-design` self-consistency** (split `Where Skills Live` to a companion or tier the cap; pick one side of "plugin-agnostic"). **Effort: low. Impact: low-medium.**

### Category 4 — Missing Skills / Workflow Gaps
- **O-M1 · Implement the ICON-0015 O-V4 literal-grep pre-commit gate** — grep staged `skills/`/`agents/` for unresolved `<…>` placeholders and for cap/version literals that disagree with `ENTRY_CAP=N` constants. Highest-recurrence-closing mechanism in the codebase (sweep-incompleteness has fired 4+ cycles). **Effort: low. Impact: high.**
- **O-M2 · Canonicalize the `context_template/phase-completion.md` Retrospective Template** to the `### ` form (closes Moderate M1). **Effort: trivial. Impact: high (consumer-correctness).**
- **O-M3 · Generalize `ecological-impact` Option-A to runtime-agnostic** (closes Moderate M2) — the calc core is already generic; only Step-1 Option A needs platform-neutral framing. **Effort: low. Impact: high.**
- **O-M4 · Add the `context_template/iconrc.json` version check to `release-plugin` Step 1** (release-time second layer behind the pre-commit gate). **Effort: trivial. Impact: medium.**

### Category 5 — Self-Verification / Automate the Retrospective Wisdom
- **O-V1 · Skill-registration pre-commit invariant** — for each `skills/<name>/`, assert `<name>` appears in `README.md` (closes the m14 class mechanically). **Effort: low. Impact: high.**
- **O-V2 · `CONTRIBUTING.md` new-skill integration checklist** (README row / `using-skills` routing / consuming-agent wiring) — would have caught m14 at the contributor's self-review. **Effort: low. Impact: high.**
- **O-V3 · Audit-finding → follow-up-task disposition ledger** (closes Moderate M3) — record per finding: tier, recommended task, **accepted / deferred / rejected + reason**, so a silently re-scoped Moderate becomes a visible *deferred* item the next audit checks. Generalizes ADR-010's carry-forward registry from "accepted watch items" to "all unclosed findings". **Effort: low. Impact: high.**
- **O-V4 · `### Changed`-dedup guard in `release-plugin` Step 5** (closes m17 class from parallel feature branches). **Effort: trivial. Impact: medium.**
- **O-V5 · Pre-write governing-rule lookup (Focus-2 M4)** — the behavioral self-verification that closes the 3× "manager bypasses the governing skill" retro pattern. **Effort: trivial. Impact: med-high.**

---

## ICON-0046 Delta

### Fixed since ICON-0046 (~7)
- `context-specialist.agent.md` description trimmed to one sentence (m-A-NET-NEW-1); Discretionary heading parenthetical restored (m-A-NET-NEW-2); audit-mode-commit contradiction removed across 3 surfaces (m-A-NET-NEW-3); `keep-last-15` prose in the two named files (m-P-NEW-1/2); `mcp-tools-first` frontmatter `user-invocable` key (m-U-net2); `impl-root` verify filename `patterns-template.md`→`patterns.md` (m-new-01); pre-commit hook header invariant ordering (m-infra-2). All confirmed on disk (ICON-0048).
- **Caveat:** the high close-rate closed *literals* while leaving *structural siblings* — reproducing the very sweep-incompleteness pattern the prior audit flagged (m5 this cycle).

### Still present or partial (~9; 3 worsened)
- **Worsened:** O-T1 ADR-008 per-component overage (50.8%→54.7% session; 136.7% per-component; +500 cumulative undetected); O-S1/m-P-NEW-3 double→**triple** verification; **M-U-NET1 `ecological-impact` — 3rd-cycle carry-forward, zero structural change**.
- **Still present:** plugin-lint Check A/B (now 3 sites); O-V4 literal-grep gate unimplemented; `phase-completion` minimal-bound; PM `Turn Start` absent; `web_search`/`web_fetch` platform note absent; `impl-branch` verify gap; multimodule root-context asymmetry; `.mcp.json` `$schema`; `release-plugin` iconrc check; `sprint-goals` org URL.

### Net-new drift since ICON-0046 (4)
1. **Consumer-template retrospective-format incompatibility** (Moderate M1) — first observable because no prior audit checked the template against the script's validation.
2. **Within-block CHANGELOG `### Changed` duplication** (m17) — a *new* failure mode from parallel feature branches, distinct from the `[Unreleased]`-absorption bug the ICON-0056 guard covers.
3. **Close-gate lint-evidence with no production step** (m2) — introduced by ICON-0057.
4. **Agent-body skill-routing conditionals** (`tester.agent.md:19`, watch-only) — benign today; risks duplicating `using-skills` routing if extended.

### Audit-process observation
This cycle confirms the ICON-0046 warning verbatim: the high ICON-0048 close-rate closed literals while leaving structural causes, reproducing both named recurring patterns. The cross-cutting prescription is unchanged and now reinforced by a third data point — **the codebase needs mechanical reach-at-the-moment-of-need infrastructure more than more prose.** The Focus-2 section and three of the five Category-5 opportunities converge on this one conclusion.

---

## Prioritized Fix Tiers

### Tier 1 — Fix immediately (correctness risk)
- **M1 / O-M2** — canonicalize the `context_template` Retrospective Template (silent consumer entry-insertion failure).
- **M2 / O-M3** — make `ecological-impact` Option-A runtime-agnostic (inoperable for every Claude Code consumer; 3rd cycle).

### Tier 2 — Short-term consolidation (defect cleanup + close recurring classes)
- **O-M1** — literal-grep pre-commit gate (closes the m5 sweep-incompleteness class).
- **O-V1 + O-V2** — skill-registration invariant + CONTRIBUTING intake checklist (closes the m14 registration class — Focus 1).
- **O-S1** — resolve the triple-verification atomically (m1).
- **m5 sweep** — fix the 4+ stale 15→10 sites now (and let O-M1 prevent recurrence).
- **O-S3** — fix the two `rfc` contradictions (m12, m13 — Focus 1).
- **m17 / O-V4** — consolidate the duplicate `### Changed` and add the dedup guard.

### Tier 3 — Structural refactors (higher effort, higher payoff)
- **O-T1** — ADR-008 cumulative-drift amendment + manager Task-Completion extraction.
- **O-V3** — audit-finding disposition ledger (closes Moderate M3; stops the carry-forward leak).
- **O-S4** — `writing-skills` / `plugin-design` self-consistency.
- Carry-forwards: m2 (lint owner), m3/m4 (footers/minimal bound), m6 (diff stderr), m7 (plugin-lint labels), m15 (`.mcp.json` `$schema`), m16 (release iconrc check), `impl-branch` verify, multimodule root-context.

### Tier 4 — New capabilities (forward-looking)
- **Focus 2: M1 + M2 (+ M3, M4, M5)** — the rule/workflow discoverability infrastructure. This is the highest-strategic-value item in the report even though it is not a defect: it addresses the root cause behind multiple recurring classes.
- **O-D2** — README hook-install reminder (force-multiplier on every gate above).

---

## Open Questions for the User

1. **Org-URL portability (m10, m11):** `sprint-goals` and `rfc` embed live `onedatascan.atlassian.net` Confluence URLs. Per the standing decision that **this repo IS DataScan's production plugin**, are these intentional production state (leave as-is) or should they become portable placeholders? The audit recommends the placeholder *mechanism* for any fork regardless, but will not "fix" production URLs without your call.
2. **Focus-2 sequencing:** do you want the full M1–M5 suite scoped as one task, or the phased path (M4 now → M1+M2 → M3)?
3. **Disposition ledger (O-V3):** adopt it as a section in future audit reports, or as a standalone `.context/` artifact the manager maintains?

---

## Suggested Follow-up Tasks

- **ICON-0059** — Tier-1 correctness fixes: canonicalize the `context_template` retrospective template (M1) + make `ecological-impact` Option-A runtime-agnostic (M2).
- **ICON-0060** — Reach-at-the-moment-of-need automation: implement the O-V4 literal-grep gate + skill-registration invariant + CONTRIBUTING intake checklist (closes the sweep-incompleteness and registration classes; Focus 1).
- **ICON-0061** — Verification/close-gate consolidation: resolve the triple-verification atomically + assign lint ownership + the two `rfc` doc contradictions.
- **ICON-0062** — **Focus 2** rule/workflow discoverability: `.context/rules-index.md` (M1) + research-need rule gate (M2) + `### Applicable Rules` warmstart field (M3) + pre-write governing-rule lookup (M4).
- **ICON-0063** — Token governance: ADR-008 cumulative-drift amendment + manager Task-Completion extraction + the audit-finding disposition ledger (O-V3).
- **ICON-0064** — Hygiene sweep: 15→10 literal sweep, plugin-lint label citations, `.mcp.json` `$schema`, release-plugin iconrc check, CHANGELOG `### Changed` dedup guard, README hook-install reminder.

Each is independent and can be triaged by priority and bandwidth.

---

## Post-Review Dispositions (2026-06-10)

Recorded after the user reviewed the findings (an instance of the O-V3 disposition-ledger pattern this report recommends):

- **m10 / m11 (live `onedatascan.atlassian.net` URLs in `sprint-goals` and `rfc`)** — **Accepted as intentional production state.** This repo IS DataScan's production plugin; the URLs are real references, not placeholder leaks. Findings closed (will not be "fixed"). The portable-placeholder *mechanism* remains the recommendation only if a non-DataScan fork is ever created. (Open Question 1 resolved.)
- **Suggested follow-up tasks (ICON-0059..0064)** — **Filed as GitLab work items** (2026-06-10): ICON-0059 → #31, ICON-0060 → #32, ICON-0061 → #33, ICON-0062 → #34, ICON-0063 → #35, ICON-0064 → #36. Each is labeled `follow-up`/`audit-finding` + domain/tier and links back to this report.
- **Branch disposition** — Pushed and opened as an MR to `main` (report lands on main, as ICON-0046 did). No release.
