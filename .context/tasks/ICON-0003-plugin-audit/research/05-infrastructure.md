# Infrastructure Audit — Raw Findings

## Summary

Post-split infrastructure has shrunk to a small, well-formed surface: one canonical manifest (`.claude-plugin/plugin.json:1-18`), one MCP registry (`.mcp.json:1-151`), one repo-root README/CHANGELOG, one SessionStart-hook pair (`hooks/inject-manager-role.{sh,ps1}`), one repo-level git hook (`.githooks/post-commit`) wired to `.context/workflows/prune-context.sh`, and one maintainer-only release skill at `.claude/skills/release-plugin/` (plus two scripts). JSON manifests both parse (`python3 -c "import json; json.load(...)"` exits 0). Version SSOT is enforced de facto by being a single field in a single file: `1.15.3` at `.claude-plugin/plugin.json:4` is the only canonical version reference in the repo (verified by grep across `*.md`/`*.json`/`*.sh`/`*.ps1` excluding `CHANGELOG.md` and `.context/`). The MKT-0080 MCP allowlist landed cleanly: 70 gitlab + 51 atlassian tools, zero destructive ops in either set (grep for `delete|cancel|create_or_update|remove|move` over tool names returns no matches). The prune-script TTL fix from ICON-0002 is correctly in place at `.context/workflows/prune-context.sh:50-52` with the `|| true` tail-guard, AND the same fix is mirrored in the shipped template at `context_template/context/workflows/prune-context.sh:50-52` — the two files differ only in the expected ways (`INTEGRATION_BRANCHES` regex + comment header). The dominant active defect is a documentation conflict already named in `.context/retrospectives.md` (ICON-0001) but unaddressed: `changelog.md:11` says the release flow "renames" the `[Unreleased]` header, while `release-plugin/SKILL.md:106` says it "inserts a new entry immediately below the `[Unreleased]` block" — these prescribe different post-release CHANGELOG shapes. Several MKT-0087 minor findings are explicitly out-of-scope post-split (no `marketplace.json`, no `.gitlab-ci.yml`, no ICON-beta/, no second `bump-versions.sh`); these are recorded under Structural Observations, not in defect tiers. Net infrastructure health: GOOD with one Moderate doc-conflict and a recurring `$schema` gap.

---

## Defect Findings

### Critical

None observed.

### Moderate

**M-1 · `release-plugin/SKILL.md` Step 5 and `.context/workflows/changelog.md:11` prescribe different CHANGELOG mutation shapes — pre-existing conflict, called out but unresolved in retro ICON-0001.**
`.context/workflows/changelog.md:11` reads `When a release is cut via /release-plugin, the [Unreleased] header is renamed to [X.Y.Z] - YYYY-MM-DD and a fresh [Unreleased] section is added above it.` Diagram below it (`:13-17`) shows the resulting shape: `## [Unreleased]` empty on top, then the renamed `## [1.13.0] - YYYY-MM-DD` block. `.claude/skills/release-plugin/SKILL.md:105-108` instead reads `Insert a new entry immediately below the [Unreleased] block, before the previous release:` — i.e. the `[Unreleased]` block is preserved with its current contents intact and a separate `[X.Y.Z]` block is added below. The two procedures produce different end states: the workflow doc moves the accumulated entries into the new versioned section; the skill leaves them in `[Unreleased]` and writes an empty `[X.Y.Z]` block. The retrospective entry `.context/retrospectives.md:9` explicitly flagged this ("workflow doc is operationally correct, SKILL.md should be reconciled in a separate task") and shipped without filing the follow-up. Looking at the current `CHANGELOG.md:9-11` — `[Unreleased]` is empty and `[1.15.3]` is fully populated — the workflow-doc-style "rename" is what actually shipped at v1.15.3, so the SKILL.md prose is the diverged copy. Maintainer-only blast radius (release skill is not shipped), but the next release run risks the maintainer following SKILL.md verbatim and producing the wrong shape.

