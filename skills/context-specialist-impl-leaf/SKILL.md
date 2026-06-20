---
name: context-specialist-impl-leaf
description: >
  Internal @context-specialist skill. Do not invoke without explicit direction.
user-invocable: false
---

# Initialize Leaf Project

Set up a `.context/` folder and git hook infrastructure for this repository. **This
runs once per repository.** Take the time to do it thoroughly — the richer the
context, the fewer mistakes agents make on every future task.

---

## Pre-requisite: `claude.md`

Before starting, ensure a `claude.md` exists in the project's `.claude/`
folder. It provides the big-picture view (project overview, tech stack, key
commands, high-level conventions) that the agent system uses on every turn.
Claude Code loads from `.claude/claude.md` automatically. Copilot CLI requires a
root-level `claude.md` redirect (created below) to reach the same file.

- **Claude Code**: run `/init` from the project root — this typically creates
  `.claude/claude.md`. Confirm `ls .claude/claude.md` succeeds before continuing.
- **Copilot CLI**: run `/init`, then move the generated file:
  `mkdir -p .claude && git mv .github/copilot-instructions.md .claude/claude.md`.
- **VS Code**: `Ctrl-Shift-P` → "Chat: Generate Workspace Instructions File",
  then move as above.

> **Monorepo note**: Tools create their instructions file relative to the folder
> they treat as the project root. If this project is a subfolder within a larger
> repository (e.g., `<repo>/services/my-app/`), run `/init` from inside that
> project folder so the file lands at `<project-root>/.claude/claude.md` —
> not at the repository root's `.claude/`. Agents will look for `claude.md` in
> the **project directory**, not the git repo root.

> **Legacy path**: The legacy location `.github/copilot-instructions.md` is
> still recognized by Copilot CLI. If this repository already has a file there,
> run `upgrade-repo` to migrate it to `.claude/claude.md` before proceeding
> with initialization.

**Root-level redirect** — Copilot CLI loads instructions from a root-level
`claude.md` when one exists, but does **not** automatically read `.claude/claude.md`.
Create a root-level redirect so Copilot CLI users receive project instructions:

```bash
if [ ! -f "claude.md" ]; then
  cat > claude.md << 'EOF'
# Project Instructions

This file is a redirect. The canonical project instructions live in `.claude/claude.md`.

Read `.claude/claude.md` for the full project overview, tech stack, key commands,
and conventions.
EOF
fi
```

Skip silently if `claude.md` already exists.

**Separation of concerns** — keep this file high-level. `.context/` holds the
deep, area-specific knowledge. Do not duplicate content between them.

---

## context-specialist-impl-leaf: Step 1: Detect Project Characteristics

Analyze the project before creating any files:

- **Language(s) and versions** — read `package.json`, `pom.xml`, `*.csproj`,
  `go.mod`, `Cargo.toml`, `requirements.txt`, `pyproject.toml`, etc.
- **Frameworks** — Spring Boot, Next.js, Django, Rails, etc.
- **Build tool and package manager** — Maven, Gradle, npm, pnpm, cargo, etc.
- **Testing frameworks** — JUnit + Mockito, Jest + React Testing Library,
  pytest, RSpec, etc.
- **Database and ORM** — PostgreSQL/MySQL + Hibernate/JDBC/Prisma/etc.
- **API style** — REST, GraphQL, gRPC, tRPC, etc.
- **Deployment target** — Docker/Kubernetes, serverless, EAR/WAR, etc.
- **Module structure** — mono-repo, multi-module Maven/Gradle, workspaces,
  microservices, etc.

### 1a: Infer Commit and Branch Conventions from Git History

Not every team uses the same conventions. Sample the repository's own history
rather than assuming defaults:

```bash
# Sample recent commit messages (50 is usually enough to see the pattern)
git log --oneline -50

# See remote branches to understand naming conventions
git branch -r
```

From the log, determine:

| Question | What to look for |
|---|---|
| **Commit format** | Does every message start with a ticket ID? (`ABC-123`, `PROJ-42`) A type prefix? (`feat:`, `fix:`, `chore:`) A plain description? A combination? |
| **Ticket ID prefix(es)** | What external issue-tracker key(s) appear? (e.g., a GitHub issue reference convention, or prefixes like `WSD-`, `CORE-`, `BE-`) The full set MUST be passed to `create-iconrc` (Step 6) as `forbidden_prefixes`, and the chosen `local_task_id_prefix` MUST be distinct from every entry — agents otherwise cannot tell at a glance whether a task ID points at a real external ticket. |
| **Case and separator** | `TICKET-123: Title` vs `ticket-123 title` vs `[TICKET-123] Title` |
| **Body / footer conventions** | Co-authors? Breaking-change footers? Scope annotations? |
| **Integration branches** | Which branches act as merge targets? (`main`, `master`, `dev`, `develop`, a release branch, etc.) |
| **Feature branch format** | `feature/ABC-123-short-desc`? `ABC-123-description`? `users/name/branch`? |
| **Release/tag format** | `v1.2.3`? `release/1.2.3`? `1.2.3`? |

Record your findings — they feed directly into `workflows/commit-conventions.md`
and `workflows/branching.md` in Step 4, and into the pruning script in Step 3.

---

## context-specialist-impl-leaf: Step 2: Create Directory Structure and Copy Template Files

Invoke the `find-context-template` skill to locate the template directory and establish `$TEMPLATE_DIR`.

```bash
# Bash / zsh
mkdir -p .context/{standards,architecture,testing,tasks,workflows,domains,styling}

# Template files — copy verbatim, do not customize
cp "$TEMPLATE_DIR/context/META.md"              .context/
cp "$TEMPLATE_DIR/context/retrospectives.md"    .context/
cp "$TEMPLATE_DIR/context/overview.md"          .context/
cp -r "$TEMPLATE_DIR/context/decisions"          .context/
cp "$TEMPLATE_DIR/context/.gitignore"           .context/
cp "$TEMPLATE_DIR/context/workflows/prune-context.sh"         .context/workflows/
chmod +x .context/workflows/prune-context.sh

# Phase template directory — loaded on-demand by phase skills
mkdir -p .context/workflows/task-plan
cp "$TEMPLATE_DIR/context/workflows/task-plan/base.md"                 .context/workflows/task-plan/
cp "$TEMPLATE_DIR/context/workflows/task-plan/phase-investigation.md"  .context/workflows/task-plan/
cp "$TEMPLATE_DIR/context/workflows/task-plan/phase-architecture.md"   .context/workflows/task-plan/
cp "$TEMPLATE_DIR/context/workflows/task-plan/phase-implementation.md" .context/workflows/task-plan/
cp "$TEMPLATE_DIR/context/workflows/task-plan/phase-testing.md"        .context/workflows/task-plan/
cp "$TEMPLATE_DIR/context/workflows/task-plan/phase-completion.md"     .context/workflows/task-plan/
```

```powershell
# PowerShell
New-Item -ItemType Directory -Force -Path .context/standards, .context/architecture, .context/testing, .context/tasks, .context/workflows, .context/domains, .context/styling

# Template files — copy verbatim, do not customize
Copy-Item "$TEMPLATE_DIR\context\META.md"              .context\
Copy-Item "$TEMPLATE_DIR\context\retrospectives.md"    .context\
Copy-Item "$TEMPLATE_DIR\context\overview.md"          .context\
Copy-Item "$TEMPLATE_DIR\context\decisions" .context\ -Recurse
Copy-Item "$TEMPLATE_DIR\context\.gitignore"           .context\
Copy-Item "$TEMPLATE_DIR\context\workflows\prune-context.sh"         .context\workflows\
# chmod not needed on Windows — the script is invoked explicitly via `bash script.sh`

# Phase template directory — loaded on-demand by phase skills
New-Item -ItemType Directory -Force -Path .context\workflows\task-plan
Copy-Item "$TEMPLATE_DIR\context\workflows\task-plan\base.md"                 .context\workflows\task-plan\
Copy-Item "$TEMPLATE_DIR\context\workflows\task-plan\phase-investigation.md"  .context\workflows\task-plan\
Copy-Item "$TEMPLATE_DIR\context\workflows\task-plan\phase-architecture.md"   .context\workflows\task-plan\
Copy-Item "$TEMPLATE_DIR\context\workflows\task-plan\phase-implementation.md" .context\workflows\task-plan\
Copy-Item "$TEMPLATE_DIR\context\workflows\task-plan\phase-testing.md"        .context\workflows\task-plan\
Copy-Item "$TEMPLATE_DIR\context\workflows\task-plan\phase-completion.md"     .context\workflows\task-plan\
```

> The `task-plan/` directory contains per-phase workflow templates that are
> loaded on-demand by phase skills as a task progresses. Copy verbatim; teams
> customize them post-installation. See each file's header comment for guidance.

