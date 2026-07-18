---
name: characterization-testing
description: >
  Use when modifying legacy code that lacks test coverage, when writing tests for code that already exists but has no tests, when branch coverage is absent or low on the area being changed, or when a refactor or bug fix is required in code with no tests — including when a coder is about to change a function that has never been tested, when "just fix the bug" is the instruction but no tests exist to verify the change, when a class is being refactored with zero coverage, or when the area being modified has no existing tests that would catch regressions.
user-invocable: false
---

# Characterization Testing

## Overview

**You can't safely change code you don't understand, and you can't understand code without tests.** Characterization tests capture what the code *actually does* — not what it *should* do — so you can change it without unknowingly breaking it. From Michael Feathers' *Working Effectively with Legacy Code*.

## When to Use

- Modifying a class/function that has zero test coverage
- Branch coverage is absent or low on the code being changed
- Bug fix required in untested legacy code
- Refactoring a large method before you can reason about it safely
- Coverage gate would fail because no tests exist for the area being changed

## When NOT to Use

- New code being written from scratch (use RED-GREEN-REFACTOR instead — see `testing-discipline`)
- Code that already has tests — extend those, don't write fresh characterization tests alongside them

---

## The Process

### characterization-testing: Step 1: Run the Code and Capture Its Outputs

Don't read the source yet. Call it with realistic inputs and observe what comes out.

```csharp
// Write a throwaway probe test — you'll turn this into a real test
[Fact]
public void Probe_WhatDoesThisReturn()
{
    var result = LegacyCalculator.ComputeFee(1000, "STANDARD", 3);
    // Set a breakpoint here and note the actual output
    Assert.True(false, $"Actual result: {result}");
}
```

Capture: return values, side effects (DB writes, events published), exceptions thrown.

### characterization-testing: Step 2: Lock the Actual Behavior as Tests

Replace the probe with real assertions matching what you observed. You are NOT asserting what the code *should* do — you are locking what it *does*.

```csharp
[Fact]
public void ComputeFee_StandardTier_3Months_Returns147()
{
    var result = LegacyCalculator.ComputeFee(1000, "STANDARD", 3);
    Assert.Equal(147m, result); // Locked: this is what it currently returns
}
```

Write enough cases for both line and branch coverage of the code you're about to change:
- The specific input you're about to change
- Boundary values adjacent to your change
- Any paths your modification touches — every branch (if/else, switch, early return) exercised by at least one test

### characterization-testing: Step 3: Confirm the Tests Pass Green (Without Any Code Change)

Run the suite. All characterization tests must pass before you touch a line of production code.

**If a test fails before you change anything:** The test is wrong — fix the assertion to match reality, not your expectation.

### characterization-testing: Step 4: Make the Change

Now apply the bug fix or refactor. The characterization tests are a regression net — if one breaks, you've changed existing behavior (intentionally or not).

- **Intentional behavior change**: Update the test assertion to match the new intended behavior, with a comment noting it was deliberate.
- **Unintentional behavior change**: Revert your code change, not the test.

### characterization-testing: Step 5: Add Behavior Tests for the New/Fixed Code

With the characterization net in place, add normal RED-GREEN tests for the new behavior you're introducing — the forward-looking tests. The characterization tests are the safety net underneath.

See `testing-discipline` for the RED-GREEN-REFACTOR process to apply here.

---

## What Makes a Good Characterization Test

| Property | Good | Bad |
|---|---|---|
| Asserts real output | `Assert.Equal(147m, result)` | `Assert.NotNull(result)` |
| Input is realistic | Uses production-representative values | Uses `0`, `""`, `null` everywhere |
| Name describes current behavior | `ApproveAudit_ClosedDealer_ThrowsInvalidOperation` | `Test1` |
| Covers the path you'll change | Exercises the exact branch being modified | Tests a completely unrelated branch |

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I understand the code, I don't need tests" | You understand it *now*. You won't at 3am during a prod rollback. |
| "It's too hard to test — too many dependencies" | That's the seam problem. Extract an interface at the boundary. |
| "A characterization test of wrong behavior is useless" | It's not a correctness test — it's a change detector. Wrong behavior locked is better than changed behavior undetected. |
| "I'll just be careful with the refactor" | Everyone who breaks legacy code intended to be careful. |
