# Plugin Resource Paths

Reference for accessing resources bundled within the ICON plugin, across both supported AI tools (Claude Code and GitHub Copilot CLI). This dual-path documentation is how the plugin honors ADR-004's tool-agnostic-content decision — every resource path is recorded for both runtimes even where only one exposes a native substitution variable.

---

## Path Variables by Level

### Plugin-Level (Shared Resources)

Resources at the plugin root — e.g., `context_template/` — are accessed via plugin-level path variables.

| Tool | Variable / Pattern | Notes |
|------|--------------------|-------|
| Claude Code | `${CLAUDE_PLUGIN_ROOT}` | Officially documented; inline-substituted in skill content before the AI reads it; points to the plugin root directory at install time |
| Copilot CLI | *(no official variable)* | Use deterministic install-layout path (see below) |

Hook configuration is a special case of this variable: `${CLAUDE_PLUGIN_ROOT}` only resolves inside a plugin-scoped `hooks/hooks.json`, not in every context that names it — see `domains/hooks.md` for the hook-specific scope-resolution rules.

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

> **`icon-marketplace` is a default, not a constant — and it is wrong on at least one real machine.**
> Measured 2026-08-01 on the ICON maintainer's host: the local **Claude Code** plugin cache resolves
> to `~/.claude/plugins/cache/`**`icon-local`**`/ICON/`**`1.22.0`**`/…` — a different marketplace
> slug *and* an undocumented version segment, alongside a second marketplace directory
> (`claude-plugins-official`). That is Claude Code's cache rather than Copilot's
> `installed-plugins`, so it does **not** establish that Copilot inserts a version segment; what it
> establishes is that the slug is user-local and that more than one marketplace can be installed at
> once.
>
> **For a script *invocation*, do not hand-write this pattern.** Use the hardened reconstruction in
> [executable content — invocation contract](../standards/skill-decomposition/executable-content/invocation-contract.md)
> § 3, which globs for the marketplace directory, tries a version segment as a fallback, and fails
> closed with the match count on ambiguity. This section remains the reference for the *documented
> layout*; ADR-018 records why naming the slug is no longer sufficient for an invocation.

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

## Related

- Governed by: [ADR-004: tool-agnostic content](../decisions/004-tool-agnostic-content.md)
- See also: [hooks](hooks.md) — `${CLAUDE_PLUGIN_ROOT}` scope-resolution rules specific to hook configs
- See also: [executable content — invocation contract](../standards/skill-decomposition/executable-content/invocation-contract.md) § 3 — the discovery-based form to use when the reconstructed path is invoking a script
- See also: [ADR-018 the body test, program vs command](../decisions/018-body-test-program-vs-command.md) — the measured `icon-local` counter-example, and why an invocation may not name the slug
