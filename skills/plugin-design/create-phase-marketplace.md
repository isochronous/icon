# Create — Phase 5: Marketplace Listing (Optional)

## Overview

Prepare the plugin for listing in a Claude Code plugin marketplace. This phase produces:

1. A re-validated `plugin.json` declaring all marketplace-required fields.
2. An expanded `README.md` with install instructions, usage examples, and a capability list.
3. Documentation of the submission process.

This phase **does not submit** anything. Marketplaces use their own PR workflow against a separate registry repo; the user opens that PR manually.

## Verify plugin.json

Confirm the manifest parses and declares the fields a marketplace typically requires (`name`, `version`, `description`, `author`, plus optional `repository`, `keywords`, `license`):

Identical in every shell — run it as-is, in whatever shell the session uses. Both field
lists print as plain comma-separated names, not as a language-specific list literal.

```
node -e '
const data = JSON.parse(require("fs").readFileSync(".claude-plugin/plugin.json", "utf8"));
const empty = (v) => !v || (typeof v === "object" && Object.keys(v).length === 0);
const missing = ["name", "version", "description", "author"].filter((k) => empty(data[k]));
if (missing.length) {
  console.error("missing required fields: " + missing.join(", "));
  process.exit(1);
}
console.log("plugin.json OK; declared fields: " + Object.keys(data).sort().join(", "));
'
```

If any required field is missing or empty, return to Phase 2 and fill it in first.

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
