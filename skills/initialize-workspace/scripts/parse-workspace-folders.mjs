// parse-workspace-folders — resolve and report on-disk state for every folder
// entry in a `.code-workspace` file, for `initialize-workspace` Step 0.
//
// Contract (ADR-018 — body test, program vs command):
//   input   argv[2] = path to the .code-workspace file
//           argv[3] = the workspace file's own directory (folder paths
//                     resolve relative to this, not to process.cwd())
//   stdout  one tab-separated row per folder entry, in order:
//             "<n>\t<resolved path>\t<raw path>\t<on-disk state>"
//           where <on-disk state> is "on disk" or "NOT ON DISK".
//   stderr  "ERROR: folders[<i>] has no string path key" for a uri-only
//           virtual/remote entry, before any row is written.
//   exit    0 on a normal run (including zero folders). 1 when any folder
//           entry has no string `path` key. An unreadable or invalid-JSON
//           workspace file is an uncaught error — a stack trace on stderr,
//           non-zero exit, no rows — same as the pre-migration inline form.
//
// A folder path is never interpolated into program text — it arrives only as
// an argument (shell-portability Rule 9) — so a quote or backslash in a path
// cannot corrupt anything downstream.
//
// Node built-ins only, `node:`-prefixed, ESM, no `require`, no shebang —
// matching hooks/*.mjs and skills/icon-init/scripts/detect-repo-type.mjs
// (ADR-005).

import { readFileSync, realpathSync } from "node:fs";
import { resolve } from "node:path";

const [wsFile, wsDir] = process.argv.slice(2);
const folders = JSON.parse(readFileSync(wsFile, "utf8")).folders || [];

folders.forEach((f, i) => {
  if (typeof f.path !== "string") {
    process.stderr.write(`ERROR: folders[${i}] has no string path key\n`);
    process.exit(1);
  }
});

folders.forEach((f, i) => {
  let p = resolve(wsDir, f.path);
  let state = "on disk";
  try {
    p = realpathSync(p);
  } catch {
    state = "NOT ON DISK";
  }
  process.stdout.write(`${i + 1}\t${p}\t${f.path}\t${state}\n`);
});
