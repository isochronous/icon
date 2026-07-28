# Create — Phase 2: Basic Info

## Overview

Interactively collect plugin metadata and write it to `plugin.json` and `README.md`, replacing the Phase 1 placeholders. Validate each input before writing.

## Fields to Collect

Ask for each field in order, validating as you go.

| Field | Validation | Notes |
|-------|------------|-------|
| `name` | lowercase, alphanumeric + hyphens; ≤ 64 chars; no leading/trailing hyphen | Becomes the plugin slug. Example: `my-cool-plugin`. |
| `version` | SemVer `MAJOR.MINOR.PATCH`; pre-release allowed (`0.1.0-alpha.1`) | Default `0.1.0`. |
| `description` | one sentence, ≤ 200 chars | Used by `using-skills` and marketplace listings. |
| `author` | name (required), email and url (optional) | If a single string is given, treat as name only. |
| `license` | SPDX identifier (`MIT`, `Apache-2.0`, etc.) OR explicit `null` | `null` for intentionally unlicensed internal plugins. |
| `entry-point intent` | free-text (e.g., "manager-style orchestrator", "slash-command bundle", "hook injector") | Not written to `plugin.json`; informs later phases (especially marketplace README). |

If a field fails validation, surface the rule and prompt again rather than proceeding with bad input.

## Update plugin.json

Two forms. The `jq` form is **bash only** — its `--arg` flags and backslash line
continuations are parse errors in PowerShell. Use it in bash when `jq` is installed;
otherwise — and in PowerShell always, whether or not `jq` is installed — use the Node
fallback, which is identical in every shell.

Both forms pass the collected values as **arguments**, never interpolated into the
program: an apostrophe in a description or an author name (`O'Brien`) would otherwise
close the shell quote and abort the write. A double-quoted argument carries `'` through
unchanged in bash and PowerShell; a literal `"` inside a value still needs that shell's
own escape (`\"` in bash, `` `" `` in PowerShell).

```bash
jq --arg n "<name>" \
   --arg v "<version>" \
   --arg d "<description>" \
   --arg a "<author-name>" \
   --arg l "<license-or-null>" \
   '.name = $n
    | .version = $v
    | .description = $d
    | .author = {name: $a}
    | (if $l == "null" then .license = null else .license = $l end)' \
   .claude-plugin/plugin.json > .claude-plugin/plugin.json.tmp \
   && mv .claude-plugin/plugin.json.tmp .claude-plugin/plugin.json
```

Node fallback (no `jq` required). Two-space indent and a trailing newline, matching the
`jq` output above — other tooling matches the serialized `"version": "…"` literally, so
do not change the indent or reorder keys.

```
node -e '
const fs = require("fs");
const [name, version, description, author, lic] = process.argv.slice(1);
const p = ".claude-plugin/plugin.json";
const data = JSON.parse(fs.readFileSync(p, "utf8"));
data.name = name;
data.version = version;
data.description = description;
data.author = { name: author };
data.license = lic === "null" ? null : lic;
fs.writeFileSync(p, JSON.stringify(data, null, 2) + "\n");
' "<name>" "<version>" "<description>" "<author-name>" "<license-or-null>"
```

## Update README.md

Replace the placeholder title and description line with the real values. Written back
LF-terminated with no BOM regardless of platform — using the host's line ending here
would rewrite every line of the file.

```
node -e '
const fs = require("fs");
const [name, description] = process.argv.slice(1);
const lines = fs.readFileSync("README.md", "utf8").split(/\r?\n/);
if (lines[lines.length - 1] === "") lines.pop();
lines[0] = "# " + name;
for (let i = 1; i < lines.length; i++) {
  if (lines[i].trim() && !lines[i].startsWith("#")) { lines[i] = description; break; }
}
fs.writeFileSync("README.md", lines.join("\n") + "\n");
' "<name>" "<description>"
```

## Validation

Re-parse `plugin.json` after every edit to catch malformed writes. Identical in every shell:

```
node -e 'JSON.parse(require("fs").readFileSync(".claude-plugin/plugin.json", "utf8"))'
```

Exit code 0 with no output means the file is valid. Any output is the parse error.
