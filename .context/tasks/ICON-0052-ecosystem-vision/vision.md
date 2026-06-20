# ICON v2 Ecosystem Vision Sketch

**Status:** Sketch — for iteration. Not RFC-ready yet.  
**Date:** 2026-06-03  
**Task:** ICON-0052  
**Working names:** `context-core`, `devcon`, `pm`, `agentic-toolkit` (all placeholders; final brand decision deferred)  
**Predecessor:** ICON-0051 (decomposition RFC, superseded in framing — see §13)  
**Primary runtime:** GitHub Copilot CLI. **Secondary:** Anthropic Claude Code. Where the two diverge, Copilot CLI patterns win.

---

## TL;DR

ICON v1 is a swiss-army-knife plugin: dev orchestration, product management, `.context/` system, MCP integration, and meta-tooling bundled together. A role using only 10% of the skills carries 100% of the context weight. **ICON v2 is an ecosystem, not a plugin.**

The proposal:

- **A `.context/`-centric base plugin** (working name `context-core`) owns the protocol, the structural writes, the reader surface, the maintenance/audit discipline, and the repository-topology resolution. It publishes a **formal versioned interface** that role plugins program against.
- **Role-specific SDLC plugins** sit beside it as siblings, each carrying only the skills/agents for its role. **First wave:** `devcon` (dev orchestration), `pm` (product management), `agentic-toolkit` (plugin authoring). **Future shelf:** `qa`, `release-mgmt`, `devops`, `triage`, `support` — added when concrete demand surfaces.
- **Composition model = B+ v2 (federated protocol + scoped specialist gatekeeper + rich internal skill library).** Each role plugin ships its own **manager** that prefers in-plugin skills on overlap; managers may freely call other plugins' *user-invocable* skills, but never their *internal* skills. Role plugins write directly only to their declared `tasks/` lane. Every other `.context/` write is dispatched to `context-specialist` (a lean skill-router sub-agent in `context-core`), which selects the right *internal* skill — many of them script-backed — to perform the write and its automatic post-write discipline (split, dead-ref rewrite, schema validation, retro cap-rotation).
- **Scripting is preferred over agent-authored work for standardized, repeatable operations** — retro append, version bump, oversize-split, dead-ref rewrite, audit checks, schema validation, changelog append. Internal skills are mostly scripted shells around shell logic; user-invocable skills are mostly prompted intent-driven work.
- **Repository topology is a first-class problem.** Single-project, hierarchical-monorepo (with aggregator `.context/`), multi-module (scattered leaves), and VS Code workspace (arbitrary folder collections) all need correct, reliable resolution. ICON v1 attempted this; v2 makes it work.
- **ICON v1 becomes the prototype**; v2 supersedes it once parity is reached. `.context/` schema is forward-compatible — existing ICON repos migrate by installing v2 plugins, no `.context/` rewrite needed.

This sketch is a discussion artifact, not a commitment. Architecture and principles are settled enough to draft against; plugin lineups, naming, and several open questions remain for iteration before this graduates into an ORG-004 RFC.

---

## 1. Why ICON v2

ICON v1 succeeded as a single-team productivity plugin. As the team considered extending its reach to QA, release management, devops, and other SDLC roles, three pressures became unignorable:

**The bloat problem.** ICON's manager agent is at 97.1% of its always-loaded token budget (per ADR-008). 49 consumer skills and 9 agents are loaded whether the user is doing dev work, PM work, or anything else. A QA engineer using `.context/` discipline pays for a `product-manager` agent they'll never invoke; a PM pays for `systematic-debugging`. Adding QA / release / devops capabilities to ICON the way Dev and PM were added would make this worse, not better. Copilot CLI's 30,000-character cap on agent markdown content makes this concrete: bloated agents do not fit.

**The shared substrate.** The `.context/` system itself — the schema, the navigation discipline, the file-size rules, the audit pattern, the retrospective protocol, the topology resolution — is the genuinely universal pillar. Every SDLC role benefits from the same project context. None of the other ICON concerns (manager-routing, RFC authoring, MR discipline, jira-story formatting) are universal. The asymmetry between *one universal capability* and *many role-specific capabilities* is precisely the asymmetry a plugin ecosystem is for.

**The composition challenge.** Once you have role-specific plugins, they have to compose cleanly. They have to share an understanding of `.context/` without each one having to re-state the rules, and they have to agree on who writes what without producing a coordination mess. They also have to handle Copilot CLI's first-found-wins skill-name resolution without silent overrides between plugins. This is the load-bearing technical question, addressed by the architecture in §3.

**Why Copilot CLI is primary.** The DataScan target audience is already on Copilot CLI day-to-day. Claude Code remains a supported runtime, but where syntax, conventions, or capabilities diverge, the ecosystem optimizes for Copilot CLI ergonomics and lets adapters cover Claude Code where needed. Tool-agnostic content (per ADR-004) is still the goal; primary-runtime framing affects only where two valid choices exist.

---

## 2. Principles

These are the load-bearing beliefs the ecosystem is built on. If any of these stop being true, the design should be revisited.

1. **`.context/` is the universal substrate.** Every plugin in the ecosystem reads from the same `.context/` schema. The schema is owned by `context-core` and is the only thing every ecosystem plugin must understand.

2. **Each plugin's scope is "only what that role uses."** No inheritance bloat. A QA engineer's installation does not load dev agents. A PM's installation does not load test-runner skills. The cost of any role is the cost of *that role*.

3. **Composition over inheritance.** Plugins are siblings, not children. Role plugins depend on `context-core` (and nothing else, by default); they do not depend on each other. Cross-plugin cooperation happens through declared metadata and intentional dispatch, not through implicit coupling.

4. **Rich skill library; lean agents.** `context-core` ships many skills (one per write operation, one per protocol rule, one per maintenance pass). Agents stay small and route to skills on demand. This matches Copilot CLI's 30,000-char agent cap and avoids the "load everything always" cost.

5. **Internal vs user-invocable is a first-class metadata distinction.** Every skill declares `user-invocable: true|false` in frontmatter. User-invocable skills are the externally-facing surface — managers may call across plugins freely. Internal skills are owned by specific agents per explicit instructions — cross-plugin internal-skill calls are forbidden by audit, even if a runtime would permit them syntactically.

6. **Scripts beat prompts for standardized, repeatable tasks.** Retro append, version bump, oversize-split, dead-ref rewrite, schema validation, audit checks, changelog append — all run as scripts. Internal skills are mostly script-backed wrappers; user-invocable skills are mostly prompted intent-driven work. Determinism where it's available; reasoning where it's needed.

