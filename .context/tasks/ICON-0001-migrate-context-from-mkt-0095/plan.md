## Task: ICON-0001
## Branch: feature/ICON-0001-migrate-context-from-mkt-0095
## Objective: Complete the `.context/` for the ICON repo by (a) migrating 6 files that were authored under the marketplace's `.context/` for plugin-authoring concerns and deleted during the MKT-0095 split, and (b) running `@context-specialist mode=upgrade` to fill remaining gaps (decisions.md, META.md, additional standards/workflows). Originates as follow-up items #3 and #4 from `marketplace/.context/tasks/MKT-0095-split-icon-to-own-repo/plan.md`.
## Folder: .context/tasks/ICON-0001-migrate-context-from-mkt-0095/

## Decisions
- **Migrate first, upgrade second.** Recover the 6 files from marketplace git history, adapt them for the ICON-repo authoring context, land them, then dispatch `mode=upgrade` so it sees the populated files and only fills genuine gaps. Rationale: `mode=upgrade` is documented to skip populated files; running it first would either populate placeholders we'd then overwrite or skip useful gaps because we hadn't named them yet.
- **Source the 6 files from `marketplace@6a403f7^`** (the commit before MKT-0095 began deleting files). Pre-deletion content is authoritative; the post-deletion tree no longer has them.
- **Adapt during migration, do not verbatim copy.** Each file referenced the marketplace's `plugins/ICON/` path layout, two-channel release flow (ICON + ICON-beta), and `release-plugin-beta` skill. These have been collapsed in the new repo (paths are at repo root; single-channel `main`-only release; one `release-plugin` skill). Re-anchor paths and drop obsolete content during migration; do not preserve as a historical record.
- **Delegate migration to @coder** rather than handling each file directly — they are content edits, not orchestration artifacts.
- **Delegate upgrade to @context-specialist with mode=upgrade**, not mode=create. The repo already has a populated `overview.md`, `iconrc.json`, empty `retrospectives.md`, and `tasks/.gitkeep`. `mode=create` is for empty trees.
- **Task ID prefix `ICON`** per `.context/iconrc.json` `local_task_id_prefix`. This is the first task in the repo since the split.

## Key Files

### Source (marketplace repo, recover from git history at 6a403f7^)
- `.context/standards/skill-decomposition.md` → ICON `.context/standards/skill-decomposition.md`
- `.context/standards/changelog-discipline.md` → ICON `.context/standards/changelog-discipline.md`
- `.context/workflows/changelog.md` → ICON `.context/workflows/changelog.md`
- `.context/domains/plugin-resource-paths.md` → ICON `.context/domains/plugin-resource-paths.md`
- `.context/domains/skill-system.md` → ICON `.context/domains/skill-system.md`
- `.context/domains/mcp-servers.md` → ICON `.context/domains/mcp-servers.md`

### Target (ICON repo)
- `.context/standards/` — new directory; receives skill-decomposition.md + changelog-discipline.md (and any standards mode=upgrade adds).
- `.context/workflows/` — new directory; receives changelog.md (and any workflows mode=upgrade adds).
- `.context/domains/` — new directory; receives the three domain files (and any domains mode=upgrade adds).
- `.context/overview.md` — already populated; the "Status of `.context/`" section currently lists `domains/`, `standards/`, `workflows/`, `cache/`, `decisions.md`, `META.md` as pending. Update at task close to reflect the new state.
- `.context/decisions.md`, `.context/META.md` — expected to be added by mode=upgrade.
- `.context/cache/` — expected as part of mode=upgrade. Researcher-maintained reference cache; iconrc.json declares `cache_expires_after_days: 30`.
- `.context/retrospectives.md` — empty; the manager will append the close entry directly per workflow rules.

