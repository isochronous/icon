# Skill Mechanics

Conventions for how individual skills are registered, declared invisible, and wired as thin routers in front of agent-dispatched implementations.

## `using-skills` Registration

The `using-skills` common-workflows table is **for multi-skill workflows only** — sequences where the agent needs to invoke several skills in combination. Individual skill registration belongs in the skill's own frontmatter `description`, not in `using-skills`.

Before adding to `using-skills`: "Am I describing a workflow that chains two or more skills?" If you're just naming a skill and saying when to use it, that belongs in the skill's frontmatter. Do not duplicate it.

## Invisible Skills

When a skill is too large to inline, or represents one branch of a routing decision, split it into an invisible implementation skill:

```yaml
---
name: my-feature-impl-leaf
description: >
  Implementation detail for my-feature — leaf-node variant.
  NOT for auto-invocation. Only loaded by @my-specialist.
user-invocable: false
---
```

Key properties:
- `user-invocable: false` — excluded from autocomplete and `/skill-name` routing
- Description must include `"NOT for auto-invocation"`
- Named `<parent>-impl-<variant>` or `<parent>-<category>-<variant>`

Parallel paths use `impl` in the name; sequential stages use `phase` (e.g., `task-plan-phase-2`).

## Thin-Router Skill Pattern

When a public-facing skill needs to dispatch an agent rather than execute inline, keep `user-invocable: true` and replace the body with routing logic:

```
If you are @my-specialist:
  Load and execute the my-feature-impl-leaf skill inline.
  Do not dispatch a sub-agent.

If you are any other agent:
  Dispatch @my-specialist via the task tool with:
    agent_type: "ICON:my-specialist"
    prompt: (include all required parameters)
```

**Unreachable branch note**: The `@specialist` branch of the router is typically never reached in normal flows. Add a comment: `<!-- Fallback only — not reached in standard flows -->` to prevent future confusion.

---

See [`../skill-decomposition.md`](../skill-decomposition.md) for the full skill-decomposition index.
