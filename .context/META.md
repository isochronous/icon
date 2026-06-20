# META - .context Directory Maintenance Guide

## Purpose

This document explains when and how to update `.context/` documentation for this repo. The goal is a living knowledge base that captures what AI agents and developers need to know beyond what's obvious from the code itself.

This repo is a pure-content plugin (markdown + JSON + a single Node.js hook wrapper). `iconrc.json` excludes `architecture/`, `testing/`, and `styling/` because there is no compile step, no test runner, and no UI to style. Those directories will not appear in this repo.

## Separation of Concerns

`.claude/claude.md` and `.context/` serve different roles — avoid duplicating content between them.

| | `.claude/claude.md` (or `.github/copilot-instructions.md`) | `.context/` |
|---|---|---|
| **Scope** | Big picture | Detailed, area-specific |
| **Content** | Plugin overview, key directories, top-level conventions | Skill-system mechanics, GitHub-access rules, plugin-authoring standards, ADRs |
| **Size** | Short (one file, quick to scan) | Structured (many files, read as needed) |
| **Example** | "ICON is a pure-content plugin; the version lives in `.claude-plugin/plugin.json`" | Detailed `gh`-CLI GitHub-access notes in `domains/github-access.md` |
| **Example** | "Skills live under `skills/<name>/SKILL.md`" | Detailed thin-router, invisible-skill, and distribution-layout rules in `standards/skill-decomposition.md` |

When updating documentation, ask: is this a project-wide fact or convention? → `.claude/claude.md`. Is this detailed guidance for a specific area? → `.context/`.

## When to Update

Update documentation when:

1. **New patterns emerge**: A pattern used successfully 3+ times should be documented in `standards/` with real examples and guidance on when to use it.
2. **Standards evolve**: Team agrees on new conventions. Update the relevant file in `standards/`, mark old conventions as deprecated, and provide migration examples.
3. **Decisions are made**: A significant project-wide decision is reached. Record it as a new ADR file under `decisions/` and add a row to `decisions/README.md`.
4. **Lessons learned**: Retrospective identifies reusable insights. Promote from `retrospectives.md` to the appropriate subdirectory. See the [Retrospective Mechanism](#retrospective-mechanism) section.
5. **AI agents make repeated mistakes**: Clarify the problematic area with explicit examples. Add "do this / not this" guidance to the relevant file.
6. **Onboarding friction**: New developers or agents struggle with a concept. Expand explanations and include more examples.
7. **Working in an undocumented domain area**: When code touches a domain not yet covered in `domains/`, create a file for that domain. ICON's current domains are technical (skill system, MCP servers, plugin resource paths); new categories are added as the plugin grows.

## What to Document

**Document (high value):**
- Non-obvious patterns that aren't clear from code alone
- The "why" behind architectural decisions (rationale and trade-offs)
- Common pitfalls with solutions
- Real examples with file paths (e.g., "see `src/features/auth/login.component.ts` lines 45-67")
- Migration paths between old and new patterns

**Skip (low value):**
- Language basics and standard features
- Content already in official framework documentation
- Patterns obvious from reading the code
- Duplicated content — link to the single source of truth instead

## Retrospective Mechanism

The retrospective system ensures lessons outlive individual tasks:

1. **At task completion**, the manager first reconciles `plan.md` against the final state (step 0 of completion — see `workflows/task-plan/phase-completion.md § Reconcile plan.md`), then invokes the `task-retrospective` skill. The reconciled plan is the input the retro reads from.
2. **Lessons are logged** in `retrospectives.md` as a rolling log (last 10 entries; cap enforced by `append-retrospective-entry`'s `ENTRY_CAP`) via that script — never by hand.
3. **Lessons are promoted** to the appropriate subdirectory once they have generalized:
   - Coding/process patterns → `standards/`
   - Decisions worth preserving → new ADR file under `decisions/` (also add a row to `decisions/README.md`)
   - Domain clarifications → `domains/`
   - Workflow refinements → `workflows/`
4. **The rolling log** gives agents a quick-reference of recent lessons without reading every subdirectory.

## Directory Structure

```
.context/
├── META.md              # This file — maintenance guide
├── overview.md          # Project overview, tech stack, key concepts
├── decisions/           # Key project-wide decisions and rationale (ADRs) — one file per ADR + README index
├── retrospectives.md    # Rolling log of lessons learned (last 10)
├── iconrc.json          # ICON config (repo type, task ID prefix, excludes, cache TTL)
├── cache/               # Research reference docs cached by @researcher (TTL from iconrc, default 30 days)
├── domains/             # Domain docs (technical and/or business)
├── standards/           # Coding conventions, plugin-authoring rules
├── tasks/               # Ephemeral task execution plans (auto-pruned after 90 days on main)
└── workflows/           # Persistent process docs: branching, commit conventions, changelog
```

**tasks/ vs workflows/**: Tasks are ephemeral (per-task execution plans, pruned after 90 days by `workflows/prune-context.sh`). Workflows are persistent (branching, commit conventions, changelog flow).

## Quality Standards

Documentation should be: **accurate** (correct and current), **specific** (concrete guidance, not vague), **example-driven** (real code and file paths), **contextual** (explains why, not just what), and **non-duplicated** (single source of truth, link elsewhere).

## Maintenance

**After major tasks**: Review and update documentation affected by the work. Promote lessons from `retrospectives.md`. Mark deprecated patterns.

**Periodically**: Read through `.context/` files. Remove outdated content. Consolidate duplicates. Verify code examples still work and file paths still exist.

**Warning signs that docs need attention**: Developers or agents ask questions already answered in docs. New patterns go undocumented. Examples reference non-existent files. Agents make the same mistakes repeatedly.

## Context Recovery

When an AI agent's context window compacts mid-task:
1. Re-read the project-wide instructions file (`.claude/claude.md` for Claude Code, `.github/copilot-instructions.md` for Copilot CLI) — always
2. Re-read `.context/` files relevant to the current task
3. Review the task's `.context/tasks/ICON-NNNN-.../plan.md` for status, decisions, and next steps
4. Resume from the documented progress point

---

*This file should be reviewed when the `.context/` structure changes.*
