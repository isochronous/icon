# ICON-0046 — Plugin Audit (with Plugin-Decomposition Lens)

**Type:** Maintainer audit (icon-audit skill)
**Branch:** main (audit produces no source changes; report-only)
**Date opened:** 2026-05-27

---

## Goal

Run the standard 6-domain ICON audit against the current `main` (v1.17.2 plus zero `[Unreleased]` changes). Additionally, evaluate how this plugin could be split into 2+ composable plugins (e.g., software-development, product-management, agentic-toolkit-design, context-initialization), distinguishing standalone candidates from ICON-extension candidates from cross-composable building blocks.

## Phase 1 Baseline (Discovery Preamble)

**Prior audit:** ICON-0015 (2026-05-20, plugin v1.15.4 + Unreleased ICON-0011/0012/0013/0014). Verdict: GOOD — 0 Critical / 5 Moderate / 38 Minor / ~35 Improvement Opportunities. Most Tier-2 and Tier-3 recommendations were filed as ICON-0016 through ICON-0023 follow-ups.

**Current state:** v1.17.2 released 2026-05-26. `[Unreleased]` block is currently empty. 30 tasks have completed since ICON-0015 (ICON-0016 through ICON-0045).

**Filesystem counts:**
- 9 agents (unchanged)
- 49 consumer-facing skills in `skills/` (+1 net since ICON-0015: added `mcp-tools-first` + `plugin-design`; removed `plugin-audit` which was moved to maintainer-only `.claude/skills/icon-audit/`)
- 3 maintainer-only skills in `.claude/skills/`: `changelog-entry`, `icon-audit`, `release-plugin`
- 1 plugin manifest: `.claude-plugin/plugin.json`
- 11 ADRs: `.context/decisions/001` through `010` + `README.md` (decisions-folder layout migration via ICON-0040)
- Retrospective log: 49 lines (~10 entries at `ENTRY_CAP=10`)

**Retrospective log size:** 10 entries (cap-converged). Window covers ICON-0036 through ICON-0045.

**Known-churning areas distilled from retros + CHANGELOG since ICON-0015:**
1. **MCP tool integration & discipline** — ICON-0041 (skill creation), ICON-0045 (rationalization-prevention hardening). New skill class.
2. **Plugin-design + audit decomposition** — ICON-0042 (plugin-audit → icon-audit maintainer-move) + ICON-0043 (generic plugin-design skill for any plugin). Pre-tee for the decomposition question being asked here.
3. **Decisions-folder migration + auto-split rule** — ICON-0040 (`.context/decisions/<NNN>-<slug>.md` layout, 16 KB Folder Split threshold).
4. **Retrospective write-path canonicalization** — ICON-0027 + cap-convergence fix ICON-0041.
5. **Template promotions + carry-forward re-tier registry** — ICON-0039 (ADR-010 created).
6. **Release-flow & infrastructure hardening** — ICON-0038 (semver comparison, JSON schema, dry-run mode).
7. **Token-economy trims** — ICON-0033 (SSOT consolidations).
8. **Pre-commit hook extensions** — ICON-0032 (dead-ref resolver + script-parity), ICON-0044 (iconrc version-bump gate).

**Special directive for this audit:** in addition to the standard 6-domain output, produce a **plugin-decomposition analysis** that:
- Identifies natural plugin boundaries based on agent/skill clustering, dependency direction, audience, and reuse potential.
- Categorizes each candidate as (a) standalone (no ICON dependency), (b) ICON-extension (requires ICON's core), or (c) composable building block (usable alongside ICON or other plugins).
- Flags the dependency edges that would need attention if a split were attempted (shared common-constraints, `using-skills` cross-references, manager-routing-guide entries).
- Surfaces a recommended decomposition with phased migration path.

## Decisions

- **D1** — Brief 06 (cross-cutting) consumes briefs 01–05; dispatched after they complete.
- **D2** — A new Brief 07 (plugin-decomposition) consumes briefs 01–05 and runs in parallel with brief 06. It has its own brief file authored in this task folder.
- **D3** — No plugin source files are edited by sub-agents or by this skill; all output lives under `.context/tasks/ICON-0046-icon-audit/research/` and `audit-report.md`.
- **D4** — Decomposition recommendations are framed as Suggested Follow-up Tasks; we do not auto-file them as GitLab issues (per common-constraints data-exfiltration rule, user confirmation required).

## Dispatch Record

| Brief | Sub-agent | Status |
|-------|-----------|--------|
| 01-agents | explore (Sonnet) | dispatched |
| 02-process-skills | explore (Sonnet) | dispatched |
| 03-context-specialist-init | explore (Sonnet) | dispatched |
| 04-utility-skills | explore (Sonnet) | dispatched |
| 05-infrastructure | explore (Sonnet) | dispatched |
| 06-cross-cutting | architect (Opus) | dispatched after 01–05 |
| 07-plugin-decomposition | architect (Opus) | dispatched after 01–05 |

## Progress

- [x] Phase 1 Discovery complete (this preamble).
- [x] Task folder created at `.context/tasks/ICON-0046-icon-audit/`.
- [x] Brief 07 (plugin-decomposition) drafted inline in this task folder.
- [x] Phase 2 leaf dispatches (01–05) — all five research files written.
- [x] Phase 2 synthesis-tier dispatches (06 cross-cutting, 07 plugin-decomposition) — both research files written.
- [x] Phase 3 synthesis → `audit-report.md` written (344 lines).
- [ ] Chat summary delivered.
