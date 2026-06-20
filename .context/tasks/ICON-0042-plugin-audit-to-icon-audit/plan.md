## Task: ICON-0042
## Branch: feature/ICON-0042-plugin-audit-to-icon-audit
## Objective: Move `skills/plugin-audit/` → `.claude/skills/icon-audit/` and rename `plugin-audit` → `icon-audit` throughout. The skill is specific to auditing the ICON plugin itself (ADR-007/009/010 references, ICON-specific finding IDs like `m-A-1`, `m-U-K`), so it belongs maintainer-only — parallel to `release-plugin` and `changelog-entry` already in `.claude/skills/`. Closes GitLab issue #27.
## Folder: .context/tasks/ICON-0042-plugin-audit-to-icon-audit/

## Decisions
- **`git mv` for the directory move** (per issue #27): preserves file history and renames in one operation. Avoids the `git rm + git add new` pattern that breaks blame continuity.
- **Move + rename in the same MR**: scope and name both change at once — the new path (`.claude/skills/icon-audit/`) signals "maintainer-only, ICON-internal" and the new name signals "audits ICON itself, not generic plugins." Splitting them would leave a confusing intermediate state.
- **README skill-table row removed**, not relabelled. `.claude/skills/` skills (icon-audit, release-plugin, changelog-entry) are not in the consumer-facing skill table — they're maintainer-only and don't ship via the marketplace `latest` tag. Precedent: `release-plugin` has no README entry.
- **briefs/ content unchanged**. The briefs reference ADR-007/009/010, finding IDs (`m-A-1`, etc.), and ICON-specific architecture — that's correct content now that the skill is correctly scoped at `.claude/skills/icon-audit/`. Per issue #27: "Brief content stays the same — once the skill is in `.claude/`, the ICON-specific content is correctly scoped."
- **Pre-commit hook scope check**: `.githooks/pre-commit` dead-ref resolver scans `agents/`, `skills/`, `shared/`, `commands/` — NOT `.claude/skills/`. The move removes the skill from hook scope by design, matching the `release-plugin` precedent. No hook changes needed.

## Key Files

### A. The move itself
- `skills/plugin-audit/` → `.claude/skills/icon-audit/` via `git mv` (4 entries: `SKILL.md`, `synthesis-template.md`, `briefs/` directory, `scripts/` directory).

### B. Internal references inside the moved skill
- `.claude/skills/icon-audit/SKILL.md`:
  - Frontmatter `name: plugin-audit` → `name: icon-audit`
  - Phase heading prefixes: `## plugin-audit: Phase 1/2/3:` → `## icon-audit: Phase 1/2/3:` (3 occurrences)
  - Task folder paths: `.context/tasks/<TASK-ID>-plugin-audit/` → `.context/tasks/<TASK-ID>-icon-audit/` (3 occurrences in SKILL.md)
- `.claude/skills/icon-audit/scripts/structural-check.sh`:
  - Header comment "plugin-audit skill files" → "icon-audit skill files"
  - Usage example path `skills/plugin-audit/scripts/structural-check.sh` → `.claude/skills/icon-audit/scripts/structural-check.sh`
  - `SKILL_ROOT="${REPO_ROOT}/skills/plugin-audit"` → `SKILL_ROOT="${REPO_ROOT}/.claude/skills/icon-audit"`
  - Grep target literal `"plugin-audit"` for the agent-evaluation cross-ref check → `"icon-audit"`
  - Failure messages mentioning `plugin-audit` → `icon-audit`
  - `head -6 "${SKILL_MD}" | grep -q "^name: plugin-audit"` → `... "^name: icon-audit"`
- `.claude/skills/icon-audit/briefs/` (6 brief files): **zero matches** for `plugin-audit` per grep — no edits.
- `.claude/skills/icon-audit/synthesis-template.md`: **zero matches** for `plugin-audit` — no edits.

### C. Consumer-facing surfaces (sweep)
- `README.md` L164: skill-table row for `plugin-audit` removed (maintainer-only skills aren't in this table).
- `.claude/claude.md`: no `plugin-audit` references (verified via grep).
- `agents/*.agent.md`: no references (verified).
- `shared/common-constraints.md`: no references (verified).
- `commands/`: no references (verified).
- `.context/tasks/ICON-0003-plugin-audit/`: historical task folder, NOT a skill reference. Left alone.

### D. CHANGELOG
- `[Unreleased]` `### Removed` entry: `skills/plugin-audit/` no longer ships to consumers; moved + renamed to `.claude/skills/icon-audit/`. Reference ICON-0038 release-plugin precedent.

### E. Bookkeeping
- `.context/tasks/ICON-0042-plugin-audit-to-icon-audit/plan.md` — this file.
- `.context/retrospectives.md` — appended at close.

## Progress
- [x] Survey: plugin-audit references in repo (10 hits in scope, 8 of them CHANGELOG history grandfathered; 1 README row to remove; 1 .claude/settings.local.json historical task-folder path → leave alone)
- [x] Create branch + task folder + plan.md
- [x] Execute `git mv skills/plugin-audit → .claude/skills/icon-audit` (9 files renamed, `R` status, history preserved)
- [x] Edit `.claude/skills/icon-audit/SKILL.md` (frontmatter name + description + H1 + 3 phase headings + 3 task-folder paths)
- [x] Edit `.claude/skills/icon-audit/scripts/structural-check.sh` (path constant + REPO_ROOT climb 4 levels + B.4 grep target + B.1 phase-heading regex fix + B.6 frontmatter-name check + B.6 description folded-scalar fix)
- [x] Remove README.md skill-table row for plugin-audit
- [x] structural-check.sh post-move: ALL OK (B.1–B.6)
- [x] `.githooks/pre-commit`: EXIT 0
- [x] `plugin.json` parses
- [x] CHANGELOG `### Removed` entry added
- [x] verification-checklist: Gate 1 (evidence — hook 0, structural-check 0, grep clean), Gate 2 (scope — only the move + targeted reference updates), Gate 3 (pattern — matches `release-plugin` precedent), Gate 4 (no rationalization residue)
- [x] @reviewer pass (Sonnet): 1 Critical (not-yet-committed — addressed by committing), 3 Moderate (evergreen `.context/` sweep misses — fixed: `skill-system.md`, `skill-decomposition.md`, `skill-structure.md:75` partial-update), 2 Minor process-sweeps.md hits + 1 ADR-010 living-text — fixed
- [x] task-retrospective Stage 1 (manager draft) + Stage 2 (context-specialist) — entry inserted; cap-converge from ICON-0041 worked correctly (13 → 10, pruned ICON-0029/0030/0031/0032)
- [ ] Commit, push, open MR, AWAIT user approval ← IN PROGRESS

## Open Questions / Blockers
- None. Scope is bounded; mechanical move + targeted reference updates; no hook changes needed since `.claude/skills/` is outside dead-ref scope by design.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- File history must be preserved via `git mv` (not `rm` + `add`).
- briefs/ content is ICON-specific and stays unchanged (issue #27 explicitly: "Brief content stays the same").
