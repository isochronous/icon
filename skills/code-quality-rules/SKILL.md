---
name: code-quality-rules
description: >
  Use when conducting a code review — including when the diff is "small enough" that skipping passes feels safe, when CI-green is being treated as proof of correctness, when a security-sensitive change has only happy-path tests, when "tests exist" is being used as Pass 5 satisfaction without checking assertions, or when an experienced author's PR is being approved without each pass being run.
user-invocable: false
---

# Code Quality Rules

## Overview

The evaluation criteria, severity levels, and multi-pass methodology for code reviews. Apply when reviewing any code change.

## Checklist

**Code Quality**: No commented-out code. No debug statements. Proper error handling (no swallowed exceptions). No hardcoded secrets. Clear naming. No magic numbers. DRY followed.

**Security**: No sensitive data in logs or error messages. User input validated/sanitized at trust boundaries. No SQL injection (parameterized queries). No XSS (output encoding). No eval() or dynamic code execution. Auth/authz enforced at the service layer, not just the UI. Secrets not hardcoded or committed. New endpoints or data access paths have appropriate access controls. Auth/authz changes get extra scrutiny — verify the change doesn't widen access unintentionally.

**Performance**: No N+1 query patterns. Resources cleaned up (connections, files, streams). Expensive operations not in hot paths.

**Testing**: Tests exist for new functionality. Assertions are meaningful (real behavior, not mock existence). Edge cases covered. No test-only methods in production classes. For changed decision points, check whether the standardized **Coverage Evidence Block** from `testing-discipline` is present and reasonably complete. Treat as process guidance: note gaps as coaching feedback, not an automatic blocker.

**Verification**: Build and test commands were actually run, not assumed. Output evidence included or reproducible.

**Maintainability**: Methods not excessively long. Reasonable cyclomatic complexity. Clear separation of concerns. No circular dependencies.

## Severity Levels

**Critical**: Security vulnerabilities, data loss risk, crashes, breaking public API changes, incorrect business logic.

**Moderate**: Performance issues, missing error handling, missing tests for important paths, deviation from established patterns.

**Minor**: Style inconsistencies not caught by linters, documentation improvements, optional refactoring.

## Review Passes

For thorough reviews, evaluate through multiple focused passes rather than one read. Each pass has a narrow focus that prevents issues from being overlooked.

### code-quality-rules: Pass 1: Correctness & Logic
- Does the code do what the specification requires?
- Off-by-one errors, null/undefined paths, or race conditions?
- Are error states handled, not just happy paths?
- Does the control flow match the intended behavior?

### code-quality-rules: Pass 2: Security & Trust Boundaries
- Is user input validated before use?
- Are authorization checks present at the service layer (not just UI)?
- Are secrets, tokens, or PII handled safely (not logged, not exposed)?
- Do new endpoints or data paths have appropriate access controls?
- Are SQL queries parameterized? Is output encoded to prevent XSS?

### code-quality-rules: Pass 3: Integration & Side Effects
- How do these changes interact with existing code?
- Unintended side effects on callers or consumers?
- Do changes to shared utilities affect other modules?
- Are database migrations backward-compatible?
- Are API contract changes backward-compatible?

### code-quality-rules: Pass 4: Maintainability & Clarity
- Would a new team member understand this without the PR description?
- Are names descriptive and consistent with project conventions?
- Is complexity justified, or could the same result be simpler?
- Any magic numbers, unclear abbreviations, or misleading names?

### code-quality-rules: Pass 5: Evidence & Completeness
- Did the implementer run the build and include output?
- Do tests exist for new behavior, and do assertions verify real outcomes?
- Are all requirements from the task specification addressed?
- Is there scope creep — changes beyond what was specified?

### When to Use All Passes

**Full multi-pass review**: New features, cross-module changes, security-sensitive code, public API changes.

**Abbreviated review (Passes 1, 4, 5 only)**: Single-file bug fixes, documentation changes, configuration changes, test additions.

The output should still use the standard Findings structure (Critical / Moderate / Minor), but note which pass uncovered each finding — this helps the author understand the issue's nature.

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The diff is small — one read is enough" | Small diffs hide subtle issues precisely because reviewers stop reading. Each pass takes seconds on a small diff; run them. |
| "CI is green — that's the review" | CI proves the code compiles and tests pass. Not that the tests are meaningful, the design sound, or auth boundaries correct. |
| "Tests exist, Pass 5 is satisfied" | Pass 5 asks whether tests verify real outcomes, not whether files exist. Open the test file; confirm assertions match the change. |
| "I trust this author — skip the security pass" | Trust shortcuts are how subtle auth widenings ship. Pass 2 is non-negotiable for any change touching auth, input handling, or trust boundaries. |
| "The author already explained it in the PR description" | Pass 4 asks whether the *code* is clear without the description. The description rots; the code stays. |
| "It's a doc / config / styling change — skip everything but Pass 4" | Config can break envs; docs can mislead contributors; CSS can leak XSS via attribute injection. Match passes to the actual change surface. |
| "Pass 3 (integration) doesn't apply — no callers will notice" | Author claims about caller impact are hypotheses. Verify by searching for callers; don't skip on assurance. |
| "I caught the big issues — minor stuff can ship" | Minor issues compound. Style drift becomes pattern drift becomes architectural drift. Note them; the author decides. |

## Red Flags — STOP and Run the Missing Pass

If you catch yourself thinking any of these, the review is not done:

- About to approve without having opened every changed file.
- About to skip Pass 2 (security) because the change "doesn't look security-sensitive".
- Treating CI-green as Pass 5 (evidence) — without confirming the assertions test the changed behavior.
- About to accept "tests exist" without reading the assertions.
- About to skip Pass 3 (integration) because the author said no callers will notice.
- Reviewing a security-sensitive change whose tests only cover the happy path.
- Approving a senior author's PR faster because "they don't make mistakes".

**All of these mean: a pass was skipped. Run it now, or hand the review to someone who will.**
