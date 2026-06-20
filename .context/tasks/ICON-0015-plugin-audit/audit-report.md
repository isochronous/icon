# ICON Plugin Audit Report — ICON-0015

**Task:** ICON-0015
**Date:** 2026-05-20
**Plugin version audited:** `1.15.4` released-tag; `main` carries `[Unreleased]` work for ICON-0011, ICON-0012, ICON-0013, and ICON-0014 (ICON-0013 and ICON-0014 merged into `main` mid-audit at the user's direction; see *Mid-audit state change* note below).
**Scope:** 9 agents, 48 skills, 4 commands, 1 plugin-scoped SessionStart hook, 1 pre-commit hook (fence-aware as of ICON-0013), 1 plugin manifest (`.claude-plugin/plugin.json`), 1 MCP registry (`.mcp.json`), 1 maintainer-only `release-plugin` skill at `.claude/skills/release-plugin/`.
**Method:** 6 parallel research agents per domain → synthesis. Baseline for delta comparisons: **ICON-0003** (2026-05-14, plugin v1.15.3, verdict GOOD).
**Raw findings:** `./research/01-agents.md`, `02-process-skills.md`, `03-context-specialist-init.md`, `04-utility-skills.md`, `05-infrastructure.md`, `06-cross-cutting.md`.
**User directive:** Two focuses — *internal consistency* and *token efficiency*. Off-limits: removing anti-rationalization tables (protected as load-bearing redundancy per ADR-004); automating CHANGELOG entries from git commit messages.
**Release model (important framing):** This project releases by **moving the `latest` tag** to a chosen commit on `main` — *not* by merging feature branches to `main`. Feature work can sit on `main` for an arbitrary period before a tag-move. Findings that previously framed "ICON-0013/0014 unmerged" as a release-readiness concern are reframed accordingly: doc-drift and `[Unreleased]` CHANGELOG completeness are still discipline issues; the merge state of any specific feature is not.
**Plugin-shipped agents and `.context/`:** Per the user, plugin-shipped agents may reference (a) the standardized always-created files (`retrospectives.md`, `META.md`, `overview.md`, `iconrc.json`, `decisions.md`) and (b) the subdirectories that ship in the context template (`standards/`, `domains/`, `architecture/`, `testing/`, `styling/`, `workflows/`, `cache/`). When a subdirectory is excluded via `.iconrc.json` (e.g., `architecture`, `testing`, `styling` in this repo), the corresponding specialist agent simply isn't invoked, so the reference inside that agent does no harm. What agents must NOT do is cite *specific files inside those subdirectories by name* unless the plugin itself ships those files in `context_template/`. The audit found one such violation (see updated **M-CC-NET3** below — `manager.agent.md:151` references `.context/standards/three-layer-enforcement.md`, a file that is in neither `context_template/context/standards/` nor this repo's `.context/standards/`).

**Plugin vs this repo's local `.context/`:** This repo is BOTH the ICON plugin source AND a consumer of ICON (the plugin "dogfoods" itself for its own development). Files under this repo's `.context/` are the ICON-repo's *local* metadata — they do NOT define the plugin's behavior for consumers. A local file having extra ICON-specific content (like a richer `task-plan/phase-completion.md` with `Ticket: ICON-NNNN` and ICON-specific standards references) does not mean the plugin's shipped base template (`context_template/context/workflows/task-plan/phase-completion.md`) is "outdated" — it means this repo has customized its own copy. The right framing for any local-vs-template delta is: identify content changes in the local file that *generalize across organizations and tech stacks*, and propose targeted promotions of just that generalizable content to the base templates in `context_template/`. This audit reframes the prior "distribution-mirror drift" finding accordingly (see updated **M-P-A → Improvement Opportunity** below).
**Mid-audit state change:** After the leaf briefs ran but before synthesis closed, the user authorized merging `feature/ICON-0013-fence-aware-pre-commit-hook` and `feature/ICON-0014-plan-md-freshness-gate` into `main`. Both merges landed cleanly (one conflict resolved in `retrospectives.md` ordering). The report has been updated to reflect the post-merge state — the freshness gate is now on `main` and ICON-0014/0013 retros are integrated. Findings tied to "ICON-0014 not on main" (Brief 01 M-A-NET2; Brief 02 m-P-7; Brief 05 m-n4) are discharged with that merge.

---

## Executive Summary

**Overall health: GOOD.** Eight of the twelve ICON-0003 Moderates are confirmed fixed on disk (M-U1, M-U2, M-1, M-2, M-I1, M-I2, M-I3, M-P1, M-P2). The M-A2 9× common-constraints duplication is policy-accepted with mechanical byte-equality enforcement (ICON-0011 pre-commit hook, now fence-aware via ICON-0013). The ICON-0014 plan.md freshness gate is live on `main` as of this audit. RULE 4 and RULE 5 both move from WARNING back to PASS for the first time in two cycles. No Critical defects.

The remaining issues cluster into three themes:

1. **User-facing doc-drift on `main` since the `v1.15.4` tag.** `README.md:100,:110` and `.claude/claude.md:9` still describe the pre-ICON-0012 hook architecture; `commands/enable-manager-default.md:7` / `commands/disable-manager-default.md:7` describe behavior already on `main` as "Starting with ICON 1.16". Readers form wrong mental models regardless of release mechanism. This is **M-CC-NET1**, narrowed: the *merged-vs-unmerged* sub-cluster was discharged by the mid-audit merge; the *CHANGELOG-completeness* sub-cluster was withdrawn after re-reading `release-plugin/SKILL.md` (Steps 2–5 author the CHANGELOG from the git diff and commit log at release time, so an empty `[Unreleased]` mid-cycle is expected, not a defect). The remaining doc-drift fix is a short maintainer-authored sweep at the next tag-move.

