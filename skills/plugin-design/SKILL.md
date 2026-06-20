---
name: plugin-design
description: >
  Use when about to scaffold a new Claude Code plugin, audit a plugin's structure for consistency, or evaluate a plugin against improvement-opportunity heuristics — including natural-language equivalents like "help me start a new plugin", "create a plugin from scratch", "audit my plugin", "review this plugin's design", or "check whether this plugin is well-organized".
user-invocable: true
---

# Plugin Design

## Overview

A two-mode skill for building and reviewing Claude Code plugins. **Create mode** scaffolds a new plugin from an empty directory through boilerplate, metadata, optional git setup, context initialization, and optional marketplace preparation. **Audit mode** evaluates an existing plugin's structural integrity, internal consistency, and forward-looking improvement opportunities.

This skill is plugin-agnostic — it ships with ICON but applies to any Claude Code plugin. It does **not** publish to a marketplace (the marketplace phase prepares artifacts and documents the submission process; the user submits manually). It does **not** duplicate `/icon-init` (the context-init phase delegates to it).

## When to Use

- Starting a new Claude Code plugin from an empty directory.
- Returning to a partially-scaffolded plugin to resume at a later phase.
- Auditing an existing plugin before a release or after a major refactor.
- Reviewing whether a plugin's structure, frontmatter, and cross-file references are consistent.
- Looking for forward-looking improvement opportunities even when no defects are present.

## When NOT to Use

- For a single-agent design review without the full structural sweep → use `agent-evaluation`.
- For context-folder initialization on an existing plugin → use `/icon-init` directly.
- For an ICON-internal audit (references ICON ADRs, finding IDs, carry-forward registry) → use the maintainer-only `icon-audit`.

## Mode Detection

When the user invokes this skill, determine the mode from their language:

| Trigger words | Mode | Companion file to load |
|---------------|------|------------------------|
| "create", "new", "start", "scaffold", "bootstrap", "from scratch" | create | `create-mode.md` |
| "audit", "review", "check", "validate", "evaluate", "assess" | audit | `audit-mode.md` |

If the request is ambiguous (e.g., "help me with my plugin"), ask the user which mode they want before loading either companion file. Do not guess.

## Companion Files

The mode entry loads the relevant phase files in sequence — do not pre-load them.

| File | Loaded by |
|------|-----------|
| `create-mode.md` | Mode detection (create) |
| `create-phase-boilerplate.md` | `create-mode.md` Phase 1 |
| `create-phase-basic-info.md` | `create-mode.md` Phase 2 |
| `create-phase-repo-setup.md` | `create-mode.md` Phase 3 |
| `create-phase-context-init.md` | `create-mode.md` Phase 4 |
| `create-phase-marketplace.md` | `create-mode.md` Phase 5 (only if user opted in) |
| `audit-mode.md` | Mode detection (audit) |
| `audit-phase-structure.md` | `audit-mode.md` Phase 1 |
| `audit-phase-consistency.md` | `audit-mode.md` Phase 2 |
| `audit-phase-improvements.md` | `audit-mode.md` Phase 3 |
