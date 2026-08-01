// recent-retrospectives — the three most recent retrospective headings
// (icon-status Step 2).
//
// Contract:
//   input   none. Reads `.context/retrospectives.md` relative to
//           process.cwd(). Run from the repo root.
//   stdout  exactly one of:
//             up to three `### TASK-ID …` heading lines, in FILE ORDER
//             `(no retrospectives.md)`        the file is absent
//             `OK no-retrospective-entries`   the file has no task-ID headings
//   stderr  empty on every documented outcome.
//   exit    0.
//
// File order is load-bearing: `retrospectives.md` is newest-first, so the
// first three matches ARE the most recent three. Do not sort them and do not
// take the last three.
//
// Clause 2 (ADR-018): this block's "nothing to report" state used to be
// silence, which is indistinguishable from the block never running. It now
// prints `OK no-retrospective-entries` instead, so the caller can require a
// line on every path.
//
// The file test is `statSync().isFile()`, which FOLLOWS a symlink — a
// symlinked `retrospectives.md` is read, matching `[ -f ]` rather than a
// `Dirent` (Rule 10: port semantics, not shape).
//
// ESM, `node:`-prefixed imports, no `require`, no shebang, standard library
// only (ADR-005).

import { readFileSync, statSync } from "node:fs";

const p = ".context/retrospectives.md";

let isFile = false;
try {
  isFile = statSync(p).isFile();
} catch {
  isFile = false;
}

if (!isFile) {
  process.stdout.write("(no retrospectives.md)\n");
} else {
  const hits = readFileSync(p, "utf8")
    .split(/\r?\n/)
    .filter((l) => /^### [A-Z]+-[0-9]+/.test(l))
    .slice(0, 3);
  if (hits.length) {
    for (const l of hits) process.stdout.write(l + "\n");
  } else {
    process.stdout.write("OK no-retrospective-entries\n");
  }
}
