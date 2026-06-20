## Task: ICON-0075
## Branch: feature/ICON-0075-security-ci-pipeline
## Objective: Apply a security CI stage (secret-scan, SAST, shellcheck) to ICON's own repo, extend `.githooks/pre-commit` with a secret-scan + shellcheck gate, and document a periodic MCP-package CVE-review cadence. Closes #42 (RFC security review Q7 + Q8).

## Folder: .context/tasks/ICON-0075-security-ci-pipeline/

## Decisions
- **CI on ICON is now allowed** (user, 2026-06-18): ADR-005's "no CI" was descriptive of the original setup, not a future rule. Constraint: jobs must be supported by the team's infrastructure.
- **Infra = tagged project runner**: all CI jobs MUST carry `tags: [devqa-common-saas]` (the project's Docker-executor runner; NOT shared runners — David's container pipeline uses this same tag). This is the user's "infra support" requirement.
- **Coexist with David's MR !38** (user decision: "add security CI to main now; David integrates"): main has no `.gitlab-ci.yml` yet; !38 (`dw/copilot-containers`, container builds, tag-gated) adds one but is unmerged/stale. We add the root `.gitlab-ci.yml` with security stages now; David folds his `build` stage in when he rebases !38. Keep our file clean/minimal-surface to ease that merge.
- **Tooling = custom jobs, explicit image + tag** (most reliable on a tagged-project-runner setup; avoids GitLab-template tag-override fragility; no shared-runner dependency): gitleaks (secret-scan), semgrep (SAST over the JS hooks + scripts), shellcheck. No authoritative ICON consumer recommendation exists to mirror (ci-cd.md is a generic placeholder; prior art was GitLab built-in `secret_detection`). Architect confirms final tool/image choice + pinned image tags.
- **Scans run on MRs + branch pushes** (`rules: merge_request_event` + `$CI_COMMIT_BRANCH`), NOT tag-gated like David's container builds — security must gate every change.
- **dep-scan → MCP CVE-review cadence**: no `package.json`/lockfile (ADR-005), so GitLab Dependency Scanning has no manifest. The two pinned MCP packages (`@zereight/mcp-gitlab@2.0.36` via npx, `mcp-atlassian@0.21.1` via uvx) are the only "dependencies" — covered by a documented periodic CVE-review cadence in security.md, not a scanner job.
- **pre-commit additions** reuse the EXACT 7 credential patterns from `hooks/guardrail-pretooluse.mjs` (ICON-0073) as bash ERE, for consistency. shellcheck step degrades gracefully if shellcheck is absent (prints notice, does not block — CI is the authoritative shellcheck gate; shellcheck is NOT installed locally).
- **No `context_template/` change** → no template-version bump. The consumer `ci-cd.md` template is intentionally left out of scope (this task applies CI to ICON itself; improving consumer recommendations is separate).

## Key Files
- `.gitlab-ci.yml`: CREATE (root) — security stages (secret-scan, sast, shellcheck), all `tags: [devqa-common-saas]`, custom images, run on MR + branch. Triggers NO existing pre-commit gate.
- `.githooks/pre-commit`: CHANGE — add (1) a `secret-scan` block before final `exit 0` scanning staged ACMR files for the 7 real-token patterns (`[pre-commit] error:` + exit 1 on match); (2) a `shellcheck` block gated by a new `shellcheck_needed` flag set in the staged-file classification loop (lines ~487-556) when a `.sh`/hook file is staged, with `command -v shellcheck || { notice; skip }` graceful path. Match the existing accumulate-then-report + error-format conventions.
- `.context/standards/security.md`: CHANGE — append `## MCP Package CVE-Review Cadence` (the two pinned packages, where versions live (`.mcp.json`), the review cadence + what to check). Triggers the rules-index freshness check.
- `.context/rules-index.md`: CHANGE — extend the `security` row "applies when" to mention MCP-version CVE review.
- `CHANGELOG.md`: CHANGE — `[Unreleased]` entry.

