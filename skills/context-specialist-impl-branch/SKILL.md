---
name: context-specialist-impl-branch
description: >
  Internal @context-specialist skill. Do not invoke without explicit direction.
user-invocable: false
---

# Initialize Branch Node

A branch node is an intermediate grouping directory (e.g., `services/`, `apps/`,
`packages/`) with no build manifest of its own but containing sub-projects.
This skill generates navigational and connective `.context/` documentation:
what lives here and what the sub-projects share.

---

## `.context/` Structure

```
.context/
├── META.md                      # copy from context_template verbatim
├── overview.md                  # what sub-projects live here and how they relate
├── projects.md                  # sub-project directory map for this group
├── decisions/                   # architectural decisions affecting 2+ sub-projects
├── architecture/
│   └── patterns.md              # shared patterns used by 2+ sub-projects here
├── domains/                     # business/technical domains spanning 2+ sub-projects
│   └── <domain>.md
└── .gitignore                   # copy from context_template verbatim
```

**Explicitly absent** (do not create these at branch level):

| Directory / File | Why Absent |
|-----------------|-----------|
| `standards/` | Code style is per-leaf-project |
| `testing/` | Test infrastructure is per-leaf-project |
| `styling/` | Frontend conventions are per-leaf-project |
| `tasks/` | Tasks are tracked against specific projects, not grouping nodes |
| `retrospectives.md` | Retrospectives are per-project |
| `iconrc.json` | Not created at branch level; `create-iconrc` is leaf and root only |
| `cache/` | Research cache is per-project |

---

## File Content Guide

### `overview.md`

Answers "what lives here and how do they relate?" for an agent navigating down from the root.

Required content:
- 1–3 sentences on the group's shared purpose
- Table: sub-project name | path relative to this node | one-sentence description | primary stack
- How sub-projects communicate (shared libraries, internal APIs, event buses) — omit if they are fully independent

Derive descriptions from each sub-project's `.context/overview.md` first sentence if it exists; otherwise scan the sub-project's build manifest and README first paragraph.

### `projects.md`

Structured directory map used by `resolve-repo-context` to route tasks to the correct sub-project within this group.

Format:

```markdown
| Project Name | Path | Description | Primary Language/Stack |
|---|---|---|---|
| api-service | api-service/ | REST API for X | .NET 8 / C# |
| worker-service | worker-service/ | Background job processor | .NET 8 / C# |
```

### `decisions/`

Architectural decisions that affect 2 or more sub-projects within this group.

Example: "All services in this group share the `common-auth` library for JWT validation."

Format mirrors leaf-level `decisions/` (one ADR per `NNN-kebab-slug.md` file, `README.md` index). Omit if no cross-project decisions exist.

### `architecture/patterns.md`

Cross-project patterns used by 2 or more sub-projects within this group (e.g., shared gRPC client setup, common base controllers, shared middleware).

Keep strictly to patterns used by 2+ sub-projects — single-project patterns belong in the leaf's own `architecture/patterns.md`. Omit or leave minimal if sub-projects share no common patterns.

### `domains/<domain>.md`

Business or technical domain concepts that span 2 or more sub-projects in this group. A domain internal to one sub-project stays in that sub-project's `domains/`. Format follows the same structure as leaf-level domain files.

Create only domains that genuinely span multiple sub-projects — do not duplicate leaf domain files here.

---

## Content Depth Standard

Branch context is **navigational and connective**, not comprehensive. It tells an agent "what lives here and what they share" — it does not duplicate what is in leaf `overview.md` files. Keep descriptions to one sentence per sub-project; a paragraph on shared patterns; cross-project domain concepts only.

---

## Process

1. **Discover sub-projects**: Scan directories at depth 1–2 under the branch directory for build manifests (`package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `requirements.txt`, `Gemfile`, `build.gradle`, `pom.xml`, `*.csproj`).

2. **Gather sub-project context**: For each sub-project, read:
   - Its `.context/overview.md` first sentence (if it exists)
   - Otherwise: its build manifest and README first paragraph

3. **Copy infrastructure files**: Invoke the `find-context-template` skill to locate `$TEMPLATE_DIR`, then copy `$TEMPLATE_DIR/context/META.md` and `$TEMPLATE_DIR/context/.gitignore` verbatim.

4. **Generate `projects.md`**: Build the table from discovered sub-projects.

5. **Generate `overview.md`**: Write the group purpose, sub-project table, and communication patterns.

6. **Generate `decisions/`**: Scan for shared library imports, shared config files, shared CI scripts that affect 2+ sub-projects. Create the folder (with `README.md` and per-ADR files) only if cross-project decisions exist.

7. **Generate `architecture/patterns.md`**: Compare source code patterns across sub-projects (base classes, shared utilities, common middleware). Create only if 2+ sub-projects share patterns.

8. **Generate domain files**: Create a domain file only for concepts that genuinely span 2+ sub-projects. Omit if no cross-cutting domains exist.

9. **Verify**: Confirm all expected files are present and non-empty:
   - `.context/META.md` exists (copied from template, not recreated).
   - `.context/.gitignore` exists (copied from template, not recreated).
<!-- pre-commit:dead-ref-ok-start -->
   - `.context/overview.md` exists and contains the sub-project table with at least one real sub-project row.
   - `.context/projects.md` exists and its table lists every sub-project discovered in Step 1.
   - If cross-project decisions were found: `.context/decisions/` exists with `README.md` plus at least one ADR file; if none were found, confirm the directory was intentionally omitted (note the reason).
   - If 2+ sub-projects share patterns: `.context/architecture/patterns.md` exists with real shared-pattern content; if not, confirm it was intentionally omitted.
   - If cross-cutting domain concepts exist: at least one `domains/<domain>.md` exists; if none, confirm intentionally omitted.
<!-- pre-commit:dead-ref-ok-end -->
   **Flag any gaps** — sub-projects that could not be characterized from available context. A list of "needs attention" items is better than shallow docs that look complete but aren't.

10. **Commit**: Commit all created files with a message following the repo's commit convention.
