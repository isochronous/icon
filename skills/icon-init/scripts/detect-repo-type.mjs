// detect-repo-type — repo-shape detection for `icon-init` Step 2.
//
// Contract (ADR-017 — executable content home):
//   input   none. The probe target is process.cwd().
//   stdout  exactly one token, newline-terminated, no trailing prose:
//             workspace | monorepo | multimodule | project | undetermined
//   stderr  warnings and probe-failure reasons.
//   exit    0 when a type was determined (INCLUDING the `project` fallback),
//           2 for `undetermined`.
//
// The two channels are never merged. Folding a diagnostic into the value
// channel is what made the original Step 2b `workspaces` probe fail open, and
// re-merging them here would reintroduce that defect. stdout and exit code say
// the same thing on purpose: the redundancy is what makes a caller that reads
// only one of them still fail closed.
//
// Node built-ins only, `node:`-prefixed, ESM, no `require`, no shebang —
// matching hooks/*.mjs (ADR-005). Failure posture is the OPPOSITE of the
// harness hooks': they fail open by design, a detector must fail closed.

import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";

const CWD = process.cwd();

// Manifests that mark a directory as a single project. Order is not
// significant — presence of any one is sufficient.
const LEAF_MANIFESTS = [
  "package.json",
  "go.mod",
  "Cargo.toml",
  "pyproject.toml",
  "requirements.txt",
  "Gemfile",
  "build.gradle",
];

// A subdirectory additionally counts as a module when it carries a pom.xml,
// which at the root is ambiguous (parent vs leaf) and handled separately.
const SUBDIR_MANIFESTS = [...LEAF_MANIFESTS, "pom.xml"];

function warn(message) {
  process.stderr.write(`${message}\n`);
}

// `[ -f X ]` / `[ -d X ]` equivalents: false on absent, unreadable, or the
// wrong node type, exactly as the shell test they replace.
function isFile(...parts) {
  try {
    return statSync(join(CWD, ...parts)).isFile();
  } catch {
    return false;
  }
}

function isDir(...parts) {
  try {
    return statSync(join(CWD, ...parts)).isDirectory();
  } catch {
    return false;
  }
}

// Returns null when the directory could not be listed — a probe failure, which
// callers must distinguish from "listed, nothing matched".
function listDir(dir) {
  try {
    return readdirSync(dir, { withFileTypes: true });
  } catch {
    return null;
  }
}

function detect() {
  const rootEntries = listDir(CWD);
  if (rootEntries === null) {
    warn("ERROR: the working directory could not be listed; repo shape is unknown.");
    return "undetermined";
  }
  const rootFiles = rootEntries.filter((e) => e.isFile()).map((e) => e.name);

  // --- 2a: workspace — a *.code-workspace file at CWD --------------------
  if (rootFiles.some((n) => n.endsWith(".code-workspace"))) return "workspace";

  // --- 2b: monorepo — explicit multi-project orchestration signals -------
  if (isFile("nx.json") || isFile("turbo.json") || isFile("go.work")) return "monorepo";

  if (rootFiles.some((n) => n.endsWith(".sln"))) return "monorepo";

  if (isFile("package.json")) {
    let workspaces;
    try {
      workspaces = JSON.parse(readFileSync(join(CWD, "package.json"), "utf8")).workspaces;
    } catch (err) {
      // Fail closed. package.json is present but could not be read or parsed,
      // which is exactly the precondition of the project check below — falling
      // through would report a confident "project" for a repo whose shape is
      // unknown.
      warn(`ERROR: package.json is present but could not be probed: ${err.message}`);
      return "undetermined";
    }
    // Must be a NON-EMPTY array. `"workspaces": []` is not a monorepo signal.
    if (Array.isArray(workspaces) && workspaces.length > 0) return "monorepo";
  }

  if (isFile("pom.xml")) {
    let pom;
    try {
      pom = readFileSync(join(CWD, "pom.xml"), "utf8");
    } catch (err) {
      warn(`ERROR: pom.xml is present but could not be probed: ${err.message}`);
      return "undetermined";
    }
    // Project-as-parent pattern: declares <modules> and has no src/ sibling.
    // A pom.xml WITH src/ is a leaf and falls through to the project check.
    if (pom.includes("<modules>") && !isDir("src")) return "monorepo";
  }

  // --- 2c: project (leaf) — a build manifest at CWD ----------------------
  if (LEAF_MANIFESTS.some((m) => isFile(m))) return "project";

  if (rootFiles.some((n) => n.endsWith(".csproj"))) return "project";

  if (isFile("pom.xml") && isDir("src")) return "project";

  // --- 2d: multimodule — 2+ immediate subdirs carry build manifests ------
  //
  // The candidate set must reproduce the shell's `for SUBDIR in */` plus
  // `[ -d "$SUBDIR" ]`, NOT a dirent's idea of a directory. The two are
  // inverted on both axes: the `*/` glob EXCLUDES dot-directories and
  // INCLUDES links to directories, while `entry.isDirectory()` includes
  // dot-directories and excludes links. So the name filter stands in for the
  // glob, and `isDir` — statSync, which follows links exactly as `[ -d ]`
  // does — stands in for the test. Using the dirent instead would count
  // `.github/` as a module and drop a module reached through a junction.
  const subdirNames = rootEntries
    .map((e) => e.name)
    .filter((name) => !name.startsWith(".") && isDir(name));

  let manifestDirCount = 0;
  for (const name of subdirNames) {
    let found = SUBDIR_MANIFESTS.some((m) => isFile(name, m));

    // Only scan for *.csproj if no standard manifest was found in this subdir.
    if (!found) {
      const subEntries = listDir(join(CWD, name));
      if (subEntries === null) {
        warn(
          `WARNING: ${name}/ could not be listed; not counted toward the multimodule threshold.`,
        );
      } else {
        found = subEntries.some((e) => e.isFile() && e.name.endsWith(".csproj"));
      }
    }

    if (found) manifestDirCount += 1;
  }
  // Two or more. One subdirectory with a manifest is not a multimodule tree.
  if (manifestDirCount >= 2) return "multimodule";

  // --- 2e: fallback — no signals matched. Never guess silently. ----------
  warn("WARNING: Repo type could not be determined from manifest signals. Defaulting to 'project'.");
  warn("Review the result after initialization and re-run with a different type if needed.");
  return "project";
}

let type;
try {
  type = detect();
} catch (err) {
  // Any unanticipated failure resolves to `undetermined`, never to a type.
  warn(`ERROR: detection aborted: ${err && err.message ? err.message : String(err)}`);
  type = "undetermined";
}

if (type === "undetermined") {
  warn("WARNING: Repo type could not be determined — a detection probe failed.");
  warn("Not defaulting to a type: the failed probe covers the same file the default would key on.");
  warn("The caller must present the override list and wait for an explicit choice.");
}

// Set the code and let the process exit naturally. Forcing an immediate exit
// straight after a write can truncate stdout on a non-blocking pipe, and the
// caller captures stdout — a dropped token would leave the exit code alone to
// carry the answer, which is the single-channel reliance the header forbids.
process.stdout.write(`${type}\n`);
process.exitCode = type === "undetermined" ? 2 : 0;
