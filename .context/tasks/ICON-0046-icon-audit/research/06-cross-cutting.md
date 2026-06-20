# Cross-Cutting Audit — Raw Findings

## Summary

The ICON plugin enters this audit cycle in its strongest cross-cutting shape since ICON-0003. Both of the ICON-0015 Moderate cross-cutting findings (M-CC-NET1 doc-drift and M-CC-NET3 dead `three-layer-enforcement.md` reference) are confirmed fixed on disk, as are M-CC-NET2 (retrospectives write-path contradiction) and M-I-A (merge-phase-templates missing testing row). The token surface remains within ADR-008 bounds — manager session is at 8,251 words (97% of the 8,500 cap), PM at 6,597 (94% of 7,000), with per-component overages on `manager.agent.md` (50.8% vs. the 40% cap) and 9×common-constraints (45.4% vs. 40% cap for PM) both carried forward from ICON-0033 as known-accepted overages. No new Critical or Moderate cross-cutting defects are found in this cycle.

The net-new cross-cutting findings are Minor and fall into three classes: (1) a stale cap value propagating across two prose files after the ICON-0036/0041 cap-reduction sweep (domain findings m-P-NEW-1/2, synthesized here as a recurring sweep-incompleteness pattern), (2) an ADR-004 violation in `ecological-impact` that leaves the skill's primary calculation path inoperable for Claude Code consumers (domain finding M-U-NET1, elevated to cross-cutting because the same runtime-coupling drift was previously identified in m-U-A and partially fixed — the current finding is a recurrence of the same root cause on a different surface), and (3) a discoverability gap where `mcp-tools-first` is absent from the `using-skills` Skill Priority list, leaving an auto-invocation-only skill without any explicit catalog mention (domain findings m-U-net2, IO-U-3). The Retrospective Pattern Analysis shows the sweep-incompleteness class (now ICON-0003 through ICON-0046, six audit cycles of evidence) is still the single most reliable recurrence vector, with two specific new instances this cycle. The discoverability surface has materially improved: the README skills table is accurate and organized, `using-skills` has a phase-chain example (added ICON-0034), and the internal skills section separates user-facing from internal. The one structural discoverability gap is `mcp-tools-first` missing from the Skill Priority ordering in `using-skills/SKILL.md:69-76`.

---

## Defect Findings

### Critical

None observed.

### Moderate

None observed as purely cross-cutting. M-U-NET1 (`ecological-impact` ADR-004 violation) has cross-cutting character — a pattern of Copilot-product framing surviving ADR-004 despite partial prior-cycle fixes — but the primary finding is in domain 04 (see 04-utility-skills § M-U-NET1). Cross-cutting synthesis notes it represents the third instance of runtime-coupling residue on the `ecological-impact` skill (m-U-A in ICON-0015 addressed model names; the deeper Copilot UI framing was not addressed). See m-CC-NET-NEW-1 below.

### Minor

**m-CC-NET-NEW-1 — Runtime-coupling pattern survives partial prior-cycle fixes in `ecological-impact`**

- Location: `skills/ecological-impact/SKILL.md:43-74` (Option A calculation path), `:148-149` (output template), `:199` ("Remaining Reqs counter")
- Finding: The ICON-0015 domain finding m-U-A fixed the stale model name at `:86` and `:221`. That fix was correct but left the deeper runtime-specific UI framing untouched. The ICON-0046 audit (see 04-utility-skills § M-U-NET1) finds the Copilot-product framing is now a Moderate ADR-004 violation: "Remaining Reqs", "GitHub Copilot Business plan" quota table, and "Copilot Ecological Impact Report" header are all Copilot-only concepts. This is the third audit cycle touching the same skill with the same root cause (Copilot-specific framing in a tool-agnostic plugin): ICON-0015 m-U-A, current M-U-NET1. The cross-cutting synthesis flags this as a class-level pattern: partial sweeps that address the most obvious literal (model name, tool verb) without investigating the skill's calculation path leave the deeper coupling intact.
- ADR check: ADR-004 mandates tool-agnostic content. ADR-010 m9 covers DataScan-flavored _examples_ as accepted; Copilot-specific UI framing in the primary calculation path is not covered by that acceptance.
- Classification: Minor (cross-cutting / pattern observation; the primary defect finding is domain 04 M-U-NET1).

