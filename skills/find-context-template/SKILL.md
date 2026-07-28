---
name: find-context-template
description: >
  Internal context initialization skill. Do not invoke without explicit direction.
user-invocable: false
---

# Find Context Template

Locate the `context_template/` directory within the current tool's plugin install path and set `$TEMPLATE_DIR` for subsequent copy commands.

This skill is also a **callable primitive** for plugin-asset discovery. Other ICON skills needing the resolved plugin install path should invoke it rather than re-implementing `${CLAUDE_PLUGIN_ROOT}` / Copilot-install-path resolution inline. Calling skills follow the standard Read-and-Use pattern: read this `SKILL.md`, run the Discovery Command block for the active tool, then run the **mandatory `## Validate` block** for that same tool and **halt if it exits non-zero** — only after it passes may they use `$TEMPLATE_DIR` (or its parent for non-template assets) in their own commands. The Validate block is a required step of this skill, not optional troubleshooting; a caller that skips it proceeds on an unresolved path. Invocation shape: `$TEMPLATE_DIR`-out, no arguments in.

## Marketplace Name

The Copilot CLI install path includes the marketplace's folder name, by default `icon-marketplace` (the canonical ICON marketplace). Organizations that fork under a different slug can override the default by exporting `MARKETPLACE_NAME` before running ICON skills (or by editing the default in their fork of this file):

```bash
export MARKETPLACE_NAME="my-org-marketplace"
```

```powershell
$env:MARKETPLACE_NAME = "my-org-marketplace"
```

The Discovery Commands below honor `$MARKETPLACE_NAME` when set, else fall back to `icon-marketplace`. Claude Code variants don't need this — `${CLAUDE_PLUGIN_ROOT}` already resolves the full install path regardless of marketplace slug.

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

## Validate (mandatory)

Run the Validate block for the active tool **immediately after its Discovery Command and before any use of `$TEMPLATE_DIR`**. This is a guard, not troubleshooting advice: it exits non-zero when the template did not resolve, and a calling skill MUST halt when it does.

**Test the path `$TEMPLATE_DIR/context`, never the variable `$TEMPLATE_DIR`.** Every Discovery Command above always assigns a non-empty string, so an emptiness test can never fire. With `CLAUDE_PLUGIN_ROOT` unset, `$TEMPLATE_DIR` becomes the non-empty literal `/context_template`, which PowerShell on Windows resolves against the *current drive* (`C:\context_template`) — only a path test catches that. Testing the `context/` subdirectory rather than the root additionally distinguishes "wrong root" from "root exists but is not a template"; `context/` is the subdirectory every caller actually reads from.

### Copilot CLI (Bash / zsh)

```bash
if [ ! -d "${TEMPLATE_DIR-}/context" ]; then
  echo "ERROR: context template not found at: ${TEMPLATE_DIR-<unset>}" >&2
  echo "  COPILOT_HOME=[${COPILOT_HOME-<unset>}] MARKETPLACE_NAME=[${MARKETPLACE_NAME-<unset>}]" >&2
  echo "  Verify the plugin install: copilot plugin list" >&2
  exit 1
fi
```

### Copilot CLI (PowerShell)

```powershell
$CopilotHomeShown = if (Test-Path 'Env:\COPILOT_HOME') { "[$env:COPILOT_HOME]" } else { '[<unset>]' }
$MarketplaceShown = if (Test-Path 'Env:\MARKETPLACE_NAME') { "[$env:MARKETPLACE_NAME]" } else { '[<unset>]' }
$TemplateDirShown = if (Test-Path Variable:\TEMPLATE_DIR) { "[$TEMPLATE_DIR]" } else { '[<unset>]' }
if (-not (Test-Path Variable:\TEMPLATE_DIR) -or [string]::IsNullOrWhiteSpace($TEMPLATE_DIR) -or -not (Test-Path -LiteralPath (Join-Path $TEMPLATE_DIR 'context') -PathType Container)) {
    Write-Error "context template not found at: $TemplateDirShown`n  COPILOT_HOME=$CopilotHomeShown MARKETPLACE_NAME=$MarketplaceShown`n  Verify the plugin install: copilot plugin list"
    exit 1
}
```

### Claude Code (Bash / zsh)

```bash
if [ ! -d "${TEMPLATE_DIR-}/context" ]; then
  echo "ERROR: context template not found at: ${TEMPLATE_DIR-<unset>}" >&2
  echo "  CLAUDE_PLUGIN_ROOT=[${CLAUDE_PLUGIN_ROOT-<unset>}]" >&2
  echo "  Verify the plugin install: claude plugin list" >&2
  exit 1
fi
```

### Claude Code (PowerShell)

```powershell
$PluginRootShown = if (Test-Path 'Env:\CLAUDE_PLUGIN_ROOT') { "[$env:CLAUDE_PLUGIN_ROOT]" } else { '[<unset>]' }
$TemplateDirShown = if (Test-Path Variable:\TEMPLATE_DIR) { "[$TEMPLATE_DIR]" } else { '[<unset>]' }
if (-not (Test-Path Variable:\TEMPLATE_DIR) -or [string]::IsNullOrWhiteSpace($TEMPLATE_DIR) -or -not (Test-Path -LiteralPath (Join-Path $TEMPLATE_DIR 'context') -PathType Container)) {
    Write-Error "context template not found at: $TemplateDirShown`n  CLAUDE_PLUGIN_ROOT=$PluginRootShown`n  Verify the plugin install: claude plugin list"
    exit 1
}
```

**Never write the bash guard as `[ ! -d "$TEMPLATE_DIR/context" ] && echo …`.** That form exits **1 when the directory exists**: the `[` fails, `&&` short-circuits, and the list's status is the `[`'s status — so a caller running under `set -euo pipefail` aborts on the *success* path. Appending `&& exit 1` does not repair it. Only the `if … then … exit 1; fi` form above is safe.

### If validation fails

The plugin is not installed where the runtime says it is, or the runtime did not inject its plugin-root variable. The diagnostic distinguishes the two: `<unset>` means the variable was never injected (POSIX presence form `${VAR-<unset>}`; `Test-Path Env:\VAR` in PowerShell — `${VAR:-…}` and a bare `if ($env:VAR)` cannot tell unset from set-but-empty), while a printed value means it was injected but points somewhere wrong. Report the diagnostic to the user, ask them to confirm the install with `claude plugin list` / `copilot plugin list`, and stop — never fall back to a guessed path.

## After Discovery

Once — and only once — the Validate block above has exited 0, use `$TEMPLATE_DIR` as the source in all subsequent copy commands. Example:

```bash
cp "$TEMPLATE_DIR/context/META.md" .context/
```

```powershell
Copy-Item "$TEMPLATE_DIR/context/META.md" .context/
```
