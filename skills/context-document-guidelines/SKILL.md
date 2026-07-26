---
name: context-document-guidelines
description: >
  Use when creating or editing a .context/ document, when a .context/ file feels large or covers multiple concerns, or when deciding whether to split a domain file.
user-invocable: false
---

# Context Document Guidelines

## Overview

A `.context/` file should cover exactly one facet of one topic. Loading it for X shouldn't also load unrelated Y.

## When to Use

- Creating a new domain, standards, architecture, or testing file
- Reviewing an existing `.context/` file that has grown large
- Deciding whether to split a file
- After content refresh via `initialize-repo` or `context-maintenance`

## Size Heuristics

These are smell signals, not hard limits.

| Type | Healthy | Review scope |
|------|---------|--------------|
| `domains/` | ~100–200 lines | 300+ lines |
| `standards/` | < 150 lines | 150+ lines |
| `architecture/` | Can be longer (diagrams); still split by concern | — |

A dense 250-line file may be fine. A sparse 100-line file covering two unrelated topics should be split.

When a file exceeds **16,000 bytes** AND has 3+ discrete peer `## ` sections, apply the folder split rule below rather than treating it as a smell signal only.

## When to Split

Split when you see any of these:

- Two or more distinct entity types with no shared lifecycle
- You skip large sections when looking for specific information
- Different agents or tasks consistently need only part of the file
- A section heading could stand alone as a document title
- The file answers more than one of: "how does X work", "what are the rules for Y", "how is Z structured"

When both the bytesize threshold and the logical-split test pass, apply the folder split rule below.

## Folder Split Rule

A `.context/*.md` file that meets **both** of these gates should be converted to a folder:

1. **Bytesize**: the file exceeds **16,000 bytes** (~200 lines × 80 chars). Bytesize rather than line count because long lines (tables, prose) make line count under-represent reading burden.
2. **Logical splittability**: the file contains **≥ 3 peer-level `## ` sections** each representing a discrete topic (not just sub-headings of one narrative).

If gate (1) passes but gate (2) fails (single continuous narrative), note the finding in the maintenance report but do not split.

> **Exclude the `## Related` footer from gate (2).** A trailing `## Related` section (see `## Related Section (graph seam)` below) is a navigational footer, not a discrete topic — do **not** count it toward the "≥ 3 peer-level `## ` sections" tally.

### Folder layout

Convert `<name>.md` → a folder:

```
<name>/
├── README.md          # intro paragraph + index/table linking to topic files
└── <slug>.md          # one file per topic section
```

**Slug naming:**
- Use `kebab-slug.md` for unnumbered topics.
- Use `NNN-kebab-slug.md` (zero-padded, e.g. `001-`) when the source has numbered units (e.g. ADRs with `ADR-NNN:` headers) — the number is immutable once assigned.

**README.md contents:** retain the original intro paragraph and any whole-set preamble; add a table or list linking to each per-topic file.

After splitting, update `.context/` cross-references that pointed at the original file.

If the original file had a row in `.context/rules-index.md`, repoint that row's link at the new `<name>/` folder (or `<name>/README.md`) in the same change — don't leave it pointing at the deleted file.

> For the maintenance-cycle action that triggers this rule — and which task owns the split — see `context-maintenance § File Size Rule`.

### Split Exemptions

The gates above exist to keep **live guidance** findable — breaking a sprawling live doc into topic files helps a reader reach the current rule faster. Two independent arms exempt a file from the gates even when both would otherwise fire — a file need only satisfy one: the file is a **historical record**, or the file is a **distributed template** copy.

#### Historical Record

The gates do not apply to a historical record: an append-only chronological log or a point-in-time snapshot, where entries accumulate in time order and are never restructured. Splitting a record by topic fragments it and destroys the chronology that makes it a record in the first place — the split would make the artifact worse, not better, so the size gate does not apply to it regardless of byte count.

