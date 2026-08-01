// check-frontmatter — Phase 1 checks 5 and 6: every agents/*.agent.md and
// skills/*/SKILL.md opens with a frontmatter block declaring a non-empty
// `name` and `description`.
//
// Contract (ADR-018 — a program belongs in a committed .mjs):
//   input   none. Targets are resolved relative to process.cwd(), so run this
//           from the audited plugin's root.
//   stdout  `OK` when there are no findings, otherwise one `<path>: <finding>`
//           line per finding. Never both, and never empty on a completed run.
//   stderr  an uncaught throw's trace. Absent and non-directory `agents/` /
//           `skills/` are not errors and contribute no targets.
//   exit    0 with `OK`, 1 with findings, non-zero with empty stdout for a throw.
//
// Clause 2 of the ADR-018 guard is why `OK` is printed. The inline form was
// silent on a clean run, so a run that never happened was indistinguishable
// from a clean audit. `process.exitCode` rather than `process.exit()` for the
// same reason: exiting immediately after a write can truncate stdout on a
// non-blocking pipe, and truncated findings read as silence.
//
// This is NOT YAML validation — see `audit-phase-structure.md § Frontmatter
// parse` for the fidelity limit, which the prose states and this file does not
// restate.

import { readdirSync, readFileSync, statSync } from "node:fs";

// Dot-entries are kept: the Python original used pathlib glob, which (unlike a
// shell glob) does not hide leading-dot names. ENOENT and ENOTDIR both yield no
// entries, matching that glob, which returns nothing whether the directory is
// absent or is actually a regular file.
const ls = (d) => { try { return readdirSync(d); } catch (e) { if (e.code === "ENOENT" || e.code === "ENOTDIR") return []; throw e; } };
// statSync follows symlinks, matching what reading the file would do; a Dirent
// would not, and would drop a skill reached through a junction. It also drops a
// *directory* named something.agent.md, which would throw EISDIR on read.
const isFile = (p) => { try { return statSync(p).isFile(); } catch (e) { return false; } };
const targets = ls("agents").filter((n) => n.endsWith(".agent.md")).map((n) => "agents/" + n)
  .concat(ls("skills").map((n) => "skills/" + n + "/SKILL.md")).filter(isFile);
// Minimal YAML: top-level "key: value" plus block scalars. 34 and 39 are the
// quote characters. They were written as codes because the inline form was a
// single-quoted shell word and could hold no literal apostrophe; a .mjs has no
// such restriction, and the numeric form is kept only because rewriting working
// code buys nothing. The same is true of the doubled quotes in the finding
// message below.
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
  const d = fm(readFileSync(p, "utf8"));
  if (d === null) { findings.push(p + ": missing frontmatter"); continue; }
  for (const k of ["name", "description"]) {
    if (!d[k]) findings.push(p + ": missing or empty \"" + k + "\"");
  }
}
if (findings.length === 0) process.stdout.write("OK\n");
else for (const f of findings) process.stdout.write(f + "\n");
process.exitCode = findings.length ? 1 : 0;
