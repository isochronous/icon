# ADR-001: Split ICON into its own repository

**Date**: 2026-05-13
**Status**: Accepted

## Context

ICON originally lived under `plugins/ICON/` inside the `datascan-marketplace` monorepo. Versioning the plugin required tagging the monorepo, which coupled ICON releases to unrelated marketplace listings and surfaced misleading diffs at install time. Marketplace consumers also could not see ICON's commit history without cloning the whole monorepo.

## Decision

Split ICON into a standalone GitLab repository at `gitlab.com/onedatascan/ai-platform/plugins/icon` (this repo). The marketplace listing references this repo with `ref: "latest"` (a movable git tag), so installs resolve to the most recent ICON-tagged commit without a marketplace edit.

## Consequences

**Positive:**
- ICON versions decoupled from marketplace versions; tags here mean ICON releases only.
- `git log` and `git diff` show only ICON-relevant changes.
- Smaller clone surface for end users and CI.
- Two-channel ICON/ICON-beta layout collapsed to a single `main`-only channel during the split.

**Negative:**
- Changes that span ICON and marketplace require coordinated commits in two repos.
- ICON's `latest` tag is mutable; a corrupt force-push to it would break all marketplace consumers until reverted. Mitigated by keeping `release-plugin` maintainer-only and tagging immutable `vX.Y.Z` alongside `latest`.

## Alternatives Considered

1. **Keep ICON in the monorepo, gate releases via a path-scoped tag**: rejected — git tags are not path-scoped; we would still tag the whole monorepo and prune the diff client-side.
2. **Publish ICON as an npm package**: rejected — Copilot CLI and Claude Code load plugins from git URLs, not package registries; the marketplace flow already works with git refs.

Tracked in marketplace task `MKT-0095`; follow-up `ICON-0001` populates this repo's `.context/`.
