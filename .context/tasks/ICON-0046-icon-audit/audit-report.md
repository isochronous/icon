# ICON Plugin Audit Report — ICON-0046

**Task:** ICON-0046
**Date:** 2026-05-27
**Plugin version audited:** `v1.17.2` on `main` (latest release; `[Unreleased]` block is currently empty).
**Scope:** 9 agents, 49 consumer-facing skills under `skills/`, 3 maintainer-only skills under `.claude/skills/` (`changelog-entry`, `icon-audit`, `release-plugin`), 1 plugin manifest (`.claude-plugin/plugin.json`), 1 MCP registry (`.mcp.json`), 1 plugin-scoped SessionStart hook + `inject-manager-role.mjs`, 1 pre-commit hook enforcing 4 invariant classes, 11 ADRs (`.context/decisions/001`–`010` + `README.md`).
**Method:** 5 parallel domain research agents (01–05) → 2 synthesis-tier agents (06 cross-cutting; 07 plugin-decomposition, per user directive) → synthesis. Baseline for delta comparisons: **ICON-0015** (2026-05-20, plugin v1.15.4 + Unreleased ICON-0011/0012/0013/0014; verdict GOOD).
**Raw findings:** `./research/01-agents.md`, `02-process-skills.md`, `03-context-specialist-init.md`, `04-utility-skills.md`, `05-infrastructure.md`, `06-cross-cutting.md`, `07-plugin-decomposition.md`.
**User directive (this cycle):** in addition to the standard 6-domain audit, evaluate how the plugin could be split into 2+ composable plugins (software-development, product-management, agentic-toolkit-design, etc.) — distinguishing standalone candidates from ICON-extension candidates from cross-composable building blocks. See § Plugin Decomposition Analysis.

---

## Executive Summary

**Overall health: STRONG.** ICON-0015's recommendations were thoroughly executed: 30 tasks closed between ICON-0016 and ICON-0045 addressed essentially every Tier-2 and Tier-3 item the prior audit surfaced. All five ICON-0015 Moderates are confirmed fixed on disk (M-CC-NET1 doc-drift via ICON-0031; M-CC-NET2 retrospectives write-path via ICON-0027; M-CC-NET3 dead `three-layer-enforcement.md` ref via ICON-0028; M-I-A `merge-phase-templates` testing row via ICON-0029; M-U-A plugin-audit brief placeholders via ICON-0030). The token surface is governed by a new ADR-008 with explicit caps (8,500-word manager session, 7,000-word PM session, 40% per-component ceiling); the manager session sits at 97.1% of cap with 247 words of headroom. Two new skills entered the catalog (`mcp-tools-first` ICON-0041 + hardening ICON-0045; `plugin-design` ICON-0043), and one existing skill moved to maintainer-only (`icon-audit`, ICON-0042). The pre-commit hook gained two new invariant classes (script-parity gate via ICON-0032; iconrc-version-bump gate via ICON-0044).

This cycle surfaces one Moderate and approximately 17 Minor findings. The remaining issues cluster into four themes:

1. **`ecological-impact` retains heavy Copilot-product coupling in its primary calculation path (M-U-NET1).** ADR-004 mandates tool-agnostic content. ICON-0037 fixed the stale model name (m-U-A) but left "Remaining Reqs", "GitHub Copilot Business plan" quota table, and the "Copilot Ecological Impact Report" output header untouched. The skill's Option-A calculation path is inoperable for Claude Code consumers; only Option B (session-only) works. This is the third audit cycle touching the same root cause on the same skill — partial sweeps that address the most visible literal without investigating the calculation path.

2. **The recurring sweep-incompleteness pattern (O-V4 from ICON-0015) is still unmitigated and produced two new instances this cycle.** `skills/task-plan-phase-completion/agent-vs-skill-invocation.md:23` still says `keep-last-15` and `skills/context-maintenance/append-retrospective-entry.md:3,:32` still describe the pre-ICON-0041 single-prune logic at cap-15 — both missed by the ICON-0036 cap-reduction sweep. This pattern has now appeared in ≥6 audit cycles. The recommended O-V4 pre-commit grep gate from ICON-0015 was not implemented (only the dead-ref resolver sub-item shipped via ICON-0032).

3. **New-skill catalog discoverability gap.** `mcp-tools-first` (ICON-0041) ships with no `user-invocable` frontmatter key (m-U-net2), is absent from `using-skills/SKILL.md:69-76` Skill Priority (IO-CC-D1), and is missing from `README.md:176-209` Internal Skills table. Every other auto-invoked internal skill appears in that table. ICON-0045's retrospective documents the exact failure mode this gap enables — an agent confirming the MCP tool exists then falling back to `which glab` under schema-unknown pressure.

4. **ADR-008 per-component overages and a 97.1%-of-cap manager session.** Both overages were acknowledged at ADR-008 adoption (`manager.agent.md` at 50.8% vs. 40% per-component cap; 9× common-constraints at 45.5% in the PM session). Manager session delta from ICON-0033 baseline is +189 words (ICON-0042 added the Task ID Source rule + AR row; ICON-0045 hardened MCP-tools-first which is on-demand). The next substantive `manager.agent.md` edit will breach the session cap without firing the 5%-delta re-audit trigger first.

A separate, dedicated **Plugin Decomposition Analysis** (per user directive) surfaces a 4-option decomposition matrix and recommends P2 (`icon-dev` + `icon-pm` + `icon-context`) **if and when** a split happens, while honestly noting that no current finding structurally compels the split today.

### Scorecard

| Rule | Verdict | Movement vs ICON-0015 |
|------|---------|-----------------------|
| RULE 1 — PROMPT vs SKILL SEPARATION | ✅ PASS | Held |
| RULE 2 — SINGLE SOURCE OF TRUTH | ✅ PASS | **Improved (was WARNING).** Common-constraints 9× duplication remains policy-accepted + mechanically enforced (ICON-0011/0013). M-CC-NET2 retrospectives write-path "Known unresolved" closed by ICON-0027. ADR-008 establishes token-budget SSOT. |
| RULE 3 — SUB-AGENT JOB CLARITY | ✅ PASS | Held — all 7 sub-agents carry consistent "Your job ends when..." scope-termination language. |
| RULE 4 — SKILL RESPONSIBILITY | ✅ PASS | Held — no skill-responsibility violations. New skills (`mcp-tools-first`, `plugin-design`) are scope-clean. |
| RULE 5 — ORCHESTRATOR CLARITY | ✅ PASS | Held — `context-specialist mode: upgrade` routing remains coherent post-ICON-0007; new `mode: audit` is documented. |