7. **The protocol is a formal, versioned interface.** Role plugins program against `context-core`'s published spec, not against its internals. Spec changes are versioned; spec breakages are deliberate releases.

8. **Writes are gatekept structurally except in the declared task lane.** Role plugins own a single declared lane (`tasks/{role}-*/`) where they write freely. Every other `.context/` change goes through `context-specialist`, which is the sole structural writer. This keeps invariants safe by construction without requiring honor-system discipline.

9. **Discipline is built into the writer, not bolted on.** Oversize check + dead-ref rewrite, retro cap-rotation, schema validation, cross-ref check — these are not callable skills. They are automatic post-write behavior in `context-specialist`'s dispatch pipeline. Plugin authors don't remember to call them; they happen.

10. **Each plugin has its own manager.** `devcon-manager`, `pm-manager`, etc. Managers prefer in-plugin skills on conceptual overlap and dispatch cross-plugin only when intent is clearly outside their lane. Copilot CLI lets the user pick which manager is active; Claude Code routes via agent description.

11. **Repository topology resolution is correctness, not convenience.** The system must reliably pick the right `.context/` folder for the task's scope across single-project, hierarchical monorepo, multi-module, and VS Code workspace topologies. Getting this wrong is a correctness failure, not a UX inconvenience.

12. **ICON v1 is the prototype.** v2 is the productized version. Concepts may transfer; code does not. ICON v1 continues to ship for existing users until v2 reaches parity; then v1 enters maintenance mode.

---

## 3. Architecture: B+ v2 — federated protocol + lean specialist router + rich internal skill library

### Picture

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
              │  │  Internal skills (specialist-only) │  │  ← rich library; mostly
              │  │  write-adr, update-domain,         │  │     script-backed.
              │  │  append-retro, bump-iconrc,        │  │     Each enforces its
              │  │  oversize-split-then-deadref,      │  │     own discipline.
              │  │  validate-schema, ...              │  │
              │  └────────────────────────────────────┘  │
              │                                          │
              │  ┌────────────────────────────────────┐  │
              │  │  User-invocable skills (any caller)│  │  ← reader, audit, init,
              │  │  read-iconrc, find-current-task,   │  │     upgrade. Free to call
              │  │  resolve-topology, audit-context,  │  │     across plugins.
              │  │  init-context, upgrade-context, …  │  │
              │  └────────────────────────────────────┘  │
              └──────────┬───────────────────────────────┘
                         │ dependsOn: context-core
       ┌─────────────────┼──────────────────┬──────────────────────┐
       │                 │                  │                      │
  ┌────▼─────┐     ┌─────▼──────┐    ┌──────▼──────────┐    ┌──────▼─────────┐
  │  devcon  │     │     pm     │    │ agentic-toolkit │    │ (future shelf) │
  │          │     │            │    │                 │    │  qa, release-  │
  │ writes:  │     │ writes:    │    │ writes: tasks/  │    │  mgmt, devops, │
  │ tasks/   │     │ tasks/     │    │ author-*/       │    │  triage, ...   │
  │ dev-*    │     │ pm-*       │    │ author-tooling  │    │                │
  │          │     │            │    │ skills, scaffolds│    │                │
  │ own mgr  │     │ own mgr    │    │ own mgr         │    │                │
  └──────────┘     └────────────┘    └─────────────────┘    └────────────────┘

  Each role plugin ships its own manager (lean), reads .context/ via context-core's
  user-invocable skills, writes directly only inside its declared task lane, and
  dispatches every other .context/ write to context-specialist.

  Standalone ecosystem peers (not depicted): ds-mcp (MCP foundation, optional consumer).
