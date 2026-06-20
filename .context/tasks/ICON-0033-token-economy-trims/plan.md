## Task: ICON-0033
## Branch: feature/ICON-0033-token-economy-trims
## Objective: Land the four bundled token-economy items from GitLab issue #18 (O-T1 budget audit + O-T2/O-T3/O-T4 concrete trims) — establish a formal per-session word budget for the always-loaded dispatcher surface, then ship the three named trim candidates with a before/after word-count snapshot in the MR.
## Folder: .context/tasks/ICON-0033-token-economy-trims/

## Decisions
- **Budget doc lives at `.context/decisions/008-always-loaded-token-budget.md`**: per-file ADR convention (008 is next sequential); does not ship to consumer plugins; pure repo-internal governance — matches how every other architectural decision in this repo is captured. Issue body offered `shared/token-budget.md` as the alternative, rejected because the budget is governance for THIS repo's manager/PM agents (consumers can't change those anyway), not a consumer-facing artifact.
- **ADR-008 carries the inventory and re-audit trigger inline**: the issue requires (1) per-session word budget, (2) component inventory, (3) per-component cap, (4) re-audit trigger. All four fit in the ADR's Context + Decision + Consequences sections; no separate spec file needed.
- **C (phase-skill collapse) lifts the canonical paragraph to `skills/task-plan/SKILL.md`**: the dispatcher already owns template-override policy framing; centralizing there matches how every other phase-skill policy is referenced. Each phase skill gets the one-line pointer the issue body specifies verbatim.
- **D (writing-skills extraction) extracts the Skill Creation Checklist to a sibling file**: `skills/writing-skills/skill-creation-checklist.md`, replacing the inline block with a one-line cross-reference. Pattern matches `skills/task-plan-phase-completion/agent-vs-skill-invocation.md` precedent (sibling reference file, not subfolder).
- **Word-count snapshot is its own artifact** at `.context/tasks/ICON-0033-token-economy-trims/word-count-snapshot.md`: captures before/after of the always-loaded surface (manager session + PM session), gets quoted into the MR description and the ADR Consequences section.

## Key Files
- `.context/decisions/008-always-loaded-token-budget.md`: NEW — ADR establishing per-session word budget (8,500 manager / 7,000 PM), 40% per-component cap, MR-scoped re-audit trigger at ≥5% net session growth (sub-task A / O-T1).
- `.context/decisions/README.md`: appended ADR-008 row to Decision Log table.
- `agents/reviewer.agent.md`: replaced 6-category enumeration on `:68` with one-line cross-reference to `code-quality-rules`; SSOT enumeration on `:25` preserved (sub-task B / O-T2 / m-A-NET3 closed).
- `skills/task-plan/SKILL.md`: NEW H2 `## task-plan: Template-Override Rule` inserted between phase-skill table and built-in fallback section; carries the canonical paragraph.
- `skills/task-plan-phase-architecture/SKILL.md`: collapsed 6-line Template-override paragraph → byte-identical 1-line pointer.
- `skills/task-plan-phase-completion/SKILL.md`: collapsed 6-line paragraph → 1-line pointer.
- `skills/task-plan-phase-implementation/SKILL.md`: collapsed 6-line paragraph → 1-line pointer.
- `skills/task-plan-phase-investigation/SKILL.md`: collapsed 6-line paragraph → 1-line pointer.
- `skills/task-plan-phase-testing/SKILL.md`: collapsed 6-line paragraph → 1-line pointer.
- `skills/writing-skills/SKILL.md`: 3 edits — extracted Skill Creation Checklist (lines 493–530), extracted `## Testing All Skill Types` (lines 359–371), trimmed STOP-section redundant closing line. Result: **549 → 499 lines** (under < 500 cap with 1-line margin); m-U-G closed.
- `skills/writing-skills/skill-creation-checklist.md`: NEW — extracted checklist content as sibling file (41 lines / 309 words).
- `skills/writing-skills/testing-skills-with-subagents.md`: appended `## Testing By Skill Type` section receiving the extracted per-type guidance (376 lines / 2,077 words, was 364).
- `.context/tasks/ICON-0033-token-economy-trims/word-count-snapshot.md`: NEW — before/after measurement; baseline for ADR-008 re-audit trigger going forward.
- `.context/tasks/ICON-0033-token-economy-trims/architecture.md`: NEW — @architect's implementation-ready spec; retained as task artifact.
- `CHANGELOG.md`: `[Unreleased]` entry to be added via `changelog-entry` skill (next step).

## Progress
- [x] Create branch + task folder + plan.md — done (manager).
- [x] Word-count baseline measured — manager session 8,062 / PM session 6,564; writing-skills 549 lines / 3,271 words. Captured in `word-count-snapshot.md`.
- [x] Architecture: @architect chose **manager 8,500 / PM 7,000** word caps (descriptive-with-headroom), 40% per-component cap, MR-scoped re-audit trigger at ≥5%. Identified that primary writing-skills extraction alone hits 511 lines; recommended secondary trims (extract Testing All Skill Types + drop 1 redundant STOP line) to land at 499. Spec in `architecture.md`.
- [x] @coder applied A/B/C/D verbatim from the architecture spec. All 5 acceptance gates passed first-pass.
- [x] Word-count snapshot recomputed; always-loaded total unchanged (issue's named trims were on adjacent on-demand surfaces by design); on-demand surface saved 488 words; writing-skills landed at 499 lines.
- [x] @reviewer Pass 1: **GOOD verdict, no Pass 2 needed**. Three sweep checks (ICON-0014 three-surface, ICON-0029 same-file, ICON-0031 cross-reference) all clean. Two Minor observations (optional plugin-audit cross-reference tightening; ADR-008 trigger-text glob clarity) — non-blocking, not addressed.
- [ ] Reconcile plan.md ← IN PROGRESS
- [ ] `changelog-entry` skill: add `[Unreleased]` line(s) for the four sub-tasks
- [ ] Retrospective (Stage 1 manager + Stage 2 @context-specialist mode:maintenance)
- [ ] Commit all artifacts; push branch; open MR with before/after word-count snapshot in description

## Open Questions / Blockers
- None. ADR-008 numbers set by @architect; all acceptance gates met; reviewer approved.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005. Verification = JSON parses + line counts + greps.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003. No version bump on this branch; release is a separate cut.
- **Out of scope (issue body)**: common-constraints inlining (ADR-004 policy-accepted); anti-rationalization tables (load-bearing redundancy per `.context/standards/anti-rationalization-tables.md`). Do not propose removal of either.
- **Three-surface sweep (ICON-0014)**: edits to `skills/task-plan/SKILL.md` are SSOT-only here — there is no corresponding `.context/workflows/task-plan/base.md` rule being changed (we're moving an existing paragraph into the dispatcher, not changing process policy), so the three-surface rule does not apply to sub-task C. Verify by reading `base.md` before @coder dispatch to confirm Template-override policy is not duplicated there.
- **Phase-skill pointer wording** is fixed by the issue body — must be byte-identical across all five files. The issue body specifies: `**Template-override rule**: apply \`.context/workflows/task-plan/phase-<name>.md\` if present — see \`task-plan\` for the full policy.`
- **writing-skills < 500 lines after extraction** is a hard acceptance criterion (m-U-G closure).
- Commit-discipline + mr-discipline skills apply at task close.
