# Context-Specialist & Init Audit — Raw Findings

## Summary

The context-specialist and init-chain domain is broadly healthy. The seven ICON-0046 findings directly applicable to this domain were all confirmed fixed in the ICON-0048 sweep: `patterns-template.md` → `patterns.md` (m-new-01), context-specialist description trimmed to one sentence (m-A-NET-NEW-1), Discretionary heading restored (m-A-NET-NEW-2), audit-mode commit parenthetical removed (m-A-NET-NEW-3), keep-last-15 prose references in two companion docs (m-P-NEW-1/2). Frontmatter is clean across all 15 in-scope skills and the agent — every file uses `description: >` folded scalar form. The delegation chain is architecturally sound: `icon-init` → one of four `initialize-*` skills → `@context-specialist` → `context-specialist-create` → correct `impl-*` skill, with no inline detection duplication since ICON-0022.

Three findings remain open from ICON-0046. One is a structural asymmetry (multimodule root-context gap); one is an agent-invoked `diff > /dev/null 2>&1` (ADR-007 scope, still Minor); one is the "plugin-lint Check A/B" undefined-label pattern (three sites, untouched by ICON-0048). Two net-new findings: a sweep-incompleteness residue in `upgrade-repo/SKILL.md:616` and `context_template/context/retrospectives.md:1` where the stale "Remove entries older than the 15th" comment was missed by the ICON-0048 cap-reference sweep.

---

## Defect Findings

### Critical

None observed.

### Moderate

None observed.

### Minor

#### m-58-03-01 — `upgrade-repo/SKILL.md:616` stale "the 15th" comment (ICON-0048 sweep miss)

**Location:** `skills/upgrade-repo/SKILL.md:616`

**Finding:** The Retrospectives File Migration section quotes the placeholder text that should be placed in a migrated `retrospectives.md`:

```
<!-- New entries go here, above older entries. Remove entries older than the 15th. -->
```

The cap was reduced from 15 to 10 in ICON-0041. ICON-0048 corrected `agent-vs-skill-invocation.md:23` and `context-maintenance/append-retrospective-entry.md:3,:32` but did not update this instruction block in `upgrade-repo`. A consumer following the Retrospectives File Migration section will copy a comment that actively contradicts the `ENTRY_CAP=10` enforced by `append-retrospective-entry.sh`. This is a consumer-visible documentation accuracy defect.

**Risk:** Low for runtime behavior (the script enforces the actual cap), but misleads any human reading the migrated file — they see "15th" and may manually delete entries at a different threshold than the script does.

---

#### m-58-03-02 — `context_template/context/retrospectives.md:1` stale "the 15th" comment (ICON-0048 sweep miss)

**Location:** `context_template/context/retrospectives.md:1`

**Finding:** The shipped consumer-facing template file reads:

```
<!-- New entries go here, above older entries. Remove entries older than the 15th. -->
```

This file is copied verbatim to every new consumer repo during `initialize-*` / `context-specialist-impl-leaf` Step 2 and `context-specialist-impl-root` Step 12. The cap is 10 (`ENTRY_CAP=10` in `append-retrospective-entry.sh:41`). Every repo initialized from v1.19.0 or earlier receives this stale comment. The ICON-0048 sweep targeted two prose documentation files but did not include the template source file.

**Risk:** Low for runtime behavior (script enforces the real cap), but every newly-initialized repo ships with a misleading comment that will persist until someone runs `upgrade-repo` and happens to inspect this file. The template is the highest-multiplier surface for this class of stale literal — it propagates to every consumer.

---

#### m-58-03-03 — `upgrade-repo/SKILL.md:124` agent-invoked `diff` command suppresses stderr (still present from ICON-0046 m-new-02)

**Location:** `skills/upgrade-repo/SKILL.md:124`

**Finding:** The `diff -q ... > /dev/null 2>&1` construct at line 124 suppresses both stdout (the diff result, expected) and stderr (error messages from `diff`, unexpected). This construct appears inside an agent-invoked bash block — ADR-007 scope applies; the `2>/dev/null` ban is in effect.

```bash
if diff -q ".context/workflows/task-workflow-template.md" \
           "$TEMPLATE_DIR/context/workflows/task-workflow-template.md" > /dev/null 2>&1; then
```