```

### Write semantics by path

| `.context/` path | Direct write by role plugin? | Mechanism | Automatic post-write discipline |
|---|---|---|---|
| `tasks/{role}-*/**` | yes (only the declared role) | direct file write | (none — task hygiene is the role's responsibility) |
| `retrospectives/{plugin}.md` | no | dispatch → `context-specialist` → `append-retro` internal skill | cap-rotation (drop oldest beyond cap N), script-backed |
| `retrospectives/shared.md` | no | dispatch → `context-specialist` → `append-retro` internal skill | cap-rotation; for cross-plugin/ecosystem lessons |
| `decisions/**` (ADRs) | no | dispatch → `context-specialist` → `write-adr` internal skill | schema, cross-ref check, oversize-split + dead-ref rewrite |
| `domains/**` | no | dispatch → `context-specialist` → `update-domain` internal skill | oversize-split + dead-ref rewrite, cross-ref check |
| `standards/**`, `workflows/**` | no | dispatch → `context-specialist` → `update-narrative` internal skill | oversize-split + dead-ref rewrite |
| `overview.md` | no | dispatch → `context-specialist` → `update-overview` internal skill | oversize-split + dead-ref rewrite |
| `iconrc.json` | no | dispatch → `context-specialist` → `bump-iconrc` internal skill | schema check, version SSOT enforcement, script-backed |
| `META.md` | no | dispatch → `context-specialist` → `update-meta` internal skill | schema check (this IS the schema) |
| `cache/**` | yes (any plugin) | direct file write | (treated as `.context/`'s `/tmp` — no protocol discipline; no per-plugin partitioning) |

### Lane declaration in manifest

Each role plugin declares its owned and contributed paths in its `plugin.json` under a custom `context:` namespace. Both Copilot CLI and Claude Code ignore unknown top-level keys, so this works in both runtimes.

```jsonc
// In <plugin>/.claude-plugin/plugin.json (or root plugin.json for Copilot CLI;
// the .claude-plugin/ path also works in Copilot CLI per dual-authoring guidance)
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
    "dependsOn": [
      { "plugin": "context-core", "versionRange": ">=1.0.0" }
    ],
    "composesWith": [
      { "plugin": "ds-mcp", "optional": true }
    ],
    "writes": ["tasks/dev-*/**"],
    "reads": ["**"],
    "dispatches": ["context-specialist"],
    "purpose": "Dev orchestration: features, bug fixes, code review, debugging",
    "verify": "scripts/verify.sh"
  },

  "mcpServers": "./.mcp.json"
}
```

`context.writes` = exclusive ownership; `context.reads` = where the plugin reads from (defaults to everything); `context.dispatches` = sub-agents the plugin's manager will invoke. Audit verifies declared lanes are honored.

### Skill invocability — four classes

Skills declare two orthogonal invocability axes in SKILL.md frontmatter:

- `user-invocable: true|false` — does typing `/skill-name` invoke it?
- `disable-model-invocation: true|false` — can agents auto-pick it via description match?

This gives four distinct classes:

| Class | `user-invocable` | `disable-model-invocation` | Description style | Examples |
|---|---|---|---|---|
| 1. Standard | true | false | Rich (drives auto-invocation) | Most user-facing skills: `read-iconrc`, `audit-context`, `rfc` |
| 2. Agent-auto only | false | false | Rich (drives auto-invocation) | Background utilities agents auto-pick but users don't type: `resolve-topology`-style helpers |
| 3. User-only | true | true | Rich (users read it) | Skills users invoke deliberately that shouldn't auto-fire on adjacent intent: `/icon:release-plugin`, role-switching commands |
| 4. **Internal** | false | true | Minimal boilerplate: `"Internal skill. Do not invoke without explicit direction."` | Skills invoked only by their owning agent's explicit instructions: `write-adr`, `append-retro`, `bump-iconrc`, `oversize-split-then-deadref` |

**Internal skills (class 4) are the key to keeping the rich skill library affordable.** Their descriptions are deliberately minimal — under ~12 words, same boilerplate string per skill — because descriptions are always loaded into context. A rich library with minimal internal-skill descriptions costs nearly nothing at session start; the bulk content loads only when the owning agent explicitly names a specific internal skill.

Example internal skill frontmatter:

```yaml
---
name: write-adr
description: Internal @context-specialist skill. Do not invoke without explicit direction.
user-invocable: false
disable-model-invocation: true
owned-by: context-specialist
---
```

**Cross-plugin invocation rules:**

- Any plugin's agent may auto-invoke any other plugin's class 1 or 2 skills freely (the runtime's description-match routing handles it).
- Class 3 (user-only) skills are skipped by agent auto-routing in both runtimes — by design.
- Class 4 (internal) skills are invoked only by the agent named in their `owned-by` frontmatter, only when explicitly instructed by that agent's prompt. Cross-plugin agents do not call other plugins' internal skills, even with explicit reference — this is the structural boundary the ecosystem relies on.

Audit (`audit-plugin`) flags any plugin whose agent definitions explicitly reference another plugin's internal skill. Runtime enforcement is best-effort: internal skills can include a first-line guard in their script that asserts the caller agent matches `owned-by`, but the primary discipline is audit + author convention.

This taxonomy aligns with Copilot CLI's existing agent-frontmatter conventions (`user-invocable`, `disable-model-invocation`). Claude Code's runtime ignores both on skills (every skill gets a slash command and is auto-discoverable by description), but the ecosystem managers and audit honor them — runtime permissiveness is not a discipline backdoor.

### Dispatch protocol (role plugin → context-specialist)

When a role plugin needs a non-task `.context/` change, its manager (or a role-specific agent it dispatches) invokes `context-specialist` as a sub-agent via the runtime's agent-dispatch tool (Copilot CLI: `agent` / `custom-agent` / `Task`; Claude Code: `Agent`). The request payload is a structured intent:

```json
{
  "operation": "write-adr",
  "target": ".context/decisions/012-context-resolution-algorithm.md",
  "intent": "Decision to use depth-first leaf-priority resolution with explicit scope tags in task plans. Refs ICON-0061.",
  "source-plugin": "devcon",
  "source-task": "DEV-0044",
  "input": {
    "title": "Context resolution algorithm",
    "context": "...",
    "decision": "...",
    "consequences": "..."
  }
}
```

`context-specialist` reads the request, picks the matching internal skill from its catalog (`write-adr` for `operation: write-adr`), invokes the skill (often a thin shell over a script), runs the post-write discipline pipeline (oversize-split, dead-ref rewrite, schema validation), and returns success/failure with a summary.

**Why this is B+ v2 and not strict A**: the gatekeeper is a *thinking router* (a lean agent with discipline-aware skill selection), and the discipline lives in the *skills* (one per operation, script-backed where possible). The protocol stays federated — any plugin author can adopt it. The writes go through a small, well-defined choke point with rich, scoped tooling.

### Scripting backbone

Internal skills that perform standardized, repeatable operations are script-backed. Each internal-skill folder contains:

```
skills/append-retro-entry/
├── SKILL.md          # frontmatter + minimal prompt: "run ./append.sh with given args"
└── append.sh         # the deterministic logic — read retro file, append entry,
                      # enforce cap-rotation, write back
```

Other operations that should be script-backed by default:
- `oversize-split-then-deadref` — Python or shell script that splits an oversized markdown file at section boundaries, rewrites incoming references, validates the result
- `bump-iconrc` — JSON-edit script, version SSOT enforcement
- `validate-schema` — JSON Schema check against per-file-type schemas
- `audit-context` — iterates all `.context/` files, runs per-file-type checks, reports violations
- Plugin-level operations: `release-plugin` (per-plugin version bump + CHANGELOG + tag), `verify` (per-plugin smoke test)

Scripts live alongside the skill that wraps them, in the plugin's repo. Scripts are runtime-agnostic (POSIX shell, Python — whatever the operation calls for). Both Copilot CLI and Claude Code can invoke them via the shell/bash tool.

---

## 4. Repository topology and `.context/` resolution

This is the load-bearing correctness problem. ICON v1 attempts it (skills `context-specialist-detect-tree-position`, `context-specialist-impl-{branch,leaf,root}`, `initialize-monorepo`, `initialize-multimodule`) but reliably solving it is named explicitly by the maintainer as one of v1's main weaknesses. v2 makes it a first-class design concern.

### Four topology types

Each shapes the tree of `.context/` folders differently:

#### Type 1 — Single project

One project root, one `.context/` at that root. The simplest case.

```
my-project/
├── .context/         ← rich
├── src/
└── ...
```

#### Type 2 — Hierarchical monorepo (with aggregator levels)

Tree of `.context/` folders. Leaves are rich; intermediate aggregator levels are thin and carry **child pointers**; the repo root carries minimal repo-level information.

```
my-monorepo/
├── .context/                    ← thin: repo overview, top-level pointers
│   ├── overview.md              ← repo-level only
│   └── children.md              ← pointers to: webapp/, services/
├── webapp/
│   ├── .context/                ← rich (leaf)
│   └── src/
└── services/
    ├── .context/                ← thin: services group overview, pointers
    │   ├── overview.md          ← group description
    │   └── children.md          ← pointers to each service
    ├── auth/
    │   ├── .context/            ← rich (leaf)
    │   └── src/
    ├── billing/
    │   ├── .context/            ← rich (leaf)
    │   └── src/
    └── ...