**m-CC-NET-NEW-2 — Sweep-incompleteness pattern persists: two new instances this cycle**

- Location (instance 1): `skills/task-plan-phase-completion/agent-vs-skill-invocation.md:23` (domain finding m-P-NEW-1)
- Location (instance 2): `skills/context-maintenance/append-retrospective-entry.md:3` and `:32` (domain finding m-P-NEW-2)
- Finding: The ICON-0036 cap-reduction sweep updated six files across four directories. Two companion prose files — `agent-vs-skill-invocation.md` and `append-retrospective-entry.md` — were outside the sweep's enumeration and were missed. Both still read "15" or describe the pre-ICON-0041 single-prune behavior. This is the same class named in ICON-0015 ("sweep-incompleteness: companion files not in the original scope") and traced in the retrospective to ICON-0003, ICON-0004, ICON-0007, ICON-0008, ICON-0011, ICON-0014, ICON-0036, and now ICON-0046. The O-V4 recommendation from ICON-0015 (extend `.githooks/pre-commit` with a literal-grep for unfilled angle-bracket placeholders and known literal values) was not implemented. See Retrospective Pattern Analysis § Pattern A.
- ADR check: ADR-010 does not protect these values; ADR-007 and ADR-009 do not apply.
- Classification: Minor (cross-cutting pattern; primary domain findings are process-skills m-P-NEW-1 and m-P-NEW-2).

---

## Improvement Opportunities

### Token Efficiency

**IO-CC-T1 — ADR-008 per-component cap overages: `manager.agent.md` at 50.8% and 9×common-constraints at 45.4% of PM budget**

- Location: `agents/manager.agent.md` (4,322 words); `shared/common-constraints.md` (354 words × 9 = 3,186 words in PM session)
- Current manager session total: 8,251 words (97.1% of ADR-008 cap 8,500). Current PM session total: 6,597 words (94.2% of ADR-008 cap 7,000). Delta from ICON-0033 baseline: manager +189 words, PM +33 words. Both are within the 5%-of-cap re-audit trigger (≥425 words manager; ≥350 words PM).
- Both per-component overages were acknowledged at ADR-008 adoption as known overages pending a next token-economy audit cycle. That cycle has not occurred. With the manager session at 97.1% of cap (2.9% headroom = ~247 words), the next substantial addition to `manager.agent.md` or `using-skills/SKILL.md` will breach the session cap without a re-audit trigger firing first. The 40% per-component cap is breached on both the most complex and most-inlined components.
- Effort: Medium (reducing `manager.agent.md` requires principled content review). Impact: High (prevents crossing the ADR-008 cap silently on the next substantive edit).

**IO-CC-T2 — `task-plan-phase-completion/SKILL.md` is the largest phase skill at 832 words, contradicting its self-described "minimal" aspiration without a measurable bound**

- Location: `skills/task-plan-phase-completion/SKILL.md:12-13` (see 02-process-skills § IO-P-3)
- The completion skill is 832 words — larger than all four sibling phase skills (investigation: 720, testing: 552, implementation: 487, architecture: 439). The "Keep this skill minimal. It loads at the end of every task; token cost matters" self-description has no enforced ceiling. This is a forward-looking concern tied to the ADR-008 adjacent-on-demand budget, not the always-loaded budget.
- Effort: Trivial (add a target comment or remove the aspirational claim). Impact: Low.

### Discoverability

**IO-CC-D1 — `mcp-tools-first` is absent from `using-skills/SKILL.md:69-76` Skill Priority list, leaving auto-invocation as the sole discovery mechanism**

- Location: `skills/using-skills/SKILL.md:69-76` (Skill Priority section — `mcp-tools-first` not mentioned); `skills/mcp-tools-first/SKILL.md:1-9` (no `user-invocable` key, see 04-utility-skills § m-U-net2)
- `using-skills` names four skill categories in its Skill Priority ordering but does not reference `mcp-tools-first`. The skill is auto-invoked by description match, but ICON-0045's retrospective documents a live failure case where an agent "confirmed `gitlab-create_merge_request` exists via tool search, then ran `which glab` to fall back to a CLI" — i.e., description-match auto-invocation did not prevent the fallback because the agent rationalized out of the MCP path under schema-unknown pressure. A one-line addition to the Process skills priority row — "For GitLab/Jira/Confluence access, ensure `mcp-tools-first` has been consulted before any external tool call" — would provide the catalog reference that survives rationalization pressure. See also 04-utility-skills § IO-U-3.
- Effort: Trivial. Impact: Medium (closes the discovery gap ICON-0045 addressed at the skill body level but not at the catalog level).

