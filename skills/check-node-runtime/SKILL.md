---
name: check-node-runtime
description: >
  Use when setting up ICON in a repo, when re-orienting with /icon-status, or when the ICON manager role is not being injected at session start — verifies that `node` is on PATH, reports the version plainly, and guides installation when Node is missing or past end-of-life. Also use when a shipped ICON script or a harness hook appears not to have run at all.
user-invocable: true
---

# Check Node Runtime

## Overview

ICON's harness hooks and several of its shipped helper scripts are Node scripts. If `node` is not
on PATH they do not run — and the most consequential one fails invisibly: the `SessionStart` hook
that injects the ICON manager role. **A hook that cannot start cannot report that it did not
start.** The session just proceeds without the role, and nothing says why.

ADR-005 (no build step, no test runner, no package manager) records the position this skill
implements: Node is a *strong default* for shipped scripts, not a guarantee — a bundled-runtime
install need not expose `node` on PATH — so a script that depends on Node should **verify it rather
than presume it**.

This skill is that verification. It never blocks anything: it reports, guides, and moves on.

---

## check-node-runtime: Step 1: Run the detector

One command. It is byte-identical in bash, sh, zsh, PowerShell, and cmd, so run it in whatever
shell the session already uses — there is no per-platform variant to pick and no helper script to
install.

```
node -v
```

**Read the command's output, not its exit status.** In PowerShell a command that is not found does
**not** update `$LASTEXITCODE`; it keeps whatever value the previous command left behind. Measured
on PowerShell 7.6.3: with `$LASTEXITCODE` seeded to `0`, running `node -v` with `node` absent from
PATH raised `CommandNotFoundException` and `$LASTEXITCODE` was **still `0`** afterwards. A check
written as `if ($LASTEXITCODE -ne 0)` therefore reports "Node present" when Node is absent — it
fails open, silently, which is the exact failure class this skill exists to end. This also means
capturing to a variable (`$out = node -v 2>&1 | Out-String`) yields an **empty string** in
PowerShell — the exception fires before any process starts, so there is no stream to redirect. Read
the text as it appears in the console or tool output, not from a captured variable.

---

## check-node-runtime: Step 2: Interpret what came back

| What the command emitted | Verdict |
|---|---|
| A version string on stdout — `v24.17.0`, `v18.20.4` | **Present.** Take the major number (the digits between `v` and the first `.`) and continue to Step 3. |
| `node: command not found` (exit 127) | **Absent** — bash, sh, zsh, and other POSIX shells. |
| Output containing `is not recognized as` (wording varies by version — PS 7 says "...as a name of a cmdlet, function, script file, or executable program.", PS 5.1 says "...as the name of a cmdlet, function, script file, or operable program.") | **Absent** — PowerShell. Match the stable substring, not the full sentence. `$LASTEXITCODE` is unreliable here; see Step 1. |
| `'node' is not recognized as an internal or external command` (errorlevel 9009) | **Absent** — cmd.exe. |
| Anything else | Treat as **absent** and quote the output verbatim in the Step 4 report. Do not guess at what it meant. |

---

## check-node-runtime: Step 3: Apply the version floor

There are two floors and they mean different things. Do not collapse them into one "too old".

- **Technical floor — below this the hooks stop running.** ICON's hooks are plain ES modules that
  import only Node builtins via `node:`-prefixed specifiers. Those specifiers arrived in the Node
  12.20 / 14.13 line; below that the imports fail outright. Nothing in the hooks has needed a
  command-line flag on any release since.
- **Supported floor — the lowest Node major still receiving security updates.** This is neither a
  syntax requirement nor something Claude Code imposes. **ICON sets it**, on one ground: a release
  past end-of-life receives no security updates. Measured against
  nodejs.org/en/about/previous-releases on 2026-07-28, that floor is **Node 22** — Node 18 and
  Node 20 have both since reached end-of-life. Recheck that page before trusting this number if
  it's been a while; the floor moves roughly once a year and nothing here re-derives it
  automatically.

Between the two floors the hooks still run. The warning there is about running an unpatched,
end-of-life runtime — not about breakage. Report which of the two applies.

---

