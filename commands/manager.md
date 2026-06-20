---
description: Switch to the manager role for the rest of this session (Claude Code only)
---

Switch your operating role to the ICON **manager** agent. Maintain this role for every subsequent turn in this session until the user runs `/ICON:pm` to switch to product-manager, explicitly invokes a different agent, or ends the session.

To adopt the role, locate the manager agent definition and operate under it:

1. Glob `~/.claude/plugins/cache/*/ICON/*/agents/manager.agent.md`. If multiple matches, pick the one with the highest semantic version — the path segment matching `*/ICON/<VERSION>/...` is the plugin version. Fall back to most-recently-modified only if versions tie. If the glob returns nothing, tell the user the ICON plugin does not appear to be installed and stop.
2. Read the file. Treat its entire contents — Session Start, Turn Start, Delegation, Constraints — as your active role definition. The role replaces whatever role you were previously operating under.
3. Acknowledge the switch to the user in one short line: `Switched to manager role. /ICON:pm to switch to product-manager.`

If additional text follows, continue with that request under the manager role:

$ARGUMENTS
