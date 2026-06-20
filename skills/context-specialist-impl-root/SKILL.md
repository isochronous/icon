---
name: context-specialist-impl-root
description: >
  Internal @context-specialist skill. Do not invoke without explicit direction.
user-invocable: false
---

# Initialize Root Context

A root node is the top-level directory of a monorepo, workspace, or multi-module
directory (identified by `nx.json`, `turbo.json`, `go.work`, `.sln`, a
`package.json` with `"workspaces"`, or a `pom.xml` with `<modules>` and no
`src/`; or simply a parent directory containing multiple independent sub-projects
with no formal manifest). This skill generates cross-project
and infrastructure-level `.context/` documentation for the entire repository.

**Do not modify sub-project `.context/` folders.** Root context covers what is
shared across or between projects — not what is specific to any one project.

---

## `.context/` Structure

```
.context/
├── META.md                           # copy from context_template verbatim
├── retrospectives.md                 # copy from context_template verbatim
├── overview.md                       # what the monorepo is, how areas relate
├── projects.md                       # canonical project map for all areas
├── decisions/                        # decisions affecting 2+ areas
├── architecture/
│   └── patterns.md                   # cross-area patterns and shared abstractions
├── domains/                          # business/technical domains spanning 2+ areas
│   └── <domain>.md
├── workflows/
│   ├── ci-cd.md                      # root-level pipeline and deployment
│   ├── branching.md                  # branching strategy and merge process
│   └── commit-conventions.md         # detected from git log
└── .gitignore                        # copy from context_template verbatim
```

---

## context-specialist-impl-root: Step 1: Read Sub-Project Context

Before generating any root-level content, read each area's `.context/overview.md`
to understand what exists. Record:
- The first sentence of each area's overview (for projects.md descriptions)
- The primary language/stack of each area
- Any shared concepts or libraries mentioned across multiple overviews

This step is critical — root content must synthesize across areas, not guess.

---

## context-specialist-impl-root: Step 2: Generate `projects.md`

The canonical project map that agents use (via `resolve-repo-context`) to locate
any area by name. This is the most important file at root level.

Format:

```markdown
| Project Name | Path | Description | Primary Language/Stack |
|---|---|---|---|
| <service-a> | src/<service-a> | <one-sentence description from overview.md> | <language/stack> |
| <service-b> | src/<service-b> | <one-sentence description from overview.md> | <language/stack> |
```

Rules:
- Derive names and descriptions from each area's `overview.md` first sentence
- Use the directory name as the project name if no better name exists
- Include every area discovered in the repo — do not omit any
- Paths should be relative to the repo root

---

## context-specialist-impl-root: Step 3: Examine Root Infrastructure

Scan the repo root for infrastructure that applies across all areas:

- **CI/CD**: `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `azure-pipelines.yml`
- **Container orchestration**: `docker-compose*.yml`, `k8s/`, `helm/`
- **IaC**: `terraform/`, `cdk/`, `pulumi/`
- **Build coordination**: `Directory.Build.props`, `Directory.Packages.props` (.NET),
  `nx.json` / `turbo.json` (Node), `go.work` (Go), root `pom.xml` / `build.gradle`
- **Shared scripts**: `Makefile`, `scripts/`, `.tool-versions`, `.nvmrc`
- **Solution files**: `*.sln`

Record findings — they feed into `workflows/ci-cd.md` and `architecture/patterns.md`.

---

## context-specialist-impl-root: Step 4: Update or Create `claude.md`

Check for `.claude/claude.md` at the repo root:

- **If it exists**: Update it to reflect the full multi-area structure.
  Add or update a section referencing `projects.md` in `.context/` as the area
  inventory. Ensure it lists all areas and their roles. Do not remove existing
  content that is still accurate.
- **If it does not exist**: Create it covering:
  - What this monorepo is (1–2 sentences)
  - Full list of areas and their roles (reference `projects.md`)
  - Integration branch and feature branch naming convention
  - Key build/test commands at repo root
  - Pointer to `projects.md` under `.context/` for the area map

---

## context-specialist-impl-root: Step 5: Generate `overview.md`

Answers "what is this repository, how is it organized, and what is shared?"

Required content:
- What this monorepo is and what business purpose it serves (1–3 paragraphs)
- How areas relate to each other: shared libraries, service communication,
  data flow, or event buses — omit if areas are fully independent
- Multi-tenant or multi-environment deployment model if relevant
- Cross-cutting concepts that span 2+ areas
- Link to `projects.md` for the full area inventory

Do not duplicate what is in area `overview.md` files — reference areas by path.

---

## context-specialist-impl-root: Step 6: Generate `decisions/`

Architectural decisions that affect two or more areas. Examples:
- Shared authentication library or pattern used across services
- Locked framework or runtime versions enforced repo-wide
- Patterns intentionally *not* used (and why)
- Cross-area migrations in progress

Format: one ADR per `NNN-kebab-slug.md` file, with `README.md` as the index. See `context-document-guidelines § Folder Split Rule` for the layout convention. Omit if no cross-area decisions are identifiable.

---

## context-specialist-impl-root: Step 7: Generate `architecture/patterns.md`

Cross-area integration patterns and shared abstractions:
- How services communicate (REST, gRPC, message queues, shared libraries)
- Shared NuGet packages, npm packages, Go modules used by 2+ areas
- Common base classes, shared middleware, or common infrastructure patterns
- Module dependency graph if meaningful

Keep strictly to patterns used by 2+ areas. Per-area patterns belong in the
area's own `architecture/patterns.md`.

---

## context-specialist-impl-root: Step 8: Generate `domains/` files

One file per business or technical domain that spans 2 or more areas.
Format follows the same structure as leaf-level domain files (overview, key
entities, API endpoints, business rules, important code paths).

Examples of root-level domains:
- `authentication.md` — if auth is shared across all services
- `event-bus.md` — if a shared message queue is used by 2+ services
- `shared-models.md` — if common DTOs or entities span multiple areas

Do not create domain files for concepts internal to a single area.

---

## context-specialist-impl-root: Step 9: Generate `workflows/ci-cd.md`

Root-level pipeline and deployment process:
- CI system (GitHub Actions, GitLab CI, Jenkins, etc.) and config file location
- Pipeline stages and what each does (build, test, lint, publish, deploy)
- How to run the full pipeline locally (if possible)
- Deployment environments and how to trigger deploys
- Any manual gates or approvals required
- Per-area pipeline differences if any areas have divergent CI

---

## context-specialist-impl-root: Step 10: Generate `workflows/branching.md`

Branching strategy for the full repository:
- Primary integration branch name(s) — verified from `git branch -r`
- Feature branch naming: exact format with real examples from `git log`
- Release/tag naming format with real examples from `git tag`
- Merge request workflow (squash? merge commit? rebase?)
- Whether linear history is enforced

---

## context-specialist-impl-root: Step 11: Generate `workflows/commit-conventions.md`

Detect from `git log --oneline -50`:
- The format pattern with a concrete example
- Ticket ID prefix(es) in use — the full set MUST be passed to `create-iconrc`
  (Step 14) as `forbidden_prefixes`, and the chosen `local_task_id_prefix` MUST
  be distinct from every entry. Agents otherwise cannot tell at a glance whether
  a task ID points at a real Jira/Linear/GitHub ticket.
- Whether a body or footer is conventional
- 3–5 real examples from git log

This file is the authoritative source agents use when writing commit messages.

---

## context-specialist-impl-root: Step 12: Copy Infrastructure Files

Invoke the `find-context-template` skill to locate `$TEMPLATE_DIR`, then:

```bash
cp "$TEMPLATE_DIR/context/META.md"           .context/
cp "$TEMPLATE_DIR/context/retrospectives.md" .context/
cp "$TEMPLATE_DIR/context/.gitignore"        .context/