**M-2 · `release-plugin/SKILL.md:258` Error Conditions row references `sed` directly, but Step 6 delegates to `bump-versions.sh`.**
`release-plugin/SKILL.md:258` reads `| sed leaves the manifest at the old version | Stop. Report the file was not updated |`. Step 6 (`.claude/skills/release-plugin/SKILL.md:130-146`) no longer invokes `sed` directly — it calls `bash .claude/skills/release-plugin/scripts/bump-versions.sh "$NEW"`. The companion script uses `sed` internally (`bump-versions.sh:57`), so the prose is not strictly wrong, but the Error Conditions row points at an action layer that the human reader doesn't perform. Direct carry from MKT-0087 m-5 / MKT-0077 m-U8 — staleness has now persisted across three audits. Tier-2 because the row is in the most-consulted section of the skill (Error Conditions).

### Minor

**m-1 · Both JSON manifests lack a `$schema` declaration.**
`.claude-plugin/plugin.json:1-18` and `.mcp.json:1-151` carry no `$schema` field (verified by `grep '\$schema' .claude-plugin/plugin.json .mcp.json` → 0 hits). Editor/IDE tooling cannot auto-discover the plugin or MCP-server schemas; drift in shape is not detectable by static lint. Direct carry from MKT-0087 m-1 (then 7/8 manifests; here 2/2). User-groomed deferral.

**m-2 · `hooks/inject-manager-role.ps1` is not executable (mode 644); `inject-manager-role.sh` is (mode 755).**
`hooks/inject-manager-role.ps1:1-66` ships with mode `644` per `stat -c '%a' hooks/inject-manager-role.ps1`. The hook is invoked as `pwsh -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/hooks/inject-manager-role.ps1"` (per `commands/enable-manager-default.md:41`), so the executable bit is irrelevant in practice. But the parity gap is visible to anyone auditing the hook surface and risks confusion if a future invocation pattern switches to direct execution. Cosmetic.

**m-3 · `inject-manager-role.sh` and `inject-manager-role.ps1` have no parity test.**
Bash variant emits JSON via `awk`-based escaping (`hooks/inject-manager-role.sh:51-65`); PowerShell variant emits JSON via `ConvertTo-Json -Compress -Depth 4` (`hooks/inject-manager-role.ps1:55-65`). PowerShell strips trailing newlines via `.TrimEnd("\`r", "\`n")` (`hooks/inject-manager-role.ps1:53`) "to match the byte output of the bash sibling's cat" but no automated test verifies the two outputs round-trip to byte-identical JSON. Direct carry from MKT-0087 m-7. User-groomed deferral.

**m-4 · `format-slack.sh` runs without strict-mode (`set -euo pipefail`).**
`.claude/skills/release-plugin/scripts/format-slack.sh:1-21` has no `set -euo pipefail`. The script is short, pure-stdin/stdout, and all sed invocations are safe-by-construction, so the omission is not load-bearing. Asymmetric with `bump-versions.sh:11` (strict-mode) and the prune-script (strict-mode + `|| true` tail-guard, the ICON-0002 lesson). Net: a single sed-pipeline failure in `format-slack.sh` would silently emit truncated Slack notes via the calling pipeline at `release-plugin/SKILL.md:227-231`.

**m-5 · `bump-versions.sh:42` OLD-version parse uses `grep '"version"'` without scoping to top-level — works only because `.claude-plugin/plugin.json` has exactly one `"version"` line.**
`.claude/skills/release-plugin/scripts/bump-versions.sh:42` reads `OLD=$(grep -m1 '"version"' "$PRIMARY" | sed 's/.*"version": "\(.*\)".*/\1/')`. If a future schema adds a nested `"version"` key (e.g., for an MCP dependency pin), `grep -m1` would match the first such line, not necessarily the top-level one. The current manifest has one `"version"` line so the script works; defense-in-depth: switch to `jq` (already used in `prune-context.sh:44`) or anchor on `.claude-plugin/plugin.json`'s top-level object. Same class as MKT-0087 m-3.

**m-6 · Release skill caller-listing is empty in frontmatter `description`.**
`.claude/skills/release-plugin/SKILL.md:3-7` description names no callers — the skill is maintainer-invoked via `/release-plugin`. Per Common Check Pattern 3 (caller-listing in description), the absence is technically a miss, but the skill is user-invocable (`user-invocable: true`, `:8`) and the only caller is the human operator, so there is no agent caller to list. Note for completeness; not a defect.

