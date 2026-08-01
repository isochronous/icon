# Create — Phase 5: Marketplace Listing (Optional)

## Overview

Prepare the plugin for listing in a Claude Code plugin marketplace. This phase produces:

1. A re-validated `plugin.json` declaring all marketplace-required fields.
2. An expanded `README.md` with install instructions, usage examples, and a capability list.
3. Documentation of the submission process.

This phase **does not submit** anything. Marketplaces use their own PR workflow against a separate registry repo; the user opens that PR manually.

## Verify plugin.json

Confirm the manifest parses and declares the fields a marketplace typically requires (`name`, `version`, `description`, `author`, plus optional `repository`, `keywords`, `license`):

**Precondition — confirm Node is present before running this block.** Run `node -v` and read its
**output**, not its exit status. If Node is absent, do not run it — invoke `check-node-runtime`,
which reports what stops working and offers a per-platform install.

A field counts as declared only if it is **non-empty**: `""`, `null`, `0` and an **empty object**
all read as absent, so an `"author": {}` left over from scaffolding is reported rather than
accepted. Both field lists print as plain comma-separated names, not as a language-specific list
literal. The manifest is read relative to the current directory, so run this from the plugin root.

| stdout | exit | Meaning |
|---|---|---|
| `plugin.json OK; declared fields: <names>` | 0 | All four required fields are non-empty. The list is every top-level key present, sorted — including the optional ones. |
| `missing required fields: <names>` | 1 | The named fields are absent or empty. Return to Phase 2 and fill them in first. |
| *(nothing)* | non-zero | No verdict was reached — the manifest is absent, unreadable, or not valid JSON, and the trace is on stderr. **Never read this as a pass.** |

The failing verdict goes to **stdout**, not stderr as the inline form emitted it, so that empty
stdout means no verdict was produced — the block did not run, or it crashed before printing. On the
inline form empty stdout meant either of those *or* a missing field. Measured on bash 5.3.9,
PowerShell 7.6.3 and Windows PowerShell 5.1.26100.8875 with Node v24.18.0: identical stdout and
exit status on all three. Not measured under `cmd`.

### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/verify-marketplace-fields.mjs"
```

### Copilot CLI (Bash)

```bash
# Resolve this skill's install directory. Set MARKETPLACE_NAME=<slug> to pin one marketplace;
# otherwise every installed marketplace is searched and an ambiguous result fails closed.
ROOT="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins"
S="plugin-design"; P="scripts/verify-marketplace-fields.mjs"
if [ -n "${MARKETPLACE_NAME+x}" ]; then G="$MARKETPLACE_NAME"; else G="*"; fi
F=""; N=0
for f in "$ROOT"/$G/ICON/skills/"$S/$P" "$ROOT"/$G/ICON/*/skills/"$S/$P"; do
  [ -f "$f" ] || continue; F="$f"; N=$((N+1))
done
[ "$N" = 1 ] || { echo "ICON: $N matches for $S/$P under $ROOT (marketplace ${MARKETPLACE_NAME-<any>}) — set MARKETPLACE_NAME; see: copilot plugin list" >&2; exit 1; }
node "$F"
```

## Generate Marketplace README Skeleton

Extend `README.md` with the sections a marketplace consumer expects. Preserve the existing title and description; append (or merge) the following (the outer ````markdown```` fence below uses four backticks so the inner shell fences render as content, not as terminators):

````markdown
## Installation

### Via the marketplace

```bash
# Copilot CLI
copilot plugin install <marketplace-install-url>

# Claude Code
claude plugin install <marketplace-install-url>
```

### Direct install (no marketplace)

```bash
# Copilot CLI
copilot plugin install <plugin-repo-url>

# Claude Code
claude plugin install <plugin-repo-url>
```

## Usage

<At least one concrete example — invoke an agent, run a slash command, or describe how a hook activates.>

## Capabilities

<Auto-derived from the plugin's contents:>

- Agents: <list any `agents/*.agent.md` files>
- Skills: <list any `skills/*/SKILL.md` files; mark `user-invocable: true` ones>
- Commands: <list any `commands/*.md` files>
- Hooks: <list any `hooks/*.json` entries>
````

When generating the capability list, scan the actual files in `agents/`, `skills/`, `commands/`, and `hooks/` rather than asking the user — the answer is already on disk.

## Submission Process

Most Claude Code plugin marketplaces work by:

1. The plugin author opens a PR against a registry repo containing a `marketplace.json` (or equivalent) listing all plugins.
2. The PR adds an entry pointing at the plugin's git URL and a movable tag (commonly `latest` or a specific SemVer tag).
3. The marketplace maintainers review and merge.

Reference example: a registry repo lists a plugin via a movable `latest` tag in the plugin's own repo. The exact workflow varies by marketplace — consult the target's contributing guide before opening the PR, and follow any PR template it publishes. The skill cannot infer this.

## What This Phase Does NOT Do

- Does not open a PR against any marketplace.
- Does not push the plugin's own repo to a remote (that is Phase 3).
- Does not tag a release (use the consuming plugin's own release flow, e.g., ICON's `release-plugin` skill).
