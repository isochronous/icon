// check-manifest-fields — Phase 1 check 3: plugin.json declares the three
// required top-level fields.
//
// Contract (ADR-018 — a program belongs in a committed .mjs):
//   input   none. The manifest is read relative to process.cwd(), so run this
//           from the audited plugin's root.
//   stdout  exactly one verdict line: `OK`, or `MISSING <keys>`.
//   stderr  an uncaught throw's trace when the manifest cannot be read or parsed.
//   exit    0 for OK, 1 for MISSING, non-zero with empty stdout for a throw.
//
// Clause 2 of the ADR-018 guard is why a verdict is printed at all. The inline
// form this replaces was silent on success, so "clean" and "never ran" produced
// the same empty stdout. It is also why the MISSING verdict moved from stderr to
// stdout: leaving it on stderr would restore the same ambiguity on the failing
// branch. stdout carries the result, stderr carries diagnostics, and the exit
// code agrees with the stdout token.

import { readFileSync } from "node:fs";

const d = JSON.parse(readFileSync(".claude-plugin/plugin.json", "utf8"));
const missing = ["name", "version", "description"].filter((k) => !(k in d));
if (missing.length) {
  process.stdout.write("MISSING " + missing.join(", ") + "\n");
  process.exitCode = 1;
} else {
  process.stdout.write("OK\n");
}
