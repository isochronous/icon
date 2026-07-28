# ADR-016: Skill hot path / cold path separation — per-file byte caps

**Date**: 2026-07-27
**Status**: Accepted
**Supersedes**: none
**Superseded-by**: none

## Context

**This is a correctness problem before it is an efficiency problem.**

Claude Code's published skill semantics state that when a conversation is summarized to free
context, the harness re-attaches the most recent invocation of each skill after the summary,
**keeping only the first 5,000 tokens of each**, and that re-attached skills share a combined
**25,000-token** budget.

`skills/upgrade-repo/SKILL.md` measures **92,797 B ≈ 23,000 tokens** (÷4). That is **~4.6× past the
5,000-token retention cap**, so roughly **78% of the file is silently dropped on every compaction
today** — no error, no warning, no signal to the agent that it is now operating on a truncated
procedure. A `/upgrade-repo` run is long and multi-phase, so compaction mid-run is likely, and the
content most likely to be dropped is the late-phase conditional material that decides what gets
written to a consumer's repo. **A skill that cannot survive its own runtime is broken independently
of what it costs.** Six other shipped `SKILL.md` files are over the same cliff.

The efficiency argument is real but secondary: on invocation only the rendered `SKILL.md` body
enters context, and companion files enter **only** if the model subsequently issues its own `Read`.
The split is mechanically real, not cosmetic.

Two further facts shape the fix rather than motivating it:

- **References must stay one level deep from `SKILL.md`.** A file discovered *from* another
  referenced file degrades into a **silent partial read** (the model may `head` it rather than read
  it whole). So the decomposition must be a flat fan-out, never a tree.
- **The repo already carried nine overlapping size rules in four units, exactly one of them
  enforced**, including a live 3.3× contradiction: `writing-skills` said "under 500 lines" while
  `skill-decomposition/skill-structure.md` said "~150 lines or fewer". A rule that a quarter of the
  corpus breaks (the "< 500 words" standard-skill rule, violated by 13 of 49 shipped skills)
  governs nothing. Adding a tenth rule in a fifth unit would make this worse; this ADR retires the
  contradicting statements rather than sitting beside them.

## Decision

### Unit: bytes

Measured with `wc -c`. Bytes reuse the constant and unit `context-document-guidelines` already
applies to `.context/` docs rather than adding a fifth; convert to tokens by a stable public
constant (÷4) where words have none (1.3–1.5, unstable); and `wc -c` is POSIX with zero
dependencies (ADR-005). **Lines are retired entirely** — ADR-008 and `context-document-guidelines`
independently rejected them, and lines are the unit of the contradiction above. The repo ends with
**two** units, each with a stated domain: words for the always-loaded surface (ADR-008), bytes for
on-demand skill files (this ADR).

### The caps, with provenance

| Gate | Cap | Provenance |
|---|---|---|
| Every `SKILL.md` | **16,000 B** | **Derived** — 4,000 tokens is 80% of the documented 5,000-token compaction retention cap, leaving 20% for the harness wrapper. Six such skills total 24,000 tokens, inside the 25,000-token combined re-attach budget. Coincides with the existing `.context/` folder-split constant, so one number governs both domains. |
| Every companion `.md` | **8,000 B** | **Empirical** — the median well-formed companion in this corpus is ~5,100 B and 25 of 30 sit between 1,200 B and 7,000 B. 8,000 B is the top of the healthy observed band. |
| Floor — do not create a companion below | **2,000 B** | The anti-confetti stop, and what makes the cohesion test below *terminate*. |

Each cap is labelled with its provenance so a future reader knows which one moves if something
changes: the `SKILL.md` cap is a function of the harness's retention constant and moves if that
constant moves; the companion cap is a function of this corpus and moves if the corpus does.

**Sensitivity, stated.** The 16,000 B cap keeps `SKILL.md` under the retention cliff for any true
ratio of **≥ 3.2 B/token**; at ÷4 there is 20% margin. If a measurement disagrees, only the
constant moves, not the structure of the rule.

### Two gates, conjunctive

- **Gate 1** — the byte cap above. Mechanical.
- **Gate 2** — does the file contain **≥ 2 regions guarded by a condition statable in one
  sentence, each ≥ 2,000 B**? Counting `##` sections would be vacuous; every skill has three or
  more by template.

Gate 2 is deliberately **not** mechanically checkable; the advisory hook's job is to make the author
answer it, exactly as `context-document-guidelines § Folder Split Rule` does for `.context/` docs. A
genuinely unconditional oversized skill records the finding and stays whole — the corpus already
shows the conjunction earning its keep: `context-specialist-impl-leaf/step-4-file-content.md`
(9,382 B) trips gate 1 and fails gate 2.

