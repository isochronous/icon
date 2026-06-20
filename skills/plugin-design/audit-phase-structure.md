# Audit — Phase 1: Structure Validation

## Overview

Verify the plugin's file/folder layout and frontmatter are well-formed. Findings from this phase are blockers for marketplace listing — a plugin that fails structural validation will not load cleanly in Claude Code.

## Checks

For each check, report a pass/fail line with a path if applicable.

1. **`plugin.json` parses as valid JSON** — required.
2. **`plugin.json` declares `$schema`** — recommended; ideally `https://json.schemastore.org/claude-code-plugin-manifest.json` for IDE validation.
3. **`plugin.json` declares `name`, `version`, `description`** — required.
4. **Standard directories exist** — `agents/`, `skills/`, `commands/`, `hooks/`, `shared/`. Not all are mandatory (a skill-only plugin may omit `agents/`), but report each as present/absent so the auditor can sanity-check.
5. **Every `agents/*.agent.md` has valid YAML frontmatter** declaring at least `name` and `description`.
6. **Every `skills/*/SKILL.md` has valid YAML frontmatter** declaring at least `name` and `description`.
7. **`CHANGELOG.md` exists** and contains an `## [Unreleased]` block.

## Validation Snippets

### plugin.json

```bash
python3 -c "import json; data = json.load(open('.claude-plugin/plugin.json')); \
  assert 'name' in data and 'version' in data and 'description' in data, \
  f'missing required: {sorted(set([\"name\",\"version\",\"description\"]) - data.keys())}'"
```

PowerShell:

```powershell
$d = Get-Content .claude-plugin/plugin.json -Raw | ConvertFrom-Json
foreach ($k in 'name','version','description') {
  if (-not $d.PSObject.Properties[$k]) { "MISSING: $k" }
}
```

### Frontmatter parse (Python, no yq dependency)

`yq` is not always installed; use this Python snippet to parse the YAML block between the first pair of `---` markers in every agent and skill file.

```bash
python3 - <<'PY'
import yaml, pathlib, sys
findings = []
for p in list(pathlib.Path("agents").glob("*.agent.md")) + \
         list(pathlib.Path("skills").glob("*/SKILL.md")):
    txt = p.read_text()
    parts = txt.split("---", 2)
    if len(parts) < 3:
        findings.append(f"{p}: missing frontmatter")
        continue
    try:
        fm = yaml.safe_load(parts[1])
    except Exception as e:
        findings.append(f"{p}: YAML parse error: {e}")
        continue
    if not isinstance(fm, dict):
        findings.append(f"{p}: frontmatter is not a mapping")
        continue
    for required in ("name", "description"):
        if required not in fm or not fm[required]:
            findings.append(f"{p}: missing or empty '{required}'")
for f in findings:
    print(f)
sys.exit(1 if findings else 0)
PY
```

PowerShell variant (uses `powershell-yaml` if available, otherwise falls back to a hand parser that only validates "starts with ---, ends with ---, has key: value lines"):

```powershell
$files = @(Get-ChildItem agents/*.agent.md -ErrorAction SilentlyContinue) + @(Get-ChildItem skills/*/SKILL.md -ErrorAction SilentlyContinue)
$findings = @()
foreach ($f in $files) {
  $txt = Get-Content $f.FullName -Raw
  $parts = $txt -split '---', 3
  if ($parts.Count -lt 3) { $findings += "$($f.FullName): missing frontmatter"; continue }
  $fm = $parts[1]
  foreach ($k in 'name','description') {
    if ($fm -notmatch "(?m)^\s*${k}\s*:") {
      $findings += "$($f.FullName): missing '$k'"
    }
  }
}
$findings
if ($findings.Count -gt 0) { exit 1 }
```

### CHANGELOG `[Unreleased]` block

```bash
grep -q '^## \[Unreleased\]' CHANGELOG.md && echo "OK" || echo "MISSING [Unreleased]"
```

PowerShell:

```powershell
if (Select-String -Path CHANGELOG.md -Pattern '^## \[Unreleased\]' -Quiet) { 'OK' } else { 'MISSING [Unreleased]' }
```
