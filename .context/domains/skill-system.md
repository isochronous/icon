# Skill System Domain

## What Skills Are

A skill is a named, reusable process instruction. When invoked, the tool reads `skills/<name>/SKILL.md` and the active agent follows its instructions. Skills encode proven workflows that would otherwise be improvised inconsistently — they are the plugin's mechanism for making good process repeatable.

Skills are named directories: `skills/<name>/SKILL.md`. The directory allows co-located support files (examples, templates, sub-scripts) without polluting the `skills/` root.

## Skill Invocation Lifecycle

```
User types /commit-discipline  (or agent invokes via skill tool)
      ↓
Tool reads skills/commit-discipline/SKILL.md
      ↓
SKILL.md content is injected into the agent's context
      ↓
Agent follows the skill instructions
```

**Critical:** The tool maps `/skill-name` to the **directory name**, not the `name:` field in frontmatter. If the directory name and frontmatter `name:` diverge, invocation will fail silently.

## Skill Types

The canonical skill registry is `ls skills/` for shipped skills and `ls .claude/skills/` for maintainer-only skills. The tables below give representative examples per category — they are not exhaustive and may lag the directory listing.

### Rigid Discipline Skills
Process gates that enforce non-negotiable behavior. They have specific phases, checklists, or required outputs.

Examples: `commit-discipline`, `pr-discipline`, `testing-discipline`, `verification-checklist`, `systematic-debugging`, `code-quality-rules`.

### Flexible Process Skills
Guidance for open-ended work where judgment is required. Less prescriptive than discipline skills.

Examples: `design-first`, `context-maintenance`, `dependency-management`, `agent-evaluation`, `migration-planning`, `post-incident-review`, `writing-skills`.

### Mandatory Enforcement: `using-skills` Skill + Common Constraints Block

Every agent definition runs with two non-optional pieces of always-loaded text:

| Mechanism | What it is | How it loads |
|-----------|-----------|--------------|
| `using-skills` | A real skill — forces agents to check for applicable skills before starting work | Agents only (`user-invocable: false`); invoked by each dispatcher at session start |
| Common-constraints block | A shared text block (`shared/common-constraints.md`) defining core rules for all agents: communication, codebase respect, verification, self-review, anti-rationalization, scope discipline, task artifacts | **Not a skill.** The content is inlined verbatim into each `agents/*.agent.md` file between `<!-- BEGIN: common-constraints -->` and `<!-- END: common-constraints -->` sync markers, so it is always-loaded with the agent definition — no invocation step. Authoritative source is `shared/common-constraints.md`; agent copies must remain byte-equal to it. |

