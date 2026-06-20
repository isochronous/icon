# Infrastructure Audit — Raw Findings

## Summary

Infrastructure domain at v1.19.0 + [Unreleased] (ICON-0056, ICON-0057) is in good health. The ICON-0046 findings are partially resolved: m-infra-2 (hook header comment ordering) is **confirmed fixed** — the header now correctly lists the execution order (1. iconrc gate, 2. script-parity, 3. dead-ref). m-infra-3 (release-plugin Step 1 iconrc check) and m-infra-1 (`.mcp.json` `$schema`) both remain **still absent and unchanged**.

Two net-new Minors have appeared since ICON-0046: (1) the `[1.19.0]` CHANGELOG section contains a duplicate `### Changed` heading — ICON-0049's and ICON-0051's changes each shipped their own `### Changed` block rather than being merged into one; (2) the `append-retrospective-entry.sh` file-level header comment still says "cap (15)" while the code correctly enforces `ENTRY_CAP=10`, a stale-doc remnant from before ICON-0036. Script parity, the pre-commit hook mechanics, and the release-plugin scripts are all healthy. CONTRIBUTING.md shipped cleanly. The Slack webhook integration (ICON-0054) is correctly implemented as non-blocking. The ADR-010 carry-forwards (m1 `prune-context.sh`, m9 DataScan examples) remain present and accepted; not re-tiered.

**Defect counts this cycle: 0 Critical, 0 Moderate, 4 Minor** (m-infra-1, m-infra-3, m-infra-4, m-infra-5). **Improvement Opportunities: 5** (IO-I-A through IO-I-E).

---

## Defect Findings

### Critical

None observed.

### Moderate

None observed.

### Minor

#### m-infra-1 (carry-forward from ICON-0046, unchanged): `.mcp.json` lacks `$schema`

`.claude-plugin/plugin.json:2` has `"$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json"` (confirmed, ICON-0038). `.mcp.json` still has no `$schema` key. The ICON-0046 finding IO-I3 / m-infra-1 explicitly records that ICON-0038 only fixed `plugin.json`; `.mcp.json` was not addressed. No SchemaStore-hosted MCP config schema has been discovered and added.

**Location:** `.mcp.json:1` (entire file; no `$schema` key present)

**Risk:** Low. No IDE validation or schema-driven auto-completion is available for the `mcpServers` structure. Manual errors in tool allowlists or env-var placeholder format are the only blast radius.

**ADR-010 status:** Not an accepted carry-forward (m1 covers `prune-context.sh` only). Still open.

---

#### m-infra-4 (net-new): `[1.19.0]` CHANGELOG section contains a duplicate `### Changed` heading

The `[1.19.0]` release block at `CHANGELOG.md:18-31` contains two separate `### Changed` sections — line 25 (ICON-0049 content) and line 29 (ICON-0051 content). The Keep-a-Changelog format requires each subsection heading to appear at most once per release block. Having two `### Changed` blocks means the second one is invisible to changelog parsers, tooling that renders only the first-seen heading, and reader convention.

This appears to be a merge-time oversight: ICON-0049 and ICON-0051 were developed on separate branches and both produced their own `### Changed` block in `[Unreleased]`. When merged to main and promoted to `[1.19.0]`, neither was consolidated into the other.

The ICON-0056 retro explicitly records a guard for this pattern: "Guarded the recurring `[Unreleased]`-absorption bug by instructing @coder to anchor the CHANGELOG edit on the `## [Unreleased]` header…and prove it by quoting the surrounding lines." That guard applies to the `[Unreleased]` → `[X.Y.Z]` promotion step; however, the duplicate-sub-heading case inside a single version block is a distinct failure mode not covered by the guard.

**Location:** `CHANGELOG.md:25` (first `### Changed` in `[1.19.0]`) and `CHANGELOG.md:29` (duplicate `### Changed` in same block)

**Risk:** Low-Medium. The second `### Changed` block is valid markdown but violates Keep-a-Changelog structure. Downstream consumers parsing CHANGELOG for release notes (e.g., the `format-slack.sh` pipeline in release-plugin Step 9) read the whole block but tooling that extracts "the Changed section" by heading name will capture only the first one. The ICON-0051 RFC-metadata entry (line 31) is effectively invisible to heading-based parsers.

