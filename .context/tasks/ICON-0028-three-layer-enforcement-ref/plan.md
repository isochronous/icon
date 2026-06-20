## Task: ICON-0028
## Branch: feature/ICON-0028-three-layer-enforcement-ref
## Objective: Close M-CC-NET3 (GitLab #13) — `agents/manager.agent.md:151` cross-references `.context/standards/three-layer-enforcement.md`, a file the plugin doesn't ship. Per the issue's recommended Option A, delete the `see ... three-layer-enforcement.md ...` clause; the surrounding instruction ("name all three layers and their exact file locations") is self-sufficient.
## Folder: .context/tasks/ICON-0028-three-layer-enforcement-ref/

## Decisions
- **Option A (delete the reference), not Option B (inline layer definitions).** Rationale: the issue body explicitly recommends Option A; the surrounding bullet's instruction is already actionable without the cross-reference, and the layer-cascade rule is encoded in the manager's own Behavior Tiers section.
- **Do NOT create `.context/standards/three-layer-enforcement.md` to satisfy the reference** — that would put plugin-shipped content into the repo-local `.context/` layer where consumer repos never see it (would not propagate via `latest`).

## Key Files
- `agents/manager.agent.md:151` — Scope Boundaries bullet inside the Delegation template. Remove the trailing "— see `.context/standards/three-layer-enforcement.md` for the layer definitions and delegation notes." clause. Resulting line: "Three-layer enforcement (if this change touches a rule enforced at all three layers): name all three layers and their exact file locations in the delegation prompt."
- `CHANGELOG.md` — `[Unreleased]` entry under `### Changed` per `changelog-entry` skill (this IS a shipped surface — `agents/manager.agent.md` changes affect every consumer).

## Progress
- [x] Branch + task folder created, plan.md drafted
- [x] @coder dispatched (Sonnet) — verbatim 1-line edit applied; 4 acceptance checks passed
- [x] @reviewer pass (Sonnet) — Approved, no findings
- [x] CHANGELOG.md `[Unreleased]` entry added under `### Fixed`
- [x] task-retrospective — manager drafted Q1+Q2; @context-specialist (mode:maintenance) inserted via script and staged-only (15/15 cap reached, no pruning). No `.context/` promotions
- [ ] Commit, push, open MR closing #13 ← IN PROGRESS

## Open Questions / Blockers
- None.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- common-constraints byte-equality in `agents/manager.agent.md` must remain unchanged (pre-commit hook enforces, ICON-0011/ICON-0013).
- Acceptance verifier: `grep -n "three-layer-enforcement.md" agents/` returns 0 hits after the fix.