**m-7 · `release-plugin/SKILL.md:32` calls out `git --no-pager branch --show-current` but doesn't check whether the repo is a git repo at all.**
If invoked outside a git repo (e.g., the maintainer cloned just the tarball), `git --no-pager branch --show-current` exits with `fatal: not a git repository` — the skill text says `If not on main, stop`, but the failure mode isn't `not on main`, it's `not in any git repo`. Cosmetic edge — the skill is maintainer-only so a maintainer would notice immediately.

---

## Improvement Opportunities

**O-1 · Reconcile `changelog.md:11` ⇄ `release-plugin/SKILL.md:105-108` and document the actual shape.**
Effort: small (one edit to one file). Impact: high. Closes the M-1 doc-conflict and discharges the unfiled follow-up named in `.context/retrospectives.md:9`. Direction: SKILL.md is the diverged copy per the v1.15.3 release evidence (which followed the rename pattern); rewrite Step 5 to match `workflows/changelog.md:11`'s "rename + add fresh empty `[Unreleased]` above" procedure.

**O-2 · Add a manifest-schema validator (one-line `python3 -m json.tool` or `jq empty`) wired to the `.githooks/post-commit` (or a pre-commit) hook.**
Effort: medium (3–5 lines bash + hook wire-up). Impact: catches the most-likely failure mode of the maintainer release flow — a malformed JSON edit landing in `.claude-plugin/plugin.json` or `.mcp.json` between releases. The MKT-0087 marketplace ran `validate-manifests.sh` in CI; this repo has no CI yet, and the existing `.githooks/post-commit` is wired only to prune-context. Wiring a JSON-validity check to the same hook is a 4-line change.

**O-3 · Adopt `$schema` declarations on both manifests.**
Effort: 2 single-line additions. Impact: enables editor tooling (VS Code, IntelliJ) to validate `.claude-plugin/plugin.json` against the marketplace schema and `.mcp.json` against the MCP-server-config schema. Documents the contract; makes future shape drift detectable client-side. Direct carry of MKT-0087 O-4; reduces in scope here to 2 files vs the marketplace's 7.

**O-4 · Add a dry-run flag to `release-plugin/scripts/bump-versions.sh`.**
Effort: small (4 lines — flag parse + guard the `sed -i`). Impact: closes the Common Check Pattern 4 gap (operational defensiveness on the only write-side script in the release flow). The skill currently says (`:140-146`) "verify the file was updated" after the bump, but the verification is a `grep` after-the-fact, not a preview. A dry-run flag (`bump-versions.sh --dry-run X.Y.Z`) prints the proposed diff without writing — useful both for the maintainer and for any future CI smoke-test.

**O-5 · Add a post-bump sanity check that the new version parses as semver and is monotonically greater than the old version.**
Effort: small. Impact: catches accidental version regressions (e.g., maintainer types `1.15.2` instead of `1.16.0` and the script happily writes it). Current validation (`bump-versions.sh:28`) only checks the input matches `^[0-9]+\.[0-9]+\.[0-9]+$`; no monotonicity check. The `release-plugin/SKILL.md:99-100` already prescribes the "increment-segment, zero-lower" rule — codifying it in the script closes the gap between prose and tool.

---

## Infrastructure-Specific Structural Observations

**No `marketplace.json` / `.gitlab-ci.yml` / `ICON-beta/` / second-variant `plugin.json` — out-of-scope for standalone repo.** The MKT-0087 infrastructure findings against marketplace-only artifacts (`m-1` $schema on 7 manifests, `m-6` `.gitlab-ci.yml` interpreter gap, `m-8` `.mcp.json` drift guard between ICON and ICON-beta, `m-10` release-plugin-beta verification gap, `M-3` ICON-beta CHANGELOG orphan, the entire `release-plugin-beta` skill, `validate-manifests.sh` + `plugin-lint.sh` in `.claude/scripts/`) target files that did not migrate to this repo and were never expected to. The split commit `254ff7c chore: split ICON to standalone repo at v1.15.3` flattened the marketplace's two-plugin / two-channel topology to a single-repo / single-channel release flow. The synthesis pass should NOT mark these "fixed" — they are not applicable.

