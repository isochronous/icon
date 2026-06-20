## Task: ICON-0064
## Branch: feature/ICON-0064-memory-to-context-migration
## Objective: Audit the agent's personal Claude memory store (`~/.claude/projects/-home-jmcleod-dev-ai-platform-plugins-icon/memory/`, 19 files) and relocate entries that are transferable ICON project/workflow knowledge into shared, version-controlled `.context/` (or `.claude/claude.md`), per user direction — personal memory is invisible to other contributors and the ICON system. Genuinely harness-/tooling-specific or non-ICON entries stay in personal memory; entries already covered in shared docs are dropped from personal memory (verify coverage first).
## Folder: .context/tasks/ICON-0064-memory-to-context-migration/

## Decisions
- Branch off main (independent of the now-merged ICON-0059..0063 stack; everything is on main as of v1.20.0 / b85e4e2).
- Three-way classification per memory file: (A) MIGRATE to a shared doc; (B) KEEP personal (harness/tooling-specific or non-ICON-repo knowledge); (C) ALREADY COVERED in shared docs → drop from personal memory (only after verifying the coverage with a citation).
- The memory files live OUTSIDE the repo (~/.claude/...); their deletion is memory management done by the manager directly, not a repo change. Only the `.context/`/`.claude/claude.md` additions are the repo MR.
- Tool-agnosticism guard (ADR-004): do NOT migrate Claude-Code-specific guidance (e.g. model-tier names) into shared ICON docs that are meant to be tool-portable.

## Key Files (to be refined after audit)
- `~/.claude/.../memory/*.md` (19 files) — audit source; deletions/edits are memory management, not repo.
- `~/.claude/.../memory/MEMORY.md` — index; prune lines for migrated/dropped entries.
- `.context/...` target docs — TBD from audit (candidates: `workflows/branching.md`, `standards/changelog-discipline.md`, `decisions/`, a domain doc, `.claude/claude.md`).
- No `CHANGELOG.md` entry — `.context/`/`.claude/` are repo-internal.

## Candidate classification (manager's pre-audit read — to be verified)
- KEEP personal: git-commands-no-cd (harness perm prompts), blocked-command-pause (autopilot), subagent-model-defaults (Claude-Code model tiers — ADR-004), workspace-folder-convention (org-wide, not ICON-repo).
- MIGRATE: icon-repo-is-datascan-production (critical production-state knowledge), session-start-unmerged-branch (branching), plan-final-edit-needs-followup-commit (task-plan completion), yaml-scalars-means-folded (skill-authoring), task-start-and-reopen-conventions (workflow).
- VERIFY-then-likely-DROP (already covered): changelog-one-per-change, changelog-by-user-relevance, changelog-unreleased-edit-boundary (→ changelog-discipline.md), never-skip-retrospective (→ manager.agent.md Hardcoded), invoke-skills-on-edit (→ writing-skills/using-skills), context-specialist-commit-scope (→ task-retrospective/context-maintenance), markdown-hard-linebreaks (verify), never-release-without-instruction (verify), agents-no-context-refs + release-via-latest-tag (orphaned — read & classify).

## Finalized classification (post-audit)
**Guard applied:** migrations land in `.context/` or `.claude/claude.md` ONLY — NOT in consumer-shipped `agents/`/`skills/`. Where the auditor's ideal home was a shipped agent/skill, the *knowledge* is migrated to the nearest `.context` doc and *enforcement in the agent/skill* is recorded as a candidate follow-up (NOT done here — it's behavior change needing its own task).

MIGRATE (8):
- agents_no_context_refs → `.context/standards/skill-decomposition/infrastructure-and-distribution.md`
- changelog_unreleased_edit_boundary → `.context/standards/changelog-discipline.md`
- invoke_skills_on_edit_tasks → `.context/domains/skill-system.md`
- never_release_without_instruction → `.claude/claude.md`
- plan_final_edit_needs_followup_commit → `.context/workflows/task-plan/phase-completion.md`
- session_start_unmerged_branch → `.context/workflows/branching.md` (enforce-in-manager = follow-up)
- icon_repo_is_datascan_production → NEW `.context/decisions/011-datascan-production-instance.md`
- task_start_and_reopen_conventions → NEW `.context/workflows/task-start-conventions.md`

KEEP personal (5): blocked_command_pause, git_commands_no_cd, subagent_model_defaults (harness/tool-specific, ADR-004), markdown_hard_linebreaks (universal), workspace_folder_convention (org-wide).

DROP — already covered (6), citations to verify at review: changelog_by_user_relevance (changelog-discipline Rule 4), changelog_one_per_change (changelog-discipline Rule 1), context_specialist_commit_scope (manager.agent.md:206), never_skip_retrospective (manager.agent.md Hardcoded), release_via_latest_tag (branching.md §Tag+ADR-002), yaml_scalars_means_folded (writing-skills + skill-mechanics).

Candidate follow-ups (behavior changes, NOT in this task): enforce never-release gate in release-plugin skill; add unmerged-branch check to manager Session Start; promote invoke-skill-before-edit to a writing-skills AR row.

## Progress
- [x] Establish task: branch off main + folder + plan.md
- [x] Audit (general-purpose): 19 files classified with coverage citations
- [x] Manager finalized classification (.context-only migration guard applied)
- [x] @context-specialist wrote the 8 migrations (incl. new ADR-011 + new task-start-conventions.md + decisions/README index); 9 files staged; no agents/skills touched
- [x] @reviewer: APPROVED — 8 migrations accurate/well-placed; all 6 drop-citations verified REAL (no knowledge lost on deletion); cap-gate exit 0; 2 optional Minors. 
- [x] Deleted 14 personal memory files (8 migrated + 6 covered); kept 5 (harness/tool-specific + org-wide); MEMORY.md pruned to 5
- [ ] Reconcile plan; retrospective (manager draft → @context-specialist insert) ← IN PROGRESS
- [x] Committed (9fe4e9f, dae010c), pushed; MR !48 → https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/merge_requests/48 (targets main)

## Outcome
- 8 ICON knowledge entries relocated from personal memory into shared `.context/`/`.claude/claude.md` (2 new files: ADR-011 datascan-production-instance, workflows/task-start-conventions.md).
- 6 entries dropped as already-covered (citations verified by reviewer).
- 5 entries kept personal (genuinely harness/tool-specific or org-wide, not ICON-repo knowledge).
- Migration guard: knowledge → .context only; enforcing rules in shipped agents/skills deferred as candidate follow-ups (never-release gate in release-plugin; unmerged-branch check in manager Session Start; invoke-skill-before-edit AR row in writing-skills).
- No CHANGELOG entry — all .context/.claude/ repo-internal.

## Open Questions / Blockers
- Borderline: subagent-model-defaults (Claude-Code-specific — keep personal vs a Claude-Code-scoped .context note?). Resolve during audit; surface to user only if genuinely ambiguous.

## Constraints
- ICON pure-content (ADR-005). Verification = content/coverage checks, not execution.
- ADR-004 tool-agnosticism: keep tool-specific guidance out of shared portable docs.
- O-M1b cap-literal gate scans `.context/*.md` (excl. tasks/) — don't introduce a cap literal N≠10.
- Personal-memory deletions are NOT repo changes; only .context/.claude.md edits go in the MR.
