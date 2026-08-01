# Correcting a stale ADR: amend, scope-supersede, or supersede

An ADR records a **decision**, not a snapshot of the repo. When one goes stale, the disposition
turns on a single question: **did the position change, or only the world it described?**

| What went stale | Disposition | Mechanism |
|---|---|---|
| A supporting fact, a consequence, or a rejection's stated grounds — the Decision still holds | **Amend in place** | Correct the prose and append a dated `## Amendments` entry. `**Status**` stays `Accepted`. No new ADR. |
| One sub-decision is now decided differently; the rest stands | **Scope-supersede** | New ADR plus scoped bold-fields in both directions. The old Decision prose is left intact. |
| The Decision itself no longer holds | **Supersede** | New ADR plus bold-fields; the old ADR's `**Status**` becomes `Superseded by ADR-NNN` and its content freezes. |

**Do not supersede an ADR whose Decision still stands.** `**Supersedes**: ADR-NNN` asserts that a
later decision replaced an earlier one; where no such decision was taken, the record manufactures a
deliberation that never happened. Superseding also *freezes* the old ADR — a superseded ADR is a
point-in-time snapshot, and therefore exempt from the folder-split gates — which is wrong for a
record other documents still cite as the live rule, and it leaves the stale text in place for
anyone who lands on it directly, adding a hop rather than removing the error.

**An amendment must not erase what was believed.** Every correction gets an `## Amendments` entry —
dated and task-attributed — naming what the text said, what is true, and, where the original
reasoning was wrong rather than merely overtaken, why. Git history is the exhaustive record; the
`## Amendments` section is the discoverable one.

**Proportionality.** An `## Amendments` entry is owed when the corrected text was load-bearing —
a reader could have acted on it. A typo, a renamed skill, or a stale path is corrected in place
with no entry. Correcting one ADR's passing summary of *another* ADR's scope does count as
load-bearing: that is exactly the kind of sentence a reader acts on.

**Verify the replacement, not just the error (ICON-0091).** A correction pass is not
self-verifying. Every assertion written *into* an ADR — including one written to replace a false
one — needs checking against the repo, and every citation needs reading the cited file to confirm
it says what the sentence claims. The failure mode is concrete: an amendment corrected five
unsourced claims and introduced a sixth, attributing to a neighbouring ADR a rule that ADR never
stated. Prefer a description of what the repo does, with known gaps named as gaps, over a
universal ("only in X", "always Y") that one counter-example falsifies.

**That preference is not self-executing — run the procedure (ICON-0099).** Stated as a preference,
this paragraph was violated five times in one task, including by the round that was citing it. The
executable form is the **claim-scope** standard: before writing any sentence containing *every /
never / only / all* or an unqualified present-tense claim about repo state, attempt to construct a
counter-example and **record what you tried**. It applies to any authored artifact, not only an
ADR — the five ICON-0099 instances were spread across ADR prose, skill prose, and a code comment.
The tense trap is specific to this file's subject and worth naming here: a correction written
*after* the commit that fixed the thing it describes still reads false if it keeps the present
tense. Check the working tree at the moment of writing, not the state you remember investigating.

**When a claim resists repeated correction, remove it instead of correcting it again
(ICON-0091).** Some facts have no reliable representation to verify against, and no amount of
careful re-checking converges on one. The same ADR-005 correction stated a count of unpaired
shell scripts four times and got it wrong four times (6, 7, 8, against an independently rebuilt
9), and one file evaded five successive passes, three of which explicitly verified "against the
repo" — because "the set of committed scripts" has no single cheap derivation: a file-extension
glob misses the extensionless git hooks, a shebang grep matches a markdown file's fenced code
block, and directory membership misses the copies distributed under `context_template/`. This
generalizes beyond ADRs to any `.context/` content doc: when a fact keeps resisting correction
across multiple independently-verified passes, suspect the claim is not representable rather
than that the last reader was careless, and **remove the assertion rather than attempting
another correction**. State where something lives — a directory, a derivation command with its
known blind spots named — instead of inventorying what currently exists; see ADR-005's Context
section for the worked example.

## The `## Amendments` section

- **Placement is fixed: the LAST `## ` section of the ADR.** Entries accumulate in date order,
  newest last, so the section reads as a chronological log.
- **Format: a bold dated, task-attributed lead-in, then the corrections.** `**YYYY-MM-DD
  (TASK-ID).**` followed by a sentence stating whether the Decision changed (for an amendment it has
  not), then the corrections themselves — each naming the section, quoting what the text said, and
  stating what is true. **An entry correcting two or more things uses one bullet per correction**,
  so each stays separately readable and separately checkable; an entry correcting a single thing may
  instead be a short prose paragraph. **Quote the original erroneous text verbatim** either way —
  the quoted text is often the only explanation for how the same error spread to other documents.
- **It is a record appended to a live rule, not a second topic** — like a `## Related` footer. It
  does **not** violate one-facet-per-file, and it is **excluded from the folder-split gate (2)**
  section count. Its bytes still count toward gate (1); an ADR whose amendments log has genuinely
  outgrown the record is a sign to prune superseded entries, not to split the ADR along its
  amendment history.
