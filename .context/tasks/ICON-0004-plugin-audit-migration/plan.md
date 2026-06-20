# ICON-0004: plugin-audit migration to standalone-repo layout

**Status**: ready for review
**Branch**: `feature/ICON-0004-plugin-audit-migration`
**GitLab issue**: [#1 (M-U1)](https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/work_items/1)
**Source audit finding**: ICON-0003 audit-report, M-U1 (net-new since MKT-0087; concrete instance of M-CC1 sweep-incompleteness)

## Objective

Migrate the `plugin-audit` skill itself from the marketplace-monorepo layout (`plugins/<plugin>/...`) to the standalone-repo layout (paths relative to the repo root). Per the issue's acceptance criterion: a subsequent `/plugin-audit` run on this repo should produce non-zero Phase 1 baseline counts without requiring a plan-level translation table.

## Approach

Two-phase sweep across 8 files in `skills/plugin-audit/`:

### Phase 1 — Literal path substitution

`plugins/<plugin>/...` → repo-root path (drop the prefix). All 30+ occurrences fixed:

| File | Hits |
|---|---|
| `SKILL.md` | 5 |
| `briefs/01-agents.md` | 4 |
| `briefs/02-process-skills.md` | 2 |
| `briefs/03-context-specialist-init.md` | 3 |
| `briefs/04-utility-skills.md` | 2 |
| `briefs/05-infrastructure.md` | 18 |
| `briefs/06-cross-cutting.md` | 4 |
| `synthesis-template.md` | 0 (path) + 1 (`:343-345` line-coupling drop) |

Plus the Self-Application paragraph at `SKILL.md:104` was rewritten — the marketplace-monorepo auto-detection logic is retired.

### Phase 2 — Companion drift from the same standalone-repo move

The reviewer caught a deeper M-CC1 instance: even after path strings were fixed, the briefs still enumerated files that don't exist in this standalone repo. Phase 2 reconciled them:

| Finding | Fix |
|---|---|
| `release-plugin/SKILL.md` lives at `.claude/skills/release-plugin/SKILL.md`, not `skills/release-plugin/SKILL.md` | Path corrected |
| `release-plugin-beta` was collapsed during the split (per `CHANGELOG.md:47`) | Reference removed |
| `BEST_PRACTICES.md` / `GETTING_STARTED.md` were not carried over in the split | Removed from briefs 05 + 06; onboarding axis re-anchored on `README.md` |
| `.gitlab-ci.yml` doesn't exist in this repo | Annotated `(if present — repo currently has no CI config)` and CI/CD scope softened |
| `find` commands in SKILL.md and brief 05 were leaking `.git/hooks/*.sample` (16 spurious hits) | All `find` commands now have `-not -path './.git/*'` exclusion |
| `hooks/` (Claude Code session hooks) vs `.githooks/` (git hook directory) distinction was missing | Both listed with explicit clarification of the different mechanisms |
| `scripts/` listed as if it existed at repo root, but it doesn't | Replaced with `skills/*/scripts/` and `.claude/skills/release-plugin/scripts/` |
| Phase 1 baseline command emitted stderr noise (`.github` doesn't exist) | Replaced with defensive `find . -maxdepth 3 -name 'plugin.json' -type f -not -path './.context/*' -not -path './.git/*'` |
| Cross-reference to `MKT-0046 audit-report.md:343-345` carried a line-coupling that violates writing-skills standards | Dropped `:343-345`; qualified "(in the upstream marketplace repo)" |

## Key files

8 modified, all under `skills/plugin-audit/`:

- `SKILL.md`
- `synthesis-template.md`
- `briefs/01-agents.md` through `briefs/06-cross-cutting.md`

## Verification

```bash
# Acceptance gates (issue #1)
git grep "plugins/<plugin>" skills/plugin-audit/   # expected: 0
git grep "plugins/ICON" skills/plugin-audit/       # expected: 0
grep -nE "audit-report\.md:[0-9]+" skills/plugin-audit/synthesis-template.md   # expected: 0

# Phase 1 baseline smoke test runs cleanly without stderr noise
wc -l CHANGELOG.md
ls agents/ | wc -l
ls skills/ | wc -l
find . -maxdepth 3 -name 'plugin.json' -type f -not -path './.context/*' -not -path './.git/*'
# expected: 834 / 9 / 48 / .claude-plugin/plugin.json (one match)

# Non-existent enumerated files removed
grep -rn "BEST_PRACTICES\|GETTING_STARTED" skills/plugin-audit/briefs/   # expected: 0
grep -nE "skills/release-plugin/SKILL\.md|release-plugin-beta" \
  skills/plugin-audit/briefs/05-infrastructure.md   # expected: 0

# release-plugin path corrected
grep -n "\.claude/skills/release-plugin/SKILL\.md" \
  skills/plugin-audit/briefs/05-infrastructure.md   # expected: 1

# Defensive `find` commands
grep -cE "not -path './.git/" skills/plugin-audit/briefs/05-infrastructure.md   # expected: >= 4
```

## Done

- [x] @coder Phase 1 (literal substitution sweep across 8 files)
- [x] @reviewer flagged 3 Critical (stale file enumerations) + 4 Moderate (find paths, hooks distinction, scripts location, defensive find)
- [x] @coder Phase 2 polish — all Critical + Moderate addressed plus 2 minor polish items
- [ ] Commit + push + open MR
- [ ] User review/approval
- [ ] Merge to main
- [ ] Retrospective entry

## Notes

- This task was the most substantial of the 7 ICON-0003 audit follow-ups, and the most M-CC1-prone. Reviewer's catch of the deeper file-enumeration drift (beyond literal path strings) is the kind of sweep-completeness that the audit's M-CC1 pattern flags as recurring.
- The next `/plugin-audit` invocation on this repo should now succeed self-sufficiently: Phase 1 baseline commands produce real counts, brief input lists enumerate files that actually exist, and there is no need for a `plan.md` translation table.
- Beta-channel release flows were collapsed during the standalone-repo split. The `release-plugin` skill (singular) is now the only release surface; no `-beta` variant exists. This MR removes the stale enumeration.
- The systemic M-CC1 recurrence-vector closure (commit-time path-drift lint + cross-surface sweep rule) is referenced in the issue as separate ICON-0006-class lint-gate work; filed separately.
