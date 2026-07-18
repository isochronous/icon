---
name: context-maintenance
description: >
  Use when a task is complete and .context/ may need updating, when documentation contradicts the codebase, when retrospective entries need promotion, when task artifacts need pruning, or when a proactive drift scan is requested before editing (invoked via @context-specialist mode=audit).
user-invocable: true
---

# Context Maintenance

## Overview

**A `.context/` directory is only useful if it stays current.** Stale documentation is
worse than no documentation — it misleads agents into making decisions based on outdated
information. This skill provides a three-phase process — Audit, Explore, Edit — that
produces a structured report of every change made.

## When to Use

- A task has just been completed and lessons were learned
- You notice `.context/` files that contradict the current codebase
- A new domain, pattern, or convention has been introduced
- Retrospective entries have accumulated and need promotion
- Task artifacts have accumulated and need pruning
- A dependency, tool, or architectural pattern has changed

---

## context-maintenance: Phase 0: Scope Gate

**Check the invocation mode before proceeding.**

If this skill was loaded by `@context-specialist` with `mode == audit`:
- Execute Phase 1 (Audit) and Phase 2 (Explore/Verify) only.
- **Stop before Phase 3 (Edit).** Do not modify any `.context/` files.
- Return the verified audit report from Phase 2 as your final output.

Otherwise (mode is `maintenance` or absent): proceed through all three phases normally.

---

## context-maintenance: Phase 1: Audit (~⅓ of effort)

**Goal**: Build a full audit report of what exists and what needs to change — without
modifying any files yet.

Scan all `.context/` files. For each file, check for these issue types:

| Issue Type | What to Look For |
|------------|-----------------|
| **Out-of-scope content** | Content in this file that belongs in a different `.context/` file |
| **Stale/outdated info** | References to deleted modules, renamed APIs, removed patterns, or fixed bugs |
| **Oversized files** | Files exceeding 16,000 bytes (see § File Size Rule) |
| **Cross-file inconsistencies** | The same concept described differently in two files (e.g., an auth pattern described one way in `domains/auth.md` and differently in `standards/api.md`) |
| **Orphaned entries** | Task folders in `tasks/` for completed or abandoned work; retrospective entries for issues that no longer represent active learnings |
| **Unpromoted lessons** | Retrospective entries with learnings that should have been promoted to persistent docs but were not |
| **Index-coverage gap** | A top-level file under `standards/`, `workflows/`, or `decisions/` (an ADR `NNN-*.md`) has no row in `rules-index.md`. A file *inside* an already-indexed sub-directory (e.g. `standards/skill-decomposition/`, `workflows/task-plan/`) is covered by that directory's parent row — not a gap. **Detect with the `check-rules-index.sh` script (see § Tooling) — do not hand-scan.** |
| **Dangling reference** | A `[text](path)` link (or a `## Related` link) in **any** content doc — `domains/`, `architecture/`, `standards/`, prose links, ADR supersede targets — whose target does not resolve on disk. Generalizes the rules-index-only backward check to the whole tree. **Detect with `context-graph --check` (see § Tooling) — do not hand-scan.** |
| **Orphan / unreachable node** | A content doc with no in-edges that is not a known discovery root (`overview.md`, `projects.md`, `rules-index.md`) — e.g. a `domains/` file nothing links to and no index covers. **Detect with `context-graph --check` (see § Tooling).** `tasks/*` files are never orphan-flagged. |

Build an **audit report** in working memory as you scan. For each finding, record:
- File path
- Issue type (from table above)
- Proposed action (update, delete, split, promote, prune)
- Brief justification

**Do not modify any files during Phase 1.**

---

## context-maintenance: Phase 2: Explore (~⅓ of effort)

**Goal**: Verify each audit finding against the actual codebase before acting on it.

For each finding in the audit report:

1. Check the corresponding source code, config, or codebase artifact.
2. Ask: "Does the documented behavior match what the code does today? Does the API,
   interface, or pattern still exist?"
3. Mark each finding as **verified** (proceed with proposed action) or **invalidated**
   (finding was wrong — leave the content unchanged).
4. Update the audit report: retain only verified findings.

**Do not skip this phase even for findings that seem obvious.** Stale docs often persist
precisely because they look plausible without checking the code.

---

## context-maintenance: Phase 3: Edit (~⅓ of effort)

**Goal**: Apply all verified findings from the audit report.

Work through each verified finding:

### Updates

Apply the proposed changes — rewrite, remove, or correct content as needed.

### Promotions

For unpromoted retrospective entries, identify the target file using this table and
write the promoted content there:

| Lesson Type | Promote To |
|------------|-----------|
| Domain-specific gotcha | `domains/<domain>.md` |
| Coding convention | `standards/<area>.md` |
| Test pattern | `testing/<area>.md` |
| Architecture decision | `architecture/` or `decisions/` |
| Process improvement | `workflows/<process>.md` |

After promoting, add a "Promoted to:" note on the retrospective entry.

**Don't promote everything.** Some retrospective entries are task-specific and don't
generalize. That's fine — they stay in the retrospective as history.

