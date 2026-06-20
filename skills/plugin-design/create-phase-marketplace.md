# Create — Phase 5: Marketplace Listing (Optional)

## Overview

Prepare the plugin for listing in a Claude Code plugin marketplace. This phase produces:

1. A re-validated `plugin.json` that declares all marketplace-required fields.
2. An expanded `README.md` with install instructions, usage examples, and a capability list.
3. Documentation of the submission process.

This phase **does not actually submit** anything. Marketplaces use their own PR/MR workflow against a separate registry repo; the user opens that PR manually.

## Verify plugin.json

Confirm the manifest parses and declares the fields a marketplace typically requires (`name`, `version`, `description`, `author`, plus optional `repository`, `keywords`, `license`):

```bash
python3 - <<'PY'
import json, sys
data = json.load(open(".claude-plugin/plugin.json"))
required = ["name", "version", "description", "author"]
missing = [k for k in required if k not in data or data[k] in (None, "", {})]
if missing:
    print(f"missing required fields: {missing}")
    sys.exit(1)
print("plugin.json OK; declared fields:", sorted(data.keys()))
PY
```

PowerShell:

```powershell
$data = Get-Content .claude-plugin/plugin.json -Raw | ConvertFrom-Json
$required = 'name','version','description','author'
$missing = $required | Where-Object { -not $data.PSObject.Properties[$_] -or -not $data.$_ }
if ($missing) {
  "missing required fields: $missing"
  exit 1
}
"plugin.json OK; declared fields: $(($data.PSObject.Properties.Name | Sort-Object) -join ', ')"
```

If any required field is missing or empty, return to Phase 2 and fill it in before continuing.

## Generate Marketplace README Skeleton

Extend `README.md` to include the sections a marketplace consumer expects. Preserve the existing title and description; append (or merge) the following sections (the outer ````markdown```` fence below uses four backticks so the inner shell fences render as content, not as fence terminators):

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

When generating the capability list, scan the actual files in `agents/`, `skills/`, `commands/`, and `hooks/` rather than asking the user to type them — the answer is already on disk.

## Submission Process

Most Claude Code plugin marketplaces work by:

1. The plugin author opens a PR or MR against a registry repo that contains a `marketplace.json` (or equivalent) listing all plugins.
2. The PR adds a new entry pointing at the plugin's git URL and a movable tag (commonly `latest` or a specific SemVer tag).
3. The marketplace maintainers review and merge.

Reference example: the `datascan-marketplace` registry at `gitlab.com/onedatascan/ai-platform/marketplace` lists ICON via the movable `latest` tag in the ICON repo. The exact registry workflow varies by marketplace — consult the target marketplace's contributing guide before opening the PR.

If the marketplace publishes a PR template or contributing guide, follow it. The skill cannot infer this — it varies per marketplace.

## What This Phase Does NOT Do

- Does not open a PR or MR against any marketplace.
- Does not push the plugin's own repo to a remote (that is Phase 3).
- Does not tag a release (use the consuming plugin's own release flow, e.g., ICON's `release-plugin` skill).
