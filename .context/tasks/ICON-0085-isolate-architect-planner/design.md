# Design: ICON-0085 — Isolate @architect and @planner (task→report via warmstart)

**Status**: DESIGN — awaiting user sign-off. No implementation in this document. A later @coder implements after approval.
**Author**: @architect
**Date**: 2026-07-18
**Follows**: ICON-0084 (model-aware delegation, merged PR #5)

---

## 1. Summary

Make @architect and @planner **isolated task→report dispatches** — self-contained warmstart in, structured report out — exactly like @coder/@tester/@reviewer/@researcher/@context-specialist. They are today the **only two inline (shared-context) specialists**; isolating them leaves the inline category with **zero members**, so the whole inline-vs-isolated split collapses to a single rule: **all specialist dispatches are isolated.**

This forces four coupled changes: (a) both agent defs gain an INPUTS/warmstart-received contract and become cold-start tolerant; (b) the `## Context Warmstart` template gains one `### Architecture` field (the only context these two self-gathered that the template doesn't already carry); (c) @planner's live "clarify with the manager" loop is replaced by a report-borne **Open Questions & Assumptions** section; (d) the ICON-0084 model-tier carve-out ("inline agents run at session model") is flipped — @architect → **complex/Opus**, @planner → **default/Sonnet (upgrade→complex)**. A new **ADR-015** records the isolation model (which had no ADR) and resolves ADR-014's inline carve-out.

**Recommendation: Approve.** Pure-content, plugin-internal, no `context_template/` touch, no iconrc bump, no release. ADR-008 delta is one conditional warmstart field.

---

## 2. Architectural Assessment

### Decision framework (7 criteria)

| Criterion | Assessment |
|-----------|-----------|
| **Consistency** | Strongly positive. Removes a special case: five specialists already dispatch isolated via warmstart; this makes it uniform. One dispatch model instead of two. |
| **Coupling** | Reduces coupling. Inline dispatch coupled @architect/@planner to the manager's live session state; isolation makes the warmstart the single, explicit interface. |
| **Scope** | Context becomes explicitly scoped per dispatch (warmstart) rather than implicitly inherited from the whole session — a scope tightening. |
| **Reusability** | Reuses the existing warmstart template + tier machinery + both agents' existing report contracts. One new template field; no new mechanism. |
| **Compatibility** | ADR-004 portability preserved (tier realization already degrades to advisory on Copilot). ADR-005/008 respected. The behavior change is the planner clarification loop (§5). |
| **Scalability** | Enables parallel dispatch of @architect/@planner (impossible while inline) and per-role tiering. |
| **Testability** | Pure-content; validated by JSON-parse + manifest validator + pre-commit context-graph/rules-index gates. No runtime test surface. |

### Why they were inline, and why isolation is now correct

The inline rationale (`manager-routing-guide` SKILL.md:104-107) was: @planner "needs full task history… benefits from clarifying questions with the manager"; @architect "design decisions often require iteration; needs the accumulated decision context." Both reduce to **two** real needs — (1) access to accumulated context, and (2) interactive iteration.

- Need (1) is **not** a reason to stay inline. Every isolated agent already has filesystem access and receives distilled context via the warmstart. "Isolated" means *no shared conversation memory*, not *no repo access*. The gap is only the slice of context that lives in the live session and isn't yet on disk — which the warmstart's `### Task > Prior work` and the new `### Architecture` field carry (ICON-0082 / ADR-013 cold-resume principle: carry what can't be re-derived from committed files).
- Need (2), interactive iteration, is the one genuine loss. §5 replaces it with the warmstart + report-open-questions loop and states the tradeoff honestly.

---

## 3. Isolated task→report contract for @architect and @planner

Both agent defs already have clean **report** contracts (architect `## Architectural Assessment` at `architect.agent.md:44-80`; planner `## Story Split` / `## Feature` at `planner.agent.md:47-91`). What they lack is an **INPUTS** contract and **cold-start tolerance** — both assume shared session state.

### 3a. @architect — add an `## Inputs (from warmstart)` section

Insert after `## Scope` (before `## When to Invoke`). Proposed content:

```markdown
## Inputs (from warmstart)

You are dispatched **isolated** — you do not share the orchestrator's session. Your task arrives as a `## Context Warmstart` block carrying: `### Task` (objective, current step, prior decisions), `### Architecture` (relevant `.context/architecture/` — or ADR/domain — excerpts, plus any session design decisions not yet persisted to disk), `### Domain`, `### Applicable Rules`, and `### Scope Boundaries`.

**Cold-start tolerant**: the warmstart's architecture excerpt is a distilled pointer, not a replacement for the source. Read `.context/architecture/`, `.context/standards/`, and `.context/domains/` directly to fill any gap — you have full repo access. If a fact the assessment depends on is absent from both the warmstart and the repo, surface it as a **blocking gap** in your report (do not guess).
```

Then adjust the existing `## Workflow` step 1 (`architect.agent.md:22`) — it already says "Gather context: `.context/architecture/`…"; append a clause: "…(the warmstart supplies task-relevant excerpts; read the source files to fill gaps)." Keeps the self-gather behavior, now framed as gap-filling rather than the sole source.

**Report contract**: unchanged. `## Architectural Assessment` already returns a self-contained structured artifact — exactly a task→report shape. No edit needed.

### 3b. @planner — add an `## Inputs (from warmstart)` section

Insert after `## Scope` (before `## Workflow`). Proposed content:

```markdown
## Inputs (from warmstart)

You are dispatched **isolated** — you do not share the orchestrator's session and cannot ask the manager questions mid-task. Your task arrives as a `## Context Warmstart` block carrying: `### Task` (objective, current step, prior decisions), `### Architecture`, `### Domain`, `### Applicable Rules`, and `### Scope Boundaries`.

**Cold-start tolerant**: read `.context/domains/`, `.context/architecture/`, `.context/standards/`, and `.context/tasks/` directly to fill gaps — you have full repo access. **Ambiguity handling**: you cannot clarify live. Proceed on explicit, stated assumptions and record every ambiguity in the report's **Open Questions & Assumptions** section (see Output Format). The manager resolves blocking questions and re-dispatches if the breakdown depends on the answer.
```

**Report contract**: add one section to *both* output templates (`## Story Split` and `## Feature`) — see §5.

---

## 4. Warmstart template extension (`agents/manager.agent.md:133-161`)

The template already carries `### Project`, `### Task`, `### Domain`, `### Applicable Rules`, `### Scope Boundaries`. Mapping the three sources @architect/@planner self-gather:

| Self-gathered source | Already in warmstart? |
|----------------------|-----------------------|
| `.context/standards/` | Yes — `### Applicable Rules` (rows from rules-index: standards/workflows/decisions) |
| `.context/domains/` | Yes — `### Domain` |
| `.context/architecture/` | **No — gap** |

So **only one field is missing**. Workflows and decisions excerpts are **not** separately needed — they are already covered by `### Applicable Rules` (which explicitly draws standards/workflows/decisions rows from the rules-index). Adding them would duplicate and bloat the always-loaded template against ADR-008. **Decision: add exactly one field, `### Architecture`.**

Insert between `### Domain` and `### Applicable Rules`:

```markdown
### Architecture
- [Relevant .context/architecture/ excerpts — module structure, boundaries, system-design constraints. Where no architecture/ dir exists, the governing ADR/domain excerpts.]
- [Session design decisions not yet persisted to disk — the context a cold specialist can't re-derive from files.]
```

Guidance line to add near the template's "drop sections that don't apply" note (`manager.agent.md:131`): "Populate `### Architecture` for @architect and @planner dispatches (and any design-touching @coder step); drop it otherwise."

**ADR-008 accounting**: one conditional field, ~2 lines, in the always-loaded manager role. Well under the re-inventory trigger; the tier tables and isolation rules it interacts with live in the on-demand `manager-routing-guide` skill (zero always-loaded cost). The `### Architecture` field is the ICON-0082/ADR-013 cold-resume guarantee for these two agents: the warmstart must carry enough that a cold specialist can work, and the not-yet-persisted session design decisions are precisely what it can't reconstruct from the repo.

---

## 5. The planner interactive-clarification replacement

**Current behavior** (to remove): @planner "clarifies ambiguous requirements with specific questions" via live dialogue with the manager — `planner.agent.md:20` (Workflow step 1), `:104` (Default tier: "Ask clarifying questions when requirements are ambiguous"), `:157` (constraint: "Always ask clarifying questions if requirements are ambiguous"), and the inline rationale at SKILL.md:106.

**Replacement**: @planner surfaces ambiguities as **stated assumptions** (proceed) and **open questions** (report) in one structured pass. The manager reads the report, resolves blocking questions, and re-dispatches only if the breakdown depends on an answer.

Add this section to **both** planner output templates (after `### Sequencing…` in `## Story Split`; after `### Notes` in `## Feature`):

```markdown
### Open Questions & Assumptions
- **Assumption**: [what I assumed in order to proceed] — manager: correct if wrong.
- **Open question (blocking)**: [ambiguity that changes the breakdown; I could not proceed reliably] — manager resolves and re-dispatches.
- **Open question (non-blocking)**: [ambiguity I proceeded past under a stated assumption above].
```

Edits that go with it:
- Workflow step 1 (`:20`): "Clarify ambiguous requirements with specific questions" → "Identify ambiguous requirements; record them as stated assumptions and open questions in the report (you cannot clarify live when isolated)."
- Default tier row (`:104`): "Ask clarifying questions when requirements are ambiguous" → "Record ambiguities as stated assumptions + open questions in the report — no live dialogue when isolated."
- Constraint (`:157`): "Always ask clarifying questions if requirements are ambiguous" → "Never block on live clarification — surface ambiguities as assumptions/open questions in the report; the manager resolves blocking ones and re-dispatches."

**common-constraints tension (documented, not resolved by edit)**: the shared block (`planner.agent.md:124-125`, injected into all nine agents) says "Use `ask_user` for all input — never embed questions in response text." An isolated planner has no `ask_user` channel and *must* embed open questions in its report. The planner-specific instructions above **take precedence** for isolated dispatch — the same precedence every other isolated agent (coder/tester/reviewer) already operates under (they surface blockers in their reports, not via `ask_user`). **Do not edit the shared common-constraints block** — it is verbatim-injected into all nine agents and a change there is cross-cutting (flagged as an architecture trigger in `phase-architecture.md:44`). Recorded as **Open Question OQ-2** for the user: soften the shared line, or keep the documented per-agent precedence (recommend: keep precedence).

**Tradeoff — stated honestly.** Isolation trades interactive iteration for clean context + per-role model tiers + parallelism — the exact benefit inline dispatch was preserving. The loss: a blocking ambiguity now costs a dispatch round-trip (report → manager resolves → re-dispatch) instead of a cheap live turn. The offset: (1) the warmstart **front-loads** the context that live Q&A used to discover, so fewer questions arise; (2) the **assumptions-first** discipline means most ambiguities resolve in a single pass — the planner proceeds on a stated assumption the manager accepts or corrects in the next step, with no re-dispatch; (3) only genuinely breakdown-altering ambiguities force a re-dispatch. Net: rare extra round-trips, in exchange for clean isolated context, tierability, and parallel planning. On balance the isolation benefits dominate for a plugin whose whole delegation model is otherwise uniformly isolated.

---

## 6. Collapse the inline/isolated concept

With zero inline members, the split disappears. End state:

### 6a. `skills/manager-routing-guide/SKILL.md`

- **Intro (`:10`)**: remove "or choosing isolated vs. shared sub-agent context" — no such choice remains.
- **§ Sub-Agent Context Isolation (`:88-109`)**: rewrite. Replace the two-table (isolated / shared-inline) structure with a single statement + one table. Proposed:

  ```markdown
  ## Sub-Agent Context Isolation

  **All specialist dispatches are isolated** — each runs in a separate context window
  via the task tool, receives a self-contained `## Context Warmstart`, and returns a
  structured report. The manager incorporates only the report (findings, artifacts,
  decisions) into its context — never the agent's full reasoning trail.

  | Agent | Manager needs (the report) |
  |-------|----------------------------|
  | @researcher | Findings and citations, not the web-fetch trail |
  | @planner | The task breakdown + open questions/assumptions, not the exploration |
  | @architect | The assessment (recommendation + rationale), not the file reads |
  | @coder | The diff and build proof, not the compiler noise |
  | @tester | Pass/fail counts and what was written, not the runner output |
  | @reviewer | Findings, not the many file reads |
  | @context-specialist | Completion summary + file list, not the generation trail |
  ```

- **Per-role tier rows (`:139-140`)**: flip the two `*(inline)*` rows — see §7.
- **§ Isolated vs. inline (`:142-144`)**: **remove entirely.** Its content ("the tier is set via per-subagent model control, which only applies to isolated dispatches; inline agents run at session model") is moot once no agent is inline. The tier→model realization note (`:146-161`) is unaffected and stays.

### 6b. `agents/manager.agent.md`

- **Delegation intro (`:131`)**: "For isolated agents (separate context windows), use this template" → "For specialist dispatches, use this template" (all are isolated now; the "(separate context windows)" gloss is no longer a distinguishing clause).
- **Hardcoded routing rule (`:237`)**: remove "or choosing isolated vs. shared sub-agent context" from the trigger list.
- Tier-rule wording (`:163`, `:233`) and Default rule (`:243`): see §7 (drop the now-redundant "isolated" qualifier).

---

## 7. Flip the ICON-0084 model-tier carve-out

### 7a. Per-role default tiers (the design call)

| Agent | Default | Upgrade → complex when… | Downgrade when… | Justification |
|-------|---------|--------------------------|-----------------|---------------|
| **@architect** | **complex** (Opus) | — (already top) | → default for a routine pattern-conformance check | Architecture/design decisions are the canonical `complex → Opus` signal (SKILL.md:127). Design is Opus-worthy. |
| **@planner** | **default** (Sonnet) | large or cross-cutting breakdown; ambiguous/underspecified requirements | → basic for a trivial re-sequence of an existing plan | "Planning a medium task" is an explicit `default → Sonnet` signal (SKILL.md:126). Standard-pattern breakdown is Sonnet work; upgrade on the same ambiguity/cross-cutting signals that upgrade @coder/@reviewer. |

Rationale for the **planner = default (not complex)** choice: a breakdown of a well-scoped feature into sequenced tasks is judgment work but *standard-pattern* judgment — the same class as a normal code review or a bounded refactor, both of which default to Sonnet. Reserving Opus for the genuinely hard planning cases (many-story splits, cross-module sequencing, ambiguous requirements) matches ICON-0084's "start at role default; one strong complexity signal upgrades" philosophy and avoids burning a frontier model on routine breakdowns. @architect defaults to complex because *every* architecture dispatch is, by the tier definition, a complex-signal task.

### 7b. Site-by-site edits

| # | File / anchor | Current | New |
|---|---------------|---------|-----|
| 1 | `manager-routing-guide` SKILL.md `:113` | "Every **isolated** delegation names a tier…" | "Every delegation names a tier…" (all are isolated; drop the qualifier) |
| 2 | SKILL.md `:139` | `@planner *(inline)* \| inherits session model \| — \| —` | `@planner \| default \| large / cross-cutting / ambiguous breakdown \| trivial re-sequence of an existing plan` |
| 3 | SKILL.md `:140` | `@architect *(inline)* \| inherits session model — Opus-worthy work \| — \| —` | `@architect \| complex \| — \| routine pattern-conformance check` |
| 4 | SKILL.md `:142-144` (§ Isolated vs. inline) | whole subsection | **remove** (see §6a) |
| 5 | `manager.agent.md` `:163` | "every isolated delegation names a tier" | "every delegation names a tier" |
| 6 | `manager.agent.md` `:233` (Hardcoded) | "Every isolated delegation specifies a model tier…" | "Every delegation specifies a model tier…" |
| 7 | `manager.agent.md` `:237` (Hardcoded) | "…or choosing isolated vs. shared sub-agent context…" | remove that clause (see §6b) |
| 8 | `manager.agent.md` `:243` (Default) | "Use the delegation warmstart template for isolated agent dispatches" | "Use the delegation warmstart template for all specialist dispatches" |
| 9 | `agents/product-manager.agent.md` `:55` | "state a tier in every isolated (@researcher) delegation — default…complex…basic…" | broaden to name all three it dispatches: "state a tier in every delegation — @researcher default (complex for ambiguous/novel deep research, basic for a single-fact lookup); **@architect complex**; **@planner default (complex for a large/ambiguous breakdown)**." |
| 10 | `product-manager.agent.md` `:220` (anti-rat) | "@researcher can run on whatever model" | generalize subject to "A specialist can run on whatever model" (or leave — minor; recommend generalize for consistency) |

PM note: PM triggers @researcher, @architect, and @planner (product-manager.agent.md:34/39/44) and previously treated architect/planner as inline. Post-change PM dispatches all three **isolated via the warmstart** and names a tier for each. No new PM mechanism — same tier vocabulary, broadened scope. ADR-008 PM delta: a few words on one line.

---

## 8. ADR decision

**Recommendation: create ADR-015 (new), and update only ADR-014's `**Superseded-by**` field.** Do **not** rewrite ADR-014's Decision prose.

Justification:
1. **The isolation model has no ADR at all** — it lived only in a skill (`manager-routing-guide` §88-109) + a CHANGELOG line. This is a documented gap (plan.md finding 1). A first-class architectural decision — *how every specialist is dispatched* — deserves its own ADR regardless of the ADR-014 interaction.
2. **ADR-014 is Accepted; its core decision is unchanged.** Model-aware tiered delegation still stands in full. Only its *inline carve-out* clause ("inline agents run at the session model") is obsoleted. Rewriting an accepted ADR's Decision to delete a clause mutates the historical record; superseding the clause via a new ADR preserves it.
3. A new ADR yields a clean rules-index row for "why all specialists are isolated / task→report."

**ADR-014 edit (field only, graph-reachability seam per ICON-0081/ADR-012):**
`**Superseded-by**: none` → `**Superseded-by**: ADR-015 (inline-agent carve-out only; the tiered-delegation core remains in force)`

### 8a. Proposed ADR-015 (`.context/decisions/015-all-specialists-isolated.md`)

```markdown
# ADR-015: Sub-agent isolation — all specialists dispatched task→report

**Date**: 2026-07-18
**Status**: Accepted
**Supersedes**: ADR-014 (inline-agent carve-out only — the tiered-delegation core of ADR-014 remains in force)
**Superseded-by**: none

## Context

ICON ran two dispatch models. Five specialists (@researcher, @coder, @tester,
@reviewer, @context-specialist) dispatched **isolated** — a separate context
window, a self-contained `## Context Warmstart`, a structured report back. Two
(@planner, @architect) ran **inline** — sharing the manager's live session,
dispatched conversationally, no per-subagent model. The inline rationale was
access to accumulated context and interactive iteration. The isolation model
itself had no ADR; it lived only in the `manager-routing-guide` skill. ICON-0084
(ADR-014) then had to carve inline agents out of the required per-delegation model
tier, since inline agents take no per-subagent model — a documented asymmetry.

## Decision

**All specialist dispatches are isolated** — task→report via the `## Context
Warmstart`. @planner and @architect join the isolated set; the inline/shared-
context category is removed (it had exactly those two members). Both agents gain
an INPUTS/warmstart-received contract and are cold-start tolerant: they read
`.context/` directly to fill gaps and surface unrecoverable gaps in their reports
rather than relying on shared session memory. The warmstart template gains one
`### Architecture` field — the only context these two self-gathered that the
template didn't already carry (standards→Applicable Rules, domains→Domain already
existed) — carrying `.context/architecture/` (or ADR/domain) excerpts plus session
design decisions not yet on disk (the ICON-0082/ADR-013 cold-resume guarantee).
@planner's live clarification loop is replaced by an Open Questions & Assumptions
report section: it proceeds on stated assumptions and the manager resolves blocking
questions and re-dispatches. With no inline agents, every delegation now names a
model tier under ADR-014's mechanism — resolving ADR-014's inline carve-out.
Per-role defaults: @architect → complex (Opus, design is Opus-worthy), @planner →
default (Sonnet, upgrade→complex for large/ambiguous breakdowns). Plugin-internal
only — no `context_template/` change, no iconrc bump. Pure-content (ADR-005),
portable (ADR-004 — architect's Opus tier degrades to advisory on Copilot like
every other isolated tier), ADR-008-lean (one conditional always-loaded field).

## Consequences

**Positive:**
- One uniform dispatch model; the special case is gone.
- @architect/@planner become parallelizable and independently tierable.
- Explicit warmstart interface replaces implicit session-state coupling.
- The isolation model finally has an ADR of record.

**Negative:**
- @planner loses live clarification; a blocking ambiguity costs a dispatch
  round-trip instead of a live turn. Mitigated by warmstart front-loading and
  assumptions-first planning (most ambiguities resolve in one pass).
- Cold @architect/@planner depend on the manager populating the warmstart well;
  an under-filled `### Architecture`/`Prior work` degrades output. Mitigated by
  the cold-start-tolerant self-read and the ADR-013 cold-resume discipline.
- A residual tension: the shared common-constraints `ask_user` line vs. report-
  borne open questions — resolved by documented per-agent precedence, not a
  cross-cutting shared-block edit.

## Alternatives Considered

1. **Keep @architect/@planner inline** — rejected; perpetuates a two-model split
   for two agents whose only real inline need (accumulated context) the warmstart
   already carries, and blocks tiering + parallelism.
2. **Amend ADR-014 in place** (delete its carve-out clause) — rejected; mutates an
   accepted record and still leaves the isolation model with no ADR of its own.
3. **Add workflows/decisions excerpt fields to the warmstart too** — rejected;
   `### Applicable Rules` already carries them; duplication bloats the always-
   loaded template against ADR-008.
```

### 8b. rules-index row (`.context/rules-index.md`, Decisions table)

Add after the ADR-014 row:

```markdown
| 015 | Deciding how a specialist sub-agent is dispatched — all specialists run isolated (task→report via the warmstart); why no agent runs inline/shared-context | [decisions/015-all-specialists-isolated.md](decisions/015-all-specialists-isolated.md) |
```

(The rules-index is regenerated by the context-graph scan at commit; the coder must ensure ADR-015's `**Supersedes**`/ADR-014's `**Superseded-by**` cross-refs are reachable so the pre-commit graph gate passes.)

### 8c. plan.md Architecture Decision Capture block (per `phase-architecture.md:75-83`)

```markdown
### Architecture Decision — isolate @architect and @planner (all specialists isolated)
**Date:** 2026-07-18
**Decision:** Approve with modifications (pending user sign-off)
**Rationale:** Collapses the inline/isolated split (zero inline members remain) to a single uniform task→report dispatch model; unlocks per-role tiering and parallelism; makes the warmstart the explicit context interface.
**Modifications required:** Add `### Architecture` warmstart field; add INPUTS sections to both agent defs; replace planner live-clarification with report Open Questions & Assumptions; flip ICON-0084 tier carve-out (@architect complex, @planner default); create ADR-015 + update ADR-014 Superseded-by.
**Risks flagged:** Cold-context under-fill (mitigated by cold-start self-read); planner round-trip latency (mitigated by front-loading + assumptions-first); common-constraints ask_user tension (documented precedence).
**Promote to ADR?:** yes — ADR-015 drafted (§8a); also resolves ADR-014's inline carve-out.
```

---

## 9. File list (for @coder, post-approval)

| # | File | Change | Always-loaded? |
|---|------|--------|----------------|
| 1 | `agents/manager.agent.md` | Add `### Architecture` warmstart field + populate-guidance line; drop "isolated" qualifiers in delegation intro (`:131`), tier paragraph (`:163`), Hardcoded rule (`:233`, `:237`), Default rule (`:243`) | Yes (manager) — keep terse |
| 2 | `skills/manager-routing-guide/SKILL.md` | Rewrite intro clause (`:10`) + § Sub-Agent Context Isolation (`:88-109`); flip per-role tier rows (`:139-140`); remove § Isolated vs. inline (`:142-144`); drop "isolated" qualifier (`:113`) | No (on-demand skill) |
| 3 | `agents/architect.agent.md` | Add `## Inputs (from warmstart)` section; adjust Workflow step 1 gap-fill clause | Loaded on dispatch |
| 4 | `agents/planner.agent.md` | Add `## Inputs` section; add `### Open Questions & Assumptions` to both output templates; edit Workflow step 1 (`:20`), Default tier row (`:104`), constraint (`:157`) | Loaded on dispatch |
| 5 | `agents/product-manager.agent.md` | Broaden tier rule (`:55`) to name @architect/@planner tiers; generalize anti-rat row (`:220`) | Yes (PM) — keep terse |
| 6 | `.context/decisions/015-all-specialists-isolated.md` | **New** ADR (§8a) | No |
| 7 | `.context/decisions/014-model-aware-delegation.md` | `**Superseded-by**` field only → ADR-015 (carve-out scope) | No |
| 8 | `.context/rules-index.md` | Add ADR-015 row (§8b); regenerated by context-graph scan | No |
| 9 | `CHANGELOG.md` | `[Unreleased]` entry (ICON-0085) — manager adds at task close via `changelog-entry` | No |

**Not touched (by design)**: `context_template/` (delegation model is plugin-internal) → **no iconrc bump**. `.claude-plugin/plugin.json` → **no version bump** (release guard; consumer-shipped changes 1-5 make this *eligible* for a future release, not *authorized* to cut one). Shared `common-constraints` block → untouched (cross-cutting; OQ-2).

**Note on `.context/decisions/README.md`**: coder should check whether it enumerates ADRs and add an ADR-015 line if so (parity, graph reachability).

---

## 10. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Manager under-fills the warmstart `### Architecture`/`Prior work`; cold @architect/@planner produce degraded output | M | M | New INPUTS section makes the cold-start self-read explicit; ADR-013 cold-resume discipline; manager Hardcoded rule already requires "everything it needs without repeating discovery" |
| Planner round-trip latency on a blocking ambiguity (vs. live iteration) | M | L | Front-loaded warmstart; assumptions-first planning resolves most cases in one pass; only breakdown-altering ambiguities re-dispatch |
| ADR-008 budget creep from the new warmstart field | L | L | Exactly one conditional field, dropped when N/A; tier tables + isolation rules stay in the on-demand skill |
| common-constraints `ask_user` line conflicts with report-borne open questions | L (already latent for all isolated agents) | L | Documented per-agent precedence; no shared-block edit (OQ-2) |
| Copilot CLI lacks per-subagent model control → @architect's complex/Opus tier is advisory there | M | L | Unchanged ADR-004 degradation; same as every isolated tier today; recorded, not regressed |
| ADR-015 ↔ ADR-014 cross-ref not reachable → pre-commit context-graph gate fails | L | L | Coder wires `**Supersedes**`/`**Superseded-by**` both directions + rules-index row before commit |

---

## 11. Open questions (user go/no-go)

- **OQ-1** — Confirm **@planner default = Sonnet** (upgrade→complex), not complex-by-default. Justified in §7a; final call is the user's.
- **OQ-2** — The shared common-constraints `ask_user` line vs. planner's report-borne open questions: keep the **documented per-agent precedence** (recommended — no cross-cutting churn), or soften the shared line for all isolated agents (larger blast radius, flagged as an architecture trigger)?
- **OQ-3** — Confirm **ADR-015 (new) + ADR-014 field-only update**, rather than amending ADR-014's Decision prose in place. Recommended in §8.
- **OQ-4** — PM anti-rat row `:220` ("@researcher can run on whatever model"): generalize to "a specialist" (recommended, minor) or leave researcher-specific?

---

## 12. Implementation notes (for @planner sequencing and @coder)

- **Behavior-preserving where possible**: the report contracts already exist; the net new behavior is (a) the planner clarification→report shift and (b) tier bindings. Everything else is qualifier removal + one field + one ADR.
- **Suggested sequence**: (1) ADR-015 + ADR-014 field + rules-index (establishes the decision of record); (2) warmstart field in manager; (3) SKILL.md collapse + tier flips; (4) both agent def INPUTS/clarification edits; (5) PM tier rule; (6) CHANGELOG at close. Steps 2-5 are independent and parallelizable once the ADR lands.
- **Terseness**: files 1 and 5 are always-loaded — apply `terseness-calibration`; the INPUTS sections (files 3-4) load on dispatch, keep them tight too.
- **Validation** (pure-content, ADR-005): JSON-parse `plugin.json` (unchanged), manifest validator, and the pre-commit context-graph + rules-index gates on the ADR/rules-index changes. No runtime tests.