If `$TEMPLATE_DIR` is not set or the template file is absent, `diff` emits `"diff: cannot access '...': No such file or directory"` to stderr. With `2>&1` suppressed, the error is swallowed, the `diff` exits non-zero, and the `else` branch fires — causing the agent to incorrectly classify the installed file as "CUSTOMIZED" rather than flagging the missing template file. This converts a visible diagnostic failure into a silent wrong classification.

**Risk:** Low severity in most sessions (the template file is usually present), but the incorrect classification in Phase 1 then causes Phase 2 to invoke `merge-phase-templates` unnecessarily, potentially blocking the upgrade on a "customization" that doesn't exist.

**Fix direction:** Replace with `>/dev/null` only (keeping stderr visible), or use `cmp -s` which exits non-zero on difference and emits no stdout by default.

---

#### m-58-03-04 — "plugin-lint Check A" and "plugin-lint Check B" labels referenced but have no discoverable definition (still present from ICON-0046 m-new-03)

**Locations:**
- `skills/icon-init/SKILL.md:225` — references "plugin-lint Check B"
- `skills/icon-init/SKILL.md:245` — references "plugin-lint Check A"
- `skills/icon-status/SKILL.md:214` — references "plugin-lint Check B"

**Finding:** Three separate references to "plugin-lint Check A/B" appear in Common Mistakes tables as though these are formally numbered entries in a lint catalog. No such catalog, registry, or definition document exists on disk. The pre-commit hook does not label its checks as "A" or "B." `structural-check.sh` does not define them. The underlying rules are enforced (via `shared/common-constraints.md` and the pre-commit hook), but the "Check A/B" label creates an impression of a formal numbered catalog entry that an author or auditor cannot look up.

**Risk:** Low for runtime behavior. An agent or human encountering "rejected by plugin-lint Check B" in a Common Mistakes table has no canonical source to trace.

**ICON-0046 status:** This was m-new-03, flagged as O-S2 (Tier 2 suggested fix), recommended to either formalize or replace with plain rule citations. The ICON-0048 sweep did not address it.

---

## Improvement Opportunities

### IO-58-01 — Formalize or replace "plugin-lint Check A/B" labels (closes m-58-03-04 / m-new-03)

**Locations:** `skills/icon-init/SKILL.md:225,245`; `skills/icon-status/SKILL.md:214`

**Summary:** Replace the informal "plugin-lint Check A/B" labels with explicit rule citations. Recommend option (b) from ICON-0046 O-S2: replace "rejected by plugin-lint Check A" with "banned by `common-constraints.md § Shell command self-check`" and "rejected by plugin-lint Check B" with "required by `common-constraints.md § Shell command self-check` — use `${VAR+x}` presence form". This surfaces the actual enforcement location rather than a phantom catalog.

**Effort:** trivial (three one-line edits). **Impact:** low (maintainability clarity).

---

### IO-58-02 — Add a verification step to `context-specialist-impl-branch` (still open from ICON-0046 IO-02)

**Location:** `skills/context-specialist-impl-branch/SKILL.md:100–121`

**Summary:** `impl-leaf` ends with Step 5 (Verify) and `impl-root` ends with Step 15 (Verify and Commit). `impl-branch` ends at Step 9 with only "Commit." A verify step for branch would be short: confirm `projects.md`, `overview.md`, and `.gitignore` exist; confirm commit SHA recorded. The parity gap means a partial `impl-branch` execution (e.g., `projects.md` never generated due to a mid-run stall) produces no diagnostic trace.

**Effort:** trivial. **Impact:** low-medium (parity, reduces silent partial-execution risk).

---

### IO-58-03 — Document or resolve the multimodule root-context asymmetry vs. monorepo/workspace (still open from ICON-0046 IO-03)

**Locations:** `skills/initialize-multimodule/SKILL.md:332–428`; `skills/initialize-monorepo/SKILL.md:265–293`; `skills/initialize-workspace/SKILL.md:276–300`

