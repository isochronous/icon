# Skill Decomposition Patterns

Conventions for how individual skills are wired, structured, packaged for distribution, and swept across surfaces when their content changes. The full body of rules lives in topic-scoped sub-files under [`./skill-decomposition/`](./skill-decomposition/); this file is the index.

## Topic Index

| Sub-file | Covers |
|----------|--------|
| [skill-mechanics.md](./skill-decomposition/skill-mechanics.md) | `using-skills` registration; invisible (`user-invocable: false`) skills; thin-router skills that dispatch an agent |
| [skill-structure.md](./skill-decomposition/skill-structure.md) | Multi-mode (initialize/upgrade) refactor sweeps; pre-commit skill-reference verification; "earn your place" verbatim-citation rule; sub-file layout for heavy-template skills |
| [infrastructure-and-distribution.md](./skill-decomposition/infrastructure-and-distribution.md) | Skills cannot share scripts (each invoking skill owns its own copy); what ships with the plugin vs. what stays repo-local; no historical notes in shipped surfaces |
| [process-doc-sweeps.md](./skill-decomposition/process-doc-sweeps.md) | Three-surface sweep for `.context/workflows/` process-doc edits (local SSOT + `context_template/` mirror + `skills/<phase>/SKILL.md` fallback, with the ICON-0026 repo-local-convention exception); guard scope derived from the enumerated defect-site list rather than a generic "where this file lives" heuristic |
| [pre-flight-exploration.md](./skill-decomposition/pre-flight-exploration.md) | Pre-flight @explorer dispatch on audit-finding tasks (four narrow sub-patterns: enumeration, measurement, characterization-plus-open-questions, citation-drift detection — 6 precedents across all sub-patterns); pre-flight retrospectives.md reading translates into named implementation constraints in plan.md and the dispatch |
| [dispatch-and-review-gates.md](./skill-decomposition/dispatch-and-review-gates.md) | Echoing decisional inputs (out-of-scope surfaces, project rules, user clarifications) verbatim into the @coder dispatch (6 precedents, user-clarification sub-pattern confirmed across 4 independent tasks); reviewer pass cadence (when a single @reviewer pass suffices vs when Pass 2 is required — 6 precedents); verbatim acceptance-gate checklists in the architecture spec or coder dispatch (gates-at-dispatch-layer sub-pattern now 2 precedents across ICON-0037 and ICON-0038) |
| [verify-design-claims-against-artifacts.md](./skill-decomposition/verify-design-claims-against-artifacts.md) | Cross-check a design/@architect claim about what a gate, hook, event matcher, or config requires against the actual artifact BEFORE dispatching @coder — a confident design's behavioral assertion is an unverified hypothesis until checked (2 precedents: ICON-0061 hooks.json matcher, ICON-0065 pre-commit iconrc version gate) |

## When to consult which file

- **Adding or restructuring an individual skill** → `skill-mechanics.md` (router pattern, invisible-skill naming) and `skill-structure.md` (heavy-template layout, reference verification).
- **Refactoring a skill family (`initialize-*`, `task-plan-phase-*`, `context-specialist-*`)** → `skill-structure.md § Multi-Mode Skill Refactoring` first; the enumeration step prevents silent upgrade-contract breakage.
- **Authoring a new skill, agent, or shipped surface** → `infrastructure-and-distribution.md` for what may and may not be cross-referenced, and for the "no historical notes" rule.
- **Editing a process doc under `.context/workflows/`** → `process-doc-sweeps.md § Process Doc Sweep` for the three-surface sweep (with the ICON-0026 repo-local-convention exception); `process-doc-sweeps.md § Guard Scope From the Enumerated Defect-Site List` when adding a mechanical guard for a swept defect class.
- **Starting work on an `icon-audit` issue or any audit-finding ticket** → `pre-flight-exploration.md § Pre-Flight Explore on Audit-Finding Tasks` before dispatching @architect, AND `pre-flight-exploration.md § Pre-Flight Retro Reading Translates Into Implementation Constraints` before drafting plan.md Decisions and the @coder dispatch.
- **Dispatching @coder with multi-sub-task work, or deciding @reviewer pass cadence** → `dispatch-and-review-gates.md § Echo Decisional Inputs Into Dispatch` and `dispatch-and-review-gates.md § Reviewer Pass Cadence: When Single-Pass Suffices`.
- **Drafting an @architect spec (or, on mechanical sweeps with no @architect pass, the @coder dispatch directly) for any task touching 5+ files or with named risk axes** → `dispatch-and-review-gates.md § Verbatim Acceptance-Gate Checklist in Architecture Spec or Coder Dispatch` for the runnable-bash-checklist format and the three-component verbatim-gate rule.
- **Acting on a design or @architect deliverable that asserts what a gate, hook, event matcher, or config requires (or does not require)** → `verify-design-claims-against-artifacts.md § Verify Design Claims Against the Artifact` to cross-check the claim against the actual artifact before dispatching @coder.
