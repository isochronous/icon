<!-- template-version: 1.1 -->
# Investigation Phase Templates

> Loaded by the `task-plan-phase-investigation` skill when present.
> These templates supersede the skill's built-in defaults for this repo.

## Additional Context Files

> Files agents should read during investigation of an ICON task, in addition
> to the standard checklist in the phase skill. ICON has no `architecture/`
> or `testing/` directories — domain and standards files carry that role.

- `.context/domains/skill-system.md` — when the task touches any skill, agent, or the invocation chain
- `.context/domains/mcp-servers.md` — when the task touches `.mcp.json`, credential handling, or MCP-related skills
- `.context/domains/plugin-resource-paths.md` — when the task touches `installed-plugins/` paths, manifest references, or runtime resource resolution
- `.context/standards/skill-decomposition.md` — when adding or restructuring a skill (thin-router rules, distribution layout)
- `.context/standards/changelog-discipline.md` — when writing CHANGELOG.md entries or planning a release
- `.context/decisions/` — always; ICON's seven ADRs constrain repo split, branching, versioning, MCP credential placeholders, build-step policy, and `2>/dev/null` ban scope (see `decisions/README.md` for the index)
- `.context/iconrc.json` — when scope, excluded directories, or task-pruning behavior is in question

## @researcher Delegation Template

```
Topic: [specific library, tool, or convention to research]
Current version: [X.Y.Z] → Target version: [A.B.C]   (omit if not version-related)
Ticket: ICON-NNNN
Questions:
  - [Question 1]
  - [Question 2]
Decision this research will inform: [what choice depends on the findings]
Constraints:
  - ICON is a pure-content plugin (no compile/test/package manager) — recommendations must not assume a build step.
  - [other relevant constraint from .context/decisions/]
```

## @planner Delegation Template

```
Task: ICON-NNNN — [brief title]
Objective: [what we're accomplishing and why]
Affected areas: [skills/, agents/, commands/, hooks/, context_template/, shared/, .claude-plugin/, .mcp.json, .context/, etc.]
Complexity: Simple / Medium / Complex
Context:
  - [key constraint from .context/decisions/ — name the ADR]
  - [relevant rule from .context/standards/skill-decomposition.md or other standards file]
  - [relevant domain fact from .context/domains/*.md]
Research findings: [summary or "N/A"]
Open questions for planner:
  - [anything still ambiguous after investigation]
```