**IO-CC-D2 — `ecological-impact` skill description still says "Copilot session" in a tool-agnostic catalog**

- Location: `skills/ecological-impact/SKILL.md:4` (description: "Calculate and display the environmental footprint of a Copilot session")
- The description is the first thing loaded in any skill-catalog scan. The "Copilot session" phrasing makes Claude Code users self-deselect the skill before reading its body, where Option B (session-only) actually works for any runtime. Changing "Copilot session" to "AI session" in the description would not fix the Moderate body-level violation (M-U-NET1) but would improve the skill's discoverability for Claude Code users.
- Effort: Trivial. Impact: Low-Medium (pairs with IO-U-1 from domain 04).

**IO-CC-D3 — README `ecological-impact` skill description says "Copilot session" in the user-facing skills table**

- Location: `README.md:159` ("Calculate and display the environmental footprint of a Copilot session in Trees Burned and water-usage equivalents, with annual projections")
- The skills table entry echoes the SKILL.md description verbatim. A new installer reading the README table will see "Copilot session" and understand the skill as Copilot-only. This is the user-facing manifestation of the same ADR-004 gap.
- Effort: Trivial. Impact: Low.

### Consolidation

**IO-CC-C1 — "plugin-lint Check A/B" labels are referenced in two skills with no discoverable formal definition**

- Location: `skills/icon-init/SKILL.md:225,245`; `skills/icon-status/SKILL.md:214` (see 03-context-specialist-init § m-new-03 and IO-04)
- These labels imply a formal numbered check catalog that does not exist. The underlying rules are already enforced by `shared/common-constraints.md` and the pre-commit hook; the labels add an appearance of formality that misleads skill authors and auditors. Option (b) from IO-04 — replace with plain rule citations — eliminates the ghost catalog.
- Effort: Trivial. Impact: Low.

**IO-CC-C2 — Verification-gate ownership split between `manager.agent.md` Task Completion Step 2 and `task-retrospective` Steps 6–7 creates silent double-verification**

- Location: `agents/manager.agent.md:201`; `skills/task-retrospective/SKILL.md:129-130` (see 02-process-skills § m-P-NEW-3 and IO-P-4)
- Every task close invokes `verification-checklist` twice: once before the retrospective (manager Step 2) and again inside the retrospective (retro Steps 6–7). The duplication is not documented as intentional, creating agent confusion about which invocation is the primary gate. A one-line clarifying note in the retrospective's Completion Gates section would make the redundancy explicit and optional for the within-manager-workflow case.
- Effort: Trivial. Impact: Low-Medium.

### Missing Skills / Workflow Gaps

**IO-CC-M1 — Implement O-V4 from ICON-0015: extend `.githooks/pre-commit` with a literal-grep for unfilled placeholders and known stale literal values**

- Location: `.githooks/pre-commit` (add a new invariant block); primary recommendation O-V4 from `ICON-0015 audit-report.md:199` (two cycles open)
- Pattern A from the Retrospective Pattern Analysis (see below) has now fired in six audit cycles: ICON-0003, ICON-0007, ICON-0008, ICON-0011, ICON-0036, and ICON-0046. In ICON-0046 it produced two net-new findings (m-P-NEW-1 and m-P-NEW-2). The O-V4 ICON-0015 recommendation — a pre-commit grep for angle-bracket placeholders and known literal values — was not implemented. A two-phase hook block would: (1) grep staged `skills/` and `agents/` files for unresolved `<…>` angle-bracket placeholders (catches M-U-A class); (2) grep staged files for newly introduced cap/version literals that also appear in `scripts/` files as `ENTRY_CAP=N` constants (catches m-P-NEW-1/2 class). The ICON-0036 retro already describes the exact `grep -rnE` invocation; the hook invariant would encode it mechanically.
- Effort: Low. Impact: High (closes the single highest-recurrence vector in the entire codebase across six audit cycles).

### Self-Verification

**IO-CC-V1 — Add `context-maintenance` cache-pruning ownership for `researcher.agent.md` stale cache files**

