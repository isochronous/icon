## Task: ICON-0092
## Branch: feature/ICON-0092-remove-ecological-impact
## Objective: Remove the `ecological-impact` skill from the plugin, per maintainer triage of the ICON-0089 audit. Repairing it was the alternative; removal was chosen instead.
## Folder: .context/tasks/ICON-0092-remove-ecological-impact/

## Phase State
- **Phase plan**: implementation → completion
- **Completed**: —
- **Current**: implementation   (status: in-progress)
- **Next**: completion
- **Loaded skill**: task-plan-phase-implementation
- **Branch**: feature/ICON-0092-remove-ecological-impact
- **Attempts (current phase)**: 1

## Decisions
- **Removal rather than repair — maintainer's call at triage.** The ICON-0089 audit's finding M-U-1 was that `skills/ecological-impact/SKILL.md:210-227`'s worked example disagreed with its own formulas by **1000×**, was internally inconsistent on milliTrees, carried a ~6.6×-wrong car equivalent, and had a headline rate ~**57× its own cited source**. Four consecutive audits read that block without checking the arithmetic. Removal costs less than repair and eliminates a whole class of unverifiable numeric claims.
- **Branched off `feature/ICON-0091-amend-adr-005`, not `main`.** Both tasks add a bullet to the same `## [Unreleased]` CHANGELOG block; stacking avoids a near-certain conflict on adjacent lines. ICON-0091 must merge first. Rebase onto `main` after it lands.
- **`context_template/context/workflows/commit-conventions.md:37,102,125` deliberately NOT edited.** All three hits are the same historical commit-message *example* — `feat: add ecological-impact and start-worktree skills (1.5.0)` — illustrating the release-commit format. It is accurate history and remains a valid format example after the skill is gone. Editing `context_template/` would additionally force a template-schema version bump (`.githooks/pre-commit` enforces it), propagating a no-op change to every consumer running `/upgrade-repo`. Not worth it.
- **Historical records left intact**: `.context/retrospectives.md`, `.context/standards/skill-decomposition/verify-design-claims-against-artifacts.md`, and existing `CHANGELOG.md` entries mention the skill as past fact. Records describe what happened; they are not stale merely because the subject was later removed.

## Key Files
- `skills/ecological-impact/` — **delete** (`SKILL.md`, `formulas-reference.md`).
- `README.md:162` — remove the skills-table row. Load-bearing: `.githooks/pre-commit` O-V1 gate ties `skills/<name>/` to a README row.
- `CHEATSHEET.md:203` — remove the `/ecological-impact` row.
- `.claude/skills/icon-audit/briefs/04-utility-skills.md:5` — remove from the domain-04 investigation list so future audits don't hunt for a skill that no longer exists.
- `CHANGELOG.md` — one `### Removed` bullet under `## [Unreleased]`.
- `.claude-plugin/plugin.json` — verify whether it enumerates skills explicitly; update only if it does.

## Progress
- [x] Survey references — 7 files mention the skill outside its own directory; 3 need edits, 4 are correctly left alone
- [x] Deleted the skill (`git rm -r`, 2 files) and updated the 3 reference sites + CHANGELOG `### Removed` (sub-heading created; it did not exist)
- [x] Verified: `context-graph --check` green (49 nodes), `check-rules-index` green, manifest parses at 2.0.0 unchanged. `grep -ril ecological` returns only historical records, each justified. No command or agent routed to the skill; `.claude-plugin/plugin.json` does not enumerate skills, so it needed no edit.
- [x] Rebased onto `main` after ICON-0091 merged (PR #12, `d09e26f`) — clean, single commit, no CHANGELOG collision (`### Added` and `### Removed` are separate sub-headings)
- [x] @reviewer — **Approved**, no Critical or Moderate findings. Rebuilt the reference sweep independently (167 hits across 31 files) and classified every one; confirmed the registration gate's actual logic at `.githooks/pre-commit:704-735`; confirmed both Markdown tables remain well-formed with no adjacent row clipped.
- [x] Retrospective — lesson promoted to `.claude/skills/icon-audit/SKILL.md` Quality Checklist (an audit-time recompute requirement), judged a distinct axis from the two adjacent lessons: this is *undetectability* (never checked once across four audits), not correction-resistance or unverified-mechanism.
- [ ] PR ← IN PROGRESS

## Close-Gate Evidence

1. **@reviewer coverage** — Approved over the complete changed-file set (`3557ef8`). The retrospective commit that follows touches only `retrospectives.md`, `retrospectives-archive.md` (append-only records) and one maintainer-only skill, produced by @context-specialist under the reviewed maintenance path.
2. **Lint** — N/A, pure-content repo (ADR-005). Substitute: `.githooks/pre-commit` ran and passed on every commit.
3. **Tests** — N/A, no test runner (ADR-005). Behavioural verification instead: `context-graph --check` OK at 49 nodes; `check-rules-index` OK; manifest parses at 2.0.0 unchanged; `skills/ecological-impact/` confirmed absent; the only remaining live-file reference is the `context_template/` commit-message example deliberately retained as accurate history.
4. **verification-checklist** — passed; every claim carries command output.
5. **Commit conventions** — Pattern 1, lowercase imperative, no trailing period, single prefix, `Co-authored-by` trailer present.

**CHANGELOG**: one `### Removed` entry under `[Unreleased]` (sub-heading newly created), stating the consumer-visible effect. The retrospective's promotion target is `.claude/skills/`, which is repo-internal per `changelog-entry` Rule 4 and owes no entry. No version bump, `[Unreleased]` not renamed, `## [2.0.0]` intact below.

## Open Questions / Blockers
- **Consumer impact**: this removes a user-invocable skill. Anyone invoking `/ecological-impact` loses it at the next `latest` move. That is a user-facing removal and should be reflected in release-note tone whenever the next release is cut — **not** in this task (release guard).

## Constraints
- ICON is pure-content (ADR-005) — verification is the structural checkers plus `.githooks/pre-commit`.
- **Release guard**: no `.claude-plugin/plugin.json` version bump, no `[Unreleased]` rename, no tag, no `latest` move.
- `context_template/` untouched — see Decisions. No template-schema bump owed.
- Do not act on any other ICON-0089 finding; the remaining dispositions are with the maintainer.
