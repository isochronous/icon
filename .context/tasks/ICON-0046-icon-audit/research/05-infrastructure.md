# Infrastructure Audit — Raw Findings

## Summary

The infrastructure domain is in strong health at v1.17.2. The dominant finding from ICON-0015 (M-CC-NET1 doc-drift, M-CC-NET3 dead specific-file reference, M-U-H git-repo guard, M-U-K format-slack.sh strict mode, m-1 schema, m-n2 LICENSE, m-n3 context_template README diagram, O-M4 bump-versions dry-run) are all confirmed closed on disk. The pre-commit hook now enforces four invariant classes. The release-plugin SKILL.md gained its doc-sweep reminder (O-M1) and git-repo guard. `.claude/claude.md` correctly reflects the single Node.js hook wrapper. The two script-parity triplicate sets (`append-retrospective-entry.{sh,ps1}`) are byte-identical across all three skill locations.

Two new findings emerge in this cycle. First, the pre-commit hook header comment's invariant numbering (lines 19–40) lists the dead-ref resolver as "1" and the iconrc gate as "2" but the actual script execution runs them in the reverse order: iconrc gate executes first (lines 57–116), common-constraints sync second (118–359), script-parity third (407–443), and dead-ref resolver last (445–532). The comment explicitly claims to be "in script-execution order," making it factually wrong. Second, the `release-plugin` SKILL.md Step 1 doc-sweep reminder does not mention the need to verify the `context_template/context/iconrc.json` template version bump before tagging — a newly relevant check since ICON-0044, and one that proved necessary at v1.17.0 (where the bump was missed, requiring ICON-0044 retroactive fix).

The `.mcp.json` still lacks a `$schema` field; this was listed as m-1 in ICON-0015 but only half-resolved (manifest gained `$schema`; MCP config did not).

---

## Defect Findings

### Critical

None observed.

### Moderate

None observed.

### Minor

#### m-infra-1 (carry-forward, partial): `.mcp.json` lacks `$schema`

`.claude-plugin/plugin.json` gained `"$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json"` in ICON-0038 (confirmed at `.claude-plugin/plugin.json:2`). However, `.mcp.json` still has no `$schema` key. The ICON-0015 m-1 finding covered both manifests; the ICON-0038 fix applied only to `plugin.json`. No SchemaStore-hosted schema for `.mcp.json` may yet exist, but the finding should be explicitly accepted or re-evaluated rather than silently carried.

**Location:** `.mcp.json:1` (entire file; no `$schema` key present)

#### m-infra-2 (net-new): Pre-commit hook header comment invariant numbering is incorrect

The hook header at lines 19–40 states the additional invariants are listed "in script-execution order" and numbers them:
1. Dead-ref resolver
2. iconrc.json version-bump gate
3. Script-parity check

The actual execution order in the script is:
- **iconrc.json version-bump gate** runs first, at lines 57–116, before any agent-file check. The comment inline at line 60 even says "This check runs before any agent-file early-exit…"
- **Common-constraints sync** runs second, at lines 118–359 (not enumerated in the numbered list).
- **Script-parity check** runs third, at lines 407–443.
- **Dead-ref resolver** runs last, at lines 445–532.

The ICON-0044 retro records that the header invariant list was "reorganized… (1. dead-ref / 2. iconrc gate / 3. script-parity in execution order)" — but what was shipped has dead-ref as #1 despite it executing last. The claim "in script-execution order" is false for dead-ref, which runs after script-parity.

**Location:** `.githooks/pre-commit:19-40` (header comment numbering); actual execution at `:57` (iconrc gate), `:407` (script-parity), `:445` (dead-ref resolver)

**Risk:** Low. The hook's behavior is correct; only the documentation of ordering is wrong. A maintainer adding a fifth invariant who reads the comment may insert in the wrong position.

#### m-infra-3 (net-new): `release-plugin` Step 1 doc-sweep does not mention `context_template/iconrc.json` version check