(The 5-rule scorecard borrows the framework from `agent-evaluation`. Cross-reference for rule definitions — do not duplicate them here.)

### Top-line counts

- **Defects (deduplicated)**: **0 Critical**, **1 Moderate**, **17 Minor** (total **18**).
- **Improvement Opportunities**: **~25** unique after dedup across briefs 01–06, organized into 5 standard categories (Token Efficiency / Discoverability / Consolidation / Missing Skills / Self-Verification).
- **ICON-0015 delta**: **~28 items confirmed fixed** (all 5 Moderates + most of the Improvement-Opportunity inventory closed via ICON-0016 → ICON-0045); **~5 still-present-or-partial** (the long-tail carry-forwards + O-V4 placeholder-grep sub-item not implemented); **~6 net-new** drift classes including the M-U-NET1 ecological-impact pattern recurrence.
- **Theme**: surface area shifted from "doc-drift and retro-write-path canonicalization" (ICON-0015) to "ADR-004 runtime-coupling residue, ADR-008 cap-management, and structural discoverability gaps for new auto-invoked skills." Token-economics has gone from "not measured" (ICON-0015) to "measured but tight" (this cycle).

*Dedup notes:* (a) M-U-NET1 (04 utility) = m-CC-NET-NEW-1 (06 cross-cutting pattern observation) — single Moderate. (b) m-P-NEW-1/2 (02 process) = m-CC-NET-NEW-2 (06 sweep-incompleteness pattern) — counted as 2 Minor in process-skills, narrated as one pattern observation in cross-cutting. (c) m-U-net2 (04 utility) + IO-U-3 (04) + IO-CC-D1 (06) all reference `mcp-tools-first` discoverability — single discoverability gap. (d) IO-A-6 / Observation 3 (01 agents) is reframed as a Minor finding (`context-specialist.agent.md:84` "where audit-write occurs" parenthetical) in this synthesis.

---

## Critical Findings (0)

None observed.

---

## Moderate Findings (1)

*Full rationale and file:line references in the research files. This section is a consolidated inventory for triage.*

### Tool-Agnostic Content / ADR-004 Violation (1)

| # | Finding | Location |
|---|---------|----------|
| **M-U-NET1** | **`ecological-impact` embeds Copilot-product-specific framing throughout the Option-A calculation path.** ADR-004 mandates tool-agnostic content. The skill's primary calculation path asks for "Remaining Reqs" (GitHub Copilot status-bar UI), references "GitHub Copilot Business plan" quota tiers (Free 50 / Pro 300 / Business 300 / Enterprise 1,000 — the GitHub billing structure, not a property of any Anthropic-hosted runtime), and hardcodes "Copilot Ecological Impact Report" in the output template and example. The description at `:4` still says "Copilot session." Only Option B (session-only) works for non-Copilot runtimes; the "preferred" path is inoperable. This is the third audit cycle touching the same skill with the same root cause: ICON-0015 m-U-A fixed the stale model name at `:86,:221`; the deeper Copilot UI framing was not in scope and remains. **Classification:** Moderate (not Critical because Option B still works; the skill degrades rather than fails completely). | `skills/ecological-impact/SKILL.md:4,:12,:17,:21,:43-74,:148-149,:199,:208`; `README.md:159` (skills-table description echo) |

---

## Minor Findings (17)

Condensed list. Details in research files; each ID resolves to a line-cited finding in the corresponding brief.

**Agents (3):** `context-specialist.agent.md:2-6` description is 3 sentences, violating `agent-evaluation/SKILL.md:104` one-sentence sub-agent rule — the ICON-0034 fix normalized the YAML form but missed sentence count (**m-A-NET-NEW-1**); `manager.agent.md:238` Discretionary heading missing `(Off Unless Explicitly Requested)` parenthetical present on all 8 sibling agents (**m-A-NET-NEW-2**); `context-specialist.agent.md:84` Hardcoded commit-rule parenthetical "(where audit-write occurs)" contradicts the Process section's "Do not modify any files" for `mode: audit` (**m-A-NET-NEW-3**).

**Process skills (3):** `task-plan-phase-completion/agent-vs-skill-invocation.md:23` still says `keep-last-15` after ICON-0036 cap reduction (**m-P-NEW-1**); `context-maintenance/append-retrospective-entry.md:3,:32` still says "rolling log of last 15 entries" with single-prune behavior description (pre-ICON-0041 logic) (**m-P-NEW-2**); double-verification at canonical task close — `manager.agent.md:201` Step 2 and `task-retrospective/SKILL.md:129-130` Steps 6–7 both invoke `verification-checklist` without documented intent (**m-P-NEW-3**).

**Context-specialist + init (3):** `context-specialist-impl-root/SKILL.md:256` Step 15 verify item 4 checks `patterns-template.md` but the skill generates `patterns.md` (wrong filename — file never created) (**m-new-01**); `upgrade-repo/SKILL.md:124` `diff -q ... > /dev/null 2>&1` suppresses stderr in agent-invoked bash block (ADR-007 scope) (**m-new-02**); "plugin-lint Check A/B" labels referenced in `icon-init/SKILL.md:225,245` and `icon-status/SKILL.md:214` with no discoverable formal definition (**m-new-03**).

**Utility skills (5):** `writing-skills/SKILL.md:240` word-count self-reference violation persists at 2,908 words vs. its own "aim for < 500 words" guidance (m-U-G line axis closed by ICON-0033; word axis open) (**m-U-net1**); `mcp-tools-first/SKILL.md:1-9` frontmatter missing `user-invocable` key (every other skill has it) (**m-U-net2**); `sprint-goals/SKILL.md:20,:196` embeds live `onedatascan.atlassian.net` Confluence URL — org-specific, distinct from ADR-010 m9-accepted DataScan-flavored examples in the body (**m-U-net3**); `plugin-design/SKILL.md:4,:12,:14` description names "Claude Code plugin" specifically while body claims plugin-agnosticism — internal contradiction (**m-U-net4**); `icon-audit/SKILL.md:144-152` Quality Checklist references `writing-skills` Iron Law without on-disk RED-phase TDD evidence (informational / process-observability gap, rename-not-creation context) (**m-U-net5**).

