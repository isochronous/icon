# Phase 3: Edit for `context-maintenance`

Cold-path companion to the `context-maintenance` skill. **Read this only when Phase 3 runs** —
that is, mode `maintenance` or absent, so the Phase 0 scope gate did not stop the run after
Phase 2. In `mode: audit` Phase 3 never runs and this file is not read.

**Contents**

- Updates
- Promotions
- Pruning
- File Size Rule
- Stage (commit ownership depends on caller mode)

**Goal**: Apply all verified findings from the audit report, other than any P0 already
marked **done** in Phase 1 or in Phase 2 step 5 — those are already corrected and are not
re-applied.

Work through each remaining verified finding:

## Updates

Rewrite, remove, or correct content as needed.

## Promotions

For unpromoted retrospective entries, pick the target file from this table and
write the promoted content there:

| Lesson Type | Promote To |
|------------|-----------|
| Domain-specific gotcha | `domains/<domain>.md` |
| Coding convention | `standards/<area>.md` |
| Test pattern | `testing/<area>.md` |
| Architecture decision | `architecture/` or `decisions/` |
| Process improvement | `workflows/<process>.md` |

After promoting, add a "Promoted to:" note on the retrospective entry.

**Don't promote everything.** Task-specific entries that don't generalize stay in the
retrospective as history.

## Pruning

Remove orphaned or outdated entries, and completed task folders older than the
current cycle.

**Never delete history from `decisions/`** — those records explain WHY the codebase
looks as it does, even if the decision was later reversed.

## File Size Rule

A file that **records** rather than instructs — a log, a snapshot, an ADR, a `README.md` index, a fixed-shape scaffold, and so on — is exempt from this rule at any size. See `context-document-guidelines § Folder Split Rule → Split Exemptions` for the test; do not re-enumerate cases here. `.context/retrospectives.md` is mutated only via the `append-retrospective-entry` script (§ Tooling), never edited or split by hand — do not split it.

After writing or updating any `.context/*.md` file, measure its size:

```bash
wc -c <file>   # bytes
```

```powershell
(Get-Item <file>).Length   # bytes
```

If the file exceeds **16,000 bytes** AND has **≥ 3 peer-level `## ` sections** each a discrete topic, convert it to a folder in the same pass:

1. Create `<name>/README.md` with the original intro/preamble and a table or list linking to the per-topic files.
2. Write one `<name>/<slug>.md` per topic section. Use `NNN-kebab-slug.md` for numbered units (e.g. ADRs); `kebab-slug.md` otherwise.
3. Update `.context/` cross-references that pointed at the original file.
4. If the original file had a row in `.context/rules-index.md`, repoint that row's link at the new `<name>/` folder (or `<name>/README.md`) — don't leave it pointing at the deleted file.
5. Delete (`git rm`) the original flat `.md` file.

If oversized but lacking ≥ 3 discrete peer `## ` sections (single continuous narrative), note it in the Output Report — do not split.

**Splitting is the response when both gates fire — not one of two options to weigh.** A file over
16,000 bytes with ≥ 3 discrete peer `## ` sections is converted to a folder in this pass. Nothing
is being chosen between.

**Pruning is not a way to avoid a split.** Remove redundancy because it is redundant — at any time,
at any size, gate or no gate. It is never a lever for getting a number under a threshold. If a file
is over the gate *and* genuinely carries redundancy, prune **and** split; the prune does not
discharge the split. A file pruned to just under 16,000 bytes has bought a few hundred bytes of
headroom at the cost of real content and still has no structure — which is how one file gets pruned
twice and split never, each prune buying less than the last.

**Never defer a split for cost.** None of the following is a reason, and each is what actually gets
said:

- "it adds scope to this task"
- "it is more work than the change that triggered it"
- "this is the end of a long task; a structural decision now would be rushed"
- "the next task can do it"
- "pruning gets it under, so nothing is required"

The split is mechanical — move sections into `<name>/<slug>.md`, write the `README.md` index, sweep
the cross-references, preserve any numbering. The one judgement is which axis to divide on, and that
judgement is cheaper now than after another accretion.

**Do not decline to write content in order to keep a file under the gate.** Withholding a lesson, a
convention, or a correction because adding it would trip the size gate is worse than deferring the
split. A deferred split at least leaves the obligation visible in the file's byte count; unwritten
content leaves nothing behind, and a lesson parked in `retrospectives.md` instead decays out of the
rolling log within a few tasks. Write the content, then split the file it landed in.

**The split is owned by the task that surfaced it** — normally the task whose edit pushed the file
over the threshold. It is P1: done before that task closes, never handed to a later one. A previous
task having deferred the same split does not license another deferral — it means the debt survived a
full cycle, so treat the repeat as escalation (§ Ownership and Urgency).

| Rationalization | Reality | Correct Action |
|---|---|---|
| "Pruning brought it under, so no split is required" | Rule-sanctioned once, and it is how a file gets pruned twice and still has no structure. Each prune buys less headroom and spends real content. | Prune the redundancy because it is redundant — and split anyway. |
| "Adding this lesson would trigger a split obligation, so don't add the lesson" | The dodge. Worse than deferring: a deferral leaves the obligation visible, this hides it, and the unwritten lesson decays out of the rolling log. | Write the lesson. Then split the file it landed in. |
| "A structural decision at the end of a long task would be rushed" | The split is mechanical — move sections, sweep citations, keep numbering. The judgement is which axis, and that is cheaper now than after another accretion. | Split it before this task closes. |
| "The next task can do it" | A previous deferral raises urgency rather than licensing another. That rule got routed around, not disagreed with. | Split it in this task. |

See `context-document-guidelines § Folder Split Rule` for the canonical rule and slug-naming conventions.

## Stage (commit ownership depends on caller mode)

After all edits, **stage the writes with `git add`**. The commit is owned by the dispatching manager, which folds these staged changes into its Task Completion Step 4 commit. Do not run `git commit` from this skill — it would sweep pre-staged manager work (source changes, `plan.md` updates) into a commit owned by the wrong author and break the manager's commit-discipline pass.
