// update-plugin-json — Create Phase 2: write the collected metadata into
// `.claude-plugin/plugin.json`, replacing the Phase 1 placeholders.
//
// Contract (ADR-018 — this block converts on ADR-017 trigger 2, mutation):
//   input   five positional arguments, in order:
//             name  version  description  author-name  license-or-null
//           The literal string `null` in the fifth slot writes a JSON null.
//           Values arrive as ARGUMENTS, never interpolated into a program body:
//           an apostrophe in a description or an author name (O'Brien) would
//           otherwise close the shell quote and abort the write.
//   stdout  `WROTE .claude-plugin/plugin.json` once the write has returned.
//   stderr  an uncaught throw's trace when the manifest cannot be read, parsed
//           or written. Nothing is written to the manifest in that case.
//   exit    0 on success, non-zero for a throw.
//
// process.argv.slice(2), NOT slice(1). Under `node -e` there is no script path
// in argv and the user arguments start at index 1; in a committed .mjs argv[1]
// IS the script path. Carrying the inline form's slice(1) across would write
// the script's own absolute path into the manifest's `name` field.
//
// Clause 2 of the ADR-018 guard is why `WROTE` is printed. This block's success
// state was silence, which for a MUTATION is the dangerous direction: a caller
// that never ran the script cannot tell that from a completed write, and would
// go on to the next phase believing the manifest holds the collected values.
//
// KNOWN, UNCHANGED from the inline form: arity is not checked. Supplying fewer
// than five arguments assigns `undefined`, and JSON.stringify DROPS a key whose
// value is undefined, so a short call silently deletes manifest keys rather than
// failing. The `## Validation` re-parse in the prose does not catch it either --
// the result is still valid JSON. Left as-is rather than fixed here, because
// changing it is a behaviour change outside a mechanism conversion.
//
// Two-space indent and a trailing newline, matching the jq form the prose
// offers alongside this one -- other tooling matches the serialized
// "version": "..." literally, so the indent and key order must not change.

import { readFileSync, writeFileSync } from "node:fs";

const [name, version, description, author, lic] = process.argv.slice(2);
const p = ".claude-plugin/plugin.json";
const data = JSON.parse(readFileSync(p, "utf8"));
data.name = name;
data.version = version;
data.description = description;
data.author = { name: author };
data.license = lic === "null" ? null : lic;
writeFileSync(p, JSON.stringify(data, null, 2) + "\n");
process.stdout.write("WROTE " + p + "\n");