**Infrastructure (3):** `.mcp.json:1` lacks `$schema` — ICON-0015 m-1 covered both manifests; only `.claude-plugin/plugin.json` was fixed in ICON-0038 (**m-infra-1**); `.githooks/pre-commit:19-40` header comment lists "1. dead-ref / 2. iconrc gate / 3. script-parity in script-execution order" but actual execution is iconrc-gate → common-constraints sync → script-parity → dead-ref, making dead-ref #4 not #1 (**m-infra-2**); `release-plugin/SKILL.md:26-42` Step 1 doc-sweep does not mention verifying `context_template/context/iconrc.json` version-bump before tagging (motivated by the v1.17.0 missed-bump that drove ICON-0044) (**m-infra-3**).

**Cross-cutting (0):** No additional cross-cutting Minors beyond what the domain briefs surface. The two cross-cutting pattern observations (m-CC-NET-NEW-1 / m-CC-NET-NEW-2) are domain findings narrated through the recurrence lens; counted once each above.

---

## Improvement Opportunities (~25 after dedup)

*Items below are positive-design suggestions. None are defects; each is a judgment call the user can accept, defer, or reject.*

### Category 1 — Token Efficiency / Slim the Always-Loaded Surface (3)

**O-T1 · Address the ADR-008 per-component cap overages on `manager.agent.md` (50.8%) and 9× common-constraints (45.5% in PM session).** Both overages were acknowledged at ADR-008 adoption as "next-tier candidates" and have not been touched since. Manager session is at 97.1% of the 8,500-word cap with 247 words of headroom — the tightest the budget has been since ADR-008 was established. `manager.agent.md` is 4,322 words (up +174 from the ICON-0033 baseline of 4,148); the additions (ICON-0042 Task ID Source rule + AR row) are defensible individually but the cumulative pressure breaks the per-component cap. Three sub-options: (a) principled content review of `manager.agent.md` looking for sections that have grown since ICON-0033 baseline that can be extracted to on-demand companion files (low impact alone); (b) split the always-loaded surface by extracting the manager's Task Completion section into a separate on-demand "task-close-protocol" doc loaded only at retro time (medium impact); (c) accept the overage and amend ADR-008 to reflect the actual per-component cap rather than the aspirational 40%. **Effort: medium. Impact: high.** (Brief 06 IO-CC-T1.)

**O-T2 · Add a measurable bound to `task-plan-phase-completion`'s "Keep this skill minimal" self-description.** The completion skill at 832 words is the largest phase skill (vs. investigation 720, testing 552, implementation 487, architecture 439). Its self-description at `:12-13` aspires to "minimal" without a measurable ceiling. Either remove the aspirational claim or add an inline comment `<!-- target ≤ 800 words -->` so future edits can be measured. Pairs with ADR-008 adjacent-on-demand budget work. **Effort: trivial. Impact: low.** (Brief 02 IO-P-3.)

**O-T3 · Generalize `ecological-impact` to be runtime-agnostic (closes M-U-NET1).** The calculation core (Steps 2–6) is already fully generic. The Copilot-specific coupling is isolated to Step 1 Option A. Rename Option A to "Monthly Usage (Preferred)" and reframe data-gathering as platform-neutral; add a Claude Code-specific sub-option; replace "GitHub Copilot Business plan" quota table with generic "typical AI platform tiers" framing; replace "Copilot Ecological Impact Report" in template/example (`:149,:208`) with `<platform> Ecological Impact Report` or "AI Session Ecological Impact Report"; update the description at `:4` from "Copilot session" to "AI session". **Effort: low. Impact: high (correctness, not just hygiene).** (Brief 04 IO-U-1 + Brief 06 IO-CC-D2/D3.)

### Category 2 — Discoverability / Onboarding UX (4)

**O-D1 · Add `mcp-tools-first` to `using-skills/SKILL.md:69-76` Skill Priority list AND `README.md:176-209` Internal Skills table.** The single actionable discoverability gap in the current catalog: every other auto-invoked internal skill appears in both surfaces; `mcp-tools-first` is in neither. ICON-0045's retrospective documents an agent that knew the MCP tool existed and still fell back to `which glab` under schema-unknown pressure — exactly the failure mode catalog mentions are designed to prevent. **Effort: trivial. Impact: medium.** (Brief 04 IO-U-3, IO-U-4 = Brief 06 IO-CC-D1.)

**O-D2 · Add a `## Turn Start` section to `product-manager.agent.md`** mirroring `manager.agent.md:73-75`. PM is a user-invocable orchestrator with multi-turn research drift risk; one-line "Apply common constraints; if active story research is in progress, re-read the most recent research brief" would close the parity gap. **Effort: trivial. Impact: low-medium.** (Brief 01 IO-A-4.)

**O-D3 · Surface researcher's `web_search`/`web_fetch` tool names as platform-note callouts (ADR-004 portability hygiene).** `researcher.agent.md:26` uses both literals without platform annotation. `manager.agent.md:71` has the precedent format for a `> Platform note:` block. One-line addition. **Effort: trivial. Impact: low.** (Brief 01 IO-A-7.)

**O-D4 · Document the four-type-init-fan-out vs. three-position-impl-skills mapping at both endpoints.** `icon-init` produces workspace/monorepo/multimodule/project and dispatches to four `initialize-*` skills; the impl skills use root/leaf/branch positions (workspace+monorepo → root; project → leaf; multimodule → branch). Neither file documents the mapping. A short cross-reference at `icon-init/SKILL.md:34` and in `context-specialist-detect-tree-position` "Entry-Point Detection Primitive" section would close the cognitive gap. **Effort: trivial. Impact: low-medium.** (Brief 03 Observation 1.)

### Category 3 — Consolidation / Structural Simplification (8)

**O-S1 · Resolve the verification-gate ownership between `manager.agent.md:201` Task Completion Step 2 and `task-retrospective/SKILL.md:129-130` Steps 6–7 (closes m-P-NEW-3).** Every task close invokes `verification-checklist` twice. Pick one of two resolutions: (a) remove Steps 6–7 from `task-retrospective` and document that the retro runs after manager Step 2 (lower token cost; preserves manager orchestration model); (b) move verification from manager Step 2 into the retro and have manager step 3 note "task-retrospective includes verification gates" (more self-contained for callers invoking the retro standalone). Recommend (a) with a one-line note in retro: "If invoked from within `task-plan-phase-completion`, manager Task Completion Step 2 already ran this gate." **Effort: trivial. Impact: low-medium.** (Brief 02 IO-P-1/IO-P-4 = Brief 06 IO-CC-C2.)