## Progress
- [x] Branch created (feature/ICON-0001-migrate-context-from-mkt-0095)
- [x] Task folder created
- [x] plan.md written
- [x] @coder migrated 6 files from marketplace@6a403f7^, adapted for ICON repo — all acceptance greps pass; `workflows/changelog.md` significantly rewritten (two-changelog → one); other files were path-only or minor adaptation
- [x] Committed migration as commit `5799de2`
- [x] @context-specialist mode=upgrade — committed as `295a3ae`. Created 14 files (META.md, decisions.md, .gitignore, cache/.gitkeep, workflows/branching.md, workflows/commit-conventions.md, workflows/prune-old-tasks.sh, 6 workflows/task-plan/* templates, .githooks/post-commit). Surfaced gaps (skipped template `code-style.md`/`naming-conventions.md`/`error-handling.md`/`glossary.md`/`entities.md` as not applicable to a content-only repo).
- [x] @coder updated `.context/overview.md` "Status of `.context/`" section to reflect populated state — committed as `fd1cb56`
- [x] @reviewer pass — flagged Critical (ADR date errors in decisions.md, 4 of 6 wrong against git log) + Moderate (cross-repo wording slip in ADR-001, invented `bugfix/` branch pattern, META.md template-fidelity note). Minor findings deferred.
- [x] @coder applied Critical + Moderate fixes — committed as `f05b4ca`. M-1 (changelog.md "rename" vs SKILL.md "insert" wording) deferred as pre-existing pre-split conflict; surfaced as follow-up.
- [x] task-retrospective skill applied — 3 questions answered; no `.context/` promotion (lessons too narrow); entry appended via `append-retrospective-entry.sh`
- [x] @context-specialist mode=maintenance skipped — nothing material to promote beyond the retrospective entry itself
- [x] retrospectives.md entry written
- [ ] Commit final task artifacts (plan.md + retrospectives.md) ← IN PROGRESS
- [ ] Merge feature → main in ICON repo (main-only branch model)
- [ ] Push origin/main (user confirmation required)
- [ ] Marketplace housekeeping: delete merged local feature/MKT-0095 branch (item 5 from MKT-0095 follow-ups)

## Follow-ups identified during this task

1. **Reconcile `workflows/changelog.md` vs `release-plugin/SKILL.md` Step 5 wording.** The workflow doc says release-plugin "renames `[Unreleased]` to `vX.Y.Z`"; SKILL.md says "insert a new entry below `[Unreleased]`". Repo evidence (empty `[Unreleased]` in current CHANGELOG.md above `## [1.15.3] - 2026-04-30`) shows the rename behavior is what actually happens, so the SKILL.md is the file to fix. Scope: a quick wording-only edit; trivially small task.

## Notes
- @coder flagged a `<system-reminder>` block appearing at the end of `git show 6a403f7^:.context/standards/skill-decomposition.md` output during migration. Likely a harness artifact rather than embedded content (the marketplace source file would not contain `<system-reminder>` tags); regardless, @coder correctly did not propagate it into the migrated file. No action needed.

## Open Questions / Blockers
- None at task start. Items 1, 2 (rotate PAT, distribute helper script) are user actions and are surfaced at task close, not blockers. Item 6 (cache retention policy) is optional and deferred.
- If during adaptation @coder finds substantial content that is plugin-internal but doesn't map to a single domain/standard/workflow file, surface to manager for placement decision rather than inventing new structure unilaterally.

## Constraints
- ICON repo is `main`-only (no dev/main split). Feature branches off main, merge back to main when complete.
- Default sub-agent model is `sonnet`; architect exempt; ask user before choosing `opus` for high-complexity dispatches. (Per user feedback memory.)
- ICON repo follows the same `.context/` structure conventions as the marketplace, with `excludes: ["architecture", "testing", "styling"]` from iconrc.json — those subdirectories are not part of this repo's `.context/`.
- No source investigation by the manager; all file inspection and content edits are delegated. Manager owns only plan.md, retrospectives.md, and git operations.
- During migration, content authored for the marketplace's monorepo perspective (two-channel ICON/ICON-beta, `plugins/ICON/`-prefixed paths, marketplace listing concerns) must be re-anchored or dropped, not preserved.
