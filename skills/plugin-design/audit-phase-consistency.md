# Audit — Phase 2: Internal Consistency

## Overview

Cross-file checks that detect drift between what a file claims and what other files contain. Structure can be valid (Phase 1) yet internally inconsistent — a skill referencing `/foo` when no `skills/foo/SKILL.md` exists, a placeholder description, or two agents whose responsibilities overlap.

## Checks

1. **Skill references resolve** — any `/foo` invocation in `agents/*.agent.md` or `skills/*/SKILL.md` body text must correspond to an existing `skills/foo/SKILL.md` (or a built-in slash command, which the auditor should distinguish if known).
2. **File-path references resolve** — any `.context/<subdir>/<file>.<ext>` reference in shipped surfaces (agents, skills, shared, commands) must resolve under the plugin's `.context/`. (For the ICON self-audit case where `.context/` content lives under `context_template/context/`, prefer that location when present.) This generalizes the dead-ref pattern from ICON's own pre-commit hook.
3. **Frontmatter `description` is non-boilerplate** — heuristic: must not be empty, must not equal the skill/agent name, must not be the literal `TODO` or `<description>`, must exceed 20 characters.
4. **Agent/skill role-overlap heuristic** — if two agents have first-sentence descriptions with overlapping responsibilities (similar verb + object), surface it as a concern. Heuristic only; flag for review, do not auto-fail.

## Validation Snippets

**Shell requirement — bash or PowerShell 7.** Each block below is one single-quoted shell word whose
body contains double quotes. Windows PowerShell 5.1 does not escape embedded `"` when it builds a
native command line, so it strips them and node fails at parse time: `SyntaxError`, empty stdout,
exit 1. Measured on 5.1.26100 — every block in this file fails that way, so on 5.1 these checks
cannot be run as written.

That failure is loud in stdout only where a block answers with stdout *content*. Where the contract
is "silence means clean", empty stdout **is** the pass signal, so a failed run reads as a clean audit
unless the exit status is read alongside it. On 5.1 that status is 1, so reading it is enough — but
read it from the run you just made. PowerShell leaves `$LASTEXITCODE` at the previous command's value
when a native command is not found, so a node that never launched can leave a stale 0 behind, and the
silence then passes for a genuine clean.

### Skill-reference resolution

Run it as-is in bash or PowerShell 7. It prints one line per
unresolved invocation to stdout and exits 0: this check reports, it does not gate, because
the built-in slash commands named in check 1 are indistinguishable from a dead reference here and
the auditor is the one who tells them apart. Silence means every `/name` token in agent and skill
body text has a matching `skills/name/SKILL.md`. Each finding is a *candidate*: check 1 above is
what decides whether the name is really dead or is a harness built-in.

The exit-0 promise depends on the target list holding only readable regular files, which is what the
`isFile` filter is for — without it, a *directory* named `something.agent.md` reaches `readFileSync`
and the block dies on `EISDIR` with exit 1 and no findings at all. Anything that cannot be stat-ed
as a file is skipped rather than thrown.

