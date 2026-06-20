# Cross-Cutting Audit — Raw Findings

**Auditor:** ICON-0015 synthesis agent (Brief 06)
**Date:** 2026-05-20
**Plugin version on main:** 1.15.4 (ICON-0011/0012 merged post-tag; ICON-0013/0014 on unmerged feature branches)
**Inputs consumed:** Briefs 01–05; `retrospectives.md` (8 entries, ICON-0001–ICON-0014); `README.md`; `CHANGELOG.md`

---

## Summary

The ICON plugin at v1.15.4 is in materially better cross-cutting health than the ICON-0003 baseline: eight Moderate/Minor cross-cutting concerns from that report are confirmed fixed, the three-layer-enforcement discipline has held structurally, and the sweep-incompleteness pattern (M-CC1) shows evidence of stabilization at the companion-file level. Two structural concerns dominate this cycle. First, a cluster of features that are complete on feature branches but absent from `main` — ICON-0013 (fence-aware pre-commit) and ICON-0014 (plan.md freshness gate) — has produced a multi-surface documentation drift that simultaneously creates: two unmerged working features, a missing CHANGELOG `[Unreleased]` block, documentation contradictions in README and `.claude/claude.md` (Brief 05 M-N1/M-N2), and a gating step every task completion runs without. This cluster is treated as a single net-new structural concern (M-CC-NET1). Second, the always-loaded token surface has grown without an explicit budget: manager or PM (3,951 / 2,650 words) + 9× inlined common-constraints (~3,186 words) + `using-skills` (728 words) = 7,865–9,078 words before any sub-agent body loads. At this volume, the common-constraints block alone (354 words × 9 agents ≈ 3,186 words) represents 35–40% of the dispatcher's always-loaded surface, a share large enough to warrant the formal budget audit that O-T2 from ICON-0003 called for but never received. No Critical cross-cutting defects are present. The retrospective analysis surfaces two recurring failure classes that have now met the 3-entry threshold for standardization consideration: cross-surface sweep depth on companion files (6 entries) and distribution-mirror sync (implicitly present in 3+ entries since ICON-0014 codified the three-surface rule).

---

## Defect Findings

### Critical

None observed.

---

### Moderate

#### M-CC-NET1 — Unmerged-branch + missing-CHANGELOG cluster (net-new)

Two feature branches — `feature/ICON-0013-fence-aware-pre-commit-hook` and `feature/ICON-0014-plan-md-freshness-gate` — are complete by their own plan.md Progress records but have not been merged to `main`. This produces a compound documentation drift across six surfaces simultaneously:

1. **CHANGELOG `[Unreleased]` block is silent on ICON-0013 and ICON-0014.** `CHANGELOG.md:9-21` (the entire `[Unreleased]` block) contains only ICON-0011 and ICON-0012 entries. ICON-0013 and ICON-0014 are not mentioned anywhere in the file. `CHANGELOG.md:1-21` confirmed via search for "ICON-0013", "ICON-0014", "fence-aware", "freshness" — zero results.

2. **README `Default Role` section describes pre-ICON-0012 architecture** (Brief 05 M-N1): `README.md:100,:110` still references `~/.claude/settings.json` hook wiring and describes `/ICON:disable-manager-default` as "Remove the SessionStart hook," both of which are false post-ICON-0012.

3. **`.claude/claude.md:9` tech-stack line is stale** (Brief 05 M-N2): references "two `hooks/inject-manager-role.*` scripts" while only `hooks/inject-manager-role.mjs` exists post-ICON-0012.

4. **`manager.agent.md` on `main` lacks step 0** (Brief 01 M-A-NET2, Brief 05 m-n4): the plan.md freshness gate ICON-0014 introduced is entirely absent from the production agent. Every task completion between branch-cut and merge runs without the gate.

5. **Five skills on `main` lack their ICON-0014 wiring** (Brief 02 m-P-7): `skills/task-plan-phase-completion/SKILL.md`, `skills/mr-discipline/SKILL.md`, `skills/task-retrospective/SKILL.md`, `.context/workflows/task-plan/phase-completion.md`, and `context_template/context/workflows/task-plan/phase-completion.md` all lack their respective ICON-0014 additions.

6. **`commands/enable-manager-default.md:7` and `commands/disable-manager-default.md:7`** (Brief 05 m-n1) describe ICON-0012 behavior as "Starting with ICON 1.16" while the current released version is `1.15.4`.

The root cause is a single process gap: two complete features have accumulated on unmerged branches without triggering a CHANGELOG entry, without prompting a README sweep, and without having their `[Unreleased]` block entries written. The gap between "feature-branch complete" and "main reflects the feature" is wider here than in any prior cycle: ICON-0012 merged to main without a version bump (acceptable per batch-release policy) and ICON-0013/0014 are pending merge entirely.

**Impact:** User-facing documentation actively contradicts the runtime behavior of every session. The plan.md freshness gate — ICON-0014's design objective across a full task cycle — is unenforced on production. The CHANGELOG is the canonical record of what the plugin does; its silence on two features undermines the release narrative.

