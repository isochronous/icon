#!/usr/bin/env bash
# ============================================================
# check-rules-index.sh — rules-index.md freshness check (SSOT)
# ============================================================
# Single source of truth for the rules-index invariant, shared by:
#   - .githooks/pre-commit (ICON-only hard gate; $repo_root IS the plugin root)
#   - skills/context-maintenance (consumer-facing task-close audit; Phase 1
#     "Index-coverage gap" row)
#
# This check is FOLDER-AWARE and BIDIRECTIONAL (ICON-0069 gap fix):
#
# FORWARD (completeness, folder-aware):
#   The indexable unit under standards/ and workflows/ is a top-level NAME:
#   either a *.md file's basename-without-.md OR a sub-directory's name.
#   A file and a directory of the same name collapse to ONE unit
#   (e.g. standards/skill-decomposition.md + standards/skill-decomposition/
#   require exactly one row). Each unique name must have >=1 row whose link
#   target is EITHER (<dir>/<name>.md) OR (<dir>/<name>/...). This lets a
#   by-the-book folder split (which replaces <name>.md with <name>/README.md)
#   stay indexed via a row that points at the folder. Non-.md top-level files
#   (e.g. workflows/prune-context.sh) are NOT units and are ignored.
#   ADRs are unchanged: each decisions/[0-9]*.md needs a (decisions/<base>) row.
#
# BACKWARD (no dead rows):
#   Every link target in rules-index.md that points under standards/,
#   workflows/, or decisions/ must resolve to an existing path on disk — a
#   file OR a directory (workflows/task-plan/ is a valid directory target).
#   This catches rows left pointing at a file that a split deleted.
#
# Forward row-presence uses fixed-string grep -qF on the two candidate link
# forms. Backward targets are extracted with one POSIX grep -oE pass and
# validated in bash (shell-portability Rule 2: parsing stays in bash, not awk).
#
# Read-only: never writes, deletes, or stages. Diagnostics go to stderr.
# No 2>/dev/null — diagnostic output stays visible (ADR-007).
#
# Usage:   check-rules-index.sh [repo_root]
#   repo_root  Directory containing .context/. Defaults to the git toplevel.
# Exit:    0 = every unit is indexed AND every index row resolves on disk
#              (prints one-line OK to stdout)
#          1 = one or more forward misses OR one or more dead rows
#              (all problems listed on stderr)
#          2 = environment error (.context/ or rules-index.md missing)
set -euo pipefail

# ------------------------------------------------------------
# Resolve repo root
# ------------------------------------------------------------
if [[ $# -ge 1 && -n "${1:-}" ]]; then
  repo_root="$1"
else
  repo_root="$(git rev-parse --show-toplevel)"
fi

context_dir="$repo_root/.context"
rules_index="$context_dir/rules-index.md"

if [[ ! -d "$context_dir" ]]; then
  echo "[check-rules-index] error: .context/ not found under: $repo_root" >&2
  exit 2
fi

if [[ ! -f "$rules_index" ]]; then
  echo "[check-rules-index] error: rules index missing: $rules_index" >&2
  echo "  fix: create .context/rules-index.md (see context-specialist-impl-leaf Step 4.5)" >&2
  exit 2
fi

# ============================================================
# FORWARD: every top-level NAME under standards/ and workflows/
# has >=1 row; every numbered ADR has a row. Folder-aware:
# collapse <name>.md + <name>/ to one unit.
# ============================================================
forward_missing=()

shopt -s nullglob
for dir in standards workflows; do
  dir_path="$context_dir/$dir"
  [[ -d "$dir_path" ]] || continue

  # Collect unique names from *.md files (basename minus .md) and sub-dirs.
  names=()
  for f in "$dir_path"/*.md; do
    [[ -f "$f" ]] || continue
    b="${f##*/}"
    names+=("${b%.md}")
  done
  for d in "$dir_path"/*/; do
    [[ -d "$d" ]] || continue
    d="${d%/}"
    names+=("${d##*/}")
  done

  # Deduplicate names (collapses the file+dir pair to one unit).
  uniq_names=()
  for n in "${names[@]}"; do
    seen=0
    for u in "${uniq_names[@]:-}"; do
      [[ "$u" == "$n" ]] && { seen=1; break; }
    done
    (( seen == 0 )) && uniq_names+=("$n")
  done

  # A name is satisfied by a row whose link target is (dir/name.md) OR (dir/name/...).
  for n in "${uniq_names[@]:-}"; do
    [[ -n "$n" ]] || continue
    if grep -qF "($dir/$n.md)" "$rules_index"; then
      continue
    fi
    if grep -qF "($dir/$n/" "$rules_index"; then
      continue
    fi
    forward_missing+=(".context/$dir/$n (file or folder)")
  done
done

# decisions/: numbered ADRs only; README.md and non-NNN files excluded by glob.
for adr in "$context_dir"/decisions/[0-9]*.md; do
  [[ -f "$adr" ]] || continue
  base="${adr##*/}"
  if ! grep -qF "(decisions/$base)" "$rules_index"; then
    forward_missing+=(".context/decisions/$base")
  fi
done
shopt -u nullglob

# ============================================================
# BACKWARD: every link target under standards/, workflows/, or
# decisions/ must resolve to an existing path on disk.
# ============================================================
dead_rows=()

# Extract link targets of the form ](standards|workflows|decisions/...).
# grep -oE returns 1 (no match) under set -e; guard with || true.
while IFS= read -r match; do
  [[ -n "$match" ]] || continue
  target="${match#](}"      # strip leading "]("
  target="${target%)}"      # strip trailing ")"
  if [[ ! -e "$context_dir/$target" ]]; then
    dead_rows+=("$target")
  fi
done < <(grep -oE '\]\((standards|workflows|decisions)/[^)]*\)' "$rules_index" || true)

# ============================================================
# Report (accumulate-then-report across BOTH directions)
# ============================================================
fail=0

if (( ${#forward_missing[@]} > 0 )); then
  fail=1
  echo "[check-rules-index] error: rule unit has no row in .context/rules-index.md:" >&2
  for m in "${forward_missing[@]}"; do
    echo "  $m is not indexed" >&2
  done
  echo "  fix: add an 'Applies when…' row linking the file or folder to .context/rules-index.md" >&2
fi

if (( ${#dead_rows[@]} > 0 )); then
  fail=1
  echo "[check-rules-index] error: rules-index.md row points at a path that does not exist:" >&2
  for t in "${dead_rows[@]}"; do
    echo "  $t (linked from .context/rules-index.md, not found on disk)" >&2
  done
  echo "  fix: repoint the row at the current path, or remove the row if the rule was deleted" >&2
fi

if (( fail == 1 )); then
  exit 1
fi

echo "[check-rules-index] OK: all rule units indexed and all index rows resolve"
exit 0