- Location: `agents/researcher.agent.md:26` (writes date-stamped cache files); `skills/context-maintenance/SKILL.md` (does not audit the `cache/` directory — see 01-agents § IO-A-3)
- The researcher writes `.context/cache/` files with date slugs but has no instruction to prune stale ones. `context-maintenance` does not audit `cache/`. Files accumulate without bound. A one-line addition to `context-maintenance/SKILL.md`'s scope section — "Prune `.context/cache/` entries older than 30 days" — assigns ownership and provides the housekeeping trigger.
- Effort: Low. Impact: Medium (prevents unbounded cache accumulation in long-lived repos).

---

## Token Economics Analysis

### Always-Loaded Surface (ADR-008 inventory)

**Manager session (as of this audit):**

| Component | Words | % of cap |
|-----------|------:|--------:|
| `agents/manager.agent.md` | 4,322 | 50.8% (cap: 40%) |
| 9 × `shared/common-constraints.md` | 3,186 | 37.5% |
| `skills/using-skills/SKILL.md` | 743 | 8.7% |
| **Manager session total** | **8,251** | **97.1% of 8,500** |

**PM session (as of this audit):**

| Component | Words | % of cap |
|-----------|------:|--------:|
| `agents/product-manager.agent.md` | 2,668 | 38.1% |
| 9 × `shared/common-constraints.md` | 3,186 | 45.5% (cap: 40%) |
| `skills/using-skills/SKILL.md` | 743 | 10.6% |
| **PM session total** | **6,597** | **94.2% of 7,000** |

**Movement from ICON-0033 baseline:** Manager +189 words (+2.3%); PM +33 words (+0.5%). Both are below the 5%-of-cap re-audit trigger (≥425 manager, ≥350 PM). The ICON-0041 `mcp-tools-first` addition added zero always-loaded words (on-demand skill). The ICON-0045 hardening of `mcp-tools-first` was also on-demand.

**Per-component cap status:** `manager.agent.md` is at 50.8% of the manager budget — 10.8 points over the 40% cap. The 9×common-constraints block is at 45.5% of the PM budget — 5.5 points over. Both were acknowledged at ADR-008 adoption and are currently "known overage / next-tier candidate." The manager session's 2.9% headroom (≈247 words) is the tightest it has been since the ADR-008 baseline was established.

**Highest-impact trim candidates:**

1. `agents/manager.agent.md` (4,322 words, 50.8% of session): the single largest trim opportunity. Previous cycles identified common-constraints inlining and AR tables as out-of-scope per ADR-004. What remains: any structural sections that have grown since ICON-0033 (delta: the `mcp-tools-first` skip block in session start, the Task ID Source rule and AR row added in ICON-0042). These additions are defensible individually; collectively they push the agent from 4,148 (ICON-0033 baseline) to 4,322 words (+174).

2. Common-constraints inlining (3,186 words in PM session, 45.5% of cap): structural. ADR-004 policy-accepted. Not a viable trim without an ADR revision.

3. `skills/using-skills/SKILL.md` (743 words): minor. The rationalization-prevention table and red-flags section are load-bearing discipline content.

**Adjacent on-demand (high-frequency) surface:**

| Skill | Words | Notes |
|-------|------:|-------|
| `task-plan-phase-completion` | 832 | Largest phase skill |
| `task-plan-phase-investigation` | 720 | — |
| `task-plan-phase-testing` | 552 | — |
| `task-plan-phase-implementation` | 487 | — |
| `task-plan-phase-architecture` | 439 | — |
| `writing-skills/SKILL.md` | 2,908 | 6× its own "aim for < 500 words" guidance |
| `ecological-impact/SKILL.md` | 1,774 | 634-word Option B calculation; 1,140 words on Copilot-specific Option A |
| `mcp-tools-first/SKILL.md` | 634 | Up from 15-line original; ICON-0045 hardening added ~580 words |

---

## Discoverability UX Analysis

### README Skills Table

**Structure:** The README at `README.md:149-209` presents a two-tier skills table: 23 user-facing skills listed alphabetically in the main section, followed by 22 internal skills in a "Internal Skills" sub-section. This split was not present in ICON-0015 (the prior audit noted the mixing of user-facing and internal skills). The current layout is materially better.

**Accuracy check (user-facing table):**

