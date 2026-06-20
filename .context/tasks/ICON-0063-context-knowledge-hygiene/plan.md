## Task: ICON-0063
## Branch: feature/ICON-0063-context-knowledge-hygiene
## Objective: Knowledge-base hygiene from this session. (1) Split the oversized `.context/standards/skill-decomposition/process-sweeps.md` (30KB, over the 16KB threshold — a mechanical maintenance obligation that should have been handled in ICON-0060 when an edit enlarged it). (2) Relocate two durable session lessons from an agent's personal memory into shared `.context/` (per user direction). (3) Add a guard to `.claude/claude.md` so future agents capture durable lessons in `.context/`, not tool-specific personal memory.
## Folder: .context/tasks/ICON-0063-context-knowledge-hygiene/

## Decisions
- Stacked on `feature/ICON-0062-...` (ordered stack !42→!43→!44→!46→this). MR targets the ICON-0062 branch; auto-retargets to main as earlier MRs merge.
- Treat as one coherent "context/knowledge-base hygiene" task — all changes are `.context/` + `.claude/claude.md` documentation. No consumer-shipped behavior change → no CHANGELOG entry (`.context/` and `.claude/` are repo-internal per changelog-discipline).
- The split was the user's explicit callout ("why am I having to tell you to split it"): mechanical, rule-driven maintenance (16KB threshold + ICON-0040 auto-split convention) must be done in-task, not deferred.

## Key Files
- `.context/standards/skill-decomposition/process-sweeps.md` (30,257 bytes, 7 `## ` sections): split per `context-document-guidelines` so each resulting file is < 16KB; preserve ALL content; keep the skill-decomposition structure coherent.
- `.context/standards/skill-decomposition.md`: parent index — update any inbound link/reference to `process-sweeps.md` to match the new structure.
- `.context/workflows/branching.md`: add the **stacked-branches-for-dependent-task-sequences** convention (branch each task off the previous, MRs accepted in order to avoid merge conflicts; confirm stacked-vs-independent at sequence start). branching.md already owns the branch/merge model + the ICON-0062 template-bump cadence.
- `.context/standards/` (placement TBD by specialist): add the **don't-defer-mechanical-maintenance** discipline (rule-driven obligations — file-size split, README registration, stale-literal sweeps — get done in-task; only genuine product/design decisions get surfaced to the user).
- `.claude/claude.md`: add a guard — capture durable lessons in `.context/` (via the retrospective/promotion flow), not in tool-specific personal memory, since personal memory is invisible to other contributors and the ICON system.
- (no `CHANGELOG.md` — repo-internal only)

## Progress
- [x] Establish task: branch off ICON-0062 (stacked) + folder + plan.md
- [x] @context-specialist: split process-sweeps.md → 3 themed siblings (process-doc-sweeps.md 6.2KB, pre-flight-exploration.md 11KB, dispatch-and-review-gates.md 14KB), original git rm'd, content byte-preserved, skill-decomposition.md index updated; promoted stacked-branches → branching.md; created standards/in-task-maintenance.md (don't-defer discipline); added claude.md "Durable knowledge capture" guard
- [x] @reviewer: APPROVED — 0 Critical/Moderate, 1 Minor (brittle positional cross-ref in branching.md — FIXED). Reviewer independently reconstructed all 7 sections from `git show HEAD:` and confirmed zero content loss; ran the pre-commit gate (exit 0).
- [ ] Reconcile plan; retrospective (manager draft → @context-specialist insert) ← IN PROGRESS
- [x] Committed (46807f7, 0a9cc49, 24d6afa), pushed; MR !47 → https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/merge_requests/47 (targets ICON-0062 branch)

## Outcome
- `process-sweeps.md` (30KB, over threshold) split into 3 themed siblings under skill-decomposition/, all <16KB, content byte-identical, index + anchors updated.
- Two session lessons relocated from personal memory into shared `.context/`: stacked-branches → `workflows/branching.md`; don't-defer-mechanical-maintenance → new `standards/in-task-maintenance.md`.
- `.claude/claude.md` gains a "Durable knowledge capture" guard (lessons → .context/, not personal memory).
- No CHANGELOG entry — all `.context/`/`.claude/` repo-internal.
- Post-review addition (user-suggested, 8ff4812): branching.md stacked-branches section now notes GitLab **Merge request dependencies** (Premium/Ultimate) as the mechanical way to enforce stacked-MR merge order; verified via @researcher (cache doc gitignored).

## Open Questions / Blockers
- Split boundaries for process-sweeps.md (7 sections) — specialist decides per context-document-guidelines (folder-with-index vs sibling files under skill-decomposition/). Must update the inbound reference in skill-decomposition.md; the reference in retrospectives.md is a historical retro entry — leave it.

## Constraints
- ICON pure-content (ADR-005). No behavior change; verification = content-preservation + reference-resolution checks (grep), not execution.
- Do NOT lose any content in the split — every section/line of process-sweeps.md must survive in the new structure.
- The new O-M1b cap-literal gate scans `.context/*.md` (excl. `.context/tasks/`) — ensure the split files and promotions don't introduce a `cap (N)`/`older than the Nth`/`N entries to scan` literal with N≠10 (the pre-commit hook will enforce this on commit).
- `.claude-plugin/plugin.json` version SSOT untouched (ADR-003).
