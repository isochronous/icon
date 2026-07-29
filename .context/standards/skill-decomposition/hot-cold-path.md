# Hot Path / Cold Path Separation

`SKILL.md` carries the **hot path** — the instructions every invocation executes. Conditional
content (modes, platform branches, rarely-taken procedures) is **cold path** and moves into
companion files the model loads deliberately, only on the run that needs them.

The rule exists because a `SKILL.md` past the harness's compaction-retention cap is **silently
truncated at runtime**, not merely expensive. Provenance for every number below, the sensitivity
analysis, and the advisory→blocking promotion condition live in
[ADR-016](../../decisions/016-skill-hot-cold-path.md); this file is the authoring spec.

## Scope

Applies to shipped `skills/` **and** `.claude/skills/` — identical failure mode, identical harness.

**Excludes `context_template/context/workflows/task-plan/`.** Three reasons, recorded here so this
is not re-litigated at the next audit:

1. It is not a skill — no `SKILL.md`, no frontmatter, no invocation path.
2. It is already governed, and already exempt, under `context-document-guidelines § Folder Split
   Rule → Split Exemptions` — a fixed-shape scaffold whose headings are a parse contract.
3. Touching it forces a `context_template/context/iconrc.json` version bump for zero benefit.

**No skill file is ever exempt from the caps below.** `context-document-guidelines` exempts a
`.context/` file that **records** rather than instructs — a log, a snapshot, an ADR, a `README.md`
index, a fixed-shape scaffold — from its own 16,000 B folder-split gate at any size. That exemption
stops at `.context/`. A skill exists to tell an agent what to do, so no `SKILL.md` and no companion
can be a record: a data table, a template set, or a body of reference prose inside a skill is still
material the agent is instructed to apply. **"It is reference material, therefore a record" is not
an argument available here** — the remedy for an oversized companion is always the condition-wise
split below. The two rules diverge because the failures differ: the `.context/` gate protects
findability, and splitting a record destroys the chronology or index that makes it useful; the
`SKILL.md` cap protects against **silent truncation at runtime**, which cuts a record exactly as
readily as it cuts a procedure.

That truncation reason attaches to the **`SKILL.md` cap only.** A companion is not injected — it
enters context on a model-issued `Read` — so the retention cliff does not act on it, and its
8,000 B cap is empirical rather than derived from the cliff. The boundary above does not need the
truncation argument: it stands on the definition, which is independent and sufficient.

**ICON's agents preload no skills today** — verified: all nine `agents/*.agent.md` carry only
`description:` and `user-invocable:`, with no `skills:` frontmatter field. That matters because a
*preloaded* skill's body is injected whole at agent startup, which would make its companions
unconditional and this rule inapplicable to it. If that ever changes, the rule stops applying to
the preloaded skill.

## The Two Gates

Both must hold before you split. They are conjunctive on purpose.

| Gate | Test |
|---|---|
| **1 — size** | `wc -c` exceeds **16,000 B** for a `SKILL.md`, or **8,000 B** for a companion. |
| **2 — conditionality** | The file contains **≥ 2 regions guarded by a condition statable in one sentence**, each **≥ 2,000 B**. |

Gate 2 is not mechanically checkable and is not meant to be — counting `##` sections would be
vacuous, since every skill has three or more by template. The advisory pre-commit gate asks the
question; the author answers it. **If gate 1 fires and gate 2 fails, record the finding and leave
the file whole.** A genuinely unconditional oversized procedure is not improved by splitting it.

**Floor: never create a companion below 2,000 B.** This is the anti-confetti stop and the reason
the cohesion test below terminates.

## The Three Tests, In Order

The unit of extraction is **one if→then block**: everything needed when a condition holds, and
nothing else. The defect designed against is a companion bundling two branches — taking branch A
then drags B into context anyway, so you pay the indirection *and* still load the bulk, which is
worse than not splitting.

1. **Scope.** Is the condition resolved once per *invocation*, or once per *item the invocation
   iterates over*? Only invocation-scoped conditions may be extracted. An item-scoped condition
   sits inside a loop: a single run meets items on both sides and loads every arm anyway, so the
   extraction costs a `Read` per iteration and saves nothing. **Mechanical tell** — find the
   condition and ask whether any enclosing step says *"for each …"*.
2. **Cohesion.** Is there any invocation that loads the companion and uses only *part* of it? If
   yes, it bundles more than one condition and must split further — **bounded by the 2,000 B
   floor**.
3. **Coupling.** Is there any pair of companions always loaded together? If yes, they are one
   condition and must merge.

Without the floor, cohesion fragments indefinitely: almost any procedure has a step some run skips.

## The Canonical Shape

````markdown
---
name: example-skill
description: >
  Use when … — including <every scenario that now lives in a companion>.
user-invocable: true
---

# Example Skill

## Overview

What this is, in one or two sentences. Always read.

## Mode Detection

| Trigger | Mode | Load |
|---|---|---|
| "create", "scaffold", "from scratch" | create | `create-mode.md` |
| "audit", "review", "validate" | audit | `audit-mode.md` |

If the request is ambiguous, ask which mode before loading either companion. Do not guess.

## Companion Files

| File | Load when |
|---|---|
| `create-mode.md` | The request is to create a new artifact (Mode Detection → create). |
| `audit-mode.md` | The request is to review an existing artifact (Mode Detection → audit). |
| `windows-notes.md` | The target repo is on Windows and Step 3 needs a path fix-up. |

