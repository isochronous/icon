---
name: pr-feedback-triage
description: >
  Use when a GitHub pull request has open review comments and the author needs to assess which threads are blocking versus optional, and what action is needed to resolve each one — including when reviewer feedback is scattered across the diff, when it is unclear which comments must be addressed before merge, or when the author wants a prioritized resolution plan for each thread.
user-invocable: true
---

# PR Feedback Triage

## Overview

**Unread reviewer feedback is debt. Mis-triaged reviewer feedback is waste.** This skill pulls all open review comments from a GitHub PR, assesses each for necessity, synthesizes what action is needed to close it, and produces a prioritized triage report the author can work from.

## When to Use

- A GitHub PR has open review comments and you need a resolution plan
- You're unsure which reviewer threads are blocking merge versus optional
- You want a structured summary before addressing feedback

**When NOT to use**: For performing a code review yourself → use `code-quality-rules`. For PR authoring discipline → use `pr-discipline`.

---

## pr-feedback-triage: Phase 1: Guard and Fetch

**Check prerequisites first.** This skill drives the `gh` CLI. If it is unavailable or unauthenticated, stop immediately:

```bash
gh auth status
```

> The `gh` CLI is not available or not authenticated. Run `gh auth login`, then retry.

**Identify the PR.** If not provided by the user, infer it from branch context (`gh pr view --json number,title,headRefName`) or ask:
- `repo` — `owner/repo` (defaults to the current repository's `origin` remote)
- `pr` — the PR number

**Fetch PR metadata:** Confirm the PR exists and capture its title, number, head branch, and base:

```bash
gh pr view <pr> --json number,title,headRefName,baseRefName,url
```

**Fetch all review comments.** GitHub has two distinct comment surfaces — fetch both, do not stop at one:

1. **Inline review comments** (anchored to a file/line in the diff) — paginate until exhausted:
   ```bash
   gh api --paginate "repos/{owner}/{repo}/pulls/<pr>/comments"
   ```
2. **Review summaries** (the body a reviewer writes when submitting an Approve / Request-changes / Comment review):
   ```bash
   gh api --paginate "repos/{owner}/{repo}/pulls/<pr>/reviews"
   ```
3. **Issue-level (general) PR comments** (the conversation tab, not anchored to the diff):
   ```bash
   gh api --paginate "repos/{owner}/{repo}/issues/<pr>/comments"
   ```

`--paginate` walks every page; do not hand-roll page loops or stop at the first page.

A GitHub review **thread** is the chain of inline comments sharing an `in_reply_to_id` lineage (the root comment plus its replies on the same `path`/`line`). Group the inline comments into threads by following `in_reply_to_id` back to each root.

**Filter to open human threads.** Exclude threads where:
- Every comment's `user.login` matches a bot pattern (ends with `[bot]`, or is a known CI/service account)
- The thread is resolved — GitHub marks resolution on the **review thread**, exposed via the GraphQL API (REST does not return `isResolved`). Fetch resolution state with:
  ```bash
  gh api graphql -f query='
    query($owner:String!,$repo:String!,$pr:Int!){
      repository(owner:$owner,name:$repo){
        pullRequest(number:$pr){
          reviewThreads(first:100){
            nodes{ isResolved isOutdated comments(first:1){ nodes{ databaseId } } }
          }
        }
      }
    }' -F owner={owner} -F repo={repo} -F pr=<pr>
  ```
  Match each REST comment thread to its GraphQL `reviewThread` by the root comment's `databaseId`, and drop threads where `isResolved == true`.

Retain both unresolved inline threads and unresolved general/review-summary comments that carry actionable feedback.

If zero threads remain after filtering, report:
> No open human review threads found on this PR.

---

## pr-feedback-triage: Phase 2: Gather Code Context

For each retained inline thread, the root comment carries `path`, `line` (or `original_line`), and a `diff_hunk` field — GitHub embeds the surrounding diff hunk directly in the comment payload. Use `diff_hunk` as the primary context source; no extra fetch is needed.

When `diff_hunk` is insufficient (the comment is `outdated`, the line shifted, or you need more surrounding code), pull the file's current diff:

```bash
gh pr diff <pr>
```

For each thread, locate the hunk containing the referenced line. If the diff cannot be matched (file renamed, deleted, position outdated per the GraphQL `isOutdated` flag, or line not found):
- Mark context as **outdated or unavailable**
- Do not fabricate a resolution; instead propose investigation

For general (non-inline) comments and review summaries, mark as **No code location — general comment**.

---

## pr-feedback-triage: Phase 3: Assess Each Thread

For each thread, assess the **entire discussion** — not just the first comment. The last substantive reviewer reply may soften, retract, or escalate the original request. Quote the most actionable comment.

Assign a necessity tier:

| Tier | Label | Assign when |
|------|-------|-------------|
| 🔴 | **Blocking** | Correctness or security flaw, data loss risk, policy/architecture violation, a Request-changes review gating merge |
| 🟡 | **Recommended** | Performance concern, readability issue, design inconsistency, strong reviewer preference |
| ⚪ | **Optional** | Explicit `nit:` prefix, style preference, speculative future concern, rhetorical question without fix request |

**Reviewer tone is a signal, not a rule.** A reviewer saying "please fix" on a style preference is Recommended. A quiet diff comment flagging a null-dereference is Blocking. A comment attached to a review submitted as **Request changes** weighs toward Blocking.

For the **Proposed action**, choose the most appropriate response type:
- **Code change**: specific edit that would close the thread
- **Reply**: clarification or rebuttal where no code change is needed
- **Investigation**: context is unclear or outdated — investigate before deciding
- **Already addressed**: if the code was already changed; propose a "resolved by commit [sha]" reply

> **As part of this skill, never resolve threads or post replies on behalf of the author.** For threads where code has already been addressed, include suggested reply text in the report (e.g., "resolved by commit [sha]") for the author to post. The reviewer who raised the concern is the one who resolves it — posting replies or resolving threads automatically skips their validation step and may cause feedback to be silently dropped. Do **not** run `gh pr review`, `gh pr comment`, `gh api ... -X POST .../comments`, or the GraphQL `resolveReviewThread` mutation as part of this skill.

---

## pr-feedback-triage: Phase 4: Report

Produce the triage report grouped by tier (Blocking first, then Recommended, then Optional). Preserve original PR thread order within each tier.

**Header:**
```
## PR Feedback Triage: [PR title] (#<pr>)
[N] open threads — [B] Blocking · [R] Recommended · [O] Optional
```

**Per-thread entry:**
```
---
### Thread [N] — [reviewer login]
📍 `path/to/file.ts:42` ← or "General comment" if no location
💬 "[exact quoted text of the most actionable reviewer comment]"

**Necessity:** 🔴 Blocking — [one-sentence rationale]
**Proposed action:** [code change / reply / investigation / already addressed]
**Context:** [full / partial / outdated — note if diff context was unavailable]
```

If a thread has multiple comments and the last one changes the thread's intent (e.g., reviewer withdrew the request), note it:
> _Reviewer follow-up softened this to a suggestion. Re-classified as Recommended._

**Report footer — include at the end of every triage report:**

> **Before re-requesting review:** If any feedback-driven code change makes an existing `.context/` statement false, incomplete, or missing — APIs, data contracts, constraints, architecture decisions, required config, or workflow documentation — invoke `context-maintenance` before re-requesting review. If unsure, invoke it.

---

## Common Mistakes

- **Assessing only the first comment** — multi-comment threads often end in a retraction, escalation, or clarification that changes the right response
- **Marking all explicit fix requests as Blocking** — intent and correctness are the signal, not request phrasing
- **Fetching only inline comments** — GitHub splits feedback across `pulls/.../comments` (inline), `pulls/.../reviews` (summaries), and `issues/.../comments` (general); reading one surface silently drops the others
- **Skipping pagination on busy PRs** — without `--paginate` a single page read silently drops threads; always exhaust pages
- **Using REST to judge resolution** — REST does not expose thread resolution; only the GraphQL `reviewThreads.isResolved` flag does. Reading REST alone treats resolved threads as still-open
- **Fabricating a resolution when diff context is missing** — mark as "Investigation" instead
- **Resolving threads, posting replies, or adding comments directly** — do not run `gh pr review`, `gh pr comment`, a POST to the comments API, or the GraphQL `resolveReviewThread` mutation as part of this skill, including after pushing fixes to address feedback. Resolving is the reviewer's prerogative; this skill produces a report with suggested reply text for the author to post — all PR interactions are the author's responsibility, and the reviewer closes the thread when satisfied
