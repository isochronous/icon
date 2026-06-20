## Task: ICON-0056
## Branch: feature/ICON-0056-retrospective-tier-fix
## Objective: Make the task-retrospective unconditionally non-skippable in the manager definition. Currently `agents/manager.agent.md` lists it under the "Default (On Unless Explicitly Disabled)" tier, which by definition permits skipping on user request — contradicting the rule that the retrospective is the single most crucial ICON step and must never be skipped. Resolves GitLab issue #30.
## Folder: .context/tasks/ICON-0056-retrospective-tier-fix/

## Decisions
- Move (not duplicate) the retrospective behavior from the Default tier to the Hardcoded (Non-Negotiable) tier in `agents/manager.agent.md` — a single source of truth per behavior, no contradictory entries.
- Scope is the manager definition plus an audit of directly-related artifacts (`task-retrospective` skill, `task-plan-phase-completion`) for wording that frames the retro as optional/skippable. Edits to those only if they actually contain defeatable wording — avoid scope creep.
- Delegate edits to @coder; manager does not hand-edit. @architect not consulted: this is a prescriptive tiering correction, not an open design question (the correct tier is unambiguous per issue #30).

## Key Files
- agents/manager.agent.md: move retrospective from "Default (On Unless Explicitly Disabled)" (line ~233) to "Hardcoded (Non-Negotiable)" tier; verify no Anti-Rationalization row or other tier frames the retro as skippable. The existing "We don't need a retrospective for this" anti-rationalization row already pushes back — keep/strengthen it.
- skills/task-retrospective/SKILL.md: audit for optional/skippable framing; align if needed.
- .context/workflows/task-plan/phase-completion.md: audit retro step wording for skippable framing.
- CHANGELOG.md: add `[Unreleased]` entry — agents/ ships with the plugin, so this IS a consumer-facing change. (ICON-0056)

## Progress
- [x] Task setup: branch, folder, plan.md created
- [x] @coder: moved retro bullet Default→Hardcoded (manager.agent.md:229, "no exceptions, no user override"); audited task-retrospective skill + phase-completion.md → both already mandatory, unchanged. Manager spot-checked the rendered tiers.
- [x] @reviewer: Approved. No Critical/Moderate. Two optional Minor notes (line 259 row could echo "no user override"; line 32 timing reference — no edit). Confirmed audit of the two related files.
- [x] @coder: applied Minor #1 (line 259 Correct Action now "…no exceptions, no user override.") + added CHANGELOG [Unreleased] → ### Changed bullet (ICON-0056). Manager verified both; [1.19.0] header intact; diff scoped to 3 files only.
- [x] Reconciled plan.md against final state.
- [x] task-retrospective run: entry drafted, inserted via script by @context-specialist (ICON-0041 pruned at cap=10). Q3 lesson promoted to standards/changelog-discipline.md.
- [x] Surfaced changelog-criterion inconsistency (git-clone means everything ships) → user chose user-relevance framing; corrected standards/changelog-discipline.md Rule 4 + the retro entry's Repeat(1) clause accordingly.
- [ ] Commit, push, open MR (mr-discipline) ← IN PROGRESS

## Outcome
- `agents/manager.agent.md`: retrospective now in Hardcoded (Non-Negotiable) tier ("no exceptions, no user override"); removed from Default; Anti-Rationalization row 259 aligned. Reviewer-approved.
- `CHANGELOG.md`: `[Unreleased] ### Changed` bullet added (ICON-0056).
- `.context/standards/changelog-discipline.md`: Rule 4 reframed to user-relevance criterion (supersedes the "does it ship" test).
- `.context/retrospectives.md`: ICON-0056 entry inserted.
- Resolves GitLab issue #30.

## Open Questions / Blockers
- Resolved: Default-tier line was cleanly removed (no replacement cross-reference needed) since the Hardcoded entry covers it. Coder confirmed the two audited files already treat the retro as mandatory.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005. Verification is by reading the rendered tiers, not by running a build.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003. (No version bump in this task — not releasing.)
- Agent definitions follow the "earn your place" principle: every line prevents a concrete mistake. Do not add bloat; the fix should be a move + minimal wording alignment, not new prose.
- Keep portable across Copilot CLI and Claude Code — no tool-specific constructs.
