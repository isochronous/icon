## Task: ICON-0084
## Branch: feature/ICON-0084-model-aware-delegation
## Objective: Make ICON delegation model-aware: the orchestrator must pick the model appropriate to the task — **Sonnet default, Haiku for basic tasks, Opus for complex ones** — and **every delegation prompt must require a model (tier) to be specified**. Improves cost/latency (cheap model for mechanical work) and quality (powerful model for hard work). Follow-up to the ICON-0081→0083 pipeline; distinct feature, own PR.
## Folder: .context/tasks/ICON-0084-model-aware-delegation/

## Decisions
- **Tier policy (user directive)**: Haiku = basic/mechanical; Sonnet = default; Opus = complex. Every delegation specifies a tier — a required field, not optional.
- **Portability (ADR-004)**: express selection as a TIER concept (basic/default/complex), map per harness. Claude Code Task tool takes a `model` param (haiku/sonnet/opus); Copilot CLI mechanism differs — design must state the portable tier + per-harness realization, and degrade gracefully where a harness lacks per-subagent model control.
- **Enforcement**: "every delegation specifies a model tier" → a **Hardcoded (Non-Negotiable)** behavior-tier rule + a required `Model`/tier field in the `## Context Warmstart` delegation template. Whether/how a gate can check instruction-content adherence: TBD in design (likely prose-enforced + an anti-rationalization row, not a hard gate).
- Architecture-primary: @architect design-first before implementation (mirrors ICON-0081/0082).
- **Interacts with ICON-0083 terseness**: adding a required directive to the just-tersened delegation surface — keep the addition lean (ADR-008); it's a small, high-value field.

## Key Files (candidate — confirm in design)
- `agents/manager.agent.md` — § Delegation + `## Context Warmstart` template (add required Model/tier field) + a tier-selection rule + a Hardcoded item + an anti-rationalization row. Primary surface.
- `agents/product-manager.agent.md` — PM also delegates (to @researcher); same requirement.
- `skills/manager-routing-guide/SKILL.md` — routing tables; natural home for the task-complexity→tier mapping per agent role (keeps the always-loaded manager lean, ADR-008).
- Possibly a per-role default-tier table (coder/tester/reviewer=Sonnet; architect=Opus; researcher=Sonnet; etc.) — placement TBD (routing-guide vs a new reference).
- `context_template/` — does any consumer-facing template need the model-tier convention? If the delegation contract is ICON-plugin-internal (agents/skills ship with plugin), likely no template touch → no iconrc bump. Confirm.
- `.context/decisions/014-*.md` — new ADR + rules-index row.
- `CHANGELOG.md` — `[Unreleased]` (consumer-facing: changes how the orchestrator delegates).