```

Each level has a `.context/` proportional to its scope. Parent levels point to immediate children only — chain navigation, not deep references.

#### Type 3 — Multi-module (scattered projects, no intermediate groupings)

Projects live at varying depths but without a hierarchical grouping concept. Only the repo root and the leaf projects get `.context/` folders.

```
my-multi-module/
├── .context/         ← thin: repo overview, leaf pointers
├── tools/
│   ├── linter/
│   │   ├── .context/  ← rich (leaf)
│   │   └── src/
│   └── formatter/
│       ├── .context/  ← rich (leaf)
│       └── src/
└── apps/
    └── mobile/
        ├── .context/  ← rich (leaf)
        └── src/
```

Root → leaf navigation only. No aggregator levels between them.

#### Type 4 — VS Code workspace (dedicated workspace folder)

DataScan convention (project requirement, not optional): every VS Code workspace has its own dedicated folder. That folder:

- contains the `.code-workspace` file
- is its own git repository
- hosts the workspace-level `.context/`, `.claude/`, `.copilot/`, and other CLI tooling state

The workspace folder is the workspace's "root" — analogous to a repo root, but the projects it references live elsewhere in their own git repos. Each referenced folder remains its own project with its own `.context/`.

```
~/dev/workspaces/FullWiStack/                 ← workspace folder (its own git repo)
├── FullWiStack.code-workspace                ← workspace file
├── .context/         ← workspace-level context (workspace overview, references to
│                       each project, workspace-specific standards/workflows)
├── .claude/
└── .copilot/

~/dev/proj-a/                                 ← referenced folder (own git repo)
└── .context/         ← rich (leaf, scope:leaf or its own root/aggregator subtree)

~/dev/proj-b/                                 ← referenced folder (own git repo)
└── .context/         ← rich

~/elsewhere/proj-c/                           ← referenced folder (own git repo)
└── .context/         ← rich
```

The workspace `.context/` plays an aggregator-like role *across git-repo boundaries*. It describes:

- What the workspace is for (the set of projects collected together)
- References to each project: its git repo URL, its on-disk path, the path to its `.context/`
- Cross-workspace standards or workflows that apply to all referenced projects (e.g., shared style rules, cross-cutting deployment runbooks)
- Workspace-scope tasks (under `tasks/workspace-*/`) for work that genuinely spans multiple referenced projects

Topology resolution treats the workspace `.context/` as a special scope (`workspace`), distinct from leaf/aggregator/root. A task that affects only one referenced project resolves to that project's leaf `.context/`; a task that genuinely spans multiple referenced projects resolves to the workspace `.context/`.

Cross-repo references in the workspace `.context/` use the same child-pointer mechanism as hierarchical monorepo aggregators (see open question #18) — with the extra fields needed to identify the referenced git repo (not just a relative path).

### Truth source for topology — `iconrc.json`

ICON v1 already encodes the topology type in `iconrc.json`:

```jsonc
{
  "version": "1.2",
  "repo_type": "project",   // ← truth source: project | monorepo | multimodule | workspace
  "local_task_id_prefix": "ICON",
  "default_branch": "main",
  "cache_expires_after_days": 30,
  "excludes": ["architecture", "testing", "styling"]
}
```

The `repo_type` field is established during `icon-init` (now in `context-core` as `init-context`). v2 inherits this as the authoritative topology declaration — no heuristic detection at session start, no scanning for `.context/` folders to guess the layout. The init flow writes `repo_type` once; resolution reads it. Each per-scope `.context/`'s `META.md` declares its scope (`leaf | aggregator | root | workspace`) for sub-tree navigation within the chosen topology.

The `excludes` array trims default `context_template/` folders not relevant to the topology — e.g., an aggregator-scope `.context/` likely excludes `domains`, `standards`, `workflows` (those belong at the leaf level). Trimming is suggested to the user during init/upgrade, not automatic — per user direction in round 3.

### Resolution algorithm (high-level)

For any task, the system must pick the `.context/` matching the task's scope:

1. **Read `iconrc.json#/repo_type`** at the working directory's nearest enclosing `.context/`. This is the authoritative topology type.
2. **Determine task scope** from the task description, the working-directory path, and the topology type:
   - Touches one project only → leaf `.context/`
   - Touches multiple projects under one aggregator → aggregator `.context/` (hierarchical monorepo only)
   - Touches multiple aggregators or repo-wide → root `.context/`
   - Touches multiple referenced projects in a workspace → workspace folder's `.context/`
3. **Resolve to the matching `.context/`** by walking down from root through child pointers OR up from the working directory, depending on the task's stated path and topology type.
4. **Verify resolution by reading the chosen `.context/`'s `META.md` scope declaration**. If the declared scope mismatches the task's scope, surface the mismatch to the user before proceeding.

### What the protocol spec must publish

The formal interface spec (§5) makes this rigorous. At minimum:

- **Topology detection rules**: how to classify a directory tree into one of the four types.
- **`.context/` scope declarations**: every `.context/` declares its scope in `META.md` (`leaf | aggregator | root | workspace`) — explicit, machine-readable.
- **Child-pointer format**: how aggregator and root `.context/` folders point to children. Likely a `children.md` file with structured links, or a `children` field in `iconrc.json`.
- **Per-scope content rules**: leaf `.context/` contents (the full v1 ICON layout), aggregator `.context/` (overview + children + decisions affecting the group), root `.context/` (repo overview + top-level pointers + repo-level decisions).
- **VS Code workspace handling**: how the workspace's `.code-workspace` file is parsed; whether the workspace gets its own `.context/`; how it composes with each referenced folder's `.context/`.
- **Multi-module navigation**: no intermediate aggregator level; direct root → leaf pointers in root's `children.md`.

### Why this is correctness, not convenience

Picking the wrong `.context/` is not "slightly off." It means a role plugin reads the wrong overview, writes a task plan to the wrong folder, audits the wrong domain — invariants designed to keep the system honest get applied to the wrong substrate. Then every downstream operation runs on bad assumptions.

v1's existing skills are the right idea structurally. v2 invests in:
- Making detection deterministic (driven by `META.md` scope declarations + protocol-published rules, not heuristic guessing).
- Making scope-mismatch a hard user-facing error, not a silent fallthrough.
- Script-backing the entire detection + resolution pipeline so behavior is reproducible.
- Test fixtures covering all four topology types as part of `context-core`'s release gate.

---

## 5. `context-core` — scope, skill catalog, formal interface

### Components

| Component | Type | Purpose |
|---|---|---|
| Formal Interface Spec | versioned doc (`spec/INTERFACE-v1.md` or similar) | The published contract. Role plugins program against this. |
| `context-specialist` | agent (lean; skill router) | Sole structural writer dispatch target. Picks the right internal skill per operation. |
| Internal skills (rich library) | skills, `user-invocable: false` | One per operation type. Script-backed where deterministic. |
| User-invocable skills | skills, `user-invocable: true` | Reader surface, audit, init, upgrade, topology resolution. Free for cross-plugin calls. |
| Protocol meta-rules | `context_template/META.md` shipped with the plugin | Authoritative description of how `.context/` is governed; copied to each project's `.context/META.md` at init. |
| Scripts | `scripts/` per skill (or shared) | Deterministic shell/Python logic backing internal skills. |