**Locations:**
- `CHANGELOG.md:9-21` (missing ICON-0013, ICON-0014 entries)
- `README.md:100,:110` (stale hook description — Brief 05 M-N1)
- `.claude/claude.md:9` (stale tech-stack — Brief 05 M-N2)
- `agents/manager.agent.md` on `main` (missing step 0 — Brief 01 M-A-NET2)
- `commands/enable-manager-default.md:7`, `commands/disable-manager-default.md:7` (version-anticipation — Brief 05 m-n1)

---

#### M-CC-NET2 — `retrospectives.md` write-path contradiction is documented but untracked (net-new cross-cutting framing of Brief 02 M-P-B)

`manager.agent.md:204` and `task-retrospective/SKILL.md:113` describe mutually exclusive paths for writing retrospective entries. The `task-plan-phase-completion/agent-vs-skill-invocation.md:63` SSOT explicitly acknowledges this as "Known unresolved" with a stated preference for the specialist path but no resolution date, issue number, or ADR reference. This has been on disk since ICON-0006 (v1.15.4, 2026-05-15) — over a full sprint.

The cross-cutting dimension: this is not merely a process-skill contradiction. It creates a three-layer-enforcement gap. The manager's Hardcoded tier (`manager.agent.md:204`: "written directly by the manager") contradicts the Default-tier skill invocation path (`task-retrospective/SKILL.md:113`: "delegate to @context-specialist"). A Hardcoded constraint should override the skill path, but the skill explicitly recommends the opposite. Any auditor applying the three-layer-enforcement model to this rule finds no stable answer — two of the three layers are contradictory, and the third layer (the SSOT reference file) explicitly refuses to resolve it.

**Impact:** Every retrospective-entry authoring path is ambiguous. Without a canonical choice, behavior depends on which surface the manager reads first.

**Locations:** (as cited in Brief 02 M-P-B)
- `agents/manager.agent.md:204`
- `skills/task-retrospective/SKILL.md:113`
- `skills/task-plan-phase-completion/agent-vs-skill-invocation.md:63`

---

#### M-CC-NET3 — Dead cross-reference to `.context/standards/three-layer-enforcement.md` (net-new cross-cutting framing of Brief 01 M-A-NET1)

`agents/manager.agent.md:151` directs the manager to see `.context/standards/three-layer-enforcement.md` for layer definitions and delegation notes. That file does not exist — `.context/standards/` contains only `changelog-discipline.md` and `skill-decomposition.md`. This dead reference was introduced in MKT-0059 and has persisted through ICON-0001, ICON-0003, and this cycle. The cross-cutting dimension: the three-layer enforcement model is the ICON plugin's primary mechanism for ensuring rule durability across edits. Without the referenced standard document, agents operating on delegation templates that touch three-layer-enforced rules receive a broken cross-reference at the critical moment they need it most.

**Location:** `agents/manager.agent.md:151`; `.context/standards/` (missing `three-layer-enforcement.md`)

---

### Minor

#### m-CC-1 (carry-forward from ICON-0003 m-CC1) — README `Default Role` section has no "not yet migrated" sweep companion

`README.md:27` ("Design Principles") uses the parenthetical `(.github/copilot-instructions.md if not yet migrated)` as a fallback qualifier alongside `.claude/claude.md`. This framing is consistent with `start-worktree/SKILL.md:87,:111,:162` (Brief 04 m-U-C, still present). However, since MKT-0089 shipped the modern path as standard, the "not yet migrated" language in the README's own Design Principles section misleads new installers about the expected project state.

**Location:** `README.md:27`

---

#### m-CC-2 (net-new) — `using-skills` Skill Priority chain omits the task-plan phase-skill sequence

`skills/using-skills/SKILL.md:64-67` defines a four-priority invocation order (Process → Discipline → Maintenance → Formatting). The example at line 68 ("Fix this bug and write tests for it → `systematic-debugging` → `testing-discipline` → `verification-checklist`") demonstrates a debugging chain but provides no task-plan phase-skill invocation chain example. A manager loading `using-skills` sees no model for how to sequence `task-plan` → `task-plan-phase-investigation` → `task-plan-phase-implementation` → `task-plan-phase-completion` → `task-retrospective`. The skill that most frequently guides dispatcher decisions has no example of the dominant workflow chain.

**Location:** `skills/using-skills/SKILL.md:64-68`

---

#### m-CC-3 (carry-forward from ICON-0003 m-CC3) — CHANGELOG `[Unreleased]` missing entries for ICON-0013 and ICON-0014

Confirmed zero occurrences of "ICON-0013" and "ICON-0014" in `CHANGELOG.md`. The `[Unreleased]` block at `CHANGELOG.md:9-21` covers only ICON-0011 (pre-commit hook) and ICON-0012 (plugin-scoped hook). This is a subset of M-CC-NET1 above but is also independently a changelog discipline violation: `.context/standards/changelog-discipline.md` (introduced MKT-0079) requires entries at the time changes land on main. ICON-0013/0014 have not landed yet, but once they do, the entries must be pre-written or written in the same commit per the discipline standard.

