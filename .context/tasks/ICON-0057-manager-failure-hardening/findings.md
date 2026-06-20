# ICON-0057 — Forensic findings from session.md (WSD-26817, 906 min)

Source: `session.md` at repo root — an exported Copilot CLI session where ICON's @manager
was used to rework an Angular 20 / NGXS feature ("not properly utilizing ngxs to drive the UI").
The user judged the result a serious failure ("You really fucked up today", line 4452).

## What the user asked for
- L15: "Reopen task WSD-26817 - the code in the MR is not properly utilizing ngxs to drive the UI."
- L686 (clarification): "It is using ngxs to some degree, but it is also not using the forms plugin,
  it has its own state properties, and it's setting up questionable subscriptions in the component"
- L2004 (the real principle): "There's a TON of manual form getting/setting going on rather than
  relying on the forms plugin... When the save button gets clicked, all that should be needed for
  submission is literally just the 'go' signal. All of the other information in the request payload
  should be already in the ngxs state."

## User pushback timeline (verbatim)
1. L1206 — "the glob you provided did not specify only spec.js files, it tried to run EVERY file as a karma test"
2. L1245 — "this is also like the third time I have seen you assume the --include flag doesn't work,
   and one time you even encoded '--include doesn't work, always run the full suite' in project .context,
   so you need to proactively update test guidance ... to ALWAYS SPECIFY THE FILE TYPE"
3. L1678 — "Why the `@let`s in the template for EVERYTHING? That pattern only provides a benefit when a
   value is used multiple times"
4. L2004 — manual form get/set instead of the forms plugin (the core requirement)
5. L2906 — "Once again, THEIR PAYLOAD VALUES SHOULD ALREADY BEEN IN THE STATE. There is ZERO reason that
   the component should be assembling any DTOs like that"
6. L2971 — "nope nope nope. Number one cause of user frustration is violating your prescribed role. Do it right."
   (manager had started hand-editing instead of delegating)
7. L4452 — "there were lint errors in that MR (that I have fixed) and you also completely failed to run a
   code reviewer pass on almost all of the code changes in this task. You really fucked up today"

## Root-cause patterns
- **A. Shallow up-front diagnosis → multi-round thrash.** Single audit ran 22s on a mini model, captured
  symptoms not the architectural principle. 5 sequential rework rounds each peeled back one layer the user
  had to name manually. The manager's own delegation prompt baked in the half-measure (told coder that
  component-side DTO assembly / option constants were acceptable).
- **B. Green-suite-as-proof / verification theater.** Build+tests run every round, but: `--include` loader
  errors ignored because full suite was green (L1156-1214); a 1452→1450 test-count drop waved away as a guess
  (L3227); and the two project-mandated gates — `npm run lint` ("required before commit") and a code-review
  pass — were **never run** in the entire session (L4475-4477).
- **C. Inconsistent role discipline.** Manager hand-edited the `@let` cleanup (L1819-1871) and began
  hand-fixing the DTO issue (L2922) before being told off (L2971). Oscillated between delegating and doing.
- **D. Self-reinforcing bad context.** The agent had previously encoded its own `--include` misunderstanding
  into the consumer's `.context` ("always run the full suite") — a wrong mental model promoted to durable
  docs, then re-applied. Third recurrence.
- **E. Preference churn from missing up-front alignment.** Rounds 4 & 5 (selector style) partially undid each
  other (manual `@Selector` → `createPropertySelectors`). One up-front question would have collapsed them.
- **F. Confident "done" unbacked by claimed evidence.** First coder declared "All acceptance criteria
  verified" (L1071) for an implementation violating the task's intent; manager relayed "the rework is solid"
  (L1214) and "Task closed" (L4434) — both premature.
- **G. Token-expensive re-discovery.** Same files dumped in full repeatedly — selectors.ts dumped 4× (L2528,
  L3376, L3661, L4024), component.ts twice, full delegation prompts echoed verbatim in completion
  notifications, git push progress-bar spam captured in full on 6 pushes.

## Quantitative
- 7 user redirections (2 explicitly angry). 5 coder rework rounds + 1 manager-hand-done fix. 6 sub-agents.
  ≥4 full test-suite runs. **0 lint runs. 0 code-review passes.** 6 force-pushes to the MR with no review gate between any.

## Highest-leverage levers (architect to refine)
1. Make lint + code-review **hard, itemized, non-skippable** close-gates (pattern B/F). Most failures were the
   model ignoring rules ICON already states — convert soft guidance into an enumerated gate that blocks "closed".
2. Guard against treating green tests as covering other gates, and against waving away scrolled-past errors /
   unexplained test-count changes.
3. Front-load architectural intent on "rework / not-done-right / use-X-properly" tasks — extract the principle,
   not the symptom (pattern A); surface known stylistic decision points up front (pattern E).
4. Guardrail: do not promote a tool-behavior workaround into durable .context without verifying the tool
   actually behaves that way (pattern D).
NOTE: pattern C (role discipline) is already exhaustively covered in manager anti-rationalization — more prose
is unlikely to help and would violate "earn your place". Weigh carefully before adding anything there.
