# Agents Audit — Raw Findings

**Domain**: 01 — Agent definitions (`agents/*.agent.md`, `shared/common-constraints.md`)
**Audit**: ICON-0089 (2026-07-26), plugin v2.0.0 + `[Unreleased]` (ICON-0088)
**Prior baseline**: ICON-0058 (2026-06-10, v1.19.0 + `[Unreleased]`)
**Scale**: 9 agents, 1,546 lines, 15,906 words total

---

## Summary

The agents corpus came through the 2.0.0 breaking release in good structural health. Every mechanical invariant the prior audit tracked now holds: all 9 agents use `description: >` folded scalars, all 27 Behavior-Tier subheadings carry their exact parentheticals, the `common-constraints` block is **byte-equal in all 9 agents at the blob level**, every Markdown table satisfies the header-cell/row-cell invariant, and the GitHub-only conversion sweep left **zero** residual GitLab/Jira/Confluence/MR terms in `agents/`. Both ICON-0058 Minors are resolved or materially improved — the triple `verification-checklist` invocation (m-A-0058-1) is fully collapsed to a single close-gate call by ICON-0068, and the lint-evidence gap (m-A-0058-2) gained an explicit N/A escape for pure-content repos.

The two Moderates this cycle are both **contract-completeness** problems rather than correctness bugs, and both trace to the same root cause: *a rule was extended to a wider population than the files that implement it.* ADR-015 declares all seven specialists isolated with a warmstart-in / report-out contract, but only @architect and @planner — the two agents ICON-0085 actually touched — received the `## Inputs (from warmstart)` half, and three of seven still have no `## Output Format` at all. Separately, ADR-008's always-loaded manager session total now measures **8,685 words against an 8,500 ceiling (102.2%)** — over budget outright, accepted-with-rationale by ICON-0088 but with the discharging reduction pass explicitly named as "not-yet-scheduled," and with ADR-008:47 itself conceding "there is no automated pre-commit lint counting session totals."

That last line is the thread running through this cycle's script-offload work. Every defect below is a **presence, count, or cross-reference invariant** — mechanically checkable, and currently checked only by an audit that fires roughly every 30 tasks. Three of the five script-offload candidates cite a *named, already-observed* failure from the retrospective record (ICON-0088 table-column drop, ICON-0078 stale `Step N`, ADR-008 cumulative drift), and two of those retro entries state in their own words that **no gate catches this class**. The agents domain is not where ICON's quality is at risk; it is where ICON's *verification* is most cheaply mechanizable.

**Tally**: 0 Critical / 2 Moderate / 4 Minor / 6 improvement opportunities / 5 script-offload candidates.

---

## Defect Findings

### Critical

**None observed.** No agent contains a rule that contradicts another agent, a broken skill reference, a dangling `Step N` cross-reference, or a frontmatter defect that would break discovery.

---

### Moderate

#### M-A-0089-1 — ADR-015's isolation contract is specified for only 2 of 7 isolated specialists  `[see agent-evaluation]`

- **Locations**:
  - Contract asserted: `.context/decisions/015-all-specialists-isolated.md:20-21` ("**All specialist dispatches are isolated** — task→report via the `## Context Warmstart`"), restated at `skills/manager-routing-guide/SKILL.md:104-114` (the isolation roster table naming all 7).
  - Contract **implemented**: `agents/architect.agent.md:16-20` (`## Inputs (from warmstart)` + "Cold-start tolerant"), `agents/planner.agent.md:18-22` (same, plus the `ask_user` / Open-Questions channel clarification).
  - Contract **absent**: `agents/coder.agent.md`, `agents/tester.agent.md`, `agents/reviewer.agent.md`, `agents/researcher.agent.md`, `agents/context-specialist.agent.md` — measured: `Inputs (from warmstart)`=0, `Cold-start tolerant`=0, and the literal string `isolated` appears **0 times** in all five.
  - `## Output Format` **absent**: `agents/coder.agent.md` (has none; ends Workflow at `:22`), `agents/tester.agent.md` (none), `agents/context-specialist.agent.md:68-70` (prose "Report completion" only, no template). Present in architect `:48`, planner `:47`, researcher `:39`, reviewer `:28`.
- **Finding**: The isolated dispatch model is a **two-sided contract** — a structured warmstart in, a structured report out. ICON-0085/ADR-015 wrote both sides for the two agents it converted, but the five that were *already* isolated never received the input half, and three never received a report template. The asymmetry is inverted from what you would expect: the agents isolated longest have the **weakest** contracts.
- **Concrete consequence, not hypothetical**: `agents/coder.agent.md:17` Step 1 instructs "Clarify ambiguities before coding" — with no named channel. `agents/planner.agent.md:22` had exactly this problem and it was resolved explicitly ("isolation gives you a scoped context window … it does **not** remove `ask_user`. You have two complementary channels."). @coder, @tester, and @reviewer got no such resolution, and per ICON-0085's own retrospective (`.context/retrospectives.md:18`) the *inferred* belief that "an isolated sub-agent cannot clarify live" is a **documented false premise that passed both design and @reviewer**. Five agents currently sit on the unclarified side of that exact trap.
- **Also**: `agents/architect.agent.md:18` and `agents/planner.agent.md:20` each enumerate the warmstart's five fields inline (`### Task`, `### Architecture`, `### Domain`, `### Applicable Rules`, `### Scope Boundaries`), duplicating `agents/manager.agent.md:133-165`. Two literal copies of the template's field list is precisely the sweep-incompleteness class the baseline preamble names as a known-churning area.
- **ADR check**: ADR-015 mandates the contract but does not exempt the five. ADR-008 is the counterweight — these are **on-demand sub-agent files, explicitly out of the always-loaded inventory** (`ADR-008:31`: "sub-agent files … are NOT in the always-loaded set"), so adding the contract costs zero always-loaded budget. No ADR protects the gap.
- **Risk**: Moderate. Degraded output quality under cold dispatch (a @reviewer with no stated input contract does not know it may read `.context/` to fill gaps), and a latent blocking-ambiguity dead-end for @coder/@tester.
- **Classification**: **Net-new** (ADR-015 dates 2026-07-18, after ICON-0058).

