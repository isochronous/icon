# Design: ICON-0084 — Model-Aware Delegation

**Status**: Proposed — awaiting user sign-off. Design only; @coder implements after approval.
**Author**: @architect
**Date**: 2026-07-18

## Summary

Make ICON delegation model-aware: every isolated delegation names a **tier** — `basic`→Haiku, `default`→Sonnet, `complex`→Opus — picked deliberately from task-complexity signals. The tier is a portable concept (ADR-004); each harness realizes it its own way. Always-loaded roles carry only the required field + a one-line rule + a pointer; the full task→tier mapping lives in the on-demand `manager-routing-guide` skill (ADR-008-lean). No `context_template/` touch → no iconrc bump.

## Recommendation

**Decision**: Approve with modifications (three decision points for the user in Open Questions).
**Rationale**: Delivers the cost/quality win (cheap model for mechanical work, powerful model for hard work) with a ~95-word always-loaded delta on the manager and ~67 on the PM — comfortably under the ADR-008 re-inventory triggers (425 / 350 words). Enforcement is prose + anti-rationalization; a hard gate is infeasible (see §2) and not worth building.

---

## 1. Tier taxonomy + task→tier mapping

### Tiers (portable concept)

| Tier | Model (alias) | Use for |
|------|---------------|---------|
| `basic` | haiku | Mechanical, single-file, deterministic work needing no design judgment |
| `default` | sonnet | Standard implementation / testing / review / research / planning — the common case |
| `complex` | opus | Design, security, ambiguity, cross-cutting, hard debugging |

Always-loaded content names **tiers only** (`basic`/`default`/`complex`). The tier→model-ID mapping lives in `manager-routing-guide` so model names can change without churning a budgeted role.

### Complexity signals → tier

- **basic (Haiku)**: single-file mechanical edit; lint / format fix; rename or move; import fix; mechanical find-replace across obvious call sites; one obvious test case copying an existing pattern; mechanical `.context/` maintenance append (retro append, index regen); trivial additive field.
- **default (Sonnet)**: feature implementation within an established pattern; a normal test suite; standard code review; library/pattern research with a known target; a bounded refactor of clear shape; planning a medium task. **When uncertain, default.**
- **complex (Opus)**: architecture / design decisions; security-sensitive changes (auth, credentials, input trust boundaries); ambiguous or underspecified tasks needing interpretation; cross-cutting changes spanning modules or boundaries; hard debugging (the `systematic-debugging` threshold — 2+ failed attempts — is itself a complex signal); migration / breaking-change planning; novel-domain deep research.

### Per-role default tier (signals adjust up/down)

| Agent | Default | Upgrade → complex when… | Downgrade → basic when… |
|-------|---------|-------------------------|-------------------------|
| @coder | default | cross-cutting / ambiguous / security-touching | single-file mechanical, lint, rename, import |
| @tester | default | hard-to-reproduce / complex behavior | one obvious test case on an existing pattern |
| @reviewer | default | security-sensitive or large cross-cutting diff | trivial single-file diff |
| @researcher | default | ambiguous / novel domain, deep multi-source | single-fact doc lookup |
| @context-specialist | default | root/branch-node creation, structural audit | mechanical maintenance append |
| explore / general-purpose | default | — | simple file-location sweep |
| @planner *(inline)* | inherits session model | — | — |
| @architect *(inline)* | inherits session model — Opus-worthy work | — | — |

**Rule of thumb**: start at the role default; one strong complexity signal upgrades, one strong mechanical signal downgrades; when uncertain, `default` (Sonnet).

