---
name: context-maintenance
description: >
  Use when a task is complete and .context/ may need updating, when documentation contradicts the codebase, when retrospective entries need promotion, when task artifacts need pruning, when a `.context/` file has grown past the split threshold, or when a proactive drift scan is requested before editing (invoked via @context-specialist mode=audit).
user-invocable: true
---

# Context Maintenance

## Overview

**A `.context/` directory is only useful if it stays current.** Stale docs are worse
than none — they mislead agents with outdated information. This skill runs three phases —
Audit, Explore, Edit — producing a structured report of every change.

## When to Use

- A task just completed with lessons learned
- `.context/` files contradict the current codebase
- A new domain, pattern, or convention was introduced
- Retrospective entries need promotion
- Task artifacts need pruning
- A dependency, tool, or architectural pattern changed
- A `.context/` defect was identified during other work — that work owns the fix (see § Ownership and Urgency)

---

## Companion Files

| File | Load when |
|---|---|
| `phase-3-edit.md` | Phase 3 runs — mode `maintenance` or absent, so Phase 0 did not stop the run. |
| `context-graph.md` | A Phase 1 dangling-reference or orphan-node audit needs the graph tool. |
| `append-retrospective-entry.md` | A run must mutate `.context/retrospectives.md`. |

---

## Ownership and Urgency

**Inaccurate `.context/` content is poison.** Agents load it and act on it as fact, so a doc that
now says something false does damage on every read — worse than no doc at all. Urgency follows
from that, not from convenience.

**Ownership.** A `.context/` defect identified *during* a task is that task's work — not a
candidate follow-up, not a backlog note, not "whoever runs maintenance next." The one sanctioned
deferral is a defect surfaced with **no active task**: that gets its own task, filed and worked.

**Severity decides *when*.** Tag every Phase 1 finding:

| Severity | What qualifies | Fixed when |
|---|---|---|
| **P0 — inaccurate** | Content asserting something false today: a deleted module or renamed API documented as current, a fixed bug described as live, two files contradicting each other. An agent reading it would act wrongly. | **Verified against source the moment it's suspected, then corrected or deleted immediately on confirmation.** Resume the interrupted step afterward. Never carried to a later phase, a later task, or task close. |
| **P1 — mechanical** | A rule-driven obligation with no judgement call: an oversized file to split, a missing `rules-index` row, a dangling link, an orphan node, a drifted literal. | Before the current task closes. Never handed to a later task. |
| **P2 — untidy** | Out-of-scope content, unpromoted lessons, stale task folders. Nothing false, nothing rule-violating. | The normal task-close maintenance pass. |

**Audit mode:** the table above describes maintenance-mode behavior. In `mode: audit`, a P0
fixes nothing — it's flagged **BLOCKING** per Phase 0 instead.

> **A prior deferral is not precedent.** If an earlier task already deferred a P1 obligation — the
> recurring case is a file left over the 16,000-byte split threshold — that is not evidence
> deferring is acceptable. It means the debt survived a full cycle. Treat the repeat as escalation
> and fix it in this task.

| Rationalization | Reality | Correct Action |
|---|---|---|
| "I'll file the stale doc as a follow-up ticket" | It misleads every agent that loads it until the follow-up lands — and follow-ups are the tickets that don't get worked | Correct or delete it now, in this task. |
| "The split can wait — a previous task deferred it too" | A deferral that survived a cycle is compounding debt, not precedent | Split it in this task. |
| "This defect isn't what I was asked to work on" | The task that finds a `.context/` defect owns it; that is what keeps the tree true | Fix it in-task. Only a defect found with no active task becomes its own task. |
| "I'll batch it into the task-close maintenance pass" | Right for P2, wrong for P0 — a false statement is live damage for the rest of the task | Verify P0 against source on identification, correct on confirmation; batch only P2. |

---

## context-maintenance: Phase 0: Scope Gate

**Check the invocation mode first.**

If loaded by `@context-specialist` with `mode == audit`:
- Execute Phase 1 (Audit) and Phase 2 (Explore/Verify) only.
- **Stop before Phase 3 (Edit).** Modify no `.context/` files.
- Return the verified Phase 2 audit report as final output. Label any **P0** finding
  **BLOCKING** at the top of the report — audit mode cannot fix it, so the dispatching
  manager must dispatch the correction immediately rather than queue it (§ Ownership and Urgency).

Otherwise (mode `maintenance` or absent): run all three phases.

---

## context-maintenance: Phase 1: Audit (~⅓ of effort)

**Goal**: Build a full audit report of what exists and what needs to change — modifying
no files yet, except a suspected P0 fixed on the spot (see below).

Scan all `.context/` files. For each, check these issue types:

| Issue Type | Severity | What to Look For |
|------------|----------|-----------------|
| **Out-of-scope content** | P2 | Content belonging in a different `.context/` file |
| **Stale/outdated info** | **P0** | References to deleted modules, renamed APIs, removed patterns, or fixed bugs |
| **Oversized files** | P1 | Files exceeding 16,000 bytes (see § File Size Rule) |
| **Cross-file inconsistencies** | **P0** | Same concept described differently in two files (e.g. an auth pattern one way in `domains/auth.md`, differently in `standards/api.md`) |
| **Orphaned entries** | P2 | `tasks/` folders for completed or abandoned work; retrospective entries no longer active learnings |
| **Unpromoted lessons** | P2 | Retrospective entries whose learnings should have been promoted to persistent docs but weren't |
| **Index-coverage gap** | P1 | A top-level file under `standards/`, `workflows/`, or `decisions/` (an ADR `NNN-*.md`) has no row in `rules-index.md`. A file *inside* an already-indexed sub-directory (e.g. `standards/skill-decomposition/`, `workflows/task-plan/`) is covered by that directory's parent row — not a gap. **Detect with `check-rules-index.sh` (see § Tooling) — do not hand-scan.** |
| **Dangling reference** | P1 | A `[text](path)` link (or a `## Related` link) in **any** content doc — `domains/`, `architecture/`, `standards/`, prose links, ADR supersede targets — whose target doesn't resolve on disk. Generalizes the rules-index backward check to the whole tree. **Detect with `context-graph --check` (see § Tooling) — do not hand-scan.** |
| **Orphan / unreachable node** | P1 | A content doc with no in-edges that isn't a known discovery root (`overview.md`, `projects.md`, `rules-index.md`) — e.g. a `domains/` file nothing links to and no index covers. **Detect with `context-graph --check` (see § Tooling).** `tasks/*` files are never orphan-flagged. |

Build an **audit report** in working memory as you scan. For each finding, record:
- File path
- Issue type (from table above)
- **Severity** (P0 / P1 / P2 — from the same table; see § Ownership and Urgency)
- Proposed action (update, delete, split, promote, prune)
- Brief justification

**Modify no files in Phase 1 — except a suspected P0.** The moment a P0 candidate is
noticed, verify it against source immediately rather than waiting for Phase 2, and correct
or delete it on confirmation before resuming the scan. Never carried to a later phase, a
later task, or task close. Mark it **done** in the audit report (not merely "verified") so
Phase 3 does not re-apply a finding this step already corrected. *Maintenance mode only* —
in audit mode the Phase 0 scope gate still holds: modify nothing, flag it BLOCKING instead.

---

## context-maintenance: Phase 2: Explore (~⅓ of effort)

**Goal**: Verify each audit finding against the actual codebase before acting.

For each finding in the audit report:

1. Check the corresponding source code, config, or codebase artifact.
2. Ask: does the documented behavior match what the code does today? Does the API,
   interface, or pattern still exist?
3. Mark each finding **verified** (proceed with proposed action) or **invalidated**
   (finding was wrong — leave content unchanged).
4. Update the audit report: retain only verified findings, each carrying its severity.
5. **A P0 confirmed here is fixed the same way** — verified against source per step 3, then
   corrected or deleted immediately on confirmation, before continuing the pass. Never carried
   into Phase 3, a later task, or task close (§ Ownership and Urgency). *Maintenance mode only*
   — in audit mode the Phase 0 scope gate still holds: modify nothing, flag it BLOCKING instead.
   Mark it **done** in the audit report (not merely "verified") so Phase 3 does not re-apply
   a finding this step already corrected.

**Don't skip this phase even for obvious findings.** Stale docs persist precisely
because they look plausible without checking the code.

---

## context-maintenance: Phase 3: Edit (~⅓ of effort)

**This phase runs only when the Phase 0 scope gate did not stop the run — mode `maintenance` or
absent. When it runs, read `phase-3-edit.md` and apply it**: updates, promotions, pruning, the
§ File Size Rule split gate, and the staging step. In `mode: audit` Phase 3 does not run and the
companion is not read.

---

## Output Report

After all three phases, return this structured report to the caller:

```
**P0 (inaccurate) findings — verified and corrected the moment each was confirmed, never carried to a later phase, task, or task close:**
- [path]: [what it falsely asserted] → [correction or removal]
  (audit mode: list these as BLOCKING and unfixed — the caller must dispatch the fix now)

**Files modified:**
- [path]: [one-line description of change]

**Files split:**
- [original path] → [new file 1], [new file 2], ...

**Entries promoted to persistent docs:**
- [retrospective entry ID or date] → [target file]

**Entries pruned:**
- [path/entry]: [reason]

**Staged for caller commit:** [list of paths staged via `git add`]
```