**Location:** `CHANGELOG.md:9-21`; `.context/standards/changelog-discipline.md` (requirement)

---

#### m-CC-4 (net-new) — Distribution-mirror sync gap is systemic across all five phase-skill workflow templates (cross-cutting framing of Brief 02 M-P-A)

All five `context_template/context/workflows/task-plan/phase-*.md` mirrors are one or more template-versions behind their local SSOT counterparts (Brief 02 M-P-A). This is not merely a process-skill defect — it represents a cross-cutting failure of the three-surface rule that ICON-0014 is codifying. The rule requires: local `.context/` SSOT ↔ `context_template/` mirror ↔ `skills/<phase>/SKILL.md` fallback to stay in sync. All three surfaces exist; only one sync pair is maintained. The ICON-0014 merge will fix one of the five mirrors (`phase-completion.md`); the other four remain at version 1.0 while their local counterparts are at version 1.1.

**Locations:** (as cited in Brief 02 M-P-A)
- `.context/workflows/task-plan/phase-*.md` (versions 1.1–1.2) vs `context_template/context/workflows/task-plan/phase-*.md` (versions 1.0–1.1)

---

## Improvement Opportunities

### Token Efficiency

#### IO-CC-T1 — Conduct the formal always-loaded token budget audit (O-T2 from ICON-0003, still open)

**Description:** The always-loaded dispatcher surface (for a manager session) is currently: `manager.agent.md` (3,951 words) + 9× inlined common-constraints (354 words × 9 ≈ 3,186 words) + `using-skills` (728 words) = approximately 7,865 words before any sub-agent body loads. For a PM session, substitute `product-manager.agent.md` (2,650 words) for manager: approximately 6,564 words. The common-constraints inlining alone represents ~35–40% of the dispatcher's total always-loaded load. No explicit budget exists. The next always-loaded addition (e.g., if ICON-0014's step 0 or a future hook audit finding causes manager.agent.md to grow by another 30 lines) will push the surface past a natural threshold without any gate.

**Proposed action:** Define an explicit word budget for the dispatcher always-loaded surface (e.g., 8,000 words for manager session, 7,000 for PM session). Audit each component against the budget. Flag any single-component that exceeds 40% of the budget as a trim candidate. The common-constraints inlining is accepted-by-design per ADR-004; this audit should evaluate everything else.

**Effort: medium. Impact: high.** Closes O-T2 (ICON-0003 carry-forward, two audit cycles open).

---

#### IO-CC-T2 — Trim `reviewer.agent.md` Default-tier redundant category list (cross-cutting framing of Brief 01 IO-A5)

**Description:** `reviewer.agent.md:68` repeats verbatim the six-category list already present at `reviewer.agent.md:25`. The Default tier adds no decision value that the skill invocation at `reviewer.agent.md:25` doesn't already enforce. A 14-word reduction, no information loss. This is a micro-efficiency but exemplifies the class of always-loaded surface trimming that accumulates meaningfully across the reviewer's full session.

**Effort: trivial. Impact: low.** Closes Brief 01 m-A-NET3.

---

#### IO-CC-T3 — Collapse the 5× template-override rule paragraphs to a single-line reference (cross-cutting framing of Brief 02 IO-P-6)

**Description:** Each of the five phase-skill SKILL.md files carries a 5-line "Template-override rule" paragraph that is structurally identical across all five. When multiple phase skills load in a session, this content appears 5× with no additional decision value past the first occurrence. Moving the full explanation to `task-plan/SKILL.md` (the dispatcher) and replacing each phase skill's paragraph with a one-line pointer reduces token load across concurrent phase loads.

**Effort: low. Impact: low-medium.** Closes Brief 02 IO-P-6.

---

### Discoverability

#### IO-CC-D1 — Add task-plan phase-skill chain to `using-skills` Skill Priority example (closes m-CC-2)

**Description:** `using-skills/SKILL.md:68` currently exemplifies only the debugging chain (`systematic-debugging` → `testing-discipline` → `verification-checklist`). Adding a second example for the task-completion chain — "`task-plan` → `task-plan-phase-investigation` → `task-plan-phase-implementation` → `task-plan-phase-completion` → `task-retrospective`" — gives dispatchers a model for the most frequent workflow path. A one-row addition to the example following the existing model.

**Effort: trivial. Impact: medium.** The task-plan chain is the dominant orchestration path and currently has zero representation in the skill-invocation guide.

---

#### IO-CC-D2 — Resolve README `Default Role` description to reflect post-ICON-0012 hook architecture (part of M-CC-NET1, Brief 05 O-I1)

**Description:** `README.md:100,:110` should be swept in the same commit that bumps the version for ICON-0011/0012. The corrected description: (a) replace "This wires a `SessionStart` hook into your `~/.claude/settings.json`" with "Starting with ICON 1.16, the SessionStart hook is declared in the plugin's own `hooks/hooks.json` and activates automatically on install — no user-side setup required"; (b) replace "Remove the SessionStart hook" with "Disable the automatic manager-default behavior (sets `managerDefault: false` in `~/.claude/icon-user-settings.json`)."

