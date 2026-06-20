---
name: manager-routing-guide
description: >
  Internal manager skill. Do not invoke without explicit direction.
user-invocable: false
---

# Manager Routing Guide

This skill contains the manager's routing reference tables and context-isolation rules. Invoke it when making a routing decision — selecting a specialist for a task type, consulting the agent capability matrix, or choosing between isolated vs. shared sub-agent context. The sections below are authoritative.

---

### Domain Documentation

When working in a code area that lacks documentation in `.context/domains/`, create or update a domain file for that area. Each major application domain should have its own file covering relevant knowledge for that area.

**Business domains** (e.g., payments, loans, user-management): key entities and relationships, business rules and validation logic, domain-specific terminology, important code paths.

**Technical domains** (e.g., routing, state-management, lifecycle, authentication): how the system works, key patterns and conventions, important abstractions, integration points.

Keep domain files atomic and tightly scoped — one facet per file. Apply `context-document-guidelines` when creating or updating domain files.

---

### Standard Feature Workflow

```
User Request → @researcher (if needed) → @planner → @architect → @coder → @tester → @reviewer
```

### Design Approval Gate

For complex work (new modules, new patterns, cross-cutting changes), ensure @architect reviews the design before @coder begins implementation. Simple work within established patterns does not require this gate.

### Parallel Dispatch

When the task breakdown contains independent tasks with no dependencies between them, dispatch multiple agents in parallel rather than sequentially. Check the planner's dependency map to identify tasks that can run concurrently.

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
| @product-manager | Standalone tool invoked directly by users for product-management work (story shaping, Jira/Confluence drafting, sprint goals). **Not part of the manager's delegation chain** — the manager does NOT route tasks to @product-manager as part of the standard development workflow. | Participate in the manager's workflow chain; implement code; write tests |

### When to Invoke @researcher

See Session Start step 7 for trigger criteria — that step is the authoritative decision point for both `explore` agent (see platform note in manager Session Start step 7) and @researcher invocation.

Always specify version numbers when invoking @researcher. Research findings should inform @architect and @planner decisions before @coder begins work.

## Sub-Agent Context Isolation

Not all specialists should run in isolated sessions. Use the following rules:

**Isolated (separate context window via task tool)** — agents whose intermediate work is noisy and where the manager only needs the final artifact:

| Agent | Why isolated |
|-------|-------------|
| @researcher | Heavy web fetching, large raw content, cache writes — manager needs findings only |
| @coder | File reads and compiler/lint output can be large — manager needs the diff and build proof |
| @tester | Test runner output is noisy — manager needs pass/fail counts and what was written |
| @reviewer | Reads many files to form opinions — manager needs findings, not the file reads |
| @context-specialist | File creation across many directories, git operations, large content generation — manager needs the completion summary and file list only |

**Shared context (inline)** — agents that work collaboratively with the manager and whose output is compact:

| Agent | Why shared |
|-------|-----------|
| @planner | Needs full task history to produce a coherent breakdown; benefits from clarifying questions with the manager |
| @architect | Design decisions often require iteration; needs the accumulated decision context; output is a compact design doc |

After each isolated agent completes, incorporate only the **output** (findings, artifacts, decisions) into the orchestrator's context — not the agent's full reasoning trail.
