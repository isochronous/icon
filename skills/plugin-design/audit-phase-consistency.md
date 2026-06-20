# Audit — Phase 2: Internal Consistency

## Overview

Cross-file checks that detect drift between what a file claims and what other files actually contain. Structure can be valid (Phase 1) while still being internally inconsistent — a skill that references `/foo` when no `skills/foo/SKILL.md` exists, a description that is boilerplate placeholder text, or two agents whose stated responsibilities overlap.

## Checks

1. **Skill references resolve** — any `/foo` invocation in `agents/*.agent.md` or `skills/*/SKILL.md` body text must correspond to an existing `skills/foo/SKILL.md` (or to a built-in slash command, which the auditor should distinguish if known).
2. **File-path references resolve** — any `.context/<subdir>/<file>.<ext>` reference in shipped surfaces (agents, skills, shared, commands) must resolve under the plugin's `.context/`. (For the ICON self-audit case where `.context/` content lives under `context_template/context/`, prefer that location when present.) This generalizes the dead-ref pattern from ICON's own pre-commit hook.
3. **Frontmatter `description` is non-boilerplate** — heuristic: description must not be empty, must not equal the skill/agent name, must not be the literal `TODO` or `<description>`, must be longer than 20 characters.
4. **Agent/skill role-overlap heuristic** — if two agents have descriptions whose first sentence mentions overlapping responsibilities (similar verb + object), surface it as a concern. This is a heuristic only; flag for review, do not auto-fail.

## Validation Snippets

### Skill-reference resolution

```bash
python3 - <<'PY'
import pathlib, re, sys
existing = {p.parent.name for p in pathlib.Path("skills").glob("*/SKILL.md")}
findings = []
# Require the slash-name to be a real invocation: preceded by start-of-line or
# whitespace/backtick, and followed by whitespace, end-of-line, backtick, or
# common punctuation. This avoids matching mid-path tokens like `.context/standards`.
INVOCATION_RE = re.compile(r'(?:^|(?<=[\s`]))/([a-z][a-z0-9-]+)(?=[\s`.,;:!?)\]]|$)', re.MULTILINE)
SKIP_PREFIXES = (
    "http://", "https://",
    "/usr/", "/etc/", "/var/",
    ".context/", "context_template/",
    "github.com/",
)
for p in list(pathlib.Path("agents").glob("*.agent.md")) + \
         list(pathlib.Path("skills").glob("*/SKILL.md")):
    txt = p.read_text()
    for m in INVOCATION_RE.finditer(txt):
        name = m.group(1)
        if name in existing:
            continue
        # Heuristic guard: skip references inside URLs, file paths, or generic command examples.
        ctx = txt[max(0, m.start()-20):m.end()+20]
        if any(s in ctx for s in SKIP_PREFIXES):
            continue
        findings.append(f"{p}: references /{name} but skills/{name}/SKILL.md not found")
for f in findings:
    print(f)
PY
```

### File-path resolution (dead-ref)

```bash
python3 - <<'PY'
import pathlib, re
plugin_root = pathlib.Path(".")
findings = []
for d in ("agents", "skills", "shared", "commands"):
    base = plugin_root / d
    if not base.exists():
        continue
    for p in base.rglob("*"):
        if p.suffix not in (".md", ".sh", ".ps1", ".js"):
            continue
        for m in re.finditer(r'\.context/[a-zA-Z0-9_/-]+\.[a-zA-Z0-9]+', p.read_text()):
            ref = m.group(0)
            rest = ref[len(".context/"):]
            # ICON self-audit: content lives under context_template/context/.
            # Generic plugins: content lives at the plugin's .context/ root
            # (audit-mode's hard precondition guarantees .context/ exists).
            ct_path = plugin_root / "context_template" / "context" / rest
            if ct_path.exists():
                continue
            ctx_path = plugin_root / ".context" / rest
            if ctx_path.exists():
                continue
            findings.append(f"{p}: dead ref {ref}")
for f in findings:
    print(f)
PY
```

PowerShell variant:

```powershell
$pluginRoot = (Get-Location).Path
$findings = @()
foreach ($d in 'agents','skills','shared','commands') {
  $base = Join-Path $pluginRoot $d
  if (-not (Test-Path $base)) { continue }
  $files = Get-ChildItem -Path $base -Recurse -File -Include *.md,*.sh,*.ps1,*.js -ErrorAction SilentlyContinue
  foreach ($f in $files) {
    $txt = Get-Content $f.FullName -Raw
    foreach ($m in [regex]::Matches($txt, '\.context/[a-zA-Z0-9_/-]+\.[a-zA-Z0-9]+')) {
      $ref = $m.Value
      $rest = $ref.Substring('.context/'.Length)
      $ctPath = Join-Path $pluginRoot (Join-Path 'context_template/context' $rest)
      if (Test-Path $ctPath) { continue }
      $ctxPath = Join-Path $pluginRoot (Join-Path '.context' $rest)
      if (Test-Path $ctxPath) { continue }
      $findings += "$($f.FullName): dead ref $ref"
    }
  }
}
$findings
```

### Frontmatter description quality

```bash
python3 - <<'PY'
import yaml, pathlib
findings = []
for p in list(pathlib.Path("agents").glob("*.agent.md")) + \
         list(pathlib.Path("skills").glob("*/SKILL.md")):
    parts = p.read_text().split("---", 2)
    if len(parts) < 3: continue
    try:
        fm = yaml.safe_load(parts[1]) or {}
    except Exception:
        continue
    desc = (fm.get("description") or "").strip()
    name = (fm.get("name") or "").strip()
    if not desc:
        findings.append(f"{p}: empty description")
    elif desc.lower() == name.lower():
        findings.append(f"{p}: description equals name (boilerplate)")
    elif desc.upper() in ("TODO", "<DESCRIPTION>"):
        findings.append(f"{p}: placeholder description ({desc!r})")
    elif len(desc) < 20:
        findings.append(f"{p}: description too short ({len(desc)} chars; aim for ≥ 20)")
for f in findings:
    print(f)
PY
```

### Role-overlap heuristic

This is a judgment call, not a deterministic check. List every agent's `name` + first-sentence verb phrase, then surface pairs whose verb + object look similar (e.g., two agents that both "review code", two that both "manage tasks"). Examples:

- `coder` "implements features" vs `developer` "implements changes" → flag.
- `tester` "writes tests" vs `qa` "creates tests" → flag.
- `manager` "orchestrates workflows" vs `coordinator` "orchestrates work" → flag.

Report the pair, the overlapping phrase, and the recommended action: consult `agent-evaluation` for a deeper single-agent design review.

## Cross-references

When role overlap is detected, the next step is the dedicated single-agent review: invoke `agent-evaluation` against the involved agents.
