# ADR-006: MCP credentials use `${VAR}` placeholders only — never committed

**Date**: 2026-04-06
**Status**: Accepted

## Context

`.mcp.json` defines MCP server entries with credentials (`GITLAB_PERSONAL_ACCESS_TOKEN`, `JIRA_API_TOKEN`, etc.). A naive setup would inline tokens for "easier first-run setup" — and immediately leak them on the first push.

## Decision

All credentials in `.mcp.json` use `${ENV_VAR}` placeholder syntax, resolved by the runtime at server-start time from the user's shell environment. Users export the required vars from their shell profile; the `setup-mcp-servers` skill walks them through it. Real credentials are **never** committed to this repo. See `domains/mcp-servers.md` for the full credential pattern.

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
