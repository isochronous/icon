#!/usr/bin/env bash
# ============================================================
# context-graph.sh — .context/ knowledge-graph parser (ICON-0081)
# ============================================================
# Parses a `.context/` tree ONCE and either:
#   --emit  (default) : prints a compact adjacency listing to stdout
#                       (# NODES then # EDGES; paths + edge tags ONLY,
#                        never file contents).
#   --check           : reports structural defects (dangling references,
#                       orphan/unreachable content docs) to stderr with a
#                       fail-closed 0/1/2 exit contract.
#
# This generalizes check-rules-index.sh's forward+backward checks from the
# three rule directories to the whole `.context/` graph. It DELEGATES
# rules-index completeness/backward-resolution to check-rules-index.sh
# (disjoint edge ownership, design §8.2): rules-index rows are ingested as
# reachability edges only — never emitted as dangling-ref violations here.
#
# Node/edge model: design.md §1 (CLOSED sets). Exit contract: design §8.1.
# Escape hatches: design §8.4. PowerShell parity: context-graph.ps1 (§8.5).
#
# Read-only: never writes, deletes, or stages. Diagnostics go to stderr.
# No 2>/dev/null suppression (ADR-007). Pure-bash parsing, no gawk-only awk
# and no `if grep` control flow (shell-portability Rules 1-4; ADR-004).
#
# Usage:  context-graph.sh [--emit|--check] [--include-tasks] [context_root]
#   context_root  A directory that IS a `.context/` tree, OR a repo root that
#                 CONTAINS a `.context/` dir. Defaults to the git toplevel.
#   --include-tasks  Include tasks/*/plan.md nodes (excluded by default).
#
# Exit (BOTH modes honor the fail-closed contract — safe as `… || exit 1`):
#   0 = parsed cleanly, no violations (--check prints a one-line OK)
#   1 = parsed cleanly, violations found (--check only; all listed on stderr)
#   2 = parser / environment error — missing/unreadable tree, unreadable file,
#       OR zero nodes discovered (never conflated with "clean")
set -euo pipefail

# ------------------------------------------------------------
# Parse arguments
# ------------------------------------------------------------
mode="emit"
include_tasks=0
root_arg=""
for a in "$@"; do
  case "$a" in
    --emit)          mode="emit" ;;
    --check)         mode="check" ;;
    --include-tasks) include_tasks=1 ;;
    --) ;;
    -*) echo "[context-graph] error: unknown flag: $a" >&2; exit 2 ;;
    *)  root_arg="$a" ;;
  esac
done

# ------------------------------------------------------------
# Resolve the context directory
#   - arg is the .context/ tree itself, OR a repo root containing .context/
# ------------------------------------------------------------
if [[ -n "$root_arg" ]]; then
  base="$root_arg"
else
  base="$(git rev-parse --show-toplevel)"
fi

if [[ -d "$base/.context" ]]; then
  context_dir="$base/.context"
else
  context_dir="$base"
fi

if [[ ! -d "$context_dir" ]]; then
  echo "[context-graph] error: context tree not found: $context_dir" >&2
  exit 2
fi

# ------------------------------------------------------------
# Scratch accumulators (portable to bash 3.2 — no associative arrays)
# ------------------------------------------------------------
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
: > "$tmp/nodes"        # one node rel-path per line
: > "$tmp/edges"        # edgetype<TAB>source<TAB>target
: > "$tmp/reachable"    # rel-paths reachable via an in-edge / index row
: > "$tmp/content"      # content-doc rel-paths (subject to orphan check)
: > "$tmp/orphanok"     # rel-paths carrying <!-- context-graph:orphan-ok -->
: > "$tmp/dangling"     # edgetype<TAB>source<TAB>target (unresolved)

# in_set <item> <file>  — fixed-string, whole-line membership (-e guards a
# leading '-' in the item; never an `if grep` on derived control flow).
in_set() { grep -Fxq -e "$1" "$2"; }

