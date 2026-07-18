# ADR-012: Context knowledge graph — on-demand script, edge seams, fail-closed gate

**Date**: 2026-07-17
**Status**: Accepted
**Supersedes**: none
**Superseded-by**: none

## Context

`.context/` discovery and maintenance both need a transitively-traversable view of the tree, not a flat directory listing. Discovery must reach the full set of related documents a task touches (today the manager browses flatly and consults one `rules-index.md` lookup), and maintenance must catch dangling links, orphaned/unreachable files, and index gaps across the whole tree (today `check-rules-index.sh` covers only the three rule directories). Asking an agent to "mentally build a graph" is non-deterministic — the exact reliability gap this work exists to close.

The edge signals needed for full discoverability already exist in the document format: `rules-index` rows, inline prose Markdown links, ADR supersede prose, folder-index tables, and retrospective promotions. Two of those signals are lossy to parse from prose today: by-name references (`` `domains/hooks.md` ``, "the auth pattern in domains/auth") that keep `domains/` reachable, and ADR supersede links that are forward-only. A deterministic parser can extract the rest.

## Decision

Stand up a deterministic graph over `.context/` at the fuller scope: an on-demand script, two authored edge seams, and a fail-closed enforcement gate.

- **Script (`context-graph.{sh,ps1}`).** A portable, plugin-local script materializes the graph on demand and is never persisted. `--emit` is the read side (a compact path-and-edge adjacency listing to stdout — never file contents — for the manager to seed from and traverse on medium/complex tasks). `--check` is the write side (structural defects: dangling `references`, orphan/unreachable nodes, bad ADR supersede targets), generalizing `check-rules-index.sh`'s forward+backward checks from the three rule directories to the whole tree. `--check` **delegates** rule-index completeness to `check-rules-index.sh` rather than reimplementing it, and honors ADR-005 (committed source run in-place) and ADR-004 (bash + PowerShell parity).
- **Edge seams.** Only the lossy edges become first-class, human-authorable seams: a trailing `## Related` links section on content docs (converts by-name prose mentions into explicit `references` links and gives every `domains/` file a curated out-edge set), and `**Supersedes**` / `**Superseded-by**` bold-fields on ADRs (a bidirectional, unambiguous mirror of the `**Status**` prose, keyed `ADR-NNN` → `decisions/NNN-*.md`). No YAML frontmatter is introduced and the `rules-index` table is not extended — the seams stay inside the existing Markdown-and-bold-field idiom. `context-document-guidelines` is the single authority for both seams. This record dogfoods the ADR bold-fields above.
- **Fail-closed gate.** `context-graph.sh --check` runs as a fail-closed `.githooks/pre-commit` gate (ICON-repo-local) with a three-value exit contract — `0` clean / `1` violations found / `2` parser or environment error (including zero nodes discovered on a non-empty tree) — where **any non-zero blocks the commit**. Invocation mirrors the existing `check-rules-index` call (`bash "$script" "$root" || exit 1`), never an `if script` guard that would swallow exit 2. This closes the ICON-0075 fail-OPEN class. The gate is triggered only when `.context/` or `context_template/context/` files are staged, and owns an edge set disjoint from the two existing gates (`check-rules-index.sh` and the pre-commit `.context/` dead-ref resolver), which are left unchanged.

## Consequences

**Positive:**
- Deterministic where it matters (parsing, validation) and cheap where the token budget is tight (on-demand, not always-loaded — the manager gains only a pointer + trigger, ADR-008-safe).
- Maintenance catches dangling refs, orphans, and index gaps across the whole tree, not just the rule directories.
- The two seams give `domains/` reachability and bidirectional ADR supersede edges without new parse surfaces or a `rules-index` overload.
- Reuses and generalizes the existing `check-rules-index.sh` pattern rather than inventing a parallel one; the exit-code contract structurally prevents the fail-OPEN class.

**Negative:**
- The seams are a consumer-shipping format change, so `context_template/` scaffold docs demonstrate them and `context_template/context/iconrc.json` bumps `1.8 → 1.9`; `context-specialist-impl-leaf` and `-impl-root` must emit the seams on create.
- By-name prose refs written without a `## Related` link remain unparseable — the thin procedural layer keeps light semantic linking as the agent's job.
- ICON's own `.context/` must pass the fail-closed gate, so minimum-to-green backfill (resolving the orphans and dangling refs the gate blocks) is required; exhaustive `## Related` curation is a follow-up.
- `.githooks/` does not ship to consumers, so the gate is ICON-repo-only — consumers receive the script and maintenance wiring and run `--check` at maintenance time, never blocked at their own commit.

## Alternatives Considered

1. **Procedural-only (agent mentally builds the graph):** rejected — non-deterministic (the exact failure this work closes), and its always-loaded instructions would sit in the manager surface ADR-008 most tightly budgets.
2. **Defer the format seams (script-only v1):** rejected in favor of shipping the seams now — the lossy by-name and ADR-supersede edges are the ones that keep `domains/` reachable, and deferring leaves silent orphans. The node/edge model stays forward-compatible with any future explicit seam.
3. **YAML frontmatter, or extending the `rules-index` table to `domains/`:** rejected — frontmatter adds a second parse surface fighting the human-authorable character of `.context/`; extending `rules-index` would blur the rule-router's purpose and collide with `check-rules-index.sh`'s scope.
