# Task-Start Conventions

How users hand work to the ICON system, and how the manager interprets requests to continue or revisit existing tasks. These are the entry-point conventions that precede branching (`.context/workflows/branching.md`) and commit work (`.context/workflows/commit-conventions.md`).

## The `New task:` convention

`New task:` is the recommended entry point for starting work. The manager reads the rest of the line to decide what to plan from:

| Form | Meaning |
|------|---------|
| `New task: <issue #>` | The manager pulls the GitHub issue (`gh issue view <#>`) and plans from it. |
| `New task: No issue. <description>` | A local task with no GitHub issue; plan from the description. |
| `New task: <issue #>. <extra context>` | The issue plus details not written in it; plan from both. |

## Planning from a ticket: two pre-flight checks

Before planning work from a ticket — especially an audit follow-up — run these two checks against the live repo first.

- **Stale-ticket current-state check.** If the ticket predates recent related commits, do a read-only enumerate-and-classify pass to confirm each finding still applies against the live files before planning. Commits filed since the ticket may have resolved, worsened, or shifted the findings; planning cold risks re-doing fixed work or editing against drifted line numbers.
- **Embedded-ID drift / collision.** A ticket (especially an audit follow-up) may bake in an audit-time task ID that has since drifted from the local `.context/tasks/` sequence. Verify the embedded ID against existing task folders; on collision, use the next free local ID (per the `## Task ID Generation` procedure in `.context/workflows/commit-conventions.md`) and reference the originating work-item number for traceability rather than reusing the colliding ID. This complements that file's rule that PR/issue numbers are not task IDs.
- **Referenced-artifact existence check (ICON-0072).** A ticket may name an artifact as the target of an edit — "add a note to the security doc", "update the X config" — as if that artifact already exists. Verify it actually exists before planning the edit. If it is absent, creating it is in-scope; shape the new file for known sibling or follow-up work (e.g., one `## <Topic>` section per concern so future issues can extend it without restructuring) rather than writing a one-off note.

## Resume vs Reopen

These are different operations and must not be conflated.

- **Resume** continues an *unfinished* task. Just name it — `Resume ICON-NNNN`. The manager restores the task state and picks up at the next incomplete step.
- **Reopen** adds work to a *previously finished* task. You **must state why** in the same prompt — e.g. `Reopen ICON-NNNN — review asked us to handle the null-tenant case`.

**Why the reopen-reason rule matters:** if a completed task is reopened with no stated reason, the manager opens `plan.md`, sees every step already checked off, and runs a retrospective instead of doing the new work. The reason is what tells the manager there is fresh work to plan rather than a finished task to retro.

## Who can be invoked directly

Only `@manager` and `@product-manager` are user-invocable. The other agents are internal specialists the manager delegates to; users steer them indirectly by giving instructions to the manager rather than addressing the specialist agents directly.
