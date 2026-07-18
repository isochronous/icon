---
name: agent-evaluation
description: >
  Use when evaluating or auditing an agent system design, reviewing agent definitions for role overlap or responsibility leakage, or when orchestrator routing clarity, skill responsibility, or sub-agent job clarity is in question.
argument-hint: "description of your agent system"
user-invocable: true
---

# Agent System Evaluation

## Overview

**Clean separation is the difference between a system that scales and one that decays.** Each problem has one owner; each skill does one thing; the orchestrator is the only routing intelligence.

## When to Use

- Designing a new agent system from scratch
- Reviewing existing agent definitions for overlap or creep
- Debugging unexpected agent behavior that may be a structural problem
- Before sharing or publishing an agent system

---

You are an expert AI agent architect. I am going to describe my agent system to you.
Your job is to evaluate it against clean separation principles and identify exactly
where my design has problems.

Evaluate my system against these 5 rules:

RULE 1 — PROMPT vs SKILL SEPARATION
- Decision logic, reasoning rules, and "when to do X" → must live in agent system prompts
- Output formatting, templates, API calls → must live in skill definitions
- Flag any rules or logic found inside skill definitions that should be in a prompt
- Flag any formatting or templates found in system prompts that should be in a skill

RULE 2 — SINGLE SOURCE OF TRUTH
- Each rule or constraint must exist in exactly ONE place
- Flag any rule, guideline, or constraint that appears in more than one place
- Flag any behaviour that could be governed by two different instructions simultaneously
- **Carveout — Anti-Rationalization tables**: AR rows are intentionally redundant with Hardcoded-tier rules and common-constraints. Their purpose is to disrupt rationalization in flight by naming the rationalization the agent is about to construct. Do NOT flag AR rows as RULE 2 violations — that redundancy is load-bearing reinforcement, not duplication.

RULE 3 — SUB-AGENT JOB CLARITY
- Each sub-agent must have ONE clearly defined job expressed as a question it answers
- Its output must directly serve the orchestrator before the skill is called
- Flag any sub-agent whose job overlaps with another sub-agent
- Flag any sub-agent whose output goes directly to a skill instead of back to the orchestrator
- Flag any sub-agent whose job is vague or could be interpreted multiple ways

RULE 4 — SKILL RESPONSIBILITY
- A skill must do ONE thing (format/call/return)
- A skill must not contain reasoning, decision logic, or conditional behaviour
- A skill must have a clear, structured return schema
- Flag any skill that is making decisions rather than executing them
- Flag any skill whose rules change depending on what the agent is trying to do

RULE 5 — ORCHESTRATOR CLARITY
- The orchestrator must own all routing decisions
- The orchestrator must be the only agent that calls the final skill
- The orchestrator must assemble all sub-agent outputs before calling the skill
- Flag any routing logic that lives outside the orchestrator
- Flag any case where a sub-agent could trigger the final skill directly

---

For each rule, respond in this format:

RULE [N] — [PASS / WARNING / FAIL]
Finding: [what you found]
Problem: [why it matters]
Fix: [specific change to make]

---

After evaluating all 5 rules, give me:

OVERALL HEALTH: [CLEAN / NEEDS WORK / RESTRUCTURE REQUIRED]

PRIORITY FIXES: (ordered by what to fix first)
1. [most critical fix]
2. [next fix]
3. [etc.]

OPEN QUESTIONS: (things I should clarify about my own system before fixing it)
1. [question]
2. [etc.]

---

## Frontmatter Conventions

All agent files (`agents/*.agent.md`) use this frontmatter shape:

```yaml
---
description: >
  One or more sentences describing the agent's role. Wrap at ~100 chars across
  multiple lines; the folded scalar collapses newlines into spaces.
user-invocable: true|false
---
```

**Rules**:
- `description:` is always a **folded block scalar (`>`)**, not a flow scalar or single-quoted string. The folded form tolerates em-dashes, backticks, parentheses, asterisks, colons, and apostrophes without escaping — YAML collapses internal newlines to spaces and preserves blank lines as paragraph breaks. This matches the convention `skills/writing-skills/SKILL.md` mandates for skills.
- User-invocable agents (`user-invocable: true`) MAY have rich multi-paragraph descriptions with examples and usage notes — their `description:` renders in user-facing dispatcher surfaces (slash-command picker, agent listings). Sub-agents (`user-invocable: false`) keep their description to a single sentence; do not enrich them, since they are dispatched programmatically (never directly by a user), so a rich description has no surface to render against. This holds even for structurally complex sub-agents like `context-specialist` (four modes, multiple invocation paths) — describe the role, not the modes.
- Blank lines inside the folded block create paragraph breaks in the parsed value. Use them sparingly, only when the description has genuinely distinct paragraphs (mode tables, examples lists).

**Anti-rationalizations**:

| Rationalization | Reality | Correct Action |
|----------------|---------|----------------|
| "Single-quoted one-liner is simpler and renders the same" | Folded form is the unified convention with skill frontmatter (`writing-skills`); divergent forms create parser-fragility and audit churn. | Use `description: >` even for one-sentence descriptions. |
| "I should enrich this sub-agent's description for symmetry with manager" | Sub-agents are dispatched programmatically; their description has no user-facing render surface. Enriching adds always-loaded tokens for no benefit. | Keep sub-agent descriptions to one sentence. |
| "context-specialist is complex enough to deserve a rich description" | Complex sub-agents are still sub-agents. Their description renders nowhere user-facing. | Describe the role in one sentence; let the body cover modes and procedures. |
| "The colon mid-value will break YAML — I need to quote it" | The folded scalar tolerates `:` without ambiguity — colons only break unquoted plain scalars at the top level. | Use folded form; no quoting needed. |

---

Here is my agent system:

$ARGUMENTS