# ------------------------------------------------------------
# classify <relpath> -> prints node kind, or nothing if not a node
#   content kinds: domain standard workflow decision architecture testing styling
#   non-content nodes: overview projects rules-index folder-index config
#                      retrospective task
# ------------------------------------------------------------
classify() {
  local rel="$1"
  case "$rel" in
    overview.md)          echo overview ;;
    projects.md)          echo projects ;;
    rules-index.md)       echo rules-index ;;
    iconrc.json)          echo config ;;
    retrospectives.md)    echo retrospective ;;
    tasks/*/plan.md)      if [[ "$include_tasks" -eq 1 ]]; then echo task; fi ;;
    tasks/*)              : ;;   # other task-subtree files are never graph nodes
    README.md|*/README.md) echo folder-index ;;
    decisions/[0-9]*.md)  echo decision ;;
    decisions/*.md)       echo decision ;;
    domains/*.md)         echo domain ;;
    standards/*.md)       echo standard ;;
    workflows/*.md)       echo workflow ;;
    architecture/*.md)    echo architecture ;;
    testing/*.md)         echo testing ;;
    styling/*.md)         echo styling ;;
    *) : ;;
  esac
  return 0
}

is_content_kind() {
  case "$1" in
    domain|standard|workflow|decision|architecture|testing|styling) return 0 ;;
    *) return 1 ;;
  esac
}

# ------------------------------------------------------------
# All hot-path helpers set a global (NORM_OUT / CLEAN_OUT / ADR_OUT) instead
# of echoing, so parsing spawns ZERO subprocesses per line/link — pure-bash
# parsing (shell-portability Rules 1-2) that is also fast on Git-Bash, where
# fork+exec is expensive.
# ------------------------------------------------------------

# normalize_rel <combined-path> -> NORM_OUT = path relative to context root,
#   or "" if it escapes the context root (path-traversal safety, §4).
normalize_rel() {
  local combined="${1#/}"             # tolerate a leading slash
  local IFS='/'
  # shellcheck disable=SC2206
  local parts=($combined)
  local stack=() p
  NORM_OUT=""
  for p in "${parts[@]}"; do
    case "$p" in
      ''|'.') continue ;;
      '..')
        [[ ${#stack[@]} -eq 0 ]] && return   # escapes root -> drop (NORM_OUT="")
        unset 'stack[${#stack[@]}-1]' ;;
      *) stack+=("$p") ;;
    esac
  done
  local out="" s
  for s in "${stack[@]:-}"; do
    [[ -z "$s" ]] && continue
    out="${out:+$out/}$s"
  done
  NORM_OUT="$out"
  return 0
}

# clean_target <raw> -> CLEAN_OUT = target minus anchor/title, or "" if the
# target is an external/anchor-only scheme to skip. Always returns 0 (it is
# called directly under set -e, so a leaked non-zero must not abort parsing).
clean_target() {
  local t="$1"
  CLEAN_OUT=""
  t="${t%%#*}"                        # drop #anchor
  t="${t%% *}"                        # drop " \"title\"" suffix
  if [[ -n "$t" ]]; then
    case "$t" in
      *://*|//*|mailto:*|tel:*|'#'*) : ;;      # external / anchor-only -> skip
      *) CLEAN_OUT="$t" ;;
    esac
  fi
  return 0
}

# record a resolved-under-context link.
#   $1 edgetype  $2 sourcefile-rel  $3 resolved-target-rel  $4 in_deadref(0/1)
record_link_edge() {
  local etype="$1" src="$2" tgt="$3" deadref="$4"
  case "$etype" in
    indexed-by)
      # rule-file -> rules-index (design direction). Reachability flows to the
      # rule file. Delegated to check-rules-index.sh: never dangling-flagged.
      printf '%s\t%s\t%s\n' "indexed-by" "$tgt" "$src" >> "$tmp/edges"
      printf '%s\n' "$tgt" >> "$tmp/reachable"
      ;;
    covers|references)
      printf '%s\t%s\t%s\n' "$etype" "$src" "$tgt" >> "$tmp/edges"
      printf '%s\n' "$tgt" >> "$tmp/reachable"
      if [[ "$deadref" -eq 0 && ! -e "$context_dir/$tgt" ]]; then
        printf '%s\t%s\t%s\n' "$etype" "$src" "$tgt" >> "$tmp/dangling"
      fi
      ;;
  esac
  return 0
}

# resolve_adr <NNN> -> ADR_OUT = decisions/<NNN>-*.md rel-path if it exists,
# else "" (glob only; no subprocess).
resolve_adr() {
  local num="$1" m
  ADR_OUT=""
  shopt -s nullglob
  for m in "$context_dir"/decisions/"$num"-*.md; do
    ADR_OUT="decisions/${m##*/}"
    break
  done
  shopt -u nullglob
}