**No CI/CD in this repo (yet).** `find . -name '*.yml' -o -name '*.yaml'` returns nothing under the audit-scope paths (only `.context/iconrc.json` is config-flavored). The marketplace baseline's MKT-0069 `.gitlab-ci.yml` lint stage (running `validate-manifests.sh` + `plugin-lint.sh`) did not migrate. The release flow is now entirely local-and-manual: the maintainer runs `bump-versions.sh`, commits, and pushes — no CI gate catches a malformed manifest or stale-changelog before the tag lands. This is an architectural choice (matched to "main-only branch model" per `.claude/skills/release-plugin/SKILL.md:24`), not a defect.

**Hook surface is intentionally minimal post-split.** `.githooks/post-commit:1-7` (5 lines) wraps `.context/workflows/prune-context.sh` (the only repo-level git hook). The marketplace's pre-commit chain (`common-constraints` sync, dev-version auto-bump, `validate-manifests.sh`, `plugin-lint.sh`) did not migrate. Pre-commit responsibilities now live at the maintainer's discretion. The hook is wired via `git config core.hooksPath .githooks` (confirmed: `git config core.hooksPath` → `.githooks`).

**Two `prune-context.sh` copies are intentionally non-identical.** `.context/workflows/prune-context.sh:24` pins `INTEGRATION_BRANCHES="^main$"` (this repo is main-only); `context_template/context/workflows/prune-context.sh:24` uses `^(main|master|dev|develop|trunk)^` as the template default that `initialize-repo` rewrites. Lines `:20-22` differ in the comment header. The ICON-0002 `|| true` tail-guard fix is present in both (verified `grep -n '|| true' .context/workflows/prune-context.sh context_template/context/workflows/prune-context.sh` → both `:52`). The fix mirrored correctly across the split.

**`inject-manager-role.{sh,ps1}` are not declared in `.claude-plugin/plugin.json` — opt-in only.** `.claude-plugin/plugin.json:1-18` has no `hooks` key; the SessionStart hook is wired explicitly by `/ICON:enable-manager-default` (`commands/enable-manager-default.md:21-44`) into the user's `~/.claude/settings.json`. Substring-match removal in `disable-manager-default.md:11` uses the token `inject-manager-role` to handle both variants. Convention documented inline at `hooks/inject-manager-role.sh:14-17` and `hooks/inject-manager-role.ps1:15-17`.

**`release-plugin` ships under `.claude/skills/` — maintainer-only by design.** `.claude/skills/release-plugin/SKILL.md` is not in the plugin's shipped `skills/` directory (`ls skills/ | grep release` → empty); it lives under `.claude/skills/` which is the repo's own Claude Code project-level skill location. End-user installs of ICON do not receive this skill. The `claude.md` workflow doc (`.context/workflows/changelog.md:23-24`) names this explicitly. Tradeoff: the release flow is invisible to plugin consumers (correct) but also unprotected by the plugin's audit infrastructure (this audit-skill, `plugin-audit`, scans the shipped plugin only — `.claude/skills/release-plugin/` was added to this audit's scope by explicit brief override).

**MCP allowlist composition verified clean.** 70 gitlab + 51 atlassian tools; zero `delete_*` / `cancel_*` / `create_or_update_*` / `remove_*` / `move_*` matches across both servers (`python3 -c "..."` filter returns empty). Both servers use `${VAR}` placeholder substitution (`.mcp.json:8-10` for gitlab; `.mcp.json:88-94` for atlassian); no secrets in source. The MKT-0080 hardening that landed pre-split survived the migration byte-for-byte.

**Common Check Pattern 5 — frontmatter parser-fragility — passes.** `.claude/skills/release-plugin/SKILL.md:3-7` uses the YAML folded-block-scalar form (`description: >`) for the multi-line description. No instances of plain-scalar descriptions with mid-value `: ` or `[…]` in the audit-scope files. The four `commands/*.md` files (`commands/disable-manager-default.md:1-3`, `enable-manager-default.md:1-3`, `manager.md:1-3`, `pm.md:1-3`) all use single-line plain `description:` strings with no special characters — parser-safe.

