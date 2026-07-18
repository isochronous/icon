# `context-graph` — Tooling Reference

Companion reference for the `context-maintenance` skill. Documents the script
that parses a `.context/` tree into a knowledge graph — used on the **read**
side (discovery) and the **write** side (a fail-closed consistency check).

---

The `context-graph` script (located in the `scripts/` subdirectory at
`skills/context-maintenance/scripts/`) parses every `.context/` file **once**
and reports the graph either as an adjacency listing (`--emit`) or as a set of
structural defects (`--check`). It **never emits file contents** — only paths
and edge tags.

Two variants ship side by side — pick the one that matches the calling shell:

- `context-graph.sh` — Bash (Linux, macOS, WSL, Git-Bash) — the SSOT parser.
- `context-graph.ps1` — PowerShell (Windows without Git-Bash/WSL).

Both variants produce identical output, edge ordering, and exit codes. They are
verified against the same fixtures (ADR-004 parity; shell-portability §8.5).

**This is a read-only reporter — it never writes, deletes, or stages.**

### When to use

- **Read side (discovery):** on a medium/complex task, run `--emit` once after
  reading `rules-index.md`, then traverse `references` / `covers` /
  `supersedes` out-edges to collect the reachable set before reading files.
- **Write side (maintenance):** run `--check` in the Phase 1 audit to catch
  dangling references and orphan/unreachable content docs across the whole
  tree — generalizing `check-rules-index.sh` from the three rule directories to
  every `.context/` doc.

Rules-index completeness stays owned by `check-rules-index.sh`; `--check`
ingests rules-index rows only as reachability edges and never re-reports them
as dangling (disjoint edge ownership).

### Modes

| Mode | Output | Purpose |
|------|--------|---------|
| `--emit` (default) | `# NODES` (one path/line) then `# EDGES` (`edgetype<TAB>source<TAB>target`), to stdout | Adjacency listing for discovery traversal |
| `--check` | Violations to stderr; a one-line OK to stdout when clean | Structural consistency gate |

Flags: `--include-tasks` adds `tasks/*/plan.md` nodes (excluded by default).

### Node & edge model

Nodes are existing `.context/` document types (overview, projects, rules-index,
domain, standard, workflow, decision, architecture, testing, styling,
folder-index, retrospective, config). Edge types: `references` (inline
`[text](path)` links + a `## Related` section), `covers` (folder-`README.md` /
`projects.md` index tables), `indexed-by` (rules-index rows), `supersedes` /
`superseded-by` (ADR `**Supersedes**` / `**Superseded-by**` bold-fields and the
legacy `**Status**: Superseded by ADR-NNN` prose), `promoted-from`
(retrospective `Promoted to:`), and `excludes` (`iconrc.json`).

Resolved link targets are constrained to stay under the context root
(path-traversal safety); links resolving outside `.context/` are ignored.

### Escape-hatch markers

- `<!-- pre-commit:dead-ref-ok-start --> … <!-- pre-commit:dead-ref-ok-end -->`
  — suppresses the dangling-reference check for links inside the region
  (reuses the existing pre-commit dead-ref marker idiom).
- `<!-- context-graph:orphan-ok -->` — a file-level marker that excludes the
  containing doc from the orphan check (for an intentional, not-yet-linked
  stub).

Markers are opt-outs for genuine intentional gaps — not general escape hatches.

### Usage — Bash

```bash
# Emit the adjacency listing for the repo's .context/ tree
./scripts/context-graph.sh --emit .context

# Run the consistency check (fail-closed); any non-zero must block
./scripts/context-graph.sh --check .context || exit 1
```

### Usage — PowerShell

```powershell
pwsh -NoProfile -File ./scripts/context-graph.ps1 --emit .context
pwsh -NoProfile -File ./scripts/context-graph.ps1 --check .context
```

The path argument may be the `.context/` tree itself **or** a repo root that
contains a `.context/` directory. It defaults to the git toplevel.

### Exit codes

The contract is fail-closed on both violations and uncertainty — **any**
non-zero must abort the caller. Invoke as `… || exit 1`; never guard control
flow with `if context-graph …; then` (which would swallow exit 2).

| Code | Meaning | Caller action |
|------|---------|---------------|
| 0 | Parsed cleanly, no violations (`--check` prints a one-line OK) | proceed |
| 1 | Parsed cleanly, violations found (dangling refs / orphans, listed on stderr) | block |
| 2 | Parser / environment error — missing or unreadable tree, unreadable file, or **zero nodes discovered** (never conflated with "clean") | block |
