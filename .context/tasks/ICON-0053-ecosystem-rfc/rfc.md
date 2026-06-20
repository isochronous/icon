# ICON v2: A Federated Plugin Ecosystem for `.context/`-Centric SDLC Tooling

**Status:** Draft — for team review  
**Author:** ICON maintainer team  
**Date:** 2026-06-03  
**Primary runtime:** GitHub Copilot CLI. **Secondary:** Anthropic Claude Code. No Claude-only features.

---

## Summary

ICON v1 is a single bundled plugin spanning dev orchestration, product management, the `.context/` system, MCP integration, and meta-tooling for plugin authoring. Its monolithic shape produces three measurable strains: the manager agent sits at 97.1% of its always-loaded token budget, there is no clean affordance for external SDLC consumers (QA, devops, release management) that want narrow capabilities, and per-role cost is inefficient (a PM user pays for `systematic-debugging`; a dev user pays for `product-manager`).

This RFC proposes **ICON v2: a multi-plugin ecosystem composed around a `.context/`-centric base plugin**. The first wave is four plugins (`context-core`, `devcon`, `pm`, `agentic-toolkit`) plus one standalone ecosystem peer (`ds-mcp`); a future-wave shelf claims lane prefixes for `qa`, `release-mgmt`, `devops`, `triage`, and `support`. Composition follows a federated protocol: `context-core` publishes a formal versioned interface; each role plugin ships its own manager and writes directly only to its declared `tasks/` lane; every other `.context/` write is dispatched to a lean `context-specialist` skill router in `context-core` that selects the appropriate internal (script-backed) skill and applies automatic post-write discipline (oversize-split + dead-ref rewrite, schema validation, retro cap-rotation). ICON v1 becomes the prototype; v2 supersedes it once parity is reached. `.context/` schema is forward-compatible — existing repos migrate by installing v2 plugins with one additive `iconrc.json` bump and a single retro-file rename.

---

## Background

### Current state

ICON v1 ships as a single Claude Code / Copilot CLI plugin at `gitlab.com/onedatascan/ai-platform/plugins/icon` (currently v1.18.2). It contains:

- **9 agents** — `manager`, `planner`, `architect`, `coder`, `tester`, `reviewer`, `researcher`, `context-specialist`, `product-manager`.
- **49 consumer-facing skills** — spanning dev orchestration, context management, product management, MCP integration, meta-tooling, and a single `ecological-impact` skill.
- **3 maintainer-only skills** — `icon-audit`, `release-plugin`, `changelog-entry`.
- **Supporting infrastructure** — 11 ADRs, a 49-line retrospective log capped at 10 entries, a pre-commit hook enforcing four invariants (`shared/common-constraints.md` byte-equality, dead-reference resolution, `iconrc.json` version-bump gate, script parity), and two MCP server configurations (`gitlab`, `atlassian`).

A user installing ICON gets all of this, regardless of which subset they actually use.

### Pressures driving the proposal

Three distinct pressures, each independently surfaced, jointly force the question:

**The bloat problem.** ICON's manager agent sits at 97.1% of its always-loaded token budget. Copilot CLI imposes a 30,000-character cap on agent markdown content. Adding QA, release-management, devops, or any other SDLC capability to ICON in v1's shape — more agents, more skills, all always loaded — does not fit, regardless of how well-designed the additions might be. The structural ceiling is real.

**The shared-substrate observation.** The `.context/` system (schema, navigation discipline, file-size rules, audit pattern, retrospective protocol, topology resolution) is genuinely universal across SDLC roles. The rest of ICON (manager-routing, RFC authoring, MR discipline, jira-story formatting) is role-specific. The asymmetry — *one* universal capability and *many* role-specific ones — is precisely the shape a plugin ecosystem exists to express.

**The composition challenge.** Once role-specific plugins are real, they have to compose: share an understanding of `.context/` without each one re-stating the rules, agree on who writes what without producing a coordination mess, and handle Copilot CLI's first-found-wins skill-name resolution without silent overrides. This is the load-bearing technical question this RFC addresses.

### Why Copilot CLI is primary

The DataScan target audience operates on Copilot CLI day-to-day. Claude Code is a supported secondary runtime, but the design rejects any feature not replicable in Copilot CLI. Tool-agnostic content remains the goal; primary-runtime framing only affects design choices where two valid forks exist.

### How we got here

This RFC consolidates four prior threads of work done by the ICON maintainer team:

1. **An earlier internal audit** considered four candidate decomposition models (two-/three-/four-plugin, plus a core + composable-blocks variant) and recommended a three-plugin split with the honest caveat that no audit finding structurally compelled the split.
2. **An earlier decomposition proposal** kept ICON at the center and carved off pieces (`ds-mcp`, `agentic-toolkit`, an `icon-pm` addon, optional `ai-sustainability`) plus a small read-only `context-reader` plugin. Several components from that proposal survive directly into this RFC (see Abandoned Ideas).
3. **A vision sketch** inverted the prior framing: build a fresh `.context/`-centric base plugin (`context-core`) as the foundation; treat ICON v1 as the prototype; design v2 as new plugins, not carve-outs. The sketch iterated through three design-first rounds with the maintainer to close architectural questions and ground the spec against verified Copilot CLI and Claude Code plugin documentation.
4. **An internal team discussion** preserved the umbrella-naming consensus (marketplace as umbrella, plugins keep their own identities; reject the `ICON-FOO` prefix pattern). That consensus carries forward into v2 unchanged.

### Desired state

