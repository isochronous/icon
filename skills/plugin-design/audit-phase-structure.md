# Audit — Phase 1: Structure Validation

## Overview

Verify the plugin's file/folder layout and frontmatter are well-formed. These findings block marketplace listing — a plugin that fails structural validation will not load cleanly in Claude Code.

## Checks

For each check, report a pass/fail line with a path if applicable.

1. **`plugin.json` parses as valid JSON** — required.
2. **`plugin.json` declares `$schema`** — recommended; ideally `https://json.schemastore.org/claude-code-plugin-manifest.json` for IDE validation.
3. **`plugin.json` declares `name`, `version`, `description`** — required.
4. **Standard directories exist** — `agents/`, `skills/`, `commands/`, `hooks/`, `shared/`. Not all are mandatory (a skill-only plugin may omit `agents/`), but report each present/absent for a sanity-check.
5. **Every `agents/*.agent.md` has valid YAML frontmatter** declaring at least `name` and `description`.
6. **Every `skills/*/SKILL.md` has valid YAML frontmatter** declaring at least `name` and `description`.
7. **`CHANGELOG.md` exists** and contains an `## [Unreleased]` block.

## Validation Snippets

### plugin.json

Identical in every shell — run it as-is, in whatever shell the session uses. Silence
and exit 0 mean all three fields are declared; anything else goes to stderr and exits 1.

```
node -e '
const d = JSON.parse(require("fs").readFileSync(".claude-plugin/plugin.json", "utf8"));
const missing = ["name", "version", "description"].filter((k) => !(k in d));
if (missing.length) {
  console.error("missing required: " + missing.join(", "));
  process.exit(1);
}
'
```

### Frontmatter parse

Identical in every shell — run it as-is, in whatever shell the session uses. It walks every
`agents/*.agent.md` and `skills/*/SKILL.md` and prints one line per finding to stdout: a file with
no frontmatter block, or one whose `name` or `description` is missing or empty. Silence and exit 0
mean every file is well-formed; any finding exits 1. A missing `agents/` or `skills/` directory
contributes no files rather than erroring — check 4 above already allows a skill-only plugin.

**Fidelity limit — read this before treating a clean run as YAML validation.** Node ships no YAML
parser and ICON forbids third-party imports (ADR-005), so the block parses a deliberate subset:
top-level `key: value`, and `>` / `>-` / `|` / `|-` block scalars. Block-scalar support is not
optional — nearly every real `description:` is folded, and a parser that skipped folding would
report a *false* empty description for every file in a healthy plugin.

Two findings the previous Python version emitted are **deliberately dropped**, because a subset
parser cannot produce them honestly:

- **`YAML parse error`** — malformed YAML is not detected. A broken block is read for whatever
  `key:` lines it still exposes.
- **`frontmatter is not a mapping`** — a scalar or sequence frontmatter block surfaces as missing
  `name` and `description`, not as a type error.

That is the fidelity the retired PowerShell variant already shipped, so nothing is lost on Windows,
and neither case becomes a false pass — both still produce findings, under a less precise name. A
plugin that needs real YAML validation should run `yq` or a YAML linter separately.

The block is also **stricter about where frontmatter starts**: the file must open with a `---` line,
and the block ends at the next line that is exactly `---`. The Python version split on the first two
`---` sequences anywhere in the text, so a file with no frontmatter but a `---` horizontal rule in
its body was read as having one. Anchoring to line starts is the intended meaning.

```
node -e '
const fs = require("fs");
// Dot-entries are kept: the Python original used pathlib glob, which (unlike a
// shell glob) does not hide leading-dot names. A missing directory yields none.
const ls = (d) => { try { return fs.readdirSync(d); } catch (e) { if (e.code === "ENOENT") return []; throw e; } };
// statSync follows symlinks, matching what reading the file would do; a Dirent
// would not, and would drop a skill reached through a junction.
const isFile = (p) => { try { return fs.statSync(p).isFile(); } catch (e) { return false; } };
const targets = ls("agents").filter((n) => n.endsWith(".agent.md")).map((n) => "agents/" + n)
  .concat(ls("skills").map((n) => "skills/" + n + "/SKILL.md")).filter(isFile);
// Minimal YAML: top-level "key: value" plus block scalars. 34 and 39 are the quote
// characters, written as codes so this program holds no literal apostrophe.
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
  if (d === null) { findings.push(p + ": missing frontmatter"); continue; }
  for (const k of ["name", "description"]) {
    if (!d[k]) findings.push(p + ": missing or empty \"" + k + "\"");
  }
}
for (const f of findings) console.log(f);
process.exit(findings.length ? 1 : 0);
'
```

### CHANGELOG `[Unreleased]` block

Identical in every shell — run it as-is. Three outcomes, and the exit code agrees with stdout:

| stdout | exit | Meaning |
|---|---|---|
| `OK` | 0 | `CHANGELOG.md` exists and carries an `## [Unreleased]` heading. |
| `MISSING [Unreleased]` | 1 | The file exists but has no `## [Unreleased]` heading. |
| `MISSING CHANGELOG.md` | 1 | There is no `CHANGELOG.md` at all. |

The third outcome is new. Check 7 is two conditions — the file exists *and* it carries the block —
and the previous `grep -q` form collapsed them, reporting `MISSING [Unreleased]` for a plugin with
no changelog whatsoever.

```
node -e '
const fs = require("fs");
let txt;
try { txt = fs.readFileSync("CHANGELOG.md", "utf8"); }
catch (e) {
  if (e.code !== "ENOENT") throw e;
  console.log("MISSING CHANGELOG.md");
  process.exit(1);
}
const ok = /^## \[Unreleased\]/m.test(txt);
console.log(ok ? "OK" : "MISSING [Unreleased]");
process.exit(ok ? 0 : 1);
'
```
