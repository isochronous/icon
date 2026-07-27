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
- **Phase 2 applies nothing — the audit's recommendation, accepted by the user.** The premise `upgrade-repo` encodes ("differs from template ⇒ behind template") is false for ICON in *both* directions, and false for any mature consumer repo. Concretely: 5 of 6 task-plan templates are installed **ahead** of the template, and template `phase-completion.md` 1.9 is **not a superset** of the installed 1.7 — applying it would delete the `## Update CHANGELOG [Unreleased]` section, the SHA/PR two-commit rule, the excludes-aware checklist, and the ICON-0088 attribution, while substituting a `**Tests:** [N added]` field into a repo with no test runner (ADR-005). `prune-context.sh`'s `^main$` is not drift either — it implements ADR-002.
- **The `iconrc.json` 1.2 → 1.12 bump is actively wrong as a bare field write**, on three independent grounds: the field sets are byte-identical across those ten versions (zero schema delta); the field is a *template-tree content counter*, bumped by the pre-commit invariant for any `context_template/` change (1.11 was a terseness pass, 1.9 the `## Related` seam), not a schema version despite the skill calling it one; and `.context/iconrc.json` has exactly one commit ever, at which point the template already read 1.7 — so 1.2 and 1.12 were never on the same track and the arithmetic describes no real upgrade path. Writing 1.12 would assert conformance ICON does not have, and `icon-status` surfaces that number to users.
- **Hook file-mode fix taken in-task rather than deferred.** Found incidentally by the audit, verified independently. It is not a `.context/` inaccuracy so the ICON-0088 P0 rule does not formally bind, but the severity does: combined with ICON-0089's finding that none of the ten pre-commit invariants have a CI backstop, a macOS or Linux contributor currently has **zero** enforcement — no local gates, none in CI. One-command fix, no reason to queue it.
- **Root `claude.md` redirect deliberately NOT created** (Phase 4 check 6, the single non-passing check). The redirect exists so Copilot CLI users of a *consumer* repo reach `.claude/claude.md`; ICON's root already carries `README.md`, `CONTRIBUTING.md`, and `CHEATSHEET.md` as its public face, and its own contributors run Claude Code, which loads `.claude/CLAUDE.md` directly. Adding a stub to the repo that *defines* the convention should be a deliberate maintainer decision about Copilot parity, not a side effect of an upgrade run. **Open for the user.** Related defect worth noting: the skill's redirect block is an unguarded `cat >` with no confirmation gate, so Phase 0 can mutate the working tree *before* the Phase 1 audit the user is meant to approve (audit defect D7).
- **Phase 3 scoped to bounded writes only.** The sample check plus the known `## Related` seam gap may be fixed; any broader drift is reported, not rewritten. Rationale: the skill's own motto is "audit first, act second," and an unbounded `.context/` rewrite pass is not what a no-op upgrade should turn into.

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
- [x] Phase 0 + Phase 1 — audit complete, stopped at the confirmation gate with zero writes beyond the report itself. Committed `37861b2`.
- [x] User go/no-go — **decision: apply no template deltas; fix the hook file mode; additionally run the Phase 3 content check.**
- [x] **Phase 2 — deliberately empty. No template delta applied.** See Decisions for the reasoning; this is the audit's recommendation, accepted.
- [x] Hook file-mode fix — `.githooks/pre-commit` and `post-commit` were `100644` in the git index with `core.fileMode=false`, so a fresh macOS/Linux clone got them non-executable and **silently ran no hooks at all**. `git update-index --chmod=+x` → both now `100755`. Verified before and after.
- [x] Phase 3a — content-currency sample check: **5 of 5 resolved, no trigger.** Selection method stated and reproducible (every 10th distinct reference across all 4 `domains/*.md` in alphabetical order, from position 3). Drift inventory correctly skipped — a clean result, not a manufactured one.
- [x] Phase 3b — **`## Related` seam closed**: footers added to 19 previously-footerless content docs + 1 wrong-heading fix (`github-access.md`: `## Related Skills` → `## Related`). `context-graph.sh --check` green afterward: 49 nodes, no dangling references, no orphans.
- [x] Phase 4 — verification: **8 of 9 checks pass**; check 6 (root `claude.md` redirect) intentionally not satisfied, see Decisions.
- [ ] @reviewer over the full task diff ← IN PROGRESS
- [ ] Commit, retrospective, CHANGELOG decision, PR

## Open Questions / Blockers
- **Does ICON count as a consumer of its own template?** Several template deltas may be inapplicable or actively wrong for the repo that *defines* the template. Each such case is a decision for the audit report, not an automatic apply.
- Whether the `iconrc.json` 1.2 → 1.12 bump should be a bare version-field write or should carry the accumulated schema changes those ten versions represent. The skill only rewrites the field; whether that is sufficient for a repo this far behind is a genuine question the audit must answer.

## Constraints
- ICON is pure-content (no compile/test/package manager) — ADR-005. Verification is the structural checkers plus `.githooks/pre-commit`.
- **Release guard**: no version bump to `.claude-plugin/plugin.json`, no `[Unreleased]` rename, no tag, no `latest` move.
- **`context_template/` is out of scope.** Editing it is a plugin change and would trip the pre-commit rule requiring a template-schema version bump. This task upgrades `.context/`, not the template.
- Do not act on any ICON-0089 audit finding beyond this one — the report's 62 dispositions are awaiting user triage, and implementing recommendations here would pre-empt that.
