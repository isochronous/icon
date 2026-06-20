## Task: ICON-0027
## Branch: feature/ICON-0027-retro-write-path-split
## Objective: Resolve the M-CC-NET2 three-surface contradiction on retrospective entry authorship. Split the work cleanly: manager drafts Q1 (Avoid) and Q2 (Repeat); @context-specialist evaluates `.context/` impact (Q3 Updated), runs the `append-retrospective-entry` script, and reports back. This collapses two execution paths into one, closes the documented-but-unresolved gap from ICON-0006, and as collateral closes m-P-4 (the line 92 vs 113 two-path ambiguity inside `task-retrospective/SKILL.md`).
## Folder: .context/tasks/ICON-0027-retro-write-path-split/

## Decisions
- **Adopt the user-directed split (issue #12 Fix Direction), not the manager-owns-everything path from `manager.agent.md:204`.** Rationale: aligns each role with its natural source of authority — manager owns the orchestration narrative (Q1+Q2 are reflections on orchestration choices), @context-specialist owns `.context/` (which files get touched IS the answer to Q3, and the specialist already owns the `append-retrospective-entry` script via the `context-maintenance` skill).
- **Single execution path in `task-retrospective/SKILL.md`.** Rationale: the existing two-path shape (script invocation at line 92 vs delegate-to-specialist at line 113) is the on-the-ground manifestation of the same ambiguity; collapsing to one path closes m-P-4 as a collateral effect.
- **No `--no-verify` and no plugin-shipped behavior changes beyond the three named files** unless the three-surface sweep checklist surfaces a fourth surface that needs adjustment. Scope discipline per the ICON-0015 sweep-completeness lesson (M-CC1 pattern).

## Key Files
- `agents/manager.agent.md` — Step 3 of Task Completion (`:200-204` area). Rewrite to describe the two-stage flow: manager drafts Q1+Q2, dispatches @context-specialist with the draft + task context, specialist owns Q3 + script invocation. Update the matching Anti-Rationalization row if it references manager-direct authorship.
- `skills/task-retrospective/SKILL.md` — rewrite Steps to a two-stage flow. Remove the line ~92 "use the script directly" path. Stage 1 (manager): answer Q1 and Q2 by reflecting on the task. Stage 2 (handoff to @context-specialist): provide drafted Q1+Q2 + task context; the specialist evaluates `.context/` impact (answering Q3), runs the script, and reports back which files were touched and which retro entries (if any) were pruned per the 15-entry rolling cap.
- `skills/task-plan-phase-completion/agent-vs-skill-invocation.md` — replace the "Known unresolved" block (around `:63`) with the resolution text + cross-reference to this MR.
- `.context/workflows/task-retrospective.md` — confirm whether a local override exists in this repo; if so, sweep it to match the new flow.
- `context_template/context/workflows/task-retrospective.md` (or `task-plan/phase-completion.md` if the template ships phase files) — confirm whether the template ships a workflow doc that names the retrospective flow; if so, sweep it to match.
- `CHANGELOG.md` — single `[Unreleased]` line at task close per `changelog-entry` skill.

## Progress
- [x] Branch + task folder created, plan.md drafted
- [x] Three-surface sweep — `.context/workflows/task-retrospective.md` and `context_template/context/workflows/task-retrospective.md` not present in repo (no parallel surface to sweep)
- [x] @coder dispatched and edits applied (3 in-scope surfaces)
- [x] @reviewer Pass 1 — flagged Critical: new "specialist stages, manager commits" rule contradicts `context-specialist.agent.md:92` Hardcoded tier + `context-maintenance/SKILL.md` Phase 3 Commit. Sweep was incomplete.
- [x] Critical fixes applied: `context-specialist.agent.md:92` Hardcoded exception added, `context-maintenance/SKILL.md` Phase 3 rewritten as Stage, output report updated, `manager-routing-guide/SKILL.md:79` capability cell updated. Moderate residue (Rolling Log Entry/Maintenance prose) rewritten to voice-neutral form. Minor "Updated placeholder" instruction added to manager Step 3b.
- [x] @reviewer Pass 2 — flagged ONE Critical at `agent-vs-skill-invocation.md:21` (blanket commit-ownership rule re-introduced the contradiction by omitting the `mode: maintenance` qualifier) + 2 Minors
- [x] Pass 2 Critical fix: split idempotency bullet into separate `Commit ownership (mode-dependent)` bullet with explicit qualifier; both Minors picked up (`plugin-audit/SKILL.md:144` rewords to @context-specialist path; `task-plan-phase-completion/SKILL.md:82` adds via-task-retrospective clarification)
- [x] verification-checklist — 7 acceptance gates all pass (no `Known unresolved`, no script-direct path, two-stage flow in all three primary surfaces, mode-qualified commit-ownership in all four reconciled surfaces, common-constraints byte-identical in both edited agents, plugin.json parses)
- [x] CHANGELOG.md `[Unreleased]` entry added under `### Changed` per `changelog-entry` skill — no subject overlap with existing entries
- [x] task-retrospective skill — manager drafted Q1 (Avoid: inverse-phrasing sweep), Q2 (Repeat: two reviewer passes), entry text with placeholder; dispatched @context-specialist `mode: maintenance` which ran the `append-retrospective-entry` script, filled the placeholder with "Nothing to promote" rationale, and staged with `git add` only (no commit). **First end-to-end dogfood of the new ICON-0027 flow — succeeded on first attempt; the new flow is mechanically deliverable.**
- [ ] Commit all artifacts (source changes + updated context + completed plan.md) and open MR ← IN PROGRESS

## Open Questions / Blockers
- The issue notes "One dogfood retrospective (next task close after the MR lands) demonstrates the flow end-to-end" as an acceptance criterion. Is the dogfood expected at THIS task's close (ICON-0027 itself), or at the next task that runs the new flow AFTER the MR is merged? Reading: at THIS close — the new manager.agent.md + SKILL.md are in effect on the branch, so this task is the first opportunity to exercise the new flow. Proceed with that assumption; flag in the MR description for confirmation.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005. Verification is grep-based against the acceptance criteria, plus reading the rewritten skill end-to-end for coherence.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003. No version bump in this task; the release is a separate `/release-plugin` invocation.
- Three-layer enforcement applies to this change: the retrospective flow is named in (a) `manager.agent.md` (Hardcoded tier — currently says "manager directly"), (b) `skills/task-retrospective/SKILL.md` (Default tier — currently delegates to specialist), (c) `skills/task-plan-phase-completion/agent-vs-skill-invocation.md` (SSOT — currently "Known unresolved"). All three must agree on the new split after this MR.
- Sweep-completeness (ICON-0015 M-CC1 lesson): the rewrite must touch every shipped surface that names the retrospective flow, not just the three the issue body enumerates. Grep before declaring done.
