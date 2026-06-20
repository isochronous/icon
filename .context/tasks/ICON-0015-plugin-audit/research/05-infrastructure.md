# Infrastructure Audit — Raw Findings

**Audit cycle:** ICON-0015
**Plugin version on main:** `1.15.4` (tagged at `b153591`; ICON-0011 and ICON-0012 merged to main after tag, in `[Unreleased]`)
**Prior audit:** ICON-0003 (2026-05-14)
**Date:** 2026-05-20
**Auditor:** Infrastructure domain sub-agent

---

## Summary

The infrastructure surface is materially cleaner than ICON-0003. Both Moderate findings from ICON-0003 (M-1 CHANGELOG-shape conflict, M-2 Error Conditions `sed` reference) are fully fixed. The prior m-2/m-3 bash-vs-pwsh parity issues are resolved by deletion — ICON-0012 replaced the two-script pair with a single Node.js wrapper. The pre-commit hook (ICON-0011) is correctly wired via `git config core.hooksPath = .githooks`, confirmed live. The release-plugin skill is now internally consistent in the post-ICON-0010 shape.

The dominant finding this cycle is a CHANGELOG-to-shipped-code lag that produced two layers of documentation drift simultaneously: (1) ICON-0011 and ICON-0012 merged to `main` after the `v1.15.4` release tag without triggering a version bump or a README/`.claude/claude.md` update sweep, leaving three user-facing documents describing the pre-ICON-0012 hook architecture; and (2) ICON-0014 (plan.md freshness gate) remains on an unmerged feature branch — its changes to `manager.agent.md`, `task-plan-phase-completion/SKILL.md`, and `.context/workflows/task-plan/phase-completion.md` are not present on `main`, contradicting the brief's claim that those surfaces should document the gate.

Three minor carry-forwards (format-slack.sh strict mode, release-plugin git-repo guard, both manifests missing `$schema`) persist unchanged from ICON-0003.

---

## Defect Findings

### Critical

None observed.

### Moderate

**M-N1 · README `Default Role` section describes pre-ICON-0012 hook architecture**

`README.md:100` reads: "This wires a `SessionStart` hook into your `~/.claude/settings.json`." After ICON-0012, the SessionStart hook is declared in `hooks/hooks.json` (plugin-scoped, active automatically on install). `/ICON:enable-manager-default` no longer writes to `~/.claude/settings.json`; it sets `managerDefault: true` in `~/.claude/icon-user-settings.json`. A new user following the README's "Default Role" section will form a wrong mental model of how the feature works.

