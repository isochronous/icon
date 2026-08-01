# Claim Scope — A Sentence May Not Outrun Its Measurement

Two standards already cover claims that were never checked: `skill-decomposition/verify-design-claims-against-artifacts.md`
(a design's assertion relied on without verification) and `harness-trust.md` (a verification result
that is itself untrustworthy). **This standard covers the third case: the measurement was made, it
was correct, and the sentence written around it asserted more than it licensed.**

That case is not caught by verifying harder. Verification already happened. What fails is the step
after it — turning a measured observation into prose — and it fails in a way that reads as
authoritative, because a real number sits next to it.

## The Rule

**Before writing a sentence that contains `every`, `never`, `only`, `all`, `always`, `none`, `any`,
or an unqualified present-tense claim about repo state: try to construct a counter-example, and
record what you tried.**

The recorded attempt is the whole mechanism. This rule existed as a preference for four ICON-0099
review rounds — *"prefer a description of what the repo does over a universal that one
counter-example falsifies"* — and did not fire once, including in the round that was citing it. It
started working the moment a dispatch demanded the attempt **as a deliverable**. A rule phrased as
a disposition is advice. The same rule phrased as a step with an output is a procedure.

Three outcomes, all acceptable, one required:

| Outcome | What to write |
|---|---|
| You built a counter-example | Narrow the sentence to the case you actually measured. Name the counter-example — it is usually the more useful half. |
| You tried and could not | Keep the universal, and say what you tried. A reviewer can then attack the attempt rather than re-derive the whole claim. |
| You cannot state the boundary at all | Drop the generalization. Describe what the repo does; leave the universal unwritten. |

## Two Shapes This Takes

**Scope inflation — the measurement is narrower than the sentence.** ICON-0099 produced five in one
task, each falsified by a reviewer in under a minute:

| Measured, correctly | Written, falsely |
|---|---|
| One copy of a duplicated block had diverged | *"two copies already drifted"* |
| YAML folding is load-bearing for the description check | *"changes no outcome for this block"* — false for an empty block scalar, in the false-pass direction |
| `rglob` yields a symlinked directory without recursing | *"matching `pathlib.rglob`"* — false for a Windows junction, and **silently**: a subtree went unscanned while three sibling blocks saw it |
| The migrated fences fail loudly on PowerShell 5.1 | *"never with a wrong answer"* — false wherever silence is the pass |

Note the pattern in the third and fourth rows: the counter-example is not merely an exception, it is
the *dangerous* case. A universal is most often falsified precisely where the failure is quiet.

**Tense drift — a present-tense claim about a state your own task already changed.** ICON-0099's
correction to a stale ADR was written 14 seconds after the commit that fixed the thing it described,
on the same branch, and kept the present tense; the amendment written to fix *that* added a new
false claim that the copies still "carry" the bug. When correcting a record mid-task, check the
working tree at the moment of writing, not the state you remember investigating.

## Anti-Rationalization

| Excuse | Reality | Correct Action |
|---|---|---|
| "I measured this — the sentence is grounded" | The measurement grounds the *case you ran*. The universal covers cases you did not. | State the case you ran, or falsify the extension to the ones you did not. |
| "A counter-example would be pathological" | Two of ICON-0099's five were a Windows junction and an empty YAML block scalar — both present in the corpus | Construct it and check. Pathological is a conclusion, not a premise. |
| "The rule is already written down; I know it" | It was written down, and was violated by the round citing it | Perform the step and record its output. Knowing the rule is not the deliverable. |
| "This is prose, not code — it can't be wrong" | Prose is what the next agent acts on; a false universal in a standard propagates further than a bug | Hold repo prose to the evidence standard you hold a test to. |

## Dispatching for It

When dispatching an agent that will write prose about something it measures, put the requirement in
the dispatch, not in the reviewer's checklist. ICON-0099's round-4 dispatch said: before writing any
sentence containing *every / never / only / all*, attempt to falsify it and report what you tried.
Both coders caught universals in their **own** drafts before finishing. By round 6 agents were
falsifying premises they had been *handed* — one was told a proposed guard would make the word
"unreadable" true, measured a case it did not cover, and both applied the guard and narrowed the
prose.

## Related

- See also: [skill-decomposition/verify-design-claims-against-artifacts](skill-decomposition/verify-design-claims-against-artifacts.md)
  — a claim relied on *without* verification; here verification succeeded and the claim written
  around it was wider than the evidence
- See also: [harness-trust](harness-trust.md) — a verification *result* that cannot be trusted; this
  standard assumes the result is sound and governs what may be said about it
