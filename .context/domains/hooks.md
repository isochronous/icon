# Hooks Domain

How ICON wires Claude Code lifecycle hooks, what variables resolve where, and the user-level opt-out file.

## Hook Scopes — Where `${CLAUDE_PLUGIN_ROOT}` Resolves

Claude Code reads hook configurations from three places. They are NOT interchangeable.

| Scope | File | `${CLAUDE_PLUGIN_ROOT}` resolves? | Use for |
|-------|------|-----------------------------------|---------|
| **Plugin** | `<plugin-root>/hooks/hooks.json` | ✅ Yes | Hooks that ship with the plugin and must follow the installed version |
| **User** | `~/.claude/settings.json` | ❌ No | User-defined hooks not plugin-associated |
| **Project** | `<project>/.claude/settings.json` | ❌ No | Project-local hooks not tied to a plugin |

`${CLAUDE_PLUGIN_ROOT}` (and any other plugin-scoped substitution variable) is substituted **only** when the hook entry is declared inside a plugin's own `hooks/hooks.json` (or another plugin-scoped file like `agents/`, `skills/`, `commands/`). Declaring the same entry in user-scope `~/.claude/settings.json` produces this error at session start:

```
Hook command references ${CLAUDE_PLUGIN_ROOT} but the hook is not associated with a plugin. This variable is only available in hooks defined in a plugin's hooks/hooks.json file, not in <user settings>
```

**Rule for any skill or command that writes hook configuration:** the destination scope dictates which substitution variables you may use. A `${CLAUDE_PLUGIN_ROOT}` entry in user-scope settings is broken at runtime. If you need plugin-relative paths in a hook, the hook MUST live in `hooks/hooks.json` inside the plugin.

**Precedent (ICON-0012):** `/ICON:enable-manager-default` originally wrote a `${CLAUDE_PLUGIN_ROOT}`-bearing entry into `~/.claude/settings.json`; every session failed with the error above. Fix: move the wiring into the plugin's own `hooks/hooks.json` and have the slash command toggle a separate opt-out key instead.

## Cross-Platform Hooks: Single Node.js Wrapper

Claude Code's plugin `hooks/hooks.json` has **no per-platform conditional**. The fields `os`, `platform`, `when`, `runIf`, and `condition` are not in the schema. The only conditional (`if`) is restricted to tool events (PreToolUse/PostToolUse), not SessionStart.

Listing multiple hook entries for the same event does NOT act as a fallback — they all run in parallel inside the matcher group. So a `hooks.json` listing both a `.sh` and a `.ps1` handler for SessionStart executes BOTH on any host where both interpreters exist (WSL, macOS with PowerShell, Git-Bash on Windows).

**The supported pattern is a single Node.js wrapper.** Node.js is a safe assumption — Claude Code is itself a Node.js CLI, so `node` is always on PATH wherever Claude Code runs. The plugin's `hooks.json` invokes the wrapper in exec form:

```json
{
  "type": "command",
  "command": "node",
  "args": ["${CLAUDE_PLUGIN_ROOT}/hooks/wrapper.mjs"]
}
```

