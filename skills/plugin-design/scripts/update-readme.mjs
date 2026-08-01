// update-readme — Create Phase 2: replace README.md's placeholder title and
// description line with the collected values.
//
// Contract (ADR-018 — a program belongs in a committed .mjs; this block also
// converts on ADR-017 trigger 2, mutation):
//   input   two positional arguments, in order:  name  description
//           Values arrive as ARGUMENTS, never interpolated into a program body,
//           for the same apostrophe reason as update-plugin-json.mjs.
//   stdout  `WROTE README.md` once the write has returned.
//   stderr  an uncaught throw's trace when README.md cannot be read or written.
//   exit    0 on success, non-zero for a throw.
//
// process.argv.slice(2), NOT slice(1) — see update-plugin-json.mjs for why the
// index differs between `node -e` and a committed .mjs.
//
// Clause 2 of the ADR-018 guard is why `WROTE` is printed: this block's success
// state was silence, and for a mutation that makes "never ran" and "rewrote the
// file" the same observation.
//
// Written back LF-terminated with no BOM regardless of platform — using the
// host's line ending here would rewrite every line of the file.

import { readFileSync, writeFileSync } from "node:fs";

const [name, description] = process.argv.slice(2);
const lines = readFileSync("README.md", "utf8").split(/\r?\n/);
if (lines[lines.length - 1] === "") lines.pop();
lines[0] = "# " + name;
for (let i = 1; i < lines.length; i++) {
  if (lines[i].trim() && !lines[i].startsWith("#")) { lines[i] = description; break; }
}
writeFileSync("README.md", lines.join("\n") + "\n");
process.stdout.write("WROTE README.md\n");
