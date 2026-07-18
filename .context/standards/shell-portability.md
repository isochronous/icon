# Shell Portability for Shipped Skills

Bash code shipped inside a `skills/*/SKILL.md` (or installed via `.claude-plugin/`) runs in the consumer's environment, not the maintainer's. Debian, Ubuntu, WSL, and Alpine all ship **mawk** as the default `awk`, not gawk. Code that compiles on a maintainer's gawk-equipped Mac can silently produce zero output — or silently delete files — on every consumer machine in the field.

## Rules

### 1. No gawk extensions in awk blocks

Two extensions are forbidden because mawk 1.3.x does not implement them:

- **3-argument `match()`** — `match($0, /regex/, arr)` with a capture-group array is gawk-only. Use `match($0, /regex/)` + `RSTART`/`RLENGTH` + `substr()`, or move parsing into bash with `[[ ... =~ ... ]]` + `${BASH_REMATCH[N]}`.
- **`printf -v <var>`** — bash builtin syntax, not awk. Awk's `printf` has no `-v` flag. For variable assignment, do it in the shell layer.

### 2. Prefer pure bash for non-trivial parsing

When awk's pattern-action structure is not pulling its weight — multi-step capture, variable mutation, or conditional branching — prefer pure bash (`while IFS= read -r`, `[[ =~ ]]`, `BASH_REMATCH`). Simpler, more portable, and easier to live-test than an awk block embedded in a markdown fenced code block.

### 3. Live-test shell blocks that write or delete files

Any shipped shell snippet that writes, renames, or deletes files must be live-tested against the platform-default toolchain before merge. Diff-reading is not sufficient — mawk failures produce empty output with exit 0, invisible to reviewers.

### 4. `grep` with a pattern that can start with `-`: pass `-e`, and don't trust an `if grep` guard

A regex or string whose first character is `-` (e.g. a PEM header `-----BEGIN`) is parsed by `grep` as options, not a pattern — `grep` exits 2 with "unrecognized option". When wrapped in `if … | grep -Eq …`, the `if` reads grep's exit-2 *error* as "no match" and falls through silently — the check fails **OPEN**: it looks like it works but never fires. For a security gate (secret-scan, etc.) this is a silently-disabled control. Two rules: (a) whenever a pattern can begin with `-`, use `grep -e <pat>` (or `--`) to force end-of-options; (b) an `if grep` guard masks grep's own errors, so a malformed pattern fails silently — test every pattern against a known-positive fixture (the contents-not-exit-code discipline of Rule 3 applied to match logic). Applies to all ICON shell — `.githooks/pre-commit`, the retrospective scripts, `check-rules-index.sh` — not just shipped skill blocks. (ICON-0075: the `pem-private-key` secret-scan pattern would have NEVER fired until fixed to `grep -Eq -e "$re"`.)

### 5. Use `${VAR+x}` for presence tests, not `${VAR:-fallback}`

`${VAR+x}` is a POSIX **presence test**: it expands to `x` when `VAR` is set (even if set-but-empty) and to empty string when `VAR` is unset. Use it — e.g. `[ -z "${VAR+x}" ]` (unset) / `[ -n "${VAR+x}" ]` (set) — whenever distinguishing "unset" from "set-but-empty" is load-bearing (e.g. credential-presence checks in generated shell).

`${VAR:-literal}` is a **fallback substitution**, not a presence test: it yields `literal` only when `VAR` is unset *or* empty, so an empty-but-set variable silently defeats a presence check written with it.

This is the rule the `icon-init` MCP-onboarding gate and `icon-status` credential check rely on — a `${VAR:-…}` there would misreport an empty-but-set token as "set".

### 6. PowerShell `-replace` inside a .NET method-call argument list: parenthesize it

Inside a .NET method call's argument list, PowerShell parses the two commas of a `-replace 'pattern','replacement'` expression as **method-argument separators**, not as part of the `-replace` operator. So this passes `TryParse` the wrong number of arguments:

```powershell
[int]::TryParse((Get-Content $f -replace '\D',''), [ref]$n)   # BROKEN
```

PowerShell reads it as `TryParse(<arg1>, <arg2>, <arg3>)` — `<arg1>` is `(Get-Content $f -replace '\D'`, `<arg2>` is `''`, `<arg3>` is `[ref]$n` — the wrong arity, which throws under `Set-StrictMode` / `$ErrorActionPreference='Stop'`. Wrap the `-replace` expression in its **own** parentheses so its commas are contained within the operand, not the argument list:

```powershell
[int]::TryParse(((Get-Content $f) -replace '\D',''), [ref]$n)   # correct
```

(ICON-0082: a persisted-`Attempts` parse in the PowerShell phase-launcher template silently broke the same bounded-retry guarantee in PS mode until the `-replace` was wrapped in its own parentheses `((… -replace '\D',''))`.)

## Testing Pattern

1. Create a temp directory (`mktemp -d`; pair with `trap 'rm -rf "$tmpdir"' EXIT`).
2. Write a fixture file covering all edge cases: valid blocks, malformed headers, whitespace-only preambles, special characters.
3. Extract the shell block from the SKILL.md markdown via an awk sweep on the fenced ` ```bash ` … ` ``` ` markers.
4. Run the extracted shell against the fixture.
5. Inspect each expected output file's **contents** — not just exit code, and not just file existence.

Step 5 is the critical difference: `mawk + gawk extension` exits 0 with zero bytes written; a contents check catches it, an existence check does not.

## Pattern Observed — ICON-0040

A first-pass coder migrated a file-splitting routine using `match($0, /regex/, arr)` (3-arg gawk extension) and `printf -v` (bash builtin) inside an awk block. On mawk 1.3.4 both silently fail: the awk block emits zero output files while the surrounding bash keeps executing — including a `git rm .context/decisions.md` that would have run unconditionally, destroying consumer data. Invisible to diff-reading, it would have shipped silently to every consumer on Debian, Ubuntu, WSL, and Alpine. The reviewer caught it by live-running the extracted block against a fixture on mawk before approving. The fix replaced the gawk-only awk block with pure bash `BASH_REMATCH` parsing — simpler, portable, and verifiable in the same live-fixture loop.
