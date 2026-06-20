# Create — Phase 4: Context Initialization

## Overview

Populate the plugin's `.context/` directory by delegating to the `/icon-init` skill, which is the canonical context-folder initializer.

## Why Delegate

`/icon-init` already handles repo-type detection, template copying, `.iconrc.json` creation, git-hook wiring, and the post-init affordances (`/icon-status` hint, conditional MCP onboarding hint). Duplicating any of that here would create drift the next time `/icon-init` changes. The job of this phase is simply to make sure that flow runs against the new plugin's working directory.

## Run

From the plugin root, invoke:

```
/icon-init
```

`/icon-init` will auto-detect the repo shape. For a fresh plugin scaffold from Phase 1, the detected type will be `project` (single-project leaf — there is no monorepo manifest, no `*.code-workspace`, no multimodule layout). Confirm `project` when prompted.

## Validation

After `/icon-init` completes successfully, confirm `.context/iconrc.json` exists at the plugin root:

```bash
test -f .context/iconrc.json && echo "context initialized" || echo "context-init failed"
```

PowerShell:

```powershell
if (Test-Path .context/iconrc.json) { 'context initialized' } else { 'context-init failed' }
```

If the file is missing, surface the failure rather than continuing to the next phase — Phase 5 (marketplace) and audit-mode both assume `.context/` is populated.
