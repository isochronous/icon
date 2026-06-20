#!/usr/bin/env bash
# Test driver for ICON-0013: verify the fence-aware pre-commit hook handles
# every fixture in ./fixtures/ correctly.
#
# For each fixture, this driver:
#   1. Builds a scratch repo in a tempdir (`git init`, `agents/`, `shared/`).
#   2. Copies `shared/common-constraints.md` and the real hook into place.
#   3. Drops the fixture into `agents/<fixture-name>.agent.md`.
#   4. Runs the hook against that scratch repo.
#   5. Asserts the expected outcome (rewrite happened / no-op / abort).
#
# Exits 0 iff every fixture passes. Prints PASS/FAIL per fixture.
set -uo pipefail

# Resolve script directory and repo root.
script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../../.." && pwd)"
fixtures_dir="$script_dir/fixtures"
source_file="$repo_root/shared/common-constraints.md"
hook_file="$repo_root/.githooks/pre-commit"

if [[ ! -f "$source_file" ]]; then
  echo "FATAL: source file missing: $source_file" >&2
  exit 2
fi
if [[ ! -x "$hook_file" ]]; then
  echo "FATAL: hook not found or not executable: $hook_file" >&2
  exit 2
fi

# Expected outcome per fixture. Outcomes:
#   rewrite  — hook MUST modify the agent file (stale placeholder replaced)
#   noop     — hook MUST exit 0 with the agent file unchanged
#   abort    — hook MUST exit non-zero with an orphan-marker message
declare -A expected=(
  ["01-plain-markers.md"]="rewrite"
  ["02-fenced-only-markers.md"]="noop"
  ["03-mixed.md"]="rewrite"
  ["04-nested-backtick-fences.md"]="noop"
  ["05-indented-fence.md"]="noop"
  ["06-tilde-fence.md"]="noop"
  ["07-fence-with-language-tag.md"]="noop"
  ["08-orphan-outside-fence.md"]="abort"
  ["09-orphan-inside-fence.md"]="noop"
  ["10-stale-content-with-fence.md"]="rewrite"
  ["11-stray-end-before-begin.md"]="abort"
  ["12-single-line-begin-end.md"]="abort"
)

# Ordered fixture list so output is deterministic.
ordered_fixtures=(
  "01-plain-markers.md"
  "02-fenced-only-markers.md"
  "03-mixed.md"
  "04-nested-backtick-fences.md"
  "05-indented-fence.md"
  "06-tilde-fence.md"
  "07-fence-with-language-tag.md"
  "08-orphan-outside-fence.md"
  "09-orphan-inside-fence.md"
  "10-stale-content-with-fence.md"
  "11-stray-end-before-begin.md"
  "12-single-line-begin-end.md"
)

# Fixtures whose `rewrite` outcome must produce a between-markers block that
# is BYTE-IDENTICAL to shared/common-constraints.md. Weaker assertions (only
# checking that the stale placeholder is gone) would pass on corrupted output
# such as "source content + leaked stale fence body" (the in-block fence-leak
# regression class).
declare -A strict_rewrite=(
  ["01-plain-markers.md"]=1
  ["03-mixed.md"]=1
  ["10-stale-content-with-fence.md"]=1
)

src_content="$(cat "$source_file")"

pass_count=0
fail_count=0
fail_details=()