### Granularity: three tests, in order

The unit of extraction is **one if→then block** — everything needed when a condition holds, and
nothing else. The failure mode designed against is a companion bundling two branches, so taking
branch A drags B into context anyway: you pay the indirection *and* still load the bulk.

1. **Scope** — is the condition resolved once per *invocation*, or once per *item the invocation
   iterates over*? Only invocation-scoped conditions may be extracted.
2. **Cohesion** — is there any invocation that loads the companion and uses only *part* of it? If
   so it bundles more than one condition and must split — **bounded by the 2,000 B floor**.
3. **Coupling** — is there any pair of companions always loaded together? If so they are one
   condition and must merge.

The floor is what makes this terminate: without it, cohesion fragments indefinitely, since almost
any procedure has a step some run skips.

### Shape: strict depth-1 flat fan-out

Companions are leaves; none references another. Where two need the same fact, duplicate the line or
promote it to `SKILL.md` — never cross-link. Pointers are a **bare backticked sibling filename**,
the condition is stated **twice** (a required `## Companion Files` manifest with a `Load when`
column, and inline at the branch point), and companions carry no frontmatter. The full authoring
spec is `.context/standards/skill-decomposition/hot-cold-path.md`.

### Scope

Shipped `skills/` **and** `.claude/skills/` — identical failure mode, same harness, same
compaction, and free to include (measured violation population there is zero; largest maintainer
`SKILL.md` is 12,839 B). **Excludes `context_template/context/workflows/task-plan/`**: it is not a
skill, it is already governed and already exempt under `context-document-guidelines`' split
exemptions (it is a fixed-shape scaffold whose headings are a parse contract — a record, not
instruction), and touching it would force an `iconrc.json` bump for zero benefit.

### These caps admit no record exemption

`context-document-guidelines § Folder Split Rule → Split Exemptions` exempts a `.context/` file
that **records** — a log, a snapshot, an ADR, a `README.md` index, a fixed-shape scaffold — from
its 16,000 B folder-split gate at any size. **That exemption does not reach these caps, and no
file under `skills/` or `.claude/skills/` qualifies for it.** A skill exists to tell an agent what
to do; that is what invocation means and what its `description` frontmatter advertises. An
oversized companion is therefore never "reference material, and therefore a record" — a data table,
a template set, or a body of reference prose inside a skill is still material the agent is being
instructed to apply, and the correct remedy is the condition-wise split above, which is always
available to it.

**The two rules differ because their failure modes differ, not as a courtesy.** The `.context/`
gate is a *findability* rule: an oversized instructional file buries its own rules, and the remedy
is a topic split. Against a record that remedy is unavailable or destructive — a record's length is
a function of accumulation rather than authorial sprawl, it is consulted by lookup rather than read
end to end, and splitting it fragments the chronology, index, or decision that is the reason to
keep it. These caps answer a different failure: an injected `SKILL.md` past the harness's retention
cliff is **silently truncated at runtime**. Truncation does not care what kind of content it cuts,
so nothing about being a record would earn relief from it even if a skill could be one.

**That truncation reason carries the `SKILL.md` cap only, and is not what forecloses the companion
case.** A companion is not injected; it enters context on a model-issued `Read`, so the retention
cliff does not act on it, its 8,000 B cap is empirical rather than derived, and whether a separately
read companion counts against the 25,000-token re-attach budget is unsettled. The companion half of
the boundary rests entirely on the primary argument above — a skill is instructional by definition —
which is independent of the harness's retention behaviour and dispositive on its own.

**This ADR is itself exempt from the `.context/` gate**, as an ADR, which resolves a review finding
raised when it measured 15,467 B against that gate's 16,000 B threshold — 96.7% of a cap it shares,
on a document whose promotion condition and violation baseline are both designed to be edited later.
Remediation has since carried it past the threshold (20,245 B on 2026-07-27; re-measure with `wc -c`
rather than citing that figure), which is exactly the point: the exemption is what makes those
sections safe to extend.

**The exemption changes nothing about this file's disposition, which is why it is not
self-serving.** This ADR was never splittable. Its four peer `##` sections — Context, Decision,
Consequences, Alternatives Considered — are the ADR template's facets of one decision, so it
**fails gate 2** on exactly the reasoning the split exemptions give for ADRs generally. Under the
pre-existing rule (gate 1 fires, gate 2 fails → record the finding and leave the file whole) the
outcome was already "do not split". The exemption's entire practical effect here is to suppress a
maintenance-report line item.

