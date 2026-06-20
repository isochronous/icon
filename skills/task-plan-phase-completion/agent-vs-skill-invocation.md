# Agent vs. Skill Invocation

When the manager (or any orchestrator) needs to apply a process, the choice is **delegate to a specialist agent** vs. **invoke the skill directly**. This standard defines which path applies for which surface.

## The Rule

**Specialist agents own their domain's writes.** Skills that write to files owned by a specialist agent's domain must be invoked **through that specialist**, not directly by the manager.

| Domain surface | Owning specialist | Invocation path |
|---|---|---|
| `.context/` writes (domains, standards, architecture, decisions, etc.) | `@context-specialist` | Delegate with `mode: maintenance` (or `mode: create` / `mode: upgrade` at init time, or `mode: audit` for a proactive read-only drift scan) |
| Source code changes | `@coder` | Delegate with task warmstart |
| Tests | `@tester` | Delegate with test warmstart |
| Architectural review | `@architect` | Delegate with design context |

## Why

The specialist enforces invariants that direct skill invocation skips:

- **Pre-write audit**: `@context-specialist` runs a Phase 0 / Phase 1 / Phase 2 audit before writing, catching staleness in target files that a direct `context-maintenance` invoke would miss.
- **Idempotency + provenance**: the specialist returns a structured report — files modified, entries promoted, entries pruned — which the manager records in the retrospective entry's **Updated** field.
- **Commit ownership** (mode-dependent): In **`mode: maintenance`**, the specialist stages writes via `git add` only; the manager owns the commit (Task Completion Step 4). In **`mode: create`** and **`mode: upgrade`**, the specialist commits before reporting per its own Hardcoded tier rule in `agents/context-specialist.agent.md`. **`mode: audit`** is read-only — no commit phase. The mode split exists so the maintenance-mode specialist does not sweep pre-staged manager work into its commit.
- **Pruning and rotation**: rolling-log behavior (e.g., `retrospectives.md` keep-last-10 with multi-prune convergence) lives inside the specialist's owned scripts; bypassing the specialist bypasses the script.

The empirical evidence: the ICON-0001 retrospective explicitly used the `@context-specialist` path and recorded what the specialist returned. Subsequent tasks (ICON-0002, ICON-0003) followed the same pattern.

## When the manager invokes a skill directly

There are skills the manager invokes without a specialist intermediary — they govern manager-owned artifacts, not specialist-owned files:

- `task-plan` — writes `plan.md` and task-folder artifacts (manager-owned per `manager.agent.md`)
- `commit-discipline` — wraps `git commit` (manager runs git directly)
- `pr-discipline` — guides the manager's PR write-up
- `verification-checklist` — guides the manager's own success-claim discipline
- `task-retrospective` — drives the retrospective ceremony; ITS guidance still routes `.context/` writes through `@context-specialist`

## Specialist-internal skill chaining

Within a specialist's owned skill chain, the specialist may invoke other specialist-owned skills directly — this is the specialist running its own toolkit, not the manager bypassing the specialist.

Concrete examples:

- `upgrade-repo` (Phase 3) invokes `context-maintenance` when documentation drift is detected. Both skills are `@context-specialist`-owned; the specialist is the invoker.
- `initialize-monorepo` / `initialize-workspace` / `initialize-multimodule` dispatch prompts tell the sub-session `@context-specialist` to invoke `context-maintenance` from inside its upgrade-repo Phase 3 work. Same pattern — the specialist invokes its own tool inside its own context.

The rule in this standard governs the **manager**'s choice, not invocations the specialist makes from within its own skill chain. If you see `invoke context-maintenance` inside a `@context-specialist`-owned skill body or dispatch prompt, that is not a violation of this standard.

## Anti-Rationalization

| Excuse | Reality | Correct action |
|---|---|---|
| "The update is narrow — only one file in `.context/`" | The audit / provenance / idempotency benefits still apply. | Route through `@context-specialist`. |
| "`context-maintenance` is the relevant skill, so I'll just invoke it" | The skill is `@context-specialist`'s tool, not the manager's. | Delegate to `@context-specialist`; the specialist invokes the skill. |
| "Calling the specialist is one more handoff" | The handoff IS the audit gate. | Pay the handoff cost. |

## Source

This standard codifies the decision reached in:

- ICON-0003 audit, finding M-P2 (`task-plan-phase-completion` ⇄ `task-retrospective` divergence on `.context/` delegation)
- ICON-0001 retrospective ("Repeat" note documenting the @context-specialist path)
- GitHub issue #3
- GitHub issue `isochronous/icon#12` (M-CC-NET2 resolution — canonicalized `retrospectives.md` write path, ICON-0027)
