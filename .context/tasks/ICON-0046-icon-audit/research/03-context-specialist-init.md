# Context-Specialist & Init Audit — Raw Findings

## Summary

The context-specialist and init-chain domain has seen substantial fixes since ICON-0015. The five prior-audit Moderates in this domain (M-I-A, plus the set handled by ICON-0020/0022/0027/0028/0029/0035) are confirmed fixed on disk. ICON-0022 closed the 6-copy entry-point detection drift surface; ICON-0035 closed DataScan/WMS hardcoded examples and the upgrade-repo Phase 3 vague drift-trigger spec; ICON-0040 added the decisions/-folder migration. The init chain is architecturally sound: the 4-skill dispatch fan-out from `icon-init` routes correctly, `context-specialist-create` cleanly delegates to the right impl skill, and `context-specialist-detect-tree-position` is now the authoritative primitive.

Three defects found: one Minor in `context-specialist-impl-root` (wrong filename in verification checklist), one Minor in `upgrade-repo` Phase 1 (stdout+stderr suppression in an agent-invoked command), and one Minor regarding "plugin-lint Check A/B" labels referenced in two skills with no discoverable definition. Five improvement opportunities are identified, all forward-looking architectural simplification items.

---

## Defect Findings

### Critical

None observed.

### Moderate

None observed.

### Minor

#### m-new-01 — `context-specialist-impl-root` Step 15 verification item 4 checks wrong filename

**Location:** `skills/context-specialist-impl-root/SKILL.md:256`

**Finding:** Step 15 verify list item 4 reads:
> `.context/architecture/patterns-template.md` exists (or is explicitly omitted)

The file that `context-specialist-impl-root` actually generates in Step 7 is `patterns.md` (see structure diagram at line 30 and Step 7 heading at line 137). The `context_template/context/architecture/` directory does contain a `patterns-template.md` (a starter document), but `impl-root` never copies it — it generates custom `patterns.md` content from the actual codebase. The verification check will always fail to locate `patterns-template.md` in a newly-initialized root because that file is never created there.

**Risk:** The verify step silently passes or mis-reports. An agent following Step 15 may either flag a false gap (looking for a file that should not be there) or skip the check as "explicitly omitted" when in fact `patterns.md` was never generated.

---

#### m-new-02 — `upgrade-repo` Phase 1 `diff` command suppresses stderr in an agent-invoked bash block

**Location:** `skills/upgrade-repo/SKILL.md:124`

**Finding:** The `diff -q ... > /dev/null 2>&1` construct suppresses both stdout (the diff result, expected) and stderr (error messages from `diff`, unexpected). This is an agent-invoked bash block per ADR-007 scope — the ban on `2>/dev/null` applies here. If `$TEMPLATE_DIR` is not set or the template file is absent, `diff` will emit `"diff: cannot access '...': No such file or directory"` to stderr, which is silently swallowed, causing the `else` branch to fire and falsely classify the installed file as `CUSTOMIZED`.

**Fix direction:** Replace with `>/dev/null` only (stdout suppression), retaining stderr visibility. Or use `cmp -s` which exits non-zero on difference and produces no stdout by default, so no redirection needed.

---

#### m-new-03 — "plugin-lint Check A" and "plugin-lint Check B" labels are referenced but have no discoverable definition

**Locations:** `skills/icon-init/SKILL.md:225` and `skills/icon-init/SKILL.md:245`; `skills/icon-status/SKILL.md:214`

**Finding:** Two skills reference "plugin-lint Check A" (the `>/dev/null` ban) and "plugin-lint Check B" (the `${VAR+x}` vs `${VAR:-literal}` ban) as if they are named checks in a formal lint tool or documented registry. No such registry, tool, or definition document exists in the repo. `structural-check.sh` (the only check script found) does not define or enforce them. The pre-commit hook does not label its checks as "A" or "B."

**Risk:** Low for runtime behavior, but moderate for maintainability: a skill author or auditor encountering "rejected by plugin-lint Check B" has no canonical source to understand what that means or where it is enforced.

---

## Improvement Opportunities

### IO-01 — Unify `icon-init` detection with `context-specialist-detect-tree-position` or document the deliberate split