### Pruning

Remove orphaned or outdated entries. For task artifacts, remove completed task folders
older than the current cycle.

**Never delete history from `decisions/`** — those records explain WHY the codebase
looks the way it does, even if the specific decision was later reversed.

### File Size Rule

After writing or updating any `.context/*.md` file, measure its size:

```bash
wc -c <file>   # bytes
```

```powershell
(Get-Item <file>).Length   # bytes
```

If the file exceeds **16,000 bytes** AND has **≥ 3 peer-level `## ` sections** each representing a discrete topic, convert it to a folder as part of this same pass:

1. Create `<name>/README.md` with the original intro/preamble and a table or list linking to the per-topic files.
2. Write one `<name>/<slug>.md` per topic section. Use `NNN-kebab-slug.md` for numbered units (e.g. ADRs); `kebab-slug.md` otherwise.
3. Update any cross-references within `.context/` that pointed at the original file.
4. If the original file had a row in `.context/rules-index.md`, repoint that row's link at the new `<name>/` folder (or `<name>/README.md`) in the same change — do not leave it pointing at the deleted file.
5. Delete (`git rm`) the original flat `.md` file.

If the file is oversized but does not have ≥ 3 discrete peer `## ` sections (single continuous narrative), surface a note in the Output Report — do not split.

**Prune first, split second.** If pruning brings the file under 16,000 bytes, prune only — no split needed.

See `context-document-guidelines § Folder Split Rule` for the canonical rule definition and slug-naming conventions.

### Stage (commit ownership depends on caller mode)

After all edits are applied, **stage the writes with `git add`**. The commit is owned by the dispatching manager, which folds these staged changes into its Task Completion Step 4 commit. Do not run `git commit` from this skill — running it sweeps any pre-staged manager work (source changes, `plan.md` updates) into a commit owned by the wrong author and breaks the manager's commit-discipline pass.

---

## Output Report

After completing all three phases, return this structured report to the caller:

```
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
| Promoting everything from retrospectives | Some entries are task-specific. Only promote generalizable lessons. |
| Splitting files before pruning | Prune first. Split only if the file remains oversized after pruning. |
| Documenting the past instead of the present | Architecture/domain docs describe the CURRENT state. Use `decisions/` for history. |
| Deleting history from `decisions/` | Those records explain WHY the codebase looks the way it does. Keep them. |
| Editing files without the audit report | Edits without a prior audit miss stale content in other files. Always audit first. |
| Editing `retrospectives.md` by hand | Use the `append-retrospective-entry` script (Bash `.sh` or PowerShell `.ps1` variant) — hand edits risk misaligned blank lines, lost comments, or an off-by-one on entry count. |

---

## Tooling: append-retrospective-entry

A sibling reference, [`append-retrospective-entry.md`](append-retrospective-entry.md), documents the Bash and PowerShell scripts in `./scripts/` that mutate `.context/retrospectives.md` (deterministic insert + rolling-log trim). **This is the only approved way to mutate `retrospectives.md` — do not edit it directly.**

## Tooling: check-rules-index

The **Index-coverage gap** audit (Phase 1) is script-backed — run
`check-rules-index.sh` rather than hand-scanning the three rule directories.
The script is the single source of truth shared with the `pre-commit` hook
(ICON-0069); it asserts every top-level file under `standards/`, `workflows/`,
and each numbered ADR under `decisions/` has a row in `.context/rules-index.md`,
honoring parent-row granularity (sub-directory files are covered by their
parent row and not flagged).

Run it from the target repo (the directory containing `.context/`), passing
the repo root as the argument. The script lives next to this skill, so resolve
the skill directory per `plugin-resource-paths § Skill-Level`:

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
`.context/` for broken links and unlinked docs. A sibling reference,
[`context-graph.md`](context-graph.md), documents both the `.sh` and `.ps1`
variants in `./scripts/`, the node/edge model, the escape-hatch markers, and
the fail-closed exit contract (`0` clean / `1` violations / `2` parser or
environment error — any non-zero must block; invoke as `… || exit 1`, never
`if context-graph …; then`).

Run it from the target repo, passing the repo root or the `.context/` tree:

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
consistency gates, so no dangling reference is ever reported twice:

- It owns **content-doc → content-doc** links (including `## Related` links) and
  **ADR supersede targets**.
- It **ingests** `rules-index.md` rows only as reachability edges (so a
  rule file reachable via the index is not flagged as an orphan) but does
  **not** re-validate them — dead rules-index rows stay owned by
  `check-rules-index.sh`'s backward check. Run `check-rules-index.sh` first;
  their edge sets do not overlap, so their verdicts cannot conflict.
- It does not touch plugin-doc → `.context/` references (the `pre-commit`
  dead-ref resolver's domain).

The `## Related` seam and the ADR `**Supersedes**` / `**Superseded-by**`
bold-fields the graph keys on are defined by the `context-document-guidelines`
skill — consult it for the seam authoring rules rather than restating them here.

