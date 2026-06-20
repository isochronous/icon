---
name: initialize-repo
description: >
  Use when setting up a new repository to use the agent system for the first time.
  Covers creating the .context/ folder, populating all files exhaustively from
  the actual codebase, and wiring the automatic task-pruning git hook. Run once
  per repository.
user-invocable: false
---

# Initialize Repository

**This skill is a thin router.** The implementation lives in `@context-specialist`
via the `context-specialist-impl-leaf` skill.

---

## If you are @context-specialist

<!-- Fallback only — not reached in standard flows. @context-specialist's own
     Process (Step 3) maps tree_position directly to impl skills without ever
     reading initialize-repo. This branch exists as a safety net for unforeseen
     future invocations. -->
Load the `context-specialist-impl-leaf` skill and execute it inline.
Do not dispatch a sub-agent.

---

## If you are any other agent (manager, or skill invoked by user)

Dispatch `@context-specialist` as an isolated background agent using the
task tool with `agent_type: "ICON:context-specialist"`.

Use the following prompt, substituting `<CWD>` with the absolute path of the
target project directory:

~~~
You are @context-specialist. Initialize agent-system context for a project.

tree_position: leaf
working_directory: <CWD>

Load and execute the `context-specialist-impl-leaf` skill.
Work autonomously — do not pause for user confirmation or input at any point.
Commit all created files using the commit convention detected from
`git log --oneline -20`. Run to completion without stopping.
~~~

Wait for the agent to complete, then verify:
- `.context/` directory exists at `<CWD>`
- `.context/overview.md` exists and contains real content
- `.context/iconrc.json` exists

If verification fails, re-dispatch with the same prompt.
