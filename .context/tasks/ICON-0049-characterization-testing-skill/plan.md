## Task: ICON-0049
## Branch: feature/ICON-0049-characterization-testing-skill
## Objective: Legacy code that lacks test coverage is dangerous to touch. This task introduces the `characterization-testing` skill to give agents a structured technique for building a targeted safety net around the specific code being changed, complementing the existing regression suite. Agents are guided to first lock the code's *actual* current behavior as tests, then make the change with confidence that any unintended side-effects will surface immediately. The skill is also wired into `using-skills` so agents are routed to it automatically whenever they encounter legacy code with no coverage — ensuring the discipline is applied consistently, not just when someone remembers to invoke it.
## Folder: .context/tasks/ICON-0049-characterization-testing-skill/

## Decisions
- **New skill introduction**: `characterization-testing` is being added to the ICON plugin for the first time. The technique is established (Michael Feathers, *Working Effectively with Legacy Code*) but has not previously been encoded as an ICON skill.
- **Single atomic commit for skill + routing**: Adding `characterization-testing/SKILL.md` and updating `using-skills/SKILL.md` are one logical unit — a skill that is not reachable via `using-skills` routing is not fully functional. Splitting them would leave a commit where the skill exists but agents cannot be directed to it.
- **No plugin manifest update**: Skills in the ICON plugin are auto-discovered by directory presence; `plugin.json` does not enumerate them. Adding a directory is sufficient.
- **No version bump in this task**: Per project convention, version bumps happen only during a dedicated release task (`/release-plugin`). This commit is feature work only.
- **`marketplace` repo untouched**: The standalone `marketplace` repo is a thin manifest index with no plugin content. It automatically receives the skill when the `icon` repo is tagged and `latest` is moved during the next release.

## Key Files
- `skills/characterization-testing/SKILL.md`: New skill — 5-step process (probe, lock, verify green, change, add forward tests), characterization table, and rationalization prevention guard.
- `skills/using-skills/SKILL.md`: Three targeted diffs — (1) `characterization-testing` added to the process skills list with guidance on when to prefer it over `testing-discipline`; (2) added to the rigid skills list; (3) new routing example for the legacy-code scenario.
- `.context/tasks/ICON-0049-characterization-testing-skill/plan.md`: This file — task record and handoff context.

## Progress
- [x] Create task folder and plan.md
- [x] Add `skills/characterization-testing/SKILL.md`
- [x] Update `skills/using-skills/SKILL.md` (process skills list, rigid list, routing example)
- [x] Atomic commit: `ICON-0049: add characterization-testing skill and wire into using-skills`
- [ ] Push branch and open MR targeting `main` ← IN PROGRESS

## Open Questions / Blockers
- None — all implementation complete. Pending MR review and merge.

## Constraints
- `icon` uses a feature-branch + MR model targeting `main` directly (no persistent `dev` branch)
- Commit format: `ICON-NNNN: <lowercase verb description>` (see `.context/workflows/commit-conventions.md`)
- No version bump — bumps are release-only, driven by `/release-plugin`
- `marketplace` repo requires no changes — it is a thin manifest index; it receives the skill automatically when `icon` is tagged and `latest` is moved during the next release.