**The test is shape, not readership.** Ask: is the file's organizing axis *time* — entries appended in sequence, never reorganized — or *topic* — sections grouping subject areas, meant to be found and read independently? A chronological record has no topic structure for the gate to split along, so the gate has nothing to act on. A topic-organized guidance doc is exactly what the gate exists to split, because dividing it by subject genuinely improves findability. This holds **regardless of whether the record is also consulted for current guidance** — that question is about readership, and readership is not the axis the test turns on. `.context/retrospectives.md` is the case that proves it: it is skimmed at Session Start to inform current decisions, and it is still exempt, because its shape is a chronological log, not a topic index.

Exempt (chronological logs and point-in-time records): a task's snapshot artifact (e.g. `word-count-snapshot.md`), a closed archive that exists solely to receive overflow from a live file's own pruning mechanism (e.g. `retrospectives-archive.md`), and `.context/retrospectives.md` itself — entries accumulate in date order and are never rewritten or split by topic. (`retrospectives.md` is mutated only via the `append-retrospective-entry` script — `context-maintenance § Tooling` — which is a true and useful authoring warning, but the reason the size gate doesn't govern it is its shape, not that script.)

Not exempt: topic-organized guidance documents — `domains/`, `standards/`, `architecture/`, and any doc whose sections are subject areas rather than dated or sequential entries. These are exactly the files the split rule exists for. A doc does not become chronological merely because some of its sections carry dates — the question is whether the *file* is a sequence of entries or a set of subjects, so a `domains/` file with dated subsections grouped under topic headings is still topic-organized and not exempt.

**Living in `decisions/` does not itself confer the exemption.** An ADR that still carries a live, normative rule is, in shape, a topic-organized guidance doc — an agent reads its Decision/Consequences sections to learn the current rule, not a sequence of dated entries — so the gates apply in full, regardless of its historical framing or of record-keeping language elsewhere that describes `decisions/` as history. A superseded or withdrawn ADR, by contrast, falls under the exemption's *point-in-time snapshot* case: supersession freezes its Decision/Consequences content at that moment, so the file no longer describes a live rule — that frozen state, not who reads it or why, is what makes it exempt under the test above.

#### Distributed Template

The gates do not apply to a **fixed-shape scaffold** distributed by the plugin's template: a file whose section structure is a parse contract rather than consumer content — agents locate what they need by these files' section headings (e.g. `workflows/task-plan/base.md`'s required core sections), so restructuring one breaks the agents that depend on that structure instead of helping any reader. That is a narrower claim than "came from the template." Most template-seeded content — `domains/`, `standards/`, `testing/`, `architecture/`, `styling/` — is **not** exempt under this arm: the consumer replaces the seed with their own conventions, so it diverges from the template by design from day one, and splitting an oversized one is exactly what the gates exist for.

**The test has two parts, both required.** (1) A counterpart exists at the template's matching path. Resolve the template root with the `find-context-template` skill — the same idiom `context-maintenance § Tooling` uses for its own scripts — and check `$TEMPLATE_DIR/context/<same relative path>`; a bare `context_template/` path has no meaning inside an installed consumer repo, so don't test against it directly. (2) The file is one of the fixed-shape scaffolds whose structure is a parse contract, not a content seed the consumer is meant to fill in or replace. Both parts must hold — a template counterpart alone is not enough, which is what keeps the seeded files above out of this arm.

Exempt under this arm (the current scaffold set — verify against the template tree if this list is suspected stale): `workflows/task-plan/base.md` and its `phase-*.md` siblings (`phase-investigation.md`, `phase-architecture.md`, `phase-implementation.md`, `phase-testing.md`, `phase-completion.md`), `META.md`, `overview.md`, and `rules-index.md`.

## Related Section (graph seam)

This section is the **single authority** for the `## Related` seam and the ADR supersede bold-fields. Generators (`context-specialist-impl-leaf`, `context-specialist-impl-root`) and `context-maintenance` reference it by name rather than restating it.

The `.context/` knowledge graph (`context-maintenance § context-graph`) is built from edge signals already present in the document format. Two are **authored seams** — where the author records a relationship the graph would otherwise miss (a by-name prose mention, or a `domains/` file nothing links to).

### The `## Related` block (content docs)

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
- **It is a navigational footer, not a second topic** — like a folder-README index table or a `rules-index` row. It does **not** violate one-facet-per-file, and it is **excluded from the folder-split gate (2)** section count (see `## Folder Split Rule`).
- **Purpose:** convert a by-name prose mention (`` `domains/auth.md` ``, "the auth pattern in domains/auth") into an explicit link, and give every `domains/` file a curated out-edge set so no content doc is a silent orphan.

### ADR supersede bold-fields (`decisions/NNN-*.md`)

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

### Escape-hatch markers (use sparingly)

These are **opt-outs, not general escape hatches** — use them only for a genuine, intentional gap, and prefer fixing the underlying link:

- **Intentionally-dangling ref** (a link to a doc a follow-up will add): wrap the region in the existing pre-commit marker family — `<!-- pre-commit:dead-ref-ok-start -->` … `<!-- pre-commit:dead-ref-ok-end -->`. The graph honors it for the dangling-ref check.
- **Intentional orphan** (a stub doc deliberately not linked yet): place a file-level `<!-- context-graph:orphan-ok -->` comment in the doc to exclude it from the orphan check.

> **Authoring caveat — an illustrative link is still a real edge (ICON-0081).** An *example* Markdown link (`[text](path)`) written **anywhere** in a `.context/` content doc — even prose merely showing what a link looks like — is parsed by `context-graph` as a genuine `references` edge, and a target that doesn't resolve under `.context/` is flagged as dangling by `--check` and the pre-commit gate. To show an example link without minting an edge, wrap it in a `<!-- pre-commit:dead-ref-ok-start -->` … `<!-- pre-commit:dead-ref-ok-end -->` region, or drop the link syntax (e.g. `` `path/to/doc.md` `` in backticks).

## Naming Guidance

- Name after the topic, not the category: `payments.md`, not `business-domain-1.md`
- Split files get specific names: `payments-validation.md` and `payments-lifecycle.md`, NOT `payments-part1.md`
- Names should be self-explanatory without reading the file

## Anti-Patterns

| Anti-pattern | What to do instead |
|---|---|
| One giant `domains.md` covering all domains | One file per domain: `payments.md`, `users.md`, `loans.md` |
| Standards file mixing naming, error handling, and logging | Separate: `naming-conventions.md`, `error-handling.md`, `logging.md` |
| Catch-all domain file that keeps growing with each task | Create focused files per concern; reference each other when needed |
| Adding an "Other" or "Miscellaneous" section | If it doesn't fit, it belongs in its own file or not at all |
| Duplicating content from `.claude/claude.md` (or `.github/copilot-instructions.md`) | Reference, don't repeat — the canonical instructions file is the big-picture source |

## Rationalization Prevention

| Thought | Reality |
|---|---|
| "It's all related to payments" | Related ≠ same concern. Payments validation and payments lifecycle are separate facets. |
| "I'll split it later when it gets bigger" | Splitting after the fact is harder. Start focused. |
| "Adding one more section won't hurt" | One more section is how every bloated file started. Check scope before adding. |
| "Agents can just skip the parts they don't need" | They can't reliably. Every token in the file costs context budget. |
| "This oversized file feels historical, so it's exempt" | The historical-record test is shape — an append-only chronological log or point-in-time snapshot, not vibe or prose tone. A topic-organized guidance doc reads as "historical" all it wants and is still not exempt. Apply the test explicitly (§ Split Exemptions → Historical Record); split it if the honest answer is "topic-organized." |

## Self-Check

Before adding to or creating a `.context/` file:

- Does this file have a single, nameable topic?
- Would another agent looking for this information look here first — and *only* here?
- Am I adding to an existing file because it's *the right file*, or because it's *convenient*?

---

*For when to update files, see `context-maintenance`. For how to create files initially, see `initialize-repo`.*