**Effort: trivial. Impact: high.** Closes Brief 05 M-N1 as part of the next version-bump PR.

---

#### IO-CC-D3 — Extend `using-skills` Skill Priority to name the `mr-discipline` gate explicitly

**Description:** `using-skills/SKILL.md:66` lists "Discipline skills — `verification-checklist`, `commit-discipline`, `mr-discipline`" in the priority ordering, which is correct. However, no example in the file demonstrates an MR-opening chain. A one-sentence example: "Opening an MR: `mr-discipline` → `verification-checklist`" would make the gate discoverable at first read. Currently no agent file references `mr-discipline` either (Brief 01 m-A-5), making `using-skills` the only discovery surface.

**Effort: trivial. Impact: medium.** Complements Brief 01 IO-A4 (adding `mr-discipline` cue to manager task completion).

---

### Consolidation

#### IO-CC-C1 — Create `.context/standards/three-layer-enforcement.md` (closes M-CC-NET3, Brief 01 IO-A1)

**Description:** Write the missing standard document that `manager.agent.md:151` has referenced since MKT-0059. Content is derivable from `skill-decomposition.md`, the ICON-0007 retro lesson (routing rules appear in role intro, scope/skip guards, mode tables, dispatch routing, Hardcoded constraints, Default/Discretionary tiers, sibling routing-guide tables), and the ADR-004 load-bearing redundancy principle. A 30–50 line document covering the three layer definitions ("Hardcoded Behavior Tier," "Default Behavior Tier," "Discretionary Tier"), the enforcement cascade rule (Hardcoded overrides Default overrides Discretionary), and delegation notes for three-layer-enforced rules would resolve the dead-reference defect and provide the intended enforcement guidance.

**Effort: low. Impact: high.** Closes the only agent-domain Moderate that can be addressed without a branch merge.

---

#### IO-CC-C2 — Bundle the four remaining distribution-mirror syncs into the ICON-0014 merge PR (closes m-CC-4, Brief 02 IO-P-3)

**Description:** ICON-0014's merge will bump `phase-completion.md` mirror to 1.3. The other four mirrors (`phase-implementation.md`, `phase-investigation.md`, `phase-architecture.md`, `phase-testing.md`) are all at 1.0, behind their local 1.1 counterparts. Bundling all four sync sweeps into the same PR closes the distribution-mirror gap in one shot rather than leaving four mirrors at stale versions. The ICON-0014 branch already provides the model for how to generalize ICON-specific content when mirroring to `context_template/`.

**Effort: low. Impact: medium.** Closes M-P-A (Brief 02) systemically.

---

### Missing Skills

#### IO-CC-M1 — Canonicalize the retrospectives.md write path and close the "Known unresolved" in `agent-vs-skill-invocation.md` (closes M-CC-NET2, Brief 02 IO-P-1)

**Description:** The "Known unresolved" block at `task-plan-phase-completion/agent-vs-skill-invocation.md:63` is a documented three-layer-enforcement gap with no resolution anchor. The two options are: (a) amend `manager.agent.md:204` to align with the specialist-delegation path — "drafted by the manager, then inserted via @context-specialist with the append script"; or (b) change `task-retrospective/SKILL.md:113` to specify that the manager runs the local `./scripts/append-retrospective-entry.sh` inline and remove the specialist-delegation path for entry append. The SSOT itself states a preference for the specialist path; option (a) aligns the Hardcoded tier with the stated preference. Whichever path is chosen, the "Known unresolved" block must be replaced with the resolution text and a cross-reference to the ADR or commit that decided it.

**Effort: low. Impact: medium.** Closes Brief 02 M-P-B and the most consequential "Known unresolved" on disk.

---

#### IO-CC-M2 — Add a pre-commit parity gate for the two `append-retrospective-entry` script copies (Brief 04 IO-U5)

**Description:** `skills/post-incident-review/scripts/append-retrospective-entry.{sh,ps1}` and `skills/task-retrospective/scripts/append-retrospective-entry.{sh,ps1}` are currently byte-identical (confirmed in Brief 04). The `.githooks/pre-commit` hook already enforces byte-equality for common-constraints. Adding a two-line diff check for the append-retrospective-entry scripts converts the SSOT risk (Brief 04 m-U-J) from a periodic audit finding into a commit-time gate, following the same pattern that closed M-A2 via ICON-0011.

**Effort: low. Impact: medium.** Closes Brief 04 m-U-J; extends the pre-commit hook's enforcement scope to a second two-copy SSOT.

---

### Self-Verification

#### IO-CC-V1 — Add a doc-sweep reminder to `release-plugin` Step 1 for unreleased-on-main drift (Brief 05 O-I7)

**Description:** The "unreleased on main" pattern (ICON-0011/0012 landing on main before a version bump) predictably creates documentation-drift windows where `README.md` and `.claude/claude.md` describe the last-released behavior, not current-main behavior. `release-plugin/SKILL.md` Step 1 currently says "Verify you are on main and the working tree is clean" but does not prompt a doc-drift sweep. Adding a one-bullet "sweep user-facing docs (`README.md`, `.claude/claude.md`, `commands/`) for behavioral drift vs. current-main before cutting the release" would catch M-N1/M-N2 class findings at release time rather than at the next audit.

