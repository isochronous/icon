# ICON-0057 — Prioritized hardening recommendations

Input: `.context/tasks/ICON-0057-manager-failure-hardening/findings.md` (forensic timeline of
WSD-26817, 906 min, root-cause patterns A–G). Lens: `agent-evaluation` (RULE 5 orchestrator
gate-ownership; RULE 2 single-source) + `icon-audit` cross-cutting (retrospective clustering,
"earn your place", token economics).

## Framing — where the leverage actually is

The session's worst failures (B and F) were **not** missing rules. ICON already says "Invoke
@reviewer for all code changes before closing a task" (manager.agent.md:234) and "Every success
claim requires evidence" (common-constraints:276). The model **rationalized past soft rules**.
For that failure class, more prose has near-zero marginal value — the proven lever (per ICON-0056,
which moved the retrospective into the Hardcoded tier) is to convert a soft, scattered rule into a
**single hard, itemized, non-skippable close-gate** that blocks the word "closed."

So the recommendation set is deliberately small: **one structural gate (R1) carries most of the
fix.** The rest are a couple of cheap prose touches, one token-*reducing* fix, one out-of-scope
flag, and an explicit do-not-do list to resist padding.

Priority order: R1 (Recommend, high leverage) → R2 (Recommend, cheap) → R3 (Recommend,
token-negative) → R4 (Optional) → R5 (Out-of-scope, flag only) → R6/R7 (Do-not-do).

---

## R1 — Itemized "Closure Gate" promoting reviewer + lint to Hardcoded tier

