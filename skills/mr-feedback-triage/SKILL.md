---
name: mr-feedback-triage
description: >
  Use when a GitLab merge request has open review comments and the author needs to assess which threads are blocking versus optional, and what action is needed to resolve each one — including when reviewer feedback is scattered across the diff, when it is unclear which comments must be addressed before merge, or when the author wants a prioritized resolution plan for each thread.
user-invocable: true
---

# MR Feedback Triage

## Overview

**Unread reviewer feedback is debt. Mis-triaged reviewer feedback is waste.** This skill pulls all open discussion threads from a GitLab MR, assesses each for necessity, synthesizes what action is needed to close it, and produces a prioritized triage report the author can work from.

## When to Use

- A GitLab MR has open review comments and you need a resolution plan
- You're unsure which reviewer threads are blocking merge versus optional
- You want a structured summary before addressing feedback

**When NOT to use**: For performing a code review yourself → use `code-quality-rules`. For MR authoring discipline → use `mr-discipline`.

---

## mr-feedback-triage: Phase 1: Guard and Fetch

**Check prerequisites first.** If GitLab MCP tools are unavailable, stop immediately:
> GitLab MCP tools are not available. Run `/setup-mcp-servers` or `/icon-status` to verify credentials, then retry.

**Identify the MR.** If not provided by the user, check branch context or ask:
- `project_id` — GitLab project ID or full path (e.g., `my-group/my-repo`)
- `merge_request_iid` — the MR's internal ID

**Fetch MR metadata:** Call `gitlab-get_merge_request` to confirm the MR exists and capture the source branch and diff refs.

**Fetch all discussions:** Call `gitlab-mr_discussions` with pagination, iterating until all pages are exhausted. Do not stop at the first page.

**Filter to open human threads.** Exclude threads where:
- All notes have `author.username` matching a bot pattern (e.g., ends with `[bot]`, `_bot`, or is a service account)
- The thread is fully resolved (`notes[0].resolved == true` on any resolvable thread)
- All notes are system notes (`system == true`)

Retain both resolvable unresolved threads and non-resolvable human comment threads.

If zero threads remain after filtering, report:
> No open human review threads found on this MR.

---

## mr-feedback-triage: Phase 2: Gather Code Context

For each retained thread that has an inline position (`position` is present):
- Extract `new_path` (or `old_path`), `new_line` / `old_line`
- Collect unique file paths across all inline threads

Batch-fetch diffs: call `gitlab-get_merge_request_file_diff` with all unique file paths in one call (or a few batches if many files).

For each thread, locate the hunk containing the referenced line. If the diff cannot be matched (file renamed, deleted, position outdated, or line not found):
- Mark context as **outdated or unavailable**
- Do not fabricate a resolution; instead propose investigation

For general (non-inline) threads, mark as **No code location — general comment**.

---

## mr-feedback-triage: Phase 3: Assess Each Thread

For each thread, assess the **entire discussion** — not just the first note. The last substantive reviewer note may soften, retract, or escalate the original request. Quote the most actionable note.

Assign a necessity tier:

| Tier | Label | Assign when |
|------|-------|-------------|
| 🔴 | **Blocking** | Correctness or security flaw, data loss risk, policy/architecture violation, approval-gating concern |
| 🟡 | **Recommended** | Performance concern, readability issue, design inconsistency, strong reviewer preference |
| ⚪ | **Optional** | Explicit `nit:` prefix, style preference, speculative future concern, rhetorical question without fix request |

**Reviewer tone is a signal, not a rule.** A reviewer saying "please fix" on a style preference is Recommended. A quiet diff comment flagging a null-dereference is Blocking.

For the **Proposed action**, choose the most appropriate response type:
- **Code change**: specific edit that would close the thread
- **Reply**: clarification or rebuttal where no code change is needed
- **Investigation**: context is unclear or outdated — investigate before deciding
- **Already addressed**: if the code was already changed; propose a "resolved by commit [sha]" reply

> **As part of this skill, never resolve threads or post replies on behalf of the author.** For threads where code has already been addressed, include suggested reply text in the report (e.g., "resolved by commit [sha]") for the author to post. The reviewer who raised the concern is the one who resolves it — posting replies or resolving threads automatically skips their validation step and may cause feedback to be silently dropped. Do not call `gitlab-resolve_merge_request_thread`, `gitlab-create_merge_request_discussion_note`, `gitlab-create_merge_request_note`, or `gitlab-create_note` as part of this skill.

---

## mr-feedback-triage: Phase 4: Report

Produce the triage report grouped by tier (Blocking first, then Recommended, then Optional). Preserve original MR thread order within each tier.

**Header:**
```
## MR Feedback Triage: [MR title] (!IID)
[N] open threads — [B] Blocking · [R] Recommended · [O] Optional
```

**Per-thread entry:**
```
---
### Thread [N] — [discussion_id short prefix]
📍 `path/to/file.ts:42` ← or "General comment" if no location
💬 "[exact quoted text of the most actionable reviewer note]"

**Necessity:** 🔴 Blocking — [one-sentence rationale]
**Proposed action:** [code change / reply / investigation / already addressed]
**Context:** [full / partial / outdated — note if diff context was unavailable]
```

If a thread has multiple notes and the last note changes the thread's intent (e.g., reviewer withdrew the request), note it:
> _Reviewer follow-up softened this to a suggestion. Re-classified as Recommended._

**Report footer — include at the end of every triage report:**

> **Before re-requesting review:** If any feedback-driven code change makes an existing `.context/` statement false, incomplete, or missing — APIs, data contracts, constraints, architecture decisions, required config, or workflow documentation — invoke `context-maintenance` before re-requesting review. If unsure, invoke it.

---

## Common Mistakes

- **Assessing only the first note** — multi-note threads often end in a retraction, escalation, or clarification that changes the right response
- **Marking all explicit fix requests as Blocking** — intent and correctness are the signal, not request phrasing
- **Skipping pagination on busy MRs** — a single-page read silently drops threads; always exhaust pages
- **Fabricating a resolution when diff context is missing** — mark as "Investigation" instead
- **Missing non-resolvable general comments** — GitLab `resolvable: false` threads can still carry blocking feedback
- **Resolving threads, posting replies, or adding comments directly** — do not call `gitlab-resolve_merge_request_thread`, `gitlab-create_merge_request_discussion_note`, `gitlab-create_merge_request_note`, or `gitlab-create_note` as part of this skill, including after pushing fixes to address feedback. Resolving is the reviewer's prerogative; this skill produces a report with suggested reply text for the author to post — all MR interactions are the author's responsibility, and the reviewer closes the thread when satisfied