**Effort: low. Impact: medium.** Closes Brief 05 O-I7; prevents the documentation-drift pattern from recurring post-merge.

---

#### IO-CC-V2 — Replace `<path-to-prior-audit-report.md>` placeholder in all six `plugin-audit` briefs with a discovery command (Brief 04 IO-U1)

**Description:** All six `plugin-audit/briefs/0*.md` files contain an unfilled `<path-to-prior-audit-report.md>` template placeholder (Brief 04 M-U-A). ICON-0004 swept path strings but did not resolve angle-bracket placeholders. The fix: replace the placeholder at each brief's Inputs section with a bash discovery command: `ls .context/tasks/*/audit-report.md | sort | tail -1`. Alternatively, instruct sub-agents to "read plan.md § Phase 1 Baseline Preamble for the prior-audit path." Either approach eliminates the manager workaround that each plugin-audit invocation currently requires. This is the single highest-leverage trivial fix in the utility-skills domain with direct cross-cutting impact.

**Effort: trivial. Impact: high.** Closes Brief 04 M-U-A across all six briefs in a single sweep.

---

## Token Economics Analysis

### Always-Loaded Surface Inventory

The following surfaces load on every dispatcher session (manager OR PM):

| Surface | Lines | Words | Notes |
|---------|-------|-------|-------|
| `agents/manager.agent.md` | 287 | 3,951 | Manager sessions |
| `agents/product-manager.agent.md` | 267 | 2,650 | PM sessions |
| `shared/common-constraints.md` (×9, inlined) | 21×9=189 | 354×9≈3,186 | Byte-identical copies; accepted by design (ADR-004) |
| `skills/using-skills/SKILL.md` | 90 | 728 | Loaded at dispatcher Session Start |
| **Manager session total** | — | **≈7,865** | (manager + 9× constraints + using-skills) |
| **PM session total** | — | **≈6,564** | (PM + 9× constraints + using-skills) |

Sub-agent bodies load on-demand per dispatch; they are not always-loaded. Typical sub-agent word counts: `coder.agent.md` 981 words, `reviewer.agent.md` 1,057, `tester.agent.md` 1,173, `researcher.agent.md` 1,342.

### On-Demand (Not Always-Loaded)

- `manager-routing-guide/SKILL.md` — loaded when manager makes routing decisions
- `task-plan/SKILL.md` + phase skills — loaded per task phase
- All 35+ other skills — loaded on trigger only
- Sub-agent bodies — loaded per dispatch

### Highest-Impact Trim Candidates

1. **9× common-constraints inlining (~3,186 words)** — accepted-by-design per ADR-004 (pre-commit hook enforces byte-equality). No action per audit scope constraints. Still 35–40% of the dispatcher's always-loaded surface.

2. **Manager agent body (3,951 words)** — 287 lines. No single section dominates. The Delegation section (lines ~140–175) is verbose relative to the "delegate goals not scripts" principle it encodes; the delegation template at lines ~151–165 contains the dead cross-reference (M-CC-NET3) and could be trimmed once the standards document exists. Estimated trim potential: 20–40 words without information loss.

3. **5× phase-skill template-override paragraphs** — when multiple phase skills fire in one session, 25 lines of near-identical content load. IO-CC-T3 above addresses this.

4. **No explicit budget gate exists.** The next always-loaded addition will push the surface past the natural 8,000-word threshold without any mechanism to force a trim trade-off. IO-CC-T1 addresses this.

### Token Efficiency Movement Since ICON-0003

ICON-0003 listed O-T1 (single-source common-constraints) and O-T2 (formal token budget audit) as Tier 3 improvements. Neither has been actioned. However, the 6-skill token-efficiency extraction pass (MKT-0085) moved heavy examples out of `rfc`, `post-meeting`, `sprint-goals`, `context-specialist-impl-leaf`, `context-maintenance`, and `ecological-impact` into sibling files — this was a meaningful win for on-demand skills. The always-loaded surface itself has not been trimmed.

---

## Discoverability UX Analysis

### README Skills Table

The README skills table at `README.md:149-205` is well-maintained at the structural level: it correctly segregates user-facing skills (the top 20-row table) from internal skills (the second 24-row table). `mr-discipline` is listed at `README.md:194` (confirmed present — this was a gap in ICON-0003). `systematic-debugging` and `verification-checklist` are listed. `task-plan-phase-*` skills are listed in the internal table with accurate phase descriptions.

**Gap 1:** `README.md:100,:110` (Default Role section) describes pre-ICON-0012 behavior (M-CC-NET1 / Brief 05 M-N1). New users following the README will form a wrong mental model of how the manager-default feature works.

**Gap 2:** `README.md:27` (Design Principles) uses "`.github/copilot-instructions.md` if not yet migrated" framing that is dated post-MKT-0089. A new user reading the Design Principles block before installation will normalize the pre-migration path as current. The fallback mention is arguably correct (the plugin still supports it), but the "if not yet migrated" framing implies migration is expected — which is inconsistent with a new installation.

