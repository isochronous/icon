---
name: testing-discipline
description: >
  Use when writing tests, reviewing test quality, deciding mocking strategy, or debugging test failures — including when implementation is being written before any test exists, when an assertion is `toHaveBeenCalled` without checking the result, when a production class is gaining a `getInternalState`/`_testHelper` method for test access, when a partial mock is being used because "the test only reads three fields", or when a feature is being marked done without test output.
user-invocable: false
---

# Testing Discipline

## Overview

**Tests prove behavior, not implementation.** The most common testing failures — mocking internals, testing mock return values, writing tests after the fact — all stem from testing HOW code works instead of WHAT it does. This skill enforces the discipline to catch those traps before they happen.

## TDD: RED-GREEN-REFACTOR

When writing tests for new functionality, follow this cycle strictly:

### testing-discipline: RED: Write a Failing Test First

Write a test that defines the expected behavior BEFORE writing the implementation. Run the test and confirm it fails for the RIGHT reason.

**Why "for the right reason" matters**: A test that fails because of a typo in the test itself doesn't prove anything. The failure should be "expected X but got Y" or "function not found" — something that shows the test is correctly asserting behavior that doesn't exist yet.

```
# Good: Test fails because the function returns wrong value
Expected: 42
Actual: 0

# Bad: Test fails because of a syntax error in the test
ReferenceError: expetced is not defined
```

### testing-discipline: GREEN: Write Minimal Code to Pass

Write only enough implementation code to make the test pass. Don't optimize, don't add features, don't handle edge cases yet. Run the test and confirm it passes.

**The temptation to resist**: It's natural to want to write the "complete" implementation. Don't. Each behavior should be driven by a specific test. If there's no test requiring it, you're speculating about what the code needs to do.

### testing-discipline: REFACTOR: Clean Up While Green

With passing tests, clean up the implementation and the test. Remove duplication, improve names, simplify logic. Run tests after each change to confirm they stay green.

**When adding tests to existing code**: You can't always do RED-GREEN-REFACTOR when the code already exists. In that case:
1. Write the test for existing behavior first and confirm it passes (this is your safety net).
2. Then write tests for the behavior you're about to add or change (these should fail — RED).
3. Modify the code to make the new tests pass (GREEN).
4. Refactor with full test coverage protecting you.

## Anti-Patterns to Avoid

These are the most common testing mistakes. Each one wastes time and creates false confidence.

### 1. Testing Mock Behavior Instead of Real Behavior

**The mistake**: Your test asserts that a mock was called, that a mock element exists, or that a mock returned what you told it to return. You're testing your test setup, not your code.

**How to recognize it**:
- Assertions like `expect(mockFn).toHaveBeenCalled()` without checking the RESULT of that call
- Testing that a mocked component renders (of course it does — you mocked it)
- Assertions that check mock return values you yourself defined

**What to do instead**: Assert on the **observable output** of the unit under test. If a function calls a database, don't just assert the DB function was called — assert that the function returned the correct data or threw the correct error.

**Example**:
```
# BAD: Testing that the mock exists
expect(screen.getByTestId('mock-payment-form')).toBeInTheDocument();

# GOOD: Testing real component behavior
fireEvent.click(submitButton);
expect(screen.getByText('Payment submitted')).toBeInTheDocument();
```

### 2. Adding Test-Only Methods to Production Code

**The mistake**: You add a method like `getInternalState()` or `_testHelper()` to a production class solely because your test needs to inspect something.

**Why it's harmful**: It pollutes the production API with methods that serve no business purpose. Other developers may start depending on these methods, creating coupling to implementation details. The test is now testing internal state rather than behavior.

**What to do instead**:
- Test through the public API only
- If you can't observe the behavior through the public API, the design may need to change (consult @architect)
- Put test helpers in test utility files, not production code
- Use dependency injection to make internal behavior observable without exposing it

### 3. Mocking Without Understanding Side Effects

**The mistake**: You mock a dependency without understanding what it actually does. Your mock returns the "happy path" response, but the real dependency has side effects (caching, rate limiting, state mutations, event emissions) that your test completely ignores.

**Before mocking any dependency, answer these questions**:
1. What does this dependency do beyond returning a value?
2. Does my code depend on any of those side effects?
3. Am I mocking at the right level? (Mock at the boundary, not deep internals)

**Checklist for mock correctness**:
- [ ] I understand all side effects of the real dependency
- [ ] My mock replicates the side effects my code depends on
- [ ] My mock fails in the same way the real dependency fails (errors, exceptions, timeouts)
- [ ] I'm mocking at the service boundary, not mocking internal implementation details

### 4. Incomplete Mock Data Structures

**The mistake**: You mock a data object with only the fields your test currently uses. The production code accesses other fields that your mock doesn't include, and the test passes because JavaScript/Python/etc. silently return `undefined`/`None` for missing fields.

**What to do instead**: Mock the complete data structure as it exists in reality. If the real API returns 20 fields, your mock should include all 20 — even if your test only checks 3. This catches bugs where code accesses a field that the mock forgot.

**Example**:
```
# BAD: Partial mock
mockUser = { name: "Alice" }

# GOOD: Complete mock
mockUser = { id: 1, name: "Alice", email: "alice@example.com", role: "admin",
             createdAt: "2024-01-01", updatedAt: "2024-06-15", isActive: true }
```

### 5. Tests as an Afterthought

**The mistake**: Writing all the implementation code first, then writing tests to "cover" it. The tests end up testing implementation details because the developer already knows HOW the code works, so they test the HOW instead of the WHAT.

