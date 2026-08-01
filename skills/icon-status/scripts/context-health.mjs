// context-health — per-subdirectory `.md` counts (icon-status Step 2).
//
// Contract:
//   input   none. Reads `.context/<subdir>` relative to process.cwd().
//           Run from the repo root.
//   stdout  one indented line per PRESENT subdirectory, in the fixed order
//           below:
//             `  .context/<name>/ — N files`
//           and, when none of the six is present, the single line
//             `OK no-context-subdirectories`
//   stderr  empty on every documented outcome.
//   exit    0.
//
// An absent subdirectory produces no line, which is how the dashboard omits
// it. A subdirectory that is present but unreadable produces `— 0 files`, not
// an omission: it exists, and the count is what could not be established.
//
// Clause 2 (ADR-018): the all-absent state used to be total silence, which is
// indistinguishable from the block never running. It now prints
// `OK no-context-subdirectories`, so the caller can require a line on every
// path.
//
// Rule 10 — two different Node idioms in one loop, deliberately:
//   * the DIRECTORY test is `statSync().isDirectory()`, which FOLLOWS a
//     symlink, so a symlinked `.context/domains` is reported and the files
//     behind it are counted;
//   * the ENTRY test is `Dirent.isFile()`, which does NOT follow a symlink, so
//     a symlink pointing at a `.md` file is not counted — it is a link, not a
//     file.
// Dot-prefixed names such as `.hidden.md` ARE counted; `Dirent` enumeration
// has no glob semantics to exclude them.
//
// ESM, `node:`-prefixed imports, no `require`, no shebang, standard library
// only (ADR-005).

import { readdirSync, statSync } from "node:fs";

const SUBDIRS = ["domains", "standards", "workflows", "architecture", "testing", "styling"];

let printed = 0;

for (const d of SUBDIRS) {
  const p = ".context/" + d;

  let isDir = false;
  try {
    isDir = statSync(p).isDirectory();
  } catch {
    isDir = false;
  }
  if (!isDir) continue;

  let count = 0;
  try {
    count = readdirSync(p, { withFileTypes: true }).filter(
      (e) => e.isFile() && e.name.endsWith(".md"),
    ).length;
  } catch {
    count = 0;
  }

  process.stdout.write("  .context/" + d + "/ — " + count + " files\n");
  printed += 1;
}

if (printed === 0) process.stdout.write("OK no-context-subdirectories\n");
