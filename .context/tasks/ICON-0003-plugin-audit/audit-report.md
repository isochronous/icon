# ICON Plugin Audit Report — ICON-0003 (First Standalone-Repo Audit)

**Task:** ICON-0003
**Date:** 2026-05-14
**Plugin version audited:** `1.15.3` on `main` (standalone repo; post-`254ff7c` marketplace → standalone split)
**Scope:** 9 agents, 48 skills, 4 commands, 2 SessionStart hooks, 1 repo git hook, 1 plugin manifest (`.claude-plugin/plugin.json`), 1 MCP registry (`.mcp.json`), 1 maintainer-only release skill at `.claude/skills/release-plugin/`.
**Method:** 6 parallel research agents per domain → synthesis. Baseline for delta comparisons: **MKT-0087** (2026-04-29, marketplace repo, "POOR for release"). Each sub-agent received a `plan.md`-level "Layout delta vs marketplace baseline" translation table to handle the `plugins/ICON/...` → repo-root path shift.
**Raw findings:** `./research/01-agents.md`, `02-process-skills.md`, `03-context-specialist-init.md`, `04-utility-skills.md`, `05-infrastructure.md`, `06-cross-cutting.md`.
**Framing:** User directive (verbatim): *"We just moved this plugin from a marketplace repo into its own repo, which involved a bit of restructuring and path updates, as well as separating out relevant .context data, so those areas may need special attention."*

---

## Executive Summary

**Overall health: GOOD.** The marketplace → standalone-repo split was non-destructive at the domain level and net-positive at the verdict level: −2 Critical (both MKT-0087 release-blockers fixed by MKT-0088 and verified to have survived the split), no Critical regressions, and the on-disk plateau of carry-forward Moderates and Minors is essentially unchanged.

The remaining issues cluster into three themes:

1. **Split-induced drift inside the audit infrastructure itself.** The `plugin-audit` skill — the very tool that produced this report — still references the marketplace `plugins/<plugin>/...` layout in its SKILL.md and all six dispatch briefs (30+ stale placeholders). This audit compensated via a `plan.md`-level translation table, but the next invocation without such a workaround will silently mis-baseline. This is the single highest-leverage net-new defect and is documented as both **M-U1** (domain-specific) and **M-CC2** (cross-cutting self-verification framing). It is also a concrete instance of the broader **M-CC1 sweep-incompleteness pattern**.
2. **A carry-forward plateau across four audit cycles.** ~20 Moderate/Minor findings now persist across MKT-0046 → MKT-0063 → MKT-0077 → MKT-0087 → ICON-0003. Brief 04's closing audit-process observation is apt: continued re-surfacing as Minors is no longer the right tiering. Recommend a **watch/accepted** re-tier in the user-driven follow-up step rather than another audit cycle.
3. **A previously-deferred release-flow doc conflict is now an active defect.** `release-plugin/SKILL.md:105-108` ("insert below `[Unreleased]`") contradicts `.context/workflows/changelog.md:11` ("rename `[Unreleased]` to `[X.Y.Z]`"). The v1.15.3 release proves the workflow doc is operationally correct; SKILL.md is the diverged copy. ICON-0001's retrospective named this and shipped without filing the follow-up — the plate is empty (M-1).

### Scorecard

| Rule | Verdict | Movement vs MKT-0087 |
|------|---------|----------------------|
| RULE 1 — PROMPT vs SKILL SEPARATION | ✅ PASS | Held |
| RULE 2 — SINGLE SOURCE OF TRUTH | ⚠️ WARNING | Held — common-constraints 9× duplication unchanged; net-new SSOT violation surfaced inside the audit skill itself (M-U1) |
| RULE 3 — SUB-AGENT JOB CLARITY | ✅ PASS | Held — MKT-0084 sub-agent scoping verified holding; the `using-skills` mandate fires only on dispatcher invocations, not on each sub-agent dispatch |
| RULE 4 — SKILL RESPONSIBILITY | ⚠️ WARNING | **Improved (was FAIL).** CC-C2 (`create-iconrc` hardcoded relative path) confirmed fixed and survived split. WARNING retained because M-U1 (plugin-audit skill broken against its own layout) is a new skill-responsibility defect. |
| RULE 5 — ORCHESTRATOR CLARITY | ✅ PASS | **Improved (was FAIL).** CC-C1 (orchestrator entry-point detection) confirmed fixed in all three init orchestrators and survived the split. M1 (`mode: upgrade` agent-vs-orchestrator contradiction) remains and keeps Rule 4/5 close to the boundary, but the dominant orchestration regression from MKT-0087 is gone. |

(The 5-rule scorecard borrows the framework from `agent-evaluation/SKILL.md`. Cross-reference for rule definitions — do not duplicate them here.)

### Top-line counts

- **Defects**: **0 Critical**, **12 Moderate**, **42 Minor** (total **54**).
- **Improvement Opportunities**: **38** spanning Token Efficiency / Discoverability / Consolidation / Missing Skills / Self-Verification.
- **MKT-0087 delta**: **~8 items fixed** (incl. both Criticals); **~36 still-present-or-partial** (the carry-forward plateau); **~9 net-new** drift patterns. **Net Critical movement: −2.**