`release-plugin/SKILL.md:40` now correctly instructs: "Sweep user-facing docs (`README.md`, `.claude/claude.md`, `commands/*.md`) for behavioral drift." This closes the ICON-0015 O-M1 recommendation.

However, the Step 1 checklist does not include verifying that `context_template/context/iconrc.json` was bumped if any template files changed since the last release. ICON-0044 was created precisely because this was missed at v1.17.0 — nine template-file changes shipped without a version bump, causing consumer repos running `/upgrade-repo` to silently skip those updates. The `.githooks/pre-commit` gate enforces the bump at commit time, but if a maintainer has commits from before the hook existed (or if the hook was ever bypassed), the release-time sweep would catch it.

**Location:** `.claude/skills/release-plugin/SKILL.md:26-42` (Step 1 block)

#### m-infra-4 (carry-forward, accepted per ADR-010): `prune-context.sh` — 7 instances of `2>/dev/null`

Unchanged from prior audit cycles. Seven instances at lines 26, 44, 67, 71 (×2), 90, 102. Per ADR-007, this is out of scope of the `2>/dev/null` ban (autonomous scripts in consumer repos). Per ADR-010, this finding is formally "Accepted (watch)." Re-tiered accordingly; not a Minor defect for this cycle.

**Location:** `context_template/context/workflows/prune-context.sh:26,44,67,71,90,102` — **accepted per ADR-010; not counted as Minor**

---

## Improvement Opportunities

### IO-I1 — Add template-version verification to `release-plugin` Step 1 pre-flight checklist

**Problem:** The doc-sweep in Step 1 covers user-facing markdown but not `context_template/context/iconrc.json`. Every release that ships template content needs a bump; the gap produced ICON-0044 (retroactive bump). The pre-commit hook catches this at commit time, but a release-time check gives a second confirmation layer.

**Proposed:** Add one sentence after the doc-sweep line at Step 1: "Also verify that `context_template/context/iconrc.json` `version` was bumped since the last release if any file under `context_template/` changed (`git diff <LAST_RELEASE_SHA>..HEAD -- context_template/`)."

**Effort:** Trivial. **Impact:** Medium — prevents a class of silent consumer-upgrade misses.

**Location:** `.claude/skills/release-plugin/SKILL.md:40`

### IO-I2 — Correct or clarify the pre-commit hook header comment invariant ordering

**Problem:** The header says "in script-execution order: 1. Dead-ref, 2. iconrc gate, 3. Script-parity" but actual execution is iconrc gate → common-constraints sync → script-parity → dead-ref. A fifth invariant author reading the comment will get a wrong mental model.

**Proposed:** Either renumber to match actual execution (1. iconrc gate, 2. script-parity, 3. dead-ref) and remove the "in script-execution order" qualifier if it's going to continue to omit common-constraints sync from the list; or add a clarifying note that common-constraints sync runs between iconrc gate and script-parity.

**Effort:** Trivial. **Impact:** Low — reduces maintainer confusion when extending the hook.

**Location:** `.githooks/pre-commit:19-40`

### IO-I3 — Add a `$schema` field to `.mcp.json` if a suitable MCP schema exists

**Problem:** `.claude-plugin/plugin.json` gained `$schema` in ICON-0038 for IDE validation. `.mcp.json` has no equivalent. If a SchemaStore or Claude Code documentation schema for `.mcp.json` is available, adding `$schema` enables IDE auto-completion and validation of the `mcpServers` structure (tool lists, env var placeholders, etc.).

**Proposed:** Research whether `https://json.schemastore.org/` or Claude Code documentation provides an `.mcp.json` schema. If available, add `"$schema": "<url>"` as the first key.

**Effort:** Trivial. **Impact:** Low — quality-of-life for manifest maintenance.

**Location:** `.mcp.json:1`

### IO-I4 — Extend the early-exit comment to mention the iconrc gate's unconditional-execution property