## The Process

1. Detect the mode from the table above.
2. Read the one companion that matches. Do not pre-load the others.
3. Apply the target repo's path conventions. **If the target repo is on Windows, read
   `windows-notes.md` before continuing** — otherwise skip it.
4. …
````

**The `description` must still name every scenario that moved into a companion.** Discovery runs
entirely off the frontmatter; a description trimmed alongside the extraction produces a skill that
loads correctly and then does not know a relevant companion exists.

## Pointer Syntax

**A bare backticked sibling filename — `` `windows-notes.md` ``.** Not a Markdown link, not
`@windows-notes.md`, not `${CLAUDE_SKILL_DIR}/windows-notes.md`. Always forward slashes, including
when authoring on Windows.

`${CLAUDE_SKILL_DIR}` is rejected on **failure mode**, not on capability. It is documented-portable
within Claude Code only, and where it does not resolve it leaves a literal `$`-prefixed string
naming no file on disk — an **unrecoverable** pointer. An unresolved bare filename is still a
legible sibling name the model can glob and find. Under ADR-004, with the second harness's
semantics unestablished, graceful degradation decides it. Adoption cost is zero: every existing
precedent in this repo already uses bare filenames.

**This rejection scopes to prose pointers only. It does not reach script invocation**, which is
governed by [ADR-017](../../decisions/017-executable-content-home.md) and does use
`${CLAUDE_SKILL_DIR}`. Two things differ there: an invocation has no variable-free option — a
relative `scripts/x.mjs` resolves against the consumer's cwd, not the skill directory — and its
failure is **loud** (`Cannot find module`, non-zero exit) where a mis-resolved prose pointer is
silent.

## State the Condition Twice

Every companion's load condition appears **twice**: once in the `## Companion Files` manifest's
`Load when` column, and once inline at the branch point in the procedure.

This is not redundancy for emphasis. The documented failure mode is **under-reading** — the model
not taking a `Read` it should have taken. The inline statement catches the model at the moment of
the decision; the manifest ensures it knows the companion exists at all on a run that never reaches
that procedure step.

## The `## Companion Files` Manifest Is Required

Any skill with **≥ 1 companion** carries a `## Companion Files` section with a `File` /
`Load when` table. It is mandatory because it is the **only** construct that makes a skill's load
graph auditable: `context-graph` does not traverse `skills/` at all, so a companion orphaned by a
deleted pointer is invisible to every mechanical check in the repo.

Use `Load when` (the condition), not `Loaded by` (the parent). In a flat graph every companion is
loaded by `SKILL.md`, so `Loaded by` carries no information — and the condition is what the three
tests above operate on.

## Strict Depth-1

**Companions are leaves. No companion references another companion.** A file discovered *from*
another referenced file degrades into a silent partial read — the model may preview it with
`head` rather than read it whole, with no error and no signal that it is acting on a fragment.

Where two companions need the same fact: **duplicate the line, or promote it into `SKILL.md`.
Never cross-link.** Duplication of a few lines is cheap and visible; a chain is neither.

## Companion File Conventions

- **No frontmatter.** Frontmatter drives discovery, and companions are not discovered — they are
  read on a pointer from `SKILL.md`.
- **A plain descriptive H1**, and **no `## skill-name:` prefix on inner headings** — that prefix
  rule governs `SKILL.md`'s own numbered steps. **Exception**: a companion carrying a numbered step
  of the parent's process names the parent in its H1, matching existing practice — see
  `skills/context-specialist-impl-leaf/step-4-file-content.md`, whose H1 is
  *Per-File Content Guidance for `context-specialist-impl-leaf` Step 4*.
- **A companion over 100 lines carries its own table of contents**, so a partial read still
  surfaces the file's scope.
- **Descriptive filenames tied to content.** Never `doc2.md`.
- **Forward slashes always.**

## Section-Name Preservation

When an extraction moves a section that other files cite as `` `skill-name § Section Name` ``, the
companion's **H1 must be that section name verbatim**. Otherwise every inbound citation must be
swept in the same commit.

This is not hypothetical. `context-document-guidelines` is cited by section name from `decisions/`,
`standards/`, `skills/`, and — the one that decides the cost — **`context_template/`**, where a
rename would force an `iconrc.json` version bump for no benefit. Preserving section names verbatim
is what keeps a split confined to the skill directory.

Measure the inbound set yourself, at the time of the split, with a pattern that also catches a
citation carrying a backtick immediately before `§` — a shape a naive grep misses:

```bash
grep -rno "context-document-guidelines[^§]\{0,80\}§ [A-Za-z(][^\`.;)]*" --include=*.md .
```

**No count is recorded here, deliberately.** The pattern matches any prose naming the skill next to
a `§`, including a sentence that states the count — so a figure written into this file counts
itself, and every later edit moves it with no signal. That is the same defect as the section below:
a number measured against a living file is stale by construction.

## Cite By Name, Not By Line Number

**A line-number citation into a living file is stale by construction.** Cite a section or a rule by
name. The rot is demonstrated in this repo: `skill-structure.md` cited
`writing-skills/SKILL.md:140-152` as the source of its size guidance, and by the time anyone
checked, line 140 was an unrelated layout example.

## Related

- Index: [skill-decomposition](../skill-decomposition.md)
- Governed by: [ADR-016 skill hot path / cold path](../../decisions/016-skill-hot-cold-path.md)
