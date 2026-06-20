---
name: post-incident-review
description: >
  Use when a production incident has been resolved, a credential or secret leak has been caught, a data-loss near-miss occurred, or a retro is about to be written for a production-adjacent bug — including when an incident is being closed without a written timeline, when "we already know the cause" is short-circuiting root-cause analysis, when action items are landing without owners or dates, or when a P1/P2 user-affecting incident is being closed without comms.
user-invocable: true
---

# Post-Incident Review

## Overview

**Incidents that aren't reviewed are incidents that repeat.** This skill turns a one-off production failure into organizational memory by guiding a structured classify → timeline → root-cause → comms → action-items → retro-append process. The retrospective entry at the end is the durability mechanism — without it, the review evaporates.

## When to Use

- Production bug has been resolved
- Credential or secret leak was caught (even if no data was exposed)
- Data-loss near-miss occurred
- External-facing behavior drifted in a way users noticed
- A retro about to be written carries a "this should never happen again" finding

**When NOT to use**: Routine dev bugs that never touched production. Use `systematic-debugging` for those. The dividing line is user-impact or security exposure — if neither applies, skip this skill.

## Relationship to systematic-debugging

`systematic-debugging` includes a brief Post-Incident Follow-Up checklist that flags the concern this skill addresses; this skill is the full expansion of that checklist. Cross-reference `systematic-debugging` for the root-cause trace technique (the backward-trace to first-point-of-invalid-state); do not restate it here.

---

## post-incident-review: Phase 1: Classify

Establish what kind and magnitude of incident this is before going further.

| Dimension | Questions |
|-----------|-----------|
| **User impact** | Were users affected? How many? Were any features unavailable or degraded? |
| **Data** | Was data lost, corrupted, or exposed? Was any data written that shouldn't have been? |
| **Credentials / Secrets** | Were secrets, tokens, keys, or credentials exposed — even briefly? In logs? In a response body? |
| **Duration** | When did the incident begin? When was it fully resolved? |
| **Blast radius** | One user, cohort, all users, or external systems? |

Severity classification:

| Severity | Criteria |
|----------|----------|
| **P1 (Critical)** | Data loss, credential exposure, total service outage |
| **P2 (High)** | Partial outage, data inconsistency without loss, secret in logs |
| **P3 (Medium)** | Degraded performance, incorrect behavior for a subset of users |
| **P4 (Low)** | Internal-only issue, no user impact |

Classify before continuing — severity drives which later phases are required.

---

## post-incident-review: Phase 2: Timeline Reconstruction

Produce a named timeline from trigger to resolution. Absence of precise times is not a blocker — estimate, and mark estimates explicitly.

Required events:

1. **Trigger** — What caused the incident to begin? (code deploy, config change, external event)
2. **Detection** — When and how was it noticed? (alert, user report, internal observation)
3. **Diagnosis** — When was root cause identified? Who identified it?
4. **Fix applied** — What change resolved the incident? When was it deployed?
5. **Verification** — When was it confirmed that the incident was fully resolved?

Keep actor names generic (e.g., "on-call engineer") unless the specific person is relevant to a structural finding. The goal is process clarity, not blame attribution.

---

## post-incident-review: Phase 3: Root-Cause Analysis

Use the `systematic-debugging` Phase 2 backward-trace or the "5 whys" technique. The goal is a single **first-point-of-invalid-state** conclusion — the earliest point in time or code path where the system entered an incorrect state.

Anti-patterns to avoid:
- Stopping at "human error" — that's a symptom, not a cause
- Identifying the fix as the cause (circular)
- Multiple root causes listed without ordering them by which one enables the others

The root-cause statement format: *"The system entered an invalid state when [specific condition] because [structural reason], which was not detected before [detection point]."*

---

## post-incident-review: Phase 4: Comms Template

**Required for P1/P2 incidents where users were affected.** Optional for P3/P4 and internal-only incidents.

Internal summary structure:

```
What happened: [one sentence, plain language]
Who was affected: [user scope]
Timeline: [trigger → detection → resolution, condensed]
What we're doing: [immediate fix applied + follow-up actions]
Status: [resolved / monitoring / ongoing]
```

Do not include root-cause speculation in user-facing comms — that belongs in the internal review.

---

## post-incident-review: Phase 5: Action Items with Owners

Each finding from Phase 3 must produce at least one action item. Action items without owners and due dates are not action items — they are intentions.

Required fields per action item:

| Field | Requirement |
|-------|-------------|
| **Action** | Concrete verb + deliverable (not "monitor", "improve", "consider") |
| **Owner** | Named person or named role if person is unknown |
| **Due date** | Specific date or milestone — not "soon" or "later" |
| **Verification** | How will completion be confirmed? |

**No "we should monitor this" items** without a concrete follow-up that converts the monitoring signal into a specific action. If monitoring is the right response, define the threshold that triggers the next action.

---

## post-incident-review: Phase 6: Retrospective Append

Write the `.context/retrospectives.md` entry for this incident. Use the standard Avoid/Repeat/Updated format from the `task-retrospective` skill.

**Route through `@context-specialist` in maintenance mode** — do not hand-edit `retrospectives.md` directly. The maintenance-mode skill runs the append-retrospective-entry script that enforces format consistency and prevents duplicate entries. This skill keeps a self-contained copy of the script under `./scripts/append-retrospective-entry.{sh,ps1}` for direct use when delegation is unavailable.

The retrospective entry should:
- State the root cause in one sentence
- Name the promoted standard or process change (if any action item produces one)
- Cross-reference the action items list by date
- Use the format: *"[What happened]. [Structural fix]. [Future agents: do X instead of Y]."*

---

## Common Mistakes

- **Skipping timeline reconstruction** because "everyone knows what happened" — timeline disagreements surface during the review, not before it
- **No owner on action items** — shared responsibility is no responsibility
- **Treating comms as optional when users were affected** — silence is a communication choice with consequences
- **Re-classifying severity down after the fact** — severity is determined at time of incident, not after the fix is known
- **Stopping at the proximate cause** — "the deploy broke it" is not a root cause; the root cause is why the deploy was able to break it

---

## Rationalization Prevention

| Rationalization | Reality | Correct Action |
|----------------|---------|----------------|
| "It was a small incident, no review needed" | Small incidents signal systemic gaps as reliably as large ones | Run Phase 1 at minimum — if truly P4, the review is short |
| "We already know the root cause" | Assumed root cause is often wrong; timeline reconstruction reveals actual cause | Complete Phase 2 before writing the root-cause statement |
| "The action item owner will figure out the details" | Action items without specific deliverables are never done | Write the deliverable, not the intention |
| "We fixed it, so we don't need comms" | Users affected during the incident deserve closure even after resolution | Complete Phase 4 for any P1/P2 user-affecting incident |
| "I'll write the retrospective entry later" | "Later" means the review evaporates | Phase 6 is part of the review, not a follow-up task |
| "Severity should be P3 in hindsight — the fix was easy" | Severity is determined at time of incident, not by ease of fix | Keep the original severity classification; note the fix simplicity separately |
| "It was human error" | Human error is a symptom — the root cause is why the system permitted it | Continue Phase 3 until you reach a structural cause |

## Red Flags — STOP and Run the Missing Phase

If you catch yourself doing any of these, the review is incomplete:

- About to close the incident without a retrospective entry in `.context/retrospectives.md`.
- About to skip Phase 2 (timeline) because "everyone knows what happened".
- Action items have shared owners, "soon" / "later" due dates, or no verification step.
- About to skip Phase 4 (comms) on a P1/P2 user-affecting incident.
- Stopping the root-cause analysis at "human error" or "the deploy broke it".
- About to re-classify severity downward after the fact.
- About to hand-edit `retrospectives.md` directly instead of routing through `@context-specialist` (or invoking the local script).

**All of these mean: a review phase is being skipped. Run it now — incidents that aren't fully reviewed are incidents that repeat.**
