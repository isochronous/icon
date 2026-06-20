# ICON-0033 — Architecture Spec

> Author: @architect
> Date: 2026-05-21
> Source: GitLab issue #18 (O-T1, O-T2, O-T3, O-T4)
> Inputs: `plan.md`, `word-count-snapshot.md`

This spec is implementation-ready. Every recommendation names files, line ranges,
and exact replacement text. @coder applies the spec verbatim; no judgment calls
expected.

---

## 1. ADR-008 budget numbers

### Per-session word budget

| Surface | Cap | Baseline | Headroom |
|---------|----:|---------:|---------:|
| Manager session | **8,500 words** | 8,062 | +438 (5.4%) |
| PM session | **7,000 words** | 6,564 | +436 (6.6%) |

**Choice: descriptive-with-modest-headroom, not aspirational.**

Rationale:
- A "trim-to-fit" target (e.g., 7,500 / 6,500) would require deleting load-bearing
  content right now to meet the cap on day 1. ICON-0033 already declares
  common-constraints inlining and AR tables OUT of scope — the two biggest
  reducible blocks. Setting a budget below baseline without a plan for what
  ships first manufactures a debt the next task is forced to absorb.
- A current+10% budget would silently bless any growth up to the cap as
  "within budget" with no friction signal, which is the opposite of what an
  audit ADR is for.
- 5–7% headroom over today's measured baseline is the smallest cushion that
  (a) accommodates ordinary single-line additions to the manager/PM agents
  without immediately tripping the re-audit trigger, while (b) keeping a
  hard ceiling close enough that any structural growth lights up.
- Budget is a **ceiling, not a target**. The ADR Consequences section must
  state explicitly: shipping at 8,062 (manager) is the desired steady state;
  the 438-word cushion exists to absorb minor edits without churning this
  ADR, not as a "spend it" allowance.

### Per-component cap

**Cap: no single always-loaded component may exceed 40% of its session budget.**

At the 8,500-word manager budget:
- 40% threshold = **3,400 words per component**
- Common-constraints (9 × 354 = 3,186 words) = 37.5% ✅ within cap
- Manager agent itself (4,148 words) = **48.8% — exceeds the cap**
- using-skills/SKILL.md (728 words) = 8.6% ✅

The manager.agent.md breach is acknowledged and out-of-scope-by-policy for
ICON-0033 (the issue body's named candidates do not include manager.agent.md
trims). ADR-008 must call this out in Consequences as a **known existing
overage**: the cap is being adopted with one component already over, and
that overage is the next prioritization candidate for the token-economy
audit cycle (next-tier candidate, separate ticket).

At the 7,000-word PM budget:
- 40% threshold = **2,800 words per component**
- product-manager.agent.md (2,650 words) = 37.9% ✅ within cap
- Common-constraints (9 × 354 = 3,186 words) = 45.5% — **exceeds the cap**

PM's common-constraints share exceeds 40% because PM's agent body is
smaller — the same 3,186-word constraints block represents a larger fraction
of a smaller session. Same disposition as the manager overage: acknowledged
existing overage; out-of-scope-by-policy (ADR-004); flagged in Consequences
as the structurally hardest component to trim and the candidate that would
need a constraint-decomposition decision before reduction is possible.

### Re-audit trigger

**Trigger text** (exact wording for ADR Decision section):

> Any merge request that grows the manager session total or the PM session
> total by **≥ 5% of the budget cap** (≥ 425 words for manager, ≥ 350 words
> for PM) must re-run the word-count inventory before merge and update both
> ADR-008 and the snapshot artifact (`.context/tasks/<latest>/word-count-snapshot.md`
> pattern) with the new numbers.

Operational definition:
- **Baseline** = the "Before" column in
  `.context/tasks/ICON-0033-token-economy-trims/word-count-snapshot.md` after
  ICON-0033 lands (this is the ADR-008 effective baseline; the snapshot
  artifact becomes a permanent reference, not a per-task scratch file).
- **"Grows"** = sum of `wc -w` deltas across all files in the always-loaded
  inventory for that session (the per-file rows in the snapshot table). Counted
  in words, not lines. A change can move words between files (e.g., extract a
  block to a new file) without tripping the trigger — only net session growth
  counts.