**Location:** `skills/icon-init/SKILL.md:34`; `skills/context-specialist-detect-tree-position/SKILL.md:14–54`

**Summary:** `icon-init` Step 2 contains a full re-implementation of type detection (workspace, monorepo, multimodule, project) and notes it is "derived from" `context-specialist-detect-tree-position`. The two detection surfaces have diverged in structure: `detect-tree-position` returns `root | leaf | branch` (3 types); `icon-init` produces `workspace | monorepo | multimodule | project` (4 types, with workspace as a monorepo sub-type and multimodule as a branch sub-type). `icon-init` also introduces a `python3 -c "import json"` invocation for workspaces detection that `detect-tree-position` does not use.

The note at `icon-init:34` says "if that skill's detection signals change, update this step to match" — but there is no mechanical enforcement of this dependency, and the two surfaces have already structurally diverged. The `detect-tree-position` skill does not know about the workspace/multimodule distinction; `icon-init` does.

**Options:** (a) Extend `detect-tree-position` with a 5-type variant that subsumes the `icon-init` logic, making `icon-init` Step 2 a one-line invocation. (b) Remove the "derived from" claim and document the two surfaces as intentionally separate concerns with different output types. (b) is lower risk since the detection semantics differ (3 vs 4 types).

**Effort:** low (documentation) to medium (structural refactor). **Impact:** medium — prevents a future caller from silently using the wrong detection primitive.

---

### IO-02 — Add a verification step to `context-specialist-impl-branch`

**Location:** `skills/context-specialist-impl-branch/SKILL.md:100–120`

**Summary:** `context-specialist-impl-leaf` has Step 5 (Verify) and `context-specialist-impl-root` has Step 15 (Verify and Commit). `context-specialist-impl-branch` has 9 steps ending with "Commit" — no verify step. The three impl skills have an explicit parity gap here. A verify step for branch would be short: confirm `projects.md`, `overview.md`, and `.gitignore` exist; confirm commit SHA is recorded.

**Effort:** trivial. **Impact:** low-medium (parity, reduces silent partial-execution risk).

---

### IO-03 — Clarify or close the `initialize-multimodule` vs `initialize-monorepo` root-context asymmetry

**Locations:** `skills/initialize-multimodule/SKILL.md:332–370`; `skills/initialize-monorepo/SKILL.md:265–293`; `skills/initialize-workspace/SKILL.md:276–300`

**Summary:** `initialize-monorepo` (Step 5) and `initialize-workspace` (Step 6) both dispatch a final `@context-specialist` agent with `tree_position: root` to generate cross-project `.context/` at the root, including `projects.md`, `overview.md`, `decisions/`, `architecture/patterns.md`, and `workflows/`. `initialize-multimodule` Step 7 only invokes `create-iconrc` and offers to create a brief root `README.md`. The root-level `.context/` folder is never created for multi-module repos.

`context-specialist-impl-root` Step 2 states that `projects.md` is "the canonical project map that agents use (via `resolve-repo-context`) to locate any area." `resolve-repo-context` itself uses a filesystem topology cache and does not directly read `projects.md`, so there is no immediate runtime breakage. But agents navigating a multi-module root via `@manager` → `resolve-repo-context` get a topology from a scan (no human-readable context summary), while monorepo and workspace agents get rich root-level `.context/`.

**Options:** (a) Add a Step 7c to `initialize-multimodule` that dispatches `@context-specialist` with `tree_position: root` for multi-module repos. (b) Document that multi-module repos intentionally skip root `.context/` and update `resolve-repo-context` to note this difference. Option (b) is lower effort and honest about the structural difference.

**Effort:** low (documentation) to medium (adding root context generation). **Impact:** medium — removes a hidden disparity that can surprise agents working in multi-module repos.

---

### IO-04 — Formalize "plugin-lint Check A/B" as named entries in a discoverable document or remove the labels

**Locations:** `skills/icon-init/SKILL.md:225,245`; `skills/icon-status/SKILL.md:214`

**Summary:** Two behavioral rules are labeled "plugin-lint Check A" and "plugin-lint Check B" in skill common-mistakes tables, but neither label resolves to a formal definition. The underlying rules (no `>/dev/null` suppression; use `${VAR+x}` not `${VAR:-literal}`) are already enforced by `shared/common-constraints.md` and the pre-commit hook. The "plugin-lint" label creates an impression of a formal numbered check catalog that does not exist.

