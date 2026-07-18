---
description: >
  Write managerDefault: false to ~/.claude/icon-user-settings.json to opt out of the manager-role default (Claude Code only)
---

Disable the manager-default behavior. New sessions will no longer auto-adopt the manager role; `/ICON:manager` still works as a manual switch.

The SessionStart hook lives in the plugin's own `hooks/hooks.json`; disabling it just writes `managerDefault: false` to `~/.claude/icon-user-settings.json`. This command also migrates any legacy hook entry from earlier plugin versions out of `~/.claude/settings.json` (which used to host the wiring directly).

## Steps

1. **Migrate any legacy hook entry from `~/.claude/settings.json`.** Read `~/.claude/settings.json`; if the file does not exist, treat it as `{}` and skip the rest of this step. Otherwise:
   - Walk `hooks.SessionStart`. For each entry in the array, filter its inner `hooks` array, dropping any handler whose `command` string contains the substring `inject-manager-role` (covers the legacy `.sh` and `.ps1` variants as well as the new `.mjs`).
   - If an entry's inner `hooks` array becomes empty after filtering, drop that entry from the `SessionStart` array.
   - If the filtered `SessionStart` array is now empty, delete the `SessionStart` key.
   - If the resulting `hooks` object is now empty, delete the `hooks` key entirely.
   - Preserve every other top-level key and every other hook entry verbatim — do not reorder or rewrite them.
   - Detect the existing indentation (2-space, 4-space, or tabs) from the file as-read and match it when writing back. If the file was empty, missing, or minified, use 2-space indent. Preserve the order of existing top-level keys.
   - Record whether any legacy entry was removed (for the report in Step 3).
2. **Set `managerDefault: false` in `~/.claude/icon-user-settings.json`.** Read `~/.claude/icon-user-settings.json`; if the file does not exist or is empty, treat it as `{}`. Otherwise parse it.
   - Set the top-level key `managerDefault` to boolean `false`. Preserve all other top-level keys verbatim.
   - Write back with detected indentation (2-space, 4-space, or tabs) from the file as-read; default to 2-space indent for new files.
   - Record whether the key was already `false` (for the report in Step 3).
3. **Report the outcome.** Choose the message that matches what actually changed:
   - Legacy entry was removed AND `managerDefault` flipped (or was just created):
     ```
     Migrated legacy user-settings entry → ~/.claude/icon-user-settings.json.
     Manager-default is now OFF. /ICON:manager still works as a manual switch.
     ```
   - `managerDefault` was already `false` and no legacy entry existed:
     ```
     Manager-default is already OFF. No changes needed.
     ```
   - `managerDefault` was already `false` but a legacy entry was just cleaned up:
     ```
     Manager-default is already OFF. Cleaned up a legacy entry from ~/.claude/settings.json.
     ```
   - `managerDefault` flipped from `true` (or absent) to `false`, no legacy entry to migrate:
     ```
     Manager-default disabled. New sessions will no longer auto-adopt the manager role. /ICON:manager still works as a manual switch.
     ```

## Error Handling

- If `~/.claude/settings.json` exists but cannot be parsed as JSON, do not overwrite it. Surface the parse error to the user and stop — Step 2 does not run.
- If `~/.claude/icon-user-settings.json` exists but cannot be parsed as JSON, do not overwrite it. Surface the parse error and stop.
- If either write fails (permissions, etc.), report the failure plainly — do not retry with `sudo` or workarounds.