This is also the [community-endorsed pattern](https://claudefa.st/blog/tools/hooks/cross-platform-hooks) Anthropic links from its plugins reference.

**Rule for any new plugin-scoped hook:** start with a `.mjs` file. Do not add a parallel `.sh` or `.ps1` script. Beyond the dual-run trap above, prior retrospectives also warn about `.sh`/`.ps1` parity drift — a single Node.js wrapper structurally eliminates it.

## Plugin Hook File Layout

| File | Purpose |
|------|---------|
| `hooks/hooks.json` | Single source of truth for hook wiring. Declares the event, matcher, and handler shape. |
| `hooks/<name>.mjs` | The cross-platform implementation script. One per logical hook. |

ICON currently ships one hook:

| Hook | Event | Matcher | Wrapper | Purpose |
|------|-------|---------|---------|---------|
| inject-manager-role | `SessionStart` | `startup\|resume` | `hooks/inject-manager-role.mjs` | Inject a small read-and-adopt bootstrap (as `system-reminder` context) directing the model to load `agents/manager.agent.md` and adopt the full role, in projects with a `.context/` folder. |

The `inject-manager-role` substring is load-bearing in the wrapper's filename — `/ICON:enable-manager-default` and `/ICON:disable-manager-default` substring-match this token when cleaning up legacy entries from `~/.claude/settings.json`. Do not rename the wrapper without also updating the migration logic in those commands.

**Authoring note — SessionStart context-injection hooks (ICON-0061):**

- **Stay under the ~2 KB ceiling.** Claude Code silently truncates an oversized `additionalContext`: output above ~2 KB is persisted to a file and only a ~2 KB preview reaches the model, with **no stderr warning**. Keep the injected payload small. Prefer the **read-and-adopt-a-file pattern** — inject a short bootstrap pointing the model at a canonical file to load in full — over inlining large role/context content. (This is the shape `inject-manager-role.mjs` and `/ICON:manager` both use.)
- **Emit resolved absolute paths, never `${CLAUDE_PLUGIN_ROOT}`, for any path the downstream model will consume.** The hook process and consuming model run in different environments; the literal variable would not expand downstream. Resolve the path inside the hook (e.g. `join(process.env.CLAUDE_PLUGIN_ROOT, ...)`) and inject the resolved string.

## User-Level Config: `~/.claude/icon-user-settings.json`

ICON owns a separate user-level config file at `~/.claude/icon-user-settings.json` — a flat JSON object whose keys toggle ICON behaviors the user opted into per-machine.

| Key | Type | Default (key absent) | Effect |
|-----|------|----------------------|--------|
| `managerDefault` | boolean | `true` (manager-default ON) | When `false`, `inject-manager-role.mjs` exits silently — manager role is not injected at session start. `/ICON:manager` still works as a manual switch. |

**Why a separate file:** keeping ICON's user-level toggles out of `~/.claude/settings.json` (a) avoids polluting a file the user and other tools also write, and (b) lets an ICON uninstall clean up by deleting one file. The current rewrite of `/ICON:enable-manager-default` and `/ICON:disable-manager-default` migrates any pre-1.16 entry out of `~/.claude/settings.json` automatically.

**Schema discipline:**

- Top-level object only — no nested namespaces.
- Add new keys here rather than scattering preferences across files or polluting `~/.claude/settings.json`.
- Document every new key in the table above when adding it. Anyone consuming the key (hook script, slash command, agent) must tolerate the absent-file and absent-key cases with the documented default.
- Parse failures must fail open — emit a stderr warning and proceed with defaults. A malformed user settings file should never block a session start.

**Read pattern (hook scripts):**

```js
import { readFileSync, existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const settingsPath = join(homedir(), ".claude", "icon-user-settings.json");
if (existsSync(settingsPath)) {
  try {
    const settings = JSON.parse(readFileSync(settingsPath, "utf8"));
    if (settings && settings.managerDefault === false) {
      process.exit(0); // user opted out
    }
  } catch (err) {
    process.stderr.write(
      `ICON: could not parse ${settingsPath} (${err.message}) — proceeding with defaults.\n`,
    );
  }
}
```

**Write pattern (slash commands):**

- Read the file if it exists; if missing or empty, treat as `{}`.
- Preserve every other top-level key verbatim. Do not reorder.
- Match detected indentation when writing back (2-space, 4-space, or tabs); default to 2-space for new files.
- Refuse to overwrite a file that does not parse as JSON — surface the parse error and stop.

See `commands/enable-manager-default.md` and `commands/disable-manager-default.md` for the canonical write-side implementation, including the legacy-entry migration step.

## Where the Authoritative Reference Lives

- **Claude Code plugin hook schema and behavior**: see `.context/cache/claude-code-plugin-hooks-2026-05-20.md` for the cached reference summarizing the official docs (plugins reference, hooks reference) plus the cross-platform-hooks community pattern. Cache TTL is governed by `iconrc.json` (`cache_expires_after_days`).
- **Cache-prune authoring rule (ICON-0066)**: age-based file-prune loops in `prune-context.sh` must exclude dotfile dir-keepers (`.gitkeep`, `.keep`), or they delete the directory marker and re-churn it on every commit. The guard `[[ "$(basename "$file")" == .* ]] && continue` lives at the top of the cache loop in both copies: `.context/workflows/prune-context.sh` and `context_template/context/workflows/prune-context.sh`.
- **Template-version companion-bump planning rule (ICON-0044 / ICON-0069)**: any staged add, modify, or delete under `context_template/` requires a companion `version` bump in `context_template/context/iconrc.json` in the same commit — the ICON-0044 block of `.githooks/pre-commit` enforces it (release-aware against the `main` merge-base baseline per ICON-0062). When **planning** any task touching `context_template/`, list this bump as a required companion edit up front, not a staging-time surprise — the @architect "Key Files" list must enumerate it. This is the TEMPLATE-distribution version driving consumers' `/upgrade-repo`, distinct from the plugin release version (`.claude-plugin/plugin.json`, ADR-003), which stays untouched mid-task. The cadence rule (once-per-release, not once-per-task) lives in `.context/workflows/branching.md § Template-Version Bump Cadence`.
- **Why this approach was chosen (ICON-0012)**: `.context/tasks/ICON-0012-plugin-scoped-manager-default-hook/plan.md` records the decision points (plugin-scope vs user-scope, single Node.js wrapper, opt-out file) at migration time.

## Pre-commit Gate Coupling — Sequencing Multi-Surface Commits (ICON-0080)

When a task stages changes across `agents/`, `README.md`, and `skills/` together, the `.githooks/pre-commit` gates are **coupled**, so commit-split order matters. Plan the sequence up front rather than discovering a blocked commit mid-task:

- **README skill-registration gate (O-V1)**: every `skills/<name>/` directory with a `SKILL.md` must have an anchored table row (`^| \`<name>\` |`) in `README.md`. The check fires whenever any `skills/**` path **or** `README.md` is staged, and aborts if any skill lacks its row. Consequence: when adding or **renaming** a skill, the `README.md` row must land in the same commit as (or before) the `skills/` change — committing the renamed skill folder before updating `README.md` is blocked.
- **common-constraints re-injection re-stages agent files**: the byte-equality sync (see § Sync mechanism in `domains/skill-system.md`) re-stages every `agents/*.agent.md` it touches on **every** commit. A commit intended to carry only `skills/` work can therefore sweep in agent-file edits. Commit `agents/` (and `README.md`) **before** `skills/` so each commit's contents stay intentional.
- **Template-version invariant (ICON-0044/0069)**: see the companion-bump rule above — any `context_template/` change needs its `iconrc.json` version bump in the same commit.

**Rule**: for a sweep touching all three surfaces, sequence the commits `agents/` + `README.md` first, then `skills/`. Knowing the gate coupling before sequencing avoids a blocked or contents-polluted commit.
