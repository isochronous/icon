# Changelog Workflow

## Overview

This repo maintains a single changelog at `CHANGELOG.md` (repo root). It is the user-facing release log driven by the `release-plugin` flow.

## Structure (`CHANGELOG.md`)

- Always has an `[Unreleased]` section at the top.
- Changes accumulate under `[Unreleased]` as they land on `main`.
- When a release is cut via `/release-plugin`, the `[Unreleased]` header is renamed to `[X.Y.Z] - YYYY-MM-DD` and a fresh `[Unreleased]` section is added above it.

```
## [Unreleased]            ← accumulates during normal work on main

## [1.13.0] - 2026-05-13   ← written by release-plugin skill
```

## Skill Responsibilities

| Skill | Changelog action |
|-------|-----------------|
| `release-plugin` | Renames `[Unreleased]` → `[X.Y.Z] - YYYY-MM-DD` in `CHANGELOG.md`; adds a fresh empty `[Unreleased]` section above it |

The release-plugin skill lives under `.claude/skills/release-plugin/` and is maintainer-only — it is not shipped as part of the plugin to end users.

## Investigating Release History

Releases are tagged `vX.Y.Z` on `main`. The mutable tag `latest` is force-moved to the newest stable release at cut time; this is how the marketplace listing picks up new versions automatically (the marketplace at `gitlab.com/onedatascan/ai-platform/marketplace` references this repo with `ref: "latest"`).

To compare two releases:

```bash
git log v1.13.2..v1.13.3
```

Do not use `latest` as an endpoint in a comparison — it is mutable and will refer to whatever the current stable release is, not a fixed point in history.

## Preserving Historical Entries

Past versioned sections (`[1.13.0]`, `[1.13.1]`, etc.) describe what shipped in that release and are frozen history — do **not** rewrite them when a component is later retired or renamed.

When a skill, agent, or feature is removed, record the retirement as a new entry under `[Unreleased]` (typically in a `### Removed` or `### Deprecated` subsection). The next release carries that entry forward; earlier versions keep their original text intact.
