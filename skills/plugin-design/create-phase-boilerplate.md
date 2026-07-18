# Create — Phase 1: Boilerplate

## Overview

Scaffold the standard Claude Code plugin directory tree with placeholder files. The output is structurally valid — `plugin.json` parses, the tree matches conventions — but metadata is intentionally minimal; Phase 2 fills in real values.

## Output Tree

```
<plugin-root>/
├── .claude-plugin/
│   └── plugin.json
├── .gitignore
├── CHANGELOG.md
├── README.md
├── agents/
│   └── .gitkeep
├── commands/
│   └── .gitkeep
├── hooks/
│   └── .gitkeep
├── shared/
│   └── .gitkeep
└── skills/
    └── .gitkeep
```

`.gitkeep` files preserve the otherwise-empty directories under git. Drop each once a real file lands in its directory.

## Scaffold (Bash)

```bash
mkdir -p .claude-plugin agents commands hooks shared skills

cat > .claude-plugin/plugin.json <<'EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json",
  "name": "<placeholder-plugin-name>",
  "version": "0.1.0",
  "description": "<placeholder description — filled in during basic-info phase>"
}
EOF

cat > README.md <<'EOF'
# <Plugin Name>

<One-line description of what this plugin does.>
EOF

cat > CHANGELOG.md <<'EOF'
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]
EOF

cat > .gitignore <<'EOF'
# Editor / OS noise
.DS_Store
*.swp
*.swo
Thumbs.db
*.log

# Common build outputs (uncomment if your plugin builds anything)
# node_modules/
# dist/
# build/
EOF

for d in agents commands hooks shared skills; do
  touch "${d}/.gitkeep"
done
```

## Scaffold (PowerShell)

```powershell
New-Item -ItemType Directory -Force -Path .claude-plugin, agents, commands, hooks, shared, skills | Out-Null

@'
{
  "$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json",
  "name": "<placeholder-plugin-name>",
  "version": "0.1.0",
  "description": "<placeholder description — filled in during basic-info phase>"
}
'@ | Set-Content -Path .claude-plugin/plugin.json -Encoding UTF8

@'
# <Plugin Name>

<One-line description of what this plugin does.>
'@ | Set-Content -Path README.md -Encoding UTF8

@'
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]
'@ | Set-Content -Path CHANGELOG.md -Encoding UTF8

@'
# Editor / OS noise
.DS_Store
*.swp
*.swo
Thumbs.db
*.log

# Common build outputs (uncomment if your plugin builds anything)
# node_modules/
# dist/
# build/
'@ | Set-Content -Path .gitignore -Encoding UTF8

foreach ($d in 'agents','commands','hooks','shared','skills') {
  New-Item -ItemType File -Force -Path "$d/.gitkeep" | Out-Null
}
```

## Validation

Confirm the manifest parses as valid JSON:

```bash
python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))"
```

Exit code 0 with no output means the file is valid. Any exception means re-check the heredoc was written correctly.

## Cross-references

- Phase 2 (`create-phase-basic-info.md`) — fills in the placeholder `name`, `version`, `description`, and adds `author` / `license` / repository metadata.