**Gap 3:** The skills table has no column for skill chains or "typical sequence." A user wanting to know "how do I start a task?" can find `icon-status` (return after a break) and `icon-init` (first time) in the intent index, but there is no entry for "I want to work a task end-to-end." The `using-skills` skill covers this but is listed as internal (not user-invocable). The intent index at `README.md:34-49` is the primary discovery surface; it has 8 rows covering setup and meta-operations but no row for "I want to start a development task."

### `using-skills` Common Workflows Table

The MKT-0084 refactor dropped the `using-skills` Common Workflows table entirely in favor of the Skill Priority ordering and rationalization-prevention content. The current `using-skills/SKILL.md` provides a 4-tier priority order (lines 64-67) with one example chain (line 68). The dropped table was explicitly called for in ICON-0003 as O-D2. The current design is leaner but leaves the task-plan phase-skill chain undiscoverable unless the user reads each phase-skill frontmatter individually.

**Gap:** No model chain for the dominant orchestration workflow (task-plan → phase skills → completion → retrospective). IO-CC-D1 addresses this.

### Onboarding Flow Cohesion

`README.md:34-49` (intent index) correctly covers: install, new-repo setup, returning after a break, upgrading, MCP credentials, manager-default role, mid-session switching, multi-project repos, skill authoring, and skill browsing. This is a well-designed entry surface.

**Improvement opportunity:** "I want to start a development task" is absent from the intent index. A user who has installed ICON and initialized their repo but wants to know how to actually start working has no README row pointing them to `@manager` and the task-plan workflow. This is the plugin's primary use case and it has no intent-index entry. Adding one row — "I want to start a development task | Invoke `@manager` and describe the task | [Workflow](#workflow)" — closes a first-use discoverability gap without any structural change.

### Internal vs User-Facing Skill Segregation

The README correctly segregates user-facing and internal skills into two tables. All skills marked `user-invocable: false` in their frontmatter appear in the internal table. The segregation is internally consistent. The one tension: `using-skills` appears in the internal table (correct) but is described in its own frontmatter description as "MANDATORY — execute this skill before starting any task" — language that implies user action but is actually directed at agent behavior. This is not a defect but is a UX signal that the description was written for the agent audience, not the user audience.

---

## Retrospective Pattern Analysis

All 8 retrospectives (ICON-0001 through ICON-0014, the ICON-0014 entry being on the feature branch) were read in full. The following failure classes have appeared in 3 or more entries.

### Pattern A — Cross-Surface Sweep Depth on Companion Files (6 entries)

**Definition:** A sweep visits the primary SKILL.md surface but stops short of companion files (briefs/, scripts/, examples/, distribution mirrors, sibling routing tables, CHANGELOG, commands/).

**Occurrences:**
1. **ICON-0003:** Plugin-audit SKILL.md swept for `plugins/<plugin>/` paths; briefs not swept. M-U1. Retro: "sweep visits primary surface, stops short of companion files."
2. **ICON-0004:** Path-string sweep executed on 8 files; briefs' angle-bracket placeholders not resolved. Retro: "validate that enumerated inputs in companion files still resolve."
3. **ICON-0007:** Routing-rule change treated as a 2-file edit; four additional contradictions in role intro, Hardcoded constraint, Scope guard, and Discretionary tier were missed. Retro: "a routing-rule change is an agent-file sweep, not a dispatch-block edit."
4. **ICON-0008:** Step renumbering created backref drift potential in Common Mistakes table; caught by reviewer. Retro: "renumbering steps without an automated check that every inline backref points at the new numbering."
5. **ICON-0011:** Prior-audit byte-equality certifications treated as live truth; whitespace drift had accumulated on all 9 agents. Retro: "for invariants enforced by author discipline, never plan around prior-audit claims."
6. **ICON-0014** (on feature branch): three-surface rule codified in ICON-0014's own `skill-decomposition.md` update, but the four remaining phase-skill mirrors were not swept. The rule's own defining commit left 4 of 5 mirrors stale.