#### M-A-0089-2 — Manager always-loaded session total is over the ADR-008 ceiling, with no gate and no scheduled discharge

- **Locations**: `.context/decisions/008-always-loaded-token-budget.md:14` (8,500-word manager ceiling), `:15` (40% / 3,400-word per-component cap), `:43-45` (the recorded overages), `:47` ("**Reviewers must apply the trigger check manually; there is no automated pre-commit lint counting session totals. (Candidate for a future hook.)**"); `agents/manager.agent.md` (whole file).
- **Measured live this audit** (`wc -w`, exact agreement with ADR-008's ICON-0088 figures — the ADR is accurate, the *state* is the finding):

  | Component | Words | Note |
  |---|---|---|
  | `agents/manager.agent.md` | 4,620 | 54.4% of budget; **136% of the 3,400-word per-component cap** |
  | `shared/common-constraints.md` × 9 | 3,321 | 369 × 9 |
  | `skills/using-skills/SKILL.md` | 744 | |
  | **Manager session total** | **8,685** | **102.2% of the 8,500 ceiling — over budget** |
  | PM session total | 6,459 | 92.3% of 7,000 — within budget |

- **Finding**: Two distinct overages. The **per-component** overage (manager at 136% of its 40% cap) is long-standing and explicitly accepted-with-rationale at `ADR-008:44` — per the brief's consult-before-tiering rule I do **not** re-tier it. The **session-total** overage is different: it is newly recorded (`ADR-008:45`, dated 2026-07-26, the same day as this audit), it is stated plainly as "over budget outright," and its discharge is named as "a **separate, not-yet-scheduled task**" (`ADR-008:44`). An accepted overage with no scheduled discharge and no automated detector is an open budget breach, and reporting it is exactly what the audit cycle exists for.
- **Why it recurs**: `ADR-008:24` documents the mechanism in its own words — "the manager grew **+978 words** cumulatively (4,148 → 5,126) **without any single PR's net delta reaching 425 words**." The per-PR trigger provably misses slow drift, the cumulative-drift trigger only fires at audit time, and audit time is ~30 tasks apart.
- **Countervailing evidence (report honestly)**: the manager is *shrinking*, not growing — 5,126 → 4,976 → 4,620, a net −506 across that span (`ADR-008:44`), of which −356 came in the ICON-0083 terseness leg alone. The trend is favorable; the ceiling is still breached and the detector is still manual.
- **Risk**: Moderate. Not a correctness risk today. The risk is that the *only* mechanism that surfaces the breach is a manual audit, so the next few incremental additions land unopposed against an already-exceeded ceiling. See **SO-A-4**.
- **Classification**: **Still present / escalated** from ICON-0058 IO-A-0058-4. ICON-0058 flagged the per-component overage and the cumulative-drift gap; ICON-0088 closed the *measurement* half (fresh snapshot, ADR refreshed) and in doing so surfaced a **new** session-total overage that ICON-0058 did not observe.

---

### Minor

#### m-A-0089-1 — `web_search` / `web_fetch` named as bare tool names, contra ADR-004's own convention clause

- **Location**: `agents/researcher.agent.md:26` — "`web_search` to locate docs, then `web_fetch` for specific pages".
- **Finding**: ADR-004 does not merely *suggest* portability here; `.context/decisions/004-tool-agnostic-content.md:32` states the rule in prohibitive form: "**Do not name a single platform's tool** (e.g. `AskUserQuestion`) in shipped content: naming one harness while omitting the other is exactly the runtime-specific asymmetry this ADR forbids." `web_search`/`web_fetch` are Copilot CLI's names; Claude Code exposes `WebSearch`/`WebFetch`. Unlike `ask_user` — which ADR-004:30-32 explicitly designates as ICON's *portable* name with a documented both-harness mapping — `web_search`/`web_fetch` have **no** portable designation and **no** platform note.
- **Precedent exists in the corpus**: `agents/manager.agent.md:71` handles the identical situation correctly — "> Platform note: the `explore` sub-agent is native to Copilot CLI; under Claude Code, substitute the `Task` tool with the `general-purpose` sub-agent". Of the three harness-divergent tool-name sites in `agents/`, one is annotated (`explore`/`Task`), one is ADR-designated portable (`ask_user`), and one is bare.
- **Risk**: Low. A Claude Code @researcher will use its own tool regardless. The defect is conformance, not function.
- **Classification**: **Still present** (ICON-0058 IO-A-0058-6, itself carried from ICON-0046 IO-A-7 — third consecutive cycle). Rationale strengthened this cycle: ADR-004's prohibitive clause makes this a conformance defect, not a missing courtesy.

#### m-A-0089-2 — Lint execution ownership still unassigned for repos that *have* a lint command

- **Locations**: `agents/manager.agent.md:218` (close-gate item 2), `:244` (Hardcoded restatement), `agents/coder.agent.md:21` (Step 5), `agents/reviewer.agent.md:17` and `:20`.
- **Finding**: ICON-0068 (`CHANGELOG.md:64`) resolved the *pure-content* half — item 2 now reads "or, if the project has no lint command (pure-content repo, ADR-005), N/A, satisfied instead by showing the pre-commit hook … ran and passed." The **other** half is untouched: for a repo that does have a lint command, no Task Completion step assigns lint execution to any agent. `coder.agent.md:21` still says "Run the project's **build** command (e.g. `npm run build`, `mvn compile`, `dotnet build`, `go build ./...`)" — build only, and every example is a compiler. `reviewer.agent.md:17` checks linter *configs* "for automated rules you can skip" and `:20` defers to "issues the linter won't catch" — the reviewer explicitly does not run it. `manager.agent.md:101` forbids the manager from running shell against the codebase.
- **Risk**: Low. In the common path @coder ran lint incidentally; the gate then passes on implicit evidence. The residual risk is an agent rationalizing past item 2, or manufacturing an unowned obligation on a non-content repo with a lint script.
- **Classification**: **Still present / partial** — ICON-0058 m-A-0058-2, half-fixed by ICON-0068.

#### m-A-0089-3 — Bare `Step 3` cross-references inside a section that has its own numbered list

- **Locations**: `agents/manager.agent.md:91` and `:92` — both read "if Step 3 resolved context", inside `## Context Discovery`, which is itself a numbered list running 1–5 (`:91-99`).
- **Finding**: The intended referent is **Session Start** Step 3 ("Resolve repo context", `:36`). But Context Discovery's *own* item 3 is "Auto-detect from manifests" (`:95`), which resolves nothing. A reader — or an agent — resolving "Step 3" against the nearest enclosing numbered list lands on the wrong step. Contrast the correctly-qualified references elsewhere in the same file: `:251` "during Session Start step 7", `:232` "(Task Completion step 0)", `:244` "close-gate (step 6)". The file's own dominant convention is to qualify; these two sites don't.
- **Verified**: all 13 `Step N` references across `agents/` resolve to a semantically correct step. This is an **ambiguity**, not a dangling reference — but it is precisely the ICON-0078 class that `.context/retrospectives.md:55` records as "invisible to the pre-commit hooks."
- **Risk**: Low. See **SO-A-3**.
- **Classification**: **Net-new**.

#### m-A-0089-4 — Unqualified cross-*file* step reference with no gate protecting it

- **Location**: `agents/context-specialist.agent.md:82` — "the dispatching manager owns the commit (folded into **Task Completion Step 4**)".
- **Finding**: This resolves into a *different file* (`agents/manager.agent.md:216`, "Commit all task artifacts") and is currently correct. It is also the single most renumbering-fragile reference in the corpus: any insertion into the manager's Task Completion list silently invalidates it, and no gate, grep convention, or reviewer checklist covers cross-file step references. The manager's Task Completion list has been renumbered at least twice in the audit record (ICON-0057 added the close-gate; ICON-0065 restructured the review item).
- **Risk**: Low today, latent. Mitigation is cheap: cite the *named* step ("the manager's Task Completion **Commit all task artifacts** step") rather than the ordinal. See **SO-A-3**.
- **Classification**: **Net-new**.

---

## Common Check Patterns — Coverage

Per the brief, each pattern is either reported or explicitly marked "no instances."

**Pattern 1 — Self-reference violation**: **No instances.** Checked each agent against its own Hardcoded rules. `manager.agent.md:229` ("never implement, test, review, or research directly") is consistent with the file's structure, with explicit carve-outs at `:239-240` for `plan.md`/`.context/tasks/` artifacts and git operations. `context-specialist.agent.md:76` ("Cannot delegate to sub-agents") is structurally honored — the file routes by mode to inline skill loads, never a dispatch. `researcher.agent.md:92` ("Check `.context/cache/` before any web fetch") matches Research Process step 2 at `:25` and is guarded by the AR row at `:112`. `product-manager.agent.md:53` GATE RULE matches Hardcoded `:189` and AR row `:217`. `tester.agent.md:68` ("Run only specific test files during iteration") matches the Iteration vs. Full-Suite section at `:49-57`.

**Pattern 2 — Template / standard cross-reference**: **No dangling references.** Spot-verified: `manager.agent.md:175` → `.context/workflows/task-plan/phase-*.md` (present); `:212,:213,:215` → `phase-completion.md` §§ (present); `:164` → `writing-skills` Quality Checklist (present); `:241` → `manager-routing-guide` (present); `reviewer.agent.md:26` and `coder.agent.md:45` → `code-quality-rules` (present); `tester.agent.md:19-20` → `characterization-testing` + `testing-discipline` (both present); `context-specialist.agent.md:48,58,64` → `context-maintenance`, `upgrade-repo`, `context-specialist-create` (all present). The `.githooks/pre-commit` dead-ref resolver (`.githooks/pre-commit:32-40`) already covers `.context/<subdir>/<file>.<ext>` references from `agents/` — this class is mechanically gated and clean.

**Pattern 3 — Operational defensiveness**: Adequate, with one carried-forward gap. `context-specialist.agent.md:19-25` defines explicit skip conditions; `:53-56` defines `mode: audit` as strictly read-only with no Phase 3; `:82` correctly scopes commit-before-report to exclude `mode: maintenance`. `manager.agent.md:231` ("Write `plan.md` to disk immediately … plans may be incomplete at creation") is a genuine partial-failure-recovery guarantee, reinforced by the AR row at `:273-274`. `manager.agent.md:218` close-gate is fail-closed by construction ("Missing any one = NOT closed"). **Gap**: `researcher.agent.md:27` writes to `.context/cache/` unconditionally after every fresh fetch, and no agent or skill owns cache pruning — carried from ICON-0046 IO-A-3 through ICON-0058, still unaddressed (see **IO-A-0089-4**).

**Pattern 4 — Frontmatter parser-fragility**: **No instances.** All 9 agents use `description: >` folded block scalar at line 2 with uniform 2-space continuation indentation. `user-invocable` is present and boolean in all 9: `true` for `manager` and `product-manager`, `false` for the other seven — matching the `agent-evaluation` rule that only user-invocable agents carry rich multi-paragraph descriptions (manager's is 5 sentences plus an examples block; PM's is one sentence; all seven sub-agents are one sentence). `context-specialist.agent.md:3` is a single semicolon-joined sentence — the ICON-0046 m-A-NET-NEW-1 fix holds.

---

## Improvement Opportunities

### IO-A-0089-1 — Make `manager-routing-guide`'s isolation table the *generator input* for the agent contract

`skills/manager-routing-guide/SKILL.md:104-114` already holds the authoritative roster of the 7 isolated specialists and, per-agent, "what the manager needs (the report)". That table is currently prose an LLM reads. Promote it to a **data source**: for every agent named in it, require `agents/<name>.agent.md` to carry `## Inputs (from warmstart)` and `## Output Format`, and seed each agent's Output Format from that table's existing per-agent report description. This closes M-A-0089-1 *and* converts a class of drift into a registration-gap check with an exact existing precedent — the O-V1 README skill-registration gate (`.githooks/pre-commit:705`) is the same shape. **Effort: low. Impact: high.**

### IO-A-0089-2 — Hoist the warmstart field enumeration to a single site

`architect.agent.md:18` and `planner.agent.md:20` each restate the warmstart's five field names, which are canonically defined at `manager.agent.md:133-165`. Adding the contract to five more agents (IO-A-0089-1) would make that **seven** literal copies of one field list — a sweep-incompleteness generator, and the exact "satellite sites point by reference; only the canonical site enumerates" rule ICON-0088 just promoted to `.context/standards/skill-decomposition/process-doc-sweeps.md` (`.context/retrospectives.md:2`). Apply that rule now, before the duplication is created: each agent says "your task arrives as a `## Context Warmstart` (fields defined in the manager's Delegation template)" and enumerates only the fields *it specifically* depends on. **Effort: trivial. Impact: medium — prevents a 7-way sweep obligation from being created.**

