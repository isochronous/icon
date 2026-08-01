// suggest-domains — Suggestions signal 1: `.context/domains/` missing or
// empty (icon-status Step 2).
//
// Contract:
//   input   none. Reads `.context/domains` relative to process.cwd().
//           Run from the repo root.
//   stdout  exactly ONE line, always, and one of exactly three:
//             `- No .context/domains/ directory — run /upgrade-repo …`
//             `- .context/domains/ has no files — run /upgrade-repo …`
//             `OK domains-populated`
//   stderr  empty on every documented outcome.
//   exit    0.
//
// A line starting `- ` is the suggestion and belongs on the dashboard. `OK …`
// is the signal reporting that it ran and did not fire; it is never rendered.
//
// Clause 2 (ADR-018): the not-fired state used to be silence, which is
// indistinguishable from the block never running — and a suggestion that
// silently never fires is the whole failure mode Suggestions exists to avoid.
//
// It counts files exactly as `context-health.mjs` does: the directory test
// follows symlinks (`statSync`), the entry test does not (`Dirent`), and
// dot-prefixed `.md` names are counted (Rule 10).
//
// ESM, `node:`-prefixed imports, no `require`, no shebang, standard library
// only (ADR-005).

import { readdirSync, statSync } from "node:fs";

const p = ".context/domains";

let isDir = false;
try {
  isDir = statSync(p).isDirectory();
} catch {
  isDir = false;
}

if (!isDir) {
  process.stdout.write(
    "- No .context/domains/ directory — run /upgrade-repo to bring context current.\n",
  );
} else {
  let count = 0;
  try {
    count = readdirSync(p, { withFileTypes: true }).filter(
      (e) => e.isFile() && e.name.endsWith(".md"),
    ).length;
  } catch {
    count = 0;
  }

  if (count === 0) {
    process.stdout.write(
      "- .context/domains/ has no files — run /upgrade-repo to bring context current.\n",
    );
  } else {
    process.stdout.write("OK domains-populated\n");
  }
}
