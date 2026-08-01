// iconrc-version — the dashboard's `.context/iconrc.json` line
// (icon-status Step 2).
//
// Contract:
//   input   none. Reads `.context/iconrc.json` relative to process.cwd().
//           Run from the repo root.
//   stdout  exactly ONE line, always, and one of exactly three:
//             `  .context/iconrc.json — version <X.Y>`
//             `  .context/iconrc.json — not found`
//             `  .context/iconrc.json — version (unreadable)`
//   stderr  the reason, whenever the outcome is `(unreadable)`. Empty
//           otherwise.
//   exit    0.
//
// The empty-result guard is the point of this block, not a detail of it: an
// empty read must never reach the dashboard as a value, because `version `
// with nothing after it reads as a healthy line. An absent, non-string or
// empty `version`, and a file that will not parse, all resolve to the one
// visible token `(unreadable)` — with the reason on stderr, never on stdout.
//
// There is no fourth outcome and no silent one, so Clause 2 (affirmative
// token) does not bind: empty stdout already means the block did not run.
//
// The file test is `statSync().isFile()`, which FOLLOWS a symlink (Rule 10).
//
// ESM, `node:`-prefixed imports, no `require`, no shebang, standard library
// only (ADR-005).

import { readFileSync, statSync } from "node:fs";

const p = ".context/iconrc.json";

let isFile = false;
try {
  isFile = statSync(p).isFile();
} catch {
  isFile = false;
}

if (!isFile) {
  process.stdout.write("  .context/iconrc.json — not found\n");
} else {
  let version;
  try {
    const v = JSON.parse(readFileSync(p, "utf8")).version;
    if (typeof v === "string" && v !== "") version = v;
    else process.stderr.write('iconrc.json parsed, but "version" is missing or not a string\n');
  } catch (err) {
    process.stderr.write("iconrc.json could not be read or parsed: " + err.message + "\n");
  }

  if (version === undefined) {
    process.stderr.write(
      'ERROR: no usable "version" in .context/iconrc.json (reason above, on stderr).\n',
    );
    process.stdout.write("  .context/iconrc.json — version (unreadable)\n");
  } else {
    process.stdout.write("  .context/iconrc.json — version " + version + "\n");
  }
}