- `ecological-impact` description (`README.md:159`) says "Copilot session" — see IO-CC-D3 above.
- All other user-facing rows are accurate and current. No internal skills leaked into the user-facing table. No user-facing skills missing from the table.
- `mcp-tools-first` is correctly absent from the README user-facing table (it is auto-invoked, not user-invocable). But it is also absent from the Internal Skills table (`README.md:176-209`). This is a structural gap: every other auto-invoked internal skill appears in the Internal Skills table; `mcp-tools-first` is the only one absent. The ICON-0042 task that removed `plugin-audit` from the skills table correctly removed it as now-maintainer-only; no equivalent addition of `mcp-tools-first` occurred.

  - Location: `README.md:176-209` (Internal Skills table — `mcp-tools-first` absent)
  - The description at `skills/mcp-tools-first/SKILL.md:3-8` ("fires when an agent is about to access GitLab, Jira, or Confluence") is precisely the kind of "Internal: auto-invoked on description match" signal that belongs in this table.

**`using-skills` Skill Priority chain:**

`skills/using-skills/SKILL.md:69-76` defines a four-category Skill Priority ordering. The task-plan phase chain example was added in ICON-0034 (confirmed at `:77`). The `mcp-tools-first` skill is not mentioned in any category. This is the single actionable discoverability gap in the current `using-skills` structure (see IO-CC-D1).

**Onboarding flow:**

The README `## What do you want to do?` intent index at `README.md:35-49` is well-structured and accurate — nine intent rows covering install, new repo, returning user, upgrade, MCP setup, role switch, and skill authoring. No stale entries found. The "I want to set up GitLab/Jira MCP credentials" row correctly points to `setup-mcp-servers`. The row for "I want `@manager` to be my default role" correctly describes the post-ICON-0012 plugin-scoped hook model.

**Design Principles block:**

`README.md:23-31` — all six principles are accurate and current. The "Legacy repos that haven't migrated can still use `.github/copilot-instructions.md`" note at `:27` correctly uses "haven't migrated" (post-ICON-0037 language normalization). Confirmed no "if not yet migrated" or "Starting with ICON 1.16" phrasing remains — both ICON-0015 M-CC-NET1 items are confirmed fixed.

---

## Retrospective Pattern Analysis

The retrospectives log covers ICON-0036 through ICON-0045 (10 entries as of this audit, cap=10). Relevant cross-cycle patterns:

### Pattern A — Sweep-incompleteness: companion files missed when a literal value changes (≥6 audit cycles)

**Evidence across the log:**
- ICON-0036 retro: "Lesson: for any audit-derived task whose payload is a literal-value sweep … run `grep -rnE` for the literal across `.context/ context_template/ skills/` BEFORE dispatching — trust the repo, not the issue body's enumeration." → ICON-0036 sweep itself missed two companion files (`agent-vs-skill-invocation.md:23` and `append-retrospective-entry.md:3,:32`), producing m-P-NEW-1 and m-P-NEW-2 in ICON-0046.
- ICON-0037 retro: "Pre-flight Explore exact-phrase-only grep missed semantically-equivalent variants … must grep for both the exact target AND semantically-equivalent variants."
- ICON-0038 retro: "Pre-flight Explore with citation-drift detection — 6th broad-axis instance."
- ICON-0042 retro: "Sweep scoped to consumer-facing surfaces … missed `.context/domains/skill-system.md`, `.context/standards/skill-decomposition.md` … evergreen `.context/` content that re-reads as current state."
- ICON-0015 audit-report.md: "the retrospective-pattern analysis shows the sweep-incompleteness class … has appeared in ICON-0003, ICON-0004, ICON-0007, ICON-0008, ICON-0011, and ICON-0014."

**Frequency:** ≥6 audit cycles (ICON-0003, ICON-0004, ICON-0007, ICON-0008, ICON-0011, ICON-0014 per ICON-0015; plus ICON-0036 sweep that produced new instances in ICON-0046).

**Current-cycle instances:** m-P-NEW-1 (`agent-vs-skill-invocation.md:23` "keep-last-15") and m-P-NEW-2 (`append-retrospective-entry.md:3,:32` "last 15 entries" / single-prune description).

**Evaluation:** This pattern has appeared in more than six audit cycles, meets the "3+ retrospective entries" threshold definitively, and already has an accepted mitigation recommendation (O-V4 from ICON-0015, open for two cycles). A mechanical hook gate is the warranted intervention; editorial rule reminders in the retrospective have not broken the recurrence.

