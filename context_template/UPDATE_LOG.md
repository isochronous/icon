# Context Template - Update Log

## 2026-02-17 — System Polish (v2.0)

Major overhaul of all agent definitions and context template files. Changes informed by research into Anthropic Claude Code best practices, multi-agent orchestration patterns, and context engineering principles.

### Agent Definitions (all 7 rewritten)

**Total: 2,201 → 534 lines (76% reduction)**

| Agent | Before | After | Reduction |
|-------|--------|-------|-----------|
| manager.agent.md | 410 | 125 | 70% |
| researcher.agent.md | 506 | 98 | 81% |
| coder.agent.md | 242 | 48 | 80% |
| tester.agent.md | 387 | 45 | 88% |
| reviewer.agent.md | 206 | 75 | 64% |
| planner.agent.md | 200 | 60 | 70% |
| architect.agent.md | 251 | 83 | 67% |

Key changes:
- **Restructured to Anthropic-aligned format**: Role → Workflow → Context Needs → Output → Constraints
- **Centralized context discovery in manager**: Removed ~40 identical lines from each specialist agent. Manager owns discovery and passes context in delegation prompts.
- **Removed language-specific examples from all agents**: Models already know language idioms. These wasted tokens without adding project-specific value.
- **Simplified manager preflight**: 4-signal cascade (session state → git branch → modification time → prompt) reduced to 2-step (session state → ask user).
- **Removed "read own agent definition" pattern**: The system already injects the agent definition.
- **Applied "earn your place" principle**: Every line must prevent a concrete mistake or it gets cut.

### Retrospective System (new)

Added a lightweight learning mechanism:
- **retrospectives.md**: New template — rolling log of last 10 lessons learned (cap enforced by `append-retrospective-entry`'s `ENTRY_CAP`)
- **Phase 8 in task workflow**: Mandatory retrospective at task completion (3 questions)
- **Promotion pattern**: Lessons promoted from rolling log to appropriate `.context/` subdirectory (standards/, testing/, architecture/, etc.)

### Context Template Files

| File | Before | After | Change |
|------|--------|-------|--------|
| META.md | 790 | 89 | 89% reduction |
| task-workflow-template.md | 916 | 148 | 84% reduction |
| SETUP_PROMPT.md | 220 | 80 | 64% reduction |
| context_template/README.md | 93 | 49 | 47% reduction |
| retrospectives.md | — | 19 | New file |

Key changes:
- **META.md**: Removed verbose good/bad examples, duplicate context recovery protocol, detailed maintenance schedules. Added retrospective mechanism reference.
- **task-workflow-template.md**: Collapsed verbose delegation patterns, removed decision log templates, removed progress tracking template. Added Phase 8 retrospective.
- **SETUP_PROMPT.md**: Simplified to essential steps, added retrospectives.md to generated structure.
- **Clarified tasks/ vs workflows/**: Tasks are ephemeral (per-task plans, prunable). Workflows are persistent (CI/CD, branching, deployment).

### Top-Level README

Rewritten to reflect the updated system: agent table with models, design principles, installation instructions, directory structure, workflow diagram.

### Research Sources

- Anthropic Claude Code best practices (code.claude.com/docs/en/best-practices)
- Anthropic effective agent harnesses (anthropic.com/engineering)
- Claude Code subagent documentation
- GitHub agents.md lessons from 2,500+ repositories
- Multi-agent orchestration patterns (AutoGen, LangChain, Azure AI)

### Design Decisions

- **Copilot Memories not adopted**: No IntelliJ support, no cross-vendor standard, preview status, 28-day expiration, cloud-only. File-based `.context/` is the correct architecture for toolset-agnostic needs.
- **Agents.md "6 core areas" structure not adopted**: Anthropic's simpler pattern (Role → Workflow → Constraints) is more effective and aligned with the models we use.
- **Language-specific examples removed**: Confirmed through Anthropic docs that models already know these. Only project-specific patterns (from `.context/`) add value.

---

## 2026-02-10 (Part 2) — Researcher Agent

Added researcher agent for bridging training data gaps with current library documentation. Updated manager and task-workflow-template with research phase.

## 2026-02-10 (Part 1) — Initial Template

Created context_template from patterns established in the ngDAS project. Included workflow templates, architecture templates, styling guide, META documentation, and domain templates.

---

*Template Version: 2.0.0*
