# Create — Phase 3: Repo Setup (Optional)

## Overview

For a plugin directory not yet under git, this phase initializes a repo, optionally configures a remote, and offers starter commit-convention and branching templates. Skip it entirely if the plugin already lives in a git repo (e.g. a monorepo subdirectory).

## Check

Run this first. If the command succeeds, the directory is already inside a git working tree — skip the rest of this phase.

```bash
git rev-parse --is-inside-work-tree
```

PowerShell variant:

```powershell
git rev-parse --is-inside-work-tree
```

## Initialize

If not already a git repo:

```bash
git init
git add .
git commit -m "Initial plugin scaffold"
```

PowerShell:

```powershell
git init
git add .
git commit -m "Initial plugin scaffold"
```

## Remote (optional)

If the user wants to push to a remote, offer the GitHub forms. Do not auto-execute — provide the command and let the user run it after confirming the URL.

```bash
# GitHub (HTTPS)
git remote add origin https://github.com/<user-or-org>/<plugin-repo>.git
# GitHub (SSH)
git remote add origin git@github.com:<user-or-org>/<plugin-repo>.git

git push -u origin main
```

## Conventions

Commit-convention and branching templates are delivered by Phase 4 (`create-phase-context-init.md`), which delegates to `/icon-init`. No action here; running Phase 4 ships the templates into the new plugin's `.context/workflows/` automatically.
