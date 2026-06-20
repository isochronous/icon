## Task: ICON-0044
## Branch: feature/ICON-0044-iconrc-version-bump-rule
## Objective: Enforce that any add/modify/delete under `context_template/` is accompanied by a version-field bump in `context_template/context/iconrc.json`. The iconrc `version` field is the gate that `/upgrade-repo` Phase 2 uses to decide whether to apply template updates to an installed consumer repo — without a bump, consumers running `/upgrade-repo` won't know template content changed and will skip the update. Enforce mechanically via `.githooks/pre-commit`; document discoverably via a `commit-discipline` Common Mistakes row + Red Flags bullet.

## Folder: .context/tasks/ICON-0044-iconrc-version-bump-rule/

## Decisions
- **Mechanical hook enforcement** in `.githooks/pre-commit` is the primary gate. Documentation alone (commit-discipline rule) is easy to forget — and missing the bump leaves consumers silently out-of-date with no error surface. Hook check matches the architectural pattern of ICON-0032's dead-ref resolver and ICON-0040's pre-commit-marker exemption: invariants that ship deserve mechanical enforcement.
- **Scope: ANY change under `context_template/`** — adds, modifies, deletes, renames. Anything that ships to consumers via `/icon-init` or `/upgrade-repo`. Per the issue narrative: "any time ANYTHING in context_template is added/modified/deleted."
- **Exception: when ONLY `context_template/context/iconrc.json` is staged** — that change IS the bump itself, no other template files were touched. The hook passes (it's the bump operation).
- **Bump means: the version field's value differs from HEAD**. Any change to the version string passes (`1.2` → `1.3`, `1.2` → `1.2.1`, etc.). The hook does NOT enforce a semver scheme — that's a discipline call for the maintainer, not a mechanical gate.
- **Error message lists the staged template files + current/HEAD version** so the maintainer knows exactly what's gated and what value to bump from. Hook prints to stderr; non-zero exit aborts the commit.
- **Bumping iconrc.json without any other template change is allowed** (e.g., maintainer wants to force a re-upgrade signal for an out-of-band reason). The hook only fires when other template files are staged.
- **Documentation in `commit-discipline`** is secondary — the hook is mechanical so this is "explain why" not "remind to do it." One Common Mistakes table row + one Red Flags bullet, matching the existing form.

## Key Files

### A. Hook (mechanical enforcement)
- `.githooks/pre-commit` — add a new invariant section after the existing dead-ref resolver. Detect staged files under `context_template/`, exit-early if no template changes, exit-early if only iconrc.json is staged, otherwise require iconrc.json to be staged AND its version field to differ from HEAD. Bash awk/grep with no extra dependencies. Inline the logic (matches the rest of the hook's style; no scripts/ split).
- Update the hook's header comment block to mention the new invariant (ICON-0044), matching how ICON-0032 + ICON-0040 invariants are listed.

### B. Documentation (discoverability)
- `skills/commit-discipline/SKILL.md` — add one Common Mistakes table row about staging `context_template/` changes without bumping iconrc, and one Red Flags bullet at the bottom of the file. Match the row form already used for the ICON-0042 jira-fabrication entry.

### C. Retroactive bump (scope addition mid-task per user direction)
- `context_template/context/iconrc.json` — `version` bumped from `1.2` → `1.3`. The 1.17.0 release shipped 9 template-file changes (decisions/-folder layout, phase-template tweaks, META + UPDATE_LOG + commit-conventions updates) but the iconrc bump was missed at release time, so consumers running `/upgrade-repo` against 1.17.0 silently skipped those updates. The bump in THIS task retroactively flags them — `/upgrade-repo` against the next release will apply the cumulative template content.
- This bump also serves as the first real-world use of the new hook's exemption path (Scenario B): a commit staging ONLY `iconrc.json` under `context_template/` is the bump itself and passes without requiring further template changes.

### D. CHANGELOG
- `CHANGELOG.md` `[Unreleased]` `### Fixed` entry — describes the retroactive bump and its consumer impact (the iconrc bump IS consumer-visible since it triggers `/upgrade-repo` to pick up template updates). Originally planned as "no CHANGELOG entry" because the hook + docs are repo-internal, but the scope addition (the bump itself) reintroduces a consumer-visible change.

### E. Bookkeeping
- `.context/tasks/ICON-0044-iconrc-version-bump-rule/plan.md` — this file.
- `.context/retrospectives.md` — appended at close.

## Progress
- [x] Branch + task folder + plan.md
- [x] Implement hook invariant — initial implementation + reviewer fixes (Moderate 1: deletion guard + `2>/dev/null`; Moderate 2: header invariant numbering reorganized to 1/2/3 execution order)
- [x] Smoke-test the hook against the 4 scenarios: (a) no template changes (pass), (b) only iconrc.json staged (pass), (c) template files staged + iconrc.json NOT staged (fail with clear message), (d) template files staged + iconrc.json staged with unchanged version (fail), (e) template files staged + iconrc.json staged with bumped version (pass)
- [x] Scope addition: retroactive `context_template/context/iconrc.json` bump from `1.2` → `1.3` (1.17.0 shipped 9 template changes with no iconrc bump; consumers running `/upgrade-repo` silently skipped them). Also exercises the hook's Scenario B exemption path.
- [ ] Update commit-discipline Common Mistakes + Red Flags — DECIDED SKIPPED: the gate is ICON-internal repo infrastructure (the hook is local-only, not shipped). Documenting it in `commit-discipline` (a consumer-shipped skill) would leak ICON architecture into a generic surface. Rule is documented instead in `.claude/claude.md` (repo-internal, ICON maintainer audience only).
- [x] CHANGELOG entry — originally planned as "no entry" (hook + docs are repo-internal), but revised: the retroactive iconrc bump from `1.2` → `1.3` IS consumer-visible (it triggers `/upgrade-repo` Phase 2 to apply the 9 previously-missed 1.17.0 template changes). A `### Fixed` entry was added to `CHANGELOG.md [Unreleased]`.
- [x] verification-checklist
- [x] @reviewer pass — reviewer findings addressed (Moderate 1, 2, 3; Minor 4/6 folded into those; Minor 5 explicitly deferred per plan)
- [ ] task-retrospective Stage 1 + Stage 2
- [ ] Commit, push, open MR, AWAIT user approval

## Open Questions / Blockers
- None. Scope is bounded; hook + 2-line doc change.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.githooks/pre-commit` is repo-local infrastructure (not shipped); changes do NOT propagate to consumer repos. The hook only protects ICON's own maintainers from forgetting the bump.
- Hook check must be bash-only (no Python/Node dependency); matches the existing hook's style.
- Hook must handle the initial-commit edge case (no HEAD version to compare against) — treat as "no prior version, bump considered satisfied."
