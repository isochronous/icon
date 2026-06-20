## Task: ICON-0011
## Branch: feature/ICON-0011-port-common-constraints-sync-hook
## Objective: Port the `common-constraints` sync pre-commit hook from the marketplace layout to this standalone repo so the byte-equality of the injected block across all agent files is enforced by automation, not author discipline. Update `.context/domains/skill-system.md` (and any related docs) to describe the hook accurately.
## Folder: .context/tasks/ICON-0011-port-common-constraints-sync-hook/

## Decisions
- Bundle the doc fix originally requested for `skill-system.md` into this task rather than committing it ahead of the hook port: the doc wording for the "sync mechanism" sub-section depends on whether the hook exists, so committing the docs twice (once describing the gap, again describing the hook) would create noise. One coherent commit set is cleaner.
- Install hook at `.githooks/pre-commit` to sit alongside the existing `post-commit` cache-pruning hook. The repo has `.githooks/` configured via `core.hooksPath` (verified: `git config core.hooksPath` returns `.githooks`); follow the existing convention rather than introducing `.husky/` or `.pre-commit-config.yaml`.
- **Reconstruct, don't port.** The marketplace's current `.githooks/pre-commit` no longer contains the common-constraints sync — it was lost during the split when `plugins/ICON/` was deleted and the hook's hard-coded paths broke (recorded in marketplace `.context/retrospectives.md:8`). The marketplace pre-commit is now just JSON manifest validation. So this task reconstructs the sync logic from the documented behavior (MKT-0056 planner report, ICON-0003 audit research), not by copying an existing script.
- **Rewrite in pure bash** (not Python like the original). Rationale: ADR-005 — ICON is pure-content and ships no Python runtime dependency. A pre-commit hook firing on every commit should not require a separate interpreter when bash + standard POSIX tools can do the same job. Use `awk` with `ENVIRON[]` for safe arbitrary-content injection (avoids `-v` escape-processing pitfalls when the constraints block contains backslashes or other awk-significant characters).
- **Auto-fix and re-stage**, matching the documented original behavior: if drift is detected, rewrite the agent file in place and `git add` it so the commit proceeds with the synced content. Abort only if the source file is missing or a BEGIN marker lacks a matching END (structural error, not drift).
- **Sync all agents on every pre-commit**, not just staged ones. Rationale: when `shared/common-constraints.md` changes, all 9 agents need re-sync regardless of which files are staged. Cheap (small files, ~9 invocations); guaranteed correct.

## Key Files
- `shared/common-constraints.md` — authoritative source of the injected constraints block. Hook reads from here; not modified by the hook port.
- `agents/*.agent.md` (9 files) — each contains a `<!-- BEGIN: common-constraints -->` … `<!-- END: common-constraints -->` block that the hook keeps in sync with `shared/common-constraints.md`. Sync run during step 4 should be a no-op if author discipline has held; any diff surfaces drift.
- `.githooks/pre-commit` (NEW) — the ported hook script.
- `.githooks/post-commit` (existing) — reference for the directory's existing style/conventions.
- `.context/domains/skill-system.md` — already partially edited by @context-specialist; the "Sync mechanism (current state)" paragraph needs to be rewritten once the hook lands to describe the hook as the live mechanism rather than as a missing one.
- `.context/decisions.md:140` — already updated by @context-specialist to reframe common-constraints as a shared block rather than a skill. Verify it still reads correctly after step 5.
- `.context/tasks/ICON-0003-plugin-audit/research/05-infrastructure.md:73` — historical record of the migration gap; **do not edit** (point-in-time research artifact).
- `CHANGELOG.md` — entry describing the hook port.

## Progress
- [x] **Investigate**: located the marketplace `.githooks/pre-commit` and confirmed the sync logic is GONE — replaced with JSON-validation-only after the split. Confirmed `.githooks/` is wired via `core.hooksPath` (= `.githooks`). Markers used are `<!-- BEGIN: common-constraints -->` / `<!-- END: common-constraints -->`. Original was Python embedded in pre-commit; we'll rewrite in pure bash.
- [x] Updated this plan with findings (this section + Decisions). Concrete step list below.
- [x] **Wrote the hook** (`.githooks/pre-commit`) in pure bash. Auto-fix + re-stage on drift; abort on structural error. CHANGELOG `[Unreleased] / ### Added` entry added in same dispatch. (Note: the @coder sub-agent was blocked by autopilot from running its own verification commands and reported correctly per the new feedback rule.)
- [x] **Ran the hook locally**. `bash -n` passed; dry-run **surfaced real whitespace drift** (one trailing blank line between last content line and END marker on all 9 agents). The ICON-0003 audit's SHA256 byte-equality claim was wrong — author discipline had silently introduced a single blank line on each agent file. Hook auto-fixed and re-staged all 9; diffs are whitespace-only (semantically equivalent), and the sync becomes part of this commit. Capture this in the retrospective: "audit byte-equality claim was stale; author-discipline alone could not catch a single-blank-line drift accumulated over multiple sessions."
- [x] **Rewrote "Sync mechanism" paragraph** in `.context/domains/skill-system.md` to describe the live hook (source file, marker block, auto-fix + re-stage, abort-on-structural-error, `core.hooksPath` wiring). Verified `decisions.md:140` historical note still reads correctly; no edit needed. Verified other `.context/` references (overview, phase-*.md, standards/skill-decomposition.md) — all still accurate (`shared/` directory, "byte-equal" wording).
- [x] @reviewer pass on all changes. Approved-with-comments: one Moderate finding (fenced-code-block false-positive on marker detection); minor style nits ignored per spec. Doc-mitigated in-MR via header comment in hook + sentence in skill-system.md; engineering fix filed as GitLab issue #11 (`pre-commit hook: make common-constraints marker detection fenced-code-block aware`).
- [x] task-retrospective + @context-specialist maintenance pass. Promotions landed: ADR-004 Consequences updated to note mechanical enforcement; phase-implementation.md @coder dispatch template names the hook explicitly; retrospectives.md entry appended (rolling log now 8 entries, under 15 cap).
- [ ] Commit, verify clean working tree, close task. ← IN PROGRESS

## Open Questions / Blockers
- None outstanding. Investigation resolved the marketplace question (script gone, reconstruct in pure bash). The user's note about the marketplace hook pointing at the icon plugin dir is consistent with what was found: original paths were `plugins/ICON/shared/common-constraints.md` and `plugins/ICON/agents/*.md`, which broke when those directories were deleted.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005. The hook itself is bash; no node/python toolchain to lean on.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003. Not modified by this task.
- The injected block in every agent file MUST remain byte-equal to `shared/common-constraints.md` post-hook. The hook's job is to enforce this.
- Do not edit point-in-time task-folder research artifacts (`.context/tasks/ICON-0003-plugin-audit/`).
- The repo uses `main`-only branching — this task merges back to `main` when complete.
