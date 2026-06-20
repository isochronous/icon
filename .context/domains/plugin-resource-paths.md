# Plugin Resource Paths

Reference for accessing resources bundled within the ICON plugin, across both supported AI tools (Claude Code and GitHub Copilot CLI).

---

## Path Variables by Level

### Plugin-Level (Shared Resources)

Resources at the plugin root — e.g., `context_template/` — are accessed via plugin-level path variables.

| Tool | Variable / Pattern | Notes |
|------|--------------------|-------|
| Claude Code | `${CLAUDE_PLUGIN_ROOT}` | Officially documented; inline-substituted in skill content before the AI reads it; points to the plugin root directory at install time |
| Copilot CLI | *(no official variable)* | Use deterministic install-layout path (see below) |

**Copilot CLI — Bash:**
```bash
${COPILOT_HOME:-$HOME/.copilot}/installed-plugins/icon-marketplace/ICON/<resource>
```

**Copilot CLI — PowerShell:**
```powershell
$CopilotHome = if ($env:COPILOT_HOME) { $env:COPILOT_HOME } else { "$HOME\.copilot" }
$CopilotHome\installed-plugins\icon-marketplace\ICON\<resource>
```

---

### Skill-Level (Per-Skill Resources)

Resources co-located with a specific skill's `SKILL.md` — e.g., scripts or templates bundled with one skill only.

| Tool | Variable / Pattern | Notes |
|------|--------------------|-------|
| Claude Code | `${CLAUDE_SKILL_DIR}` | Officially documented; inline-substituted; points to the skill's own directory within the plugin |
| Copilot CLI | *(no official variable)* | Files are auto-discovered and available, but no path variable is injected; construct manually (see below) |

**Copilot CLI — Bash:**
```bash
${COPILOT_HOME:-$HOME/.copilot}/installed-plugins/icon-marketplace/ICON/skills/<skill-name>/<resource>
```

---

## Decision Rule: Which Level to Use

| Situation | Use |
|-----------|-----|
| Resource is shared across multiple skills (e.g., `context_template/` used by `initialize-repo`, `upgrade-repo`, `initialize-multimodule`) | Plugin-level path |
| Resource is bundled with a single skill only (e.g., a script or template sitting next to a skill's `SKILL.md`) | Skill-level path |

---

## Sources

- `${CLAUDE_PLUGIN_ROOT}`: [Claude Code Plugins Reference — Environment Variables](https://docs.anthropic.com/en/docs/claude-code/plugins-reference#environment-variables)
- `${CLAUDE_SKILL_DIR}`: [Claude Code Skills — Available String Substitutions](https://docs.anthropic.com/en/docs/claude-code/skills)
- Copilot CLI (`COPILOT_HOME` documented; no skill-level variable): [GitHub Copilot CLI Plugin Reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference)
