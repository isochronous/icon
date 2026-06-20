# Agents Audit — Raw Findings

## Summary

The agents domain is in substantially better shape than ICON-0015 found it. All six of ICON-0015's explicit agent carry-forwards that had follow-up tasks assigned (m-A-NET4 frontmatter normalization, m-A-3/m-A-4 PM Session Start, m-A-5 mr-discipline cue, m-A-2 threshold contradiction, m-A-1 planner fence count, M-CC-NET3 three-layer-enforcement dead reference, M-CC-NET2 retrospectives write-path) are confirmed fixed on disk by ICON-0034, ICON-0027, ICON-0028, and ICON-0034 respectively. The common-constraints block is present and byte-equal across all 9 agents (mechanically enforced by `.githooks/pre-commit`). Role clarity is strong: all seven sub-agents carry explicit "Your job ends when you hand back..." scope-termination statements; no sub-agent reverses-references its orchestrator.

Two net-new Minor findings surface. First, `context-specialist.agent.md` carries a 3-sentence description that contradicts the "one sentence for sub-agents" rule added to `agent-evaluation` in the same ICON-0034 commit that claimed to fix the description-format issue — the format was normalized but the content sentence count was not. Second, the `manager.agent.md` Discretionary tier heading is missing its parenthetical `(Off Unless Explicitly Requested)`, producing a cosmetic inconsistency against all eight sibling agents. No Critical or Moderate defects are observed. The ICON-0015 Moderate cluster (M-CC-NET3, M-CC-NET2) is confirmed fully closed on disk.

## Defect Findings

### Critical

None observed.

### Moderate

None observed.

M-CC-NET3 (dead `.context/standards/three-layer-enforcement.md` reference, `manager.agent.md:151`): **confirmed fixed** — `manager.agent.md:152` now reads "Three-layer enforcement (if this change touches a rule enforced at all three layers): name all three layers and their exact file locations in the delegation prompt." The `see .context/standards/...` cross-reference has been removed. CHANGELOG entry ICON-0028 confirms.

M-CC-NET2 (retrospectives write-path "Known unresolved"): **confirmed fixed** — `manager.agent.md:203-204` and `skills/task-retrospective/SKILL.md:103-125` now agree on the two-stage flow; `skills/task-plan-phase-completion/agent-vs-skill-invocation.md` no longer carries the "Known unresolved" marker and instead specifies a clean delegation contract. CHANGELOG entry ICON-0027 confirms.

### Minor

**m-A-NET-NEW-1 — `context-specialist.agent.md:2-6` description exceeds sub-agent one-sentence cap**

- Location: `agents/context-specialist.agent.md:2-6`
- Finding: The description field contains three sentences: "Creates and maintains `.context/` documentation; operates in create, upgrade, maintenance, and audit modes. Invoked by initialize-\* skills and by manager during task retrospectives or after refactors. Cannot delegate to sub-agents." The `agent-evaluation/SKILL.md:104` Frontmatter Conventions rule states: "Sub-agents (`user-invocable: false`) keep their description to a single sentence... This applies even to sub-agents that are structurally complex like `context-specialist`." The ICON-0034 CHANGELOG entry claims "context-specialist.agent.md and the other seven agents use single-sentence folded form" — that claim does not match the current file.
- Risk: Low. The extra sentences do not cause runtime failure but add token cost to programmatic dispatch contexts that include the description field. More importantly, the rule was added by the same commit that made the format fix — the content fix was missed.
- ADR check: ADR-009 does not protect this (the rule is about sentence count, not caller enumeration). ADR-010 registry does not list this finding. This is net-new.
- Classification: Minor (cosmetic/convention); self-reference violation against `agent-evaluation/SKILL.md:104`.

**m-A-NET-NEW-2 — `manager.agent.md:238` Discretionary heading missing parenthetical label**

- Location: `agents/manager.agent.md:238`
- Finding: The heading reads `### Discretionary` while all eight other agent files use `### Discretionary (Off Unless Explicitly Requested)`. The Behavior Tiers heading format is inconsistent across the agent suite.
- Risk: Very low. The content below is `*None — all manager behavior is mandatory orchestration.*` so the functional meaning is clear. This is purely a heading-label inconsistency.
- Classification: Minor (cosmetic). Not in ICON-0015 (the prior finding was m-A-NET4 about format normalization, not content consistency within headings).

## Common Check Patterns — Coverage

**Pattern 1: Self-reference violation**