---

## context-specialist-impl-leaf: Step 3: Wire Automatic Task Pruning

`.context/tasks/` is ephemeral. A tracked git hook prunes stale task folders
automatically after every commit so the whole team benefits without any
per-machine cron setup:

```bash
# Bash / zsh
mkdir -p .githooks
cp "$TEMPLATE_DIR/context/workflows/post-commit"  .githooks/post-commit
chmod +x .githooks/post-commit
git config core.hooksPath .githooks
```

```powershell
# PowerShell
New-Item -ItemType Directory -Force -Path .githooks
Copy-Item "$TEMPLATE_DIR\context\workflows\post-commit" .githooks\post-commit
# chmod not needed on Windows — git invokes the hook directly
# Then run: git config core.hooksPath .githooks  (identical in all shells)
```

Commit `.githooks/post-commit` to the repository. Any team member who clones
and runs `git config core.hooksPath .githooks` gets automatic pruning.

**Update the integration branch pattern** using the branch names discovered in
Step 1a. Edit the `INTEGRATION_BRANCHES` variable near the top of
`.context/workflows/prune-context.sh` to match this repository exactly:

```bash
# Example: repo uses "main" and "dev" only
INTEGRATION_BRANCHES="^(main|dev)$"

# Example: repo uses "master" with numbered release branches like "release/1.x"
# (release branches are NOT integration branches — they should be excluded)
INTEGRATION_BRANCHES="^(master|develop)$"
```

**How pruning works** — two guards prevent accidental data loss:

1. **Branch guard**: pruning only runs on integration branches matching
   `INTEGRATION_BRANCHES`. On feature, hotfix, and release branches it is
   silently skipped. This means checking out a 6-month-old release tag to do
   a hotfix will never wipe the task context from that release.

2. **Git-log date**: age is measured by the last *committed* date of each task
   folder (`git log`), not by filesystem mtime. `git checkout` resets mtime to
   "now", so mtime-based checks are unreliable across branch switches. Git
   history is stable.

A task folder is removed only when **both** conditions are met: on an
integration branch AND the folder's last commit is 90+ days ago.

To run a one-off cleanup manually (branch guard still applies):
```bash
bash .context/workflows/prune-context.sh
```

### context-specialist-impl-leaf: Step 3b: Ensure repo-root `.gitattributes`

Retrospective logs are append-mostly, so give them the `union` merge driver at
the git repo root. A slash-less pattern matches the basename at any depth, so one
root-level file covers every `.context/` directory in the repository. Idempotent —
safe to re-run.

```bash
# Ensure repo-root .gitattributes gives retrospective logs a union merge driver,
# so concurrent retrospective appends across branches merge cleanly instead of
# conflicting. Idempotent — safe to re-run.
ROOT=$(git rev-parse --show-toplevel)
GA="$ROOT/.gitattributes"
if [ -f "$GA" ] && grep -qF 'retrospectives.md' "$GA"; then
  echo ".gitattributes: retrospective union-merge entries already present — skipped"
else
  {
    printf '\n# ICON retrospective logs are append-mostly; the union merge driver keeps\n'
    printf '# both sides'"'"' entries instead of conflicting on concurrent appends.\n'
    printf 'retrospectives.md          merge=union\n'
    printf 'retrospectives-archive.md  merge=union\n'
  } >> "$GA"
  echo "Ensured retrospective union-merge entries in $GA"
fi
```

---

## context-specialist-impl-leaf: Step 4: Populate Every File Exhaustively

This is the most important step. **Generic templates are useless.** Every file
must contain real class names, real file paths, real code examples, and real
business rules drawn from the actual codebase. If a statement could apply to any
project, it doesn't belong here.

### Quality Bar — What "Thorough" Looks Like

| Shallow (bad) | Thorough (good) |
|---|---|
| "Use constructor injection" | Code snippet from an actual class showing the pattern |
| "Controllers call services" | Naming table: `CustomerController` → `CustomerService` → `CustomerServiceImpl` with real package paths |
| "Payments domain exists" | Entity table, lifecycle diagram, API endpoint table, business rules from validators |
| "Tests use Mockito" | Actual base class names, import block, example test method, naming conventions |
| "Uses Flyway for migrations" | How to generate timestamps, which module, naming convention, example filename |

**Atomicity:** Each file should cover exactly one facet of one topic. If a domain or standards file is growing large or mixing concerns, split it rather than expanding. See `context-document-guidelines` for size heuristics and when-to-split signals.