```
node -e '
const fs = require("fs");
// ENOENT and ENOTDIR both yield no entries, matching pathlib glob, which returns
// nothing whether the directory is absent or is actually a regular file.
const ls = (d) => { try { return fs.readdirSync(d); } catch (e) { if (e.code === "ENOENT" || e.code === "ENOTDIR") return []; throw e; } };
const isFile = (p) => { try { return fs.statSync(p).isFile(); } catch (e) { return false; } };
const existing = new Set(ls("skills").filter((n) => isFile("skills/" + n + "/SKILL.md")));
// filter(isFile) is required on the agents half too: a *directory* named
// something.agent.md would otherwise reach readFileSync below and throw EISDIR.
const targets = ls("agents").filter((n) => n.endsWith(".agent.md")).map((n) => "agents/" + n)
  .concat(Array.from(existing).map((n) => "skills/" + n + "/SKILL.md")).filter(isFile);
// Require the slash-name to be a real invocation: preceded by start-of-line or
// whitespace/backtick, and followed by whitespace, end-of-line, backtick, or
// common punctuation. This avoids matching mid-path tokens like .context/standards.
// Flags: m makes ^ and $ line anchors; g is required by matchAll.
const INVOCATION = /(?:^|(?<=[\s`]))\/([a-z][a-z0-9-]+)(?=[\s`.,;:!?)\]]|$)/gm;
const SKIP = ["http://", "https://", "/usr/", "/etc/", "/var/", ".context/", "context_template/", "github.com/"];
const findings = [];
for (const p of targets) {
  const txt = fs.readFileSync(p, "utf8");
  for (const m of txt.matchAll(INVOCATION)) {
    if (existing.has(m[1])) continue;
    // Heuristic guard: skip references inside URLs, file paths, or command examples.
    const ctx = txt.slice(Math.max(0, m.index - 20), m.index + m[0].length + 20);
    if (SKIP.some((s) => ctx.includes(s))) continue;
    findings.push(p + ": references /" + m[1] + " but skills/" + m[1] + "/SKILL.md not found");
  }
}
for (const f of findings) console.log(f);
'
```

### File-path resolution (dead-ref)

Run it as-is in bash or PowerShell 7. It recursively scans `agents/`, `skills/`, `shared/` and
`commands/` for `.context/<path>.<ext>` tokens and prints `<file>: dead ref <token>` for each one
resolving under neither `context_template/context/` nor `.context/`. Absent directories are skipped,
as is one that exists but is a regular file. Silence means every reference in every file it *scanned*
resolves — see **Links** below for what it declines to scan. The exit status
is 0 whether or not there were findings, so it carries no verdict of its own — read the output for
that. It is not evidence the block *ran*, either: per the banner above, a `node` that never launched
leaves whatever `$LASTEXITCODE` already held — measured on pwsh 7.6.3, 0 after a prior 0 and 3 after
a prior 3. Apply the test `icon-status` puts on its fresh-repo guard instead: treat silence as clean
only when stdout **and** stderr are both empty.

**Links.** Every entry is resolved with `statSync`, which follows links, so a directory reached
through a symlink or a Windows junction is descended into and its files are scanned. That is what
makes this block agree with the other three audit blocks — Phase 1 frontmatter, and the
skill-reference and description-quality blocks here — which resolve links the same way. Measured
on a fixture whose only skill sits behind a junction: Phase 1 and the description-quality block below
both reported it, while the earlier `Dirent`-based walk here printed nothing and exited 0 — a silent
false-clean, the worst failure available to a dead-reference check.

It diverges from `pathlib.rglob` in both directions, deliberately. `rglob` descends a junction
(`os.path.islink` is False for one) but stops at a true symlink; this block descends both, so it
reaches more of the tree. `rglob` also yields the symlinked directory itself, and the Python original
then died on `read_text()` (`PermissionError` on Windows, `IsADirectoryError` on POSIX), losing every
finding in the run; here a directory never reaches the read branch.

`realpathSync` and a visited set bound the walk. Without them a junction pointing at its own ancestor
is re-entered until the operating system refuses to resolve another link. Measured on a fixture whose
`agents/` holds `a.md` plus a real `sub/` holding `b.md`, with `sub/loop` junctioned back onto
`agents/`: this block reports those 2 files and exits 0, while the same block with the visited set
deleted reports the same 2 files 128 times over, one respelling per lap, and also exits 0. That
ceiling is the link-resolution limit, not the path length — `statSync` raises `ELOOP` on the 64th lap
and `isDir` reports not-a-directory, so the walk stops there whether the accumulated path has reached
582 characters or half that.

The set dedupes *directories*, not files: it is consulted only inside `walk`, and the branch that
pushes a file never touches it. So a directory reachable by several links is walked once and its
files reported under the first path to reach it — `skills/` junctioned onto `agents/` yields findings
spelled `agents/...` only — while a file carrying two names of its own is still reported under each:
one inode spelled `real.md`, `hard.md` and `alias.md` in a single `agents/` produced 3 findings, one
per spelling. That over-reporting is the safe direction for a dead-reference check, which would
otherwise be hiding a path a reader can follow. What the set costs is path spellings, not coverage:
aliasing fixtures built to make it drop a real file outright (sibling junctions onto one target; a
top-level directory aliased onto another) did not. An entry `statSync` cannot resolve — a broken
link, or a link loop (`ELOOP`) — is skipped like any other unreadable entry.

Scanned suffixes are `.md`, `.sh`, `.ps1`, `.js` **and `.mjs`**. `.mjs` is deliberate and was added
with this port: `*.js` does not glob-match `.mjs`, and the pre-commit gate this check generalizes
was extended to `.mjs` under ADR-017, so omitting it here would leave migrated scripts unscanned.

```
node -e '
const fs = require("fs");
const EXTS = [".md", ".sh", ".ps1", ".js", ".mjs"];
// One link policy across all four audit blocks: statSync, which FOLLOWS links.
// Descending: a directory reached through a symlink or a Windows junction is
// entered and its files are scanned. The three frontmatter blocks already read
// a SKILL.md sitting behind a junction; this walk used to be the only one that
// did not, and it said nothing about what it had skipped.
// Reading: isFile drops whatever statSync cannot resolve to a regular file --
// a broken link, a device -- which readFileSync would throw on. A directory
// never reaches that branch; isDir claims it first, so the throw this guard
// prevents is ENOENT on a broken link, not EISDIR. EXTS filters on the name
// before any read, so the guard only bites for a scanned suffix: unguarded,
// a broken brokendir.md kills the run and extension-less brokendir does not.
// seen holds realpaths, which bounds the walk: a junction pointing at its own
// ancestor is otherwise re-entered until the OS stops resolving links (ELOOP).
// It is consulted here only, so it dedupes directories, not files: a directory
// reachable by several links is walked once, under the first path to reach it,
// while a file with two names of its own is reported under each of them.
// ENOENT means the directory is absent; ENOTDIR means it is a regular file.
const isDir = (p) => { try { return fs.statSync(p).isDirectory(); } catch (e) { return false; } };
const isFile = (p) => { try { return fs.statSync(p).isFile(); } catch (e) { return false; } };
const seen = new Set();
function walk(dir, out) {
  let real;
  try { real = fs.realpathSync(dir); } catch (e) { if (e.code === "ENOENT") return out; throw e; }
  if (seen.has(real)) return out;
  seen.add(real);
  let ents;
  try { ents = fs.readdirSync(dir); }
  catch (e) { if (e.code === "ENOENT" || e.code === "ENOTDIR") return out; throw e; }
  for (const n of ents) {
    const p = dir + "/" + n;
    if (isDir(p)) walk(p, out); else if (isFile(p)) out.push(p);
  }
  return out;
}
const findings = [];
for (const d of ["agents", "skills", "shared", "commands"]) {
  for (const p of walk(d, [])) {
    const base = p.slice(p.lastIndexOf("/") + 1);
    const dot = base.lastIndexOf(".");
    if (!EXTS.includes(dot > 0 ? base.slice(dot) : "")) continue;
    for (const m of fs.readFileSync(p, "utf8").matchAll(/\.context\/[a-zA-Z0-9_\/-]+\.[a-zA-Z0-9]+/g)) {
      const rest = m[0].slice(".context/".length);
      // ICON self-audit: content lives under context_template/context/.
      // Generic plugins: content lives at the plugin .context/ root
      // (the audit-mode hard precondition guarantees .context/ exists).
      if (fs.existsSync("context_template/context/" + rest)) continue;
      if (fs.existsSync(".context/" + rest)) continue;
      findings.push(p + ": dead ref " + m[0]);
    }
  }
}
for (const f of findings) console.log(f);
'
```

### Frontmatter description quality

Run it as-is in bash or PowerShell 7. It prints at most one finding per file to stdout, in the
precedence order of check 3 above — empty, then equals-name, then placeholder, then too-short — and
exits 0. Precedence matters: an empty description is reported as empty, not also as too
short. Files with no frontmatter block are skipped silently; Phase 1 already reports those.

Same **YAML fidelity limit** as Phase 1 — a dependency-free subset parser, no syntax-error
detection, and the same three cosmetic message divergences (two of which are this block's); see
`audit-phase-structure.md § Frontmatter parse`.

One divergence is specific to this block and is an improvement. A frontmatter block that is a scalar
or a sequence rather than a mapping **crashed the Python original**: its `yaml.safe_load(...) or {}`
guard replaces `None` but not a non-dict, so the next `.get()` raised `AttributeError` and killed
the run before any finding printed. Here such a block yields no keys, so the file is reported
`empty description` and the scan continues.

**Block-scalar folding is load-bearing here, and most visibly here.** Descriptions are almost always
written as `description: >` with the text on the following lines, so a parser that skipped folding
would store the literal `">"` — one character. This block measures length, so files written that way
land on `description too short (1 chars)`. Note the finding is *too short*, not *empty*: `">"` is
non-empty, which is why Phase 1, whose test is only non-emptiness, is unaffected by *this* case.
Phase 1 has its own, narrower dependency on the folding — an **empty** block scalar, where dropping
it converts a real finding into a false pass — recorded there. Mutation-verified: replacing
the parser with a folding-skipped one turns this check's **0 findings against this repo into 59
false `description too short (1 chars)` findings**, while Phase 1's output over the same repo does
not change by a single byte.

```
node -e '
const fs = require("fs");
// ENOENT and ENOTDIR both yield no entries, matching pathlib glob.
const ls = (d) => { try { return fs.readdirSync(d); } catch (e) { if (e.code === "ENOENT" || e.code === "ENOTDIR") return []; throw e; } };
// statSync follows symlinks, matching what reading the file would do. It also
// drops a *directory* named something.agent.md, which would throw EISDIR.
const isFile = (p) => { try { return fs.statSync(p).isFile(); } catch (e) { return false; } };
const targets = ls("agents").filter((n) => n.endsWith(".agent.md")).map((n) => "agents/" + n)
  .concat(ls("skills").map((n) => "skills/" + n + "/SKILL.md")).filter(isFile);
// Minimal YAML, as in Phase 1: top-level "key: value" plus block scalars. 34 and
// 39 are the quote characters, as codes so this program holds no apostrophe.
function fm(txt) {
  const L = txt.replace(/^\uFEFF/, "").split(/\r?\n/);
  if (L[0] !== "---") return null;
  const end = L.indexOf("---", 1);
  if (end < 0) return null;
  const out = {};
  for (let i = 1; i < end; i++) {
    const m = /^([A-Za-z0-9_.-]+):(?:[ \t]+(.*))?$/.exec(L[i]);
    if (!m) continue;
    const v = m[2] === undefined ? "" : m[2].trim();
    if (!/^[>|][+-]?[0-9]*$/.test(v)) {
      const q = v.charCodeAt(0);
      const quoted = v.length > 1 && (q === 34 || q === 39) && v.charCodeAt(v.length - 1) === q;
      out[m[1]] = quoted ? v.slice(1, -1) : v;
      continue;
    }
    const par = [[]];
    let j = i + 1;
    for (; j < end; j++) {
      const t = L[j].trim();
      if (t === "") { if (par[par.length - 1].length) par.push([]); continue; }
      if (!/^[ \t]/.test(L[j])) break;
      par[par.length - 1].push(t);
    }
    i = j - 1;
    out[m[1]] = par.filter((g) => g.length).map((g) => g.join(v[0] === ">" ? " " : "\n")).join("\n");
  }
  return out;
}
const findings = [];
for (const p of targets) {
  const d = fm(fs.readFileSync(p, "utf8"));
  if (d === null) continue;
  const desc = (d.description || "").trim();
  const name = (d.name || "").trim();
  const n = Array.from(desc).length;
  if (!desc) findings.push(p + ": empty description");
  else if (desc.toLowerCase() === name.toLowerCase()) findings.push(p + ": description equals name (boilerplate)");
  else if (["TODO", "<DESCRIPTION>"].includes(desc.toUpperCase())) findings.push(p + ": placeholder description (" + JSON.stringify(desc) + ")");
  else if (n < 20) findings.push(p + ": description too short (" + n + " chars; aim for >= 20)");
}
for (const f of findings) console.log(f);
'
```

### Role-overlap heuristic

A judgment call, not a deterministic check. List every agent's `name` + first-sentence verb phrase, then surface pairs whose verb + object look similar (e.g. two agents that both "review code" or "manage tasks"):

- `coder` "implements features" vs `developer` "implements changes" → flag.
- `tester` "writes tests" vs `qa` "creates tests" → flag.
- `manager` "orchestrates workflows" vs `coordinator` "orchestrates work" → flag.

Report the pair, the overlapping phrase, and the recommended action: consult `agent-evaluation` for a deeper single-agent design review.

## Cross-references

When role overlap is detected, invoke `agent-evaluation` against the involved agents for a dedicated single-agent review.