- `manager.agent.md`: The manager's Hardcoded rule "Always delegate to specialist — never implement, test, review, or research directly" has explicit carved-out exceptions for `plan.md`, `.context/tasks/` artifacts, and git operations (`manager.agent.md:124`, `:226-227`). The agent follows its own rules.
- `reviewer.agent.md`: Reviewer's Hardcoded "Verify claims independently — never trust implementation reports at face value. Read the actual code" (`reviewer.agent.md:63`). The reviewer has no access to run commands on the codebase from its workflow — it relies on the implementer-provided output in reports. This is a structural tension, not a new finding, and the Default tier row "Check for evidence of build/test execution" compensates.
- `researcher.agent.md`: No self-reference violations. The 3-day cache rule is self-consistent.
- `context-specialist.agent.md:2-6`: Description violates the one-sentence sub-agent rule from `agent-evaluation/SKILL.md:104` — see m-A-NET-NEW-1 above.
- All other agents: no self-reference violations detected.

**Pattern 2: Template / standard cross-reference**

- `manager.agent.md:162`: References `.context/workflows/task-plan/phase-*.md` (glob pattern, not specific file). All six `phase-*.md` files confirmed present in `context_template/context/workflows/task-plan/`. Valid per C1 walkback rule.
- `manager.agent.md:199,:221,:250`: References `.context/workflows/task-plan/phase-completion.md § Reconcile plan.md` (specific file). Confirmed shipped in `context_template/context/workflows/task-plan/phase-completion.md`. Valid.
- `reviewer.agent.md:26`: References `code-quality-rules` skill for "six evaluation categories." `skills/code-quality-rules/` exists. Valid.
- `coder.agent.md:45`: References `code-quality-rules` skill checklist. Valid.
- `tester.agent.md:18-19`: References `testing-discipline` and `verification-checklist` skills. Both exist. Valid.
- `context-specialist.agent.md:38`: References `context-specialist-create`, `upgrade-repo`, `context-maintenance` skills. All confirmed shipped. Valid.
- `manager.agent.md:124`: References `manager-routing-guide` skill. Confirmed shipped. Valid.
- No template cross-reference violations found.

**Pattern 3: Operational defensiveness**

- `context-specialist.agent.md`: Writes `.context/` files. Has explicit skip conditions at `:21-25` (mode != maintenance and `.context/` already current; mode is create and tree position unknown). Has `mode: audit` read-only path at `:55-59`. The `upgrade` mode explicitly "does not overwrite populated files" (`:38`). Defensiveness is adequate.
- `researcher.agent.md`: Writes `.context/cache/` files. Cache-read step (`:25`) checks 3-day validity before web fetch. Step 4 (`:27`) writes unconditionally after a fresh fetch — no check for a pre-existing cache file with the same date slug. Two sessions researching the same topic on the same day produce identical filenames and will overwrite silently (benign — same content). Old cache files with different date slugs accumulate with no pruning mechanism. No `context-maintenance` rule prunes the cache directory. This is an improvement opportunity, not a critical gap.
- `manager.agent.md`: Writes `plan.md` and `.context/tasks/` artifacts. The Hardcoded rule "Write plan.md to disk immediately... even an incomplete plan is a durable artifact" (`manager.agent.md:222-223`) handles partial-failure recovery (a reset mid-task still has the plan artifact). Adequate.
- No critical operational-defensiveness gaps found in agents.

**Pattern 4: Frontmatter parser-fragility**

- All 9 agents now use `description: >` folded block scalar form (`agents/*.agent.md:2`). ICON-0034 normalized the format. No parser-fragility from mixed indentation or single-quoted forms. m-A-NET4 is confirmed fixed.
- `context-specialist.agent.md` description content is multi-sentence but the YAML form is correct folded scalar — parser impact is nil. The issue is rule compliance, not parser fragility. Logged as m-A-NET-NEW-1.

## Improvement Opportunities

**IO-A-1 — Trim `context-specialist.agent.md` description to one sentence**
- Close m-A-NET-NEW-1 and align with `agent-evaluation/SKILL.md:104`.
- The three-sentence description can be reduced to: "Creates and maintains `.context/` documentation across create, upgrade, maintenance, and audit modes; cannot delegate to sub-agents." (One sentence, semicolon-joined compound verb phrase — same structure the ICON-0034 CHANGELOG assumed was already in place.)
- Effort: trivial. Impact: low (rule compliance + minor token savings).

**IO-A-2 — Add parenthetical to `manager.agent.md:238` Discretionary heading**
- Close m-A-NET-NEW-2. Change `### Discretionary` to `### Discretionary (Off Unless Explicitly Requested)` for heading-format parity with all eight sibling agents.
- Effort: trivial. Impact: very low (cosmetic).

**IO-A-3 — Add cache-pruning guidance to `researcher.agent.md`**
- The researcher writes date-stamped cache files but has no instruction to prune stale ones. `.context/cache/` can accumulate indefinitely. Either add a step to the research process ("If more than 3 expired cache files exist for this topic, delete all but the most recent before writing the new one") or assign ownership to `context-maintenance`. The `context-maintenance` skill does not currently audit the `cache/` directory.
- This addresses the operational-defensiveness gap in Pattern 3 above.
- Effort: low. Impact: medium (prevents unbounded cache accumulation in long-lived repos).

