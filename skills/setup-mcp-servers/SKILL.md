---
name: setup-mcp-servers
description: >
  Use when configuring MCP servers bundled with the ICON plugin, setting up GitLab or Atlassian credentials, or when MCP tools are not loading after plugin installation.
user-invocable: true
---

# Setup MCP Servers

## Overview

The ICON plugin bundles two MCP servers — **GitLab** and **Atlassian** — providing tools for issue tracking, merge requests, Jira, and Confluence. **You do not need to edit any config files.** The plugin supplies the server configuration automatically on install; you only need to set environment variables with your credentials.

## Bundled Servers

| Server | Package | Tools Provided |
|--------|---------|----------------|
| `gitlab` | `@zereight/mcp-gitlab` (via `npx`) | Issues, MRs, pipelines, wikis, CI/CD |
| `atlassian` | `mcp-atlassian` (via `uvx`) | Jira issues/sprints, Confluence pages/spaces |

---

## setup-mcp-servers: Step 1: Install prerequisites

Each server has a different runtime requirement. Run the checks and install whatever is missing.

### GitLab server — requires Node.js and npx

```bash
node --version
```

If missing, install Node.js from [nodejs.org](https://nodejs.org) or via your OS package manager:

```bash
# macOS (Homebrew)
brew install node

# Ubuntu/Debian
sudo apt install nodejs npm

# Windows (winget)
winget install OpenJS.NodeJS
```

`npx` ships with npm ≥ 5.2 and is available once Node.js is installed. Confirm:

```bash
npx --version
```

### Atlassian server — requires uv (Python package manager)

```bash
uvx --version
```

If missing, install `uv`:

```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows (PowerShell)
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

After install, reload your shell or open a new terminal, then confirm:

```bash
uvx --version
```

---

## setup-mcp-servers: Step 2: Gather credentials

**GitLab** — Create a Personal Access Token at `https://gitlab.com/-/user_settings/personal_access_tokens` with the `api` scope. (For self-hosted GitLab, substitute your instance URL.)

| Variable | Value |
|----------|-------|
| `GITLAB_PERSONAL_ACCESS_TOKEN` | Your PAT, starting with `glpat-` |
| `GITLAB_API_URL` | Your GitLab root URL, e.g. `https://gitlab.com` |

**Atlassian** — Create an API token at `https://id.atlassian.com/manage-profile/security/api-tokens`. One token works for both Jira and Confluence.

| Variable | Value |
|----------|-------|
| `JIRA_URL` | e.g. `https://yourorg.atlassian.net` |
| `JIRA_USERNAME` | Your Atlassian account email |
| `JIRA_API_TOKEN` | Your API token |
| `CONFLUENCE_URL` | e.g. `https://yourorg.atlassian.net` (often same as `JIRA_URL`) |
| `CONFLUENCE_USERNAME` | Your Atlassian account email (same as `JIRA_USERNAME`) |
| `CONFLUENCE_API_TOKEN` | Same API token as `JIRA_API_TOKEN` |

---

## setup-mcp-servers: Step 3: Set environment variables

### Shell profile setup (persistent, works everywhere)

Add the following to `~/.zshrc`, `~/.bashrc`, or `~/.bash_profile` (whichever your shell uses), substituting real values:

```bash
# GitLab MCP
export GITLAB_PERSONAL_ACCESS_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx"
export GITLAB_API_URL="https://gitlab.com"

# Atlassian MCP
export JIRA_URL="https://yourorg.atlassian.net"
export JIRA_USERNAME="you@example.com"
export JIRA_API_TOKEN="your-api-token"
export CONFLUENCE_URL="https://yourorg.atlassian.net"
export CONFLUENCE_USERNAME="you@example.com"
export CONFLUENCE_API_TOKEN="your-api-token"
```

Reload immediately without opening a new terminal:

```bash
source ~/.zshrc      # zsh users
# or
source ~/.bashrc     # bash users
```

## setup-mcp-servers: Step 4: Verify the servers started

Restart your AI tool (Copilot CLI or Claude Code) after setting env vars — they are read at startup.

**Copilot CLI:**

```
/mcp show
```

Both `gitlab` and `atlassian` should appear with a running status.

**Claude Code:**

Open the MCP panel (bottom status bar → "MCP", or `Cmd/Ctrl+Shift+P` → "MCP"). Both servers should show a green indicator.

### If a server shows an error

1. **Confirm the env vars are visible in the current session:**
   ```bash
   echo $GITLAB_PERSONAL_ACCESS_TOKEN   # should print your token
   echo $JIRA_URL                        # should print your Jira URL
   ```
   If blank, the vars are not exported. Re-source your profile.

2. **Confirm the runtime is on your PATH:**
   ```bash
   which npx    # GitLab server
   which uvx    # Atlassian server
   ```
   If either is missing, return to Step 1.

3. **Reconnect without restarting:**
   - Copilot CLI: `/mcp reconnect`
   - Claude Code: reload the MCP panel

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Vars set in a new terminal tab without reloading | `source ~/.zshrc` or open a new shell after editing the profile |
| Using Atlassian account password instead of API token | API tokens only — create one at `id.atlassian.com` |
| `uvx` not found after installing `uv` | Open a new terminal — the install script updates PATH for new shells only |
| Server listed but no tools appear | `/mcp reconnect` in Copilot CLI, or reload Claude Code's MCP panel |
| Self-hosted GitLab URL includes a trailing slash | Use `https://gitlab.example.com` not `https://gitlab.example.com/` |
| Confluence and Jira using different tokens | One API token covers both — use the same value for all four Atlassian vars |
