## Task: ICON-0037
## Branch: feature/ICON-0037-utility-skill-polish
## Objective: Apply 7 small content-correctness fixes inside individual utility skills, bundled per GitLab issue #22 (carry-forwards m-U-A, m-U-B, m-U-C, m-U-E, m-U-F, m-U-I from ICON-0015 audit + net-new m-U-D). All fixes are independent; bundled because each is a one-author sweep across `skills/` (+ adjacent agents/context_template for the m-U-C scope expansion).
## Folder: .context/tasks/ICON-0037-utility-skill-polish/

## Decisions
- m-U-A — Replace `Claude Sonnet 4.6` (cited at `ecological-impact/SKILL.md:86, :221`) with the placeholder `<model-in-use>`. Rationale: angle-bracketed placeholder convention per ICON-0035 retro (Pattern-3 m9 cycle); also drop `GPT-4.1` co-reference at :86 since the example list itself is the canonical-output reference for the agent. Future model generations cannot re-create the defect.
- m-U-B — Generic verb: rewrite both `jira-story/SKILL.md:32` and `:35` to "Write the file using your available file-write tool" (issue-recommended phrasing). Same pattern applied to m-U-D below.
- m-U-C — **Extended to all 15 sites with breakout commit** per user direction. Original scope: 3 cited + 10 drift sites (pre-flight Explore). Final scope: 3 cited + 12 drift sites (the additional 2 — `agents/manager.agent.md:44` + `:86` — surfaced by @reviewer as a different phrasing variant `"for repos that haven't migrated"`; user direction "Unify in this MR (add to drift-sweep commit)"). Final phrase: `"on repos still on the legacy path"` (chosen at @coder dispatch time over the earlier-considered "for repos on the legacy .github/copilot-instructions.md path"). Two commits: (1) 8 files = the 7 sub-task fixes (m-U-A/B/D/E/F/I) + 3 `start-worktree` cited sites + CHANGELOG; (2) 10 files = the m-U-C drift sweep. Rationale: clearer review trail; same end state as one big commit; matches ICON-0036's promoted "manager repo-wide sweep" pattern.
- m-U-D — Cited line `:495` in `writing-skills/SKILL.md` is wrong (that line is `## The Bottom Line`). Actual `TaskCreate` references live in two sub-files of `skills/writing-skills/`: `skill-creation-checklist.md:6` and `persuasion-principles.md:36`. Apply same generic-verb pattern as m-U-B: `skill-creation-checklist.md:6` → "Track each phase using your runtime's task-tracking tool." (replaces "Use `TaskCreate` to track each phase."); `persuasion-principles.md:36` → "Use your runtime's task-tracking tool for checklists" (replaces "Use task tracking (e.g. `TaskCreate`) for checklists").
- m-U-E — Revise framing to single-option per user direction: remove "Choose one option. Option A is recommended for most users." from `setup-mcp-servers/SKILL.md:100-102`. Step 3's option header simplifies to a direct instruction. No new Option B documented.
- m-U-F — Move the `rfc/SKILL.md:139` design-history paragraph ("Section-5 resolution (Operationalization ⊇ Security)…") to a new `## Design Notes` section at the end of the file. The Step 3 schema closing ``` ``` at :137 then flows directly into the `## rfc: Step 4` heading at :141 (via one blank line).
- m-U-I — Drop the `synthesis-template.md:122` MKT-0046 sentence entirely (the precedent value is already encoded in the `plugin-audit` SKILL.md overview). For the 6 "Per MKT-0046 user directive" lines in `briefs/01..06.md`: per user direction, evaluate per-line — leave MKT-0046 as a provenance label IF (a) the directive itself is stated nearby in the same file, OR (b) the agent will definitely already know what the MKT-0046 user directive refers to when executing the brief. Otherwise rewrite the line to state the directive self-contained (drop the MKT-0046 citation). Note: in practice (b) almost always reduces to (a) since fresh audit-running agents do not have access to the original MKT-0046 conversation. `SKILL.md:57` example placeholder ("e.g., 'baseline: MKT-0046, 2026-04-21'") is a format example, not a real reference — leave alone.

