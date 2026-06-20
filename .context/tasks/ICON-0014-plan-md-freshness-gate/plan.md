## Task: ICON-0014
## Branch: feature/ICON-0014-plan-md-freshness-gate
## Objective: Make `plan.md` reconciliation a **gated** step in task-completion — before any MR/PR is opened and before the retrospective is run. Replaces the current author-discipline-only enforcement (manager's "Update plan.md *before* starting each step" rule). Closes GitLab work item #10.
## Folder: .context/tasks/ICON-0014-plan-md-freshness-gate/

## Decisions
- Reconciliation lands as a discrete step at the **top** of `.context/workflows/task-plan/phase-completion.md`, ahead of review / context-maintenance / retro / commit steps. Single source of truth for what reconciliation entails (re-read plan.md, check each Progress item against actual outcomes, fill in late Decisions, update Key Files to match the actual diff, close out Open Questions, update Constraints if any discovered ones aren't yet captured).
- In `agents/manager.agent.md` "Task Completion and Retrospective" section, the reconciliation appears as **step 0** before the existing review step. Hardcoded tier reflects the new step (it's non-negotiable, not encouraged).
- `skills/mr-discipline/SKILL.md` gets a pre-flight check: if a `plan.md` exists for this branch's task, the MR opener confirms it has been reconciled against the final state. Surface as a self-review question on the MR opening checklist.
- `skills/task-retrospective/SKILL.md` notes the freshness presumption — retros presume a reconciled `plan.md` as input. If detectably stale (unchecked Progress steps whose outcomes are clearly in the diff; missing Key Files visible in the diff), the retro flags it and routes back to step 0 of completion rather than proceeding.
- Single canonical wording for "reconcile plan.md" — define once in `phase-completion.md`, refer to it from the other three surfaces by name rather than re-describing. This is the lesson from ICON-0007 (avoid distributed copies of a routing rule).
- The issue's acceptance bullet says "A retrospective entry captures this as a new operational standard." This task's own retro will be that entry — written in the standard format at task close, not as a separate deliverable.
- **Late decision (fix iteration):** Mirror the SSOT to two upstream distribution surfaces in addition to the local file — `context_template/context/workflows/task-plan/phase-completion.md` (verbatim) and `skills/task-plan-phase-completion/SKILL.md` (fallback SSOT). Surfaced by @reviewer; the original four-file scope was incomplete because greenfield installs read from `context_template/` and downstream repos without local overrides read from the SKILL. Template-version bumped 1.1 → 1.3 on the mirror (skipping 1.2 to stay in sync with the local file going forward).

## Key Files
- `.context/workflows/task-plan/phase-completion.md` — local SSOT: added the `## Reconcile plan.md` section as the first content section; template-version bumped to 1.3.
- `context_template/context/workflows/task-plan/phase-completion.md` — distribution mirror: same `## Reconcile plan.md` section byte-equal to local; template-version 1.1 → 1.3.
- `agents/manager.agent.md` — "Task Completion and Retrospective" section: new step 0; Hardcoded tier entry; Anti-Rationalization row.
- `skills/mr-discipline/SKILL.md` — Opening-an-MR pre-flight bullet; matching Red Flag entry.
- `skills/task-retrospective/SKILL.md` — When-to-Run precondition note: retro presumes a reconciled plan.md.
- `skills/task-plan-phase-completion/SKILL.md` — fallback SSOT for downstream repos without a local phase-completion.md override: new top-most section `## task-plan: Completion: Reconcile plan.md` covering the five sub-checks.
- `.context/retrospectives.md` — entry for this task captures the upstream-sweep lesson (added at task close).

## Progress
- [x] Branch + task folder + plan.md created
- [x] @coder: implement the four-surface edits per Decisions; ensure consistent canonical wording referenced from phase-completion.md — SSOT lands in phase-completion.md `## Reconcile plan.md`; manager.agent.md step 0 + Hardcoded tier + Anti-Rationalization row reference it; mr-discipline pre-flight bullet + Red Flag reference it; task-retrospective precondition note references it. Inserted step is "0" (existing steps 1–5 keep their numbers); the existing "step 4 of task completion" backref in manager.agent.md still resolves correctly.
- [x] @coder (fix-iteration): close upstream-sweep gaps flagged by @reviewer — mirror the `## Reconcile plan.md` section verbatim into `context_template/context/workflows/task-plan/phase-completion.md` (template-version bumped 1.1 → 1.3) and add an equivalent `## task-plan: Completion: Reconcile plan.md` section to `skills/task-plan-phase-completion/SKILL.md` as the fallback SSOT for downstream repos without a local override.
- [x] @reviewer (first pass): found 1 Critical (missing `context_template/` mirror update) + 1 Moderate (missing `skills/task-plan-phase-completion/SKILL.md` update) + 1 Minor deferred (`.context/META.md:54` mildly stale prose). APPROVE-WITH-FIXES on the in-scope four-file diff.
- [x] @reviewer (second pass, fix iteration): both Critical and Moderate CLOSED. One cosmetic Minor noted (single vs double blockquote paragraph in the SKILL fallback intro) — no action required. APPROVED.
- [x] Manager: dogfooded the new gate by reconciling this plan.md against final state (the very step this task ships) — added late Decision for the upstream-sweep surfaces, added the two new Key Files (`context_template/.../phase-completion.md`, `skills/task-plan-phase-completion/SKILL.md`), closed both Open Questions as resolved.
- [ ] Manager: run retrospective, commit artifacts, push branch, open MR closing #10 ← IN PROGRESS

## Open Questions / Blockers
- Both prior open questions resolved during execution:
  - Testability: structural greps + prose review across two @reviewer passes confirmed cross-file consistency; the gate is "as testable as docs-based process gates can be in a pure-content repo."
  - Lightweight enough: each sub-check is one paragraph in the SSOT — a reviewer can verify reconciliation in under two minutes by scanning Progress checkmarks vs the diff. Confirmed during the dogfood reconciliation pass.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005. Verification is structural (greps + prose check).
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003. This task does NOT bump the version on its own (release bundles changes).
- Follow ICON-0007 lesson: when adding a process rule, grep every place the affected workflow already lives. The four files above are the known surfaces; @reviewer's Pass 2 must confirm no fifth surface was missed (`grep -rn "task completion\|completion.*step\|plan.md" agents/ skills/ .context/workflows/`).
- Follow ICON-0008 lesson: if inserting a numbered step into manager.agent.md, audit every inline backref to step numbers in the same file and Common Mistakes table.
- The reconcile step is a new HARDCODED behavior (non-negotiable). The issue framing is explicit on this.
- **Upstream-sweep surfaces include `context_template/` AND `skills/<phase>/SKILL.md`.** When editing process docs under `.context/workflows/`, the change is incomplete until the template mirror at `context_template/context/workflows/<same path>` AND the fallback-SSOT skill at `skills/<phase>/SKILL.md` are both updated. `context_template/` is the distribution surface for `/icon-init` greenfield installs; the SKILL is the fallback SSOT for downstream repos that do not yet have a local override. Missing either surface means the change does not propagate to all consumers. (Discovered during ICON-0014 first @coder pass — reviewer caught both gaps after only the local file and three other surfaces were edited.)