**Options:** (a) Define the labels formally — add a `## Plugin-Lint Checks` section to a plugin-wide shared document and link from both skill common-mistakes tables. (b) Remove the "plugin-lint Check A/B" label and replace with the plain rule (e.g., "banned by common-constraints.md § Shell command self-check" and "required by bash-scripting.md § Presence check idiom").

**Effort:** trivial. **Impact:** low — reduces confusion for skill authors and auditors.

---

### IO-05 — Add an operational-defensiveness note to `upgrade-repo` Phase 0 for the "neither instructions file exists" Case 3 path

**Location:** `skills/upgrade-repo/SKILL.md:70–100`

**Summary:** Common Check Pattern 3 (Operational Defensiveness) asks: for skills that mutate state, is there a partial-failure recovery path? `upgrade-repo` Phase 0 handles Case 3 ("neither `.github/copilot-instructions.md` nor `.claude/claude.md` is present") by emitting a note and continuing to Phase 1. Phase 1 then proceeds to upgrade `.context/` infrastructure even though there is no instructions file to load the context. An agent completing Phase 2 and Phase 4 could produce a fully-upgraded `.context/` directory with no entry point — a state that downstream skills silently treat as "no instructions, no context" (the entry-point detection primitive requires BOTH an entry-point file AND `.context/`).

**Options:** Add a warning in Case 3 that Phase 1 will still audit existing `.context/` infrastructure, but Phase 2 will skip creating or updating `.claude/claude.md` and any output summarizing the upgrade should note the missing entry point as a required follow-up. This makes the partial-state outcome explicit rather than implicit.

**Effort:** trivial. **Impact:** low-medium (makes a latent silent-degradation path visible).

---

## Architectural Coherence Observations

### Four-type init fan-out vs. three-position impl skills

`icon-init` produces four repo types (workspace, monorepo, multimodule, project) dispatching to four `initialize-*` skills. The impl skills use three positions (root, leaf, branch). The mapping is: workspace+monorepo → root; project → leaf; multimodule → branch. This is structurally clean but not documented at either end. A new contributor reading `context-specialist-detect-tree-position` would not know that "branch" corresponds to "multimodule" in the `icon-init` vocabulary. An improvement noting this mapping explicitly in both `icon-init:34` and `detect-tree-position`'s "Entry-Point Detection Primitive" section would reduce the cognitive gap.

### Asymmetric root-level context: monorepo/workspace vs. multimodule

As noted in IO-03, three of four init paths generate rich root-level `.context/` (projects.md, overview.md, workflows). The multimodule path generates only `iconrc.json` and optionally a README. This asymmetry is not documented and could mislead a user who initializes a multi-module directory and then expects `resolve-repo-context` to use a `projects.md` for routing.

### `context-specialist-impl-branch` has no verification step

Both `impl-leaf` and `impl-root` end with an explicit verify+commit step that checks all created files. `impl-branch` ends at Step 9 with just "Commit." Branch initialization produces fewer files (no hook, no `retrospectives.md`, no phase templates), but the absence of any verify step means a partial execution (e.g., `projects.md` not generated) leaves no diagnostic trace. This parity gap is minor in severity but represents a structural inconsistency across the three impl skills.

### `upgrade-repo`'s canonical Phase 3 spec is well-placed but the cross-reference pattern is not enforced

`upgrade-repo/SKILL.md:586–588` now carries the canonical "spot-check 5 random items" spec with the note "orchestrators reference this section." The three orchestrators (`initialize-monorepo`, `initialize-workspace`, `initialize-multimodule`) do reference it by name in their sub-session prompts. This is the intended single-source-of-truth pattern and is working correctly. There is no mechanical enforcement that a future orchestrator will follow the cross-reference convention rather than re-inlining the spec — this remains an editorial discipline item.

### `icon-init` python3 usage is technically portable but fragile on minimal environments

