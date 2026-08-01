// check-description-quality — Phase 2 check 3: each frontmatter `description`
// is non-empty, is not the agent/skill name, is not a placeholder, and is at
// least 20 code points long.
//
// Contract (ADR-018 — a program belongs in a committed .mjs):
//   input   none. Targets are resolved relative to process.cwd(), so run this
//           from the audited plugin's root.
//   stdout  `OK` when there are no findings, otherwise at most one finding per
//           file, in the precedence order above. Never both, and never empty on
//           a completed run.
//   stderr  an uncaught throw's trace.
//   exit    0 whether or not there were findings — this check carries no
//           verdict in its exit status. Read stdout for that.
//
// Clause 2 of the ADR-018 guard is why `OK` is printed: with the exit code
// carrying no verdict, silence was the only pass signal.
//
// Block-scalar folding in `fm` is load-bearing here and is not an optimisation
// to remove — see `audit-phase-consistency.md § Frontmatter description
// quality` for the measurement.

import { readdirSync, readFileSync, statSync } from "node:fs";

// ENOENT and ENOTDIR both yield no entries, matching pathlib glob.
const ls = (d) => { try { return readdirSync(d); } catch (e) { if (e.code === "ENOENT" || e.code === "ENOTDIR") return []; throw e; } };
// statSync follows symlinks, matching what reading the file would do. It also
// drops a *directory* named something.agent.md, which would throw EISDIR.
const isFile = (p) => { try { return statSync(p).isFile(); } catch (e) { return false; } };
const targets = ls("agents").filter((n) => n.endsWith(".agent.md")).map((n) => "agents/" + n)
  .concat(ls("skills").map((n) => "skills/" + n + "/SKILL.md")).filter(isFile);
// Minimal YAML, as in Phase 1: top-level "key: value" plus block scalars. 34 and
// 39 are the quote characters, kept as codes only because the inline form could
// hold no literal apostrophe and rewriting working code buys nothing.
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
  if (d === null) continue;
  const desc = (d.description || "").trim();
  const name = (d.name || "").trim();
  // Code points, not UTF-16 units: Array.from iterates by code point, so an
  // astral character counts once, as Python's len() over a str does.
  const n = Array.from(desc).length;
  if (!desc) findings.push(p + ": empty description");
  else if (desc.toLowerCase() === name.toLowerCase()) findings.push(p + ": description equals name (boilerplate)");
  else if (["TODO", "<DESCRIPTION>"].includes(desc.toUpperCase())) findings.push(p + ": placeholder description (" + JSON.stringify(desc) + ")");
  else if (n < 20) findings.push(p + ": description too short (" + n + " chars; aim for >= 20)");
}
if (findings.length === 0) process.stdout.write("OK\n");
else for (const f of findings) process.stdout.write(f + "\n");