**O-S2 · Resolve "plugin-lint Check A/B" undefined labels (closes m-new-03).** Two skills reference these as if they are formal numbered catalog entries that don't exist. Either (a) define formally — add `## Plugin-Lint Checks` section to a shared document and link from both skill common-mistakes tables; or (b) replace the labels with plain rule citations (e.g., "banned by `common-constraints.md` § Shell command self-check"). Recommend (b). **Effort: trivial. Impact: low.** (Brief 03 IO-04 = Brief 06 IO-CC-C1.)

**O-S3 · Trim `context-specialist.agent.md:2-6` description to one sentence (closes m-A-NET-NEW-1).** "Creates and maintains `.context/` documentation across create, upgrade, maintenance, and audit modes; cannot delegate to sub-agents." — matches the structure the ICON-0034 CHANGELOG assumed was in place. **Effort: trivial. Impact: low.** (Brief 01 IO-A-1.)

**O-S4 · Add `(Off Unless Explicitly Requested)` parenthetical to `manager.agent.md:238` Discretionary heading (closes m-A-NET-NEW-2).** Trivial parity fix. **Effort: trivial. Impact: very low.** (Brief 01 IO-A-2.)

**O-S5 · Remove the misleading "(where audit-write occurs)" parenthetical from `context-specialist.agent.md:84` (closes m-A-NET-NEW-3).** Contradicts the Process section's read-only `mode: audit` definition. Likely a copy-edit residue from an earlier draft. **Effort: trivial. Impact: low.** (Brief 01 IO-A-6.)

**O-S6 · Fix `context-specialist-impl-root` Step 15 verify item 4 filename from `patterns-template.md` to `patterns.md` (closes m-new-01).** The skill generates `patterns.md`; `patterns-template.md` is a context_template starter the skill never copies into the consumer's `.context/architecture/`. **Effort: trivial. Impact: low.** (Brief 03 m-new-01.)

**O-S7 · Add a verification step to `context-specialist-impl-branch` (closes IO-02 parity gap).** `impl-leaf` and `impl-root` both end with verify+commit; `impl-branch` ends at Step 9 with just commit. Confirm `projects.md`, `overview.md`, `.gitignore` exist; confirm commit SHA recorded. **Effort: trivial. Impact: low-medium.** (Brief 03 IO-02.)

**O-S8 · Sweep `Does NOT cover` footers in phase-investigation and phase-architecture for missing exclusions (closes IO-P-2).** Investigation omits "completion" from its exclusion list; architecture omits "retrospective." ICON-0036 aligned terminology but not coverage. One sweep to make all five footers enumerate the same five sibling phases (minus self). **Effort: trivial. Impact: low.** (Brief 02 IO-P-2.)

### Category 4 — Missing Skills / Workflow Gaps (5)

**O-M1 · Implement O-V4 from ICON-0015: extend `.githooks/pre-commit` with a literal-grep gate for unfilled placeholders and known stale literal values.** Pattern A from Brief 06's Retrospective Pattern Analysis has fired in ≥6 audit cycles (ICON-0003, 0004, 0007, 0008, 0011, 0014 per ICON-0015; plus ICON-0036's sweep that produced m-P-NEW-1/2 this cycle). The O-V4 placeholder-grep sub-item was deferred when ICON-0032 implemented only the dead-ref resolver. A two-phase hook block — (i) grep staged `skills/`/`agents/` files for unresolved `<…>` angle-bracket placeholders; (ii) grep for cap/version literals that also appear in `scripts/` files as `ENTRY_CAP=N` constants — encodes the existing editorial rule mechanically. The ICON-0036 retro already articulates the exact `grep -rnE` invocation. **Effort: low. Impact: high (closes the single highest-recurrence vector in the codebase across six audit cycles).** (Brief 06 IO-CC-M1.)

**O-M2 · Add `context_template/iconrc.json` version-bump check to `release-plugin/SKILL.md:26-42` Step 1 pre-flight (closes m-infra-3).** ICON-0044 added the commit-time gate; the release-time check gives a second confirmation layer. One sentence: "Also verify that `context_template/context/iconrc.json` `version` was bumped since the last release if any file under `context_template/` changed." **Effort: trivial. Impact: medium.** (Brief 05 IO-I1.)

**O-M3 · Assign `.context/cache/` pruning ownership to `context-maintenance`.** `researcher.agent.md` writes date-stamped cache files but has no instruction to prune stale ones; `context-maintenance` does not audit `cache/`. One-line addition: "Prune `.context/cache/` entries older than 30 days." Prevents unbounded accumulation in long-lived repos. **Effort: low. Impact: medium.** (Brief 01 IO-A-3 = Brief 06 IO-CC-V1.)

**O-M4 · Decide policy on `mcp-tools-first` frontmatter `user-invocable` key (m-U-net2) AND `plugin-design` description self-contradiction (m-U-net4).** For `mcp-tools-first`: add `user-invocable: false` and optionally `disable-model-invocation: true` for defense-in-depth. For `plugin-design`: either rephrase `:14` "applies to any Claude Code plugin" to honestly say "applies to any plugin" (and back-fill Copilot CLI support in the body), or accept it as Claude Code-specific by removing the "plugin-agnostic" claim. **Effort: trivial. Impact: low.** (Brief 04 IO-U-4 + m-U-net4.)

**O-M5 · Replace live `onedatascan.atlassian.net` URL in `sprint-goals/SKILL.md:20,:196` with placeholder (closes m-U-net3).** "See your organization's Sprint Goal Guidelines document (replace this link with your org's equivalent)." ADR-010 m9 covers DataScan-flavored *examples*; the live URL in body text is not within that acceptance. **Effort: trivial. Impact: low-medium.** (Brief 04 IO-U-5.)

### Category 5 — Self-Verification / Automate the Retrospective Wisdom (5)

**O-V1 · Correct or clarify the `.githooks/pre-commit:19-40` header comment invariant numbering (closes m-infra-2).** Actual execution is iconrc-gate → common-constraints sync → script-parity → dead-ref, but the header says "1. dead-ref / 2. iconrc gate / 3. script-parity in script-execution order." Either renumber to match actual execution OR remove the "in script-execution order" qualifier. The ICON-0044 retro records the reorganization claim that does not match what shipped. **Effort: trivial. Impact: low.** (Brief 05 IO-I2.)

**O-V2 · Add a `$schema` field to `.mcp.json` if a suitable schema exists (closes m-infra-1).** ICON-0015 m-1 covered both manifests; ICON-0038 only fixed `plugin.json`. Research whether SchemaStore or Claude Code documentation provides an `.mcp.json` schema; if available, add as first key. **Effort: trivial. Impact: low.** (Brief 05 IO-I3.)