A user installs the marketplace once. They install a role-shaped set (e.g., `dev-set`) and get exactly the plugins their role needs: `context-core` (always required, provides the protocol), one role plugin, optionally `ds-mcp` if they consume MCP servers, optionally `agentic-toolkit` if they author plugins. The token footprint matches the role. Adding new SDLC capabilities means adding new plugins — not bloating the existing ones. Cross-plugin work composes through declared metadata and intentional dispatch, not through implicit coupling.

---

## Proposal

This proposal has six components, each independently load-bearing: (1) the principles, (2) the composition architecture, (3) the plugin lineup, (4) the skill invocability taxonomy, (5) the repository-topology resolution model, (6) the scripting backbone and dynamic sub-project skill loading. Each is described below.

### Component 1 — Principles

These are the beliefs the ecosystem is built on. If any of these stops being true, the design should be revisited.

1. **`.context/` is the universal substrate.** Every plugin reads from the same `.context/` schema owned by `context-core`.
2. **Each plugin's scope is "only what that role uses."** No inheritance bloat; the cost of any role is the cost of that role.
3. **Composition over inheritance.** Plugins are siblings, not children. Role plugins depend on `context-core` only.
4. **Rich skill library; lean agents.** `context-core` ships many skills; agents stay small and route to skills on demand. This matches Copilot CLI's 30,000-char agent cap and avoids the always-loaded cost.
5. **Internal vs user-invocable is first-class metadata.** Skill frontmatter declares both `user-invocable` and `disable-model-invocation`, producing four distinct invocation classes (see Component 4).
6. **Scripts beat prompts for standardized, repeatable tasks.** Internal skills are mostly script-backed thin wrappers; user-invocable skills are mostly prompted intent-driven work.
7. **The protocol is a formal, versioned interface.** Role plugins program against `context-core`'s published spec, not against its internals.
8. **Writes are gatekept structurally except in the declared task lane.** Role plugins own `tasks/{role}-*/`; every other `.context/` change goes through `context-specialist`.
9. **Discipline is built into the writer, not bolted on.** Oversize-split + dead-ref rewrite, retro cap-rotation, schema validation are automatic post-write behavior, not callable skills.
10. **Each plugin has its own manager.** Per-plugin managers prefer in-plugin skills on overlap and dispatch cross-plugin only on out-of-lane intent.
11. **Repository-topology resolution is correctness, not convenience.** Single-project, hierarchical-monorepo, multi-module, and VS Code workspace topologies must all resolve reliably; getting this wrong is a correctness failure.
12. **ICON v1 is the prototype.** v2 is the productized version. Concepts may transfer; code does not.

### Component 2 — Architecture (B+ v2)

```
              ┌──────────────────────────────────────────┐
              │              context-core                │
              │                                          │
              │  ┌────────────────────────────────────┐  │
              │  │  Formal Interface Spec (v1.0)      │  │  ← published, versioned
              │  │  .context/ schema, lane syntax,    │  │     the contract role
              │  │  dispatch protocol, topology rules │  │     plugins program against
              │  └────────────────────────────────────┘  │
              │                                          │
              │  ┌────────────────────────────────────┐  │
              │  │  context-specialist (agent, lean)  │  │  ← skill router; not a writer
              │  │  routes dispatch → internal skill  │  │     itself. Lean prompt.
              │  └────────────────────────────────────┘  │
              │                                          │
              │  ┌────────────────────────────────────┐  │
              │  │  Internal skills (class 4)         │  │  ← rich library; mostly
              │  │  write-adr, update-domain,         │  │     script-backed.
              │  │  append-retro, bump-iconrc,        │  │     Each enforces its
              │  │  oversize-split-then-deadref,      │  │     own discipline.
              │  │  validate-schema, ...              │  │
              │  └────────────────────────────────────┘  │
              │                                          │
              │  ┌────────────────────────────────────┐  │
              │  │  User-invocable + shared primitives │  │  ← reader, audit, init,
              │  │  read-iconrc, find-current-task,   │  │     upgrade, using-skills,
              │  │  resolve-topology, audit-context,  │  │     invoke-sub-project-skill.
              │  │  using-skills, invoke-sub-project- │  │
              │  │  skill, ...                        │  │
              │  └────────────────────────────────────┘  │
              └──────────┬───────────────────────────────┘
                         │ dependsOn: context-core
       ┌─────────────────┼──────────────────┬──────────────────────┐
       │                 │                  │                      │
  ┌────▼─────┐     ┌─────▼──────┐    ┌──────▼──────────┐    ┌──────▼─────────┐
  │  devcon  │     │     pm     │    │ agentic-toolkit │    │ (future shelf) │
  │  + own   │     │  + own     │    │  + own manager  │    │  qa, release-  │
  │  manager │     │  manager   │    │                 │    │  mgmt, devops, │
  │  writes: │     │  writes:   │    │  writes: tasks/ │    │  triage, …     │
  │  tasks/  │     │  tasks/    │    │  author-*/      │    │                │
  │  dev-*   │     │  pm-*      │    │                 │    │                │
  └──────────┘     └────────────┘    └─────────────────┘    └────────────────┘

  Each role plugin ships its own manager (lean), reads .context/ via context-core's
  user-invocable skills, writes directly only inside its declared task lane, and
  dispatches every other .context/ write to context-specialist.

  Standalone ecosystem peer (not depicted): ds-mcp (MCP foundation, optional consumer).
```

