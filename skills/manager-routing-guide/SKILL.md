---
name: manager-routing-guide
description: >
  Internal manager skill. Do not invoke without explicit direction.
user-invocable: false
---

# Manager Routing Guide

The manager's routing reference tables and context-isolation rules. Invoke when making a routing decision — selecting a specialist or consulting the capability matrix. The sections below are authoritative.

---

### Domain Documentation

When working in a code area lacking documentation in `.context/domains/`, create or update a domain file for it. Each major application domain gets its own file.

**Business domains** (e.g., payments, loans, user-management): key entities and relationships, business rules and validation logic, domain-specific terminology, important code paths.

**Technical domains** (e.g., routing, state-management, lifecycle, authentication): how the system works, key patterns and conventions, important abstractions, integration points.

Keep domain files atomic and tightly scoped — one facet per file. Apply `context-document-guidelines` when creating or updating them.

---

### Standard Feature Workflow

```
User Request → @researcher (if needed) → @planner → @architect → @coder → @tester → @reviewer
```

### Design Approval Gate

For complex work (new modules, new patterns, cross-cutting changes), ensure @architect reviews the design before @coder implements. Simple work within established patterns skips this gate.

### Parallel Dispatch

When the task breakdown contains independent tasks with no dependencies, dispatch multiple agents in parallel rather than sequentially. Check the planner's dependency map to identify concurrent tasks.

### Agent Selection

Always delegate to the appropriate specialist — even for simple or single-file requests. The manager's role is routing and coordination, not execution.

**Exception**: `plan.md` and other `.context/tasks/` orchestration artifacts are written directly by the manager — these are task orchestration documents, not source code.

**Exception**: Git operations (`git commit`, `git push`, `git checkout`, `git rebase`, `git tag`, `git commit --amend`, etc.) are run directly by the manager — they are operational steps, not file content changes.

| Task Type | Start With | Involve Others |
|-----------|------------|----------------|
| New feature | @planner | @researcher for library patterns, @architect for new modules |
| Bug fix (clear cause) | @coder | @tester for regression test |
| Bug fix (unknown cause) | @coder | Create task with "Investigate: [symptom]" as first plan step; invoke `systematic-debugging` skill; report root cause to manager before fix begins |
| Refactoring | @architect | @coder for implementation |
| Code review (any size) | @reviewer | @tester if tests missing |
| Fix a failing test | @tester | @coder if source code needs to change |
| Test failures (CI) | @tester | @coder if code fix needed |
| Add/fix imports or lint errors | @coder | — |
| Architecture decision | @architect | @researcher for current patterns |
| Library/version research | @researcher | @architect to evaluate, @planner for breakdown |
| Initialize / regenerate project context | Invoke `initialize-repo` skill (routes to @context-specialist) | — |
| Context maintenance / `.context/` update | @context-specialist (mode: maintenance) | — |

Common patterns that **must** use a specialist, even when they feel trivial:
- "Review this file" → @reviewer
- "Fix this test" → @tester
- "Add this import" / "fix this lint error" → @coder
- "What does this library do?" → @researcher

### Agent Capabilities

| Agent | Does | Does Not |
|-------|------|----------|
| @researcher | Research docs, find best practices, cite sources | Implement code, make design decisions |
| @planner | Break down tasks, sequence work, identify deps | Implement code, make design decisions |
| @architect | Design systems, evaluate patterns, recommend structure | Write implementation code, run tests |
| @coder | Write code, run builds, fix compilation errors | Write tests, make design decisions |
| @tester | Write tests, run tests, debug test failures | Implement features, change architecture |
| @reviewer | Review code, identify issues, suggest improvements | Directly fix code, approve own work |
| @context-specialist | Create, maintain, and update `.context/` directories for leaf, branch, and root nodes; handles initial creation (`mode: create`), upgrades (`mode: upgrade` via `upgrade-repo`), maintenance updates at task close (`mode: maintenance`), and drift audits (`mode: audit`); detect tree position; commit context artifacts in `create`/`upgrade` modes; `mode: audit` is read-only — no commit phase; in `mode: maintenance`, stage writes via `git add` only — the manager owns the commit (see `task-plan-phase-completion/agent-vs-skill-invocation.md`) | Delegate to sub-agents, implement source code, make architectural decisions |
| @product-manager | Standalone tool invoked directly by users for product-management work (story shaping, GitHub issue drafting). **Not part of the manager's delegation chain** — the manager does NOT route tasks to it in the standard development workflow. | Participate in the manager's workflow chain; implement code; write tests |

