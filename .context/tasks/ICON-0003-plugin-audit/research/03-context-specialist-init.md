# Context-Specialist & Init Audit — Raw Findings

## Summary

Both MKT-0087 Criticals (CC-C1 entry-point detection in the three orchestrators, CC-C2 `create-iconrc` template-path hardcode) are confirmed **fixed** in this repo and the fixes survived the marketplace → standalone split cleanly. The agent frontmatter "three modes / Phase 1 and 2" inconsistency (MKT-0087 M2 / MKT-0077 M-I1) is also fixed — frontmatter now enumerates four modes and Phase 0/1/2. The remaining surface is mostly carry-forward defects MKT-0087 already triaged: the `mode: upgrade` orchestrator-vs-agent contradiction (M1) is still active; `prune-context.sh` template still has 8 `2>/dev/null`/`>/dev/null` instances directly in the path the agent's own Constraints block bans (line 125 of `context-specialist.agent.md`); `upgrade-repo:124` still has `> /dev/null 2>&1`; `find-context-template` PowerShell variant still uses `\` literals where bash uses `/`; `initialize-multimodule` still lacks branch-creation/MR parity with the other two orchestrators; three orchestrators still triplicate the Phase 3 drift-sampling spec. Net-new findings are small: `initialize-multimodule` lacks `disable-model-invocation: true` while its siblings have it (frontmatter-divergence regression of MKT-0087 m8); `context-specialist-create:11` still claims to handle `mode: upgrade` even though the routing target is dead code (m6 carry); and `find-context-template/SKILL.md:3-4` still understates caller list (m4 carry). No path-reference drift from the repo split was found in this domain — all `$TEMPLATE_DIR`-via-`find-context-template` resolution is intact, no skill hardcodes `plugins/ICON/...` anywhere.

## Defect Findings

### Critical

None observed.

### Moderate

**M1 — Orchestrator dispatch prompts still contradict agent body for `mode: upgrade`. (Carry from MKT-0087 M1.)**
`initialize-monorepo:222-228`, `initialize-workspace:230-235`, and `initialize-multimodule:202-204` all pass `mode: upgrade` to the dispatched agent AND tell it `Load and execute the upgrade-repo skill`. But `context-specialist.agent.md:68-71` routes `mode == upgrade` to `context-specialist-create`, which then loads `context-specialist-impl-{leaf,branch,root}` (not `upgrade-repo`). A manager invoking `@context-specialist` directly with `mode: upgrade` (not via an orchestrator) would follow the agent body's dead path and run a fresh-init impl skill on an already-initialized repo. Effect surface depends on whether the dispatched agent prioritizes its own routing rules or the orchestrator's explicit "Load and execute" instruction.
- `agents/context-specialist.agent.md:46` (mode table), `:68-71` (routing for create/upgrade/absent), `:84-85` (Hardcoded tier dispatch-by-mode rule).
- `skills/initialize-monorepo/SKILL.md:222-228` vs `skills/initialize-workspace/SKILL.md:230-235` vs `skills/initialize-multimodule/SKILL.md:202-204`.

**M2 — `initialize-multimodule` still lacks the feature-branch + per-repo MR parity that `initialize-monorepo` and `initialize-workspace` enforce. (Carry from MKT-0087 M3.)**
Step 0 (`initialize-multimodule/SKILL.md:26-73`) is a **guard only** — it halts on a task branch or dirty tree but never creates a `chore/initialize-agent-context` branch. Step 4 dispatch prompts (`:172-216`) pass neither `feature_branch` nor `git_root`; sub-sessions will commit on whatever branch is current in each sub-project's repo, possibly directly on the integration branch. There is no Step "push and open MR" parallel to `initialize-monorepo` Step 6 / `initialize-workspace` Step 7. For multi-module of independent git repos, this means each sub-project may end up with one commit on `main` with no MR review path.
- `skills/initialize-multimodule/SKILL.md:26-73` (Step 0 — guard only).
- `skills/initialize-multimodule/SKILL.md:172-216` (Step 4 dispatch — no `feature_branch`, no `git_root`).
- Missing: post-Step-6 push/MR steps (`initialize-monorepo:309-340`, `initialize-workspace:310-345` have them).

