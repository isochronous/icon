## Task: ICON-0048
## Branch: feature/ICON-0048-audit-objective-fixes
## Objective: Close the objective-only subset of ICON-0046 audit findings — bad paths, outdated references, and factual contradictions — leaving subjective design decisions (ecological-impact rewrite, writing-skills word cap, plugin-lint label resolution, verification-gate ownership, plugin decomposition) for separate follow-up tasks.
## Folder: .context/tasks/ICON-0048-audit-objective-fixes/

## Decisions
- **Scope is "objective only" per user directive.** Excluded: M-U-NET1 (ecological-impact rewrite — open Q2 in audit), m-new-03 (plugin-lint label resolution — open Q in audit), m-infra-3 (release-plugin feature add), m-P-NEW-3 (verification-gate ownership — open Q3 in audit), m-U-net1 (writing-skills word cap — open Q5 in audit), m-U-net4 (plugin-design self-contradiction — multiple resolution options), m-U-net5 (icon-audit Iron Law observability — process gap, not a defect), **m-new-02 (stderr suppression in `upgrade-repo` — user confirms this is a known will-not-do exception).**
- **m-infra-1 (`.mcp.json` `$schema`) skipped.** Researcher (2026-05-28) confirmed no canonical, publicly hosted JSON Schema exists for Claude Code's `.mcp.json`. SchemaStore registers 4 Claude Code schemas (`claude-code-settings`, `claude-code-plugin-manifest`, `claude-code-plugin-marketplace`, `claude-code-keybindings`); none match `.mcp.json`. The `settings.json` schema covers an `mcpServers` sub-object but is semantically wrong as `$schema` for the standalone registry file. Finding deferred until an upstream schema is published.
- **m-U-net3 (sprint-goals live `onedatascan.atlassian.net` URL) reverted after user clarification (2026-05-28).** This repo IS DataScan's production plugin — there is no separate "DataScan fork" where a live link could live. The audit's classification of the URL as a portability defect was wrong; the live ORG-004 link is the working production reference DataScan engineers need. ADR-010 m9 already accepts DataScan-flavored examples in the body; m-U-net3 misread body prose as out-of-bounds for that carve-out. Original URL restored on both `:20` and `:196`; CHANGELOG bullet removed. If a future fork or marketplace split decouples a generic ICON from DataScan's instance, the link can be revisited at that boundary.
- Bundle as a single sweep PR rather than 9 micro-PRs. Audit-report Suggested Follow-up "ICON-0050 — Net-new Minor sweep PR" anticipates exactly this bundling shape.
- **CHANGELOG entries: one per change, not one per task** (user clarification, 2026-05-28). The first-draft bundled sentence and the reviewer's compressed-summary alternative were both wrong shapes. Final form: separate `### Fixed` bullets, one per distinct semantic fix (cap-drift, filename fix, agent-description trim, audit-mode contradiction, Discretionary parenthetical, user-invocable key, sprint-goals URL).
- Use `@coder` for the SKILL.md / agent / hook / manifest edits; manager owns the plan.md and git operations per hardcoded-tier rule.

## Key Files
- `skills/task-plan-phase-completion/agent-vs-skill-invocation.md` — `:23` says `keep-last-15`; should reflect post-ICON-0036 cap. (m-P-NEW-1)
- `skills/context-maintenance/append-retrospective-entry.md` — `:3,:32` describe "rolling log of last 15 entries" and single-prune logic (pre-ICON-0041); should reflect current cap and multi-prune behavior. (m-P-NEW-2)
- `skills/context-specialist-impl-root/SKILL.md` — `:256` Step 15 verify item 4 references `patterns-template.md`; skill generates `patterns.md`. (m-new-01)
- `.githooks/pre-commit` — `:19-40` header comment lists invariants in wrong order vs. actual execution. (m-infra-2)
- `agents/manager.agent.md` — `:238` Discretionary heading missing `(Off Unless Explicitly Requested)` parenthetical present on sibling agents. (m-A-NET-NEW-2)
- `agents/context-specialist.agent.md` — `:2-6` description is 3 sentences (1-sentence rule); `:84` "(where audit-write occurs)" parenthetical contradicts read-only `mode: audit`. (m-A-NET-NEW-1, m-A-NET-NEW-3)
- `skills/mcp-tools-first/SKILL.md` — `:1-9` frontmatter missing `user-invocable` key. (m-U-net2)
- `skills/sprint-goals/SKILL.md` — `:20,:196` — m-U-net3 reverted (see Decisions); file is unchanged from main at task close.
- `skills/task-plan-phase-completion/agent-vs-skill-invocation.md` — `:22` propagation of m-A-NET-NEW-3 audit-mode contradiction (added in reviewer pass).
- `skills/manager-routing-guide/SKILL.md` — `:79` propagation of m-A-NET-NEW-3 audit-mode contradiction (added in reviewer pass; not strictly in the audit's line-citation but the same factual contradiction).
- `CHANGELOG.md` — `[Unreleased]` entry at task close: 7 per-change bullets under `### Fixed` (one per distinct semantic fix, not one per file or one per task).

## Progress
- [x] Read ICON-0046 audit report; classify objective vs. subjective findings — 10 objective items identified (1 conditional on research)
- [x] Confirm scope with user — m-new-02 dropped; m-infra-1 pending schema research
- [x] Create feature branch and task folder
- [x] Research `.mcp.json` `$schema` availability — none exists; m-infra-1 dropped from scope
- [x] Dispatch @coder with the consolidated fix list — all 9 fixes applied across 8 files (current cap value: 10, found in `append-retrospective-entry.sh:41`)
- [x] Verify each fix landed at cited line — confirmed via sed spot-checks and git diff
- [x] Add CHANGELOG `[Unreleased]` entry via `changelog-entry` skill
- [x] Dispatch @reviewer (Opus) — found 2 critical blockers (dead-ref hook on impl-root:256; m-A-NET-NEW-3 propagation in agent-vs-skill-invocation.md:22) + 2 moderates (manager-routing-guide.md:79 sibling propagation; CHANGELOG run-on)
- [x] Dispatch @coder follow-up (Fixes A/B/C/D) — all 4 applied
- [x] User clarification on CHANGELOG shape: one bullet per change, not per task — rewrote `[Unreleased] ### Fixed` block as 7 per-change bullets
- [ ] Reconcile plan.md, run task-retrospective, commit, open MR ← IN PROGRESS

## Open Questions / Blockers
- None. (`.mcp.json` `$schema` question resolved by research — no canonical schema available; skipped.)

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- ADR-004 tool-agnostic content: edits must remain portable across Claude Code and Copilot CLI.
- ADR-008 token budget caps: do not add bulk to `manager.agent.md` or other already-near-cap surfaces. The fixes in scope are deletions/substitutions or single-line adds — keep within that shape.
- Out-of-scope findings (listed above in Decisions) must NOT be touched in this PR even if the same file is opened for an in-scope fix; surface them as follow-up tasks rather than expanding scope unilaterally.
