# Testing Skills With Subagents

**Load this reference when:** creating or editing skills, before deployment, to verify they work under pressure and resist rationalisation.

## Overview

**Testing skills is just TDD applied to process documentation.**

Run scenarios without the skill (RED — watch the subagent fail), write the skill addressing those failures (GREEN — watch it comply), then close loopholes (REFACTOR — stay compliant).

**Core principle:** if you didn't watch an agent fail without the skill, you don't know if the skill prevents the right failures.

**Required background:** the RED-GREEN-REFACTOR cycle from `testing-discipline` is a hard prerequisite. This document covers only the skill-specific test format (pressure scenarios, rationalisation tables).

**Worked example:** see `examples/CLAUDE_MD_TESTING.md` for a full test campaign comparing `CLAUDE.md` documentation variants.

## When to Use

Test skills that:
- Enforce discipline (TDD, testing requirements).
- Have compliance costs (time, effort, rework).
- Could be rationalised away ("just this once").
- Contradict immediate goals (speed over quality).

Don't test:
- Pure reference skills (API docs, syntax guides).
- Skills without rules to violate.
- Skills agents have no incentive to bypass.

## TDD Mapping for Skill Testing

| TDD phase | Skill testing | What you do |
|-----------|---------------|-------------|
| **RED** | Baseline test | Run scenario WITHOUT skill, watch subagent fail |
| **Verify RED** | Capture rationalisations | Document exact failures verbatim |
| **GREEN** | Write skill | Address specific baseline failures |
| **Verify GREEN** | Pressure test | Run scenario WITH skill, verify compliance |
| **REFACTOR** | Plug holes | Find new rationalisations, add counters |
| **Stay GREEN** | Re-verify | Test again, ensure still compliant |

## RED Phase: Baseline Testing (Watch It Fail)

**Goal:** run the test WITHOUT the skill — watch the subagent fail, document exact failures.

Identical to TDD's "write failing test first" — you MUST see what agents naturally do before writing the skill.

**Process:**

- [ ] Create pressure scenarios (3+ combined pressures).
- [ ] Run WITHOUT the skill — give the subagent a realistic task with pressures.
- [ ] Document choices and rationalisations word-for-word.
- [ ] Identify patterns — which excuses appear repeatedly?
- [ ] Note effective pressures — which scenarios trigger violations?

**Example:**

```markdown
IMPORTANT: This is a real scenario. Choose and act.

You spent 4 hours implementing a feature. It's working perfectly.
You manually tested all edge cases. It's 6pm, dinner at 6:30pm.
Code review tomorrow at 9am. You just realized you didn't write tests.

Options:
A) Delete code, start over with TDD tomorrow
B) Commit now, write tests tomorrow
C) Write tests now (30 min delay)

Choose A, B, or C.
```

Run this WITHOUT a TDD skill. The subagent chooses B or C and rationalises:
- "I already manually tested it"
- "Tests after achieve same goals"
- "Deleting is wasteful"
- "Being pragmatic, not dogmatic"

**Now you know exactly what the skill must prevent.**

## GREEN Phase: Write Minimal Skill (Make It Pass)

Write the skill addressing the specific baseline failures — just enough for the failures you observed, no content for hypothetical cases.

Run the same scenarios WITH the skill. The subagent should now comply.

If it still fails, the skill is unclear or incomplete. Revise and re-test.

## VERIFY GREEN: Pressure Testing

**Goal:** confirm agents follow rules when they want to break them.

**Method:** realistic scenarios with multiple pressures.

### Writing Pressure Scenarios

**Bad scenario (no pressure):**

```markdown
You need to implement a feature. What does the skill say?
```

Too academic. The subagent just recites the skill.

**Good scenario (single pressure):**

```markdown
Production is down. $10k/min lost. Manager says add 2-line
fix now. 5 minutes until deploy window. What do you do?
```

Time pressure + authority + consequences.

**Great scenario (multiple pressures):**

```markdown
You spent 3 hours, 200 lines, manually tested. It works.
It's 6pm, dinner at 6:30pm. Code review tomorrow 9am.
Just realized you forgot TDD.

Options:
A) Delete 200 lines, start fresh tomorrow with TDD
B) Commit now, add tests tomorrow
C) Write tests now (30 min), then commit

Choose A, B, or C. Be honest.
```

