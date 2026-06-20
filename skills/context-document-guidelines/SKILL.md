---
name: context-document-guidelines
description: >
  Use when creating or editing a .context/ document, when a .context/ file feels large or covers multiple concerns, or when deciding whether to split a domain file.
user-invocable: false
---

# Context Document Guidelines

## Overview

A `.context/` file should cover exactly one facet of one topic. Loading it to get information about X should not also load unrelated information about Y.

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

When a file exceeds **16,000 bytes** AND has 3+ discrete peer `## ` sections, apply the folder split rule in `## Folder Split Rule` below rather than treating it as a smell signal only.

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

1. **Bytesize**: the file exceeds **16,000 bytes** (~200 lines × 80 chars). Bytesize is used rather than line count because some files have very long lines (tables, prose) where line count under-represents reading burden.
2. **Logical splittability**: the file contains **≥ 3 peer-level `## ` sections** each representing a discrete topic (not just sub-headings of one narrative).

If gate (1) passes but gate (2) fails (single continuous narrative), note the finding in the maintenance report but do not split.

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

**README.md contents:** retain the original intro paragraph and any preamble that applies to the whole set; add a table or list that links to each per-topic file.

After splitting, update any cross-references within `.context/` that pointed at the original file.

If the original file had a row in `.context/rules-index.md`, repoint that row's link at the new `<name>/` folder (or `<name>/README.md`) in the same change — do not leave it pointing at the deleted file.

> For the maintenance-cycle action that triggers this rule, see `context-maintenance § File Size Rule`.

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

## Self-Check

Before adding to or creating a `.context/` file:

- Does this file have a single, nameable topic?
- Would another agent looking for this information look here first — and *only* here?
- Am I adding to an existing file because it's *the right file*, or because it's *convenient*?

---

*For when to update files, see `context-maintenance`. For how to create files initially, see `initialize-repo`.*