*Dedup notes:* (a) Brief 06 M-CC2 and Brief 04 M-U1 describe the same on-disk defect (plugin-audit skill unmigrated) with different framings; counted once below as M-U1 with the cross-cutting framing folded into the Improvement Opportunities. (b) Brief 06 m-CC2 and Brief 04 m-U8 describe the same on-disk defect (`icon-status:161` broken `/release-plugin` suggestion); counted once. (c) Brief 06 M-CC1 is a structural observation wrapping three concrete defects in Briefs 02 / 04 / 05 (M-P2, M-U1, M-1) — each retained in its own domain; M-CC1 is recorded as a structural pattern in the Open Questions and the Improvement Opportunities, not as a fourth Moderate.

---

## Critical Findings (0)

None observed. Both MKT-0087 Criticals (CC-C1 init-orchestrator entry-point detection, CC-C2 `create-iconrc` hardcoded template path) are confirmed fixed and survived the repo split. See `research/03-context-specialist-init.md:134-135` for verification details.

---

## Moderate Findings (12)

*Full rationale and file:line references in the research files. This section is a consolidated inventory for triage.*

### Audit infrastructure (1)

| # | Finding | Location |
|---|---------|----------|
| M-U1 | **`plugin-audit` skill itself was not migrated when the plugin split out of the marketplace.** 30+ `plugins/<plugin>/...` placeholders across SKILL.md + 6 briefs + `synthesis-template.md`. The audit-orchestration tooling assumes the marketplace layout; Phase 1 baseline commands return zero-counts in this repo. Compensated for THIS audit by `plan.md` translation table — a task-level workaround, not a skill-level fix. | `skills/plugin-audit/SKILL.md:40-45,:104`; `skills/plugin-audit/briefs/01-agents.md:5,9,12,13`; `skills/plugin-audit/briefs/02-process-skills.md:9,12`; `skills/plugin-audit/briefs/03-context-specialist-init.md:11,12,15`; `skills/plugin-audit/briefs/04-utility-skills.md:13,16`; `skills/plugin-audit/briefs/05-infrastructure.md:14-36`; `skills/plugin-audit/briefs/06-cross-cutting.md:15-19`; `skills/plugin-audit/synthesis-template.md:122` |

### Agents (3)

| # | Finding | Location |
|---|---------|----------|
| M-A1 | **Carry-forward.** Planner Output Format has 3 code fences (odd count → imbalance). | `agents/planner.agent.md:45,:60,:87` |
| M-A2 | **Carry-forward.** Common-constraints 24-line block duplicated byte-identical (SHA `b3ac3bff…ade885`) across all 9 agents (~216 lines repo-wide). Largest single always-loaded trim candidate; see IO-T1. | All 9 `agents/*.agent.md` (sourced from `shared/common-constraints.md:1-21`) |
| M-A3 | **Carry-forward.** Architect Anti-Rationalization table has 4 abstraction-family rows that share the same rationalization shape. | `agents/architect.agent.md:103-117` |

### Process skills (2)

| # | Finding | Location |
|---|---------|----------|
| M-P1 | **Carry-forward — 3rd audit cycle.** `design-first` Step 3 body still says "This is a hard gate:" contradicting the description / When-to-Use / When-to-Skip advisory framing. | `skills/design-first/SKILL.md:103` vs `:4`, `:14-16`, `:26-31` |
| M-P2 | **Carry-forward — 3rd audit cycle. Concrete instance of M-CC1 sweep-incompleteness pattern.** `task-plan-phase-completion` invokes `context-maintenance` directly; `task-retrospective` routes `.context/` writes through `@context-specialist`. Empirical resolution (ICON-0001 used the specialist path per `.context/retrospectives.md:6-9`) never landed on disk. | `skills/task-plan-phase-completion/SKILL.md:46,:80-81` vs `skills/task-retrospective/SKILL.md:104-109` |

### Context-specialist + init (3)

| # | Finding | Location |
|---|---------|----------|
| M-I1 | **Carry-forward.** Orchestrator dispatch prompts say "Load and execute `upgrade-repo` skill" for `mode: upgrade`, but agent body routes `mode: upgrade` → `context-specialist-create` (which loads the fresh-init impl skills, not `upgrade-repo`). | `agents/context-specialist.agent.md:46,:68-71`; `skills/initialize-monorepo/SKILL.md:222-228`; `skills/initialize-workspace/SKILL.md:230-235`; `skills/initialize-multimodule/SKILL.md:202-204` |
| M-I2 | **Carry-forward.** `initialize-multimodule` lacks the feature-branch + per-repo MR parity that the other two orchestrators enforce. Sub-projects may commit directly to integration branches. | `skills/initialize-multimodule/SKILL.md:26-73` (guard only), `:172-216` (dispatch without feature_branch/git_root); missing post-Step-6 push/MR phase. |
| M-I3 | **Net-new.** `initialize-multimodule` frontmatter is missing `disable-model-invocation: true` while its two sibling orchestrators carry it. Model can still auto-invoke `initialize-multimodule` under the right surface description, bypassing the `/icon-init` entry point. | `skills/initialize-multimodule/SKILL.md:10-11` vs `skills/initialize-monorepo/SKILL.md:9` and `skills/initialize-workspace/SKILL.md:11` |

