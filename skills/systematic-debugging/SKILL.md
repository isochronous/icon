---
name: systematic-debugging
description: >
  Use when a bug persists after 2+ fix attempts on the same issue, when a fix is being added at the line where the error surfaced rather than where the bad state originated, when invalid input is being patched with try/catch instead of traced to its source, or when a failure cannot be reproduced and the response is to guess at the cause.
user-invocable: true
---

# Systematic Debugging

## Overview

**Fix the root cause, not the symptom.** Most debugging fails because the agent fixes where the error surfaces, not where the bad state originates. This skill enforces backward tracing and defense-in-depth validation.

## systematic-debugging: Phase 1: Reproduce

Before debugging, confirm the failure is reproducible:

1. Run the exact command or test that fails.
2. Capture the full error output.
3. Determine whether the failure is consistent or intermittent.

If you cannot reproduce it, you cannot fix it. Go back to the reporter for clarification.

### Collaborative Investigation

Some failures are easier to diagnose with the user — particularly when reproduction needs their environment, data, or runtime conditions. If user involvement would meaningfully speed root-cause identification, use it: instrument the code to surface debug output, have the user run it and report back. Better than guessing at causes you cannot observe.

### Production Incidents

When the failure comes from production (not a local test), reproduction needs different inputs:

1. **Gather observability data first**: Collect logs, error traces, metrics, and request IDs from production before reproducing locally.
2. **Identify the trigger**: What user action, data shape, or timing caused it? Logs and metrics answer this — guessing does not.
3. **Reproduce locally with production-like state**: Use the gathered data to reconstruct the failure. If it depends on data volume, concurrency, or env config, replicate those conditions as closely as possible.
4. **If local reproduction fails**: It may be environment-specific (infrastructure, config, race under load). Document what you tried and escalate with the observability data — don't guess at fixes you can't verify.

## systematic-debugging: Phase 2: Root-Cause Tracing

Trace backward through the call chain to where invalid state originates:

1. Start at the error location — what value or state is wrong?
2. Trace backward — where does that value come from?
3. Continue until you find the **first point** where the data becomes invalid.
4. The fix belongs at that first point, not where the error was detected.

**Key principle**: Never fix at the symptom level. If a function receives bad data and crashes, the fix is wherever the bad data was created — not in the crashing function.

## systematic-debugging: Phase 3: Defense-in-Depth

Once you find the root cause, add validation at **every layer** the data passes through:

| Layer | Action |
|-------|--------|
| Entry point | Validate input shape and types |
| Business logic | Assert preconditions before processing |
| Environment | Guard against missing config or dependencies |
| Debug aids | Add logging or assertions that make future failures obvious |

Don't just fix the one place that broke — ensure invalid data cannot silently pass through any layer.

## systematic-debugging: Phase 4: Verify the Fix

1. Run the original failing test — it must pass.
2. Run the full suite — no regressions.
3. If the fix added validation, write a test that sends the invalid data and confirms the validation catches it.
4. Show the command output as evidence.

## Escalation Rules

| Situation | Action |
|-----------|--------|
| Fix attempt 1-2 fails | Re-read the error carefully. Are you fixing the right thing? |
| Fix attempt 3 fails | Stop. Your model of the problem is likely wrong. Re-trace from Phase 2. |
| Re-trace still fails | Escalate to @architect for structural analysis. The architecture itself may be the issue. |
| Architectural issue confirmed | Propose a design change rather than another patch. |

## Post-Incident Follow-Up

After resolving a production incident (not required for routine dev bugs):

1. **Write a regression test** reproducing the exact failure condition.
2. **Add monitoring/alerting** if the failure could recur silently (metric, WARN/ERROR log, or alert rule).
3. **Update runbooks** if resolution required non-obvious steps that would help the next responder.
4. **Note in `.context/retrospectives.md`** — production incidents are high-value lessons. Include the root cause, what made diagnosis hard, and what would make it faster next time.

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The fix at this level prevents the crash" | A symptom-level fix lets the same bad state cause a different failure later. Trace to where the data became invalid. |
| "I've tried 2 fixes — the third will work" | Three failed fixes means your model is wrong. Stop and re-trace from Phase 2; don't guess again. |
| "I can't reproduce locally — I'll add a try/catch and ship" | Untraced exceptions become silent data corruption. If you can't reproduce, gather observability data first; don't patch with `catch (Exception)`. |
| "Adding validation at every layer is over-engineering" | One layer is what every previous bug also had. Defense-in-depth surfaces the next regression at the boundary, not in production. |
| "The error names function X, so the bug is in X" | The error names where the failure was detected. The bug lives wherever the data first became invalid — usually upstream. |
| "I don't need a regression test — the fix is obvious" | Without a test, the next refactor silently reintroduces the bug. Not done until a failing-then-passing test exists. |
| "The failure is intermittent — must be a race condition" | "Intermittent" without trace data is a guess. Add logging, instrument the path, or capture the failing payload before assuming concurrency. |

## Red Flags — STOP and Restart

If you catch yourself doing any of these, STOP and re-trace from Phase 2:

- About to add a `try/catch` around the failing line without knowing where the bad data originated.
- About to add a null check or default value at the crash site instead of tracing where `null` came from.
- Three or more fix attempts have failed for the same root issue.
- About to ship a fix you cannot reproduce or verify with output evidence.
- Concluded the cause is "race condition / intermittent" without observability data to back it.
- About to escalate to @architect without first re-tracing — escalation only after Phase 2 has been re-run from scratch.

**All of these mean: your model of the problem is wrong. Re-trace from Phase 2 — Root-Cause Tracing.**
