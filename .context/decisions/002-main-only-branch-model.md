# ADR-002: `main`-only branch model

**Date**: 2026-05-13
**Status**: Accepted

## Context

The marketplace monorepo used a `feature → dev → main` flow with a separate `ICON-beta` channel for pre-release plugin testing. The split surfaced that this complexity was solving a marketplace-coordination problem, not an ICON-development problem.

## Decision

ICON uses **only `main`**. Feature branches off `main`, merge back to `main`. There is no `dev`, `develop`, or `beta` integration branch. The release IS the `vX.Y.Z` tag push plus the force-move of the `latest` tag.

## Consequences

**Positive:**
- Single integration target removes "did this merge to dev or main?" confusion.
- `release-plugin` flow simplified to one channel — see `.context/workflows/changelog.md`.
- `.context/workflows/prune-context.sh` `INTEGRATION_BRANCHES` is a single literal: `^main$`.

**Negative:**
- No staging integration branch for pre-release stabilization. Mitigated by the lightweight scope of ICON changes (markdown content, no build) and the maintainer-only `release-plugin` gate.

## Alternatives Considered

1. **Preserve the `dev`/`main` split**: rejected — there is no automated CI promotion between branches in this content-only repo; the split added overhead without buying integration safety.
2. **Keep `ICON-beta` as a parallel pre-release channel**: rejected during MKT-0095 split planning — beta consumers can opt in by installing from a specific commit SHA if needed; we will not maintain a second changelog and tag flow for it.
