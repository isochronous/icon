# In-Task Maintenance

Mechanical, rule-driven maintenance obligations get done **in-task**, not demoted to a "candidate follow-up." Deferring them is how a repo accumulates the exact debt the rules exist to prevent — an oversized doc that never gets split, a skill that ships unregistered, a cap literal that drifts from canon.

## The Rule

When a mechanical maintenance obligation surfaces during a task, do it now. This applies with particular force when **the current task's own edit caused or worsened the violation**, or when **a sub-agent (reviewer, explorer, context-specialist) flagged it**. In both cases the obligation is already in scope — the edit that created it, or the pass that found it, is part of this task.

Representative obligations (non-exhaustive):

- A `.context/` doc pushed **over the 16KB split threshold** by this task's edit → split it now per `context-document-guidelines § Folder Split Rule` (some files are exempt; see that rule's Split Exemptions for the full test).
- A **new skill missing its `using-skills` README registration** → register it now (see `skill-decomposition/skill-mechanics.md § using-skills Registration`).
- A **stale cap or version literal** (e.g. an entry-cap `N` that drifted from the canonical `ENTRY_CAP`, a template version that no longer matches) → correct it now.
- A **new or removed rule file** under `standards/`, `workflows/`, or `decisions/` → add or remove its row in `rules-index.md` in the same task (parent-row granularity: files inside an indexed sub-directory are already covered).

## Urgency Above In-Task

"Before this task closes" is the floor, not the ceiling. Two obligations are stricter:

- **Inaccurate content is fixed at the moment of identification.** A `.context/` doc that asserts something false today — a renamed API described as current, a convention the codebase no longer follows, a fixed bug documented as live — is poison: every agent that loads it acts on the falsehood, including agents working this very task. Interrupt the current step, correct or delete the content, then resume. It does not wait for the task-close maintenance pass, and it is not the same "now" as the retrospective's promote-at-close rule.
- **A prior deferral raises urgency; it does not create license.** When an earlier task already deferred the same mechanical obligation — the recurring case is a doc left over the 16,000-byte split threshold — that is not precedent that deferring is acceptable. It means the debt survived a full cycle unaddressed. Treat the repeat as escalation and clear it in this task.

A defect surfaced with **no active task** is the one sanctioned deferral, and it becomes its own task — not a backlog note, not a "candidate follow-up."

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
| "The stale doc can wait for the task-close maintenance pass" | Task-close is too late for an inaccuracy — every load between now and then acts on false content, including this task's own sub-agents. | Correct or delete it the moment it is identified. |
| "A previous task deferred this same split, so deferring is normal" | A deferral that survived a cycle is compounding debt, not precedent. | Treat the repeat as escalation; clear it in this task. |
| "Doing it now expands the task" | Mechanical rule-following is not scope expansion; it is completing the task to standard. Genuine scope questions still go to the user. | Apply the test: mechanical → do it; design decision → surface it. |

## Related

- See also: [skill mechanics](skill-decomposition/skill-mechanics.md) § using-skills Registration — a representative mechanical obligation this standard names
- See also: [rules-index.md](../rules-index.md) — the index this standard's rule-file obligation keeps current