**Failure it prevents**: Pattern B and F. Lint was a project-mandated "required before commit" gate
and a code-review pass was project-mandated — **both run zero times across 906 minutes**
(findings A–G summary; session L4452: *"there were lint errors in that MR ... and you also
completely failed to run a code reviewer pass on almost all of the code changes ... You really
fucked up today"*). Manager relayed "Task closed" (L4434) and "the rework is solid" (L1214) with
neither gate satisfied.

**Exact location**: `agents/manager.agent.md`
- (a) Add one bullet to **Behavior Tiers → Hardcoded** (after line 228).
- (b) Add a closing gate restatement at the END of **Task Completion and Retrospective** (after
  step 6, line 208).
- (c) Promote the two affected lines OUT of the **Default** tier (lines 234, and add lint) so the
  rule lives in exactly one tier (RULE 2 — no split-tier ownership).

**Minimal change**:

(a) New Hardcoded bullet:
```
- Do not report a task "closed"/"done" until the Task Completion close-gate has run: @reviewer
  invoked on the actual changed-file set, project lint run with output shown, and
  verification-checklist passed. A green test suite does NOT satisfy the review or lint gate.
```

(b) Append to Task Completion and Retrospective (new step, before "Clear the active task"):
```
> **Close-gate (non-skippable).** Before saying "closed"/"done", confirm — itemized, each with
> evidence — (1) @reviewer ran over the final changed-file set, (2) project lint command ran and
> its output is shown, (3) verification-checklist passed. Missing any one = task is NOT closed.
> "Tests are green" satisfies none of these three.
```

(c) Reword Default-tier line 234 from "Invoke @reviewer for all code changes before closing a
task" to a pointer (`— enforced by the Task Completion close-gate`) so the *rule* lives only in
Hardcoded. Same for adding lint there as a pointer, not a second authority.

**Token cost**: ~9 net lines added; one Default line demoted to a pointer. Per-task token cost is
**neutral** — the gate is read once at close, the same point the manager already reads steps 0–6.
This is the load-bearing recommendation; its cost is justified by being the direct fix for the two
angriest redirections (L2971-adjacent lint/review, L4452).

**Verdict**: **Recommend.** This is the ICON-0056 lever applied to the review/lint class. It is the
one place where structure (a hard itemized gate) beats prose. The itemization ("each with
evidence", "tests-green satisfies none") is what blocks the specific rationalizations that fired in
this session.

---

## R2 — "Rework / use-X-properly" tasks: extract the principle, surface decision points up front

**Failure it prevents**: Pattern A and E. A 22-second mini-model audit captured symptoms, not the
architectural principle, forcing 5 sequential rework rounds (findings A). The user had to manually
name the real principle three times (session L686, L2004: *"all that should be needed for submission
is literally just the 'go' signal. All of the other information ... should be already in the ngxs
state"*, L2906). Rounds 4 & 5 on selector style partially undid each other — *"One up-front
question would have collapsed them"* (findings E).

**Exact location**: `agents/manager.agent.md` → **Session Start**, step 7 ("Assess research need"),
add a third gate after the External-research block (after line 67).

**Minimal change**:
```
   **Intent extraction** (when the task is a reopen/redo framed as "not done right" / "not using
   X properly" / "rework"): before delegating, state the *architectural principle* the user is
   asking for in one sentence and confirm it with the user, and surface any known stylistic
   decision points (e.g. selector style, form-binding approach) as one up-front question. A
   symptom-level audit here produces multi-round thrash.
```

**Token cost**: ~5 net lines. Per-task cost is **neutral-to-negative in aggregate** — it adds a few
tokens to reopen-tasks only (Session Start is read once), and the expected payoff is collapsing
multi-round rework (this session: 5 rounds → ideally 1–2). It does not fire on normal feature work.

**Verdict**: **Recommend.** This is genuinely new behavior, not a duplicated rule, and it targets
the *root* (shallow diagnosis) rather than symptoms. Keep it terse and gated to the reopen/"do-it-
properly" trigger so it does not bloat the common path. Note: this is one-up-front-question
behavior the manager can do directly; it does not need a new skill.

---

## R3 — Stop re-dumping unchanged files / verbatim prompt echoes (token-REDUCING)

**Failure it prevents**: Pattern G. `selectors.ts` dumped in full 4× (session L2528, L3376, L3661,
L4024), `component.ts` twice, full delegation prompts echoed verbatim in completion notifications,
git push progress-bar spam captured on 6 pushes (findings G). This is pure waste that also crowds
out the context needed to catch B/F.

**Exact location**: `agents/manager.agent.md` → **Delegation** section, add one line after the
warmstart-template guidance (after line 158, near "Delegate goals, not scripts").

**Minimal change**:
```
**Do not re-dump unchanged context.** Reference a file by path + the specific lines/symbols in
scope; never paste a full file a specialist can read itself. Do not echo a delegation prompt back
verbatim in a completion notification — summarize the outcome. Suppress nothing, but do not
re-capture progress-bar / push spam.
```

**Token cost**: ~4 net lines added to the definition; **strongly token-negative per task** — this
is the one recommendation that *reduces* ongoing usage, directly serving the user's overriding
"don't add a ton of token usage" constraint. It partly self-funds R1+R2.

**Verdict**: **Recommend.** Cheap, addresses the user's explicit cost concern, and removes noise
that masked the missing gates. (Note: the "suppress nothing" clause keeps it consistent with the
existing stderr/output-suppression constraint at common-constraints:283.)

---

## R4 — Guard against waving away scrolled-past errors / unexplained test-count changes

**Failure it prevents**: Pattern B (sub-case). `--include` loader errors ignored because the full
suite was green (session L1156-1214); a 1452→1450 test-count drop *"waved away as a guess"*
(L3227) (findings B).

**Exact location**: TWO candidate homes — choose ONE, do not duplicate:
- Preferred: `skills/verification-checklist/SKILL.md` → **Rationalization Prevention** table
  (after line 40), one row.
- Alternative: a row in manager Anti-Rationalization. Prefer the skill — it is where verification
  rationalizations already live (RULE 2: keep the rule in one place).

**Minimal change** (verification-checklist Rationalization Prevention, one row):
```
| "The suite is green, that loader/collection error scrolled past is noise" | A green count can hide unrun files. An unexplained test-COUNT change (e.g. 1452→1450) means tests stopped running or were deleted — account for the delta before claiming pass. |
```

**Token cost**: ~1 line, in a skill loaded only when verification is in play. **Neutral** per task.

**Verdict**: **Optional (lean Recommend).** It is a real, specific failure and the fix is one line
in exactly the right skill. Marked Optional only because R1's "tests-green satisfies none of the
three gates" already covers the *headline* version of this; this row adds the narrower "count-delta
/ scrolled-past error" nuance. Recommend if the user wants the sharper guard; skip if minimizing
edits.

---

## R5 — Don't promote an unverified tool-behavior workaround into durable .context (OUT OF SCOPE — flag)

**Failure it prevents**: Pattern D. The agent had previously encoded its own `--include`
misunderstanding into the **consumer's** `.context` (*"always run the full suite"*), then re-applied
the wrong mental model — third recurrence (session L1245: *"one time you even encoded '--include
doesn't work, always run the full suite' in project .context ... ALWAYS SPECIFY THE FILE TYPE"*;
findings D).

**Exact location**: The durable fix the user is asking for ("proactively update test guidance in
**this project**") lives in the **consumer repo's** `.context/testing/` — that is **out of scope for
ICON plugin edits**.

The *generalizable* ICON-side guard, if wanted, is one line in
`skills/context-maintenance/SKILL.md` → **Common Mistakes** table:
```
| Promoting an unverified tool-behavior workaround as fact | Reproduce the tool's actual behavior (show the command output) before encoding a "tool X doesn't work, do Y instead" rule. A wrong mental model promoted to durable docs re-fires on every future task. |
```

**Token cost**: 0 lines if treated as consumer-repo-only (the default); ~1 line if the optional
context-maintenance guard is added.

**Verdict**: **Out-of-scope (flag to user).** The concrete remediation (fixing the bad
`--include` guidance + lint-target advice) belongs in the consumer's `.context/`, not ICON. Surface
this to the user as a separate consumer-repo action item. The optional one-line ICON-side guard is
defensible (it generalizes), but offer it as opt-in, not part of the core set.

---

## R6 — More manager role-discipline prose (DO NOT DO)

**Failure it prevents**: Pattern C — manager hand-edited the `@let` cleanup (session L1819-1871)
and began hand-fixing the DTO issue (L2922) before being told *"Number one cause of user
frustration is violating your prescribed role. Do it right."* (L2971).

**Verdict**: **Do-not-do.** Per findings note (lines 67–68) and confirmed by reading the manager:
role discipline is **already exhaustively covered**. The Hardcoded tier states "Always delegate ...
never implement" (line 218); the Anti-Rationalization table has **four** dedicated rows
(manager.agent.md:254, 255, and the always-delegate/execution-context rows at 246, 253). Adding a
fifth row would violate "earn your place" — it would be redundant reinforcement of a rule the model
*understood and chose to ignore*, which is model-behavior prose cannot guarantee. The honest read:
no agent definition can make a model that decided to hand-edit not hand-edit; the existing coverage
is already at the point of diminishing returns. R1's close-gate provides the *downstream* catch
(an un-reviewed manager edit fails the review gate), which is the enforceable lever; the prose
itself should not grow.

---

## R7 — A new "diagnosis-quality" skill or sub-agent (DO NOT DO)

**Failure it prevents**: would target Pattern A (shallow audit).

**Verdict**: **Do-not-do (over-engineering).** A new skill/sub-agent for "diagnose properly" is the
"design a system for extensibility" anti-pattern. R2's five-line gated trigger on the manager covers
the concrete, recurring case (reopen / "use-X-properly" tasks) at a fraction of the token cost. No
second consumer exists to justify extracting a skill. Revisit only if retrospectives later cluster
multiple distinct shallow-diagnosis failures across task types.

---

## Summary table

| ID | Pattern | Home | Net lines | Per-task token cost | Verdict |
|----|---------|------|-----------|---------------------|---------|
| R1 | B, F | manager: Hardcoded + Task Completion close-gate | ~9 | Neutral (read once at close) | **Recommend** |
| R2 | A, E | manager: Session Start step 7 | ~5 | Neutral; gated to reopen tasks | **Recommend** |
| R3 | G | manager: Delegation | ~4 | **Negative** (reduces usage) | **Recommend** |
| R4 | B (count/scrolled error) | verification-checklist Rationalization table | ~1 | Neutral | Optional (lean Recommend) |
| R5 | D | consumer `.context/` (+ optional 1-line context-maintenance) | 0–1 | n/a | **Out-of-scope — flag** |
| R6 | C | — | 0 | — | **Do-not-do** |
| R7 | A | — | 0 | — | **Do-not-do** |

**Net definition growth if R1+R2+R3 adopted: ~18 lines added, 1 demoted to pointer; R3 makes
ongoing per-task token use net-negative.** Core fix (R1) is structural, not prose — matching the
ICON-0056 precedent that the user already validated.

## What no agent definition can reliably fix

Patterns C and F are fundamentally **model compliance** problems: the rules existed and were
understood. ICON's only durable lever against them is making the *downstream artifact* gate-checked
(R1's close-gate catches an un-reviewed change regardless of why it was un-reviewed) — not adding
more upstream prose telling the model to comply. State this honestly to the user: R1 reduces the
blast radius of a non-compliant manager; it cannot guarantee compliance.