### Skill catalog (v2 launch sketch)

**Internal skills (specialist-only):**

| Skill | Operation | Discipline applied |
|---|---|---|
| `write-adr` | Create/update ADR | Schema, cross-ref, oversize-split, dead-ref rewrite |
| `update-domain` | Edit a domain doc | Oversize-split + dead-ref rewrite, cross-ref |
| `update-overview` | Edit `overview.md` | Oversize-split + dead-ref rewrite |
| `update-narrative` | Edit standards/workflows | Oversize-split + dead-ref rewrite |
| `append-retro` | Append retro entry to `retrospectives/{plugin}.md` or `shared.md` | Cap-rotation (script-backed) |
| `bump-iconrc` | Version bump in `iconrc.json` | Schema, SSOT enforcement (script-backed) |
| `update-meta` | Edit `META.md` | Schema check |
| `oversize-split-then-deadref` | (Pipeline step, callable internally) Split + dead-ref rewrite | Script-backed |
| `validate-schema` | (Pipeline step) Run schema check | Script-backed |
| `establish-children-pointer` | Update aggregator/root `children.md` | Topology-aware |
| `set-context-scope` | Write a `.context/`'s scope declaration in `META.md` | Schema check |

**User-invocable skills (any caller):**

| Skill | Purpose |
|---|---|
| `read-iconrc` | Read parsed `iconrc.json` |
| `find-current-task` | Locate the active task folder under the resolved `.context/` |
| `summarize-decisions` | List ADRs with summaries |
| `read-domain` | Fetch a named domain doc |
| `read-overview` | Fetch the chosen `.context/`'s overview |
| `list-recent-retros` | Read retro entries (specific plugin or shared) |
| `list-context-tree` | Walk the topology tree from root, listing each `.context/` and its scope |
| `resolve-topology` | Detect topology type + return scope-to-`.context/` mapping |
| `resolve-context-for-task` | Given a task scope, return the matching `.context/` path |
| `init-context` | Scaffold the `.context/` skeleton for a fresh repo: detect topology with user input, write `iconrc.json`, lay out `context_template/` folders honoring `excludes`, write `META.md` with `scope:` declaration. Does NOT populate role-specific content — that's a role-plugin responsibility (`devcon` triggers `init-context` if the repo is uninitialized, then runs its own population skill). |
| `upgrade-context` | Migrate an older-protocol `.context/` to current version |
| `audit-context` | Run all protocol invariants against the chosen `.context/` and any lane violations across installed plugins; report findings |
| `audit-plugin` | Audit a specific installed ecosystem plugin against the protocol (alignment + conformance) |
| `invoke-sub-project-skill` | (class 2: agent-auto-invocable, not user-invocable) Load a sub-project skill from an absolute path and frame it as an active invocation. Carried forward from ICON v1; the runtime composition primitive that makes workspace and monorepo dynamic skill loading possible. Lives in context-core as a shared primitive (rather than per-plugin copies) so any role plugin's manager can use it for the same scope-gated loading pattern. |
| `using-skills` | (class 2: agent-auto-invocable, not user-invocable) Forces catalog consultation before any task action. Carried forward from ICON v1 as a shared primitive in core. Trimmed for the ecosystem: keeps the discipline (the rule, rationalization-prevention table, red flags, instruction-priority hierarchy) but drops the dev-specific Skill Priority ordering and Skill Type examples. Each role plugin's manager doc declares its own priority over its own catalog. |

### Dynamic sub-project skill loading

Workspace and hierarchical-monorepo topologies introduce a runtime concern that single-project plugins don't have: **sub-projects may ship their own skills that the ecosystem plugins don't know about at install time**. A workspace referencing 5 projects can have each project ship its own `.copilot/skills/`; a monorepo with 5 services can do the same.

Project-level skills are **scope-gated by design** — they are *not* surfaced into the ecosystem plugin's catalog at session start. A workspace user working in `proj-a` should not see `proj-b`'s skills as routing candidates; that's the isolation property the design intentionally buys. Discovery happens *after* `resolve-topology` (or the v2-equivalent) has determined the active scope.

The runtime pattern, carried forward unchanged from ICON v1:

1. Manager calls `resolve-topology` (or a successor v2 resolution skill) which returns the active `.context/` plus `available_skills` — a list of absolute paths to sub-project skills at that scope.
2. Manager picks a skill matching the user's intent.
3. Manager invokes `invoke-sub-project-skill` with the chosen path.
4. `invoke-sub-project-skill` reads the file and wraps it in explicit "execute these instructions" framing language. The framing is the load-bearing trick: without it, the model treats the file as reference material; with it, the content runs as active instructions.

Why this lives in context-core and not in each role plugin: the load + frame primitive is purely mechanical (no role-specific reasoning), and v2 has multiple per-plugin managers. Centralizing it as a class-2 skill in context-core means every role plugin's manager gets the same primitive without per-plugin duplication. Sub-project skills are still subject to their own author's discipline; the ecosystem trusts them within their scope, exactly as project-level code is trusted within its scope.

### What the Formal Interface Spec contains

The spec is the substrate that makes the ecosystem programmable by anyone. v1.0 contents:

1. **`.context/` directory structure.** Required and optional paths per scope (leaf, aggregator, root, workspace).
2. **Per-file schemas.** What goes in `overview.md`, ADRs, domain docs, workflows, standards, retros (per-plugin and shared), `iconrc.json`, `META.md`, task plans. JSON Schema for structured files; markdown templates with required sections for narrative files.
3. **Topology detection and resolution rules.** Detection inputs, classification algorithm, scope declarations, child-pointer format, scope-to-`.context/` resolution algorithm. (Per §4.)
4. **Lane declaration syntax.** JSON Schema for the `context.writes`, `context.reads`, `context.dispatches`, `context.dependsOn`, `context.composesWith` manifest fields.
5. **Dispatch protocol.** Request shape, response shape, error codes for role-plugin → `context-specialist` invocation. Independent of runtime (Copilot CLI's `agent` tool vs Claude Code's `Agent` tool both speak it).
6. **Skill invocability metadata.** The `user-invocable` / `internal` / `owned-by` frontmatter fields, including audit enforcement rules.
7. **Reader skill catalog.** Canonical names, inputs, outputs, semantics. Role plugins call these by name; the spec is authoritative.
8. **Discipline matrix.** Which file types get which automatic post-write check (oversize-split+deadref, retro cap, schema, cross-ref).
9. **Scripting conventions.** How scripts live in skill folders, how they receive arguments, expected output format, error handling.
10. **Versioning policy.** Semver for the spec; what's a breaking change vs additive.
11. **Conformance audit checklist.** What `audit-context` and `audit-plugin` validate. A plugin that passes audit is conformant.

