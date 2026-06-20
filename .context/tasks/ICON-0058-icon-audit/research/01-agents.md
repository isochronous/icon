# Agents Audit — Raw Findings

## Summary

The agents domain is in strong health overall. All three ICON-0046 agent-domain Minors (m-A-NET-NEW-1, m-A-NET-NEW-2, m-A-NET-NEW-3) are confirmed fixed on disk by ICON-0048. The two high-impact ICON-0056/0057 changes — making `task-retrospective` Hardcoded Non-Negotiable and adding a structured non-skippable close-gate — are structurally sound and the retrospective hardcoding eliminates the single most-flagged skip-rationalization in the codebase.

However, the ICON-0057 close-gate introduces two structural observations worth reporting. First, `verification-checklist` now appears three times in the manager Task Completion flow (manager Step 2, task-retrospective Steps 6–7, close-gate Step 6 item 4) — an escalation of the ICON-0046 double-verification concern (m-P-NEW-3) that was not resolved. Second, the close-gate demands "project lint command ran and its output is shown" (Step 6 item 2) but the Task Completion workflow has no explicit step assigning lint execution to any agent; the coder runs build (not lint separately), and the reviewer defers to linters rather than running them. These are Minor structural concerns introduced by the hardening changes, not blockers.

The manager word count has grown to 4,648 words — 54.7% of the 8,500-word session cap and 136.7% of the 40% per-component threshold (3,400 words). Cumulative growth from the ICON-0033 baseline is 500 words (5.9% of cap) — technically a threshold-exceedance on a cumulative basis, though no individual MR triggered the ADR-008 per-MR gate. The ADR-008 incremental-drift gap flagged in ICON-0046 (O-T1) is worsening.

No Critical or new Moderate findings are observed. The agents domain defect count for this cycle is 0 Critical, 0 Moderate, 2 Minor (net-new), with two items still present from ICON-0046.

---

## Defect Findings

### Critical

None observed.

### Moderate

None observed.

Prior moderate finding M-U-NET1 (`ecological-impact` ADR-004 violation) is a utility-skills domain finding, not agents domain. No agent-domain Moderates observed.

### Minor

**m-A-0058-1 — Triple `verification-checklist` invocation in Task Completion flow**

- **Location**: `agents/manager.agent.md:203` (Step 2), `skills/task-retrospective/SKILL.md:129-130` (Steps 6–7), `agents/manager.agent.md:210` (close-gate item 4) and `:233` (Hardcoded)
- **Finding**: The Task Completion flow invokes `verification-checklist` three distinct times:
  1. **Manager Step 2** (`agents/manager.agent.md:203`): "Verify all planned work items are done (invoke `verification-checklist` skill)."
  2. **task-retrospective Steps 6–7** (`skills/task-retrospective/SKILL.md:129-130`): Step 6 "Verify all planned work items are done"; Step 7 "Confirm all builds and tests pass (invoke `verification-checklist` skill)." This fires during manager Task Completion Step 3.
  3. **Close-gate item 4** (`agents/manager.agent.md:210`): "(4) verification-checklist passed."
  This is an escalation of ICON-0046 m-P-NEW-3 (2x invocation). ICON-0057 added the close-gate but did not address the underlying double-verification, making it triple. The practical risk is agent confusion about which gate is authoritative. The close-gate is now Hardcoded; the other two occurrences are redundant but have not been demoted.
- **ADR check**: ADR-010 does not protect this; m-P-NEW-3 was flagged as an active improvement opportunity (O-S1) in ICON-0046. ICON-0049 suggested removing Steps 6–7 from `task-retrospective` to collapse the double to single. ICON-0057 added a third without resolving the existing overlap.
- **Risk**: Low. The close-gate is the authoritative final check; the earlier two invocations are not harmful. The risk is that an agent running `verification-checklist` at Step 2 believes it has already satisfied the close-gate requirement and does not re-confirm at Step 6.
- **Classification**: Minor (structural redundancy; regression of m-P-NEW-3 from ICON-0046).

**m-A-0058-2 — Close-gate lint evidence requirement has no explicit workflow step assigning lint execution**