2. **Two long-standing structural inconsistencies surfaced this cycle as Moderates.** (a) **M-CC-NET3**: `agents/manager.agent.md:151` references `.context/standards/three-layer-enforcement.md` — a specific file by name that is neither in `context_template/context/standards/` (the plugin's own ships-with-init standards content) nor in this repo's local `.context/standards/`. Per the user's `.context/` reference rule, naming subdirectories and template-shipped files is fine; naming a specific file the plugin doesn't actually ship is not. Reframed fix: either delete the reference, or — if the layer-definitions content is genuinely needed — inline it in the agent body. **Note:** the related `manager.agent.md:198,:220,:249` references introduced by the ICON-0014 merge target `.context/workflows/task-plan/phase-completion.md § Reconcile plan.md`, and *that file does ship in `context_template/context/workflows/task-plan/`* (verified). Those references are valid. (b) **M-CC-NET2**: `manager.agent.md:204` ("retrospectives.md is written directly by the manager") contradicts `task-retrospective/SKILL.md:113` ("delegate to @context-specialist"); the `agent-vs-skill-invocation.md:63` SSOT explicitly acknowledges this as "Known unresolved" — a documented three-layer-enforcement gap.

3. **The recurring cross-surface sweep pattern is now retrospective-evidenced at 6 of 8 tasks.** Brief 06's pattern analysis shows the sweep-incompleteness class (M-CC1 in ICON-0003) has appeared in ICON-0003, ICON-0004, ICON-0007, ICON-0008, ICON-0011, and ICON-0014. The rule is correctly named in every retro but enforced editorially — current on-disk instances include **M-U-A** (all six plugin-audit briefs carry unfilled `<path-to-prior-audit-report.md>` placeholders) and **M-I-A** (`merge-phase-templates` Step 2 routing table missing `phase-testing.md`). The right intervention is structural (pre-commit grep for unfilled angle-bracket placeholders), not another retro entry.

### Scorecard

| Rule | Verdict | Movement vs ICON-0003 |
|------|---------|-----------------------|
| RULE 1 — PROMPT vs SKILL SEPARATION | ✅ PASS | Held |
| RULE 2 — SINGLE SOURCE OF TRUTH | ⚠️ WARNING | Held — common-constraints 9× duplication remains but is now mechanically enforced (ICON-0011, fence-aware via ICON-0013); net-new SSOT/3-layer gap surfaced in M-CC-NET2 (retrospectives.md write-path). |
| RULE 3 — SUB-AGENT JOB CLARITY | ✅ PASS | Held — sub-agent scope sections verified clean across all 7 specialists (Brief 01 § Structural Observation 4). |
| RULE 4 — SKILL RESPONSIBILITY | ✅ PASS | **Improved (was WARNING).** M-U1 (plugin-audit migration) closed; the residual M-U-A placeholder is a brief-template defect, not a skill-responsibility one. |
| RULE 5 — ORCHESTRATOR CLARITY | ✅ PASS | Held — M-I1 routing contradiction fully closed across all 5 sections of `context-specialist.agent.md` (ICON-0007). |

(The 5-rule scorecard borrows the framework from `agent-evaluation`. Cross-reference for rule definitions — do not duplicate them here.)

### Top-line counts (after dedup, mid-audit merge discharge, and clarifications)

- **Defects (deduplicated)**: **0 Critical**, **5 Moderate**, **36 Minor** (total **41**).
  - The prior Moderate **M-P-A** ("distribution-mirror drift") is recategorized as a *plugin-vs-local* misframing — moved to Improvement Opportunities as a targeted base-template-promotion review (O-S3).
  - The prior Critical **C1** was walked back after user clarification: agents *may* reference template-shipped subdirectories (`standards/`, `domains/`, `architecture/`, `testing/`, `workflows/`, `cache/`, etc.) — what's not allowed is naming *specific files* the plugin doesn't ship. Only one such reference exists (`manager.agent.md:151`), and it remains as Moderate **M-CC-NET3**.
  - Two Minors (Brief 02 m-P-7; Brief 05 m-n4) discharged by the mid-audit ICON-0014 merge.
- **Improvement Opportunities**: **~34** unique after dedup across the 6 briefs, spanning Token Efficiency / Discoverability / Consolidation / Missing Skills / Self-Verification. (O-S3 retitled and rescoped to **promote generalizable local content**, not **sync mirrors**, given the plugin-vs-local reframing. O-V3 dropped — the parity check it proposed was premised on the misframing.)
- **ICON-0003 delta**: **~16 items fixed** (incl. all 9 carry-forward Moderates that had follow-up tasks; ICON-0014-merge discharges another item this cycle); **~25 still-present-or-partial** (the long-tail carry-forwards); **~9 net-new** drift patterns.
- **Theme**: surface area shifted from "audit infrastructure unmigrated" (ICON-0003 M-U1) and "feature work unshipped" (now discharged) to "release-time doc-discipline at tag-move" (M-CC-NET1) and "long-standing inter-skill contradictions" (M-CC-NET2, M-CC-NET3).

*Dedup notes:* (a) Brief 01 M-A-NET1 = Brief 06 M-CC-NET3 (single dead specific-file reference at `manager.agent.md:151`). (b) Brief 01 M-A-NET2 + Brief 02 m-P-7 + Brief 05 m-n4 (ICON-0014 not on main) — **discharged by mid-audit merge**. (c) Brief 02 M-P-A + Brief 06 m-CC-4 (distribution-mirror sync) — recategorized as Improvement Opportunity O-S3 (plugin-vs-local reframing). (d) Brief 02 M-P-B = Brief 06 M-CC-NET2 (retrospectives write-path). (e) Brief 04 m-U-H = Brief 05 m-7 (release-plugin git-repo guard). (f) Brief 04 m-U-K = Brief 05 m-4 (format-slack.sh strict mode). (g) Brief 05 M-N1+M-N2+m-n1 roll into M-CC-NET1 (doc-drift on user-facing surfaces). (h) Brief 06 m-CC-3 (CHANGELOG missing ICON-0013/0014 entries) — **withdrawn**: `release-plugin` Step 5 authors versioned CHANGELOG sections from the git diff + commit log at release time, so an empty `[Unreleased]` mid-cycle is expected behavior.

---

## Critical Findings (0)

None observed. The audit initially elevated a systemic `.context/` reference concern to Critical based on an early reading of user feedback. After clarification, the concern collapses to a single Moderate (**M-CC-NET3** below): plugin-shipped agents may reference template-shipped `.context/` subdirectories (`standards/`, `domains/`, `architecture/`, `testing/`, `workflows/`, `cache/`, etc.) and the always-created standardized files freely — what they may not do is name a *specific file by name* unless the plugin itself ships that file under `context_template/`. Excluded-via-`.iconrc.json` subdirectories don't break this rule because the corresponding specialist agent isn't invoked when that layer is excluded.

<details><summary>Walked-back C1 (kept for audit-trail; not a defect)</summary>

### C1 (WALKED BACK) — Shipped agents systemically reference `.context/` paths beyond the standardized always-created files

- **Location**: 28 references across 8 of 9 agents. Affected files:
  - `agents/architect.agent.md:20,:92` (`.context/architecture/`, `.context/standards/`, `.context/domains/`)
  - `agents/coder.agent.md:30,:31,:34` (`.context/standards/`, `.context/domains/`)
  - `agents/manager.agent.md:34,:58,:97,:135,:144,:151,:161,:198,:220,:249,:252` (`.context/iconrc.json`, `.context/domains/`, `.context/standards/`, `.context/workflows/task-plan/phase-completion.md`, `.context/standards/three-layer-enforcement.md`, etc.). The `:198, :220, :249` references were just introduced by the ICON-0014 merge.
  - `agents/planner.agent.md:33-35` (`.context/domains/`, `.context/architecture/`, `.context/standards/`)
  - `agents/product-manager.agent.md:20,:130,:142` (`.context/domains/`, `.context/architecture/`, `.context/archive/`)
  - `agents/researcher.agent.md:23,:25,:34,:86` (`.context/cache/`, `.context/standards/`, `.context/architecture/`)
  - `agents/reviewer.agent.md:16` (`.context/standards/`, `.context/testing/`)
  - `agents/tester.agent.md:26` (`.context/testing/`)
  - `agents/context-specialist.agent.md` — also carries `.context/` references but is the closest to legitimate-by-design (it is the agent that owns `.context/`); to be evaluated as a special case during the sweep.

- **Problem**: ICON's per-repo `.context/` is generated fresh by `initialize-repo` and is partially configurable via `.iconrc.json` excludes. The user's rule: plugin-shipped agents may reference only the standardized always-created files (`retrospectives.md`, `META.md`, `overview.md`, and similar always-created top-level files). Agents must not cite `.context/<subdir>/...` paths, because: (a) the subdir may not exist (the ICON plugin's own `.iconrc.json` excludes `architecture`, `testing`, `styling`, so any agent directing a reader to `.context/architecture/` or `.context/testing/` is pointing at a dir that does not exist here); (b) specific files inside `.context/<subdir>/` are repo-content, not plugin-shipped artifacts; (c) `.context/` content can be customized or deleted by the consumer without breaking the plugin contract.

- **Risk**: Live and demonstrable in the ICON repo itself. `architect.agent.md:20`, `planner.agent.md:34`, `product-manager.agent.md:20`, `reviewer.agent.md:16`, `researcher.agent.md:34`, and `tester.agent.md:26` each instruct the agent to read from `.context/architecture/` or `.context/testing/`. These directories are excluded in this repo's `.iconrc.json` — they do not exist. Any agent following its own Session Start instructions runs `Read` against a path that does not resolve. Sub-agents follow these instructions in every dispatch. The defect is not theoretical.

- **Walk-back rationale**: User clarification — "when I said that agents should not refer to non-standard files/folders .context, that did not mean folders that are part of the context template. It's a safe assumption that if the user adds 'testing' to the excludes in iconrc.json, then it is because that project has no test layer, and so the testing agent will never be invoked." All of the listed references except `manager.agent.md:151` (the `three-layer-enforcement.md` specific-file reference) cite template-shipped subdirectories or template-shipped specific files (verified: `context_template/context/workflows/task-plan/phase-completion.md § Reconcile plan.md` exists). The only remaining defect is the single dead specific-file reference, retained as **M-CC-NET3** in the Moderate section.

</details>

---

## Moderate Findings (5)

*Full rationale and file:line references in the research files. This section is a consolidated inventory for triage. The prior **M-P-A** ("distribution-mirror drift") is reframed under O-S3 below as a base-template-promotion review, not a defect.*

### Doc-Discipline / Release Hygiene (1)

| # | Finding | Location |
|---|---------|----------|
| M-CC-NET1 | **User-facing doc-drift on `main` since the `v1.15.4` tag.** Now that ICON-0013 and ICON-0014 are merged, four features (ICON-0011, ICON-0012, ICON-0013, ICON-0014) sit on `main` ahead of the released tag. (i) `README.md:100,:110` describes the pre-ICON-0012 hook architecture (`~/.claude/settings.json` wiring + "Remove the SessionStart hook" — neither true post-ICON-0012). (ii) `.claude/claude.md:9` describes "two `hooks/inject-manager-role.*` scripts" while only `.mjs` exists. (iii) `commands/enable-manager-default.md:7` and `commands/disable-manager-default.md:7` describe behavior already on `main` as "Starting with ICON 1.16" — at minimum a confusing temporal frame at the next tag-move. **Release model:** This project releases by moving the `latest` tag, not by merging to `main`; the *merged-vs-unmerged* aspect of the prior framing is not a defect. **CHANGELOG note:** The earlier framing of "missing `[Unreleased]` entries for ICON-0013/0014" is also withdrawn — `.claude/skills/release-plugin/SKILL.md` Steps 2–5 author CHANGELOG entries at release time from the git diff and commit log between the last release commit and HEAD; the `[Unreleased]` block is *expected* to be partial or empty mid-cycle. The doc-drift items above remain the substance of this finding. | `README.md:100,:110`; `.claude/claude.md:9`; `commands/enable-manager-default.md:7`; `commands/disable-manager-default.md:7` |

### Process Skills / SSOT (1)

| # | Finding | Location |
|---|---------|----------|
| M-CC-NET2 (= M-P-B) | **`retrospectives.md` write-path contradiction is documented but untracked.** `manager.agent.md:204` ("written directly by the manager") contradicts `task-retrospective/SKILL.md:113` ("delegate to @context-specialist"). The `agent-vs-skill-invocation.md:63` SSOT — created in ICON-0006 specifically to resolve M-P2 — explicitly acknowledges this sub-issue as "Known unresolved" with a stated preference for the specialist path but no resolution date, no issue number, no ADR reference. Three-layer-enforcement gap: a Hardcoded-tier statement contradicts a Default-tier skill path, with the SSOT refusing to adjudicate. | `agents/manager.agent.md:204`; `skills/task-retrospective/SKILL.md:113`; `skills/task-plan-phase-completion/agent-vs-skill-invocation.md:63` |

### Agent / Manager (1)

| # | Finding | Location |
|---|---------|----------|
| M-CC-NET3 (= M-A-NET1) | **`manager.agent.md:151` names a specific `.context/` file the plugin does not ship.** The delegation template's "see `.context/standards/three-layer-enforcement.md` for the layer definitions" reference is the sole instance of an agent citing a file by name that is neither in `context_template/context/standards/` (the plugin's own initialize-repo content — currently ships `error-handling.md`, `naming-conventions.md`, `code-style.md`) nor in this repo's local `.context/standards/` (currently `changelog-discipline.md`, `skill-decomposition.md`). The reference has been on disk since MKT-0059. Per the user's `.context/` rule: subdirectory and template-shipped-file references are fine; naming a specific never-shipped file is not. **Fix:** either delete the reference, or — if the layer-definitions content is genuinely needed in delegations — inline it in the agent body or move it to `shared/three-layer-enforcement.md` (a plugin-shipped surface). Do NOT create a `.context/standards/three-layer-enforcement.md` to satisfy the reference; that puts the content in the repo-local layer where it shouldn't be. | `agents/manager.agent.md:151`; `context_template/context/standards/` (file absent); `.context/standards/` (file absent) |

### Init Chain Routing (1)

| # | Finding | Location |
|---|---------|----------|
| M-I-A | **`merge-phase-templates` Step 2 routing table is missing `phase-testing.md` as a destination.** The 4-row table covers `phase-investigation`, `phase-architecture`, `phase-implementation`, and `phase-completion` — but the canonical phase set (`context-specialist-impl-leaf/SKILL.md:267`) includes 6 files. Testing-related custom content from a deprecated `task-workflow-template.md` is routed to `phase-completion.md` by the catch-all "Testing, code review, retrospective, completion" row — incorrectly conflating testing and completion phases in a *plugin-shipped* skill. | `skills/merge-phase-templates/SKILL.md:42-46` vs `skills/context-specialist-impl-leaf/SKILL.md:267` |

### Plugin-Audit Self-Reference (1)

| # | Finding | Location |
|---|---------|----------|
| M-U-A | **All six `plugin-audit` dispatch briefs contain the unfilled `<path-to-prior-audit-report.md>` placeholder.** ICON-0004 swept `plugins/<plugin>/` path strings across SKILL.md and the briefs but did not resolve template-style angle-bracket placeholders — exactly the M-CC1 sweep-incompleteness class the ICON-0004 retro warned about. Every plugin-audit invocation now requires a plan-level workaround (the ICON-0015 plan.md baseline preamble carries the path explicitly), reproducing the workaround pattern that M-U1 was supposed to eliminate. This is a *plugin-shipped* skill defect. | `skills/plugin-audit/briefs/01-agents.md:10`; `02-process-skills.md:10`; `03-context-specialist-init.md:13`; `04-utility-skills.md:14`; `05-infrastructure.md:35`; `06-cross-cutting.md:16` |

---

## Minor Findings (38)

Condensed list. Details in research files; each numbered ID resolves to a line-cited finding in the corresponding brief.

**Agents (8):** planner odd code-fence count (m-A-1, `planner.agent.md:45,:60,:87`); manager hardcoded "3+" failure threshold vs `systematic-debugging` "2+" trigger (m-A-2 / m-P-5, `manager.agent.md:182,:247` vs `systematic-debugging/SKILL.md:4`); PM Session Start lacks common-constraints acknowledgement (m-A-3); PM Session Start positioned after `## When to Invoke` despite "MANDATORY" framing (m-A-4); zero agents reference `mr-discipline` (m-A-5); manager step-7 / Default-tier "Session Start" wording tension (m-A-6); reviewer Default-tier repeats the 6-category checklist list verbatim (m-A-NET3, `reviewer.agent.md:25,:68`); manager + context-specialist use `description: >` folded scalar while other 7 agents use single-quoted form — parser-fragility (m-A-NET4).

**Process skills (5):** 5 phase-skill frontmatter descriptions byte-identical (m-P-1); "Does NOT cover" footer terminology drift across 5 phase skills (m-P-2); "10–15" prose vs script-canonical "15" (m-P-3); `task-retrospective` two-path script invocation (m-P-4, line 92 direct vs line 113 delegate); `verification-checklist` Gate headings missing skill-name prefix (m-P-6).

**Context-specialist + init (8):** `prune-context.sh` template still has 8 `2>/dev/null` instances despite agent's own ban (m1, fourth carry); `find-context-template` PowerShell `\` vs Bash `/` separator literals (m3); `find-context-template` description doesn't list its five callers (m4); `resolve-repo-context` schema example omits the fallback `instructions` path (m5); `context-specialist.agent.md` doubled scope-discipline statement at `:133, :138-139` (m7); hardcoded DataScan/.NET/WMS examples across 4 init skills (m9); `upgrade-repo` Phase 3 vague drift-trigger spec while 3 orchestrators inline the precise version (m10); **net-new (m-new-A):** `initialize-workspace` Step 7 MR template "How to Test" row uses legacy `copilot-instructions.md` while the sibling `initialize-multimodule` template at line 400 correctly uses `.claude/claude.md` (`initialize-workspace/SKILL.md:336`).

**Utility skills (10):** `ecological-impact` example references stale "Claude Sonnet 4.6" (m-U-A, `:86, :221`); `jira-story:32, :35` Copilot-CLI `create` tool literal (m-U-B); `start-worktree` 3× "not yet migrated" framing dated post-MKT-0089 (m-U-C); **net-new (m-U-D):** `writing-skills:495` references `TaskCreate` (Copilot-CLI-only) within a skill that mandates platform-agnostic tool naming; `setup-mcp-servers:100-102` "Choose one option" but only Option A documented (m-U-E); `rfc:139` design-history paragraph mid-schema (m-U-F); `writing-skills` exceeds its own 500-line / 500-word self-imposed caps (549 / 3,271) — defining self-reference violation (m-U-G); `release-plugin/SKILL.md:31` no git-repo guard before `git --no-pager branch --show-current` (m-U-H / m-7); `synthesis-template.md:122` MKT-0046 external reference unresolvable from this repo (m-U-I, partial improvement post-ICON-0004); `post-incident-review/scripts/append-retrospective-entry.{sh,ps1}` byte-identical with `task-retrospective/scripts/...` — SSOT drift risk with no automated guard (m-U-J); `.claude/skills/release-plugin/scripts/format-slack.sh:1` no `set -euo pipefail` (m-U-K / m-4, third carry-forward cycle).

**Infrastructure (5):** both manifests still lack `$schema` (m-1, `.claude-plugin/plugin.json:1`, `.mcp.json:1`); **net-new (m-n1):** `commands/enable-manager-default.md:7` + `commands/disable-manager-default.md:7` describe behavior already-on-main as "Starting with ICON 1.16"; **net-new (m-n2):** `.claude-plugin/plugin.json:9` declares `"license": "MIT"` but no `LICENSE` file exists at repo root; **net-new (m-n3):** `context_template/README.md:27-38` structure diagram omits `iconrc.json` and `.gitignore` (both present in the shipped template); plus carry-forwards already counted in Utility (m-U-H, m-U-K).

**Cross-cutting (2):** `README.md:27` Design Principles uses `.github/copilot-instructions.md` "if not yet migrated" qualifier that misleads new installers about the expected state (m-CC-1, carry-forward from ICON-0003 m-CC1); `using-skills/SKILL.md:64-68` Skill Priority example has only the debugging chain — no example of the dominant task-plan → phase-skills → completion → retrospective chain (m-CC-2, net-new).

---

## Improvement Opportunities (~35 after dedup)

*Items below are positive-design suggestions. None are defects; each is a judgment call the user can accept, defer, or reject. Per the user's directive, no item proposes removing anti-rationalization tables or automating CHANGELOG entries from git commit messages.*

### Category 1 — Token Efficiency / Slim the Always-Loaded Surface (4)

**O-T1 · Conduct the formal always-loaded token-budget audit (carry-forward from ICON-0003 O-T2; now two cycles open).** The dispatcher always-loaded surface (manager + 9× inlined common-constraints + `using-skills` ≈ 7,865 words; PM substitution ≈ 6,564 words). The common-constraints inlining alone is ~35–40% of the surface and is policy-accepted per ADR-004 (mechanically enforced byte-equal by `.githooks/pre-commit`). Other always-loaded components have not been budgeted. The next addition (any size) will push the surface past a natural threshold without a gate. Define explicit per-session word budgets and per-component caps; flag any single component over 40% as a trim candidate. **Effort: medium. Impact: high.** (Brief 06 IO-CC-T1.)

**O-T2 · Trim the reviewer Default-tier redundant category list.** `reviewer.agent.md:68` repeats verbatim the 6-category list at `reviewer.agent.md:25`. Replace with "Review against all six categories defined in the `code-quality-rules` skill" — 14-word reduction, no information loss. **Effort: trivial. Impact: low** (micro-efficiency; example of the class O-T1 systematizes). (Brief 01 IO-A5 = Brief 06 IO-CC-T2.)

**O-T3 · Collapse the 5× phase-skill template-override paragraphs to a one-line dispatcher reference.** Each of the five phase skills carries a 5-line "Template-override rule" paragraph that is structurally identical. When multiple phase skills load in a session, 25 lines repeat with no decision value past the first. Move the full explanation to `task-plan/SKILL.md` (the dispatcher) and replace each phase skill's paragraph with one line: `**Template-override rule**: apply `.context/workflows/task-plan/phase-<name>.md` if present — see `task-plan` for the full policy.` **Effort: low. Impact: low-medium.** (Brief 02 IO-P-6 = Brief 06 IO-CC-T3.)

**O-T4 · Tighten `writing-skills` to its own self-imposed length cap.** 549 lines / 3,271 words against its own 500/500 caps. Extract the Skill Creation Checklist (~430 words at lines 493–531) to a sibling `writing-skills/skill-creation-checklist.md` and replace inline with a one-line cross-reference. Closes m-U-G (the defining self-reference violation). **Effort: low. Impact: medium.** (Brief 04 IO-U2.)

### Category 2 — Discoverability / Onboarding UX (4)

**O-D1 · Add a task-plan phase-skill chain to `using-skills` Skill Priority.** `using-skills/SKILL.md:64-68` currently exemplifies only the debugging chain. Adding a second example for the task-completion chain — `task-plan` → `task-plan-phase-investigation` → `task-plan-phase-implementation` → `task-plan-phase-completion` → `task-retrospective` — gives dispatchers an explicit model for the dominant orchestration workflow. Closes m-CC-2. **Effort: trivial. Impact: medium.** (Brief 06 IO-CC-D1.)

**O-D2 · Sweep README and `.claude/claude.md` for post-ICON-0012 hook architecture.** Replace `README.md:100,:110` and `.claude/claude.md:9` with descriptions matching the shipped plugin-scoped `hooks/hooks.json` + `~/.claude/icon-user-settings.json` model. Bundle into the next version-bump PR. Closes M-N1 / M-N2 (the user-visible halves of M-CC-NET1). **Effort: trivial. Impact: high.** (Brief 05 O-I1 = Brief 06 IO-CC-D2.)

**O-D3 · Promote PM Session Start parity with manager.** Two 1–2 line edits: move `## Session Start` before `## When to Invoke` in `product-manager.agent.md`; add "Apply common constraints — always active, no invocation required" as step 2 mirroring `manager.agent.md:33`. Closes m-A-3 + m-A-4. **Effort: trivial. Impact: low-medium.** (Brief 01 IO-A3.)

**O-D4 · Add an `mr-discipline` cue to the manager Task Completion section.** Currently no agent file references `mr-discipline`. The manager's Task Completion section (`manager.agent.md:197-208`) orchestrates review, verification, retrospective, and commit, but never cues `mr-discipline` for MR opening. Adding "Apply `mr-discipline` before opening an MR" as step 5 (or inside step 4) closes the discovery gap. Closes m-A-5. Pairs with extending `using-skills` to name the gate. **Effort: trivial. Impact: medium.** (Brief 01 IO-A4 + Brief 06 IO-CC-D3.)

### Category 3 — Consolidation / Structural Simplification (8)

**O-S1 · Resolve `manager.agent.md:151` `three-layer-enforcement.md` reference (closes M-CC-NET3).** Two options: (a) **Delete the reference**. The surrounding bullet ("name all three layers and their exact file locations") still stands without the trailing "see `.context/standards/three-layer-enforcement.md`" pointer — the content the reference promises is itself derivable from the ICON-0007 retro lesson ("routing rules appear in role intro / scope guards / mode tables / dispatch routing / Hardcoded constraints / Default-Discretionary tiers / sibling routing-guide tables"). (b) **Inline the layer definitions** into the manager agent's body (or `shared/`), and update the delegation template to point at the local location. Both close M-CC-NET3 without putting plugin-shipped content into the repo-local `.context/` layer. Do NOT create a `.context/standards/three-layer-enforcement.md` to satisfy the reference. **Effort: trivial. Impact: medium.** (Brief 01 IO-A1 = Brief 06 IO-CC-C1, both retitled away from "create the doc".)

**O-S2 · Add `phase-testing.md` to the `merge-phase-templates` Step 2 routing table.** Closes the only init-chain Moderate (M-I-A). A fifth row covering "@tester dispatch, coverage review, regression checks" routes to `phase-testing.md`; the `phase-completion` row narrows to "retrospective, sign-off, post-deployment verification." **Effort: trivial. Impact: medium.** (Brief 03 IO-3.)

**O-S3 · Review the ICON-repo-local phase-template customizations for generalizable content; promote only that content to `context_template/`.** Brief 02 M-P-A originally framed this as "distribution mirrors are stale" — that framing was wrong. The local `.context/workflows/task-plan/phase-*.md` files have been customized for this repo's own dev workflow (ICON-specific `Ticket: ICON-NNNN` fields, repo-specific standards references). Those customizations are not defects, and the base templates in `context_template/` are not "outdated" simply for lacking them. The improvement opportunity: walk each per-phase delta and ask "does this change generalize across organizations and tech stacks?" Examples surfaced by Brief 02 that appear to generalize: the `phase-completion` "Append via the `append-retrospective-entry` script — do not edit retrospectives.md by hand" instruction (applies to any ICON-initialized repo); the reordered completion-checklist that puts plan.md reconcile first per ICON-0014. Promote *only* those changes to `context_template/`; leave repo-specific text in `.context/`. **Effort: low. Impact: low-medium.** (Brief 02 IO-P-3 reframed; m-CC-4 reframed.)

**O-S4 · Canonicalize the `retrospectives.md` write path and close the `agent-vs-skill-invocation.md:63` "Known unresolved" block.** Two options: (a) amend `manager.agent.md:204` to align with the specialist-delegation path ("drafted by the manager, then inserted via @context-specialist with the append script") — the SSOT's stated preference; or (b) change `task-retrospective/SKILL.md:113` to specify direct manager invocation of `./scripts/append-retrospective-entry.sh` and drop the delegation path. Closes M-CC-NET2 / M-P-B. **Effort: low. Impact: medium.** (Brief 02 IO-P-1 = Brief 06 IO-CC-M1.)

**O-S5 · Single-source the entry-point detection block across the three init orchestrators.** Six inline copies of `{ [ -f ".../.claude/claude.md" ] || [ -f ".../.github/copilot-instructions.md" ]; }` across `initialize-monorepo` (lines 147, 255), `initialize-workspace` (lines 154, 261), and `initialize-multimodule` (lines 148, 316). MKT-0088 had to fix all six at once. A shared bash function (or a canonical primitive in `context-specialist-detect-tree-position`) eliminates the recurring drift surface. Carry-forward improvement; the increase from 4 to 6 copies post-ICON-0008 adds urgency. **Effort: medium. Impact: high (structural).** (Brief 03 IO-1.)

**O-S6 · Extract the Phase 3 drift-trigger sampling spec into `upgrade-repo` Phase 3 body.** Replace three verbatim copies of the "spot-check 5 random items, threshold 2/5" rule with a single canonical paragraph in `upgrade-repo`; each orchestrator's dispatch becomes a one-line cross-reference. Closes m10. **Effort: low. Impact: low-medium.** (Brief 03 IO-2.)

**O-S7 · Collapse / align phase-skill "Does NOT cover" footers.** Five sites with redundancy and terminology drift between negation ("@coder dispatch") and positive list ("implementation phase"). Either remove the footers and expand the Relationship sections, or standardize footer terminology. Closes m-P-2. **Effort: low. Impact: low.** (Brief 02 IO-P-5.)

**O-S8 · Fix the `initialize-workspace` Step 7 MR template "How to Test" row.** `initialize-workspace/SKILL.md:336` still says "Review each project's copilot-instructions.md" while the same template's Summary (line 326) and the sibling `initialize-multimodule` template (line 400) correctly use `.claude/claude.md`. Closes m-new-A. **Effort: trivial. Impact: low.**

### Category 4 — Missing Skills / Workflow Gaps (4)

**O-M1 · Add a doc-sweep reminder to `release-plugin` Step 1 for "unreleased on main" drift.** ICON-0011/0012 landing on `main` without a doc sweep produced M-N1 / M-N2. A one-bullet "sweep user-facing docs (`README.md`, `.claude/claude.md`, `commands/`) for behavioral drift vs. current-main before cutting the release" in Step 1 would catch this class at release time rather than at the next audit. Note: this is a manual reminder for the maintainer, NOT an automated CHANGELOG generator. **Effort: low. Impact: medium.** (Brief 05 O-I7 = Brief 06 IO-CC-V1.)

**O-M2 · Decide policy on `icon-status:161` `/release-plugin` suggestion.** Three options: (a) drop the suggestion entirely — `release-plugin` is by-design maintainer-only post-split; (b) gate behind a heuristic (check whether `.claude/skills/release-plugin/SKILL.md` exists before emitting); (c) re-examine whether `release-plugin` should be shipped to consumers. Recommend (a). Closes m-U8 carry-forward. **Effort: trivial. Impact: medium.** (Brief 04 IO-U4.)

**O-M3 · Add a `LICENSE` file or remove the `"license": "MIT"` claim from `plugin.json`.** `.claude-plugin/plugin.json:9` declares MIT but no `LICENSE` file exists. Either ship the four-sentence MIT text or remove the field. Closes m-n2. **Effort: trivial. Impact: low-medium.** (Brief 05 O-I2.)

**O-M4 · Add a dry-run flag + monotonicity check to `bump-versions.sh`.** Operational defensiveness on the only write-side script in the release flow. 4 lines for `--dry-run`; 6 lines for `semver-greater-than-prev`. Carry-forward from ICON-0003 O-M3. **Effort: low. Impact: medium.** (Brief 05 O-I5.)

### Category 5 — Self-Verification / Automate the Retrospective Wisdom (4)

**O-V1 · Replace `<path-to-prior-audit-report.md>` placeholder across all six `plugin-audit` briefs.** Substitute the standard discovery command: `ls .context/tasks/*/audit-report.md | sort | tail -1`. Closes M-U-A. Single highest-leverage trivial fix in the cycle. **Effort: trivial. Impact: high.** (Brief 04 IO-U1 = Brief 06 IO-CC-V2.)

**O-V2 · Extend `.githooks/pre-commit` to enforce parity on the two `append-retrospective-entry` script pairs.** `skills/post-incident-review/scripts/append-retrospective-entry.{sh,ps1}` and `skills/task-retrospective/scripts/...` are currently byte-identical but have no automated guard. A two-line `diff || exit 1` check converts the SSOT risk (m-U-J) into a commit-time gate, following the same pattern that closed M-A2 via ICON-0011. **Effort: low. Impact: medium.** (Brief 04 IO-U5 = Brief 06 IO-CC-M2.)

**O-V3 · ~~Template-version parity check between local `.context/` and `context_template/`~~ — DROPPED.** Brief 06 proposed this as Pattern B's standardization candidate, but it was premised on the misframing that local `.context/` should mirror `context_template/`. With the plugin-vs-local clarification, the local file is *expected* to diverge from the template — they serve different audiences. Automated parity-enforcement would create false alarms on legitimate repo-local customizations. The correct intervention is the periodic *generalizability review* in O-S3 above (manual, judgement-based), not a mechanical parity gate.

**O-V4 · Extend `.githooks/pre-commit` (or post-commit) to grep for unfilled `<…>` placeholders and unresolvable file-path references in modified `skills/*/` content.** Pattern A from Brief 06's retrospective analysis (6 of 8 retros). Would have caught M-U-A (placeholder), M-A-NET1 (missing referenced standard), and the recurring sweep-incompleteness class. Closes the M-CC1 recurrence vector. **Effort: low-medium. Impact: high.** (Brief 06 § Pattern A standardization candidate.)

### Category 6 — Other (3)

**O-X1 · Sweep the carry-forward Minor cluster as a Tier-3 hygiene PR.** Bundles m-A-1 (planner fence count), m-A-2 (manager 3+ threshold — reconcile with `systematic-debugging` description trigger), m-A-NET3 (reviewer category list trim), m-A-NET4 (frontmatter format normalization), m-P-1 (phase-skill trigger descriptions), m-P-3 (10-15 → 15), m-P-6 (Gate heading prefix), m1 (`prune-context.sh` 2>/dev/null sweep), m3 (find-context-template separators — note: cosmetic, not runtime), m4 (find-context-template caller list), m5 (resolve-repo-context schema example fallback), m7 (context-specialist doubled scope), m9 (DataScan/.NET/WMS examples — may be intentional), m-U-A through m-U-K minus what's already in Category 4 and 5, m-n3 (context_template README diagram), and m-CC-1 (README "not yet migrated" framing). ~18 trivial-effort changes in one batch.

**O-X2 · Re-tier the third-cycle and fourth-cycle carry-forwards to "watch / accepted".** The format-slack.sh strict-mode item (m-U-K / m-4) is now in its third cycle; `prune-context.sh` `2>/dev/null` is in its fourth cycle. Brief 05's structural observation flags this: continued re-surfacing as Minors creates audit fatigue without producing fixes. Document the re-tier decision in `.context/decisions.md` so future audits know to skip them.

**O-X3 · Decide whether `disable-model-invocation: true` should propagate to the five `context-specialist-impl-*` and `context-specialist-detect-tree-position` skills.** All carry `user-invocable: false` already; the additional key would be defense-in-depth only. Five one-line frontmatter edits. **Effort: trivial. Impact: low.** (Brief 03 IO-6.)

---

## ICON-0003 Delta (Comparison with 2026-05-14 baseline)

### Fixed since ICON-0003 (~14 items, including all 8 carry-forward Moderates with follow-up tasks)

| ICON-0003 ID | Description | Closing task / evidence |
|---|---|---|
| M-U1 | `plugin-audit` skill unmigrated from marketplace layout | ICON-0004; SKILL.md + all 6 briefs now use repo-root paths. Residual M-U-A (placeholder) is a different defect class. |
| M-U2 | `writing-skills` stale registration instructions | ICON-0009; CHANGELOG 1.15.4 Fixed entry confirms. |
| M-1 (infra) | `release-plugin` Step 5 CHANGELOG-shape contradicted `workflows/changelog.md` | ICON-0010; `release-plugin/SKILL.md:104-125` now correctly describes the rename procedure. |
| M-2 (infra) | `release-plugin` Error Conditions referenced `sed` directly | ICON-0010; row now references `bump-versions.sh` + `git diff` verification. |
| M-I1 | `context-specialist mode: upgrade` routing contradiction | ICON-0007; all 5 sections of `context-specialist.agent.md` converge. |
| M-I2 | `initialize-multimodule` missing feature-branch + per-repo MR parity | ICON-0008; new Step 4 + Step 8. |
| M-I3 | `initialize-multimodule` missing `disable-model-invocation: true` | ICON-0008; all three orchestrators carry uniform frontmatter. |
| M-P1 | `design-first` Step 3 "hard gate" language | ICON-0005; advisory framing throughout. |
| M-P2 | `task-plan-phase-completion` invoked `context-maintenance` directly | ICON-0006; routes through `@context-specialist mode: maintenance`. |
| M-A2 (status change) | common-constraints 9× duplication | Policy-accepted; ICON-0011 pre-commit hook mechanically enforces byte-equality. Defining commit ICON-0011 retro: "the hook's first run was the real truth-discovery moment, not a no-op confirmation." |
| m-2 (infra) | `inject-manager-role.ps1` mode 644 | ICON-0012; file deleted (single Node.js wrapper). |
| m-3 (infra) | bash/pwsh parity test missing | ICON-0012; parity concern eliminated by consolidation. |
| m6 (init) | `context-specialist-create:11` claimed upgrade mode | ICON-0007 collateral; description corrected. |
| m8 (init) | init-orchestrator frontmatter key-order divergence | ICON-0008; key order normalized. |

### Still present or partial (~25 items)

- **Agent carry-forwards (6):** M-A1 (now m-A-1 — planner odd fence count); M-A3 (architect AR table — per audit directive, no removal proposals); m-A1 (3+ threshold — now m-A-2); m-A4/m-A5 (PM Session Start — now m-A-3/m-A-4); m-A6 (no `mr-discipline` references — now m-A-5); m-A7 (step-7 wording tension — now m-A-6).
- **Process carry-forwards (4):** m-P2 (now m-P-1 phase-skill descriptions); m-P3 (now m-P-3 10-15 prose); m-P4 (now m-P-4 task-retrospective two-path); n-P1 (now m-P-2 "Does NOT cover" footers); m-P1 (now m-P-6 verification-checklist gate prefix).
- **Init carry-forwards (7):** m1, m3, m4, m5, m7, m9, m10 — all unchanged from ICON-0003 / MKT-0087.
- **Utility carry-forwards (7):** m-U1 (→ m-U-B jira-story `create`); m-U3 (→ m-U-A ecological-impact model name); m-U5 (→ m-U-F rfc design-history); m-U7 (→ m-U-G writing-skills cap); m-U9 (→ m-U-J post-incident-review scripts SSOT); m-U10 (→ m-U-C start-worktree); m-U2 (→ m-U-E setup-mcp-servers Option A).
- **Infrastructure carry-forwards (3):** m-1 (both manifests lack `$schema`); m-4 (→ m-U-K format-slack.sh strict mode — **third carry-forward cycle**); m-7 (→ m-U-H release-plugin git-repo guard).
- **Cross-cutting carry-forwards (1):** m-CC1 (README "not yet migrated" framing — now m-CC-1, partial — README intent index partially addressed via MKT-0073).
- **Improvement opportunities still open (~5):** O-T1 (single-source common-constraints — supplanted by ADR-004 policy acceptance, but not closed); O-T2 (formal token budget — now O-T1 in this cycle); O-X16 (DataScan examples — possibly intentional); O-M3 (bump-versions.sh dry-run — now O-M4); O-X17 (JSON-validity check — partially overlaps O-M3).

### Net-new drift since ICON-0003 (~9 items, post-merge)

1. **M-CC-NET1 — Doc-drift on user-facing surfaces since the v1.15.4 tag.** Reframed for tag-move releases: the merged-vs-unmerged sub-cluster discharged by the mid-audit merge; the CHANGELOG-completeness sub-cluster withdrawn (handled by `release-plugin` Step 5 at release time); the README / `.claude/claude.md` / `commands/` doc-drift remains.
2. **M-CC-NET2 / M-P-B — `retrospectives.md` write-path "Known unresolved":** documented but untracked since ICON-0006 closed. Three-layer-enforcement gap.
3. **M-CC-NET3 / M-A-NET1 — `manager.agent.md:151` names a specific `.context/` file the plugin doesn't ship.** Persisted since MKT-0059, not flagged by ICON-0003.
4. **M-I-A — `merge-phase-templates` Step 2 routing table missing `phase-testing.md` destination:** pre-existing structural gap; not flagged by ICON-0003.
5. **M-U-A — `plugin-audit` brief placeholders unfilled:** different syntactic shape than M-U1 (path strings vs. `<…>` placeholders); ICON-0004 sweep did not catch it.
6. **m-A-NET3 — Reviewer Default-tier verbatim category list repeat.**
7. **m-A-NET4 — Agent frontmatter description format divergence.**
8. **m-U-D — `writing-skills:495` TaskCreate reference** (Copilot-CLI-only tool in a platform-agnostic skill).
9. **m-CC-2 — `using-skills` Skill Priority example lacks the task-plan phase chain.**

*The prior M-P-A "distribution-mirror drift" finding is removed from the Net-new list — it was a plugin-vs-local misframing per the audit's late clarification. Some content in local phase-*.md files may still warrant promotion to `context_template/`, but that's an improvement opportunity (O-S3), not a defect.*

*Discharged during this audit cycle by the mid-audit merge of ICON-0013 and ICON-0014: Brief 01 M-A-NET2 (ICON-0014 not on main); Brief 02 m-P-7 (same); Brief 05 m-n4 (same).*

### Audit-process observation

This is the first audit cycle to complete a full retrospective-driven dispatch loop with the plugin-audit infrastructure migrated (ICON-0004) and the prior audit baseline locally resolvable. Phase 1 Discovery ran the canonical commands without translation, the plan.md baseline preamble carried the prior-audit path explicitly (the `<path-to-prior-audit-report.md>` placeholder workaround), and the sub-agent dispatches proceeded without the marketplace-layout substitution table that ICON-0003 needed.

The dominant audit-process observation is that **the briefs' Prior-Audit Pointer placeholder (M-U-A) is now the next bottleneck.** ICON-0004 closed the path-string class but left the template-placeholder class; the ICON-0004 retro warned that "a literal sweep would have left the next `/plugin-audit` invocation failing on missing inputs." That warning resolved against path strings but not against angle-bracket placeholders. The fix (O-V1) is trivial; the structural lesson — extending the cross-surface-sweep rule to template-placeholder syntax — is more durable.

Secondary observation: the retrospective-pattern analysis (Brief 06) now has enough cross-cycle evidence to promote Pattern A (cross-surface sweep depth on companion files) from editorial rule to mechanical enforcement (O-V4). Brief 06's Pattern B (distribution-mirror sync) was reframed late in the audit: local `.context/` files diverging from `context_template/` is *expected* (the local file is repo-customized), not a drift to enforce against. The recurring class is real, but the mechanical fix Brief 06 proposed (parity grep) does not apply; the correct response is the periodic generalizability review (O-S3).

---

## Prioritized Fix Tiers

### Tier 1 — Fix immediately (correctness risk)

None. No Critical defects; the plugin is shippable as-is. The Moderates are doc-drift and structural-inconsistency issues, not correctness risk.

### Tier 2 — Short-term consolidation (high leverage, low-medium effort)

- **Pre-tag-move doc-sweep (closes M-CC-NET1).** Before the next `latest`-tag move, sweep `README.md:100,:110`, `.claude/claude.md:9`, and `commands/enable-manager-default.md:7` / `commands/disable-manager-default.md:7` to match current behavior. CHANGELOG is *not* part of this — `release-plugin` Step 5 will author the versioned section from the git diff and commit log at release time.
- **O-S1 — Resolve `manager.agent.md:151` `three-layer-enforcement.md` reference.** Closes M-CC-NET3. Trivial.
- **O-V1 — Replace the `<path-to-prior-audit-report.md>` placeholder in all six plugin-audit briefs.** Closes M-U-A. Single highest-leverage trivial fix.
- **O-S4 — Canonicalize the retrospectives write path.** Closes M-CC-NET2 / M-P-B. Discharges the "Known unresolved" block that has been on disk since ICON-0006.
- **O-S2 — Add `phase-testing.md` to `merge-phase-templates` routing table.** Closes M-I-A. Trivial.

### Tier 3 — Structural refactors (higher effort, higher payoff)

- **O-V4 — Extend `.githooks/pre-commit` with the angle-bracket-placeholder + unresolvable-reference grep.** Promotes Pattern A from editorial to mechanical. The single intervention most likely to break the 6-of-8 retro recurrence. Could ALSO carry a `.context/`-reference allowlist check for agents (per the rule from C1) so a future agent edit can't reintroduce a non-standardized `.context/` path.
- **O-S5 — Single-source the init-orchestrator entry-point detection block.** Closes a 6-copy drift surface that MKT-0088 had to fix simultaneously across three files.
- **O-V2 — Extend `.githooks/pre-commit` parity check to the `append-retrospective-entry` script copies.** Reuses the proven ICON-0011 pattern.
- **O-T1 — Formal always-loaded token-budget audit.** Two cycles open; the next always-loaded addition will exceed natural thresholds without a gate. (Token-efficiency focus from this audit's user directive.)
- **O-T4 — Trim `writing-skills` to its own cap by extracting the Skill Creation Checklist.** Closes the defining self-reference violation.

### Tier 4 — Sweep-and-batch hygiene (low-impact carry-forwards)

The Tier 4 batch is a single hygiene PR that closes ~18 long-standing minors plus this cycle's trivial net-new items:

- O-T2 / O-T3 (reviewer trim + template-override collapse — small token-efficiency wins)
- O-D3 / O-D4 (PM session-start parity + mr-discipline cue)
- O-S6 / O-S7 / O-S8 (drift-trigger spec extraction + footer alignment + initialize-workspace MR template fix)
- O-M2 / O-M3 (icon-status `/release-plugin` policy + LICENSE file)
- O-X1 (the long-tail minor sweep)
- O-X3 (defense-in-depth `disable-model-invocation: true` propagation)

### Tier 5 — New capabilities (forward-looking)

- **O-M1 — Add a "sweep user-facing docs" reminder bullet to `release-plugin` Step 1 (pre-tag-move).** Manual reminder for the maintainer (not an automated CHANGELOG generator). Catches the M-CC-NET1 class at tag-move time rather than the next audit.
- **O-S3 — Targeted generalizable-content review** for the local `.context/workflows/task-plan/phase-*.md` files vs `context_template/...` base templates. Identify content that should propagate to base templates; leave repo-specific text alone.
- **O-M4 — `bump-versions.sh` dry-run + monotonicity check.**
- **O-X2 — Re-tier the third-cycle and fourth-cycle carry-forwards** (format-slack.sh strict mode; prune-context.sh `2>/dev/null`) to "watch / accepted" with a `.context/decisions.md` ADR — though note this is a local-to-this-repo decision, not a plugin-wide one.

---

## Open Questions for the User

1. **Pre-tag-move doc-sweep scope?** The next `latest`-tag move accumulates ICON-0011/0012/0013/0014 into a single release. CHANGELOG is handled by `release-plugin` Step 5 (the skill authors the versioned section from the git diff + commit log between the last release commit and HEAD). The remaining question is the **doc-sweep scope** — should the pre-tag-move sweep cover only the user-facing surfaces (`README.md`, `.claude/claude.md`, `commands/`) or also the `.iconrc.json`-defaulting prose in `context_template/`? Recommend the narrow scope (user-facing only) for the tag-move PR; broader sweeps can be follow-ups.

2. **`manager.agent.md:151` resolution — delete or inline?** O-S1 closes M-CC-NET3 by either deleting the `three-layer-enforcement.md` reference (simplest, the surrounding bullet still functions) or inlining the layer definitions into the manager body (preserves the intent of the original MKT-0059 change). Recommend delete: the surrounding bullet ("name all three layers and their exact file locations") is self-sufficient. The layer cascade rule is already encoded in the agent's Behavior Tiers section.

3. **Re-tier decision for the third-cycle and fourth-cycle carry-forwards?** The `format-slack.sh` strict-mode finding (m-U-K / m-4) is now in its third audit cycle; `prune-context.sh` `2>/dev/null` (m1) is in its fourth. Brief 05 § "format-slack.sh strict mode (m-4): third carry-forward cycle" recommends explicit re-tier to "watch / accepted" rather than re-surfacing them as Minors next cycle. Where would you record the re-tier — a maintainer-facing ADR-style doc shipped with the plugin (in `shared/` or as a comment in the relevant skill SKILL.md), or this repo's local `.context/decisions.md`? The latter doesn't propagate to consumers, which is correct if the decision is project-local; if the re-tier reflects a plugin-wide stance, a shipped artifact is better.

4. **Pre-commit hook strategy: one hook with N checks, or N hooks?** O-V2, O-V4 want to extend `.githooks/pre-commit`. The hook already carries the common-constraints sync (ICON-0011/0013). Recommended: one hook with multiple checks (the script can branch on the path of files in the staged set). Open question: do you want the hook to **fail** on placeholder / parity / reference violations, or **warn-and-stage** in the style of the common-constraints auto-rewrite? Recommend fail-fast for placeholders and reference violations (no auto-fix exists).

5. **Maintainer-orientation surface — where does the pre-tag-move release checklist live?** O-M1 (sweep user-facing docs before tag-move) needs a home. Two options: (a) inline in `.claude/skills/release-plugin/SKILL.md` Step 1 (lives with the release flow itself); (b) a new `.claude/MAINTAINING.md` or similar maintainer-only doc. Recommend (a) — the release skill is the natural call-site and won't drift.

---

## Suggested Follow-up Tasks

Each task below is independent and can be triaged by priority and available bandwidth. **Per the audit's data-exfiltration constraint, the task-ID slots are local recommendations — please confirm before filing as GitLab issues.**

- **ICON-0016 — Pre-tag-move doc-sweep PR (Tier 2).** Closes M-CC-NET1. Sweep of `README.md:100,:110`, `.claude/claude.md:9`, `commands/enable-manager-default.md:7`, `commands/disable-manager-default.md:7` for post-ICON-0012 hook architecture descriptions. CHANGELOG is handled by `release-plugin` Step 5 at the tag-move itself, not in this PR. Low effort; clears the path for the next `latest`-tag move.
- **ICON-0017 — Resolve `manager.agent.md:151` `three-layer-enforcement.md` reference (Tier 2).** Closes M-CC-NET3. Trivial. Recommend deletion (the surrounding bullet still functions); inline option also acceptable. Do NOT create the missing file in `.context/` — that would put plugin-shipped content into the repo-local layer.
- **ICON-0018 — Plugin-audit brief placeholder sweep (Tier 2).** Replace `<path-to-prior-audit-report.md>` with a discovery command across all six briefs. Closes M-U-A. Trivial effort.
- **ICON-0019 — Canonicalize `retrospectives.md` write path + close `agent-vs-skill-invocation.md:63` "Known unresolved" (Tier 2).** Closes M-CC-NET2 / M-P-B. Choose Option A (align manager.agent.md:204 to specialist path) or Option B (align task-retrospective:113 to manager path) and update all three surfaces. Low effort.
- **ICON-0020 — `merge-phase-templates` Step 2 routing table fix (Tier 2).** Add `phase-testing.md` as a routing destination. Closes M-I-A. Trivial.
- **ICON-0021 — Pre-commit hook extension PR (Tier 3).** Bundles O-V2 (script parity for the two `append-retrospective-entry.{sh,ps1}` copies) + O-V4 (angle-bracket placeholders + unresolvable references). Closes the M-CC1 recurrence vector mechanically. Low-to-medium effort; high recurrence-prevention payoff.
- **ICON-0022 — Init-orchestrator entry-point detection single-sourcing (Tier 3).** O-S5; closes a 6-copy drift surface. Medium effort.
- **ICON-0023 — Token-economy audit and budget document (Tier 3).** O-T1 / O-T4 — formal always-loaded surface inventory + per-component cap + `writing-skills` extraction. Medium effort. Pairs with the user's stated token-efficiency focus.
- **ICON-0024 — Tier-4 hygiene sweep PR.** Bundles ~18 trivial-effort minors per Tier 4. Closes the long tail.
- **ICON-0025 — Maintainer-orientation: pre-tag-move checklist in `release-plugin/SKILL.md` (Tier 5).** O-M1 — add a "sweep user-facing docs" bullet to `.claude/skills/release-plugin/SKILL.md` Step 1, so the M-CC-NET1 pattern is caught at tag-move time. Optionally: O-S3 base-template-promotion review for the ICON-repo-local phase-template customizations.
