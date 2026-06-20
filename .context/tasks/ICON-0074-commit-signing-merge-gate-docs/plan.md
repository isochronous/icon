## Task: ICON-0074
## Branch: feature/ICON-0074-commit-signing-merge-gate-docs
## Objective: Document cryptographic commit signing (GPG/SSH) as verifiable attribution complementing the forgeable `Co-authored-by` trailer, and document protected-branch + human-merge on `main` as a required setup prerequisite — in both ICON's own workflow docs and the consumer template scaffolds. Closes #41 (RFC security review Q6 + Q9).

## Folder: .context/tasks/ICON-0074-commit-signing-merge-gate-docs/

## Decisions
- **Docs-only; NO ICON-level enforcement gate** (per user scoping principle [[feedback_security_control_scoping]]): commit-signing enforcement and protected-branch rules are org/GitLab-side controls. ICON documents them as prerequisites and points to how to enable them; it does not add a pre-commit signing-nag (friction for no benefit — the platform is the enforcement layer). Acceptance ("enforced where the org supports it") is satisfied by documenting the org-side mechanism.
- **Two doc audiences, edited independently**: the live `.context/workflows/*` docs (ICON contributors + dogfooding) and the `context_template/context/workflows/*` scaffolds (new consumer repos) are intentionally DIVERGENT (ICON-specific vs generic), NOT mirrors — so each is edited on its own terms, not synced.
- **Template-version bump REQUIRED**: editing `context_template/context/workflows/branching.md` + `commit-conventions.md` trips the ADR-044 pre-commit gate → bump `context_template/context/iconrc.json` `version` 1.6 → 1.7 in the same commit. (Plugin version `.claude-plugin/plugin.json` 1.22.0 stays untouched — separate SSOT per ADR-003.)
- **Tier-agnostic GitLab phrasing**: GitLab can reject unsigned commits via a push rule (availability depends on plan/tier) and verifies signatures with a "Verified" badge on all tiers. Phrase the enforcement guidance without pinning exact tier names, so the doc stays accurate regardless of the consumer's GitLab edition. No research dependency.
- **Signing key type**: document BOTH GPG and SSH signing (SSH is simpler and increasingly common) — `git config commit.gpgsign true`, `gpg.format ssh` + `user.signingkey` for SSH.
- Extend existing `rules-index.md` trigger text for `branching`/`commit-conventions` rows (no new row — sections stay within their parent files).

## Key Files
- `.context/workflows/branching.md`: CHANGE — expand the existing `## Protected-Branch Rules` stub (lines ~123-128) into a setup-prerequisite checklist (protect `main`, require MR + ≥1 approval, no force-push, human performs the merge — agent never self-merges); add a peer `## Commit Signing` section.
- `.context/workflows/commit-conventions.md`: CHANGE — add a `## Commit Signing` subsection after `## Co-authorship trailer` (line ~131): forgeable trailer (provenance claim) vs signed commit (cryptographic proof); how to enable; what the server-side push rule enforces.
- `context_template/context/workflows/branching.md`: CHANGE — add protected-branch + signing prerequisite to the generic consumer scaffold (its `## Protected Branches` area).
- `context_template/context/workflows/commit-conventions.md`: CHANGE — add a signing note to the generic scaffold near its co-authorship section.
- `context_template/context/iconrc.json`: CHANGE — bump `version` 1.6 → 1.7 (ADR-044 gate; single field).
- `.context/rules-index.md`: CHANGE — extend "applies when" text for the `branching` and `commit-conventions` rows to mention signing/protected-branch prerequisites.
- `CONTRIBUTING.md`: CHANGE — add Requirements bullets: protected-branch config on `main`, and commit signing enabled (with pointer to branching.md).
- `CHANGELOG.md`: CHANGE — `[Unreleased]` entry.

## Progress
- [x] Create branch + task folder + initial plan.md
- [x] Read-only Explore — doc landscape, stub location, template divergence, template-version gate (findings in Decisions)
- [x] @coder applies edits — 8 files (branching.md, commit-conventions.md live + template, iconrc.json 1.6→1.7, rules-index, CONTRIBUTING, CHANGELOG); pre-commit template-gate passed (hook exit=0)
- [x] @reviewer checkpoint — APPROVE, 0 Critical/Moderate; git commands accurate, GitLab guidance tier-agnostic, no ICON leakage into generic template, gate passes, consistent with security.md. Two optional polish notes applied (SSH "Usage type" label; dropped a redundant sentence).
- [x] changelog-entry — done by coder (### Added, ICON-0074)
- [x] Reconcile plan.md
- [x] Retrospective (two-stage) — entry inserted (ICON-0064 pruned → archived, not destroyed); promoted the "intentionally divergent live-vs-template workflow docs" exception to `standards/skill-decomposition/process-doc-sweeps.md`
- [x] Commit + push + open MR — committed (pre-commit + template-version gate green); MR !58 opened (label security, remove_source_branch)
- [ ] PAUSE — awaiting user go-ahead to merge !58 → delete branch → next item (#42)

## Review Checkpoint
@reviewer APPROVED the full diff (live branching.md/commit-conventions.md, generic template scaffolds, iconrc.json version bump, rules-index, CONTRIBUTING, CHANGELOG) with 0 Critical/Moderate — independently re-ran the pre-commit template-version gate (exit 0), verified git/GitLab signing instructions are accurate + tier-agnostic, confirmed no ICON-specific text leaked into the generic consumer template, and checked consistency with the security.md server-side-enforcement note. The only post-checkpoint edits were the two reviewer-flagged optional polish items (pure doc wording), so this checkpoint covers the complete changed-file set.

## Open Questions / Blockers
- None. Tier-agnostic phrasing avoids a GitLab-edition research dependency.

## Constraints
- ICON is pure-content (no compile/test/package manager) — ADR-005. Verification = grep for the new sections + pre-commit hook green (esp. the template-version gate).
- `.claude-plugin/plugin.json` is the plugin version SSOT (ADR-003) — do NOT bump it here; only the template `iconrc.json` version moves.
- ADR-044 gate: any `context_template/` change requires the `context_template/context/iconrc.json` version bump in the same commit (pre-commit enforces).
