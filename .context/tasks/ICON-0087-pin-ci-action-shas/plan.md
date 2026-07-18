## Task: ICON-0087
## Branch: feature/ICON-0087-pin-ci-action-shas
## Objective: Fix the failing `security` CI (semgrep SAST) by pinning GitHub Actions to full commit SHAs instead of mutable tags. The `github-actions-mutable-action-tag` rule blocks (3 findings): `.github/workflows/security.yml` uses `actions/checkout@v4` (mutable) at lines 20/31/43. Pre-existing failure (not caused by ICON-0081–0086); makes `main` + every PR go green.
## Folder: .context/tasks/ICON-0087-pin-ci-action-shas/

## Decisions
- Pin `actions/checkout@v4` → its resolved 40-char commit SHA (GitHub's run resolved `@v4` → `34e114876b0b11c390a56381ad16ebd13914f8d5`); keep a `# v4` comment for readability/auditability. Behavior-identical to current CI.
- Only file with mutable `uses:` refs is `security.yml` (3× checkout; other tools run via container/`run:`). Confirm no other workflow/`uses:` needs pinning.
- Simple/mechanical CI-security fix; no design pass.

## Key Files
- `.github/workflows/security.yml` — 3× `actions/checkout@v4` → pinned SHA (lines 20/31/43).

## Progress
- [x] Diagnosed CI failure: semgrep `github-actions-mutable-action-tag`, 3× `actions/checkout@v4` in security.yml. Branch off main.
- [x] Create branch + plan.md
- [x] @coder (Sonnet): verified via `gh api` that `actions/checkout@v4` = commit `34e114876b0b11c390a56381ad16ebd13914f8d5` (lightweight tag, type commit, no deref; matches CI-run resolution). Pinned all 3 refs → `actions/checkout@34e1148… # v4`. Completeness grep: zero remaining mutable `uses:` (only security.yml, only 3 checkouts). YAML valid.
- [x] @reviewer (Haiku) → **APPROVED**: SHA authentic (independently re-verified via gh api, type commit), all 3 pinned, nothing else changed, YAML valid, no remaining mutable refs. Clears the semgrep `github-actions-mutable-action-tag` finding.
- [x] Reconcile plan (this pass — checkpoint below).
- [ ] Brief retrospective + promote "pin CI actions to SHAs" to secure-coding → commit → PR → confirm CI semgrep passes ← IN PROGRESS

## Review Checkpoint
Stamped 2026-07-18. @reviewer (code-quality, Haiku) covered the full ICON-0087 diff. Verdict: **APPROVED.** SHA `34e114876b0b11c390a56381ad16ebd13914f8d5` independently verified via `gh api` as the `actions/checkout` v4 commit; all 3 `actions/checkout@v4` refs (security.yml:20/31/43) pinned to it with `# v4`; no job-logic/trigger/step changes; zero remaining mutable `uses:` repo-wide; YAML valid. Definitive verification is the CI re-run (semgrep `sast` job must go from fail→pass) — confirmed post-push. Release guard intact (no plugin.json); no CHANGELOG (CI infra, not consumer-shipped).

## Final Changed-File Set (ICON-0087)
**Modified (1):** `.github/workflows/security.yml` (3 action `uses:` refs pinned). (+ task folder + retro.)
**Untouched (guards):** `.claude-plugin/plugin.json` (no release); CI job logic/triggers.

## Open Questions / Blockers
- Confirm the pinned SHA genuinely corresponds to `actions/checkout` v4 (verify via `gh api`, not a blind copy of the run log).
- Any OTHER `.github/workflows/*.yml` (or the same file) with a mutable `uses:` semgrep would still flag? (grep found only the 3 checkouts.)

## Constraints
- Pure-content/config (ADR-005). Release guard: no `plugin.json` bump / no release. Maintainer/CI infra — no CHANGELOG (not consumer-shipped).
- Do NOT change CI LOGIC (the security jobs, triggers) — only pin the action refs.
- `.githooks/pre-commit` gates run on commit (this touches `.github/`, not `.context/`/`context_template/` — no context-graph/iconrc impact; shellcheck N/A to YAML).