## Progress
- [x] ICON-0083 merged (PR #4); branch off fresh main
- [x] Create branch + initial plan.md
- [x] @architect design-first DONE → design.md. Tiers: basic→Haiku/default→Sonnet/complex→Opus + per-role defaults + signals. Enforcement: prose+Hardcoded+anti-rat+required `Model:` warmstart field, NO hard gate. Placement: full map in on-demand manager-routing-guide (0 budget); manager +94w, PM +68w (under ADR-008 triggers). Portability: tier concept + aliases; Claude sets Task `model` param, Copilot advisory. **No template/iconrc touch (plugin-internal).** ADR-014 drafted. 4 open Qs all rec "yes".
- [x] Accepted architect recommendations A-D (A: required field targets ISOLATED dispatches, inline planner/architect inherit session model — technical necessity; B: prose+anti-rat no gate; C: consumer phase-templates untouched for v1; D: model aliases not pinned IDs). Surfaced A & C to user as awareness.
- **Implementation (small, disjoint — parallel):**
  - [ ] **P1 — delegating agents**: `manager.agent.md` + `product-manager.agent.md` — required `Model:` (tier) field in `## Context Warmstart` `### Task` block, Hardcoded item, anti-rat row, 1-line tier rule + pointer to routing-guide. Terse (ICON-0083 standard). ← IN PROGRESS
  - [x] **P2 — routing-guide mapping** DONE: `manager-routing-guide` `### Model Tier Selection` (+569w on-demand; tiers table, complexity signals, per-role defaults, isolated-vs-inline, tier→alias per-harness realization). Existing tables untouched.
  - [x] **P3 — ADR-014 + docs** DONE: `decisions/014-model-aware-delegation.md` (`**Supersedes**: none`/`**Superseded-by**: none`) + rules-index row + README log. check-rules-index + context-graph --check exit 0 (47 nodes). CHANGELOG deferred to manager-close. **REVIEW FLAG: ADR-014 has a `## Related` footer (ADR-004/008) — ADR-013 used plain prose; F1 convention routes ADRs to bold-fields not `## Related`. Reviewer: consistency call (remove footer → plain prose, or accept).**
  - [x] @reviewer → **APPROVED with comments**, no blocking. Deltas confirmed (manager +111w, PM +70w < triggers); portability sound; pure insertions; release guard + no-iconrc intact; inline carve-out correctly not flagged (ICON-0085 owns it). 3 minors ↓.
  - [ ] **Fix** (ADR-014): remove `## Related` footer (F1 convention — ADRs use bold-fields+prose, not footer; reachable via rules-index+README); fix wording drifts (L28 "tier→model-ID"→"tier→model"; L30 stale "~94/68w"→actual/"under triggers"). KEEP manager inline realization (under budget, useful). ← IN PROGRESS
  - [x] Reviewer confirmed fix delta → **APPROVED to commit, final tree clean** (footer removal clean, ADR-014 reachable, wording fixes correct).
  - [x] Reconcile plan.md (this pass — Review Checkpoint stamped below).
  - [ ] CHANGELOG → retrospective → commit(s) → PR ← IN PROGRESS

## Review Checkpoint
Stamped 2026-07-18. @reviewer (code-quality-rules) covered the full ICON-0084 diff + the ADR-014 fix delta. Verdict: **APPROVED — no blocking findings.** Confirmed: tier policy stated identically everywhere (Sonnet default / Haiku basic / Opus complex); always-loaded deltas manager +111w, PM +70w (under ADR-008 triggers 425/350); full mapping on-demand in manager-routing-guide (+569w, unbudgeted); portability via tier concept + aliases + Copilot advisory degradation (ADR-004); pure insertions (common-constraints + existing rows/tables untouched); ADR-014 bold-fields + rules-index row + README log; gates green (context-graph 47 nodes, check-rules-index exit 0); release guard intact (plugin.json + context_template untouched → no iconrc bump). The inline @planner/@architect carve-out is correct for today; ICON-0085 owns revising it. Close-gate review item satisfied.

## Final Changed-File Set (ICON-0084, reviewed + green)
**New (1):** `.context/decisions/014-model-aware-delegation.md`. (+ task folder.)
**Modified (5):** `agents/manager.agent.md` (+111w), `agents/product-manager.agent.md` (+70w), `skills/manager-routing-guide/SKILL.md` (+569w on-demand), `.context/rules-index.md`, `.context/decisions/README.md`.
**Untouched (guards):** `.claude-plugin/plugin.json` (no release); `context_template/` (plugin-internal → no iconrc bump).

## Follow-up (queued next task)
- **ICON-0085 — isolate @architect & @planner** (user request 2026-07-18): refactor so architect and planner do NOT share context — they get a task and produce a structured report like every other specialist (isolated dispatch). **Couples with ICON-0084**: 0084's model-tier rule carves out @planner/@architect as inline (inherit session model); once 0085 isolates them, they take a model tier like other isolated dispatches — so 0085 OWNS updating 0084's carve-out (manager.agent.md tier rule, manager-routing-guide isolated-vs-inline note, ADR-014). Same files 0085 already touches. Design-first: self-contained task→report contract (warmstart in / structured report out) for architect+planner; revisit the "selective sub-agent context isolation" model (ICON 1.4.5) marking them shared; new ADR (or amend ADR-014). Sequenced AFTER ICON-0084 merges.

## Open Questions / Blockers
- Per-role DEFAULT tiers + the complexity signals that upgrade/downgrade (e.g. single-file mechanical → Haiku; architecture/security/ambiguous → Opus). Design to propose concrete mapping.
- Does the manager set the harness `model` param on the actual Task dispatch, AND state the tier in the prompt, or just the prompt? (Design: likely both where the harness supports it.)
- Portability degradation: if a harness can't set per-subagent model, the tier is advisory — how to express without breaking ADR-004.
- Enforcement realism: instruction-content can't be hard-gated like a pre-commit check; is a prose Hardcoded rule + anti-rat row sufficient, or is there a lightweight check?

## Constraints
- Pure-content (ADR-005); portability (ADR-004: no tool-specific-only capability — express as tier, map per harness).
- ADR-008 always-loaded budget: keep the manager/PM addition minimal (we just tersened these); put the mapping table in the on-demand routing-guide skill.
- The live context-graph + rules-index gates run on `.context/` commits; new ADR needs its rules-index row + reachability.
- `context_template/` touch → iconrc bump (now 1.11) same commit — avoid if the contract stays plugin-internal.
- Release guard: no `plugin.json` bump / no release unless explicitly instructed this turn.
- Terseness-calibration standard (ICON-0083) applies to any prose added here — terse + behavior-clear.