**Recommendation:** Implement IO-CC-M1 (pre-commit literal-grep gate). This is the single highest-leverage structural fix available.

### Pattern B — YAGNI violation: skills authored with anticipated-problem anti-patterns before field failures are observed (3 retrospective entries)

**Evidence:**
- ICON-0041 retro: "Default-reasoning the cross-cutting MCP-awareness rule into `shared/common-constraints.md` without weighing the 9× always-loaded multiplier … skill bodies should follow YAGNI — start with the minimum the agent needs … add anti-patterns / discipline tables ONLY after observing the lean version failing."
- ICON-0045 retro: "a thin auto-invocation skill that names triggers but does not pre-empt the parameter-discovery gap leaves the dominant failure mechanism unaddressed" — acknowledging that the ICON-0041 lean-by-YAGNI skill was too lean and needed ICON-0045 hardening.
- ICON-0043 retro: "Opus authored 11 files in one shot … and hit the lean YAGNI bar cleanly — no preemptive anti-patterns tables, no rationalization-prevention sections, sizes well under the 16 KB Folder Split threshold." (positive YAGNI instance)

**Pattern:** Three retrospective entries address the YAGNI tension. The pattern has two sub-types: (B1) over-anticipation (ICON-0041 first draft) — authoring discipline tables before observing failures, inflating always-on context; (B2) under-anticipation (ICON-0041/ICON-0045 pair) — starting too lean, requiring a hardening cycle when the field failure appears. The retros have converged on a rule: "start minimal; harden on observed failure (conversation log as RED phase)." No new skill or standard is needed — the rule is well-articulated. Retro-only at this cycle.

### Pattern C — Porting-introduces-bugs-that-original-didn't-have (3 retrospective entries)

**Evidence:**
- ICON-0040 retro: "First-pass coder shell migration combined `match($0, /regex/, arr)` (3-arg gawk extension) with `printf -v <var>` (bash builtin) inside an awk block — both silently fail on mawk."
- ICON-0043 retro: "the dead-ref resolver carried ICON's internal `context_template/context/<rest>` path mapping verbatim into a skill that's supposed to audit OTHER plugins (where `.context/` lives at the plugin root) … when authoring NEW generic content that mirrors existing ICON-internal logic, walk through every constant / path / regex flag explicitly."
- ICON-0038 retro: "`printf '%03d'`-padded semver comparison … worked for typical version pairs but had an implicit ceiling at patch=999."

**Pattern:** Three retros describe bugs introduced by porting (bash→PowerShell, ICON-internal→generic, comparison-algorithm) where the original had no equivalent defect. The `.context/standards/shell-portability.md` file was created in ICON-0040 for the mawk case. The generic-port case (ICON-0043) and the arithmetic-boundary case (ICON-0038) are first-occurrence retro-only. The pattern has the three-entry threshold but is not clearly actionable beyond the existing shell-portability standard. The ICON-0043 guidance ("walk through every constant/path/regex flag and ask 'does this assume ICON-internal layout?'") is a good candidate for promotion to a "Porting Checklist" standard if a fourth instance appears.

---

## ICON-0015 Delta

### Fixed since ICON-0015