**O-V3 · Extend hook readability — add short-circuit guard comments before script-parity and dead-ref blocks; add an "iconrc gate already ran above" note above the no-agents early exit.** Three trivial comment additions improve next-maintainer onboarding cost without changing behavior. **Effort: trivial. Impact: low.** (Brief 05 IO-I4 + IO-I5.)

**O-V4 · Document `phase-skill task-retrospective` "double verification is intentional" OR remove Steps 6–7 (paired with O-S1).** If O-S1 picks Option (a), this opportunity is closed by that change. If O-S1 picks Option (b) or defers, a one-line note in the Completion Gates section makes the duplication intentional rather than ambiguous. **Effort: trivial. Impact: low-medium.** (Brief 02 IO-P-4.)

**O-V5 · Add an operational-defensiveness note to `upgrade-repo` Phase 0 Case 3 path (no instructions file exists).** Phase 1 still upgrades `.context/` infrastructure even with no entry-point file — producing a fully-upgraded `.context/` with no caller. Make the partial-state outcome explicit rather than implicit. **Effort: trivial. Impact: low-medium.** (Brief 03 IO-05.)

---

## ICON-0015 Delta (Comparison with 2026-05-20 baseline)

### Fixed since ICON-0015 (28+ items)

The ICON-0016 → ICON-0045 task sequence executed essentially all of ICON-0015's Tier-2 and Tier-3 recommendations. Summary by category:

**Moderates closed (5/5):**
- **M-CC-NET1** (user-facing doc-drift on README/`.claude/claude.md`/`commands/*`) — ICON-0031.
- **M-CC-NET2 / M-P-B** (retrospectives write-path "Known unresolved") — ICON-0027; `manager.agent.md:203-204` and `task-retrospective/SKILL.md` now agree on two-stage delegation; `agent-vs-skill-invocation.md` has no "Known unresolved" block.
- **M-CC-NET3 / M-A-NET1** (`manager.agent.md:151` dead `three-layer-enforcement.md` reference) — ICON-0028.
- **M-I-A** (`merge-phase-templates` Step 2 routing table missing `phase-testing.md`) — ICON-0029.
- **M-U-A** (six plugin-audit briefs unfilled `<path-to-prior-audit-report.md>` placeholder) — ICON-0030.

**Improvement Opportunities closed (~24):**
- **Token-economy / SSOT:** O-T1 (ADR-008 budget audit) — ICON-0033; O-T2 (reviewer 6-category trim), O-T3 (5× phase-skill template-override collapse), O-T4 (writing-skills 500-line cap) — ICON-0033.
- **Discoverability:** O-D1 (using-skills task-plan phase chain example), O-D3 (PM Session Start parity with manager), O-D4 (mr-discipline cue) — all ICON-0034; O-D2 (README/`.claude/claude.md` hook architecture sweep) — ICON-0031.
- **Consolidation:** O-S2 (phase-testing routing row) — ICON-0029; O-S3 (base-template promotion review — ADR-010 Part A) — ICON-0039; O-S5 (init-orchestrator entry-point detection single-sourcing, 6 copies) — ICON-0022; O-S6 (upgrade-repo Phase 3 drift-trigger spec extraction), O-S7/O-S8 (phase-skill footer terminology + initialize-workspace MR template) — ICON-0035/0036.
- **Self-verification / hooks:** O-V1 (brief placeholder sweep) — ICON-0030; O-V2 (script-parity gate for `append-retrospective-entry.{sh,ps1}`) — ICON-0032; O-V4 (partial: dead-ref resolver implemented; placeholder-grep sub-item NOT implemented) — ICON-0032 partial.
- **Missing capabilities:** O-M1 (release-plugin Step 1 doc-sweep reminder) — ICON-0038; O-M2 (`icon-status /release-plugin` suggestion removed) — ICON-0038; O-M3 (LICENSE field removed; no LICENSE file shipped) — ICON-0038; O-M4 (`bump-versions.sh` `--dry-run` + monotonicity guard) — ICON-0038.
- **Sweep / re-tier:** O-X2 (ADR-010 Part B carry-forward registry) — ICON-0039.

**Other on-disk evidence of fixed items (carry-forward closures via ICON-0037 utility-skill polish bundle):** m-U-A (ecological-impact stale model name), m-U-B (jira-story `create` literal), m-U-C (start-worktree "not yet migrated"), m-U-D (writing-skills TaskCreate refs), m-U-E (setup-mcp-servers Option A only), m-U-F (rfc design-history mid-schema), m-U-I (synthesis-template MKT-0046 ref). m-U-G (writing-skills line-cap) closed by ICON-0033; word-cap axis still open (see m-U-net1).

**Other on-disk evidence (infrastructure):** m-1 partial (plugin.json `$schema` via ICON-0038; .mcp.json still absent — see m-infra-1); m-7/m-U-H (release-plugin git-repo guard) — ICON-0038; m-4/m-U-K (format-slack.sh strict mode) — ICON-0038; m-n3 (context_template README diagram) — ICON-0038.

### Still present or partial (~5)

- **O-V4 placeholder-grep sub-item** — ICON-0032 implemented the dead-ref resolver but NOT the angle-bracket placeholder / literal-value sweep. Two cycles open; this cycle produced m-P-NEW-1 and m-P-NEW-2 as new instances of the unmitigated pattern. See **O-M1** above.
- **m-U-G word-count axis** — ICON-0033 fixed the line-cap (549 → 499); the 2,908-word body still violates the "aim for < 500 words" guidance at `writing-skills/SKILL.md:240`. See **m-U-net1**.
- **m-1 sub-item: `.mcp.json $schema`** — only `plugin.json` was fixed in ICON-0038. See **m-infra-1** + **O-V2**.
- **O-X3** (`disable-model-invocation: true` propagation to context-specialist-impl-* and detect-tree-position skills) — not implemented; remains low-priority defense-in-depth.
- **ADR-008 per-component overages** — `manager.agent.md` 50.8% and 9× common-constraints 45.5% are over the 40% per-component cap, acknowledged but not resolved. See **O-T1**.

### Net-new drift since ICON-0015 (~6 items)

