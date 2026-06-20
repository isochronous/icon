## Task: ICON-0067
## Branch: feature/ICON-0067-commit-mr-format-enforcement
## Objective: Sub-agents commit with the wrong commit-message format and the manager opens MRs with the wrong MR format, even though `icon-init` discovers and documents each repo's correct commit/MR conventions. Wire the discipline skills and agent definitions so the icon-init-discovered, repo-specific format is reliably loaded and applied at the point of commit / MR creation — closing the enforcement gap rather than restating format prose.
## Folder: .context/tasks/ICON-0067-commit-mr-format-enforcement/

## Decisions
- Root cause is enforcement, not spec (user-confirmed): the correct format IS discovered by `icon-init` and written to `.context/`. Agents ignore it at commit/MR time. → Fix targets the wiring/discoverability path (commit-discipline, mr-discipline, manager/coder agent defs), per the ICON-0057/0056 precedent that "the model ignores a rule ICON already states" is fixed by a hard, discoverable enforcement point — not more prose.

## Investigation Findings (Explore pass, complete)
- **Discovery SSOT:** `icon-init` → `@context-specialist` (impl-leaf Step 1a/Step 4) discovers commit & MR/branch convention from `git log`/`git branch -r` and writes them to `.context/workflows/commit-conventions.md` (commit format SSOT) and `.context/workflows/branching.md` (branch + MR workflow). These are agent-authored from git history, NOT template-copied; the `context_template/` equivalents are reference scaffolds only.
- **Commit gap = PARTIAL.** `skills/commit-discipline/SKILL.md:14-29` already correctly points at `.context/workflows/commit-conventions.md`. The fragility is at call sites: (a) `agents/context-specialist.agent.md:88` fallback is "delegation prompt → `git log`", which BYPASSES commit-conventions.md on maintenance/upgrade runs; (b) `agents/manager.agent.md:208` says "apply commit-discipline" without asserting the file-read prerequisite.
- **MR gap = NONE wired (true bug, highest value).** `skills/mr-discipline/SKILL.md:37` hardcodes `Jira Ticket ID: Brief description` with no pointer to the discovered convention. `agents/manager.agent.md:209` MR step likewise doesn't reference it.
- **Who commits:** manager owns task commits (`manager.agent.md:230`); sub-agents don't commit task work EXCEPT `@context-specialist` commits its own init/upgrade work (`context-specialist.agent.md:82`) — this is the "sub-agent commits with wrong format" the user reports.
- **Layering:** all three candidate fix sites (mr-discipline skill, manager agent, context-specialist agent) are single-layer (skills/ or agents/) — no `context_template/` sync needed. The `context_template/.../branching.md` MR template is a cosmetic scaffold, out of primary scope.

## Key Files (confirmed)
- `skills/mr-discipline/SKILL.md` (~line 37) — PRIMARY MR fix: wire title/format to discovered convention; generic format becomes the fallback-when-absent.
- `agents/context-specialist.agent.md` (line 88) — fix commit-convention fallback chain to consult `commit-conventions.md` before `git log`.
- `agents/manager.agent.md` (lines 208-209) — make the discovered-convention read an explicit prerequisite at the commit and MR steps.
- `skills/commit-discipline/SKILL.md` (lines 14-29) — already wired; likely no change, confirm during design.

## Progress
- [x] Set up branch, task folder, plan.md
- [x] Investigation (Explore pass) — gap pinpointed (see Findings above)
- [x] Update plan with findings and concrete fix scope
- [x] Design (@architect + agent-evaluation/icon-audit) — see design.md. Decisions: Gap A commit-discipline = NO CHANGE; Gap B context-specialist:88 = wired pointer; Gap C manager close-gate (210 + 233 tier copy) = hard gate fifth check; Gap D mr-discipline:37 = wired pointer to commit-conventions.md.
- [x] Implement four-site fix (@coder) per design.md — 3 files, net 0 added lines (like-for-like replacements); both manager close-gate copies byte-aligned; context_template + commit-discipline untouched. Diff verified by manager.
- [x] Review (@reviewer) — APPROVED, zero findings; two-copy sync confirmed byte-identical (grep -c = 2), no spec duplication, no scope creep, no stale "four" refs.
- [x] Changelog entry — `### Fixed` bullet added to `[Unreleased]` (ICON-0067), describing the wiring fix + effect.
- [x] Retrospective — Stage 1 (manager) drafted; Stage 2 (@context-specialist mode=maintenance) inserted entry via append-retrospective-entry.sh (pruned ICON-0057, lesson already in standards), promotion = retro-only (first firing of three-way mechanism matrix). retrospectives.md staged.
- [x] Commit all artifacts (`2e5db71`, `ICON-0067:` format — dogfoods the gate), push, open MR !51 — https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/merge_requests/51
- [x] Close-gate passed (see below)

## Close-Gate
- (1) @reviewer: covered the full changed-file set at the Review Checkpoint; no @coder/@tester step ran after → satisfied.
- (2) Lint: N/A — pure-content repo (ADR-005), no lint command. Substituting gate = pre-commit hook (fence/placeholder/template-version) ran on `2e5db71` and passed.
- (3) Tests: N/A by repo type — no test framework; verification is the 8 grep-checkable acceptance criteria (design.md), produced by @coder and independently re-run by @reviewer.
- (4) verification-checklist: passed (@coder 4 gates + @reviewer independent verification + manager diff spot-check).
- (5) [new gate, dogfooded] commit + MR title follow `ICON-NNNN:` per commit-conventions.md → satisfied.

## Review Checkpoint
- @reviewer (opus) reviewed the full changed-file set (`agents/context-specialist.agent.md`, `agents/manager.agent.md`, `skills/mr-discipline/SKILL.md`) at this state. Verdict: **Approved**, no critical/moderate/minor/nit findings. No @coder/@tester step ran after this checkpoint → close-gate review item satisfied; no re-review needed.

## Design Decisions (from design.md)
- Gap A — `skills/commit-discipline/SKILL.md`: NO CHANGE (already wires to commit-conventions.md correctly).
- Gap B — `agents/context-specialist.agent.md` commit-convention bullet: re-order fallback to read commit-conventions.md first, demote `git log` to absent-only.
- Gap C — `agents/manager.agent.md` close-gate: add 5th itemized check (commit + MR title match discovered convention); mirror in Hardcoded-tier restatement; update four→five count in both copies.
- Gap D — `skills/mr-discipline/SKILL.md` Title bullet: point at `.context/workflows/commit-conventions.md`, generic format demoted to absent-only fallback.
- Out of scope (do-NOT): no context_template edits, no new skill, no format-spec duplication, no non-committing agents.

## Open Questions / Blockers
- Design decision for @architect: does the MR gap warrant only a wired pointer (it's a genuine missing-pointer bug, unlike the commit side), while the commit-side fragility warrants a stronger mechanism? Weigh against ICON-0057 ("more prose has near-zero value for model-ignores-a-rule failures").

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- Three-layer enforcement: changes to a rule enforced in skill + `.context/` + `context_template/` must update all layers in sync.
- Fix should follow "earn your place" — prefer wiring/gate over added prose (ICON-0057).
