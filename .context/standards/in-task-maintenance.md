# In-Task Maintenance

Mechanical, rule-driven maintenance obligations get done **in-task**, not demoted to a "candidate follow-up." Deferring them is how a repo accumulates the exact debt the rules exist to prevent — an oversized doc that never gets split, a skill that ships unregistered, a cap literal that drifts from canon.

## The Rule

When a mechanical maintenance obligation surfaces during a task, do it now. This applies with particular force when **the current task's own edit caused or worsened the violation**, or when **a sub-agent (reviewer, explorer, context-specialist) flagged it**. In both cases the obligation is already in scope — the edit that created it, or the pass that found it, is part of this task.

Representative obligations (non-exhaustive):

- A `.context/` doc pushed **over the 16KB split threshold** by this task's edit → split it now per `context-document-guidelines § Folder Split Rule`.
- A **new skill missing its `using-skills` README registration** → register it now (see `skill-decomposition/skill-mechanics.md § using-skills Registration`).
- A **stale cap or version literal** (e.g. an entry-cap `N` that drifted from the canonical `ENTRY_CAP`, a template version that no longer matches) → correct it now.
- A **new or removed rule file** under `standards/`, `workflows/`, or `decisions/` → add or remove its row in `rules-index.md` in the same task (parent-row granularity: files inside an indexed sub-directory are already covered).

## The Distinguishing Test

The line between "just do it" and "surface to the user" is **mechanical/rule-driven vs genuine product/design decision**:

| Mechanical / rule-driven → do it in-task | Product / design decision → surface to the user |
|---|---|
| Split a doc that crossed the bytesize threshold | Define new gate semantics for a pre-commit check |
| Register a new skill in the README index | Change a behavioral contract (what an agent does) |
| Reconcile a cap/version literal to the canonical value | Narrow the scope of an already-filed issue |
| Repair a cross-reference broken by a rename | Decide whether a new convention should ship to consumers |

If applying the rule requires no judgement beyond following the rule, it is in-task work. If it requires a decision about *what the rule should be* or *what the product should do*, it is the user's call — surface it rather than deciding unilaterally (see the Scope Discipline constraint in the agent definitions).

## Anti-Rationalization

| Excuse | Reality | Correct Action |
|---|---|---|
| "This split is a clean follow-up ticket" | The edit that crossed the threshold is part of *this* task; deferring ships a known-oversized doc. | Split it in the same task that enlarged it. |
| "The reviewer flagged it, but it's out of scope" | A sub-agent flag on a mechanical obligation IS the in-task signal to fix it, not a reason to file it away. | Fix the flagged mechanical defect before reporting complete. |
| "The cap literal drift is cosmetic" | A drifted literal defeats the guard that scans for it; it is exactly the defect the canon exists to prevent. | Reconcile to the canonical value now. |
| "Doing it now expands the task" | Mechanical rule-following is not scope expansion; it is completing the task to standard. Genuine scope questions still go to the user. | Apply the test: mechanical → do it; design decision → surface it. |
