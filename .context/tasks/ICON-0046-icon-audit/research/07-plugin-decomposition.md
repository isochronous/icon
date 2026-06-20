# Plugin Decomposition Analysis — ICON-0046

This brief is forward-looking. It evaluates how the single ICON plugin could be decomposed into 2+ composable plugins (software-development, product-management, agentic-toolkit-design, context-initialization, etc.). It does not propose any source-file edits. The recommendation at §4 may be "keep as one plugin" if the cuts cost more than the gain; that decision is reached only after enumerating the cuts.

Inputs: research/01-agents.md, research/02-process-skills.md, research/03-context-specialist-init.md, research/04-utility-skills.md, research/05-infrastructure.md, plus source skim of the agent files, `using-skills`, `manager-routing-guide`, `shared/common-constraints.md`, `.githooks/pre-commit`, `.claude-plugin/plugin.json`, and ADRs 004 / 008 / 010.

---

## 1. Current Coupling Map

Inventory of all 9 agents + 49 skills (47 user-tree + 3 maintainer-only `.claude/skills/`, of which `using-skills` straddles the boundary). Clusters are role-functional, not file-tree. Categories adapted from the brief; `(D)` and `(E)` slightly subdivided where the audit findings drove a sharper boundary.

### Cluster A — Software-Development Orchestration

**Member agents** (`agents/`):
- `manager.agent.md` (user-invocable, 292 lines, 4,148 words per ADR-008)
- `planner.agent.md` (sub-agent, 155 lines)
- `architect.agent.md` (sub-agent, 149 lines)
- `coder.agent.md` (sub-agent, 100 lines)
- `tester.agent.md` (sub-agent, 115 lines)
- `reviewer.agent.md` (sub-agent, 120 lines)

**Member skills** (`skills/`):
- Workflow spine: `task-plan` + five phase skills (`task-plan-phase-investigation`, `task-plan-phase-architecture`, `task-plan-phase-implementation`, `task-plan-phase-testing`, `task-plan-phase-completion`)
- Discipline skills: `verification-checklist`, `commit-discipline`, `mr-discipline`, `code-quality-rules`, `testing-discipline`, `design-first`, `systematic-debugging`
- Process / lifecycle: `task-retrospective`, `post-incident-review`, `migration-planning`, `dependency-management`, `start-worktree`

**Internal deps** (intra-A):
- `manager.agent.md:124` → `manager-routing-guide` (Cluster E, but referenced from A)
- `manager.agent.md:32` → `using-skills` (Cluster E)
- `manager.agent.md:79,162,199,221,250` → `task-plan` skill + `.context/workflows/task-plan/phase-*.md` template files
- `manager.agent.md:201` → `verification-checklist`
- `manager.agent.md:206` → `commit-discipline`
- `manager.agent.md:207` → `mr-discipline`
- `manager.agent.md:202-205` → `task-retrospective` (which delegates to `@context-specialist` mode:maintenance — crosses into C)
- `reviewer.agent.md:26,69` → `code-quality-rules`
- `coder.agent.md:45` → `code-quality-rules`
- `tester.agent.md:18-19` → `testing-discipline`, `verification-checklist`
- `task-retrospective` Steps 6-7 invoke `verification-checklist` (duplicate of manager Step 2 — see m-P-NEW-3 in research/02)

**External deps**:
- Cluster C (Context-Init): manager Step 3 calls `resolve-repo-context`; manager Step 5 uses `.context/tasks/` artifact paths; task-retrospective Stage 2 dispatches `@context-specialist` mode:maintenance.
- Cluster E (Cross-Cutting): `using-skills`, `manager-routing-guide`.
- Cluster F (Maintainer-only): irrelevant to runtime; only `release-plugin`/`changelog-entry` consume A-domain hooks.

**Always-loaded vs on-demand**:
- Always-loaded (manager session): `manager.agent.md`, `using-skills` (Cluster E), `shared/common-constraints.md` ×9 inlined (Cluster E).
- On-demand: every other A skill.

### Cluster B — Product Management

**Member agents**:
- `product-manager.agent.md` (user-invocable, 270 lines, ~6,564 words session baseline per ADR-008)

**Member skills**:
- `jira-story` (Format-type)
- `sprint-goals` (Format-type)
- `post-meeting` (Format-type)
- `rfc` (Format-type — straddles B and D; design documents can be PM or architectural artifacts)

**Internal deps**:
- `product-manager.agent.md:25,71-73,77,84,104` → `jira-story` skill (skill renders and writes the file)
- `product-manager.agent.md:14` → `using-skills`
- PM may invoke `rfc` when story scope demands a design doc instead

**External deps**:
- Cluster A sub-agents: PM delegates to `@researcher`, `@architect`, `@planner` per `product-manager.agent.md:34-47`. These three sub-agents live in Cluster A.
- Cluster E: `using-skills`, common-constraints (inlined per ADR-004).
- Cluster F: none.

**Always-loaded vs on-demand**:
- Always-loaded (PM session): `product-manager.agent.md`, `using-skills`, common-constraints ×9 inlined (the 9 inlined copies count even when only PM is the front-of-session agent, because ADR-008 measures the session, not per-active-agent).
- On-demand: `jira-story`, `sprint-goals`, `post-meeting`, `rfc`.

### Cluster C — Context Initialization & Maintenance

**Member agents**:
- `context-specialist.agent.md` (sub-agent, 130 lines, modes: create / upgrade / maintenance / audit)
- `researcher.agent.md` (sub-agent, 145 lines — used by both A and B, but its cache-writing behavior is squarely a context-init concern; classified C with cross-cluster notes)

