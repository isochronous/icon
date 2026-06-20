# Skill Creation Checklist (TDD-Adapted)

> Companion to `writing-skills/SKILL.md`. Loaded only when authoring or
> revising a skill — not part of the writing-skills entry point.

**Track each phase using your runtime's task-tracking tool.**

**RED — write the failing test:**
- [ ] Create pressure scenarios (3+ combined pressures for discipline skills).
- [ ] Run scenarios WITHOUT the skill — document baseline behaviour verbatim.
- [ ] Identify patterns in rationalisations and failures.

**GREEN — write the minimal skill:**
- [ ] Name uses only letters, numbers, hyphens.
- [ ] YAML frontmatter has `name` and `description` (folded block scalar form), plus `user-invocable` if applicable.
- [ ] Description starts with "Use when…" and includes specific triggers/symptoms.
- [ ] Description is third person and does NOT summarise the workflow.
- [ ] Keywords throughout for search (errors, symptoms, tools).
- [ ] Clear overview with core principle.
- [ ] Step/phase headings prefixed with skill name.
- [ ] Addresses specific baseline failures identified in RED.
- [ ] One excellent example (not multi-language).
- [ ] Re-run scenarios WITH the skill — verify subagent now complies.

**REFACTOR — close loopholes:**
- [ ] Identify NEW rationalisations from testing.
- [ ] Add explicit counters (if discipline skill).
- [ ] Build a rationalisation table from all test iterations.
- [ ] Create a red-flags list.
- [ ] Re-test until bulletproof.

**Quality checks:**
- [ ] Small flowchart only if the decision is non-obvious.
- [ ] Quick reference table where useful.
- [ ] Common-mistakes section.
- [ ] No narrative storytelling.
- [ ] Supporting files only for tools or heavy reference.

**Registration:**
- [ ] Added to the skills table in `README.md`.
- [ ] Documented in the consuming agent's workflow section (manager Workflow Orchestration, product-manager Workflow) if the skill participates in a multi-skill sequence.
