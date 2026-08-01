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

**Runtime and shell.** Every fence in Steps 1 and 2 except the bare `node -v` probe is a `node -e`
program, so with `node` off `PATH` each one emits nothing at all and the dashboard degrades to its
`Node — not found` line alone — no block has a non-Node fallback. Run them in **bash or
PowerShell 7**: Windows PowerShell 5.1 does not escape the `"` embedded in a single-quoted program
when it builds the native command line, so each one fails there at parse time with a visible
`SyntaxError` and empty stdout — never with a wrong answer. The `node -v` probe carries no quotes
and runs in 5.1 too.

## When to Use

- Returning to a repo after a break, to see where things stand
- About to plan new work and need to check context health

**Do not use** to inspect a specific task's details — read `.context/tasks/<TASK-DIR>/plan.md`
directly for that.

---

## icon-status: Step 1: Fresh-repo guard

Check whether `.context/` exists in the current working directory. **Run this as-is** — one text
serves both supported shells. It prints `NOT_INITIALIZED` when `.context/` is absent or is not a
directory, and prints **nothing at all** when the repo is initialized. Silence is the pass.

```
node -e '
const fs = require("fs");
let isDir = false;
try { isDir = fs.statSync(".context").isDirectory(); } catch (e) { isDir = false; }
if (!isDir) process.stdout.write("NOT_INITIALIZED\n");
'
```

If `.context/` does not exist, emit the following message and **halt — do not
attempt to render the dashboard**:

```
This repo is not yet ICON-initialized. Run `/icon-init` to set up — it detects your repo type automatically.
```

---

## icon-status: Step 2: Gather data

Run each block below. No block fails on missing data, but they do not all report it the same way.
Three always print: repo name (`(unknown)` at worst), branch/task (`BRANCH=`/`TASK_ID=`, either
possibly empty), and `iconrc.json` (`not found` or `version (unreadable)` at worst). The rest can
legitimately print **nothing** — an absent context subdirectory, a `retrospectives.md` with no
task-ID headings, a Suggestions signal that does not fire — and there, silence is the result, not a
failure. Each block's own paragraph states the outcomes it can produce.

Each block is a single `node -e` command, untagged because one text serves both supported shells —
run it as-is (see **Runtime and shell** above). **Every block is independently runnable**: none
reads a value another block set, so run them in any order. A block's result is its stdout;
**diagnostics go to stderr** and are never part of the result.

### Repo name

Run this. It prints one line — the repo name. Three sources are tried in order, stopping at the
first that yields a value: the `origin` remote URL (last path segment, `.git` stripped), the
basename of the git top-level directory, then `(unknown)`. A git failure at any rung is a
diagnostic: it goes to stderr and the chain falls through, so an error message can never reach
the dashboard as the repo's name.

```
node -e '
const path = require("path");
const { execFileSync } = require("child_process");
function git(args) {
  try { return execFileSync("git", args, { encoding: "utf8" }).trim(); } catch (e) { return ""; }
}
let name = git(["remote", "get-url", "origin"]).replace(/^.*[/:]/, "").replace(/\.git$/, "");
if (!name) name = path.basename(git(["rev-parse", "--show-toplevel"]));
if (!name) name = "(unknown)";
process.stdout.write(name + "\n");
'
```

### Current branch and active task

Run this. Branch, task ID and plan file are one block because each is derived from the one
before: the task ID comes from the branch name, the plan file from the task ID. It prints two
or three `KEY=value` lines:

| Line | Meaning |
|---------|---------|
| `BRANCH=<name>` | Checked-out branch. Empty outside a git repo (git's own error goes to stderr). |
| `TASK_ID=<id>` | First `PROJ-123`-style ID in the branch name; empty when there is none. |
| `PLAN_FILE=<path>` / `PLAN_FILE=(none)` | The task's `plan.md`. **Omitted entirely when `TASK_ID` is empty** — there is nothing to look up. |

The lookup scans `.context/tasks/` one and two levels deep for an entry named `plan.md` whose
path contains the task ID. When more than one matches, the paths are **sorted** and the first is
taken — the original took whichever the filesystem happened to return first, which is not
reproducible.

```
node -e '
const fs = require("fs");
const { execFileSync } = require("child_process");
let branch = "";
try { branch = execFileSync("git", ["rev-parse", "--abbrev-ref", "HEAD"], { encoding: "utf8" }).trim(); } catch (e) { branch = ""; }
const m = branch.match(/[A-Z]+-[0-9]+/);
const taskId = m ? m[0] : "";
process.stdout.write("BRANCH=" + branch + "\n");
process.stdout.write("TASK_ID=" + taskId + "\n");
if (!taskId) process.exit(0);
const hits = [];
// Depth budget, not a glob: entries one and two levels below .context/tasks.
(function scan(dir, depth) {
  let entries = [];
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch (e) { return; }
  for (const e of entries) {
    const p = dir + "/" + e.name;
    if (e.name === "plan.md" && p.includes(taskId)) hits.push(p);
    if (depth < 2 && e.isDirectory()) scan(p, depth + 1);
  }
})(".context/tasks", 1);
hits.sort();
process.stdout.write("PLAN_FILE=" + (hits.length ? hits[0] : "(none)") + "\n");
'
```

- If `$BRANCH` is `main`, `dev`, or `master`: active task section reads
  "No active task branch."
- Otherwise: report `$TASK_ID` (if matched) and use `$PLAN_FILE` for the dashboard's
  `Plan` line — `(none)`, or no `PLAN_FILE` line at all, means omit that line.

### Recent retrospectives (last 3 entries)

Run this. It prints up to three `### TASK-ID` heading lines from `.context/retrospectives.md`
**in file order** — that file is newest-first, so the first three *are* the most recent three.
Do not sort them and do not take the last three. If the file is absent it prints
`(no retrospectives.md)` instead.

```
node -e '
const fs = require("fs");
const p = ".context/retrospectives.md";
let isFile = false;
try { isFile = fs.statSync(p).isFile(); } catch (e) { isFile = false; }
if (!isFile) { process.stdout.write("(no retrospectives.md)\n"); process.exit(0); }
const hits = fs.readFileSync(p, "utf8").split(/\r?\n/)
  .filter((l) => /^### [A-Z]+-[0-9]+/.test(l)).slice(0, 3);
for (const l of hits) process.stdout.write(l + "\n");
'
```

If no lines match, skip the "Recent retrospectives" section in the dashboard
output entirely.

### Context health

Run this. For each of six known `.context/` subdirectories it prints one indented line carrying
the count of `.md` files directly inside — and prints **no line at all** for a subdirectory that
is absent, which is how the dashboard omits it. Dot-prefixed names such as `.hidden.md` **are**
counted; a symlink pointing at a `.md` file is **not**, because it is a link and not a file. A
subdirectory that is itself a symlink is followed and the files behind it are counted.

```
node -e '
const fs = require("fs");
for (const d of ["domains", "standards", "workflows", "architecture", "testing", "styling"]) {
  const p = ".context/" + d;
  // Directory test follows symlinks (statSync); entry test does not (Dirent).
  let isDir = false;
  try { isDir = fs.statSync(p).isDirectory(); } catch (e) { isDir = false; }
  if (!isDir) continue;
  let count = 0;
  try {
    count = fs.readdirSync(p, { withFileTypes: true })
      .filter((e) => e.isFile() && e.name.endsWith(".md")).length;
  } catch (e) { count = 0; }
  process.stdout.write("  .context/" + d + "/ — " + count + " files\n");
}
'
```

### iconrc.json

Run this. It prints exactly **one** line, always — `version <X.Y>`, `not found`, or
`version (unreadable)`. There is no fourth outcome and no silent one.

The empty-result guard is the point of the block, not a detail of it: **an empty read must never
reach the dashboard as a value**, because `version ` with nothing after it reads as a healthy
line. An absent, non-string or empty `version`, and a file that will not parse, all resolve to
the one visible token `(unreadable)` — with the reason on stderr, never on stdout.

```
node -e '
const fs = require("fs");
const p = ".context/iconrc.json";
let isFile = false;
try { isFile = fs.statSync(p).isFile(); } catch (e) { isFile = false; }
if (!isFile) { process.stdout.write("  .context/iconrc.json — not found\n"); process.exit(0); }
let version;
try {
  const v = JSON.parse(fs.readFileSync(p, "utf8")).version;
  if (typeof v === "string" && v !== "") version = v;
  else process.stderr.write("iconrc.json parsed, but \"version\" is missing or not a string\n");
} catch (e) {
  process.stderr.write("iconrc.json could not be read or parsed: " + e.message + "\n");
}
if (version === undefined) {
  process.stderr.write("ERROR: no usable \"version\" in .context/iconrc.json (reason above, on stderr).\n");
  process.stdout.write("  .context/iconrc.json — version (unreadable)\n");
} else {
  process.stdout.write("  .context/iconrc.json — version " + version + "\n");
}
'
```

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

Evaluate the following signals and collect any that apply into a suggestions list. Each signal
block prints its suggestion line when it fires and prints nothing when it does not.

**Signal 1: `.context/domains/` missing or empty.** Run this. It prints one of two suggestion
lines, or nothing when `.context/domains/` exists and holds at least one `.md` file. It counts
files exactly as the Context health block does.

```
node -e '
const fs = require("fs");
const p = ".context/domains";
let isDir = false;
try { isDir = fs.statSync(p).isDirectory(); } catch (e) { isDir = false; }
if (!isDir) {
  process.stdout.write("- No .context/domains/ directory — run /upgrade-repo to bring context current.\n");
  process.exit(0);
}
let count = 0;
try {
  count = fs.readdirSync(p, { withFileTypes: true })
    .filter((e) => e.isFile() && e.name.endsWith(".md")).length;
} catch (e) { count = 0; }
if (count === 0) {
  process.stdout.write("- .context/domains/ has no files — run /upgrade-repo to bring context current.\n");
}
'
```

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

**Signal 3: `.context/iconrc.json` missing or unreadable.** Run this. It **re-reads
`.context/iconrc.json` for itself** rather than inheriting the iconrc.json block's outcome:
separate shell invocations carry no variables between them, so a signal waiting on an inherited
value could never fire. It prints one suggestion line, or nothing when the file holds a usable
`version`; the iconrc.json block already wrote the reason to stderr, so this block does not.

```
node -e '
const fs = require("fs");
const p = ".context/iconrc.json";
let isFile = false;
try { isFile = fs.statSync(p).isFile(); } catch (e) { isFile = false; }
if (!isFile) {
  process.stdout.write("- .context/iconrc.json not found — run /upgrade-repo to restore it.\n");
  process.exit(0);
}
let v;
try { v = JSON.parse(fs.readFileSync(p, "utf8")).version; } catch (e) { v = undefined; }
if (typeof v !== "string" || v === "") {
  process.stdout.write("- .context/iconrc.json has no usable \"version\" — see the error above, or run /upgrade-repo to regenerate it.\n");
}
'
```

**Signal 4: task branch with a stale `plan.md` (not modified in 48h).** Run this. It
**re-derives the task ID from the branch and re-runs the `plan.md` lookup**, for the same reason
Signal 3 re-reads the JSON. It prints the staleness line only when a matching `plan.md` was last
modified more than 48 hours ago; a branch with no task ID, a task with no `plan.md`, and a plan
touched inside 48 hours all print nothing.

```
node -e '
const fs = require("fs");
const { execFileSync } = require("child_process");
let branch = "";
try { branch = execFileSync("git", ["rev-parse", "--abbrev-ref", "HEAD"], { encoding: "utf8" }).trim(); } catch (e) { branch = ""; }
const m = branch.match(/[A-Z]+-[0-9]+/);
if (!m) process.exit(0);
const taskId = m[0];
const hits = [];
(function scan(dir, depth) {
  let entries = [];
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch (e) { return; }
  for (const e of entries) {
    const p = dir + "/" + e.name;
    if (e.name === "plan.md" && p.includes(taskId)) hits.push(p);
    if (depth < 2 && e.isDirectory()) scan(p, depth + 1);
  }
})(".context/tasks", 1);
hits.sort();
if (!hits.length) process.exit(0);
let st;
try { st = fs.lstatSync(hits[0]); } catch (e) { process.exit(0); }
// 48h = 2880 minutes, exclusive — matches find -mmin +2880 (measured, GNU findutils 4.10).
if ((Date.now() - st.mtimeMs) / 60000 > 2880) {
  process.stdout.write("- plan.md stale — not modified in 48h. Still working on this?\n");
}
'
```

If no suggestions apply, omit the Suggestions section from the dashboard output.

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

**Section rules:**

| Section | Omit when |
|---------|-----------|
| Active task | Branch is `main`, `dev`, or `master` — replace with "No active task branch." |
| Plan line | No `plan.md` found for the task ID |
| Recent retrospectives | No task-ID headings (`### PROJ-123` style) found in `retrospectives.md` |
| Context health | No `.context/` subdirectories found at all |
| `iconrc.json` line | Never omitted **when the block ran** — report the version, `not found`, or `(unreadable)`. A blank after "version" is indistinguishable from a healthy read. With `node` absent nothing in Step 2 runs (see **Runtime and shell**). |
| Node line | Never omitted — report the version or `not found`. A silent pass is indistinguishable from the probe not running. |
| Suggestions | No signals triggered |

---

## Common Mistakes

| Mistake | What happens | Correct behavior |
|---------|-------------|-----------------|
| Running on a repo with no `.context/` | Skill halts at Step 1 with the `/icon-init` suggestion | Correct — Step 1 is a hard stop |
| Branch is `dev` or `main` | "No active task branch" appears | Correct — not an error |
| Treating a block's stderr as part of its result | A git error or a parse reason lands on the dashboard | Read stdout for the value; stderr is diagnostics only |
