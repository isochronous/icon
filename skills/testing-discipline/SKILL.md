---
name: testing-discipline
description: >
  Use when writing tests, reviewing test quality, deciding mocking strategy, or debugging test failures — including when implementation is being written before any test exists, when an assertion is `toHaveBeenCalled` without checking the result, when a production class is gaining a `getInternalState`/`_testHelper` method for test access, when a partial mock is being used because "the test only reads three fields", or when a feature is being marked done without test output.
user-invocable: false
---

# Testing Discipline

## Overview

**Tests prove behavior, not implementation.** The common failures — mocking internals, testing mock return values, writing tests after the fact — all stem from testing HOW code works instead of WHAT it does. This skill catches those traps before they happen.

## TDD: RED-GREEN-REFACTOR

For new functionality, follow this cycle strictly.

### testing-discipline: RED: Write a Failing Test First

Write a test defining the expected behavior BEFORE the implementation. Run it; confirm it fails for the RIGHT reason.

**Why "right reason" matters**: A test failing on a typo in itself proves nothing. The failure should be "expected X but got Y" or "function not found" — proof it asserts behavior that doesn't exist yet.

```
# Good: Test fails because the function returns wrong value
Expected: 42
Actual: 0

# Bad: Test fails because of a syntax error in the test
ReferenceError: expetced is not defined
```

### testing-discipline: GREEN: Write Minimal Code to Pass

Write only enough code to pass. Don't optimize, add features, or handle edge cases yet. Run the test; confirm it passes.

**Resist the temptation** to write the "complete" implementation. Each behavior should be driven by a specific test. No test requiring it = you're speculating.

### testing-discipline: REFACTOR: Clean Up While Green

With tests green, clean up implementation and test — remove duplication, improve names, simplify. Run tests after each change to stay green.