- **"Re-run the inventory"** = re-execute `wc -l -w` on every file in the
  snapshot's "Always-loaded surface" table; update both the "after" columns
  and the session totals.
- **"Re-audit"** operationally means: (1) refresh the snapshot, (2) edit
  ADR-008 to update the baseline numbers in Consequences, (3) decide whether
  the cap itself needs revision — and either reaffirm or change it with
  fresh rationale.
- **Scope of "always-loaded"**: the surface defined in ADR-008's inventory
  section — manager.agent.md OR product-manager.agent.md (per session),
  plus 9 × shared/common-constraints.md (one inlined block per dispatched
  agent), plus skills/using-skills/SKILL.md. Phase skills, sub-agent files,
  and on-demand skills are NOT in the always-loaded set and do not count
  toward the trigger.

The trigger is **MR-scoped**, not commit-scoped: a single MR's net delta is
what matters. Internal commits within an MR that grow-then-trim are fine.

---

## 2. ADR-008 structural skeleton

@coder drafts the ADR body from this skeleton. Use ADR-007 as the formatting
precedent (Context → Decision → Consequences → Alternatives Considered →
Cross-references). The skeleton below names every required subsection and
gives 1–3 bullets of intended content for each.

```markdown
# ADR-008: Always-loaded session token budget for manager and PM dispatchers

**Date**: 2026-05-21
**Status**: Accepted

## Context

- Audit cycles (ICON-0015, ICON-0033 antecedents) have repeatedly observed
  that the always-loaded dispatcher surface (manager + PM agent bodies plus
  the 9 inlined common-constraints blocks plus using-skills) has grown
  incrementally with no formal ceiling.
- The Brief 06 estimate cited ≈7,865 words for the manager session; the
  ICON-0033 baseline measurement put it at 8,062 — drift of ~2.5% between
  audit cycles with no formal trigger to notice.
- Without a stated budget, every PR that adds a line to manager.agent.md
  looks individually reasonable; the cumulative effect is invisible.

## Decision

- **Per-session word budget**: manager = 8,500 words; PM = 7,000 words.
- **Per-component cap**: no single always-loaded component exceeds 40% of
  its session budget.
- **Always-loaded inventory** (defines the surface the budget governs):
  manager.agent.md OR product-manager.agent.md (per session) + 9 ×
  shared/common-constraints.md (one inlined per dispatched agent) +
  skills/using-skills/SKILL.md.
- **Re-audit trigger**: [insert verbatim trigger text from §1 above].
- **Snapshot artifact**: `.context/tasks/ICON-0033-token-economy-trims/word-count-snapshot.md`
  is the ADR-008 effective baseline. Future re-audits update or supersede it.

## Consequences

**Positive:**
- Growth has a visible ceiling. PRs that approach 5% headroom trigger an
  explicit re-inventory conversation instead of drifting silently.
- The 40% per-component cap caps the worst case where one file consumes
  half the session.
- The snapshot artifact gives reviewers a concrete number to compare an
  incoming PR against, with no extra tooling.

**Negative / known overages at adoption:**
- manager.agent.md is at 48.8% of the manager budget (4,148 / 8,500) — over
  the 40% cap. Acknowledged at adoption; the next token-economy audit
  cycle is the venue for reducing it (out-of-scope here per ICON-0033 plan).
- 9 × common-constraints inlining is 45.5% of the PM budget — over the
  cap. Out-of-scope per ADR-004 (inlining is policy-accepted). A future
  decision to decompose constraints would resolve this; not in scope today.
- Reviewers must apply the trigger check manually; there is no automated
  pre-commit lint counting session totals. (Candidate for a future hook.)

## Alternatives Considered

1. **Trim-to-fit budget (e.g., 7,500 / 6,500)** — rejected. Would force
   immediate trims of load-bearing content with no plan for what to ship
   first; manufactures debt the next task must absorb.
2. **Generous budget (e.g., 9,500 / 7,500)** — rejected. A cap so far above
   the baseline gives no friction signal for incremental growth; the audit
   ADR's whole purpose is the friction signal.
3. **No per-component cap; only session cap** — rejected. Without a
   per-component check, one file can consume the entire session budget;
   the inventory loses its diagnostic value.
4. **Trigger on line count instead of word count** — rejected. Words are
   the unit the token economy actually pays in; lines vary with formatting
   (table cells, code blocks) in ways that don't correlate with token cost.
5. **Trigger on every PR (no threshold)** — rejected. Re-inventorying on
   every documentation typo fix is process-friction with no signal. 5% is
   the smallest threshold that fires only when growth is structural.

## Cross-references

- Baseline measurements: `.context/tasks/ICON-0033-token-economy-trims/word-count-snapshot.md`
- ADR-004: tool-agnostic content; established the common-constraints
  inlining policy that puts 9 × 354 words into every session.
- ADR-005: no build step; precludes auto-generated session size checks.
- GitLab issue #18 (O-T1 audit, O-T2/O-T3/O-T4 trims shipped under same MR).
```