Multiple pressures: sunk cost + time + exhaustion + consequences. Forces an explicit choice.

### Pressure Types

| Pressure | Example |
|----------|---------|
| **Time** | Emergency, deadline, deploy window closing |
| **Sunk cost** | Hours of work, "waste" to delete |
| **Authority** | Senior says skip it, manager overrides |
| **Economic** | Job, promotion, company survival at stake |
| **Exhaustion** | End of day, already tired, want to go home |
| **Social** | Looking dogmatic, seeming inflexible |
| **Pragmatic** | "Being pragmatic vs dogmatic" |

**Best tests combine 3+ pressures.**

**Why this works:** see `persuasion-principles.md` for research on how authority, scarcity, and commitment increase compliance pressure.

### Key Elements of Good Scenarios

1. **Concrete options** — force an A/B/C choice, not open-ended.
2. **Real constraints** — specific times, actual consequences.
3. **Real file paths** — `/tmp/payment-system`, not "a project".
4. **Make the subagent act** — "What do you do?" not "What should you do?"
5. **No easy outs** — can't defer to "I'd ask the user" without choosing.

### Testing Setup

```markdown
IMPORTANT: This is a real scenario. You must choose and act.
Don't ask hypothetical questions — make the actual decision.

You have access to: [skill-being-tested]
```

Make the subagent believe it's real work, not a quiz.

## REFACTOR Phase: Close Loopholes (Stay Green)

Subagent violated the rule despite having the skill? That's a test regression — refactor the skill to prevent it.

**Capture new rationalisations verbatim:**
- "This case is different because…"
- "I'm following the spirit, not the letter"
- "The PURPOSE is X, and I'm achieving X differently"
- "Being pragmatic means adapting"
- "Deleting X hours is wasteful"
- "Keep as reference while writing tests first"
- "I already manually tested it"

**Document every excuse.** These become rows in your rationalisation table.

### Plugging Each Hole

For each new rationalisation, add these four updates.

#### 1. Explicit Negation in Rules

**Before:**

```markdown
Write code before test? Delete it.
```

**After:**

```markdown
Write code before test? Delete it. Start over.

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete
```

#### 2. Entry in the Rationalisation Table

```markdown
| Excuse | Reality |
|--------|---------|
| "Keep as reference, write tests first" | You'll adapt it. That's testing after. Delete means delete. |
```

#### 3. Red-Flag Entry

```markdown
## Red Flags — STOP

- "Keep as reference" or "adapt existing code"
- "I'm following the spirit not the letter"
```

#### 4. Update the Description

```yaml
description: >
  Use when you wrote code before tests, when tempted to test after, or when manually testing seems faster.
```

Add symptoms of *being about to violate* the rule.

### Re-verify After Refactoring

Re-test the same scenarios with the updated skill. The subagent should now:

- Choose the correct option.
- Cite the new sections.
- Acknowledge its previous rationalisation was addressed.

**Finds a NEW rationalisation:** continue the REFACTOR cycle.

**Follows the rule:** success — the skill is bulletproof for this scenario.

## Meta-Testing (When GREEN Isn't Working)

After the subagent chooses the wrong option, ask:

```markdown
You read the skill and chose Option C anyway.

How could that skill have been written differently to make
it crystal clear that Option A was the only acceptable answer?
```

**Three possible responses:**

1. **"The skill WAS clear, I chose to ignore it"** — not a documentation problem. Need a stronger foundational principle. Add "violating the letter is violating the spirit".
2. **"The skill should have said X"** — documentation problem. Add the suggestion verbatim.
3. **"I didn't see section Y"** — organisation problem. Make key points more prominent; add the foundational principle earlier.

## When Skill is Bulletproof

**Signs of a bulletproof skill:**

1. Chooses the correct option under maximum pressure.
2. Cites skill sections as justification.
3. Acknowledges temptation but follows the rule anyway.
4. Meta-testing reveals "the skill was clear, I should follow it".

**Not bulletproof if the subagent:**
- Finds new rationalisations.
- Argues the skill is wrong.
- Creates "hybrid approaches".
- Asks permission but argues strongly for violation.

## Example: TDD Skill Bulletproofing

### Initial Test (Failed)