### IO-A-0089-3 — Add the intent-extraction Anti-Rationalization row

`manager.agent.md:69` carries the ICON-0057 intent-extraction rule (reopen/redo tasks: state the architectural principle in one sentence and confirm before delegating) with **no** AR row backing it, while all 21 manager AR rows back a stated rule. The ICON-0057 retrospective identified multi-round rework as the cost this rule prevents. Suggested row:

| "I understand the rework — I'll just delegate the fix" | Symptom-level delegation produces multi-round thrash when the architectural principle is unstated | State the principle in one sentence and confirm with the user before delegating. |

**Effort: trivial (+20 words, and ADR-008-relevant — see the tension note in IO-A-0089-6). Impact: medium.** *Carried from ICON-0058 IO-A-0058-3, still absent.*

### IO-A-0089-4 — Assign `.context/cache/` pruning ownership

`researcher.agent.md:25` enforces a 3-day cache validity window for *reads* but `:27` writes unconditionally after every fresh fetch, and neither `researcher.agent.md` nor the `context-maintenance` skill owns pruning. A cache with an expiry rule for reads and no expiry action for writes grows without bound. Natural owner: `context-maintenance` (it already owns `.context/` hygiene and already runs pruning scripts), with a one-line pointer in the researcher. **Effort: low. Impact: medium.** *Carried from ICON-0046 IO-A-3 → ICON-0058, third cycle unaddressed.*

