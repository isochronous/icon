---
name: find-context-template
description: >
  Internal context initialization skill. Do not invoke without explicit direction.
user-invocable: false
---

# Find Context Template

Locate the `context_template/` directory within the current tool's plugin install path and set `$TEMPLATE_DIR` for use in subsequent copy commands.

This skill is also a **callable primitive** for plugin-asset discovery. Other ICON skills that need the resolved plugin install path should invoke this skill rather than re-implementing `${CLAUDE_PLUGIN_ROOT}` / Copilot-install-path resolution inline. Calling skills follow the standard Read-and-Use pattern: read this `SKILL.md`, run the appropriate Discovery Command block for the active tool, then use `$TEMPLATE_DIR` (or its parent for non-template assets) in their own commands. The invocation shape is `$TEMPLATE_DIR`-out; no arguments are passed in.

## Marketplace Name

The Copilot CLI install path includes the marketplace's folder name. By default this is `icon-marketplace` (the canonical ICON marketplace). Organizations that fork the marketplace under a different slug can override the default by exporting `MARKETPLACE_NAME` before running ICON skills (or by editing the default in their fork of this file):

```bash
export MARKETPLACE_NAME="my-org-marketplace"
```

```powershell
$env:MARKETPLACE_NAME = "my-org-marketplace"
```

The Discovery Commands below honor `$MARKETPLACE_NAME` when set and fall back to `icon-marketplace` otherwise. Claude Code variants do not need this — `${CLAUDE_PLUGIN_ROOT}` already resolves the full install path regardless of marketplace slug.

## Discovery Command

### Copilot CLI (Bash / zsh)

```bash
# Override via `MARKETPLACE_NAME=<your-marketplace-slug>` env var, or edit this line in forks.
[ -n "${MARKETPLACE_NAME+x}" ] || MARKETPLACE_NAME="icon-marketplace"
TEMPLATE_DIR="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins/${MARKETPLACE_NAME}/ICON/context_template"
```

### Copilot CLI (PowerShell)

```powershell
# Override via `MARKETPLACE_NAME=<your-marketplace-slug>` env var, or edit this line in forks.
$CopilotHome = if ($env:COPILOT_HOME) { $env:COPILOT_HOME } else { "$HOME/.copilot" }
$MarketplaceName = if ($env:MARKETPLACE_NAME) { $env:MARKETPLACE_NAME } else { "icon-marketplace" }
$TEMPLATE_DIR = "$CopilotHome/installed-plugins/$MarketplaceName/ICON/context_template"
```

### Claude Code (Bash / zsh)

```bash
TEMPLATE_DIR="${CLAUDE_PLUGIN_ROOT}/context_template"
```

### Claude Code (PowerShell)

```powershell
$TEMPLATE_DIR = "$env:CLAUDE_PLUGIN_ROOT/context_template"
```

## If the Result Is Empty or the Path Does Not Exist

### Copilot CLI

`$TEMPLATE_DIR` is always assigned a string — checking for an empty variable is not meaningful. Instead, verify that the path exists on disk:

**Bash / zsh:**
```bash
[ ! -d "$TEMPLATE_DIR" ] && echo "Template not found at: $TEMPLATE_DIR"
```

**PowerShell:**
```powershell
if (-not (Test-Path $TEMPLATE_DIR)) { Write-Host "Template not found at: $TEMPLATE_DIR" }
```

If the path does not exist, the plugin may not be installed or may be at a non-standard location. Ask the user to verify:

```bash
copilot plugin list
```

### Claude Code

`$CLAUDE_PLUGIN_ROOT` may be unset if the plugin runtime did not inject it, making `$TEMPLATE_DIR` empty or null. Check for that before using it:

**Bash / zsh:**
```bash
[ -z "$TEMPLATE_DIR" ] && echo "CLAUDE_PLUGIN_ROOT is not set — plugin runtime may not have injected it"
```

**PowerShell:**
```powershell
if (-not $env:CLAUDE_PLUGIN_ROOT) { Write-Host "CLAUDE_PLUGIN_ROOT is not set — plugin runtime may not have injected it" }
```

If the variable is unset, ask the user to verify:

```bash
claude plugin list
```

## After Discovery

Use `$TEMPLATE_DIR` as the source in all subsequent copy commands. Example:

```bash
cp "$TEMPLATE_DIR/context/META.md" .context/
```

```powershell
Copy-Item "$TEMPLATE_DIR/context/META.md" .context/
```
