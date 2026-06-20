## Task: ICON-0043
## Branch: feature/ICON-0043-plugin-design-skill
## Objective: Ship `skills/plugin-design/` as a consumer-facing skill that helps build Claude Code plugins from scratch and audit them for internal consistency + improvement opportunities. Thin-router `SKILL.md` + lazy-loaded mode and phase files per the structure prescribed in issue #28. Closes GitLab issue #28.
## Folder: .context/tasks/ICON-0043-plugin-design-skill/

## Decisions
- **Full file structure (11 files)** per the issue spec. User confirmed at task start (rejected the lean-2-file MVP option). Files: router `SKILL.md` + `create-mode.md` + 5 create-phase files + `audit-mode.md` + 3 audit-phase files. Flat layout (no subdirectories) following the precedent of `skills/writing-skills/` which holds companion files flat alongside `SKILL.md`.
- **Lean content within each file** — the YAGNI lesson from ICON-0041 applies to body length even when file count is full. Each file gets just enough workflow guidance to be useful; no preemptive anti-patterns tables, rationalization-prevention sections, or cross-ref webs unless the file genuinely needs them. Add later when observed needs surface.
- **Marketplace phase is optional, user is prompted at create-mode start** — open question Q1 resolved by user: "marketplace integration should be optional - ask the user." `create-mode.md` includes a prompt step before sequencing phases; the marketplace phase only runs if user opts in.
- **plugin-design ships with ICON, not as a separate plugin** — open question Q2 resolved by user: "ICON is intended to be kind of a generalized toolkit for agentic development, and building new plugins is part of that." Lives at `skills/plugin-design/` (shipped via `latest` tag), not `.claude/skills/`.
- **Audit mode hard-requires `/icon-init`** — open question Q3 resolved by user: "hard-required". `audit-mode.md` checks for `.context/iconrc.json` at the plugin root before sequencing phases; if missing, halts and instructs the user to run `/icon-init` first. Rationale: audit reads `.context/domains/`, `.context/standards/`, `.context/decisions/` to ground architectural-consistency checks; without those, the audit degenerates into a generic file-structure linter.
- **Sibling cross-refs**: `plugin-design` delegates `create-phase-context-init` to `/icon-init`, references `agent-evaluation` from `audit-phase-consistency.md` for the agent-system-design layer (matches the cross-ref pattern in `icon-audit/SKILL.md`), and references `setup-mcp-servers` from `create-phase-boilerplate.md` (in passing — the new plugin may want its own MCP servers).
- **Description form for auto-invocation**: SKILL.md frontmatter description names concrete triggers ("Use when about to scaffold a new Claude Code plugin, audit a plugin's structure for consistency, or evaluate a plugin against improvement-opportunity heuristics") so `using-skills` pulls it in at the right moment.
- **No `scripts/` directory in v1** — the issue says the boilerplate phase should create files like `plugin.json`, `README.md`, etc.; for the first cut, do this via inline bash + PowerShell heredocs in the phase file rather than separate scaffolding scripts. Promote to `scripts/` only if the inline-shell becomes unwieldy or duplicated.
- **No carry-forward / re-tier registry in audit mode** — per issue: "That concept is ICON-internal (one repo's audit cycle has continuity); generic consumers running ad-hoc audits don't need it." Audit-mode output is structured findings, no tiering history.

## Key Files