The defining property: writes to non-`tasks/` paths *always* go through `context-specialist`. The specialist is a lean skill router (per Copilot CLI's 30k-char cap on agent content); the discipline lives in class-4 internal skills it dispatches to, many of which are script-backed for determinism.

#### Write semantics by path

| `.context/` path | Direct write by role plugin? | Mechanism | Automatic post-write discipline |
|---|---|---|---|
| `tasks/{role}-*/**` | yes (only the declared role) | direct file write | (none — task hygiene is the role's responsibility) |
| `retrospectives/{plugin}.md` | no | dispatch → `context-specialist` → `append-retro` | cap-rotation, script-backed |
| `retrospectives/shared.md` | no | dispatch → `context-specialist` → `append-retro` | cap-rotation; for cross-plugin / protocol / conformance-affecting lessons |
| `decisions/**` (ADRs) | no | dispatch → `context-specialist` → `write-adr` | schema, cross-ref check, oversize-split + dead-ref rewrite |
| `domains/**`, `standards/**`, `workflows/**` | no | dispatch → `context-specialist` → `update-narrative` | oversize-split + dead-ref rewrite, cross-ref check |
| `overview.md` | no | dispatch → `context-specialist` → `update-overview` | oversize-split + dead-ref rewrite |
| `iconrc.json` | no | dispatch → `context-specialist` → `bump-iconrc` | schema, version SSOT enforcement, script-backed |
| `META.md` | no | dispatch → `context-specialist` → `update-meta` | schema check (this IS the schema) |
| `cache/**` | yes (any plugin) | direct file write | `/tmp`-equivalent, no per-plugin partitioning |

### Component 3 — Plugin lineup

#### First wave (v2 launch)

| Plugin | Role | Owned lane | Notes |
|---|---|---|---|
| `context-core` | `.context/` protocol + reader + structural writer + topology resolution + shared primitives | (none — owns the protocol, not a lane) | Hard dependency for every role plugin |
| `devcon` | Dev orchestration: features, bug fixes, refactors, code review, debugging | `tasks/dev-*/**` | Own manager (`devcon-manager`); ~85% of ICON v1's dev-flavored skills |
| `pm` | Product management: stories, RFCs, sprint planning, meeting summaries | `tasks/pm-*/**` | Own manager (`pm-manager`); lightweight footprint |
| `agentic-toolkit` | Plugin authoring: scaffolding new ecosystem plugins, generating templated audit/release/conformance skills | `tasks/author-*/**` | Own manager; ships `scaffold-plugin`, `generate-audit-skill`, `generate-release-skill`, `generate-conformance-test`, plus `writing-skills`, `plugin-design`, `agent-evaluation` from ICON v1 |

#### Standalone ecosystem peer

| Plugin | Role | Notes |
|---|---|---|
| `ds-mcp` | MCP foundation (GitLab + Atlassian, currently) | Carries forward from prior decomposition work. No `context-core` dependency. Skills auto-invoke when installed; consumers (`devcon`, `pm`, `qa`, third-party plugins like Selenium) include `composesWith: ds-mcp` |

#### Future-wave shelf

These plugins are *not* designed in this RFC. They are listed to claim lane prefixes and demonstrate the ecosystem grows without restructuring.

| Plugin | Role | Lane prefix |
|---|---|---|
| `qa` | Test orchestration, defect triage | `tasks/qa-*/` |
| `release-mgmt` | Release engineering (cross-plugin coordination; distinct from per-plugin `release-plugin`) | `tasks/release-*/` |
| `devops` | Infrastructure operations | `tasks/devops-*/` |
| `triage` | Incident response | `tasks/triage-*/` |
| `support` | Customer-facing support | `tasks/support-*/` |

#### Per-plugin manager pattern

Every role plugin ships its own manager. The manager is lean (Copilot CLI's 30k-char cap applies); its role is intent routing within the plugin's catalog, falling back to other plugins' user-invocable skills only when intent is clearly outside its lane.

Copilot CLI's explicit agent picker handles which manager is active at any moment. Claude Code routes implicitly via agent descriptions; v2 inherits ICON v1's `commands/manager.md` slash-command pattern for explicit role switching (see Addendum: Remaining Work).

### Component 4 — Skill invocability taxonomy

Skills declare two orthogonal axes in `SKILL.md` frontmatter:

- `user-invocable: true|false` — does typing `/skill-name` invoke it?
- `disable-model-invocation: true|false` — can agents auto-pick it via description match?

This yields four distinct classes:

| Class | `user-invocable` | `disable-model-invocation` | Description style | Examples |
|---|---|---|---|---|
| 1. Standard | true | false | Rich (drives auto-invocation) | `read-iconrc`, `audit-context`, `rfc` |
| 2. Agent-auto only | false | false | Rich (drives auto-invocation) | `using-skills`, `invoke-sub-project-skill`, `resolve-topology`-style helpers |
| 3. User-only | true | true | Rich (users read it) | `/icon:release-plugin`, role-switching commands |
| 4. **Internal** | false | true | Minimal boilerplate: `"Internal skill. Do not invoke without explicit direction."` | `write-adr`, `append-retro`, `bump-iconrc`, `oversize-split-then-deadref` |

Class 4 (internal) is the key to keeping the rich skill library affordable. Descriptions are deliberately minimal — under ~12 words, same boilerplate string — because descriptions are always loaded into context. A rich library with minimal internal descriptions costs nearly nothing at session start; the bulk loads only when the owning agent explicitly names a specific internal skill.

**Cross-plugin invocation rules:**

- Any plugin's agent may auto-invoke any other plugin's class-1 or class-2 skills freely (runtime description-match routing handles it).
- Class 3 (user-only) skills are skipped by agent auto-routing in both runtimes by design.
- Class 4 (internal) skills are invoked only by the agent named in their `owned-by` frontmatter, only when explicitly instructed by that agent's prompt. Cross-plugin agents do not call other plugins' internal skills, even with explicit reference. This is the structural boundary the ecosystem relies on.

Audit (`audit-plugin`) flags any plugin whose agent definitions explicitly reference another plugin's internal skill. Runtime enforcement is best-effort: internal skills include a first-line script guard asserting the caller matches `owned-by`. Primary discipline is audit + author convention.

### Component 5 — Repository topology and `.context/` resolution

Four supported topology types, each shaping the tree of `.context/` folders differently:

| Type | Layout | Example |
|---|---|---|
| **Single project** | One `.context/` at project root | `my-project/.context/` (rich) |
| **Hierarchical monorepo** | Root `.context/` (thin, repo overview, pointers) → aggregator `.context/` per group level (thin, group overview, child pointers) → leaf `.context/` per project (rich) | `my-monorepo/.context/` → `services/.context/` → `services/auth/.context/` |
| **Multi-module** | Root `.context/` (thin, leaf pointers) → leaf `.context/` per project. No intermediate aggregator level. | `my-multi-module/.context/` → `tools/linter/.context/` |
| **VS Code workspace** | Workspace folder is its own git repo (DataScan convention); hosts workspace-level `.context/.claude/.copilot/`. Workspace `.context/` plays aggregator-like role across git-repo boundaries (references include git-repo URL + on-disk path, not just relative path). Each referenced project is its own repo with its own `.context/`. | `~/dev/workspaces/FullWiStack/.context/` references `~/dev/proj-a/.context/`, `~/dev/proj-b/.context/`, ... |

#### Truth source: `iconrc.json#/repo_type`

ICON v1 already encodes the topology type:

```jsonc
{
  "version": "1.2",
  "repo_type": "project",          // project | monorepo | multimodule | workspace
  "local_task_id_prefix": "ICON",
  "default_branch": "main",
  "cache_expires_after_days": 30,
  "excludes": ["architecture", "testing", "styling"]
}
```

v2 inherits `repo_type` as the authoritative topology declaration. `init-context` writes it once; resolution skills read it. No heuristic detection at session start. Each per-scope `.context/`'s `META.md` declares its scope (`leaf | aggregator | root | workspace`) for sub-tree navigation within the chosen topology.

The `excludes` array trims default `context_template/` folders not relevant to the current scope — e.g., an aggregator-scope `.context/` likely excludes `domains`, `standards`, `workflows` (those belong at the leaf level). Trimming is suggested to the user during init/upgrade, not automatic.

#### Resolution algorithm

For any task:

1. Read `iconrc.json#/repo_type` at the nearest enclosing `.context/`. This is the authoritative topology type.
2. Determine task scope from the task description, working-directory path, and topology type. Single-project / leaf-only / aggregator-spanning / repo-wide / workspace-spanning resolve to corresponding `.context/` levels.
3. Resolve to the matching `.context/` by walking child pointers (from root down) or working-directory parents (from leaf up), per topology type.
4. Verify resolution by reading the chosen `.context/`'s `META.md` scope declaration. If declared scope mismatches the task's scope, surface the mismatch to the user before proceeding.

**Requires Further Detail.** The rigorous algorithm — exact tie-breaking rules, scope-classification heuristics, workspace cross-repo reference handling, fixture-tests covering all four topology types — is a deliverable of the formal interface spec (Implementation: API), not this RFC. ICON v1's existing topology skills (`context-specialist-detect-tree-position`, `context-specialist-impl-{branch,leaf,root}`, `initialize-monorepo`, `initialize-multimodule`) are the conceptual ancestor. The maintainer has flagged v1's reliability gap as the load-bearing technical risk for v2.

### Component 6 — Scripting backbone and dynamic sub-project skill loading

#### Scripting backbone

Internal skills that perform standardized, repeatable operations are script-backed. Each internal-skill folder contains a thin `SKILL.md` plus the deterministic logic:

```
skills/append-retro-entry/
├── SKILL.md          # frontmatter + minimal prompt: "run ./append.sh with given args"
└── append.sh         # deterministic logic — read retro file, append entry,
                      # enforce cap-rotation, write back
```

Operations that are script-backed by default: `oversize-split-then-deadref`, `bump-iconrc`, `validate-schema`, `audit-context`, plus plugin-level operations like `release-plugin` (per-plugin version bump + CHANGELOG + tag) and `verify` (per-plugin smoke test). Scripts live alongside the skill that wraps them; both Copilot CLI and Claude Code invoke them via the shell tool.

#### Dynamic sub-project skill loading

Workspace and hierarchical-monorepo topologies introduce a runtime concern: sub-projects may ship their own skills the ecosystem plugins don't know about at install time. A workspace referencing 5 projects, or a monorepo with 5 services, can have each project ship its own `.copilot/skills/`.

Project-level skills are **scope-gated by design** — *not* surfaced into the ecosystem plugin's catalog at session start. A workspace user working in `proj-a` should not see `proj-b`'s skills as routing candidates; that's the isolation property the design intentionally buys. Discovery happens *after* topology resolution determines the active scope.

The runtime pattern (carried forward unchanged from ICON v1):

1. Manager calls a context-core resolution skill which returns the active `.context/` plus `available_skills` — a list of absolute paths to sub-project skills at that scope.
2. Manager picks a skill matching the user's intent.
3. Manager invokes `invoke-sub-project-skill` with the chosen path.
4. `invoke-sub-project-skill` reads the file and wraps it in explicit "execute these instructions" framing language. The framing is the load-bearing trick: without it, the model treats the file as reference material; with it, the content runs as active instructions.

`invoke-sub-project-skill` lives in `context-core` as a class-2 shared primitive (one shared implementation rather than per-plugin copies). Sub-project skills are subject to their own author's discipline within their own `.context/`'s scope, not to ecosystem-shared lane discipline.

---

## Abandoned Ideas

This section captures candidate approaches considered and rejected, with the reason for rejection. Several survived in modified form; those are noted explicitly.

### Keep-ICON-at-center decomposition framing

**What it was.** An earlier proposal kept ICON as the dev plugin (minus a few carved-off pieces) and added `ds-mcp`, `agentic-toolkit`, and a read-only `context-reader` as siblings.

**Why rejected.** Treats ICON as the substrate when `.context/` is the actual substrate. Forces every ecosystem plugin to either depend on ICON (inheriting its dev opinions) or duplicate the `.context/` capability. This RFC inverts the framing: ICON v1 becomes the prototype, `context-core` is a new plugin built around `.context/` as the central pillar, ICON v2 = the whole ecosystem.

**What was salvaged.** `ds-mcp` as a standalone foundation plugin (unchanged). `agentic-toolkit` as a separate plugin for authoring substrate (unchanged). The plugin-metadata standard (`tags`, `purpose`, `dependsOn`, `composesWith`, `provides`, `verify`) — adopted into v2 under a custom `context:` namespace in `plugin.json`. The marketplace-as-umbrella framing (executive-facing surface; per-plugin identities preserved). The rejection of the `ICON-FOO` prefix pattern.

### Strict A — centralized gatekeeper (all writes through fixed skill API)

**What it was.** A single set of fixed-API write skills in `context-core` that every role plugin invokes for every `.context/` write. No role plugin writes any file directly.

**Why rejected.** Every new write capability requires a `context-core` release. The skill set grows linearly with role demands; the choke point reintroduces the bloat problem at a different layer. Loses write ergonomics for routine task hygiene.

**What was salvaged.** The intuition that *invariants must be enforced at a choke point* — preserved in v2 via `context-specialist`'s dispatch for non-`tasks/` writes. The choke point is narrower (only non-`tasks/` writes) and the dispatch target is a *thinking router* (lean agent + rich internal skill library), not a fixed-API surface.

### Strict C — layered capability stack (protocol, reader, maintainer as separate plugins)

**What it was.** Split `context-core` into separately-installable layers: `context-protocol` (schema docs only), `context-reader` (read skills only), `context-maintainer` (init/upgrade/audit/write skills + maintenance agent). Role plugins declare which layers they need.

**Why rejected.** Install complexity tax. "Give me the dev stack" requires 3+ plugins. Marketplace bundles become essential UX glue rather than helpful convenience. More cross-version compatibility surfaces. Optimizes for a separation that DataScan's role plugins don't need (every role plugin wants reader + writer; no current consumer wants only protocol).

### ICON-FOO prefix-everything naming

**What it was.** A proposal in internal discussion that every ecosystem plugin carry an `ICON-` prefix (`ICON-Core`, `ICON-QA`, `ICON-SDD`) so leadership and contributors recognize family membership.

**Why rejected.** Three reasons: technical hygiene (60+ skills prefixed `ICON-*` is genuinely worse for humans and agents), inheritance of opinions (calling a QA plugin `ICON-QA` makes it harder for the QA team to disagree with ICON's choices), and routing confusion (agents conflating `ICON` vs `ICON-FOO` at runtime).

**What was salvaged.** Marketplace umbrella resolves leadership's recognition need without prefix imposition. Where one plugin is genuinely an addon of another, a shared prefix is meaningful as a dependency signal.

### Centralized review-board governance

**What it was.** A first-pass framing where contributors open issues, one team handles all implementation, and a verification audit caps each change.

**Why rejected.** Does not scale. If QA wants their plugin shipped this quarter and the answer is "open an issue, central team gets to it eventually," they will build outside the ecosystem. Hygiene preserved by toolchain (the published protocol, `agentic-toolkit`-generated audit skills, per-plugin verify scripts) beats hygiene preserved by a review board.

### `ecological-impact` as a separate plugin

**What it was.** An earlier proposal floated `ai-sustainability` as a standalone plugin housing the `ecological-impact` skill after a runtime-agnostic rewrite.

**Why rejected.** A single skill does not merit a whole plugin. Dropped from v2 entirely.

### Per-plugin cache partitioning

**What it was.** `.context/cache/{plugin}/**` namespace, each plugin owns its own subfolder.

**Why rejected.** No benefit at v2's scale. Cache is treated as `.context/`'s `/tmp` equivalent — shared, plugins coexist, contents can be wiped by any plugin.

### Auto-split without follow-up dead-ref check

**What it was.** Split oversized files silently as part of the write pipeline; trust authors to update incoming references separately.

**Why rejected.** Splits change anchor paths; stale references break silently. v2 specialist auto-splits *and then* runs a dead-ref check that rewrites incoming references to the new paths in the same pipeline operation.

### `children.md` as JSON (rather than markdown)

**What it was.** Encode aggregator and workspace child pointers as a JSON file (machine-parseable, schema-validatable) instead of a structured markdown file.

**Why rejected.** Markdown is human-readable; the `.context/` discipline favors human-readable formats throughout. Script-backed skills can parse structured markdown reliably. JSON loses readability without buying parser determinism the markdown form doesn't already provide.

### Reserved skill-name registry (centrally managed)

**What it was.** A marketplace-published, centrally-maintained registry of reserved skill names to prevent cross-plugin collisions.

**Why rejected.** YAGNI. Both Copilot CLI and Claude Code support plugin namespacing natively — `/devcon:commit` vs `/pm:commit` resolves cleanly without a registry. If collisions become a real problem at scale, revisit.

### Audit-on-load for sub-project skills

**What it was.** Block execution of any sub-project skill (loaded dynamically via `invoke-sub-project-skill`) that fails `audit-plugin` conformance checks.

**Why rejected.** Sub-project skills operate within their own project's `.context/` scope, not against ecosystem-shared surfaces. The project's author owns their `.context/` and their skills; violations affect them, not the ecosystem. Audit-on-load is unnecessary trust-machinery for content the ecosystem already trusts within its own scope.

### Up-front discoverability of sub-project skills

**What it was.** Surface sub-project skill paths in `children.md` so plugin managers know what's available before scope resolution; cache `available_skills` per session; provide a `list-subproject-skills` user-invocable skill.

**Why rejected.** Sub-project skills are scope-gated *by design*. A workspace user working in `proj-a` should not see `proj-b`'s skills as routing candidates. Post-context-discovery loading is the correctness property the design buys, not a UX cost to be optimized away.

---

## Implementation

### UX

#### Marketplace and install flow

The DataScan AI marketplace lists every ecosystem plugin. The marketplace README is the executive-facing surface for the umbrella; per-plugin identities live in each plugin's own README.

The marketplace publishes **sets** — pre-bundled compositions for common roles:

```jsonc
// marketplace.json
{
  "sets": {
    "dev-set":        ["context-core", "devcon", "ds-mcp"],
    "pm-set":         ["context-core", "pm"],
    "author-set":     ["context-core", "agentic-toolkit"],
    "qa-set":         ["context-core", "qa"],
    "full-engineer":  ["context-core", "devcon", "pm", "ds-mcp"],
    "full-sdlc":      ["context-core", "devcon", "pm", "qa", "release-mgmt", "devops", "triage", "support", "ds-mcp"]
  }
}
```

Copilot CLI is the canonical install syntax:

```bash
copilot plugin marketplace add https://gitlab.com/onedatascan/ai-platform/marketplace.git
copilot plugin install --set dev-set@datascan
# → installs context-core + devcon + ds-mcp

# Or pick-and-mix:
copilot plugin install context-core@datascan
copilot plugin install devcon@datascan
```

Equivalent `claude plugin` syntax works in Claude Code.

#### Migration from ICON v1

| ICON v1 user | v2 path |
|---|---|
| Pure dev user | Install `context-core` + `devcon` + `ds-mcp` (~95% of v1 dev capabilities) |
| Pure PM user | Install `context-core` + `pm` |
| Mixed dev/PM user | Install `context-core` + `devcon` + `pm` + `ds-mcp` |
| Plugin author | Install `agentic-toolkit` (depends on `context-core`) |
| MCP-only consumer | Install `ds-mcp` alone — no `context-core` needed |

`.context/` migration is mostly transparent. v2's v1.0 protocol matches ICON v1's existing `.context/` shape with three additive bumps:

- `retrospectives.md` → `retrospectives/devcon.md` (rename + relocation). One-shot script-backed migration: `migrate-retros-to-v2`.
- `iconrc.json` gains optional `protocolVersion` and ecosystem-plugin declaration fields (additive only).
- `META.md` gains a required `scope: leaf | aggregator | root | workspace` declaration. One-shot script writes it based on detected topology.

A `migrate-to-v2` user-invocable skill in `context-core` or `agentic-toolkit` walks an existing `.context/` through the additive changes. Not blocking for v2 launch; built when the first user requests it.

### API

The formal interface spec is the public contract. It lives at `context-core/spec/INTERFACE-v1.md` and is the canonical source. Every change to the spec is a versioned `context-core` release.

**v1.0 contents (mandatory):**

1. **`.context/` directory structure.** Required and optional paths per scope (leaf, aggregator, root, workspace).
2. **Per-file schemas.** What goes in `overview.md`, ADRs, domain docs, workflows, standards, retros (per-plugin and shared), `iconrc.json`, `META.md`, task plans. JSON Schema for structured files; markdown templates with required sections for narrative files.
3. **Topology detection and resolution rules.** The rigorous algorithm sketched in Proposal Component 5; the algorithm itself is `Requires Further Detail` and will be the spec's largest section. Fixture-tests cover all four topology types.
4. **Lane declaration syntax.** JSON Schema for the `context:` manifest namespace fields:
   - `context.protocolVersion` (string, semver)
   - `context.dependsOn[]` ({plugin, versionRange})
   - `context.composesWith[]` ({plugin, optional})
   - `context.writes[]` (glob patterns of owned paths)
   - `context.reads[]` (glob patterns; defaults to `**`)
   - `context.dispatches[]` (sub-agent names this plugin invokes)
   - `context.purpose` (string, one-line)
   - `context.verify` (path to verify script)
5. **Dispatch protocol.** Request/response shapes for role-plugin → `context-specialist`. Cross-runtime — works against Copilot CLI's `agent`/`custom-agent`/`Task` tool and Claude Code's `Agent` tool. Example request payload:

   ```json
   {
     "operation": "write-adr",
     "target": ".context/decisions/012-context-resolution.md",
     "intent": "Decision to use depth-first leaf-priority resolution with explicit scope tags in task plans.",
     "source-plugin": "devcon",
     "source-task": "DEV-0044",
     "input": { ... }
   }
   ```

6. **Skill invocability metadata.** The `user-invocable` / `disable-model-invocation` / `owned-by` frontmatter fields, the four-class taxonomy, the cross-plugin invocation rules from Proposal Component 4.
7. **Reader skill catalog.** Canonical names, inputs, outputs, semantics for every user-invocable reader skill.
8. **Discipline matrix.** Which file types get which automatic post-write check.
9. **Scripting conventions.** How scripts live in skill folders, how they receive arguments, expected output format, error handling.
10. **Versioning policy.** Semver for the spec; additive vs breaking changes.
11. **Conformance audit checklist.** What `audit-context` and `audit-plugin` validate. A plugin that passes audit is conformant.

#### Manifest example (illustrative)

```jsonc
// devcon/.claude-plugin/plugin.json
{
  "$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json",
  "name": "devcon",
  "description": "Dev orchestration plugin: features, bug fixes, code review",
  "version": "1.0.0",
  "author": { "name": "DataScan Engineering", "email": "ai-platform@datascan.com" },
  "license": "MIT",
  "keywords": ["dev", "sdlc", "context"],
  "category": "development",
  "tags": ["sdlc:dev", "role:dev"],

  // Ecosystem-specific fields (custom namespace, ignored by both runtimes)
  "context": {
    "protocolVersion": "1.0",
    "dependsOn": [{ "plugin": "context-core", "versionRange": ">=1.0.0" }],
    "composesWith": [{ "plugin": "ds-mcp", "optional": true }],
    "writes": ["tasks/dev-*/**"],
    "reads": ["**"],
    "dispatches": ["context-specialist"],
    "purpose": "Dev orchestration: features, bug fixes, code review, debugging",
    "verify": "scripts/verify.sh"
  },

  "mcpServers": "./.mcp.json"
}
```

Both Copilot CLI and Claude Code ignore unknown top-level keys; the `context:` namespace is read by `context-core`'s reader, audit, and lane-enforcement machinery.

### Scope and Constraints

**In scope for v2 launch:**

- `context-core` plugin with the v1.0 formal interface spec, complete reader skill catalog, complete internal skill library for non-`tasks/` writes, `context-specialist` dispatch agent, `using-skills` and `invoke-sub-project-skill` as class-2 shared primitives, and init/upgrade/audit skills.
- `devcon` plugin with its own manager and ~85% of ICON v1's dev-flavored skills.
- `pm` plugin with its own manager and ICON v1's product-management skills (`rfc`, `jira-story`, `sprint-goals`, `post-meeting`).
- `agentic-toolkit` plugin with scaffolding skills (`scaffold-plugin`, `generate-audit-skill`, `generate-release-skill`, `generate-conformance-test`) and ICON v1's authoring meta-skills (`writing-skills`, `plugin-design`, `agent-evaluation`).
- `ds-mcp` as a standalone ecosystem peer (carried forward from prior decomposition work).
- The DataScan AI marketplace with the published role-sets above.
- A migration story for ICON v1 users.

**Out of scope for v2 launch (deferred to future work):**

- Future-wave plugins (`qa`, `release-mgmt`, `devops`, `triage`, `support`). Their lane prefixes are reserved; their design is deferred.
- The `switchboard` plugin — ecosystem-wide discovery, routing, and health checks. Defer until ecosystem reaches ~5+ installed plugins per typical user.
- `migrate-to-v2` user-invocable skill (built on first user request).
- A centrally-managed reserved-skill-name registry (YAGNI; plugin namespacing handles it).
- Resolution of the per-plugin manager reliability gap in Claude Code (carried forward from ICON v1 as a known issue; see Addendum).
- A signed-manifests / plugin trust framework (deferred; revisit if external non-DataScan publishers want to ship).
- Final naming (working names used throughout; final brand decision pending leadership input).

---

## Operationalization

### Logging

`context-specialist`'s write-operation log records every dispatched non-`tasks/` write: timestamp, source plugin, source task ID, operation type, target path, success/failure, post-write discipline applied. Lives under `.context/cache/audit-log.md` (cache-tier; subject to the same `/tmp`-equivalent semantics as the rest of `.context/cache/`). No PII expected. Retention is the user's `iconrc.json#/cache_expires_after_days` value.

Role plugins do not log direct `tasks/` writes — those are role-private hygiene and the role plugin's responsibility if it wants audit logging in its lane.

### Monitoring

Per-plugin **`verify.sh`** scripts ship in each ecosystem plugin's repo (path declared in `context.verify` manifest field). Each verify script exercises the plugin's core skills against a minimal fixture and returns 0 on success, non-zero on failure. Used in CI for the plugin's release pipeline and as the implementation for the `verify` field consumed by future switchboard `/switchboard health` calls.

`audit-context` and `audit-plugin` (both in `context-core`) provide on-demand health checks for any installed ecosystem deployment. `audit-context` validates protocol invariants against the current `.context/`. `audit-plugin` validates a specific installed plugin's lane declarations, manifest schema conformance, and cross-plugin internal-skill reference cleanliness.

### Resilience

**Hard dependency missing.** A plugin whose `context.dependsOn` is unsatisfied refuses to load and surfaces an error pointing at the missing dependency and its install command. Both runtimes can express this via standard plugin-load errors.

**Soft dependency missing.** A plugin whose `context.composesWith` entry is missing loads with degraded capability; the absent functionality is explained when the user invokes a skill that would have used it.

**Dispatch failure.** When `context-specialist` cannot complete a requested write (invalid schema, lane violation, internal skill not found), it returns a structured error to the dispatching role plugin. The role plugin surfaces the failure to the user with the specialist's diagnostic; no silent partial writes.

**Topology resolution mismatch.** If `META.md`'s declared scope mismatches the task's resolved scope (Proposal Component 5 step 4), surface the mismatch to the user before any writes. User confirms or corrects scope; specialist proceeds only after explicit confirmation.

**Marketplace as version compatibility surface.** The marketplace's set definitions advertise which versions of which plugins are tested together. Users installing from a set get a known-compatible composition; users installing plugins individually take responsibility for compatibility themselves.



### Security

**Internal-skill cross-plugin block.** Class-4 internal skills (per Proposal Component 4) include a first-line script guard that asserts the caller agent matches the skill's `owned-by` frontmatter. Audit (`audit-plugin`) additionally flags any plugin whose agent definitions reference another plugin's internal skill by name. Defense-in-depth: script guard catches runtime attempts; audit catches author-time references in plugin source.

**Lane enforcement.** Audit verifies every plugin's writes (observed in `tasks/` and in dispatched operations) stay within their declared `context.writes`. Violations are surfaced as audit findings. Runtime enforcement is partial: direct file writes outside the declared lane bypass `context-specialist` and would not be caught at write time, but `audit-context` catches them on demand.

**Sub-project skill trust boundary.** Sub-project skills loaded via `invoke-sub-project-skill` operate within the loading project's `.context/` scope (their own author's responsibility), not against ecosystem-shared surfaces. The framing-as-active-invocation wrapper is the model's signal to execute; the ecosystem does not audit-on-load (per Abandoned Ideas). Trust is scoped to the sub-project; isolation is via topology resolution (`proj-a` skills never load when scope is `proj-b`).

**MCP credential boundary.** `ds-mcp` owns credential setup and storage. Credentials are user-scoped (per Copilot CLI / Claude Code conventions) and never exposed across plugins. Plugins that consume MCP servers do so through the runtime's standard protocol; credentials never appear in any plugin's manifest, hook output, skill content, or audit log.

**No cross-plugin data leakage.** Plugins do not share state files. Each plugin's state (if any) lives under its own namespace in `~/.copilot/` or `~/.claude/`. Project-level `.context/iconrc.json` is read-only to plugins that opt in via `context-core`'s reader skills.

**Data-exfiltration discipline.** ICON v1's per-plugin common-constraints rule (no auto-filing to external systems without explicit user confirmation) is preserved in v2: each plugin authors its own `common-constraints.md` with its own variant of the rule. No shared extraction; per-plugin discipline.

**Plugin signing and trust.** Out of scope for v2. The marketplace currently relies on Git transport trust. Future ecosystem growth may warrant signed manifests; deferred to a separate RFC if/when external non-DataScan publishers want to ship.

---

## Addendum

### Naming

Working names used throughout this RFC are placeholders pending leadership decision:

| Working name | Likely fate |
|---|---|
| `context-core` | May inherit the `ICON` name at launch (v2 ICON = the central plugin) |
| `devcon` | Placeholder; final name TBD |
| `pm` | Placeholder; could be `pmcon`, `product`, etc. |
| `agentic-toolkit` | Placeholder; carries forward from prior decomposition work |
| `qa`, `release-mgmt`, `devops`, `triage`, `support` | Future-wave shelf; placeholders |
| `ds-mcp` | Carries forward from prior decomposition work |
| Marketplace umbrella | "DataScan AI Toolkit" or similar — pending leadership decision |

Naming constraints (from prior internal discussion): avoid `ICON-FOO` prefix pattern; shared prefixes only meaningful as dependency signals; marketplace name is the umbrella, plugins keep their own identities.

### Remaining work items

These items are not blockers for circulating this RFC, but each will need closure before v2 launch.

**Topology resolution algorithm (Requires Further Detail).** The rigorous algorithm is a deliverable of the formal interface spec, not this RFC. ICON v1's existing topology skills are the conceptual ancestor; v1's reliability has been flagged by the maintainer as the biggest technical risk for v2. Algorithm work + fixture-tests across all four topology types are a discrete follow-up implementation effort.

**Per-plugin manager reliability in Claude Code.** Inherited gap from ICON v1. Claude Code routes to agents implicitly via descriptions and does not let users "pick the active agent" the way Copilot CLI does. ICON v1's strategy is `commands/manager.md` slash + `commands/pm.md` slash + an `enable-manager-default` setting; the pattern is reliable only when the user explicitly runs `/manager` at session start. v2 inherits this concern unchanged. Copilot CLI has no equivalent gap because its explicit agent picker handles role switching natively. No clean Claude-Code-only resolution is in scope for v2; the current pattern is carried forward.

**Future-wave plugin designs.** `qa`, `release-mgmt`, `devops`, `triage`, `support` — lane prefixes are reserved; their designs are explicitly out of scope for v2 launch. Each becomes its own RFC when a team commits to building it.

**`switchboard` plugin design.** Deferred until the ecosystem grows past ~5 installed plugins per typical user and discovery/routing/health becomes a real user problem. If built, its own RFC.

### External references

The following public documentation was consulted to ground this RFC's design against the actual plugin models of both target runtimes:

- [Claude Code Plugins reference](https://code.claude.com/docs/en/plugins-reference)
- [Claude Code Plugin Manifest schema (JSON Schemastore)](https://www.schemastore.org/claude-code-plugin-manifest.json)
- [GitHub Copilot CLI plugin reference](https://docs.github.com/en/copilot/reference/cli-plugin-reference)
- [GitHub Copilot CLI custom agents reference](https://docs.github.com/en/copilot/reference/custom-agents-configuration)
- [Adding agent skills for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills)
- [How to write one skill for both Claude Code and Copilot CLI](https://www.allaboutken.com/posts/20260408-mini-guide-claude-copilot-skills/)

### What this RFC does NOT propose

- A specific release date for v2 launch.
- A specific brand for the marketplace umbrella.
- Final names for any plugin in the ecosystem.
- The full skill set for `devcon`, `pm`, or `agentic-toolkit` (the lists in Proposal Component 3 are starting points, not commitments).
- Designs for any future-wave plugin (`qa`, `release-mgmt`, `devops`, `triage`, `support`).
- Concrete schemas for the formal interface spec — only the structure of the spec is in scope here.
- The exact topology-detection-and-resolution algorithm (Requires Further Detail in Implementation: API).
- Resolution of the per-plugin manager reliability gap in Claude Code (Remaining Work).