**Problem:** The hook has one hard early exit at line 127–129: if no agent files exist, the script exits 0 (skipping common-constraints sync, script-parity, and dead-ref). The iconrc gate (lines 57–116) runs before this exit. The comment at line 60 says "This check runs before any agent-file early-exit" — correct — but there is no symmetric comment on the early exit itself explaining that the iconrc gate already ran. A reader scanning line 127–129 (`if (( ${#agent_files[@]} == 0 )); then exit 0; fi`) may not realize the iconrc gate already fired.

**Proposed:** Add a one-line comment above `exit 0` at line 128: `# iconrc.json version-bump gate (ICON-0044) already ran above; safe to exit here.`

**Effort:** Trivial. **Impact:** Low — removes a subtle readability trap for the next hook maintainer.

**Location:** `.githooks/pre-commit:127-129`

### IO-I5 — Pre-commit hook: enumerate the "no staged files in scope" short-circuit for script-parity and dead-ref as explicit guard comments

**Problem:** The script-parity check (lines 407–443) and dead-ref check (445–532) both have their own implicit scope guards (`script_parity_needed == 0` and `ref_check_files` empty), but neither has a comment explaining WHY the check is a no-op in those cases. The iconrc gate's no-op path is explained by the `if [[ -n "$template_staged" ]]` block guard with a comment. The ICON-0032 invariants lack the same discoverability.

**Proposed:** Add brief comments before each ICON-0032 check block explaining the short-circuit condition — for example: "# No append-retrospective-entry script copies were staged — parity check skipped."

**Effort:** Trivial. **Impact:** Low — improves hook readability for the next invariant author.

**Location:** `.githooks/pre-commit:406-412`, `:445-458`

---

## Infrastructure-Specific Structural Observations

### 1. Pre-commit hook header comment / execution order mismatch (m-infra-2)

The header comment describes the additional invariants as "in script-execution order," but the numbering (1. dead-ref, 2. iconrc gate, 3. script-parity) does not match actual execution. The common-constraints sync — the hook's original and still-largest block — is also not numbered in the additional invariants list. This is a structural pattern: each new invariant added to the hook appended to the header comment list without re-reading the full script execution order to verify placement. The ICON-0044 retro explicitly warns against this ("when adding new invariants to an existing hook, do a one-pass read of the entire script to map control-flow exits before deciding where the new logic lives") but the header comment did not get the corresponding correction.

### 2. Release-plugin skill gap: template version is a second independent release artifact

With ICON-0044 establishing the `context_template/context/iconrc.json` as a second, independently versioned artifact (alongside `.claude-plugin/plugin.json`), the release-plugin SKILL.md now implicitly covers two versioned artifacts but explicitly describes only one. Step 6 ("Bump the Manifest") updates only `plugin.json`. Steps 5–8 make no mention of `iconrc.json`. This is correct — the iconrc bump is a commit-time concern, not a release-time action. But the release-plugin SKILL.md's overview statement "Every release bumps one manifest file and one changelog" is now technically incomplete: if template files changed, the iconrc also bumped (enforced at commit time). No action needed, but this is worth noting for the next reader of the overview.

### 3. Parity system working as designed

All six `append-retrospective-entry.{sh,ps1}` copies across `skills/post-incident-review/`, `skills/task-retrospective/`, and `skills/context-maintenance/` are confirmed byte-identical. The pre-commit script-parity gate is active and would catch any future drift. The bash copy correctly states `ENTRY_CAP` at 10 in its header comment (line 25: "Counts ### entry blocks…If count >= ENTRY_CAP (10)"). PowerShell copy also states cap at 10 in line 11. No parity drift found.

### 4. No CI config present — validation is manual or hook-based only

Per the brief's pre-check discovery (`find . -maxdepth 3 -name '.gitlab-ci.yml'`): no CI config exists. All mechanical validation (common-constraints byte-equality, iconrc version bump, dead-ref resolution, script parity) is hook-enforced at commit time. This is consistent with ADR-005 (no build step), but means CI-gated schema validation for `plugin.json`, JSON validity checks, or hook-skipped commits are the only risk vectors that aren't caught mechanically.

