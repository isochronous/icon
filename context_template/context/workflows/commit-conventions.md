# Commit Conventions

Inferred from `git log --oneline -50` and `.claude/claude.md` (or `.github/copilot-instructions.md` on repos still on the legacy path).

## Format

Two patterns are in use depending on context:

### Active task work

```
MKT-NNNN: <description>
```

Use this for any commit made while executing a tracked task (feature, fix, docs, chore — anything under a `MKT-NNNN` task ID).

Examples from the actual log:

```
MKT-0023: use official resource path APIs in find-context-template
MKT-0023: fix PowerShell env var syntax and error-handling premise
MKT-0023: update CHANGELOG unreleased section
MKT-0023: create task folder and plan.md
```

### Non-task / release commits

```
<type>[(<scope>)]: <description>
```

Use this for housekeeping, releases, and any commit not tied to an active task ID.

Examples from the actual log:

```
feat: add ecological-impact and start-worktree skills (1.5.0)
feat(manager): selective sub-agent context isolation (1.4.5)
fix(marketplace): bump plugin version reference to 1.4.1
docs: fix Claude update instructions to refresh marketplace before plugin
refactor: trim redundant task artifact sections
```

**Types in use**: `feat`, `fix`, `chore`, `docs`, `refactor`

**Scopes in use**: `manager`, `marketplace`, `common-constraints` — match the component being changed

## Task ID Generation

This repo uses **agent-generated task IDs** for local tracking (`.context/tasks/` folders, branch names, and commit messages for task work).

### Format

```
MKT-<NNNN>
```

- `MKT` — fixed prefix for this project
- `NNNN` — four-digit zero-padded monotonically incrementing integer, starting at `0001`

Examples:
```
MKT-0001
MKT-0002
MKT-0042
```

### How to Generate

When starting a new task, the manager agent:

1. Lists existing task folders to find the highest ID in use:
   ```bash
   ls .context/tasks/ | grep -oP 'MKT-\K[0-9]+' | sort -n | tail -1
   ```
2. Increments by one (or starts at `1` if none exist), then zero-pads to 4 digits
3. Creates the task folder: `.context/tasks/MKT-<NNNN>-kebab-description/`

### Task Folder Naming

Task folder = task ID + kebab-case description:

```
.context/tasks/MKT-0001-add-post-meeting-skill/
.context/tasks/MKT-0002-fix-version-drift-check/
```

### Branch Naming

Branches use the task ID as the anchor:

```
feature/MKT-0001-add-post-meeting-skill
bugfix/MKT-0002-fix-version-drift-check
```

## Release Commits

Release commits append the version in parentheses at the end of the subject:

```
feat: add ecological-impact and start-worktree skills (1.5.0)
feat: sub-agent isolation, research caching, and tool-agnostic session invocation (1.4.4)
```

This pattern is used by the `/release-plugin` skill to identify the last release point.

## Co-authorship

All AI-assisted commits include the co-author trailer:

```
Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

The co-author trailer is a plain-text, forgeable provenance claim. For verifiable attribution, enable cryptographic commit signing (GPG or SSH); GitHub shows a **Verified** badge on signed commits and can enforce it via the "Require signed commits" branch protection setting where supported. See `branching.md` for protected-branch and signing setup.

## Well-formed Examples

```
MKT-0023: use official resource path APIs in find-context-template
MKT-0023: fix PowerShell env var syntax and error-handling premise
MKT-0023: update CHANGELOG unreleased section
MKT-0023: create task folder and plan.md
feat: add ecological-impact and start-worktree skills (1.5.0)
feat(manager): selective sub-agent context isolation (1.4.5)
fix: make no-/dev/null rule unconditional in common constraints
chore: bump version to 1.2.1; update all agents to claude-sonnet-4.6
docs: add Getting Started and Best Practices guides
```
