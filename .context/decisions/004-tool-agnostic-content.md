# ADR-004: Tool-agnostic content; no runtime-specific code

**Date**: (originating principle predates the split; recorded here for the ICON repo)
**Status**: Accepted

## Context

ICON ships to two runtimes: Claude Code and Copilot CLI. Each runtime exposes slightly different APIs (Claude Code has `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_SKILL_DIR}`; Copilot CLI has neither). A naive port would special-case one runtime in skill content, breaking the other.

## Decision

Skills, agents, and commands are written as **portable markdown**. Where a path or variable differs between runtimes, both forms are documented (see `domains/plugin-resource-paths.md`). Skills must not embed runtime-only assumptions.

## Consequences

**Positive:**
- A skill works in both runtimes without forking.
- Bug fixes apply to both runtimes simultaneously.
- The portability rule in `shared/common-constraints.md` ("Do not produce output that depends on capabilities specific to one AI tool") is structurally enforceable. (Originally lived in a `common-constraints` skill; the rule survived the move to an inlined shared block — see `domains/skill-system.md` for the current mechanism.)
- Byte-equality of the inlined common-constraints block across all agent files is now automated via `.githooks/pre-commit` (added in ICON-0011). The hook's first run revealed real whitespace drift on all 9 agents — confirming that author discipline alone is insufficient to maintain the invariant the inlined-block design depends on. The structural choice is now mechanically enforced, not aspirational.

**Negative:**
- Some Claude-Code-only ergonomics (e.g., inline `${CLAUDE_SKILL_DIR}` substitution) cannot be relied on; skills must construct paths from `COPILOT_HOME` as a fallback.

## Alternatives Considered

1. **Two parallel skill trees, one per runtime**: rejected — duplicated content immediately drifts.
2. **Generate runtime-specific copies from a single source**: rejected — adds a build step to a repo whose explicit constraint is "no build step" (see ADR-005).
