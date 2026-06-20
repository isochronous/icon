---
name: security-review
description: >
  Use when authoring, reviewing, or about to ship a change to ICON's own infrastructure
  scripts — a `hooks/*.mjs` hook, a `.githooks/` git hook, a `skills/*/scripts/*.sh` script,
  a new enforcement gate, or any script that handles secrets, external input, or tool/command
  execution — to security-review the change against ICON's secure-coding standard before merge.
user-invocable: true
---

# Security Review

## Overview

Reviews a change to ICON's OWN shell/JS infrastructure against the `secure-coding` standard (an ICON-local standard, not mirrored into `context_template/`). This complements `code-quality-rules`, which reviews arbitrary consumer code through a generic web-app security lens; this skill is for ICON's own hooks, git hooks, and scripts — where the failure modes are fail-closed enforcement, leaked secrets, and silently-disabled gates, not SQLi/XSS.

Run it against the current diff before merging any change to a `hooks/*.mjs`, a `.githooks/` hook, a `skills/*/scripts/*.sh`, or any script touching secrets, external input, or tool/command execution.

### security-review: Checklist

Walk each gate against the diff. A "no" is a finding to fix before merge.

- **Fail-open hook** — does every enforcement/`PreToolUse` hook ALWAYS `exit 0`, emitting a deny only on a positive rule match? A throw or non-zero exit fails CLOSED and bricks the session. (Rule 1.)
- **No secret values in logs** — do gates log only the pattern NAME or a redacted reference, never the matched credential? (Rule 2.)
- **Node built-ins only** — do `.mjs` scripts import only `node:*`, with no new dependency or `package.json`? (Rule 3.)
- **Tight credential regexes** — does any new credential pattern match a real-token shape (length/charset-bounded), not a bare prefix that fires on docs and placeholders? (Rule 4.)
- **Config/env fails open** — does a missing env var or unparseable config produce a stderr warning + `exit 0` with safe defaults, never a throw? (Rule 5.)
- **`grep` dash-leading patterns** — is any pattern that can start with `-` passed via `-e` (or `--`), and tested against a known-positive fixture? An `if grep` guard hides a malformed pattern as a silent open. (Rule 6.)
- **`set -euo pipefail`** — present at the top of every bash script (except the deliberately fail-open hook bodies)? (Rule 7.)
- **No real secret in source** — every token an ADR-006 placeholder, not a real credential? (Rule 8.)
- **No new `2>/dev/null`** — no new output suppression added (grandfathered git-probes excepted)? (Rule 9.)
- **Logs outside the repo** — do operator/audit/telemetry logs write under `~/.icon/` (or similar), never the tracked tree? (Rule 10.)

### security-review: Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "It's a tiny hook tweak" | A tiny hook tweak can fail-close and brick every tool call in every session. Run the checklist. |
| "The regex obviously works" | An `if grep` guard reads a malformed pattern as "no match" — the gate fails silently-open. Test it against a positive fixture. |
| "It's only adding a log line" | A log line is exactly where secret values leak. Confirm it logs the pattern name, not the match. |
| "One `2>/dev/null` to quiet a warning" | ADR-007: stderr is diagnostic signal; suppression turns a visible failure silent. Fix the cause, don't mute it. |
| "The token in the fixture is fake enough" | "Fake enough" is what trips the secret-scan or, worse, what gets copied as real. Use an ADR-006 placeholder. |
| "Missing config can just throw" | A throw in a hook or startup script fails closed. Warn to stderr and exit 0 with safe defaults. |
| "It's a maintainer-only script, lower bar" | Maintainer scripts are the enforcement layer — their failure modes are the highest-blast-radius ones in the repo. |

## Red Flags — STOP and run this checklist

- Editing a `PreToolUse` or any enforcement/guardrail hook.
- Adding or changing a credential regex or a secret-scan pattern.
- A script that logs tool input, command strings, or anything that could carry a secret.
- Adding a new `2>/dev/null` or other output suppression.
- A `grep`/`sed` pattern whose first character can be `-`.
- A hook or startup script that reads an env var or parses a config file.

**Any of these means a secure-coding rule is in play — run the checklist before you merge.**