run_fixture() {
  local fixture="$1"
  local want="$2"

  local fixture_path="$fixtures_dir/$fixture"
  if [[ ! -f "$fixture_path" ]]; then
    echo "FAIL  $fixture  (fixture file missing)"
    fail_count=$((fail_count + 1))
    fail_details+=("$fixture: fixture file missing at $fixture_path")
    return
  fi

  local scratch
  scratch="$(mktemp -d)"
  trap 'rm -rf "$scratch"' RETURN

  # Build scratch repo layout.
  mkdir -p "$scratch/agents" "$scratch/shared" "$scratch/.githooks"
  cp "$source_file" "$scratch/shared/common-constraints.md"
  cp "$hook_file" "$scratch/.githooks/pre-commit"
  chmod +x "$scratch/.githooks/pre-commit"

  local agent_name="${fixture%.md}.agent.md"
  local agent_path="$scratch/agents/$agent_name"
  cp "$fixture_path" "$agent_path"

  # Snapshot the agent file before running the hook.
  local before_hash
  before_hash="$(cksum < "$agent_path")"

  # Initialize git so `git rev-parse --show-toplevel` and `git add` work.
  (
    cd "$scratch"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test"
    git add -- "agents/$agent_name" "shared/common-constraints.md"
    # No commit yet; the hook runs against the working tree.
  )

  # Run the hook from within the scratch repo. Capture stdout, stderr, exit.
  local stdout_file stderr_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  local exit_code=0
  (
    cd "$scratch"
    "./.githooks/pre-commit"
  ) > "$stdout_file" 2> "$stderr_file" || exit_code=$?

  local after_hash
  after_hash="$(cksum < "$agent_path")"

  local got
  if (( exit_code != 0 )); then
    got="abort"
  elif [[ "$before_hash" != "$after_hash" ]]; then
    got="rewrite"
  else
    got="noop"
  fi

  # Additional invariants per outcome:
  local detail=""
  if [[ "$want" == "rewrite" && "$got" == "rewrite" ]]; then
    # Confirm the actual source block is present and the stale placeholder is gone.
    if ! grep -qF "STALE PLACEHOLDER" "$agent_path"; then
      # Source content first non-empty line must appear in the rewritten file.
      local first_src_line
      first_src_line="$(head -n1 "$source_file")"
      if grep -qF "$first_src_line" "$agent_path"; then
        :  # ok
      else
        got="rewrite-but-source-missing"
        detail="rewrite happened but source content not found in agent file"
      fi
    else
      got="rewrite-but-placeholder-remains"
      detail="rewrite happened but stale placeholder still present"
    fi

    # Strict mode: if this fixture is in `strict_rewrite`, extract the
    # between-markers block (exclusive of the markers themselves) and assert
    # it is BYTE-IDENTICAL to shared/common-constraints.md. Guards against
    # corrupted-output regressions where source content is followed by leaked
    # stale lines (e.g. a fence body that escaped the in-block drop).
    if [[ "$got" == "rewrite" && -n "${strict_rewrite[$fixture]:-}" ]]; then
      local extracted
      extracted="$(mktemp)"
      # Extractor mirrors the hook: only markers OUTSIDE a fenced code block
      # delimit the real block. Without this, an illustrative `<!-- BEGIN ... -->`
      # inside a fence (e.g. fixture 03) is mistaken for the real BEGIN.
      awk '
        BEGIN {
          in_block = 0
          inside_fence = 0
          fence_char = ""
          fence_len = 0
        }
        {
          line = $0
          stripped = line
          if (substr(stripped, 1, 1) == " ") {
            sub(/^ {1,3}/, "", stripped)
          }
          first = substr(stripped, 1, 1)
          is_fence = 0
          if (first == "`" || first == "~") {
            n = length(stripped); i = 1
            while (i <= n && substr(stripped, i, 1) == first) { i++ }
            run = i - 1
            if (run >= 3) {
              rest = substr(stripped, i)
              tmp = rest
              sub(/[ \t]+$/, "", tmp); sub(/^[ \t]+/, "", tmp)
              has_info = (tmp == "" ? 0 : 1)
              if (inside_fence == 0) {
                is_fence = 1; this_char = first; this_len = run
              } else if (first == fence_char && run >= fence_len && has_info == 0) {
                is_fence = 1; this_char = first; this_len = run
              }
            }
          }
          if (is_fence) {
            if (inside_fence == 0) {
              inside_fence = 1; fence_char = this_char; fence_len = this_len
            } else {
              inside_fence = 0; fence_char = ""; fence_len = 0
            }
            next
          }
          if (inside_fence == 0) {
            if (index(line, "<!-- BEGIN: common-constraints -->") > 0) {
              in_block = 1; next
            }
            if (index(line, "<!-- END: common-constraints -->") > 0) {
              in_block = 0; next
            }
          }
          if (in_block == 1) print line
        }
      ' "$agent_path" > "$extracted"
      if ! cmp -s "$extracted" "$source_file"; then
        got="rewrite-but-block-not-byte-equal"
        detail="block between markers differs from shared/common-constraints.md"
        # Capture a short diff hint for the failure report.
        local diff_hint
        diff_hint="$(diff "$source_file" "$extracted" | head -n 8 | tr '\n' '|')"
        detail="$detail — diff (source vs extracted, first 8 lines): $diff_hint"
      fi
      rm -f "$extracted"
    fi
  fi
  if [[ "$want" == "abort" && "$got" == "abort" ]]; then
    if ! grep -qE "orphan|BEGIN|END" "$stderr_file"; then
      detail="abort happened but stderr did not mention orphan/BEGIN/END"
      got="abort-but-wrong-message"
    fi
  fi

  if [[ "$want" == "$got" ]]; then
    echo "PASS  $fixture  ($want)"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL  $fixture  (expected: $want, got: $got)"
    fail_count=$((fail_count + 1))
    fail_details+=("$fixture: expected=$want got=$got${detail:+ ($detail)}")
    fail_details+=("  stdout: $(tr '\n' '|' < "$stdout_file")")
    fail_details+=("  stderr: $(tr '\n' '|' < "$stderr_file")")
  fi

  rm -f "$stdout_file" "$stderr_file"
  # `trap RETURN` cleans up $scratch
}

echo "=== ICON-0013 fence-aware pre-commit hook test driver ==="
echo "Hook:    $hook_file"
echo "Source:  $source_file"
echo "Fixtures: $fixtures_dir"
echo

for fixture in "${ordered_fixtures[@]}"; do
  run_fixture "$fixture" "${expected[$fixture]}"
done

echo
echo "=== Summary: $pass_count passed, $fail_count failed ==="
if (( fail_count > 0 )); then
  echo
  echo "Failure details:"
  for line in "${fail_details[@]}"; do
    echo "  $line"
  done
  exit 1
fi
exit 0
