# ICON Plugin Decomposition Strategy and Ecosystem Extensibility Pattern

**Status:** Draft — for team review
**Author:** ICON maintainer team (synthesized from ICON-0046 audit Brief 07, conversational refinement 2026-05-27 → 2026-06-02, and the 2026-06-02 #ai-platform Slack thread)
**Date:** 2026-06-02
**Task:** ICON-0051

---

## Summary

ICON today is a single, strongly-opinionated plugin that bundles a dev-orchestration workflow, a product-management agent, a `.context/` knowledge system, GitLab/Atlassian MCP integration, and meta-tooling for authoring plugins themselves. Two pressures now push toward decomposition: **external consumers** (an internal Selenium testing plugin under development, plus likely future QA, DevOps, Operations, and Support plugins) want narrow capabilities — particularly MCP access — without inheriting ICON's full opinion set; and **organizational positioning** needs a clear umbrella for executive communication without forcing every contributor plugin to brand itself as ICON.

This RFC proposes a phased five-plugin decomposition (`ds-mcp`, `agentic-toolkit`, `icon`, `icon-pm`, optionally `ai-sustainability`), augmented by a small read-only `context-reader` plugin as ecosystem glue and an optional `switchboard` plugin that provides cross-plugin discovery, routing, and health checks. The umbrella concern is resolved at the marketplace layer rather than by mandating shared name prefixes. **Recommendation: carve `ds-mcp` first** (smallest scope, immediate Selenium unblock), `context-reader` second (highest ecosystem leverage), `agentic-toolkit` third, and defer `icon-pm` and `switchboard` until concrete demand materializes. None of these phases requires the others — each delivers value on its own and can be paused independently.

---

## Background

### Current state

ICON ships as a single Claude Code / Copilot CLI plugin (`gitlab.com/onedatascan/ai-platform/plugins/icon`, currently v1.18.2). Today it contains:

- **9 agents** — `manager`, `planner`, `architect`, `coder`, `tester`, `reviewer`, `researcher`, `context-specialist`, `product-manager`
- **49 consumer-facing skills** — spanning dev orchestration (`task-plan`, `code-quality-rules`, `mr-discipline`, `systematic-debugging`), context management (`context-maintenance`, `initialize-repo`, `upgrade-repo`), product management (`rfc`, `jira-story`, `sprint-goals`, `post-meeting`), MCP integration (`setup-mcp-servers`, `mcp-tools-first`), meta-tooling (`writing-skills`, `plugin-design`, `agent-evaluation`), and sustainability (`ecological-impact`)
- **3 maintainer-only skills** — `icon-audit`, `release-plugin`, `changelog-entry`
- **1 plugin manifest** + **2 MCP server configurations** (`gitlab`, `atlassian`)
- **11 ADRs** capturing architectural decisions, **49-line retrospective log** capping at 10 entries
- **A pre-commit hook** enforcing four invariants (`shared/common-constraints.md` byte-equality, dead-reference resolution, `iconrc.json` version-bump gate, script parity)

This is roughly 80 skill/agent/manifest files plus supporting infrastructure. The plugin is internally cohesive but externally monolithic: a consumer who wants any one capability inherits all of them.

### Pressures driving decomposition

Three distinct pressures have surfaced since the v1.0 release. Each on its own might be ignorable; together they suggest the current shape is reaching its limits.

**Pressure 1 — External consumers wanting narrow capabilities.** An internal Selenium testing plugin is under active development and needs access to the GitLab and Atlassian MCP servers ICON bundles. The Selenium plugin has no need for ICON's dev-orchestration agents, `.context/` system, product-manager agent, or meta-tooling — yet today the only way to get the MCP layer is to install the entire ICON plugin. Future plugins for QA orchestration, DevOps automation, Ops monitoring, and Support workflows will face the same problem.

**Pressure 2 — Organizational positioning and executive communication.** A 2026-06-02 Slack discussion surfaced a real tension between technical hygiene (distinct plugin names, narrow scopes, clean dependency graphs) and organizational coherence (a single name leadership can point at, a unified surface for cross-team contribution). The "everything is `ICON-FOO`" pattern was floated and pushed back on; the "marketplace as umbrella, plugins keep their own names" pattern was floated and tentatively agreed.

**Pressure 3 — Contribution governance.** ICON is currently maintained by a small steward team. Distributed contributions from QA, DevOps, Ops, PM, and Support teams need a path that does not require central review of every change, but also does not invite the "10 competing standards" failure mode. Shared protocols (`.context/`, common-constraints discipline, the manager/specialist agent pattern) are the natural enforcement layer — but they only work as enforcement if they are extractable and adoptable by plugins that are not ICON.

### How we got here

This RFC consolidates three threads of prior work:

**ICON-0046 audit, Brief 07 (plugin-decomposition lens).** The most recent quarterly audit (2026-05-27 → 2026-05-31) included a special directive to evaluate decomposition candidates. Brief 07 surfaced four candidate models (two-plugin, three-plugin, four-plugin, core + composable-blocks) and recommended a three-plugin split (`icon-dev` + `icon-pm` + `icon-context`) with the honest caveat that no current finding structurally compelled the split. That research file remains in `.context/tasks/ICON-0046-icon-audit/research/07-plugin-decomposition.md`.

**Conversational refinement (2026-05-31 → 2026-06-02).** Through iterative discussion, the recommendation shifted from three plugins to five (adding `ds-mcp` as standalone after the Selenium consumer surfaced; adding `agentic-toolkit` after recognizing `writing-skills` / `plugin-design` / `agent-evaluation` as universal Claude Code authoring tools; identifying `ai-sustainability` as a natural standalone post the runtime-agnostic `ecological-impact` rewrite). Several proposed coupling concerns dissolved on examination: `mcp-tools-first` plugin-awareness is handled by plugin-registry composition; `common-constraints.md` extraction is unnecessary if each plugin owns its own; `iconrc.json` namespacing is unnecessary if PM is purely a `.context/` reader.

**2026-06-02 Slack thread.** The umbrella-naming tension between technical hygiene and organizational positioning was raised by Vitaliy Hodykin (concern: agents will conflate `ICON` vs `ICON-FOO` when both are loaded), pushed back on by Matt Gibbs (need: single name for executive leadership and contributor onboarding), and tentatively resolved by separating the umbrella concern (marketplace name) from the per-plugin naming concern (plugins keep their own identities). Pasha Stanovskyi raised the broader SDLC framing (PM, Dev, Testing, Deployment, Monitoring, Support). The key insight from that thread — captured in the closing message — was that the `.context/` reading capability is the natural ecosystem substrate: any plugin that can read `.context/` participates in the ecosystem without inheriting ICON's writer opinions.

### Why act now

Two specific signals make this the right moment to surface a proposal:

- **The Selenium plugin is in development.** Its maintainers need a near-term answer on whether to vendor a copy of ICON's `.mcp.json` (and inherit a maintenance burden), wait for ICON to decompose (blocking their progress), or build against a stable standalone `ds-mcp` plugin (the clean answer).
- **The audit just closed.** ICON-0046 surfaced no critical defects but flagged the decomposition question as worth structured analysis. Treating it as a real proposal now — with phased opt-in — costs less than the inevitable retrofit if external consumers ship first and we end up matching their de facto structure.

---

## Proposal

This proposal has four components: (1) the umbrella framing that resolves the naming tension; (2) the five-plugin core decomposition; (3) the `context-reader` ecosystem layer; (4) the optional `switchboard` plugin and the plugin-metadata standard it would consume. Each component can be adopted independently.

### Component 1 — The umbrella framing

The umbrella is the marketplace, not the plugins. Concretely:

- **Marketplace** (the umbrella surface) — given a working name like "Solifi AI Toolkit" or similar, owned by the marketplace repo (`gitlab.com/onedatascan/ai-platform/marketplace`). The marketplace README is the executive-facing entry point: it names every published plugin, its purpose in one line, and its install command.
- **Plugins** (the products inside) — keep their own names and identities. `ICON` stays `ICON` (acronym intact). `ds-mcp`, `agentic-toolkit`, and future QA/DevOps/Ops/Support plugins choose their own names. Where one plugin is genuinely an addon of another, a shared prefix is meaningful (`icon-pm` depends on `icon`); where it is standalone, no prefix is required (`ds-mcp`, `agentic-toolkit`).

This resolves Matt's executive-communication need (the marketplace name is the brand leadership talks about) and Jeremy's technical-hygiene concern (the skill catalog stays free of artificial prefix noise; agents do not have to disambiguate between `ICON` and `ICON-SOMETHING`).

### Component 2 — The five-plugin core decomposition

| # | Plugin | Layer | Depends on | Files moved (approx) |
|---|--------|-------|------------|---------------------|
| 1 | `ds-mcp` | Standalone foundation | None | 3 (`.mcp.json`, `mcp-tools-first` skill, `setup-mcp-servers` skill) |
| 2 | `agentic-toolkit` | Standalone foundation | None | 4 skills (`writing-skills`, `plugin-design`, `agent-evaluation`, generic `plugin-audit`) |
| 3 | `icon` (base — formerly the whole thing minus carved-out pieces) | ICON-extension target | (transitively) `ds-mcp` for MCP-using skills | Stays put: 9 agents minus `product-manager`; ~35 skills; `.context/` system; pre-commit hook |
| 4 | `icon-pm` | ICON-extension | `icon` (hard dependency) | 1 agent (`product-manager`); 4 skills (`rfc`, `jira-story`, `sprint-goals`, `post-meeting`) |
| 5 | `ai-sustainability` | Standalone (optional, deferred) | None | 1 skill (`ecological-impact` after the runtime-agnostic rewrite tracked in ICON-0046 O-T3) |

**Dependency graph:**

```
                ┌──────────────┐       ┌──────────────────┐
                │   ds-mcp     │       │  agentic-toolkit │   (standalone)
                └──────┬───────┘       └──────────────────┘
                       │
            ┌──────────┼────────────┬────────────────────┐
            │          │            │                    │
       ┌────▼────┐ ┌───▼───┐ ┌──────▼──────┐  ┌──────────▼───────┐
       │   icon  │ │icon-pm│ │  selenium-  │  │  any-future-     │
       │ (base)  │◄┤(addon)│ │  testing    │  │  plugin          │
       └─────────┘ └───────┘ └─────────────┘  └──────────────────┘

       ┌─────────────────┐
       │ ai-sustainability│    (optional, standalone)
       └─────────────────┘
```

**Key properties:**

- **No cycles.** Every arrow points from "uses" to "provides."
- **Asymmetric PM/Dev relationship.** PM depends on Dev (PM is a `.context/` consumer that also drives PM-specific workflows). Dev does not depend on PM (most projects do not need a product-manager agent loaded; making it optional reduces always-loaded token weight).
- **MCP is genuinely shared infrastructure.** Selenium, ICON, future plugins all consume `ds-mcp` — it is the wire, not an opinion.
- **`agentic-toolkit` is write-time only.** ICON does not need it at runtime; skill authors install it when authoring. This means ICON's runtime install footprint does not grow if `agentic-toolkit` exists.
- **Each plugin owns its own `common-constraints` discipline.** No shared extraction; if PM needs constraints (it does), `icon-pm`'s plugin defines them. The pre-commit byte-equality invariant is per-plugin, not cross-plugin.

### Component 3 — The `context-reader` extensibility layer

This is the technical key that makes the whole ecosystem buildable without forcing every plugin to be an ICON extension.

Split the `.context/` capability into two pieces:

- **`context-reader`** (small, read-only, standalone plugin) — owns the `.context/` schema knowledge: how to parse `iconrc.json`, ADRs in `decisions/`, retrospectives, task folders, project overview, standards, workflows. Provides skills like `read-iconrc`, `summarize-decisions`, `find-current-task`, `list-recent-retros`, `read-domain-context`. No agents. No writes.
- **`icon` (base)** — keeps the writer side: `context-specialist` agent, `initialize-repo`, `upgrade-repo`, `icon-init`, ADR management, retrospective discipline, the pre-commit hook, all the strong opinions about how `.context/` is maintained.

Any plugin that wants to participate in the ICON ecosystem — selenium-testing, a future QA orchestration plugin, a deployment monitor — declares `dependsOn: context-reader` and gains the ability to read the project's context without inheriting ICON's writer opinions. This is what Jeremy's closing Slack message named: "any plugin that wants to ride along the ICON ecosystem and take advantage of .context information."

This is more powerful than putting `.context/` reading inside `icon`, because non-ICON plugins (Selenium, future QA, future DevOps) can adopt the protocol without taking on `icon` as a dependency.

### Component 4 — The optional `switchboard` plugin and the plugin-metadata standard

This is the most speculative piece. It exists if and only if the ecosystem grows past ~3 plugins and discovery/routing/health becomes a real user problem. Treat it as a sketch — not a commitment.

**The problem it would solve:** Once a user has 5+ plugins installed, four real questions emerge that no single plugin can answer:

1. **Discovery** — "Which plugin handles X?" The skill catalog shows everything; it does not show relationships between plugins, what each plugin's purpose is, or how they compose.
2. **Routing** — "I said 'create a Jira story.' Both `icon-pm` and a hypothetical `qa-orchestration` plugin define skills near that intent. Which fires?"
3. **Health** — "Are all my plugins up to date? Are their MCP credentials configured? Are there version conflicts? Did one plugin's update break another's contract?"
4. **Composition** — "Cross-plugin workflows — dev finds a bug, files a Jira ticket, assigns it to a sprint, notifies Slack — touch four plugins. Who orchestrates?"

**What the `switchboard` plugin would do:**

- `/switchboard list` — show all installed ecosystem plugins, organized by SDLC tag (`pm`, `dev`, `qa`, `deployment`, `monitoring`, `support`), with one-line descriptions
- `/switchboard capabilities <tag>` — list all agents and skills available for a given SDLC phase, across all installed plugins
- `/switchboard find <intent>` — natural-language intent routing ("I want to write a Jira story" → recommends `icon-pm`'s `jira-story` skill; "I want to debug a Selenium failure" → recommends `selenium-testing`'s debug skill)
- `/switchboard health` — run each installed plugin's self-test, surface credential gaps, version-conflict warnings, missing optional dependencies
- `/switchboard compose <workflow>` — execute a declared cross-plugin workflow (see metadata standard below)

**The plugin-metadata standard the switchboard would consume.** This is the substrate that makes the switchboard possible — and also useful even without the switchboard, because anyone building a plugin can declare itself this way and get listed in the marketplace cleanly.

Each plugin's `.claude-plugin/plugin.json` (or a sibling `ecosystem.json`) gains the following optional fields:

```json
{
  "name": "icon-pm",
  "version": "1.0.0",
  "tags": ["pm", "sdlc:product-management"],
  "purpose": "Product-management workflow: Jira stories, RFCs, sprint goals, meeting summaries",
  "dependsOn": [
    { "plugin": "icon", "versionRange": ">=1.18.0" },
    { "plugin": "ds-mcp", "versionRange": ">=1.0.0" }
  ],
  "composesWith": [
    { "plugin": "context-reader", "optional": true }
  ],
  "provides": {
    "agents": ["product-manager"],
    "skills": ["rfc", "jira-story", "sprint-goals", "post-meeting"]
  },
  "verify": ".claude-plugin/verify.sh",
  "workflows": []
}
```

Key fields:

- **`tags`** — SDLC phase + capability tags. Drives switchboard grouping and intent routing.
- **`purpose`** — one-line description for the switchboard list. Authoritative; the README can repeat it but should not contradict it.
- **`dependsOn`** — hard dependencies with version ranges. Switchboard refuses to load a plugin whose deps are missing or out of range; surfaces the gap clearly.
- **`composesWith`** — soft dependencies. Plugin works without them but behaves better with them (e.g., `icon-pm` works without `context-reader` but is richer with it).
- **`provides`** — declared capabilities. Enables the switchboard's intent routing and capability listing.
- **`verify`** — path to a self-test script. Switchboard runs all installed plugins' verify scripts on `/switchboard health`.
- **`workflows`** — declared cross-plugin workflows. Each workflow is a sequence of skill or agent invocations across plugins, with input/output schemas. Switchboard validates referenced plugins are installed before running.

**Why the standard is useful even without a switchboard.** Even if `switchboard` is never built, the metadata fields above are individually valuable: `tags` improves marketplace browsing; `purpose` standardizes the one-line description; `dependsOn` enables clean version-conflict detection; `verify` enables CI smoke-testing each plugin in isolation. The switchboard is the consumer of this metadata; the metadata is worth standardizing first.

---

## Abandoned Ideas

This section captures candidate approaches that were considered and rejected, with the reason for rejection. Several have nuance worth preserving for future re-evaluation if conditions change.

### P1 — Two-plugin split (`icon` + `icon-pm` only)

**What it was.** Carve only the product-manager agent and its skills into `icon-pm`. Leave everything else (MCP, agentic-toolkit, context system) inside ICON.

**Why rejected.** Does not address the Selenium pressure. Selenium still has to vendor or fork ICON's `.mcp.json`; future non-ICON consumers face the same problem. The smallest "real" decomposition that addresses external-consumer demand requires at minimum `ds-mcp` carved out separately.

**When to revisit.** If the Selenium plugin is canceled or relocated to consume ICON in full, and no other external MCP consumer surfaces within ~6 months, P1 becomes the proportionate response — the PM/Dev split is the only one demanded by purely internal pressure.

### P2 — Three-plugin split (`icon-dev` + `icon-pm` + `icon-context`) — original Brief 07 recommendation

**What it was.** The audit's Brief 07 recommendation: split `icon-context` (the `.context/` system) as its own plugin and have both `icon-dev` and `icon-pm` depend on it.

**Why rejected.** Two issues. First, no current external consumer wants just `.context/` reading; the consumers we know of want MCP (Selenium) or write-time meta-tooling (skill authors). Second, `icon-context` as a *full* `.context/` system plugin (writer + reader) is the heaviest split — `context-specialist` agent, init/upgrade skills, ADR management, retro discipline all together — without a clean reason to split them, because Dev and PM both need all of them.

**What was salvaged.** The insight that `.context/` is a separable concern survived; it just needed to be reframed as *read-only* (the `context-reader` plugin) rather than the whole context system. P5's Component 3 is the refined version of P2's instinct.

### P3 — Four-plugin split (`ds-mcp` + `icon-dev` + `icon-pm` + `icon-context`)

**What it was.** P2 plus `ds-mcp` carved separately.

**Why rejected.** Same issue as P2 on the `icon-context` split. The four-plugin version is "P2 with a Selenium concession" — it does not fix the underlying overreach of separating the full context system from `icon`.

### P4 — Status quo plus extensibility hooks

**What it was.** Keep ICON monolithic. Add the plugin-metadata standard (Component 4 above) and let external plugins declare themselves alongside ICON without ICON having to decompose. The Selenium plugin would vendor its own `.mcp.json`; future MCP consumers would do the same.

**Why rejected.** Vendoring `.mcp.json` across N plugins creates N maintenance points for credentials, server versions, and configuration changes. It also fragments the user experience — each plugin's setup flow is slightly different. Long term, P4 produces the "10 competing standards" failure mode Matt warned about in the Slack thread. The metadata standard alone is necessary but not sufficient.

**What was salvaged.** The metadata standard *is* worth adopting independently of the decomposition. P5 retains it as Component 4.

### Full SDLC plugin per phase

**What it was.** Pasha's framing in the Slack thread: "consider all phases of SDLC — PM, Dev, testing, deployment, monitoring/observability, support." Logically a 6+ plugin family with one plugin per SDLC phase.

**Why rejected.** Premature. ICON only has clean shapes for Dev (and partial shape for PM) today. Carving plugins for testing, deployment, monitoring, and support without concrete consumer demand or staffed teams would produce empty shells. The right approach is to define the metadata standard and `context-reader` substrate now so that future SDLC-phase plugins (Selenium, a future ops monitor, etc.) can join the ecosystem when they are real — without ICON pre-creating them.

**What was salvaged.** The framing is correct directionally — the ecosystem is intended to grow into the full SDLC. The decomposition proposal is the chassis for that growth, not the growth itself.

### The "ICON-FOO" prefix-everything pattern

**What it was.** Matt's framing in the Slack thread: every plugin in the ecosystem takes an `ICON-` prefix (e.g., `ICON-Core`, `ICON-QA`, `ICON-SDD`) so leadership and contributors recognize family membership at a glance.

**Why rejected.** Three reasons. **Technical hygiene** — the skill catalog with 60+ entries all prefixed `ICON-*` is genuinely worse for both humans (visual noise) and agents (less semantic distinction between names). **Inheritance of opinions** — calling the QA plugin `ICON-QA` makes it harder for the QA team to disagree with ICON's choices when they should; ICON is a strongly-opinionated dev plugin, not a neutral foundation. **Routing confusion** — Vitaliy's original concern (agents conflate `ICON` vs `ICON-FOO` at runtime) is a real failure mode that semantically distinct names avoid.

**What was salvaged.** Where one plugin is genuinely an addon of another (e.g., `icon-pm` depending on `icon`), the prefix is meaningful as a dependency signal — not a branding rule. The marketplace umbrella addresses leadership's recognition concern without imposing the prefix.

### Centralized review-board governance

**What it was.** Jeremy's first-pass framing in the Slack thread: contributors open issues; one team handles all implementation centrally; verification audit at the end of each change. The premise was that distributed contribution invites breakage.

**Why rejected.** Does not scale. If QA wants their plugin shipped this quarter and the answer is "open an issue, central team will get to it," they will build outside the ecosystem — producing the very fragmentation it was meant to prevent. The breakage concern is real but is better solved by **toolchain enforcement** (a published plugin authoring standard via `agentic-toolkit`, a `.context/` protocol via `context-reader`, a metadata standard via Component 4) than by **process gatekeeping**. Hygiene preserved by the tools beats hygiene preserved by a review board.

**What was salvaged.** The instinct that quality matters — translated into: shared protocols + per-plugin self-tests + clear plugin-authoring guidance, rather than central review of every line. The `CONTRIBUTING.md` added in ICON-0050 reflects this shift.

### Larger `ds-mcp` scope (including workflow skills)

**What it was.** Early conversational draft proposed bundling `mr-discipline`, `mr-feedback-triage`, `jira-story`, `sprint-goals`, and `post-meeting` into `ds-mcp` as "things that use the MCP layer."

**Why rejected.** Those skills are *workflow* concerns, not *access* concerns. `mr-discipline` is about git/MR hygiene (MCP-agnostic in principle). `jira-story` is a formatting skill (no MCP calls in the rendering logic). Bundling them into `ds-mcp` imports ICON-flavored workflow opinions into a plugin that is supposed to be neutral infrastructure. Selenium would not want them; Selenium just wants the wire.

**What was salvaged.** The minimal `ds-mcp` (3 files: `.mcp.json`, `mcp-tools-first`, `setup-mcp-servers`) is the correct shape. Workflow skills stay with their domain plugins (`icon` for dev workflow, `icon-pm` for PM workflow).

### Shared `common-constraints.md` across plugins

**What it was.** Extract the `shared/common-constraints.md` file ICON's pre-commit hook enforces byte-equality on into a separate `constraints` package that all plugins import.

**Why rejected.** Per the design discussion: each plugin owns its own discipline. `ds-mcp` does not have agents and does not need common-constraints. `agentic-toolkit` ships its own write-time discipline (different from ICON's runtime discipline). `icon-pm` inherits ICON's via its `dependsOn: icon` relationship. A shared package is not needed.

### Folding everything into one mega-plugin

**What it was.** The implicit status quo with no extraction. ICON keeps growing; new capabilities go inside.

**Why rejected.** Token-weight pressure (the 2026-06-02 audit found `manager` at 97.1% of its 8500-word ADR-008 cap), inability to satisfy external consumers, no path for the Selenium plugin. This is the path the conversation rejected from the start; documented here for completeness.

---

## Implementation

### Phasing

Five phases, executed in order, each independently valuable, each pausable. None of them require a "big bang."

**Phase 1 — Carve `ds-mcp`.** Smallest scope (3 files), no dependents inside ICON change behavior, immediate Selenium unblock. New repo (`gitlab.com/onedatascan/ai-platform/plugins/ds-mcp`), basic README, plugin manifest. ICON declares a soft dependency or vendors the files during transition. Selenium adopts `ds-mcp` and removes its own `.mcp.json`. Estimated effort: 1–2 days.

**Phase 2 — Carve `context-reader`.** New plugin with the `.context/` schema knowledge and 5–7 read-only skills. ICON keeps the writer side. Selenium and future non-ICON plugins can adopt `context-reader` without taking on `icon` as a dependency. Estimated effort: 3–5 days (mostly skill authoring and schema documentation).

**Phase 3 — Carve `agentic-toolkit`.** Move `writing-skills`, `plugin-design`, `agent-evaluation`, and a generic `plugin-audit` (the rehoming of ICON-0042's split — `icon-audit` becomes ICON's specific override that imports the generic). ICON's `using-skills` priority list at `using-skills/SKILL.md:69-76` gets trimmed. Estimated effort: 2–3 days.

**Phase 4 — Carve `icon-pm`** *(optional, demand-driven).* Move `product-manager` agent and PM workflow skills. `icon-pm` declares `dependsOn: icon`. Only execute when there is concrete demand: a non-ICON PM consumer, a token-budget pressure on ICON, or a team that wants PM separately. Estimated effort: 2–3 days.

**Phase 5 — Build `switchboard`** *(optional, ecosystem-driven).* Only relevant once the ecosystem has ~3 plugins published and discovery becomes a real user problem. Estimated effort: 1–2 weeks for a minimal switchboard with list / capabilities / find / health; longer for compose / workflow execution.

**Decoupling guarantee.** Each phase produces a working ecosystem at its completion. Pausing after Phase 1 leaves the Selenium team unblocked and ICON unchanged. Pausing after Phase 2 leaves the ecosystem substrate in place and lets the Selenium team adopt `context-reader` if they want richer integration. Etc. There is no "halfway broken" state.

### Plugin metadata standard (Component 4 detail)

The metadata schema would land as a draft in a marketplace-owned `ECOSYSTEM.md` doc, not in ICON. The schema versions independently of any plugin. Initial v0.1 declares only the optional fields above; all are non-breaking additions to existing `plugin.json` (Claude Code and Copilot CLI ignore unknown keys).

The schema's evolution path:

- **v0.1** — `tags`, `purpose`, `dependsOn`, `composesWith`, `provides`, `verify` fields. Pure declaration; no runtime consumer required.
- **v0.2** — `workflows` field for cross-plugin orchestration. Requires a switchboard or equivalent consumer to be useful.
- **v0.3+** — additional fields as concrete needs surface. Examples that might be needed: `migrations` (for version upgrades), `conflictsWith` (for known incompatibilities), `lifecycle.hooks` (for install/update/uninstall events).

The schema does not require a switchboard to be useful. Even unconsumed metadata is documentation that the marketplace README can render, that CI can validate, and that future tooling can read.

### UX considerations

**Contributor experience.** A contributor making a change in any ecosystem plugin uses the same task flow ICON pioneered: "New task: …" → ICON-style branch/folder/plan/specialist routing → "task complete." This requires `agentic-toolkit` to publish the manager-agent pattern as a reusable component, or each plugin to ship its own manager. The first option preserves consistency; the second preserves plugin autonomy. Resolution deferred to the `agentic-toolkit` Phase 3 implementation.

**End-user experience.** Installing the marketplace and then individual plugins. A typical user might run:

```bash
claude plugin marketplace add https://gitlab.com/onedatascan/ai-platform/marketplace.git
claude plugin install ds-mcp@solifi-marketplace
claude plugin install icon@solifi-marketplace
```

The marketplace README explains what each plugin does in one line; deeper docs live in each plugin's README. A future switchboard would make this discoverable from inside a session (`/switchboard list`).

**Cross-plugin task experience.** When a user has `icon` + `icon-pm` both installed and says "create a Jira story for the bug I just found," both plugins are candidates. Resolution paths:

- **If `switchboard` is installed:** routes via the metadata `provides.agents` declarations + intent matching.
- **If `switchboard` is not installed:** Claude Code's existing agent-selection logic chooses based on agent descriptions. As long as descriptions are distinct (which they are today — `manager` vs `product-manager` are clearly differentiated), conflict is rare.

The decomposition does not require a switchboard for routing to work in the simple cases; the switchboard becomes valuable when the ecosystem has 5+ plugins and routing becomes ambiguous.

---

## Operationalization

### Resilience

**Dependency declarations and graceful degradation.** Plugins declare hard dependencies (`dependsOn`) and soft compositions (`composesWith`) in their manifest. Behavior expectations:

- **Hard dep missing.** Plugin refuses to load; surfaces a clear error pointing at the missing dep and its install command.
- **Soft dep missing.** Plugin loads but with degraded capability; the absent functionality is explained when the user invokes a skill that would have used it.
- **Version mismatch.** Switchboard (when present) surfaces it on `/switchboard health`; without switchboard, plugins SHOULD log a warning at session start and continue if possible.

**Marketplace as the version compatibility surface.** The marketplace's `marketplace.json` is the source of truth for which versions of which plugins are tested-together. A user installing from the marketplace gets a known-compatible set; users installing plugins directly take responsibility for compatibility themselves.

**Per-plugin self-test.** Each plugin ships `.claude-plugin/verify.sh` (or equivalent) that exercises its core skills against a minimal fixture. CI runs this on every release. Switchboard runs it on `/switchboard health`. Users can run it manually for diagnosis.

**Pre-commit hook scope per plugin.** ICON's existing pre-commit hook (`shared/common-constraints.md` byte-equality, dead-ref resolution, `iconrc.json` version-bump gate, script parity) stays with ICON. Each decomposed plugin defines its own hook as needed; the hooks do not cross plugin boundaries.

### Security

**MCP credential boundary.** `ds-mcp` owns credential setup and storage. Credentials are user-scoped (per Claude Code / Copilot CLI conventions) and never exposed across plugins. A plugin that wants to use the MCP servers calls the MCP tools through Claude Code's standard protocol; the credentials never appear in any plugin's manifest, hook output, or skill content.

**No cross-plugin data leakage.** Plugins do not share state files. Each plugin's state (if any) lives under its own namespace in `~/.claude/` or equivalent. ICON's `.context/iconrc.json` lives in the user's repo and is read-only to other plugins that opt-in via `context-reader`.

**Common-constraints data-exfiltration rule.** ICON's existing rule (no auto-filing to external systems without explicit user confirmation) replicates per plugin. Each plugin authors its own common-constraints file with its own variant of the rule — this is one of the reasons the no-shared-constraints decision was correct.

**MCP tool discipline.** `mcp-tools-first` ships with `ds-mcp`. Any plugin that uses GitLab or Jira data is expected to invoke MCP tools rather than `curl` or `gh`/`glab` CLIs. Without `ds-mcp` installed, this discipline is silently absent — which is correct, because the discipline only applies when the MCP layer is present.

**Plugin signing and trust.** Out of scope for this RFC. The marketplace currently relies on Git transport trust (the user trusts the marketplace repo). Future ecosystem growth may warrant signed manifests; deferred to a separate RFC if/when external (non-DataScan) plugins want to publish.

---

## Addendum

### Open questions for the team

1. **Marketplace umbrella name.** Working name in this RFC is "Solifi AI Toolkit." Final name needs leadership sign-off. Alternatives discussed: "Solifi-AIM (AI Marketplace)", "Solifi-AI-Dev (formerly ICON)" (Matt's example, but tied to dev specifically).
2. **Does `agentic-toolkit` truly belong outside `icon`?** ICON consumes it write-time; non-ICON authors consume it any time. The runtime footprint argument supports separation. The cohesion argument (everything-an-author-needs lives together) supports keeping it inside ICON. Lean toward separation, but worth confirming.
3. **Should `using-skills` move to `agentic-toolkit` or stay in `icon`?** It is a runtime discipline (favors `icon`) but is authored as universal (favors `agentic-toolkit`). Tentative answer: stays in `icon`, since ICON's "always consult the catalog" discipline is opinionated and other plugins should adopt similar discipline in their own form. But this is reversible.
4. **Switchboard ownership.** If built, does it live in the marketplace repo or as a separate plugin? Leaning separate-plugin, but tied to the metadata schema's evolution which lives in the marketplace.
5. **Migration timeline.** Phase 1 (`ds-mcp`) has a near-term forcing function (Selenium plugin). Phase 2 (`context-reader`) is the highest-leverage technical move. Phases 3–5 are demand-driven. Should the team commit to Phase 1 + Phase 2 as a near-term sequence and explicitly leave Phases 3–5 deferred?
6. **What about ICON's name?** If the decomposition lands and `icon` becomes "the base dev plugin" (40% of its current footprint), does the name still fit? The acronym (Independent Context Orchestration Network) describes a system that is increasingly distributed across plugins, not concentrated in one. Not urgent — but worth re-examining once the decomposition is real.

### Future considerations

- **Cross-plugin task coordination.** When a manager in `icon` receives a task that ought to involve `product-manager` (in `icon-pm`), how is the handoff modeled? Possible answers: (a) manager dispatches directly to product-manager via the standard agent invocation; (b) switchboard intermediates; (c) a new "ecosystem manager" pattern. Tentative answer: (a) for now (works today), (b) once switchboard exists.
- **Marketplace-level documentation.** Beyond the README listing plugins, should the marketplace ship a unified "getting started" guide that walks a new user through installing the right subset of plugins for their use case? Tentative answer: yes, but defer until ≥3 plugins are published.
- **Contribution flow across plugins.** A bug that spans multiple plugins (e.g., a workflow that touches `ds-mcp` and `icon-pm`) — which plugin's issue tracker does it land in? Tentative answer: the consumer plugin (the one whose user-facing behavior breaks); but document this in each plugin's CONTRIBUTING.md.
- **Ecosystem-wide retrospective sharing.** ICON's retrospective log is per-repo today. Would an ecosystem-wide pattern (shared lessons across plugins) be valuable? Out of scope for this RFC; possible future RFC.
- **A non-ICON consumer of `agentic-toolkit` other than ICON.** This is the natural pressure-test for the standalone-vs-bundled question. If the Selenium team or another team uses `agentic-toolkit` for their own skill authoring without needing `icon`, the separation pays for itself. If not, it might be premature.

### What this RFC does NOT propose

- Renaming ICON now (deferred — see open question 6).
- Building the switchboard now (deferred to Phase 5, demand-driven).
- Carving `icon-pm` now (deferred to Phase 4, demand-driven).
- Centralizing common-constraints (explicitly rejected).
- Forcing the `ICON-FOO` prefix pattern (explicitly rejected).
- Auto-filing GitLab issues for any phase (subject to common-constraints data-exfiltration rule — requires explicit user direction).

### Related work

- `.context/tasks/ICON-0046-icon-audit/research/07-plugin-decomposition.md` — Brief 07 of the most recent audit; first formal analysis of decomposition candidates.
- `.context/tasks/ICON-0046-icon-audit/audit-report.md` — overall audit context, including the cluster themes (ecological-impact ADR-004, mcp-tools-first discoverability) that informed this RFC's framing.
- `CONTRIBUTING.md` (added in ICON-0050) — the contribution governance counterpart. The RFC's "hygiene via tools, not gates" stance is consistent with `CONTRIBUTING.md`'s task-flow + holistic-review framing.
- 2026-06-02 #ai-platform Slack thread — original umbrella-naming discussion; not preserved in repo but captured in the Background section above.
- `.context/decisions/008-always-loaded-token-budget.md` — ADR-008 (the 8500-word manager cap that is part of what makes decomposition technically attractive).
- `.context/decisions/010-carry-forward-registry.md` — ADR-010 (the carry-forward pattern that informs how decomposed plugins would handle cross-version state).
