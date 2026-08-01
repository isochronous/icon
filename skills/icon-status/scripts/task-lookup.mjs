// task-lookup — shared helpers for icon-status's two task-derived blocks.
//
// NOT AN ENTRY POINT. This module is imported by `branch-and-task.mjs` and
// `suggest-stale-plan.mjs`. Running it directly does nothing and prints
// nothing; it takes no arguments and has no side effects on import.
//
// Why it exists — and the motive is correctness, not size. Those two blocks
// previously carried byte-identical copies of the same branch probe, the same
// task-ID regex and the same `plan.md` walker. Two copies of a walker drift,
// and a drift here has a specific consequence: the dashboard would name one
// `plan.md` while the staleness signal stats a different one. ADR-017's
// cross-skill duplication rule is not engaged — this is one skill's own
// `scripts/` directory, and an installed skill may reference a file inside it.
//
// Consolidating does NOT reintroduce cross-fence state (ADR-017 trigger 1).
// Each caller is its own process and re-derives every input from scratch, so
// both blocks stay independently runnable, in any order, with no inherited
// environment.
//
// Relative paths resolve against process.cwd() — run the callers from the
// repo root.
//
// ESM, `node:`-prefixed imports, no `require`, no shebang, standard library
// only (ADR-005).

import { readdirSync } from "node:fs";
import { execFileSync } from "node:child_process";

// The checked-out branch, or "" when git fails for any reason — not a git
// repo, git not installed, a detached probe that errors.
//
// `stdio` is deliberately left at its default so the child's stderr is
// inherited: git's own error text must reach stderr, never become the value.
export function gitBranch() {
  try {
    return execFileSync("git", ["rev-parse", "--abbrev-ref", "HEAD"], { encoding: "utf8" }).trim();
  } catch {
    return "";
  }
}

// The first PROJ-123-style ID in the branch name; "" when there is none.
export function taskIdFrom(branch) {
  const m = branch.match(/[A-Z]+-[0-9]+/);
  return m ? m[0] : "";
}

// Every `plan.md` one or two levels below `.context/tasks` whose path contains
// the task ID, **sorted**. Sorted rather than filesystem order on purpose: the
// pre-Node original took whichever entry the filesystem happened to return
// first, which is not reproducible across machines.
//
// `depth < 2` is a depth budget, not a glob: it admits entries one and two
// levels below `.context/tasks`. Recursion keys on the `Dirent`, which does
// NOT follow a symlinked subdirectory — that is the shipped semantics and it
// is preserved deliberately (Rule 10: port semantics, not shape).
//
// Path segments are joined with a literal "/" rather than `path.join`, because
// the joined string is both the `taskId` substring test and the value printed
// as `PLAN_FILE=`. `path.join` would emit backslashes on Windows and change
// both.
export function findPlanFiles(taskId) {
  const hits = [];
  (function scan(dir, depth) {
    let entries = [];
    try {
      entries = readdirSync(dir, { withFileTypes: true });
    } catch {
      return;
    }
    for (const e of entries) {
      const p = dir + "/" + e.name;
      if (e.name === "plan.md" && p.includes(taskId)) hits.push(p);
      if (depth < 2 && e.isDirectory()) scan(p, depth + 1);
    }
  })(".context/tasks", 1);
  hits.sort();
  return hits;
}
