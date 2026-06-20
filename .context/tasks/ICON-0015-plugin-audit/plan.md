## Task: ICON-0015
## Branch: feature/ICON-0015-plugin-audit
## Objective: Run a six-domain parallel plugin audit focused on internal consistency and token efficiency. Produce tiered defect inventory, improvement opportunities, delta vs ICON-0003, and fix-tier recommendations.
## Folder: .context/tasks/ICON-0015-plugin-audit/

## User Directive (verbatim)

> "Audit plugin with two focuses: internal consistency and token efficiency. Do not suggest changes that remove core mechanisms like anti-rationalization tables. Do not suggest automatically updating the changelog based on git commit messages. Act as ICON:manager for the duration of this task."

This directive shapes every sub-agent dispatch and synthesis: AR tables are load-bearing redundancy (see ADR codified in MKT-0081 / `.context/standards/anti-rationalization-tables.md`) and are out-of-scope for trimming proposals; CHANGELOG automation from commit messages is not a recommendation any brief should produce.

## Phase 1 Baseline Preamble

- **Prior audit ID and date:** ICON-0003 (2026-05-14, plugin v1.15.3, verdict GOOD — 0 Critical / 12 Moderate / 42 Minor / 38 Improvements). Report at `.context/tasks/ICON-0003-plugin-audit/audit-report.md`.
- **Retrospective entries since baseline:** 7 (ICON-0004, 0006, 0007, 0008, 0011, 0012, 0014). File `.context/retrospectives.md` now sits at 49 lines, well under the 15-entry / decay cap.
- **CHANGELOG entries since baseline:** v1.15.4 release (single release covering ICON-0002, 0004, 0005, 0006, 0007, 0008, 0009, 0010) + current `[Unreleased]` block covering ICON-0011, 0012, 0014 (in retros but not yet in changelog).
- **Current filesystem scale:** 9 agents, 48 skills, 1 plugin manifest (`.claude-plugin/plugin.json`). Plus `.claude/skills/release-plugin/` (maintainer-only, not shipped).
- **Known-churning areas since baseline:**
  1. `plugin-audit` skill itself (ICON-0004 migrated it; this audit dogfoods that migration).
  2. `release-plugin` SKILL.md & `workflows/changelog.md` (ICON-0010 reconciled CHANGELOG-shape; v1.15.4 release proved the workflow).
  3. Initialization orchestrators (ICON-0007 routing fix; ICON-0008 multimodule parity).
  4. Process-skills delegation (ICON-0006 routed `.context/` writes through `@context-specialist`).
  5. Hooks infrastructure (ICON-0011 added common-constraints sync pre-commit hook; ICON-0012 replaced bash/pwsh hook pair with single Node wrapper; ICON-0014 added plan.md freshness gate as step 0 of task completion).

## ICON-0003 Defects: Pre-Audit Disposition Hypothesis

For each sub-agent: verify on-disk before declaring fixed. This list is the **manager's expectation**, not authoritative — sub-agent must cite line numbers either way.

| ICON-0003 Item | Expected disposition | Closing task |
|----------------|---------------------|--------------|
| M-U1 (plugin-audit unmigrated) | FIXED | ICON-0004 |
| M-1 (release-plugin CHANGELOG-shape) | FIXED | ICON-0010 |
| M-2 (release-plugin Error Conditions sed ref) | FIXED | ICON-0010 |
| M-I1 (context-specialist mode:upgrade routing) | FIXED | ICON-0007 |
| M-I2 (initialize-multimodule MR parity) | FIXED | ICON-0008 |
| M-I3 (initialize-multimodule disable-model-invocation) | FIXED | ICON-0008 |
| M-P1 (design-first hard-gate phrasing) | FIXED | ICON-0005 |
| M-P2 (task-plan-phase-completion vs task-retrospective delegation) | FIXED | ICON-0006 |
| M-U2 (writing-skills registration cleanup) | FIXED | ICON-0009 |
| M-A2 (common-constraints 9× duplication) | PARTIALLY FIXED — duplication remains but is now byte-equal-enforced by `.githooks/pre-commit` (ICON-0011). Treat the duplication as accepted-by-design with mechanical enforcement; re-tier if needed. |
| M-A1, M-A3 (planner code-fence count; architect AR sub-tables) | UNFIXED expected — no closing task in retros. |

