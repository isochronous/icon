// check-skill-refs — Phase 2 check 1: every `/name` invocation in agent and
// skill body text has a matching `skills/name/SKILL.md`.
//
// Contract (ADR-018 — a program belongs in a committed .mjs):
//   input   none. Targets are resolved relative to process.cwd(), so run this
//           from the audited plugin's root.
//   stdout  `OK` when there are no findings, otherwise one candidate line per
//           unresolved invocation. Never both, and never empty on a completed run.
//   stderr  an uncaught throw's trace.
//   exit    0 whether or not there were findings. This check REPORTS, it does
//           not gate: a harness built-in is indistinguishable from a dead
//           reference here, and the auditor is the one who tells them apart.
//           Read stdout for the verdict; the exit code carries none.
//
// Clause 2 of the ADR-018 guard is why `OK` is printed. With the exit code
// carrying no verdict, silence was the ONLY pass signal, so a run that never
// happened read as a clean audit. `OK` makes empty stdout mean "did not run".

import { readdirSync, readFileSync, statSync } from "node:fs";

// ENOENT and ENOTDIR both yield no entries, matching pathlib glob, which returns
// nothing whether the directory is absent or is actually a regular file.
const ls = (d) => { try { return readdirSync(d); } catch (e) { if (e.code === "ENOENT" || e.code === "ENOTDIR") return []; throw e; } };
const isFile = (p) => { try { return statSync(p).isFile(); } catch (e) { return false; } };
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
  const txt = readFileSync(p, "utf8");
  for (const m of txt.matchAll(INVOCATION)) {
    if (existing.has(m[1])) continue;
    // Heuristic guard: skip references inside URLs, file paths, or command examples.
    const ctx = txt.slice(Math.max(0, m.index - 20), m.index + m[0].length + 20);
    if (SKIP.some((s) => ctx.includes(s))) continue;
    findings.push(p + ": references /" + m[1] + " but skills/" + m[1] + "/SKILL.md not found");
  }
}
if (findings.length === 0) process.stdout.write("OK\n");
else for (const f of findings) process.stdout.write(f + "\n");
