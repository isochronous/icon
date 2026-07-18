---
name: context-specialist-create
description: >
  Internal @context-specialist skill. Do not invoke without explicit direction.
user-invocable: false
---

# Context Specialist — Create Mode

Initialize a `.context/` directory for a repository node. This skill is loaded
inline by `@context-specialist` when `mode` is `create` or absent (default).
It handles tree-position resolution and implementation skill selection.

**You cannot delegate to sub-agents.** All work — detection, implementation, commit —
is performed inline by you. Copilot CLI nested dispatch produces no output; attempting to
sub-delegate silently fails.

---

## Inputs

| Parameter | Required | Description |
|-----------|----------|-------------|
| `working_directory` | yes | Absolute path of the target directory — set as your CWD |
| `tree_position` | recommended | `leaf`, `branch`, or `root`; skip detection entirely if provided |
| `git_root` | recommended | Git repo root for all git operations. Defaults to `working_directory` if absent. |
| `feature_branch` | recommended | Branch to commit to; verify active before committing. If absent, detect from context. |

---

## Process

### context-specialist-create: Step 1: Confirm tree position

- If the caller provided `tree_position: leaf|branch|root`, use that value — **skip
  detection entirely**. This is the normal path.
- If `tree_position` is absent, invoke the `context-specialist-detect-tree-position`
  skill to determine the position. **Do not inline detection logic** — load and follow the
  skill.
- If detection returns no definitive result, surface the ambiguity to the caller rather
  than guessing.

### context-specialist-create: Step 2: Load implementation skill

Based on the confirmed tree position, load the corresponding skill inline:

| Tree Position | Skill to Load |
|---------------|---------------|
| `leaf`        | `context-specialist-impl-leaf` |
| `branch`      | `context-specialist-impl-branch` |
| `root`        | `context-specialist-impl-root` |

**Execute the skill inline. Do not dispatch a sub-agent.** Follow every step of the
loaded skill completely — do not cherry-pick steps.

### context-specialist-create: Step 3: Commit

After all `.context/` files are created or updated:

1. Use `git_root` as the working directory for all git operations.
2. Scope `git add` to files inside `working_directory` only — do not stage sibling
   or parent directory files.
3. Commit to `feature_branch` using the convention from the delegation prompt, or
   detect from `git --no-pager log --oneline -20` at `git_root`.
4. Note the commit SHA for the completion report.

### context-specialist-create: Step 4: Report

Return a structured completion summary to the caller:

```
Tree position: [leaf | branch | root] ([detected | provided])
Files created or updated: [list each file path]
Commit SHA: [sha]
Warnings: [any gaps, ambiguities, or skipped files — or "none"]
```

---

## Constraints

**Never delegate to sub-agents.** All implementation is inline. This applies to:
- Tree-position detection: use the `context-specialist-detect-tree-position` skill
  inline, not as a sub-agent dispatch.
- Implementation: load and execute the impl skill inline, not as a sub-agent dispatch.

**Do not inline tree-position detection logic.** The algorithm lives in
`context-specialist-detect-tree-position`. Always load that skill when detection is
needed — don't copy or re-implement the algorithm here.

**Scope git operations strictly.** `git add` targets files inside `working_directory`
only. Never stage files outside this directory.

## Anti-Rationalization

| Rationalization | Reality | Correct Action |
|----------------|---------|----------------|
| "I'll dispatch the detect skill as a sub-agent" | Nested dispatch produces no output | Load the skill inline and execute it. |
| "The caller probably meant leaf — I won't bother detecting" | Wrong position produces wrong file set | Detect via skill or confirm before loading any impl. |
| "I'll skip committing — the caller will handle it" | Files left uncommitted are lost on branch switch | Commit as part of this process; report the SHA. |
| "I'll cherry-pick a few steps from the impl skill" | Partial execution leaves context incomplete | Follow every step of the loaded skill in full. |