## Sub-Agent Dispatch Plan

Six domain briefs at `~/.claude/plugins/cache/datascan-marketplace/ICON/1.15.4/skills/plugin-audit/briefs/`:

| # | Brief | Domain |
|---|-------|--------|
| 01 | `01-agents.md` | Agent definitions |
| 02 | `02-process-skills.md` | Orchestration + discipline skills |
| 03 | `03-context-specialist-init.md` | Context-specialist + init tree |
| 04 | `04-utility-skills.md` | Standalone utility skills |
| 05 | `05-infrastructure.md` | Manifests, scripts, hooks, docs |
| 06 | `06-cross-cutting.md` | Token economics, discoverability, onboarding |

**Dispatch model:** five leaf briefs (01–05) in parallel as Sonnet sub-agents (per user's default model standing instruction). Brief 06 dispatched serially after 01–05 complete, consuming their research outputs.

Each sub-agent receives:
- Its brief path (absolute).
- The path to the prior audit (`.context/tasks/ICON-0003-plugin-audit/audit-report.md`).
- The user's two focuses (internal consistency + token efficiency).
- The two off-limits directives (no AR-table trimming; no CHANGELOG automation).
- Phase 1 baseline preamble (above).
- Output path: `.context/tasks/ICON-0015-plugin-audit/research/0N-<domain>.md`.

## Decisions

- **Use canonical six-domain split.** No need to override; this plugin's structure maps cleanly to the brief set.
- **Sub-agent model:** Sonnet across all six (per standing user pref); the synthesis phase runs on Opus (this conversation).
- **Worktree isolation:** not used — manager edits no source files except merging ICON-0013/0014 (under user direction); audit artifacts confined to `.context/tasks/ICON-0015-plugin-audit/`.
- **~~No GitLab issue filing.~~ REVERSED mid-task.** Per user direction at synthesis close, filed 13 GitLab issues against `onedatascan/ai-platform/plugins/icon` (#12–#24). The ICON-0003 audit's "Suggested Follow-up Tasks" list pattern was supplanted by direct issue filing this cycle.
- **Mid-audit merge of ICON-0013 + ICON-0014.** Under user direction during synthesis, merged both feature branches into `main` (one retrospectives.md conflict, resolved by placing ICON-0014 above ICON-0013 in reverse-chronological order). Branch rebased onto post-merge main for the audit-artifact commit.
- **Plugin-vs-local-`.context/` distinction (user clarification).** Plugin-shipped agents MAY reference template-shipped `.context/` subdirectories (`standards/`, `domains/`, `workflows/`, etc.) and standardized files. What they may NOT do is name a *specific file by name* that the plugin doesn't ship under `context_template/`. This distinction reframed Critical C1 → Moderate M-CC-NET3 (single file: `manager.agent.md:151` → `three-layer-enforcement.md`) and reframed Moderate M-P-A → Improvement Opportunity O-S3 (local `.context/workflows/task-plan/phase-*.md` divergence from `context_template/` is expected, not drift).
- **Release-via-`latest`-tag (user clarification).** ICON releases by moving the `latest` tag, not by merging to `main`. M-CC-NET1 was narrowed to user-facing doc-drift; the `[Unreleased]` CHANGELOG completeness sub-cluster was withdrawn because `release-plugin/SKILL.md` Steps 2–5 author versioned CHANGELOG sections from the git diff + commit log at tag-move time.

## Key Files

- `.context/tasks/ICON-0015-plugin-audit/plan.md` — this file
- `.context/tasks/ICON-0015-plugin-audit/research/01-agents.md` through `06-cross-cutting.md` — six sub-agent outputs (one per domain brief)
- `.context/tasks/ICON-0015-plugin-audit/audit-report.md` — synthesis output (~600 lines after four feedback-round reframings)
- `.context/retrospectives.md` — this task's retro entry appended at close
- `.context/tasks/ICON-0003-plugin-audit/audit-report.md` — baseline for delta comparisons (read-only)
- `agents/manager.agent.md` — referenced as plugin-shipped surface in M-CC-NET3 finding (no edits in this task)
- GitLab issues #12–#24 — 13 follow-up issues filed against `onedatascan/ai-platform/plugins/icon` (no on-disk artifact in this repo)
- Memory files (user-scope) added this task:
  - `~/.claude/projects/-home-jmcleod-dev-ai-platform-plugins-icon/memory/feedback_agents_no_context_refs.md`
  - `~/.claude/projects/-home-jmcleod-dev-ai-platform-plugins-icon/memory/feedback_release_via_latest_tag.md`

## Progress

- [x] Phase 0 — Switch to manager role; invoke using-skills
- [x] Phase 1 — Discovery: prior audit, retros, CHANGELOG, filesystem scale
- [x] Phase 1 — Create branch + task folder + plan.md
- [x] Phase 2 — Dispatched briefs 01–05 in parallel; all 5 research files written
- [x] Phase 2 — Dispatched brief 06 (cross-cutting synthesis-axis); research file written
- [x] Phase 3 — Synthesized `audit-report.md` from 6 research files
- [x] Phase 3 — User feedback round 1: agents must not reference `.context/` paths (added Critical C1 framing, saved memory)
- [x] Phase 3 — User instruction: merged ICON-0013 + ICON-0014 into main (conflict in retrospectives.md ordering resolved)
- [x] Phase 3 — User feedback round 2: plugin vs local `.context/` distinction (reframed M-P-A as Improvement Opportunity, dropped O-V3)
- [x] Phase 3 — User feedback round 3: agents MAY reference template-shipped subdirs; only specific-file-by-name references to non-shipped files are violations (walked C1 back to Moderate M-CC-NET3)
- [x] Phase 3 — Final counts: 0 Critical, 5 Moderate, 36 Minor, ~34 Improvements; verdict GOOD
- [x] Phase 3 — Post final chat summary
- [x] User feedback round 4: release-plugin handles CHANGELOG auto-generation; withdrew the CHANGELOG-completeness sub-cluster of M-CC-NET1
- [x] Filed 13 GitLab issues: 4 standalone Moderates (#12 M-CC-NET2, #13 M-CC-NET3, #14 M-I-A, #15 M-U-A) + 1 Moderate doc-sweep (#16 M-CC-NET1) + 8 bundled work items (#17 pre-commit, #18 token-economy, #19 agents, #20 init, #21 phase-skill, #22 utility-skill, #23 release-flow, #24 base-template-gen + re-tier)
- [x] Surfaced 5 Open Questions to user in audit-report.md (4 originals + 1 from the agent-frontmatter normalization decision)
- [x] Filed all 13 follow-up tasks as GitLab issues (per user direction; replaces the "Suggested Follow-up Tasks" Markdown-only pattern from ICON-0003)
- [x] Step 0 of completion — reconciled plan.md against final state (ICON-0014 freshness gate, now live on main)
- [x] Task-retrospective — dispatched @context-specialist mode:maintenance; specialist staged `.context/retrospectives.md` (12 entries, no pruning); no `.context/` promotions warranted this cycle
- [ ] Commit all artifacts on `feature/ICON-0015-plugin-audit` branch ← IN PROGRESS

## Open Questions / Blockers

- None for the audit itself — all five Open Questions from the synthesis report are surfaced for **user triage** of the 13 follow-up issues, not blockers for closing this audit task.
- The Open Questions are now embedded in `audit-report.md § Open Questions for the User` and tracked across issues #16–#24's `## Acceptance` sections; future audits should read those issues' resolutions rather than re-reading the audit-report.

## Constraints

- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- **AR tables are load-bearing redundancy** — codified in `.context/standards/anti-rationalization-tables.md`; sub-agents must not propose trimming them on single-source-of-truth grounds. ICON-0003 already verified this carveout is in place (RULE 2 WARNING, with AR-table exemption preserved).
- **No NEW CHANGELOG-automation mechanism proposals.** The existing `.claude/skills/release-plugin/SKILL.md` Steps 2–5 already author the versioned CHANGELOG section from the git diff + commit log between the last release commit and HEAD at tag-move time. The user's directive forbids proposing *additional* automation; the existing mechanism stands.
- Read-only investigation: no sub-agent edits plugin source files. All output goes to `<task-folder>/research/`.
- Cite `<file>:<line-range>` for every finding. No conclusions without locations.
- Each domain produces ≥3 improvement opportunities (forward-looking mandate).
