## Task: ICON-0031
## Branch: feature/ICON-0031-doc-sweep-hook-arch
## Objective: Sweep user-facing docs to describe the post-ICON-0012 plugin-scoped hook architecture (M-CC-NET1 from ICON-0015 audit). Pre-tag-move correction so the `latest` move that ships ICON-0011/0012/0013/0014 doesn't carry stale prose.
## Folder: .context/tasks/ICON-0031-doc-sweep-hook-arch/

## Decisions
- Drop the "Starting with ICON 1.16" temporal framing in the `commands/*-manager-default.md` files: describe current behavior in plain present-tense. Rationale (per issue Fix direction §3): the maintainer running `release-plugin` decides the next version at tag-move time; command docs shouldn't anticipate it, and pre-tag the framing is internally inconsistent (released tag is still v1.15.4).
- Keep the `.github/copilot-instructions.md` mention in `README.md:27` as a back-compat note rather than dropping it entirely (issue Fix direction §4 offers both; back-compat note preserves the migration path for legacy repos while removing the "if not yet migrated" framing that implies migration is the current expectation).
- Single PR, single coder delegation — concrete diffs and acceptance grep are spelled out in the source issue; no architectural decisions remain.
- Expanded the sweep to include the two `commands/*-manager-default.md` frontmatter `description:` strings — they are user-facing (rendered in the slash-command picker and the Skill-tool listing) and were carrying the same pre-ICON-0012 phrasing the issue called out in body text. Caught in @reviewer pass; in scope for a "user-facing doc sweep". Same theme extension applied to `.claude/claude.md:24` ("scripts" plural → "script" singular) and `.claude/claude.md:9` ("Node.js" duplicated in the same clause).
- For `/ICON:enable-manager-default`, the README now says the command "sets `managerDefault: true`" rather than "removes that opt-out". The user-observable behavior is identical (`inject-manager-role.mjs` treats absent-key and `true` as equivalent), but the previous prose did not match the implementation — a user inspecting `~/.claude/icon-user-settings.json` after running enable would see the key still present. Doc-fix path chosen over command-change path (out of scope to alter command behavior).

## Key Files
- `README.md` — lines ~27 (Design Principles back-compat reframe), ~100/~104 (Default Role section: SessionStart hook description), ~113 (table row for `/ICON:enable-manager-default` correctly says "sets `managerDefault: true`").
- `.claude/claude.md` — line ~9 (single `hooks/inject-manager-role.mjs` cross-platform wrapper, no duplicated "Node.js"); line ~24 (singular "hook script that injects").
- `commands/enable-manager-default.md` — line ~2 frontmatter `description:` rewritten to present-tense; line ~7 body "Starting with ICON 1.16" preamble removed.
- `commands/disable-manager-default.md` — line ~2 frontmatter `description:` rewritten to present-tense; line ~7 body "Starting with ICON 1.16" preamble removed.

## Progress
- [x] Read source issue (#16) and confirm scope is doc-only.
- [x] Create branch + task folder + plan.
- [x] Delegate doc edits to @coder — acceptance grep returned zero hits.
- [x] @reviewer pass — three moderate findings (stale frontmatter descriptions ×2, README "removes opt-out" inaccuracy) + two minor polish items (`.claude/claude.md:9` duplicated "Node.js", `.claude/claude.md:24` plural "scripts").
- [x] Fix-up @coder pass — all five findings closed; six independent acceptance greps confirmed clean.
- [x] Reconcile plan.md against final state.
- [x] Retrospective — entry inserted via `append-retrospective-entry` script; ICON-0003 pruned by rolling-log cap.
- [x] CHANGELOG `[Unreleased]` entry added under `### Fixed`.
- [x] Commit + push + open MR !15.
- [x] **Post-MR regression fix** — user flagged that both rewritten command frontmatter `description:` values contained unquoted `: ` (mapping-separator) and would fail YAML parsing. Confirmed with js-yaml: both files threw `"bad indentation of a mapping entry"`. Converted both to folded block scalar `description: >\n  ...` (same pattern already used in `agents/manager.agent.md`) preserving description prose verbatim. Re-verified with js-yaml: both parse cleanly. Retro entry amended to fold in the lesson.
- [ ] Commit follow-up + push ← IN PROGRESS

## Open Questions / Blockers
- None. All reviewer findings closed in the fix-up pass.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003. Doc edits must not state a version; the next `latest`-tag move is what determines whether the released number is 1.16.x or otherwise.
- Out of scope: CHANGELOG `[Unreleased]` entries for ICON-0013/0014 (release-plugin owns these at tag-move; issue calls this out explicitly).
- Closes GitLab issue #16.