**Inline vs isolated (load-bearing)**: `@planner` and `@architect` run in **shared context** (inline, in the manager's own session) — there is no separate context window and therefore no per-subagent `model` param to set. They run at the **session model**. The required-tier field targets **isolated** dispatches (@researcher, @coder, @tester, @reviewer, @context-specialist, explore), where a model can actually be selected. For inline agents the tier is informational: if architecture (Opus-worthy) work is coming, that is a signal for the *session* to be on Opus, not a per-delegation parameter. See Open Question A.

---

## 2. Enforcement

**Mechanism (recommended): prose + anti-rationalization, no hard gate.**

Three additions per delegating role:
1. **Required field** in the `## Context Warmstart` template (`### Task` section): `- Model: [tier — basic / default / complex]`.
2. **A `### Hardcoded (Non-Negotiable)` item**: every isolated delegation names a tier; pick deliberately, never let it default silently.
3. **An `## Anti-Rationalization` row**: "I'll just let the harness pick" → choose the tier from the signals.

**Why no hard gate**: a delegation prompt is produced at runtime and leaves **no committed artifact** for a git hook to inspect (unlike a commit message or a template file, which `.githooks/pre-commit` can gate). There is nothing to statically check at commit time. Building a runtime interceptor for prompt content would be harness-specific tooling (ADR-004 friction) for marginal benefit. Prose enforcement + the anti-rat row is the correct and proportionate mechanism — consistent with how every other manager behavioral rule (always-delegate, no-source-reads) is enforced today.

---

## 3. Placement (ADR-008-lean)

Full mapping (both tables from §1) → **`skills/manager-routing-guide/SKILL.md`**, on-demand, zero always-loaded cost. Add a new `### Model Tier Selection` section there containing: the tier table, the complexity-signal lists, the per-role table, and the tier→model-ID mapping (§4).

### Always-loaded manager — exact insert points (`agents/manager.agent.md`)

| # | Location | Content | ~words |
|---|----------|---------|--------|
| 1 | `## Delegation` → fenced `## Context Warmstart` template → `### Task` block (after `- Current step:`) | `- Model: [tier — basic / default / complex]` | 8 |
| 2 | `## Delegation`, immediately after the fenced template | One-line rule + pointer: "**Model tier (required)**: every isolated delegation names a tier — `basic` (Haiku) / `default` (Sonnet) / `complex` (Opus). Default to Sonnet; task→tier mapping and per-role defaults are in `manager-routing-guide`." | 30 |
| 3 | `### Hardcoded (Non-Negotiable)` | "Every isolated delegation specifies a model tier (`basic`/`default`/`complex`), chosen from the task's complexity signals — never dispatch on the silent default." | 28 |
| 4 | `## Anti-Rationalization` table | Row: "I'll let the harness pick a good model" \| "Defaulting wastes Opus on mechanical work and under-powers hard work" \| "Choose the tier from the complexity signals (`manager-routing-guide`)." | 28 |

**Manager delta ≈ 94 words** (baseline 4,403 → ~4,497). Under the ADR-008 per-PR re-inventory trigger (≥425 words); no re-inventory required. The manager component is already in accepted-overage territory (ADR-008 Consequences); +94 words does not change that posture and is load-bearing (a required delegation field).

### Always-loaded PM — exact insert points (`agents/product-manager.agent.md`)

PM's only isolated delegation is `@researcher` (its other triggers, @architect/@planner, are inline). Keep PM self-contained — do **not** point it at the manager-only routing-guide.

| # | Location | Content | ~words |
|---|----------|---------|--------|
| 1 | `## Delegation Protocol`, after the trigger blocks | "**Model tier (required)**: state a tier in every isolated (@researcher) delegation — `default` (Sonnet) for standard research; `complex` (Opus) for ambiguous or novel-domain deep research; `basic` (Haiku) for a single-fact lookup." | 30 |
| 2 | `### Hardcoded (Non-Negotiable)` | "Specify a model tier on every isolated delegation — never dispatch on the silent default." | 14 |
| 3 | `## Anti-Rationalization` table | Row: "@researcher can run on whatever model" \| "Deep/ambiguous research needs Opus; a lookup wastes it" \| "State the tier for the research depth." | 24 |

**PM delta ≈ 68 words** (baseline 2,311 → ~2,379). Under the PM re-inventory trigger (≥350 words). PM baseline (6,564 total surface) headroom (~436 to the 7,000 cap) absorbs it.

---

## 4. Portability (ADR-004)

Rule stated in **tier** terms; each harness maps tier → realization:

| Harness | Realization |
|---------|-------------|
| **Claude Code** | Set the Task/Agent tool `model` param **and** state the tier in the prompt. |
| **Copilot CLI** | State the tier in the prompt. If per-subagent model control is unavailable, the tier is **advisory** — it still travels in the prompt so a human, a session model-switch, or a future capability can honor it. Graceful degradation: the delegation never fails for lack of model control; it proceeds at the session/default model with the intended tier recorded. |

**Tier → model mapping** (lives in `manager-routing-guide`, updatable without touching a budgeted role):

| Tier | Claude Code `model` value |
|------|---------------------------|
| basic | `haiku` |
| default | `sonnet` |
| complex | `opus` |

**Recommendation**: use the **aliases** (`haiku`/`sonnet`/`opus`), not pinned concrete IDs (`claude-haiku-4-5`, etc.). Aliases track the current generation and rarely churn; pinned IDs would need editing every model refresh. Record the alias↔generation note in the routing-guide so a maintainer can pin deliberately if ever needed.

---

## 5. Affected agents + template / iconrc impact

**Delegating surfaces (confirmed)**: the **manager** (primary orchestrator) and the **product-manager** (→@researcher). Specialists do not sub-delegate; @context-specialist explicitly cannot. No specialist agent file changes.

**Files touched**:

| File | Change | Ships to consumers via |
|------|--------|------------------------|
| `agents/manager.agent.md` | required field + rule + Hardcoded + anti-rat row | plugin (`agents/`) |
| `agents/product-manager.agent.md` | rule + Hardcoded + anti-rat row | plugin (`agents/`) |
| `skills/manager-routing-guide/SKILL.md` | new `### Model Tier Selection` section (full mapping) | plugin (`skills/`) |
| `.context/decisions/014-model-aware-delegation.md` | new ADR (§6) | ICON-internal |
| `.context/rules-index.md` | new ADR-014 row | ICON-internal |
| `CHANGELOG.md` | `[Unreleased]` entry (consumer-facing behavior change) | — |

**Template / iconrc impact — NONE (confirmed).** The delegation contract is **plugin-internal**: agent definitions and skills ship *with the plugin* (moved `latest` tag propagates them), not via `context_template/`. `context_template/` is the `.context/` scaffold `/icon-init` copies into consumer repos; it contains no `## Context Warmstart` delegation contract. Therefore **no `context_template/` edit → no `iconrc.json` version bump**. (The `context_template/` grep hits for "delegat" are phase-workflow prose, not the delegation template.)

**Scoping decision (deliberate)**: the shipped `context_template/.../phase-*.md` @architect/@reviewer *phase* delegation sub-templates are **out of scope**. Adding the field there would touch `context_template/` → force an iconrc bump and widen the surface. Keeping this task to the plugin-internal always-loaded contract is what preserves the "no template touch" property. Flagged as Open Question C.

---

## 6. ADR-014 (draft for promotion to `.context/decisions/`)

```markdown
# ADR-014: Model-aware delegation — required per-delegation tier

**Date**: 2026-07-18
**Status**: Accepted
**Supersedes**: none
**Superseded-by**: none

## Context

ICON delegations dispatch every sub-agent at the harness default model, with no
signal about task difficulty. Mechanical single-file edits burn a frontier model;
genuinely hard work (architecture, security, ambiguous debugging) gets no more
capability than a rename. Nothing in the delegation contract lets the orchestrator
express "this is cheap" or "this is hard." The fix must respect portability
(ADR-004 — Claude Code and Copilot CLI differ in per-subagent model control), the
always-loaded budget (ADR-008 — manager/PM are tightly capped), and the
pure-content posture (ADR-005 — no build/gate tooling).

## Decision

Delegation is model-aware via a portable three-tier concept: `basic`→Haiku,
`default`→Sonnet, `complex`→Opus, selected from task-complexity signals with a
per-role default the signals adjust. Every **isolated** delegation must name a
tier (a required `Model:` field in the `## Context Warmstart` template), enforced
by a Hardcoded rule + an anti-rationalization row on the two delegating roles
(manager, product-manager). Inline agents (@planner, @architect) run at the
session model; the required field targets isolated dispatches where a model can
be selected. The full task→tier mapping and the tier→model-ID table live in the
on-demand `manager-routing-guide` skill, keeping the always-loaded delta minimal
(~94 words manager, ~68 PM — under the ADR-008 re-inventory triggers). Per
ADR-004 the rule is stated in tier terms; Claude Code sets the Task tool `model`
param and states the tier, Copilot CLI states the tier and degrades to advisory
where per-subagent model control is unavailable. Tier→model uses aliases
(haiku/sonnet/opus), not pinned IDs, so it rarely churns. No hard gate: a
delegation prompt leaves no committed artifact to check, so enforcement is prose,
consistent with every other manager behavioral rule. Plugin-internal only — no
`context_template/` change, no iconrc bump.

## Consequences

**Positive:**
- Cost/latency drop on mechanical work (Haiku) and quality rise on hard work (Opus).
- Portable: tier concept ships everywhere; only the realization is harness-specific.
- Minimal always-loaded cost; the mapping stays on-demand.
- Tier-name aliases keep the model table stable across model refreshes.

**Negative:**
- Prose-only enforcement — no gate can prove a tier was chosen deliberately;
  mitigated by the Hardcoded rule + anti-rat row (same rigor as always-delegate).
- Inline agents can't take a per-subagent model; their tier is a session-level
  signal, a documented asymmetry.
- Mis-tiering risk (Haiku under-powers a subtly hard task); mitigated by
  "when uncertain, default (Sonnet)" and the manager's freedom to upgrade.
- Copilot advisory degradation means the intended tier may not bind there until
  the harness supports per-subagent model control.

## Alternatives Considered

1. **No required field, guidance only** — rejected; optional guidance is ignored
   under load, the exact drift this task targets.
2. **Hard gate on delegation prompts** — rejected; no committed artifact exists to
   gate, and a runtime interceptor is harness-specific (ADR-004) for marginal gain.
3. **Concrete model IDs in the contract** — rejected; pins churn on every model
   refresh and would sit in a budgeted always-loaded role.
4. **Full mapping inlined into the manager role** — rejected; violates ADR-008
   lean-surface intent when an on-demand skill carries it at zero always-loaded cost.
```

**Rules-index row** (add under `## Decisions (ADRs)`):

```
| 014 | Choosing a model/tier for a delegation, or adding a delegation field | [decisions/014-model-aware-delegation.md](decisions/014-model-aware-delegation.md) |
```

ADR needs a `## Related` footer per ADR-012 (link ADR-004, ADR-008) for graph reachability.

---

## 7. Risks & open questions

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Mis-tiering under-powers a subtly hard task on Haiku | M | M | "When uncertain, `default`"; manager may upgrade; basic reserved for truly mechanical work |
| Prose enforcement ignored under load | M | L | Hardcoded rule + anti-rat row (same mechanism as every manager rule) |
| Copilot lacks per-subagent model control → tier not binding | M | L | Advisory degradation; tier still recorded in prompt |
| Always-loaded creep from future tier additions | L | M | Mapping stays in on-demand routing-guide; roles hold only the field + one-liner |

### Open questions (user go/no-go)

- **A. Inline agents.** @planner/@architect run at the session model (no per-subagent param). Accept that the required-tier field targets **isolated** dispatches and inline agents inherit the session, with a note that Opus-worthy design work is a signal to run the session on Opus? *(Recommend: yes.)*
- **B. Enforcement.** Accept **prose + anti-rat, no hard gate** as sufficient (no committed artifact to gate)? *(Recommend: yes.)*
- **C. Phase-template scope.** Leave the shipped `context_template/.../phase-*.md` @architect/@reviewer delegation sub-templates **untouched** (keeps the task template-free / no iconrc bump), deferring them to a follow-up? *(Recommend: yes — preserves the no-template-touch property.)*
- **D. Tier→model.** Use aliases (`haiku`/`sonnet`/`opus`) rather than pinned IDs? *(Recommend: yes.)*
```
