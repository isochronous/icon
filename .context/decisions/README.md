# Architecture Decision Records (ADRs)

This folder tracks significant architectural decisions made for the ICON plugin repository. Each ADR captures the context, the decision, and its trade-offs so future contributors do not relitigate the same trade-offs from scratch.

One ADR per file, numbered sequentially: `NNN-kebab-slug.md`. ADR numbers are immutable once assigned; superseded ADRs stay in place with their status updated.

## Template

```markdown
# ADR-NNN: Title

**Date**: YYYY-MM-DD
**Status**: Accepted | Superseded by ADR-XXX | Deprecated

## Context
What problem prompted this decision?

## Decision
What did we choose?

## Consequences
What is now easier or harder as a result?

## Alternatives Considered
What did we reject and why?
```

## Decision Log

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [001](001-split-icon-into-own-repo.md) | Split ICON into its own repository | Accepted | 2026-05-13 |
| [002](002-main-only-branch-model.md) | `main`-only branch model | Accepted | 2026-05-13 |
| [003](003-version-source-of-truth.md) | Single source of truth for the version is `.claude-plugin/plugin.json` | Accepted | (predates split) |
| [004](004-tool-agnostic-content.md) | Tool-agnostic content; no runtime-specific code | Accepted | (predates split) |
| [005](005-no-build-step.md) | No build step, no test runner, no package manager | Accepted | (predates split) |
| [006](006-mcp-credentials-placeholders.md) | MCP credentials use `${VAR}` placeholders only — never committed | Superseded (ICON-0080) | 2026-04-06 |
| [007](007-devnull-ban-scope.md) | `2>/dev/null` ban applies to agent-invoked commands only, not to autonomous scripts | Accepted | 2026-05-21 |
| [008](008-always-loaded-token-budget.md) | Always-loaded session token budget for manager and PM dispatchers | Accepted | 2026-05-21 |
| [009](009-skill-description-callers.md) | Skill `description` frontmatter does not enumerate callers | Accepted | 2026-05-22 |
| [010](010-template-promotions-and-carryforward-retier.md) | Phase-template promotions and carry-forward re-tier registry | Accepted | 2026-05-23 |
| [011](011-datascan-production-instance.md) | This repo IS DataScan's production plugin instance | Superseded (ICON-0080) | 2026-06-12 |
