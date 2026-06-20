#!/usr/bin/env bash
# ============================================================
# append-retrospective-entry.sh
# ============================================================
# Prepend a new entry to .context/retrospectives.md and prune
# the oldest entry when the current count reaches the cap (10).
#
# Usage:
#   append-retrospective-entry.sh <retro-file> [<entry-source>]
#
#   retro-file    Path to .context/retrospectives.md
#   entry-source  Path to a file containing the new entry text,
#                 or '-' to read from stdin. Defaults to stdin.
#
# Entry text must begin with a '### ' heading line.
# See task-retrospective skill for the canonical entry format:
#   ### TASK-ID: Short description
#   - **Avoid**: ...
#   - **Repeat**: ...
#   - **Updated**: ...
#
# Behavior:
#   1. Counts ### entry blocks from the top of the file.
#   2. If count >= ENTRY_CAP (10), drops the oldest entries until the post-insert
#      count equals ENTRY_CAP (i.e., trims down to cap regardless of how far
#      above cap the file starts — converges, not just one-prune-per-call).
#   3. Prepends the new entry at the top of the file, making it the newest.
#   4. Preserves the trailing HTML comment.
#   5. Writes atomically (temp file in same dir -> mv).
#
# Exit codes:
#   0  Success — file updated
#   1  Usage or validation error
#   2  File access error (missing, unreadable, or not writable)
#
# Requirements: bash >= 4, awk, mktemp, mv

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
ENTRY_CAP=10

# ---------- helpers ----------

die() {
  echo "${SCRIPT_NAME}: error: $*" >&2
  exit 1
}

die2() {
  echo "${SCRIPT_NAME}: error: $*" >&2
  exit 2
}

usage() {
  cat >&2 <<EOF
Usage: ${SCRIPT_NAME} <retro-file> [<entry-source>]

  retro-file    Path to .context/retrospectives.md (must exist and be writable)
  entry-source  Path to a file containing the new entry text, or '-' for stdin.
                Omit to read from stdin.

The new entry is prepended at the top of the file, becoming the newest entry.
If the file already contains ${ENTRY_CAP} or more entries, the oldest entry is
removed before insertion, keeping the log capped at ${ENTRY_CAP} entries.

Entry text must begin with a '### ' heading line, e.g.:
  ### MKT-0045: Short description
  - **Avoid**: ...
  - **Repeat**: ...
  - **Updated**: ...

Exit codes:
  0  Success
  1  Usage or validation error
  2  File access error
EOF
  exit 1
}

# ---------- argument parsing ----------

[[ $# -eq 0 ]] && usage

case "${1:-}" in
  -h|--help) usage ;;
esac

retro_file="${1}"
entry_source="${2:--}"  # default to stdin ('-')

# ---------- file validation ----------

[[ -e "$retro_file" ]]  || die2 "retro-file not found: $retro_file"
[[ -f "$retro_file" ]]  || die2 "retro-file is not a regular file: $retro_file"
[[ -r "$retro_file" ]]  || die2 "retro-file is not readable: $retro_file"
[[ -w "$retro_file" ]]  || die2 "retro-file is not writable: $retro_file"

# ---------- read new entry ----------

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

entry_tmp="${tmpdir}/entry.txt"

if [[ "$entry_source" == "-" ]]; then
  cat > "$entry_tmp"
else
  [[ -e "$entry_source" ]] || die "entry-source not found: $entry_source"
  [[ -f "$entry_source" ]] || die "entry-source is not a regular file: $entry_source"
  [[ -r "$entry_source" ]] || die "entry-source is not readable: $entry_source"
  cp "$entry_source" "$entry_tmp"
fi

# Validate entry starts with '### '
first_line="$(head -1 "$entry_tmp")"
[[ "$first_line" =~ ^"### " ]] \
  || die "entry text must begin with a '### ' heading line (got: ${first_line})"

# ---------- file manipulation ----------

retro_dir="$(dirname "$(realpath "$retro_file")")"
out_tmp="$(mktemp -p "$retro_dir" .retro_tmp_XXXXXX.md)"
trap 'rm -f "$out_tmp"; rm -rf "$tmpdir"' EXIT

# Pruned entries are archived here (uncapped, append-only) rather than being
# silently destroyed. The main file is still written atomically (tmp -> mv);
# the archive is appended directly with >> — an accepted tradeoff, since the
# archive is non-authoritative historical overflow, not the live log.
archive_file="${retro_dir}/retrospectives-archive.md"

old_count=$(grep -c '^### ' "$retro_file" || true)

awk \
  -v entry_file="$entry_tmp" \
  -v cap="$ENTRY_CAP" \
  -v archive_file="$archive_file" \
'
BEGIN {
  RS  = ""
  ORS = ""

  while ((getline line < entry_file) > 0)
    new_entry = new_entry (new_entry == "" ? "" : "\n") line
  close(entry_file)
  sub(/[[:space:]]+$/, "", new_entry)

  n      = 0
  suffix = ""
}

{
  para = $0
  sub(/[[:space:]]+$/, "", para)
  if (para == "") next

  if (para ~ /^\#\#\# /)  { entries[++n] = para }
  else if (para ~ /^<!--/) { suffix = para }
}

END {
  # Keep cap-1 old entries so the post-insert count equals cap.
  # The prior implementation used `n--` (single decrement), which kept a
  # file already above cap stuck above cap forever — one prune per
  # insert balanced one insert per call, never converging back down.
  keep = n
  if (keep >= cap) keep = cap - 1

  # Archive the entries that WOULD be dropped (entries[keep+1 .. n]) before
  # truncating the main file, so historical lessons are preserved instead of
  # destroyed. Write a one-time header if the archive does not yet exist.
  if (n > keep) {
    if ((getline _probe < archive_file) < 0) {
      printf "# Retrospectives Archive\n\nEntries pruned from .context/retrospectives.md when it exceeded its cap. Append-only; newest at the bottom. Not loaded into context — read on demand for historical lessons.\n" >> archive_file
    }
    close(archive_file)
    for (i = keep + 1; i <= n; i++) printf "\n%s\n", entries[i] >> archive_file
    close(archive_file)
  }

  printf "%s\n", new_entry
  for (i = 1; i <= keep; i++) printf "\n%s\n", entries[i]
  if (suffix != "") printf "\n%s\n", suffix
}
' "$retro_file" > "$out_tmp"

mv "$out_tmp" "$retro_file"

# ---------- report ----------

new_count=$(grep -c '^### ' "$retro_file" || true)
# pruned = how many entries the awk dropped from the read set.
# Pre-state n; post-write n_kept = min(old_count, cap-1); final count = n_kept + 1.
# So pruned = old_count - (final_count - 1) = old_count + 1 - new_count.
pruned=$(( old_count + 1 - new_count ))
(( pruned < 0 )) && pruned=0

[[ $new_count -eq 1 ]] && entry_word="entry" || entry_word="entries"

if (( pruned > 0 )); then
  [[ $pruned -eq 1 ]] && prune_word="entry" || prune_word="entries"
  echo "Updated ${retro_file}: ${old_count} -> ${new_count} ${entry_word}, pruned ${pruned} oldest ${prune_word} (cap ${ENTRY_CAP})"
else
  echo "Updated ${retro_file}: ${old_count} -> ${new_count} ${entry_word}"
fi