### IO-A-0089-5 — Add `## Turn Start` to `product-manager.agent.md`

`manager.agent.md:73-75` defines multi-turn continuity behavior; `product-manager.agent.md` has `## Session Start` (`:12-15`) but no Turn Start. The PM is the *other* user-invocable agent and runs genuinely multi-turn story-research sessions where a mid-session context reset loses the research brief the GATE RULE (`:53`) depends on. One line after Session Start: "**## Turn Start** — apply common constraints; if story research is in progress, re-read the most recent research brief before proceeding." PM session total is 6,459/7,000, so there is budget headroom here (unlike the manager). **Effort: trivial. Impact: medium.** *Carried from ICON-0046 IO-A-4 → ICON-0058 IO-A-0058-5, third cycle.*

### IO-A-0089-6 — Name the ADR-008 discharge path explicitly, and resolve its tension with ICON-0083

Three of the improvements above *add* words, and two of them add to `manager.agent.md`, which is already over both its caps (M-A-0089-2). ADR-008:44 defers reduction to "the token-economy audit cycle" but schedules nothing. Meanwhile `.context/standards/terseness-calibration.md` (ICON-0083) forbids de-duplicating reinforcing redundancy without maintainer sign-off — and the manager's largest reducible block is exactly that: the close-gate is stated **three times** (`:218` Step 6, `:244` Hardcoded, and reinforced across AR rows `:263-264`), a deliberate reliability choice ICON-0083 explicitly declined to cut (`.context/retrospectives.md:29`: "Stopped manager at −13.1% rather than de-dup the tiered close-gate restatement … surfaced the reliability-reinforcement-vs-size tradeoff to the user"). **The honest framing is that ADR-008's ceiling and ICON-0083's reinforcement rule are in unresolved tension, and that tension is what leaves the discharge unscheduled.** Recommended: put the question to the maintainer as a single decision — either (a) raise the manager ceiling with fresh rationale acknowledging that tiered restatement is load-bearing, or (b) authorize a targeted extraction (Task Completion elaboration already moved once under ICON-0070; the AR table is the next candidate) — rather than carrying a fourth cycle of "accepted with rationale, discharge unscheduled." **Effort: trivial to raise, medium to execute. Impact: high — this is the only finding here with a compounding cost.**

---

## Agents-Specific Structural Observations

**Observation 1 — The corpus's mechanical invariants are uniformly clean; this is the strongest structural result in the audit record.** All 27 Behavior-Tier subheadings carry exact parentheticals; all 9 frontmatters are folded scalars with correct `user-invocable` values; `common-constraints` is byte-equal in all 9 at the blob level; every Markdown table passes the header/row cell-count invariant; all 13 `Step N` references resolve correctly; zero dead `.context/` refs; zero residual GitLab/Jira/MR terms post-2.0.0. Nothing in this list was true by accident — the `.githooks/pre-commit` sync and dead-ref gates produce most of it. **The invariants that are gated are clean; the two Moderates are both in the ungated space.** That correlation is the central finding of this domain.