**Member skills** (`skills/`):
- Init entry-point and fan-out: `icon-init`, `initialize-repo`, `initialize-monorepo`, `initialize-workspace`, `initialize-multimodule`
- Upgrade and maintenance: `upgrade-repo`, `context-maintenance`, `merge-phase-templates`
- Implementation primitives: `context-specialist-create`, `context-specialist-impl-root`, `context-specialist-impl-branch`, `context-specialist-impl-leaf`, `context-specialist-detect-tree-position`
- Discovery / routing: `find-context-template`, `resolve-repo-context`, `create-iconrc`
- Doc shape: `context-document-guidelines`

**Member non-skill artifacts**:
- `context_template/` — the ship-on-init starter tree, including `iconrc.json` (versioned, gated by `.githooks/pre-commit:57-116`), `META.md`, `architecture/patterns-template.md`, `decisions/`, `workflows/task-plan/phase-*.md`, `workflows/prune-context.sh`, `retrospectives.md`.

**Internal deps**:
- `icon-init` → `initialize-monorepo` | `initialize-workspace` | `initialize-multimodule` | `initialize-repo` (one of four based on detection)
- All four `initialize-*` → `@context-specialist` (mode: create) → `context-specialist-create` → impl skill (root/branch/leaf)
- `upgrade-repo` Phase 2 reads `context_template/context/iconrc.json:version` to gate updates
- `context-maintenance` is the single skill that handles both `mode: maintenance` and `mode: audit` (`context-specialist.agent.md:49-58`)
- `task-retrospective` Stage 2 → `@context-specialist` mode:maintenance → `context-maintenance` → `append-retrospective-entry.sh` (3-copy parity gate per `.githooks/pre-commit:407-443`)

**External deps**:
- Cluster A: invoked by manager during task close (Stage 2 of retrospective); manager Session Start Step 3 invokes `resolve-repo-context`.
- Cluster E: `manager-routing-guide` row 11 names `initialize-repo` and `context-specialist`.
- The `context_template/` payload bundles content that is conceptually Cluster A (phase-*.md templates, retrospectives.md format) and Cluster D (none). Ownership of `phase-*.md` files in particular is contested — they ship via Cluster C's init flow but encode Cluster A's workflow spine.

**Always-loaded vs on-demand**:
- Never always-loaded. `@context-specialist` is sub-agent only.
- `using-skills` and common-constraints are inlined into `context-specialist.agent.md:106-128`.

### Cluster D — Agentic Toolkit / Meta-Tooling

**Member skills**:
- `writing-skills` (Iron Law SSOT, 499 lines, 2,908 words — see m-U-net1 in research/04)
- `agent-evaluation` (frontmatter conventions live here per `agent-evaluation/SKILL.md:104`)
- `plugin-design` (audit-mode + create-mode for Claude Code plugins; m-U-net4 ADR-004 tension)
- `invoke-sub-project-skill` (mechanism for sub-project skill catalog dispatch)

**Internal deps**:
- `agent-evaluation` is the SSOT for agent frontmatter rules (`agent-evaluation/SKILL.md:104` — drives `context-specialist.agent.md:2-6` finding m-A-NET-NEW-1 in research/01)
- `writing-skills` is the SSOT for skill authorship discipline (cited by `icon-audit` Quality Checklist at `.claude/skills/icon-audit/SKILL.md:144-152`)
- `plugin-design` cites `writing-skills`, `agent-evaluation`, `manager-routing-guide` patterns when auditing

**External deps**:
- Cluster F: `icon-audit` consumes `writing-skills` Iron Law; `release-plugin` consumes `agent-evaluation` patterns indirectly.
- Cluster A: `manager.agent.md:153` mentions "if this delegation creates or edits a skill … paste the writing-skills Quality Checklist verbatim."
- Cluster C: `agent-evaluation` references `context-specialist` description as a worked example.

**Always-loaded vs on-demand**:
- Never always-loaded. All four skills are on-demand.

### Cluster E — Cross-Cutting Building Blocks

**Member skills**:
- `using-skills` (Meta-type per `using-skills/SKILL.md:87`; always-loaded per ADR-008)
- `manager-routing-guide` (Internal manager skill; loaded on routing decisions)
- `mcp-tools-first` (auto-invoked by description match)
- `setup-mcp-servers` (one-shot user setup)
- `icon-status` (user-invoked reorientation)
- `ecological-impact` (user-invoked; M-U-NET1 — heavy Copilot product coupling per research/04)

**Member agents**: none (researcher could be co-located here, but classified C above; cross-reference noted).

**Member infrastructure**:
- `shared/common-constraints.md` — the inlined block enforced by `.githooks/pre-commit:50-359` byte-equality check.

**Internal deps**:
- `using-skills` is referenced from `manager.agent.md:32`, `product-manager.agent.md:14`, every initialize-* skill, and the catalog discipline machinery itself.
- `manager-routing-guide` is the routing table — referenced only by `manager.agent.md:124,228`.
- `mcp-tools-first` is referenced by no other skill (see IO-U-3 in research/04 — discoverability gap).
- `common-constraints.md` is byte-injected into all 9 agent files.

**External deps**:
- This cluster has no externals; everything externally depends on it.

**Always-loaded vs on-demand**:
- Always-loaded: `using-skills`, common-constraints ×9 inlined.
- On-demand: `manager-routing-guide` (loaded on routing decision), `mcp-tools-first` (auto-invoked), `setup-mcp-servers`, `icon-status`, `ecological-impact`.

### Cluster F — Maintainer-Only (`.claude/skills/`)

