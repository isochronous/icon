---
name: task-retrospective
description: >
  Use when completing a task, before marking it done.
user-invocable: false
---

# Task Retrospective

## Overview

**Lessons are only valuable if they're findable.** A retrospective takes 2–3 minutes and does two things: captures what was learned in `.context/retrospectives.md`, and immediately promotes generalizable lessons into the relevant `.context/` subdirectory so they inform future work.

## When to Run

Run a retrospective at the end of every medium or complex task (multiple steps, files, or agents). Skip trivial tasks (single-file lint fixes, import additions).

**Phase ordering (retrospective runs inside the completion phase)**: When a
task uses `task-plan-phase-completion`, this skill is invoked **inside** the
completion phase — after review and context-update steps, and **before** the
phase's Completion Summary. It is not a phase that runs after completion; it is a
step within it.

**Precondition: `plan.md` must be reconciled before this skill runs.** The retrospective reads `plan.md` as ground truth — Progress for "what was done", Decisions for "what was chosen", Key Files for "what was touched". A stale plan produces a noisy or wrong retro. Reconciliation is the first step of the completion phase (`.context/workflows/task-plan/phase-completion.md § Reconcile plan.md`); this skill presumes it has run. If you detect staleness — unchecked Progress items whose outcomes are clearly in the diff, Key Files visible in the diff but absent from the list, or Open Questions the diff resolves — stop, flag it, and route back to step 0 of the completion phase rather than proceeding.

## The Three Questions

Answer these three honestly. Short, specific answers beat vague generalities.

### task-retrospective: Question 1: What mistake or friction should we avoid next time?

Focus on **specific, actionable** friction, not abstract complaints.

**Good examples**:
- "Spent 30 minutes debugging a mock that didn't include the `createdAt` field. Future mocks for User objects should use the complete factory helper in `test/factories/user.ts`."
- "Assumed the legacy endpoint accepted camelCase. It requires snake_case. Added a note to a domain file under `.context/domains/`."
- "Tests were flaky because of shared database state between test cases. Each test now sets up its own data."

**Bad examples** (too vague to act on):
- "Communication could be better"
- "We should write more tests"
- "The code was hard to understand"

### task-retrospective: Question 2: What pattern or approach worked well and should be repeated?

Capture techniques that saved time or prevented bugs, especially if not yet documented.

**Good examples**:
- "Writing the API contract test before the implementation caught 3 interface mismatches early."
- "Using the existing `BaseController` pattern for the new endpoint avoided duplicating auth/error handling."
- "Breaking the migration into 2 steps (add column nullable → backfill → add constraint) prevented downtime."

### task-retrospective: Question 3: What should be updated in `.context/` based on this experience?

Decide what to update in `.context/` — and update it now.

## Where to Promote Lessons

Use this table to pick which `.context/` file to update. Do this **now**, at task close — not later.

| Lesson Type | Destination |
|-------------|-------------|
| Coding pattern or convention | `standards/` |
| Test strategy or mock pattern | `testing/` |
| Domain knowledge or business rule | `domains/[area].md` |
| Architectural decision or pattern | `architecture/` |
| CI/CD or deployment process | `workflows/` |
| Module-specific gotcha | `domains/[technical-area].md` |

**If no `.context/` directory exists**: Note the lesson in your completion report and flag that the project needs `initialize-repo`.

Not every task produces a `.context/` update. A lesson too task-specific to generalize belongs only in the retro entry — that's fine. Ask: "Would a future agent working in this area benefit from knowing this?"

## Rolling Log Entry

Each retrospective entry uses this format:

```markdown
### [TASK-ID]: [Short description]
- **Avoid**: [Specific mistake and how to prevent it — cite files, error messages, or concrete outcomes]
- **Repeat**: [Specific technique that worked]
- **Updated**: [Which .context/ file was updated, if any — or "nothing to promote"]
```

