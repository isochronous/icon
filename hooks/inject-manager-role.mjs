// SessionStart hook for Claude Code.
//
// Injects a small (<2 KB) read-and-adopt bootstrap as `additionalContext`
// when the current project has a `.context/` folder. Emits nothing (exit 0)
// otherwise — no-op in non-ICON projects.
//
// The bootstrap front-loads the load-bearing manager discipline and instructs
// the model to read the full role file (`agents/manager.agent.md`) and adopt
// its entire contents for the session. Keeping the payload under ~2 KB avoids
// the silent-truncation behaviour observed in Claude Code 2.1.165, which
// silently persists output >~2 KB and injects only a ~2 KB preview.
//
// The JSON envelope makes Claude Code render the bootstrap as a
// system-reminder injection rather than ordinary conversation content.
//
// Fires on SessionStart with source "startup", "resume", OR "clear" — the
// last of which re-establishes the manager role after the user runs /clear,
// ensuring the role is never lost to a context wipe.
//
// Wired in by the plugin's `hooks/hooks.json`. Manager-default is ON by
// default whenever the project is ICON-initialized; users opt out by writing
// `{ "managerDefault": false }` to `~/.claude/icon-user-settings.json` (the
// `/ICON:disable-manager-default` command writes that key for them).
//
// Single cross-platform wrapper — replaces the legacy `.sh` and `.ps1`
// variants. The `inject-manager-role` substring is preserved in this filename
// so the enable/disable commands can substring-match legacy user-settings
// entries during migration.

import { readFileSync, existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

// `SessionStart` surfaces a hook's stderr only on a NON-ZERO exit, and every
// failure path below deliberately exits 0 (hooks must fail open). A bare
// `process.stderr.write` on those paths therefore reaches the debug log and
// nothing the user sees. `systemMessage` is the documented universal exit-0
// JSON field that displays a warning line TO THE USER — distinct from
// `hookSpecificOutput.additionalContext`, which injects into Claude's context
// as a system reminder. Both may travel in the same envelope, so a warning
// never costs the injection.
//
// The stderr writes are KEPT alongside: `systemMessage` is a Claude Code
// field, and Copilot CLI's hook semantics are unestablished (ADR-004). An
// unknown JSON field is expected to be ignored there, leaving stderr as the
// fallback signal. Nothing here is claimed for Copilot CLI.
//
// This does NOT address a missing `node` — a hook that cannot spawn is never
// read and cannot report its own absence. That detection lives in the
// `check-node-runtime` skill, invoked from `icon-init` and `icon-status`.
function emit(envelope) {
  process.stdout.write(JSON.stringify(envelope) + "\n");
}

// Warn-and-stop: the role is NOT injected, but the user is told why.
function warnAndExit(message) {
  process.stderr.write(`ICON: inject-manager-role — ${message}\n`);
  emit({ systemMessage: `ICON: manager role not injected — ${message}` });
  process.exit(0);
}

// Only activate when the current project is ICON-initialized. Silent no-op is
// correct here — the hook runs in every session and most sessions will be in
// non-ICON projects.
const projectDir = process.env.CLAUDE_PROJECT_DIR;
if (!projectDir || !existsSync(join(projectDir, ".context"))) {
  process.exit(0);
}

// Honor the user-level opt-out. Absent file or absent key ⇒ default ON
// (inject). `managerDefault: false` ⇒ silent no-op. Parse error ⇒ stderr warn
// and fail open (continue with defaults).
const userSettingsPath = join(homedir(), ".claude", "icon-user-settings.json");
// Carries a user-visible warning raised on a path that CONTINUES, so it can
// ride along in the same envelope as the injection rather than replacing it.
let pendingWarning = null;
if (existsSync(userSettingsPath)) {
  try {
    const raw = readFileSync(userSettingsPath, "utf8");
    const settings = JSON.parse(raw);
    if (settings && settings.managerDefault === false) {
      process.exit(0);
    }
  } catch (err) {
    process.stderr.write(
      `ICON: inject-manager-role — could not parse ~/.claude/icon-user-settings.json (${err.message}) — proceeding with defaults.\n`,
    );
    // Worth surfacing: a file that does not parse means any `managerDefault`
    // opt-out in it is silently being ignored, which the user would otherwise
    // only notice as ICON behaving contrary to a setting they wrote.
    pendingWarning =
      `ICON: ~/.claude/icon-user-settings.json could not be parsed (${err.message}) — ` +
      `proceeding with defaults, so any setting in that file is being ignored.`;
  }
}

// Past this point the project IS ICON-initialized and the user has not opted
// out. Missing plugin state is a real problem the user should see, not a
// silent no-op.
const pluginRoot = process.env.CLAUDE_PLUGIN_ROOT;
if (!pluginRoot) {
  warnAndExit(
    "CLAUDE_PLUGIN_ROOT is not set. Reinstall the ICON plugin or report this as a bug.",
  );
}

const managerPath = join(pluginRoot, "agents", "manager.agent.md");
if (!existsSync(managerPath)) {
  warnAndExit(
    `manager agent file not found at ${managerPath}. The plugin install may be incomplete; try reinstalling ICON.`,
  );
}

// Small bootstrap (<2 KB). Front-loads the load-bearing manager discipline
// and instructs the model to read the full role file and adopt it. Keeping the
// payload under ~2 KB avoids the silent-truncation behaviour in Claude Code
// 2.1.165 (output >~2 KB is persisted but only a ~2 KB preview is injected).
//
// JSON.stringify on the wrapping object handles all string escaping
// (backslash, double-quote, tab, CR, LF, control chars) automatically.
const bootstrap = `You are operating as the ICON @manager — the workflow orchestrator. Your core constraint is load-bearing and applies from this first turn, even before you read your full role file: you orchestrate and delegate; you do NOT implement, test, review, or research directly. Always route work to the appropriate specialist sub-agent (planner, architect, coder, tester, reviewer, researcher). You do not read raw source files or run grep/shell to understand code — use .context/ or delegate. You DO directly own git operations and plan.md / .context/tasks/ artifacts. Do not begin any file edit before a feature branch and plan.md exist on disk; reading is fine, the gate is the first write.

MANDATORY FIRST ACTION: invoke the using-skills skill before anything else.

Now read ${managerPath} in full and adopt its entire contents — Session Start, Turn Start, Delegation, Constraints, Behavior Tiers, and the Anti-Rationalization table — as your authoritative operating role for the rest of this session. The Anti-Rationalization table is load-bearing: apply it before every Edit or Write. This role replaces whatever role you were previously operating under. Switch to product-manager with /ICON:pm; switch back with /ICON:manager.`;

const envelope = {
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: bootstrap,
  },
};

// The injection happened; a pending warning rides along rather than replacing it.
if (pendingWarning) {
  envelope.systemMessage = pendingWarning;
}

emit(envelope);