### Utility skills (1)

| # | Finding | Location |
|---|---------|----------|
| M-U2 | **Carry-forward — 3rd audit cycle.** `writing-skills` still instructs authors to register skills in a `using-skills` Common Workflows table that was dropped in MKT-0084 (verified absent from `using-skills/SKILL.md`). Authors silently skip the step or re-introduce the dropped table. | `skills/writing-skills/SKILL.md:230-232,:528-530` |

### Infrastructure (2)

| # | Finding | Location |
|---|---------|----------|
| M-1 | **Net-new (previously-deferred retrospective finding). Concrete instance of M-CC1 sweep-incompleteness pattern.** Release-flow docs disagree on CHANGELOG mutation shape. `.context/workflows/changelog.md:11` says "rename `[Unreleased]` to `[X.Y.Z]` and add fresh `[Unreleased]` above"; `.claude/skills/release-plugin/SKILL.md:105-108` says "insert new entry below `[Unreleased]` block." The v1.15.3 release proves the workflow doc is operationally correct; SKILL.md is the diverged copy. ICON-0001 retro flagged it and shipped without filing the follow-up (`.context/retrospectives.md:9`). | `.context/workflows/changelog.md:11` vs `.claude/skills/release-plugin/SKILL.md:105-108` |
| M-2 | **Carry-forward — 3rd audit cycle (re-tiered to Moderate).** `release-plugin/SKILL.md:258` Error Conditions row references `sed` directly, but Step 6 (`:130-146`) now delegates to `bump-versions.sh`. The maintainer reading the Error Conditions section is pointed at an action layer they no longer perform. | `.claude/skills/release-plugin/SKILL.md:258` vs `:130-146` |

---

## Minor Findings (42)

Condensed list. Details in research files.

**Agents (7):** manager hardcoded "3+/3 failures" threshold (`agents/manager.agent.md:182,:247`); coder Discretionary tier thin (`coder.agent.md:57-59`); researcher Discretionary overlap with Process Step 1 (`researcher.agent.md:95-97` vs `:22`); PM Session Start lacks `common-constraints` acknowledgement vs manager's (`product-manager.agent.md:14-16` vs `manager.agent.md:32-33`); PM Session Start positioned after `## When to Invoke` despite "MANDATORY FIRST ACTION" wording (`product-manager.agent.md:10-16`); no agent references `mr-discipline` (post-MKT-0086 rename); manager Session Start step 1 ("note skills, do not invoke yet") vs Default-tier step-7 trigger ("invoke @researcher at Session Start") wording tension (`manager.agent.md:32` vs `:233`).

**Process skills (6):** `verification-checklist` Gate headings missing the `skill-name:` prefix MKT-0083 standardized (`verification-checklist/SKILL.md:46,:49,:55,:62`); 5 phase skills share identical frontmatter description (`task-plan-phase-*/SKILL.md:3-4`); rolling-log "10–15" prose drift vs script-canonical "15" (`task-plan-phase-completion:63`, `task-retrospective:91`); `task-retrospective` two-path script invocation (line 91 vs line 113); `task-plan-phase-completion` partial retro restatement (`:48-63`); **net-new (n-P1):** 5 phase skills duplicate "Does NOT cover" footers that negate the positive Relationship lists immediately above (`task-plan-phase-*/SKILL.md` Relationship sections + footers).

