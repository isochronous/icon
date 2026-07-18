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
be selected. The full task→tier mapping and the tier→model table live in the
on-demand `manager-routing-guide` skill, keeping the always-loaded delta minimal
(~111 words manager, ~70 PM — under the ADR-008 re-inventory triggers). Per
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
