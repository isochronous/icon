## Task: ICON-0065
## Branch: feature/ICON-0065-review-before-completion
## Objective: Reframe ICON's @reviewer invocation from a single end-of-task close-gate (added in ICON-0057) into a review-BEFORE-success discipline woven into the implementation flow, and reduce the completion gate to a conditional catch-all: "run @reviewer only if there are code changes since the last review." Reviews should happen as part of doing the work, not as a final ceremony after the agent has effectively declared success.
## Folder: .context/tasks/ICON-0065-review-before-completion/

## Decisions
- Branch off main (clean; v1.20.0 released). Behavior change to consumer-shipped `agents/manager.agent.md` → consumer-facing → CHANGELOG entry + the change ships in a future release (do NOT release this task).
- Design-first via @architect + `agent-evaluation` (mirrors how ICON-0057 designed the close-gate). The key work is the design, not the typing — get the review-placement + the "since last review" mechanism right before editing.
- Keep a completion gate, but make it CONDITIONAL ("@reviewer if code changed since last review") rather than the current unconditional "always invoke @reviewer at close." This avoids a redundant second review when implementation already reviewed, while still catching unreviewed code.

## Key Files (candidates — @architect to confirm the full surface set; watch sweep-incompleteness)
- `agents/manager.agent.md` — the ICON-0057 close-gate (Task Completion step 1 "Review code changes"; the Hardcoded-tier close-gate bullet; the Anti-Rationalization rows; Workflow Orchestration). The reviewer item shifts from unconditional-at-close to woven-in-implementation + conditional-at-close.
- `skills/task-plan-phase-implementation/SKILL.md` — add the review-before-reporting-success step.
- `skills/task-plan-phase-completion/SKILL.md` — change the reviewer step to the conditional gate.
- `.context/workflows/task-plan/phase-implementation.md` + `phase-completion.md` — repo-local templates that OVERRIDE the phase skills (task-plan template-override rule); must stay consistent with the skills.
- `context_template/context/workflows/task-plan/phase-implementation.md` + `phase-completion.md` — shipped consumer templates; mirror (triggers the iconrc version-bump gate if touched).
- `skills/verification-checklist/SKILL.md` — ICON-0057 added a row referencing the close-gate; align if needed.
- `CHANGELOG.md` `[Unreleased]` — behavior change entry.

## Progress
- [x] Establish task: branch off main + folder + plan.md
- [x] @architect (agent-evaluation): full surface map + design delivered (see Design below)
- [x] Manager finalized design + corrected one architect error (iconrc version bump IS required — see Constraints)

## Design (architect, approved with manager correction)
- **A — review before success:** ONCE at the implementation→completion boundary (not per-increment) — when impl/testing steps are done, dispatch @reviewer over the full changed-file set, resolve critical/moderate (route fixes to @coder), then record a `## Review Checkpoint` line in plan.md (reviewed step + findings status). This is the primary review; it precedes "done".
- **B — conditional completion gate:** the close-gate reviewer item becomes "@reviewer has covered every code change up to the current changed-file set — satisfied by the plan.md Review Checkpoint if no @coder/@tester step ran after it; if code changed after the checkpoint OR no checkpoint exists, re-run @reviewer over that diff first." **FAIL-CLOSED**: missing/uncovered checkpoint ⇒ gate fires (never an escape hatch).
- **Mechanism = plan.md `## Review Checkpoint`** (tool-agnostic; rejected git-ref/diff approaches as ADR-004-fragile and commit-cadence-coupled). The checkpoint does double duty (A evidence + B's "last review point").
- **Surfaces to EDIT:** manager.agent.md S1(step1)/S2(close-gate item)/S3(Hardcoded mirror)/S4(Default pointer)/S5(AR row update + 1 new AR row); phase-implementation ADD ~6-line "Pre-Completion Review" section in all THREE copies (skill + .context + context_template); phase-completion conditional-wrap the @reviewer template in all THREE copies; bump per-file template-version headers on the 2 context_template files.
- **Do NOT touch:** verification-checklist (its ICON-0057 row is test-count, orthogonal), manager-routing-guide (pipeline already ends in @reviewer), shared/common-constraints.md (no review rule there).

## Progress (cont.)
- [x] @coder A: manager.agent.md S1–S5 — conditional + fail-closed wording across all 5 sites
- [x] @coder B: Pre-Completion Review added to 3 impl copies; conditional preamble in 3 completion copies; 4 template-version headers bumped; iconrc 1.4→1.5; gate exit 0
- [x] CHANGELOG [Unreleased] ### Changed entry (ICON-0065)
- [x] @reviewer (dogfooded — primary review ran during implementation, before completion): APPROVED — 0 Critical, 1 Moderate (CHANGELOG — now added), 2 Minor (pre-existing template-version tree skew; cosmetic step-1/gate wording — both non-blocking, not addressed). Confirmed fail-closed, no protection gap, no double-review, cross-copy consistent.
- [ ] Reconcile plan; retrospective (manager draft → @context-specialist insert) ← IN PROGRESS
- [x] Committed (9dee6a2, f0cbe07), pushed; MR !49 → https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/merge_requests/49 (targets main)

## Review Checkpoint
- Last @reviewer pass: full ICON-0065 changed-file set (manager.agent.md + 6 phase copies + iconrc + CHANGELOG), reviewed before completion. 0 Critical, 1 Moderate (CHANGELOG, resolved), 2 non-blocking Minor. No @coder/@tester step has run since.

## Outcome
- Primary @reviewer pass relocated into the implementation flow (phase-implementation § Pre-Completion Review, all 3 copies), recorded as a plan.md `## Review Checkpoint`.
- Completion close-gate review item is now conditional + FAIL-CLOSED (fires when code changed since the checkpoint or no checkpoint exists); no redundant second review when nothing changed.
- manager.agent.md (5 sites) + 6 phase-doc copies kept consistent; verification-checklist / manager-routing-guide / common-constraints untouched (out of scope).
- Consumer-affecting (upgrade-repo pulls new phase content + manager behavior) → CHANGELOG entry; iconrc 1.4→1.5; NOT released this task.

## Open Questions / Blockers
- Mechanism for "code changes since the last review": how does the manager know? Candidate signals — @coder/@tester ran after the last @reviewer; a recorded last-reviewed git ref; or "diff since last review is non-empty." @architect to choose the simplest reliable signal that works for both Claude Code and Copilot (tool-agnostic, ADR-004).
- Does "review before success" mean per-implementation-step, or once before declaring implementation done? Lean: review when an implementation increment is complete / before handing to completion — architect to define precisely without over-prescribing.
- Preserve the ICON-0057 intent (review is non-skippable when there IS unreviewed code) while removing the redundancy (no second review when nothing changed since the last one).

## Constraints
- ICON pure-content (ADR-005); verify by reading rendered definitions, not execution.
- ADR-004 tool-agnostic: the "since last review" mechanism must not depend on a Claude-Code-only capability.
- Three-layer/sweep consistency: any rule encoded in a phase skill likely also lives in `.context/workflows/...` and `context_template/...` — change all copies or none (the O-M1-class sweep-incompleteness failure).
- Do NOT release. `.claude-plugin/plugin.json` version SSOT untouched (ADR-003).
