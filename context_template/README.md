# Context Template for AI-Assisted Development

## Purpose

Templates for creating `.context/` documentation in software projects. The `.context/` directory serves as a knowledge base for both human developers and AI agents, capturing project-specific patterns, standards, and decisions that aren't obvious from the code alone.

This approach is tool-agnostic — it works with any AI coding tool that can read files (GitHub Copilot CLI, VS Code + Copilot, IntelliJ + Copilot, Claude Code, Cursor, etc.).

## Quick Setup

Run `/icon-init` to automatically generate `.context/` for your project — it detects your repo type and runs the right initializer:

```
/icon-init
```

Or set up manually:

```bash
cp -r /path/to/context_template/context /path/to/your-project/.context
# Edit files to replace placeholders with project-specific content
```

## Structure

```
context/
├── META.md              # How to maintain .context/
├── iconrc.json          # Repo-level config (task ID prefix, version, etc.)
├── overview.md          # Project overview, tech stack, architecture
├── decisions/           # Key architectural decisions and rationale (one ADR per file)
├── retrospectives.md    # Rolling log of lessons learned (last 10)
├── architecture/        # System design, module structure, patterns
├── domains/             # Domain docs: business (payments, loans) and technical (routing, state-management)
├── standards/           # Coding conventions, style, error handling
├── styling/             # UI/CSS conventions (if applicable)
├── testing/             # Test patterns, mocking strategies, coverage
├── tasks/               # Ephemeral per-task execution plans (prunable)
├── workflows/           # Persistent process docs: CI/CD, branching, deployment
└── .gitignore           # Ignore task scratch files, generated artifacts
```

**tasks/ vs workflows/**: Tasks are ephemeral (per-task plans, pruned after ~3 months). Workflows are persistent (CI/CD, branching strategy, deployment procedures).

## Key Concepts

**Document what's non-obvious**: Patterns not clear from code alone, the "why" behind decisions, common pitfalls, and real examples with file paths. Skip language basics, framework docs, and obvious patterns.

**Separation of concerns**: `.claude/claude.md` (or `.github/copilot-instructions.md` for legacy setups) provides the big picture (project overview, tech stack, key commands). `.context/` provides detailed, area-specific knowledge (domain models, coding standards, test strategies). Don't duplicate between them.

**Retrospective system**: At task completion, lessons are logged in `retrospectives.md` and promoted to the appropriate subdirectory. This keeps documentation current through normal workflow rather than separate maintenance efforts.

**Context recovery**: When AI context windows compact, agents re-read `.context/` files to restore working context. See `context/META.md` for the protocol.

## Maintenance

See `context/META.md` for the full maintenance guide. The retrospective system handles most updates automatically. Periodic human review catches what automation misses.
