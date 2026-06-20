## Task: ICON-0047
## Branch: feature/ICON-0047-writing-skills-where-skills-live
## Objective: Teach `writing-skills` to direct authors to the correct destination for new skills — plugin (`<plugin-repo>/skills/`), repo-level (`<repo>/.claude/skills/`), or user-level (`~/.claude/skills/`). The current skill describes the INTERNAL structure of a skill folder but is silent on WHERE that folder belongs. Authors with no guidance default to wherever the example came from.
## Folder: .context/tasks/ICON-0047-writing-skills-where-skills-live/

## Decisions
- **Apply writing-skills iron law to this edit**: An earlier attempt to add this section bypassed the RED-GREEN-REFACTOR cycle (no baseline test, no subagent verification). The user called the violation out and directed a redo from scratch. This task explicitly runs the pressure test first, even though the addition is small reference content — the iron law says "Not for 'just adding a section'."
- **Three scopes, not two**: Initial draft covered plugin + repo-level only. User flagged user-level skills (`~/.claude/skills/`) as a third destination — global to the operator across all repos. The "where" answer is incomplete without it.
- **YAGNI for the addition**: Per ICON-0041/0045 lessons — lean body, no anti-rationalization tables until observed failure justifies them. Goal is the minimum content that makes the right destination obvious.

## Key Files
- `skills/writing-skills/SKILL.md` — add a "Where Skills Live" section
- `CHANGELOG.md` — `[Unreleased]` entry for the addition
- `.context/retrospectives.md` — retrospective entry at task close (via append-retrospective-entry script)

## Progress
- [x] Create branch + task folder + plan.md
- [x] RED: Baseline pressure test — fresh Sonnet subagent against three scenarios. Result: Skill B (maintainer-only) wrongly placed in `plugins/icon/skills/` with verbatim reasoning "There is no separate 'maintainer-only' subdirectory defined anywhere in the tooling." Meta-note: PARTIAL.
- [x] Analyze baseline — gap is naming `.claude/skills/` as repo-scope destination + naming `~/.claude/skills/` as user-scope + giving a worked example contrasting maintainer-only-within-plugin from consumer-facing-within-plugin
- [x] GREEN: @coder added `## Where Skills Live` section at lines 79-102 of `skills/writing-skills/SKILL.md` — 3-row scope table, decision rule, worked example citing `release-plugin` vs `writing-skills` vs `my-draft-style`
- [x] Verify (pass 1): Fresh Sonnet subagent re-ran the same three scenarios. All three correct. Meta-note flipped PARTIAL → YES.
- [x] @reviewer (Opus) pass: 1 Critical + 2 Moderate + 1 Minor — Critical was line 98 "lives at" path being the consumer path, not the source path; same root cause at table line 85; line 91 "project-specific workflows" conflicted with line 64 "project-specific conventions → .context/standards/"; line 102 hedge paragraph was YAGNI-loose. Verdict: Approve with fixes.
- [x] @coder applied four fixes: line 85 (path cell disambiguated authoring vs installed), line 91 (repo-level rule now excludes conventions/rules with back-ref to "Don't create for"), line 98 (worked example honest about source vs install path), line 102 (hedge paragraph compressed to declarative one-liner)
- [x] Verify (pass 2): Fresh Sonnet subagent re-ran all three scenarios after fixes. All three still correct; verifier explicitly cited the `release-plugin` worked example as Skill B's reason. Loophole flagged (academic, did not manifest in their behavior) — per YAGNI, retained as-is.
- [x] CHANGELOG `[Unreleased]` `### Changed` entry added (cumulative-effect check: no overlap with existing ICON-0046 entry).
- [x] Reconcile plan.md against final state.
- [x] Task-retrospective: Stage 1 manager draft + Stage 2 @context-specialist insertion (script-based; ICON-0036 pruned at cap=10; no `.context/` promotions — all lessons retro-only first-occurrence).
- [ ] Commit all task artifacts ← IN PROGRESS
- [ ] Open MR

## Open Questions / Blockers
- None at task start. Surface here if the baseline subagent picks the *correct* destination by luck — that would mean the test scenario didn't pressure the right axis and needs redesign before writing.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- `writing-skills` iron law applies to edits, not just new skills. No skipping RED.
- Edit must be portable across Copilot CLI and Claude Code — `~/.claude/skills/` is Claude Code's user dir; describe behavior accurately without claiming portability where it doesn't exist.
