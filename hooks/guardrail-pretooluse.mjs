// PreToolUse guardrail hook — shared by GitHub Copilot CLI (primary) and
// Claude Code. Moves ICON's highest-risk security controls from bypassable
// prose into a harness-enforced layer. Node built-ins only (ADR-005; mirrors
// inject-manager-role.mjs).
//
// CRITICAL SAFETY: a PreToolUse hook that throws or exits non-zero makes
// Copilot fail-CLOSED → it would DENY EVERY tool call and brick the session.
// Therefore the ENTIRE body is wrapped in try/catch and the script ALWAYS
// exits 0. On any parse/IO/unknown error, empty stdin, or unrecognized input
// → write NOTHING and allow (fail-OPEN). The matcher `*` fires on every tool
// including report_intent, so the default MUST be allow.
//
// Both harnesses deliver snake_case stdin:
//   { hook_event_name, tool_name, tool_input, session_id, cwd, ... }
// Claude Code additionally sends `transcript_path`; Copilot sends `timestamp`
// and NO `transcript_path`. Output shape is selected by that presence:
//   - Claude Code: nested { hookSpecificOutput: { ..., permissionDecision } }
//   - Copilot:     top-level { permissionDecision, permissionDecisionReason }
//
// To add a control, append a rule to the RULES array below: each rule is
// { id, reason, test() -> bool|string } keying off the raw tool_name plus
// command/content already in scope; first match wins. A rule may return a
// log-safe string identifier instead of true (used by secret-in-write to
// record the matched pattern NAME without logging the secret value). See
// .context/standards/security.md → Harness-Enforced Controls.

import { readFileSync, mkdirSync, appendFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

try {
  // ---------- read + parse stdin (fail-open on anything unexpected) ----------
  let raw;
  try {
    raw = readFileSync(0, "utf8");
  } catch {
    process.exit(0);
  }
  if (!raw || raw.trim() === "") process.exit(0);

  let p;
  try {
    p = JSON.parse(raw);
  } catch {
    process.exit(0);
  }
  if (!p || typeof p !== "object") process.exit(0);

  // ---------- extract fields ----------
  const toolName = typeof p.tool_name === "string" ? p.tool_name : null;
  if (!toolName) process.exit(0);

  const command =
    p.tool_input && typeof p.tool_input.command === "string"
      ? p.tool_input.command
      : null;

  const isClaude = Object.prototype.hasOwnProperty.call(p, "transcript_path");
  const harness = isClaude ? "claude-code" : "copilot";

  const isBash = ["bash", "shell", "powershell"].includes(toolName.toLowerCase());

  // ---------- gather file-write content (for secret-in-write) ----------
  // Concatenate whichever write/edit content fields are present across both
  // harnesses (string values only): content (Claude Write), file_text (Copilot
  // Write), new_string (Claude Edit), new_str (Copilot Edit), new_source
  // (Claude NotebookEdit).
  const ti = p.tool_input && typeof p.tool_input === "object" ? p.tool_input : {};
  const writeTools = ["Write", "Edit", "NotebookEdit"];
  let writeContent = "";
  if (writeTools.includes(toolName)) {
    for (const f of ["content", "file_text", "new_string", "new_str", "new_source"]) {
      if (typeof ti[f] === "string") writeContent += ti[f];
    }
  }

  // ---------- deny rules (first match wins) ----------
  // Each rule keys off the raw tool_name plus command/content. A rule's test
  // returns either false (no match) or a truthy value; rules that need to
  // surface a matched identifier (without logging the value) may return a
  // string used as the log-safe pattern name.
  const RULES = [
    {
      id: "no-pipe-to-shell",
      reason:
        "ICON guardrail: piping a remote fetch (curl/wget) into a shell interpreter is denied — it executes unreviewed remote code. Download, inspect, then run. See .context/standards/security.md → Harness-Enforced Controls.",
      test() {
        if (!isBash || !command) return false;
        return (
          /\b(curl|wget)\b[^\n|]*\|\s*(sudo\s+)?(ba|z|da|k)?sh\b/i.test(command) ||
          /\b(sh|bash|zsh)\b\s+-c\s+["']?\$\((curl|wget)\b/i.test(command) ||
          /\beval\b[^\n]*\b(curl|wget)\b/i.test(command)
        );
      },
    },
    {
      id: "secret-in-write",
      reason:
        "ICON guardrail: a credential-like secret (API token or private key) was detected in file content being written. Do not persist secrets in files — use an environment variable or a credential placeholder (ADR-006). See .context/standards/security.md → Harness-Enforced Controls.",
      // Applies ONLY to file-write/edit tools (NEVER Bash), so tokens passed to
      // API calls via curl headers remain unaffected. Patterns are tight,
      // real-token shapes (not bare prefixes) to avoid false positives.
      test() {
        if (!writeTools.includes(toolName)) return false;
        if (typeof writeContent !== "string" || writeContent === "") return false;
        const SECRET_PATTERNS = [
          { name: "gitlab-pat", re: /glpat-[A-Za-z0-9_-]{20,}/ },
          { name: "github-token", re: /gh[pousr]_[A-Za-z0-9]{36,}/ },
          { name: "slack-token", re: /xox[baprs]-[A-Za-z0-9-]{10,}/ },
          { name: "aws-access-key", re: /AKIA[0-9A-Z]{16}/ },
          { name: "google-api-key", re: /AIza[0-9A-Za-z_-]{35}/ },
          { name: "atlassian-token", re: /ATATT[A-Za-z0-9_=.\-]{20,}/ },
          { name: "pem-private-key", re: /-----BEGIN [A-Z ]*PRIVATE KEY-----/ },
        ];
        for (const { name, re } of SECRET_PATTERNS) {
          if (re.test(writeContent)) return name;
        }
        return false;
      },
    },
  ];

  let decision = "allow";
  let matchedRule = null;
  let reason = null;
  let matchedPattern = null;
  for (const rule of RULES) {
    const result = rule.test();
    if (result) {
      decision = "deny";
      matchedRule = rule.id;
      reason = rule.reason;
      if (typeof result === "string") matchedPattern = result;
      break;
    }
  }

  // ---------- audit log (own try/catch — must never throw / fail-close) ----------
  try {
    const auditDir = join(homedir(), ".icon");
    mkdirSync(auditDir, { recursive: true });
    const entry = {
      ts: new Date().toISOString(),
      harness,
      tool: toolName,
      decision,
      rule: matchedRule,
    };
    // cmd is logged ONLY for the bash pipe-to-shell rule. The secret-in-write
    // rule must NEVER log the matched content (that would leak the secret);
    // only the log-safe pattern NAME is recorded, never the value.
    if (decision === "deny" && matchedRule === "no-pipe-to-shell" && command) {
      entry.cmd = command.slice(0, 200);
    } else if (decision === "deny" && matchedRule === "secret-in-write" && matchedPattern) {
      entry.pattern = matchedPattern;
    }
    appendFileSync(join(auditDir, "guardrail-audit.log"), JSON.stringify(entry) + "\n");
  } catch {
    // Logging failure must not affect the decision or throw.
  }

  // ---------- emit decision ----------
  if (decision === "allow") {
    process.exit(0);
  }

  if (isClaude) {
    process.stdout.write(
      JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          permissionDecision: "deny",
          permissionDecisionReason: reason,
        },
      }),
    );
  } else {
    process.stdout.write(
      JSON.stringify({
        permissionDecision: "deny",
        permissionDecisionReason: reason,
      }),
    );
  }
  process.exit(0);
} catch {
  // Absolute backstop: never throw, never fail-close. Allow.
  process.exit(0);
}
