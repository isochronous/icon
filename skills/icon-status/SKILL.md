---
name: icon-status
description: >
  Use when re-orienting in a repo — shows active task, current branch, recent retrospectives, and context coverage. Run when returning to a repo after a break or before planning new work.
user-invocable: true
---

# ICON Status

## Overview

Emit a concise plugin-state dashboard for the current repo: active task, recent
retrospectives, and context health. Use before planning new work or after a break.

**Runtime.** Steps 1 and 2 hold twenty fences: **one inline `node -e` command** (Step 1's
fresh-repo guard), **eight committed `.mjs` scripts** invoked through a fence pair each (Step 2's
data gathering), the bare `node -v` probe, and two message templates you *emit* rather than run
(Step 1's `/icon-init` text and Signal 2's suggestion line).

**Precondition — confirm Node is present before running any of them.** Run the `node -v` probe in
Step 2 and **read its output, not its exit status**: PowerShell leaves `$LASTEXITCODE` stale when a
command is not found, so an exit-status check reports "Node present" when Node is absent. If Node is
absent, do not run the guard and do not run the scripts — invoke **`check-node-runtime`**, which
reports what stops working and offers a per-platform install without running one. The dashboard then
degrades to its `Node — not found` line plus Signal 2's suggestion.

**Shell.** The eight scripts are invoked as `node "<absolute path>"`. That form has no quote *inside*
an argument value, and it was measured running correctly in bash, PowerShell 7 **and Windows
PowerShell 5.1**. Step 1's inline command is the one exception: 5.1 does not escape the `"` embedded
in a single-quoted native-command argument, so it reaches Node with the quotes deleted and dies at
parse time with a visible `SyntaxError` and empty stdout. **Run Step 1 in bash or PowerShell 7.** The
`node -v` probe carries no quotes and runs everywhere.

