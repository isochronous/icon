# ICON (Independent Context Orchestration Network)

A project-agnostic multi-agent orchestration system for GitHub Copilot and Claude Code, based on the orchestrator pattern.

## Overview

Specialized agents work together to complete development tasks. A **manager** agent orchestrates the workflow, selecting which specialist should act based on task requirements and progress. The system adapts to any tech stack through a `.context/` directory that provides project-specific knowledge.

### Agents

| Agent | Purpose |
|-------|---------|
| `@manager` | Orchestrates workflows, maintains context, delegates to specialists |
| `@planner` | Breaks down features into sequenced, actionable tasks |
| `@architect` | Evaluates architectural decisions, designs module structures, and ensures patterns align with project conventions. |
| `@coder` | Implements features, writes production code, and applies changes following project conventions. |
| `@tester` | Writes and runs tests, validates implementations, and ensures adequate test coverage. |
| `@reviewer` | Reviews code changes for quality, consistency, and adherence to project standards. |
| `@researcher` | Researches up-to-date library documentation, best practices, and standards to bridge training data gaps for technical decision-making. |
| `@context-specialist` | Creates and maintains `.context/` documentation for leaf projects, grouping directories, and monorepo roots |
| `@product-manager` | Creates and refines GitHub issue-style user stories grounded in codebase research, existing stories, and project context. |

### Design Principles