**Observation 2 — Methodological note for the synthesis pass: verify `common-constraints` equality at the blob level, not the working tree.** A naive working-tree `cmp` reports all 9 agents as DIFFERING on a Windows checkout with `core.autocrlf=true`, because `shared/common-constraints.md` renders pure-CRLF while agent files render mixed. `git cat-file -p HEAD:<path>` shows **0 CR bytes in every blob** and byte-equality across all 9. Any future automated check (see SO-A-1) must normalize line endings or read blobs, or it will fail-closed spuriously for every Windows contributor.

**Observation 3 — Role boundaries are stable and non-overlapping; no consolidation candidate identified.** The clearest boundary statement in the corpus remains `planner.agent.md:16` ("The PM decides WHETHER a story is split. The Planner decides HOW"). `manager-routing-guide/SKILL.md:78-88` capability matrix and each agent's terminal Constraints block agree with no contradictions: @coder→"Do not write or run tests" vs @tester→"Do not implement features"; @architect→"Do not write user stories or decompose tasks — defer to @planner" vs @planner→"Do not make architectural decisions — defer to @architect"; @reviewer→"Do not implement fixes". The PM's exclusion from the manager's delegation chain is stated explicitly at `manager-routing-guide/SKILL.md:88`. Nine agents with zero role overlap after four audit cycles is a genuinely good result and should be recorded as such.

**Observation 4 — One ordering tension worth a note, not a finding.** `manager-routing-guide/SKILL.md:31` sequences `@planner → @architect`, but `architect.agent.md:24` says "For routine feature work within established patterns, defer to @planner and @coder" and `planner.agent.md:171` says "defer to @architect if structure is unclear." The two agents each defer to the other under different conditions, and the linear workflow diagram puts planning first. The Design Approval Gate (`manager-routing-guide/SKILL.md:35`) resolves it in practice — @architect reviews the design before @coder implements, regardless of diagram order. Stable across four cycles; flagged for completeness only. `[see agent-evaluation]`

**Observation 5 — The `agents/` surface is disproportionately under-gated relative to its blast radius.** `.githooks/pre-commit` runs eleven distinct invariant classes (common-constraints sync, iconrc version-bump, script-parity, two dead-ref resolvers, placeholder sentinel, cap-literal, README skill-registration, rules-index freshness, context-graph fail-closed, shellcheck). Exactly **one** — the common-constraints sync — is specific to agent *definition structure*; the rest are either repo-wide or `.context/`-specific. Meanwhile `.claude/skills/icon-audit/scripts/structural-check.sh` checks B.1–B.6, all six of which validate the *icon-audit skill's own* files (its SKILL.md, briefs, synthesis template, frontmatter) — **none** validate the agent corpus the audit is auditing. The audit's own tooling audits the audit. That is the single largest mechanization gap in this domain.

---

## Script-Offload Candidates

Ranked by leverage. Existing inventory consulted per the baseline preamble; three of five **extend** existing tooling rather than adding new hooks.

### SO-A-1 — Markdown table column-count gate  ·  low effort × **high** leverage  ·  **fail-closed today**

- **(a) Current LLM obligation**: An author must not write a table row with more cells than its header. The rule was promoted to `.context/standards/terseness-calibration.md` by ICON-0088 ("added the table column-count companion beside the existing row-count invariant", `.context/retrospectives.md:4`) — i.e. it is prose an agent must remember to apply. Directly relevant to `agents/`: every one of the 9 agents carries a 3-column Anti-Rationalization table, **98 data rows in total** (manager 21, product-manager 15, architect 12, planner 11, researcher 11, reviewer 10, tester 9, coder 6, context-specialist 3).
- **(b) Observed failure mode**: **Named and explicit.** `.context/retrospectives.md:2` (ICON-0088): "A 3-cell row written into a 2-column Markdown table silently drops its last cell at render — **the entire Correct Action column vanished** — and **no gate catches column-count mismatch**." The retrospective states the absence of a gate in its own words. Silent at render — the highest-severity failure shape, since neither author nor reviewer sees it.
- **(c) Mechanization**: ~10 lines of awk in `.githooks/pre-commit`, scoped to staged `agents/*.md`, `skills/**/*.md`, `shared/*.md`, `commands/*.md` (the existing dead-ref scope block at `:527-530` already computes exactly this file set — reuse it, no new scoping logic). For each contiguous `|`-prefixed block, take the first row's cell count as the header and assert every subsequent row matches. **Fail-closed with zero migration backlog**: this audit ran the check across all 9 agents and `shared/common-constraints.md` and it passes clean today, so it can be enabled at exit-1 immediately. Fenced-code-block awareness should reuse the hook's existing CommonMark §4.5 fence-detection helper (`.githooks/pre-commit:14-17`) so template tables inside `## Output Format` fences (e.g. `architect.agent.md:77-79`, a legitimately 4-column risk table) are treated consistently.
- **(d) Residual judgment**: Whether the table's columns are the *right* columns, and whether a given AR row's content is correct. Not mechanizable, not proposed.
- **(e)** Effort **low** / Leverage **high**. Strongest candidate in the domain: a named, already-observed, silent-at-render failure with an explicitly acknowledged gate gap, a demonstrated working checker, and no backlog to clear.

### SO-A-2 — ADR-008 always-loaded word-budget gate  ·  low effort × **high** leverage

