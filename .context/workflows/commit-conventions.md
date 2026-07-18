# Commit Conventions

Inferred from this repo's `git log --oneline -50` and the maintainer `release-plugin` skill. Two patterns are in active use; which one applies depends on whether the commit is part of a tracked task or a release.

## Format

### Pattern 1 — Active task work

```
ICON-NNNN: <description>
```

Use for every commit made while executing a tracked ICON task — feature, fix, docs, chore, anything assigned an `ICON-NNNN` task ID via `.context/tasks/`. The description starts with a lowercase imperative verb ("add X", "fix Y", "split Z").

Example:

```
ICON-0001: migrate 6 plugin-authoring .context files from marketplace
```

Pre-split history (this same repo, prior to MKT-0095) used the marketplace `MKT-NNNN` prefix for the same pattern; those commits are grandfathered:

```
MKT-0094: split README skills table into user-invocable and internal sections
MKT-0093: drop Model column from README agent table
MKT-0092: harden prefix validation against non-string inputs and lowercase prefixes
MKT-0091: emit manager role via JSON additionalContext for system-reminder framing
MKT-0090: deprecate task-workflow-template install/upgrade flow
```

**Do not use `MKT-NNNN` for new ICON work** — that prefix points at marketplace tasks. New work uses `ICON-NNNN`.

### Pattern 2 — Non-task / release commits

```
<type>[(<scope>)]: <description> (<version>)
```

Used for release commits driven by `release-plugin` and for housekeeping commits not tied to a task ID.

Examples:

```
chore: split ICON to standalone repo at v1.15.3
chore: tighten local task prefix rule; remove default model pins (1.15.3)
fix: deprecate task-workflow-template install and harden manager-role injection (1.15.2)
fix(agent-evaluation): remove non-distributed .context/ file reference (1.15.1)
feat: root-level claude.md redirect for Copilot CLI (1.15.0)
```

**Types in use**: `feat`, `fix`, `chore`, `docs`, `refactor`.

**Scopes in use**: `manager`, `agent-evaluation`, `upgrade-repo`, `marketplace` — match the component changed. Optional; omit for cross-cutting changes.

**Trailing `(X.Y.Z)`**: every release commit appends the new plugin version in parentheses at the end of the subject. `release-plugin` Step 2 uses this exact pattern to find the previous release boundary:

```bash
git --no-pager log --oneline | grep -P '\(\d+\.\d+\.\d+\)' | head -1
```

Breaking this convention breaks the release skill's diff range. Do not append the version to non-release commits, and do not omit it from a release commit.

## Task ID Generation

ICON uses **agent-generated task IDs** for local tracking. Configured in `.context/iconrc.json`:

```json
{
  "local_task_id_prefix": "ICON",
  "default_branch": "main"
}
```

### Format

```
ICON-<NNNN>
```

- `ICON` — fixed prefix for this project (per `iconrc.json`).
- `NNNN` — at least three digits, zero-padded, monotonically incrementing. This repo started at `ICON-0001` and uses four-digit width to match the marketplace `MKT-NNNN` convention.

### How to Generate

When starting a new task, the `@manager` agent:

1. Lists existing task folders to find the highest ID in use:
   ```bash
   ls .context/tasks/ | grep -oP 'ICON-\K[0-9]+' | sort -n | tail -1
   ```
2. Increments by one (or starts at `0001` if none exist), zero-padded to four digits.
3. Creates the task folder: `.context/tasks/ICON-<NNNN>-kebab-description/`.

### Task Folder Naming

Task folder = task ID + kebab-case description:

```
.context/tasks/ICON-0001-migrate-context-from-mkt-0095/
```

### Branch Naming

Branches use the task ID as the anchor (see `.context/workflows/branching.md`):

```
feature/ICON-0001-migrate-context-from-mkt-0095
```

## Release-Commit Convention (detail)

Release commits append `(X.Y.Z)` and are produced by the maintainer-only `release-plugin` skill at `.claude/skills/release-plugin/`. They include the `Co-authored-by` trailer when AI-assisted (below).

Two release-commit shapes are common:

```
feat: <one-line summary of new content> (X.Y.Z)
fix(<scope>): <one-line bug summary> (X.Y.Z)
```

`chore:` is the default when the release is a tightening, doc fix, or housekeeping pass that fits neither `feat:` nor `fix:`.

## Co-authorship trailer

AI-assisted commits include the co-author trailer at the bottom of the commit body:

```
Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

The `release-plugin` skill's Step 7 includes this trailer by default. Manual AI-assisted commits should match.

## Commit Signing

The `Co-authored-by` trailer and the `ICON-NNNN:` prefix are provenance *claims* written into the commit text — forgeable. Cryptographic commit signing (GPG or SSH) is verifiable *proof* GitHub checks and surfaces as a **Verified** badge. Sign commits wherever signing is configured. For one-time setup (SSH and GPG options) and server-side enforcement, see the **Commit Signing** section of `.context/workflows/branching.md`.

## Well-formed Examples

```
ICON-0001: migrate 6 plugin-authoring .context files from marketplace
ICON-0001: populate .context/ scaffold via context-specialist mode=upgrade
chore: split ICON to standalone repo at v1.15.3
chore: tighten local task prefix rule; remove default model pins (1.15.3)
fix: deprecate task-workflow-template install and harden manager-role injection (1.15.2)
fix(agent-evaluation): remove non-distributed .context/ file reference (1.15.1)
feat: root-level claude.md redirect for Copilot CLI (1.15.0)
feat(manager): selective sub-agent context isolation (1.4.5)   ← pre-split history
```

## Anti-patterns observed in pre-split history (do not repeat)

- **Period at end of subject**: `ICON-0001: migrate files.` — drop the period.
- **`feat:` without a version on a non-release commit**: signals a release that never happened, confusing `release-plugin` Step 2.
- **`ICON-NNNN: ICON-NNNN: ...` (double prefix)**: copy-paste error; the task ID appears exactly once.
- **Bare `WIP` or `fix typo` commits on `main`**: every commit on `main` should be releasable; squash before merge if needed.
