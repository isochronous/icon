# MCP Servers in the ICON Plugin

## What This Is

The ICON plugin bundles MCP server configuration in `.mcp.json` at the repo root. Both the Copilot CLI and Claude Code plugin formats support a `mcpServers` key in their `plugin.json` manifests, pointing to this file. The plugin ships the server structure; users supply only their credentials via environment variables.

## How It Works

Both platforms auto-discover `.mcp.json` at the plugin root. The `.claude-plugin/plugin.json` manifest declares:

```json
"mcpServers": "./.mcp.json"
```

**Important**: Claude Code requires component path strings to start with `./`. The value `".mcp.json"` (without the leading `./`) fails Claude's schema validation with `mcpServers: Invalid input`. The correct form is `"./.mcp.json"`.

At install time, Copilot CLI and Claude Code register the servers defined in `.mcp.json`. At startup, `${VAR}` placeholders in the `env` block are resolved from the process environment.

## Credential Pattern — `${VAR}` Substitution

All credentials in `.mcp.json` use placeholder syntax:

```json
"env": {
  "GITLAB_PERSONAL_ACCESS_TOKEN": "${GITLAB_PERSONAL_ACCESS_TOKEN}"
}
```

**This is the only correct approach.** Never commit real credentials. The `setup-mcp-servers` skill guides users to export the required env vars from their shell profile.

**Copilot CLI has no global env-injection block in `mcp-config.json`.** There is no top-level `env` key or `mcpServers.env` shortcut that injects variables across all servers. Per-server `env` in `.mcp.json` + shell profile export is the only working approach. Do not document alternatives that don't exist.

## Version Pinning (Required)

Pin package versions for any MCP server that receives credentials:

```json
"args": ["-y", "@zereight/mcp-gitlab@2.0.36"]    // npm — pin with @version
"args": ["mcp-atlassian==0.21.0"]                 // uvx/pip — pin with ==version
```

Unpinned packages silently pull latest on every startup. A compromised package version would gain access to all stored credentials with no notification. Version bumps are deliberate tasks, not automatic upgrades.

## Bundled Servers

| Server | Package | Command | Credentials |
|--------|---------|---------|-------------|
| `gitlab` | `@zereight/mcp-gitlab` | `npx -y` | `GITLAB_PERSONAL_ACCESS_TOKEN`, `GITLAB_API_URL` |
| `atlassian` | `mcp-atlassian` | `uvx` | `JIRA_URL`, `JIRA_USERNAME`, `JIRA_API_TOKEN`, `CONFLUENCE_URL`, `CONFLUENCE_USERNAME`, `CONFLUENCE_API_TOKEN` |

## Platform Differences

| Feature | Copilot CLI | Claude Code |
|---------|-------------|-------------|
| `mcpServers` in plugin.json | ✅ | ✅ |
| Auto-discovers `.mcp.json` | ✅ | ✅ |
| `${CLAUDE_PLUGIN_ROOT}` variable | ❌ | ✅ |
| Multiple config files (array) | ❌ | ✅ |
| Global env block in mcp-config.json | ❌ | n/a |

## Setup Skill

Users run `/setup-mcp-servers` after install. The skill covers prerequisites (Node.js/npx for GitLab, uv/uvx for Atlassian), all eight required env vars with examples, shell profile export instructions, and verification steps for each platform.