**Enforcement chain**: The injected common-constraints block instructs every agent to follow the listed rules from the first token of the session — including the rule that drives skill awareness. The `using-skills` skill, invoked by each dispatcher at session start (and reachable from the constraints' "skill awareness" expectation), then mandates that applicable skills are invoked before any other action. The result is a self-reinforcing loop that cannot be bypassed by an agent choosing to skip either layer.

**Sync mechanism**: A pre-commit hook at `.githooks/pre-commit` enforces byte-equality of the inlined block across all nine agents. The hook reads `shared/common-constraints.md` as the authoritative source and, for each `agents/*.agent.md`, rewrites the content between the `<!-- BEGIN: common-constraints -->` and `<!-- END: common-constraints -->` markers to match. Marker detection is fenced-code-block aware (CommonMark §4.5), so agent files may safely illustrate the BEGIN/END marker strings inside backtick or tilde fenced code blocks — those examples are treated as literal text, not as sync markers. Any rewritten file is re-staged so the in-flight commit includes the synced content. The hook aborts the commit on structural errors (missing source file, or an orphaned marker — one of the BEGIN/END pair without the other). Agent files that carry no markers are skipped. The hook is wired via `git config core.hooksPath .githooks`, the same mechanism used by the `post-commit` cache-pruning hook.

**Authoring rule — scope before delegation**: Before delegating any edit that adds a new behavioral rule, decide whether the rule applies to one agent or all agents. If all agents, the rule belongs in `shared/common-constraints.md` (propagated by the hook above) — not in a single agent's body. Adding a universal discipline to one agent's file and later relocating it requires a kill-and-redispatch; deciding scope first makes the delegation correct on the first dispatch.

### Output / Formatting Skills
Transform content into structured formats.

Examples: `github-issue`, `rfc`, `post-meeting`.

### Setup / Maintenance Skills
One-time or periodic operations on consumer repos. Includes the initialization family (`initialize-repo`, `initialize-monorepo`, `initialize-multimodule`, `initialize-workspace`), the umbrella `icon-init` dispatcher, `upgrade-repo`, `create-iconrc`, the runtime helpers `find-context-template` and `resolve-repo-context`, `icon-status`, and `start-worktree`.

### Task-Plan Family
The `task-plan` skill and its phase skills (`task-plan-phase-investigation`, `-architecture`, `-implementation`, `-testing`, `-completion`) plus `task-retrospective` structure how the manager drives a single task end-to-end.

### Context-Specialist Internals
`@context-specialist` is backed by a set of internal skills (`context-specialist-create`, `context-specialist-detect-tree-position`, `context-specialist-impl-leaf`, `-branch`, `-root`, `context-document-guidelines`). These are not directly invocable.

### Manager Internals
Internal manager-only skills: `manager-routing-guide`, `invoke-sub-project-skill`, `merge-phase-templates`.

### Plugin-Authoring / Maintainer Skills
Skills used to evolve this plugin itself: `icon-audit` (audits ICON's agent definitions and infrastructure — maintainer-only, see below), `writing-skills` (skill authoring discipline).

### Maintainer-Only Skills (Not Shipped)
Live in `.claude/skills/` rather than the shipped `skills/` tree and are not distributed to end users.

| Skill | Purpose |
|-------|---------|
| `release-plugin` | Bumps `.claude-plugin/plugin.json`, renames the `CHANGELOG.md` `[Unreleased]` section, commits on `main`, tags `vX.Y.Z`, and force-moves `latest` |
| `icon-audit` | 6-domain parallel audit of the ICON plugin itself — dispatches per-domain sub-agents in parallel, then synthesizes findings + improvement opportunities into a tiered report. References ICON ADRs and finding IDs; ICON-specific by design. |
| `changelog-entry` | Adds or merges a `[Unreleased]` entry into `CHANGELOG.md` at task close, applying the cumulative-effect rule per `.context/standards/changelog-discipline.md`. |

## When to Create a New Skill

Create a skill when:
- A multi-step process has been improvised more than once and the steps should be standardized
- A recurring mistake could be prevented by a checklist or explicit phase gate
- A complex output format needs consistent structure across uses
- A process is specific enough that an agent would produce worse results without explicit guidance

Do not create a skill when:
- The guidance is already general enough to live in an agent definition
- The process is so simple it needs no more than a sentence
- The skill would mostly duplicate another skill

**When creating or editing a skill, invoke the `writing-skills` skill first.** It covers structure, discoverability, quality standards, and the discipline-hardening patterns that separate effective skills from vague ones.

**When the task is "edit skill X", invoke `using-skills` AND the target skill itself BEFORE the first `Read` or `Edit` on its `SKILL.md`.** The discipline of the skill being edited governs the edit — not only the discipline of skills being consumed for unrelated work. This applies even to edits that feel "small" or "obvious" (adding a section, fixing a reference): a skill's own iron law (e.g. `writing-skills`' "edit skill without testing? same violation") fires on the edit regardless of size. Re-invoke the target skill even if you have read it recently — its specifics may have evolved, and re-reading is cheap. The rationalization to watch for is "this addition is too small for the workflow"; that thought is the trigger to stop and invoke `using-skills`.

## Skill Authoring Principles

- **Earn your place**: Every instruction in a skill must prevent a real mistake. If removing a sentence wouldn't change behavior, remove it.
- **Concrete over abstract**: "Check X before Y" beats "Be thorough."
- **Phases for rigid skills**: Rigid discipline skills should have explicit numbered phases so agents cannot skip steps.
- **`user-invocable: false`** for skills that should only run in response to an agent's decision, not direct user invocation.
- **Frontmatter invocability semantics** — `user-invocable: false` and `disable-model-invocation: true` are independent gates with different targets:
  - `user-invocable: false` — hides the skill from the user slash-command menu; has no effect on whether an agent or dispatcher can invoke it.
  - `disable-model-invocation: true` — blocks invocation by any model or agent; the skill cannot be dispatched programmatically.
  - Setting **both** makes a skill invocable by no one. A skill meant to be dispatched by an agent (e.g. the `initialize-monorepo`/`-multimodule`/`-workspace` skills invoked by `/icon-init`) must keep `disable-model-invocation` absent or `false` — otherwise the dispatch silently fails with no error surfaced to the caller.

## Dispatcher Prompt Variable Convention

`<SCREAMING_SNAKE_CASE>` slots in a dispatcher prompt are **unfilled placeholders** — values the orchestrator substitutes before dispatching the agent. They are never present in the prompt that the dispatched skill actually reads.

Once inside the dispatched skill, refer to a received value in prose ("the `repo_type` value supplied by the dispatcher prompt") rather than repeating the bracketed slot marker. If a bracket IS used inside the dispatched skill, it signals a resolved value — not a new slot to fill. The semantic distinction is easy to miss when reading a step cold.

**Concrete example**: In `initialize-monorepo/SKILL.md:289`, the dispatcher prompt contains `repo_type: monorepo` — a literal value being passed to the dispatched agent. Inside `context-specialist-impl-root/SKILL.md:236`, the invocation reads `repo_type: <repo_type>` — the lowercase form is the variable as received by that skill, not an unfilled orchestrator slot. A future writer seeing `<repo_type>` inside `impl-root` must not treat it as something the orchestrator needs to fill in; it is already filled by the time that step runs.
