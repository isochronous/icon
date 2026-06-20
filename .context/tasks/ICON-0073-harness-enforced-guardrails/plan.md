## Task: ICON-0073
## Branch: feature/ICON-0073-harness-enforced-guardrails
## Objective: Move ICON's highest-risk security controls from bypassable prose into a harness-enforced layer that works on BOTH GitHub Copilot CLI (primary target) and Claude Code, archive pruned retrospectives instead of destroying them, and document how to monitor/tune guardrail policy over time. Closes the enforceable subset of GitLab #40 (RFC security review Q2 + Q5).

## Folder: .context/tasks/ICON-0073-harness-enforced-guardrails/

## Decisions
- **Scope = minimum acceptance slice** (user, 2026-06-18): (1) highest-risk controls enforced via harness rather than prose, (2) pruned retrospectives archived not destroyed, (3) a documented monitoring/tuning approach. The **service-identity / least-privilege** workstream from #40 is deferred to **#41** (the issue itself links it there). No tool-use telemetry pipeline build in this MR beyond a local audit log the hook already produces.
- **Enforcement = portable spec, implemented in each harness's native mechanism** (user, 2026-06-18). Copilot is the PRIMARY target (per user). A single shared `preToolUse` hook script is the portable enforcement layer; Claude Code's `settings.json` deny-list is added as defense-in-depth on that side only.
- **One shared hook script** serves both harnesses. Research (cache `github-copilot-cli-security-controls-2026-06-18.md`) confirmed both expose a `preToolUse`/`PreToolUse` event with fail-closed semantics and compatible stdin (tool name + args) / stdout (`permissionDecision: deny`). The script must accept both Copilot camelCase (`toolName`/`toolArgs`, top-level decision out) and Claude Code (`tool_name`/`tool_input`, nested `hookSpecificOutput` out) shapes and emit the matching output for whichever it received. Node built-ins only (ADR-005; mirrors existing `inject-manager-role.mjs`).
- **Hook complements prose, does not replace it.** Copilot issue #2392: `preToolUse` may not fire in subagents (status unclear on current GA). ICON is delegation-heavy, so the #39 untrusted-content prose guardrails stay as the subagent backstop. Document this enforcement boundary explicitly.
- **Portable control spec lives in `.context/standards/security.md`** — appended as a new `## Harness-Enforced Controls` section. The doc was shaped append-friendly in #39 for exactly this. rules-index.md row already points here; no new row needed (verify).
- **Retrospective archive**: pruned entries appended to `.context/retrospectives-archive.md` (uncapped) instead of being silently dropped in the awk `END` block. Change must be applied identically to all 6 byte-synced `append-retrospective-entry.{sh,ps1}` copies (pre-commit enforces parity) — and the .ps1 logic kept behaviorally identical.