**Current on-disk instances:**
- Brief 04 M-U-A: all six plugin-audit briefs contain the `<path-to-prior-audit-report.md>` placeholder (ICON-0004 sweep did not catch angle-bracket form)
- Brief 02 M-P-A: five distribution mirrors stale (ICON-0014's three-surface rule did not sweep all five)
- Brief 01 M-A-NET1: dead cross-reference in manager delegation template (MKT-0059 sweep did not create the referenced document)

**Assessment:** This is the single most recurring failure class in the ICON retrospective history. The retros have correctly named it (ICON-0003, ICON-0004, ICON-0007), but the fix has always been editorial (restate the rule) rather than structural (automate the check). The pattern has now appeared 6 times across 8 tasks.

**Standardization candidate:** A pre-commit or post-commit grep that enumerates angle-bracket placeholders and cross-referenced file paths in modified `skills/*/` files and exits 1 if any placeholder is unfilled or any referenced file does not exist. This is the `O-V2` improvement from ICON-0003 (promoted from skill-folder scope to automated enforcement) that has not been implemented.

---

### Pattern B — Distribution-Mirror Sync (3+ entries, implicit)

**Definition:** A change to a local `.context/` SSOT document is not mirrored to the corresponding `context_template/` copy, or vice versa, leaving installed-plugin consumers on an older version of the process.

**Occurrences:**
1. **ICON-0006:** `task-plan-phase-completion/SKILL.md` updated to route through @context-specialist; no corresponding update to `context_template/` phase templates.
2. **ICON-0014:** Three-surface rule codified; `phase-completion.md` mirror bumped to 1.3 on the feature branch; four other mirrors not touched.
3. **ICON-0015 (this cycle):** M-P-A surfaces that all five distribution mirrors are stale (1.0 vs local 1.1 for four; 1.1 vs 1.3 for phase-completion).

**Assessment:** The three-surface rule codified in ICON-0014 is the correct response to this pattern. However, the rule was applied retroactively to only one of five files. The mechanical enforcement gap is that no automated check verifies template-version parity between local and `context_template/` copies. A two-line `grep` comparing `<!-- template-version:` strings across the two directories would catch drift at commit time.

**Standardization candidate:** Add a `template-version` parity check to `.githooks/pre-commit`: if any `.context/workflows/task-plan/phase-*.md` is modified, verify the corresponding `context_template/context/workflows/task-plan/phase-*.md` carries the same `<!-- template-version: X.Y -->` value, or fail with a message naming the out-of-sync file.

---

### Pattern C — Routing Rule Appearing in Multiple Agent Sections (5 entries, risk-level)

**Definition:** A routing rule is added to one section of an agent file without sweeping all other sections where the same rule should appear (role intro, scope/skip guards, mode tables, dispatch routing, Hardcoded constraints, Default/Discretionary tiers).

**Occurrences:**
1. **ICON-0007:** Context-specialist `mode: upgrade` routing contradiction — Hardcoded constraint, role intro, Scope guard, Discretionary tier all diverged. Retro explicitly codified the multi-section sweep requirement.
2. **ICON-0003 M-I1:** Same context-specialist routing contradiction, pre-ICON-0007.
3. **ICON-0012 (implied):** README and `.claude/claude.md` not swept when hook architecture changed.
4. **ICON-0014 (M-A-NET2):** ICON-0014 manager changes not yet propagated to main.
5. **ICON-0011 (Structural Observation 2):** Common-constraints drift across agents despite author discipline; hook enforces it now.

**Assessment:** The ICON-0007 retro correctly named the multi-section sweep pattern and the grep command to enforce it. The on-disk standing from this cycle is that `mr-discipline` is absent from all 9 agent files (Brief 01 m-A-5) — a routing/discipline-skill reference that should appear in the manager's task-completion section but does not. The pattern is not escalating but is not fully extinguished.

**Current automation:** `.githooks/pre-commit` enforces common-constraints byte-equality. No hook enforces routing-rule sweep completeness.

---

### Pattern D — "Ready to Ship" Branch Sitting Unmerged (2 entries; approaching threshold)

**Definition:** A feature branch reaches a complete state (reviewer approval, plan.md reconciled, retro entry written) but is not merged promptly, allowing drift between the completed feature and the production baseline.

**Occurrences:**
1. **ICON-0014 (current):** Branch complete, retro written, reviewer approved; only the MR-open step pending. Main does not have the gate.
2. **ICON-0015 (this audit context):** The audit brief's statement that ICON-0014 "was added" is technically forward-looking; the feature exists only on the feature branch.

**Assessment:** This pattern has appeared in 2 entries but not 3; it does not yet meet the 3-entry threshold. Flagged because M-CC-NET1 represents the most significant user-facing impact of any single finding in this cycle — a pattern that will reliably recur if the merge speed convention is not tightened.

---

## ICON-0003 Delta

### Fixed since ICON-0003

The following ICON-0003 cross-cutting findings are confirmed fixed:

| ICON-0003 ID | Description | Status |
|---|---|---|
| M-U1 | `plugin-audit` skill unmigrated from marketplace layout | FIXED by ICON-0004. `plugin-audit/SKILL.md` and all 6 briefs now use repo-root paths. |
| M-CC2 (= m-U8) | `icon-status:161` suggests `/release-plugin` to consumers; skill is maintainer-only | FIXED by ICON-0009 retro; io-U4 still open for the `icon-status` suggestion itself, but the registration instruction that caused the confusion was removed. |
| M-P1 | `design-first` Step 3 "hard gate" language | FIXED by ICON-0005. |
| M-P2 | `task-plan-phase-completion` invoked `context-maintenance` directly | FIXED by ICON-0006. |
| M-I1 | `context-specialist mode: upgrade` routing contradiction | FIXED by ICON-0007. |
| M-I2 | `initialize-multimodule` missing feature-branch + MR parity | FIXED by ICON-0008. |
| M-I3 | `initialize-multimodule` missing `disable-model-invocation: true` | FIXED by ICON-0008. |
| M-1 (infra) | CHANGELOG-shape conflict in `release-plugin/SKILL.md` | FIXED by ICON-0010. |
| M-2 (infra) | `release-plugin` Error Conditions referenced `sed` directly | FIXED by ICON-0010. |
| M-U2 | `writing-skills` stale registration instructions | FIXED by ICON-0009. |
| O-T2 (partial) | Token-efficiency extractions from 6 heavy skills | PARTIALLY addressed by MKT-0085 (examples → sibling files). Always-loaded surface audit (O-T2 proper) still open. |
| m-CC1 (ICON-0003) | Onboarding gap — no user-facing slash entry points for Copilot CLI | PARTIALLY addressed by MKT-0073 (intent index). Still no explicit "start a development task" entry. |

### Still present or partial

| ICON-0003 ID | Current form | Location |
|---|---|---|
| M-A1 (planner odd fence count) | m-A-1 | `agents/planner.agent.md:45,:60,:87` |
| M-A3 (architect AR table) | Carry-forward; per audit scope, no removal proposals | `agents/architect.agent.md:103-117` |
| m-A1 (manager "3+" threshold) | m-A-2 | `agents/manager.agent.md:182,:247` |
| m-A4/m-A5 (PM Session Start) | m-A-3, m-A-4 | `agents/product-manager.agent.md:10,:14-16` |
| m-A6 (no agent references `mr-discipline`) | m-A-5 | All 9 `agents/*.agent.md` |
| m-A7 (step-7 wording tension) | m-A-6 | `agents/manager.agent.md:32,:233` |
| O-T1 (common-constraints single-sourcing) | Policy-accepted; pre-commit hook enforces; no action | ADR-004 |
| O-T2 (formal always-loaded token budget) | Still open — IO-CC-T1 this cycle | No budget document exists |
| m-CC3 (CHANGELOG historical `plugins/ICON/` paths) | Still present; historical preservation — correct behavior | `CHANGELOG.md` historical entries |
| m-P1–m-P5 (process skill minors) | m-P-1 through m-P-5 in this cycle | See Brief 02 |
| m1, m3–m5, m7, m9, m10 (init minors) | Carry-forward; see Brief 03 | See Brief 03 |
| m-U5, m-U8, m-U9, m-U10 (utility minors) | m-U-F, IO-U4, m-U-J, m-U-C in this cycle | See Brief 04 |
| m-1 (manifests lack `$schema`) | m-1 (infra) | `.claude-plugin/plugin.json:1`, `.mcp.json:1` |
| m-4 (`format-slack.sh` no strict mode) | Third carry-forward cycle; m-4 (infra) | `.claude/skills/release-plugin/scripts/format-slack.sh:1` |
| m-7 (release-plugin no git-repo guard) | m-7 (infra) | `.claude/skills/release-plugin/SKILL.md:31` |

### Net-new drift classes (ICON-0015 cycle)

| ID | Description | Location |
|---|---|---|
| M-CC-NET1 | Unmerged-branch + missing-CHANGELOG cluster: ICON-0012/0013/0014 features absent from README, `.claude/claude.md`, CHANGELOG; plan.md gate unenforced on main | `CHANGELOG.md:9-21`; `README.md:100,:110`; `.claude/claude.md:9`; `agents/manager.agent.md` (main) |
| M-CC-NET2 | Retrospectives.md write-path contradiction — three-layer-enforcement gap with no resolution anchor | `manager.agent.md:204`; `task-retrospective/SKILL.md:113`; `agent-vs-skill-invocation.md:63` |
| M-CC-NET3 | Dead cross-reference to `.context/standards/three-layer-enforcement.md` | `agents/manager.agent.md:151` |
| m-CC-2 | `using-skills` Skill Priority has no example of the task-plan phase chain | `skills/using-skills/SKILL.md:64-68` |
| m-CC-4 | Distribution-mirror sync gap systemic across all five phase-skill templates | `.context/workflows/task-plan/phase-*.md` vs `context_template/context/workflows/task-plan/phase-*.md` |
| M-A-NET1 | Dead cross-ref to `three-layer-enforcement.md` (agent-domain framing) | `agents/manager.agent.md:151` |
| M-A-NET2 / m-P-7 / m-n4 | ICON-0014 plan.md freshness gate complete on feature branch, absent from main | Feature branch `feature/ICON-0014-plan-md-freshness-gate`; main missing step 0 |
| M-N1 / M-N2 | README and `.claude/claude.md` describe pre-ICON-0012 hook architecture | `README.md:100,:110`; `.claude/claude.md:9` |
| M-P-A | All five phase-skill distribution mirrors stale (1–2 versions behind) | `context_template/context/workflows/task-plan/phase-*.md:1` |
| M-P-B | `retrospectives.md` write-path "Known unresolved" — no resolution date, no issue number | `agent-vs-skill-invocation.md:63` |
| M-I-A | `merge-phase-templates` routing table missing `phase-testing.md` destination | `skills/merge-phase-templates/SKILL.md:42-46` |
| M-U-A | All six plugin-audit briefs contain unfilled `<path-to-prior-audit-report.md>` placeholder | `skills/plugin-audit/briefs/0*.md` |