It grants this file no relief from anything in `skills/`, and none of the caps above move.

### Enforcement: advisory now, fail-closed on a stated condition

The gate ships **advisory** — it prints the finding and the two-gate question, and does not block
the commit. `.githooks/pre-commit` is opt-in per clone and `--no-verify`-bypassable, and
`.github/workflows/` re-runs none of its ten checks, so a fail-closed gate here would raise surface
without raising the guarantee. **Promotion condition: the gate becomes blocking once issue #24
lands a CI backstop that re-runs the pre-commit check set.** No other condition promotes it.

### Retirements (this ADR is a consolidation, not an addition)

- `skills/writing-skills/SKILL.md`: the "split into supporting files beyond that" 500-line cap
  clause and the "Standard skills: < 500 words" target are deleted; the `wc -w` verification
  becomes `wc -c` against the 16,000 B cap; the remaining word targets are reworded as explicit
  targets, not gates.
- `.context/standards/skill-decomposition/skill-structure.md`: the "~150 lines or fewer" cap is
  deleted; the content-*type* trigger ("templates ≥ 100 lines, reusable scripts, or per-domain
  dispatch briefs") is replaced by the byte gate — that trigger is precisely why the rule never
  caught `upgrade-repo`, which has no templates and no scripts, only procedure; a stale
  line-number citation into `writing-skills/SKILL.md` is removed.
- `context-document-guidelines`' 16,000 B `.context/` folder-split rule survives with its
  threshold unchanged. Its **exemption test** was re-axised in the same task, from two enumerated
  arms (historical record / distributed template) to a single question — *does the file instruct,
  or does it record?* — which widened the exempt class to cover ADRs and `README.md`. That change
  governs `.context/` only and does not touch the caps below; see the next section for why the two
  rules have different exemption sets.

### Relationship to ADR-008

**Peer, not amendment.** ADR-008 caps the *always-loaded session contribution* in words; this ADR
caps *single-file compaction survivability* in bytes. On the one file in both scopes
(`using-skills`) they are provably non-contradictory and this ADR is strictly tighter:
16,000 B ÷ ~7.1 B/word ≈ 2,250 words, below ADR-008's 3,400-word per-component cap. ADR-008's
exclusion of on-demand skills was a deliberate scope line, not an error, so it gains a
cross-reference and no `## Amendments` entry.

### Portability: designed for, untested

ADR-004 requires content to work on both Claude Code and Copilot CLI. Everything above is
established for Claude Code from its published documentation. **Copilot CLI's skill-loading
semantics are entirely unestablished** — not whether it renders only `SKILL.md`, not whether it
resolves a bare sibling filename, not whether it eagerly loads a skill directory. Two-harness
portability is therefore **designed for and untested; it must not be described as verified.**
Settling test: run one split skill under Copilot CLI on one triggering and one non-triggering
prompt and observe whether the companion is read only on the triggering run. The bare-filename
pointer was chosen partly because its failure mode degrades gracefully under exactly this
uncertainty (see Alternatives 4).

## Consequences

**Positive:**
- The seven `SKILL.md` files that cannot survive compaction are now identified by a rule rather
  than by an audit, and the rule states what to do about each.
- Nine size rules in four units become two rules in two units, each with a named domain.
- The `## Companion Files` manifest makes a skill's load graph auditable — the only such construct
  available, since `context-graph` does not see `skills/` at all.

**Negative / known violation population.** Baseline measured 2026-07-27 **before** this task's
proving-case split — this is the population that motivated the rule, not a live inventory. Re-run
`wc -c` rather than citing these numbers as current.

- **11 findings across 8 distinct skills.** Seven `SKILL.md` over 16,000 B: `upgrade-repo` 92,797,
  `writing-skills` 23,301, `context-document-guidelines` 22,518, `context-maintenance` 18,842,
  `initialize-multimodule` 18,634, `context-specialist-impl-leaf` 18,517, `rfc` 18,418. Four
  companions over 8,000 B: `writing-skills/anthropic-best-practices.md` 38,305,
  `generate-phase-launcher/references/launcher-templates.md` 23,043,
  `writing-skills/testing-skills-with-subagents.md` 13,709,
  `context-specialist-impl-leaf/step-4-file-content.md` 9,382. `.claude/skills/` contributes zero.
- **This task resolves exactly one of the eleven**: `context-document-guidelines`, the proving case,
  splits to a compliant `SKILL.md` plus three companions all inside both caps. Every other violation
  is a recorded follow-up, so the corpus is knowingly non-compliant on adoption day and the advisory
  gate will fire on files nobody is fixing this week. Accepted deliberately: the alternative is a
  multi-week split campaign gating a rule that is already correct.
- **`upgrade-repo` is deferred behind issue #23.** Its platform axis cross-cuts its mode axis
  completely — all eight PowerShell fences sit inside mode-conditional regions — so splitting both
  multiplies to ~16 files where a post-#23 design needs ~5, and a correct split today still leaves
  it over the cap. Only #23 brings it under.
- **The line-unit retirement covers ICON-authored content only.** "Lines are retired entirely" and
  "nine size rules in four units become two rules in two units" are true of the rules ICON writes
  and enforces, not of every line-count sentence in the tree. Three survive in
  `skills/writing-skills/anthropic-best-practices.md` — under *Progressive disclosure patterns*,
  under *Token budgets*, and as a *Core quality* checklist item — in a file that is a **verbatim
  vendored copy of Anthropic's published guidance** and is not ICON's to rewrite. A precedence note
  at the head of that file records that this ADR's byte cap supersedes them for ICON skills. That is
  **mitigation, not removal**: an author working through that companion still reads "under 500
  lines" three times.
- **`writing-skills` teaches the rule while violating it**, and this task made it slightly worse:
  wiring the new rule into it cost a net ~1 kB against a file already ~1.5× over the cap, plus two
  oversized companions. Named here so it is not read as an oversight; fixing it is a follow-up.
- Gate 2 is a judgement call every author must make; the hook can prompt for it but cannot check
  it.

## Alternatives Considered

1. **Measure the directory total instead of per-file — rejected, and this reverses an earlier
   position in this task's own plan.** A directory-sum gate set low enough to catch the proving
   case flags **`plugin-design` at 35,832 B** — the corpus's best-decomposed skill, a 3,164 B pure
   router over ten cohesive companions, and the exemplar this whole standard is built on — as a
   *worse* offender than the 22,518 B proving case. A standard whose own model fails it is not a
   standard. The two per-file caps are strictly better: they catch everything the sum catches
   (`writing-skills` trips them four times, and *names which four files*), they are ungameable
   (bulk moved out of `SKILL.md` must land in cohesive ≤ 8,000 B pieces — compliance, not evasion),
   and they do not punish correct decomposition (`plugin-design`'s largest companion is 6,491 B;
   all ten pass). Recorded explicitly because the directory-total measure was adopted before the
   architecture pass reversed it, and an unrecorded reversal gets re-proposed.
2. **Cap `SKILL.md` alone — rejected.** Provably gameable, and worse, it *incentivises* the exact
   bundling defect this ADR designs against: it rewards moving bulk anywhere, including into one
   giant companion. The per-companion cap is the anti-gaming construct.
3. **Lines, or words, as the unit — rejected.** Lines are the unit of the live contradiction and
   were independently rejected by ADR-008 and `context-document-guidelines`. Words have no stable
   bytes-to-token constant. Note that words were *not* rejected for undercounting fence-heavy
   files: that concern was tested and **refuted at file scale** (bytes-per-word spans 6.79–8.06
   across 0%–79% fence density, a 19% spread against a 29× size spread).
4. **`${CLAUDE_SKILL_DIR}/x.md` pointers — rejected.** Documented-portable within Claude Code only,
   and its failure mode is unrecoverable: an unsubstituted pointer is a literal `$`-string naming
   no file. A bare `` `x.md` `` degrades to a legible filename the model can glob. Under ADR-004,
   with Copilot CLI semantics unestablished, graceful degradation decides it. Adoption cost is
   zero — all five existing precedents already use bare filenames.
5. **Amend ADR-008 to cover on-demand skills — rejected.** Nothing in ADR-008 went stale; its
   exclusion of on-demand skills was a deliberate scope line. The two ADRs constrain different
   quantities in different units for different reasons, which is a peer relationship.
6. **Ship the gate fail-closed immediately — rejected.** Issue #24 states that adding a gate to an
   unbacked, bypassable, opt-in stack raises surface without raising the guarantee, and that the CI
   backstop must land first. Advisory now, with the promotion condition written down, gets the
   authoring signal without the false assurance.
7. **Extend the rule to `context_template/context/workflows/task-plan/` — rejected.** It is not a
   skill (no `SKILL.md`, no frontmatter, no invocation), it is already governed and already exempt
   under `context-document-guidelines`' split exemptions as a fixed-shape scaffold, and touching it
   forces an `iconrc.json` bump for zero benefit.
