#!/usr/bin/env bash
# bump-versions.sh — Update the ICON plugin version in the canonical manifest.
#
# Usage:  bump-versions.sh [--dry-run] <new-version>
# Example: bump-versions.sh 1.14.0
#          bump-versions.sh --dry-run 1.14.0
#
# --dry-run: print what would change and exit 0 WITHOUT writing.
#            A downgrade is still rejected even in dry-run mode.
#
# Must be run from the repo root, or via the release-plugin skill which
# invokes it automatically.  The script auto-navigates to the repo root
# using its own path, so it is safe to invoke from any directory.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$REPO_ROOT"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
DRY_RUN=0
ARGS=()
for arg in "$@"; do
    if [ "$arg" = "--dry-run" ]; then
        DRY_RUN=1
    else
        ARGS+=("$arg")
    fi
done

if [ "${#ARGS[@]}" -ne 1 ]; then
    echo "Usage: $(basename "$0") [--dry-run] <new-version>"
    echo "  e.g., $(basename "$0") 1.14.0"
    exit 1
fi

NEW="${ARGS[0]}"

if ! echo "$NEW" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "Error: new version must be plain semver (e.g., 1.14.0), got: ${NEW}" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Read current version from the canonical plugin.json
# ---------------------------------------------------------------------------
PRIMARY=".claude-plugin/plugin.json"
if [ ! -f "$PRIMARY" ]; then
    echo "Error: cannot find ${PRIMARY}  (run from repo root)" >&2
    exit 1
fi

OLD=$(grep -m1 '"version"' "$PRIMARY" | sed 's/.*"version": "\(.*\)".*/\1/')
if [ -z "$OLD" ]; then
    echo "Error: could not parse version field from ${PRIMARY}" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Monotonicity check — NEW must be strictly greater than OLD.
# Per-component comparison; no implicit ceiling on any segment.
# ---------------------------------------------------------------------------
ver_gt() {
    # Returns 0 (true) iff $1 is strictly semver-greater than $2.
    local a_maj a_min a_pat b_maj b_min b_pat
    IFS=. read -r a_maj a_min a_pat <<< "$1"
    IFS=. read -r b_maj b_min b_pat <<< "$2"
    if [[ "$a_maj" -ne "$b_maj" ]]; then [[ "$a_maj" -gt "$b_maj" ]]; return; fi
    if [[ "$a_min" -ne "$b_min" ]]; then [[ "$a_min" -gt "$b_min" ]]; return; fi
    [[ "$a_pat" -gt "$b_pat" ]]
}

if ! ver_gt "$NEW" "$OLD"; then
    echo "Error: new version ${NEW} is not strictly greater than current version ${OLD} — aborting." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Dry-run: show what would change and exit without writing.
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 1 ]; then
    echo "Dry-run: no files will be written."
    echo ""
    echo "  ${PRIMARY}"
    echo "    before: \"version\": \"${OLD}\""
    echo "    after:  \"version\": \"${NEW}\""
    echo ""
    echo "Dry-run complete. Re-run without --dry-run to apply."
    exit 0
fi

# ---------------------------------------------------------------------------
# Bump the single canonical manifest.
# ---------------------------------------------------------------------------
echo "Bumping ICON version: ${OLD} → ${NEW}"
echo ""

# Escape dots in OLD so they match literally in BRE sed patterns.
OLD_ESC=$(printf '%s' "$OLD" | sed 's/\./\\./g')

sed -i "s/\"version\": \"${OLD_ESC}\"/\"version\": \"${NEW}\"/" "$PRIMARY"
echo "  [1/1] ${PRIMARY}"

echo ""
echo "Done. ICON version bumped: ${OLD} → ${NEW}"
