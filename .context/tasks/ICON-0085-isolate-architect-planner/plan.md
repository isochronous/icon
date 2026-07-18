## Task: ICON-0085
## Branch: feature/ICON-0085-isolate-architect-planner
## Objective: Refactor so @architect and @planner do NOT share the manager's context — they receive a self-contained task (warmstart) and return a structured report, exactly like the other specialist agents (@coder/@tester/@reviewer/@researcher). Removes the special-case "inline / shared-context" treatment from ICON's "selective sub-agent context isolation" model. Follow-up to ICON-0084 (user request 2026-07-18).
## Folder: .context/tasks/ICON-0085-isolate-architect-planner/

## Decisions
- **User directive**: architect & planner become isolated task→report dispatches like every other specialist. No longer inline/shared-context.
- **Couples with ICON-0084 (now merged)**: 0084's model-tier rule carves out @planner/@architect as inline ("inherit the session model"). Once isolated, they take a model tier like other isolated dispatches → this task MUST update that carve-out (manager.agent.md tier rule, `manager-routing-guide` isolated-vs-inline note + per-role default table, ADR-014). Same files.
- Architecture-primary: @architect design-first before implementation.

## Key Files (candidate — confirm via exploration)
- `skills/manager-routing-guide/SKILL.md` — the "Sub-Agent Context Isolation" guidance (which agents are inline vs isolated) + the ICON-0084 `### Model Tier Selection` per-role table marking planner/architect inline. Primary surface.
- `agents/manager.agent.md` — any instruction to dispatch architect/planner with shared context; the model-tier carve-out; the delegation/warmstart usage.
- `agents/architect.agent.md`, `agents/planner.agent.md` — ensure each has a clear self-contained task→report contract (warmstart in / structured report out). May already; the ISOLATION guidance is what changes.
- `.context/decisions/` — the ADR behind "selective sub-agent context isolation" (find it) — amend or supersede; + reconcile ADR-014's carve-out. Possibly new ADR-015.
- `.context/domains/` or workflow docs describing the delegation/isolation model.
- `CHANGELOG.md` — `[Unreleased]` (changes orchestration behavior).
- `context_template/`? — likely none (delegation model is plugin-internal); confirm.

