## Task: ICON-0061
## Branch: feature/ICON-0061-sessionstart-hook-bootstrap
## Objective: Fix GitLab #29 — `hooks/inject-manager-role.mjs` injects the full ~29KB `manager.agent.md` body as SessionStart `additionalContext`, but Claude Code 2.1.165 silently persists oversized hook output to a file and injects only a ~2KB preview. Net effect: manager sessions run on a truncated role definition (the Anti-Rationalization table, Session Start steps, delegation rules never reach the model). Fix: inject a small (<2KB) bootstrap — a discipline-led prefix + an instruction to read and adopt `${CLAUDE_PLUGIN_ROOT}/agents/manager.agent.md` — so the full role is loaded by the model reading the file, not by an oversized injection.

## Folder: .context/tasks/ICON-0061-sessionstart-hook-bootstrap/

## Decisions
- Stacked on `feature/ICON-0060-reach-automation` (user-directed ordered acceptance #31→#32→#29). MR targets the ICON-0060 branch; auto-retargets to main as earlier MRs merge.
- Read-and-adopt bootstrap pattern (issue's suggested direction): proven this very session — the `/ICON:manager` command works by having the model glob+read+adopt manager.agent.md. The hook should do the same automatically when managerDefault is on.
- Keep the fix MINIMAL: the issue notes context-core's CC-0002 routing hook may supersede ICON's hook entirely — do not over-engineer; a small bootstrap is the correct, low-risk change. Record the supersession note in the MR.

## Key Files
- `hooks/inject-manager-role.mjs`: the SessionStart hook — currently emits the full role body as `additionalContext`. Change to emit a <2KB bootstrap. (consumer-shipped — `hooks/` is in the installed set.)
- `agents/manager.agent.md`: the role file the bootstrap points the model to read+adopt (source of the discipline-led prefix; the file the model loads itself).
- `.claude-plugin/plugin.json` / hook registration: confirm how the hook is wired (SessionStart event) — reference only.
- `.context/tasks/ICON-0058-icon-audit/audit-report.md`: cross-ref (this is an out-of-audit follow-up; #29 was filed separately, not from the audit body).
- `CHANGELOG.md` `[Unreleased]`: entry — consumer-facing behavior fix (managerDefault users now get the full role reliably).

## Progress
- [x] Establish task: branch off ICON-0060 (stacked) + folder + plan.md
- [x] @architect: read hook; confirmed CLAUDE_PLUGIN_ROOT present + `managerPath` already resolved at line 64; current payload = 31,679 bytes; designed 1,292-byte bootstrap. KEY: emit the RESOLVED `managerPath`, not literal `${CLAUDE_PLUGIN_ROOT}` (consuming model's env may not expand it). Change-list: replace lines 72–90, remove line 79 body read, keep gating (lines 23–70) + header-comment update.
- [x] DECISION: bootstrap must NOT claim "persists across /clear" — the hooks.json matcher is `startup|resume` only, so the hook does not re-fire on /clear (pre-existing matcher-vs-comment discrepancy, flagged as candidate follow-up, out of scope).
- [x] @coder: bootstrap implemented (1,286 bytes); verified <2KB + resolved path + read-and-adopt + using-skills; managerDefault-off and non-ICON both 0 bytes; valid JSON. Manager spot-checked (1286 bytes, SessionStart envelope).
- [x] CHANGELOG entry added (### Fixed). hooks.md touch-up → handed to @context-specialist at retro stage (it owns .context/ writes).
- [x] @reviewer: APPROVED — 0 Critical, 0 Moderate, 2 Minor (hooks.md:56 doc drift — being fixed at retro stage; bootstrap's 6-agent list is accurate, no action). Reviewer independently re-ran all hook scenarios.
- [x] Committed hook fix + CHANGELOG (3fa8906)
- [ ] Reconcile plan; retrospective (manager draft → @context-specialist insert + hooks.md touch-up) ← IN PROGRESS
- [x] Committed plan+retro+hooks.md (8c0334a), pushed; MR !44 → https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/merge_requests/44 (targets ICON-0060 branch; Closes #29)
- [x] Post-hoc (user-directed): consolidated the template version to ONE release bump. ICON-0059 (1.3→1.4) + ICON-0060 (1.4→1.5) double-bumped because the ICON-0044 gate forces a version change per template-touching commit. Reset to 1.4 at the tip (8eead79); released end-state = single bump 1.3→1.4 covering all template changes. Candidate ICON follow-up: make the ICON-0044 gate release-aware so stacked same-release commits don't force redundant bumps.

## Outcome
- hooks/inject-manager-role.mjs now injects a ~1.3KB read-and-adopt bootstrap (was ~31KB full body) → survives CC 2.1.165's ~2KB preview-truncation; managerDefault sessions get the full role reliably.
- Emits the RESOLVED managerPath (not literal ${CLAUDE_PLUGIN_ROOT}); all gating preserved; degrades safely on all CLI versions.
- Out-of-scope follow-up surfaced: hooks.json matcher (`startup|resume`) vs header-comment `/clear` claim discrepancy — candidate separate issue (NOT fixed here).

## Design (architect, approved)
- Payload (~1.3KB): leads with load-bearing discipline (orchestrate/delegate, never implement; no source investigation; manager owns git + plan.md/.context/tasks/; no edit before branch+plan.md exist); MANDATORY using-skills first; then "read <resolved managerPath> in full and adopt its entire contents (Session Start, Turn Start, Delegation, Constraints, Behavior Tiers, Anti-Rationalization) as authoritative for the session." Mirrors /ICON:manager framing + /ICON:pm switch.
- Keep: project gate, managerDefault gate, plugin-root + managerPath existence checks, JSON envelope, filename substring.
- Out of scope: /clear matcher fix, any new settings/abstractions (context-core CC-0002 may supersede this hook).

## Open Questions / Blockers
- What exactly belongs in the "discipline-led prefix"? (The minimal always-on content that must survive even if the model somehow doesn't read the file — likely the using-skills mandate + the read-and-adopt instruction.) @architect to determine from the current hook + manager.agent.md.
- Does the bootstrap need to handle the managerDefault=false case (no injection)? Confirm current hook's gating is preserved.

## Constraints
- ICON is pure-content/runtime-config (ADR-005), but `.mjs` hooks ARE runnable — verify by executing the hook and measuring output.
- The bootstrap MUST be < 2KB to survive CC 2.1.165's preview-truncation (the whole point).
- Must be portable (the hook ships to consumers); use `${CLAUDE_PLUGIN_ROOT}` not absolute paths.
- Do not change the managerDefault opt-in/opt-out gating behavior — only what gets injected.
- Behavior must degrade safely on older CLI versions (a <2KB payload is passed whole everywhere).