- **Concise definitions**: Agent instructions follow the "earn your place" principle — every line must prevent a concrete mistake or it gets cut. Bloated instructions cause models to ignore them.
- **Tool-agnostic**: Works with GitHub Copilot CLI, VS Code, IntelliJ, or any tool that reads files. No dependency on vendor-specific features.
- **Context through files**: Project knowledge lives in `.context/` — version-controlled, portable, permanent. `.claude/claude.md` provides the big picture; `.context/` provides detailed, area-specific knowledge. No duplication between them. (Legacy repos that haven't migrated can still use `.github/copilot-instructions.md` — the redirect is supported for back-compat.)
- **Retrospective learning**: Lessons from completed tasks are promoted to persistent documentation, keeping `.context/` accurate over time.
- **Verification over reasoning**: Agents must provide evidence (command output) before claiming success. Internal reasoning that something "should work" is not verification.
- **Discipline enforcement**: Common constraints prevent rationalization, enforce self-review before reporting, and escalate persistent failures rather than allowing infinite retry loops.

This repository is the canonical home for ICON. The `isochronous` marketplace listing points here via the movable `latest` git tag — installing ICON from the marketplace resolves to this repo at its most recent stable release.

## What do you want to do?

Quick intent index — pick the row that matches your situation:

| Your intent | Run this | More info |
|-------------|----------|-----------|
| I want to install ICON | `copilot plugin install ...` / `claude plugin install ...` | [Installation](#installation) |
| I want to try ICON in a new repo | `/icon-init` | [Quick Setup](#quick-setup) |
| I'm returning to a repo after a break | `/icon-status` | [Skills](#skills) table — `icon-status` row |
| I'm upgrading an existing ICON repo | `/upgrade-repo` (also auto-dispatched by `/icon-init` when `.context/` already exists) | [Skills](#skills) table — `upgrade-repo` row |
| I want `@manager` to be my default role (Claude Code) | `/ICON:enable-manager-default` | [Default Role (Claude Code only)](#default-role-claude-code-only) |
| I want to switch roles mid-session (Claude Code) | `/ICON:manager` or `/ICON:pm` | [Default Role (Claude Code only)](#default-role-claude-code-only) |
| I'm working in a workspace, monorepo, or multi-module repo | `/icon-init` (auto-detects) | [Multi-Project Workspaces and Monorepos](#multi-project-workspaces-and-monorepos) |
| I want to author a new skill | Invoke `writing-skills` | [Skills](#skills) table — `writing-skills` row |
| I want to know what skills are available | Browse the [Skills](#skills) table | — |

## Installation

There are two equivalent ways to install ICON.

### Option 1: Install via the `isochronous` marketplace (recommended)

The marketplace listing pins ICON to the movable `latest` tag in this repo, so you receive new stable releases automatically on plugin update.

Two steps: first register the marketplace, then install ICON from it.

```bash
# Copilot CLI
copilot plugin marketplace add https://github.com/isochronous/icon-marketplace.git
copilot plugin install ICON@isochronous

# Claude Code
claude plugin marketplace add https://github.com/isochronous/icon-marketplace.git
claude plugin install ICON@isochronous
```

### Option 2: Install this repo directly

```bash
# Copilot CLI
copilot plugin install https://github.com/isochronous/icon.git
# or SSH
copilot plugin install git@github.com:isochronous/icon.git

# Claude Code
claude plugin install https://github.com/isochronous/icon.git
# or SSH
claude plugin install git@github.com:isochronous/icon.git
```

### To update

```bash
# Copilot CLI
copilot plugin update ICON

# Claude Code (update the marketplace index first, then the plugin)
claude plugin marketplace update isochronous
claude plugin update ICON
```

### Default Role (Claude Code only)

The `SessionStart` hook is declared in the plugin's own `hooks/hooks.json` and activates automatically on install — no user-side setup required. Every new Claude Code session launched from an ICON-initialized project (a project with a `.context/` folder) automatically adopts the manager role from turn 1.

Sessions launched from non-ICON projects are unaffected.

To opt out, run:

```
/ICON:disable-manager-default
```

This writes `managerDefault: false` to `~/.claude/icon-user-settings.json`. To re-enable, run `/ICON:enable-manager-default`, which sets `managerDefault: true`.

Mid-session role switching (Claude Code only):

| Command | Effect |
|---------|--------|
| `/ICON:pm` | Switch to the product-manager role for the rest of this session |
| `/ICON:manager` | Switch back to the manager role for the rest of this session |
| `/ICON:disable-manager-default` | Write `managerDefault: false` to `~/.claude/icon-user-settings.json` to opt out of the default |
| `/ICON:enable-manager-default` | Set `managerDefault: true` in `~/.claude/icon-user-settings.json` to re-enable the default |

These are Claude-Code-only conveniences. Copilot CLI users interact with `@manager` and `@product-manager` directly as agents; none of the slash commands above apply.

## Project Context

### `.context/` Directory

The `.context/` directory provides structured project knowledge that agents use to make correct, project-specific decisions. See [context_template/](context_template/) for templates and setup instructions.

```
.context/
├── overview.md           # Project overview, tech stack, architecture
├── META.md               # How to maintain this directory
├── decisions/            # Key architectural decisions and rationale (ADRs — one file per decision)
├── retrospectives.md     # Rolling log of lessons learned
├── architecture/         # System design, patterns, migration guides
├── domains/              # Domain docs: business (payments, loans) and technical (routing, state-management)
├── standards/            # Coding conventions, style, error handling
├── styling/              # UI/CSS conventions (frontend projects)
├── testing/              # Test patterns, mocking strategies, coverage
├── tasks/                # Ephemeral per-task execution plans (prunable)
└── workflows/            # Persistent process docs: CI/CD, branching, deployment
```

### Quick Setup

Run `/icon-init` to automatically generate `.context/` for your project — it detects your repo type and runs the right initializer:

```
/icon-init
```

Or copy from `context_template/context/` and customize manually.

### Skills

Skills provide reusable processes that agents can invoke when needed.

| Skill | Purpose |
|-------|---------|
| `agent-evaluation` | Evaluate agent system designs |
| `context-maintenance` | Keeping `.context/` current: update domains, promote lessons, prune artifacts |
| `create-iconrc` | Use when `.context/iconrc.json` needs to be created or updated — whether initializing a repository for the first time or modifying an existing configuration. Called by all initialize-* skills; also invoke directly when a user requests `.iconrc` creation or reconfiguration. |
| `dependency-management` | Library upgrades, new dependency evaluation, migration planning, version conflict resolution |
| `design-first` | Pre-implementation exploration: propose alternatives, get approval before coding. Covers API design and security threat assessment. |
| `ecological-impact` | Calculate and display the environmental footprint of a Copilot session in Trees Burned and water-usage equivalents, with annual projections |
| `generate-phase-launcher` | Emit a harness-specific per-phase launcher script (`target-harness` ∈ claude-code / copilot-cli / generic) that runs each `plan.md` phase in a fresh, fail-closed session — for headless / cron / CI session-per-phase execution |
| `icon-init` | Recommended first command — auto-detects repo type and dispatches to the correct `/initialize-*` skill, or to `/upgrade-repo` if `.context/` already exists |
| `icon-status` | Display plugin state: active task, current branch, recent retrospectives, and context health |
| `github-issue` | Render content into GitHub issue format |
| `migration-planning` | Four-pattern migration discipline: two-phase deploy, feature flag rollout, schema backfill, and incremental refactor — with named rollback criteria for each |
| `pr-feedback-triage` | Triage open GitHub PR review threads: fetch all unresolved discussions, assess necessity (Blocking / Recommended / Optional), and produce a prioritized resolution plan per thread |
| `plugin-design` | Help build Claude Code plugins from scratch (create mode: scaffold, basic info, repo setup, context init, optional marketplace listing) or audit an existing plugin for structural integrity, cross-file consistency, and improvement opportunities (audit mode hard-requires /icon-init) |
| `post-incident-review` | Structured classify → timeline → root-cause → comms → action-items → retro-append process for production incidents and security near-misses |
| `post-meeting` | Transform meeting transcriptions into structured summaries |
| `rfc` | Create RFCs from scratch or polish rough drafts (ORG-004) |
| `security-review` | Security-review a change to ICON's own hooks/scripts against the `secure-coding` standard before merge |
| `start-worktree` | Isolate agent work in a git worktree when a human developer is actively editing the same repository, preventing branch and file conflicts |
| `systematic-debugging` | 4-phase debugging: reproduce → root-cause trace → defense-in-depth → verify. Includes production incident guidance. |
| `upgrade-repo` | Bring an existing `.context/` up to current spec: audit infrastructure, replace outdated scaffolding files, wire missing hooks |
| `writing-skills` | How to author new skills: TDD-for-skills (RED-GREEN-REFACTOR), pressure-scenario testing, persuasion principles, and Anthropic skill-authoring best practices |

#### Internal Skills

The following skills are internal — they are invoked automatically by agents during normal workflows. Users will not see them in their skill list and should not need to invoke them directly.

| Skill | Purpose |
|-------|---------|
| `characterization-testing` | Write tests that lock existing behavior before modifying legacy code that has no test coverage |
| `code-quality-rules` | Use when conducting a code review and evaluating whether a change meets project quality standards. |
| `commit-discipline` | Atomic commits, meaningful messages, branch hygiene |
| `context-document-guidelines` | Standards for atomic, focused `.context/` files: size heuristics, when to split, naming, and anti-patterns |
| `context-specialist-create` | Handles creation and upgrade of `.context/` directories — detects tree position (via `context-specialist-detect-tree-position`) if not provided, then loads the appropriate impl skill (leaf/branch/root) |
| `context-specialist-detect-tree-position` | Detects tree position (leaf, branch, or root) from filesystem signals when caller has not provided an explicit tree_position |
| `context-specialist-impl-branch` | Branch node context initialization — loaded inline by @context-specialist when tree_position is branch |
| `context-specialist-impl-leaf` | Leaf project context initialization — loaded inline by @context-specialist when tree_position is leaf |
| `context-specialist-impl-root` | Monorepo/workspace root context initialization — loaded inline by @context-specialist when tree_position is root |
| `find-context-template` | Locates the plugin's `context_template/` directory dynamically (used by the `/initialize-*` skills and `/upgrade-repo`) |
| `initialize-monorepo` | Discover all sub-projects in a monorepo, bootstrap each with `initialize-repo` or `upgrade-repo` in isolated sessions, then generate root-level cross-project context |
| `initialize-multimodule` | Use when setting up agent-system context for a multi-module directory for the first time — a parent folder containing multiple independent repos or project folders with no formal monorepo manifest. |
| `initialize-repo` | Exhaustively generate `.context/` for a project (run once per repo) |
| `initialize-workspace` | Parse a VS Code `.code-workspace` file, bootstrap each project folder with `initialize-repo` or `upgrade-repo` in isolated sessions (skipping resource-only folders), then generate workspace-level cross-project context at the first folder |
| `invoke-sub-project-skill` | Use when a manager agent has a skill path from resolve-repo-context and needs to execute that skill against a specific task. |
| `manager-routing-guide` | Routing reference tables, agent capability matrix, and sub-agent context-isolation rules — loaded on-demand when the manager makes a routing decision. |
| `merge-phase-templates` | Migrate custom content from a deprecated `task-workflow-template.md` into the appropriate phase template files so the deprecated file can be deleted |
| `pr-discipline` | Opening pull requests, writing descriptions, addressing review feedback, resolving merge conflicts |
| `resolve-repo-context` | Use when a manager agent needs to determine the correct context root for a task and the repo type is not a plain project — workspaces, monorepos, and multi-module repos all require this resolution before delegating to sub-agents. |
| `task-plan` | plan.md format selection and handoff guidance — defers to local workflow template when present |
| `task-plan-phase-architecture` | Invoke when entering Phase 4 (Architecture Review). Provides decision matrix for @architect consultation, delegation structure, and guidance for capturing architect output. |
| `task-plan-phase-completion` | Invoke when entering completion phases (Phases 6–8). Provides @reviewer delegation structure, context update checklist, retrospective format, and completion summary template. |
| `task-plan-phase-implementation` | Invoke when entering Phase 5 (Implementation). Provides pre-dispatch checklist, @coder delegation structure, deviation handling, and progress tracking. |
| `task-plan-phase-investigation` | Invoke when entering the investigation phase of a task (Phases 1–3). Provides context checklists, @researcher and @planner delegation structures, and investigation exit criteria. |
| `task-plan-phase-testing` | Load when the task's primary concern is tests — fixing failing tests, adding coverage to existing code, or implementing a feature test-first (TDD). |
| `task-retrospective` | Structured retrospective process for task completion |
| `testing-discipline` | TDD process, anti-patterns, mock strategy, and test quality |
| `using-skills` | **MANDATORY** — executed before starting any task. Forces skill invocation and prevents agents from skipping applicable skills. |
| `verification-checklist` | Evidence-based verification gate and self-review process |

## GitHub Integration

ICON is GitHub-only and does not bundle any MCP servers. Agents interact with issues, pull requests, and CI through the GitHub [`gh` CLI](https://cli.github.com/). Authenticate once with `gh auth login`; no plugin-side credential setup is required.

## Workflow

```
User Request → @product-manager (standalone — story creation and refinement)

User Request → @manager → delegates to specialists as needed:

  @planner            → Task breakdown (complex features)
  @architect          → Structure review (major changes)
  @coder              → Implementation
  @tester             → Test creation and execution
  @reviewer           → Code quality review
  @researcher         → External library/API research
  @context-specialist → Creates and maintains .context/ docs (leaf/branch/root)

  → @manager conducts retrospective at task completion
```

The manager reads `.context/` files at the start of each task, delegates work to specialists with relevant context, tracks progress, and promotes lessons learned back to `.context/` when the task completes.

## Multi-Project Workspaces and Monorepos

`@manager` handles all repository types automatically — workspaces, monorepos, and multi-module directories — via the `resolve-repo-context` skill. Start tasks the same way regardless of repo structure.

To bootstrap agent-system context for the first time, run `/icon-init` — it detects your repo type (single project, monorepo, VS Code workspace, or multi-module directory) and dispatches the correct initializer automatically.

## Contributing

When working on ICON itself, configure your local hooks path so the pre-commit invariant gates run before push: `git config core.hooksPath .githooks`. See `CONTRIBUTING.md` for the full workflow.