**Context-specialist + init (10):** `prune-context.sh` template still has 8 `2>/dev/null`/`>/dev/null` instances (`context_template/.../prune-context.sh:26,:43,:44,:67,:71,:90,:102,:106`); `upgrade-repo:124` `> /dev/null 2>&1` self-reference violation; `find-context-template` PowerShell `\` vs Bash `/` separator literals (`find-context-template/SKILL.md:33-34,:40-42,:48,:54`); `find-context-template` description doesn't list callers (`:3-4` vs `:10-12`); `resolve-repo-context` schema example omits fallback path (`:99` vs `:121`); `context-specialist-create:11` claims `mode: upgrade` support but body has no upgrade branch (pairs with M-I1); `context-specialist.agent.md:128` vs `:134-135` doubled scope rule inside/outside common-constraints; `initialize-monorepo` vs `initialize-workspace` frontmatter key-order divergence; hardcoded DataScan/.NET/WMS examples across 4 init skills; `upgrade-repo` Phase 3 vague drift-trigger spec while 3 orchestrators duplicate the precise version.

**Utility skills (9):** `jira-story:32,:35` Copilot-CLI `create` literal; `setup-mcp-servers:100,:102` "Choose one option, A recommended" but only Option A documented; `ecological-impact:86,:221` example references `Claude Sonnet 4.6` (stale); `ecological-impact` annual-projection mixes `×12` and `×1,200` multipliers without explicit basis annotation; `rfc:139` Step 3 design-history paragraph mid-schema; `synthesis-template.md:122` line-coupled `MKT-0046 audit-report.md:343-345` cross-reference; `writing-skills` exceeds its own self-imposed length cap (549 lines vs 500-line cap; 3,262 words vs 500-word target); **net-new (m-U8 / m-CC2):** `icon-status:161` suggests `/release-plugin` to end users but `release-plugin` is at `.claude/skills/` (maintainer-only, not shipped); **net-new (m-U9):** `post-incident-review/SKILL.md:123` 2-location SSOT risk on the embedded `append-retrospective-entry.{sh,ps1}` scripts; **net-new (m-U10):** `start-worktree/SKILL.md:87,91,111,162` "not yet migrated" framing dated post-MKT-0089.

**Infrastructure (7):** both manifests lack `$schema` (`.claude-plugin/plugin.json`, `.mcp.json`); **net-new (m-2):** `hooks/inject-manager-role.ps1` mode 644 vs `.sh` mode 755 (cosmetic — pwsh-invoked, not exec-bit dependent); `inject-manager-role.{sh,ps1}` parity test missing; **net-new (m-4):** `.claude/skills/release-plugin/scripts/format-slack.sh` runs without `set -euo pipefail`; `bump-versions.sh:42` OLD-version parse uses unbounded `grep '"version"'`; release-skill frontmatter description has empty caller-list (Pattern 3 N/A — user-invocable, no agent caller); **net-new (m-7):** `release-plugin/SKILL.md:32` doesn't guard against "not a git repo" before `git --no-pager branch --show-current`.

**Cross-cutting (1 net-new beyond dedupes):** **m-CC1** — Onboarding-surface gap: no `GETTING_STARTED.md` / `BEST_PRACTICES.md`; the 4 `commands/*.md` files are all Claude-Code-only role/hook commands. Copilot CLI users post-install have zero slash-command entry points beyond `/icon-init` (a skill, not a command). `README.md:34-49` intent index does the heavy lifting alone. **m-CC3** — CHANGELOG retains marketplace `plugins/ICON/...` paths inside historical release notes (40+ hits); correct historical preservation but informational signal for any future `git grep` lint design.

---

## Improvement Opportunities (38)

*Items below are positive-design suggestions. None are defects; each is a judgment call the user can accept, defer, or reject.*

### Category 1 — Token Efficiency / Slim the Always-Loaded Surface (3)

**O-T1 · Single-source the common-constraints inclusion.** The 9× byte-identical 24-line block (~216 lines / ~2,832 words repo-wide) collapses to a single `<!-- common-constraints: see shared/common-constraints.md -->` line per agent. The design decision is between *include at author time* (current) and *include at load time* (proposed). Closes M-A2. Largest single always-loaded trim. **Effort: medium. Impact: high.** (Brief 01 IO-1 + Brief 06 IO-CC1.)

**O-T2 · Audit the always-loaded surface end-to-end and decide an explicit budget.** Dispatcher session loads ~10,000+ words: manager (288 lines / 3,951 words) OR PM (268 / 2,650) + shared common-constraints (354 words) + 9× inlined common-constraints (~3,186 words) + `using-skills` mandate (90 / ~1,100) + one sub-agent body (~1,500). ~32% of that is the M-A2 duplication. Formal inventory + trim pass. **Effort: medium. Impact: high.** (Brief 06 IO-CC2.)

**O-T3 · Tighten `writing-skills` to its own self-imposed length cap.** 549 lines vs 500; 3,262 words vs 500 target. Long-standing self-reference violation. **Effort: medium. Impact: low** (rarely-loaded skill). (Brief 04 m-U7.)

### Category 2 — Discoverability / Onboarding UX (4)

**O-D1 · Decide policy on `icon-status:161` `/release-plugin` suggestion.** Three options at Brief 04 IO-U4: (a) drop the suggestion entirely; (b) gate behind a maintainer-repo heuristic; (c) re-ship `release-plugin` to consumers. Recommend (a) — `release-plugin` is by-design maintainer-only post-split. Closes m-U8 / m-CC2. **Effort: trivial. Impact: medium.** (Brief 06 IO-CC4.)

**O-D2 · Add a `commands/index.md` or expand `README.md § "What do you want to do?"` to enumerate all user-invocable slash entry points across Copilot CLI + Claude Code.** Closes m-CC1 onboarding gap. **Effort: trivial. Impact: medium.** (Brief 06 IO-CC3.)

**O-D3 · Promote PM Session Start to match manager symmetry.** Reorder before `## When to Invoke` (m-A5) and add a one-line `common-constraints` acknowledgement (m-A4). 4-line move + 2-line add. **Effort: trivial. Impact: low.** (Brief 01 IO-4 + IO-5.)

**O-D4 · Add a balanced-code-fence lint to pre-commit.** 5-line `grep -c '^\`\`\`'` script over `agents/*.agent.md` + `skills/*/SKILL.md` would have caught M-A1 at commit time. **Effort: trivial. Impact: medium.** (Brief 01 IO-2.)

### Category 3 — Consolidation / Structural Simplification (8)

**O-S1 · Migrate the `plugin-audit` skill to standalone-repo layout.** Closes M-U1. Regex sweep across `plugin-audit/SKILL.md`, all 6 `briefs/*.md`, and `synthesis-template.md`: replace every `plugins/<plugin>/` with the repo-root path (or a `${PLUGIN_ROOT}` template variable defaulting to `.`). Option (a) — direct repo-root paths — is the safe path; the skill defaults to the ICON plugin per `SKILL.md:104` and there is no current evidence of cross-plugin reuse. **Effort: medium. Impact: medium (closes the only Moderate net-new finding; makes the audit skill self-sufficient for future runs).** (Brief 04 IO-U1.)

**O-S2 · Single-source the entry-point detection block across the three init orchestrators.** Each orchestrator carries an identical inline `[ -f "$dir/.claude/claude.md" ] || [ -f "$dir/.github/copilot-instructions.md" ]` block (and `initialize-multimodule` has a fourth variant in its discovery loop). MKT-0088 had to fix this in 3 places at once. A shared bash function in `context_template/context/workflows/` (sourced by each orchestrator) closes the recurring drift surface. **Effort: medium. Impact: high (structural).** (Brief 03 O5.)

**O-S3 · Reconcile `mode: upgrade` semantics.** Either route `mode: upgrade` directly to `upgrade-repo` from the agent body and drop the `upgrade` value from `context-specialist-create:11`'s mode list, OR drop `mode: upgrade` from the agent's table and have orchestrators stop passing it. Closes M-I1 + m6. **Effort: low. Impact: medium.** (Brief 03 O1.)

**O-S4 · Promote `initialize-multimodule` to feature-branch + per-repo MR parity.** Mirror `initialize-workspace` Step 1/7 pattern across each sub-repo (`git -C "$sub_root"` loops). Closes M-I2. **Effort: medium. Impact: medium.** (Brief 03 O2.)

**O-S5 · Reconcile release-flow CHANGELOG-shape docs.** Rewrite `release-plugin/SKILL.md` Step 5 (`:105-108`) to match `workflows/changelog.md:11`'s "rename `[Unreleased]` + add fresh empty `[Unreleased]` above" procedure. v1.15.3 release proves the workflow doc is operationally correct. Closes M-1 and discharges the unfiled ICON-0001 follow-up. **Effort: trivial. Impact: high (closes the only retrospective-flagged-but-unfiled item).** (Brief 05 O-1.)

**O-S6 · Extract the Phase 3 drift-trigger sampling spec into `upgrade-repo` Phase 3 body.** Replace three verbatim copies of the "spot-check 5 random items, threshold 2/5" rule with a single canonical paragraph; each orchestrator's dispatch prompt becomes one-line. Closes m10. **Effort: low. Impact: low.** (Brief 03 O3.)

**O-S7 · Sweep `2>/dev/null` / `>/dev/null` from `prune-context.sh` template + `upgrade-repo:124`.** The agent's own Constraints block bans these patterns and instructs the agent to scan-and-remove them; the artifacts it ships contain them. Replace with `|| true` / `|| echo ""` tails (the ICON-0002 lesson). Closes m1 + m2. **Effort: low. Impact: low.** (Brief 03 O4.)

**O-S8 · Collapse phase-skill "Does NOT cover" footers or align wording with positive Relationship lists.** 5 sites with redundancy + terminology drift between negation ("@coder dispatch") and positive list ("implementation dispatch"). Closes n-P1. **Effort: low. Impact: low.** (Brief 02 O-8.)

### Category 4 — Missing Skills / Workflow Gaps (3)

**O-M1 · Consider a maintainer-orientation surface — `MAINTAINING.md` or `.context/workflows/release-flow.md`.** Post-split the release flow is invisible to consumers (correct by design) but also unprotected by the plugin's audit infrastructure (Brief 05 SO at `research/05-infrastructure.md:79`). Doc the M-1 CHANGELOG-shape decision, the M-2 Error Conditions row, and the M-CC2 self-verification gap in one place. **Effort: low-to-medium. Impact: medium.** (Brief 06 IO-CC6.)

**O-M2 · Add a manifest-schema validator + `$schema` declarations.** O-2 from Brief 05: a 3-5-line `python3 -m json.tool` (or `jq empty`) check wired into `.githooks/post-commit`. O-3 from Brief 05: add `$schema` to both manifests (`.claude-plugin/plugin.json`, `.mcp.json`). Closes m-1; adds first CI-like gate post-split. **Effort: medium. Impact: medium.** (Brief 05 O-2 + O-3.)

**O-M3 · Add a dry-run flag + monotonicity check to `bump-versions.sh`.** Closes Common Check Pattern 4 (operational defensiveness on the only write-side script in the release flow). 4 lines for `--dry-run`; 6 lines for `semver-greater-than-prev` check. **Effort: low. Impact: medium.** (Brief 05 O-4 + O-5.)

### Category 5 — Self-Verification / Automate the Retrospective Wisdom (3)

**O-V1 · Wire a `plugins/<plugin>/` lint gate to commit time, not audit time.** 4-line bash script run by `.githooks/post-commit` (or new pre-commit) that excludes `CHANGELOG.md` (historical paths) and `plugin-audit/*` (until O-S1 lands) and exits 1 on any other match. Closes the dominant net-new drift vector from the split. **Effort: trivial. Impact: high.** (Brief 06 IO-CC7.)

**O-V2 · Promote the standing "Skill Evolution Cross-Surface Sweep" rule from SKILL.md-unit to skill-folder-unit.** 6 marketplace retros + 3 fresh on-disk instances now share the "sweep visits primary surface, stops short of companion files" shape. The rule itself works; the enforcement layer doesn't reach companion files. Rule extension + lint script (the O-V1 hook can carry it). Closes M-CC1 systemically. **Effort: low. Impact: high.** (Brief 06 IO-CC5.)

**O-V3 · Bash/PowerShell parity test for the SessionStart hooks.** Round-trip both `inject-manager-role.{sh,ps1}` outputs to byte-identical JSON via a CI-like local test. Closes m-3 (carried since MKT-0087). **Effort: medium. Impact: low.** (Brief 05 SO + m-3.)

### Category 6 — Other (17)

*Items below are the long tail — cosmetic carry-forward improvements from Briefs 01–05 that the user may choose to batch into a single hygiene sweep or defer indefinitely. Numbered O-X1 through O-X17 for stable triage reference.*

- **O-X1** (Brief 01 IO-3) — Soften manager "3+ attempts" magic-number to named threshold. Closes m-A1.
- **O-X2** (Brief 01 IO-6) — Promote architect AR table to "Premature Abstraction" + "Premature Scaling" sub-tables. Closes M-A3.
- **O-X3** (Brief 02 O-1) — Soften `design-first` Step 3 body to advisory framing. Closes M-P1.
- **O-X4** (Brief 02 O-2) — Settle delegation path for `.context/` writes on the specialist-routed side. Closes M-P2. *(Concrete instance of M-CC1.)*
- **O-X5** (Brief 02 O-3) — Apply heading-prefix convention to `verification-checklist` Gates. Closes m-P1.
- **O-X6** (Brief 02 O-4) — Add trigger differentiators to the 5 phase-skill descriptions. Closes m-P2.
- **O-X7** (Brief 02 O-5) — Sweep "10–15" → "15" in the two prose sites. Closes m-P3.
- **O-X8** (Brief 02 O-6) — Reconcile `task-retrospective` script-path canonicality. Closes m-P4.
- **O-X9** (Brief 02 O-7) — Inline the script-ownership meta-explanation in `task-retrospective:113`. Closes part of m-P4.
- **O-X10** (Brief 03 O6) — Add `disable-model-invocation: true` to `initialize-multimodule` + normalize key order across all three orchestrators. Closes M-I3 + m8.
- **O-X11** (Brief 04 IO-U2) — Sweep `writing-skills` registration instructions. Closes M-U2. *(Trivial-effort 3rd-cycle carry; the value of letting it carry a 4th cycle is questionable.)*
- **O-X12** (Brief 04 IO-U3) — Refresh `ecological-impact` to current model + add explicit projection-basis annotation. Closes m-U3 + m-U4 in one PR.
- **O-X13** (Brief 04 IO-U5) — Defer rfc + post-meeting + sprint-goals consolidation; record as watch-pattern.
- **O-X14** (Brief 04 IO-U6) — Lint or refactor the 2-location `append-retrospective-entry.{sh,ps1}` SSOT. Closes m-U9.
- **O-X15** (Brief 05 O-1) — *(already promoted to O-S5 above.)*
- **O-X16** — Hardcoded DataScan/.NET/WMS examples sweep across 4 init skills. Closes m9. *(May be intentional — these are the ICON maintainer's reference shapes; mention only if making the skill cross-organization usable.)*
- **O-X17** — Add JSON-validity check to the existing `.githooks/post-commit` (subsumes / parallels O-M2; can land as one change).

---

## MKT-0087 Delta (Comparison with 2026-04-29 baseline)

### Fixed since MKT-0087 (8 items, including both Criticals)

- **CC-C1 (Critical, init-orchestrator entry-point detection)** — fixed by MKT-0088; survived split. Verified in all three orchestrators (`research/03-context-specialist-init.md:134`).
- **CC-C2 (Critical, `create-iconrc` hardcoded template path)** — fixed by MKT-0088; survived split. Verified (`research/03-context-specialist-init.md:135`).
- **MKT-0087 M2 / MKT-0077 M-I1 (context-specialist agent frontmatter "three modes" / "Phase 1 and 2")** — fixed by MKT-0088. Verified at `agents/context-specialist.agent.md:5,:8-9,:46,:62-66`.
- **MKT-0087 M-U1 (release-plugin manager-only guard)** — out-of-scope post-split (release-plugin is maintainer-only at `.claude/skills/`).
- **MKT-0087 m-U6 / m-U7 / m-U10 / m-U11 (release-plugin-beta + ICON-beta CHANGELOG)** — out-of-scope post-split (`-beta` channel does not exist).
- **MKT-0087 m-1 marketplace.json / .gitlab-ci.yml / 7-manifest $schema gap** — out-of-scope post-split (artifacts do not exist in this repo). Note: the **2 remaining manifests** still lack `$schema` (Brief 05 m-1).
- **MKT-0087 m-9 README `mr-discipline` omission** — fixed; `README.md:194` lists it (`research/05-infrastructure.md:96`).
- **MKT-0087 O-2 (orphan ICON-beta CHANGELOG)** — out-of-scope post-split.

### Still present or partial (~36 items)

- **Agents (10 carry-forwards):** M-A1, M-A2, M-A3, m-A1 through m-A7. None changed.
- **Process skills (7 carry-forwards):** M-P1, M-P2, m-P1 through m-P5. None changed. Third audit cycle for each.
- **Context-specialist + init (12 carry-forwards):** M-I1 (= MKT-0087 M1), M-I2 (= MKT-0087 M3), m1 through m10. None changed.
- **Utility skills (7 carry-forwards):** M-U2, m-U1 through m-U7. None changed. Third audit cycle for the user-groomed-deferral cluster.
- **Infrastructure (4 carry-forwards):** m-1 (`$schema` missing), M-2 (release-plugin Error Conditions `sed`, re-tiered to Moderate), m-3 (inject-manager-role parity test missing), m-5 (`bump-versions.sh` regex hygiene — same root class as MKT-0087 m-3 with a different shape).

### Net-new drift since MKT-0087 (~9 items)

1. **M-U1 — `plugin-audit` skill itself was not migrated** (30+ stale `plugins/<plugin>/...` placeholders). *The highest-leverage net-new defect.*
2. **M-I3 — `initialize-multimodule` missing `disable-model-invocation: true` frontmatter key** (sibling orchestrators have it).
3. **M-1 — Release-plugin `SKILL.md` ⇄ `workflows/changelog.md` doc conflict** (workflow doc created in ICON-0001 and conflict named in retro but unfiled).
4. **m-U8 / m-CC2 — `icon-status:161` suggests now-unshipped `/release-plugin`** (release-plugin moved to `.claude/skills/` in the split).
5. **m-U9 — `post-incident-review/scripts/append-retrospective-entry.{sh,ps1}` 2-location SSOT risk** (script lives in two skill folders).
6. **m-U10 — `start-worktree` "not yet migrated" framing dated post-MKT-0089.**
7. **Brief 05 m-2 / m-4 / m-7 — Hook + script asymmetries newly visible post-split** (`.ps1` mode 644 vs `.sh` 755; `format-slack.sh` no strict-mode; release-plugin no git-repo guard).
8. **n-P1 — 5 phase skills' "Does NOT cover" footers are redundant with the positive Relationship lists above them** (existed pre-split; not flagged until now).
9. **m-CC1 — Onboarding gap newly visible post-split: no `GETTING_STARTED.md` / `BEST_PRACTICES.md`, 4 commands all Claude-Code-only.**

### Audit-process observation

The standalone-repo split was the right call: the verdict moved from POOR/release-blocking to GOOD, and the infrastructure surface is materially smaller and easier to reason about. The split's two costs are visible: (1) **the audit infrastructure didn't migrate itself** — M-U1 is the meta-finding, and the ICON-0003 `plan.md` translation table is the workaround that this audit relied on; (2) **CI-like gates that the marketplace ran in `.gitlab-ci.yml` now live at the maintainer's discretion** — Brief 05 surfaces this as a structural observation, not a defect, but it explains why several net-new minor findings ($schema missing, `format-slack.sh` strict-mode, release-skill git-repo guard) all cluster in the release-flow area.

The carry-forward plateau across four audit cycles is the more interesting signal. **Brief 04's recommendation to re-tier ~7 of the long-standing user-groomed deferrals to "watch / accepted" is supported by the cross-audit evidence:** continued re-surfacing as Minors creates audit fatigue without producing the fix. Open Question 1 (below) captures this.

---

## Prioritized Fix Tiers

### Tier 1 — Fix immediately (correctness risk)

None. No Critical defects; the two release-blockers from MKT-0087 are confirmed fixed and survived the split. The plugin is **shippable as-is** by the MKT-0087 standard.

### Tier 2 — Short-term cleanup (high leverage, low-medium effort)

- **O-S1 — Migrate `plugin-audit` skill to standalone-repo layout** (closes M-U1, the only Moderate net-new in scope-applicable defects). Medium effort. The next plugin-audit invocation should not need a plan-level translation table.
- **O-S5 — Reconcile `release-plugin/SKILL.md` Step 5 with `workflows/changelog.md:11`** (closes M-1; discharges the unfiled ICON-0001 retrospective follow-up). Trivial effort. The next release run should not be ambiguous.
- **O-V1 — Wire a `plugins/<plugin>/` lint gate to `.githooks/post-commit`** (closes the recurrence vector for M-CC1 sweep-incompleteness). Trivial effort.
- **O-V2 — Promote "Skill Evolution Cross-Surface Sweep" from SKILL.md scope to skill-folder scope** (closes M-CC1 systemically). Low effort + the O-V1 hook carries it.

### Tier 3 — Medium-term structural refactors (higher effort, higher payoff)

- **O-T1 — Single-source common-constraints inclusion** (closes M-A2 9× duplication, largest always-loaded trim).
- **O-S2 — Single-source the init-orchestrator entry-point detection block** (closes a recurring drift surface MKT-0088 had to fix in 3 places at once).
- **O-S3 — Reconcile `mode: upgrade` agent-vs-orchestrator semantics** (closes M-I1 + m6).
- **O-S4 — Promote `initialize-multimodule` to feature-branch + per-repo MR parity** (closes M-I2).
- **O-X10 — Add `disable-model-invocation: true` to `initialize-multimodule` + normalize key order across all three orchestrators** (closes M-I3 + m8 in one frontmatter edit).

### Tier 4 — Sweep-and-batch hygiene (low-impact carry-forwards)

The Tier 4 batch is a single hygiene PR that closes ~15 long-standing minors:

- **O-X11 — Sweep `writing-skills` registration instructions** (closes M-U2, third cycle).
- **O-X12 — Refresh `ecological-impact` to current model + add projection-basis annotation** (closes m-U3 + m-U4).
- **O-X5 / O-X6 / O-X7 / O-X8** — heading-prefix sweep on `verification-checklist`; phase-skill description triggers; "10–15" → "15" sweep; `task-retrospective` script-path canonicalization.
- **O-S7 — Sweep `2>/dev/null` from `prune-context.sh` template + `upgrade-repo:124`** (closes m1 + m2).
- **O-S8 — Collapse / align phase-skill "Does NOT cover" footers** (closes n-P1).
- **O-D1 — Drop the `icon-status:161` `/release-plugin` suggestion** (closes m-U8 / m-CC2).

### Tier 5 — New capabilities (forward-looking)

- **O-M1 — `MAINTAINING.md` or `.context/workflows/release-flow.md`** for maintainer-only orientation.
- **O-M2 — Manifest-schema validator + `$schema` declarations** as the first CI-like gate post-split.
- **O-M3 — Dry-run flag + monotonicity check on `bump-versions.sh`.**
- **O-D2 — `commands/index.md` or expanded README intent index** for Copilot CLI onboarding parity.
- **O-T2 — Formal token-economy audit and budget** for the always-loaded surface.

---

## Open Questions for the User

1. **Re-tier decision for the ~7 thrice-cycled Moderate/Minor carry-forwards?** The cluster `M-U2`, `m-U1` through `m-U7`, `M-P1`, `M-P2`, and parts of the architect/coder/researcher/PM minors have now appeared identically in MKT-0077, MKT-0087, and ICON-0003. They are user-groomed deferrals each time. Recommended choice between: (a) **Tier 4 sweep PR** (the closure path; trivial-to-low effort each); (b) **explicit "watch / accepted" classification** with a one-time documentation in `.context/standards/` or `.context/decisions.md` so future audits know to skip them; (c) **continue carry-forward** for another cycle. Recommend (a) for the trivial-effort items (sweeps under 5 lines each) and (b) for the rest.

2. **`MAINTAINING.md` vs `.context/workflows/release-flow.md`?** O-M1 lives somewhere. Public `MAINTAINING.md` advertises the release flow to outside contributors; private `.context/workflows/release-flow.md` keeps it inside the repo's already-loaded context. Recommend the latter — the audience is "people working on ICON itself," which is currently the same set of people who load `.context/`.

3. **Lint-gate scope.** O-V1 wires a `plugins/<plugin>/` grep into `.githooks/post-commit`. Two scoping decisions: (i) does the lint also block stale `MKT-NNNN` ticket-ID introductions outside `CHANGELOG.md` / `.context/`? (ii) does the same hook carry the manifest-schema validator (O-M2) so there is one place to expand it later, or are they two separate hooks? Recommend (i) yes (cheap to add the grep), (ii) one hook with two checks.

---

## Suggested Follow-up Tasks

Each task is independent and can be triaged by priority and available bandwidth. The task-ID slots are suggestions — please confirm before filing as GitLab issues per the audit's data-exfiltration constraint.

- **ICON-0004 — Migrate `plugin-audit` skill to standalone-repo layout (Tier 2).** Regex sweep across SKILL.md + 6 briefs + synthesis-template.md. Closes M-U1. Medium effort.
- **ICON-0005 — Reconcile release-plugin CHANGELOG-shape doc conflict (Tier 2).** Rewrite `release-plugin/SKILL.md:105-108` to match `workflows/changelog.md:11`. Closes M-1; discharges ICON-0001 retrospective follow-up. Trivial effort.
- **ICON-0006 — Wire commit-time path-drift lint + cross-surface sweep rule extension (Tier 2).** Bundles O-V1 + O-V2 + O-X17 + O-M2 into a single hook-and-standards PR. Low effort; high recurrence-prevention payoff.
- **ICON-0007 — Init-orchestrator structural cleanup (Tier 3).** Bundles O-S2 + O-S3 + O-S4 + O-X10. Closes M-I1, M-I2, M-I3, m6, m8. Medium-to-high effort.
- **ICON-0008 — Common-constraints single-sourcing (Tier 3).** Closes M-A2. Largest always-loaded trim. Medium effort.
- **ICON-0009 — Tier-4 hygiene sweep PR.** Bundles ~10 trivial-effort minors per Tier 4. Closes M-U2 + m-U3 + m-U4 + n-P1 + m1 + m2 + m-U8 + m-P1 through m-P5 (some). Low effort; closes the long tail.
- **ICON-0010 — Maintainer orientation + token-economy audit (Tier 5).** Bundles O-M1 + O-T2 + first cut at $schema declarations. Low-to-medium effort.
- **ICON-0011 — Re-tiering decision and `.context/decisions.md` ADR-007 (Open Question 1).** Document which carry-forwards move to "watch / accepted" classification so future audits skip them. Trivial effort.
