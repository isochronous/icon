---
name: changelog-entry
description: >
  Use at task close — after reconcile-plan.md and @reviewer delegation, before
  commit — to add or merge a single line item into the `## [Unreleased]` block
  of `CHANGELOG.md`. Covers when to invoke, the hard one-sentence-per-entry
  limit, how to decide entry tone (terse for internal-only vs efficient for
  user-facing), and the cumulative-effect
  responsibility: when a task's change overlaps a subject already in
  `[Unreleased]`, edit or remove that existing entry rather than appending a
  second one.
user-invocable: true
disable-model-invocation: false
---

# Changelog Entry

## Overview

At task close, before committing, add or merge an entry in the `## [Unreleased]`
block of `CHANGELOG.md` (repo root). This skill covers procedure and tone.

**The hard limit: one entry is one sentence.** Not one sentence plus an em-dash
aside plus a parenthetical plus a "which means…" tail. **Over ~30 words is
wrong.** Root cause, mechanism, before/after measurements, and internal-invariant
reassurances belong in the commit message, `plan.md`, and the retrospective —
never here. The remaining form rules (no block-level formatting, ticket IDs at
end, one bullet per distinct fix-class on sweep PRs) are in
`.context/standards/changelog-discipline.md`.

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
removed capabilities): name **(a) what changed** and **(b) who or what it
affects** — where (b) must fit **inside** the same sentence, as a clause or as a
named command/surface, never as a second sentence extending it. If the effect
will not fit inside the sentence, the entry is too broad: split it by fix-class.
"How it affects the reader" constrains word choice; it is not a licence to
explain the mechanism.

Good — what changed + effect, one sentence:
> `Added changelog-entry skill; managers now add [Unreleased] entries incrementally at task close instead of reconstructing them at release time. (ICON-0026)`

Bad — what changed only:
> `Added changelog-entry skill to .claude/skills/. (ICON-0026)` ← reader cannot tell whether to care

## changelog-entry: Before / After

A real `[Unreleased]` entry that had to be rewritten — 89 words, five distinct
fix-classes, mechanism inline:

✗ `` `/upgrade-repo` no longer overwrites a consumer's customized `INTEGRATION_BRANCHES`, tell an established project its own task-ID prefix collides with itself, create a root `claude.md` without asking, or skip the `## Related` graph seam and the `decisions/` directory. The pruning-script step now extracts the existing branch regex, copies the template's script logic, and restores the value byte-exactly — refusing loudly rather than guessing when it cannot read the existing test confidently. Repos initialized before 2.0.0 also get the graph seam emitted, which unblocks `context-maintenance`… (ICON-0094) ``

✓ Five bullets, 15–19 words each, mechanism dropped:

- `` `/upgrade-repo` no longer overwrites a consumer's customized `INTEGRATION_BRANCHES` value when it refreshes the pruning script. (ICON-0094) ``
- `` `/upgrade-repo` no longer tells an established repo that its own task-ID prefix collides with itself. (ICON-0094) ``
- `` `/upgrade-repo` now asks before creating a root `claude.md` redirect instead of writing one unprompted. (ICON-0094) ``
- `` `/upgrade-repo` now emits the `## Related` graph seam in repos initialized before 2.0.0, unblocking `context-maintenance`'s Phase 1 audit. (ICON-0094) ``
- `` `/upgrade-repo` now includes `decisions/` in its Phase 1 checklist, which `rules-index` generation depends on. (ICON-0094) ``

Everything cut — the byte-exact restore, the refuse-rather-than-guess behaviour,
the orphaned-graph explanation — is in the commit message and the retrospective.
None of it changes whether a reader is affected.

## changelog-entry: Self-Check Before Writing

Run this on the draft *before* it goes in the file:

1. **Count sentences.** More than one → cut, don't compress.
2. **Count clauses, not full stops.** An em-dash aside, a parenthetical claim, or
   a `which` / `so that` / `because` tail is a second claim wearing a coat. If it
   splits cleanly without losing the claim, it was two entries.
3. **Count words.** Over ~30 is wrong. The standard's ✓ example is 20.
4. **Count fix-classes.** Two unrelated changes joined by "and", "or", or a
   semicolon → two bullets.
5. **Read the neighbours last, not first.** Existing `[Unreleased]` entries are
   grandfathered and may be non-compliant; calibrate to the standard's ✓ example,
   never to the adjacent bullet.

## changelog-entry: Anti-Rationalization

| Rationalization | Reality | Correct Action |
|----------------|---------|----------------|
| "It *is* one sentence." | Rule 1's letter is satisfied by one grammatical sentence carrying em-dash asides and parentheticals. A sentence with three subordinate clauses is three sentences wearing a coat. | Count clauses, not full stops. If it splits cleanly at an em-dash without losing the claim, it was two entries. |
| "The neighbouring entries look like this." | A systemic trap, not a lapse of judgement: the standard's own grandfather clause guarantees non-compliant entries stay in the file, so the nearest visible examples are the least reliable guide in the repo. | Calibrate to the standard's ✓ example (~20 words). Never to the adjacent bullet. |
| "The mechanism *is* the user-facing impact." | True of a silent-failure bug only in the sense that the *symptom* matters — which then gets read as licence to explain the cause. The reader needs to know **whether** they are affected, not **why** it broke. | Name the affected command or surface; drop the cause. The commit message carries it. |
| "This task was large; one line undersells it." | Entry length tracks user-facing surface, not effort. A six-review-round task and a one-word fix earn the same line. | If the task closed several distinct fix-classes, that is several bullets — never one long one. |

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
5. Run the **Self-Check Before Writing** list above on the draft: one sentence,
   one claim, under ~30 words, one fix-class, no block-level formatting,
   `(ICON-NNNN)` at the end. See `.context/standards/changelog-discipline.md`
   for the remaining form rules.

## changelog-entry: Cross-References

- `.context/standards/changelog-discipline.md` — form rules
- `.claude/skills/release-plugin/SKILL.md` — release-time flow that renames `[Unreleased]` to `[X.Y.Z]`
- `.context/workflows/task-plan/phase-completion.md` — completion phase template that invokes this skill
