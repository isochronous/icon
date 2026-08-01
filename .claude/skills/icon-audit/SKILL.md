---
name: icon-audit
description: >
  Use when auditing the ICON plugin's own agent definitions, skills, infrastructure, and cross-cutting quality concerns — especially after a major refactor, before a release, or when retrospective entries cluster around a recurring failure class. Maintainer-only: this skill audits ICON itself and references ICON-specific architecture, ADRs, and finding IDs; it does not generalize to other plugins.
user-invocable: true
---

# ICON Audit

## Overview

Run a 6-domain parallel audit that dispatches one sub-agent per domain, then synthesizes findings into a tiered report with scorecard, defect inventory, improvement opportunities, delta vs prior audit, and fix-tier recommendations. Even when no defects are found, each domain sub-agent must produce at least 3 forward-looking improvement opportunities.

## When to Use

- Before a major release to establish a health baseline.
- After a large refactor to check for structural drift.
- On a recurring cadence (e.g., after every 10–15 task completions).
- When retrospective entries start clustering around a common failure class.
- When you suspect an agent's scope, responsibility, or skill-routing has drifted.

**When NOT to use:**
- For single-agent or single-skill spot checks — use `agent-evaluation` directly.
- For context-document health checks only — use `context-maintenance`.

---

## icon-audit: Phase 1: Discovery

Before dispatching any sub-agents, establish the baseline.

The command below is one `node -e` program. Run it in **bash or PowerShell 7** — it is a
single-quoted shell word containing double quotes, and Windows PowerShell 5.1 does not escape
those when it builds the native command line, so it fails there at parse time with a visible
`SyntaxError` and empty stdout rather than a wrong answer.

It prints, in order: the prior-audit baseline (or a baseline-run note), the retrospectives and
CHANGELOG line counts, and the agent/skill/manifest counts — record all of it in `plan.md` per the
Phase 1 output list below.

Missing inputs are reported, not silently absorbed — and "missing" is wider than "absent". A
`.context/retrospectives.md` or `CHANGELOG.md` that is absent, that is a *directory*, or that has a
regular file somewhere in its path prints `(not found)` in place of its count. An `agents/` or
`skills/` directory that cannot be listed prints `0` and names the reason on
stderr: `cannot access agents: No such file or directory` when nothing is there,
`cannot access agents: Not a directory` when a regular file holds the name. That separates both from
a genuinely empty directory, which also counts `0` but writes nothing to stderr. Every guard in the
block catches `ENOENT` and `ENOTDIR` together, and `lineCount` catches `EISDIR` as well, because an
uncaught one aborts the program where it is thrown and forfeits every later line — measured, a
regular file named `agents` costs the three trailing counts, a regular file at `.context/tasks`
costs the entire output, and a directory named `CHANGELOG.md` cost four of the six lines before the
`EISDIR` arm existed. Those three codes are the whole of the coverage, not a synonym for
*unreadable*: a file that is present but cannot be opened still aborts the run, measured on an
exclusively locked `CHANGELOG.md` — `EBUSY`, exit 1, two lines of six. Treat any of these
as "no data available for this line," not as an error.