**M3 — `initialize-multimodule` frontmatter is missing `disable-model-invocation: true` while `initialize-monorepo` and `initialize-workspace` both carry it. (Net-new — frontmatter divergence regression.)**
The two MKT-0058 / MKT-0090 sibling skills are explicitly hidden from model invocation because `/icon-init` is the user-facing entry point. `initialize-multimodule` was flipped to `user-invocable: false` but never got the matching `disable-model-invocation: true`, so the model can still auto-invoke it under the right surface description.
- `skills/initialize-monorepo/SKILL.md:9` (`disable-model-invocation: true`).
- `skills/initialize-workspace/SKILL.md:11` (`disable-model-invocation: true`).
- `skills/initialize-multimodule/SKILL.md:10-11` (only `user-invocable: false`; no `disable-model-invocation` key).

### Minor

**m1 — `prune-context.sh` template still propagates 8 `2>/dev/null` / `>/dev/null` occurrences to every initialized repo. (Carry from MKT-0087 m1; the script was renamed from `prune-old-tasks.sh` in ICON-0002 but the suppression idioms were preserved.)**
Each occurrence is defensible (`git rev-parse`, `git log -1`, `stat -c %Y`, `command -v jq`) but the agent's own Constraints block (`context-specialist.agent.md:125`) explicitly names `2>/dev/null` and `>/dev/null` as patterns the agent must scan-and-remove. Every project initialized through `context-specialist-impl-leaf` Step 3 inherits the script and propagates the pattern.
- `context_template/context/workflows/prune-context.sh:26, :43, :44, :67, :71, :90, :102, :106` (8 instances).

**m2 — `upgrade-repo` Phase 1 still uses `> /dev/null 2>&1` for `diff -q` exit suppression. (Carry from MKT-0087 m2.)**
Same self-reference violation as m1. The agent's Constraints block bans this idiom; the script-using-skill that runs under that agent contains it.
- `skills/upgrade-repo/SKILL.md:124` (bash variant; PowerShell variant at `:135-147` uses `Compare-Object` without suppression).