- **Location**: `agents/manager.agent.md:210` (close-gate item 2), `agents/manager.agent.md:233` (Hardcoded restatement)
- **Finding**: The ICON-0057 close-gate (Step 6, Hardcoded) requires "(2) project lint command ran and its output is shown" as one of four itemized evidence checks. However, no step in Task Completion Steps 0–5 assigns lint execution to any agent. Specifically:
  - `agents/coder.agent.md:21` Step 5 says "Run the project's build command" — explicitly a build command, not a lint command.
  - `agents/reviewer.agent.md:20` Step 4 says "Focus on issues the linter won't catch" — the reviewer defers to linters rather than running them.
  - `agents/manager.agent.md:100` ("No source investigation") prohibits the manager from running shell commands including lint.
  - `skills/verification-checklist/SKILL.md:86` Step 2 says "Run all relevant verification commands (build, test, lint)" — but this step fires when a specialist invokes the skill, and the manager's invocation at Step 2 is a meta-coordination check (confirming specialist evidence), not a fresh lint execution.
  The close-gate demands lint evidence that has no explicit production step in the standard Task Completion sequence. In practice, lint output is expected to come from the coder's work phase, but this is not stated.
- **Risk**: Low-medium. In the common path where @coder ran lint during implementation, the evidence exists implicitly. In paths where lint was not explicitly run (e.g., purely documentation tasks, context-only changes), the close-gate will block with no clear remediation path. An agent may rationalize past it or run a bare lint command without the manager's prior "no shell commands" rule being surfaced.
- **Classification**: Minor (structural gap in close-gate specification; first-occurrence post-ICON-0057).

---

## Common Check Patterns — Coverage

**Pattern 1: Self-reference violation**

- `manager.agent.md`: The Hardcoded "Always delegate to specialist — never implement, test, review, or research directly" rule at `:221` is consistent with the file's own structure (manager delegates via steps, does not implement). Exceptions for `plan.md`, `.context/tasks/` artifacts, and git operations are explicitly carved out at `:229-231`. The new close-gate is a coordination/confirmation check, not an implementation action. No self-reference violation.
- `context-specialist.agent.md:76`: "Cannot delegate to sub-agents" is structurally consistent with the file — the agent follows mode-routing skill dispatch without sub-agent calls. No violation.
- `researcher.agent.md`: No self-reference violations. The Hardcoded rule "Check `.context/cache/` before any web fetch" at `:88` is consistent with the Research Process at `:25`. The Anti-Rationalization row at `:108` guards against the cache-skip. Clean.
- `product-manager.agent.md`: GATE RULE at `:54` ("Do not call the jira-story skill until all triggered sub-agents have returned") is consistent with the Hardcoded tier at `:211` ("Delegate to sub-agents when trigger conditions are met"). No self-reference violation. The AR row at `:238` guards the gate-bypass rationalization. Clean.
- All other agents: no self-reference violations detected. Sub-agent scope-termination language ("Your job ends when you hand back...") is present and consistent in all 6 sub-agents: `architect.agent.md:14`, `coder.agent.md:13`, `planner.agent.md:14`, `researcher.agent.md:14`, `reviewer.agent.md:13`, `tester.agent.md:13`. Context-specialist variant at `:16` matches its mode-based termination pattern.

**Pattern 2: Template / standard cross-reference**

- `manager.agent.md:164`: References `.context/workflows/task-plan/phase-*.md` (glob pattern). Confirmed present in `context_template/context/workflows/task-plan/`. Valid.
- `manager.agent.md:201,:224,:254`: References `.context/workflows/task-plan/phase-completion.md § Reconcile plan.md`. Confirmed shipped. Valid.
- `manager.agent.md:155`: References `writing-skills` Quality Checklist for skill-delegation contexts. `skills/writing-skills/` confirmed present. Valid.
- `reviewer.agent.md:26`: References `code-quality-rules` skill. Confirmed present at `skills/code-quality-rules/`. Valid.
- `coder.agent.md:45`: References `code-quality-rules` skill checklist. Valid.
- `tester.agent.md:19`: References `characterization-testing` and `testing-discipline` skills. Both confirmed present. Valid. (ICON-0049 update to Step 2 correctly added the `characterization-testing` fork before `testing-discipline`.)
- `context-specialist.agent.md:38`: References `context-specialist-create`, `upgrade-repo`, `context-maintenance` skills. All confirmed shipped. Valid.
- `manager.agent.md:124`: References `manager-routing-guide` skill. Confirmed present. Valid.
- No template cross-reference violations found.

**Pattern 3: Operational defensiveness**