1. **M-U-NET1** — `ecological-impact` ADR-004 violation (Copilot product framing in Option-A calculation path). Recurrence of the same root cause as ICON-0015 m-U-A on a different surface.
2. **m-A-NET-NEW-1** — `context-specialist.agent.md:2-6` 3-sentence description violates `agent-evaluation/SKILL.md:104` one-sentence sub-agent rule. ICON-0034 fixed the YAML form but missed the content axis; the CHANGELOG claim was inaccurate.
3. **m-A-NET-NEW-2 / m-A-NET-NEW-3** — `manager.agent.md:238` Discretionary heading parenthetical missing; `context-specialist.agent.md:84` "(where audit-write occurs)" contradicting the read-only audit-mode definition. Both first surfaced this cycle.
4. **m-P-NEW-1 / m-P-NEW-2 / m-P-NEW-3** — Two ICON-0036 sweep-incompleteness companions (m-P-NEW-1/2); one structural double-verification observation surfaced by ICON-0027's canonicalization (m-P-NEW-3).
5. **m-new-01 / m-new-02 / m-new-03** — `impl-root` Step 15 wrong filename; `upgrade-repo` Phase 1 stderr suppression in agent-invoked bash (ADR-007 scope); "plugin-lint Check A/B" undefined labels. All net-new structural observations.
6. **m-U-net2 + IO-CC-D1 + Internal-Skills-table gap** — `mcp-tools-first` discoverability gap as a unified pattern: missing frontmatter key, missing from `using-skills` Skill Priority, missing from README Internal Skills table.

Three structural items only first observable this cycle because they involve new-since-ICON-0015 surfaces: `m-U-net2` / `m-U-net4` (new skills `mcp-tools-first`, `plugin-design`), `m-U-net5` (renamed-not-created `icon-audit`), `m-infra-2` (new ICON-0044 invariant added to pre-commit), `m-infra-3` (new ICON-0044 invariant adjacent to existing release flow).

### Audit-process observation

This is the first audit cycle to run against the post-ICON-0033 token-economy regime with explicit caps (ADR-008), the post-ICON-0040 decisions-folder layout, and the post-ICON-0044 iconrc-version-bump enforcement. The audit infrastructure itself was renamed (plugin-audit → icon-audit, maintainer-only) in ICON-0042 and gained `synthesis-template.md` as a shared structural reference.

The dominant audit-process observation is that **the ICON-0015 → ICON-0046 close rate (essentially 100% of explicit Tier-2 + Tier-3 recommendations executed across 30 tasks in 7 days)** is unusually high for an audit-driven cycle. The risk of this high close-rate is the M-U-NET1 pattern: tasks that close the *literal* named in the audit may leave the *deeper structural cause* unaddressed. ICON-0037 fixed every utility-skill drift the prior audit named verbatim but did not investigate the root cause (Copilot product framing in a tool-agnostic plugin). The same pattern was named in retros across ICON-0036 (sweep-incompleteness), ICON-0040 (porting bugs), and ICON-0043 (ICON-internal logic carried into generic skills). The cross-cycle prescription is consistent: when fixing a literal, ask "what else does this root cause touch?" before declaring the sweep complete.

Secondary observation: the ICON-0015 → ICON-0046 baseline migration cost very little (Phase 1 Discovery returned a clean ICON-0015 audit report immediately resolvable from `.context/tasks/`, no path-translation table needed, the brief enumeration was current). The synthesis-template.md reference established by ICON-0042 worked exactly as intended — Brief 06's synthesis lens was clean, and the new Brief 07 was a one-time additive write (no need to retrofit the existing brief catalog).

---

## Plugin Decomposition Analysis (Per User Directive)

*Full analysis in `research/07-plugin-decomposition.md` (461 lines). This section consolidates the recommendation.*

The user asked: how might this plugin be split into 2+ composable plugins (software development, product management, agentic toolkit design, etc.), with some sub-plugins as extensions of ICON, some standalone, some composable?

### Current Coupling — Six Clusters

| Cluster | Member agents | Member skills (count) | Identity |
|---|---|---|---|
| **A** Software-development orchestration | manager, planner, architect, coder, tester, reviewer | task-plan + 5 phase-skills + 11 discipline/lifecycle skills (~17) | The workflow spine |
| **B** Product management | product-manager | jira-story, sprint-goals, post-meeting, rfc (4) | Story shaping & sprint comms |
| **C** Context initialization & maintenance | context-specialist, researcher | icon-init, 4 initialize-*, upgrade-repo, context-maintenance, 5 context-specialist-*, find-context-template, resolve-repo-context, create-iconrc, merge-phase-templates, context-document-guidelines + `context_template/` payload (~16) | `.context/` lifecycle |
| **D** Agentic toolkit / meta-tooling | (none) | writing-skills, agent-evaluation, plugin-design, invoke-sub-project-skill (4) | Plugin & skill authorship discipline |
| **E** Cross-cutting building blocks | (none) | using-skills, manager-routing-guide, mcp-tools-first, setup-mcp-servers, icon-status, ecological-impact + `shared/common-constraints.md` (6 + 1) | Shared scaffolding |
| **F** Maintainer-only (`.claude/skills/`) | (none) | icon-audit, release-plugin, changelog-entry (3) | ICON-internal tooling — out-of-scope per brief constraint |

**Heaviest cross-cluster edges:** A↔C (manager Session Start → `resolve-repo-context`; manager Task Completion → `task-retrospective` → `@context-specialist` mode:maintenance; `context_template/` ships `phase-*.md` workflow templates that A's task-plan skill reads at runtime). B→A is one-way (PM delegates to A's @researcher/@architect/@planner; A never invokes B). E is a pure sink (everything depends FROM E; E depends on nothing).

### Four Decomposition Candidates

| # | Proposal | Members | Type | Effort |
|---|----------|---------|------|--------|
| **P1** | Two-plugin split | `icon-dev` = A+C+D+E+F; `icon-pm` = B | dev standalone; pm extension | Low |
| **P2** ⭐ | Three-plugin split | `icon-dev` = A+D+E+F; `icon-pm` = B; `icon-context` = C | dev standalone; pm/context extensions | Medium |
| **P3** | Four-plugin split | + `icon-toolkit` = D (writing-skills, agent-evaluation, plugin-design) | Toolkit standalone-ish | Medium-high |
| **P4** | Core + composable-blocks | `icon-core` = E + minimal hook infra; `icon-sw`, `icon-pm`, `icon-context`, `icon-toolkit` as extensions | All extensions of core; requires new manifest dependency schema | High (non-starter today) |

### Recommended: P2 — Three-Plugin Split

`icon-dev` (Cluster A + D + E + F + `shared/common-constraints.md`) — "Multi-agent software development orchestration for Claude Code and Copilot CLI." Standalone.

