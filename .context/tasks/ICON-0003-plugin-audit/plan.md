# ICON-0003: First Plugin Audit in Standalone Repo

**Branch:** `feature/ICON-0003-plugin-audit`
**Skill:** `/plugin-audit`
**Date opened:** 2026-05-14
**Trigger:** User invoked `/plugin-audit` after the marketplace → standalone-repo split (commit `254ff7c chore: split ICON to standalone repo at v1.15.3`). User flag: "We just moved this plugin from a marketplace repo into its own repo, which involved a bit of restructuring and path updates, as well as separating out relevant .context data, so those areas may need special attention."

---

## Phase 1 — Discovery Baseline (the preamble every sub-agent uses)

### Prior audit

- **Prior audit ID:** MKT-0087 ("ICON Plugin Audit Report — MKT-0087 (Release-Stability Lens)")
- **Prior audit date:** 2026-04-29
- **Prior audit verdict:** POOR for release. 2 Critical (CC-C1, CC-C2), 14 Moderate, 44 Minor; 2 Criticals were fixed in MKT-0088 per CHANGELOG `[1.14.0]`.
- **Prior audit file (read-only reference):** `/home/jmcleod/dev/ai-platform/marketplace/.context/tasks/MKT-0087-plugin-audit/audit-report.md` and `./research/01..06-*.md` siblings.
- **Caution:** the prior audit was written against the marketplace repo layout (`plugins/ICON/...`, `marketplace.json`, `.gitlab-ci.yml`, sibling `ICON-beta/`). Some of its findings ARE NOT APPLICABLE here — see "Inapplicable prior findings" below.

### Repo movement since baseline

- **Plugin version at baseline:** `1.13.3-dev.39` (marketplace `dev` branch).
- **Plugin version at audit:** `1.15.3` (this repo, branch `main`).
- **Commits since baseline (in marketplace) covering ICON:** MKT-0088 (init bug fixes — Critical defects), MKT-0089 (claude.md redirect), MKT-0090 (task-workflow-template removal), MKT-0091 (manager-role-injection hardening), MKT-0092 (local-task-prefix), MKT-0093 (default model pins removed), MKT-0094 (README skill table split), then `chore: split ICON to standalone repo at v1.15.3`, then ICON-0001 (migrate .context/), ICON-0002 (prune script fix).
- **CHANGELOG size:** 834 lines (root `CHANGELOG.md`; MKT-0087 and later marketplace history all preserved).
- **Retrospectives:** 1 entry, 9 lines (`.context/retrospectives.md`), covering ICON-0001 and ICON-0002.

### Filesystem scale at audit

| Surface | Count | Path |
|---------|-------|------|
| Agents | 9 | `agents/*.agent.md` |
| Skills | 48 | `skills/*/SKILL.md` |
| Commands | 4 | `commands/*.md` (disable-manager-default, enable-manager-default, manager, pm) |
| Hooks (Claude Code SessionStart) | 2 | `hooks/inject-manager-role.{sh,ps1}` |
| Hooks (repo git) | 1 | `.githooks/post-commit` |
| Plugin manifests | 1 | `.claude-plugin/plugin.json` |
| MCP registries | 1 | `.mcp.json` |
| Shared content | 1 | `shared/common-constraints.md` |
| Context template | 1 tree | `context_template/` |
| Maintainer-only release tooling | `.claude/skills/release-plugin/` | local-only, not shipped |

### Layout delta vs marketplace baseline (CRITICAL CONTEXT FOR SUB-AGENTS)

The MKT-0087 baseline assumes `plugins/ICON/...` paths because ICON lived inside the `datascan-marketplace` monorepo. **In this repo, ICON IS the repo root.** Sub-agents must translate path references in their briefs:

| Brief reference | Actual path in this repo |
|-----------------|--------------------------|
| `plugins/<plugin>/agents/` | `agents/` |
| `plugins/<plugin>/skills/<skill-name>/SKILL.md` | `skills/<skill-name>/SKILL.md` |
| `plugins/<plugin>/.claude-plugin/plugin.json` | `.claude-plugin/plugin.json` |
| `plugins/<plugin>/.mcp.json` | `.mcp.json` |
| `plugins/<plugin>/CHANGELOG.md` | `CHANGELOG.md` (root) |
| `plugins/<plugin>/README.md` | `README.md` (root) |
| `plugins/<plugin>/.githooks/` | `.githooks/` (note: now repo-root git hooks, not plugin hooks) |
| `plugins/<plugin>/hooks/` | `hooks/` (SessionStart role-injection scripts) |
| `plugins/<plugin>/.claude/common-constraints.md` | `shared/common-constraints.md` |
| `plugins/<plugin>/scripts/` | does not exist (the marketplace `scripts/` directory did not migrate; only `.context/workflows/prune-context.sh` lives in this repo) |
| `plugins/<plugin>/skills/release-plugin/SKILL.md` | `.claude/skills/release-plugin/SKILL.md` (maintainer-only, not shipped) |

### Inapplicable prior findings

These MKT-0087 findings target marketplace-only artifacts and are out-of-scope for this audit. Sub-agents must NOT treat their absence as "fixed" — they were never *applicable* to this repo:

- `.gitlab-ci.yml` — does not exist in this repo. (Marketplace had it; ICON standalone does not yet have CI.)
- `marketplace.json` — never lived here; marketplace-only.
- `plugins/<plugin>/.github/plugin/plugin.json` — never lived here.
- `plugins/<plugin>/plugin.json` (the root mirror, distinct from `.claude-plugin/plugin.json`) — never lived here.
- `plugins/<plugin>/GETTING_STARTED.md`, `plugins/<plugin>/BEST_PRACTICES.md` — never lived here. (Only `README.md` exists at root.)
- `ICON-beta/` distribution snapshot — marketplace-only sibling. The post-split release flow uses tag movement, not a `-beta/` dist directory.
- `plugins/<plugin>/skills/release-plugin-beta/SKILL.md` — never lived here.
- `validate-manifests.sh` / `plugin-lint.sh` — marketplace `scripts/`; did not migrate.

Sub-agents reaching into these should record "out-of-scope for standalone repo" in their research file's Structural Observations section, not in defect tiers.

### Known-churning areas (from CHANGELOG + retrospectives since MKT-0087)

1. **Repo structural split** — the marketplace → standalone migration is the dominant churn. The `254ff7c chore: split ICON to standalone repo at v1.15.3` commit moved every file. Path references inside skills/agents/commands may still cite `plugins/ICON/...` paths that no longer exist.
2. **`.context/` was re-bootstrapped** — ICON-0001 migrated 6 plugin-authoring files from the marketplace `.context/` and then ran `mode=upgrade` to fill scaffold gaps. Cross-references from skill files into `.context/` may target paths that exist in marketplace but not yet here (or vice-versa).
3. **Init-skill correctness** — MKT-0088 fixed two release-blocking Criticals (CC-C1 + CC-C2) by patching `initialize-*` orchestrators and `create-iconrc`. Confirm those fixes survived the repo split.
4. **MCP credential bootstrap** — `setup-mcp-servers` and `.mcp.json` carry repo-specific GitLab and Atlassian endpoints; the move may have left stale references.
5. **Release-plugin script** — moved from `plugins/ICON/skills/release-plugin/` (marketplace) to `.claude/skills/release-plugin/` (this repo, maintainer-only). Its internal path assumptions may not have been audited end-to-end.

---

## Phase 2 — Parallel Dispatch Plan

5 sub-agents (briefs 01–05) dispatched in parallel; brief 06 (cross-cutting) dispatched after they complete.

| # | Brief | Output file |
|---|-------|-------------|
| 01 | Agents | `research/01-agents.md` |
| 02 | Process skills | `research/02-process-skills.md` |
| 03 | Context-specialist + init | `research/03-context-specialist-init.md` |
| 04 | Utility skills | `research/04-utility-skills.md` |
| 05 | Infrastructure | `research/05-infrastructure.md` |
| 06 | Cross-cutting (after 01–05) | `research/06-cross-cutting.md` |

Each sub-agent receives the brief verbatim, this plan's "Layout delta" and "Inapplicable prior findings" sections, the prior audit pointer (`/home/jmcleod/dev/ai-platform/marketplace/.context/tasks/MKT-0087-plugin-audit/`), and the instruction not to edit any file outside its `research/NN-*.md` output.

---

## Phase 3 — Synthesis

After all six research files exist, write `audit-report.md` using `synthesis-template.md` as the structural guide. Borrow the 5-rule scorecard from `agent-evaluation` (do not redefine it). Tier defects (Critical / Moderate / Minor). Aggregate Improvement Opportunities into the 5 standard categories. Three-bucket delta vs MKT-0087: fixed / still-present-or-partial / net-new.

---

## Phase 4 — Reporting

- Chat summary: top-line counts, delta vs MKT-0087, top 3 Tier-1 recommendations.
- Offer to file Suggested Follow-up Tasks as GitLab issues (user confirmation required).
- Append a retrospective entry per `context-maintenance` discipline.
- Commit the task folder to `feature/ICON-0003-plugin-audit`.

---

## Decisions

- **Branch:** `feature/ICON-0003-plugin-audit` cut from `main` at `d9cbc1c`. Audit artifacts only; no plugin source modifications in this branch.
- **Baseline:** MKT-0087 (2026-04-29) is the prior audit. Two Criticals from MKT-0087 (CC-C1 + CC-C2) were fixed in MKT-0088 per CHANGELOG `[1.14.0]`. Sub-agents should mark those as **fixed** in their Delta sections.
- **Out-of-scope artifacts:** marketplace-only files listed under "Inapplicable prior findings" are not defects; do not surface them.
- **Sub-agent path translation:** every sub-agent gets the "Layout delta" table and the user's framing verbatim so brief-vs-reality path mismatches are caught early.

---

## Status

- [x] Phase 1 baseline preamble recorded
- [x] Phase 2a dispatched (briefs 01-05 in parallel; all complete)
- [x] Phase 2b dispatched (brief 06 cross-cutting; complete)
- [x] Phase 3 synthesized (`audit-report.md` written, 301 lines)
- [x] Phase 4 reported (chat summary + retrospective + commit)

## Outcome

- **Verdict:** GOOD (improved from MKT-0087's POOR/release-blocking).
- **Defect counts:** 0 Critical / 12 Moderate / 42 Minor (54 total).
- **Net Critical movement:** −2 (CC-C1, CC-C2 fixed by MKT-0088 and verified to have survived the split).
- **Highest-leverage net-new defect:** M-U1 / M-CC2 — the `plugin-audit` skill itself was not migrated; 30+ stale `plugins/<plugin>/...` placeholders. Closure is O-S1 (ICON-0004).
- **Highest-leverage net-new improvement:** O-V1 + O-V2 — commit-time path-drift lint + cross-surface sweep rule widening. Closes the M-CC1 sweep-incompleteness pattern systemically. Bundled as ICON-0006.
