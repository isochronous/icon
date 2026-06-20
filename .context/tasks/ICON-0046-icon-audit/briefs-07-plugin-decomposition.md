# Plugin-Decomposition Analysis — Dispatch Brief

## Scope

Evaluate how the ICON plugin could be split into 2+ composable plugins. This is a special-directive brief (not part of the standard 6-domain audit). User-asked question, paraphrased: "Some sub-plugins might be designed as **extensions** of ICON, some **standalone**, some designed to be **composable** with each other. Examples of candidate plugin domains: software development, product management, agentic toolkit design."

This brief is dispatched **after** briefs 01–05 are complete. It consumes their outputs as inputs (especially structural observations) but produces an independent decomposition-lens output, not a re-audit.

## Inputs (read-only)

- `<task-folder>/research/01-agents.md` — agent coupling and role boundaries
- `<task-folder>/research/02-process-skills.md` — orchestration spine (task-plan + phase-*)
- `<task-folder>/research/03-context-specialist-init.md` — init chain coupling
- `<task-folder>/research/04-utility-skills.md` — utility surface diversity
- `<task-folder>/research/05-infrastructure.md` — shared infrastructure (hooks, manifest, common-constraints)
- `README.md` — current plugin description, skill table, intended audience
- `agents/manager.agent.md` — central orchestration agent (sees what spine looks like)
- `skills/using-skills/SKILL.md` — cross-skill workflow chains documented here
- `skills/manager-routing-guide/SKILL.md` — agent-routing table (couples agent ↔ skill ↔ workflow)
- `shared/common-constraints.md` — what is injected into every agent
- `.claude-plugin/plugin.json` — manifest shape (single-plugin assumption today)
- `.githooks/pre-commit` — coupling: which assumptions live here
- `.context/decisions/` — ADRs that constrain coupling (especially ADR-004 tool-agnostic content, ADR-008 always-loaded token budget, ADR-010 carry-forward registry)

## ADR / Decision-Log Pointer

- **ADR-004** (tool-agnostic content) — relevant: any sub-plugin candidate must also stay tool-agnostic, OR the split must explicitly carve out tool-specific content into a separate optional layer.
- **ADR-008** (always-loaded token budget) — splitting reduces always-loaded surface per-domain; quantify expected reduction per candidate split.
- **ADR-010** (carry-forward re-tier) — irrelevant to this brief.

## Required Output Sections

Produce a single file at `<task-folder>/research/07-plugin-decomposition.md` with the following sections in order:

### 1. Current Coupling Map

Inventory and classify every agent and skill by role-cluster. Use the categories below as a starting point, but feel free to subdivide or rename based on what you find. For each cluster, list:
- Member agents (file names)
- Member skills (file names)
- Internal dependencies (which member depends on which)
- External dependencies (depends on members of other clusters)
- Always-loaded vs on-demand status

Suggested starting categories:
- **(A) Software-Development Orchestration** — manager, architect, coder, tester, reviewer, planner; task-plan + phase-*, mr-discipline, commit-discipline, code-quality-rules, verification-checklist, design-first, systematic-debugging, testing-discipline, migration-planning, dependency-management, post-incident-review, start-worktree
- **(B) Product Management** — product-manager agent; jira-story, sprint-goals, post-meeting, rfc
- **(C) Context Initialization & Maintenance** — context-specialist agent; icon-init, initialize-*, upgrade-repo, context-maintenance, context-document-guidelines, context-specialist-*, find-context-template, resolve-repo-context, create-iconrc, merge-phase-templates
- **(D) Agentic Toolkit / Meta-Tooling** — writing-skills, agent-evaluation, plugin-design, using-skills, invoke-sub-project-skill
- **(E) Cross-Cutting Building Blocks** — mcp-tools-first, setup-mcp-servers, manager-routing-guide, icon-status, ecological-impact, researcher agent (advisory across all domains)
- **(F) Maintainer-Only (ICON-internal)** — `.claude/skills/`: changelog-entry, icon-audit, release-plugin

