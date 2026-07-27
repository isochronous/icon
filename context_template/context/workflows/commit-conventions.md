# Commit Conventions

Inferred from `git log --oneline -50` and this repo's agent instructions file (`.claude/claude.md` or `.github/copilot-instructions.md`, depending on the harness in use).

## Format

Two patterns are in use depending on context:

### Active task work

```
TICKET-NNNN: <description>
```

Use this for any commit made while executing a tracked task (feature, fix, docs, chore — anything under a `TICKET-NNNN` task ID).

Examples (replace with 3-5 real subjects from this repo's log):

```
TICKET-0023: add refresh-token endpoint
TICKET-0023: fix token expiry calculation
TICKET-0023: update CHANGELOG unreleased section
TICKET-0023: create task folder and plan.md
```

### Non-task / release commits

```
<type>[(<scope>)]: <description>
```

Use this for housekeeping, releases, and any commit not tied to an active task ID.

Examples (replace with 3-5 real subjects from this repo's log):

```
feat: add refresh-token rotation to the auth service (1.5.0)
feat(auth): enforce multi-factor enrollment for admin accounts (1.4.5)
fix(billing): correct proration on mid-cycle plan changes
docs: document the local development setup
refactor: extract shared request-validation helpers
```

**Types in use**: `feat`, `fix`, `chore`, `docs`, `refactor`

**Scopes**: optional, and specific to this repo — use the name of the component being changed (a module, package, or service directory). Record the set actually in use here as it settles, so contributors reuse established scopes instead of inventing a new one per commit.

## Task ID Generation

This repo uses **agent-generated task IDs** for local tracking (`.context/tasks/` folders, branch names, and commit messages for task work).

### Format

```
TICKET-<NNNN>
```

- `TICKET` — placeholder for this project's task ID prefix. The real value is the `local_task_id_prefix` field in `.context/iconrc.json` (e.g. `PROJ`, `ACME`); substitute it wherever `TICKET` appears throughout this file.
- `NNNN` — four-digit zero-padded monotonically incrementing integer, starting at `0001`

Examples:
```
TICKET-0001
TICKET-0002
TICKET-0042
```

### How to Generate

When starting a new task, the manager agent:

1. Lists existing task folders to find the highest ID in use:
   ```bash
   MAX=$(ls .context/tasks/ | sed -n 's/^TICKET-\([0-9][0-9]*\).*/\1/p' | sort -n | tail -n 1)
   ```
2. Increments by one, forcing base-10 interpretation so a zero-padded value (e.g. `0042`) isn't parsed as octal, then zero-pads the result back to 4 digits (or starts at `0001` if none exist):
   ```bash
   NEXT=$(printf '%04d' $((10#${MAX:-0} + 1)))
   ```
3. Creates the task folder: `.context/tasks/TICKET-<NNNN>-kebab-description/`

### Task Folder Naming

Task folder = task ID + kebab-case description:

```
.context/tasks/TICKET-0001-add-user-authentication/
.context/tasks/TICKET-0002-fix-login-timeout/
```

### Branch Naming

Branches use the task ID as the anchor:

```
feature/TICKET-0001-add-user-authentication
bugfix/TICKET-0002-fix-login-timeout
```

## Release Commits

Release commits append the version in parentheses at the end of the subject:

```
feat: add refresh-token rotation to the auth service (1.5.0)
feat: add multi-region failover for the session store (1.4.4)
```

This lets release tooling find the last release point by scanning the log for the most recent version-suffixed subject.

## Co-authorship

All AI-assisted commits include a co-author trailer:

```
Co-authored-by: Assistant Name <assistant@users.noreply.github.com>
```

This is a placeholder: `Assistant Name` and the email are supplied by whichever AI assistant made the commit — each tool has its own registered name and no-reply address, and git requires the `Name <email>` shape (no angle brackets around the name) to recognize the trailer. Record this repo's actual trailer here once it's known, and keep it consistent so the log stays greppable.

The co-author trailer is a plain-text, forgeable provenance claim. For verifiable attribution, enable cryptographic commit signing (GPG or SSH); GitHub shows a **Verified** badge on signed commits and can enforce it via the "Require signed commits" branch protection setting where supported. See `branching.md` for protected-branch and signing setup.

## Well-formed Examples

```
TICKET-0023: add refresh-token endpoint
TICKET-0023: fix token expiry calculation
TICKET-0023: update CHANGELOG unreleased section
TICKET-0023: create task folder and plan.md
feat: add refresh-token rotation to the auth service (1.5.0)
feat(auth): enforce multi-factor enrollment for admin accounts (1.4.5)
fix: reject expired sessions on the token refresh path
chore: bump dependencies to their latest patch releases
docs: add Getting Started and Best Practices guides
```