**Adding tests to existing code** (can't always do RED-GREEN-REFACTOR):
1. Write a test for existing behavior first; confirm it passes (your safety net).
2. Write tests for the behavior you're about to add/change (should fail — RED).
3. Modify code to make the new tests pass (GREEN).
4. Refactor with full coverage protecting you.

## Anti-Patterns to Avoid

The most common testing mistakes. Each wastes time and creates false confidence.

### 1. Testing Mock Behavior Instead of Real Behavior

**The mistake**: The test asserts a mock was called, a mock element exists, or a mock returned what you told it to. You're testing your test setup, not your code.

**Recognize it**:
- `expect(mockFn).toHaveBeenCalled()` without checking the RESULT of that call
- Testing that a mocked component renders (of course it does)
- Asserting mock return values you defined yourself

**Instead**: Assert on the **observable output** of the unit. If a function calls a DB, assert it returned the correct data or threw the correct error — not just that the DB function was called.

```
# BAD: Testing that the mock exists
expect(screen.getByTestId('mock-payment-form')).toBeInTheDocument();

# GOOD: Testing real component behavior
fireEvent.click(submitButton);
expect(screen.getByText('Payment submitted')).toBeInTheDocument();
```

### 2. Adding Test-Only Methods to Production Code

**The mistake**: Adding `getInternalState()` or `_testHelper()` to a production class solely so a test can inspect something.

**Why harmful**: It pollutes the production API with methods that serve no business purpose. Others may depend on them, coupling to implementation details. The test now tests internal state, not behavior.

**Instead**:
- Test through the public API only.
- If behavior isn't observable through the public API, the design may need to change (consult @architect).
- Put test helpers in test utility files, not production code.
- Use dependency injection to make internal behavior observable without exposing it.

### 3. Mocking Without Understanding Side Effects

**The mistake**: Mocking a dependency without knowing what it does. The mock returns the happy path, but the real dependency has side effects (caching, rate limiting, state mutations, event emissions) the test ignores.

**Before mocking any dependency, answer**:
1. What does this dependency do beyond returning a value?
2. Does my code depend on any of those side effects?
3. Am I mocking at the right level? (Mock at the boundary, not deep internals.)

**Mock-correctness checklist**:
- [ ] I understand all side effects of the real dependency
- [ ] My mock replicates the side effects my code depends on
- [ ] My mock fails the same way the real dependency fails (errors, exceptions, timeouts)
- [ ] I'm mocking at the service boundary, not internal implementation details

### 4. Incomplete Mock Data Structures

**The mistake**: Mocking a data object with only the fields your test uses. Production code accesses other fields the mock omits, and the test passes because the language silently returns `undefined`/`None` for missing fields.

**Instead**: Mock the complete structure as it exists in reality. If the real API returns 20 fields, include all 20 — even if the test checks 3. This catches bugs where code accesses a field the mock forgot.

```
# BAD: Partial mock
mockUser = { name: "Alice" }

# GOOD: Complete mock
mockUser = { id: 1, name: "Alice", email: "alice@example.com", role: "admin",
             createdAt: "2024-01-01", updatedAt: "2024-06-15", isActive: true }
```

### 5. Tests as an Afterthought

**The mistake**: Writing all implementation first, then tests to "cover" it. The tests end up testing implementation details, because the developer already knows HOW the code works and tests the HOW instead of the WHAT.

**Why harmful**: Tests written after implementation are brittle (break on refactor) and give false confidence (pass without verifying correctness). They also miss edge cases, the developer having already committed to an approach.

**Instead**: Tests are part of implementation, not a follow-up. Use TDD, or at minimum write tests BEFORE claiming the implementation complete — not as a separate phase.

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

**The boundary rule**: If you're mocking something you wrote and own, ask why. Usually test through it, not around it. Mock what you don't control.

## Test Quality Indicators

A good suite has these properties:

- **Tests fail when behavior changes**: Change what the code does, a test should fail. If none fails, the behavior wasn't tested.
- **Tests survive refactoring**: Change HOW it works (not WHAT it does), no test should fail. If they do, they're coupled to implementation.
- **Test names describe behavior**: `test_returns_empty_list_when_no_items_match` is good; `test_getItems` is not.
- **Each test has one reason to fail**: A test that could fail 5 ways is 5 tests crammed into one.
- **Tests are readable without comments**: Arrange-Act-Assert makes each test self-documenting.

## Change-Driven Coverage Completeness

Good test style is not enough. For any change, derive coverage from the changed decision points.

### Required coverage matrix (per changed behavior)

1. **Primary path** — the intended/changed behavior is covered.
2. **Counter path** — the opposite outcome is covered (success vs failure, allow vs deny, emit vs skip).
3. **Adjacent branches** — sibling conditions near the change (null/empty/whitespace, malformed/valid, mapped/unmapped, boundaries).
4. **External contract** — if outward behavior changed (status code, error payload, emitted event, rendered state, public return shape), assert that contract explicitly.

### Derive tests from the diff

For each changed file, inspect new/modified conditionals and branch points; map each branch to a test case or explicitly mark it out of scope.

If you can't answer "which changed branches are still untested?", coverage is incomplete.

### Reporting guidance

When reporting testing work, include a **Coverage Evidence Block** when practical — to improve consistency and review quality, not as a strict go/no-go gate.

```markdown
Coverage Evidence Block
- Changed decision points:
  - [file:path + branch/condition] -> [test file + test/case name]
  - [file:path + branch/condition] -> [test file + test/case name]
- Intentionally untested branches:
  - [branch/condition] — [rationale]
  - None
```

Keep entries concise, but make the mapping explicit enough that a reviewer can trace each changed decision point to a test or a deliberate exception.

## Arrange-Act-Assert Pattern

Every test follows this structure:

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

Keep each section visually distinct. A 50-line ARRANGE section means the setup is too complex — extract a helper or simplify the design.

## Rationalization Prevention

The Anti-Patterns above describe each failure mode in detail. This table is the consolidated self-check — every excuse maps to one of them.

| Excuse | Reality |
|--------|---------|
| "Just this once, I'll write the test after" | Tests-after measure what the code does, not what it should. Brittle, false confidence. Use TDD. |
| "I'll mock the function I own — it's faster" | Mocking what you own couples the test to implementation. Mock at the boundary — what you don't control. |
| "I only need the field my test reads" | Production code reads other fields. Partial mocks let bugs through silently. Mock the complete shape. |
| "Adding a getter for testing is a small concession" | Test-only methods become production API. Test through the public interface or change the design. |
| "The test fails — I'll just adjust the assertion" | If the assertion was right, the code is wrong. Adjusting the test to pass erases the test. |
| "100% coverage means we're testing the behavior" | Coverage measures lines hit, not behavior asserted. Calling code without asserting doesn't test it. |
| "Mock returned what I expected — my test passes" | Asserting your mock returns what you set tests the setup, not the code under test. |
| "I can't test this without exposing internals — design constraint" | If behavior isn't observable through the public API, the design is wrong. Consult @architect; don't pollute production code. |

## Red Flags — STOP and Restart

If you catch yourself doing any of these, STOP — the test will pass but prove nothing:

- About to write `expect(mockFn).toHaveBeenCalled()` as the only assertion for that interaction.
- About to add `getInternalState()`, `_testHelper()`, or any test-only accessor to a production class.
- About to mock a data object with only the fields this one test reads.
- About to write tests after the implementation is "complete" (rather than driving it via TDD).
- About to mock a function or class you wrote and own.
- About to claim a change is ready for review without showing test output as evidence.
- About to silently adjust a failing test's assertion to match what the code now returns.

**All of these mean: the test is being shaped to pass, not to prove behavior. Re-anchor on Arrange-Act-Assert and the boundary rule.**
