## Task: ICON-0039
## Branch: feature/ICON-0039-template-generalization-retier
## Objective: Make the judgment-and-documentation pass that closes GitLab #24 (O-S3 + O-X2). Walk the per-phase deltas between this repo's `.context/workflows/task-plan/phase-*.md` files and the shipped `context_template/.../phase-*.md` base templates, promote only the generalizable parts, and re-tier the remaining 3+-cycle carry-forward Minors to "watch / accepted" with a written rationale. The audit cycle should have a clear basis to stop re-surfacing accepted items.
## Folder: .context/tasks/ICON-0039-template-generalization-retier/

## Decisions
- One ADR captures both sub-tasks: O-S3 promotion outcome and O-X2 re-tier decisions live in `.context/decisions/010-template-promotions-and-carryforward-retier.md`. Rationale: the GitLab issue explicitly bundles them ("one documentation artifact covering both"), and they share an audience (future audit-brief authors).
- Single promotion only: the 2-line "Append via the `append-retrospective-entry` script — do not edit retrospectives.md by hand" note in `phase-completion.md` (local lines 65–66) → inserted after `## Retrospective Template` heading in `context_template/.../phase-completion.md`, plus bumping `<!-- template-version: 1.3 -->` to `1.4`. Rationale (per architect pass): every other delta the explorer flagged as PROMOTE turned out to be either repo-specific phrasing (ICON-NNNN ticket shape, skill-decomposition standards refs) or already-generalized-in-base (plan.md reconcile-first is in the base already). Pushing those would un-generalize the base. The script-invocation note is the lone exception because the `append-retrospective-entry` script ships in the initializer payload.
- Re-tier recording location: both m1 and m9 land in `.context/decisions/010-…md` (option a — repo-local ADR). The durable ADR uses a `Disposition` column with concrete rationale, not the (a)/(b) labels from the GitLab issue. Rationale (per architect pass): both findings have ICON-repo-specific disposition rationale (ADR-007 scope for m1; ICON-0035 example-shape decision for m9); a plugin-wide `shared/` doc would add indirection without benefit. The (a)/(b) labels are issue-framing scaffolding, not durable taxonomy.
- Brief edit shape: one identical bullet inserted into the `## ADR / Decision-Log Pointer` section of all six `skills/plugin-audit/briefs/0{1..6}-*.md` files, listed after the existing ADR-007 and ADR-009 bullets. Rationale: pattern matches the existing ADR-consult convention; six identical bullets keep the briefs in lockstep so the audit cycle behavior is predictable regardless of which brief is consulted first.

## Key Files
- `.context/decisions/010-template-promotions-and-carryforward-retier.md` — NEW. ADR recording the single promoted phase-template change (Part A) and the m1/m9 carry-forward re-tier registry with Disposition + Rationale columns (Part B).
- `.context/decisions/README.md` — appended one row to the Decision Log table (ADR-010).
- `context_template/context/workflows/task-plan/phase-completion.md` — UPDATED. Inserted the 2-line "Append via `append-retrospective-entry` script — do not edit `retrospectives.md` by hand" note immediately after `## Retrospective Template`; template-version bumped `1.3` → `1.4`. No other base templates touched (architect pass confirmed `phase-{investigation,architecture,implementation,testing}.md` had no real promotions — Step 1's other PROMOTE classifications were either base-already-correct or repo-specific).
- `skills/plugin-audit/briefs/{01-agents,02-process-skills,03-context-specialist-init,04-utility-skills,05-infrastructure}.md` — UPDATED. Each got one byte-identical ADR-010 bullet inserted after the existing ADR-007 and ADR-009 bullets in the `## ADR / Decision-Log Pointer` section.
- `skills/plugin-audit/briefs/06-cross-cutting.md` — UPDATED. Was missing the `## ADR / Decision-Log Pointer` section entirely; coder added the full section (heading + intro paragraph + ADR-007/009/010 bullets + catch-all line) so all six briefs are in lockstep. Reviewer approved this scope expansion as the minimum needed for predictable audit-cycle behavior.
- `CHANGELOG.md` — `[Unreleased]` updated: the existing ICON-0035 ADR-pointer entry was rewritten to include ADR-010 and the six-brief end state (cumulative-effect rule); a new `### Changed` entry added describing the `phase-completion.md` template script-note insertion.
- `.context/tasks/ICON-0039-template-generalization-retier/plan.md` — this file.

## Progress
- [x] Step 1 — Explore: per-phase deltas enumerated; 22 candidate PROMOTE / 24 LEAVE / 5 NEUTRAL. Architect later trimmed PROMOTE to one real item (the script-invocation note in `phase-completion.md`); the rest were base-already-correct or repo-specific.
- [x] Step 2 — Explore: carry-forward Minor survival check done. **m-U-K and m-U-H closed by ICON-0038**. **m1 still open** (`context_template/.../prune-context.sh` has 7 `2>/dev/null` instances, ADR-007 scope-exempts autonomous scripts). **m9 still open, intentionally** (literal DataScan-flavored examples per ICON-0035 disposition). → Only m1 and m9 went into the registry.
- [x] Step 3 — Explore: `plugin-audit` skill at `skills/plugin-audit/SKILL.md`. ADR-consult gating lives in `skills/plugin-audit/briefs/{01..06}.md` "ADR / Decision-Log Pointer" sections (briefs 01-05 identical; brief 06 was missing the section). Insertion point: after existing ADR-007 and ADR-009 bullets.
- [x] Step 4 — Architect: produced the concrete promotion list (single 2-line block in `phase-completion.md`), approved the ADR-010 outline with refinements (Disposition column with rationale, drop (a)/(b) labels in the durable ADR), confirmed the exact brief-bullet text.
- [x] Step 5 — Coder: ADR-010 file written; Decision Log row appended; the 2-line note inserted into base `phase-completion.md` with template-version bumped 1.3→1.4; six briefs updated in lockstep (brief 06's section expansion noted in Key Files).
- [x] Step 6 — Reviewer: approved with two minor stylistic notes. One ("Future audit cycles" sentence-stem redundancy at ADR-010 lines 34/41) was applied as a tightening edit; the other (cosmetic nested-bullet preference) was acknowledged but left as-is.
- [ ] Step 7 — Changelog entry done; reconcile plan.md done (this update); retrospective + commit + MR remaining. ← IN PROGRESS

## Open Questions / Blockers
- (resolved by Step 1) — phase-* deltas enumerated; some PROMOTE classifications in the explore report may be base-already-correct rather than local-needs-promoting. Architect validates against actual file contents in Step 4.
- (resolved by Step 2) — m-U-K and m-U-H closed by ICON-0038; m1 (autonomous-script `2>/dev/null` — already scope-exempted by ADR-007) and m9 (intentional DataScan examples per ICON-0035 disposition) remain.
- (resolved by Step 3) — Brief edits are the right insertion point; one bullet under each brief's "ADR / Decision-Log Pointer" section.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- This task is judgment + documentation only. Implementation of individual promotions or fixes happens in the relevant domain PRs (per GitLab #24 "Out of scope"). The promotions to `context_template/` allowed here are the small generalizable bits that the review surfaces; substantive new behavior would belong in its own task.
- `.context/workflows/task-plan/phase-*.md` files are intentionally repo-customized — do not blindly sync from `context_template/`.
- Common-constraints / scope-discipline: stay within the GitLab #24 acceptance criteria; do not expand into new audit work.
