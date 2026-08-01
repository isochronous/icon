# Audit — Phase 2: Internal Consistency

## Overview

Cross-file checks that detect drift between what a file claims and what other files contain. Structure can be valid (Phase 1) yet internally inconsistent — a skill referencing `/foo` when no `skills/foo/SKILL.md` exists, a placeholder description, or two agents whose responsibilities overlap.

## Checks

1. **Skill references resolve** — any `/foo` invocation in `agents/*.agent.md` or `skills/*/SKILL.md` body text must correspond to an existing `skills/foo/SKILL.md` (or a built-in slash command, which the auditor should distinguish if known).
2. **File-path references resolve** — any `.context/<subdir>/<file>.<ext>` reference in shipped surfaces (agents, skills, shared, commands) must resolve under the plugin's `.context/`. (For the ICON self-audit case where `.context/` content lives under `context_template/context/`, prefer that location when present.) This generalizes the dead-ref pattern from ICON's own pre-commit hook.
3. **Frontmatter `description` is non-boilerplate** — heuristic: must not be empty, must not equal the skill/agent name, must not be the literal `TODO` or `<description>`, must exceed 20 characters.
4. **Agent/skill role-overlap heuristic** — if two agents have first-sentence descriptions with overlapping responsibilities (similar verb + object), surface it as a concern. Heuristic only; flag for review, do not auto-fail.

## Validation Snippets

### Skill-reference resolution

Identical in every shell — run it as-is, in whatever shell the session uses. It prints one line per
unresolved invocation to stdout and always exits 0: this check reports, it does not gate, because
the built-in slash commands named in check 1 are indistinguishable from a dead reference here and
the auditor is the one who tells them apart. Silence means every `/name` token in agent and skill
body text has a matching `skills/name/SKILL.md`. Each finding is a *candidate*: check 1 above is
what decides whether the name is really dead or is a harness built-in.

```
node -e '
const fs = require("fs");
const ls = (d) => { try { return fs.readdirSync(d); } catch (e) { if (e.code === "ENOENT") return []; throw e; } };
const isFile = (p) => { try { return fs.statSync(p).isFile(); } catch (e) { return false; } };
const existing = new Set(ls("skills").filter((n) => isFile("skills/" + n + "/SKILL.md")));
const targets = ls("agents").filter((n) => n.endsWith(".agent.md")).map((n) => "agents/" + n)
  .concat(Array.from(existing).map((n) => "skills/" + n + "/SKILL.md"));
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

Identical in every shell — run it as-is. It recursively scans `agents/`, `skills/`, `shared/` and
`commands/` for `.context/<path>.<ext>` tokens and prints `<file>: dead ref <token>` for each one
resolving under neither `context_template/context/` nor `.context/`. Absent directories are skipped.
Silence means every reference resolves; exit is always 0, so read the output, not the status.

Scanned suffixes are `.md`, `.sh`, `.ps1`, `.js` **and `.mjs`**. `.mjs` is deliberate and was added
with this port: `*.js` does not glob-match `.mjs`, and the pre-commit gate this check generalizes
was extended to `.mjs` under ADR-017, so omitting it here would leave migrated scripts unscanned.

```
node -e '
const fs = require("fs");
const EXTS = [".md", ".sh", ".ps1", ".js", ".mjs"];
// Dirent.isDirectory() does not follow symlinks, matching pathlib rglob, which
// does not descend into symlinked directories either. ENOENT yields no files.
function walk(dir, out) {
  let ents;
  try { ents = fs.readdirSync(dir, { withFileTypes: true }); }
  catch (e) { if (e.code === "ENOENT") return out; throw e; }
  for (const e of ents) {
    const p = dir + "/" + e.name;
    if (e.isDirectory()) walk(p, out); else out.push(p);
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

Identical in every shell — run it as-is. It prints at most one finding per file to stdout, in the
precedence order of check 3 above — empty, then equals-name, then placeholder, then too-short — and
always exits 0. Precedence matters: an empty description is reported as empty, not also as too
short. Files with no frontmatter block are skipped silently; Phase 1 already reports those.

Same **YAML fidelity limit** as Phase 1 — a dependency-free subset parser, no syntax-error
detection; see `audit-phase-structure.md § Frontmatter parse`. Block-scalar folding is load-bearing
*here* in particular: descriptions are almost always written as `description: >`, so reading only
the text on that line would report every file in a healthy plugin as empty.

```
node -e '
const fs = require("fs");
const ls = (d) => { try { return fs.readdirSync(d); } catch (e) { if (e.code === "ENOENT") return []; throw e; } };
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
