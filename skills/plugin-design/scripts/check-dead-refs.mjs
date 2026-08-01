// check-dead-refs — Phase 2 check 2: every `.context/<path>.<ext>` token in a
// shipped surface resolves under `context_template/context/` or `.context/`.
//
// Contract (ADR-018 — a program belongs in a committed .mjs):
//   input   none. The four scanned roots are resolved relative to
//           process.cwd(), so run this from the audited plugin's root.
//   stdout  `OK` when there are no findings, otherwise one
//           `<file>: dead ref <token>` line per finding. Never both, and never
//           empty on a completed run.
//   stderr  an uncaught throw's trace. An absent root, a root that is a regular
//           file, and an entry statSync cannot resolve are all skipped rather
//           than thrown.
//   exit    0 whether or not there were findings — this check carries no
//           verdict in its exit status. Read stdout for that.
//
// Clause 2 of the ADR-018 guard is why `OK` is printed, and it matters most
// here: with the exit code carrying no verdict, silence was the only pass
// signal for a check whose worst failure mode is a silent false-clean.

import { existsSync, readFileSync, readdirSync, realpathSync, statSync } from "node:fs";

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
const isDir = (p) => { try { return statSync(p).isDirectory(); } catch (e) { return false; } };
const isFile = (p) => { try { return statSync(p).isFile(); } catch (e) { return false; } };
const seen = new Set();
function walk(dir, out) {
  let real;
  try { real = realpathSync(dir); } catch (e) { if (e.code === "ENOENT") return out; throw e; }
  if (seen.has(real)) return out;
  seen.add(real);
  let ents;
  try { ents = readdirSync(dir); }
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
    for (const m of readFileSync(p, "utf8").matchAll(/\.context\/[a-zA-Z0-9_\/-]+\.[a-zA-Z0-9]+/g)) {
      const rest = m[0].slice(".context/".length);
      // ICON self-audit: content lives under context_template/context/.
      // Generic plugins: content lives at the plugin .context/ root
      // (the audit-mode hard precondition guarantees .context/ exists).
      if (existsSync("context_template/context/" + rest)) continue;
      if (existsSync(".context/" + rest)) continue;
      findings.push(p + ": dead ref " + m[0]);
    }
  }
}
if (findings.length === 0) process.stdout.write("OK\n");
else for (const f of findings) process.stdout.write(f + "\n");