The spec lives at `spec/INTERFACE-v1.md` in `context-core`'s repo and is the canonical source. Every change to the spec is a versioned `context-core` release.

---

## 6. First-wave plugins

These ship at v2 launch. They are the immediate-need plugins: existing ICON users migrate to these.

### `devcon` — dev orchestration

| | |
|---|---|
| Role | Dev work: features, bug fixes, refactors, code review, debugging |
| Owned lane | `tasks/dev-*/**` |
| Own manager | `devcon-manager` (lean; routes intent to in-plugin skills first, cross-plugin user-invocable skills second) |
| Agents | `devcon-manager`, `planner`, `architect`, `coder`, `tester`, `reviewer`, `researcher` |
| Skills (transferred from ICON) | `task-plan`, `code-quality-rules`, `mr-discipline`, `mr-feedback-triage`, `systematic-debugging`, `testing-discipline`, `verification-checklist`, `commit-discipline`, `dependency-management`, `migration-planning`, `post-incident-review` (note: `using-skills` is NOT here — it lives in `context-core` as a shared class-2 primitive; devcon's manager doc declares dev-specific skill priority over devcon's catalog) |
| Per-plugin meta-skills | `release-plugin` (scaffolded from agentic-toolkit) for releasing devcon itself |
| Reads | `.context/` via `context-core` reader skills |
| Writes directly | only `tasks/dev-*/**` |
| Dispatches | `context-specialist` for ADRs, domain updates, retro appends at task close |
| NOT included | PM workflows, RFC authoring, sprint goals — those live in `pm` |

### `pm` — product management

| | |
|---|---|
| Role | Product management: stories, RFCs, sprint planning, meeting summaries |
| Owned lane | `tasks/pm-*/**` |
| Own manager | `pm-manager` |
| Agents | `pm-manager`, `product-manager` |
| Skills | `rfc`, `jira-story`, `sprint-goals`, `post-meeting` |
| Per-plugin meta-skills | `release-plugin` for releasing pm itself |
| Reads | `.context/` via `context-core` reader skills |
| Writes directly | only `tasks/pm-*/**` |
| Dispatches | `context-specialist` for ADRs (when an RFC graduates to a decision), retro appends at task close |
| Lightweight footprint | Most engineering users do NOT install this — keeps token weight off everyone but PMs |

### `agentic-toolkit` — plugin authoring (first-wave per user endorsement)

