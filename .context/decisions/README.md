# Architecture Decision Records (ADRs)

This folder tracks significant architectural decisions made for the ICON plugin repository. Each ADR captures the context, the decision, and its trade-offs so future contributors do not relitigate the same trade-offs from scratch.

One ADR per file, numbered sequentially: `NNN-kebab-slug.md`. ADR numbers are immutable once assigned; superseded ADRs stay in place with their status updated.

**Correcting a stale ADR.** A record whose *Decision* still holds but whose supporting facts have
decayed is **amended in place** with a dated `## Amendments` entry — not superseded. Supersede only
when the position itself changed; scope-supersede when one sub-decision changed and the rest stands.
The full convention lives in `context-document-guidelines § Correcting a stale ADR`.

## Template

```markdown
# ADR-NNN: Title

**Date**: YYYY-MM-DD
**Status**: Accepted            <!-- or: Superseded by ADR-NNN | Deprecated -->
**Supersedes**: none            <!-- or: ADR-NNN -->
**Superseded-by**: none         <!-- or: ADR-NNN — machine-readable mirror of Status -->

## Context
What problem prompted this decision?

## Decision
What did we choose?

## Consequences
What is now easier or harder as a result?

## Alternatives Considered
What did we reject and why?

## Amendments
<!-- Omit this section until the first correction. Then it is the LAST section,
     entries in date order:

**YYYY-MM-DD (TASK-ID).** The Decision is unchanged. <what was corrected and why>

- *Section* said "<verbatim quote of the erroneous text>". <What is true, and its source.>
-->
```

`**Supersedes**` / `**Superseded-by**` are machine-readable — `context-graph` builds the ADR
supersede edges from them, so a new ADR needs both fields present even when the value is `none`.
An ADR does **not** get a `## Related` footer; that seam is for content docs. The full convention is
`context-document-guidelines § Related Section (graph seam)`; `## Amendments` placement and entry
format live in its `§ Correcting a stale ADR` section, cited above.

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
| [012](012-context-knowledge-graph.md) | Context knowledge graph — on-demand script, edge seams, fail-closed gate | Accepted | 2026-07-17 |
| [013](013-session-lifecycle-cold-resume.md) | Session lifecycle — phase-per-session cold resume via hardened plan.md | Accepted | 2026-07-17 |
| [014](014-model-aware-delegation.md) | Model-aware delegation — required per-delegation tier | Accepted (inline carve-out superseded by ADR-015) | 2026-07-18 |
| [015](015-all-specialists-isolated.md) | Sub-agent isolation — all specialists dispatched task→report | Accepted | 2026-07-18 |
| [016](016-skill-hot-cold-path.md) | Skill hot path / cold path separation — per-file byte caps | Accepted | 2026-07-27 |