`icon-init` Step 2b uses `python3 -c "import json..."` to parse `package.json` for the `workspaces` field detection. `python3` is not guaranteed on all environments (minimal Docker images, some CI systems). ADR-004 defines portability as "Claude Code vs Copilot CLI runtime" rather than OS environment, so this is not strictly an ADR-004 violation. However, it is the only `python3` usage in the init chain (all other skills use pure bash), and the same `workspaces` detection could be done with `grep -q '"workspaces"' package.json` (accepting a slightly looser match). The `icon-init` Common Mistakes section warns against `2>&1 | grep -v "^Traceback"` being needed but does not acknowledge the python3 dependency as a risk.

---

## ICON-0015 Delta

### Fixed since ICON-0015

| ICON-0015 ID | Description | Evidence |
|---|---|---|
| M-I-A | `merge-phase-templates` Step 2 routing table missing `phase-testing.md` | ICON-0029. Current `skills/merge-phase-templates/SKILL.md:45` has the testing row. |
| m3 | `find-context-template` PowerShell `/` vs `\` separator literals | ICON-0035 (CHANGELOG line 66). All four variants now use consistent separators. |
| m4 | `find-context-template` description doesn't list its five callers | ADR-009 accepted; caller-listing requirement removed; not a defect. |
| m5 | `resolve-repo-context` schema example omits fallback `instructions` path | ICON-0035 (CHANGELOG line 66). `skills/resolve-repo-context/SKILL.md:99` now has inline comment with fallback. |
| m7 | `context-specialist.agent.md` doubled scope-discipline statement | No doubling present in current file. Lines 125 and 130 are the common-constraints Scope Discipline rule and the specialist-specific refinement — two complementary statements, not a duplicate. This appears resolved in ICON-0035 or earlier. |
| m9 | Hardcoded DataScan/.NET/WMS examples in 4 init skills | ICON-0035 (CHANGELOG line 41). Angle-bracketed placeholders throughout; `find-context-template` retains `datascan-marketplace` default with documented `MARKETPLACE_NAME` override. Accepted per ADR-010 for remaining reference shapes. |
| m10 | `upgrade-repo` Phase 3 vague drift-trigger spec | ICON-0035 (CHANGELOG line 42). Canonical spec now inline at `skills/upgrade-repo/SKILL.md:586–588`; orchestrators cross-reference. |
| m-new-A (ICON-0015) | `initialize-workspace` Step 7 MR template "How to Test" row using legacy `copilot-instructions.md` | ICON-0035 (CHANGELOG line 66). `skills/initialize-workspace/SKILL.md:330` now reads "Review each project's .claude/claude.md." |
| (ICON-0040) | `decisions/` folder migration in `upgrade-repo` | ICON-0040. Phase 1/2 now detect and migrate flat `decisions.md` to `decisions/` folder layout with bash+PowerShell parity. |
| (ICON-0022) | Entry-point detection 6-copy inline drift surface | ICON-0022 (CHANGELOG line 42). All three orchestrators now use "Entry-Point Detection Primitive" cross-reference to `context-specialist-detect-tree-position/SKILL.md` rather than inlining the conditional. |

### Still present or partial

| ID | Description | Status |
|---|---|---|
| m1 | `prune-context.sh` `2>/dev/null` instances | Accepted (watch) per ADR-010 / ADR-007. Autonomous script; ban does not apply. |
| (structural) | `context-specialist-impl-branch` lacks a verification step | Newly observed; recorded as IO-02 above. Not flagged in ICON-0015. |
| (structural) | `initialize-multimodule` root-context asymmetry vs monorepo/workspace | Newly observed; recorded as IO-03 above. Not flagged in ICON-0015. |

### Net-new

| ID | Description | Location |
|---|---|---|
| m-new-01 | `context-specialist-impl-root` Step 15 item 4 checks `patterns-template.md` (wrong filename — should be `patterns.md`) | `skills/context-specialist-impl-root/SKILL.md:256` |
| m-new-02 | `upgrade-repo` Phase 1 `diff` command uses `> /dev/null 2>&1` in agent-invoked bash block (ADR-007 scope — stderr suppression in agent command) | `skills/upgrade-repo/SKILL.md:124` |
| m-new-03 | "plugin-lint Check A/B" labels referenced in two skills with no discoverable definition | `skills/icon-init/SKILL.md:225,245`; `skills/icon-status/SKILL.md:214` |
