## Task: ICON-0050
## Branch: feature/ICON-0050-contributing-md
## Objective: Add a top-level CONTRIBUTING.md that routes defect reports and feature suggestions to GitLab work items, and instructs code contributors to use Claude Code or Copilot CLI with ICON installed and the standard ICON task flow ("New task: …" → "task complete"). Encourages a holistic plugin review before opening an MR. Establishes the governance model raised in the umbrella-naming Slack thread (2026-06-02): inclusive contributions, hygiene preserved by the toolchain itself.
## Folder: .context/tasks/ICON-0050-contributing-md/

## Decisions
- **Filename: `CONTRIBUTING.md` (not `CONTRIBUTORS.md`)** — GitLab/GitHub convention; surfaces automatically in the MR sidebar and Issue templates. `CONTRIBUTORS.md` is for listing names, not process.
- **No new GitLab issue templates in this task** — scope is the contributor-facing document only. Templates can come later if open-issue volume warrants.
- **Reference the README for install steps, do not duplicate** — single source of truth. CONTRIBUTING.md links to the README's `## Installation` section.
- **Task-flow phrasing is mandatory, not suggested** — the "New task: …" / "task complete" verbiage triggers ICON's session-start and retrospective discipline; without it the plugin's quality gates don't fire. Document as a requirement.
- **Holistic plugin review is contributor-side, not maintainer-side** — the contributor runs `/icon-audit` (or equivalent broad re-check) against their branch before opening the MR; this catches cross-cutting drift before reviewer load.

## Key Files
- `CONTRIBUTING.md` (new, repo root) — primary deliverable
- `CHANGELOG.md` — append a `[Unreleased]` entry at task close per `changelog-entry` discipline
- (No agent/skill/manifest changes — pure docs addition)

## Progress
- [x] Feature branch created
- [x] Task folder + plan created
- [x] Draft CONTRIBUTING.md written (66 lines)
- [ ] User review of draft ← IN PROGRESS
- [ ] Apply any revisions
- [ ] CHANGELOG `[Unreleased]` entry appended
- [ ] @reviewer pass
- [ ] Retrospective + commit

## Open Questions / Blockers
- None at draft time. May surface during review.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003. (No version bump for this task; docs-only addition lands in `[Unreleased]` until next release.)
- Per common-constraints data-exfiltration rule + auto-memory: no release / tag / Slack-post on this task unless user explicitly directs.
- CHANGELOG `[Unreleased]` edit boundary (auto-memory): `old_string` must anchor on `## [Unreleased]\n\n` and must NOT include the next `## [X.Y.Z]` header.
