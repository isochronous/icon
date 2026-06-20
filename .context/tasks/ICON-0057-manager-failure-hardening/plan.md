## Task: ICON-0057
## Branch: feature/ICON-0057-manager-failure-hardening
## Objective: A 906-minute consumer session (WSD-26817, captured in session.md) using ICON went badly — 5 user-driven rework rounds, a role violation, a recurring test-glob mistake, and two mandatory close-gates (lint + code-review) never run. Distill the failure into a small set of high-leverage, low-token-cost improvements to the ICON plugin's agent definitions/skills, let the user choose which to adopt, and implement them without bloating the definitions ("earn your place").

## Folder: .context/tasks/ICON-0057-manager-failure-hardening/

## Decisions
- Source of truth for the failure analysis: forensic timeline of session.md (7 user pushbacks at lines 1206/1245/1678/2004/2906/2971/4452; 5 rework rounds; 0 lint runs; 0 code-review passes). Captured in findings.md (this folder).
- Scope = ICON **plugin** changes only (agents/, skills/). The session happened in a consumer repo (datascan-ui/ngWi); consumer-side .context fixes (e.g. the project's lint/test-glob guidance) are the consumer's responsibility and out of scope here.
- Key framing: most failures were the model **ignoring existing ICON rules** (reviewer-for-all-changes, evidence-before-claiming), not ICON content gaps. So the cheapest high-leverage fix is converting soft guidance into a **hard, itemized, non-skippable close-gate** — not adding more prose. More prose has diminishing returns and violates "earn your place".
- Design pass delegated to @architect (agent-evaluation + icon-audit skills) rather than decided by the manager — this is an agent-system design question, the architect's domain.
- User chooses which recommendations to implement before any edits — original ask was "ideas without a ton of extra token usage", and agent-definition edits carry a no-bloat constraint, so selection is a user decision.
- User selection (2026-06-10): implement **R1 (Closure Gate), R2 (Intent extraction), R3 (No re-dumping), R4 (count-delta guard)**. **Skip R5 entirely** (consumer-repo concern; no context-maintenance edit). R6/R7 rejected per @architect (role-discipline already exhaustively covered; new diagnosis skill = over-engineering).
- R3 home (user, 2026-06-10): the "don't re-dump unchanged context" discipline applies to **all** agents, not just the manager — so it lives in the shared source `shared/common-constraints.md` (inlined into all 9 agents via BEGIN/END markers, propagated byte-equal by the `.githooks/pre-commit` hook — see domains/skill-system.md), NOT in the manager's Delegation section. R1/R2 stay manager-specific.
- R1 expansion (user, 2026-06-10): the close-gate has **four** itemized requirements, not three — add **test coverage for the code changes** (anchored to the existing `testing-discipline` skill, single-source) alongside @reviewer, lint-with-output, and verification-checklist. The gate checks the *changes* are actually covered/asserted, not merely that the suite is green.
- Full proposed wording + exact locations are in `recommendations.md` (R1–R4) — that is the implementation spec.

## Key Files
- session.md (repo root, untracked): the raw session log being analyzed. Do not commit as task work.
- .context/tasks/ICON-0057-manager-failure-hardening/findings.md: forensic timeline + root-cause patterns (to be written).
- agents/manager.agent.md: likely primary edit target (Task Completion close-gates, verification-theater anti-rationalization).
- skills/verification-checklist/, skills/code-quality-rules/, skills/testing-discipline/, skills/task-retrospective/, skills/context-maintenance/: candidate edit targets depending on which recommendations are chosen.

## Progress
- [x] Closed out ICON-0056 (commit, push, MR !39) so its uncommitted manager.agent.md edits don't tangle with this task
- [x] Branched feature/ICON-0057-manager-failure-hardening from updated main
- [x] Forensic analysis of session.md complete (general-purpose agent) — timeline, 7 root-cause patterns, token-waste hot spots
- [x] Wrote findings.md; dispatched @architect → recommendations.md (R1–R7, prioritized)
- [x] Surfaced recommendations to user → selected R1+R2+R3+R4, skip R5, reject R6/R7
- [x] @coder: R1 (close-gate, 4 items incl. testing-discipline) + R2 (intent extraction) in manager.agent.md; R4 row in verification-checklist SKILL.md
- [x] @coder: R3 relocated to shared/common-constraints.md (Context Economy), propagated byte-equal to all 9 agents via pre-commit hook
- [x] Minor fix: close-gate converted to numbered step 6, list integrity restored (@coder)
- [x] Close-gate item 1 (@reviewer): Approved — 0 Critical/Moderate; 1 Minor (list numbering) fixed
- [x] Close-gate items 2/3 (lint/test coverage): N/A — ICON is pure-content (ADR-005), no lint/test toolchain
- [x] Close-gate item 4 (verification-checklist): passed — all 4 gates with grep/md5 evidence (byte-equality 1 unique md5 across 9 agents)
- [x] changelog-entry: 3 bullets added to [Unreleased] ### Changed (R1+R4 merged same-fix-class, R2, R3)
- [x] Retrospective inserted (@context-specialist; lesson promoted to domains/skill-system.md; cap pruned ICON-0041/0042)
- [x] Committed (25f7adb, 17 files), pushed, MR !40 opened → main. TASK COMPLETE.

## Outcome
- `agents/manager.agent.md`: R1 close-gate (4-item, non-skippable, step 6) + Hardcoded-tier bullet + Default-tier @reviewer line demoted to pointer (single-source); R2 intent-extraction gate in Session Start step 7.
- `shared/common-constraints.md`: R3 Context Economy item; propagated byte-equal to all 9 `agents/*.agent.md` via `.githooks/pre-commit`.
- `skills/verification-checklist/SKILL.md`: R4 rationalization row (green count can hide unrun files / account for test-count delta).
- `CHANGELOG.md`: 3 `[Unreleased] ### Changed` bullets (ICON-0057).
- Net ~27 insertions / 1 deletion across 11 files; reviewer-approved. R5 skipped (consumer-repo concern), R6/R7 rejected (already-covered / over-engineering).

## Open Questions / Blockers
- Which subset of recommendations to implement — pending @architect output + user selection.
- Whether any fix belongs in the consumer repo instead of ICON (e.g. the --include/lint guidance) — flag to user if so.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005. Verification is by reading rendered definitions.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003. (Not releasing in this task unless asked.)
- Agent definitions follow "earn your place" — every line must prevent a concrete mistake. No bloat; prefer tightening/relocating existing rules over adding new prose.
- User's overriding constraint: improvements must not add "a ton of extra token usage" — prefer fixes that are cheap to carry and ideally reduce per-task token cost.
- Keep portable across Copilot CLI and Claude Code — no tool-specific constructs.