`README.md:110` reads: "`/ICON:disable-manager-default` — Remove the SessionStart hook." The hook can no longer be "removed" (it lives in the plugin's `hooks/hooks.json` and is always present after install); the command only writes `managerDefault: false` to the user-settings file. The effect description is inaccurate.

Both are directly contradicted by `CHANGELOG.md:13-21` (the `[Unreleased]` entries for ICON-0012) and by `commands/enable-manager-default.md:7` and `commands/disable-manager-default.md:7`.

- **Location:** `README.md:100,:110` vs `CHANGELOG.md:13-21`; `commands/enable-manager-default.md:7`; `commands/disable-manager-default.md:7`
- **Risk:** User-facing documentation mismatch. A developer following the README will check `~/.claude/settings.json` for the hook and find nothing, or will not understand why `/ICON:disable-manager-default` does not remove the hook they see firing.

**M-N2 · `.claude/claude.md` tech-stack description stale after ICON-0012**

`.claude/claude.md:9` reads: "Bash / PowerShell for the **two** `hooks/inject-manager-role.*` scripts and the maintainer `release-plugin` scripts." After ICON-0012, there is exactly one hook file: `hooks/inject-manager-role.mjs` (Node.js). The `.sh` and `.ps1` variants were deleted. The tech stack line will cause any agent loading this file to believe two scripts exist and to search for the `.sh`/`.ps1` variants.

- **Location:** `.claude/claude.md:9` vs `hooks/inject-manager-role.mjs:1-91`; `CHANGELOG.md:21` (Removed section)
- **Risk:** Agent confusion on any task that touches the hook surface. The Removed entry in `[Unreleased]` is correct; the project instructions file was not swept.

### Minor

**m-n1 · `commands/enable-manager-default.md` and `commands/disable-manager-default.md` anticipate a not-yet-released version**

`commands/enable-manager-default.md:7` reads: "Starting with ICON 1.16, the SessionStart hook is declared in the plugin's own `hooks/hooks.json`." Same text in `commands/disable-manager-default.md:7`. The current released version is `1.15.4`; the ICON-0012 changes described are in `[Unreleased]` on `main`. The commands ship the new behavior while describing it as a future-version feature — a consumer who has the `v1.15.4` tagged version will see the new behavior but the "Starting with ICON 1.16" framing is inconsistent with what they have installed.

- **Location:** `commands/enable-manager-default.md:7`; `commands/disable-manager-default.md:7`; `.claude-plugin/plugin.json:4` (`"version": "1.15.4"`)
- **Risk:** Cosmetic confusion; the commands function correctly. Resolves automatically when ICON-0011/0012 are released (next version bump).

**m-n2 · `plugin.json` claims `"license": "MIT"` but no `LICENSE` file exists**

`.claude-plugin/plugin.json:9` declares `"license": "MIT"`. No `LICENSE` or `LICENSE.md` file exists anywhere in the repo root (confirmed via discovery pass). The field is unenforceable without the actual license text on-disk and creates an ambiguity for any consumer or marketplace system that validates license declarations against an on-disk file.

- **Location:** `.claude-plugin/plugin.json:9`; filesystem (no `LICENSE` file)
- **Risk:** Legal ambiguity; not a security risk. Low immediate impact in a private org repo.

**m-n3 · `context_template/README.md` structure diagram missing three items present in the actual template**

`context_template/README.md:27-38` lists the `context/` directory structure. Missing from the diagram: `iconrc.json` (present at `context_template/context/iconrc.json`), `.gitignore` (present at `context_template/context/.gitignore`), and `cache/` (not in the template directory itself, but documented in the top-level `README.md:130` as part of the `.context/` structure deployed in consumer repos). The first two are concrete omissions from the diagram for files that exist in the template being shipped.

- **Location:** `context_template/README.md:27-38` vs `context_template/context/iconrc.json`, `context_template/context/.gitignore`
- **Risk:** Consumers setting up manually from the template will not know about `iconrc.json` configuration or the `.gitignore` for `.topology-cache.json`. Low impact since `/icon-init` is the documented path.

**m-n4 · ICON-0014 plan.md freshness gate not present on `main`**

The ICON-0014 feature branch (`feature/ICON-0014-plan-md-freshness-gate`) contains changes to `agents/manager.agent.md` (step 0 under "Before closing a task" plus an AR row), `.context/workflows/task-plan/phase-completion.md` (§ Reconcile plan.md, template-version bump 1.2→1.3), and `skills/task-plan-phase-completion/` (indirectly, via the local override mechanism). None of these changes appear on `main` — the branch has not been merged.

The brief for this audit states: "Verify [ICON-0014] is documented in the manager agent and `task-plan-phase-completion` skill, and consistent with `.context/META.md`." As of the `main` branch (audit baseline), it is not. `.context/META.md:55` says "Lessons are logged in `retrospectives.md` as a rolling log (last 10-15 entries)" — the ICON-0014 retro entry is on the unmerged branch and has not been incorporated into `main`'s `retrospectives.md`.

- **Location:** `agents/manager.agent.md` (no step 0); `skills/task-plan-phase-completion/SKILL.md` (no reconcile reference); `.context/META.md:55`; branch `feature/ICON-0014-plan-md-freshness-gate` (commits `52c9178`, `d4a635a`)
- **Risk:** The gate was designed to prevent a class of retro-corruption bugs (stale plan misleads reviewer and retrospective). Without the merge, the gate is not enforced. Moderate workflow risk if the branch continues to sit unmerged while new tasks close.

**m-4 (carry-forward) · `format-slack.sh` runs without `set -euo pipefail`**

`.claude/skills/release-plugin/scripts/format-slack.sh:1-21` has no `set -euo pipefail`. The script is a sed pipeline invoked via `bash format-slack.sh` and handles user-visible release notes. A silent mid-pipe failure would produce a malformed Slack payload with no error signal.

- **Location:** `.claude/skills/release-plugin/scripts/format-slack.sh:1` (missing strict-mode header)
- **Risk:** Silent failure on malformed input. Carry-forward from ICON-0003 m-4.

**m-7 (carry-forward) · release-plugin SKILL.md Step 1 has no git-repo guard before `git --no-pager branch --show-current`**

`release-plugin/SKILL.md:31` runs `git --no-pager branch --show-current` as the first command. If invoked outside a git repository (an agent running in a detached context or wrong directory), this command fails with a non-obvious error. A one-line `git rev-parse --is-inside-work-tree > /dev/null 2>&1 || { echo "error: not a git repository"; exit 1; }` or `git rev-parse --show-toplevel` guard would make the failure explicit.

- **Location:** `.claude/skills/release-plugin/SKILL.md:31`
- **Risk:** Cosmetic; the skill is maintainer-only. Carry-forward from ICON-0003 m-7.

**m-1 (carry-forward) · Both manifests lack `$schema` declarations**

`.claude-plugin/plugin.json:1-18` and `.mcp.json:1-151` have no `$schema` key. No published JSON schema URL for either format has been identified, but declaring `$schema` (even as a placeholder or internal URL) enables IDE validation and signals where the format authority lives. Carry-forward from ICON-0003 m-1.

- **Location:** `.claude-plugin/plugin.json:1`; `.mcp.json:1`
- **Risk:** Cosmetic. No operational impact.

---

## Improvement Opportunities

**O-I1 · Sweep README and `.claude/claude.md` when ICON-0011/0012 are released**

Effort: trivial. Impact: high (closes M-N1, M-N2, m-n1).

The three stale surfaces (README `Default Role` section, `.claude/claude.md` tech stack line, and `enable/disable-manager-default.md` version-anticipation language) should be swept in the same commit that bumps the version for ICON-0011/0012. The release-plugin skill's Step 5 (CHANGELOG entry) creates a natural review moment; adding a "sweep doc surfaces for hook-architecture drift" reminder to Step 5 guidance would make this systematic rather than relying on author recall.

**O-I2 · Add a `LICENSE` file to match the `"license": "MIT"` manifest claim**

Effort: trivial. Impact: low-medium.

The standard MIT license text is four sentences. Adding `LICENSE` at the repo root closes the m-n2 gap, makes the declaration legally enforceable, and prevents any future marketplace or registry from treating the license claim as unverifiable. Alternatively, if the intent is a private internal plugin with no open-source license, remove the `license` field from `.claude-plugin/plugin.json:9`.

**O-I3 · Update `context_template/README.md` structure diagram to include `iconrc.json` and `.gitignore`**

Effort: trivial. Impact: low.

Consumers following the manual setup path (`cp -r context_template/context /path/to/your-project/.context`) see the diagram at `context_template/README.md:27-38` but the two config files (`iconrc.json` and `.gitignore`) are not listed. Three lines added to the diagram closes m-n3 and prevents "what is this file" confusion on first install.

**O-I4 · Add a `set -euo pipefail` header to `format-slack.sh`**

Effort: trivial. Impact: low.

One line added after the shebang. Closes m-4 (third carry-forward cycle). The script is already functionally correct; strict mode prevents a silent-failure class that would produce a malformed JSON payload sent to the Slack webhook.

**O-I5 · Add a dry-run mode to `bump-versions.sh`**

Effort: low. Impact: medium.

Common Check Pattern 4 (operational defensiveness on write-side scripts). A `--dry-run` flag that prints what would change without writing closes the "did I compute the right version?" verification gap. Six additional lines. Pairs naturally with O-M3 from ICON-0003 (monotonicity check). Closes O-M3 from the prior audit's Tier 5 list.

**O-I6 · Merge ICON-0014 promptly; add a cross-surface sweep reminder to phase-completion skill**

Effort: low. Impact: medium.

The ICON-0014 branch has been open since before this audit. The "reconcile plan.md" gate it introduces is the highest-leverage completion-quality mechanism added since M-A2 common-constraints. Every day the branch sits unmerged is a day the gate is not enforced. Once merged, the `task-plan-phase-completion/SKILL.md` should reference `.context/workflows/task-plan/phase-completion.md § Reconcile plan.md` (the local SSOT) so installs that don't have the local override still get a pointer to the reconcile step.

**O-I7 · Document the "unreleased code on main" pattern in the release-plugin skill or branching guide**

Effort: low. Impact: medium.

ICON-0011 and ICON-0012 introduced a pattern where code lands on `main` ahead of a version bump (the `[Unreleased]` CHANGELOG block accumulates). This is operationally intentional (batch releases) but creates drift windows where `README.md` and `.claude/claude.md` describe the last-released behavior, not the current-main behavior. The release-plugin SKILL.md Step 1 currently says "Verify you are on main and the working tree is clean" but does not prompt the maintainer to check for doc-drift introduced since the last tag. A one-bullet "sweep user-facing docs for behavioral drift vs. current-main" reminder in Step 1 would catch M-N1 / M-N2 class findings at release time.

---

## Infrastructure-Specific Structural Observations

### Discovery-pass findings out of scope

`context_template/README.md` was found by the pre-check discovery (`find . -maxdepth 2 -name 'README.md'`). It is a consumer-facing template readme, not a plugin-infrastructure file, and is not in the Inputs list. It is documented here (m-n3) because the structure diagram drift is observable and trivially fixable; it is not audited against all common check patterns as a top-level infrastructure file.

No `.github/plugin/plugin.json`, `plugin.json` at repo root, `.gitlab-ci.yml`, or `-beta`/`-dev`/`-staging` sibling repos were found. These are correctly absent in the standalone-repo layout.

### Hook architecture: from two scripts to one Node wrapper

ICON-0012 completed the architectural shift that ICON-0003 m-3 anticipated as a clean closure path. The bash/pwsh parity concern is gone by design — there is now one execution surface (`hooks/inject-manager-role.mjs`), one opt-out mechanism (`~/.claude/icon-user-settings.json`), and one wiring point (`hooks/hooks.json`). The plugin-scoped hook also eliminates the `${CLAUDE_PLUGIN_ROOT} is not associated with a plugin` error that prior retros flagged.

The remaining documentation drift (M-N1, M-N2) is a predictable cost of the "code lands on main ahead of version bump" pattern; it is not a sign of incomplete implementation.

### ICON-0014 merge gap

The ICON-0014 branch was in-flight when this audit began (the current session branch, `feature/ICON-0015-plugin-audit`, is branched from main at commit `39aca7f`, which predates the ICON-0014 commits). The brief asks to verify ICON-0014's gate is documented; the correct answer is "documented on the feature branch, not yet on main." This is a workflow gap (m-n4), not a documentation gap — the work exists; it hasn't shipped.

### "Unreleased on main" as a recurring pattern

This is the second time (post-MKT-0091 era) where multiple features have accumulated in `[Unreleased]` on `main` without a corresponding version bump. The pattern is operationally valid (batch releases reduce release overhead) but creates a predictable documentation-drift window. The prior audit flagged a single case (M-1 CHANGELOG shape conflict). This audit finds two moderate doc-drift cases (M-N1, M-N2) and one version-anticipation inconsistency (m-n1) from the same root cause.

### `format-slack.sh` strict mode (m-4): third carry-forward cycle

This finding has appeared in every infrastructure audit since MKT-0087. The script is maintainer-only and the immediate risk is low, but the pattern of deferral is worth naming: if it carries a fourth time, the appropriate action is to accept it as known-tolerable and remove it from future audit pass lists, not to re-surface it again as a Minor finding.

---

## ICON-0003 Delta

### Fixed since ICON-0003

- **M-1 (Release-flow CHANGELOG-shape doc conflict).** `release-plugin/SKILL.md:104-125` (Step 5) now correctly describes the "rename `[Unreleased]` to `[X.Y.Z]`" procedure and the "insert fresh empty `[Unreleased]` above" step, matching `workflows/changelog.md:11` and the shipped CHANGELOG shape. Fixed by ICON-0010.

- **M-2 (Error Conditions row referenced `sed`).** `release-plugin/SKILL.md:263` (Error Conditions) now reads: "Stop. Check the `bump-versions.sh` exit code; run `git diff .claude-plugin/plugin.json` to see what (if anything) was changed." The `sed`-direct-action reference is gone. Fixed by ICON-0010.

- **m-2 (`inject-manager-role.ps1` mode 644).** The `.ps1` file no longer exists. Fixed by ICON-0012 (deleted).

- **m-3 (inject-manager-role bash/pwsh parity test missing).** Parity concern eliminated by consolidation into a single `.mjs` wrapper. Fixed by ICON-0012.

### Still present or partial

- **m-1 (`$schema` missing from both manifests).** `.claude-plugin/plugin.json:1` and `.mcp.json:1` still lack `$schema`. Unchanged.

- **m-4 (`format-slack.sh` no `set -euo pipefail`).** `.claude/skills/release-plugin/scripts/format-slack.sh:1` still has no strict-mode header. Unchanged. Third carry-forward cycle.

- **m-7 (release-plugin SKILL.md no git-repo guard).** `release-plugin/SKILL.md:31` still calls `git --no-pager branch --show-current` without a prior git-repo check. Unchanged.

### Net-new (ICON-0015 cycle)

1. **M-N1** — README `Default Role` section (`:100,:110`) describes pre-ICON-0012 hook architecture (`~/.claude/settings.json` wiring) while shipped code uses `hooks/hooks.json` + `icon-user-settings.json`. Result of ICON-0012 landing on main without a README sweep.

2. **M-N2** — `.claude/claude.md:9` tech-stack line describes "two `hooks/inject-manager-role.*` scripts" (Bash + PowerShell); `.mjs` wrapper is the only hook file post-ICON-0012. Result of the same documentation sweep gap.

3. **m-n1** — `commands/enable-manager-default.md:7` and `commands/disable-manager-default.md:7` say "Starting with ICON 1.16" for behavior already deployed on main at `1.15.4`. Resolves at next version bump.

4. **m-n2** — `.claude-plugin/plugin.json:9` declares `"license": "MIT"` but no `LICENSE` file exists at the repo root.

5. **m-n3** — `context_template/README.md:27-38` structure diagram omits `iconrc.json` and `.gitignore`, both of which exist in `context_template/context/`.

6. **m-n4** — ICON-0014 (plan.md freshness gate) is on an unmerged branch (`feature/ICON-0014-plan-md-freshness-gate`). The gate's step 0 addition to `manager.agent.md`, the § Reconcile plan.md section in `.context/workflows/task-plan/phase-completion.md`, and the retro entry are all absent from `main`.
