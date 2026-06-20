# Changelog Discipline

Standards for writing entries in `CHANGELOG.md` at this repo's root — the canonical changelog driven by the `release-plugin` flow.

## Why these rules exist

The changelog is a user-facing release artifact. A reader skims it for "what changed and how does that affect me," not "how was the bug fixed" or "what was the dev process." It also ships verbatim to Slack via `format-slack.sh`, where multi-paragraph entries and fenced code blocks render poorly. Tight, scannable entries serve both surfaces.

## The Four Rules

### 1. One sentence per entry

Each bullet under `### Added` / `### Changed` / `### Fixed` / `### Removed` is a single sentence. The reason a change was needed (root-cause prose, before/after metrics, internal-invariant reassurances) belongs in the commit message, the task plan, and the retrospective — not the changelog.

✓ `Fixed silent skill-loader parse failures in three SKILL.md files whose plain-scalar descriptions contained colon-space mid-value. (MKT-0078)`

✗ `Fixed silent skill-loader parse failures. The descriptions in jira-story, post-meeting, and sprint-goals contained ': ' (colon + space) which the YAML parser treated as a nested mapping. The conversion is content-lossless and idempotent. (MKT-0078)` ← four sentences; sentences 2-4 are implementation/QA detail that belong in the retrospective

**Sweep PRs: one bullet per distinct fix-class.** When a single task closes multiple unrelated findings, write one `### Fixed` (or `### Changed`, etc.) bullet per distinct fix-class — not one semicolon-chained run-on summarizing the whole task. Same fix-class across multiple files is fine in one bullet; different fix-classes get different bullets. The reader scans for "what changed and does this affect me," which a per-fix-class slicing serves and a per-task summary does not.

✓ Two `### Fixed` bullets, one for "outdated cap references in two SKILL.md files" and one for "wrong verify-step filename in a third file" — same task, distinct fix-classes

✗ One `### Fixed` bullet listing both via "; and" — chains unrelated changes the reader has to parse apart

### 2. No block-level formatting

Inline code spans (single backticks for paths, identifiers, env vars) are required and expected. Block-level formatting is not allowed in entries:

- No triple-backtick fenced code blocks
- No multi-paragraph entries
- No nested bullet lists deeper than one level under the section heading

If an entry feels like it needs a code block, it is too complex for a single bullet — split it into multiple entries.

### 3. Ticket IDs go at the end, parenthesized

If a change is associated with a ticket, append `(TICKET-ID)` at the end. Never start the entry with the ticket ID — that is a commit-message convention, not a changelog convention. Multiple tickets are comma-separated inside one set of parentheses.

✓ `Tightened @planner output schema to a single-section JSON shape. (MKT-0061)`

✓ `Promoted "Skills Cannot Share Scripts" rule + reorganized release-helper paths. (MKT-0066, MKT-0070)`

✗ `**MKT-0061**: tightened @planner output schema to a single-section JSON shape.` ← ticket at start, breaks the convention

✗ `MKT-0061: Tightened @planner output schema to a single-section JSON shape.` ← same problem

### 4. Only user-relevant changes

The changelog describes changes to the **ICON plugin release** — what consumers see when they install or update the plugin via the `latest` tag at `gitlab.com/onedatascan/ai-platform/plugins/icon.git`. If a task touched only repo-internal artifacts, the changelog gets no entry for it (this is the `changelog-entry` skill's "legitimate skip" case).

**The reusable test**: "Does this change affect what consumers DO?" Because ICON installs by full git clone there is no packaging boundary — everything ships. Shipping alone is therefore not the criterion. An entry is required when the change affects **plugin behavior** (`agents/`, `skills/`, `commands/`, `hooks/`, `.mcp.json`, `.claude-plugin/`) or **process/usage docs consumers follow** (`README.md` install instructions, `CONTRIBUTING.md` contribution flow). It is NOT required for supplementary references that change no behavior or process — e.g. `CHEATSHEET.md` — even though they ship via git clone.

**Changelog-eligible**: `agents/`, `skills/` (excluding `.claude/skills/`), `commands/`, `hooks/`, `shared/`, `context_template/`, `.claude-plugin/plugin.json`, `.mcp.json`, `README.md`, `CONTRIBUTING.md`.

**NOT changelog-eligible**: `.context/` (any subdirectory — `domains/`, `standards/`, `workflows/`, `tasks/`, `decisions/`, `retrospectives.md`, `META.md`), `.claude/skills/` (maintainer-only skills like `release-plugin`, `changelog-entry`), `.githooks/`, repo-internal scripts, `plan.md` and task-folder artifacts, this repo's own `CHANGELOG.md`, supplementary reference docs like `CHEATSHEET.md` that change no behavior or process consumers follow.

Edge case: `context_template/` IS changelog-eligible (used by `/icon-init` in consumer repos), so changes to `context_template/context/workflows/task-plan/*` ARE changelog-eligible. But changes to **this** repo's `.context/workflows/task-plan/*` (without a matching `context_template/` update) are repo-local-only.

✓ `Refactored phase-completion template to consolidate CHANGELOG step. (ICON-0026)` ← if the refactor lived in `context_template/context/workflows/task-plan/phase-completion.md`

✗ `Added an Update CHANGELOG step to .context/workflows/task-plan/phase-completion.md.` ← repo-local-only path; consumers never see this file

## Edit boundary when modifying `[Unreleased]`

When adding or editing a bullet under `## [Unreleased]`, the `Edit` tool's `old_string` must stay **strictly inside the `[Unreleased]` block** — it must never include the next `## [X.Y.Z] - YYYY-MM-DD` version header. Including that header in `old_string` and forgetting to reproduce it in `new_string` silently deletes the version header, absorbing the next release's entries back into `[Unreleased]` (this happened in ICON-0049 and was recovered in v1.18.2).

**Safe anchor**: bound the edit on the empty line above the heading you are changing — for an empty `[Unreleased]`, anchor on `## [Unreleased]\n\n`:

```
old_string:  "## [Unreleased]\n\n"
new_string:  "## [Unreleased]\n\n### Fixed\n\n- <bullet> (TICKET)\n\n"
```

This keeps the next `## [X.Y.Z]` heading out of the diff boundary entirely. Alternatively, anchor on an existing `### Fixed` / `### Changed` heading already inside `[Unreleased]`.

**Verify after the edit**: re-read the top of the file and confirm the most recent `## [X.Y.Z]` version header is still present before committing.

## Scope

- **Applies to**: `CHANGELOG.md` at this repo's root from MKT-0079 onward.
- **Does not apply retroactively**: existing entries are grandfathered. Do not sweep them for compliance.

## Pattern observed

MKT-0078's first changelog draft was four sentences, included an internal mirror invariant, and had to be cleaned up in a follow-up commit and reposted to Slack. The cleanup edit is the diff to study: it kept the user-relevant claim ("fixes silent parse failures in jira-story / post-meeting / sprint-goals") and discarded the QA reassurances and process detail.