### Decision Log entry

Append to `.context/decisions/README.md` Decision Log table:

```markdown
| [008](008-always-loaded-token-budget.md) | Always-loaded session token budget for manager and PM dispatchers | Accepted | 2026-05-21 |
```

---

## 3. Phase-skill collapse — canonical paragraph text

### Canonical paragraph for `skills/task-plan/SKILL.md`

After reading all five phase-skill Template-override paragraphs, the wording
converges on these elements: (1) the conditional file check, (2) "supersedes",
(3) the customization rationale, (4) the "applies to every section below"
scope clause that prevents per-section restatement. The five files differ
only in the example list in parens (each names the section types it has —
"triggers, delegation templates, or decision capture blocks", etc.).

The canonical paragraph generalizes the example list (since this version
lives in the dispatcher and must apply to all five phases) and keeps the
strongest scope-locking sentence (`This rule applies to every section below;
individual sections will not restate it.`).

**Canonical text** (paste verbatim into `task-plan/SKILL.md`):

```markdown
## task-plan: Template-Override Rule

If the repo has a local `.context/workflows/task-plan/phase-<name>.md`
(for any phase: `phase-investigation`, `phase-architecture`,
`phase-implementation`, `phase-testing`, `phase-completion`), read and
apply it — the local file supersedes the guidance in the corresponding
phase skill (including any triggers, delegation templates, checklists,
decision-capture blocks, or status-tracking tables defined in the skill).
Repos customize these templates to match team conventions. This rule
applies to every section in every phase skill; individual sections do not
restate it.
```

**Insertion point** in `skills/task-plan/SKILL.md`: insert as a new H2
section **immediately after the `## Phase Skills (On-Demand)` table block
(currently lines 19–37)** and **before `## Built-in Format (Fallback)`
(currently line 39)**. The new section heading is `## task-plan:
Template-Override Rule` (line-name-prefixed per `writing-skills`
Step/Phase Heading Format convention).

Position rationale: the phase-skill table is what tells a reader which
phase skill to load; the very next thing they need to know is that local
overrides exist and apply. Putting the rule between the table and the
fallback format puts it on the dispatcher's primary read-path.

### Phase-skill replacements (5 files)

Each file gets the same 5–6 line Template-override paragraph deleted and
replaced with the issue body's one-line pointer (byte-identical across all
five files):

```markdown
**Template-override rule**: apply `.context/workflows/task-plan/phase-<name>.md` if present — see `task-plan` for the full policy.
```

**Exact line ranges to delete and replace** (each replacement preserves
the leading blank line above and the trailing blank line below):

| File | Lines to delete | Replacement |
|------|----------------:|-------------|
| `skills/task-plan-phase-architecture/SKILL.md` | **17–22** (6 lines) | one-line pointer |
| `skills/task-plan-phase-completion/SKILL.md` | **15–20** (6 lines) | one-line pointer |
| `skills/task-plan-phase-implementation/SKILL.md` | **16–21** (6 lines) | one-line pointer |
| `skills/task-plan-phase-investigation/SKILL.md` | **16–21** (6 lines) | one-line pointer |
| `skills/task-plan-phase-testing/SKILL.md` | **16–21** (6 lines) | one-line pointer |

For each file:
- The deletion range starts at the first line of `**Template-override
  rule**: If the repo has a local` and ends at the last line of `individual
  sections will not restate it.` (the closing sentence of the paragraph).
- The replacement is the single pointer line above, byte-identical across
  all 5 files (verify with a final `grep` after edits — all 5 occurrences
  must match exactly).
- The blank line BEFORE the deleted block (separating it from the file's
  intro paragraph) stays. The blank line AFTER the deleted block (separating
  it from the next H2 heading) stays. The pointer line replaces the 6
  paragraph lines between them.