Entries are inserted into `.context/retrospectives.md` via the `append-retrospective-entry` script (see the Full Process Checklist below). The manager drafts the entry text; the @context-specialist runs the script. Direct hand-editing is not part of the flow.

If `.context/retrospectives.md` contains any legacy format or legend sections — headings such as `## Entry Format`, `## Format`, `## Legend`, or similar — the manager flags them for removal in the delegation to the specialist. The canonical entry format lives in this skill, not the file.

Entries must be specific enough to be useful without additional context. Vague entries ("avoid bugs", "repeat testing") provide no value.

## Rolling Log Maintenance

The retrospectives file is a **rolling log**, not an ever-growing archive. The `append-retrospective-entry` script keeps the most recent 10 entries automatically (oldest removed when count reaches the script's `ENTRY_CAP`). Pruning is mechanical, not a manual step.

Before an entry rotates out, durable lessons should be promoted to the appropriate `.context/` file — at task close, not during periodic maintenance. So by the time the script prunes the oldest entry, any worth-keeping lesson already lives in a `.context/` document.

**The goal**: The retrospectives file is short-term memory; `.context/` subdirectories are long-term memory.

Once a pattern is promoted to `.context/` and validated across 3+ tasks, it may be a candidate for embedding in a local skill definition. When you observe that stability, ask the team or file a request to add a new skill — skill graduation is a manual, on-demand process.

## Full Process Checklist

The retrospective runs in two stages. The **manager** owns the narrative reflection (Q1 + Q2 answers), evaluates which `.context/` files need updating (Q3 planning), and drafts the entry text. The **@context-specialist** executes the writes — entry insertion via the `append-retrospective-entry` script, domain/standards/architecture updates, and rolling-log pruning.

When closing a task:

### Stage 1 — Manager: Reflect and Draft (Steps 1–3)

1. [ ] Answer Question 1 (Avoid) and Question 2 (Repeat) by reflecting on the task.
2. [ ] Identify which `.context/` files to update based on the lessons (Q3 answer — use the table above). A planning decision, not a write.
3. [ ] Draft the complete retrospective entry text using the format in the Rolling Log Entry section above:
       - Fill in the **Avoid** and **Repeat** fields from your Q1 and Q2 answers.
       - In the **Updated** field, write a placeholder such as `[specialist to complete — files: <list from step 2>]` if context updates are expected, or `nothing to promote` if none are needed.
       - Before appending, scan `.context/retrospectives.md` for any legacy format or legend sections (e.g., `## Entry Format`, `## Format`, `## Legend`). If found, include removal as an instruction to the specialist.

### Stage 2 — @context-specialist: Write and Insert (Steps 4–5)

4. [ ] Delegate to **@context-specialist** with `mode: maintenance`, providing:
       - The drafted entry text from step 3
       - The list of `.context/` files to update from step 2, with the lessons to promote into each
       - Instruction to run the `append-retrospective-entry` script from the `context-maintenance` skill's `scripts/` folder to insert the entry into `.context/retrospectives.md` (do not hand-edit the file)
       - Instruction to report back: which `.context/` files were modified, what was promoted, and which retrospective entries (if any) the rolling-log cap pruned
5. [ ] Receive the specialist's report. Update the entry's **Updated** field with the actual files modified and pruning information from the report. The specialist stages its writes (`git add`) but leaves the commit to the manager — the manager commits all task artifacts together in Task Completion Step 4.

> **Note**: The specialist owns all `.context/` writes including `retrospectives.md` — inserted via the `append-retrospective-entry` script (which removes the oldest entry at the script's `ENTRY_CAP`), never hand-edited. No manual pruning needed.

### Completion Gate

> The completion gate is owned by the manager's Task Completion close-gate (`agents/manager.agent.md` Step 6), where `verification-checklist` runs once over the finished task. When running this retrospective standalone (outside the manager close path), invoke `verification-checklist` yourself to confirm all planned work is done and all builds and tests pass before marking the task done.