**Summary:** `initialize-monorepo` Step 5 and `initialize-workspace` Step 6 both dispatch a final `@context-specialist` with `tree_position: root`, generating full cross-project `.context/` at the root — `projects.md`, `overview.md`, `decisions/`, `architecture/patterns.md`, and `workflows/`. `initialize-multimodule` Step 7 only invokes `create-iconrc` and optionally creates a brief root README. The root-level `.context/` folder — the primary surface that `resolve-repo-context` uses for cross-project routing — is never created for multi-module directories.

This means agents operating in a multi-module repo get topology from a filesystem scan (no human-readable context summary), while monorepo and workspace agents get rich root-level `.context/`. The asymmetry is not documented in `initialize-multimodule`, `resolve-repo-context`, or `context-specialist-detect-tree-position`.

**Options:** (a) Add a Step 7c to `initialize-multimodule` dispatching `@context-specialist` with `tree_position: root` — bringing it to parity. (b) Document the intentional difference explicitly in `initialize-multimodule` § Overview and in `resolve-repo-context` Edge Cases table (add "multi-module root has no `.context/`" row). Option (b) is lower risk.

**Effort:** low (documentation) to medium (parity implementation). **Impact:** medium — removes a hidden disparity that can surprise agents working in multi-module repos.

---

### IO-58-04 — Consolidate or annotate the icon-init / context-specialist-detect-tree-position detection split (from ICON-0046 IO-01)

**Locations:** `skills/icon-init/SKILL.md:34`; `skills/context-specialist-detect-tree-position/SKILL.md:14–54`

**Summary:** `icon-init` Step 2 re-implements type detection (4 types: workspace, monorepo, multimodule, project) with a note that it is "derived from" `context-specialist-detect-tree-position`. The detect-tree-position skill returns 3 positions (root, leaf, branch). The two surfaces have diverged structurally: `icon-init` uses `python3` for JSON parsing that `detect-tree-position` does not use; `icon-init` distinguishes workspace from monorepo and multimodule from branch while `detect-tree-position` does not. The mapping is: workspace + monorepo → root; project → leaf; multimodule → branch — but this mapping is documented in neither file.

Neither file cross-references the other's entry table. A new contributor reading `detect-tree-position` would not know "branch corresponds to multimodule" in `icon-init` vocabulary. A contributor reading `icon-init` would not know the 4→3 type collapsing when delegating to the impl skills.

**Options:** (a) Document the mapping at both endpoints — add a footnote at `icon-init/SKILL.md:34` noting the 4→3 collapse and add a "Used by" note to `detect-tree-position`'s Detection Summary table. (b) Extend `detect-tree-position` with a 5-type variant (adding workspace and multimodule) to subsume `icon-init` detection. Option (a) is lower risk.

**Effort:** trivial (option a) to medium (option b). **Impact:** low-medium — prevents future callers from silently using the wrong detection primitive.

---

### IO-58-05 — Sweep stale "the 15th" placeholder text across all consumer-facing surfaces (closes m-58-03-01 and m-58-03-02)

**Locations:** `skills/upgrade-repo/SKILL.md:616`; `context_template/context/retrospectives.md:1`; `skills/context-maintenance/scripts/append-retrospective-entry.sh:6` (and its two byte-equal copies at `skills/task-retrospective/scripts/append-retrospective-entry.sh:6` and `skills/post-incident-review/scripts/append-retrospective-entry.sh:6`)

**Summary:** ICON-0048 corrected the cap references in `agent-vs-skill-invocation.md:23` and `context-maintenance/append-retrospective-entry.md:3,:32` but missed five additional sites where "15" or "the 15th" appears:

| File | Line | Stale text | Correct text |
|------|------|-----------|--------------|
| `skills/upgrade-repo/SKILL.md` | 616 | "Remove entries older than the 15th." | "Remove entries older than the 10th." |
| `context_template/context/retrospectives.md` | 1 | "Remove entries older than the 15th." | "Remove entries older than the 10th." |
| `skills/context-maintenance/scripts/append-retrospective-entry.sh` | 6 | "reaches the cap (15)." | "reaches the cap (10)." |
| `skills/task-retrospective/scripts/append-retrospective-entry.sh` | 6 | (byte-equal copy — same stale comment) | — |
| `skills/post-incident-review/scripts/append-retrospective-entry.sh` | 6 | (byte-equal copy — same stale comment) | — |

