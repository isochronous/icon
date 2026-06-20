#!/usr/bin/env bash
# Prune stale .context/ ephemeral content:
#   - .context/cache/  : files with no commits in N+ days (all branches),
#                        configurable via .context/iconrc.json
#                        `cache_expires_after_days` (default: 30 days).
#   - .context/tasks/  : folders with no commits in 90+ days (integration branches only)
#
# Designed to run as a git post-commit hook or standalone script.
#
# Task pruning is skipped on non-integration branches to preserve context
# when working from old release checkpoints.
#
# INTEGRATION_BRANCHES is set by the initialize-repo skill based on git history
# analysis. Update it here if your branch conventions change.
#
# Usage:
#   ./prune-context.sh              # from project root
#   bash .context/workflows/prune-context.sh

set -euo pipefail

# Customize to match this repository's integration branch names.
# Updated by initialize-repo based on git log / git branch analysis.
INTEGRATION_BRANCHES="^(main|master|dev|develop|trunk)$"

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TASKS_DIR="$REPO_ROOT/.context/tasks"
CACHE_DIR="$REPO_ROOT/.context/cache"
ICONRC="$REPO_ROOT/.context/iconrc.json"

if [ ! -d "$TASKS_DIR" ] && [ ! -d "$CACHE_DIR" ]; then
  exit 0
fi

# --- Resolve cache TTL from .context/iconrc.json (default: 30 days) ---
# Prefers jq when available; falls back to a grep|sed parse so the script
# works in minimal environments. The fallback tolerates surrounding whitespace
# and a trailing comma in the JSON value.
CACHE_DAYS_DEFAULT=30
CACHE_DAYS="$CACHE_DAYS_DEFAULT"
if [ -f "$ICONRC" ]; then
  PARSED=""
  if command -v jq >/dev/null 2>&1; then
    PARSED="$(jq -r '.cache_expires_after_days // empty' "$ICONRC" 2>/dev/null || echo "")"
  else
    # Match: "cache_expires_after_days" : 30   (optional trailing comma, any whitespace)
    # `|| true` ensures the pipeline never aborts the script under `set -e` when
    # the key is missing, quoted, negative, or the JSON is malformed — in those
    # cases PARSED stays empty and CACHE_DAYS falls back to the default.
    PARSED="$(grep -E '"cache_expires_after_days"[[:space:]]*:[[:space:]]*[0-9]+' "$ICONRC" \
                | sed -E 's/.*"cache_expires_after_days"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/' \
                | head -n1 || true)"
  fi
  if [[ "$PARSED" =~ ^[0-9]+$ ]] && [ "$PARSED" -gt 0 ]; then
    CACHE_DAYS="$PARSED"
  fi
fi

NOW="$(date +%s)"
CACHE_CUTOFF_SECONDS=$(( CACHE_DAYS * 86400 ))
TASKS_CUTOFF_SECONDS=$(( 90 * 86400 ))

# --- Prune .context/cache/ files older than $CACHE_DAYS days (all branches) ---
PRUNED_CACHE=()
if [ -d "$CACHE_DIR" ]; then
  while IFS= read -r -d '' file; do
    [[ "$(basename "$file")" == .* ]] && continue
    LAST_COMMIT="$(git log -1 --format="%ct" -- "$file" 2>/dev/null || echo "")"

    if [ -z "$LAST_COMMIT" ]; then
      # File is untracked (never committed). Fall back to mtime.
      LAST_COMMIT="$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo "$NOW")"
    fi

    AGE=$(( NOW - LAST_COMMIT ))
    if [ "$AGE" -gt "$CACHE_CUTOFF_SECONDS" ]; then
      PRUNED_CACHE+=("$file")
      rm -f "$file"
    fi
  done < <(find "$CACHE_DIR" -maxdepth 1 -mindepth 1 -type f -print0)

  if [ ${#PRUNED_CACHE[@]} -gt 0 ]; then
    echo "prune-context: removed ${#PRUNED_CACHE[@]} cache file(s) with no commits in ${CACHE_DAYS}+ days:"
    printf '  %s\n' "${PRUNED_CACHE[@]##*/}"
  fi
fi

# --- Prune .context/tasks/ folders older than 90 days (integration branches only) ---
# When working on a hotfix from an old release tag, task context should be
# preserved regardless of folder age.
CURRENT_BRANCH="$(git branch --show-current 2>/dev/null || echo "")"
if [[ ! "$CURRENT_BRANCH" =~ $INTEGRATION_BRANCHES ]]; then
  exit 0
fi

PRUNED_TASKS=()
if [ -d "$TASKS_DIR" ]; then
  while IFS= read -r -d '' dir; do
    # Use the last git commit date for this path, not filesystem mtime.
    # Filesystem mtime is reset to "now" by git checkout, making age checks
    # unreliable when working from old release branches or tags. Git commit
    # history is stable across checkouts.
    LAST_COMMIT="$(git log -1 --format="%ct" -- "$dir" 2>/dev/null || echo "")"

    if [ -z "$LAST_COMMIT" ]; then
      # Folder is untracked (never committed). Fall back to mtime.
      LAST_COMMIT="$(stat -c %Y "$dir" 2>/dev/null || stat -f %m "$dir" 2>/dev/null || echo "$NOW")"
    fi

    AGE=$(( NOW - LAST_COMMIT ))
    if [ "$AGE" -gt "$TASKS_CUTOFF_SECONDS" ]; then
      PRUNED_TASKS+=("$dir")
      rm -rf "$dir"
    fi
  done < <(find "$TASKS_DIR" -maxdepth 1 -mindepth 1 -type d -print0)

  if [ ${#PRUNED_TASKS[@]} -gt 0 ]; then
    echo "prune-context: removed ${#PRUNED_TASKS[@]} task folder(s) with no commits in 90+ days:"
    printf '  %s\n' "${PRUNED_TASKS[@]##*/}"
  fi
fi
