# Audit — Phase 3: Improvement Opportunities

## Overview

Positive-design suggestions that surface even when no structural or consistency defects are found. **A "no issues found" result is unacceptable; produce at least 3 improvement opportunities every run.** Plugins evolve; there is always headroom for token economy, discoverability, or operational hygiene.

This phase is heuristic, not prescriptive — surface the opportunity and let the user decide.

## Heuristics

Walk the list and produce at least one suggestion per applicable category. Skip categories that don't apply (e.g. no `hooks/` directory).

1. **Skill table organization** — does `README.md` group skills into user-invocable vs internal sections? Plugins with > 5 skills benefit from the split. Pure-internal plugins (no `user-invocable: true` skills) can collapse to a single table.
2. **Token economy on always-loaded surfaces** — measure the byte size of every `agents/*.agent.md` and any `shared/common-constraints.md`-equivalent file. Files loaded on every agent invocation should stay small (rough target: < 8 KB each). Suggest extractions when one is bloated.
3. **Mandatory-entry skill** — does the plugin have a `using-skills`-style skill that fires at the start of every task to force catalog consultation? Plugins without one tend to accumulate skills that are never invoked. Suggest adding one (or wiring the existing one into an agent's Session Start).
4. **Retrospective-wisdom automation** — is there a mechanism (skill, script, or documented manual step) for promoting recurring retrospective lessons to standards? Without one, retros become write-only and the same lessons repeat.
5. **CHANGELOG hygiene** — sample 5 entries from `## [Unreleased]` and the most recent released version. Suggest improvements when:
   - Entries lack a ticket/issue ID at the end.
   - Entries are multi-sentence (split into atomic entries).
   - Entries contain fenced code blocks (move to docs, link from changelog).
   - Entries use vague verbs ("updated", "improved") without naming what changed.
6. **Pre-commit / CI hooks** — does the plugin enforce structural invariants automatically? Suggest a pre-commit hook when:
   - Multiple files must stay byte-equal (e.g. shared snippets duplicated across agents).
   - References to other plugin files must resolve (dead-ref class).
   - Frontmatter must be valid (otherwise the loader silently drops the file).
7. **MCP server bundling** — does the plugin ship MCP servers? If so, is there a dedicated setup skill walking the consumer through credential setup? Bundling MCP servers without a setup skill leaves consumers to reverse-engineer the requirements.
8. **Frontmatter description quality** — even when descriptions pass the Phase 2 boilerplate check, are they written so `using-skills`-style auto-invocation picks them up? Descriptions that start "Use when…" with concrete triggers outperform abstract one-liners.

## Output Shape

Present the opportunities as a flat list, no severity assigned. Group by heuristic category for readability:

```
## Improvement Opportunities

### Skill table organization
- <suggestion 1>

### Token economy
- <suggestion 2>

### Mandatory-entry skill
- <suggestion 3>

…
```

If a category surfaces no suggestion, omit the heading. Always produce at least 3 suggestions in total across all categories.