**m3 — `find-context-template` PowerShell variant still uses `\` separators while Bash uses `/`. (Carry from MKT-0087 m3 / MKT-0077 L4.)**
Lines 33-34 and 48 use `/installed-plugins/${MARKETPLACE_NAME}/ICON/context_template`; lines 40-42 and 54 use `\installed-plugins\$MarketplaceName\ICON\context_template`. PowerShell tolerates either separator, so the bash variant would work on PowerShell but the literal mismatch is a maintenance hazard if a single shell is ever standardized.
- `skills/find-context-template/SKILL.md:33-34, :40-42, :48, :54`.

**m4 — `find-context-template` description still understates the skill's role as a callable primitive. (Carry from MKT-0087 m4.)**
Body at `:10-12` describes it as a callable primitive used by `upgrade-repo`, `merge-phase-templates`, and all three impl skills for `$TEMPLATE_DIR` discovery. The frontmatter description (`Internal context initialization skill. Do not invoke without explicit direction.`) omits this caller list. Common Check Pattern 3 violation.
- `skills/find-context-template/SKILL.md:3-4` vs `:10-12`.

**m5 — `resolve-repo-context` schema example still shows only the canonical path while prose names the fallback. (Carry from MKT-0087 m5.)**
The JSON schema example at `:99` (`"instructions": "/absolute/path/.claude/claude.md"`) shows only the canonical path; the prose at `:121` describes the `.github/copilot-instructions.md` fallback. A consumer reading the schema example might miss the fallback rule.
- `skills/resolve-repo-context/SKILL.md:99` vs `:121`.

**m6 — `context-specialist-create:11` still claims to handle `mode: upgrade` but the body has no upgrade-specific branch. (Carry from MKT-0087 m6.)**
Line 11 says: *"loaded inline by `@context-specialist` when `mode` is `create`, `upgrade`, or absent (default)"*. The body unconditionally routes to `context-specialist-impl-{leaf,branch,root}` — those skills do fresh init (no "skip if file already populated" guard). The `upgrade` mode value is dead at this layer; the actual upgrade path used by orchestrators is `upgrade-repo` per the dispatch prompts. Pairs with M1 — fixing one without the other leaves the inconsistency.
- `skills/context-specialist-create/SKILL.md:11`, no upgrade branch in `:31-76`.

**m7 — `context-specialist.agent.md` doubled scope rule inside and outside common-constraints block. (Carry from MKT-0087 m7 / MKT-0077 L6.)**
Line 128 (inside common-constraints): *"Scope Discipline: Stay within assigned scope. Do not modify files..."*. Lines 134-135 (outside common-constraints): *"Do not read or modify `.context/` files in sibling or parent directories — scope is strictly the target directory."* The latter is a refinement of the former but the textual proximity creates a fragile reading.
- `agents/context-specialist.agent.md:128, :134-135`.

**m8 — `initialize-monorepo` and `initialize-workspace` frontmatter key order still divergent. (Carry from MKT-0087 m8.)**
`initialize-monorepo` puts `disable-model-invocation` before `user-invocable`; `initialize-workspace` reverses the order.
- `skills/initialize-monorepo/SKILL.md:9-10` (`disable-model-invocation: true`, `user-invocable: false`).
- `skills/initialize-workspace/SKILL.md:10-11` (`user-invocable: false`, `disable-model-invocation: true`).

**m9 — Hardcoded DataScan / .NET / WMS examples still present across four init skills. (Carry from MKT-0087 m9.)**
- `skills/initialize-monorepo/SKILL.md:72` (`RestApi`, `Services`, `DataProvider`, `Integrations` as illustrative .NET groups), `:123-133` (`src/RestApi`, `src/DataScan.RiskGauge.WebApp`, `src/DataScan.AdminDashboard.WebApp`), `:159` (`src/RestApi`), `:355` (`src/RestApi`).
- `skills/initialize-workspace/SKILL.md:64-65` (`/dev/ngWi`, `/dev/wi-ui-service`), `:138-139` (same), `:326` (`ngWi, wi-ui-service` in MR description).
- `skills/initialize-multimodule/SKILL.md:156-157, :277` (`wms-api`, `wms-frontend`).
- `skills/context-specialist-impl-root/SKILL.md:64` (`RestApi`).

**m10 — `upgrade-repo` Phase 3 still has the vague drift-trigger spec while three orchestrators duplicate the precise version. (Carry from MKT-0087 m10 / MKT-0077 M-I5.)**
`upgrade-repo/SKILL.md:336-339` Phase 3 prose: *"if documentation has also drifted from the codebase, invoke `context-maintenance`"* (no thresholds, no sample size). Three orchestrator dispatch prompts inject the precise spec: *"spot-check 5 random class names, function names, type names, or file paths from `.context/domains/*.md` against the codebase using grep; if at least 2 of the 5 are absent..."*.
- `skills/upgrade-repo/SKILL.md:336-339` vs `skills/initialize-monorepo/SKILL.md:230-233`, `skills/initialize-workspace/SKILL.md:237-240`, `skills/initialize-multimodule/SKILL.md:206-209`.

## Improvement Opportunities

**O1 — Hoist the orchestrator `mode: upgrade` semantics into the agent body. (Effort: low. Impact: closes M1 + m6.)**
Either have the agent route `mode: upgrade` directly to `upgrade-repo` (and drop the `upgrade` value from `context-specialist-create:11`'s mode list), OR remove the `mode: upgrade` parameter from the agent's mode table and have orchestrators stop passing it. The current state — two routing rules in two files — guarantees one path silently breaks under refactor.

**O2 — Promote `initialize-multimodule` to feature-branch + per-repo MR parity with the other two orchestrators. (Effort: medium. Impact: closes M2.)**
Each sub-project gets a `chore/initialize-agent-context` branch in its own git repo (loop over `git -C "$sub_root"` like `initialize-workspace` Step 1); per-repo push and MR steps mirror `initialize-workspace` Step 7. Dispatch prompts gain `feature_branch` and `git_root`. Without this, multi-module repos with independent git histories can land context commits directly on `main`.

**O3 — Extract the Phase 3 drift-trigger sampling spec into `upgrade-repo` Phase 3 body so all three orchestrators reference it by skill name. (Effort: low. Impact: closes m10.)**
Replace three verbatim copies of "spot-check 5 random items, threshold 2/5" with a single canonical paragraph in `upgrade-repo:336-339`. Each orchestrator's dispatch prompt becomes one line ("follow Phase 3 sampling rule in `upgrade-repo`").

**O4 — Sweep `2>/dev/null` / `>/dev/null` from the prune-context.sh template + `upgrade-repo:124`. (Effort: low. Impact: closes m1 + m2 — both Minor self-reference defects against `context-specialist.agent.md:125`.)**
Replace the 8 instances in `prune-context.sh` with explicit `|| echo ""` / `|| true` tails (the script already does this in some places — see line 52's `|| true` from ICON-0002 fix). Replace `diff -q ... > /dev/null 2>&1` with an exit-code-only check (`diff -q "$a" "$b" >&3 3>&-` form, or rewrite using `cmp -s`).

**O5 — Single-source the entry-point detection block (`.claude/claude.md` || `.github/copilot-instructions.md`). (Effort: medium. Impact: structural — closes the recurring drift surface that MKT-0088 had to fix in three skills at once.)**
The three orchestrators each carry an identical inline `if { [ -f "$dir/.claude/claude.md" ] || [ -f "$dir/.github/copilot-instructions.md" ]; }` block, and `initialize-multimodule` Step 2 has its own variant for the discovery loop (line 126-127). The next change to canonical-vs-legacy detection (e.g., deprecation of the `.github/` fallback) will require coordinated edits to at least 6 sites. A shared bash function in `context_template/context/workflows/` (sourced by each orchestrator) closes this.

**O6 — Add `disable-model-invocation: true` to `initialize-multimodule` frontmatter and normalize key order across all three orchestrators. (Effort: low. Impact: closes M3 + m8.)**
Same key order (`name`, `description`, `user-invocable: false`, `disable-model-invocation: true`) on all three init orchestrators. The MKT-0058 / MKT-0090 "user-facing entry point is `/icon-init`" principle is enforced inconsistently today.

## Architectural Coherence Observations

**A1 — Three-orchestrator fan-out still carries ~70% identical body shape (entry-point detection, dispatch prompt scaffold, verification block, drift-trigger spec, MR boilerplate).**
The MKT-0088 CC-C1 fix touched three files at once because the entry-point detection block lives in three places. `initialize-monorepo` Step 2 + Step 4, `initialize-workspace` Step 3 + Step 5, `initialize-multimodule` Step 3 + Step 5 are each near-verbatim copies of the same logic. This is the dominant maintenance hazard of the init domain; O5 addresses it.

**A2 — `initialize-repo` is genuinely a thin router with no functional duties beyond dispatch.**
Lines 20-23 explicitly call this out: *"Fallback only — not reached in standard flows. @context-specialist's own Process (Step 3) maps tree_position directly to impl skills without ever reading initialize-repo."* The skill exists for discoverability under MKT-0058's `user-invocable: false` flip. Not a defect — but it means the actual leaf-init logic lives in `context-specialist-impl-leaf`, and changes to "what every leaf gets" need to touch that file, not `initialize-repo`.

**A3 — `mode: upgrade` semantically lives in two places that disagree about what it means.**
The agent's mode table at `context-specialist.agent.md:46` routes to `context-specialist-create` (which routes to fresh-init impl skills); orchestrator dispatch prompts at `initialize-monorepo:228` (etc.) say "Load and execute upgrade-repo". The two paths have different file sets, different overwrite-guards, and different verification skills. Surface for confusion: a manager dispatching `@context-specialist` directly with `mode: upgrade` (not via an orchestrator) would follow the dead path.

**A4 — `create-iconrc` is correctly the sole owner of `.context/iconrc.json` per its preamble and Called-By table. All four orchestrators chain to it correctly post-init.**
CC-C2 from MKT-0087 is fully closed: Step 2 create path reads `$TEMPLATE_DIR/context/iconrc.json` via `os.environ.get("TEMPLATE_DIR")` with explicit `RuntimeError` if unset. Pre-requisite section (`:55-63`) tells callers to set `$TEMPLATE_DIR` via `find-context-template` first. No relative-path fallback remains.

**A5 — Self-reference Common Check Pattern (Pattern #1).**
`@context-specialist` agent's Constraints block (line 125) explicitly bans `2>/dev/null` and `>/dev/null` and instructs the agent to scan-and-remove them. The agent dispatches into `upgrade-repo` (line 124 violates) and copies `prune-context.sh` template (8 violations). The agent's own discipline does not propagate to the artifacts it ships.

**A6 — Template / standard cross-reference (Common Check Pattern #2).**
Every skill that needs `$TEMPLATE_DIR` correctly cites `find-context-template` before using it: `context-specialist-impl-leaf:115`, `context-specialist-impl-branch:108`, `context-specialist-impl-root:206`, `upgrade-repo:105`, `merge-phase-templates:22`, `create-iconrc:55-63`. No drift between caller expectations and `find-context-template`'s actual contract. The cross-reference layer is clean.

**A7 — Caller-listing in description (Common Check Pattern #3).**
Apart from `find-context-template` (m4 carry), the other in-scope skills are correctly tagged: `context-specialist-detect-tree-position`, `context-specialist-create`, `context-specialist-impl-{leaf,branch,root}`, `merge-phase-templates`, `resolve-repo-context`, `invoke-sub-project-skill` are all marked "Internal … skill. Do not invoke without explicit direction." and the agent body lists them at `context-specialist.agent.md:21-22`. `create-iconrc`'s description correctly lists all four callers + user direct (`create-iconrc:3-4` + `:177-185` Called-By table). No additional gaps.

**A8 — Operational defensiveness (Common Check Pattern #4).**
- `create-iconrc:67-72` correctly branches on `[ -f ".context/iconrc.json" ]` (create vs update path).
- `upgrade-repo` Phase 0 has three explicit cases (migration / already migrated / neither exists) with show-and-confirm.
- `initialize-multimodule` Step 0 has `--force` escape for branch/dirty-tree guard.
- `merge-phase-templates` Step 3 stages diffs before write and gets one user confirmation for the whole set.
- Gap: orchestrator Step 4 verification blocks re-dispatch on failure but have no retry cap — an area that fails twice will loop indefinitely if the underlying issue is unfixable. Worth a single retry-cap counter in the verification scripts. Not tier-1; flagging here.

**A9 — Frontmatter parser-fragility (Common Check Pattern #5).**
All 15 in-scope skills + the agent use YAML folded scalar (`description: >`) consistently — no plain-scalar descriptions in this domain. MKT-0078's plain-scalar fix held across the repo split. No instances.

## MKT-0087 Delta

### Fixed since MKT-0087

- **CC-C1 (Critical) — fixed.** All three orchestrators now correctly check both `.claude/claude.md` (canonical) and `.github/copilot-instructions.md` (legacy fallback) in both classification and post-dispatch verification. Verified at `initialize-monorepo/SKILL.md:147, :255`, `initialize-workspace/SKILL.md:154, :261`, `initialize-multimodule/SKILL.md:144, :230`. Fix survived the repo split.
- **CC-C2 (Critical) — fixed.** `create-iconrc/SKILL.md:86-93` now reads `template_dir = os.environ.get("TEMPLATE_DIR")` with explicit `RuntimeError` on missing env var; `os.path.join(template_dir, "context", "iconrc.json")` replaces the marketplace-relative literal. Pre-requisite section at `:55-63` tells callers to invoke `find-context-template` first. Schema blockquote at `:31` correctly names `$TEMPLATE_DIR/context/iconrc.json` as the source. Fix survived the repo split.
- **MKT-0087 M2 / MKT-0077 M-I1 — fixed.** `context-specialist.agent.md:2-13` frontmatter now enumerates all four modes (create / upgrade / maintenance / audit) and "Phase 0, Phase 1, and Phase 2"; matches body at `:46` and `:62-66`.
- **MKT-0087 M4 — fixed.** All `NOTASK-0002` citations are gone from `create-iconrc/SKILL.md` (verified by `grep -n NOTASK` returning zero hits).
- **Path-reference drift from repo split — clean.** No skill in scope hardcodes `plugins/ICON/...` or any marketplace-relative path. The only `installed-plugins/datascan-marketplace/ICON/` references are in `find-context-template` (correctly — that is the Copilot CLI runtime install path, parameterized via `MARKETPLACE_NAME` env var).

### Still present or partial

- **MKT-0087 M1** — orchestrator-vs-agent contradiction on `mode: upgrade`. Reproduced as M1 above.
- **MKT-0087 M3** — `initialize-multimodule` lacks feature-branch + MR parity. Reproduced as M2 above.
- **MKT-0087 m1 / MKT-0077 L5** — `prune-context.sh` template still has 8 `2>/dev/null` instances (script was renamed from `prune-old-tasks.sh` in ICON-0002 but suppression idioms were preserved). Reproduced as m1.
- **MKT-0087 m2** — `upgrade-repo:124` `> /dev/null 2>&1`. Reproduced as m2.
- **MKT-0087 m3 / MKT-0077 L4** — `find-context-template` PowerShell separator mismatch. Reproduced as m3.
- **MKT-0087 m4** — `find-context-template` description-vs-body caller-listing gap. Reproduced as m4.
- **MKT-0087 m5** — `resolve-repo-context` schema example vs prose fallback rule. Reproduced as m5.
- **MKT-0087 m6** — `context-specialist-create:11` claims upgrade mode but no upgrade branch in body. Reproduced as m6.
- **MKT-0087 m7 / MKT-0077 L6** — `context-specialist.agent.md` doubled scope rule. Reproduced as m7.
- **MKT-0087 m8** — `initialize-monorepo` vs `initialize-workspace` frontmatter key-order divergence. Reproduced as m8.
- **MKT-0087 m9** — Hardcoded DataScan / .NET / WMS examples in 4 init skills. Reproduced as m9.
- **MKT-0087 m10 / MKT-0077 M-I5** — `upgrade-repo` Phase 3 vague spec + 3 duplicated orchestrator copies. Reproduced as m10.

### Net-new

- **M3 (Moderate, net-new)** — `initialize-multimodule` frontmatter missing `disable-model-invocation: true` while `initialize-monorepo` and `initialize-workspace` carry it. Same MKT-0058 / MKT-0090 principle ("user-facing entry point is `/icon-init` exclusively") should apply uniformly. Not flagged in MKT-0087 m8 (that finding was about *key order*, not *missing key*).
- **A8 observation (no defect tier)** — orchestrator Step 4/5 verification blocks re-dispatch failed areas with no retry cap. Unbounded loop risk if the underlying failure is structural (e.g., source files genuinely missing in a partial repo clone). Worth a retry-counter in a future refactor; not tier-1.
