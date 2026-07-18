# Create Mode

## Overview

Create mode scaffolds a new Claude Code plugin from an empty directory to a working, optionally marketplace-ready, ICON-initialized plugin. Each phase loads on demand from a companion file in this directory.

## Precondition

Confirm a working directory exists for the new plugin and that the shell is inside it:

```bash
pwd
ls -A
```

If the directory does not exist, offer to create it (`mkdir -p <plugin-name> && cd <plugin-name>`) first. If it contains files that look like an existing project (e.g. a `plugin.json`), pause and confirm whether this is a resume or a re-init.

## Marketplace Opt-In Prompt

Before sequencing phases, ask the user:

> This skill can also prepare your plugin for marketplace listing — extra `plugin.json` validation, a marketplace-ready README skeleton, and submission instructions. Include the marketplace phase? (y/n, default n)

Record the answer. `y` runs all 5 phases; `n` (or empty) runs only Phases 1–4 and skips `create-phase-marketplace.md`.

## Phase Sequence

Load and execute each phase file in order. A returning user may have completed earlier phases — confirm where to resume rather than re-running phases that already produced outputs.

1. **Boilerplate** — load `create-phase-boilerplate.md`. Scaffold the directory tree (`.claude-plugin/plugin.json`, `agents/`, `skills/`, `commands/`, `hooks/`, `shared/`, `README.md`, `CHANGELOG.md`, `.gitignore`).
2. **Basic info** — load `create-phase-basic-info.md`. Interactively fill in plugin metadata (name, version, description, author, license, entry-point intent).
3. **Repo setup (optional)** — load `create-phase-repo-setup.md`. Initialize git, set up a remote, offer commit-convention and branching templates.
4. **Context initialization** — load `create-phase-context-init.md`. Delegate to `/icon-init` to populate `.context/`.
5. **Marketplace listing (optional)** — load `create-phase-marketplace.md` ONLY if the user opted in at the prompt above. Otherwise stop after Phase 4.

After the final phase completes, report a summary: phases run, files created, and any follow-up steps the user should take (e.g. "run `/icon-status` to see where things stand").
