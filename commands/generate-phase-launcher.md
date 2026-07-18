---
description: >
  Generate a harness-specific per-phase launcher script that runs each task-plan phase in a fresh session (Claude Code only)
---

Invoke the `generate-phase-launcher` skill to emit a per-phase launcher for an ICON task. Pass the `target-harness` (`claude-code`, `copilot-cli`, or `generic`) plus the task's `task_id` and `task_folder`. The skill emits a launcher that runs each `plan.md` phase in a fresh, fail-closed session; run `security-review` on the result before unattended use. Copilot users invoke the skill directly.

$ARGUMENTS