- **(a) Current LLM obligation**: `ADR-008:22` — "Any pull request that grows the manager session total or the PM session total by ≥ 5% of the budget cap (≥ 425 words for manager, ≥ 350 for PM) must re-run the word-count inventory before merge and update both ADR-008 and the snapshot artifact." `ADR-008:29` even specifies the exact command ("re-execute `wc -l -w` on every file in the snapshot's Always-loaded surface table"). This is a fully-specified deterministic procedure carried entirely by reviewer memory.
- **(b) Observed failure mode**: **Named, quantified, and self-diagnosed by the ADR.** `ADR-008:47`: "Reviewers must apply the trigger check manually; there is no automated pre-commit lint counting session totals. **(Candidate for a future hook.)**" `ADR-008:24`: "the manager grew **+978 words** cumulatively (4,148 → 5,126) without any single PR's net delta reaching 425 words." Current state (M-A-0089-2): the manager session total sits at **8,685 / 8,500 = 102.2%**, detected only by this audit.
- **(c) Mechanization**: `skills/context-maintenance/scripts/check-token-budget.{sh,ps1}` (SSOT-script pattern, mirroring `check-rules-index.sh` which `.githooks/pre-commit:747` already delegates to). It `wc -w`s the ADR-008 inventory — the dispatcher file + 9 × `shared/common-constraints.md` + `skills/using-skills/SKILL.md` — and compares against caps and against the committed snapshot artifact. **Two hook points, deliberately different**: (i) `.githooks/pre-commit`, firing only when an always-loaded file is staged, **advisory** (print the numbers to stderr, exit 0) — ADR-008:32 says the trigger is "PR-scoped, not commit-scoped," so a commit-time hard fail would contradict the ADR; (ii) a GitHub Actions PR job, **fail-closed against a recorded accepted-overage baseline** rather than against the raw cap — so it blocks *new* growth without blocking on ICON-0088's existing accept-with-rationale. That baseline-relative design is what makes it deployable before the reduction pass IO-A-0089-6 asks for.
- **(d) Residual judgment**: Whether to trim or accept-with-rationale; which content is load-bearing; whether the cap itself should move. All maintainer decisions. The script only reports "you crossed a line you wrote down."
- **(e)** Effort **low** / Leverage **high**. The ADR explicitly nominates this hook. Also the only candidate that would have caught a *currently-live* breach.

### SO-A-3 — Agent-definition structural conformance check  ·  low effort × **high** leverage

- **(a) Current LLM obligation**: `.claude/skills/icon-audit/briefs/01-agents.md:5` asks the auditing agent to evaluate "frontmatter correctness, presence and quality of Scope / Workflow / Output Format / Behavior Tiers / Anti-Rationalization sections, the common-constraints block inclusion." The *presence* half is pure mechanics, currently performed by an Opus agent once per ~30 tasks.
- **(b) Observed failure mode**: **Two prior occurrences, both audit-caught rather than gate-caught.** ICON-0046 m-A-NET-NEW-2 — the manager's Discretionary heading shipped without its `(Off Unless Explicitly Requested)` parenthetical, fixed only at ICON-0048 (`CHANGELOG.md:135`). ICON-0046 m-A-NET-NEW-1 — `context-specialist`'s description shipped as 3 sentences against the one-sentence sub-agent rule, also fixed at ICON-0048 (`CHANGELOG.md:134`). Both are presence/format invariants that lived in the repo across a full audit interval.
- **(c) Mechanization**: Extend `.claude/skills/icon-audit/scripts/structural-check.sh` with a **B.7 — agent definition conformance** block (closing Observation 5's gap — the script currently validates only the audit skill's own files), and mirror the subset that is cheap and stable into `.githooks/pre-commit` for staged `agents/*.agent.md`. Assertions: line 2 is exactly `description: >`; `user-invocable:` present with value `true|false`; exactly one each of `### Hardcoded (Non-Negotiable)`, `### Default (On Unless Explicitly Disabled)`, `### Discretionary (Off Unless Explicitly Requested)` — literal match, this is precisely the ICON-0046 defect; `## Anti-Rationalization` present; exactly one `<!-- BEGIN: common-constraints -->` / `<!-- END: common-constraints -->` pair. Fail-closed; all 9 agents pass today. **Must read blobs or normalize CRLF** — see Observation 2.
- **(d) Residual judgment**: Whether a Scope statement is *clear*, whether an AR row is *well-chosen*, whether a tier assignment is *correct*. The check asserts presence and literal format only.
- **(e)** Effort **low** / Leverage **high**. Extends an existing script rather than adding a hook.

### SO-A-4 — `Step N` cross-reference qualifier requirement  ·  low effort (narrow form) × medium leverage

- **(a) Current LLM obligation**: `skills/writing-skills/SKILL.md` § "Editing an Existing Numbered Skill" requires an author to "renumber every `Step N` cross-reference after insert/reorder." Carried by author diligence across `agents/` and `skills/`.
- **(b) Observed failure mode**: **Named, with the gate gap stated explicitly.** `.context/retrospectives.md:55` (ICON-0078): "inserting the new Step 7 and renumbering (old 7→8, 8→9, 9→10) left one stale 'Step 8' cross-reference in Step 4 prose — **caught by @reviewer, not by any gate** … **the dangling-reference class is invisible to the pre-commit hooks**." Live latent instances in this domain: m-A-0089-3 (`manager.agent.md:91,92`) and m-A-0089-4 (`context-specialist.agent.md:82`, a cross-*file* ordinal).
- **(c) Mechanization**: Two tiers; propose only the first.
  - **Narrow, fully mechanizable, fail-closed**: require every `[Ss]tep [0-9]+` reference in `agents/*.md` and `skills/**/SKILL.md` to be **section-qualified** — matching `<Section Name> [Ss]tep N` (e.g. "Session Start step 7", "Task Completion step 0"). Pure regex, no list parsing, no semantic resolution. The manager already follows this convention at 6 of 8 sites, so the migration is 3 edits repo-wide (`manager.agent.md:91`, `:92`, `context-specialist.agent.md:82`). This alone eliminates the ambiguity class *and* makes the cross-file reference self-describing.
  - **Broad (noted, not recommended now)**: a full resolver parsing ordered lists per section and validating N is in range. Materially more code, needs a warn-then-fail migration, and buys less than the qualifier rule.
