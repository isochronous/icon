# Audit — Phase 1: Structure Validation

## Overview

Verify the plugin's file/folder layout and frontmatter are well-formed. These findings block marketplace listing — a plugin that fails structural validation will not load cleanly in Claude Code.

## Checks

For each check, report a pass/fail line with a path if applicable.

1. **`plugin.json` parses as valid JSON** — required.
2. **`plugin.json` declares `$schema`** — recommended; ideally `https://json.schemastore.org/claude-code-plugin-manifest.json` for IDE validation.
3. **`plugin.json` declares `name`, `version`, `description`** — required.
4. **Standard directories exist** — `agents/`, `skills/`, `commands/`, `hooks/`, `shared/`. Not all are mandatory (a skill-only plugin may omit `agents/`), but report each present/absent for a sanity-check.
5. **Every `agents/*.agent.md` has a frontmatter block** declaring at least `name` and `description`. The snippet below verifies the block is present and that both keys are non-empty. It does **not** verify that the block is valid YAML — see the fidelity limit under *Frontmatter parse*.
6. **Every `skills/*/SKILL.md` has a frontmatter block** declaring at least `name` and `description`. Same scope and same limit as check 5.
7. **`CHANGELOG.md` exists** and contains an `## [Unreleased]` block.

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

### plugin.json

Run it as-is in bash or PowerShell 7. Silence and exit 0 mean all three fields
are declared; anything else goes to stderr and exits 1.

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

Run it as-is in bash or PowerShell 7. It walks every `agents/*.agent.md` and `skills/*/SKILL.md` and
prints one line per finding to stdout: a file with no frontmatter block, or one whose `name` or
`description` is missing or empty. Silence and exit 0 mean **every file has a frontmatter block and
both keys are non-empty** — not that the YAML is valid; read the fidelity limit below before
treating a clean run as more than that. Any finding exits 1. A missing `agents/` or `skills/`
directory contributes no files rather than erroring — check 4 above already allows a skill-only
plugin — and so does one that exists but is a regular file rather than a directory.

**Fidelity limit — read this before treating a clean run as YAML validation.** Node ships no YAML
parser and ICON forbids third-party imports (ADR-005), so the block parses a deliberate subset:
top-level `key: value`, and `>` / `>-` / `|` / `|-` block scalars. Block-scalar folding is shared
with the Phase 2 description-quality check, which uses this same parser
(`audit-phase-consistency.md § Frontmatter description quality`), and it is load-bearing here too —
in a narrower case than Phase 2's. Where a block scalar *has* content, folding changes nothing this
check can see: the test is only non-emptiness, and an unfolded `>` is itself a non-empty string, so a
folding-skipped parser produces byte-identical output over this repo (463 bytes either way). The case
that matters is an **empty** block scalar. `description: >` with nothing indented under it folds to
the empty string and is reported; a folding-skipped parser stores the literal `">"`, finds it
non-empty, and says nothing. That is a false pass, so the folding stays. Mutation-verified on a
two-key `name: x` / `description: >` fixture: this parser printed `missing or empty "description"`
and exited 1, while the folding-skipped mutant printed nothing and exited 0.

Two findings the previous Python version emitted are **not reproduced**, because a subset parser
cannot produce them honestly. They are not equivalent, and the difference matters:

- **`YAML parse error`** — malformed YAML is not detected at all; a broken block is read for
  whatever `key:` lines it still exposes. **This one can become a false pass.** A file whose
  frontmatter is unparseable YAML but still exposes non-empty `name:` and `description:` lines
  produces no finding, and if it is the only defect present the run exits 0 — which the paragraph
  above defines as every file having its block and both keys. Measured against the Python original
  over two such files (an unterminated double-quoted scalar, and a tab-indented line): the original
  reported `YAML parse error` for both and exited 1; this block reported nothing and exited 0.
- **`frontmatter is not a mapping`** — a scalar or sequence frontmatter block **does** still produce
  findings, under a less precise name: it surfaces as missing `name` *and* missing `description`
  rather than as a type error. No false pass here.

So a clean run is **not** YAML validation. The retired PowerShell variant detected YAML errors no
better — it matched `name:` / `description:` by regex — so this is not a loss relative to what
Windows already had. It is still a real gap: a plugin that needs YAML validation should run `yq` or
a YAML linter separately, and a CI gate should not treat exit 0 from this block as proof the
frontmatter parses.

Three **cosmetic** divergences from the Python original are also deliberate. They affect only how a
finding is worded, never whether it fires. Two are forced by the program body being a single-quoted
shell word, which therefore cannot contain an apostrophe: restoring Python's `'…'` quoting would
mean assembling the character via `String.fromCharCode(39)`, which costs more clarity than the
rendering is worth. The third is the ASCII-only rule, so the text survives every console codepage.

| Python original | These blocks | Where | Cause |
|---|---|---|---|
| `missing or empty 'name'` | `missing or empty "name"` | this block | no apostrophe |
| `repr(desc)` → `'TODO'` | `JSON.stringify(desc)` → `"TODO"` | Phase 2 description quality | no apostrophe |
| `aim for ≥ 20` | `aim for >= 20` | Phase 2 description quality | ASCII only |

The block is also **stricter about where frontmatter starts**: the file must open with a `---` line,
and the block ends at the next line that is exactly `---`. The Python version split on the first two
`---` sequences anywhere in the text, so a file with no frontmatter but a `---` horizontal rule in
its body was read as having one. Anchoring to line starts is the intended meaning.

```
node -e '
const fs = require("fs");
// Dot-entries are kept: the Python original used pathlib glob, which (unlike a
// shell glob) does not hide leading-dot names. ENOENT and ENOTDIR both yield no
// entries, matching that glob, which returns nothing whether the directory is
// absent or is actually a regular file.
const ls = (d) => { try { return fs.readdirSync(d); } catch (e) { if (e.code === "ENOENT" || e.code === "ENOTDIR") return []; throw e; } };
// statSync follows symlinks, matching what reading the file would do; a Dirent
// would not, and would drop a skill reached through a junction. It also drops a
// *directory* named something.agent.md, which would throw EISDIR on read.
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

Run it as-is in bash or PowerShell 7. Read stdout **and** the exit code together; the last row is the
one with no verdict in it at all, so exit alone would misreport it as an ordinary failure:

| stdout | exit | Meaning |
|---|---|---|
| `OK` | 0 | `CHANGELOG.md` exists and carries an `## [Unreleased]` heading. |
| `MISSING [Unreleased]` | 1 | The file exists but has no `## [Unreleased]` heading. |
| `MISSING CHANGELOG.md` | 1 | There is no `CHANGELOG.md` at all. |
| *(nothing)* | 1 | The block did not finish, and reached no verdict — a `CHANGELOG.md` that is a *directory* throws `EISDIR` out of `readFileSync`, with the trace on stderr. Fix the tree and re-run. |

The `MISSING CHANGELOG.md` outcome is new. Check 7 is two conditions — the file exists *and* it
carries the block — and the previous `grep -q` form collapsed them, reporting `MISSING [Unreleased]`
for a plugin with no changelog whatsoever.

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
