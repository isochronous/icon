---
name: design-first
description: >
  Optional design pass. Consider invoking before significant new features or architectural changes when the approach is ambiguous and a written design would shorten the implementation. Not a hard gate — small or routine structural changes can skip it.
user-invocable: true
---

# Design First

## Overview

**Explore alternatives before committing to an implementation.** Jumping straight to code is the most common source of wasted work. Even "simple" changes benefit from 30 seconds of design thinking — simple projects are where unexamined assumptions cause the most rework.

## When to Use

This is an optional design pass — not a required step. Consider invoking it when a written design would meaningfully shorten implementation or surface tradeoffs, and skip it when the path forward is already clear.

Useful when:

- Building a significant new feature or component
- Making architectural changes (new modules, patterns, integrations)
- Modifying behavior that affects multiple parts of the system
- Multiple valid approaches exist and the tradeoffs are non-obvious
- A user describes WHAT they want but not HOW

## When to Skip

- Bug fixes with an obvious root cause (use `systematic-debugging` instead)
- Purely mechanical changes (renaming, formatting, dependency bumps)
- Tasks where the implementation approach is explicitly specified by the user
- Small or routine structural changes where the design is self-evident

## The Process

### design-first: Step 1: Understand Context

Before proposing anything, understand the landscape:

- Read relevant `.context/` files (domains, architecture, standards)
- Check existing code patterns — what conventions are already established?
- Identify constraints: performance requirements, backward compatibility, existing APIs

**Don't skip this.** Proposing a design without understanding context produces designs that clash with the existing codebase.

### design-first: Step 2: Explore Alternatives

Propose 2-3 approaches with trade-offs. For each approach:

- **What**: Brief description of the approach
- **Pros**: Why this approach is good
- **Cons**: What it costs or risks
- **Fits when**: Under what circumstances this is the best choice

Lead with your recommendation and explain why you favor it.

#### API Design Considerations

When the feature exposes or modifies an API (REST, GraphQL, gRPC, or internal service interface), each alternative must also address:

- **Contract**: What does the request/response shape look like? What are the required vs. optional fields?
- **Backward compatibility**: Will existing clients break? If yes, what's the migration path (versioning, deprecation period, adapter)?
- **Consistency**: Does the endpoint naming, error format, and pagination style match existing APIs in this project?
- **Validation boundary**: Where is input validated — at the API layer, service layer, or both? Define this explicitly.

Don't design APIs in isolation. Check `.context/architecture/` and existing endpoints for established conventions before proposing new patterns.

#### Security Threat Considerations

For features that handle user input, authentication, authorization, data access, or external integrations, briefly assess:

- **What could an attacker abuse?** Think about the trust boundaries the feature crosses (user → server, service → service, internal → external).
- **What data is exposed or stored?** PII, credentials, tokens, or financial data require encryption at rest and in transit, plus access logging.
- **What access controls apply?** Who should be able to use this feature? Is that enforced at the right layer?

This is not a full threat model — it's a 60-second check during design to catch security-relevant decisions before they're buried in implementation. If the assessment surfaces real concerns, flag them for deeper review.

```markdown
## Approaches

### A: Extract middleware (Recommended)
- **What**: Move rate limiting into Express middleware, shared across all routes
- **Pros**: Single implementation, consistent behavior, easy to test
- **Cons**: Less granular control per-route
- **Fits when**: All routes need similar rate limiting

### B: Per-route decorators
- **What**: Apply rate limiting as decorators on individual route handlers
- **Pros**: Fine-grained control, routes opt-in explicitly
- **Cons**: Duplication risk, easy to forget on new routes
- **Fits when**: Different routes need very different limits

### C: API gateway layer
- **What**: Handle rate limiting in the API gateway, not the application
- **Pros**: Application stays simple, infrastructure handles it
- **Cons**: Requires gateway changes, less visibility in app code
- **Fits when**: Gateway is already managing auth/routing
```

### design-first: Step 3: Get Approval

Present the design and your recommendation to the user. **Do NOT start implementing until the approach is approved.**

When you do run a design pass, the approval flow looks like:
- If working autonomously (no user interaction), choose your recommended approach but document WHY in the commit or task artifact
- If the user is available, present options and wait for selection
- If delegated by the manager agent, confirm approach with manager before coding

### design-first: Step 4: Document the Decision

Record the chosen approach and why alternatives were rejected:
- For significant decisions: add to `.context/decisions/`
- For task-level decisions: note in the task plan or commit message
- Scale documentation to significance — a one-line note is fine for small choices

## Scaling to Complexity

Not every task needs a 3-option analysis. Scale the process:

| Task Complexity | Design Effort |
|----------------|---------------|
| Trivial (rename variable, fix typo) | Skip design-first entirely |
| Simple (add field, new endpoint) | 30-second mental check: "Is there another way?" |
| Medium (new feature, refactor module) | 2-3 approaches with brief trade-offs |
| Complex (new system, architecture change) | Full analysis with diagrams, RFC if warranted |

**The key insight:** Even for "simple" tasks, the 30-second pause to consider alternatives prevents the most common source of rework — committing to the first approach without considering whether it's the best one.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Jumping straight to the first idea | Force yourself to name at least one alternative |
| Analysis paralysis on small changes | Scale effort to complexity. 30 seconds, not 30 minutes. |
| Designing in isolation without checking existing patterns | Read `.context/` and existing code first |
| Presenting options without a recommendation | Always lead with your recommendation and reasoning |
| Skipping design "because the user told me what to do" | Users specify WHAT, not always HOW. If HOW is ambiguous, explore options. |

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "This is too simple to need a design" | Simple tasks with bad assumptions cause the most rework. 30 seconds. |
| "I already know the best approach" | Then it'll take 30 seconds to confirm. Do it. |
| "The user will just pick my recommendation anyway" | They might not. And presenting alternatives shows thoroughness. |
| "Designing slows me down" | Rework from wrong assumptions slows you down more. |
| "There's only one way to do this" | There's almost never only one way. Name one alternative. |
