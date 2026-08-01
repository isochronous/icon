// icon-audit-discovery — Phase 1 baseline discovery for the maintainer-only
// `icon-audit` skill.
//
// Contract (ADR-018 — body test, program vs command):
//   input   none. Probes process.cwd() — run from the repo root being audited.
//   stdout  six lines, always, in this order:
//             1. "Baseline: <path>" or the baseline-run note
//             2. "<n> .context/retrospectives.md" (or "(not found) ...")
//             3. "<n> CHANGELOG.md" (or "(not found) ...")
//             4. "<n>       # agent count"
//             5. "<n>       # skill count"
//             6. "<n>       # manifest count"
//   stderr  diagnostics only, e.g. "cannot access agents: <reason>" — never
//           merged into stdout.
//   exit    0 on a normal run, including every "(not found)" / 0-count line.
//           A non-zero exit with a stack trace on stderr means the run was
//           aborted by an error none of the per-guard ENOENT/ENOTDIR/EISDIR
//           catches cover — e.g. EBUSY on an exclusively locked file, the
//           documented remaining gap (see SKILL.md Phase 1).
//
// Node built-ins only, `node:`-prefixed, ESM, no `require`, no shebang —
// matching hooks/*.mjs and skills/icon-init/scripts/detect-repo-type.mjs
// (ADR-005).

import { existsSync, readdirSync, readFileSync } from "node:fs";

// 1.1 — find the most recent prior plugin audit, if any. Lexicographic sort
// over zero-padded task IDs is numerically correct here: Array.prototype.sort()
// is lexicographic by default, and ICON-NNNN task-folder names are zero-padded
// to >= 3 digits, so string order agrees with numeric order.
const tasksDir = ".context/tasks";
const priorAudits = [];
let taskEntries = [];
try {
  taskEntries = readdirSync(tasksDir, { withFileTypes: true });
} catch (err) {
  // ENOTDIR: .context/tasks exists but is a regular file. Same result as
  // absent -- no task entries -- rather than an uncaught throw that loses
  // all of Phase 1.
  if (err.code !== "ENOENT" && err.code !== "ENOTDIR") throw err;
}
for (const entry of taskEntries) {
  if (entry.isDirectory()) {
    const nested = tasksDir + "/" + entry.name + "/audit-report.md";
    if (existsSync(nested)) priorAudits.push(nested);
  } else if (entry.name === "audit-report.md") {
    priorAudits.push(tasksDir + "/" + entry.name);
  }
}
priorAudits.sort();
const priorAudit = priorAudits.length ? priorAudits[priorAudits.length - 1] : "";
if (priorAudit) {
  console.log("Baseline: " + priorAudit);
} else {
  console.log("No prior audit found — this is a baseline run. All findings will be reported as net-new.");
}

// 1.2 / 1.3 — retrospectives and CHANGELOG line counts. wc -l counts newline
// characters, not "lines"; a missing file reports "(not found)" rather than
// throwing, so an absent input is visible on stdout instead of vanishing —
// the same convention icon-status states in its "Step 2: Gather data" preamble.
function lineCount(file) {
  let text;
  try {
    text = readFileSync(file, "utf8");
  } catch (err) {
    // ENOTDIR covers a path component that is a regular file. On win32 that
    // case surfaces as ENOENT instead, so this arm is what keeps the two
    // platforms agreeing rather than one throwing where the other reports
    // (not found). EISDIR covers the path itself being a directory; without
    // it a directory named CHANGELOG.md aborted here and forfeited the four
    // lines after it.
    if (err.code === "ENOENT" || err.code === "ENOTDIR" || err.code === "EISDIR") return "(not found)";
    throw err;
  }
  return String((text.match(/\n/g) || []).length);
}
console.log(lineCount(".context/retrospectives.md") + " .context/retrospectives.md");
console.log(lineCount("CHANGELOG.md") + " CHANGELOG.md");

// 1.4 — filesystem scale. readdirSync includes dot-entries, unlike `ls`
// without -a, so dot-entries are filtered out to match `ls | wc -l`. A
// missing directory reports 0 on stdout, matching `ls` (error to stderr) +
// `wc -l` (0) rather than throwing — and it writes the same kind of
// diagnostic `ls` did to stderr, because a bare 0 on stdout cannot be told
// apart from an empty directory. stdout stays the count; the reason stays on
// stderr.
function countEntries(dir) {
  let entries;
  try {
    entries = readdirSync(dir);
  } catch (err) {
    // A directory that is really a regular file (ENOTDIR) counts 0 exactly
    // as an absent one does, but says so with its own reason -- keeping
    // "absent", "not a directory" and "empty" three distinguishable states,
    // not two.
    if (err.code === "ENOENT" || err.code === "ENOTDIR") {
      const why = err.code === "ENOENT" ? "No such file or directory" : "Not a directory";
      process.stderr.write("cannot access " + dir + ": " + why + "\n");
      return 0;
    }
    throw err;
  }
  return entries.filter((name) => name[0] !== ".").length;
}
console.log(countEntries("agents") + "       # agent count");
console.log(countEntries("skills") + "       # skill count");

// Manifest count: depth <= 3 from ".", regular files named plugin.json
// (Dirent.isFile() does not follow symlinks, matching find -type f), with
// .context and .git excluded before descending — not merely filtered after,
// since walking .git is slow and can surface a stray plugin.json in a packed
// object path.
function countManifests(dir, depth) {
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch (err) {
    // Same two codes as the guards above. On the recursive calls both are
    // races against the listing that produced this path: the entry was a
    // directory then and has since gone (ENOENT) or become a regular file
    // (ENOTDIR). The first call is passed ".", which no listing preceded --
    // there ENOENT would mean the working directory itself was removed out
    // from under the process.
    if (err.code === "ENOENT" || err.code === "ENOTDIR") return 0;
    throw err;
  }
  let count = 0;
  for (const entry of entries) {
    const childPath = dir + "/" + entry.name;
    const childDepth = depth + 1;
    if (childPath === "./.context" || childPath === "./.git") continue;
    if (entry.isFile() && entry.name === "plugin.json" && childDepth <= 3) {
      count += 1;
    } else if (entry.isDirectory() && childDepth < 3) {
      count += countManifests(childPath, childDepth);
    }
  }
  return count;
}
console.log(countManifests(".", 0) + "       # manifest count");
