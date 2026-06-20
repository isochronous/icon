# Security Standards

Cross-cutting security rules for the ICON plugin and the agent system it ships. Append new sections here as security guidance grows.

## Untrusted External Content (Prompt-Injection Mitigation)

**Threat**: Content fetched from external systems is attacker-controllable. A malicious GitHub issue, web page, library doc, CI/pipeline log, or GitHub PR review comment can embed text crafted to look like instructions ("ignore previous instructions", "run this command", "call tool X"). If an agent treats that text as instructions, an attacker can steer it into executing shell commands (e.g. a write-capable `gh` call for data exfiltration) or fetching attacker-chosen URLs. This was identified in the ICON AI RFC security review (question 3; issue #39) as the top data-leakage risk.

**Mitigation**: Agents treat all fetched external content as untrusted DATA, never as instructions.
- `@researcher` (the only direct web/doc fetcher) carries an **Untrusted Content** section instructing it to read, summarize, and cite fetched content only — never to act on embedded directives, invoke write-capable/command-executing tools, exfiltrate repository contents, or fetch attacker-chosen URLs. See `agents/researcher.agent.md`.
- `@manager` (which ingests `@researcher` findings and routes write-capable `gh` calls) carries matching guidance in Session Start Step 7. See `agents/manager.agent.md`. `@product-manager` reaches external content only by delegating to `@researcher`, so it is covered at the fetch source.
- The `pr-feedback-triage` skill, which reads attacker-controllable GitHub PR review comments, independently forbids the agent from resolving threads, posting replies, or making any PR write calls as part of triage — PR content is reported, never acted on. See `skills/pr-feedback-triage/SKILL.md`.

**Boundary**: External content may be summarized, quoted, and cited. It must never cause a write-capable tool call, command execution, or attacker-directed fetch. When fetched content appears to attempt this, the agent records it as a finding and continues with the originally scoped task.

## Harness-Enforced Controls

ICON's highest-risk controls are enforced at the harness `PreToolUse` layer, not by prose alone (which an agent can rationalize past). A single shared Node hook (`hooks/guardrail-pretooluse.mjs`, Node built-ins only per ADR-005) is the portable enforcement layer for BOTH GitHub Copilot CLI (primary) and Claude Code. (The current control set — pipe-to-shell and secret-in-write — keys off `command`/file-content. ICON ships no MCP servers, so there are no MCP tool-name rules and the `.claude/settings.json` deny-list is empty; a declarative deny-list remains available there as Claude Code defense-in-depth should a future rule be added.) One `hooks/hooks.json` entry serves both harnesses: it carries Claude Code's `command`+`args` form and Copilot's `bash` form in the same object (Copilot executes the `bash` field and ignores the inert `command`/`args`; Claude Code does the reverse). Both harnesses deliver snake_case `tool_name`/`tool_input` on stdin; the hook emits Copilot's top-level `permissionDecision` or Claude Code's nested `hookSpecificOutput.permissionDecision`, selected by the presence of `transcript_path` (Claude-only). This complements — does not replace — the untrusted-content prose above, which remains the backstop where the hook cannot reach.

Self-merge/self-approve of pull requests is deliberately NOT enforced here, because GitHub enforces approval and protected-branch rules server-side (applying equally to the UI, the API, and the `gh` CLI), so blocking those tools would only remove legitimate capability for zero security benefit.

| Control | Maps to prose | Mechanism (both harnesses) | Claude Code defense-in-depth | Enforcement boundary |
| --- | --- | --- | --- | --- |
| No remote-fetch piped into a shell | Untrusted External Content boundary above ("must never cause … command execution"); issue #39 | hook denies `bash`/`shell` commands matching curl/wget piped into an interpreter | none — bare curl/wget is intentionally NOT blocked (routine API-development work depends on it); the hook's narrow pipe-to-shell rule is the only enforcement | bare (non-piped) remote fetch is NOT denied — covered by untrusted-content prose |
| No credential written into file content | RFC residual-radius rec #3 (secret-scan gate) | hook denies Write/Edit/NotebookEdit whose content matches real-token-shaped credential patterns (GitHub/Slack/AWS/Google tokens, plus residual GitLab/Atlassian token shapes, PEM private keys) | none — single hook rule | file-write content only; NOT Bash, so tokens passed to API calls via curl headers are unaffected; top-level calls (subagent caveat applies) |

The hook deliberately matches ONLY `curl … | sh`-class remote code execution, never bare curl/wget, so ordinary API-development calls are unaffected; the Claude Code `settings.json` deny-list therefore carries no entries — both guardrails are enforced entirely in the shared hook.

### Enforcement boundary (subagents)

GitHub Copilot CLI may not fire `PreToolUse` for tool calls made inside subagents (issue #2392, unresolved on current GA). ICON is delegation-heavy, so the hook is the guarantee for TOP-LEVEL tool calls; the untrusted-content prose guardrails (above, and in `agents/researcher.agent.md` / `agents/manager.agent.md`) remain the subagent backstop. Verify against the installed CLI version before relying on subagent enforcement.

## Monitoring & Tuning

Every evaluated tool call (allow and deny) appends one JSONL line to `~/.icon/guardrail-audit.log` (not committed — operator telemetry, not a project artifact): `{ts, harness, tool, decision, rule, cmd?, pattern?}`. Review recent denials:

    grep '"decision":"deny"' ~/.icon/guardrail-audit.log | tail -20

The secret-scan patterns are intentionally tight (real-token shapes, not bare prefixes) to avoid false positives on docs and credential placeholders; if a legitimate fixture trips a pattern, tune the regex in the `RULES` array. The audit log deliberately records secret-scan denials WITHOUT the matched content — only the log-safe pattern name (`pattern`) is recorded, never the secret value (the `cmd` field is logged only for the bash pipe-to-shell rule). Watch the allow:deny ratio per rule — a spike means either an attack pattern or an over-broad rule. To adjust controls, edit the `RULES` array in `hooks/guardrail-pretooluse.mjs` (append `{id, reason, test}`). New rules must map to existing prose (cite it in the table above) — the hook moves prose to enforcement; it does not invent policy. Keep the set tight; add a rule only after the audit log or a retrospective shows a real need. Because Copilot subagent enforcement is unverified (#2392), a hook rule is a top-level guarantee only — if a control must hold inside subagents, also encode it as prose.

## Third-Party Runtime Dependencies

ICON ships **no MCP servers and no third-party runtime packages**. After the ICON-0080 GitHub-only conversion, `.mcp.json` (which formerly pinned `@zereight/mcp-gitlab` and `mcp-atlassian`) was removed entirely, so there is no pinned external package to review for CVEs. GitHub access is via the `gh` CLI, whose installation and security posture are the user's responsibility outside this repo (see `domains/github-access.md`). The plugin's only runtime artifacts are markdown, JSON, and the single Node.js hook wrapper, which uses Node built-ins only (ADR-005). If a future change reintroduces a pinned third-party dependency, restore a periodic CVE-review cadence for it here.