## check-node-runtime: Step 4: Report the result — always visibly

Emit exactly one of these, as plain output the user reads. Never report a pass by staying silent:
a silent no-op is indistinguishable from the skill not having run.

**Node present, at or above the supported floor:**

```
Node runtime: OK — <version reported by node -v>
```

**Node present, below the supported floor:**

```
Node runtime: <version> — below ICON's supported floor (Node <floor major from Step 3>).
ICON's hooks will still run on this version, but Node <major> is past end-of-life and
receives no security updates. Upgrading to a current LTS release is recommended.
```

**Node absent:**

```
Node runtime: NOT FOUND — `node` is not on PATH.
ICON's session-start hook cannot run, so the manager role will not be injected
automatically, and shipped Node helper scripts will not run either.
Everything else in ICON still works; you can switch roles manually with /ICON:manager.
```

Then continue to Step 5.

---

## check-node-runtime: Step 5: Guide the install (absent case only)

Offer the option matching the user's platform. Do not run an installer without being asked.

| Platform | Suggested install |
|---|---|
| macOS | `brew install node`, or the official installer from `nodejs.org` |
| Windows | `winget install OpenJS.NodeJS.LTS`, or the `.msi` from `nodejs.org` |
| Debian / Ubuntu | The NodeSource repository, or a version manager. The distro's own `nodejs` package is often several major versions behind. |
| Any platform | A version manager — `nvm`, `fnm`, or `volta` — if the user juggles Node versions per project |

Two things worth telling the user, because both produce a "but I have Node installed" that is still
a genuine miss:

- **A Node bundled inside another application does not count.** An app that ships its own runtime
  need not expose `node` on PATH. That case is precisely why ADR-005 downgrades Node from a
  guarantee to a default worth checking.
- **PATH changes do not reach an already-running shell.** After installing, open a new terminal —
  and, for the hook specifically, start a new session — then re-run `node -v` to confirm.

---

## When the manager role is not being injected

If Node is present and the manager role still is not injecting, the session-start hook may be
failing to spawn for some other reason. The hook itself cannot tell you — it never executed — but
the harness records the failure in two places. Both are Claude Code paths; Copilot CLI's hook
semantics are not established, so nothing here is claimed for it.

| Where to look | What you get |
|---|---|
| `--output-format stream-json` | The `hook_response` event carries the harness's synthesized message — e.g. `Executable not found in $PATH: …` — with a non-zero `exit_code` and `outcome: "error"`. Requires a client new enough to emit hook stream events. |
| `--debug-file <path>` | A distinct `[ERROR] Hook command failed to spawn (SessionStart:startup)` line. A hook that *did* spawn and then exited non-zero does not produce this line, so it specifically identifies the could-not-execute case. |

Two limits worth knowing before you go looking:

- **Plain `-p` (headless) mode surfaces nothing** for either failure class — neither a hook that
  could not spawn nor one that spawned and exited non-zero. Absence of a message in `-p` output is
  not evidence the hook ran.
- **Client version matters.** Before Claude Code v2.1.199, `SessionStart` stderr went to the debug
  log only — silent by design, not a bug. `/doctor` is not a substitute: it validates hook
  configuration *shape*, so it never reports a hook that failed at runtime.

---

## Common Mistakes

| Mistake | Fix |
|---|---|
| Checking the exit status instead of the output | PowerShell leaves `$LASTEXITCODE` stale when a command is not found, so the check passes with Node absent. Read what the command printed (Step 2). |
| Writing a `.mjs` script to detect whether Node is available | Self-defeating — it cannot run in the case it is meant to detect. `node -v` is the detector. |
| Reaching for `python3` as the Node-free fallback | ADR-005 records `python3` as **not** an assumed runtime; on Windows it resolves to a non-executing Store stub. |
| Reporting nothing when Node is present | A silent pass is indistinguishable from the skill never running. Always emit the Step 4 line. |
| Blocking initialization or a session because Node is missing | This skill reports; it never gates. The harness must fail open — the signal is a message, never a block. |
| Treating "below the supported floor" as breakage | Between the technical and supported floors the hooks run fine. Say which floor was missed (Step 3). |
