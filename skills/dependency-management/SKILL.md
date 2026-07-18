---
name: dependency-management
description: >
  Use when upgrading a library or framework version, evaluating whether to adopt a new dependency, resolving version conflicts, or handling breaking changes from upstream packages.
user-invocable: true
---

# Dependency Management

## Overview

**Understand the blast radius before changing a dependency.** Upgrading a library is not a code change — it's a contract change affecting every consumer of that library across the project. Agents routinely suggest outdated APIs after upgrades or miss transitive breakage.

## When to Use

- Upgrading a library or framework to a new major/minor version
- Evaluating whether to adopt a new dependency
- Resolving version conflicts or peer dependency warnings
- Responding to a CVE or security advisory in a dependency
- Migrating from one library to another (e.g., Moment.js → date-fns)

## When NOT to Use

- Patch-version bumps with no breaking changes (just update and run tests)
- Internal module refactoring that doesn't touch external packages

## The Process

### dependency-management: Step 1: Research Before Changing

Before touching `package.json`, `pom.xml`, `*.csproj`, or any manifest:

1. **Read the changelog/migration guide** for the target version. Use `@researcher` if it's long or the library is unfamiliar.
2. **Identify breaking changes** — renamed APIs, removed features, changed defaults, new required config.
3. **Check transitive impact** — does the upgrade force upgrades in other packages? Run the package manager's dry-run or resolution check first.
4. **Check project usage** — search the codebase for every import/usage. Know what you're about to break.

```
# Examples of pre-upgrade discovery
grep -r "from 'react-router'" src/          # Find all usages
npm ls react-router                          # Check dependency tree
npm outdated                                 # See what's behind
```

### dependency-management: Step 2: Plan the Migration

For major version upgrades or library swaps:

- List every API change that affects this project (not the full changelog — just what matters here)
- Order changes by dependency: types/interfaces first, then implementations, then tests
- Determine whether the migration can be incremental or requires a big-bang change
- If incremental, define the coexistence strategy (adapter pattern, feature flags, parallel imports)

### dependency-management: Step 3: Execute and Verify

1. **Update the dependency** in the manifest
2. **Run the build** — fix compilation/type errors first
3. **Run the full test suite** — not just the files you changed
4. **Search for runtime-only breakage** — some changes (renamed config keys, changed defaults) won't cause build errors but fail at runtime. Check integration tests or run the app.

### dependency-management: Step 4: Document What Changed

If the upgrade introduced non-obvious changes (new defaults, removed features, required config):
- Note in the commit message body which migration steps were applied
- Update `.context/` if the upgrade changes established patterns (e.g., new routing API, new state management)

## Evaluating New Dependencies

When considering adopting a new library:

| Question | Why It Matters |
|----------|---------------|
| Does something in the project already solve this? | Avoid redundant dependencies |
| How maintained is it? (last release, open issues, bus factor) | Unmaintained deps become liabilities |
| What's the bundle/binary size impact? | Matters for frontend and serverless |
| What's the transitive dependency count? | Deep trees increase conflict and CVE surface |
| Is there a simpler alternative or can you write it yourself? | 10 lines of code > 1 dependency for simple utilities |

**Default bias: fewer dependencies.** Every dependency is a future maintenance obligation.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Upgrading without reading the migration guide | Always read the changelog for the version range you're crossing |
| Fixing build errors without checking runtime behavior | Run the app or integration tests, not just unit tests |
| Upgrading multiple unrelated dependencies at once | One dependency per commit. Isolate blast radius. |
| Assuming the old API still works | Search the codebase for every usage. Verify each one. |
| Ignoring peer dependency warnings | Warnings become runtime errors. Resolve them. |

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "It's just a minor version bump" | Minor versions can deprecate APIs and change defaults. Check the changelog. |
| "The tests pass so it's fine" | Tests don't cover every runtime path. Check for behavioral changes. |
| "I'll update the other packages later" | Partial upgrades create version skew. Plan the full dependency graph. |
| "The library handles backward compatibility" | Some do, many don't. Verify, don't assume. |
| "I don't need to read the migration guide, I know this library" | Migration guides exist because upgrades are non-obvious. Read it. |

## Red Flags — STOP and Re-Plan

If you catch yourself doing any of these, the upgrade is not ready:

- About to bump a major version while existing tests are red.
- About to upgrade multiple unrelated dependencies in a single commit.
- About to skip the changelog because the bump "looks small".
- Treating a green build as proof the library's behavior didn't change.
- About to ignore peer-dependency warnings ("they'll resolve themselves").

**All of these mean: re-plan as a single-dependency commit with the changelog read and runtime behavior verified.**
