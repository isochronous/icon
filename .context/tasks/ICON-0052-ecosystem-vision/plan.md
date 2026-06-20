## Task: ICON-0052
## Branch: feature/ICON-0052-ecosystem-vision
## Objective: Author a vision sketch for an ICON v2 ecosystem: a `.context/`-centric base plugin (`context-core`, working name) plus role-specific SDLC plugins (`devcon`, `pm`, `agentic-toolkit`, plus future-wave `qa`/`release-mgmt`/`devops`/`triage`/`support`) that compose around a federated protocol. Sketch is discussion-ready, not RFC-ready. Once the design settles through iteration, a follow-up task graduates the sketch into an ORG-004 RFC.
## Folder: .context/tasks/ICON-0052-ecosystem-vision/

## Decisions
- **Architecture: B+ v2 — federated protocol + lean specialist router + rich internal skill library.** context-specialist is a small skill-routing agent (not an expansive writer). The discipline lives in skills, many of them script-backed. Confirmed 2026-06-03 in design-first round 2.
- **Four-class skill invocability taxonomy** (round 3): `user-invocable × disable-model-invocation` → standard (1), agent-auto only (2), user-only (3), **internal (4)** (both flags restrictive + boilerplate description "Internal skill. Do not invoke without explicit direction."). Cross-plugin agents may auto-invoke classes 1 and 2 freely; class 4 reserved for the owning agent per explicit instruction. Audit + script-side guard enforce.
- **Topology truth-source: `iconrc.json#/repo_type`** (already in ICON v1). Init-context writes it; resolve-topology reads it. No heuristic detection at session start.
- **Aggregator init suggests `excludes` adjustments to user** (not automatic). Uses existing `iconrc.json#/excludes` array (already in ICON v1).
- **Copilot CLI is canonical; no Claude-only features.** Round 3 confirmation of round 2 framing — any feature not replicable in Copilot CLI is excluded from the design.
- **Separate repos per plugin** — confirmed round 3.
- **Plugin namespacing handles collisions natively** (`/devcon:commit` vs `/pm:commit`); no central reserved-name registry needed (YAGNI per round 3).
- **Init flow split**: `context-core`'s `init-context` scaffolds the skeleton; role plugins (e.g., `devcon`) trigger it on uninitialized repos and populate role-specific content.
- **Aggregator/workspace `children.md` is markdown** (not JSON), structurally formatted, script-backed by skill that writes it.
- **Sub-project skills are scope-gated by design.** Post-context-discovery loading is the intended invocation flow — project-level skills are invisible to plugin managers until `resolve-topology` resolves the active scope and returns `available_skills`. No up-front catalog surfacing; no audit-on-load (sub-project skills are their own author's responsibility within their own scope, not ecosystem-shared).
- **`invoke-sub-project-skill` carried forward from ICON v1 as a class-2 skill in context-core** (agent-auto-invocable, not user-invocable). Shared primitive that every role plugin's manager uses — not per-plugin copies. Frames loaded sub-project skill content as active instructions; mechanical, no role-specific reasoning.
- **`using-skills` lives in context-core as a class-2 shared primitive.** Trimmed for the ecosystem: keeps the discipline (the rule, rationalization-prevention table, red flags, instruction-priority hierarchy) but drops the dev-specific Skill Priority ordering and Skill Type examples. Each role plugin's manager doc declares its own priority over its own catalog. Each plugin's `using-skills`-related guidance is local; the core skill provides the universal discipline.
- **Primary runtime: Copilot CLI. Secondary: Claude Code.** Where conventions diverge, Copilot CLI patterns win. Both are supported per ADR-004 tool-agnostic content; this is a framing/priority decision.
- **Direct-write surface = `tasks/{lane}/` ONLY.** Every other `.context/` change dispatches to context-specialist via the runtime's sub-agent tool (Copilot: `agent`/`Task`; Claude: `Agent`).
- **Internal vs user-invocable is a first-class skill metadata distinction.** `user-invocable: true|false` in SKILL.md frontmatter; mirrors Copilot CLI's existing agent-frontmatter convention. Audit enforces cross-plugin call restrictions.
- **Each role plugin ships its own manager.** `devcon-manager`, `pm-manager`, `agentic-toolkit-manager`, etc. Managers prefer in-plugin skills on conceptual overlap; may freely call other plugins' user-invocable skills; forbidden from calling other plugins' internal skills.
- **Scripts beat prompts for standardized, repeatable operations.** Internal skills are mostly script-backed thin wrappers; user-invocable skills are mostly prompted intent-driven work.
- **Lane declaration: opt-in via manifest** under custom `context:` namespace in `plugin.json` (both runtimes ignore unknown top-level keys).
- **Oversize handling: auto-split, then dead-ref rewrite** (built into specialist's post-write pipeline).
- **Retros layout: per-plugin file (`retrospectives/{plugin}.md`) + shared file (`retrospectives/shared.md`).** Specialist owns all retro writes via `append-retro` internal skill (script-backed, cap-rotation).
- **Cache: shared, no per-plugin partitioning.** `.context/cache/` treated as `/tmp`-equivalent.
- **Domain contributions: specialist trusts any non-task write from a conformant plugin.** No per-plugin domain-prefix authorization.
- **First-wave plugins: `context-core`, `devcon`, `pm`, `agentic-toolkit`. Standalone peer: `ds-mcp`.** `ecological-impact` dropped from v2 entirely.
- **`release-plugin` is a per-plugin meta-skill.** Each plugin's repo includes its own `release-plugin`; `agentic-toolkit` provides the template generator.
- **Plugin metadata formally defined** under `context:` namespace; includes `dependsOn`, `composesWith`, `writes`, `reads`, `dispatches`, `purpose`, `verify`, `protocolVersion`.
- **Formal interface spec is a first-class context-core deliverable**, versioned (v1.0 at launch). Lives at `spec/INTERFACE-v1.md`.
- **Topology resolution is correctness, not convenience.** Four supported topologies (single project, hierarchical monorepo, multi-module, VS Code workspace). META.md per `.context/` declares its scope (`leaf | aggregator | root | workspace`); detection is deterministic when scope is declared.
- **VS Code workspace = dedicated folder convention.** Per DataScan practice: every workspace has its own dedicated folder (e.g., `~/dev/workspaces/FullWiStack/`); that folder is a git repo; that folder hosts the workspace-level `.context/`, `.claude/`, `.copilot/`. Workspace `.context/` plays aggregator-like role across git-repo boundaries (references include git-repo URL + on-disk path).
- **ICON v1 is the prototype; ICON v2 = this ecosystem.** Migration is mostly transparent for `.context/` content (additive bumps + retro rename); plugin migration is install-new + uninstall-v1.
- **Working names**: `context-core`, `devcon`, `pm`, `agentic-toolkit`, `ds-mcp` — all placeholders.
- **Deliverable shape**: vision sketch first (this task), iterate with user, then RFC in a follow-up task.

## Key Files
- `.context/tasks/ICON-0052-ecosystem-vision/vision.md` — the primary deliverable (round 2)
- `.context/tasks/ICON-0052-ecosystem-vision/plan.md` — this file
- No ICON source files change in this task.

## Progress
- [x] Branch + folder created
- [x] design-first pass round 1: architecture alternatives (A, B, C) → recommended B → user countered with hybrid → refined to B+
- [x] design-first pass round 2: user narrowed direct-write surface to tasks-only, formalized internal/external skill distinction, added scripting principle, set retros layout, confirmed agentic-toolkit first-wave, pivoted to Copilot CLI primary, flagged topology as load-bearing
- [x] Research: Copilot CLI plugin manifest, custom agents reference, skill frontmatter, dual-runtime authoring; Claude Code manifest schema
- [x] Draft vision.md round 2 (folds in all round-2 decisions + research findings)
- [ ] User review of round-2 draft ← IN PROGRESS
- [ ] Iterate on remaining open questions (§11 still-open list)
- [ ] Decide commit/abandon of ICON-0051 artifacts (separate decision; not in this task's scope)
- [ ] (Follow-up task) Graduate sketch to ORG-004 RFC

## Open Questions / Blockers (round 3 still-open)
- **#13 Topology resolution algorithm** — acknowledged work item, not a question. Sketched in vision §4; rigorous algorithm + fixture-tests are deliverables for the formal interface spec, not this sketch. Biggest remaining technical risk.
- **#22 Per-plugin manager reliability — Claude Code only** — inherited gap from ICON v1. Current strategy is `commands/manager.md` slash + `enable-manager-default` setting; only reliable if user explicitly runs `/manager` at session start. Copilot CLI has no such issue (explicit agent picker). v2 inherits the concern; no clean solution beyond carrying forward the current pattern.
- **Naming**: working names remain placeholders.
- **ICON-0051 artifacts**: the decomposition RFC remains untracked in `.context/tasks/ICON-0051-decomposition-rfc/`. Disposition is a separate decision the user will make.

### Closed in round 3
#15 (separate repos), #16 (Copilot CLI canonical, no Claude-only features), #18 (markdown children.md; aggregator init suggests excludes adjustments), #19 (shared retro for cross-plugin / protocol / conformance lessons), #20 (block — script-side guard + audit), #21 (plugin namespacing handles collisions natively; YAGNI on registry), #23 (`iconrc.json#/repo_type` is the truth source), #24 (init split: context-core scaffolds skeleton, role plugin populates).

## Constraints
- ICON v1 is the prototype, not the implementation target. Sketch may borrow concepts from ICON but is NOT a refactor of ICON.
- No edits to current ICON plugin files outside `.context/tasks/ICON-0052-ecosystem-vision/`.
- Per auto-memory: no GitLab issue auto-filing for this work unless user explicitly directs.
- Per auto-memory: do not release / tag / Slack-post on this task.
- Vision sketch is a discussion artifact; ORG-004 compliance is NOT required at this stage (deferred to the follow-up RFC task).
- ICON-0052 ID is locally assigned (next free after ICON-0051); no GitLab issue exists for it yet.
- Round-2 research consulted official Claude Code and Copilot CLI plugin docs; cross-runtime compatibility patterns are grounded, not speculated.