---

Per-file content guidance for every `.context/` file lives in [`step-4-file-content.md`](step-4-file-content.md). That document covers `overview.md`, `decisions/`, the `standards/`, `architecture/`, `testing/`, `workflows/`, `domains/`, and `styling/` files — each with the specific real-world content the file must include to clear the Quality Bar above.

---

## context-specialist-impl-leaf: Step 4.5: Generate `rules-index.md`

After populating `standards/`, `workflows/`, and `decisions/`, **generate** `.context/rules-index.md` — an on-demand router that gives those three directories the discoverability `domains/` already has. Do NOT `cp` the template; build the file by scanning the directories you just populated:

1. Three sections — `## Standards`, `## Workflows`, `## Decisions (ADRs)` — each a markdown table with header `| Rule | Applies when… | File |` (`Decisions` uses `| ADR | Applies when… | File |`).
2. **Standards / Workflows**: one row per top-level file in the directory. For a sub-directory that holds an indexed rule (e.g. `standards/skill-decomposition/`, `workflows/task-plan/`), emit a single **parent row** linking the directory (or its parent `.md`), not one row per inner file. Skip non-rule helper scripts (e.g. `prune-context.sh`).
3. **Decisions**: one row per `NNN-*.md` ADR, keyed by the ADR number, linking `decisions/NNN-slug.md`.
4. For each row, write the "Applies when…" cell as a terse, concrete situation that routes a reader to that file — a trigger phrase, not a summary of the rule.
5. Use [`../../context_template/context/rules-index.md`](../../context_template/context/rules-index.md) as the schema reference (header, intro, section layout). Replace its sentinel rows with the real rows you scanned.

---

## context-specialist-impl-leaf: Step 5: Verify

After creating all files, confirm quality:

1. List all files created
2. For each domain file: verify it contains at least one real class name, one real
   file path, and one real code example or table
3. For each standards file: verify it contains at least one real code snippet
4. Confirm template files were copied (not recreated from scratch)
5. Confirm `.githooks/post-commit` exists and is executable
6. Confirm `git config core.hooksPath` is set
6a. Root-level `.gitattributes` exists and contains `merge=union` for `retrospectives.md` / `retrospectives-archive.md`.
7. Confirm `.context/workflows/task-plan/` directory exists and contains all
   6 files: `base.md`, `phase-investigation.md`, `phase-architecture.md`,
   `phase-implementation.md`, `phase-testing.md`, `phase-completion.md`.
8. Confirm root-level `claude.md` exists.
9. Confirm `.context/rules-index.md` exists and its row count matches the file count in `standards/` + `workflows/` (parent rows for indexed sub-dirs) plus the ADR count in `decisions/`.

**Flag any gaps** — areas where the codebase was too complex to document fully in
one pass. A list of "needs attention" items is better than shallow docs that look
complete but aren't.

---

## context-specialist-impl-leaf: Step 6: Create Project `.iconrc`

Invoke the `create-iconrc` skill with `repo_type: project`, passing the ticket
prefixes detected in Step 1a so the skill can reject a colliding
`local_task_id_prefix`:

> Invoke skill: `create-iconrc` — `repo_type: project`, `forbidden_prefixes: <set detected in Step 1a>`, `local_task_id_prefix: <distinct value>`

The chosen `local_task_id_prefix` MUST be distinct (case-insensitive) from every
prefix in `forbidden_prefixes`. If the team has no opinion, default to `LOCAL` —
it is generic, clearly signals "not a real ticket", and is unlikely to collide
with any real-world external tracker key. Local task IDs use the format
`<PREFIX>-<NNN>` with a numeric suffix at least 3 digits wide and zero-padded
(e.g., `LOCAL-001`).

This creates `.context/iconrc.json` for this project, recording the project type
so agents can tailor their behaviour to the project's characteristics.

**Why this step is here**: `initialize-repo` is called by `initialize-monorepo`
and `initialize-workspace` for each sub-project. Adding `create-iconrc` here
means per-project `.iconrc` creation is automatically covered for all
orchestrators — they do not need to invoke it explicitly for each sub-project.

---

## After Setup

- Commit `.context/` and `.githooks/` to the repository
- Review all files with someone who knows the codebase — AI inference is good but
  misses institutional knowledge
- Add domain files for any area not yet covered, as agents start working in them
- The retrospective system will keep docs current as tasks complete (see `META.md`)