```
node -e '
const fs = require("fs");

// 1.1 — find the most recent prior plugin audit, if any. Lexicographic sort
// over zero-padded task IDs is numerically correct here: Array.prototype.sort()
// is lexicographic by default, and ICON-NNNN task-folder names are zero-padded
// to >= 3 digits, so string order agrees with numeric order.
const tasksDir = ".context/tasks";
const priorAudits = [];
let taskEntries = [];
try {
  taskEntries = fs.readdirSync(tasksDir, { withFileTypes: true });
} catch (err) {
  // ENOTDIR: .context/tasks exists but is a regular file. Same result as absent
  // -- no task entries -- rather than an uncaught throw that loses all of Phase 1.
  if (err.code !== "ENOENT" && err.code !== "ENOTDIR") throw err;
}
for (const entry of taskEntries) {
  if (entry.isDirectory()) {
    const nested = tasksDir + "/" + entry.name + "/audit-report.md";
    if (fs.existsSync(nested)) priorAudits.push(nested);
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
    text = fs.readFileSync(file, "utf8");
  } catch (err) {
    // ENOTDIR covers a path component that is a regular file. On win32 that case
    // surfaces as ENOENT instead, so this arm is what keeps the two platforms
    // agreeing rather than one throwing where the other reports (not found).
    // EISDIR covers the path itself being a directory; without it a directory
    // named CHANGELOG.md aborted here and forfeited the four lines after it.
    if (err.code === "ENOENT" || err.code === "ENOTDIR" || err.code === "EISDIR") return "(not found)";
    throw err;
  }
  return String((text.match(/\n/g) || []).length);
}
console.log(lineCount(".context/retrospectives.md") + " .context/retrospectives.md");
console.log(lineCount("CHANGELOG.md") + " CHANGELOG.md");

// 1.4 — filesystem scale. readdirSync includes dot-entries, unlike `ls`
// without -a, so dot-entries are filtered out to match `ls | wc -l`. A missing
// directory reports 0 on stdout, matching `ls` (error to stderr) + `wc -l` (0)
// rather than throwing — and it writes the same kind of diagnostic `ls` did to
// stderr, because a bare 0 on stdout cannot be told apart from an empty
// directory. stdout stays the count; the reason stays on stderr.
function countEntries(dir) {
  let entries;
  try {
    entries = fs.readdirSync(dir);
  } catch (err) {
    // A directory that is really a regular file (ENOTDIR) counts 0 exactly as an
    // absent one does, but says so with its own reason -- keeping "absent",
    // "not a directory" and "empty" three distinguishable states, not two.
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
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch (err) {
    // Same two codes as the guards above. On the recursive calls both are races
    // against the listing that produced this path: the entry was a directory
    // then and has since gone (ENOENT) or become a regular file (ENOTDIR). The
    // first call is passed ".", which no listing preceded -- there ENOENT would
    // mean the working directory itself was removed out from under the process.
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
'
```

**Phase 1 output** — record in `plan.md` Decisions before dispatching Phase 2:
- Prior audit ID and date (e.g., "baseline: MKT-0046, 2026-04-21").
- Count of retrospective entries since baseline.
- Count of CHANGELOG entries since baseline.
- Current counts: agents, skills, manifests.
- 1–2 line "known-churning areas" note distilled from retros and CHANGELOG.

Every domain brief references this preamble — it ensures all six sub-agents use the same agreed baseline.

**If no prior audit exists**, record "no prior audit — this is baseline run" and skip the Delta section in synthesis. Treat all findings as net-new.

---

## icon-audit: Phase 2: Parallel Dispatch

Before dispatching, set up the task folder using `task-plan`:
- Create `.context/tasks/<TASK-ID>-icon-audit/plan.md` (seed it with the Phase 1 baseline preamble).
- Create `.context/tasks/<TASK-ID>-icon-audit/research/` (empty; sub-agents write here).

Dispatch all six domain sub-agents in parallel. Each receives its brief from `./briefs/` and writes its output to `<task-folder>/research/<NN>-<domain>.md`.

| # | Brief | Domain scope |
|---|-------|--------------|
| 01 | `./briefs/01-agents.md` | Agent definitions — frontmatter, sections, role overlap |
| 02 | `./briefs/02-process-skills.md` | Orchestration and discipline skills |
| 03 | `./briefs/03-context-specialist-init.md` | Context-specialist agent + init skill tree |
| 04 | `./briefs/04-utility-skills.md` | Standalone utility skills |
| 05 | `./briefs/05-infrastructure.md` | Manifests, scripts, CI, documentation |
| 06 | `./briefs/06-cross-cutting.md` | Token economics, discoverability, onboarding, retrospective patterns |

**Dispatch rules:**
- Each sub-agent reads its brief in full before investigating.
- Each sub-agent reads the prior audit's findings for its domain before writing anything — to distinguish fixed, still-present, and net-new items.
- Sub-agent 06 (cross-cutting) consumes outputs from 01–05; dispatch it after the others complete.
- No sub-agent edits plugin source files. All output goes to `<task-folder>/research/`.

---

## icon-audit: Phase 3: Synthesis

After all six research files are produced, synthesize into `<task-folder>/audit-report.md` using `./synthesis-template.md` as the structural guide.