**Common Check Pattern 1 — self-reference — N/A for infrastructure files.** Infrastructure files (manifests, hooks, scripts) don't have "their own rules" to follow. Documented for completeness.

**Common Check Pattern 2 — template / standard cross-reference — passes.** `release-plugin/SKILL.md:122` cites `.context/standards/changelog-discipline.md` (verified existence: `ls .context/standards/changelog-discipline.md` would resolve; not opened for content verification under read-only scope). The cross-reference is sound; drift would be caught by an independent audit of `.context/standards/`.

---

## MKT-0087 Delta

### Fixed since MKT-0087

- **MKT-0087 m-2 `prune-old-tasks.sh` 2>/dev/null instances.** The file was renamed to `prune-context.sh` in ICON-0002 and the remaining `2>/dev/null` instances (`.context/workflows/prune-context.sh:26, 44, 67, 71, 90, 102, 106`) are all in `git`/`stat` fallback gates inside `LAST_COMMIT="$(... 2>/dev/null || echo …)"` patterns where the empty-stderr discard is the documented correct shape — paired with the ICON-0002 `|| true` lesson tail-guards on parse pipelines. Reframed from "banned pattern" to "gated-fallback pattern."
- **MKT-0087 m-9 `mr-discipline` README skills-table omission across root user docs.** Out-of-scope post-split — `CHEAT_SHEET.md`/`BEST_PRACTICES.md`/`GETTING_STARTED.md` did not migrate. The single shipped `README.md:194` lists `mr-discipline` correctly.
- **MKT-0087 O-2 `plugins/ICON-beta/CHANGELOG.md` orphan.** Out-of-scope post-split — no ICON-beta channel exists in this repo.

### Still present or partial

- **MKT-0087 m-1 `$schema` missing on all manifests.** Persists as m-1 here. Count dropped from 7 to 2 because most marketplace manifests did not migrate, but both of this repo's manifests still lack `$schema`. User-groomed deferral.
- **MKT-0087 m-5 release-plugin Error Conditions `sed` reference.** Persists as M-2 here (re-tiered to Moderate because Step 6 explicitly delegates to `bump-versions.sh` now, making the Error Conditions row's `sed` reference more clearly stale). Same line (`release-plugin/SKILL.md:258`). Third audit in a row to flag this class.
- **MKT-0087 m-7 inject-manager-role bash/pwsh parity test missing.** Persists as m-3 here. Unchanged.
- **MKT-0087 m-3 `bump-versions.sh` regex hygiene.** Persists as m-5 here (different shape — the marketplace concern was a `'X.Y.Z'$` rewrite pattern across two marketplace files; here the concern is the parse-side `grep '"version"'` lacking top-level anchoring). Same root class.

### Net-new since MKT-0087

- **M-1 (release-plugin SKILL.md ⇄ workflows/changelog.md doc conflict).** Net-new because `workflows/changelog.md` did not exist in the marketplace tree (created in ICON-0001 migrate-from-marketplace). The conflict was named in `.context/retrospectives.md:9` and explicitly deferred — now resurfacing as an active defect.
- **m-2 (`inject-manager-role.ps1` mode 644 vs `.sh` 755).** Net-new visibility post-split: marketplace audit did not check file modes; cosmetic but worth one line in observation.
- **m-4 (`format-slack.sh` no strict-mode).** Net-new since the script was introduced post-MKT-0087 (added in MKT-0070 alongside the canonical-paths preamble; previously the slack-formatter was inline).
- **m-6 (release skill caller-listing empty).** Net-new because the brief's Common Check Pattern 3 wasn't applied in MKT-0087; mentioned here for completeness, not a defect.
- **m-7 (`release-plugin/SKILL.md:32` no git-repo guard).** Net-new — pre-split the release skill was always invoked from inside the marketplace monorepo, so the failure mode was vanishingly unlikely. Post-split with the skill maintainer-only and the repo small, a tarball-clone footgun is slightly more plausible.
- **O-1 / O-2 / O-4 / O-5 (improvement opportunities specific to the post-split shape).** Net-new because the marketplace had a CI lint stage handling these concerns; with no CI, the gap moves to local-hook scope.