`icon-pm` (Cluster B) — "Story shaping, sprint planning, and design-doc authoring. Requires `icon-dev` for delegation to @researcher/@architect/@planner." Extension.

`icon-context` (Cluster C + `context_template/` payload) — "Repo-context initialization, maintenance, and audit. Provides `@context-specialist` and `/icon-init` for any ICON-family plugin." Extension (with graceful degradation: `icon-dev` works standalone for simple repos without it).

**Why P2 beats alternatives:** P2 isolates the largest customization surface (`.context/` shape and the init flow) into a plugin that can evolve independently. The phase-*.md template ownership question is forced into explicit resolution rather than implicit. P1 hides the heaviest edge inside one plugin without resolving the phase-template ownership ambiguity. P3 adds D as a separate plugin but D has only one external consumer today (manager.agent.md:153 single-line reference), so the split is over-anticipation. P4 requires manifest dependency-schema machinery that does not exist in Claude Code / Copilot CLI plugin format today.

**Phased migration:** (1) ADR landing the decomposition target; (2) carve `icon-pm` out first (lightest cut); (3) resolve phase-template ownership (recommend moving phase-*.md to `icon-dev`; `icon-context` init reads from `icon-dev` at init time); (4) carve `icon-context` out; (5) reconcile cross-plugin tooling (pre-commit hook duplication, script-parity gate cross-plugin variant). Each phase is independently shippable; any phase can be the final resting state.

### Important Honest Caveat (from `research/07` Appendix)

**The audit findings in this cycle do not structurally compel a split today.** No Critical defects exist; one Moderate is a tool-agnostic-content cleanup; the rest are Minors and improvement opportunities. The heaviest cross-cluster edge (A↔C) is structurally sound. The cuts P2 forces (phase-template ownership, common-constraints duplication, cross-plugin sub-agent dispatch) are real coordination costs paid against benefits (audience clarity, customizable context init) that have no explicit user demand documented in any prior task or retro.

The dependency map and cuts above become load-bearing **if** a future task — a customer fork, a non-ICON consumer of `writing-skills`, a marketplace-level reorganization — demands the split. Until then, "no split" or "Phase 1 only" (land the ADR documenting the cluster boundaries, defer the carve) are both legitimate resting states.

### Compatibility & "ICON" Identity

The recommendation if a split happens: `datascan-marketplace` remains the umbrella, hosting `icon-dev`, `icon-pm`, `icon-context` as a "ICON Suite" group. No single plugin is literally named "ICON" (clean reset); the "ICON" wordmark survives as the suite name. Alternative: keep `ICON` as the `icon-dev` plugin name with the others as named extensions. Either is workable.

---

## Prioritized Fix Tiers

### Tier 1 — Fix immediately (correctness risk)

None. **No Critical defects; the plugin is shippable as-is.** The single Moderate (M-U-NET1 ecological-impact ADR-004 violation) is a degradation rather than a failure — Option B still works.

### Tier 2 — Short-term consolidation (defect cleanup + low-effort high-leverage)

- **O-T3 — Generalize `ecological-impact` to be runtime-agnostic.** Closes M-U-NET1. Low effort; the calculation core is already generic. Pairs with the description / README updates (O-D2/D3 in brief 06).
- **O-D1 — Add `mcp-tools-first` to `using-skills` Skill Priority + README Internal Skills table.** Closes the discoverability triple-gap (m-U-net2 + IO-U-3 + missing README entry). Single highest-leverage trivial fix this cycle.
- **O-S1 — Resolve verification-gate ownership** between manager Step 2 and retro Steps 6–7. Closes m-P-NEW-3.
- **O-V1 — Correct or clarify pre-commit hook header comment ordering.** Closes m-infra-2.
- **O-S6 — Fix `impl-root` Step 15 verify item 4 filename** from `patterns-template.md` to `patterns.md`. Closes m-new-01.
- **O-S2 — Replace "plugin-lint Check A/B" labels with plain rule citations.** Closes m-new-03.

### Tier 3 — Structural refactors (higher effort, higher payoff)

- **O-M1 — Extend `.githooks/pre-commit` with literal-grep gate (placeholder + version-literal sweep).** Closes O-V4 from ICON-0015 (two cycles open). The single highest-leverage structural fix available; addresses the 6-cycle sweep-incompleteness recurrence.
- **O-T1 — Address ADR-008 per-component overages on `manager.agent.md` + 9× common-constraints.** Either (a) principled content review of `manager.agent.md`, (b) split always-loaded surface by extracting Task Completion to on-demand, or (c) amend ADR-008 to reflect actual caps. Medium effort, high impact.
- **O-S7 — Add verification step to `context-specialist-impl-branch`.** Parity with `impl-leaf` and `impl-root`. Low effort.
- **O-M3 — Assign `.context/cache/` pruning ownership to `context-maintenance`.** Prevents unbounded cache growth in long-lived repos. Low effort.

### Tier 4 — Sweep-and-batch hygiene (low-impact carry-forwards)

The Tier 4 batch is a single hygiene PR closing the long-tail minors and Improvement Opportunities:

- O-S3 / O-S4 / O-S5 (context-specialist description trim, manager Discretionary parenthetical, audit-write parenthetical removal)
- O-S8 (phase-skill `Does NOT cover` footer completeness)
- O-T2 (task-plan-phase-completion measurable word cap)
- O-D2 / O-D3 / O-D4 (PM Turn Start, researcher web-tool platform notes, init-mapping cross-references)
- O-M2 (release-plugin Step 1 iconrc check)
- O-M4 (`mcp-tools-first` frontmatter `user-invocable` + `plugin-design` description self-contradiction)
- O-M5 (sprint-goals live URL → placeholder)
- O-V2 / O-V3 / O-V4 / O-V5 (`.mcp.json` $schema, hook readability comments, retro double-verification note, upgrade-repo Case 3 defensiveness)

### Tier 5 — New capabilities (forward-looking, per user directive)

- **Plugin Decomposition Phase 1 (P2 ADR-only).** If the user wants to document the cluster boundaries without committing to a carve, land `.context/decisions/011-plugin-decomposition.md` capturing the P2 target and cluster definitions. Zero behavior change; load-bearing if a future task demands the split. **Effort: trivial. Decision required: yes — see Open Question 1.**
- **Plugin Decomposition Phase 2 (P2 `icon-pm` carve).** If the user wants to act on the decomposition, carve `icon-pm` out first as the lightest cut (one agent + 4 skills, all explicitly not-routed-to by manager per `manager-routing-guide/SKILL.md:80`). **Effort: low. Decision required: yes — see Open Question 1.**

