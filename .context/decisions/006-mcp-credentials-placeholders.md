# ADR-006: MCP credentials use `${VAR}` placeholders only — never committed

**Date**: 2026-04-06
**Status**: Superseded by ICON-0080 (MCP servers removed)

> **Superseded (2026-06-20, ICON-0080).** This ADR governed credential handling for the
> bundled MCP servers in `.mcp.json` (GitLab + Atlassian). The GitHub-only conversion
> removed both servers and deleted `.mcp.json` entirely — the plugin ships no MCP servers
> and no credential placeholders. GitHub access is now via the `gh` CLI, which manages its
> own auth outside this repo. The `${VAR}`-placeholder rule below is therefore moot. The
> never-commit-real-credentials principle survives as a general secure-coding rule (see
> `standards/secure-coding.md` and the secret-in-write guardrail in `standards/security.md`);
> this record is retained to explain why `.mcp.json` never carried inline tokens.

## Context

`.mcp.json` defines MCP server entries with credentials (`GITLAB_PERSONAL_ACCESS_TOKEN`, `JIRA_API_TOKEN`, etc.). A naive setup would inline tokens for "easier first-run setup" — and immediately leak them on the first push.

## Decision

All credentials in `.mcp.json` use `${ENV_VAR}` placeholder syntax, resolved by the runtime at server-start time from the user's shell environment. Users export the required vars from their shell profile; the `setup-mcp-servers` skill walks them through it. Real credentials are **never** committed to this repo. (The `domains/mcp-servers.md` doc that described the full credential pattern was removed in ICON-0080; see `domains/github-access.md` for the current GitHub-access model.)

## Consequences

**Positive:**
- Credential leak via this repo is structurally prevented; `.mcp.json` carries no secrets.
- Multiple users sharing the plugin can each supply their own tokens.
- Version-pinning packages (e.g., `@zereight/mcp-gitlab@2.0.36`) is enforced because unpinned packages would auto-update and inherit existing token grants without notice.

**Negative:**
- First-run setup requires shell-profile edits — covered by the `setup-mcp-servers` skill.
- Copilot CLI has no global env-injection block in `mcp-config.json`; per-server `env` in `.mcp.json` is the only working approach.

## Alternatives Considered

1. **Distribute a `.mcp.local.json` with real values, gitignored**: rejected — too easy to commit by accident; the placeholder pattern fails closed.
2. **Use a secret manager (Vault, 1Password CLI)**: rejected — would impose a hard dependency on a specific tool that not all users have.
