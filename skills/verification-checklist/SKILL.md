---
name: verification-checklist
description: >
  Use before reporting any task as complete — including when "should work" / "would pass" / "logic is correct" is being used as evidence, when no command output appears in the completion report, when "minor" / "trivial" / "simple" is qualifying a verification skip, or when build-succeeded is being treated as tests-passed.
user-invocable: false
---

# Verification Checklist

## Overview

**"Believed to be done" is not done.** Completion requires command output proving correctness — not reasoning about why it should work. This skill enforces that gate before any task is reported complete.

## Evidence-Based Verification Gate

Before claiming any task is complete, you must have **command output** proving it works. Internal reasoning is not evidence.

| Claim | Required Evidence |
|-------|-------------------|
| "Tests pass" | Show the test runner output with pass count |
| "Build succeeds" | Show the build command output with success status |
| "Lint is clean" | Show the linter output with no errors |
| "Feature works" | Show the command or test that exercises the feature |
| "Bug is fixed" | Show the previously-failing test now passing |

If you haven't run the command, you can't make the claim.

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "This should work because…" | You haven't tested it. Run the command; show the output. |
| "The logic is correct" | You're reasoning instead of running. Reasoning is not evidence. |
| "It's a simple change" | Simple changes still break things. Run the verifier anyway. |
| "I've seen this pattern work before" | Past experience is not current verification. Re-run it. |
| "The tests would pass" | Would ≠ did. Run them. |
| "Build succeeded — that means tests pass" | Build is not test. Tests are not lint. Each requires its own command output. |
| "I'll run the verification after merge" | Then the task is not complete. Verify before claiming done. |
| "Tests are in the right shape" | Shape is not output. Run them and show the result. |
| "Minor / trivial / simple" | These words minimize risk. Strip them from the report and evaluate objectively. |
| "The suite is green, that loader/collection error scrolled past is noise" | A green count can hide unrun files. An unexplained test-count change (e.g. 1452→1450) means tests stopped running or were deleted — account for the delta before claiming pass. |

## Completion Quality Gate

Before marking any task complete, pass through these gates in order. A failure at any gate means the task is NOT complete.

### verification-checklist: Gate 1: Evidence Exists
Every success claim has corresponding command output. No exceptions, no "it should work because..." reasoning.

### verification-checklist: Gate 2: Scope Fidelity
The implementation matches the task specification — no more, no less. Check for:
- **Under-delivery**: Requirements that were specified but not implemented
- **Over-delivery**: Changes that weren't requested (scope creep, "while I was here" changes, preemptive error handling for unobserved cases)
- **Drift**: Implementation that addresses a different problem than what was specified

### verification-checklist: Gate 3: Pattern Consistency
The changes follow established project patterns. Verify:
- Naming conventions match existing code
- File locations follow project structure
- Error handling matches project patterns
- No new dependencies introduced without explicit approval

### verification-checklist: Gate 4: No Rationalization Residue
Review your own completion report for rationalization language:
- "Should" → Replace with "does" backed by evidence
- "Would" → Replace with "did" backed by evidence
- "Probably" → Replace with certainty or acknowledge the gap
- "Minor" / "trivial" / "simple" → These words minimize risk. Remove them and evaluate objectively.

## Red Flags — STOP and Run the Command

If you catch yourself doing any of these, the task is NOT complete:

- About to type "should work" / "would pass" / "logic is correct" in the completion report.
- About to mark a task complete without command output appearing in your response.
- Tests have been written but the test command has not been executed.
- Build succeeded and you are about to claim "all checks pass" without running tests or lint.
- Using "minor", "trivial", or "simple" to qualify *why* verification was skipped.
- About to write "I'll verify after merge" — that means it is not verified now.

**All of these mean: run the command, capture the output, and put the output in the report. Do not paraphrase what the output would be.**

## How to Use This Skill

1. Complete your implementation work.
2. Run all relevant verification commands (build, test, lint).
3. Walk through the Completion Quality Gate above, failing any gate where evidence is missing.
4. Include command output in your completion report.
5. If any gate fails, fix it before reporting — do not report with caveats.