---

#### m-infra-3 (carry-forward from ICON-0046, still absent): `release-plugin` Step 1 doc-sweep omits `context_template/iconrc.json` version check

`release-plugin/SKILL.md:65` Step 1 instructs: "Sweep user-facing docs (`README.md`, `.claude/claude.md`, `commands/*.md`) for behavioral drift vs. current-`main` since the last release tag." This sweep still does not include a check that `context_template/context/iconrc.json` `version` was bumped if any `context_template/` content changed since the last release tag. The ICON-0046 finding m-infra-3 / IO-I1 recommended adding one sentence: "Also verify that `context_template/context/iconrc.json` `version` was bumped since the last release if any file under `context_template/` changed." The ICON-0044 pre-commit hook enforces this at commit time, but a release-time cross-check provides a second confirmation layer and catches any commits made before the hook existed or any hook bypass.

**Location:** `.claude/skills/release-plugin/SKILL.md:65` (Step 1 block; the iconrc check is absent)

**Risk:** Low. The pre-commit hook is the primary enforcement mechanism and is working. The risk is a miss if the hook was ever bypassed or if template commits predate the gate.

---

#### m-infra-5 (net-new): `append-retrospective-entry.sh` file-level header still says "cap (15)" after ICON-0036 cap reduction

`skills/post-incident-review/scripts/append-retrospective-entry.sh:6` reads: "prune the oldest entry when the current count reaches the cap (15)." The cap was reduced from 15 to 10 by ICON-0036 and `ENTRY_CAP=10` at line 41 is correct. The inline behavior comment at line 26 also correctly says `ENTRY_CAP (10)`. Only the top-of-file header (line 6) retains the stale "cap (15)" literal. Because all three byte-identical copies carry this comment, all three state the wrong cap value.

**Location:** `skills/post-incident-review/scripts/append-retrospective-entry.sh:6`; `skills/task-retrospective/scripts/append-retrospective-entry.sh:6`; `skills/context-maintenance/scripts/append-retrospective-entry.sh:6`

**Risk:** Low. Doc-only; code logic is correct. A new consumer reading the file header will have a wrong mental model of when pruning fires.

---

#### m-infra-7 (carry-forward from ICON-0046, improvement opportunities IO-I4/IO-I5 still absent): Pre-commit hook readability gaps

Two ICON-0046 improvement opportunities (IO-I4 and IO-I5) remain unimplemented. Because these were Improvement Opportunities (not defects) in ICON-0046, they are listed here for completeness but are not counted in the Minor defect total:

- **IO-I4 (early-exit missing comment):** The no-agents early exit at `.githooks/pre-commit:127-129` (`if (( ${#agent_files[@]} == 0 )); then exit 0; fi`) has no comment explaining that the iconrc gate (lines 57–116) already ran above this exit. The `iconrc` gate comment at line 60 says "This check runs before any agent-file early-exit" — the symmetric note on the exit side is still absent.

- **IO-I5 (short-circuit guard comments absent):** The script-parity check at lines 406-443 and the dead-ref check at lines 445-532 both have their own scope guards (`if (( script_parity_needed == 1 ))` and `if (( ${#ref_check_files[@]} > 0 ))`), but neither has a comment explaining the skip condition. The iconrc gate uses a clear comment-guarded `if [[ -n "$template_staged" ]]` block; the ICON-0032 invariants lack the same level of discoverability.

**Location:** `.githooks/pre-commit:127-129` (IO-I4); `.githooks/pre-commit:406-412,:445-457` (IO-I5)

**Risk:** Low. Hook behavior is correct; only maintainer readability is affected.

---

#### m-infra-8 (carry-forward from ICON-0046, accepted per ADR-010): `prune-context.sh` — 7 instances of `2>/dev/null`

