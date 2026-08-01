// check-changelog — Phase 1 check 7: CHANGELOG.md exists and carries an
// `## [Unreleased]` heading.
//
// Contract (ADR-018 — a program belongs in a committed .mjs):
//   input   none. CHANGELOG.md is read relative to process.cwd(), so run this
//           from the audited plugin's root.
//   stdout  exactly one verdict line: `OK`, `MISSING [Unreleased]`, or
//           `MISSING CHANGELOG.md`.
//   stderr  an uncaught throw's trace — a CHANGELOG.md that is a *directory*
//           throws EISDIR here rather than reporting a verdict.
//   exit    0 for OK, 1 for either MISSING, non-zero with empty stdout for a throw.
//
// This block already satisfied ADR-018 Clause 2 before conversion: every
// reachable verdict prints a token, so empty stdout means the block did not
// finish. `process.exit()` became `process.exitCode` so that a write followed
// immediately by an exit cannot truncate the token on a non-blocking pipe,
// which would turn a verdict into exactly the silence Clause 2 forbids.

import { readFileSync } from "node:fs";

let txt = null;
try { txt = readFileSync("CHANGELOG.md", "utf8"); }
catch (e) {
  if (e.code !== "ENOENT") throw e;
}
if (txt === null) {
  process.stdout.write("MISSING CHANGELOG.md\n");
  process.exitCode = 1;
} else {
  const ok = /^## \[Unreleased\]/m.test(txt);
  process.stdout.write(ok ? "OK\n" : "MISSING [Unreleased]\n");
  process.exitCode = ok ? 0 : 1;
}
