# Related Section (graph seam)

This file is the **single authority** for two things: the `## Related` seam and the ADR supersede bold-fields, together with the escape-hatch markers that opt a region out of the graph checks. Generators (`context-specialist-impl-leaf`, `context-specialist-impl-root`), `context-maintenance`, `upgrade-repo`, and `decisions/README.md` reference it by name rather than restating it.

The `.context/` knowledge graph (`context-maintenance § context-graph`) is built from edge signals already present in the document format. Two are **authored seams** — where the author records a relationship the graph would otherwise miss (a by-name prose mention, or a `domains/` file nothing links to).

## The `## Related` block (content docs)

Every **content doc** — a file under `domains/`, `standards/`, `workflows/`, `architecture/`, `testing/`, or `styling/` — should end with a `## Related` section listing its cross-references as bulleted Markdown links:

```markdown
## Related

- Extends: [naming conventions](../standards/naming-conventions.md)
- See also: [payments domain](../domains/payments.md)
- Governed by: [ADR-004 tool-agnostic content](../decisions/004-tool-agnostic-content.md)
```

Rules:

- **Placement is fixed: the LAST `## ` section of the doc.** Generators and tooling locate it deterministically there.
- **Format: a bulleted list of `label: [text](path)` links.** The path is relative to the doc's own directory and must resolve under `.context/`.
- **The graph keys on the LINK only.** Every `## Related` link is a `references` edge (the CLOSED edge set is unchanged). The relation label (`Extends:`, `See also:`, `Governed by:`, …) is **free-text documentation for humans**, not graph vocabulary — use whatever reads clearly.
- **It is a navigational footer, not a second topic** — like a folder-README index table or a `rules-index` row. It does **not** violate one-facet-per-file, and it is **excluded from the folder-split gate (2)** section count. Its bytes still count toward gate (1).
- **Purpose:** convert a by-name prose mention (`` `domains/auth.md` ``, "the auth pattern in domains/auth") into an explicit link, and give every `domains/` file a curated out-edge set so no content doc is a silent orphan.

## ADR supersede bold-fields (`decisions/NNN-*.md`)

ADRs extend their existing bold-field metadata idiom (`**Date**:`, `**Status**:`) with two machine-readable supersede fields:

```markdown
# ADR-012: …
**Date**: 2026-07-17
**Status**: Accepted
**Supersedes**: none            <!-- or: ADR-006 -->
```

```markdown
# ADR-006: …
**Status**: Superseded by ADR-012
**Superseded-by**: ADR-012      <!-- machine-readable mirror of the Status prose -->
```

- **`**Supersedes**`** and **`**Superseded-by**`** are bold-fields, not frontmatter — consistent with today's ADR format.
- **Value is `ADR-NNN`** (which maps deterministically to `decisions/NNN-*.md`) **or `none`.**
- `**Superseded-by**` is the parseable mirror of the human `**Status**: Superseded by …` prose; keep the `**Status**` line for humans.
- **ADR cross-references live in these bold-fields + plain prose — an ADR does NOT get a `## Related` footer (ICON-0081 F1, ICON-0084).** Record supersede relationships in the `**Supersedes**` / `**Superseded-by**` fields above, and reference any OTHER ADR in plain prose as `ADR-NNN` (which maps to `decisions/NNN-*.md`). The `## Related` footer seam is for **content docs only** (`domains/`, `standards/`, `workflows/`, `architecture/`, `testing/`, `styling/`) — do not append one to an ADR.
- **Scope-supersede (partial): note the scope in BOTH fields, leave the old Decision prose intact (ICON-0085).** When a new ADR resolves only a PRIOR ADR's specific *sub*-decision, set `**Supersedes**: ADR-NNN (<scope> only — the remainder stands)` on the new ADR and `**Superseded-by**: ADR-MMM (<scope> only)` on the old — the scope note in both directions. Do **not** mutate the partially-superseded ADR's `**Status**`/Decision prose; it stays as the historical record of what was originally decided.

## Escape-hatch markers (use sparingly)

These are **opt-outs, not general escape hatches** — use them only for a genuine, intentional gap, and prefer fixing the underlying link:

- **Intentionally-dangling ref** (a link to a doc a follow-up will add): wrap the region in the existing pre-commit marker family — `<!-- pre-commit:dead-ref-ok-start -->` … `<!-- pre-commit:dead-ref-ok-end -->`. The graph honors it for the dangling-ref check.
- **Intentional orphan** (a stub doc deliberately not linked yet): place a file-level `<!-- context-graph:orphan-ok -->` comment in the doc to exclude it from the orphan check.

> **Authoring caveat — an illustrative link is still a real edge (ICON-0081).** An *example* Markdown link (`[text](path)`) written **anywhere** in a `.context/` content doc — even prose merely showing what a link looks like — is parsed by `context-graph` as a genuine `references` edge, and a target that doesn't resolve under `.context/` is flagged as dangling by `--check` and the pre-commit gate. To show an example link without minting an edge, wrap it in a `<!-- pre-commit:dead-ref-ok-start -->` … `<!-- pre-commit:dead-ref-ok-end -->` region, or drop the link syntax (e.g. `` `path/to/doc.md` `` in backticks).
