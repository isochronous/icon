## Task: ICON-0045
## Branch: feature/ICON-0045-mcp-tools-first-hardening
## Objective: Harden `mcp-tools-first` with the rationalization-prevention layer that was deliberately deferred at ICON-0041 creation time ("start simple and only start adding stronger instructions and anti-rationalization tables once we've seen a need for them"). The need has now been observed: an agent confirmed `gitlab-create_merge_request` exists via tool search, then ran `which glab` to fall back to a familiar CLI because the MCP tool's parameter schema was unknown. The user explicitly framed this as the trigger to add the stronger layer.
## Folder: .context/tasks/ICON-0045-mcp-tools-first-hardening/

## Decisions
- Treat the user-supplied conversation log as the RED-phase observation: it captures the exact failure mode (parameter-discovery cost avoidance), the verbatim rationalization ("I knew the `glab` syntax cold; I'd never called the MCP tool"), and the user's articulated prevention rule. Per `writing-skills`, an edit also requires RED before GREEN — the conversation log satisfies this; no fresh subagent baseline run is required.
- Keep the skill scoped to GitLab/Jira/Confluence (the bundled MCP surfaces). The failure pattern generalizes, but broadening scope risks bloating a skill the user previously trimmed from 74 → 15 lines for being overkill. Add the rationalization-prevention layer only.
- Add the **Red Flags** list and **Rationalization Prevention** table per `writing-skills` discipline-skill hardening guidance (sections "Close Every Loophole", "Build a Rationalisation Table", "Create a Red-Flags List").
- Pre-empt the parameter-discovery rationalization explicitly: tell the agent what to do when it does not know the MCP tool's schema (use `ToolSearch select:<name>` to load it), rather than leaving the gap that gets filled with CLI fallback.
- Keep the skill's auto-invocation description unchanged — it already names the right triggers (`gh`, `glab`, `curl`, paste-URL). The body is what needs hardening, not the trigger surface.
- **Platform-agnostic phrasing (added mid-task at user prompt).** The conversation log driving this hardening is from Copilot (tool names like `gitlab-create_merge_request` without the `mcp__` prefix; agent used `tool_search_tool_regex`). Both the pre-existing body (`mcp__gitlab__*` literal prefix) and the first-pass hardening (`ToolSearch select:<name>` literal) were Claude-Code-coupled. Rewrote the body to name harness-neutral operations and explicitly footnote that tool-name prefixes differ by harness, with schema-discovery instructions covering Claude Code's `ToolSearch select:<name>`, Copilot's `tool_search_tool_regex`, and "or the equivalent in your environment" for unspecified harnesses. CLI fallback names (`gh`, `glab`, `curl`) stay literal — they're cross-harness already.
- No `iconrc.json` `version` bump required — `context_template/` is untouched (skill files live under `skills/`, not `context_template/`). The pre-commit gate for iconrc bumps (ICON-0044) only fires when `context_template/` content changes.

## Key Files
- `skills/mcp-tools-first/SKILL.md` — replace 15-line body with hardened version: tool-prefix paragraph retained, plus a "Red Flags" list, a "When the schema is unknown" instruction, and a rationalization-prevention table seeded with the verbatim excuse from the conversation log.
- `CHANGELOG.md` — `[Unreleased]` entry under `### Changed`, naming the hardening additions (loophole closure for "MCP tool exists but I don't know its parameters" fallback to CLI) and citing ICON-0045.
- `.context/retrospectives.md` — entry inserted by `task-retrospective` at task close.

## Progress
- [x] Scaffold task folder + plan.md
- [x] Edit `skills/mcp-tools-first/SKILL.md` — add Red Flags list, schema-unknown handling, rationalization table — outcome: skill grew from 15 → 60 lines; verbatim conversation-log excuse captured as a table row.
- [x] Update `CHANGELOG.md` — `[Unreleased]` `### Changed` entry citing ICON-0045 with concrete loophole closed.
- [x] Retrospective entry — appended via `append-retrospective-entry.sh`; entry covers the deferred-hardening promotion path.
- [x] Reconcile plan.md — completion marks above, retrospective inserted.
- [x] Commit on feature branch — `9a7739e` ICON-0045: harden mcp-tools-first with rationalization-prevention layer. Pre-commit hooks passed. Branch `feature/ICON-0045-mcp-tools-first-hardening` ready for merge to main at maintainer's discretion (recent task pattern is local merge → release commit).

## Open Questions / Blockers
- None. The failure mode, prevention rule, and skill location are all known.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- Skill body must stay self-contained — no cross-skill resource references (`writing-skills` § "Skills must be self-contained").
- Description field uses folded block scalar (`description: >`) per agent-evaluation and feedback memory; current frontmatter already complies — preserve it.

## Retrospective

See `.context/retrospectives.md` entry dated 2026-05-26 (ICON-0045).