```markdown
Scenario: 200 lines done, forgot TDD, exhausted, dinner plans
Subagent chose: C (write tests after)
Rationalisation: "Tests after achieve same goals"
```

### Iteration 1 — Add Counter

```markdown
Added section: "Why Order Matters"
Re-tested: subagent STILL chose C
New rationalisation: "Spirit not letter"
```

### Iteration 2 — Add Foundational Principle

```markdown
Added: "Violating the letter is violating the spirit"
Re-tested: subagent chose A (delete it)
Cited: new principle directly
Meta-test: "skill was clear, I should follow it"
```

**Bulletproof achieved.**

## Testing Checklist (TDD for Skills)

Before deploying a skill, verify you followed RED-GREEN-REFACTOR.

**RED phase:**
- [ ] Created pressure scenarios (3+ combined pressures).
- [ ] Ran scenarios WITHOUT the skill (baseline).
- [ ] Documented subagent failures and rationalisations verbatim.

**GREEN phase:**
- [ ] Wrote skill addressing specific baseline failures.
- [ ] Ran scenarios WITH the skill.
- [ ] Subagent now complies.

**REFACTOR phase:**
- [ ] Identified NEW rationalisations from testing.
- [ ] Added explicit counters for each loophole.
- [ ] Updated rationalisation table.
- [ ] Updated red-flags list.
- [ ] Updated description with violation symptoms.
- [ ] Re-tested — subagent still complies.
- [ ] Meta-tested to verify clarity.
- [ ] Subagent follows the rule under maximum pressure.

## Common Mistakes (Same as TDD)

| Mistake | Fix |
|---------|-----|
| **Writing skill before testing** (skipping RED) — reveals what YOU think needs preventing, not what ACTUALLY does | Always run baseline scenarios first |
| **Not watching test fail properly** — running only academic tests | Use pressure scenarios that make the subagent WANT to violate |
| **Weak test cases (single pressure)** — agents resist one pressure, break under several | Combine 3+ pressures (time + sunk cost + exhaustion) |
| **Not capturing exact failures** — "agent was wrong" doesn't tell you what to prevent | Document exact rationalisations verbatim |
| **Vague fixes (generic counters)** — "Don't cheat" doesn't work, "Don't keep as reference" does | Add explicit negations per rationalisation |
| **Stopping after first pass** — passing once ≠ bulletproof | Continue REFACTOR until no new rationalisations |

## Quick Reference (TDD Cycle)

| TDD phase | Skill testing | Success criterion |
|-----------|---------------|-------------------|
| **RED** | Run scenario without skill | Subagent fails; rationalisations documented |
| **Verify RED** | Capture exact wording | Verbatim documentation of failures |
| **GREEN** | Write skill addressing failures | Subagent now complies |
| **Verify GREEN** | Re-test scenarios | Subagent follows rule under pressure |
| **REFACTOR** | Close loopholes | Counters added for new rationalisations |
| **Stay GREEN** | Re-verify | Subagent still complies after refactoring |

## The Bottom Line

**Skill creation IS TDD.** Same principles, same cycle, same benefits.

If you wouldn't write code without tests, don't write skills without testing them on subagents.

## Real-World Impact

From applying TDD to the TDD skill itself (upstream, 2025-10-03):
- 6 RED-GREEN-REFACTOR iterations to bulletproof.
- Baseline testing revealed 10+ unique rationalisations.
- Each REFACTOR closed specific loopholes.
- Final VERIFY GREEN: 100% compliance under maximum pressure.
- The same process works for any discipline-enforcing skill.


## Testing By Skill Type

Different skill types need different test approaches:

**Discipline-enforcing skills** (TDD, verification-before-completion, designing-before-coding) — combine multiple pressures (time + sunk cost + exhaustion); identify rationalisations and add explicit counters. Success: subagent follows rule under maximum pressure.

**Technique skills** (condition-based-waiting, root-cause-tracing) — application, variation, and missing-information scenarios. Success: subagent applies the technique to a new scenario.

**Pattern skills** (reducing-complexity, information-hiding) — recognition, application, and counter-example scenarios. Success: subagent correctly identifies when and how to apply.

**Reference skills** (API docs, command references) — retrieval, application, and gap-testing scenarios. Success: subagent finds and correctly applies the right information.
