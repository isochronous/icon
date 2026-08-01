# Challenging a Recorded Decision

`.context/` records that a decision **was made**. It is not evidence the decision was **right**.

Three standards already cover claims that fail on their evidence: [claim-scope](claim-scope.md) (a
sound measurement written up too widely), [verify-design-claims-against-artifacts](skill-decomposition/verify-design-claims-against-artifacts.md)
(a design's claim about another artifact, relied on without checking it), and
[harness-trust](harness-trust.md) (a verification result that is itself untrustworthy). **This
standard covers the fourth case: the record is a decision, it was read correctly, it was applied
faithfully, and the decision was wrong.**

That case resists the other three because nothing looks unverified. An ADR is the artifact you would
cross-check *against*. Reading it more carefully returns the same wrong answer, so the failure is
not caught by verifying harder — it is caught by noticing that following the rule keeps costing
something.

## The Rule

**A rule you are working around is a rule to question.** When a task finds itself restructuring
work, accepting a restriction, or building scaffolding in order to keep satisfying a recorded
decision, stop and ask whether the decision is correct — before adding the next workaround.

Questioning is cheap and does not require being right. The output is a stated challenge with the
evidence behind it, which either dissolves or produces a superseding record.

## Two Signals

### Signal 1 — you are working around it

Count the workarounds. One is a cost; a third is a finding.

ICON-0099 applied ADR-017's inline-`node -e` default through six review rounds and an opened PR, and
worked around it three ways without any of them registering:

| Workaround | Where |
|---|---|
| Program output messages rewritten to remove apostrophes, so the "unavoidable apostrophe" trigger would not fire | `wave-1-classification.md:113` — *"rephrasing is required, not optional… the coder must not carry the apostrophes across and then reach for a `.mjs`"* |
| Fences extracted from markdown and re-run as shell words, because nothing could be tested where it lived | `plan.md:41` |
| Three cross-fence state chains restructured so the trigger's condition became *"literally false"*, avoiding a `.mjs` | `plan.md:113` |

The third is the instructive one: it also fixed a real dead-code defect, so it read as a win. **A
workaround that produces a genuine improvement is the hardest kind to notice**, because nothing
about it feels like a concession.

### Signal 2 — a specialist reports the rule as a blocker

A blocking finding from a specialist is a lead, not a verdict. Ask for the **measurement that
establishes the block**, not for the finding again.

ICON-0099's @architect reported that ADR-017's Node-absence precondition blocked 12 of 19
conversions. Re-dispatched to measure the premise instead — `node` off `PATH`, inline versus `.mjs`,
on bash, PowerShell 7 and Windows PowerShell 5.1 — the two forms were byte-identical on all three
channels (`plan.md:54-62`). The precondition was gating the better mechanism on a hazard both forms
share. **The blocker dissolved on one measurement**, and it turned out to be a second instance of
the same misfiling the task was already correcting.

## The Evidence Is Usually Already Yours

In both ICON-0099 instances the evidence to overturn the rule was **already inside the task's own
artifacts** before anyone looked for it. The PowerShell 5.1 defect (#62) was measured by the @tester
in the first review round and exists only because a program passed as a single-quoted shell word
loses its embedded quotes (`plan.md:39`) — a defect of the delivery mechanism the rule mandated. The
apostrophe restriction sat in both of that brief's trigger tables as a routine `No` verdict
(`wave-1-classification.md:113`, `:331`) — a language restriction imposed by the delivery mechanism,
recorded twice and questioned neither time.

**A rule read as authoritative stops being read as evidence.** When you re-read a record to check
your compliance, also read it as a claim: does what this task measured support it?

## Anti-Rationalization

| Excuse | Reality | Correct Action |
|---|---|---|
| "It's an ADR — it was reviewed and decided" | Review establishes that reasoning was inspected, not that it was correct. ADR-017 was applied by two architecture-grade dispatches that produced trigger-verdict tables and never asked whether the default was right | Read the record's *argument*, not just its rule, and check the argument reaches the obligation |
| "Changing it is out of scope for this task" | The task that keeps paying the rule's cost is the one holding the evidence. Deferring hands the next task a workaround with no reason attached | State the challenge with its evidence now; the maintainer decides whether it is worked now |
| "The specialist looked at this in depth and says it blocks" | Depth is not measurement. A confident blocking finding can be an inherited premise stated with authority | Ask for the measurement that establishes the block, on the specific cases claimed |
| "The workaround is fine — it even improved things" | An improvement obtained *in order to keep satisfying a rule* is still a workaround, and is the kind least likely to be counted | Count it. Three workarounds is the signal regardless of whether each was individually worthwhile |
| "I'd be second-guessing a maintainer decision" | The cost of a stated, evidenced challenge is one paragraph; the cost of an unchallenged wrong rule is every task that obeys it | Write the challenge and the evidence; let it be rejected on the record |

## When the Challenge Holds

Correct the record — do not leave the finding in a task artifact where it dies with the task. Pick
the form per the `context-document-guidelines` skill's `correcting-a-stale-adr.md`: amend when the
Decision stands, scope-supersede when part of it falls, supersede when it does not survive.
ICON-0099 scope-superseded ADR-017 with ADR-018 because two of its clauses fell and the rest stood.

Note the ordering trap: this standard tells you to challenge a record, and
[claim-scope](claim-scope.md) governs the sentences you then write about it. A challenge is itself a
claim, and the correction that lands is prose about a state your own task is changing.

## Related

- See also: [claim-scope](claim-scope.md) — a sound measurement over-generalized in prose; here the
  measurement was never made because the record answered the question
- See also: [skill-decomposition/verify-design-claims-against-artifacts](skill-decomposition/verify-design-claims-against-artifacts.md)
  — a claim relied on *without* verification; this standard covers a decision that was verified as
  written and is wrong on its merits
- See also: [harness-trust](harness-trust.md) — the tool reporting the result cannot be trusted;
  here the tooling is sound and the governing rule is not
- Worked example: [ADR-018 the body test, program vs command](../decisions/018-body-test-program-vs-command.md)
  — the record produced by challenging [ADR-017](../decisions/017-executable-content-home.md)
