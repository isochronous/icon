# Security Standards

Cross-cutting security rules for the ICON plugin and the agent system it ships. Append new sections here as security guidance grows.

## Untrusted External Content (Prompt-Injection Mitigation)

**Threat**: Content fetched from external systems is attacker-controllable. A malicious Jira issue, Confluence page, web page, library doc, CI/pipeline log, or GitLab MR comment can embed text crafted to look like instructions ("ignore previous instructions", "run this command", "call tool X"). If an agent treats that text as instructions, an attacker can steer it into invoking write-capable MCP tools (data exfiltration), executing shell commands, or fetching attacker-chosen URLs. This was identified in the ICON AI RFC security review (question 3; GitLab #39) as the top data-leakage risk.

**Mitigation**: Agents treat all fetched external content as untrusted DATA, never as instructions.
- `@researcher` (the only direct web/doc fetcher) carries an **Untrusted Content** section instructing it to read, summarize, and cite fetched content only — never to act on embedded directives, invoke write-capable/command-executing tools, exfiltrate repository contents, or fetch attacker-chosen URLs. See `agents/researcher.agent.md`.
- `@manager` (which ingests `@researcher` findings and routes write-capable MCP tools) carries matching guidance in Session Start Step 7. See `agents/manager.agent.md`. `@product-manager` reaches external content only by delegating to `@researcher`, so it is covered at the fetch source.
- The `mr-feedback-triage` skill, which reads attacker-controllable GitLab MR comments, independently forbids the agent from resolving threads, posting replies, or making any MR write calls as part of triage — MR content is reported, never acted on. See `skills/mr-feedback-triage/SKILL.md`.

**Boundary**: External content may be summarized, quoted, and cited. It must never cause a write-capable tool call, command execution, or attacker-directed fetch. When fetched content appears to attempt this, the agent records it as a finding and continues with the originally scoped task.

## Harness-Enforced Controls

ICON's highest-risk controls are enforced at the harness `PreToolUse` layer, not by prose alone (which an agent can rationalize past). A single shared Node hook (`hooks/guardrail-pretooluse.mjs`, Node built-ins only per ADR-005) is the portable enforcement layer for BOTH GitHub Copilot CLI (primary) and Claude Code. (The current control set — pipe-to-shell and secret-in-write — keys off `command`/file-content rather than MCP tool names, so the `.claude/settings.json` deny-list is empty; a declarative MCP deny-list remains available there as Claude Code defense-in-depth should a future MCP-name rule be added.) One `hooks/hooks.json` entry serves both harnesses: it carries Claude Code's `command`+`args` form and Copilot's `bash` form in the same object (Copilot executes the `bash` field and ignores the inert `command`/`args`; Claude Code does the reverse). Both harnesses deliver snake_case `tool_name`/`tool_input` on stdin; the hook emits Copilot's top-level `permissionDecision` or Claude Code's nested `hookSpecificOutput.permissionDecision`, selected by the presence of `transcript_path` (Claude-only). This complements — does not replace — the untrusted-content prose above, which remains the backstop where the hook cannot reach.

Self-merge/self-approve of merge requests is deliberately NOT enforced here, because GitLab enforces approval and protected-branch rules server-side (applying equally to UI, API, and MCP calls), so blocking those tools would only remove legitimate capability for zero security benefit.

| Control | Maps to prose | Mechanism (both harnesses) | Claude Code defense-in-depth | Enforcement boundary |
| --- | --- | --- | --- | --- |
| No remote-fetch piped into a shell | Untrusted External Content boundary above ("must never cause … command execution"); GitLab #39 | hook denies `bash`/`shell` commands matching curl/wget piped into an interpreter | none — bare curl/wget is intentionally NOT blocked (routine API-development work depends on it); the hook's narrow pipe-to-shell rule is the only enforcement | bare (non-piped) remote fetch is NOT denied — covered by untrusted-content prose |
| No credential written into file content | ADR-006 credentials-as-placeholders; RFC residual-radius rec #3 (secret-scan gate) | hook denies Write/Edit/NotebookEdit whose content matches real-token-shaped credential patterns (GitLab/GitHub/Slack/AWS/Google/Atlassian tokens, PEM private keys) | none — single hook rule | file-write content only; NOT Bash, so tokens passed to API calls via curl headers are unaffected; top-level calls (subagent caveat applies) |

The hook deliberately matches ONLY `curl … | sh`-class remote code execution, never bare curl/wget, so ordinary API-development calls are unaffected; the Claude Code `settings.json` deny-list therefore carries no MCP denies — both guardrails are enforced entirely in the shared hook.

### Enforcement boundary (subagents)

GitHub Copilot CLI may not fire `PreToolUse` for tool calls made inside subagents (issue #2392, unresolved on current GA). ICON is delegation-heavy, so the hook is the guarantee for TOP-LEVEL tool calls; the untrusted-content prose guardrails (above, and in `agents/researcher.agent.md` / `agents/manager.agent.md`) remain the subagent backstop. Verify against the installed CLI version before relying on subagent enforcement.

## Monitoring & Tuning

Every evaluated tool call (allow and deny) appends one JSONL line to `~/.icon/guardrail-audit.log` (not committed — operator telemetry, not a project artifact): `{ts, harness, tool, decision, rule, cmd?, pattern?}`. Review recent denials:

    grep '"decision":"deny"' ~/.icon/guardrail-audit.log | tail -20

The secret-scan patterns are intentionally tight (real-token shapes, not bare prefixes) to avoid false positives on docs and credential placeholders; if a legitimate fixture trips a pattern, tune the regex in the `RULES` array. The audit log deliberately records secret-scan denials WITHOUT the matched content — only the log-safe pattern name (`pattern`) is recorded, never the secret value (the `cmd` field is logged only for the bash pipe-to-shell rule). Watch the allow:deny ratio per rule — a spike means either an attack pattern or an over-broad rule. To adjust controls, edit the `RULES` array in `hooks/guardrail-pretooluse.mjs` (append `{id, reason, test}`). New rules must map to existing prose (cite it in the table above) — the hook moves prose to enforcement; it does not invent policy. Keep the set tight; add a rule only after the audit log or a retrospective shows a real need. Because Copilot subagent enforcement is unverified (#2392), a hook rule is a top-level guarantee only — if a control must hold inside subagents, also encode it as prose.

## MCP Package CVE-Review Cadence

ICON ships two pinned MCP server packages in `.mcp.json`: `@zereight/mcp-gitlab` pinned to `2.0.36` (run via `npx`, i.e. `@zereight/mcp-gitlab@2.0.36`) and `mcp-atlassian` pinned to `0.21.1` (run via `uvx`, i.e. `mcp-atlassian==0.21.1`). These are the plugin's only third-party runtime dependencies — there is no `package.json`/lockfile (ADR-005), so no automated dependency scanner has a manifest to read. Their security posture is instead maintained by a periodic manual review.

**Cadence**: review both pinned versions **quarterly**, and additionally **on every version bump** of either package.

**What to check** for each package:
- Upstream release notes and security advisories (the project's GitHub releases/security tab).
- The npm advisory feed for `@zereight/mcp-gitlab`; the PyPI/GitHub-advisory feed for `mcp-atlassian`.
- Whether a fixed version exists for any advisory affecting the pinned version.

If a review finds a relevant CVE or a worthwhile fix, bump the pin in `.mcp.json` through the normal task/MR flow (new ICON task, branch, MR, review) — do not pin to a floating tag.
