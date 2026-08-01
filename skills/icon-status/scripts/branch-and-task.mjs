// branch-and-task — branch, task ID and plan file (icon-status Step 2).
//
// Contract:
//   input   none. Probes the git repo containing process.cwd(), then
//           `.context/tasks` relative to it. Run from the repo root.
//   stdout  two or three `KEY=value` lines, always at least two:
//             BRANCH=<name>        empty outside a git repo
//             TASK_ID=<id>         empty when the branch carries none
//             PLAN_FILE=<path>     or `(none)`; OMITTED when TASK_ID is empty
//   stderr  git's own error text when the branch probe failed.
//   exit    0.
//
// The three are one block because each is derived from the one before: the
// task ID comes from the branch name, the plan file from the task ID.
//
// This block always prints at least two lines, so Clause 2 (affirmative
// token) does not bind: empty stdout already means the block did not run.
//
// ESM, `node:`-prefixed imports, no `require`, no shebang, standard library
// only (ADR-005). The branch probe, the task-ID regex and the `plan.md`
// walker live in `task-lookup.mjs`, shared with `suggest-stale-plan.mjs`.

import { findPlanFiles, gitBranch, taskIdFrom } from "./task-lookup.mjs";

const branch = gitBranch();
const taskId = taskIdFrom(branch);

// Built as one string and written once. Writing then calling `process.exit()`
// can truncate stdout on a non-blocking pipe, and every line here is part of
// the result.
let out = "BRANCH=" + branch + "\n" + "TASK_ID=" + taskId + "\n";

// No task ID means there is nothing to look up, so no PLAN_FILE line at all —
// which the caller reads the same way it reads `(none)`.
if (taskId) {
  const hits = findPlanFiles(taskId);
  out += "PLAN_FILE=" + (hits.length ? hits[0] : "(none)") + "\n";
}

process.stdout.write(out);
