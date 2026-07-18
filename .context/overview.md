# Overview: ICON Plugin Repository

This repo is the canonical source of the **ICON** (Independent Context Orchestration Network) plugin — a project-agnostic, multi-agent orchestration system for Claude Code and GitHub Copilot CLI. It is a standalone repository so it can be released and versioned independently of the marketplace listing that consumes it.

## What lives here

| Top-level path | Contents |
|----------------|----------|
| `agents/` | The nine ICON agent definitions (markdown with frontmatter). |
| `skills/` | User-invocable and internal skills (markdown with frontmatter). |
| `commands/` | Claude Code slash commands. |
| `hooks/` | Plugin-scoped hook wiring (`hooks.json`) + cross-platform Node.js wrappers (e.g., `inject-manager-role.mjs`). See `.context/domains/hooks.md`. |
| `context_template/` | Template `.context/` tree copied into target projects by `/icon-init`. |
| `shared/` | Shared content snippets (e.g., `common-constraints.md`). |
| `.claude-plugin/plugin.json` | Canonical plugin manifest. **Single source of truth for the version.** |
| `.github/workflows/` | GitHub Actions CI (e.g. `security.yml` — gitleaks / semgrep / shellcheck). |
| `.claude/skills/release-plugin/` | Maintainer-only release tooling (not shipped). |

## Tech stack

Pure content. Markdown for definitions, JSON for the manifest and hook wiring, a single Node.js (`.mjs`) wrapper for the SessionStart hook (cross-platform; see `.context/domains/hooks.md`), and bash + PowerShell for the maintainer-only release scripts. No compile step, no test runner, no package manager. Validation is "the JSON parses" plus structural review. The plugin bundles no MCP servers — GitHub access is via the `gh` CLI (see `.context/domains/github-access.md`).

## Branching and versioning

- **Branch model**: `main`-only. No `dev`/`main` split.
- **Version**: single source of truth is the `version` field in `.claude-plugin/plugin.json`.
- **Releases**: `/release-plugin` bumps the manifest + CHANGELOG, commits on `main`, tags `vX.Y.Z`, and force-moves the `latest` tag so the marketplace listing picks up the new version automatically.
- **Local task IDs**: `ICON-NNNN` (four-digit, zero-padded).

## Marketplace consumption

The `icon-marketplace` listing at `github.com/isochronous` references this repo with `ref: "latest"`. Moving the `latest` tag at release time is what propagates new versions to end users — no marketplace edit is required for a normal release.

## Status of `.context/`

The `.context/` tree is **complete**. The following components are populated and in use:

- `domains/` — [skill system](domains/skill-system.md), [GitHub access](domains/github-access.md) (`gh` CLI), [plugin resource paths](domains/plugin-resource-paths.md), [hooks](domains/hooks.md)
- `standards/` — skill decomposition, changelog discipline
- `workflows/` — branching, commit conventions, changelog, prune-context script
- `cache/` — research cache (TTL from `iconrc.json`)
- `tasks/` — per-task plan folders (auto-pruned after 90 days)
- `decisions/` — 11 ADRs (ADR-001 through ADR-011; ADR-006 and ADR-011 superseded by the GitHub-only conversion); see `decisions/README.md` for the log
- `retrospectives.md` — rolling log of task-level lessons
- `META.md` — maintenance guide
- `iconrc.json` — repo config

`architecture/`, `testing/`, and `styling/` are intentionally excluded per `iconrc.json` (`excludes: ["architecture", "testing", "styling"]`) — these directories do not apply to a pure-content plugin repo and will not appear.
