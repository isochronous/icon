# Create — Phase 4: Context Initialization

## Overview

Populate the plugin's `.context/` directory by delegating to the `/icon-init` skill, the canonical context-folder initializer.

## Why Delegate

`/icon-init` already handles repo-type detection, template copying, `.iconrc.json` creation, git-hook wiring, and post-init affordances (`/icon-status` hint, conditional MCP onboarding hint). Duplicating any of it here would drift the next time `/icon-init` changes. This phase just runs that flow against the new plugin's working directory.

## Run

From the plugin root, invoke:

```
/icon-init
```

`/icon-init` auto-detects the repo shape. For a fresh Phase 1 scaffold, the detected type will be `project` (single-project leaf — no monorepo manifest, no `*.code-workspace`, no multimodule layout). Confirm `project` when prompted.

## Validation

After `/icon-init` completes successfully, confirm `.context/iconrc.json` exists at the plugin root:

```bash
test -f .context/iconrc.json && echo "context initialized" || echo "context-init failed"
```

PowerShell:

```powershell
if (Test-Path .context/iconrc.json) { 'context initialized' } else { 'context-init failed' }
```

If the file is missing, surface the failure rather than continuing — Phase 5 (marketplace) and audit-mode both assume `.context/` is populated.
