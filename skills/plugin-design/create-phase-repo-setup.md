# Create — Phase 3: Repo Setup (Optional)

## Overview

For users whose plugin directory is not yet a git repo, this phase initializes one, optionally configures a remote, and offers starter commit-convention and branching templates. Skip this phase entirely if the plugin already lives in an existing git repo (e.g., a monorepo subdirectory).

## Check

Run the following before doing anything else. If the command succeeds, this directory is already inside a git working tree — skip the rest of this phase.

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

If the user wants to push to a remote, offer the GitLab and GitHub forms. Do not auto-execute — provide the command and let the user run it after confirming the URL.

```bash
# GitLab (HTTPS)
git remote add origin https://gitlab.com/<group>/<plugin-repo>.git
# GitLab (SSH)
git remote add origin git@gitlab.com:<group>/<plugin-repo>.git

# GitHub (HTTPS)
git remote add origin https://github.com/<user-or-org>/<plugin-repo>.git
# GitHub (SSH)
git remote add origin git@github.com:<user-or-org>/<plugin-repo>.git

git push -u origin main
```

## Conventions

Commit-convention and branching templates are delivered by Phase 4 (`create-phase-context-init.md`), which delegates to `/icon-init`. No action is required in this phase; running Phase 4 ships the templates into the new plugin's `.context/workflows/` automatically.
