# Repo: ICON (Independent Context Orchestration Network)

This repository is the canonical source of the ICON plugin — a project-agnostic, multi-agent orchestration system for Claude Code and GitHub Copilot CLI. The marketplace listing pulls from this repo at `ref: "latest"` (a movable git tag), so a release here is what propagates to ICON users.

## Tech stack

- **Markdown** for all agent definitions, skills, and commands.
- **JSON** for the plugin manifest (`.claude-plugin/plugin.json`).
- **Node.js** for the single `hooks/inject-manager-role.mjs` cross-platform wrapper and **Bash / PowerShell** for the maintainer `release-plugin` scripts.

There is **no build step**, **no test runner**, and **no package manager**. Validation means "the JSON parses" and "the manifest validator accepts it":

```bash
python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))"
```

## Key paths

| Path | Purpose |
|------|---------|
| `agents/` | The nine ICON agents (manager, coder, tester, etc.). |
| `skills/` | User-invocable and internal skills consumed by ICON agents. |
| `commands/` | Slash commands surfaced to Claude Code users. |
| `hooks/` | `SessionStart` hook script that injects the manager role. |
| `context_template/` | Source template copied into target projects by `/icon-init`. |
| `.claude-plugin/plugin.json` | Canonical plugin manifest. Single source of truth for the version. |
| `.claude/skills/release-plugin/` | Maintainer-only release tooling. Not shipped to consumers. |

## Versioning

- The version field in `.claude-plugin/plugin.json` is the **single source of truth** for the plugin release version.
- Release process: run `/release-plugin` (defined under `.claude/skills/release-plugin/`).
- Each release tags `vX.Y.Z` and force-moves the `latest` tag to the same commit. The marketplace consumes `latest`, so the force-move is what triggers the update for end users.

**Release guard — never release without an explicit instruction.** Do not bump `.claude-plugin/plugin.json`, rename `[Unreleased]` to a version, create a `vX.Y.Z` tag, force-move `latest`, or run `/release-plugin` unless the user has told you to release **in the current turn**. A consumer-shipped change — even a user-facing bug fix merged to `main` — is *eligibility* for the next release, not *authorization* to cut one now. The `[Unreleased]` block is meant to accumulate entries across multiple tasks between releases; that is the normal state. Releasing force-moves `latest` into every consumer's plugin cache on their next update, so readiness is the user's call. The only triggers are explicit phrasing — "release", "cut a release", "ship it", or an intentional `/release-plugin`.

### Template version (`context_template/context/iconrc.json`)

A second, independent version field lives at `context_template/context/iconrc.json` `version`. This is the **template schema version** — `/upgrade-repo` Phase 2 compares the consumer's installed `.context/iconrc.json` version against the template's to decide whether to apply updates to an installed repo. Without a bump here, consumer repos running `/upgrade-repo` silently skip the new template content.

**Invariant (enforced by `.githooks/pre-commit`)**: any commit that stages add/modify/delete/rename under `context_template/` must also bump the `version` field in `context_template/context/iconrc.json`. The hook fails the commit with a clear message if the version field is unchanged. The only exemption is a commit that stages ONLY `iconrc.json` itself (that change IS the bump). Maintainers should bump as part of the same commit that introduces the template change.

## Branching

This repo is **`main`-only**. There is no `dev` branch. All commits land on `main`; the release IS the tag push.

## Task IDs

Local tasks use the `ICON-NNNN` prefix (four-digit, zero-padded). Configured in `.context/iconrc.json`.

## Durable knowledge capture

Durable lessons and project conventions are captured in `.context/` — via the retrospective and promotion flow (`.context/retrospectives.md` → `context-maintenance` promotion into `domains/`, `standards/`, `workflows/`, or `decisions/`). They are **not** captured in tool-specific personal or agent memory (e.g. a Claude Code `MEMORY.md`, a Copilot personal note), which is invisible to other contributors and to the ICON system.

Personal/agent memory is only for genuinely user- or harness-specific facts (a developer's local shortcuts, a machine-specific path). Anything another contributor would benefit from — a convention, a gotcha, a recurring failure class — belongs in `.context/`.

## Marketplace consumption

The marketplace listing references this repo with:

```json
{ "source": "url", "url": "https://github.com/isochronous/icon.git", "ref": "latest" }
```

No marketplace edit is required for a normal ICON release — the moved `latest` tag is the propagation mechanism.
