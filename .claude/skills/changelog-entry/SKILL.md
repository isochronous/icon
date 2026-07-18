---
name: changelog-entry
description: >
  Use at task close — after reconcile-plan.md and @reviewer delegation, before
  commit — to add or merge a single line item into the `## [Unreleased]` block
  of `CHANGELOG.md`. Covers when to invoke, how to decide entry tone (terse for
  internal-only vs efficient for user-facing), and the cumulative-effect
  responsibility: when a task's change overlaps a subject already in
  `[Unreleased]`, edit or remove that existing entry rather than appending a
  second one.
user-invocable: true
disable-model-invocation: false
---

# Changelog Entry

## Overview

At task close, before committing, add or merge an entry in the `## [Unreleased]`
block of `CHANGELOG.md` (repo root). This skill covers procedure and tone. For
form rules (one sentence per entry, no block-level formatting, ticket IDs at end),
see `.context/standards/changelog-discipline.md`.

## changelog-entry: When to Run

Run after `Reconcile plan.md` and `@reviewer` delegation, before staging and committing.

**Legitimate skip:** No entry needed when the task touched only
**repo-internal** surfaces consumers never see — `.context/` (any
subdirectory), `.claude/skills/` (maintainer-only skills), `.githooks/`,
`plan.md` and task-folder artifacts, this repo's own `CHANGELOG.md`. The
ICON changelog describes plugin-release changes; if nothing in the
consumer-shipped set (`agents/`, `skills/`, `commands/`, `hooks/`, `shared/`,
`context_template/`, `.claude-plugin/plugin.json`, `.mcp.json`) changed,
there is nothing to tell the consumer. See
`.context/standards/changelog-discipline.md` Rule 4 for the full scope table.
When in doubt, check whether the changed paths ship via the `latest` tag — if
not, skip.

## changelog-entry: Tone — Internal vs User-Facing

**Internal-only changes** (refactors, hygiene, reorganizations consumers won't
notice): keep it terse — subject and action suffice.

> `Refactored phase-completion template to consolidate CHANGELOG step. (ICON-0026)`

**User-facing or maintainer-facing changes** (new skills, changed behavior,
removed capabilities): use efficient language to describe **(a) what changed**
and **(b) how it affects the reader**. The "affects them" piece is what
distinguishes a user-facing entry from an internal one.

Good — what changed + effect:
> `Added changelog-entry skill; managers now add [Unreleased] entries incrementally at task close instead of reconstructing them at release time. (ICON-0026)`

Bad — what changed only:
> `Added changelog-entry skill to .claude/skills/. (ICON-0026)` ← reader cannot tell whether to care

## changelog-entry: The Cumulative-Effect Rule

Only the end result belongs in the changelog; the reader never sees intermediate
states.

**Rule:** When this task touches the same subject as an existing `[Unreleased]`
entry, edit that entry to reflect the new end state. Append a new entry only when
the subject is distinct. If the net effect is zero change, remove the entry
entirely.

**Worked example (the `foo` case):**

Existing `[Unreleased]` entry: `Changed const foo from 3 to 5. (ICON-0020)`

- Current task changes `foo` from 5 → 3: **remove** the entry (net zero change)
- Current task changes `foo` from 5 → 8: **rewrite** as `Changed const foo from 3 to 8. (ICON-0020, ICON-0023)`
- Current task changes unrelated `bar`: **append** a new bullet (distinct subject)

## changelog-entry: How to Run

1. Open `CHANGELOG.md`. Find the `## [Unreleased]` block at the top.
2. Decide: internal-only or user/maintainer-facing? Legitimate skip? (see Tone section)
3. Scan existing `[Unreleased]` entries for subject overlap. If found, apply the
   cumulative-effect rule — edit or remove; do not append.
4. If no overlap, append a new bullet under the appropriate sub-heading
   (`### Added` / `### Changed` / `### Fixed` / `### Removed`). Create the
   sub-heading if it doesn't exist.
5. Verify: one sentence; no block-level formatting; `(ICON-NNNN)` at the end.
   See `.context/standards/changelog-discipline.md` for form rules.

## changelog-entry: Cross-References

- `.context/standards/changelog-discipline.md` — form rules
- `.claude/skills/release-plugin/SKILL.md` — release-time flow that renames `[Unreleased]` to `[X.Y.Z]`
- `.context/workflows/task-plan/phase-completion.md` — completion phase template that invokes this skill