Unchanged from ICON-0046. Seven instances at lines 26, 44, 67, 71 (×2), 90, 102 (confirmed on disk). Per ADR-007, this is out of scope of the `2>/dev/null` ban (autonomous scripts in consumer repos). Per ADR-010, this finding is formally "Accepted (watch)." Not counted as a Minor defect for this cycle.

**Location:** `context_template/context/workflows/prune-context.sh:26,44,67,71,90,102` — **accepted per ADR-010; not counted as Minor defect**

---

## Improvement Opportunities

### IO-I-A — Add `context_template/iconrc.json` version-bump check to `release-plugin` Step 1 pre-flight

**Problem:** The doc-sweep in Step 1 covers user-facing markdown (`README.md`, `.claude/claude.md`, `commands/*.md`) but not `context_template/context/iconrc.json`. Every release that ships template content needs a bump; the pre-commit gate catches this at commit time but a release-time check is the second confirmation layer. The v1.17.0 missed-bump incident (producing ICON-0044) was the motivating case.

**Proposed:** Add one sentence after the doc-sweep line at Step 1: "Also verify `context_template/context/iconrc.json` `version` was bumped since the last release if any file under `context_template/` changed (`git diff $LAST_RELEASE_SHA..HEAD -- context_template/`)."

**Effort:** Trivial. **Impact:** Medium — prevents a class of silent consumer-upgrade misses (closes m-infra-3).

**Location:** `.claude/skills/release-plugin/SKILL.md:65`

---

### IO-I-B — Add `$schema` to `.mcp.json` if a suitable MCP config schema exists

**Problem:** `.claude-plugin/plugin.json:2` has `$schema`; `.mcp.json` has none. If SchemaStore or Claude Code documentation provides an `.mcp.json` schema, adding `$schema` enables IDE auto-completion and validation of the `mcpServers` structure including tool allowlists and env-var placeholder format.

**Proposed:** Research whether `https://json.schemastore.org/` or Claude Code documentation provides an `.mcp.json` schema. If available, add `"$schema": "<url>"` as the first key.

**Effort:** Trivial. **Impact:** Low (closes m-infra-1).

**Location:** `.mcp.json:1`

---

### IO-I-C — Add `### Changed` deduplication guard to `release-plugin` Step 5 CHANGELOG instructions

**Problem:** The `[1.19.0]` block has a duplicate `### Changed` heading (m-infra-4). The root cause is that multiple feature branches each appended their own `### Changed` block to `[Unreleased]`, and the merge-to-`[X.Y.Z]` promotion step in release-plugin Step 5 does not instruct the releaser to consolidate duplicate subsection headings before promoting. The ICON-0056 retro guard ("anchor on `## [Unreleased]` header, never include the next version header in old_string") prevents absorbing the wrong block but does not prevent the within-block duplicate-heading case.

**Proposed:** Add a one-sentence check at Step 5: "Before promoting, scan `[Unreleased]` for duplicate `### Added`, `### Changed`, `### Fixed`, `### Removed` headings — merge any duplicates into a single heading." Add a row to the Error Conditions table: `[Unreleased] contains duplicate ### section headings → merge into one before promoting`.

**Effort:** Trivial. **Impact:** Medium — prevents a recurring structural defect class that arises from parallel feature branches.

**Location:** `.claude/skills/release-plugin/SKILL.md:133-160` (Step 5 CHANGELOG instruction block)

---

### IO-I-D — Add a pre-commit hook installation reminder to `README.md`

**Problem:** `CONTRIBUTING.md:50-52` instructs contributors to configure the local hooks path (`git config core.hooksPath .githooks`). `README.md` has no equivalent instruction. A developer who clones the repo without reading CONTRIBUTING.md will have no hooks installed and will bypass the four invariant gates silently.

**Proposed:** Add a short note to `README.md` Installation section or a new "Local Development" subsection: "After cloning, wire the pre-commit hook: `git config core.hooksPath .githooks`."

**Effort:** Trivial. **Impact:** Medium — prevents a class of commits that bypass the common-constraints sync, iconrc gate, script-parity check, and dead-ref resolver.

**Location:** `README.md` — no current mention of hook installation (new addition needed).

---

### IO-I-E — Neutralize the `Co-authored-by: Copilot` hardcode in `release-plugin` Step 7 commit template