---

## Open Questions for the User

1. **Plugin decomposition: act, document, or defer?** The Plugin Decomposition Analysis recommends P2 (`icon-dev` + `icon-pm` + `icon-context`) **if** a split happens, but honestly notes that no current finding structurally compels it. **Pick one**: (a) **Act** — proceed with Phase 1 ADR + Phase 2 `icon-pm` carve as a Tier-5 follow-up; (b) **Document only** — land the ADR capturing cluster boundaries, defer the carve until external demand surfaces; (c) **Defer** — close this audit without an ADR; revisit when a customer fork or marketplace reorg makes the split load-bearing.

2. **M-U-NET1 (`ecological-impact` ADR-004 violation): fix as Tier 2 or bundle with decomposition Phase 4?** The brief 07 Phase-4 plan suggests `icon-context` carve-out is a natural moment to clean up runtime-coupling in adjacent skills. But if Q1 picks (b) or (c), no Phase 4 is coming. Recommend Tier 2 (fix now); the cleanup is low-effort and shouldn't wait on a structural decision.

3. **Tier 3 hook extension (O-M1) vs. Tier 4 hygiene PR sequencing.** O-M1 (`.githooks/pre-commit` literal-grep gate) closes the highest-recurrence pattern in the codebase but is medium-effort. The Tier 4 hygiene PR is low-effort but addresses ~12 minors. **Pick one**: (a) Hook extension first (mechanical prevention beats one-time cleanup); (b) Hygiene PR first (close the visible-defect surface, then build prevention); (c) Both in parallel branches.

4. **ADR-008 per-component overage resolution (O-T1).** Three options: (a) trim `manager.agent.md` (medium effort, surgical content review); (b) extract Task Completion section to on-demand companion file (medium effort, larger structural change); (c) amend ADR-008 to acknowledge actual caps (trivial, but explicit policy shift). **Pick one**, or defer pending next major manager-agent surface change.

5. **`writing-skills` word-count axis (m-U-net1) — clarify or close?** 2,908 words against an "aim for < 500 words" guidance that may be aspirational rather than load-bearing. **Pick one**: (a) Trim to < 500 words (heavy lift; the body is dense discipline content); (b) Reframe `:240` rule to distinguish "frequently-loaded skills" (< 500 words) from "complex discipline skills" (no fixed cap, "earn every line"); (c) Accept the violation and document; (d) ADR-008 amendment defining per-skill-type caps.

6. **Pre-commit hook header invariant ordering (m-infra-2) — minor cosmetic fix or signal of larger pattern?** The header claims script-execution order but doesn't match what shipped. Trivial to fix, but the same retro that introduced it (ICON-0044) explicitly warned against this pattern. **Pick one**: (a) Fix the comment (trivial); (b) Fix and add a self-check (post-edit grep that the comment numbering matches actual block order — bigger investment).

---

## Suggested Follow-up Tasks

Each task below is independent and can be triaged by priority and available bandwidth. **Per the audit's data-exfiltration constraint, the task-ID slots are local recommendations — please confirm before filing as GitLab issues.**

- **ICON-0047 — `ecological-impact` runtime-agnostic rewrite (Tier 2).** Closes M-U-NET1. Reframe Option-A as platform-neutral; add Claude Code-specific sub-option; replace Copilot product literals in output template + description + README echo. Low effort; medium-high impact.

- **ICON-0048 — `mcp-tools-first` discoverability triple-gap (Tier 2).** Add `user-invocable: false` to frontmatter; add to `using-skills/SKILL.md:69-76` Skill Priority; add to `README.md:176-209` Internal Skills table. Closes m-U-net2 + IO-CC-D1 + README gap. Trivial effort; highest-leverage trivial fix this cycle.

- **ICON-0049 — Verification-gate ownership canonicalization (Tier 2).** Closes m-P-NEW-3. Pick Option (a) from O-S1 — remove `verification-checklist` Steps 6–7 from `task-retrospective` and document that manager Step 2 is the canonical gate. One-line note in retro covers the standalone-invocation case.

- **ICON-0050 — Net-new Minor sweep PR (Tier 2 + Tier 4 combined).** Bundles ~12 trivial-effort closures: O-S3 (context-specialist description), O-S4 (manager Discretionary parenthetical), O-S5 (audit-write parenthetical), O-S6 (impl-root verify filename), O-S2 (plugin-lint Check A/B labels), O-S8 (phase-skill footer completeness), O-V1 (hook header numbering), O-M2 (release-plugin iconrc check), O-M5 (sprint-goals URL placeholder), m-P-NEW-1/2 (cap-value prose sweep), O-V3 (hook readability comments). Low effort; closes ~11 of 17 Minors.

- **ICON-0051 — `.githooks/pre-commit` literal-grep gate extension (Tier 3).** Closes O-V4 placeholder-grep sub-item from ICON-0015 (two cycles open). Implements IO-CC-M1 / O-M1: angle-bracket placeholder grep + literal-value sweep for cap/version constants. The single highest-leverage structural fix.

- **ICON-0052 — ADR-008 per-component overage resolution (Tier 3).** Pick from O-T1 options (a/b/c); execute. Medium effort. Pairs with any future manager-agent surface change.

- **ICON-0053 — Plugin decomposition ADR + `icon-pm` carve (Tier 5, conditional on Q1).** Phase 1 + Phase 2 from the Plugin Decomposition Analysis recommendation. Land ADR-011 (cluster boundaries, P2 target, deferred-carve rationale); carve `icon-pm` as the lightest cut if user picks Q1(a). Low effort for Phase 1; ~3-5 days for Phase 2.

- **ICON-0054 — `.context/cache/` pruning ownership (Tier 3).** Closes O-M3 / IO-CC-V1 / IO-A-3. Assign pruning to `context-maintenance`; one-line scope addition + implementation rule.

- **ICON-0055 — `writing-skills` word-count axis decision (depends on Q5).** Reframe rule, amend ADR, or trim body. Defer pending Q5.

- **ICON-0056 — `impl-branch` parity verification step (Tier 3).** Closes O-S7. One-step addition matching `impl-leaf` and `impl-root`.

---

*Audit complete. Output artifacts: `plan.md`, `briefs-07-plugin-decomposition.md`, `research/01-agents.md` through `research/07-plugin-decomposition.md`, and this `audit-report.md`.*