The three script files are byte-equal copies (enforced by the pre-commit script-parity hook) — a single edit must be made to the source copy and then propagated to maintain parity. The `context_template/context/retrospectives.md` file is the highest-multiplier surface: it is copied verbatim to every new consumer repo on init and every upgrade, meaning the stale "15th" comment persists in every repo initialized from this version.

The script header comments (line 6) fall in autonomous scripts (ADR-007 scope for `2>/dev/null` ban) — but ADR-007 carves out only the ban on `2>/dev/null` suppression, not on comment accuracy. The stale cap value in the comment misrepresents the script's behavior to the next maintainer who reads it.

**Effort:** trivial (five one-line changes, but requires propagating the script edit to all three copies). **Impact:** low-medium (consumer template and upgrade instruction accuracy; corrects the sweep-incompleteness Pattern A instance for this literal).

---

## Architectural Coherence Observations

### Context-specialist commit scope is now correct and consistently documented

ICON-0048 fixed the core m-A-NET-NEW-3 finding (audit mode incorrectly listed among modes-that-commit) across all three surfaces: `agents/context-specialist.agent.md`, `skills/task-plan-phase-completion/agent-vs-skill-invocation.md`, and `skills/manager-routing-guide/SKILL.md`. The Hardcoded tier in `context-specialist.agent.md:82` now correctly documents that `maintenance` mode uses `git add` only (manager owns the commit), while `create` and `upgrade` modes commit before reporting. This is a clean three-surface fix with no observed residual propagation sites.

### Four-type init fan-out vs. three-position impl skills

The mapping (workspace + monorepo → root; project → leaf; multimodule → branch) remains undocumented at both endpoints (`icon-init/SKILL.md:34` notes "derived from" but does not state the collapsing; `detect-tree-position` does not mention the `icon-init` vocabulary). This is a cognitive gap rather than a runtime defect — the skill logic is correct, but a new contributor building on this system would not see the mapping.

### `impl-branch` verification gap persists

Both `impl-leaf` (Step 5) and `impl-root` (Step 15) end with an explicit verify+commit step. `impl-branch` ends at Step 9 with only "Commit." The branch initialization produces fewer files than leaf or root (no hook, no `retrospectives.md`, no phase templates), so the gap is less consequential than it would be for the other impl skills. However, it means a partial `impl-branch` execution that fails to generate `projects.md` or `overview.md` leaves no diagnostic trace.

### Multimodule root-context is a documented gap waiting to become a user-visible surprise

`initialize-multimodule` intentionally generates no root `.context/` (only `iconrc.json`). `resolve-repo-context` handles the no-context-at-root case via the Edge Cases table ("Resolved sub-project has no `.context/`") — but the multimodule case isn't specifically noted. An agent navigating a multi-module root via `@manager` → `resolve-repo-context` gets topology from a filesystem scan without the rich `projects.md` cross-reference that monorepo and workspace agents get. This asymmetry is load-bearing for user expectations but silent at the documentation level.

### `upgrade-repo` Retrospectives migration section is a standalone documentation island

The "Retrospectives File Migration" section (lines 602–620) documents a one-time migration for pre-MKT-0045 repos. It is the only place that quotes the retrospectives template placeholder text directly. When ICON-0041 reduced the cap from 15 to 10, the sweep updated `context_template/context/retrospectives.md:1` (the source) — but the migration instruction in `upgrade-repo` that quotes the same text was not updated. The fact that this section quotes a specific literal from a template file makes it a dependee on template content changes; the ICON-0048 sweep that touched prose documentation did not include template-quoting instructions.

---

## ICON-0046 Delta

### Fixed since ICON-0046