If nothing needed changing, report: "No changes required — all `.context/` files are current."

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Skipping Phase 2 (explore) | Audit findings can be wrong. Verify against source before editing. |
| Promoting everything from retrospectives | Only promote generalizable lessons. |
| Pruning a file to keep it under the split gate | Pruning never discharges a split. Prune redundancy because it is redundant; split because both gates fired. |
| Not writing content so the file stays under the gate | Worse than deferring the split — it hides the obligation instead of leaving it visible. Write the content, then split. |
| Documenting the past instead of the present | Architecture/domain docs describe CURRENT state. Use `decisions/` for history. |
| Deleting history from `decisions/` | Those records explain WHY the codebase looks as it does. Keep them. |
| Editing files without the audit report | Edits without a prior audit miss stale content elsewhere. Always audit first. |
| Editing `retrospectives.md` by hand | Use the `append-retrospective-entry` script (`.sh` or `.ps1`) — hand edits risk misaligned blank lines, lost comments, or an off-by-one on entry count. |

---

## Tooling: append-retrospective-entry

`append-retrospective-entry.md` documents the Bash and PowerShell scripts in `./scripts/` that mutate `.context/retrospectives.md` (deterministic insert + rolling-log trim). **This is the only approved way to mutate `retrospectives.md` — do not edit it directly.**

## Tooling: check-rules-index

The **Index-coverage gap** audit (Phase 1) is script-backed — run
`check-rules-index.sh` rather than hand-scanning the three rule directories.
The script is the single source of truth shared with the `pre-commit` hook
(ICON-0069); it asserts every top-level file under `standards/`, `workflows/`,
and each numbered ADR under `decisions/` has a row in `.context/rules-index.md`,
honoring parent-row granularity (sub-directory files covered by their parent
row, not flagged).

Run it from the target repo (the directory containing `.context/`), passing
the repo root as the argument. The script lives next to this skill — resolve
its directory per `plugin-resource-paths § Skill-Level`:

### Claude Code (Bash)

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/check-rules-index.sh" "$(git rev-parse --show-toplevel)"
```

### Copilot CLI (Bash)

```bash
# Override via MARKETPLACE_NAME=<your-marketplace-slug>, or edit this line in forks.
[ -n "${MARKETPLACE_NAME+x}" ] || MARKETPLACE_NAME="icon-marketplace"
SKILL_DIR="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins/${MARKETPLACE_NAME}/ICON/skills/context-maintenance"
bash "$SKILL_DIR/scripts/check-rules-index.sh" "$(git rev-parse --show-toplevel)"
```

**Exit codes:** `0` = all top-level rule files indexed; `1` = one or more
missing a row (listed on stderr — add an "Applies when…" row for each before
proceeding to Phase 3); `2` = `.context/` or `rules-index.md` absent (create
the index first — `context-specialist-impl-leaf` Step 4.5).

## Tooling: context-graph

The **Dangling reference** and **Orphan / unreachable node** audits (Phase 1)
are script-backed — run `context-graph --check` rather than hand-scanning
`.context/`. `context-graph.md` documents
both the `.sh` and `.ps1` variants in `./scripts/`, the node/edge model, the
escape-hatch markers, and the fail-closed exit contract (`0` clean / `1`
violations / `2` parser or environment error — any non-zero must block; invoke
as `… || exit 1`, never `if context-graph …; then`).

Run it from the target repo, passing the repo root or `.context/` tree:

### Claude Code (Bash)

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/context-graph.sh" --check "$(git rev-parse --show-toplevel)/.context" || exit 1
```

### Copilot CLI (Bash)

```bash
# Override via MARKETPLACE_NAME=<your-marketplace-slug>, or edit this line in forks.
[ -n "${MARKETPLACE_NAME+x}" ] || MARKETPLACE_NAME="icon-marketplace"
SKILL_DIR="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins/${MARKETPLACE_NAME}/ICON/skills/context-maintenance"
bash "$SKILL_DIR/scripts/context-graph.sh" --check "$(git rev-parse --show-toplevel)/.context" || exit 1
```

### Disjoint ownership — no double-reporting

`context-graph --check` owns a **disjoint** edge set from the two other
consistency gates, so no dangling reference is reported twice:

- It owns **content-doc → content-doc** links (including `## Related` links) and
  **ADR supersede targets**.
- It **ingests** `rules-index.md` rows only as reachability edges (so a
  rule file reachable via the index isn't flagged as an orphan) but does
  **not** re-validate them — dead rules-index rows stay owned by
  `check-rules-index.sh`'s backward check. Run `check-rules-index.sh` first;
  their edge sets don't overlap, so their verdicts cannot conflict.
- It does not touch plugin-doc → `.context/` references (the `pre-commit`
  dead-ref resolver's domain).

The `## Related` seam and the ADR `**Supersedes**` / `**Superseded-by**`
bold-fields the graph keys on are defined by `context-document-guidelines` —
consult it for the seam authoring rules rather than restating them here.