**Problem:** `release-plugin/SKILL.md:198` contains a hardcoded `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>` in the Step 7 commit template. Recent releases (e.g., ICON-0056, ICON-0057) have been authored using Claude Code and carry `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>` in their commit messages. The hardcoded Copilot attribution is stale: if a Claude Code maintainer follows the template literally, they misattribute the release commit to Copilot.

**Note:** This is a maintainer-only skill (`.claude/skills/release-plugin/`), so ADR-004 tool-agnostic content rules apply with reduced priority — the skill explicitly targets both tools. However, the specific hardcoded Copilot GitHub user ID is factually incorrect for a Claude Code session.

**Proposed:** Replace the hardcoded `Co-authored-by: Copilot` line with a comment: `# Add the appropriate Co-authored-by line for the tool performing this release.`

**Effort:** Trivial. **Impact:** Low.

**Location:** `.claude/skills/release-plugin/SKILL.md:197-199` (Step 7 commit template)

---

## Infrastructure-Specific Structural Observations

### 1. m-infra-2 confirmed fixed (ICON-0046 → ICON-0058 delta)

The ICON-0046 m-infra-2 finding — that the pre-commit hook header comment numbered the invariants incorrectly ("1. dead-ref / 2. iconrc gate / 3. script-parity in script-execution order" while actual execution ran iconrc gate first) — is confirmed fixed. The current header at `.githooks/pre-commit:19-40` correctly lists:

```
1. iconrc.json version-bump gate
2. Script-parity check
3. Dead-ref resolver
```

This matches the actual execution order confirmed in the script body (iconrc gate at :57, script-parity at :406, dead-ref at :445). The fix removes the maintainer trap flagged in ICON-0046.

### 2. Script parity system confirmed working

All six `append-retrospective-entry.{sh,ps1}` copies across `skills/post-incident-review/`, `skills/task-retrospective/`, and `skills/context-maintenance/` are confirmed byte-identical (verified with `diff -q`). The pre-commit script-parity gate is active. ENTRY_CAP is correctly set to 10 at line 41, and the behavior comment on line 26 correctly says `ENTRY_CAP (10)`. However, the file-level header comment on line 6 still says "prune the oldest entry when the current count reaches the cap (15)" — a stale remnant from before ICON-0036 reduced the cap from 15 to 10. The code logic is correct; only the top-of-file doc comment is wrong.

**Location:** `skills/post-incident-review/scripts/append-retrospective-entry.sh:6` (says "cap (15)" in the file-level header; `ENTRY_CAP=10` at :41 is correct; all three copies are byte-identical so all three carry the stale comment)

### 3. CONTRIBUTING.md correctly describes the task flow and hook wiring

`CONTRIBUTING.md` (ICON-0050) correctly describes the `New task:` / `task complete` flow, references ADRs, and instructs contributors to configure `core.hooksPath`. The `Maintainers: cutting a release` section accurately summarizes the Slack webhook behavior from ICON-0054. No content drift detected.

### 4. No CI config present — validation is hook-only

Per the brief's pre-check discovery: no `.gitlab-ci.yml` exists. All mechanical validation (common-constraints byte-equality, iconrc version bump, dead-ref resolution, script parity) is hook-enforced at commit time. This is consistent with ADR-005 (no build step). The dispatch brief notes "repo currently has no CI config" — confirmed.

The CHANGELOG confirms that at one point in the MKT-numbered history, a `.gitlab-ci.yml` was added (MKT-0069: "Added .gitlab-ci.yml lint stage"). That CI config is no longer present, suggesting it was removed at some point in the standalone-repo migration. The current state is hook-only enforcement with no CI schema validation.

### 5. `.mcp.json` version bump (Tom Stear / `mcp-atlassian==0.21.1`)

The dispatch brief notes a contributor (Tom Stear) changed the `.mcp.json` `mcp-atlassian` version. On disk: `args: ["mcp-atlassian==0.21.1"]` at `.mcp.json:87`. Git history confirms this was updated via commit `91f6fa0` (message: "Update atlassian mcp server version"). The change is structurally sound — version pinning in a `uvx` args list is the correct form, and the tool allowlist structure is unaffected. No finding raised.