## EMPIRICAL VERIFICATION (Copilot CLI 1.0.63, tested live 2026-06-18 — overrides doc-derived architect assumptions)
Tested with throwaway `.github/hooks` + a probe against the installed ICON plugin hooks.json. Findings:
- **Single shared `hooks/hooks.json` works on BOTH harnesses.** Copilot's `loadPluginHooks` reads the plugin's `hooks/hooks.json`; it accepts the PascalCase `PreToolUse` key (via its `_vsCodeCompat` map) AND honors the entry. NO separate `.github/hooks/guardrail.json` needed (and it would be wrong — ICON ships as a plugin, doesn't write into consumer `.github/`).
- **Copilot executes the `bash` field, NOT `command`+`args`.** The `command`/`args` form is accepted by the schema but inert in Copilot's executor → it fail-closes "code 1". So ONE entry must carry BOTH: `command:"node"` + `args:["${CLAUDE_PLUGIN_ROOT}/hooks/guardrail-pretooluse.mjs"]` (Claude executes this, interpolates `${...}`) AND `bash:"node \"$CLAUDE_PLUGIN_ROOT/hooks/guardrail-pretooluse.mjs\""` (Copilot executes this, shell-expands `$CLAUDE_PLUGIN_ROOT`). VERIFIED: with both fields present, Copilot used `bash`, ignored the rest, ran cleanly.
- **`$CLAUDE_PLUGIN_ROOT` IS set for plugin hooks on Copilot** (= install dir; `COPILOT_PLUGIN_ROOT`/`PLUGIN_ROOT` also set). Copilot does NOT interpolate `${...}` inside `args` (env-var expansion only works in the `bash` shell string).
- **stdin is snake_case `{hook_event_name, tool_name, tool_input, session_id, cwd, ...}` on BOTH** harnesses → no camelCase handling needed (simplifies the script vs the architect's dual-shape plan). Copilot adds `timestamp` and has NO `transcript_path`; Claude Code sends `transcript_path`. → **Distinguish OUTPUT shape by `transcript_path` presence.**
- **OUTPUT**: Copilot reads TOP-LEVEL `{permissionDecision:"deny",permissionDecisionReason}` (VERIFIED honored). Claude reads `{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision,permissionDecisionReason}}`. Safe approach: detect by `transcript_path`; when ambiguous, emit BOTH (extra keys are ignored by each).
- **CRITICAL SAFETY**: a PreToolUse hook that throws / exits non-zero makes Copilot **fail-closed → DENY EVERY TOOL CALL → brick the session**. The script MUST wrap everything and ALWAYS `process.exit(0)`; on any parse/IO/unknown error → allow (emit nothing). matcher `*` fires on every tool incl. `report_intent` — default MUST be allow.
- **SessionStart on Copilot = BY DESIGN, not a bug** (corrected after user clarification): the existing `SessionStart` hook's `command`+`args` form is inert on Copilot so `inject-manager-role.mjs` no-ops (harmless "code 1"; SessionStart errors don't block tools). Manager-role auto-injection is Claude-Code-only — Copilot users pre-select the manager agent via a startup alias, so it isn't needed on Copilot. No fix warranted (silencing the log line would be cosmetic only). Initially mis-flagged as a fast-follow; withdrawn.

## FINAL CONTROL SET (after MR !57 review — user, 2026-06-18)
Two rounds of user feedback reshaped the enforced set. **Final = `no-pipe-to-shell` + `secret-in-write`.**
- **NO blanket curl/wget block**: the initial settings.json `Bash(curl:*)`/`Bash(wget:*)` denies are REMOVED — this team does heavy API-development work, so blanket-blocking curl/wget is a non-starter. The hook's `no-pipe-to-shell` rule (only `curl … | sh`-class RCE; never bare/API curl) is the sole enforcement for that risk, harness-portable.
- **NO self-merge/approve control**: REMOVED entirely (hook rule + both MCP settings.json denies + the unused MCP-leaf normalization). GitLab enforces approval/protected-branch/author-can't-approve rules SERVER-SIDE at the API layer, applying equally to UI/API/MCP calls — so blocking those tools removed legitimate capability (merging an already-approved MR, approving a teammate's MR) for zero security benefit. security.md now records it as deliberately-not-enforced-here with that rationale.
- **NEW `secret-in-write`** (user chose pipe-to-shell + secret-scan): denies `Write`/`Edit`/`NotebookEdit` whose content matches tight real-token-shaped credential patterns (GitLab/GitHub/Slack/AWS/Google/Atlassian tokens, PEM private keys). Scoped to file-WRITE content ONLY — NEVER Bash — so tokens passed to API calls via curl headers are unaffected (the exact API-dev friction the user rejected). Maps to ADR-006 (credentials-as-placeholders) + RFC residual-radius rec #3 (secret-scan gate). The audit log records secret denials WITHOUT the matched value (logs only the pattern name) — verified adversarially.
- `.claude/settings.json` deny key now REMOVED entirely (empty); only `permissions.allow` remains.

## Decision — merge=union for retrospective files, AS A PLUGIN FEATURE (user, 2026-06-18, folded into MR !57)
`.gitattributes` gives retrospective logs a `merge=union` driver so concurrent appends merge cleanly. Both conflict surfaces verified in a scratch repo: `retrospectives.md` top-prepend AND `retrospectives-archive.md` end-append both CONFLICT under default merge; union → clean, both entries retained (transient over-cap self-heals on next append). Chose union over per-entry-files (heavier refactor) given current single-maintainer-sequential reality.
- **Pattern = BASENAMES** (`retrospectives.md`, `retrospectives-archive.md`), not anchored paths — git matches a slash-less pattern at any depth, so ONE repo-root `.gitattributes` covers every `.context/` dir in single-project, monorepo, multimodule, and workspace layouts. Written at `git rev-parse --show-toplevel`, idempotently.
- **Made a plugin feature** (user, second ask): `icon-init` sets it up (via `context-specialist-impl-leaf` Step 3b + `context-specialist-impl-root` Step 13b, after hook wiring); `upgrade-repo` migrates existing repos (Phase 1 audit + Phase 2 idempotent grep-before-append step + Phase 4 verify). NOT `context_template/` (root-level setup is imperative, like the git-hook wiring) → no template-version bump. This repo's own `.gitattributes` switched to the basename form to dogfood exactly what ships.
- `.gitattributes` was previously untracked here — now `git add`-ed so the plugin ships/dogfoods it.

