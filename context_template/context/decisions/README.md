# Architecture Decision Records (ADRs)

This folder tracks significant architectural decisions made for this project. Each ADR captures the context, the decision, and its trade-offs so future contributors do not relitigate the same trade-offs from scratch.

One ADR per file, numbered sequentially: `NNN-kebab-slug.md`. ADR numbers are immutable once assigned; superseded ADRs stay in place with their status updated.

## Template

```markdown
# ADR-NNN: Title

**Date**: YYYY-MM-DD
**Status**: Accepted | Superseded by ADR-XXX | Deprecated
**Supersedes**: none            <!-- or ADR-XXX when this ADR replaces an earlier one -->
**Superseded-by**: none         <!-- set to ADR-YYY when a later ADR replaces this one -->

## Context
What problem prompted this decision?

## Decision
What did we choose?

## Consequences
What is now easier or harder as a result?

## Alternatives Considered
What did we reject and why?
```

### Supersede bold-fields

`**Supersedes**` and `**Superseded-by**` are machine-readable mirrors of the human `**Status**` line — they let the `.context/` knowledge graph key the supersede relationship deterministically. Each value is `ADR-NNN` (mapping to `decisions/NNN-*.md`) or `none`. When ADR-YYY supersedes ADR-XXX, set `**Superseded-by**: ADR-YYY` on ADR-XXX and `**Supersedes**: ADR-XXX` on ADR-YYY, and keep the `**Status**` prose in sync. See `context-document-guidelines § Related Section (graph seam)` for the full convention.

## Decision Log

<!-- pre-commit:dead-ref-ok-start -->
Each row links to its ADR file, e.g. `| [001](001-some-decision.md) | Decision title | Accepted | 2026-01-01 |`. The placeholder row below is intentionally plain text — replace it with linked entries as ADRs are added.
<!-- pre-commit:dead-ref-ok-end -->

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| 001 | _Example ADR title_ | Accepted | YYYY-MM-DD |