# ------------------------------------------------------------
# parse_file <relpath> <kind> — extract edges + reachability signals.
# ------------------------------------------------------------
parse_file() {
  local rel="$1" kind="$2"
  local abs="$context_dir/$rel"
  if [[ ! -r "$abs" ]]; then
    echo "[context-graph] error: unreadable node file: $rel" >&2
    exit 2
  fi

  local srcdir; srcdir="$(dirname "$rel")"; [[ "$srcdir" == "." ]] && srcdir=""

  local link_type="references"
  case "$rel" in
    rules-index.md)        link_type="indexed-by" ;;
    README.md|*/README.md) link_type="covers" ;;
    projects.md)           link_type="covers" ;;
  esac

  local in_fence=0 in_deadref=0
  local line had_end
  while IFS= read -r line || [[ -n "$line" ]]; do
    # fenced code block toggle (```lang or ~~~), fence-aware like the hook.
    if [[ "$line" =~ ^[[:space:]]*(\`\`\`|~~~) ]]; then
      in_fence=$((1 - in_fence)); continue
    fi

    # file-level orphan-ok marker (honored anywhere in the file, even in a fence
    # it would still be a comment — but we only see it outside fences here).
    if [[ "$line" == *'<!-- context-graph:orphan-ok -->'* ]]; then
      printf '%s\n' "$rel" >> "$tmp/orphanok"
    fi

    # dead-ref-ok region markers (reused from the pre-commit idiom, §8.4).
    had_end=0
    [[ "$line" == *'dead-ref-ok-start'* ]] && in_deadref=1
    [[ "$line" == *'dead-ref-ok-end'*   ]] && had_end=1

    if [[ "$in_fence" -eq 0 ]]; then
      # --- config: iconrc excludes globs ---
      if [[ "$kind" == "config" && "$line" == *'"excludes"'* ]]; then
        local arr="${line#*[}"; arr="${arr%%]*}"
        local IFS=','; local tok
        for tok in $arr; do
          tok="${tok//\"/}"; tok="${tok// /}"
          [[ -z "$tok" ]] && continue
          printf '%s\t%s\t%s\n' "excludes" "iconrc.json" "$tok" >> "$tmp/edges"
        done
        unset IFS
      fi

      # --- Markdown links [text](target) — pure-bash, multiple per line ---
      local rest="$line" raw
      while [[ "$rest" =~ \]\(([^\)]+)\)(.*) ]]; do
        raw="${BASH_REMATCH[1]}"
        rest="${BASH_REMATCH[2]}"
        clean_target "$raw"
        [[ -z "$CLEAN_OUT" ]] && continue
        normalize_rel "${srcdir:+$srcdir/}$CLEAN_OUT"
        [[ -z "$NORM_OUT" ]] && continue           # escaped context root -> drop
        record_link_edge "$link_type" "$rel" "$NORM_OUT" "$in_deadref"
        # A rules-index File-column row that targets a DIRECTORY indexes each
        # direct-child .md (design §9.1). Emit a covers edge to each so the
        # children get an in-edge — matching check-rules-index.sh's parent-row
        # granularity (direct children only, non-recursive).
        if [[ "$link_type" == "indexed-by" && -d "$context_dir/$NORM_OUT" ]]; then
          local child crel
          shopt -s nullglob
          for child in "$context_dir/$NORM_OUT"/*.md; do
            crel="${child#"$context_dir"/}"
            printf '%s\t%s\t%s\n' "covers" "rules-index.md" "$crel" >> "$tmp/edges"
            printf '%s\n' "$crel" >> "$tmp/reachable"
          done
          shopt -u nullglob
        fi
      done

      # --- decision supersede seams (bold-fields + legacy Status prose) ---
      if [[ "$kind" == "decision" ]]; then
        local sline num
        if [[ "$line" =~ ^\*\*Supersedes\*\*: ]]; then
          sline="$line"
          while [[ "$sline" =~ ADR-([0-9]+)(.*) ]]; do
            num="${BASH_REMATCH[1]}"; sline="${BASH_REMATCH[2]}"
            resolve_adr "$num"
            if [[ -n "$ADR_OUT" ]]; then
              printf '%s\t%s\t%s\n' "supersedes" "$rel" "$ADR_OUT" >> "$tmp/edges"
              printf '%s\n' "$ADR_OUT" >> "$tmp/reachable"
            elif [[ "$in_deadref" -eq 0 ]]; then
              printf '%s\t%s\t%s\n' "supersedes" "$rel" "decisions/${num}-*.md" >> "$tmp/dangling"
            fi
          done
        fi
        if [[ "$line" =~ ^\*\*Superseded-by\*\*: ]] \
           || [[ "$line" =~ ^\*\*Status\*\*:.*Superseded\ by\ ADR-[0-9] ]]; then
          sline="$line"
          while [[ "$sline" =~ ADR-([0-9]+)(.*) ]]; do
            num="${BASH_REMATCH[1]}"; sline="${BASH_REMATCH[2]}"
            resolve_adr "$num"
            if [[ -n "$ADR_OUT" ]]; then
              printf '%s\t%s\t%s\n' "superseded-by" "$rel" "$ADR_OUT" >> "$tmp/edges"
              printf '%s\n' "$ADR_OUT" >> "$tmp/reachable"
            elif [[ "$in_deadref" -eq 0 ]]; then
              printf '%s\t%s\t%s\n' "superseded-by" "$rel" "decisions/${num}-*.md" >> "$tmp/dangling"
            fi
          done
        fi
      fi

      # --- retrospective promotion provenance (Promoted to: <link|path>) ---
      if [[ "$kind" == "retrospective" && "$line" =~ [Pp]romoted\ to:[[:space:]]*(.+)$ ]]; then
        local ptail="${BASH_REMATCH[1]}" praw=""
        if [[ "$ptail" =~ \]\(([^\)]+)\) ]]; then
          praw="${BASH_REMATCH[1]}"
        elif [[ "$ptail" =~ ([A-Za-z0-9_./-]+\.md) ]]; then
          praw="${BASH_REMATCH[1]}"
        fi
        if [[ -n "$praw" ]]; then
          clean_target "$praw"
          if [[ -n "$CLEAN_OUT" ]]; then
            normalize_rel "$CLEAN_OUT"            # retro paths are context-root-relative
            if [[ -n "$NORM_OUT" ]]; then
              printf '%s\t%s\t%s\n' "promoted-from" "$rel" "$NORM_OUT" >> "$tmp/edges"
              printf '%s\n' "$NORM_OUT" >> "$tmp/reachable"
            fi
          fi
        fi
      fi
    fi

    [[ "$had_end" -eq 1 ]] && in_deadref=0
  done < "$abs"
  return 0
}

# ------------------------------------------------------------
# Discover nodes, then parse each once.
# ------------------------------------------------------------
while IFS= read -r abs; do
  rel="${abs#"$context_dir"/}"
  kind="$(classify "$rel")"
  [[ -z "$kind" ]] && continue
  printf '%s\n' "$rel" >> "$tmp/nodes"
  if is_content_kind "$kind"; then printf '%s\n' "$rel" >> "$tmp/content"; fi
done < <(find "$context_dir" -type f \( -name '*.md' -o -name 'iconrc.json' \) | LC_ALL=C sort)

# Parse each node (kind recomputed; find order already applied above).
while IFS= read -r rel; do
  parse_file "$rel" "$(classify "$rel")"
done < "$tmp/nodes"

# ------------------------------------------------------------
# Fail-closed guard: zero nodes on an existing tree is a parser error,
# never a clean pass (design §8.1 — closes the mawk empty-output hole).
# ------------------------------------------------------------
node_count="$(grep -c . "$tmp/nodes" || true)"
if [[ "${node_count:-0}" -eq 0 ]]; then
  echo "[context-graph] error: zero nodes discovered under $context_dir" >&2
  echo "  (a populated .context/ tree must yield >=1 node; refusing to report clean)" >&2
  exit 2
fi

# ------------------------------------------------------------
# EMIT mode — adjacency listing to stdout.
# ------------------------------------------------------------
if [[ "$mode" == "emit" ]]; then
  echo "# NODES"
  LC_ALL=C sort -u "$tmp/nodes"
  echo "# EDGES"
  LC_ALL=C sort -u "$tmp/edges"
  exit 0
fi

# ------------------------------------------------------------
# CHECK mode — dangling refs + orphan content docs. Accumulate, then report.
# ------------------------------------------------------------
fail=0

# Roots are always reachable.
for r in overview.md projects.md rules-index.md; do
  printf '%s\n' "$r" >> "$tmp/reachable"
done

# Orphan content docs: content doc, not reachable, not orphan-ok.
: > "$tmp/orphans"
while IFS= read -r rel; do
  [[ -z "$rel" ]] && continue
  in_set "$rel" "$tmp/reachable"  && continue
  in_set "$rel" "$tmp/orphanok"   && continue
  printf '%s\n' "$rel" >> "$tmp/orphans"
done < "$tmp/content"

if [[ -s "$tmp/dangling" ]]; then
  fail=1
  echo "[context-graph] error: dangling reference(s) - link target not found on disk:" >&2
  while IFS=$'\t' read -r etype src tgt; do
    echo "  [$etype] $src -> $tgt (not found under .context/)" >&2
  done < <(LC_ALL=C sort -u "$tmp/dangling")
  echo "  fix: repoint the link, add the target, or wrap an intentional gap in" >&2
  echo "       <!-- pre-commit:dead-ref-ok-start --> ... <!-- pre-commit:dead-ref-ok-end -->" >&2
fi

if [[ -s "$tmp/orphans" ]]; then
  fail=1
  echo "[context-graph] error: orphan/unreachable content doc(s) - no in-edge and not a root:" >&2
  while IFS= read -r rel; do
    echo "  $rel (nothing links, covers, or indexes it)" >&2
  done < <(LC_ALL=C sort -u "$tmp/orphans")
  echo "  fix: link it from a related doc (a ## Related entry), index it, or mark an" >&2
  echo "       intentional stub with a file-level <!-- context-graph:orphan-ok --> comment" >&2
fi

if [[ "$fail" -eq 1 ]]; then
  exit 1
fi

echo "[context-graph] OK: $node_count nodes, no dangling references, no orphans"
exit 0