mkdir -p .context/workflows
cp "$TEMPLATE_DIR/context/workflows/prune-context.sh"        .context/workflows/
chmod +x .context/workflows/prune-context.sh
```

> Copy verbatim — do not customize template files.

---

## context-specialist-impl-root: Step 13: Wire Git Hook

Wire the automatic task-pruning hook at the repo root if not already wired:

```bash
git config core.hooksPath .githooks
```

Confirm `.githooks/post-commit` exists. If it does not, copy it from
`$TEMPLATE_DIR/context/workflows/post-commit` and `chmod +x` it.

### context-specialist-impl-root: Step 13b: Ensure repo-root `.gitattributes`

Retrospective logs are append-mostly, so give them the `union` merge driver at
the git repo root. A slash-less pattern matches the basename at any depth, so one
root-level file covers every area's `.context/` directory. Idempotent — safe to
re-run.

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

## context-specialist-impl-root: Step 14: Create Root `.iconrc`

Invoke the `create-iconrc` skill at the repository root with the `repo_type`
value supplied by the dispatcher prompt, passing the ticket prefixes detected
in Step 11 so the skill can reject a colliding `local_task_id_prefix`:

> Invoke skill: `create-iconrc` — `repo_type: <repo_type>`, `forbidden_prefixes: <set detected in Step 11>`, `local_task_id_prefix: <distinct value>`

The chosen `local_task_id_prefix` MUST be distinct (case-insensitive) from every
prefix in `forbidden_prefixes`. If the team has no opinion, default to `LOCAL`.
Local task IDs use the format `<PREFIX>-<NNN>` with a numeric suffix at least
3 digits wide and zero-padded (e.g., `LOCAL-001`).

---

## context-specialist-impl-root: Step 15: Verify and Commit

Verify all root-level files are present:

1. `projects.md` in `.context/` exists and lists all areas
2. `.context/overview.md` exists and contains real content
3. `.context/decisions/` exists (or is explicitly omitted with reason)
<!-- pre-commit:dead-ref-ok-start -->
4. `.context/architecture/patterns.md` exists (or is explicitly omitted)
<!-- pre-commit:dead-ref-ok-end -->
5. `.context/workflows/ci-cd.md`, `branching.md`, `commit-conventions.md` exist
6. `.claude/claude.md` exists at repo root and references `projects.md`
7. `.context/iconrc.json` exists
8. `.context/workflows/prune-context.sh` exists and is executable
9. Root-level `.gitattributes` exists and contains `merge=union` for `retrospectives.md` / `retrospectives-archive.md`.

Commit all created/updated files with a message following the repo's commit convention.
Example: `chore: initialize agent-system context at repo root`

**Flag any gaps** — areas where infrastructure was too complex to document fully.
A list of "needs attention" items is better than shallow docs that look complete.

---

## Content Quality Standard

Root context is **cross-project and infrastructure-level**. It covers what is
shared across or between areas — not what any individual area does in detail.
Reference area paths rather than duplicating area content.

| Shallow (bad) | Thorough (good) |
|---|---|
| "Areas communicate via REST" | Table: which service calls which, shared client libraries, auth method |
| "Uses GitHub Actions" | Pipeline stages, triggers, deploy environments, manual gates |
| "Monorepo with multiple services" | projects.md with paths, descriptions, stacks, and cross-project decisions |