| ICON-0015 ID | Description | Evidence |
|---|---|---|
| M-CC-NET1 | User-facing doc-drift on `README.md`, `.claude/claude.md`, `commands/enable-/disable-manager-default.md` — pre-ICON-0012 hook architecture | ICON-0031; `README.md:94-104` now describes plugin-scoped `hooks/hooks.json` + `~/.claude/icon-user-settings.json` model. No "two inject scripts" language. `commands/ICON:enable-manager-default.md` and `commands/ICON:disable-manager-default.md` no longer say "Starting with ICON 1.16." CHANGELOG 1.17.0 Fixed entry confirms. |
| M-CC-NET2 / M-P-B | `retrospectives.md` write-path "Known unresolved" contradiction | ICON-0027; `manager.agent.md:203-204` and `task-retrospective/SKILL.md:103-125` now agree on two-stage flow. `agent-vs-skill-invocation.md` has no "Known unresolved" block. See 01-agents and 02-process-skills delta sections. |
| M-CC-NET3 / M-A-NET1 | `manager.agent.md:151` dead `three-layer-enforcement.md` reference | ICON-0028; grep confirms no `three-layer-enforcement` reference in any agents file. `manager.agent.md:152` now reads the self-sufficient three-layer rule inline. See 01-agents delta. |
| M-I-A | `merge-phase-templates` Step 2 routing table missing `phase-testing.md` | ICON-0029; `skills/merge-phase-templates/SKILL.md:45` now has the testing row. See 03-context-specialist-init delta. |
| M-U-A | All six `plugin-audit` briefs with unfilled `<path-to-prior-audit-report.md>` placeholder | ICON-0030; briefs now contain a `find`-based discovery command. See 04-utility-skills delta. |
| m-CC-1 | `README.md:27` "if not yet migrated" qualifier | ICON-0037; `README.md:27` now reads "on repos still on the legacy path" per the post-ICON-0037 language normalization sweep. |
| m-CC-2 | `using-skills/SKILL.md:64-68` Skill Priority example lacked the task-plan phase chain | ICON-0034; `using-skills/SKILL.md:77` now has the `task-plan → task-plan-phase-* → task-retrospective` example. |
| O-T1 | Formal always-loaded token-budget audit (two cycles open at ICON-0015) | ICON-0033; ADR-008 established with 8,500/7,000 word caps, per-component 40% ceiling, 5%-of-cap re-audit trigger, and `ICON-0033-token-economy-trims/word-count-snapshot.md` as the ADR-008 effective baseline. |
| O-T2 | Reviewer Default-tier redundant category list | ICON-0033; `reviewer.agent.md:69` now reads "Review against all six categories defined in the `code-quality-rules` skill." |
| O-T3 | 5× phase-skill template-override paragraphs | ICON-0033; all five now carry a byte-identical one-line pointer to `task-plan/SKILL.md:39-49`. |
| O-T4 | `writing-skills` exceeds its own 500-line cap | ICON-0033; 549 → 499 lines. Line-cap axis closed. Word-count axis open — see m-U-net1 in 04-utility-skills. |
| O-D1 | `using-skills` lacked task-plan phase chain example | ICON-0034; added at `using-skills/SKILL.md:77`. (Also closes m-CC-2 above.) |
| O-D2 | Sweep README/`.claude/claude.md` for post-ICON-0012 hook architecture | ICON-0031; confirmed. (Also closes M-CC-NET1 above.) |
| O-D3 | PM Session Start parity with manager | ICON-0034; `product-manager.agent.md:12` `## Session Start` before `## When to Invoke`; step 2 has common-constraints acknowledgement. |
| O-D4 | `mr-discipline` cue missing from all agents | ICON-0034; `manager.agent.md:207` now has "Apply the `mr-discipline` skill before drafting the description." |
| O-S1 | Resolve `manager.agent.md:151` dead reference | ICON-0028; confirmed fixed (see M-CC-NET3 above). |
| O-S2 | Add `phase-testing.md` to `merge-phase-templates` routing table | ICON-0029; confirmed. (Also closes M-I-A above.) |
| O-S3 | Base-template-promotion review (generalizable local content) | ICON-0039; ADR-010 Part A confirms one promotion (phase-completion append-script note). Template version bumped 1.3→1.4. |
| O-S4 | Canonicalize retrospectives write path | ICON-0027; confirmed. (Also closes M-CC-NET2 above.) |
| O-S5 | Single-source init-orchestrator entry-point detection block (6 copies) | ICON-0022; all three orchestrators now reference `context-specialist-detect-tree-position/SKILL.md` § "Entry-Point Detection Primitive (callable)" rather than inlining. |
| O-S6 | Extract Phase 3 drift-trigger sampling spec into `upgrade-repo` | ICON-0035; canonical spec inline at `skills/upgrade-repo/SKILL.md:586-588`; orchestrators cross-reference. |
| O-S7/O-S8 | Phase-skill "Does NOT cover" footer terminology + `initialize-workspace` MR template | ICON-0036 (footers); ICON-0035 (MR template). |
| O-V1 | Replace `<path-to-prior-audit-report.md>` placeholder in all six briefs | ICON-0030; discovery command present in all six briefs. (Also closes M-U-A above.) |
| O-V2 | Extend pre-commit with script-parity gate for `append-retrospective-entry.{sh,ps1}` | ICON-0032; gate confirmed at `.githooks/pre-commit:393-443`. All six copies byte-identical. |
| O-V4 (partial) | Extend pre-commit with dead-ref resolver | ICON-0032; gate confirmed at `.githooks/pre-commit:445-532`. The _placeholder-grep_ sub-item of O-V4 was not implemented — see IO-CC-M1 below. |
| O-M1 | `release-plugin` Step 1 doc-sweep reminder | ICON-0038; confirmed at `skills/release-plugin/SKILL.md:40`. |
| O-M2 | `icon-status` `/release-plugin` suggestion policy | ICON-0038; suggestion removed. |
| O-M3 | `plugin.json` LICENSE claim without LICENSE file | ICON-0038; `"license"` field removed. |
| O-M4 | `bump-versions.sh` dry-run + monotonicity check | ICON-0038; confirmed at `bump-versions.sh:24-92`. |
| O-X2 | Re-tier third- and fourth-cycle carry-forwards | ICON-0039; ADR-010 Part B establishes the registry with m1 and m9 as "Accepted (watch)." |
| O-X3 | `disable-model-invocation: true` propagation to context-specialist-impl-* | Deferred or declined — not found on disk. Still open as low-priority. |