- **(d) Residual judgment**: Whether the referenced step is the *semantically* right one. A qualifier check proves the reference names its section; it cannot prove the author meant that step.
- **(e)** Effort **low** (narrow form) / Leverage **medium**. Note the honest limit: the qualifier rule prevents *ambiguity*, and makes staleness reviewable, but does not by itself detect a stale ordinal after renumbering.

### SO-A-5 — Isolation-contract registration check  ·  low effort × medium leverage

- **(a) Current LLM obligation**: ADR-015 (`.context/decisions/015-all-specialists-isolated.md:20-21`) asserts every specialist has a warmstart-in/report-out contract; `skills/manager-routing-guide/SKILL.md:104-114` restates the roster. Nothing verifies each agent file implements it — which is exactly how M-A-0089-1 (5 of 7 missing `## Inputs`, 3 of 7 missing `## Output Format`) survived ADR-015's adoption.
- **(b) Observed failure mode**: **No observed runtime failure yet.** M-A-0089-1 is this audit's first detection; there is no retrospective or CHANGELOG entry recording a cold-dispatch failure attributable to a missing contract. Stated plainly so it is not over-weighted against SO-A-1/2/3, all of which cite real prior incidents.
- **(c) Mechanization**: Treat `manager-routing-guide/SKILL.md` § "Sub-Agent Context Isolation" as the **roster SSOT**; parse the agent names from that table and assert each named agent's file contains `## Inputs (from warmstart)` and `## Output Format`. Hooks into the same `.githooks/pre-commit` staged-file scope as SO-A-3 (or ships as part of B.7). Structurally identical to the existing O-V1 skill-registration gate (`.githooks/pre-commit:705`), which asserts every `skills/<dir>/` has a README table row — this is that pattern applied to the agent roster. **Fail-closed only after M-A-0089-1 is fixed**; until then it must run advisory or it blocks every commit.
- **(d) Residual judgment**: What each contract should *say* per role — @coder's input needs differ from @architect's. The check asserts the sections exist, never their content.
- **(e)** Effort **low** / Leverage **medium**. Lower confidence than SO-A-1/2/3 because the failure is theorized, not observed — but it converts a whole class (ADR asserts a property of N files; nothing verifies the N files) into a registration gate.

### Discrimination note — candidates considered and **rejected** as non-mechanizable

Recorded so the synthesis pass can see the line was drawn deliberately:
- **AR-row quality** (does a row name a real rationalization, is the Reality column correct) — judgment. Only row *count* stability and column *count* are mechanizable, and the latter is SO-A-1.
- **Role-overlap detection** (does @coder's scope collide with @tester's) — semantic judgment over prose. `agent-evaluation` is the right instrument, and it is an LLM skill by design.
- **Whether a Scope/termination statement is clear** — judgment. Its *presence* is SO-A-3.
- **Whether a tier assignment is correct** (should this rule be Hardcoded or Default) — judgment, and precisely the kind of decision ADR-010's re-tier registry exists to keep human.

---

## ICON-0058 Delta

### Fixed since ICON-0058

| ICON-0058 ID | Description | Evidence |
|---|---|---|
| **m-A-0058-1** | Triple `verification-checklist` invocation across manager Step 2, `task-retrospective` Steps 6–7, and close-gate item 4 | **Fully fixed** by ICON-0068. `agents/manager.agent.md:214` now reads "`verification-checklist` runs once, at the close-gate (Step 6, item 4); don't invoke it separately here." `skills/task-retrospective/SKILL.md:129` now defers: "The completion gate is owned by the manager's Task Completion close-gate … invoke `verification-checklist` yourself [only] when running this retrospective standalone." Confirmed at `CHANGELOG.md:64`. Resolves a finding that had escalated across two prior cycles (ICON-0046 m-P-NEW-3 → ICON-0058 m-A-0058-1). |
| **ICON-0058 IO-A-0058-4** (measurement half) | ADR-008 cumulative-drift gap: manager measured against a never-refreshed ICON-0033 baseline | **Measurement fixed** by ICON-0088 — fresh snapshot at `.context/tasks/ICON-0088-context-integrity-urgency/word-count-snapshot.md`, ADR-008 Consequences refreshed, cumulative-drift trigger formalized at `ADR-008:24`. Live `wc -w` this audit agrees with ADR-008's figures exactly (4,620 / 3,321 / 744 / 8,685). *The remediation half is not fixed — see M-A-0089-2.* |
| **ICON-0058 Observation 3** | common-constraints byte-equality across all 9 agents | **Holding.** Verified at blob level (`git cat-file`): BYTE-EQUAL in all 9, 0 CR bytes stored. `.githooks/pre-commit` sync continues to enforce it. |
| **ICON-0058 Observation 2** | Scope-termination language uniform across sub-agents | **Holding.** Present at `architect:14`, `coder:13`, `planner:14`, `researcher:14`, `reviewer:13`, `tester:13`, `context-specialist:16` (mode-specific variant). Invariant now holds across five audit cycles. |
| *(2.0.0 sweep, no prior ID)* | GitHub-only conversion completeness in `agents/` | **Clean.** Zero residual `gitlab` / `jira` / `confluence` / `MR` / `merge request` / `jira-story` hits across all 9 agents. `manager.agent.md:67` and `researcher.agent.md:87` untrusted-content lists both correctly enumerate GitHub-flavored sources. |

### Still present or partial