### 2. Decomposition Candidates

Identify 2–4 viable plugin-split proposals. For each, produce a table with these columns:

| Proposal | Members | Type | Depends on | Standalone? | Key cuts required | Estimated effort |
|---|---|---|---|---|---|---|

Where:
- **Type** = `standalone` | `icon-extension` | `composable-block`
- **Standalone?** = can a user install this plugin in isolation without ICON's core? (yes / no / partial-with-fallbacks)
- **Key cuts required** = which dependency edges (file references, common-constraints injections, skill cross-references, manager routing rows) must be severed or generalized

### 3. Dependency-Edge Analysis

For each proposed split, enumerate the concrete dependency edges that need attention. Cite file:line where possible. Categories:

- **Common-constraints injection** — does the sub-plugin still need this block injected into its agents? Source of truth is `shared/common-constraints.md` enforced by `.githooks/pre-commit`. If the sub-plugin doesn't ship its own pre-commit hook, this becomes a coordination problem.
- **Manager-routing-guide entries** — which rows in `skills/manager-routing-guide/SKILL.md` reference skills that would move to a sub-plugin?
- **`using-skills` workflow chains** — which workflow chains in `skills/using-skills/SKILL.md` reference skills that would move?
- **Phase-skill template overrides** — task-plan template-override pointers; do the phase skills move with task-plan or stay?
- **`.context/` template ownership** — `context_template/` ships during `initialize-repo`. If the init chain moves to its own plugin, who owns the template?
- **Hook ownership** — `.githooks/pre-commit` enforces common-constraints byte-equality, dead-ref resolution, iconrc version-bump gate, script-parity. These checks span multiple potential sub-plugin boundaries.
- **Cross-skill `[[name]]` or "see X" references** — find with `grep -rE '\b(see|via|using) \`?[a-z-]+\`?' skills/`

### 4. Recommended Decomposition (Single Pick)

Choose ONE decomposition you would recommend. State:

- **The split** — which plugins ship, what each contains, what depends on what
- **Why this split over alternatives** — the dependency-edge minimization or audience-clarity argument
- **Phased migration path** — 3–5 phases describing how to get from current single-plugin to the proposed split without breaking consumers. Each phase should be independently shippable.
- **Risks** — what could go wrong; what's the rollback story; what coupling we'd discover only mid-migration

### 5. Compatibility Layer Considerations

If sub-plugins are designed to be composable, how do they coordinate?

- **Plugin marketplace structure** — Claude Code supports multi-plugin marketplaces. Would these ship as a single marketplace with N plugins, or N separate marketplaces?
- **Shared resources** — common-constraints, `using-skills`, `manager-routing-guide`. Do these stay in one plugin (which others depend on) or get duplicated?
- **Version pinning** — if ICON-core is at v1.17.2 and a sub-plugin needs v1.17.0+ features, how is the constraint expressed?
- **The "ICON" identity question** — does "ICON" become the meta-marketplace or the core-plugin? What's the user-facing name they install?

### 6. Open Questions for the User

Decompose this analysis into 3–6 user-decision points the maintainer would need to resolve before any split could proceed. Frame each as a yes/no or pick-from-list question.

## Forward-Looking Mandate

This entire brief is forward-looking — there's no "no issues found" failure mode. Produce a substantive decomposition proposal even if you conclude the current single-plugin shape is optimal. In that case, the recommendation is "keep as one plugin" but the brief still surfaces the dependency map and the cuts that would be needed if a future split became necessary.

## Non-Goals

- Do not propose source-file edits.
- Do not dispatch sub-agents.
- Do not edit any file outside `<task-folder>/research/`.
- Do not re-audit individual domains — cite domain findings by reference.
- Do not propose splitting any of the `.claude/skills/` maintainer-only skills out into a separate plugin; they are correctly maintainer-only by design.
