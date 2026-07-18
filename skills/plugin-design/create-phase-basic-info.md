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

## Update plugin.json (Bash)

Use `jq` to update fields in place. If `jq` is not installed, use the Python fallback below.

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

Python fallback (no `jq` required):

```bash
python3 - <<'PY'
import json
p = ".claude-plugin/plugin.json"
data = json.load(open(p))
data["name"] = "<name>"
data["version"] = "<version>"
data["description"] = "<description>"
data["author"] = {"name": "<author-name>"}
lic = "<license-or-null>"
data["license"] = None if lic == "null" else lic
json.dump(data, open(p, "w"), indent=2)
open(p, "a").write("\n")
PY
```

## Update plugin.json (PowerShell)

```powershell
$p = '.claude-plugin/plugin.json'
$data = Get-Content $p -Raw | ConvertFrom-Json
$data.name = '<name>'
$data.version = '<version>'
$data.description = '<description>'
$data | Add-Member -NotePropertyName author -NotePropertyValue @{ name = '<author-name>' } -Force
$lic = '<license-or-null>'
if ($lic -eq 'null') {
  $data | Add-Member -NotePropertyName license -NotePropertyValue $null -Force
} else {
  $data | Add-Member -NotePropertyName license -NotePropertyValue $lic -Force
}
$data | ConvertTo-Json -Depth 10 | Set-Content -Path $p -Encoding UTF8
```

## Update README.md

Replace the placeholder title and description line with the real values.

Bash:

```bash
python3 - <<'PY'
import pathlib
p = pathlib.Path("README.md")
lines = p.read_text().splitlines()
lines[0] = f"# <name>"
# Find first non-blank non-heading line and replace
for i in range(1, len(lines)):
    if lines[i].strip() and not lines[i].startswith("#"):
        lines[i] = "<description>"
        break
p.write_text("\n".join(lines) + "\n")
PY
```

PowerShell:

```powershell
$lines = Get-Content README.md
$lines[0] = "# <name>"
for ($i = 1; $i -lt $lines.Count; $i++) {
  if ($lines[$i].Trim() -and -not $lines[$i].StartsWith('#')) {
    $lines[$i] = '<description>'
    break
  }
}
Set-Content -Path README.md -Value $lines -Encoding UTF8
```

## Validation

Re-parse `plugin.json` after every edit to catch malformed writes:

```bash
python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))"
```