### 5. `release-plugin` dry-run mode (O-M4) confirmed implemented

`bump-versions.sh` now has `--dry-run` mode (lines 24–92) and a `ver_gt` monotonicity guard (lines 66–79). Both ICON-0015 O-M4 improvements are confirmed on disk.

---

## ICON-0015 Delta

### Fixed since ICON-0015 (confirmed on disk)

| ICON-0015 ID | Description | Closing task / evidence |
|---|---|---|
| M-CC-NET1 (infra sub-cluster) | Doc-drift: `README.md:100,:110` old hook architecture; `.claude/claude.md:9` "two inject scripts"; `commands/enable-/disable-manager-default.md:7` "Starting with ICON 1.16" | ICON-0031; README, `.claude/claude.md`, and commands files confirmed updated. `.claude/claude.md:9` now reads "single `hooks/inject-manager-role.mjs`." No "Starting with ICON 1.16" text in commands. |
| m-1 (infra, partial) | Both manifests lack `$schema` | ICON-0038; `.claude-plugin/plugin.json:2` now has `$schema`. `.mcp.json` still absent — see m-infra-1 carry-forward. |
| m-n2 | `.claude-plugin/plugin.json` declared `"license": "MIT"` but no LICENSE file | ICON-0038; confirmed removed from `plugin.json`. |
| m-n3 | `context_template/README.md` structure diagram omitted `iconrc.json` and `.gitignore` | ICON-0038; `context_template/README.md:29,40` now lists both. |
| m-7 / m-U-H | `release-plugin` no git-repo guard before `git --no-pager branch --show-current` | ICON-0038; `release-plugin/SKILL.md:31` now has guard. |
| m-4 / m-U-K | `format-slack.sh` no `set -euo pipefail` | ICON-0038; confirmed `format-slack.sh:17` has `set -euo pipefail`. |
| O-M4 | `bump-versions.sh` dry-run mode + monotonicity check | ICON-0038; confirmed at `bump-versions.sh:8,24-92`. |
| O-M3 | `plugin.json` LICENSE claim without LICENSE file | ICON-0038; field removed. |
| O-V2 | Extend pre-commit with script-parity gate for `append-retrospective-entry.{sh,ps1}` | ICON-0032; gate confirmed at `.githooks/pre-commit:393-443`. All six copies byte-identical. |
| O-V4 (partial) | Extend pre-commit with dead-ref resolver | ICON-0032; gate confirmed at `.githooks/pre-commit:445-532`. |
| O-M1 | `release-plugin` Step 1 doc-sweep reminder | ICON-0038 (or post-ICON-0038); confirmed at `release-plugin/SKILL.md:40`. |
| ICON-0044 gate | iconrc.json version-bump gate for `context_template/` changes | ICON-0044; confirmed at `.githooks/pre-commit:57-116`. `.claude/claude.md:36-40` documents it. |

### Still present or partial

| ID | Status |
|---|---|
| m-infra-1 | `.mcp.json` lacks `$schema` — the ICON-0015 m-1 finding was listed for both manifests; only `plugin.json` was fixed. |
| m-infra-2 | Pre-commit hook header comment invariant numbering does not match execution order. Net-new this cycle. |

### Net-new since ICON-0015

| ID | Description |
|---|---|
| m-infra-2 | Pre-commit hook header comment lists dead-ref as invariant #1 "in script-execution order" but dead-ref actually executes last (`.githooks/pre-commit:19-40` vs. `:445`). ICON-0044 retro recorded the reorganization but what shipped has the wrong ordering. |
| m-infra-3 | `release-plugin` Step 1 doc-sweep does not mention verifying `context_template/iconrc.json` version bump before tagging — newly relevant since ICON-0044, and motivated by the v1.17.0 missed-bump incident. |
