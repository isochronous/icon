// suggest-stale-plan — Suggestions signal 4: a task branch whose `plan.md`
// has not been modified in 48h (icon-status Step 2).
//
// Contract:
//   input   none. Probes the git repo containing process.cwd(), then
//           `.context/tasks` relative to it. Run from the repo root.
//   stdout  exactly ONE line, always, and one of exactly five:
//             `- plan.md stale — not modified in 48h. Still working on this?`
//             `OK no-task-id`         branch carries no PROJ-123 style ID
//             `OK no-plan-file`       no matching plan.md under .context/tasks
//             `OK plan-fresh`         modified within 48h
//             `OK plan-unstattable`   a match was found but could not be
//                                     stat'd; no staleness claim is possible
//   stderr  git's own error text when the branch probe failed, and the stat
//           failure reason on `OK plan-unstattable`. Empty otherwise.
//   exit    0.
//
// It RE-DERIVES the task ID from the branch and RE-RUNS the `plan.md` lookup
// rather than inheriting them from `branch-and-task.mjs`, for the same reason
// `suggest-iconrc.mjs` re-reads the JSON: separate invocations are separate
// processes and carry no state between them. That is what keeps this block
// independently runnable (ADR-017 trigger 1).
//
// Clause 2 (ADR-018): four of the five outcomes used to be silence, which is
// indistinguishable from the block never running.
//
// Staleness is measured with `lstatSync`, which does NOT follow a symlink —
// a symlinked `plan.md` is judged on the link's own mtime, which is the
// shipped semantics.
//
// The comparison is deliberately UNFLOORED. Measured on GNU findutils 4.10.0,
// `find -mmin +2880` compares exact timestamps rather than truncating, so
// `(now - mtime) / 60000 > 2880` is the faithful mapping; a floored form would
// fire up to a minute late. Do not "correct" it.
//
// ESM, `node:`-prefixed imports, no `require`, no shebang, standard library
// only (ADR-005). The branch probe, the task-ID regex and the `plan.md`
// walker live in `task-lookup.mjs`, shared with `branch-and-task.mjs`.

import { lstatSync } from "node:fs";
import { findPlanFiles, gitBranch, taskIdFrom } from "./task-lookup.mjs";

// 48h, exclusive.
const STALE_MINUTES = 2880;

const taskId = taskIdFrom(gitBranch());

if (!taskId) {
  process.stdout.write("OK no-task-id\n");
} else {
  const hits = findPlanFiles(taskId);

  if (!hits.length) {
    process.stdout.write("OK no-plan-file\n");
  } else {
    let st = null;
    try {
      st = lstatSync(hits[0]);
    } catch (err) {
      process.stderr.write(hits[0] + " could not be stat'd: " + err.message + "\n");
      st = null;
    }

    if (st === null) {
      process.stdout.write("OK plan-unstattable\n");
    } else if ((Date.now() - st.mtimeMs) / 60000 > STALE_MINUTES) {
      process.stdout.write("- plan.md stale — not modified in 48h. Still working on this?\n");
    } else {
      process.stdout.write("OK plan-fresh\n");
    }
  }
}