| ICON-0046 ID | Description | Evidence |
|---|---|---|
| **m-new-01** | `context-specialist-impl-root` Step 15 verify item 4: `patterns-template.md` → `patterns.md` | Fixed in ICON-0048. `skills/context-specialist-impl-root/SKILL.md:257` now reads `.context/architecture/patterns.md` |
| **m-A-NET-NEW-1** | `context-specialist.agent.md:2-6` description was 3 sentences, violating one-sentence sub-agent rule | Fixed in ICON-0048. `agents/context-specialist.agent.md:3-4` now reads one sentence: "Creates and maintains .context/ documentation across create, upgrade, maintenance, and audit modes; cannot delegate to sub-agents." |
| **m-A-NET-NEW-2** | `manager.agent.md:238` Discretionary heading missing `(Off Unless Explicitly Requested)` | Fixed in ICON-0048. `agents/manager.agent.md:242` now has `### Discretionary (Off Unless Explicitly Requested)` |
| **m-A-NET-NEW-3** | `context-specialist.agent.md:84` "(where audit-write occurs)" parenthetical contradicting read-only audit mode | Fixed in ICON-0048. The `audit` mode is removed from modes-that-commit across all three surfaces (`context-specialist.agent.md`, `agent-vs-skill-invocation.md:22`, `manager-routing-guide/SKILL.md:79`). |
| **m-P-NEW-1** | `agent-vs-skill-invocation.md:23` stale `keep-last-15` | Fixed in ICON-0048. Line now reads `keep-last-10 with multi-prune convergence` |
| **m-P-NEW-2** | `context-maintenance/append-retrospective-entry.md:3,:32` stale "rolling log of last 15 entries" and single-prune description | Fixed in ICON-0048. Line 3 now says "last 10 entries"; line 32 describes multi-prune convergence behavior at cap=10. |
| **m-U-net2** | `mcp-tools-first/SKILL.md:1-9` missing `user-invocable: false` frontmatter key | Fixed in ICON-0048. `skills/mcp-tools-first/SKILL.md` now has `user-invocable: false`. |

### Still present or partial

| ICON-0046 ID | Description | Status |
|---|---|---|
| **m-new-02** | `upgrade-repo/SKILL.md:124` `diff > /dev/null 2>&1` in agent-invoked bash block (ADR-007 scope) | Still present. Unchanged since ICON-0046. See **m-58-03-03** above. |
| **m-new-03** | "plugin-lint Check A/B" labels referenced in two skills with no discoverable definition | Still present. ICON-0048 did not include this fix. Now three locations. See **m-58-03-04** above. |
| **IO-02** | `context-specialist-impl-branch` lacks a verification step | Still present. No structural change to this skill since ICON-0046. See **IO-58-02** above. |
| **IO-03** | `initialize-multimodule` root-context asymmetry vs. monorepo/workspace | Still present. `initialize-multimodule` still generates only `iconrc.json` at root with no `.context/` documentation. See **IO-58-03** above. |
| **IO-05** | `upgrade-repo` Phase 0 Case 3 — no explicit defensiveness note about partial-state outcome | Still present. Case 3 says "Continuing to Phase 1" but does not warn that Phase 2 may produce fully-upgraded `.context/` with no entry point. |

### Net-new

| ID | Description | Location |
|---|---|---|
| **m-58-03-01** | `upgrade-repo/SKILL.md:616` stale "Remove entries older than the 15th" — ICON-0048 sweep miss | `skills/upgrade-repo/SKILL.md:616` |
| **m-58-03-02** | `context_template/context/retrospectives.md:1` stale "Remove entries older than the 15th" — ICON-0048 sweep miss (consumer-facing template) | `context_template/context/retrospectives.md:1` |
| **IO-58-05 (component)** | All three `append-retrospective-entry.sh` script copies have stale header comment "the cap (15)" at line 6 | `skills/context-maintenance/scripts/append-retrospective-entry.sh:6`; `skills/task-retrospective/scripts/append-retrospective-entry.sh:6`; `skills/post-incident-review/scripts/append-retrospective-entry.sh:6` |

**Pattern observation:** The two net-new Minor findings (m-58-03-01 and m-58-03-02) are instances of Pattern A (sweep-incompleteness) identified in ICON-0046 cross-cutting. ICON-0048's sweep of `keep-last-15` literals targeted prose documentation files (`agent-vs-skill-invocation.md`, `append-retrospective-entry.md`) but did not use a codebase-wide grep for the literal "15th" or "the cap (15)". The ICON-0015 O-V4 placeholder-grep gate (pre-commit hook extension for literal sweeps) remains unimplemented; if it had been, a staged edit to `append-retrospective-entry.md` changing "15" to "10" could have surfaced the remaining "15" literals in a mechanically enforced way.
