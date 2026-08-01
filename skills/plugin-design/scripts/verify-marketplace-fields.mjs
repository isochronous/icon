// verify-marketplace-fields — Create Phase 5: the manifest parses and declares
// the fields a marketplace typically requires, treating an empty value and an
// empty object as not declared.
//
// Contract (ADR-018 — a program belongs in a committed .mjs):
//   input   none. The manifest is read relative to process.cwd(), so run this
//           from the plugin's root.
//   stdout  one verdict line: `plugin.json OK; declared fields: <names>`, or
//           `missing required fields: <names>`. Both field lists print as plain
//           comma-separated names, not as a language-specific list literal.
//   stderr  an uncaught throw's trace when the manifest cannot be read or parsed.
//   exit    0 for OK, 1 for missing fields, non-zero with empty stdout for a throw.
//
// The success branch already printed an affirmative token before conversion, so
// ADR-018 Clause 2 was satisfied for the pass state. The failing verdict moved
// from stderr to stdout to satisfy the committed-script channel rule that
// stdout carries the result and the exit code agrees with the stdout token --
// and, with it, so that empty stdout means one thing only: the script did not
// run. On the inline form empty stdout meant either that or a missing field.

import { readFileSync } from "node:fs";

const data = JSON.parse(readFileSync(".claude-plugin/plugin.json", "utf8"));
const empty = (v) => !v || (typeof v === "object" && Object.keys(v).length === 0);
const missing = ["name", "version", "description", "author"].filter((k) => empty(data[k]));
if (missing.length) {
  process.stdout.write("missing required fields: " + missing.join(", ") + "\n");
  process.exitCode = 1;
} else {
  process.stdout.write("plugin.json OK; declared fields: " + Object.keys(data).sort().join(", ") + "\n");
}