## Progress
- [x] ICON-0084 merged (PR #5); branch off fresh main
- [x] Create branch + initial plan.md
- [x] Explore DONE. Findings: (1) **No ADR** governs isolation — only `manager-routing-guide:88-109` (§ Sub-Agent Context Isolation) + CHANGELOG v1.4.5. (2) Inline = ONLY @planner (`:105`) + @architect (`:106`); isolated = @researcher/@coder/@tester/@reviewer/@context-specialist. **Isolating the 2 leaves inline with ZERO members → collapse the concept.** (3) "Inline" = shared context, no separate window, no model param (session model), dispatched conversationally (NOT via warmstart template). (4) Both agent defs ALREADY have structured report contracts (architect `## Architectural Assessment`; planner `## Story Split`/`## Feature`) but ASSUME shared context (self-gather; planner assumes interactive clarifying Qs) — need an inputs/warmstart-received contract + cold-start tolerance. (5) **Warmstart gap**: template has NO `### Architecture` field — cold architect/planner lose architecture context (ICON-0082 cold-resume concern) → extend template. (6) ICON-0084 carve-out flip list (precise): routing-guide `:113/:139/:140/:142-144`; manager `:146/:163/:233/:237/:244`; ADR-014 `:24-27/:32-33/:47-48`; PM `:55/:190`. (7) Plugin-internal → NO template/iconrc bump; ADR-014 amend/supersede (Accepted) + opportunity for a NEW ADR governing the isolation model.
- [x] @architect design-first DONE → design.md. All specialists isolated (inline concept removed); ONE new warmstart `### Architecture` field + `## Inputs (from warmstart)` sections + cold-start tolerance; planner live-clarify → report-borne `### Open Questions & Assumptions` (proceed on assumptions, manager resolves blocking + re-dispatches); 10-site carve-out flip; tiers architect→Opus, planner→Sonnet(→Opus); NEW ADR-015 + ADR-014 `**Superseded-by**`-field-only update. 9 files, plugin-internal (no template/iconrc/plugin.json).
- [x] Accepted architect OQ-1..4: planner=Sonnet default (architect=Opus); per-agent `ask_user` precedence (NO ×9 shared-block edit); ADR-015 new + ADR-014 field-only; generalize PM anti-rat row. Surfaced OQ-1/OQ-2 to user as awareness.
- **Implementation (9 files; disjoint batches):**
  - [x] **B1 — agent contracts** DONE: architect + planner got `## Inputs (from warmstart)` + cold-start tolerance + `### Open Questions & Assumptions` report subsections; planner live-clarify removed (workflow step 1 + default-tier bullet + trailing constraint → report-borne assumptions). Report templates otherwise intact (additive). Architect OQ wording adapted per-agent ("gap the assessment depends on").
  - [ ] **B2 — manager + routing-guide (core reconciliation)**: `manager.agent.md` (warmstart `### Architecture` field; flip carve-out `:163/:233/:244`; remove "isolated vs shared" clause `:237`) + `manager-routing-guide/SKILL.md` (collapse § Sub-Agent Context Isolation to "all isolated"; remove § Isolated-vs-inline `:142-144`; flip `*(inline)*` tier rows `:139-140`; `:113` qualifier). ← Wave 1
  - [x] **B4 — ADRs** DONE: `decisions/015-all-specialists-isolated.md` (Accepted; `**Supersedes**: ADR-014 (carve-out only)`); ADR-014 `**Superseded-by**: ADR-015` (bidirectional edges); rules-index row; README log (014 status → carve-out superseded). check-rules-index + context-graph --check exit 0 (48 nodes).
  - [x] **B2 — manager + routing-guide** DONE: inline concept collapsed → "all specialist dispatches are isolated"; `### Architecture` warmstart field (manager +42w < 425 trigger); carve-out flipped (tier rule/Hardcoded/Default all "every delegation"); § Isolated-vs-inline removed; @planner→default, @architect→complex. Grep: ZERO inline/session-model refs remain (2 unrelated false-positives). **REVIEW FLAG: @architect row put "routine pattern-conformance check" under `Downgrade → basic`, but design §7a prose says →`default` (architecture check isn't Haiku-mechanical) — reviewer confirm/fix to `default`.**
  - [ ] **B3 — PM**: `product-manager.agent.md` broaden tier rule `:55` to name @architect/@planner + generalize anti-rat row `:220`. ← IN PROGRESS
  - [x] @reviewer → **Changes requested** (1 blocking + 2 minors). Approved: isolation coherent, warmstart sufficient (`### Architecture` = the cold-resume slice), ADR-015↔014 bidirectional edges resolve (014 prose intact), carve-out otherwise complete (grep: 0 surviving inline refs), gates + release guard intact, deltas under triggers (mgr +42, PM +14).
  - [ ] **Fix** (@coder): **6a [blocking]** routing-guide:131 @architect downgrade `→ basic` → **`default`** (architecture check isn't Haiku-mechanical); **6b** PM:190 "every isolated delegation"→"every delegation"; **planner** Inputs: add half-line that report-borne open questions take precedence over the shared `ask_user` line for isolated dispatch. ← IN PROGRESS
  - [x] Reviewer confirmed fix delta → **Approved to commit** (6a architecture-downgrade→default overrides column; 6b symmetric; planner precedence closes cold-reader gap; gates green, common-constraints untouched).
  - [x] Reconcile plan.md (this pass — Review Checkpoint stamped below).
  - [ ] CHANGELOG → retrospective → commit(s) → PR ← IN PROGRESS

## Review Checkpoint
Stamped 2026-07-18. @reviewer (code-quality-rules) covered the full ICON-0085 diff + the 3-fix delta. Verdict: **APPROVED — no blocking findings** (after the 6a architecture-downgrade fix). Confirmed: @architect/@planner are coherent isolated task→report specialists (Inputs contract, cold-start tolerant, report-borne Open Questions & Assumptions; planner live-clarify fully removed); carve-out flip COMPLETE (grep: 0 surviving inline/session-model refs; tier rule universal; @architect=complex, @planner=default, downgrade→default); inline concept collapsed (§ Isolated-vs-inline removed, no dangling refs); `### Architecture` warmstart field = sufficient cold-resume slice; ADR-015↔014 bidirectional bold-field edges resolve (014 prose intact as superseded record); rules-index + README present; gates green (context-graph 48 nodes, check-rules-index exit 0); ADR-008 deltas mgr +42 / PM +14 (under 425/350); release guard intact (plugin.json + context_template untouched → no iconrc bump). Close-gate review item satisfied.

## Final Changed-File Set (ICON-0085, reviewed + green)
**New (1):** `.context/decisions/015-all-specialists-isolated.md`. (+ task folder.)
**Modified (8):** `agents/architect.agent.md`, `agents/planner.agent.md`, `agents/manager.agent.md` (+42w), `agents/product-manager.agent.md` (+14w), `skills/manager-routing-guide/SKILL.md`, `.context/decisions/014-model-aware-delegation.md` (Superseded-by field), `.context/decisions/README.md`, `.context/rules-index.md`.
**Untouched (guards):** `.claude-plugin/plugin.json` (no release); `context_template/` (plugin-internal → no iconrc bump); `shared/common-constraints.md` (per-agent ask_user precedence, no ×9 edit).

## Open Questions / Blockers
- WHY are architect/planner currently inline? (Likely: architecture/planning benefit from the manager's full working context.) Isolating them means the warmstart must carry ENOUGH context for a cold architect/planner to work — the ICON-0082 handoff-hardening lessons apply. Design must ensure the warmstart template gives architect/planner sufficient context (they can't rely on shared session state).
- Does isolating them change routing/latency/quality? (Isolated = fresh context, must be warmstarted well; benefit = clean context, model-tier control, parallelism.) Note tradeoffs.
- Reconcile ICON-0084: planner/architect move from "inline (session model)" to "isolated (specify tier)" — architect default = complex/Opus; planner default = default/Sonnet or complex? Design to set.
- The "selective context isolation" model (ICON 1.4.5) may now have NO inline agents left — does the whole inline/shared-context concept get removed, or do other agents remain inline? Confirm in exploration.

## Constraints
- Pure-content (ADR-005); portability (ADR-004). ADR-008 — keep always-loaded additions minimal (terse per ICON-0083 terseness-calibration standard).
- Live context-graph + rules-index gates on `.context/` commits; new/amended ADR needs its rules-index row + reachability.
- `context_template/` touch → iconrc bump (now 1.11) same commit — avoid if plugin-internal.
- Release guard: no `plugin.json` bump / no release unless explicitly instructed this turn.
- ADR cross-ref convention (ICON-0084): ADRs use bold-fields + plain prose, not `## Related`.
