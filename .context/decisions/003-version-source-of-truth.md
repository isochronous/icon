# ADR-003: Single source of truth for the version is `.claude-plugin/plugin.json`

**Date**: (originating principle predates the split)
**Status**: Accepted

## Context

Earlier ICON releases bumped the version in multiple files (manifest, README badges, agent frontmatter). Version drift between files caused release commits where the manifest said one version and a README example said another.

## Decision

The `version` field in `.claude-plugin/plugin.json` is the **only** place the plugin version lives. No badge, no agent frontmatter, no `package.json`-style mirror. `release-plugin` updates exactly this one file (plus the dated `CHANGELOG.md` section).

## Consequences

**Positive:**
- Version drift is structurally impossible — there is only one location.
- `.claude/skills/release-plugin/scripts/bump-versions.sh` reads and writes this one path.
- README and agent files describe behaviour, not the current version.

**Negative:**
- Any code that wants to display "you are running ICON vX.Y.Z" must read `plugin.json` at runtime.

## Alternatives Considered

1. **Mirror the version into `README.md` badges**: rejected — badges go stale silently when the bump skill forgets to update them.
2. **Mirror into a top-level `VERSION` file**: rejected — would require keeping the mirror in lockstep manually.
