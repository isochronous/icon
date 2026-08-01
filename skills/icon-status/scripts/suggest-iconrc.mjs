// suggest-iconrc — Suggestions signal 3: `.context/iconrc.json` missing or
// unreadable (icon-status Step 2).
//
// Contract:
//   input   none. Reads `.context/iconrc.json` relative to process.cwd().
//           Run from the repo root.
//   stdout  exactly ONE line, always, and one of exactly three:
//             `- .context/iconrc.json not found — run /upgrade-repo …`
//             `- .context/iconrc.json has no usable "version" — …`
//             `OK iconrc-version-usable`
//   stderr  empty on every documented outcome. `iconrc-version.mjs` already
//           wrote the reason, so this block does not repeat it.
//   exit    0.
//
// It RE-READS the file for itself rather than inheriting `iconrc-version.mjs`'s
// outcome. Separate invocations are separate processes and carry no state
// between them, so a signal waiting on an inherited value could never fire.
// That is not an inefficiency to optimise away — it is what keeps this block
// independently runnable (ADR-017 trigger 1).
//
// Clause 2 (ADR-018): the not-fired state used to be silence, which is
// indistinguishable from the block never running.
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
  process.stdout.write("- .context/iconrc.json not found — run /upgrade-repo to restore it.\n");
} else {
  let v;
  try {
    v = JSON.parse(readFileSync(p, "utf8")).version;
  } catch {
    v = undefined;
  }

  if (typeof v !== "string" || v === "") {
    process.stdout.write(
      '- .context/iconrc.json has no usable "version" — see the error above, or run /upgrade-repo to regenerate it.\n',
    );
  } else {
    process.stdout.write("OK iconrc-version-usable\n");
  }
}