## Progress
- [x] Create branch + task folder + initial plan.md
- [x] Read-only Explore — CI recommendation (none authoritative), pre-commit structure, .mcp.json pins, security.md headings, secret patterns to reuse, shellcheck scope (findings in Decisions)
- [x] @architect exact-edit-spec — gitleaks/semgrep/shellcheck custom jobs (tagged devqa-common-saas, pinned images), pre-commit secret-scan + shellcheck blocks, security.md cadence; empirically pre-verified no secret-scan false positives; resolved busybox/mapfile (use xargs)
- [x] @coder applies edits — 5 files; caught + fixed a spec bug (`grep -Eq "$re"` parsed the PEM `-----` as options → `grep -Eq -e "$re"`); local verifications pass (secret-scan blocks fake token, no FP on guardrail/security.md, shellcheck graceful skip)
- [x] @reviewer checkpoint — APPROVE, 0 Critical/Moderate; independently re-ran all pre-commit verifications + YAML validation + pattern-parity. One Minor applied (uvx `==` vs `@` separator in security.md); `--verbose` nit left as benign.
- [x] changelog-entry — done by coder (### Added, ICON-0075)
- [x] Reconcile plan.md
- [x] Retrospective (two-stage) — entry inserted (ICON-0065 pruned → archived); promoted the grep leading-dash / `if grep` fail-open gotcha to `standards/shell-portability.md` (Rule 4)
- [x] Commit + push + open MR — committed (dogfooded the new pre-commit gates: shellcheck-skip notice + secret-scan no-FP); MR !59 opened
- [x] FIRST LIVE PIPELINE (MR !59): `secret-scan` (gitleaks) + `sast` (semgrep) PASSED on the `devqa-common-saas` runner — images pulled, semgrep registry reachable → the "infra support" risk is RESOLVED positively. `shellcheck` FAILED on pre-existing low-severity findings in `.githooks/pre-commit` (3× SC2001 style, 1× SC2295 info; all 10 `.sh` clean). Fixed by adopting `--severity=warning` (gate on warning+error; style/info advisory) in both the CI job and the pre-commit block — standard shellcheck CI policy, avoids contorting readable `sed` or cluttering the hook with disable-comments.
- [x] Re-push severity fix; pipeline GREEN — MR !59 pipeline 2612459374 PASSED (all 3 security jobs: secret-scan, sast, shellcheck) in 31s on devqa-common-saas. Full end-to-end validation on real infra.
- [ ] PAUSE — awaiting user go-ahead to merge !59 → delete branch → next item (#43)
- [ ] PAUSE — await user go-ahead to merge → delete branch → next item (#43)

## Review Checkpoint
@reviewer APPROVED the full diff (`.gitlab-ci.yml`, `.githooks/pre-commit` secret-scan + shellcheck blocks, security.md cadence, rules-index row, CHANGELOG) with 0 Critical/Moderate — independently re-ran every pre-commit verification in an isolated worktree (fake-token blocks; no false positive on the guardrail .mjs / security.md; shellcheck graceful skip; all 7 patterns match incl. the PEM `-e` fix; `set -e` safety), validated the YAML + `workflow.rules` (one pipeline per change) + every job tagged `devqa-common-saas`, and confirmed pattern parity with the ICON-0073 guardrail. The only post-checkpoint edit was the reviewer-flagged Minor (uvx separator wording) — pure doc text — so this checkpoint covers the complete changed-file set. Residual (not a code defect): pinned image tags + the runner's Docker-Hub/semgrep-registry egress can only be confirmed on the first MR pipeline run — flagged in the MR.

## Open Questions / Blockers
- Cannot run GitLab CI locally — `.gitlab-ci.yml` is validated by YAML/structure + correct tag/image use; the real run happens on push (visible in the MR pipeline). The pre-commit secret-scan IS testable locally; the shellcheck pre-commit path is only testable on the not-installed branch (shellcheck absent here).
- David (MR !38) owns the eventual unified `.gitlab-ci.yml`; he integrates the `build` stage on rebase. Flag in the MR.

## Constraints
- ICON is pure-content (no compile/test/package manager) — ADR-005, now amended in spirit (CI allowed where infra supports it). Verification = YAML validity + local pre-commit test + grep.
- `.claude-plugin/plugin.json` is the plugin version SSOT (ADR-003) — do NOT bump here.
- All CI jobs MUST be tagged `devqa-common-saas` or they will not run on the project's runner.
