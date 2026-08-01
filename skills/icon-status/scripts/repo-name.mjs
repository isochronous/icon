// repo-name — the dashboard's repo-name line (icon-status Step 2).
//
// Contract:
//   input   none. Probes the git repo containing process.cwd().
//   stdout  exactly one line, always: the repo name, or `(unknown)`.
//   stderr  git's own error text for any rung that failed, passed through.
//   exit    0.
//
// The two channels are never merged. A git failure at any rung is a
// diagnostic, not a value: it reaches stderr and the chain falls through, so
// an error message can never arrive on the dashboard as the repo's name.
//
// This block always prints, so Clause 2 (affirmative token) does not bind:
// empty stdout from it already means the block did not run.
//
// ESM, `node:`-prefixed imports, no `require`, no shebang, standard library
// only (ADR-005).

import { basename } from "node:path";
import { execFileSync } from "node:child_process";

// Returns git's trimmed stdout, or "" when git fails for any reason.
// `stdio` is deliberately left at its default so the child's stderr is
// inherited rather than captured — that is what keeps a git error on the
// diagnostic channel.
function git(args) {
  try {
    return execFileSync("git", args, { encoding: "utf8" }).trim();
  } catch {
    return "";
  }
}

// Three sources, tried in order, stopping at the first that yields a value.
let name = git(["remote", "get-url", "origin"]).replace(/^.*[/:]/, "").replace(/\.git$/, "");
if (!name) name = basename(git(["rev-parse", "--show-toplevel"]));
if (!name) name = "(unknown)";

process.stdout.write(name + "\n");
