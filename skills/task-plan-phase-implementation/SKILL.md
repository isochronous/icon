---
name: task-plan-phase-implementation
description: >
  Internal task-plan phase skill. Do not invoke without explicit direction.
user-invocable: false
---

# Phase: Implementation

Load this skill when the task's **primary concern is writing code** and the plan
is ready. Where scope is unclear, load `task-plan-phase-investigation` first. This
skill does not cover testing delegation — that's in `task-plan-phase-testing`.
Completion (retro, context updates) is in `task-plan-phase-completion`.

**Template-override rule**: apply `.context/workflows/task-plan/phase-<name>.md` if present — see `task-plan` for the full policy.

## task-plan: Implementation: Phase Entry (Reconstruct-First)

**Run this FIRST, before any implementation work.** Each phase resumes from the
committed `plan.md`, not session memory. Read `## Phase State`, confirm this run's
phase matches `Current`/`Next` and every earlier phase is `done`, then read the
preceding handoff block plus the cumulative `## Decisions` / `## Key Files` /
`## Constraints`. Validate this phase's entry contract (approved approach +
decisions + key-files set + any architecture assessment) and **fail closed** — if
a required input is missing, a prerequisite phase is not `done`, `HEAD` lacks the
expected `Phase-Handoff:` trailer, or the tree is unexpectedly dirty, STOP and
surface the gap; do not re-derive to backfill. Full protocol and entry contract:
`phase-implementation.md` `## Phase Entry`; `## Phase State` /
`## Phase Handoff Log` shapes: `base.md` Section Guidance.

## task-plan: Implementation: Pre-Dispatch Checklist

Before dispatching any @coder step:

- [ ] Run `git status --short`. If staged changes exist from previous agent work, commit or stash them first — a committing agent will sweep unrelated staged changes into its commit.
- [ ] Confirm the plan's current step is fully specified: files, patterns, acceptance criteria.
- [ ] If the step creates new files: include "commit the new file" as an explicit acceptance criterion. @coder agents often leave new files untracked unless told to commit.

## task-plan: Implementation: @coder Dispatch Structure

Every @coder delegation must include all of these fields:

```
Step [N]: [description]
Files to create/modify:
  - [path/to/file]: [what to do]
Patterns to follow:
  - [reference to .context/standards/ or .context/architecture/]
Research/architecture findings: [summary or "N/A"]
Acceptance criteria:
  - [Specific, verifiable outcome]
  - Commit all created/modified files
```

## task-plan: Implementation: Step Completion Verification

After each @coder step completes:

1. Run `git status --short` — verify no untracked new files remain.
2. Confirm the acceptance criteria are met.
3. Update `plan.md` `## Progress`: check the step, add an outcome note (`— [brief description of what was done/changed]`).
4. If the project has a build step: confirm the build passes before the next step.

## task-plan: Implementation: Deviation Handling

When @coder reports a deviation from the plan (different approach, unexpected blocker, different files touched):

1. Document immediately in `plan.md` `## Decisions`.
2. Assess impact: does it affect subsequent steps?
3. If architectural: consult @architect before proceeding.
4. If minor (same outcome, different path): proceed, keeping the Decisions note.
5. When `@coder` stalls, the manager escalates by invoking `systematic-debugging` — that skill owns the numeric trigger.

## task-plan: Implementation: Progress Tracking

Keep `plan.md` current throughout:

- Mark steps complete with outcome notes (not just checkmarks).
- Move new ambiguities to `## Open Questions / Blockers` as they arise.
- Add newly discovered files to `## Key Files`.

## task-plan: Implementation: Pre-Completion Review

When all implementation and testing steps are done, and BEFORE handing off to
completion or reporting the work done, dispatch @reviewer over the full
changed-file set. Resolve critical and moderate findings by routing fixes back to
@coder (which re-opens implementation). Then record a `## Review Checkpoint` line
in `plan.md` naming the reviewed step and findings-resolution status. This is the
primary review — it runs before the task is reported done.

## task-plan: Implementation: Phase Exit (Handoff Write)

**Run this LAST, at the phase boundary.** Phase boundaries are commit points.
Append one `### Handoff: implementation → <next-phase>` block to
`## Phase Handoff Log` (append-only — never rewrite earlier blocks) capturing the
@coder outcomes and deviations, the Pre-Completion Review findings + resolution,
verification evidence (copied output — clean `git status --short`, structural
checks), the Decisions/Key Files deltas, and **What the next phase needs** (the
changed-file set); mirror the deltas into their sections. Update `## Phase State`
(advance `Completed`/`Current`/`Next`, set the `Current` status, record the next
loaded skill, reset `Attempts` to `0`). Then commit `plan.md` plus all
source/artifact deltas with the trailer `Phase-Handoff: implementation` —
uncommitted work at a boundary is an incomplete handoff and the next phase fails
closed. Full write/commit steps: `phase-implementation.md` `## Phase Exit /
Handoff`; block shape: `base.md` Section Guidance and `context-document-guidelines`.

## task-plan: Implementation: Relationship to Other Skills

- **`systematic-debugging`**: Invoke when `@coder` stalls — that skill owns the
  numeric trigger.
- **`task-plan-phase-architecture`**: When deviation handling reveals an
  architectural blocker, consult @architect before proceeding — or load this skill
  if the question is substantial.
- **`task-plan-phase-testing`**: If post-implementation work is primarily tests
  (coverage gaps, failing tests discovered), load the testing skill next.
- **`task-plan`**: Use to update `plan.md` at each step boundary.

**Does NOT cover:** investigation, architecture review, testing phase,
retrospective, completion docs.