**Member skills**:
- `.claude/skills/icon-audit/` (this brief's parent skill)
- `.claude/skills/release-plugin/`
- `.claude/skills/changelog-entry/`

**Notes per brief constraint**: "Do not propose splitting any of the `.claude/skills/` maintainer-only skills out into a separate plugin." This cluster stays with the maintainer plugin in every split scenario. They are listed here only to map the dependency edges from D (writing-skills, agent-evaluation) and E (release tags / version files).

---

### Summary Coupling Matrix

| From → To | A | B | C | D | E | F |
|---|---|---|---|---|---|---|
| **A** (sw-dev) | — | (sub-agents referenced by B) | retro→@context-specialist; resolve-repo-context; .context/tasks | writing-skills cited in manager delegation template | using-skills, manager-routing-guide, common-constraints | release-plugin reads workflow |
| **B** (PM) | delegates to @researcher/@architect/@planner | — | (none direct) | rfc may overlap | using-skills, common-constraints | (none) |
| **C** (context-init) | manager invokes; retro Stage 2; ships phase-*.md to A | (none) | — | (none) | using-skills, common-constraints | release-plugin reads context_template/iconrc.json version |
| **D** (meta) | manager.agent.md:153 mentions writing-skills | rfc shared | agent-evaluation cites @context-specialist as example | — | (none direct) | icon-audit consumes writing-skills |
| **E** (cross-cut) | (none) | (none) | (none) | (none) | — | (none) |
| **F** (maintainer) | reads pre-commit hooks (A-spine) | (none) | reads context_template/iconrc.json | reads writing-skills | (none) | — |

**Reading the matrix**: E is the sink (nothing depends ON external clusters from E; everything depends from E). A→C is the heaviest cross-edge (manager pulls @context-specialist into the task-close flow; resolve-repo-context is in Session Start). B→A is structural but one-way (PM delegates to A sub-agents but A never invokes PM). The asymmetry between B's edge and the rest is meaningful for any split.

---

## 2. Decomposition Candidates

Four proposals enumerated. Each is internally consistent; they vary in how aggressively they cut and which clusters retain "ICON" identity. Effort is rough: trivial (< 1 day) | low (1-3 days) | medium (1-2 weeks) | high (> 2 weeks).

| # | Proposal | Members | Type | Depends on | Standalone? | Key cuts required | Estimated effort |
|---|---|---|---|---|---|---|---|
| **P1** | **Two-plugin split: dev-spine vs. PM** | `icon-dev` = A + C + D + E + F; `icon-pm` = B | `icon-dev` standalone; `icon-pm` icon-extension | `icon-pm` → `icon-dev` for A's @researcher/@architect/@planner sub-agents and E's using-skills/common-constraints | dev: yes; pm: no (needs dev's sub-agents) | (a) Bundle common-constraints in `icon-pm` or take dev as hard dep; (b) decide if PM's @researcher/@architect/@planner delegations are tolerable as "skip if absent" or require dev; (c) split README into two; (d) duplicate or symlink `using-skills` | low |
| **P2** | **Three-plugin split: dev / pm / context-init** | `icon-dev` = A + D + E + F; `icon-pm` = B; `icon-context` = C (incl. context_template) | dev: standalone; pm: extension of dev; context: extension of dev | pm → dev; context → dev (for using-skills, common-constraints); dev → context at runtime (manager Session Start calls resolve-repo-context, retro Stage 2 calls @context-specialist) | dev: partial (works without context but loses /icon-init, /upgrade-repo, retro-stage-2); pm: no; context: no | (a) Resolve the C-as-prerequisite-for-A problem: either ship resolve-repo-context fallback in dev, or document that dev requires context; (b) decide ownership of phase-*.md templates (they ship in context_template/ but encode A's spine); (c) duplicate using-skills / common-constraints, or define a third "icon-core" that holds them; (d) pre-commit hook ownership — the byte-equality gate covers files now in 3 separate plugins | medium |
| **P3** | **Four-plugin split: dev / pm / context-init / agentic-toolkit** | `icon-dev` = A + E + F; `icon-pm` = B; `icon-context` = C; `icon-toolkit` = D (writing-skills, agent-evaluation, plugin-design) | dev: standalone; others: extensions; toolkit: standalone-ish (no runtime deps) | toolkit: no runtime deps but referenced by F (icon-audit) and A (manager delegation template at :153) | dev: partial; pm/context: no; toolkit: yes (it's documentation-shaped) | All of P2's cuts, plus: (e) writing-skills citations in icon-audit and manager template must resolve cross-plugin; (f) agent-evaluation citations from C's context-specialist.agent.md description rule are now cross-plugin | medium-high |
| **P4** | **Core + composable-blocks marketplace** | `icon-core` = E + common-constraints + minimal hook infrastructure; `icon-sw` = A + F; `icon-pm` = B; `icon-context` = C; `icon-toolkit` = D | all extensions of `icon-core` | each declares `icon-core ^1.x.x` | core: yes; rest: no | All of P3's cuts, plus: (g) common-constraints byte-injection becomes a cross-plugin coordination problem — either each extension ships its own pre-commit hook with byte-equality against icon-core's shared file, or icon-core ships a shared hook installer; (h) the manifest contains marketplace metadata pointing at sub-plugins; (i) version-pinning machinery (none exists today) | high |

**Type definitions** (per brief):
- `standalone`: installable in isolation, works without any other ICON plugin present.
- `icon-extension`: requires the named ICON plugin to be installed alongside.
- `composable-block`: designed to be combined with other composable-blocks; no single one is "the main plugin."

**Why P1 is the lightest:** P1 keeps the heavy A↔C edge inside one plugin (preserving the Session Start + retro-Stage-2 flow without cross-plugin coordination), and only severs the B↔A one-way delegation. PM users already accept "install ICON" today; the rename of half of it to `icon-dev` is mostly cosmetic.

**Why P2 is the strategic split:** P2 isolates the context-init/template-ship machinery — the part most subject to user customization. A consumer who wants to use a different `.context/` shape can swap `icon-context` without touching `icon-dev`. This is the strongest forward-looking case but requires resolving the phase-*.md ownership question.

**Why P3 adds little marginal value:** Pulling D out as a separate plugin makes sense only if a non-ICON consumer wants `writing-skills` and `agent-evaluation` for their own plugin. Today no such consumer is documented. The split's main beneficiary is `plugin-design` (mode-detected for any Claude Code plugin), but `plugin-design` is small enough to live in `icon-dev` until evidence of external use arrives.

**Why P4 is over-engineered now:** The composable-blocks pattern only pays off when there are 3+ alternative implementations of any block (e.g., two different context-init plugins competing for the same slot). ICON has one of each. The cost of building the version-pinning and shared-hook machinery exceeds the benefit until there is choice.

---

## 3. Dependency-Edge Analysis

Per-proposal cuts, citing file:line where possible. Each block enumerates the seven edge categories from the brief.

### P1 — Two-plugin split (`icon-dev` + `icon-pm`)

**Common-constraints injection**:
- Source: `shared/common-constraints.md` (21 lines, in Cluster E).
- Enforced by: `.githooks/pre-commit:50-359`, byte-equality against all 9 `agents/*.agent.md` files.
- Cut: in `icon-pm`, the only agent file is `product-manager.agent.md`. It still needs the inlined block (already at `product-manager.agent.md:244-266`). Two options: (a) duplicate `shared/common-constraints.md` into `icon-pm` and ship a parallel pre-commit hook; (b) take `icon-dev` as a hard dependency and reference its shared file at install time. Option (a) is the cleaner cut but creates a drift surface; option (b) preserves SSOT but creates a runtime cross-plugin file resolution problem (no existing plugin manifest format for "include another plugin's file at this path").

**Manager-routing-guide entries**:
- `manager-routing-guide/SKILL.md:80` mentions `@product-manager`: "Standalone tool invoked directly by users for product-management work… Not part of the manager's delegation chain — the manager does NOT route tasks to @product-manager." Already declared not-part-of-spine.
- After split: this row can stay (advisory). No cut needed.

**`using-skills` workflow chains**:
- `skills/using-skills/SKILL.md:74` lists "Formatting skills — `jira-story`, `rfc` — shape the output." Both move to `icon-pm` (jira-story) or split (`rfc` lives in both contexts).
- Cut: either remove the formatting-skills row from `using-skills` (loss of discoverability for PM session) or duplicate `using-skills` into `icon-pm` with PM-specific examples. Today PM already inlines `using-skills` cue at `product-manager.agent.md:14`. The skill itself can stay in `icon-dev`'s using-skills and PM sessions reference it by name.

**Phase-skill template overrides**:
- `task-plan/SKILL.md:16` defines the `.context/workflows/task-plan/base.md` override; lines 41-43 cover phase-*.md per-repo override. The phase templates ship in `context_template/` (Cluster C, but staying with `icon-dev` in P1).
- No cut needed — both stay in `icon-dev`.

**`.context/` template ownership**:
- `context_template/` belongs to Cluster C, staying with `icon-dev` in P1.
- `iconrc.json` version-bump gate at `.githooks/pre-commit:57-116` is `icon-dev` internal.
- No cut needed.

**Hook ownership**:
- `.githooks/pre-commit` enforces 4 invariants today (common-constraints sync, dead-ref resolver, iconrc gate, script-parity). All four operate on files that stay in `icon-dev` *except* the common-constraints block in `product-manager.agent.md` (moves to `icon-pm`).
- Cut: `icon-pm` needs its own pre-commit hook for the common-constraints sync against the local PM agent file. Same hook script applied to a one-file repo; trivial port.

**Cross-skill references** (grep `\bsee\s+\`[a-z-]+\`|\bvia\s+\`[a-z-]+\`|\binvoke\s+\`[a-z-]+\`` across skills/ + agents/ = 227 matches per `wc -l` confirm; sampling for B-to-A and A-to-B):
- `product-manager.agent.md:25,71-73,77,84` → `jira-story` (intra-icon-pm, OK)
- `product-manager.agent.md:34-47` → `@researcher`, `@architect`, `@planner` (cross-plugin in P1 — these sub-agents live in `icon-dev`)
- `product-manager.agent.md:174` → references `jira-story` skill (intra-icon-pm, OK)
- `jira-story` description → no back-references to `@product-manager`
- Cut: cross-plugin sub-agent dispatch is the largest unknown. Claude Code's `Task` tool and Copilot's `explore` agent dispatch by name. If both plugins are installed, the sub-agent resolves; if only `icon-pm` is installed, the dispatch fails. Document `icon-pm` as requiring `icon-dev` installed (extension model).

**Total cuts for P1**: ~5 documentation edits + 1 hook duplication + 1 readme rewrite. **Trivial to low effort.**

### P2 — Three-plugin split (`icon-dev` + `icon-pm` + `icon-context`)

All of P1's cuts apply. Additional cuts:

**Common-constraints injection**:
- Source must now be available to 3 plugins (manager + 6 other A sub-agents in dev; product-manager in pm; context-specialist + researcher in context).
- Cut: either (a) elect `icon-dev` as the canonical home, with `icon-context` and `icon-pm` declaring dev as a hard dep and reading the file via a documented path convention; or (b) introduce a new `icon-core` plugin holding only shared/common-constraints.md + using-skills + common pre-commit hook. (b) is the cleaner architecture and creates P4-shaped layering.

**Manager-routing-guide entries**:
- `manager-routing-guide/SKILL.md:60` references `initialize-repo` ("Initialize / regenerate project context | Invoke `initialize-repo` skill (routes to @context-specialist)") — `initialize-repo` and `@context-specialist` both move to `icon-context`.
- `manager-routing-guide/SKILL.md:61` references `@context-specialist` (mode: maintenance) — moves to `icon-context`.
- `manager-routing-guide/SKILL.md:79` lists `@context-specialist` capabilities in detail — must be kept synchronized cross-plugin.
- Cut: routing-guide entries become cross-plugin references. The guide can stay in `icon-dev` but the entries become "if `icon-context` is installed, route to it; else surface gap" — adds a conditional.

**`using-skills` workflow chains**:
- `using-skills/SKILL.md:77` example: "Work a task end-to-end → `task-plan` → `task-plan-phase-investigation` → … → `task-retrospective`." `task-retrospective` Stage 2 dispatches `@context-specialist` — cross-plugin.
- Cut: the example still works (skill-by-skill resolution); the gap is silent if `icon-context` is not installed. Add a "requires icon-context" note to `task-retrospective`'s skill description.

**Phase-skill template overrides**:
- `task-plan/SKILL.md:41-43` and the five `task-plan-phase-*` skills all read `.context/workflows/task-plan/base.md` and `phase-<name>.md` overrides. The skills stay in `icon-dev`; the templates ship via `icon-context`'s `context_template/`.
- Cut: this is the **ownership inversion problem**. The phase template content encodes Cluster A's workflow. If `icon-context` ships them, `icon-dev` releases must coordinate with `icon-context` releases for phase template updates. ADR-010 already promoted one phase-completion.md note. A version-skew between dev and context plugins would cause phase templates to diverge from the skill content that consumes them.
- Resolution options: (i) phase-*.md templates move to `icon-dev` (init-time copy machinery in `icon-context` knows where to read them from); (ii) phase-*.md templates stay in `icon-context` and `icon-dev` documents the minimum `icon-context` version; (iii) phase-*.md templates and the phase skills both move to `icon-context` (Cluster C absorbs the workflow templates and the phase skills become "context maintenance" skills) — radical and probably wrong.

**`.context/` template ownership**:
- `context_template/` becomes `icon-context`'s payload.
- The `iconrc.json` version-bump gate at `.githooks/pre-commit:57-116` becomes `icon-context`'s pre-commit hook.
- Cut: hook ownership cleanly moves with the template.

**Hook ownership**:
- Pre-commit invariants split: common-constraints sync stays where common-constraints.md is (either dev or new core); iconrc gate moves to context; dead-ref resolver checks `.context/<x>.md` refs in skills/ and agents/ files — cross-plugin coordination required (a context-skill reference to a .context/standards/X.md file is only resolvable if context_template/ ships it).
- Script-parity check at `.githooks/pre-commit:407-443` covers three copies of `append-retrospective-entry.{sh,ps1}` across `skills/post-incident-review/`, `skills/task-retrospective/`, `skills/context-maintenance/`. `post-incident-review` and `task-retrospective` are A; `context-maintenance` is C.
- Cut: the script-parity gate fails if the file moves cross-plugin (one canonical source can't be byte-checked against a different plugin's copy at commit time). Either consolidate the three copies into one (collapse the duplication that motivated the parity check), or accept that each plugin maintains its own copy and the parity check downgrades to a release-time verification rather than commit-time.

**Cross-skill references**:
- `manager.agent.md:34,89,90` references `.context/` paths — these stay valid (the `.context/` is at the consumer repo root, populated by `icon-context`).
- `manager.agent.md:202-205` references `task-retrospective` → `@context-specialist` mode:maintenance — this is the dev→context runtime crossing. Documented as extension dependency.
- `upgrade-repo/SKILL.md:198,201` references `merge-phase-templates` — both stay in `icon-context`, intra-cluster.
- `context-specialist.agent.md:38` references `context-specialist-create`, `upgrade-repo`, `context-maintenance` — all `icon-context` intra-cluster.

**Total cuts for P2**: ~15 documentation edits + 2 hook splits + 1 phase-template ownership decision + 1 release-coordination protocol. **Medium effort.**

### P3 — Four-plugin split (adds `icon-toolkit`)

All of P2's cuts apply. Additional cuts:

**Common-constraints injection** + **using-skills**: same as P2.

**Manager-routing-guide entries**:
- `manager.agent.md:153` references `writing-skills` Quality Checklist verbatim — cross-plugin to `icon-toolkit`.
- Cut: either drop the reference (lose the discipline-injection from manager delegation) or document `icon-toolkit` as recommended-but-optional.

**`.context/` template ownership**: unchanged from P2.

**Hook ownership**: Cluster D has no hooks today.

**Cross-skill references**:
- `agent-evaluation/SKILL.md:104` is the SSOT for the "sub-agents stay one-sentence" rule that drives m-A-NET-NEW-1 in research/01.
- `context-specialist.agent.md:2-6` description is the offending file. After split: the rule lives in `icon-toolkit`, the file lives in `icon-context`. Cross-plugin SSOT.
- `.claude/skills/icon-audit/SKILL.md:144-152` references `writing-skills` Quality Checklist — Cluster F→D cross-plugin (both maintainer-only, but in different plugins now).

**Total cuts for P3**: P2's cuts + ~5 toolkit-citation rewrites. **Medium-high effort with limited benefit until a non-ICON toolkit consumer exists.**

### P4 — Core + composable-blocks

All of P3's cuts apply. Additional cuts:

**Common-constraints injection**:
- Moves to `icon-core`. Every other plugin's pre-commit hook now resolves the source from a sibling plugin install. Requires a "find icon-core install path" convention.

**`using-skills`** and **`manager-routing-guide`**:
- Both move to `icon-core`. Manager (in `icon-sw`) references its own routing guide cross-plugin.

**Version-pinning machinery**:
- `.claude-plugin/plugin.json` has no current notion of `dependencies`. Each composable plugin would need to declare `requires: { "icon-core": "^1.x.x" }`. This is **new manifest schema**, not just a content change.

**Marketplace structure**:
- The `datascan-marketplace` listing currently points at `ICON` as one plugin. P4 ships 5 plugins; the marketplace must be restructured to enumerate them and resolve install-order (core before any extension).

**Total cuts for P4**: P3's + ~10 manifest-format and installer-coordination cuts + new tooling for version pinning. **High effort; non-starter until ICON has multi-implementation choice points.**

---

## 4. Recommended Decomposition (Single Pick)

**Recommendation: P2 — Three-plugin split (`icon-dev` + `icon-pm` + `icon-context`), with a phased migration that lets us back out at any phase.**

### The split

| Plugin | Owns | User-facing tagline |
|---|---|---|
| `icon-dev` | Cluster A (manager + 5 spine sub-agents, task-plan + phase skills, discipline skills, retro+post-incident skills, dependency-mgmt, migration-planning, start-worktree) + Cluster D (writing-skills, agent-evaluation, plugin-design, invoke-sub-project-skill) + Cluster E (using-skills, manager-routing-guide, mcp-tools-first, setup-mcp-servers, icon-status, ecological-impact) + Cluster F (maintainer-only audit/release/changelog) + `shared/common-constraints.md` | "Multi-agent software development orchestration for Claude Code and Copilot CLI." |
| `icon-pm` | Cluster B (product-manager agent + jira-story + sprint-goals + post-meeting + rfc) | "Story shaping, sprint planning, and design-doc authoring. Requires `icon-dev` for delegation to @researcher/@architect/@planner." |
| `icon-context` | Cluster C (context-specialist agent + researcher agent + all init-* skills + upgrade-repo + context-maintenance + merge-phase-templates + impl skills + detect-tree-position + find-context-template + resolve-repo-context + create-iconrc + context-document-guidelines + context_template/) | "Repo-context initialization, maintenance, and audit. Provides `@context-specialist` and `/icon-init` for any ICON-family plugin." |

### Why this split over alternatives

**Beats P1** because P2 isolates the largest customization surface (`.context/` shape and the init flow) into a plugin that can evolve independently. Consumers who want a different context schema can fork `icon-context` without touching `icon-dev`. The phase-*.md template ownership question is forced into explicit resolution rather than implicit.

**Beats P3** because Cluster D (writing-skills, agent-evaluation, plugin-design) has only one consumer outside the maintainer tree (manager.agent.md:153, single line) and no external demand surfaced in research/04. Pulling D out today is over-anticipation. P3 becomes attractive only after a second plugin in this family wants `writing-skills` for its own authoring discipline.

**Beats P4** because version-pinning machinery is non-existent in the Claude Code / Copilot CLI plugin manifest format today. Building it speculatively is process drag.

### Phased migration path

Each phase is independently shippable; any phase can be the final shape if the next phase's benefit doesn't materialize.

**Phase 1 — Document the split (no code change).** Land a `.context/decisions/NNN-plugin-decomposition.md` ADR establishing P2 as the target and the cluster boundaries above. Add an ADR-008 follow-up noting that the three plugins will each have their own always-loaded budget. No file moves yet. Acceptance: ADR merged, audit briefs reference it. Effort: trivial.

**Phase 2 — Carve `icon-pm` out first (lightest cut).** Cluster B has the cleanest boundary (one agent + 4 skills, all of which the manager explicitly does not route to per `manager-routing-guide/SKILL.md:80`). Create `plugins/icon-pm/` as a sibling directory with its own `.claude-plugin/plugin.json`, `agents/product-manager.agent.md`, `skills/jira-story/`, `skills/sprint-goals/`, `skills/post-meeting/`, `skills/rfc/`. Duplicate `shared/common-constraints.md` and the `.githooks/pre-commit` block that syncs it (single-agent target). Document `icon-pm` as requiring `icon-dev` installed for delegation. Update `datascan-marketplace` to list both. Acceptance: a user can install `icon-dev` only and lose PM, or install both and have the full surface. Effort: low (3-5 days).

**Phase 3 — Resolve the phase-template ownership question.** Before splitting context out, decide where `phase-*.md` templates live. Recommended: phase-*.md templates move to `icon-dev` (the workflow spine owns its templates); `icon-context`'s init flow reads them from `icon-dev` at init time via a documented path convention. This converts the `context_template/context/workflows/task-plan/phase-*.md` files from `icon-context` ownership to `icon-dev` ownership. Coordinate with the existing iconrc gate (only iconrc.json itself stays in `icon-context`'s template). Acceptance: phase template updates ship via `icon-dev` releases without requiring `icon-context` bumps. Effort: low (2-3 days, mostly file moves + hook edits).

**Phase 4 — Carve `icon-context` out.** With phase templates relocated, `icon-context` can ship as a standalone extension. Move Cluster C agents, skills, `context_template/` (minus what Phase 3 relocated), iconrc.json gate, and dead-ref resolver scope-relevant code to `plugins/icon-context/`. Document `icon-dev` as recommending `icon-context` for full functionality (Session Start `resolve-repo-context`, retro Stage 2 `@context-specialist`). Without `icon-context`, manager falls back to "no context available, proceed with manifest inference" (which it already supports per `manager.agent.md:94-96`). Acceptance: `icon-dev` works standalone for simple repos; `icon-dev + icon-context` provides full orchestration. Effort: medium (1-2 weeks).

**Phase 5 — Reconcile cross-plugin tooling.** Pre-commit hook duplication, script-parity gate cross-plugin variant, dead-ref resolver cross-plugin scope, version pinning for the recommended dependency edge. Either accept some duplication as the cost of the split, or build minimal cross-plugin tooling. Acceptance: each plugin's pre-commit hook validates its own invariants without needing a sibling plugin installed. Effort: low-medium (5-7 days).

### Risks

| Risk | Mitigation | Rollback story |
|---|---|---|
| Phase template ownership in Phase 3 leaks user-visible behavior change (a customer's local `phase-*.md` overrides stop being picked up) | Phase 3 does not change the override resolution rule (`.context/workflows/task-plan/phase-*.md` at the consumer's project root). Only the source-of-truth-for-init changes from `context_template/` to `icon-dev/`. | If breakage surfaces: move templates back to `context_template/`, document the dual-source resolution as the "transitional" shape, defer the split. |
| `using-skills` and common-constraints duplication drift between plugins | Mechanically check byte-equality of common-constraints across all plugins at release time (CI check, not pre-commit). | Re-merge into one plugin if drift becomes unmanageable. |
| Manager session word budget per ADR-008 exceeds 8,500 when split causes `icon-dev` to absorb Cluster E entirely (common-constraints + using-skills count against budget) | The split does not change the always-loaded composition for the manager session — `icon-dev` still ships manager.agent.md + using-skills + common-constraints. Budget is unaffected. | (No budget change expected.) |
| Documentation/example skew: cross-plugin examples in `icon-pm` reference `@researcher` from `icon-dev` and a user installs only `icon-pm` | Document the dependency explicitly in `icon-pm` README. PM agent's GATE RULE already raises a hard block when sub-agents are required but unavailable — natural failure mode. | If users frequently install pm without dev, advise via README. |
| Marketplace listing must enumerate 3 plugins and order them | `datascan-marketplace` already supports multi-plugin marketplaces (the brief's §5 confirms "Claude Code supports multi-plugin marketplaces"). | Single-plugin listing remains valid for a unified-install option. |
| Mid-migration: Phase 2 ships, Phase 3 doesn't, leaving the project in a P1.5 state | Each phase is independently shippable — P1.5 (= P1 effectively) is a valid resting state. | Resting at P1.5 is fine. |

### Coupling-edge minimization argument

The Cluster A↔C edge is the heaviest (manager Session Start + retro Stage 2 + phase-template ownership). P2 makes this edge explicit and gives it a name (`icon-dev` depends on `icon-context` for full orchestration; degrades gracefully without it). P1 hides the edge inside one plugin but doesn't resolve the phase-template ownership ambiguity; P3 and P4 add cuts (toolkit / core extraction) without paying down the A↔C edge any further. P2 is the smallest split that forces the A↔C resolution.

The Cluster B→A edge is one-way (PM delegates to A sub-agents; A never invokes PM per `manager-routing-guide/SKILL.md:80`). Splitting B out costs nothing structural and clarifies the unique-direction nature of the dependency.

The audience-clarity argument: `icon-dev`'s user is "I want multi-agent software development." `icon-pm`'s user is "I want to write Jira stories and sprint goals from codebase research." `icon-context`'s user is "I want my repo to have rich .context/ documentation that any ICON-family agent can use." These three audiences are real and distinguishable today.

---

## 5. Compatibility Layer Considerations

### Plugin marketplace structure

Claude Code's plugin format supports multi-plugin marketplaces (research from `.claude-plugin/plugin.json:1-18` shows the standard single-plugin shape, but the `datascan-marketplace` listing already pre-supposes a multi-plugin structure since it can list ICON alongside other plugins). The recommended structure for P2:

- One marketplace: `datascan-marketplace`.
- Three plugins under it: `icon-dev`, `icon-pm`, `icon-context`.
- Marketplace metadata declares them all; the user can `/plugin install icon-dev`, `/plugin install icon-pm`, `/plugin install icon-context` independently, or use a meta-package shortcut like `/plugin install icon-suite` that pulls all three.

The alternative — three separate marketplaces — is rejected. It fragments discovery and complicates `/plugin update` semantics.

### Shared resources

Three shared resources matter: `using-skills`, `manager-routing-guide`, `shared/common-constraints.md`.

| Resource | Recommended home | Cross-plugin pattern |
|---|---|---|
| `using-skills/SKILL.md` | `icon-dev` (canonical) | `icon-pm` and `icon-context` reference it by name; each plugin's agent files inline the cue (`product-manager.agent.md:14`, `context-specialist.agent.md` n/a — sub-agents don't always-load). |
| `manager-routing-guide/SKILL.md` | `icon-dev` (manager owns it) | Other plugins do not need it; it is manager-internal. |
| `shared/common-constraints.md` | `icon-dev` (canonical) | `icon-pm` and `icon-context` each ship a duplicate; release-time CI gate checks byte-equality across all three. |

The duplication of common-constraints is the cost of the split. The 21-line block is small; release-time checking is cheap. Avoid the alternative ("each plugin reads from a sibling plugin's path") because plugin install paths are runtime-resolved and may differ across Claude Code and Copilot CLI.

### Version pinning

The Claude Code plugin manifest format does not currently support a `dependencies` field with version constraints. Until it does, dependency expression is documentation-only:

- `icon-pm` README states "Requires `icon-dev` v1.x.x or later."
- `icon-context` README states "Recommended companion to `icon-dev`; works standalone but degrades gracefully."
- Release-time CI checks that the inter-plugin contracts are intact (common-constraints byte-equality, shared skill reference resolution).

If Claude Code/Copilot CLI adds dependency declarations to the manifest format, adopt them at that point. Do not block the split waiting for it.

### The "ICON" identity question

**Recommendation: "ICON" remains the umbrella identity (the marketplace meta-name, the conceptual project name) but no single plugin is "ICON-the-plugin" anymore.** The three plugins are `icon-dev`, `icon-pm`, `icon-context`. The user installs one or more; the marketplace listing groups them under "ICON Suite" or similar.

Alternative: keep `ICON` as the name of the `icon-dev` plugin (since it's the largest and contains the manager, the historical center of gravity), and `icon-pm` / `icon-context` are extensions. This is more conservative but bakes the historical asymmetry into the new shape. The recommendation above is the cleaner reset.

Either way, the "ICON" wordmark survives. The plugin.json `description` field changes from "ICON (Independent Context Orchestration Network) — A project-agnostic multi-agent orchestration system. Includes manager, planner, architect, coder, tester, reviewer, researcher, context-specialist, and product-manager agents…" (current at `.claude-plugin/plugin.json:4`) to a per-plugin statement of scope.

### Carry-forward considerations from ADRs

- **ADR-004 (tool-agnostic)**: All three new plugins inherit the tool-agnostic mandate. The M-U-NET1 ecological-impact Copilot-coupling violation (in `icon-dev` per the split) is unchanged; the split does not solve or worsen it.
- **ADR-008 (always-loaded budget)**: Each plugin's user-invocable agent session gets its own budget. `icon-dev` (manager session) inherits the 8,500-word ceiling. `icon-pm` (product-manager session) inherits the 7,000-word ceiling. `icon-context` has no user-invocable agent — no session budget applies. Quantified per-domain reduction:
  - Manager session before split: 8,062 words baseline (manager.agent.md + 9×common-constraints + using-skills).
  - Manager session after split: 8,062 - 270 (PM's contribution to "9 inlined" goes to icon-pm) - 130 (context-specialist's contribution goes to icon-context) - 145 (researcher's contribution goes to icon-context) = ~7,517 words. Note: this is misleading because the 9×354-word inlined common-constraints are budgeted per-session, and the manager session doesn't load all 9 anyway (only manager.agent.md is loaded by the manager session; the other 8 inlined blocks live in sub-agent files that are loaded only on dispatch). The 8,062 baseline measures the manager's own load, not all 9 agent files together. The split does not reduce the manager session at all if the same files load.
  - **Correction**: ADR-008's snapshot lists "Nine inlined copies of shared/common-constraints.md (one per dispatched agent, synced by `.githooks/pre-commit`)" in the always-loaded inventory. Re-reading: the 9-copy count is what's at-risk in the repo, not what's always-loaded into a single session. The session loads the front-of-session agent file (manager *or* PM) and `using-skills`. The split has no impact on the always-loaded session size for either dispatcher.
- **ADR-010 (carry-forward registry)**: Irrelevant to this brief per the brief's own statement.

---

## 6. Open Questions for the User

Six user-decision points the maintainer must resolve before any split could proceed.

1. **Is the audience for `icon-pm` and `icon-context` real today?** Concretely: do any current ICON consumers want PM features but not dev features (or vice versa)? If the answer is "no, everyone wants the full suite," P2 adds marketplace complexity without unlocking adoption. **Pick one**: (a) yes, three audiences are real today; (b) no, consolidated install is fine; (c) defer until first explicit ask.

2. **Where do `phase-*.md` workflow templates belong in P2?** **Pick one**: (a) phase templates move to `icon-dev` (workflow owns its templates; `icon-context`'s init flow reads them from `icon-dev`); (b) phase templates stay in `icon-context`'s `context_template/` (init flow owns what it ships; `icon-dev`'s workflow spine documents the minimum `icon-context` version); (c) keep `icon-context` and `icon-dev` together (rejects P2 for this reason; falls back to P1).

3. **How should `common-constraints` be shared across plugins?** **Pick one**: (a) duplicate the 21-line file into each plugin, byte-equality gated by release-time CI; (b) introduce a fourth plugin `icon-core` holding common-constraints + using-skills only (P4-shape); (c) keep all common-constraints work in `icon-dev` and other plugins reference it via a documented path convention (fragile across runtimes).

4. **Does "ICON" survive as a plugin name, or only as a marketplace/suite name?** **Pick one**: (a) Marketplace = "ICON Suite"; plugins are `icon-dev`, `icon-pm`, `icon-context` with no plugin literally named "ICON" (clean reset); (b) `icon-dev` keeps the "ICON" plugin name (`pm` and `context` are extensions of "ICON"); (c) Defer naming until after the split's structural shape is settled.

5. **Should the existing `ecological-impact` Copilot-product coupling (M-U-NET1) be fixed before, during, or after the split?** **Pick one**: (a) fix first — clean it up in `icon-dev` before splitting (so the split doesn't carry the violation forward unchanged); (b) fix as part of Phase 4 (`icon-context` carve-out is the structural change; bundle the cleanup); (c) defer to a separate task — split is unrelated to the violation.

6. **What's the rollback story for users who installed `icon-pm` and `icon-context` separately if we decide to re-merge?** **Pick one**: (a) ship a meta-install (`/plugin install icon-suite`) from day one so a future merge is invisible to consumers; (b) accept that re-merge requires consumers to uninstall the sub-plugins and install the unified one; (c) commit to never re-merging once split.

---

## Appendix — Forward-looking decision: "keep as one plugin" is also valid

Per the brief's forward-looking mandate, the analysis is required to produce a substantive decomposition proposal even if the current single-plugin shape is optimal. The P2 recommendation above is the recommended decomposition **if a split happens**. The honest answer to "should it happen?" is **probably not yet**: the audit findings in research/01–06 are uniformly Minor or improvement-opportunities, the always-loaded budget is in compliance per ADR-008, and the heaviest cross-cluster edge (A↔C) is structurally sound today. The cuts P2 forces (phase-template ownership, common-constraints duplication, cross-plugin sub-agent dispatch) are real coordination costs paid against a benefit (audience-clarity, customizable context init) that has no explicit user demand documented in any prior task or retro.

The dependency map and cuts above are the work product that becomes load-bearing **if** a future task (a customer fork, a non-ICON consumer of `writing-skills`, a marketplace-level reorganization) demands the split. Until then, P1 (no split — explicit acknowledgement that we considered it) or "Phase 1 only" (land the ADR documenting the cluster boundaries, defer the carve) are both legitimate resting states.