### Still present or partial

| ID | Current state |
|----|--------------|
| O-V4 (placeholder-grep sub-item) | The dead-ref resolver was implemented in ICON-0032 (`.githooks/pre-commit:445-532`). The _angle-bracket-placeholder grep_ and _literal-value sweep_ sub-items were not. Two cycles open. See IO-CC-M1. |
| m-U-G (word-count axis) | `writing-skills/SKILL.md` 2,908 words vs. "aim for < 500 words" guidance at `:240`. Line-cap axis closed by ICON-0033; word-count axis open. See 04-utility-skills § m-U-net1. |
| m9 (ADR-010 accepted) | DataScan-flavored examples in `sprint-goals`, `jira-story` — Accepted (watch) per ADR-010. The live `onedatascan.atlassian.net` URL at `sprint-goals:20,:196` is a distinct non-accepted finding (m-U-net3 in 04-utility-skills). |
| m-infra-1 (partial) | `.mcp.json` lacks `$schema`. ICON-0015 m-1 covered both manifests; only `plugin.json` was fixed in ICON-0038. See 05-infrastructure § m-infra-1. |
| O-X3 | `disable-model-invocation: true` propagation deferred — not on disk. |
| ADR-008 per-component overages | `manager.agent.md` at 50.8% and 9×common-constraints at 45.5% of PM budget, both over 40% cap. Acknowledged at ADR-008 adoption; no resolution yet. |

### Net-new drift classes

The following drift patterns were not present in ICON-0015 and are new in this cycle:

1. **Copilot-product-framing recurrence in `ecological-impact` calculation path (M-U-NET1 / m-CC-NET-NEW-1).** ICON-0015 m-U-A fixed the model name. The deeper Copilot UI coupling (Option A "Remaining Reqs", GitHub billing plan table, "Copilot Ecological Impact Report" header) was not in scope for m-U-A and is now a Moderate ADR-004 violation. Cross-cutting pattern: partial sweeps on a Copilot-specific skill that address the most visible literal without investigating the calculation path.

2. **Sweep-incompleteness new instances: `agent-vs-skill-invocation.md:23` and `append-retrospective-entry.md:3,:32` (m-P-NEW-1/2 / m-CC-NET-NEW-2).** ICON-0036 reduced the cap from 15 to 10 and updated six files; two companion docs were missed. Same class as O-V4's placeholder-grep motivation; same fix.

3. **`mcp-tools-first` absent from `using-skills` Skill Priority and README Internal Skills table.** New skill (ICON-0041) never received a catalog mention. All other auto-invoked internal skills appear in the README Internal Skills table; `mcp-tools-first` does not. See IO-CC-D1 and `README.md:176-209`.

4. **ADR-008 manager session at 97.1% of cap with `manager.agent.md` at 50.8% of per-component ceiling.** Not present in ICON-0015 (ADR-008 did not exist). The ICON-0033 baseline was 8,062 words; current is 8,251 (+189 across ICON-0041 → ICON-0045). The headroom is tight enough that a single substantive manager-agent addition could breach the cap without triggering the 5%-delta re-audit trigger.

5. **Double-verification gap: `manager.agent.md:201` and `task-retrospective/SKILL.md:129-130` (m-P-NEW-3).** ICON-0027 canonicalization of the retrospective write path made the ordering clear enough to surface the duplicate verification-checklist invocation. Not a regression; first surfaced by this cycle's ordering clarity.