### 6. Discovery pass: no sibling `-beta` / `-dev` repos found

`find .` discovered no sibling `-beta`, `-dev`, or `-staging` variant repos. The `.github/` directory does not exist (except in the `.context/` folder context). There is no `.github/plugin/plugin.json`. The pre-check discovery confirms:

- MCP configs: one (`.mcp.json`)
- READMEs at plugin level: two (`README.md`, `context_template/README.md`) — both in scope
- Manifest variants: one (`.claude-plugin/plugin.json`) — the `plugin.json` at repo root and `.github/plugin/plugin.json` variants are absent
- Hook scripts: `hooks/hooks.json` and `hooks/inject-manager-role.mjs` (Claude Code session hooks — different mechanism from `.githooks/`), and `context_template/context/workflows/prune-context.sh` (consumer-shipped workflow script)

`hooks/hooks.json` and `hooks/inject-manager-role.mjs` are not in the brief's `## Inputs` enumeration but are discovered by the pre-check. Both are audited:

- `hooks/hooks.json:1-16` — SessionStart hook declaration is correct. Uses `"matcher": "startup|resume"` and exec-form `node "${CLAUDE_PLUGIN_ROOT}/hooks/inject-manager-role.mjs"`. No structural issues found.
- `hooks/inject-manager-role.mjs` — Claude Code session hook. Implements the manager-default injection correctly. No infrastructure defects found in the top-level header review.

`context_template/context/workflows/prune-context.sh` is an ADR-007/010 accepted carry-forward (m1 — 7 `2>/dev/null` instances). Out of scope of the ban per ADR-007; accepted per ADR-010.

---

## ICON-0046 Delta

### Fixed since ICON-0046

| ICON-0046 ID | Description | Evidence |
|---|---|---|
| **m-infra-2** | Pre-commit hook header comment invariant numbering was incorrect ("1. dead-ref / 2. iconrc gate / 3. script-parity" when actual execution was iconrc gate first) | `.githooks/pre-commit:19-40` now correctly lists "1. iconrc.json version-bump gate / 2. Script-parity check / 3. Dead-ref resolver" in execution order |
| **IO-I2** (Improvement opportunity) | Correct/clarify hook header comment invariant ordering | Confirmed fixed — same evidence as m-infra-2 |

### Still present or partial

| ID | Status |
|---|---|
| **m-infra-1** | `.mcp.json` lacks `$schema` — unchanged from ICON-0046 |
| **m-infra-3** | `release-plugin` Step 1 doc-sweep still does not mention `context_template/iconrc.json` version check |
| **IO-I3** (Improvement opportunity) | Add `$schema` to `.mcp.json` — research + implementation not done |
| **IO-I4** (Improvement opportunity) | Add "iconrc gate already ran above" comment at pre-commit early exit — not implemented |
| **IO-I5** (Improvement opportunity) | Add short-circuit guard comments for script-parity and dead-ref blocks — not implemented |

### Net-new since ICON-0046

| ID | Description |
|---|---|
| **m-infra-4** | `CHANGELOG.md:25,29` — duplicate `### Changed` heading in the `[1.19.0]` release block (ICON-0049 and ICON-0051 each supplied a separate `### Changed` section; neither was consolidated during merge) |
| **m-infra-5** | `append-retrospective-entry.sh:6` (all three byte-identical copies) — file-level header still says "cap (15)" while `ENTRY_CAP=10` at :41 is correct; ICON-0036 reduced the cap but left the header docstring stale |
| **IO-I-C** | `release-plugin` Step 5 has no deduplication guard for parallel-branch `### Changed` duplicate headings — structural process gap surfaced by m-infra-4 |
| **IO-I-D** | `README.md` has no hook installation instruction; `CONTRIBUTING.md` covers it but README does not |
| **IO-I-E** | `release-plugin/SKILL.md:197-199` hardcodes `Co-authored-by: Copilot` in the release commit template, but recent releases use Claude Code attribution |
