---
name: invoke-sub-project-skill
description: >
  Internal manager skill. Do not invoke without explicit direction.
user-invocable: false
---

# Invoke Sub-Project Skill

## Overview

Loads a skill from an absolute path and frames it as an active invocation. The framing is the key distinction: without it, an agent treats a skill file as reference material; with it, it executes the skill's instructions.

## When to Use

- The manager received `available_skills` from `resolve-repo-context` and needs to invoke one of those skills
- A specific skill path is known and a task is ready to run with it

## When NOT to Use

- You need to find which skills are available — that's `resolve-repo-context`'s job; call it first
- The target skill is already loaded from the ICON plugin — invoke it by name directly
- You only want to read a skill file for reference — just read it; this skill is for execution, not consultation

## invoke-sub-project-skill: Step 1: Verify the file exists

Check that the file at `skill_path` exists before proceeding:

```bash
test -f "$skill_path" || echo "ERROR: Skill not found at $skill_path"
```

If the file does not exist, stop and report:

```
ERROR: Skill not found at <skill_path>. Verify the path returned by resolve-repo-context is correct and the plugin is installed.
```

Do not proceed past a missing file.

## invoke-sub-project-skill: Step 2: Read the skill content

Read the full contents of `skill_path`, including frontmatter.

## invoke-sub-project-skill: Step 3: Frame and execute

Construct the invocation with this exact structure — the framing language is mandatory:

```
The following is a skill definition. Read it and execute its instructions to accomplish the task.

---
<full contents of skill_path>
---

Task: <task>
```

Execute with this framing. It signals the content is to be followed as active instructions, not consulted as documentation.

## Loading vs. Discovery

This skill handles **loading and framing only**. Discovering which skills are available at a path — scanning `.copilot/skills/` or reading `available_skills` from the resolution result — is `resolve-repo-context`'s job, not this.

Call this skill only after you have a specific `skill_path`.
