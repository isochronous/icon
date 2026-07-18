---
name: resolve-repo-context
description: >
  Internal manager skill. Do not invoke without explicit direction.
user-invocable: false
---

# Resolve Repo Context

## Overview

**Maps a task description (and optional issue metadata) to the correct sub-project root, context path, and skills directory before implementation begins.** Validates or rebuilds the topology cache, applies signal priority to match the task to a sub-project, returns structured JSON.

Run as an isolated **explore sub-agent** — never inline in the manager's main context.

## When to Use

- Manager has identified `repo_type` as `monorepo`, `workspace`, or `multi-module`
- Manager needs to know which `.context/`, `.claude/claude.md` (or `.github/copilot-instructions.md` on repos still on the legacy path), and project root govern the task

---

## Inputs

Passed via prompt from the manager:

| Field | Required | Description |
|-------|----------|-------------|
| `cwd` | Yes | Absolute path where the manager agent is running |
| `task_description` | Yes | Natural language description of the task |
| `issue_component` | No | Issue component / area field |
| `issue_impacted_area` | No | Impacted area for the issue |
| `issue_repo` | No | Repository the issue belongs to |
| `issue_labels` | No | GitHub issue labels array |

---

## resolve-repo-context: Step 1: Check iconrc

Read `.context/iconrc.json` from the git root.

Minimum fields this skill reads:

```json
{
  "repo_type": "monorepo | workspace | multi-module | project",
  "cache_expires_after_days": 7
}
```

## resolve-repo-context: Step 2: Validate Topology Cache

Read `.context/.topology-cache.json`.

**Cache is valid** when ALL hold:

1. `scanned_at` exists and is within `cache_expires_after_days` of now
2. No topology-defining source file has an `mtime` newer than `scanned_at`

**Topology-defining source files** (check each for drift):
- `.code-workspace`
- Root `package.json`
- `nx.json`
- `*.sln`

**Cache hit** → skip to Step 3 using cached topology.

**Cache miss or stale** → scan the filesystem to discover sub-projects via package manifests, `.code-workspace` folder entries, and solution files. Proceed to Step 3 with fresh topology.

## resolve-repo-context: Step 3: Apply Signal Priority

Match the task to a sub-project using these signals in priority order. Stop at the first **confident** match.

**Priority 1 — Issue metadata** (highest confidence; may short-circuit filesystem scan)
- Match `issue_component` and `issue_impacted_area` against known sub-project names
- Match `issue_labels` against sub-project names or conventional area labels
- Confident → proceed to Step 4 immediately
- Ambiguous or absent → fall through to Priority 2

**Priority 2 — Task description text** (medium confidence)
- Scan for sub-project names, module paths, file paths, or domain keywords
- Validate any candidate against the topology before accepting

**Priority 3 — Topology / filesystem scan** (ground truth fallback)
- If Priorities 1 and 2 are inconclusive, inspect the full topology
- If the task plausibly touches multiple sub-projects: set `scope: cross-project` and resolve root to the git root or lowest common ancestor

## resolve-repo-context: Step 4: Return Structured JSON

Return exactly this schema — no other output format is accepted.

```json
{
  "repo_type": "monorepo | workspace | multi-module | project",
  "resolved_context": {
    "scope": "sub-project | repo-root | cross-project",
    "root": "/absolute/path",
    "git_root": "/absolute/path",
    "instructions": "/absolute/path/.claude/claude.md",  // canonical; falls back to /absolute/path/.github/copilot-instructions.md if not present
    "context": "/absolute/path/.context/",
    "rationale": "human-readable explanation of why this root was chosen"
  },
  "available_skills": [
    {
      "name": "skill-name",
      "description": "...",
      "path": "/absolute/path/SKILL.md",
      "user-invocable": true
    }
  ],
  "projects": [
    {
      "name": "sub-project-name",
      "root": "/absolute/path",
      "is_resolved_context": true
    }
  ]
}
```

**`instructions`**: the canonical instructions file — `.claude/claude.md` if present, else `.github/copilot-instructions.md`.

**`available_skills`**: from the resolved context's skill directory. Return `[]` if no `.context/` exists at the resolved root.

**`projects`**: all discovered sub-projects. Set `is_resolved_context: true` on the matched project; for `cross-project` scope, mark all touched projects `true`.

**All paths must be absolute.** Relative paths are invalid in this schema.

## resolve-repo-context: Step 5: Update Topology Cache

After any filesystem scan (Step 2 stale or missing), write results to `.context/.topology-cache.json`:

```json
{
  "scanned_at": "<ISO 8601 timestamp>",
  "topology": { }
}
```

This file is gitignored — do not commit it.

**Cache hit path (Step 2 valid)**: do not update the cache.

---

## Edge Cases

| Situation | Behavior |
|-----------|----------|
| No `.iconrc` present | Assume `project`; return CWD as root, `available_skills: []`; stop |
| `repo_type: project` in iconrc | Return immediately; `rationale` notes this skill should not be invoked for project repos |
| Cache expired and no issue metadata | Full filesystem scan required; no short-circuit |
| Task spans multiple sub-projects | `scope: cross-project`; resolve root to git root or common ancestor; mark all touched projects |
| `.iconrc` present but cache absent | Fresh filesystem scan; write cache on completion |
| Resolved sub-project has no `.context/` | Return `available_skills: []`; root and path fields still resolve normally |

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Running inline in the manager's context | Dispatch as an isolated explore sub-agent |
| Checking only cache age, not drift | Check topology-defining file mtimes against `scanned_at` |
| Short-circuiting on ambiguous issue metadata | Priority 1 applies to confident matches only; ambiguity falls through to Priority 2 |
| Returning relative paths | Every path in the return schema must be absolute |
| Writing the cache on a cache hit | Write only after a filesystem scan, never on a hit |
| Invoking this skill when `repo_type: project` | Check iconrc first; if project, the manager uses CWD directly |