## Key Files
- `skills/ecological-impact/SKILL.md` (lines ~86, ~221) — m-U-A
- `skills/jira-story/SKILL.md` (lines 32, 35) — m-U-B
- `skills/start-worktree/SKILL.md` (lines 87, 111, 162) — m-U-C cited
- `skills/writing-skills/skill-creation-checklist.md` (line 6) — m-U-D
- `skills/writing-skills/persuasion-principles.md` (line 36) — m-U-D
- `skills/setup-mcp-servers/SKILL.md` (lines 100-102) — m-U-E
- `skills/rfc/SKILL.md` (lines 137-141; relocate :139; add `## Design Notes` near EOF) — m-U-F
- `skills/plugin-audit/synthesis-template.md` (line 122) — m-U-I (drop)
- `skills/plugin-audit/briefs/01-agents.md:33` — m-U-I (conditional)
- `skills/plugin-audit/briefs/02-process-skills.md:32` — m-U-I (conditional)
- `skills/plugin-audit/briefs/03-context-specialist-init.md:35` — m-U-I (conditional)
- `skills/plugin-audit/briefs/04-utility-skills.md:36, :40` — m-U-I (conditional)
- `skills/plugin-audit/briefs/05-infrastructure.md:57` — m-U-I (conditional)
- `skills/plugin-audit/briefs/06-cross-cutting.md:28` — m-U-I (conditional)
- **m-U-C drift sites (commit 2, final 12 sites in 10 files)**:
  - `skills/task-plan-phase-investigation/SKILL.md:22`
  - `skills/resolve-repo-context/SKILL.md:19`
  - `skills/task-plan-phase-completion/SKILL.md:58`
  - `agents/product-manager.agent.md:23, :144`
  - `agents/researcher.agent.md:35`
  - `agents/reviewer.agent.md:17`
  - `agents/coder.agent.md:30`
  - `agents/tester.agent.md:28`
  - `agents/manager.agent.md:88` (cited drift) + `:44, :86` (different-phrase drift unified per user direction post-@reviewer)
  - `context_template/context/workflows/commit-conventions.md:3`
- `CHANGELOG.md` — 6 [Unreleased] entries (3 Changed + 3 Fixed)
- `.context/tasks/ICON-0037-utility-skill-polish/plan.md` — this file

## Progress
- [x] Create branch + task folder + plan.md
- [x] Surface decisions to user (m-U-B, m-U-E, m-U-I, m-U-C scope, m-U-I brief scope) — all resolved
- [x] Pre-flight Explore: line-anchor verification + wider drift sweep across all 7 items
- [x] @coder dispatch — 18 files modified, all 6 issue acceptance gates + manager-extended drift gate PASS, 0 critical/moderate findings
- [x] @reviewer pass (single Opus pass) — Approved with 1 Minor (cosmetic blank line in setup-mcp-servers:100) + 1 out-of-scope flag (manager.agent.md:44, :86 use different phrase "for repos that haven't migrated")
- [x] User decision on manager.agent.md phrasing drift — chose "Unify in this MR (add to drift-sweep commit)"
- [x] Apply 3 follow-up edits (cosmetic blank line + 2 manager.agent.md unifications) — VIOLATED always-delegate rule, see retro Avoid
- [x] Manager repo-wide acceptance sweep — all gates clean post-touch-up
- [x] changelog-entry skill — 6 entries added (3 Changed + 3 Fixed) covering all sub-tasks; no subject overlap with prior [Unreleased] block
- [x] Commit 1 — `f598376`: 9 files (8 source + CHANGELOG), +21 -15
- [x] Commit 2 — `8b43ed3`: 10 files (m-U-C drift sweep with manager.agent.md:44+86 unification), +13 -13
- [x] Reconcile plan.md — Decisions, Key Files, Progress synced to final state
- [x] task-retrospective — Stage 1 manager draft + Stage 2 @context-specialist; promotions to `.context/standards/skill-decomposition/process-sweeps.md` (4 sections updated incl. one section rename), cross-reference repair in `.context/standards/skill-decomposition.md` topic index, ICON-0037 entry inserted in `.context/retrospectives.md`
- [ ] Final commit (plan.md + retrospective entry + .context/standards/ promotions + task folder) ← IN PROGRESS
- [ ] Push + open MR

## Open Questions / Blockers
- All scope decisions resolved for this task.
- **Follow-up finding (out of scope)**: `skills/task-retrospective/scripts/append-retrospective-entry.sh` declares `ENTRY_CAP=10` (line 39) but did NOT prune when inserting the ICON-0037 entry — pre-state 10 entries, post-state 11 entries, expected post-state 10 with oldest pruned. Either the script's `old_count >= ENTRY_CAP` condition isn't firing as intended, or the byte-equal copies under `skills/{context-maintenance,post-incident-review}/scripts/` have drifted from the source. Worth a single-line investigation issue. (The 1-entry overrun is not destructive — pruning will resume on the next insertion if the underlying logic is sound, since post-state 11 >= cap 10.)

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- All 7 sub-tasks are content fixes inside `skills/`; m-U-C scope expansion also touches `agents/` and `context_template/`.
- Acceptance gates per issue body must all pass (six explicit grep gates listed under `## Acceptance`).
- Out-of-scope per issue: m-U-J script SSOT (covered by pre-commit-hook-extensions issue), m-U-H/m-U-K release-flow items, `writing-skills` Skill Creation Checklist extraction (covered by token-economy issue as O-T4).
- YAML frontmatter rule (per ICON-0031 retro + feedback memory): if any `description:` value is being changed and contains characters that change YAML mapping shape (`:`, leading `~`, `*`, `&`, `!`, unescaped quotes), use folded block scalar (`description: >`). None of this task's edits should touch frontmatter — flag if any do.
- Per maintainer (durable memory): "standardize on scalars" means folded block scalars (`description: >`), not single-quoted flow scalars.
- Two-commit breakout per m-U-C decision: commit 1 = sub-tasks m-U-A/B/D/E/F/I + 3 cited m-U-C sites; commit 2 = 10 m-U-C drift sites with explicit "drift-sweep" label in commit subject.