## Enforced-control set (highest-risk, each maps to existing prose — "moving prose to harness", not new policy)
- **No self-merge / self-approve**: deny `merge_merge_request`, `approve_merge_request` (maps to manager Task-Completion prose; today only GitLab server-side stops it). HIGH, exact tool names.
- **Bash exfil / pipe-to-shell**: block `curl … | sh`, `wget … | sh` and bare `curl`/`wget` to remote (maps to #39 injection defense + RFC Q9 host-bash deny-list). HIGH.
- **Audit log**: hook appends one JSONL line per intercepted tool call to a local audit log (satisfies "retain tool-use logs" + gives the monitoring surface). Path + gitignore decided in spec.
- (Architect to confirm/trim final set; keep it tight and prose-backed.)

## Key Files (provisional — architect to finalize exact edits)
- hooks/guardrail-pretooluse.mjs: CREATE — shared dual-harness PreToolUse hook (deny set + audit log; Node built-ins only). snake_case input on both; output by `transcript_path` detection; ALWAYS exit 0 (fail-open) so it can never brick a Copilot session.
- hooks/hooks.json: CHANGE — add ONE `PreToolUse` entry (matcher `*`) carrying BOTH `command`+`args` (Claude) AND `bash` (Copilot) fields, both invoking `${CLAUDE_PLUGIN_ROOT}/hooks/guardrail-pretooluse.mjs`. Preserve existing SessionStart. NO separate Copilot file.
- (DROPPED) ~~.github/hooks/guardrail.json~~ — empirically unnecessary; the plugin `hooks/hooks.json` is loaded by Copilot directly.
- .claude/settings.json: CHANGE — add `permissions.deny` for the two MCP self-merge/approve tools only (Claude-Code defense-in-depth). NO curl/wget bash denies — see decision below.
- .context/standards/security.md: CHANGE — append `## Harness-Enforced Controls` (portable spec: control → action → Copilot mechanism → Claude Code mechanism → enforcement boundary re subagents) + a `## Monitoring & Tuning` subsection.
- skills/task-retrospective/scripts/append-retrospective-entry.sh + .ps1
- skills/context-maintenance/scripts/append-retrospective-entry.sh + .ps1
- skills/post-incident-review/scripts/append-retrospective-entry.sh + .ps1: CHANGE (all 6, byte-identical) — archive dropped entries to `.context/retrospectives-archive.md` before truncating.
- CHANGELOG.md: CHANGE — Unreleased entry.
- .context/rules-index.md: VERIFY — security row already added in #39; only touch if the new section needs its own discoverability row.
- .gitignore: VERIFY/CHANGE — if the audit log writes inside the repo, ignore it.

## Progress
- [x] Create branch + task folder + initial plan.md
- [x] Read-only Explore — hook/settings/retrospective-pruning/ADR recon (findings in Decisions)
- [x] @researcher — Copilot CLI enforcement capabilities (cache doc written; portable path = shared preToolUse hook; no Copilot declarative deny-list; subagent caveat #2392)
- [x] @architect exact-edit-spec — delivered (control set, hook I/O, audit-log path `~/.icon/`, retro-archive awk/ps1, security.md sections). Approved-with-mods: narrowed bash rule to pipe-to-shell only; excluded destructive-delete denies; flagged Copilot plugin-root as needs-verify.
- [x] @researcher (round 2) — Copilot plugin hook shipping mechanism (cache updated)
- [x] LIVE empirical verification on Copilot CLI 1.0.63 — see EMPIRICAL VERIFICATION section; overrides the architect's `.github/hooks` + camelCase + fail-closed-default assumptions
- [x] @coder applies edits per verified spec — 6 files (hook script, hooks.json, settings.json, 6 retro scripts byte-synced, security.md, rules-index); all fixtures + parity + archive-behavior verified
- [x] Live re-test of the REAL guardrail hook on Copilot CLI 1.0.63 (patched installed plugin, restored): benign `echo` ALLOWED (no bricking); `wget|sh` DENIED end-to-end (audit log: harness=copilot, rule=no-pipe-to-shell) and agent adapted to download→inspect→run; harness detection + audit logging confirmed
- [x] @reviewer checkpoint — APPROVE, 0 Critical/Moderate. Fail-open invariant + byte-parity held under adversarial testing. One Minor (MCP-leaf regex underscore limitation) fixed; one Nit (powershell) left as harmless.
- [x] Minor fix — MCP-leaf regex `^mcp__[^_]+__(.+)$` → `^mcp__.+?__(.+)$` (handles underscore-containing server names like `mcp__claude_ai_Gmail__`); re-verified gitlab merge still denies, claude_ai allows
- [x] changelog-entry — Added (guardrail hook) + Changed (retrospective archiving) under [Unreleased]
- [x] Reconcile plan.md
- [ ] Retrospective (two-stage) ← IN PROGRESS
- [x] Commit + push + open MR — retro/promotion in 7fe1bd2; deliverables in fcf1d9c; MR !57 opened (label security, remove_source_branch)
- [ ] PAUSE — awaiting user go-ahead to merge !57 → wait pipeline → delete branch → next item (#41)

## Review Checkpoint
**gitattributes-as-plugin-feature (2026-06-18):** @reviewer APPROVE, 0 Critical/Moderate — independently verified the embedded bash block is byte-identical across the 3 skills (leaf/root/upgrade), idempotent (fresh double-run + append-to-existing incl. no-trailing-newline edge), basename pattern resolves at depth (`git check-attr` on nested `.context/`), and the union driver merges concurrent top-prepend + end-append cleanly. `context_template/` untouched (no template bump); dispatchers untouched. Two optional notes (not-in-git-repo failure mode — consistent with existing hook-wiring assumption; cosmetic leaf "Step 3b" anchor) — not fixed.

**MR !57 review revision (2026-06-18):** after the user's two corrections, @coder removed the self-merge control + added `secret-in-write` and removed the curl/wget denies; @reviewer RE-REVIEWED the delta → APPROVE, 0 Critical/Moderate, with adversarial confirmation of the fail-open and never-log-the-secret invariants (incl. a cross-field test proving write content cannot reach the audit log). Live re-tested on Copilot CLI 1.0.63: `glpat-` token write DENIED (audit `pattern:gitlab-pat`, no value), benign write ALLOWED. Changed files this round: hook, settings.json, security.md, CHANGELOG (retro scripts + hooks.json untouched).

---
**Initial checkpoint:** @reviewer APPROVED the full diff (hook script, hooks.json, settings.json, 6 byte-synced retro scripts, security.md, rules-index.md) with 0 Critical/Moderate, after independently re-running every hook fixture + adversarial fail-open cases and `diff -q` byte-parity. The only post-checkpoint edit was the reviewer-requested Minor (MCP-leaf regex), re-verified by the fixing coder — so this checkpoint covers the complete changed-file set; no new @coder/@tester work after this stamp. Independently re-confirmed live on Copilot CLI 1.0.63: benign allowed, pipe-to-shell denied end-to-end.

## Open Questions / Blockers
- Copilot subagent enforcement (#2392) unresolved on current GA — treat top-level enforcement as the guarantee, prose as subagent backstop. Verify behavior is documented, not assumed.
- Audit-log location: in-repo (gitignored) vs. user dir (`~/.copilot/`-style). Architect to decide; must not commit session logs.

## Constraints
- ICON is pure-content (no compile/test/package manager) — ADR-005. New hook must be a committed run-in-place Node script using built-ins only (the ADR-005-sanctioned pattern; matches `inject-manager-role.mjs`).
- Tool-agnostic content — ADR-004. Hook layer is the sanctioned Claude-Code/Copilot-specific exception; agent/skill markdown stays portable. Ship per-harness registration files.
- `.claude-plugin/plugin.json` is the version SSOT — ADR-003.
- ADR-008 token budget: hooks/settings.json run out-of-band → no session-token impact. security.md is on-demand reference, not always-loaded.
- If any file under context_template/ changes, bump its template-version (ADR-044 gate) — verify whether retrospective scripts or security.md are mirrored there.