### Net effect

- 5 × ~52-word paragraph (≈260 words) → 1 canonical section (~75 words) +
  5 × pointer line (~22 words = 110 words) = ~185 words.
- **Net word savings: ~75 words.**
- Per-session impact: zero (phase skills are not always-loaded).
  Per-session-with-phase-skill-load impact: ~10 words saved per loaded phase.
- Primary value: single source of truth for the rule; future edits land in
  one place instead of five.

---

## 4. Writing-skills extraction + secondary trim

### Primary extraction (sub-task D as planned)

Extract the **Skill Creation Checklist (TDD-Adapted)** section to a sibling
file:

- **Source**: `skills/writing-skills/SKILL.md` **lines 493–530** (38 lines:
  the `## Skill Creation Checklist (TDD-Adapted)` heading through the final
  `- [ ] Documented in the consuming agent's workflow section ...` bullet).
  - Heading at line 493
  - Last checklist bullet at line 530
  - Blank line 531 separates it from `## Discovery Workflow` at 532
- **Destination**: NEW file `skills/writing-skills/skill-creation-checklist.md`
- **Replacement at deletion site** (single line, replaces all 38 lines):

```markdown
For the full TDD-adapted checklist (RED / GREEN / REFACTOR / Quality / Registration phases) used during skill creation, see [`./skill-creation-checklist.md`](./skill-creation-checklist.md).
```

The destination file gets a minimal H1 wrapper:

```markdown
# Skill Creation Checklist (TDD-Adapted)

> Companion to `writing-skills/SKILL.md`. Loaded only when authoring or
> revising a skill — not part of the writing-skills entry point.

**Use `TaskCreate` to track each phase.**

[... the 37 lines of existing checklist content, verbatim ...]
```

Net delta from primary extraction alone: 38 lines deleted, 1 line added →
**−37 lines**. 549 → 512.

That still misses the < 500 acceptance criterion by 12+ lines.

### Secondary trim (recommendation)

**Recommended**: extract the `## Testing All Skill Types` section to the
existing companion file `skills/writing-skills/testing-skills-with-subagents.md`,
AND remove one redundant line from `## STOP — Before Moving to the Next Skill`.

**Why this combination**:
- The `Testing All Skill Types` section already ends with the line
  `**Full pressure-testing methodology, rationalisation tables, and
  meta-testing technique:** see testing-skills-with-subagents.md.` — its
  content IS a per-type preview of the sibling file's content. Moving the
  per-type bullets into the sibling file consolidates the testing
  methodology where the reader is already directed to go.
- The `STOP` section's last line (`Deploying untested skills = deploying
  untested code.`) restates the Iron Law (`NO SKILL WITHOUT A FAILING TEST
  FIRST`, line 341) and the `Common Rationalisations` table conclusion
  (`All of these mean: test before deploying. No exceptions.`, line 386).
  It is the lowest-loss single-line trim available.
- Neither change touches an anti-rationalization table (load-bearing per
  `.context/standards/anti-rationalization-tables.md`).
- Combined, they get the file under 500 with margin to spare.

**Secondary extraction details**:
- **Source**: `skills/writing-skills/SKILL.md` **lines 359–371** (13 lines:
  the `## Testing All Skill Types` heading through the `**Full pressure-testing
  methodology ...**` final line of the section).
- **Destination**: append to existing
  `skills/writing-skills/testing-skills-with-subagents.md` as a new section
  `## Testing By Skill Type` (rename of the H2 to fit the destination doc's
  own naming).
- **Replacement at deletion site** (3 lines, replaces 13):

```markdown
## Testing All Skill Types

Different skill types (discipline, technique, pattern, reference) need different test approaches. See [`./testing-skills-with-subagents.md`](./testing-skills-with-subagents.md) for the per-type guidance.
```

- Net delta: −10 lines (13 deleted, 3 added).

**Secondary trim detail**:
- **Source**: `skills/writing-skills/SKILL.md` **line 491** (the single line
  `Deploying untested skills = deploying untested code.`).
- **Action**: delete the line and the blank line immediately above it
  (line 490). Net: −2 lines.
- The section keeps lines 482–489 intact (the "Do NOT:" bullet list and
  its lead-in). The closing punch is preserved in the Iron Law and the
  Common Rationalisations conclusion already in the file.