Synthesis steps:
1. Read all six research files in full.
2. Deduplicate findings that appear in multiple domains. Assign ownership to the most specific domain; note cross-domain overlap in the synthesis narrative.
3. Fill the Executive Summary scorecard using the 5-rule framework from `agent-evaluation` (borrowed lens; do not duplicate the rule definitions — cross-reference).
4. Tier all defects: Critical (correctness risk), Moderate (quality risk), Minor (style/clarity).
5. Collect all Improvement Opportunities; organize into the 5 standard categories (see `synthesis-template.md`).
6. Write the Delta section (fixed / still-present / net-new vs prior audit).
7. Write Fix Tiers, Open Questions, and Suggested Follow-up Tasks.
8. Post a summary in chat: top-line counts, delta, top 3 Tier-1 recommendations, offer to file follow-up tasks as issues (subject to user confirmation).

---

## Self-Application

This skill operates on the repo root. The plugin's manifest is at `.claude-plugin/plugin.json`. In this standalone repo there is only one plugin, so no auto-detection is required. (Earlier marketplace-monorepo invocations supported per-plugin-directory auto-detection with a user prompt on ambiguity — that path is retired.)

**What the user receives when the audit completes:**

1. A task folder `.context/tasks/<TASK-ID>-icon-audit/` containing:
   - `plan.md` (Phase 1 baseline preamble + dispatch record)
   - `research/01-agents.md` through `research/06-cross-cutting.md`
   - `audit-report.md` matching `synthesis-template.md` structure
2. A chat summary with:
   - Top-line counts (Critical / Moderate / Minor / Improvements)
   - Delta vs prior audit (fixed / still-present / net-new counts)
   - Top 3 Tier-1 recommendations
   - Offer to file Suggested Follow-up Tasks as GitLab issues (requires user confirmation per common-constraints data-exfiltration rule)

**Overriding the domain list** — for a non-ICON plugin whose domains don't map cleanly to the 6 defaults:
1. Copy `./briefs/` to `<task-folder>/briefs-custom/`.
2. Add, remove, or rename briefs as needed. Keep the shared skeleton headers intact (Scope / Inputs / Prior-Audit Pointer / Forward-Looking Improvements Mandate / Output Shape / Non-Goals). The `## Scope` section is the per-domain-variable slot — every brief names its own files and investigation axes here; the remaining five headers carry invariant preamble.
3. Update `synthesis-template.md`'s domain-specific sub-section tables to match.
4. In Phase 2 dispatch, point the brief enumeration at the custom path.

---

## Cross-References

- **`agent-evaluation`**: The synthesis scorecard borrows the 5-rule framework from `agent-evaluation`. That skill is independent and user-invocable on its own for single-agent design reviews. Do not replace it — reference it.
- **`context-maintenance`**: Run after the audit to apply any context-document drift the audit surfaces.
- **`task-plan`**: Seed the task plan in Phase 1 before dispatching Phase 2.
- **`writing-skills`**: Quality checklist for any skills found needing authoring as part of follow-up tasks.

---

## Quality Checklist

Before reporting the audit complete, verify against the Skill Creation Checklist in `writing-skills`. Additionally:

- [ ] Every finding in every research file cites `<file>:<line-range>` — no conclusions without locations.
- [ ] Synthesis scorecard rule names match the 5-rule framework in `agent-evaluation` verbatim.
- [ ] Each domain produced at least 3 improvement opportunities (forward-looking mandate).
- [ ] Delta section has three sub-sections: fixed / still-present or partial / net-new.
- [ ] Suggested follow-up tasks are filed as GitLab issues (or explicitly deferred with user confirmation).
- [ ] `## Post-Review Dispositions` table filled at user-triage — every Moderate-or-higher finding and every Improvement Opportunity has a disposition (accepted/deferred/rejected) with a reason and, where accepted, a linked follow-up task ID.
- [ ] Retrospective entry appended to `.context/retrospectives.md` via `@context-specialist` (`mode: maintenance`) running the `append-retrospective-entry` script.
- [ ] Any numeric or computed claim in audited content — a worked example, a formula, a headline rate, a cited statistic — has been independently recomputed and checked against any source it cites, not read for shape. Numbers embedded in prose are skimmed, not verified, by default; four consecutive audits read `ecological-impact`'s worked example without catching that it disagreed with its own formulas by 1000× (ICON-0092). Flag any computed value nothing in the repo can re-derive, even if no other defect is present.
