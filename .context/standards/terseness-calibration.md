# Terseness Calibration — Concision Passes on Instruction Content

A concision/terseness pass on ICON's own instruction content (agent bodies, skills, always-loaded surfaces) is a distinct task class from an edit that changes behavior. Its whole purpose is to remove words, so the usual "keep it verbatim" fidelity instinct — which caps the edit at the thin surface of unprotected prose — defeats it. This standard defines the guardrail, the target, and the verification for a concision pass. (ICON-0083; prior art: ICON-0033 token-economy trims, governed by ADR-008 always-loaded token budget.)

## 1. The guardrail is BEHAVIOR preservation, not verbatim WORDING

For a concision task the invariant is that every rule, trigger, gate, table-row, and STOP still **binds identically** — not that the words are unchanged. The words shrink hard, **including inside tables, anti-rationalization rows, Hardcoded lists, and contract prose**. Treating those categories as "keep verbatim" is the mistake that collapsed the ICON-0083 first pass into a −2% non-result; the maintainer's correction was that a peer had reduced the manager 15–20% with no behavior impact. A fidelity metaphor ("JPEG-95") applied without this distinction collapses into "barely touch anything."

Only truly **literal, string-matched tokens** stay byte-verbatim — because some other mechanism matches on the exact bytes:

- hook / gate markers (`<!-- BEGIN: … -->` / `<!-- END: … -->`, `<!-- pre-commit:dead-ref-ok… -->`, the `## <skill>:` line-name prefixes a check greps for);
- script-parity byte-identity (the `.sh`/`.ps1` script pairs; the nine inlined `common-constraints` copies the pre-commit hook syncs);
- `iconrc.json` schema keys and other JSON field names;
- cited `.context/` paths (resolved by the graph and dead-ref gates);
- the `## Related` links and `**Supersedes**` / `**Superseded-by**` seam fields the knowledge graph keys on;
- `description:` frontmatter lines other tooling matches on.

Everything else — the *explanation* of a rule, the *phrasing* of a table cell, the *prose* around a gate — is fair game to compress, provided the rule it expresses still binds the same way.

## 2. Set a word-count TARGET, not just a fidelity metaphor

Give the pass a concrete **word-count target** (~15–20% reduction on verbose always-loaded files) so the reduction is measurable and the pass can tell whether it did its job. A metaphor alone under-calibrates; a number calibrates. Measure with `wc -w` before/after per file (the ADR-008 always-loaded inventory + snapshot pattern). Note the target is a goal for a terseness task and is distinct from ADR-008's word budget, which is a *ceiling* on growth — the two are complementary: the target drives a deliberate reduction, the ceiling catches later drift.

## 3. Verification invariants — proving reliability was preserved with no test runner

ICON has no test runner, but "reliability preserved" is still verifiable on a concision diff. Check, per batch:

- **discipline / anti-rationalization table row-counts unchanged** — a compressed table must keep every row (a dropped row is a dropped rule);
- **`description:` frontmatter byte-identical** — the skill/agent routing surface must not shift;
- **parity scripts byte-unchanged** — `.sh`/`.ps1` pairs and the inlined `common-constraints` copies stay in sync;
- **gates green** — `context-graph --check` and `check-rules-index.sh` both exit 0, and a real `.githooks/pre-commit` run passes;
- **an adversarial reviewer confirms meaning-not-words** — a second agent re-reads each changed rule line-by-line and confirms the binding is identical, not merely that the diff "looks smaller."

Both ICON-0083 reviewers approved a ~98-file, ~−4,800-word diff against these invariants with zero behavior drift.

## 4. Don't de-duplicate deliberate reinforcing redundancy without maintainer sign-off

Some repetition is reliability-load-bearing, not accidental bloat — e.g. the manager's close-gate stated across multiple enforcement tiers (Step 6 + its Hardcoded mirror + the anti-rationalization row). The repetition is what makes the rule hold under pressure. **Do not collapse it as part of a concision pass** without explicit maintainer sign-off; surface the size-vs-reinforcement tradeoff instead of unilaterally cutting the reinforcing copy. (ICON-0083 stopped the manager reduction at −13.1% rather than de-dup the tiered close-gate restatement, and put the call to the user.)
