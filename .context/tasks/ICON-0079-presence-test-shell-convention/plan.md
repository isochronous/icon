## Task: ICON-0079
## Branch: feature/ICON-0079-presence-test-shell-convention
## Objective: Document the `${VAR+x}` presence-test vs `${VAR:-fallback}` shell convention in one canonical location, and trim the icon-init/icon-status inline descriptions (added in ICON-0071 m7) to cite it. Closes #46.

## Folder: .context/tasks/ICON-0079-presence-test-shell-convention/

## Decisions
- **Canonical home = `.context/standards/shell-portability.md`** (new Rule 5), NOT `shared/common-constraints.md`. Rationale: common-constraints is byte-synced into all 9 agents (always-loaded) and is already over its ADR-008 per-component cap — adding an authoring rule there multiplies ×9 for no always-loaded benefit (same reasoning as ICON-0072). The presence-test rule is a shell-AUTHORING gotcha that belongs with the other shell gotchas (esp. Rule 4, the `grep -e` rule) in the on-demand shell-portability standard. shell-portability already has a `rules-index.md` row, so adding a sub-rule needs no new index row (but editing `.context/standards/*` triggers the rules-index freshness check — it passes).
- **Cite by NAME, not path**: the icon-init/icon-status updates reference "the shell-portability standard" by name — NOT a literal `.context/standards/shell-portability.md` path (which would trip the dead-ref gate and violates the writing-skills by-name rule promoted in ICON-0076/0077). Keep the actual bash examples in those skills; trim only the duplicated EXPLANATORY prose to a brief note + the by-name citation.
- Rule 5 content: `${VAR+x}` is a POSIX presence test (expands to `x` iff VAR is set, even if empty; empty string if unset) — use it (e.g. `[ -z "${VAR+x}" ]` / `[ -n "${VAR+x}" ]`) when distinguishing "unset" from "set-but-empty" is load-bearing. `${VAR:-literal}` is a FALLBACK substitution, not a presence test — an empty-but-set variable silently defeats it. Ground with the icon-init/icon-status credential-presence-check precedent.

## Key Files
- `.context/standards/shell-portability.md`: CHANGE — add `### 5. …` presence-test rule (match Rules 1-4 format).
- `skills/icon-init/SKILL.md`: CHANGE — trim the line ~225 inline explanation to a brief note citing the shell-portability standard by name; keep the `${VAR+x}` bash.
- `skills/icon-status/SKILL.md`: CHANGE — trim the ~118-120 explanation + the ~214 rationalization-table row to cite the shell-portability standard by name; keep the bash + the table row's intent.
- `CHANGELOG.md`: CHANGE — `[Unreleased]` entry.

## Progress
- [x] Create branch + task folder + initial plan.md
- [x] Read-only survey — shell-portability Rules 1-4 + the icon-init/icon-status inline m7 descriptions located (findings in Decisions)
- [x] @coder applies edits — Rule 5 in shell-portability.md; trimmed icon-init/icon-status inline → by-name cite (bash intact); CHANGELOG; hook green
- [x] @reviewer checkpoint — APPROVE-WITH-COMMENTS, 0 Critical/Moderate; POSIX semantics verified exact (IEEE Std 1003.1). One Minor applied (icon-init `${VAR:-}` → `${VAR:-literal}` for consistency with icon-status); Nit (Rule 5 grounding example) left.
- [x] changelog-entry — done by coder (### Added, ICON-0079)
- [x] Reconcile plan.md
- [x] Retrospective (two-stage) — entry inserted (ICON-0069 pruned → archived); no promotion (clean application of established ADR-008-placement + by-name-cite rules)
- [x] Commit + push + open MR — MR !63 opened (label follow-up, remove_source_branch)
- [ ] PAUSE — awaiting user go-ahead to merge !63 → delete branch. FINAL item — #39-#46 backlog clear after this.

## Review Checkpoint
@reviewer APPROVED the diff (shell-portability Rule 5, icon-init/icon-status by-name cites, CHANGELOG), APPROVE-WITH-COMMENTS, 0 Critical/Moderate — verified the POSIX `${VAR+x}`/`${VAR:-}` semantics are exactly right, the home choice (on-demand shell-portability, not always-loaded common-constraints) is ADR-008-correct, citations are by-name (dead-ref-safe), and the bash examples are intact. The only post-checkpoint edit was the reviewer's Minor (`${VAR:-}`→`${VAR:-literal}` consistency) — covers the complete changed-file set.

## Open Questions / Blockers
- None.

## Constraints
- ICON pure-content (ADR-005); verify = grep + pre-commit green (rules-index freshness [shell-portability row exists], dead-ref [cite by name → no trip], O-V1 [skills already registered]). No `context_template/` change; no `.claude-plugin/plugin.json` bump.
