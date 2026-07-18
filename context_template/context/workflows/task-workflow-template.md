> **[DEPRECATED — use `task-plan/base.md` + phase files]** — This monolithic template is the legacy fallback. Run `/upgrade-repo` to migrate to the phase-based model (`base.md` + per-phase files under `task-plan/`).

<!-- orphan-ok rationale: deprecated legacy scaffold retained only as an upgrade fallback; intentionally not linked from any live doc. -->
<!-- context-graph:orphan-ok -->

# Task Workflow Template

## Overview

This workflow defines how agents collaborate on tasks using the manager-of-engineers delegation model. The manager orchestrates work by delegating to specialist agents, tracking progress, and ensuring quality.

## Concern-Based Skill Loading

At task start, identify the **primary concern** and load the matching skill.
Load ONE concern skill per task. Then load `task-plan-phase-completion` to
close out.

| Primary concern | Skill | Trigger |
|-----------------|-------|---------|
| Scope or approach unclear | `task-plan-phase-investigation` | Scope undefined; research needed; root cause unknown |
| Primary work is structural decisions | `task-plan-phase-architecture` | New module, shared library change, schema change, auth change |
| Primary work is writing code | `task-plan-phase-implementation` | Path is clear; ready to dispatch @coder |
| Primary work is tests | `task-plan-phase-testing` | Fixing failing tests, adding coverage, TDD |
| Closing any task | `task-plan-phase-completion` | After primary work is done — always |

### Concern identification

- "I know what to build and how" → `task-plan-phase-implementation`
- "I need to understand the problem or research first" → `task-plan-phase-investigation`
- "The key question is how to structure this" → `task-plan-phase-architecture`
- "This task is primarily about test quality" → `task-plan-phase-testing`

### Multi-concern tasks

Tasks that shift concerns (e.g., investigation reveals architecture work,
which reveals implementation) load skills sequentially as concerns shift. Do
not preload all skills at task start. Load each concern skill when entering
that concern.

---

## Task Document Template

<!-- template-version: 1.2 -->

Create `plan.md` in `.context/tasks/[TASK-ID-short-description]/` for medium and complex tasks. When the `task-plan` skill is invoked, it instructs the agent to read this section to determine the required format — customize this template to match your team's workflow.

For simple tasks, track inline in the session rather than creating a task folder.

```markdown
## Task: [TASK-ID]
## Branch: [BRANCH-NAME]
## Objective: [What we're accomplishing and why]
## Folder: .context/tasks/[TASK-ID-short-description]/

## Decisions
- [Decision made]: [Rationale — why this approach over alternatives]

## Key Files
- [path/to/file]: [What it does or how it was changed]

## Progress
- [x] Completed step — [brief outcome or note]
- [ ] Current step ← IN PROGRESS
- [ ] Upcoming step

## Open Questions / Blockers
- [Anything the next agent or developer needs to resolve or be aware of]

## Constraints
[Key constraints from user, context, or discovered during work]
```

**Section guidance:**
- **Decisions** — Record every non-obvious choice and the reason for it. Future agents should not re-litigate decided questions.
- **Key Files** — List every file touched or about to be touched. A resuming agent should orient from this list alone.
- **Progress** — Check off steps as they complete. Add a brief outcome note — not just ✓ but what the result was.
- **Open Questions / Blockers** — Ambiguities, risks, or things the next agent needs to decide. Do not carry these only in memory.
- **Constraints** — API limitations, backwards-compatibility requirements, user constraints discovered mid-task.

---

## When to Create Task Folders

Create `.context/tasks/[ISSUE-ID-kebab-description]/` when:
- Task is complex (multiple modules or phases)
- Involves architectural changes
- Has many decision points
- Will serve as reference for similar future work

Skip task folders for: simple fixes, trivial changes, routine maintenance.

---

## Context Recovery After Compaction

When context is compacted mid-task:
1. Re-read `.claude/claude.md` (or `.github/copilot-instructions.md` as legacy fallback)
2. Re-read relevant `.context/` files for the current task
3. Review the task document for current status, decisions, and next steps
4. Resume from the documented progress point