**IO-A-4 — Specify Turn Start behavior (or explicitly omit) for `product-manager.agent.md`**
- `manager.agent.md:73-75` has a `## Turn Start` section that defines behavior on every subsequent turn. `product-manager.agent.md` has no equivalent section. The PM is a user-invocable orchestrator like the manager — a multi-turn story research session with drift risk (researcher findings from a prior turn) would benefit from a one-line Turn Start cue analogous to the manager's: "Apply common constraints; if active story research is in progress, re-read the most recent research brief."
- Effort: trivial. Impact: low-medium (prevents PM losing context mid-session on complex story work).

**IO-A-5 — Add an Anti-Rationalization row for the GATE RULE bypass to `manager.agent.md`**
- The PM has an explicit AR row for GATE RULE bypass: "I'll start drafting the story while sub-agents run" (`product-manager.agent.md:238`). The manager's equivalent workflow gate is the Reconcile plan.md step 0 — "Run step 0 before @reviewer." This row already exists at `manager.agent.md:250`. However there is no AR row for the parallel case: "I'll open the MR while retro is pending" (skipping `mr-discipline` or retro step). Adding one row would complete the Task Completion section's guard surface.
- Effort: trivial. Impact: low-medium.

**IO-A-6 — Evaluate whether `context-specialist.agent.md` should have a Scope-entry warning for `mode: audit`**
- The `mode: audit` is explicitly read-only at `:55-59`. However, the Hardcoded rule at `:84` says "Must commit work before reporting complete — except in `mode: maintenance`" and lists the other three modes as committing. The `mode: audit` is listed inline as "audit-write occurs" which is confused — audit is read-only. This parenthetical `(where audit-write occurs)` at line 84 contradicts the Process section's explicit "Do not modify any files" for audit mode. [see agent-evaluation]
- Location: `agents/context-specialist.agent.md:84`
- This is a documentation consistency gap — the phrase "where audit-write occurs" inside the parenthetical following `mode: audit` appears to describe behavior that contradicts the Process section. The audit mode is defined as read-only (Phase 0/1/2, no Phase 3/Edit). The parenthetical is likely a copy-edit residue.
- Effort: trivial. Impact: low (prevents misreading that audit mode commits changes).

**IO-A-7 — Surface researcher's `web_search` / `web_fetch` tool names as platform notes**
- `researcher.agent.md:26` uses `web_search` and `web_fetch` as tool names without any platform annotation. On Copilot CLI these are the native tool names; on Claude Code the equivalents may differ. Per ADR-004, when tool names differ across runtimes, "both forms are documented." The manager has a `> Platform note:` block for the `explore`/`Task` tool divergence (`manager.agent.md:71`). Researcher's web tools warrant a similar one-line note.
- Effort: trivial. Impact: low (portability hygiene per ADR-004).

## Agents-Specific Structural Observations

**Observation 1 — Sub-agent scope-termination language is uniformly present and consistent.**
All seven sub-agents carry a "Your job ends when you hand back [output] — routing decisions (what to do next, who should act) belong to the orchestrator, not to you" scope-guard in their `## Scope` sections. This structural invariant holds across `architect.agent.md:13-14`, `coder.agent.md:12-13`, `planner.agent.md:14-15`, `researcher.agent.md:13-14`, `reviewer.agent.md:12-13`, `tester.agent.md:12-13`. RULE 3 (Sub-Agent Job Clarity) is at PASS. This is the strongest structural health signal in the domain.

**Observation 2 — The two user-invocable agents (manager, PM) are structurally asymmetric in ways that are both intentional and accidental.**
Intentional asymmetry: manager has Turn Start, Progress Tracking, Context Discovery, Delegation, Context Refresh, Conflict Resolution sections — the full orchestration surface. PM has none of these because its lifecycle is a single-task story workflow. Accidental asymmetry: manager has `### Discretionary` (missing parenthetical, m-A-NET-NEW-2); PM has the parenthetical. Manager has a `## Turn Start` section; PM has none (IO-A-4 opportunity).

**Observation 3 — The context-specialist.agent.md:84 "where audit-write occurs" parenthetical is the only remaining internal-consistency gap in the agent set.**
The Process section defines `mode: audit` as "Do not execute Phase 3 (Edit). Do not modify any files" (`:57-58`). The Hardcoded tier at `:84` says modes `create`, `upgrade`, and `audit` "retain the commit-before-report behavior" with a parenthetical "(where audit-write occurs)." The parenthetical contradicts the read-only audit definition. This was likely introduced as a vestige of an earlier draft where audit mode had a write phase. It is a Minor documentation gap (IO-A-6).