### A. Skill files (11 new)
- `skills/plugin-design/SKILL.md` — thin router. Description + Overview + When to Use + mode-detection logic (`create` vs `audit`) + companion-file index. ~50-80 lines.
- `skills/plugin-design/create-mode.md` — entry for create mode. Sequences the 5 create-phase files; includes the user-prompt step for whether to include marketplace. ~40-60 lines.
- `skills/plugin-design/create-phase-boilerplate.md` — scaffolding: `.claude-plugin/plugin.json`, `agents/`, `skills/`, `commands/`, `hooks/`, `shared/`, `README.md`, `CHANGELOG.md`, `.gitignore`. Inline bash + PowerShell for file creation. References SchemaStore-hosted plugin-manifest schema for `plugin.json`. ~80-120 lines.
- `skills/plugin-design/create-phase-basic-info.md` — interactive fill-in of `plugin.json` and `README.md` fields: name (slug-validated), version (SemVer, default `0.1.0`), description, author, license/no-license, entry-point intent. ~50-80 lines.
- `skills/plugin-design/create-phase-repo-setup.md` — optional `git init` + remote setup + initial commit + offer ICON commit-conventions / branching templates. ~40-60 lines.
- `skills/plugin-design/create-phase-context-init.md` — delegates to `/icon-init`. Short file; mostly explains the delegation and confirms the precondition (plugin folder exists). ~30-40 lines.
- `skills/plugin-design/create-phase-marketplace.md` — verify `plugin.json` schema-valid, generate marketplace-ready `README.md` skeleton (install + usage + capabilities), document submission process (the skill prepares, does not submit). ~60-90 lines.
- `skills/plugin-design/audit-mode.md` — entry for audit mode. Hard precondition check (`.context/iconrc.json` exists at plugin root → halt + instruct `/icon-init` if missing). Sequences the 3 audit-phase files. ~40-60 lines.
- `skills/plugin-design/audit-phase-structure.md` — file/folder + frontmatter validation: `plugin.json` schema-valid, required directories present, agent + skill frontmatter valid, CHANGELOG `[Unreleased]` block present. ~60-90 lines.
- `skills/plugin-design/audit-phase-consistency.md` — cross-file checks: skill references resolve, file-path refs resolve, frontmatter descriptions are non-boilerplate, role-overlap heuristic. References `agent-evaluation` for the agent-design layer. ~60-90 lines.
- `skills/plugin-design/audit-phase-improvements.md` — positive-design suggestions per MKT-0046 precedent (must produce ≥N opportunities; no scoring/tiering). Example heuristics: skills-table organization, always-loaded token economy, missing `using-skills`-style mandatory entries, retro-wisdom automation. ~50-80 lines.

### B. Consumer-facing
- `README.md` — add a `plugin-design` row in the user-invocable skill table (between `migration-planning` and `post-incident-review` alphabetically).
- `CHANGELOG.md` — `[Unreleased]` `### Added` entry.

### C. Bookkeeping
- `.context/tasks/ICON-0043-plugin-design-skill/plan.md` — this file.
- `.context/retrospectives.md` — appended at close.

## Progress
- [x] Create branch + task folder + plan.md
- [x] @coder (Opus) authored all 11 skill files — 35 KB total, largest 4.7 KB; lean YAGNI bar honored (no anti-patterns tables, no rationalization-prevention sections)
- [x] README skill-table row added alphabetically (between `migration-planning` and `post-incident-review`)
- [x] CHANGELOG `### Added` entry added under `[Unreleased]`
- [x] Verification: pre-commit hook 0, plugin.json valid, all 11 files exist with H1=1 and balanced fences
- [x] @reviewer (Opus) pass: 3 Critical (PS `\` line continuation parse error; PS regex `^...` single-line mode default; dead-ref resolver carried ICON-internal `context_template/context/` path mapping into generic plugin-audit logic) + 4 Moderate (skill-ref guard regex too narrow; `≥1` vs `≥3` improvement-count inconsistency; ICON "see ICON's own precedent" leakage in `create-phase-basic-info.md`; ICON path leakage in `create-phase-repo-setup.md` Conventions section)
- [x] @coder retry (Opus) addressed all 3 Critical + all 4 Moderate findings; verified via 6 grep + hook checks
- [x] task-retrospective Stage 1 (manager draft) + Stage 2 (specialist) — entry inserted; cap-converge from ICON-0041 worked correctly (10 → 10, pruned ICON-0033)
- [ ] Commit, push, open MR, AWAIT user approval ← IN PROGRESS

## Open Questions / Blockers
- Resolved at task start: (1) marketplace optional w/ user prompt, (2) plugin-design bundled with ICON, (3) audit mode hard-requires `/icon-init`.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- Per-file content stays lean (YAGNI per ICON-0041); add anti-patterns/discipline tables only when observed needs surface.
- `.githooks/pre-commit` dead-ref resolver scans skills/ — new file path references must resolve under `context_template/` or be wrapped in `<!-- pre-commit:dead-ref-ok-start/end -->` markers (ICON-0040 precedent).