| | |
|---|---|
| Role | Plugin authoring: scaffolding new ecosystem plugins, generating templated audit/release/conformance skills |
| Owned lane | `tasks/author-*/**` (for plugin-authoring tasks) |
| Own manager | `agentic-toolkit-manager` |
| Skills | `scaffold-plugin` (creates baseline structure for a new ecosystem plugin), `generate-audit-skill` (templates a plugin-specific audit skill), `generate-release-skill` (templates a `release-plugin` skill for inclusion in a plugin's own repo), `generate-conformance-test` (templates a verify.sh), `writing-skills` (from ICON v1), `plugin-design` (from ICON v1), `agent-evaluation` (from ICON v1) — note: `using-skills` lives in `context-core`, not here |
| Reads | `.context/` via `context-core` reader skills |
| Writes directly | only `tasks/author-*/**` |
| Dispatches | `context-specialist` rarely (most outputs are *to other repos*, not to the current `.context/`) |
| Audience | Anyone authoring an ecosystem plugin — DataScan internal teams, future external contributors |

### Why these three first

`devcon` and `pm` are the two role-shapes ICON v1 actually has working today — most validated, highest demand. `agentic-toolkit` is the meta-tooling plugin that makes adding the rest of the SDLC shelf tractable: rather than each new role-plugin author starting from scratch, they scaffold from agentic-toolkit and inherit conformance-ready patterns from day one.

---

## 7. Future-wave shelf

These plugins are not designed yet. They are listed to demonstrate the ecosystem can grow without restructuring, and to claim the lane prefixes early so role-plugin authors know what's reserved.

| Plugin | Role | Lane prefix | Plausible scope |
|---|---|---|---|
| `qa` | Test orchestration, defect triage | `tasks/qa-*/` | test-plan authoring, defect-reproduction discipline, QA retro patterns, exploratory test patterns |
| `release-mgmt` | Release engineering as a role (NOT per-plugin release) | `tasks/release-*/` | cross-plugin release coordination, ecosystem-wide changelog discipline, release retros, deployment runbooks |
| `devops` | Infrastructure operations | `tasks/devops-*/` | env management, infra-as-code workflows, runbook authoring, capacity planning |
| `triage` | Incident response | `tasks/triage-*/` | incident-channel workflows, on-call runbooks, post-incident reviews (inherits ICON's `post-incident-review` spirit) |
| `support` | Customer-facing support | `tasks/support-*/` | ticket lifecycle, escalation workflows, support retros, knowledge-base contributions |

These are not promises. They are anchored lane prefixes. A team that wants to build any of these scaffolds from `agentic-toolkit` and writes against `context-core`'s published protocol — without coordinating with the ICON maintainers.

**Standalone ecosystem peers** (not role plugins, but ecosystem members):

| Plugin | Role | Notes |
|---|---|---|
| `ds-mcp` | MCP foundation (GitLab + Atlassian, currently) | Standalone, no `context-core` dependency. Its skills auto-invoke when installed; consumers (`devcon`, `pm`, `qa`, Selenium, etc.) include `composesWith: ds-mcp` and use the auto-invoked skills directly. |

---

## 8. Marketplace and install UX

### Marketplace structure

The DataScan AI marketplace lists every ecosystem plugin. The marketplace README is the executive-facing surface (per ICON-0051's umbrella framing — that framing survives into v2).

The marketplace publishes **sets**: pre-bundled compositions for common roles.

```jsonc
// In marketplace.json (Copilot CLI- and Claude-compatible)
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

A user installs `dev-set` and gets three plugins; an advanced user pick-and-mixes individually.

### Install flow

```bash
# Marketplace install (one-time per machine; Copilot CLI primary syntax):
copilot plugin marketplace add https://gitlab.com/onedatascan/ai-platform/marketplace.git

# Role-set install:
copilot plugin install --set dev-set@datascan
# → installs context-core + devcon + ds-mcp

# Or pick-and-mix:
copilot plugin install context-core@datascan
copilot plugin install devcon@datascan
copilot plugin install pm@datascan

# Same commands work in Claude Code with `claude plugin` prefix.
```

### Discovery UX

A user with multiple plugins installed runs:

```bash
copilot plugin list --ecosystem
```

…and gets a grouped view: each ecosystem plugin, its role (from `context.purpose`), its lane (from `context.writes`), its tags (from `tags`). Implementation could be a `context-core` user-invocable skill (`list-ecosystem-plugins`) or a separate (deferred) `switchboard` plugin per ICON-0051.

### Name-collision discipline

Both Copilot CLI and Claude Code support plugin-namespaced skill invocation by default — `/devcon:commit` vs `/pm:commit` resolves cleanly without a registry. Collisions are not a practical hazard at v2 launch (YAGNI on a centrally-managed reserved-name registry). Audit (`audit-plugin`) may surface unprefixed name collisions as a soft warning, but the namespacing handles routing correctly.

---

## 9. Migration from ICON v1

### Plugin migration

| ICON v1 user | v2 path |
|---|---|
| Pure dev user | Install `context-core` + `devcon` + `ds-mcp`. 95% of ICON's current dev capabilities. |
| Pure PM user | Install `context-core` + `pm`. |
| Mixed dev/PM user | Install `context-core` + `devcon` + `pm` + `ds-mcp`. Net footprint slightly *smaller* than ICON v1 because `ecological-impact` and audit-only maintainer skills aren't loaded. |
| Plugin author | Install `agentic-toolkit`. |
| Just wanted MCP | Install `ds-mcp` alone — no `context-core` needed. |

### `.context/` migration

This is the load-bearing question for adoption: do existing ICON-using projects need to rewrite their `.context/`?

**Default answer: mostly no, with one additive change.** The v2 protocol is designed so that ICON v1's current `.context/` shape *is* the v1.0 protocol, with three minor additions:

- File structure (`overview.md`, `decisions/`, `domains/`, `standards/`, `workflows/`, `tasks/`, `iconrc.json`, `META.md`) — unchanged.
- `retrospectives.md` → `retrospectives/devcon.md` (renamed and moved). One-shot script-backed migration: `migrate-retros-to-v2`.
- Per-file schemas — unchanged. The current ICON conventions become the published protocol.
- `iconrc.json` field schema — extended (additive only). New optional fields: `protocolVersion`, ecosystem-plugin declarations.
- `META.md` — gains a required `scope: leaf | aggregator | root | workspace` declaration. One-shot script writes it based on detected topology.
- Task folder layout — unchanged; v2 role plugins use the same `<TASKID>/plan.md` convention with role-prefixed task IDs (`DEV-`, `PM-`, etc.).

What changes is *who writes what*, which is internal to the plugins — invisible to the project's `.context/` content beyond the additive bumps above.

### Migration helper skill (deferred)

A `migrate-to-v2` user-invocable skill (in `context-core` or `agentic-toolkit`) walks an existing ICON v1 `.context/` through the additive changes (retro rename, META scope declaration, iconrc protocol version). Not blocking for v2 launch; built when first user requests it.

### Deprecation timeline

- **v2 launch**: `context-core` + `devcon` + `pm` + `agentic-toolkit` + `ds-mcp` published; ICON v1 stays in service.
- **v2 + 1 release cycle**: ICON v1 enters maintenance mode (security fixes only). Public deprecation announcement.
- **v2 + N release cycles**: ICON v1 retired. Existing users migrate or stay frozen on the last v1 release.

Specific dates deferred until v2 architecture is committed.

---

## 10. Naming

### Working names used in this sketch

| Working name | Meaning | Likely fate |
|---|---|---|
| `context-core` | Central `.context/`-protocol plugin | May inherit the `ICON` name (per user) |
| `devcon` | Dev orchestration plugin | Placeholder; final name TBD |
| `pm` | Product-management plugin | Placeholder; could be `pmcon`, `product`, etc. |
| `agentic-toolkit` | Plugin-authoring plugin | Placeholder; survives from ICON-0051 |
| `qa`, `release-mgmt`, `devops`, `triage`, `support` | Future-wave shelf | All placeholders |
| `ds-mcp` | MCP foundation | Carries forward from ICON-0051 |
| Marketplace umbrella | "DataScan AI Toolkit" or similar | Per ICON-0051 thread; final brand decision deferred |

### Constraints on naming (from ICON-0051 Slack thread, still valid)

- **Avoid `ICON-FOO` prefix pattern.** Visual noise; agents may conflate `ICON` vs `ICON-FOO`; inherits opinions the role plugin may want to dissent from.
- **Where one plugin is a clear addon of another, a shared prefix is meaningful.** None of the v2 role plugins are strict addons of each other (only `context-core` is a hard dependency), so no shared prefix is needed.
- **Marketplace name is the umbrella, plugins keep their own identities.** Leadership recognition flows from the marketplace, not from per-plugin prefixes.

### One realistic naming scenario

`context-core` → renamed `ICON` at launch (v2 inherits the brand). Role plugins are `devcon`, `pm`, `agentic-toolkit`, etc. Marketplace umbrella is "DataScan AI Toolkit" (or whatever leadership lands on). This preserves ICON's recognition while reshaping what ICON *is*.

This is one scenario, not a recommendation. Final naming requires its own conversation.

---

## 11. Open questions

### Closed (cumulative)

| # | Question | Resolution |
|---|---|---|
| 1 | Oversize behavior | Auto-split, then dead-ref check that rewrites incoming references to new paths |
| 2 | Cache directory ownership | Shared cache; `.context/cache/` as `/tmp`-equivalent; no per-plugin partitioning |
| 3 | Domain file contributions | Specialist trusts any non-task write from a conformant plugin |
| 4 | Cross-plugin skill use | Refined per round 3: four invocability classes (§3); agents may auto-invoke other plugins' class-1 and class-2 skills freely; class-3 is user-only; class-4 (internal) reserved for the owning agent's explicit instructions, never cross-plugin |
| 5 | Conflict resolution between role plugins | Each plugin has its own manager; managers prefer in-plugin skills on overlap |
| 6 | Retrospective layout | Per-plugin `retrospectives/{plugin}.md` + shared `retrospectives/shared.md`; specialist owns all |
| 7 | Audit scope | Core `audit-context` (protocol invariants) + `audit-plugin` (per-plugin alignment); agentic-toolkit generates plugin-specific audit-skill templates |
| 8 | Plugin metadata standard | Yes, formally defined; under custom `context:` namespace in `plugin.json` |
| 9 | MCP servers in v2 | `ds-mcp` standalone; its skills auto-invoke when installed |
| 10 | Plugin authoring substrate | `agentic-toolkit` as first-wave plugin |
| 11 | Per-plugin `release-plugin` | Each plugin's repo carries its own `release-plugin` skill; agentic-toolkit provides the template generator |
| 12 | `ecological-impact` | Dropped from v2 entirely |
| 14 | Migration tooling | Deferred — `migrate-to-v2` helper skill built on first user request |
| 15 | Source layout | Separate repos per plugin |
| 16 | Copilot CLI vs Claude Code impedance | **Copilot CLI is canonical.** Any Claude Code feature not replicable in Copilot CLI is excluded from the design. No adapters needed in the other direction; Claude Code support is what naturally falls out of Copilot-CLI-shaped designs |
| 17 | Workspace-level `.context/` semantics | DataScan convention: workspace folder is its own git repo; hosts workspace-level `.context/.claude/.copilot/` (§4 Type 4) |
| 18 | Aggregator `children.md` format | Markdown file. Aggregator init may suggest to the user that some default `context_template/` folders should be trimmed (via the `excludes` array in `iconrc.json`) — suggested, not automatic |
| 19 | Shared retro discipline | Per-plugin file for role-specific lessons; `retrospectives/shared.md` for cross-plugin / protocol / conformance-affecting lessons. `agentic-toolkit`'s `append-retro` includes the decision rule in spec form |
| 20 | Internal-skill cross-plugin enforcement | **Block.** Internal skills (class 4 in §3) include a script-side guard that asserts the caller agent matches `owned-by`; audit also flags any explicit cross-plugin internal-skill reference in plugin definitions |
| 21 | Reserved skill-name registry | Not needed at v2 launch. Plugin-namespaced invocation (`/devcon:commit` vs `/pm:commit`) is native in both runtimes. YAGNI on a centrally-managed registry; revisit if collisions become a real problem |
| 23 | Topology detection determinism | `iconrc.json#/repo_type` is the authoritative declaration (set by `init-context`, read by `resolve-topology`). No heuristic detection at session start (§4) |
| 24 | Init flow for fresh repos | Two-step: `context-core` ships `init-context` that scaffolds the `.context/` skeleton (topology selection, `iconrc.json`, `context_template/` honoring `excludes`, `META.md`). Role plugins (e.g., `devcon`) trigger `init-context` if the repo is uninitialized and then run their own population skill to fill role-specific content |

### Still open

| # | Question | Notes |
|---|---|---|
| 13 | Repository topology resolution algorithm | Acknowledged work item (not really a question — sketched in §4; the rigorous algorithm and its fixture-tests are deliverables for the formal spec). Biggest remaining technical risk. |
| 22 | Per-plugin manager reliability — Claude Code only | Inherited from ICON v1. Claude Code doesn't let users "pick the active agent" — the strategy is the `commands/manager.md` + `commands/pm.md` slash-commands plus an `enable-manager-default` setting (current pattern), but it's only reliable if the user explicitly runs `/manager` at session start. Copilot CLI has no such gap because its explicit agent picker handles this natively. v2 inherits the Claude Code reliability concern; no clean solution beyond carrying forward the current pattern and continuing to refine it |

---

## What this sketch does NOT propose

- A specific release date for v2 launch.
- A specific brand for the marketplace umbrella.
- Final names for any plugin in the ecosystem.
- The full set of skills in `devcon`, `pm`, or `agentic-toolkit` (the lists in §6 are starting points, not commitments).
- Designs for any future-wave plugin (qa, release-mgmt, devops, triage, support).
- Concrete schemas for the formal interface spec — only the structure of the spec is sketched.
- The exact topology-detection-and-resolution algorithm — §4 sketches the shape; the algorithm is a deliverable for the formal spec.
- Resolution of any of the remaining open questions in §11 — those are explicitly for the next round.

---

## 13. Related work

- **ICON-0051 decomposition RFC** (`.context/tasks/ICON-0051-decomposition-rfc/rfc.md`) — the predecessor framing. Proposed keeping ICON at the center and carving off pieces. This sketch inverts that framing: ICON v2 is the ecosystem, `context-core` is a new plugin, and ICON v1 is the prototype superseded once v2 reaches parity. Several ICON-0051 components survive into v2: the plugin-metadata standard, `ds-mcp`, the marketplace-as-umbrella framing, the rejection of the `ICON-FOO` prefix pattern, the `agentic-toolkit` proposal.
- **ICON-0046 audit, Brief 07** (`.context/tasks/ICON-0046-icon-audit/research/07-plugin-decomposition.md`) — original decomposition research.
- **ADR-008 always-loaded token budget** (`.context/decisions/008-always-loaded-token-budget.md`) — the constraint that makes the bloat problem concrete.
- **ADR-004 tool-agnostic content** — the principle that lets one ecosystem ship on both Copilot CLI and Claude Code without forking.
- **ICON v1 topology skills** (`context-specialist-detect-tree-position`, `context-specialist-impl-{branch,leaf,root}`, `initialize-monorepo`, `initialize-multimodule`) — the conceptual ancestor of §4. v2 inherits the structure and invests in reliability.
- **`META.md` (current ICON)** — the de-facto protocol that v2 formalizes as `context-core`'s published interface spec.

### External references consulted for this sketch

- [Claude Code Plugins reference](https://code.claude.com/docs/en/plugins-reference) — plugin manifest, agents, skills, hooks structure.
- [Claude Code Plugin Manifest schema (JSON Schemastore)](https://www.schemastore.org/claude-code-plugin-manifest.json) — authoritative manifest field list.
- [GitHub Copilot CLI plugin reference](https://docs.github.com/en/copilot/reference/cli-plugin-reference) — Copilot CLI plugin.json fields, loading locations, precedence rules.
- [GitHub Copilot CLI custom agents reference](https://docs.github.com/en/copilot/reference/custom-agents-configuration) — agent frontmatter (`user-invocable`, `disable-model-invocation`, `target`, `tools`, `mcp-servers`, `metadata`), sub-agent dispatch via `agent`/`custom-agent`/`Task` tool.
- [Adding agent skills for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills) — SKILL.md format, frontmatter requirements.
- [How to write one skill for both Claude Code and Copilot CLI](https://www.allaboutken.com/posts/20260408-mini-guide-claude-copilot-skills/) — dual-authoring guide; cross-runtime gotchas (no `skills:` field in manifest, `allowed-tools` syntax divergence, default file layout).