| ICON-0058 ID | Description | Current status |
|---|---|---|
| **m-A-0058-2** | Close-gate lint evidence with no step assigning lint execution | **Partial.** ICON-0068 added the pure-content N/A escape (`manager.agent.md:218` item 2). The lint-owning-agent gap persists for repos that *have* a lint command — `coder.agent.md:21` still says "build command" with compiler-only examples. Re-filed as **m-A-0089-2**. |
| **IO-A-0058-3** | No AR row backing the intent-extraction rule | **Still absent.** `manager.agent.md:69` states the rule; the 21-row AR table (`:261-281`) has no corresponding row. Re-filed as **IO-A-0089-3**. |
| **IO-A-0058-4** | ADR-008 per-component overage / drift | **Escalated.** Per-component overage persists (4,620 = 136% of the 3,400 cap) and is accepted-with-rationale at `ADR-008:44` — *not re-tiered*, per the brief's consult-before-tiering rule. A **new** session-total overage (8,685 / 8,500 = 102.2%) is now recorded at `ADR-008:45` with discharge "not-yet-scheduled." Filed as **M-A-0089-2** + **IO-A-0089-6**. |
| **IO-A-0058-5** | PM missing `## Turn Start` | **Still absent.** `product-manager.agent.md:12-15` has Session Start only. Third consecutive cycle (ICON-0046 IO-A-4 → ICON-0058 → here). Re-filed as **IO-A-0089-5**. |
| **IO-A-0058-6** | `web_search`/`web_fetch` without platform annotation | **Still absent**, and rationale strengthened — ADR-004:32's prohibitive clause makes this a conformance defect rather than a missing courtesy. Third consecutive cycle. Re-filed as **m-A-0089-1** (promoted from improvement to Minor defect). |
| **IO-A-3 / O-M3** | `.context/cache/` pruning ownership unassigned | **Still absent.** `researcher.agent.md:27` writes unconditionally; no pruning rule in the researcher or `context-maintenance`. Third consecutive cycle. Re-filed as **IO-A-0089-4**. |
| **ICON-0058 Observation 5** | `tester.agent.md:18-20` skill-routing conditional as a novel agent-body pattern | **Unchanged and un-propagated.** Still the only routing conditional in an agent body; the predicted drift did not materialize. Downgrade to "watch." `[see agent-evaluation]` |

### Net-new

1. **M-A-0089-1** (Moderate) — ADR-015's isolation contract is implemented for only @architect and @planner; 5 of 7 isolated specialists lack `## Inputs (from warmstart)` and cold-start-tolerance language, 3 of 7 lack `## Output Format` entirely. `agents/coder.agent.md`, `agents/tester.agent.md`, `agents/reviewer.agent.md`, `agents/researcher.agent.md`, `agents/context-specialist.agent.md`; contract asserted at `.context/decisions/015-all-specialists-isolated.md:20-21` and `skills/manager-routing-guide/SKILL.md:104-114`. `[see agent-evaluation]`

2. **m-A-0089-3** (Minor) — Bare `Step 3` cross-references at `agents/manager.agent.md:91,92` sit inside `## Context Discovery`'s own 1–5 numbered list while referring to Session Start Step 3; the file's own dominant convention (`:232`, `:244`, `:251`) is to qualify.

3. **m-A-0089-4** (Minor) — `agents/context-specialist.agent.md:82` carries an unqualified cross-*file* ordinal ("Task Completion Step 4") into `agents/manager.agent.md:216`, with no gate protecting it against renumbering.

4. **Structural Observation 5** (net-new) — `.claude/skills/icon-audit/scripts/structural-check.sh` validates only the icon-audit skill's own files (B.1–B.6); nothing structurally validates the agent corpus. Largest mechanization gap in this domain; addressed by **SO-A-3**.

5. **Structural Observation 2** (net-new, methodological) — working-tree `common-constraints` comparison yields false DIFFERS on Windows checkouts under `core.autocrlf=true`; blob-level comparison is authoritative. Any automated conformance check must normalize or read blobs.

---

## Verification Evidence

Commands run and their results (all read-only; no plugin source modified):

| Check | Command | Result |
|---|---|---|
| Audit structural check | `bash .claude/skills/icon-audit/scripts/structural-check.sh` | **Exit 0** — B.1, B.2, B.3, B.4, B.6 all OK. Scope note: validates the icon-audit skill only, not `agents/` (Observation 5). |
| common-constraints equality | `git cat-file -p HEAD:<agent>` block vs `HEAD:shared/common-constraints.md` | **BYTE-EQUAL ×9**; 0 CR bytes in all blobs |
| Word counts | `wc -w agents/*.agent.md shared/common-constraints.md skills/using-skills/SKILL.md` | manager 4,620; session totals 8,685 (mgr) / 6,459 (PM) — exact agreement with `ADR-008:43-46` |
| Table column invariant | per-table awk header-cells vs row-cells over `agents/*.md` + `shared/` | **No MISMATCH** — invariant holds corpus-wide |
| Tier subheading conformance | `grep '^### \(Hardcoded\|Default\|Discretionary\)' agents/*.agent.md` | **27/27** exact parentheticals |
| Frontmatter form | line-2 + `user-invocable` extraction ×9 | **9/9** `description: >`; `user-invocable` present and boolean |
| 2.0.0 conversion sweep | `grep -in 'gitlab\|jira\|confluence\|\bMR\b\|merge request'` over `agents/` | **Zero hits** |
| `Step N` resolution | `grep -o '[Ss]tep [0-9]*' agents/*.agent.md` + manual resolution of all 13 | **13/13 semantically correct**; 3 unqualified (m-A-0089-3, m-A-0089-4) |
| Isolation contract coverage | section-presence grep ×9 | `Inputs`=2/9, `Cold-start tolerant`=2/9, `Output Format`=4/7 specialists |
