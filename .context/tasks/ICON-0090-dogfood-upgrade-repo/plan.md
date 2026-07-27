## Task: ICON-0090
## Branch: feature/ICON-0090-dogfood-upgrade-repo
## Objective: Run `/upgrade-repo` against ICON's own `.context/` — the first time the plugin has been made to execute its own consumer upgrade path. Closes the dogfooding gap ICON-0089 identified as the root cause of three consumer-facing Criticals, and treats the run itself as a live test of the skill under audit.
## Folder: .context/tasks/ICON-0090-dogfood-upgrade-repo/

## Phase State
- **Phase plan**: investigation → implementation → completion
- **Completed**: —
- **Current**: investigation   (status: in-progress)
- **Next**: implementation
- **Loaded skill**: task-plan-phase-investigation
- **Branch**: feature/ICON-0090-dogfood-upgrade-repo
- **Attempts (current phase)**: 1

## Decisions
- **Branched off `feature/ICON-0089-icon-audit`, not `main`.** PR #10 is open and unmerged, and both tasks write to `.context/`. Branching from `main` would drop the ICON-0089 `.context/domains` corrections and guarantee conflicts. The repo merges PRs with merge commits (not squash — see PR #7/#9 in `git log`), so this stacked branch rebases cleanly once #10 lands. **PR #10 should merge before this one.**
- **This run is deliberately a test, not just a maintenance chore.** ICON-0089 found five Criticals, three of them in the init/upgrade tree, and named this exact gap as why they survived four audit cycles: `/upgrade-repo` had never been run against ICON's own `.context/` (schema 1.2 against a 1.12 template). Anything the run gets wrong is therefore a finding, not just an obstacle — the specialist is instructed to record friction rather than silently work around it.
- **Phase 1 is a hard stop.** The skill mandates confirmation before touching any existing file. The specialist reports the audit and stops; the manager relays it to the user for the go/no-go. No writes without that confirmation.
- Model tier `complex` (Opus): the skill being executed has known live defects, the run requires judgment about which template deltas legitimately apply to ICON (which is the template's own source repo, not an ordinary consumer), and misapplying it corrupts the repo that defines the spec.

## Key Files
- `.context/iconrc.json` — schema **1.2**; template is **1.12**. The headline drift.
- `.context/workflows/task-plan/*.md` — 6 phase templates present; version markers to be compared against `context_template/`.
- `.context/workflows/` — also holds `changelog.md`, `task-start-conventions.md`, `prune-context.sh`, `commit-conventions.md`, `branching.md`.
- `.context/rules-index.md`, root `.gitattributes`, `.githooks/`, `core.hooksPath` — all already present/wired (pre-checked).
- `context_template/context/**` — the upgrade source. **Read-only for this task**: ICON is the template's source repo, so a template edit here is a plugin change, not a repo upgrade.

## Phase Handoff Log

*(appended at each phase boundary)*

## Progress
- [x] Pre-check: no `task-workflow-template.md` and no flat `decisions.md` in ICON's `.context/` — the two migration paths carrying ICON-0089's Critical C1 and the dead-code Moderate **do not trigger here**. `core.hooksPath=.githooks` already set; `task-plan/` already holds all 6 phase files.
- [ ] Phase 0 + Phase 1 — audit only, no writes; report and STOP for confirmation ← IN PROGRESS
- [ ] User go/no-go on the audit findings
- [ ] Phase 2 — apply confirmed infrastructure upgrades
- [ ] Phase 3 — content-currency sample check (5 names from `domains/*.md`); invoke `context-maintenance` only if ≥2 of 5 are absent
- [ ] Phase 4 — verify (9 checks) and commit
- [ ] Completion — retrospective, CHANGELOG decision, PR

## Open Questions / Blockers
- **Does ICON count as a consumer of its own template?** Several template deltas may be inapplicable or actively wrong for the repo that *defines* the template. Each such case is a decision for the audit report, not an automatic apply.
- Whether the `iconrc.json` 1.2 → 1.12 bump should be a bare version-field write or should carry the accumulated schema changes those ten versions represent. The skill only rewrites the field; whether that is sufficient for a repo this far behind is a genuine question the audit must answer.

## Constraints
- ICON is pure-content (no compile/test/package manager) — ADR-005. Verification is the structural checkers plus `.githooks/pre-commit`.
- **Release guard**: no version bump to `.claude-plugin/plugin.json`, no `[Unreleased]` rename, no tag, no `latest` move.
- **`context_template/` is out of scope.** Editing it is a plugin change and would trip the pre-commit rule requiring a template-schema version bump. This task upgrades `.context/`, not the template.
- Do not act on any ICON-0089 audit finding beyond this one — the report's 62 dispositions are awaiting user triage, and implementing recommendations here would pre-empt that.
