---
name: context-specialist-detect-tree-position
description: >
  Internal @context-specialist skill. Do not invoke without explicit direction.
user-invocable: false
---

# Detect Tree Position

Inspect the filesystem at CWD to determine whether this directory is a monorepo/workspace
root, a grouping directory (branch), or a single project (leaf). Run only when the caller
has not supplied an explicit `tree_position`.

## context-specialist-detect-tree-position: Step 1: ROOT check

Check for monorepo/workspace manifests at CWD. Any of these signals → position = `root`:

- `nx.json`, `turbo.json`, or `go.work` exists at CWD
- A `.sln` file exists at CWD
- A `*.code-workspace` file exists at CWD (VS Code multi-root workspace)
- `package.json` exists at CWD AND contains a `"workspaces"` field
- `pom.xml` exists at CWD AND contains `<modules>` AND `src/` directory does NOT exist

## context-specialist-detect-tree-position: Step 2: LEAF check

Check for a build manifest at CWD. Any of these at CWD → position = `leaf`:

`package.json` (without `"workspaces"`), `go.mod`, `Cargo.toml`, `pyproject.toml`,
`requirements.txt`, `Gemfile`, `build.gradle`, `pom.xml` (with `src/`), `*.csproj`

Note: `package.json` without a `"workspaces"` field skipped by ROOT → resolves to LEAF.

## context-specialist-detect-tree-position: Step 3: BRANCH check

No local manifest matched. Count subdirectories (depth 1) that contain any build manifest.
If 2 or more subdirectories contain build manifests → position = `branch`.

## context-specialist-detect-tree-position: Step 4: Fallback

No signals matched. Default to `leaf`. Log a warning:

> "Tree position could not be determined from manifest signals — defaulting to leaf. Review the generated `.context/` for accuracy."

## Detection Summary

| Signal | Position |
|--------|---------|
| `nx.json`, `turbo.json`, `go.work`, `.sln` at CWD | root |
| `*.code-workspace` file at CWD | root |
| `package.json` with `"workspaces"` | root |
| `pom.xml` with `<modules>` and no `src/` | root |
| `package.json` (no `workspaces`), `go.mod`, `*.csproj`, etc. at CWD | leaf |
| None of above, but 2+ subdirs contain build manifests | branch |
| No signals match | leaf (fallback + warning) |

## Return Value

Returns one of `leaf`, `branch`, or `root`. On fallback, returns `leaf` and logs a warning.

## Entry-Point Detection Primitive (callable)

This skill is also the canonical home for the entry-point detection pattern used
by the init orchestrators (`initialize-monorepo`, `initialize-workspace`,
`initialize-multimodule`). The pattern checks whether a directory has a
runtime-ready agent context (both an entry-point instructions file and a
`.context/` directory) and is used in two places per orchestrator: once when
classifying each area as `initialize-repo` vs `upgrade-repo`, and once during
post-run completeness verification.

**Detection form** — branches `initialize-repo` vs `upgrade-repo` for a single
directory:

```bash
# $dir is the directory to check
if { [ -f "$dir/.claude/claude.md" ] || [ -f "$dir/.github/copilot-instructions.md" ]; } && [ -d "$dir/.context" ]; then
  # Already initialized → upgrade-repo
  echo "upgrade-repo  $dir"
else
  # Not initialized → initialize-repo
  echo "initialize-repo  $dir"
fi
```

**Verification form** — used in post-run completeness checks:

```bash
# $dir is the directory to verify; $ok and FAILURES are caller-owned
{ [ -f "$dir/.claude/claude.md" ] || [ -f "$dir/.github/copilot-instructions.md" ]; } || { echo "MISSING entry point (.claude/claude.md or .github/copilot-instructions.md): $dir"; ok=false; }
```

**Why two forms**: detection is a binary route; verification is a soft-fail
check that accumulates into a `FAILURES` array the caller decides what to do
with. Both forms accept `.claude/claude.md` as canonical and
`.github/copilot-instructions.md` as the legacy fallback.

**How callers reference this**: orchestrators substitute the appropriate loop
variable (`$area`, `$folder`, `$project`, `$proj`) for `$dir` in the snippet
below and cross-reference this section rather than re-inlining the full check.
