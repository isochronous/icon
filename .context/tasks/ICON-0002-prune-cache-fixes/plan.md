## Task: ICON-0002
## Branch: feature/ICON-0002-prune-cache-fixes
## Objective: Fix three issues in the prune script + hook discovered during ICON-0001 wrap-up:
  1. Script hard-codes a 3-day cache TTL but `.context/iconrc.json` declares `cache_expires_after_days: 30`. Make the script the consumer, not the authority — read from iconrc.
  2. Script name `prune-old-tasks.sh` is a misnomer: it prunes both `.context/tasks/` (90-day) and `.context/cache/` (configurable). Rename to `prune-context.sh`.
  3. `.githooks/post-commit` comment says "prune `.context/tasks/` folders" only — also misleading.
  4. Apply all three changes to the template copy in `context_template/context/workflows/` so future `/icon-init` runs produce the fixed version.
## Folder: .context/tasks/ICON-0002-prune-cache-fixes/

## Decisions
- **Read `cache_expires_after_days` from iconrc.json with a default fallback of 30 days** if the key is absent or unparseable. Rationale: iconrc.json is the declared SoT for project-level knobs; hard-coding diverges from it.
- **Rename, do not symlink/alias.** Symlinks complicate Windows checkouts and the hook is the only known caller. Direct rename + hook update is simpler.
- **Fall-back default = 30 days, not 3.** iconrc.json's declared 30 represents authorial intent; the hard-coded 3 was almost certainly placeholder. New default matches declared value.
- **Use `jq` if available, fall back to `grep | sed` shell parsing** to keep the script dependency-light (consumer repos may not have `jq`).

## Key Files
- `.context/workflows/prune-old-tasks.sh` → renamed to `.context/workflows/prune-context.sh`; behavior change to read iconrc
- `.githooks/post-commit` — update comment + script path
- `context_template/context/workflows/prune-old-tasks.sh` → renamed to `prune-context.sh`; same behavior change
- `context_template/context/workflows/post-commit` — update comment + script path

## Progress
- [x] Branch + task folder + plan.md
- [x] @coder pass 1: rename + iconrc-driven TTL in both `.context/workflows/` and `context_template/context/workflows/`; hook comment+path updates in both; stale-ref sweep in 5 SKILL/doc files (`upgrade-repo`, `context-specialist-impl-root`, `context-specialist-impl-leaf`, `decisions.md`, `branching.md`)
- [x] @reviewer pass — Critical: grep|sed pipeline aborted under `set -euo pipefail` on missing/invalid iconrc keys (marketplace mirror had `|| echo ""` guard, ICON did not). Moderate: upgrade-repo SKILL legacy-handling clause unclear which path to prefer.
- [x] @coder pass 2: added `|| true` guard to both script copies; clarified upgrade-repo legacy-handling text. All 4 reviewer failure cases now exit 0.
- [x] task-retrospective applied (see retrospectives.md entry)
- [ ] Commit + merge to main + push ← IN PROGRESS

## Open Questions / Blockers
- None.

## Constraints
- ICON repo is `main`-only.
- Default sub-agent model is `sonnet`.
- The renamed script must remain dependency-light (no `jq` requirement; graceful fallback to shell parsing).
- The 90-day task TTL is unchanged in this task; only cache TTL is being touched + the rename.
