---
name: code-quality-rules
description: >
  Use when conducting a code review — including when the diff is "small enough" that skipping passes feels safe, when CI-green is being treated as proof of correctness, when a security-sensitive change has only happy-path tests, when "tests exist" is being used as Pass 5 satisfaction without checking assertions, or when an experienced author's MR is being approved without each pass being run.
user-invocable: false
---

# Code Quality Rules

## Overview

Defines the evaluation criteria, severity levels, and multi-pass methodology for code reviews. Apply these rules when reviewing any code change.

## Checklist

**Code Quality**: No commented-out code. No debug statements. Proper error handling (no swallowed exceptions). No hardcoded secrets. Clear naming. No magic numbers. DRY principle followed.

**Security**: No sensitive data in logs or error messages. User input validated/sanitized at trust boundaries. No SQL injection (use parameterized queries). No XSS (output encoding applied). No eval() or dynamic code execution. Auth/authz properly checked — verify that authorization is enforced at the service layer, not just the UI. Secrets not hardcoded or committed. New endpoints or data access paths have appropriate access controls. Changes to auth/authz logic get extra scrutiny — verify the change doesn't widen access unintentionally.

**Performance**: No N+1 query patterns. Resources properly cleaned up (connections, files, streams). Expensive operations not in hot paths.

**Testing**: Tests exist for new functionality. Assertions are meaningful (test real behavior, not mock existence). Edge cases covered. No test-only methods added to production classes. For changed decision points, check whether the standardized **Coverage Evidence Block** from `testing-discipline` is present and reasonably complete. Treat this as process guidance: note gaps as coaching feedback, not as an automatic blocker.

**Verification**: Build and test commands were actually run, not just assumed to pass. Output evidence is included or reproducible.

**Maintainability**: Methods not excessively long. Reasonable cyclomatic complexity. Clear separation of concerns. No circular dependencies.

## Severity Levels

**Critical**: Security vulnerabilities, data loss risk, crashes, breaking public API changes, incorrect business logic.

**Moderate**: Performance issues, missing error handling, missing tests for important paths, deviation from established patterns.

**Minor**: Style inconsistencies not caught by linters, documentation improvements, optional refactoring opportunities.

## Review Passes

For thorough reviews, evaluate changes through multiple focused passes rather than trying to catch everything in a single read. Each pass has a narrow focus that prevents important issues from being overlooked.

### code-quality-rules: Pass 1: Correctness & Logic
- Does the code do what the specification requires?
- Are there off-by-one errors, null/undefined paths, or race conditions?
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
- Are there unintended side effects on callers or consumers?
- Do changes to shared utilities affect other modules?
- Are database migrations backward-compatible?
- Are API contract changes backward-compatible?

### code-quality-rules: Pass 4: Maintainability & Clarity
- Would a new team member understand this code without the MR description?
- Are names descriptive and consistent with project conventions?
- Is complexity justified, or could the same result be achieved more simply?
- Are there magic numbers, unclear abbreviations, or misleading names?

### code-quality-rules: Pass 5: Evidence & Completeness
- Did the implementer run the build and include output?
- Do tests exist for new behavior, and do test assertions verify real outcomes?
- Are all requirements from the task specification addressed?
- Is there scope creep — changes beyond what was specified?

### When to Use All Passes

**Full multi-pass review**: New features, cross-module changes, security-sensitive code, public API changes.

**Abbreviated review (Passes 1, 4, 5 only)**: Single-file bug fixes, documentation changes, configuration changes, test additions.

The review output format should still use the standard Findings structure (Critical / Moderate / Minor), but consider which pass uncovered each finding — this helps the author understand the nature of the issue.

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The diff is small — one read is enough" | Small diffs hide subtle issues precisely because reviewers stop reading. Each pass takes seconds on a small diff; run them. |
| "CI is green — that's the review" | CI proves the code compiles and tests pass. It does not prove the tests are meaningful, the design is sound, or auth boundaries are correct. |
| "Tests exist, Pass 5 is satisfied" | Pass 5 asks whether the tests verify real outcomes, not whether files exist. Open the test file and confirm the assertions match the change. |
| "I trust this author — skip the security pass" | Trust shortcuts are how subtle auth widenings ship. Pass 2 is non-negotiable for any change touching auth, input handling, or trust boundaries. |
| "The author already explained it in the MR description" | Pass 4 (clarity) asks whether the *code* is clear without the description. The description rots; the code stays. |
| "It's a doc / config / styling change — skip everything but Pass 4" | Config changes can break envs; doc changes can mislead future contributors; CSS can leak XSS via attribute injection. Match passes to the actual change surface. |
| "Pass 3 (integration) doesn't apply — no callers will notice" | Author claims about caller impact are hypotheses, not facts. Verify by searching for callers; do not skip on author assurance. |
| "I caught the big issues — minor stuff can ship" | Minor issues compound. Style drift becomes pattern drift becomes architectural drift. Note them; the author decides whether to fix. |

## Red Flags — STOP and Run the Missing Pass

If you catch yourself thinking any of these, the review is not done:

- About to approve without having actually opened every changed file.
- About to skip Pass 2 (security) because the change "doesn't look security-sensitive".
- Treating CI-green as Pass 5 (evidence) — without confirming the assertions test the changed behavior.
- About to accept "tests exist" without reading the assertions.
- About to skip Pass 3 (integration) because the author said no callers will notice.
- Reviewing a security-sensitive change whose tests only cover the happy path.
- Approving a senior author's MR faster because "they don't make mistakes".

**All of these mean: a pass was skipped. Run it now, or hand the review to someone who will.**
