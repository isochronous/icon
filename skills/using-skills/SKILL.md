---
name: using-skills
description: >
  MANDATORY — execute this skill before starting any task. Forces skill invocation and prevents agents from skipping applicable skills. Run before clarifying questions, before exploring code, before any other action — including when the task feels "simple", when "I already know how to do this" is the response, when about to type a clarifying question instead of checking the catalog, or when an applicable skill is being skipped on the strength of remembered content.
user-invocable: false
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill. The dispatching agent already ran the catalog check; your job is the task in your prompt.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply, you ABSOLUTELY MUST invoke it.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

Not negotiable. Not optional. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## The Rule

**Invoke relevant skills BEFORE any response or action.** Even a 1% chance means invoke and check. If the skill turns out wrong for the situation, move on — one read costs less than skipping the discipline.

This applies before clarifying questions, before reading code, before any action. Skills tell you HOW to do those things.

## Instruction Priority

User instructions override skills:

1. **User's explicit instructions** (CLAUDE.md, AGENTS.md, GEMINI.md, direct requests) — highest.
2. **ICON skills** — override default model behavior where they conflict.
3. **Default model behavior** — lowest.

If the user says "skip TDD for this hotfix" and `testing-discipline` says "always TDD", follow the user.

## Rationalization Prevention

These thoughts mean STOP — you are rationalizing past the catalog check:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git or files quickly" | File state lacks process context. Check the catalog. |
| "Let me gather information first" | Skills tell you HOW to gather it. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember what this skill says" | Skills evolve. Read the current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent that. |
| "I know what that means" | Knowing the concept ≠ following the process. Invoke it. |

## Red Flags — STOP and Check the Catalog

If you catch yourself doing any of these, stop and run the Skill tool:

- About to ask a clarifying question without first checking the skill catalog.
- About to read code or run grep before invoking the relevant process skill.
- Acting on "I remember what the skill says" instead of re-reading.
- Treating "this seems too simple" as evidence no skill applies.
- Have not yet announced the skill you are using and why.

**All of these mean: check the catalog now. One read costs less than skipping the discipline.**

## Skill Priority

When multiple skills apply, invoke in this order:

1. **Process skills** — `systematic-debugging`, `characterization-testing`, `testing-discipline`, `task-retrospective`, `design-first` — determine HOW to approach the work. Use `characterization-testing` instead of `testing-discipline` when code already exists with no coverage — lock behavior first, then apply `testing-discipline` for new tests.
2. **Discipline skills** — `verification-checklist`, `commit-discipline`, `pr-discipline` — enforce quality gates.
3. **Maintenance skills** — `context-maintenance` — keep project knowledge current.
4. **Formatting skills** — `github-issue`, `rfc` — shape the output.

Example: "Fix this bug and write tests for it" → `systematic-debugging` → `testing-discipline` → `verification-checklist`.
Example: "Modify legacy code with no tests" → `characterization-testing` → `testing-discipline` → `verification-checklist`.
Example: "Work a task end-to-end" → `task-plan` → `task-plan-phase-investigation` → `task-plan-phase-implementation` → `task-plan-phase-completion` → `task-retrospective`.

To find which skills apply for any task: read each skill's description. Descriptions name their triggers.

## Skill Types

**Rigid** (systematic-debugging, characterization-testing, testing-discipline, verification-checklist, commit-discipline, pr-discipline): follow exactly. Don't adapt away the discipline.

**Flexible** (initialize-repo, context-maintenance, rfc, github-issue, design-first): adapt structure to fit. The template is a starting point.

**Meta** (using-skills, writing-skills): system references.

## User Instructions vs. Skills

User instructions say WHAT, not HOW. "Add X" or "Fix Y" doesn't mean skip the workflow — both apply at once.