**Every block prints at least one line. Empty stdout means the block did not run — never that it ran
and found nothing.** Node being present does not establish that a block ran: a stripped quote on 5.1
and an unresolved script path both produce zero bytes of stdout with Node installed, and neither is
caught by an exit-status check (measured: PowerShell 7 with `node` off `PATH` leaves `$LASTEXITCODE`
at **0**). So every block whose "nothing to report" state used to be silence now prints an
affirmative token instead — Step 1 prints `INITIALIZED` or `NOT_INITIALIZED`, and the Step 2 scripts
print a line beginning `OK ` (each block's outcomes table lists its own). **A line beginning `OK ` is
liveness, not content: never render one on the dashboard.** A block that printed nothing is **not
run** — report it that way, and do not read it as clean.

## When to Use

- Returning to a repo after a break, to see where things stand
- About to plan new work and need to check context health

**Do not use** to inspect a specific task's details — read `.context/tasks/<TASK-DIR>/plan.md`
directly for that.

---

## icon-status: Step 1: Fresh-repo guard

Check whether `.context/` exists in the current working directory. It prints **exactly one token,
always**: `NOT_INITIALIZED` when `.context/` is absent or is not a directory, `INITIALIZED` when it
is a directory.

**Require one of the two tokens. Anything else — including nothing at all — is a failed guard, not a
pass.** This is the one block in the skill where reading silence as a pass costs a *hard stop*
rather than a dashboard line: a repo with no `.context/` would get a full dashboard rendered for it.
Printing on both branches is what removes that inversion — silence is no longer a state the guard
can legitimately produce, so it can only mean the guard never reached the filesystem. Fix the shell
or the runtime and re-run; do not read it as initialized.

**This block stays inline on purpose.** Under ADR-018's body test it is a *command*, not a program —
it declares no named callable and has no braced body holding two or more statements — so it does not
move to `scripts/`. Inline `node -e` runs as **CommonJS**, which is why it uses `require("fs")` and
not an `import`. **Run it in bash or PowerShell 7** (see **Runtime**); on Windows PowerShell 5.1 it
dies at parse time, and the token requirement above is what turns that into a visible failure
instead of a false pass.

```
node -e '
const fs = require("fs");
let isDir = false;
try { isDir = fs.statSync(".context").isDirectory(); } catch (e) { isDir = false; }
process.stdout.write(isDir ? "INITIALIZED\n" : "NOT_INITIALIZED\n");
'
```

| stdout | Exit | Meaning | Caller does |
|---|---|---|---|
| `INITIALIZED` | 0 | `.context/` is present and is a directory | Continue to Step 2 |
| `NOT_INITIALIZED` | 0 | `.context/` is absent, or is not a directory | Emit the message below and **halt** |
| anything else, **including empty** | any | The guard did not run | **Halt.** Report the guard as not-run — never as a pass |

If the token is `NOT_INITIALIZED`, emit the following message and **halt — do not
attempt to render the dashboard**:

```
This repo is not yet ICON-initialized. Run `/icon-init` to set up — it detects your repo type automatically.
```

---

## icon-status: Step 2: Gather data

Run each block below. No block fails on missing data, and **every one of them prints at least one
line.** Three carry real content on every path: repo name (`(unknown)` at worst), branch/task
(`BRANCH=`/`TASK_ID=`, either possibly empty), and `iconrc.json` (`not found` or `version
(unreadable)` at worst). The other five have a legitimate "nothing to report" outcome — an absent
context subdirectory, a `retrospectives.md` with no task-ID headings, a Suggestions signal that does
not fire — and each of those prints an `OK …` token to say so rather than staying silent. **An `OK …`
line is liveness, not content: never render one.** Each block's own paragraph and outcomes table
state everything it can produce.

**The `node -v` probe is in neither bucket**: it is not one of the eight scripts, and empty stdout
from it means *not found* — a reportable value, never an omission, which is why the Step 3 table
lists the `Node` line, like the `iconrc.json` line, as never omitted.

**The eight are independently runnable.** Each is its own process and re-derives every input it
needs from scratch; none reads a variable another block set, so run them in any order. A block's
result is its **stdout**; **diagnostics go to stderr** and are never part of the result. Signal 2 is
the one item in this step that depends on another — it reads the `node -v` output instead of running
a program of its own.

**Where the eight live, and why.** Each is a committed `.mjs` under this skill's own `scripts/`
directory. Under ADR-018's body test they are *programs*, not commands — each declares a named
callable it calls, or has a braced branch holding two or more statements — and a program's home is a
file. Two of them, `branch-and-task.mjs` and `suggest-stale-plan.mjs`, import
`scripts/task-lookup.mjs`, which holds the branch probe, the task-ID regex and the `plan.md` walker
they both need. **`task-lookup.mjs` is not an entry point** — it is never invoked directly, and
importing it does not make either caller depend on the other having run.

**Invoking them.** Every block below carries two fences. Use the one for your harness:

- **Claude Code** — untagged. `${CLAUDE_SKILL_DIR}` is substituted before you read this file, so what
  you see is already an absolute path. Run it as-is.
- **Copilot CLI** — `bash`. Copilot exposes no path variable, so the fence reconstructs the install
  directory by searching every installed marketplace. Set `MARKETPLACE_NAME=<slug>` to pin one. If it
  finds anything other than exactly one match it **refuses and names the count** rather than guessing;
  that refusal is a failed block, not an empty result.

Run every block from the repo root — each script resolves `.context/` against the working directory —
and confirm Node is present first (see **Runtime** above).

### Repo name

`repo-name.mjs` prints one line — the repo name. Three sources are tried in order, stopping at the
first that yields a value: the `origin` remote URL (last path segment, `.git` stripped), the
basename of the git top-level directory, then `(unknown)`. A git failure at any rung is a
diagnostic: it goes to stderr and the chain falls through, so an error message can never reach
the dashboard as the repo's name.

#### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/repo-name.mjs"
```

#### Copilot CLI (Bash)

```bash
# Resolve this skill's install directory. Set MARKETPLACE_NAME=<slug> to pin one marketplace;
# otherwise every installed marketplace is searched and an ambiguous result fails closed.
ROOT="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins"
S="icon-status"; P="scripts/repo-name.mjs"
if [ -n "${MARKETPLACE_NAME+x}" ]; then G="$MARKETPLACE_NAME"; else G="*"; fi
F=""; N=0
for f in "$ROOT"/$G/ICON/skills/"$S/$P" "$ROOT"/$G/ICON/*/skills/"$S/$P"; do
  [ -f "$f" ] || continue; F="$f"; N=$((N+1))
done
[ "$N" = 1 ] || { echo "ICON: $N matches for $S/$P under $ROOT (marketplace ${MARKETPLACE_NAME-<any>}) — set MARKETPLACE_NAME; see: copilot plugin list" >&2; exit 1; }
node "$F"
```

#### Outcomes

| stdout | Exit | Meaning | Caller does |
|---|---|---|---|
| a repo name | 0 | One of the first two rungs yielded a value | Use it as `<REPO_NAME>` |
| `(unknown)` | 0 | Both rungs came back empty. stderr says why, if git spoke | Use `(unknown)` as `<REPO_NAME>` |
| *(empty)* | any | The block did not run | Report the repo name as not-gathered; do not substitute a guess |

Never omitted, and there is no `OK` token here — this block prints content on every path, so empty
stdout can only mean it did not run.

### Current branch and active task

`branch-and-task.mjs` reports branch, task ID and plan file in one block because each is derived
from the one before: the task ID comes from the branch name, the plan file from the task ID. It
prints two or three `KEY=value` lines:

| Line | Meaning |
|---------|---------|
| `BRANCH=<name>` | Checked-out branch. Empty outside a git repo (git's own error goes to stderr). |
| `TASK_ID=<id>` | First `PROJ-123`-style ID in the branch name; empty when there is none. |
| `PLAN_FILE=<path>` / `PLAN_FILE=(none)` | The task's `plan.md`. **Omitted entirely when `TASK_ID` is empty** — there is nothing to look up. |

The lookup scans `.context/tasks/` one and two levels deep for an entry named `plan.md` whose
path contains the task ID. When more than one matches, the paths are **sorted** and the first is
taken — the pre-Node original took whichever the filesystem happened to return first, which is not
reproducible.

#### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/branch-and-task.mjs"
```

#### Copilot CLI (Bash)

```bash
# Resolve this skill's install directory. Set MARKETPLACE_NAME=<slug> to pin one marketplace;
# otherwise every installed marketplace is searched and an ambiguous result fails closed.
ROOT="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins"
S="icon-status"; P="scripts/branch-and-task.mjs"
if [ -n "${MARKETPLACE_NAME+x}" ]; then G="$MARKETPLACE_NAME"; else G="*"; fi
F=""; N=0
for f in "$ROOT"/$G/ICON/skills/"$S/$P" "$ROOT"/$G/ICON/*/skills/"$S/$P"; do
  [ -f "$f" ] || continue; F="$f"; N=$((N+1))
done
[ "$N" = 1 ] || { echo "ICON: $N matches for $S/$P under $ROOT (marketplace ${MARKETPLACE_NAME-<any>}) — set MARKETPLACE_NAME; see: copilot plugin list" >&2; exit 1; }
node "$F"
```

#### Outcomes

| stdout | Exit | Meaning | Caller does |
|---|---|---|---|
| `BRANCH=`+`TASK_ID=`+`PLAN_FILE=<path>` | 0 | A task branch with a plan file | Render `Active task` and the `Plan` line |
| `BRANCH=`+`TASK_ID=`+`PLAN_FILE=(none)` | 0 | A task branch whose `plan.md` was not found | Render `Active task`, **omit** the `Plan` line |
| `BRANCH=`+`TASK_ID=` only | 0 | No task ID in the branch, so nothing to look up | **Omit** the `Plan` line — same handling as `(none)` |
| *(empty)* | any | The block did not run | Report branch and task as not-gathered; do not infer them from the shell |

Then apply the branch rule:

- If `BRANCH` is `main`, `dev`, or `master`: the active task section reads
  "No active task branch."
- Otherwise: report `TASK_ID` (if matched) and use `PLAN_FILE` for the dashboard's
  `Plan` line — `(none)`, or no `PLAN_FILE` line at all, means omit that line.

There is no `OK` token here — this block prints at least two lines on every path, so empty stdout can
only mean it did not run.

### Recent retrospectives (last 3 entries)

`recent-retrospectives.mjs` prints up to three `### TASK-ID` heading lines from
`.context/retrospectives.md` **in file order** — that file is newest-first, so the first three *are*
the most recent three. Do not sort them and do not take the last three. If the file is absent it
prints `(no retrospectives.md)`; if the file is present but holds no task-ID headings it prints
`OK no-retrospective-entries`.

#### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/recent-retrospectives.mjs"
```

#### Copilot CLI (Bash)

```bash
# Resolve this skill's install directory. Set MARKETPLACE_NAME=<slug> to pin one marketplace;
# otherwise every installed marketplace is searched and an ambiguous result fails closed.
ROOT="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins"
S="icon-status"; P="scripts/recent-retrospectives.mjs"
if [ -n "${MARKETPLACE_NAME+x}" ]; then G="$MARKETPLACE_NAME"; else G="*"; fi
F=""; N=0
for f in "$ROOT"/$G/ICON/skills/"$S/$P" "$ROOT"/$G/ICON/*/skills/"$S/$P"; do
  [ -f "$f" ] || continue; F="$f"; N=$((N+1))
done
[ "$N" = 1 ] || { echo "ICON: $N matches for $S/$P under $ROOT (marketplace ${MARKETPLACE_NAME-<any>}) — set MARKETPLACE_NAME; see: copilot plugin list" >&2; exit 1; }
node "$F"
```

#### Outcomes

| stdout | Exit | Meaning | Caller does |
|---|---|---|---|
| one to three `### TASK-ID …` lines | 0 | The most recent entries, already in the right order | Render them under "Recent retrospectives" verbatim, unsorted |
| `(no retrospectives.md)` | 0 | The file is absent | **Omit** the "Recent retrospectives" section |
| `OK no-retrospective-entries` | 0 | The file is present, no task-ID headings in it | **Omit** the section. Do not render the token |
| *(empty)* | any | The block did not run | Report retrospectives as not-gathered — **not** as "none found" |

### Context health

`context-health.mjs` prints, for each of six known `.context/` subdirectories, one indented line
carrying the count of `.md` files directly inside — and **no line at all** for a subdirectory that is
absent, which is how the dashboard omits it. When none of the six is present it prints
`OK no-context-subdirectories` rather than nothing. Dot-prefixed names such as `.hidden.md` **are**
counted; a symlink pointing at a `.md` file is **not**, because it is a link and not a file. A
subdirectory that is itself a symlink is followed and the files behind it are counted. A
subdirectory that exists but cannot be listed reports `— 0 files`, not an omission: it is present,
and the count is what could not be established.

#### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/context-health.mjs"
```

#### Copilot CLI (Bash)

```bash
# Resolve this skill's install directory. Set MARKETPLACE_NAME=<slug> to pin one marketplace;
# otherwise every installed marketplace is searched and an ambiguous result fails closed.
ROOT="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins"
S="icon-status"; P="scripts/context-health.mjs"
if [ -n "${MARKETPLACE_NAME+x}" ]; then G="$MARKETPLACE_NAME"; else G="*"; fi
F=""; N=0
for f in "$ROOT"/$G/ICON/skills/"$S/$P" "$ROOT"/$G/ICON/*/skills/"$S/$P"; do
  [ -f "$f" ] || continue; F="$f"; N=$((N+1))
done
[ "$N" = 1 ] || { echo "ICON: $N matches for $S/$P under $ROOT (marketplace ${MARKETPLACE_NAME-<any>}) — set MARKETPLACE_NAME; see: copilot plugin list" >&2; exit 1; }
node "$F"
```

#### Outcomes

| stdout | Exit | Meaning | Caller does |
|---|---|---|---|
| one to six `  .context/<name>/ — N files` lines | 0 | Those subdirectories are present; the rest are absent | Render each line under "Context health" |
| `OK no-context-subdirectories` | 0 | None of the six exists | **Omit** the "Context health" subdirectory lines. Do not render the token |
| *(empty)* | any | The block did not run | Report context health as not-gathered — **not** as "no subdirectories" |

### iconrc.json

`iconrc-version.mjs` prints exactly **one** line, always — `version <X.Y>`, `not found`, or
`version (unreadable)`. There is no fourth outcome and no silent one.

The empty-result guard is the point of the block, not a detail of it: **an empty read must never
reach the dashboard as a value**, because `version ` with nothing after it reads as a healthy
line. An absent, non-string or empty `version`, and a file that will not parse, all resolve to
the one visible token `(unreadable)` — with the reason on stderr, never on stdout.

#### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/iconrc-version.mjs"
```

#### Copilot CLI (Bash)

```bash
# Resolve this skill's install directory. Set MARKETPLACE_NAME=<slug> to pin one marketplace;
# otherwise every installed marketplace is searched and an ambiguous result fails closed.
ROOT="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins"
S="icon-status"; P="scripts/iconrc-version.mjs"
if [ -n "${MARKETPLACE_NAME+x}" ]; then G="$MARKETPLACE_NAME"; else G="*"; fi
F=""; N=0
for f in "$ROOT"/$G/ICON/skills/"$S/$P" "$ROOT"/$G/ICON/*/skills/"$S/$P"; do
  [ -f "$f" ] || continue; F="$f"; N=$((N+1))
done
[ "$N" = 1 ] || { echo "ICON: $N matches for $S/$P under $ROOT (marketplace ${MARKETPLACE_NAME-<any>}) — set MARKETPLACE_NAME; see: copilot plugin list" >&2; exit 1; }
node "$F"
```

#### Outcomes

| stdout | Exit | Meaning | Caller does |
|---|---|---|---|
| `  .context/iconrc.json — version <X.Y>` | 0 | A usable non-empty string `version` | Render the line |
| `  .context/iconrc.json — not found` | 0 | The file is absent | Render the line. Signal 3 will also fire |
| `  .context/iconrc.json — version (unreadable)` | 0 | Present but unparseable, or `version` absent / non-string / empty. **stderr carries the reason** | Render the line. Do **not** put the stderr reason on the dashboard |
| *(empty)* | any | The block did not run | Report the line as not-gathered — **never** as a blank version |

There is no `OK` token here — this block prints content on every path, so empty stdout can only mean
it did not run.

### Node runtime

ICON's session-start hook is a Node script, so a missing `node` silently costs the manager role.
Probe for it here. The command is identical in every shell — run it as-is, in whatever shell the
session uses:

```
node -v
```

Report the version string on the dashboard's `Node` line. **Read the output, not the exit status**
— PowerShell leaves `$LASTEXITCODE` stale when a command is not found. If the output is a
not-recognized / command-not-found message rather than a version, record `Node: not found`.

Do not interpret further here — the Suggestions signal below routes to `check-node-runtime` when
there is something to say.

### Suggestions

Evaluate the following signals and collect any that apply into a suggestions list. **Each signal
prints exactly one line, always**: its suggestion line (beginning `- `) when it fires, or an `OK …`
token when it does not. A signal that printed nothing did not run — collect no suggestion from it and
report it as not-evaluated, because a signal that silently never fires is the exact failure this
section exists to avoid.

**Signal 1: `.context/domains/` missing or empty.** `suggest-domains.mjs` prints one of two
suggestion lines, or `OK domains-populated` when `.context/domains/` exists and holds at least one
`.md` file. It counts files exactly as the Context health block does.

#### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/suggest-domains.mjs"
```

#### Copilot CLI (Bash)

```bash
# Resolve this skill's install directory. Set MARKETPLACE_NAME=<slug> to pin one marketplace;
# otherwise every installed marketplace is searched and an ambiguous result fails closed.
ROOT="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins"
S="icon-status"; P="scripts/suggest-domains.mjs"
if [ -n "${MARKETPLACE_NAME+x}" ]; then G="$MARKETPLACE_NAME"; else G="*"; fi
F=""; N=0
for f in "$ROOT"/$G/ICON/skills/"$S/$P" "$ROOT"/$G/ICON/*/skills/"$S/$P"; do
  [ -f "$f" ] || continue; F="$f"; N=$((N+1))
done
[ "$N" = 1 ] || { echo "ICON: $N matches for $S/$P under $ROOT (marketplace ${MARKETPLACE_NAME-<any>}) — set MARKETPLACE_NAME; see: copilot plugin list" >&2; exit 1; }
node "$F"
```

#### Outcomes

| stdout | Exit | Meaning | Caller does |
|---|---|---|---|
| `- No .context/domains/ directory — …` | 0 | The directory is absent | Collect the line into Suggestions |
| `- .context/domains/ has no files — …` | 0 | Present, zero `.md` files directly inside | Collect the line into Suggestions |
| `OK domains-populated` | 0 | Present with at least one `.md` file | Collect nothing. Do not render the token |
| *(empty)* | any | The signal did not run | Report signal 1 as not-evaluated — **not** as "did not fire" |

**Signal 2: Node absent, or below ICON's supported floor.** Read from the `node -v` probe above. As
of 2026-07-28 that floor is Node 22 — see `check-node-runtime` for how it's derived and how to
recheck it against nodejs.org/en/about/previous-releases. If `node` was not found, or the major
version is below 22, add:

```
- Node runtime <not found | vNN, below ICON's supported floor> — invoke `check-node-runtime` for the
  install and version guidance.
```

Emit no suggestion when Node is present at or above the supported floor — the `Node` line already
reports it.

**Signal 3: `.context/iconrc.json` missing or unreadable.** `suggest-iconrc.mjs` **re-reads
`.context/iconrc.json` for itself** rather than inheriting the iconrc.json block's outcome:
separate invocations are separate processes and carry no state between them, so a signal waiting
on an inherited value could never fire. That is not an inefficiency — it is what keeps the block
independently runnable. It prints one suggestion line, or `OK iconrc-version-usable` when the file
holds a usable `version`; the iconrc.json block already wrote the reason to stderr, so this block
does not.

#### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/suggest-iconrc.mjs"
```

#### Copilot CLI (Bash)

```bash
# Resolve this skill's install directory. Set MARKETPLACE_NAME=<slug> to pin one marketplace;
# otherwise every installed marketplace is searched and an ambiguous result fails closed.
ROOT="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins"
S="icon-status"; P="scripts/suggest-iconrc.mjs"
if [ -n "${MARKETPLACE_NAME+x}" ]; then G="$MARKETPLACE_NAME"; else G="*"; fi
F=""; N=0
for f in "$ROOT"/$G/ICON/skills/"$S/$P" "$ROOT"/$G/ICON/*/skills/"$S/$P"; do
  [ -f "$f" ] || continue; F="$f"; N=$((N+1))
done
[ "$N" = 1 ] || { echo "ICON: $N matches for $S/$P under $ROOT (marketplace ${MARKETPLACE_NAME-<any>}) — set MARKETPLACE_NAME; see: copilot plugin list" >&2; exit 1; }
node "$F"
```

#### Outcomes

| stdout | Exit | Meaning | Caller does |
|---|---|---|---|
| `- .context/iconrc.json not found — …` | 0 | The file is absent | Collect the line into Suggestions |
| `- .context/iconrc.json has no usable "version" — …` | 0 | Present but unparseable, or `version` absent / non-string / empty | Collect the line into Suggestions |
| `OK iconrc-version-usable` | 0 | A usable non-empty string `version` | Collect nothing. Do not render the token |
| *(empty)* | any | The signal did not run | Report signal 3 as not-evaluated — **not** as "did not fire" |

**Signal 4: task branch with a stale `plan.md` (not modified in 48h).** `suggest-stale-plan.mjs`
**re-derives the task ID from the branch and re-runs the `plan.md` lookup**, for the same reason
Signal 3 re-reads the JSON. It prints the staleness line only when a matching `plan.md` was last
modified more than 48 hours ago; a branch with no task ID, a task with no `plan.md`, and a plan
touched inside 48 hours each print their own `OK …` token instead. The 48h comparison is
**exclusive and unfloored** — measured against GNU findutils 4.10.0, which compares exact
timestamps rather than truncating.

#### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/suggest-stale-plan.mjs"
```

#### Copilot CLI (Bash)

```bash
# Resolve this skill's install directory. Set MARKETPLACE_NAME=<slug> to pin one marketplace;
# otherwise every installed marketplace is searched and an ambiguous result fails closed.
ROOT="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins"
S="icon-status"; P="scripts/suggest-stale-plan.mjs"
if [ -n "${MARKETPLACE_NAME+x}" ]; then G="$MARKETPLACE_NAME"; else G="*"; fi
F=""; N=0
for f in "$ROOT"/$G/ICON/skills/"$S/$P" "$ROOT"/$G/ICON/*/skills/"$S/$P"; do
  [ -f "$f" ] || continue; F="$f"; N=$((N+1))
done
[ "$N" = 1 ] || { echo "ICON: $N matches for $S/$P under $ROOT (marketplace ${MARKETPLACE_NAME-<any>}) — set MARKETPLACE_NAME; see: copilot plugin list" >&2; exit 1; }
node "$F"
```

#### Outcomes

| stdout | Exit | Meaning | Caller does |
|---|---|---|---|
| `- plan.md stale — not modified in 48h. Still working on this?` | 0 | A matching `plan.md` older than 48h | Collect the line into Suggestions |
| `OK no-task-id` | 0 | The branch carries no `PROJ-123`-style ID | Collect nothing. Do not render the token |
| `OK no-plan-file` | 0 | A task ID, but no matching `plan.md` under `.context/tasks/` | Collect nothing. Do not render the token |
| `OK plan-fresh` | 0 | A matching `plan.md` modified within 48h | Collect nothing. Do not render the token |
| `OK plan-unstattable` | 0 | A match was found but could not be stat'd, so no staleness claim is possible. **stderr carries the reason** | Collect nothing. Do not render the token |
| *(empty)* | any | The signal did not run | Report signal 4 as not-evaluated — **not** as "did not fire" |

If no suggestions apply, omit the Suggestions section from the dashboard output. **Omitting the
section because a signal printed nothing is wrong** — that is a signal that did not run, and it
belongs in the report as not-evaluated.

---

## icon-status: Step 3: Render the dashboard

Assemble the gathered data into the following format. **Emoji is approved for this
readout.** Omit any section entirely when it has no data (e.g. no retrospectives or
suggestions).

```
📋 ICON Status — <REPO_NAME>

Active task: <TASK_ID> (branch: <BRANCH>)
Plan: .context/tasks/<TASK-DIR>/plan.md

Recent retrospectives (last 3):
  <entry 1>
  <entry 2>
  <entry 3>

Context health:
  .context/domains/   — N files
  .context/standards/ — N files
  .context/iconrc.json — version X.Y

Runtime:
  Node — <version | not found>

Suggestions:
  - <zero or more>
```

**Never render an `OK …` line.** Those tokens are how a block says it ran and had nothing to report;
they are the reason each section below can be omitted with confidence. They are liveness, not data.

**Section rules:**

| Section | Omit when |
|---------|-----------|
| Active task | Branch is `main`, `dev`, or `master` — replace with "No active task branch." |
| Plan line | `PLAN_FILE=(none)`, or no `PLAN_FILE` line at all |
| Recent retrospectives | The block printed `(no retrospectives.md)` or `OK no-retrospective-entries` |
| Context health | The block printed `OK no-context-subdirectories` |
| `iconrc.json` line | Never omitted **when the block ran** — report the version, `not found`, or `(unreadable)`. A blank after "version" is indistinguishable from a healthy read. With `node` absent nothing in Step 2 runs (see **Runtime**). |
| Node line | Never omitted — report the version or `not found`. A silent pass is indistinguishable from the probe not running. |
| Suggestions | Every signal printed an `OK …` token, i.e. all of them ran and none fired |

**A block that printed nothing is not covered by any row above.** Do not omit its section on that
basis — say the data was not gathered, name the block, and say why if you know (Node absent, a
refused Copilot path resolution, PowerShell 5.1 on Step 1).

---

## Common Mistakes

| Mistake | What happens | Correct behavior |
|---------|-------------|-----------------|
| Running on a repo with no `.context/` | Skill halts at Step 1 with the `/icon-init` suggestion | Correct — Step 1 is a hard stop |
| Reading Step 1's silence as a pass | On PowerShell 5.1, or with `node` off `PATH`, the guard never runs and prints 0 bytes. Neither token appears, and the hard stop is skipped on a repo that has no `.context/` | Require `INITIALIZED` or `NOT_INITIALIZED`. Silence is a failed guard, not a pass |
| Reading a Step 2 block's silence as "nothing to report" | Every Step 2 block prints on every path, so 0 bytes means it did not run — a suggestion that should have fired is dropped, or a section is omitted that had data | Require at least one line. Report a silent block as not-run |
| Rendering an `OK …` token on the dashboard | `OK domains-populated` or `OK plan-fresh` appears as if it were a finding | `OK …` is liveness only. Read it, then discard it |
| Assuming the `.mjs` scripts share state | E.g. expecting Signal 4 to reuse the branch/task block's lookup | Each script is its own process and re-derives its inputs. Run them in any order |
| Branch is `dev` or `main` | "No active task branch" appears | Correct — not an error |
| Treating a block's stderr as part of its result | A git error or a parse reason lands on the dashboard | Read stdout for the value; stderr is diagnostics only |
