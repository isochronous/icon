# ADR-015: Sub-agent isolation — all specialists dispatched task→report

**Date**: 2026-07-18
**Status**: Accepted
**Supersedes**: ADR-014 (inline model-tier carve-out only — 014's tiered-delegation core stands)
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
@planner's old inline manager-dialogue loop (clarify with the manager mid-run) is
replaced by an Open Questions & Assumptions report section: it proceeds on stated
assumptions and the manager resolves manager-facing questions and re-dispatches.
Isolation does **not** remove `ask_user` — an isolated @planner/@architect retains
live user clarification for blocking, user-facing ambiguity; the report section is a
complement for assumptions made and manager-facing questions, not a replacement. With no inline agents, every delegation now names a
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
- @planner loses the inline manager-dialogue loop; a scope/orchestration ambiguity
  it can't resolve costs a dispatch round-trip instead of a live manager turn.
  Mitigated by warmstart front-loading and assumptions-first planning (most
  ambiguities resolve in one pass), and by `ask_user` remaining available for
  blocking user-facing clarifications.
- Cold @architect/@planner depend on the manager populating the warmstart well;
  an under-filled `### Architecture`/`Prior work` degrades output. Mitigated by
  the cold-start-tolerant self-read and the ADR-013 cold-resume discipline.
- The shared common-constraints `ask_user` line and the report-borne open questions
  are complementary, not in tension: isolation retains `ask_user` (no override) for
  blocking user-facing clarifications, while the report open questions document
  assumptions made and surface manager-facing scope/orchestration questions.

## Alternatives Considered

1. **Keep @architect/@planner inline** — rejected; perpetuates a two-model split
   for two agents whose only real inline need (accumulated context) the warmstart
   already carries, and blocks tiering + parallelism.
2. **Amend ADR-014 in place** (delete its carve-out clause) — rejected; mutates an
   accepted record and still leaves the isolation model with no ADR of its own.
3. **Add workflows/decisions excerpt fields to the warmstart too** — rejected;
   `### Applicable Rules` already carries them; duplication bloats the always-
   loaded template against ADR-008.