### Combined math

| Step | Lines before | Net Δ | Lines after |
|------|-------------:|------:|------------:|
| Baseline | 549 | — | 549 |
| Primary: extract Skill Creation Checklist | 549 | −37 | 512 |
| Secondary A: extract Testing All Skill Types | 512 | −10 | 502 |
| Secondary B: trim STOP section redundancy | 502 | −2 | **500** |

At 500 lines exactly, the file would still fail a strict `<` 500 check.
**Required**: extract one additional line from the destination of Secondary A
(either drop the new section's blank trailing line, or compress the 3-line
replacement to 2 lines by inlining the heading and pointer on one paragraph):

```markdown
## Testing All Skill Types
Different skill types need different test approaches — see [`./testing-skills-with-subagents.md`](./testing-skills-with-subagents.md) for per-type guidance (discipline, technique, pattern, reference).
```

That replacement is 2 lines (heading + content), one fewer than the
3-line version above. Net of all changes: 549 → **499 lines**. Under 500
with 1 line of margin.

### Verification commands @coder runs after edits

```bash
wc -l skills/writing-skills/SKILL.md         # must be < 500
wc -l skills/writing-skills/skill-creation-checklist.md
grep -c "^## " skills/writing-skills/SKILL.md   # H2 count, sanity check
```

### Alternatives rejected

- **(a) Extract Bulletproofing Discipline Skills (lines 388–458, ~65 lines)**
  to a sibling file. Rejected: that section is the densest load-bearing
  guidance for hardening discipline skills (the most common skill type to
  fail without hardening). Moving it to a sibling file pushes critical
  rationalization-prevention content one click away from the main read-path.
  The 12-line shortfall does not justify the move.
- **(b) Compress prose throughout the Token Efficiency or Discoverability
  sections**. Rejected: these are concrete technique sections with worked
  examples; compressing them either loses the example or loses the rule.
  Both are weaker than extracting a section that has a clear destination.
- **(c) Extract the Skill Creation Checklist plus Bulletproofing both to
  one combined sibling file**. Rejected: combining unrelated content into
  one file ("checklist + bulletproofing") creates a navigational artifact
  with no clear name; the checklist file and the bulletproofing material
  serve different audiences (creation-time vs hardening-time).
- **(d) Reframe the < 500 cap as "≤ 500"**. Rejected: the m-U-G framing
  cited in `word-count-snapshot.md` calls out writing-skills exceeding its
  own self-imposed 500-line cap as the **defining** self-reference
  violation. Adopting "≤ 500" to land at exactly 500 is a definitional
  workaround. The cap is `< 500`; the file must come in under it.

---

## 5. reviewer.agent.md:68 exact replacement

### Confirmation

`agents/reviewer.agent.md` line 68 is:

```markdown
- Review against all six checklist categories (Code Quality, Security, Performance, Testing, Verification, Maintainability).
```

It sits inside the `### Default (On Unless Explicitly Disabled)` bullet
list (lines 65–70). Line 25 already states (in the `## Review Checklist`
section):

> Invoke the `code-quality-rules` skill. It defines the six evaluation
> categories (Code Quality, Security, Performance, Testing, Verification,
> Maintainability), severity levels (Critical / Moderate / Minor), and
> the multi-pass review methodology.

The six-category enumeration on `:68` is a verbatim duplicate of the
parenthetical at `:25`. Confirmed: the issue's claim about `:68` is
accurate.

### Exact edit

- **Line to delete**: `agents/reviewer.agent.md` **line 68** (one line).
- **Replacement** (one bullet at the same indentation, replacing the
  deleted bullet in-place):

```markdown
- Review against all six categories defined in the `code-quality-rules` skill.
```

### Surrounding structure

- The replacement is a single bullet at the same `- ` indentation as the
  surrounding bullets in the `### Default` list (lines 66, 67, 69, 70).
  No indentation adjustment needed.
- No surrounding lines change. The `### Default` heading at line 65, the
  bullets at 66/67/69/70, and the blank line at 71 followed by `###
  Discretionary` at 72 all stay byte-equal.
- The bullet list reads cleanly with the replacement:

```markdown
### Default (On Unless Explicitly Disabled)
- Check for evidence of build/test execution in implementer's report.
- Flag claims lacking evidence.
- Review against all six categories defined in the `code-quality-rules` skill.
- Evaluate test quality and coverage depth.
- Acknowledge good work alongside findings.
```

### Notes

- The issue body's exact wording was *"Review against all six categories
  defined in the `code-quality-rules` skill."* — used verbatim above. No
  refinement needed; the surrounding bullet context accepts it without a
  connector adjustment.
- The dedup eliminates the 6-category list from the bullet point but
  preserves the operational instruction (`Review against all six
  categories`). The behavior is unchanged; the category names are now
  sourced exclusively from `:25` and the `code-quality-rules` skill.
- Word delta: ~14 words → ~14 words; raw savings ≈ 0. The win is
  redundancy elimination, not token count (`reviewer.agent.md` is a
  sub-agent file, not always-loaded). Closes m-A-NET3.

---

## Implementation summary for @coder

| Sub-task | File | Action | Lines |
|----------|------|--------|------:|
| A | `.context/decisions/008-always-loaded-token-budget.md` | CREATE per skeleton in §2 | ~60 |
| A | `.context/decisions/README.md` | Append ADR-008 row to Decision Log table | +1 |
| B | `agents/reviewer.agent.md` | Replace line 68 with new bullet per §5 | 0 net |
| C | `skills/task-plan/SKILL.md` | Insert canonical Template-override H2 after line 37, before line 39 per §3 | +10 |
| C | `skills/task-plan-phase-architecture/SKILL.md` | Replace lines 17–22 with pointer line per §3 | −5 |
| C | `skills/task-plan-phase-completion/SKILL.md` | Replace lines 15–20 with pointer line per §3 | −5 |
| C | `skills/task-plan-phase-implementation/SKILL.md` | Replace lines 16–21 with pointer line per §3 | −5 |
| C | `skills/task-plan-phase-investigation/SKILL.md` | Replace lines 16–21 with pointer line per §3 | −5 |
| C | `skills/task-plan-phase-testing/SKILL.md` | Replace lines 16–21 with pointer line per §3 | −5 |
| D | `skills/writing-skills/SKILL.md` | Extract checklist (lines 493–530), extract Testing All Skill Types (lines 359–371), trim STOP redundancy (lines 490–491) per §4 | −50 |
| D | `skills/writing-skills/skill-creation-checklist.md` | CREATE with extracted checklist content per §4 | +43 |
| D | `skills/writing-skills/testing-skills-with-subagents.md` | Append `## Testing By Skill Type` with extracted content per §4 | +12 |

### Acceptance gates (verify before reporting done)

1. `wc -l skills/writing-skills/SKILL.md` returns a number **< 500**.
2. `grep -c "Template-override rule.*apply.*phase-<name>.md.*see.*task-plan" skills/task-plan-phase-*/SKILL.md`
   returns exactly **5** matches (one per phase skill, byte-identical).
3. `grep -c "Review against all six categories defined in" agents/reviewer.agent.md`
   returns exactly **1** (the new bullet replaces the old enumeration).
4. `cat .context/decisions/008-always-loaded-token-budget.md | head -3`
   shows the correct H1 and Date/Status metadata.
5. ADR-008 row appears in the Decision Log table in
   `.context/decisions/README.md` after ADR-007.
6. `word-count-snapshot.md` "after" columns are populated by the manager
   after @coder finishes (post-implementation step, not a @coder
   responsibility).

### Pitfalls to avoid

- **Do NOT modify `shared/common-constraints.md`** — out of scope per ADR-004
  and the plan.
- **Do NOT touch any anti-rationalization table** — load-bearing per
  `.context/standards/anti-rationalization-tables.md`.
- **Do NOT mirror the new Template-override H2 into
  `.context/workflows/task-plan/base.md`** — the three-surface-sweep rule
  does not apply here (we are moving an existing skill paragraph into a
  sibling skill, not changing process policy). Plan §Constraints already
  notes this; verify by grep before adding to base.md.
- **Pointer line in §3 must be byte-identical across all 5 phase files** —
  the issue body specifies the exact text; do not paraphrase.
- **Do not move common-constraints inlined blocks** — they ship via the
  pre-commit hook; manual edits to `<!-- BEGIN: common-constraints --> ...
  <!-- END: common-constraints -->` ranges will be overwritten.
