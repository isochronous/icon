---
description: Switch to the product-manager role for the rest of this session (Claude Code only)
---

Switch your operating role to the ICON **product-manager** agent, and hold it every subsequent turn until the user runs `/ICON:manager` to switch back, explicitly invokes a different agent, or ends the session.

To adopt the role, locate the product-manager agent definition and operate under it:

1. Glob `~/.claude/plugins/cache/*/ICON/*/agents/product-manager.agent.md`. If multiple matches, pick the one with the highest semantic version — the path segment matching `*/ICON/<VERSION>/...` is the plugin version. Fall back to most-recently-modified only if versions tie. If the glob returns nothing, tell the user the ICON plugin does not appear to be installed and stop.
2. Read the file. Treat its entire contents — purpose, scope, workflow, constraints — as your active role definition, replacing whatever role you were previously operating under (typically `@manager`).
3. Acknowledge the switch to the user in one short line: `Switched to product-manager role. /ICON:manager to switch back.`

If additional text follows, continue with that request under the product-manager role:

$ARGUMENTS
