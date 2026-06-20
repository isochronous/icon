## Task: ICON-0041
## Branch: feature/ICON-0041-mcp-server-awareness
## Objective: Pre-seed agents with awareness of the bundled GitLab and Atlassian MCP servers so they reflexively reach for `mcp__gitlab__*` / `mcp__atlassian__*` tools when a task touches GitLab issues/MRs, Jira tickets, or Confluence pages — instead of defaulting to web URLs, `gh`/`glab` CLIs, `curl` against the API, or asking the user. Closes GitLab issue #26.
## Folder: .context/tasks/ICON-0041-mcp-server-awareness/

## Decisions
- **First approach (rejected after user feedback): `shared/common-constraints.md`** (issue #26 recommendation 1). One edit propagates to all 9 agents via `.githooks/pre-commit` (ICON-0011) sync. Initial implementation added a 2-line / +872B rule = ~7.8KB additional always-loaded context across the 9-agent set. User flagged this as too expensive for an always-loaded surface: "Either drastically simplify the entry in common constraints, or create a skill that can either be referenced directly in agent defs and with a rich enough description that it should be invoked automatically in the correct situation."
- **Final approach: `skills/mcp-tools-first/SKILL.md`** — a new skill loaded on-demand via its description, NOT always-loaded. Per-agent always-loaded cost: zero. The skill description names concrete triggers (about to type `curl https://gitlab.com/...`, `gh issue view`, etc., or about to access any GitLab/Jira/Confluence surface) so the `using-skills` discipline pulls it in at exactly the right moment without baking it into every agent context. Issue #26's recommendation 2 (domain doc) was already rejected because domain docs don't fire on tasks that don't look domain-shaped — but the skill model has the opposite property: a rich description that fires on action-shaped triggers.
- **Skill description names action-shaped triggers, not just topical ones.** "Use when about to type `curl https://gitlab.com/...`, `gh issue view`, paste a web URL into a response, or ask the user to paste content from one of those systems" — names the exact reflexes the rule is trying to interrupt. A topical description ("Use when working with GitLab/Jira/Confluence") would underfire on tasks the agent doesn't pre-classify as "GitLab work."
- **Skill body enumerates representative tool prefixes, not the full surface.** Issue #26 out-of-scopes exhaustive enumeration ("the goal is 'try MCP first,' not 'memorize the full API surface'"). Name ~5 examples per server family; trust the runtime's tool discovery for the rest.
- **No-silent-fallback rule** is part of the skill body (not the description): on auth error → invoke `setup-mcp-servers`; on other error → surface verbatim and ask. Reviewer-flagged framing during the common-constraints attempt: lead with the general no-fallback rule, then specialize the action by error class, so an agent reading literally doesn't read "auth error" as the only case where fallback is banned.

## Key Files
- `skills/mcp-tools-first/SKILL.md` — new skill, **trimmed to 15 lines / 751 bytes** after second user feedback ("that's a really big skill that's probably overkill ... start simple and only start adding stronger instructions and anti-rationalization tables once we've seen a need for them"). Final body: one paragraph naming the three tool prefixes + the auth-error → `setup-mcp-servers` cue. Description retains the action-shaped triggers since that's what drives auto-invocation. Dropped (YAGNI): Overview section, When-to-Use section, full On-Failure subsection (collapsed to one sentence), Anti-Patterns table, Cross-References section.
- `shared/common-constraints.md` — reverted to pre-task state (the initial common-constraints addition was the rejected first approach).
- `agents/*.agent.md` (all 9) — also reverted via re-run of the pre-commit sync.
- `CHANGELOG.md` — `[Unreleased]` `### Added` entry rewritten per cumulative-effect rule to describe the skill, not the constraint.
- `.context/tasks/ICON-0041-mcp-server-awareness/plan.md` — this file.
- `.context/retrospectives.md` — entry inserted; updated with the pivot lesson.
- `skills/{post-incident-review,task-retrospective,context-maintenance}/scripts/append-retrospective-entry.{sh,ps1}` — separate commit fixing the `ENTRY_CAP=10` cap-not-enforced bug surfaced during this task (user-requested follow-up; bundled into the same MR).

## Progress
- [x] Create branch + task folder + initial plan.md
- [x] Edit `shared/common-constraints.md`: added `**MCP Servers**` rule between General Restrictions and Scope Discipline.
- [x] Ran `.githooks/pre-commit`: source-of-truth sync propagated to all 9 `agents/*.agent.md` files; byte-equality preserved; hook exit 0.
- [x] Acceptance verification: confirmed via `grep '**MCP Servers**: GitLab and Atlassian'` returning 9/9 hits across `agents/*.agent.md`.
- [x] Bytesize sanity: `shared/common-constraints.md` 2,426 B → 3,298 B (+872 B / +2 lines); 9× multiplier across always-loaded agent set ≈ +7.8 KB total. Well under any threshold. Token-economy hit acceptable; defers broader audit to issue #18 without blocking.
- [x] @reviewer pass (Sonnet): 1 Critical (CHANGELOG missing — fixed below), 1 Moderate (GitLab examples mixed prefix-prefix-bare-bare with first one prefixed; fixed by dropping the leading prefix in the GitLab block so all four examples are bare suffixes after the `mcp__gitlab__*` namespace declaration, matching the Atlassian block's pattern), 1 Minor (auth-error scope too narrow; fixed by restructuring to "if MCP call fails, do not silently fall back — auth → setup-mcp-servers, other → surface and ask"). Re-ran hook to re-sync the corrected wording into all 9 agents.
- [x] CHANGELOG `[Unreleased]` Added entry inserted for ICON-0041.
- [x] verification-checklist: Gate 1 (evidence — hook output, grep count, wc), Gate 2 (scope — only `shared/common-constraints.md` source + 9 auto-synced agents + CHANGELOG + plan.md), Gate 3 (pattern — matches existing bold-labeled-paragraph rule pattern in the same file), Gate 4 (no rationalization residue).
- [x] task-retrospective Stage 1 (manager draft)
- [x] task-retrospective Stage 2 (context-specialist mode=maintenance) — entry inserted; file now at 13 entries (above `ENTRY_CAP=10` per script source); script's prune logic didn't fire as designed.
- [x] User feedback (post-MR-open): always-loaded cost too high. Pivoted to skill approach. Reverted `shared/common-constraints.md` + 9 agents; created `skills/mcp-tools-first/SKILL.md` with rich auto-invocation description; rewrote CHANGELOG entry per cumulative-effect rule.
- [ ] Fix `append-retrospective-entry` script cap-not-enforced bug (separate commit per user request — bundled into this MR) ← IN PROGRESS
- [ ] Update retrospective entry to reflect skill pivot
- [ ] Commit pivot, commit script fix, push, update MR description, AWAIT user approval

## Open Questions / Blockers
- None. Scope is bounded; the hook handles propagation; the destination is unambiguous per issue #26.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- The synced block in every `agents/*.agent.md` must remain byte-equal to `shared/common-constraints.md` (enforced by `.githooks/pre-commit`).
- Keep addition tight to minimize the ~9× multiplier on always-loaded agent context (pending broader audit in issue #18).