- `context-specialist.agent.md:19-25`: Skip conditions are present and cover the key failure modes (mode != maintenance and `.context/` already current; mode is create and tree position unknown). `mode: audit` is defined read-only at `:53-56`. Defensiveness is adequate; the prior ICON-0046 finding m-A-NET-NEW-3 ("where audit-write occurs" contradiction) is confirmed fixed — the commit-before-report rule at `:82` now correctly says "except in `mode: maintenance`" with the `mode: audit` NOT listed among modes that commit.
- `researcher.agent.md:25`: Cache-read step checks 3-day validity before web fetch. Step 4 (`:27`) writes unconditionally after a fresh fetch — same silent-overwrite-same-day observation from ICON-0046 Pattern 3 (benign). Cache accumulation without pruning guidance is still unaddressed (IO-A-3 still present; see Still Present section).
- `manager.agent.md:221-222`: Hardcoded "Write `plan.md` to disk immediately... even an incomplete plan is a durable artifact" handles partial-failure recovery. New close-gate (`:233`) explicitly states "A green test suite satisfies NONE of these four — green tests are not a review, not a lint run, and not proof the change itself is covered." This is strong operational defensiveness for the close-gate itself. Adequate.
- No critical operational-defensiveness gaps found in agents.

**Pattern 4: Frontmatter parser-fragility**

All 9 agents use `description: >` folded block scalar form. Confirmed uniform across `architect.agent.md:2`, `coder.agent.md:2`, `context-specialist.agent.md:2`, `manager.agent.md:2`, `planner.agent.md:2`, `product-manager.agent.md:2`, `researcher.agent.md:2`, `reviewer.agent.md:2`, `tester.agent.md:2`. No parser-fragility from mixed indentation or single-quoted forms. The ICON-0046 finding m-A-NET-NEW-1 (context-specialist description was 3 sentences) is confirmed fixed — the description at `context-specialist.agent.md:3` is now a single sentence: "Creates and maintains .context/ documentation across create, upgrade, maintenance, and audit modes; cannot delegate to sub-agents."

---

## Improvement Opportunities

**IO-A-0058-1 — Resolve the triple `verification-checklist` pattern (closes m-A-0058-1)**

The close-gate (ICON-0057, Hardcoded) is the authoritative final gate. The `verification-checklist` invocations at manager Step 2 (`manager.agent.md:203`) and `task-retrospective` Steps 6–7 (`skills/task-retrospective/SKILL.md:129-130`) predate it and are now partially redundant. Two resolution options:

