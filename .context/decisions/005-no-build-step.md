# ADR-005: No build step, no test runner, no package manager

**Date**: (originating principle; recorded here post-split)
**Status**: Accepted

## Context

ICON is pure content (markdown + JSON + two shell hooks). Adding a build step (e.g., a markdown linter pipeline, an agent-spec validator framework) would impose CI infrastructure on every contributor and every CI environment.

## Decision

Validation is "the JSON parses" plus structural review during PR. There is no `package.json`, no `Cargo.toml`, no `Makefile`, no build artifacts. The plugin's hook wiring (`hooks/hooks.json`) and its single cross-platform Node.js wrapper (`hooks/inject-manager-role.mjs`) are committed as source and run in-place — see `.context/domains/hooks.md` for the cross-platform rationale (ICON-0012 consolidated the prior `.sh` + `.ps1` pair into a single `.mjs`).

## Consequences

**Positive:**
- Zero dependency surface; `git clone` is the entire toolchain.
- Any contributor with a text editor can author or review changes.
- No CI flakiness — the only runtime check is `python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))"`.

**Negative:**
- No automated lint for markdown malformations (e.g., the YAML frontmatter `colon-space` parse failure that MKT-0078 caught manually).
- No regression test suite for agent behaviour — relies on `plugin-audit` skill and retrospective discipline.

## Alternatives Considered

1. **Add a markdown linter (e.g., `markdownlint`)**: deferred — the value would have to outweigh the contributor friction; no recurring class of bug yet justifies the investment.
2. **Build a Node-based agent-spec validator**: rejected — would introduce a Node toolchain that contradicts ADR-004's tool-agnostic stance.