**Why it's harmful**: Tests written after implementation tend to be brittle (they break when refactoring) and provide false confidence (they pass but don't actually verify correct behavior). They also miss edge cases because the developer has already mentally committed to a specific approach.

**What to do instead**: Tests are part of implementation, not a follow-up. Use TDD (above) or at minimum, write tests BEFORE you claim the implementation is complete — not as a separate phase.

## When to Mock

Mock at the **boundary** of your unit, not deep inside it:

| Mock This | Don't Mock This |
|-----------|----------------|
| External HTTP APIs | Your own utility functions |
| Database connections | Pure data transformations |
| File system operations | Business logic calculations |
| System clock (time) | Internal helper methods |
| Third-party SDKs | Your own service classes (usually) |
| Environment variables | Constructor parameters |

**The boundary rule**: If you're mocking something you wrote and own, ask why. Usually, you should test through it rather than around it. Mock what you don't control.

## Test Quality Indicators

A good test suite has these properties:

- **Tests fail when behavior changes**: If you change what the code does, a test should fail. If no test fails, the behavior wasn't tested.
- **Tests survive refactoring**: If you change HOW the code works (without changing WHAT it does), no tests should fail. If they do, the tests are coupled to implementation.
- **Test names describe behavior**: `test_returns_empty_list_when_no_items_match` is good. `test_getItems` is not — what about getItems?
- **Each test has one reason to fail**: If a test could fail for 5 different reasons, it's actually 5 tests crammed into one.
- **Tests are readable without comments**: Arrange-Act-Assert structure makes each test self-documenting.

## Change-Driven Coverage Completeness

Good test style is not enough. For any code change, derive coverage from the changed decision points.

### Required coverage matrix (for each changed behavior)

1. **Primary path** — the intended/changed behavior is covered.
2. **Counter path** — the opposite outcome is covered (success vs failure, allow vs deny, emit vs skip).
3. **Adjacent branches** — sibling conditions near the change are covered (null/empty/whitespace, malformed/valid, mapped/unmapped, boundary values).
4. **External contract** — if outward behavior changed (status code, error payload, emitted event, rendered state, public return shape), assert that contract explicitly.

### Derive tests from the diff

For each changed file, inspect new/modified conditionals and branch points, then map each branch to a test case or explicitly mark it intentionally out of scope.

If you cannot answer “which changed branches are still untested?”, coverage is incomplete.

### Reporting guidance

When reporting testing work, include a **Coverage Evidence Block** when practical. Use it to improve consistency and review quality, not as a strict go/no-go gate.

```markdown
Coverage Evidence Block
- Changed decision points:
  - [file:path + branch/condition] -> [test file + test/case name]
  - [file:path + branch/condition] -> [test file + test/case name]
- Intentionally untested branches:
  - [branch/condition] — [rationale]
  - None
```

Use concise entries, but make the mapping explicit enough that a reviewer can trace each changed decision point to a test or a deliberate exception.

## Arrange-Act-Assert Pattern

Every test should follow this structure:

```
// ARRANGE: Set up the preconditions
// - Create test data
// - Configure mocks
// - Initialize the unit under test

// ACT: Execute the behavior being tested
// - Call the method/function
// - Trigger the event
// - Make the request

// ASSERT: Verify the outcome
// - Check return values
// - Verify state changes
// - Confirm side effects
```

Keep each section visually distinct. If your ARRANGE section is 50 lines long, the test setup is too complex — extract a helper or simplify the design.

## Rationalization Prevention

The Anti-Patterns sections above describe each failure mode in detail. This table is the consolidated self-check — every excuse maps to one of those failures.

| Excuse | Reality |
|--------|---------|
| "Just this once, I'll write the test after" | Tests-after measure what the code does, not what it should do. They're brittle and provide false confidence. Use TDD. |
| "I'll mock the function I own — it's faster" | Mocking what you own couples the test to implementation details. Mock at the boundary — what you don't control. |
| "I only need the field my test reads" | Production code reads other fields. Partial mocks let bugs through silently. Mock the complete shape. |
| "Adding a getter for testing is a small concession" | Test-only methods become production API. Test through the public interface or change the design. |
| "The test fails — I'll just adjust the assertion" | If the assertion was right, the code is wrong. Adjusting the test to make it pass erases the test. |
| "100% coverage means we're testing the behavior" | Coverage measures lines hit, not behavior asserted. A test that calls code without asserting doesn't test it. |
| "Mock returned what I expected — my test passes" | Asserting that your mock returns what you set is testing the test setup, not the code under test. |
| "I can't test this without exposing internals — design constraint" | If behavior isn't observable through the public API, the design is wrong. Consult @architect; do not pollute production code. |

## Red Flags — STOP and Restart

If you catch yourself doing any of these, STOP — the test will pass but prove nothing:

- About to write `expect(mockFn).toHaveBeenCalled()` as the only assertion for that interaction.
- About to add `getInternalState()`, `_testHelper()`, or any test-only accessor to a production class.
- About to mock a data object with only the fields this one test happens to read.
- About to write tests after the implementation is "complete" (rather than driving it via TDD).
- About to mock a function or class you wrote and own.
- About to claim a change is ready for review without showing test output as evidence.
- About to silently adjust a failing test's assertion to match what the code now returns.

**All of these mean: the test is being shaped to pass, not to prove behavior. Re-anchor on Arrange-Act-Assert and the boundary rule.**