**Observation 4 — Role overlap between manager and PM is appropriately bounded.**
The planner's `Ownership boundary` at `planner.agent.md:16` — "The PM agent decides WHETHER a story should be split. The Planner agent decides HOW" — is the clearest agent-boundary documentation in the corpus. No other inter-agent boundary is as explicitly named. The manager-PM boundary (task orchestration vs. story creation) is implicit from the `When to Invoke` section of each but not explicitly stated. This is a low-priority observation: the implicit boundary has been stable across multiple audit cycles.

**Observation 5 — All nine agents' common-constraints blocks are byte-equal (mechanically enforced).**
The `.githooks/pre-commit` hook enforces byte equality of the `<!-- BEGIN: common-constraints -->` ... `<!-- END: common-constraints -->` block against `shared/common-constraints.md`. Confirmed present in all 9 agents. M-A2 is in "accepted / mechanically enforced" status.

## ICON-0015 Delta

### Fixed since ICON-0015

| ICON-0015 ID | Description | Evidence |
|---|---|---|
| M-CC-NET3 / M-A-NET1 | Dead `three-layer-enforcement.md` reference in `manager.agent.md` delegation template | `manager.agent.md:152` now self-sufficient; no `three-layer-enforcement.md` reference anywhere in agents (grep confirms). CHANGELOG ICON-0028. |
| M-CC-NET2 | Retrospectives write-path "Known unresolved" contradiction | `manager.agent.md:203-204`, `task-retrospective/SKILL.md:103-125`, and `agent-vs-skill-invocation.md` now agree on two-stage flow. CHANGELOG ICON-0027. |
| m-A-NET4 | Agent frontmatter description format divergence (mixed single-quoted vs. folded scalar) | All 9 agents now use `description: >` folded scalar. CHANGELOG ICON-0034. |
| m-A-3 | PM Session Start lacks common-constraints acknowledgement | `product-manager.agent.md:15` now has "Apply common constraints — always active, no invocation required." CHANGELOG ICON-0034. |
| m-A-4 | PM Session Start positioned after `## When to Invoke` | `product-manager.agent.md:12` now has `## Session Start` before `## When to Invoke` at `:17`. CHANGELOG ICON-0034. |
| m-A-5 | Zero agents reference `mr-discipline` | `manager.agent.md:207` now has "Apply the `mr-discipline` skill before drafting the description." CHANGELOG ICON-0034. |
| m-A-2 / m-P-5 | Manager hardcoded "3+" failure threshold contradicted `systematic-debugging` "2+" trigger | `manager.agent.md:183` now delegates threshold to `systematic-debugging`; no hardcoded number. CHANGELOG ICON-0034. |
| m-A-1 | Planner odd code-fence count | `planner.agent.md` now has 4 code fences (even). CHANGELOG ICON-0034. |
| m-A-6 | Manager step-7 / Default-tier "Session Start" wording tension | `manager.agent.md:236` now reads "Invoke @researcher during Session Start step 7 when any trigger in that step applies." CHANGELOG ICON-0034. |
| m-A-NET3 | Reviewer Default-tier verbatim 6-category list repetition | `reviewer.agent.md:69` now reads "Review against all six categories defined in the `code-quality-rules` skill" — SSOT pointer, no repetition. CHANGELOG ICON-0033. |
| m-7 | Context-specialist doubled scope-discipline statement at `:133,:138-139` | Now a single sub-bullet at `context-specialist.agent.md:130`. CHANGELOG ICON-0034. |

### Still present or partial

None from the ICON-0015 agents domain. All tracked carry-forwards are confirmed fixed on disk.

The broader ICON-0015 carry-forwards that originated in other domains but had agent-surface effects (e.g., m1 `prune-context.sh` 2>/dev/null — ADR-010 "accepted/watch"; m9 DataScan examples — ADR-010 "accepted/watch") remain in their accepted states per ADR-010 and are not re-tiered here.

### Net-new

1. **m-A-NET-NEW-1** — `context-specialist.agent.md:2-6`: description is 3 sentences, violating `agent-evaluation/SKILL.md:104` "sub-agents stay one-sentence." The ICON-0034 fix normalized the format (folded scalar) but missed the content (sentence count). The CHANGELOG's claim of "single-sentence" was inaccurate.

2. **m-A-NET-NEW-2** — `manager.agent.md:238`: `### Discretionary` heading missing the `(Off Unless Explicitly Requested)` parenthetical present on all 8 sibling agents.

3. **IO-A-6 (documentation inconsistency)** — `context-specialist.agent.md:84`: the phrase "(where audit-write occurs)" in the Hardcoded commit-rule parenthetical contradicts the Process section's explicit "Do not modify any files" for `mode: audit`. Minor documentation gap. [see agent-evaluation]