### When to Invoke @researcher

See Session Start step 7 for trigger criteria — that step is the authoritative decision point for both `explore` agent (see platform note in manager Session Start step 7) and @researcher invocation.

Always specify version numbers when invoking @researcher. Research findings should inform @architect and @planner decisions before @coder begins.

## Sub-Agent Context Isolation

**All specialist dispatches are isolated** — each runs in a separate context window via the task tool, receives a self-contained `## Context Warmstart`, and returns a structured report. Incorporate only the report (findings, artifacts, decisions) into the orchestrator's context — never the agent's full reasoning trail.

| Agent | Manager needs (the report) |
|-------|----------------------------|
| @researcher | Findings and citations, not the web-fetch trail |
| @planner | The task breakdown + open questions/assumptions, not the exploration |
| @architect | The assessment (recommendation + rationale), not the file reads |
| @coder | The diff and build proof, not the compiler noise |
| @tester | Pass/fail counts and what was written, not the runner output |
| @reviewer | Findings, not the many file reads |
| @context-specialist | Completion summary + file list, not the generation trail |

## Model Tier Selection

Every delegation names a tier, chosen from the task's complexity signals (all specialist dispatches are isolated). Start at the role default; one strong complexity signal upgrades, one strong mechanical signal downgrades. **When uncertain, `default` (Sonnet).**

### Tiers

| Tier | Model (alias) | Use for |
|------|---------------|---------|
| `basic` | `haiku` | Mechanical, single-file, deterministic work needing no design judgment |
| `default` | `sonnet` | Standard implementation / testing / review / research / planning — the common case |
| `complex` | `opus` | Design, security, ambiguity, cross-cutting, hard debugging |

### Complexity signals

- **basic → Haiku**: single-file mechanical edit; lint / format fix; rename or move; import fix; mechanical find-replace across obvious call sites; one obvious test case copying an existing pattern; mechanical `.context/` maintenance append (retro append, index regen); trivial additive field.
- **default → Sonnet**: feature implementation within an established pattern; a normal test suite; standard code review; library/pattern research with a known target; a bounded refactor of clear shape; planning a medium task. **When uncertain, default.**
- **complex → Opus**: architecture / design decisions; security-sensitive changes (auth, credentials, input trust boundaries); ambiguous or underspecified tasks needing interpretation; cross-cutting changes spanning modules or boundaries; hard debugging (the `systematic-debugging` threshold — 2+ failed attempts — is itself a complex signal); migration / breaking-change planning; novel-domain deep research.

### Per-role default tier

| Agent | Default | Upgrade → complex when… | Downgrade → basic when… |
|-------|---------|-------------------------|-------------------------|
| @coder | default | cross-cutting / ambiguous / security-touching | single-file mechanical, lint, rename, import |
| @tester | default | hard-to-reproduce / complex behavior | one obvious test case on an existing pattern |
| @reviewer | default | security-sensitive or large cross-cutting diff | trivial single-file diff |
| @researcher | default | ambiguous / novel domain, deep multi-source | single-fact doc lookup |
| @context-specialist | default | root/branch-node creation, structural audit | mechanical maintenance append |
| explore / general-purpose | default | — | simple file-location sweep |
| @planner | default | large / cross-cutting / ambiguous breakdown | trivial re-sequence of an existing plan |
| @architect | complex | — | routine pattern-conformance check → **default** (still needs design judgment; never basic) |

### Tier → model realization (ADR-004)

The rule is stated in tier terms; each harness maps tier → realization using **aliases**, not pinned IDs:

| Tier | Alias |
|------|-------|
| `basic` | `haiku` |
| `default` | `sonnet` |
| `complex` | `opus` |

| Harness | Realization |
|---------|-------------|
| **Claude Code** | Set the Task/Agent tool `model` param to the alias **and** state the tier in the delegation prompt. |
| **Copilot CLI** | State the tier in the prompt. Where per-subagent model control is unavailable the tier is **advisory** — the delegation never fails for lack of it; it proceeds at the session/default model with the intended tier recorded. |

Aliases (`haiku`/`sonnet`/`opus`) track the current generation and rarely churn, so this table stays stable across model refreshes; pinned IDs would need editing every refresh. A maintainer may pin deliberately if ever needed.
