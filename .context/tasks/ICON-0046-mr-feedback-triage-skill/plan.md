## Task: ICON-0046 / ICON-0050
## Branch: feature/ICON-0046-mr-feedback-triage-skill
## Objective: Add `mr-feedback-triage` skill for triaging open GitLab MR review threads with necessity assessment (Blocking / Recommended / Optional) and prioritized resolution plan. Bundled with ICON-0050 (prohibit auto-resolving threads in both the new skill and in `mr-discipline`), plus a `mr-discipline` update requiring `context-maintenance` invocation before re-requesting review.

## Decisions
- Skill assesses and reports only — never posts replies, never resolves threads. This constraint is core and must appear in the Phase 3 body AND as Common Mistakes entries. First-pass body was unclear about the no-action rule (led to fix commit); blanket tool prohibition was too broad (led to qualify commit). Final form: explicit callout in Phase 3 + two Common Mistakes rows distinguishing report-time vs. post-fix resolution.
- ICON-0046 and ICON-0050 bundled into the same branch because both concern the same author-action boundary — ICON-0046 introduces the non-action constraint in the new skill, ICON-0050 hardens it in `mr-feedback-triage`'s Common Mistakes to cover the "auto-resolve after pushing fixes" loophole.
- `mr-discipline` updated in the same branch (ICON-0046) to require `context-maintenance` before re-requesting review when feedback-driven changes affect `.context/` — keeps the MR lifecycle skill family consistent.
- README.md skills table already carried the `mr-feedback-triage` row before branch creation; no README change needed on this branch.

## Key Files
- `skills/mr-feedback-triage/SKILL.md` — new user-invocable skill (4 phases: Guard+Fetch, Gather Code Context, Assess, Report)
- `skills/mr-discipline/SKILL.md` — added `context-maintenance` requirement to Handling Review Feedback, plus two anti-rationalization rows and a Red Flag entry for context-update deferral
- `CHANGELOG.md` — `[Unreleased]` entries under `### Added` (mr-feedback-triage) and `### Changed` (mr-discipline)

## Progress
- [x] Add `skills/mr-feedback-triage/SKILL.md` — 4-phase skill (fetch, context, assess, report)
- [x] ICON-0050: Prohibit auto-resolving MR threads — Common Mistakes rows in mr-feedback-triage
- [x] `mr-discipline`: Add context-maintenance requirement + anti-rationalization rows and Red Flag for feedback-driven context updates (ICON-0046)
- [x] Fix: clarify skill never posts replies or resolves threads — explicit callout added to Phase 3
- [x] Qualify blanket tool prohibitions — distinguish report-time vs. post-fix resolution in Common Mistakes
- [x] Update CHANGELOG.md — `[Unreleased]` entries citing ICON-0046 and ICON-0050
- [x] Scaffold task folder + plan.md (retroactive — added at task close)
- [x] Retrospective entry appended
- [x] Commit all task artifacts and close

## Open Questions / Blockers
- None.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- Skill body must stay self-contained — no cross-skill resource references (`writing-skills` § "Skills must be self-contained").
- Description field uses folded block scalar (`description: >`) per agent-evaluation frontmatter conventions.

## Retrospective

See `.context/retrospectives.md` entry for ICON-0046/ICON-0050.