- **Option A (recommended)**: Remove `verification-checklist` from manager Step 2 (collapse it into the close-gate's item 4). Add one-line note in manager Step 2: "Verify all planned work items are done — evidence confirmed at close-gate Step 6." Keep task-retrospective Steps 6–7 as a standalone-invocation safety net but add a note: "If invoked from within the manager Task Completion flow, manager Step 6 close-gate already confirmed this gate; run these as a sanity-check only." This preserves the retro's usefulness when invoked standalone.
- **Option B**: Remove Steps 6–7 from `task-retrospective` entirely. Document that `task-retrospective` is exclusively a reflection + entry-writing tool, not a completion gate. The close-gate is the gate. Lower token cost; cleanest separation.

This is the continuation of ICON-0046 O-S1. **Effort: trivial. Impact: low-medium (rule clarity).**

**IO-A-0058-2 — Assign lint execution ownership in Task Completion workflow (closes m-A-0058-2)**

The close-gate requires lint output as evidence but no Task Completion step assigns lint to an agent. Resolution: add an explicit lint step between Step 1 (reviewer) and Step 2 (verification-checklist) in manager Task Completion. The coder is the natural owner since `coder.agent.md` already runs build; a one-line expansion to "Run the project's build and lint commands" closes the gap. Alternatively, add a note to the close-gate item 2: "Lint evidence comes from the coder's implementation report or from the manager running `<lint-command>` directly per the delegated project build instructions." **Effort: trivial. Impact: low (prevents close-gate ambiguity on doc-only or context-only tasks).**

**IO-A-0058-3 — Add an AR row for intent extraction bypass (ICON-0057 addition)**

The ICON-0057 intent extraction rule ("when the task is a reopen/redo framed as 'not done right'... state the architectural principle in one sentence and confirm with the user") lives in Session Start Step 7 (`manager.agent.md:71`) but has no corresponding Anti-Rationalization row. The ICON-0057 retrospective explicitly identified multi-round rework as the cost of symptom-level delegation — a cost high enough to drive a new behavioral rule. That cost warrants an AR row. Suggested row:

| "I understand the rework — I'll just delegate the fix" | Symptom-level delegation produces multi-round thrash if the architectural principle is unclear | State the architectural principle in one sentence and confirm with the user before delegating. |

**Effort: trivial. Impact: low-medium (prevents skip under deadline pressure).**

**IO-A-0058-4 — Address ADR-008 incremental-drift gap: manager at 54.7% of session cap**

The manager has grown from the ICON-0033 baseline of 4,148 words to 4,648 words (+500 words = 5.9% of cap), exceeding the ADR-008 5% trigger on a cumulative basis even though no single MR exceeded the per-MR threshold of 425 words. ADR-008's per-MR trigger design allows incremental drift to accumulate undetected — exactly the pattern it was designed to prevent on a cumulative basis. Session headroom is 3,852 words (was 247 at ICON-0046, now 45.3% remaining after ICON-0057 additions); while the session cap is not immediately threatened, the per-component cap at 40% (3,400 words) has been exceeded since ICON-0033 adoption.

Three options (unchanged from ICON-0046 O-T1): (a) principled content review of `manager.agent.md` for extractable-to-on-demand content; (b) extract Task Completion section to an on-demand companion file; (c) amend ADR-008 to acknowledge the per-component overage as structural. A fourth option emerges from the cumulative-drift gap: add an audit note to ADR-008 that the 5% trigger is per-MR AND that a re-inventory is triggered whenever any audit cycle finds cumulative growth from baseline ≥5%.

**Effort: low (content review) to trivial (ADR-008 amendment). Impact: high (prevents session-cap breach at next substantive manager-agent change).**

**IO-A-0058-5 — Add `Turn Start` section to `product-manager.agent.md` (still-present from ICON-0046 IO-A-4)**

`manager.agent.md:75-77` has a `## Turn Start` section defining multi-turn behavior. `product-manager.agent.md` has no equivalent. The PM is a user-invocable orchestrator with multi-turn story research workflow; a one-line Turn Start cue prevents PM losing context between turns in complex story creation sessions. Suggested addition after `## Session Start`: `## Turn Start` / "Apply common constraints; if active story research is in progress, re-read the most recent research brief before proceeding." **Effort: trivial. Impact: low-medium.**

**IO-A-0058-6 — Surface `web_search` / `web_fetch` tool names as platform notes (still-present from ICON-0046 IO-A-7)**

`researcher.agent.md:26` uses `web_search` and `web_fetch` as tool names without platform annotation. `manager.agent.md:73` has the precedent `> Platform note:` block for `explore`/`Task` tool divergence. A one-line note ("Platform note: `web_search` is the native tool name in Copilot CLI; Claude Code exposes this as `WebSearch`. Use your runtime's equivalent.") achieves ADR-004 portability parity. **Effort: trivial. Impact: low.**

---

## Agents-Specific Structural Observations

**Observation 1 — ICON-0056/0057 hardening is structurally sound; the two new Hardcoded rules are additive.**

`task-retrospective` promoted to Hardcoded Non-Negotiable (ICON-0056) and the close-gate promoted to Hardcoded (ICON-0057) are both positive-direction changes. The retrospective rule is the single most-skipped discipline in the prior audit record (ICON-0054 retro documents two retrospec-bypass instances). The close-gate itemizes the four existing gates that agents were rationalizing away ("the suite is green, that means tests pass"). The changes add approximately 200 words to the Hardcoded tier and 130 words to the Task Completion section. No existing rules are contradicted.

**Observation 2 — Scope-termination language is uniformly present and consistent (RULE 3: PASS).**

All seven sub-agents carry "Your job ends when you hand back [output] — routing decisions (what to do next, who should act) belong to the orchestrator, not to you" scope-guards. `architect.agent.md:14`, `coder.agent.md:13`, `planner.agent.md:14`, `researcher.agent.md:14`, `reviewer.agent.md:13`, `tester.agent.md:13`. Context-specialist variant at `:16` is appropriately mode-specific. This invariant has held across all audit cycles.

**Observation 3 — Common-constraints sync is mechanically enforced and byte-equal across all 9 agents.**

The ICON-0057 Context Economy rule was correctly added to `shared/common-constraints.md` (line 19–21) and propagated byte-equal to all 9 agents via the `.githooks/pre-commit` sync. All 9 agents have `<!-- BEGIN: common-constraints -->` / `<!-- END: common-constraints -->` boundary markers (1 each) and the block matches the source file. The retrospective for ICON-0057 explicitly documents the decision to place the Context Economy rule in `shared/common-constraints.md` rather than `manager.agent.md` — correctly identifying that universal disciplines belong in the shared source.

**Observation 4 — The manager-PM boundary remains implicit but stable; no role overlap observed.**

The planner `Ownership boundary` at `planner.agent.md:16` ("PM decides WHETHER to split; Planner decides HOW") is the clearest agent-boundary statement in the corpus. The manager-PM boundary continues to operate on implicit role separation without explicit documentation. This has been stable across 3 audit cycles (ICON-0015, ICON-0046, ICON-0058) — low-risk implicit contract.

**Observation 5 — The `tester.agent.md` Step 2 update (ICON-0049) is the first agent-body change to introduce a skill-routing conditional.**

Prior agent bodies referenced skills directly (invoke X, load Y). The tester Step 2 now contains a routing decision: "No existing coverage → invoke `characterization-testing` first; coverage exists → invoke `testing-discipline` directly." This is new territory for agent files (routing logic previously lived in `using-skills`). The routing is correct, but this pattern, if extended to other agents, could create agent-body routing drift that duplicates or contradicts `using-skills` catalog routing. [see agent-evaluation]

---

## ICON-0046 Delta

### Fixed since ICON-0046

| ICON-0046 ID | Description | Evidence |
|---|---|---|
| **m-A-NET-NEW-1** | `context-specialist.agent.md:2-6` description was 3 sentences, violating `agent-evaluation/SKILL.md:104` one-sentence sub-agent rule | `context-specialist.agent.md:3` now reads "Creates and maintains .context/ documentation across create, upgrade, maintenance, and audit modes; cannot delegate to sub-agents." — one sentence, semicolon-joined. CHANGELOG ICON-0048 confirms. |
| **m-A-NET-NEW-2** | `manager.agent.md:238` Discretionary heading missing `(Off Unless Explicitly Requested)` parenthetical | `manager.agent.md:242` now reads `### Discretionary (Off Unless Explicitly Requested)`. CHANGELOG ICON-0048 confirms. |
| **m-A-NET-NEW-3** | `context-specialist.agent.md:84` "(where audit-write occurs)" parenthetical contradicted `mode: audit` read-only definition | `context-specialist.agent.md:82` now correctly states "except in `mode: maintenance`" — `mode: audit` is NOT listed among modes that commit. CHANGELOG ICON-0048 confirms (removed `audit` from modes-that-commit list). |
| **IO-A-6** (improvement) | Same as m-A-NET-NEW-3 | Fixed as above. |

### Still present or partial

| ICON-0046 ID | Description | Current Status |
|---|---|---|
| **m-P-NEW-3** (agents surface) | Double `verification-checklist` invocation in manager Task Completion (Step 2 + task-retrospective Steps 6–7) | **Escalated**: ICON-0057 added a third invocation (close-gate item 4, Hardcoded). Now triple. Filed as m-A-0058-1 above. |
| **IO-A-3 / O-M3** | Cache pruning ownership not assigned to `researcher` or `context-maintenance` | Still unaddressed. `researcher.agent.md` has no pruning instruction; `context-maintenance` skill has no `.context/cache/` pruning rule. See IO-A-0058-5 (researcher) and domain-maintenance skill scope gap. |
| **IO-A-4** | PM agent missing `## Turn Start` section for multi-turn session continuity | Still absent. `product-manager.agent.md` has no Turn Start section. Filed as IO-A-0058-5 above. |
| **IO-A-7** | `researcher.agent.md:26` `web_search`/`web_fetch` tool names without platform annotation | Still absent. Filed as IO-A-0058-6 above. |
| **O-T1 / ADR-008 per-component overage** | `manager.agent.md` at >40% per-component cap; cumulative growth from ICON-0033 baseline | Worsening: manager now at 4,648 words (54.7% of session cap; 136.7% of 40% per-component cap). Cumulative growth from ICON-0033 baseline is 500 words (5.9% of cap). Filed as IO-A-0058-4 above. |
| **IO-A-5** | Manager AR row for "open MR while retro is pending" | Still absent from AR table. Lower priority given the close-gate now makes the sequence explicit. |

### Net-new

1. **m-A-0058-1** — Triple `verification-checklist` invocation: ICON-0057 close-gate added item 4 "verification-checklist passed" without removing existing Step 2 or task-retrospective Steps 6–7 invocations. Escalation of m-P-NEW-3 from ICON-0046. `agents/manager.agent.md:203,:210,:233` and `skills/task-retrospective/SKILL.md:129-130`.

2. **m-A-0058-2** — Close-gate lint evidence requirement with no explicit workflow step assigning lint execution. `agents/manager.agent.md:210,:233`. First-occurrence post-ICON-0057.

3. **IO-A-0058-3** (improvement only) — Intent extraction rule (ICON-0057, `manager.agent.md:71`) has no AR row. First-occurrence — the rule itself is new.
