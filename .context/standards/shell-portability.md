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

### 7. `grep -P`/`-oP` (PCRE mode) is a GNU extension — triage before swapping the flag

`-P` enables Perl-compatible regex matching in GNU `grep`. BSD/macOS `grep` and busybox `grep` do not implement it at all — they exit with "invalid option -- P" (or an "unsupported" error), so a shipped skill that hardcodes `-P`/`-oP` breaks outright on those platforms, not just subtly. The trap is that the fix is **not a uniform flag swap**: which fix applies depends on what the pattern actually uses. Before touching the flag, scan the pattern for `\d`, `\w`, `\s`, `\K`, a lookaround (`(?=`, `(?!`, `(?<=`, `(?<!`), or a lazy quantifier (`+?`, `*?`), and route to one of three fixes:

- **No PCRE-only feature present** — the pattern only used `-P` incidentally; `-oP` → `-oE` is behavior-identical. Example: `grep -oP '"[^"]+\.csproj"'` has no PCRE shorthand, so swapping to `grep -oE '"[^"]+\.csproj"'` changes nothing about what matches.
- **`\d`/`\w`/`\s` shorthand present, no `\K`/lookaround/lazy quantifier** — a bare flag swap **silently changes the meaning**. POSIX ERE has no backslash-digit escapes: outside a bracket expression, `\d` is an escaped literal `d` (matches the letter "d", not a digit). Inside a bracket expression — as in this rule's own example, `[\d.]+` — POSIX gives backslash **no special meaning at all**, so `[\d.]` is a three-member set of literal characters `\`, `d`, and `.`; it matches any one of those three characters, not "digit or dot". The pattern must be translated, not just re-flagged: `\d` → `[0-9]`, `\w` → `[A-Za-z0-9_]`, `\s` → `[[:space:]]`, then run under `-E`. Example: `grep -oP '[\d.]+'` must become `grep -oE '[0-9.]+'`, not `grep -oE '[\d.]+'` — run against `  "version": "1.12",`, the untranslated set `{\, d, .}` matches only the `.`, printing `.` instead of the version number.
- **`\K`, a lookaround, or a lazy quantifier present** — POSIX ERE has **no equivalent** for any of these; no flag swap or translation can preserve the pattern's behavior in `grep -E`. Move the extraction to a different tool: a `sed` capture group with `-n … p` to filter to only matching lines (`sed -n 's/^TICKET-\([0-9][0-9]*\).*/\1/p'`), or `grep -oE` the whole token followed by a separate strip step. Example: `grep -oP 'TICKET-\K[0-9]+'` (matches digits *after* a `TICKET-` prefix without including the prefix in the output) has no ERE form — replace it with a `sed -n '...p'` capture group instead of attempting `grep -oE`.

```bash
grep -oP '[\d.]+'                          # BROKEN: -oP unsupported on BSD/busybox
grep -oE '[\d.]+'                          # BROKEN: flag-only swap; inside [...] backslash is literal, set is {\,d,.} — matches only "."
grep -oE '[0-9.]+'                         # correct: shorthand translated, then re-flagged

grep -oP 'TICKET-\K[0-9]+'                 # BROKEN: -oP unsupported; \K has no ERE form at all
sed -n 's/^TICKET-\([0-9][0-9]*\).*/\1/p'  # correct: extraction moved to a capture group, -n/p filters non-matching lines
```

This rule is distinct from Rule 4: Rule 4 covers a pattern that can *start with `-`* being misparsed as an option regardless of engine. This rule covers a pattern that relies on *PCRE-only syntax* being unsupported by non-GNU `grep` regardless of where it starts. A pattern can trigger either, both, or neither — check each independently. (ICON-0093: `grep -oP` with no PCRE feature in `skills/initialize-monorepo/SKILL.md`, `grep -oP '[\d.]+'` in `skills/upgrade-repo/SKILL.md`, and `grep -oP 'MKT-\K[0-9]+'` in `context_template/context/workflows/commit-conventions.md` were three different shapes of the same unnamed gap — each needed a different fix.)

### 8. `sed -i` requires an explicit backup-suffix argument for BSD/macOS compatibility

GNU `sed -i` treats the backup suffix as **optional** — `sed -i 's/foo/bar/' file` edits in place with no backup. BSD/macOS `sed -i` treats the suffix as **mandatory**: it consumes whatever token comes next as that suffix. Given the identical invocation `sed -i "s/foo/bar/" file`, BSD/macOS `sed` reads `"s/foo/bar/"` as the backup-suffix argument and `file` as the script, which is not valid `sed` syntax and errors out (typically "command garbled" or "unterminated address regex") rather than editing anything.

```bash
sed -i "s/foo/bar/" file        # BROKEN on BSD/macOS: consumes the script as the suffix, errors
sed -i.bak "s/foo/bar/" file    # correct everywhere — but leaves file.bak behind
```

Two portable forms, with a tradeoff between them:

- **`sed -i.bak "s/…/…/" file`** — works identically on GNU and BSD because the suffix is always explicit. Simple, but leaves a stray `file.bak` in the consumer's working tree that the skill must remember to clean up (or that pollutes `git status`).
- **Temp file + `mv`** — `sed "s/…/…/" file > file.tmp && mv file.tmp file || { rm -f file.tmp; exit 1; }` — avoids `-i` entirely, so the GNU/BSD divergence never applies, and leaves no backup artifact **provided the trailing cleanup runs**. Slightly more verbose, and the `mv` must be conditional on the `sed` succeeding (`&&`, not a separate statement): the redirect only ever writes to `file.tmp`, never to `file` itself, so a failed `sed` cannot truncate the original — but it can leave a partial or empty `file.tmp` behind, and without `&&` a following unconditional `mv` would overwrite the good original with that broken temp file. The bare `&&` form stops there: on failure it leaves that `file.tmp` sitting in the consumer's working tree. The trailing `|| { rm -f file.tmp; exit 1; }` is what actually removes it and preserves the failure — without it, "leaves no backup artifact" is false on the failure path. **Do not shorten this to `|| rm -f file.tmp`**: that is the obvious-looking fix, but `rm -f` itself succeeds (with or without a file to remove), so its exit status becomes the whole list's status and the construct exits 0 even though the `sed` failed and the edit never happened — under `set -euo pipefail` (how every shipped `.sh` in this repo runs), the script then continues past the failed edit as if it had succeeded.

(ICON-0093: `sed -i "s/…/…/" .context/iconrc.json` in `skills/upgrade-repo/SKILL.md` used the no-suffix GNU-only form.)

## Testing Pattern

1. Create a temp directory (`mktemp -d`; pair with `trap 'rm -rf "$tmpdir"' EXIT`).
2. Write a fixture file covering all edge cases: valid blocks, malformed headers, whitespace-only preambles, special characters.
3. Extract the shell block from the SKILL.md markdown via an awk sweep on the fenced ` ```bash ` … ` ``` ` markers.
4. Run the extracted shell against the fixture.
5. Inspect each expected output file's **contents** — not just exit code, and not just file existence.

Step 5 is the critical difference: `mawk + gawk extension` exits 0 with zero bytes written; a contents check catches it, an existence check does not.

**This procedure applies to a fix, and to any idiom this document prescribes for others to copy — not just the code being replaced.** A corrected portability defect is a hypothesis about correct behavior, not a verified one, until it runs in the exact form printed. Rule 8's own `|| rm -f file.tmp` cleanup fence shipped for a full review round before a reviewer copied it out of the document and ran it — only then did it surface that `rm -f` succeeds whether or not the guarded command failed, so the construct exits 0 under `set -euo pipefail` even when the edit never happened. Reading a fix for correctness, or reading a rule's own illustrative fence, is not a substitute for running it.

**Passing this procedure can still ship the wrong failure mode.** Correcting a portability defect on one platform can silently trade a loud failure for a quiet one on another, and a quiet failure is worse: it looks identical to success under CI plus a single manual spot-check. The `mktemp -p DIR .retro_tmp_XXXXXX.md` case is the worked example — two independent defects stacked at the same call site:

```bash
mktemp -p "$dir" .retro_tmp_XXXXXX.md               # BROKEN everywhere, two different ways:
                                                      #  - macOS <=13.x / FreeBSD <13.2: "illegal option -- p" (-p not yet implemented) — LOUD
                                                      #  - macOS 14+ / FreeBSD 13.2+: -p resolves fine, but the X's are mid-string so
                                                      #    mkstemp() substitutes zero of them — every call returns the same literal
                                                      #    filename, exit 0, uniqueness silently gone — QUIET
CDPATH= cd -- "$dir" && mktemp .retro_tmp_XXXXXX     # correct: no -p version dependency, and the X's are trailing so mkstemp()
                                                      # substitutes them as intended
```

Fixing only the loud half (swap in `-p` and stop) moves every consumer on a current macOS/FreeBSD straight into the quiet half, and that migration looks like progress: the old hard error is gone, Linux CI stays green, and a one-off manual test on a current machine finds nothing wrong. When correcting a portability defect, verify what the *new* failure mode is on each target platform the fix touches — not merely that the old error stopped reproducing.

(ICON-0093: three consecutive review rounds each ran a prescribed fix, or this document's own printed idiom, for the first time — and each run found a defect the previous round's remediation had introduced or missed.)

**PowerShell's non-terminating-error model is a fail-open generator with three shapes (ICON-0094)**: a non-terminating cmdlet error yields `$null`, indistinguishable downstream from "no differences"; under `Set-StrictMode`, a `catch` that dereferences the variable whose absence it is reporting itself throws, abandoning the `try`/`catch` before its own `exit 1` runs; and cleanup placed before `exit 1` can itself throw, with the same result — the bash twins failed closed in all three. Guard with `Test-Path Variable:\NAME` before `IsNullOrWhiteSpace`, and put `Write-Error` + `exit 1` before cleanup or wrap cleanup in its own `try`/`catch`. For every success message in a script, ask what makes it print when the work did not happen.

## Pattern Observed — ICON-0040

A first-pass coder migrated a file-splitting routine using `match($0, /regex/, arr)` (3-arg gawk extension) and `printf -v` (bash builtin) inside an awk block. On mawk 1.3.4 both silently fail: the awk block emits zero output files while the surrounding bash keeps executing — including a `git rm .context/decisions.md` that would have run unconditionally, destroying consumer data. Invisible to diff-reading, it would have shipped silently to every consumer on Debian, Ubuntu, WSL, and Alpine. The reviewer caught it by live-running the extracted block against a fixture on mawk before approving. The fix replaced the gawk-only awk block with pure bash `BASH_REMATCH` parsing — simpler, portable, and verifiable in the same live-fixture loop.

## Related

- See also: [secure coding](secure-coding.md) § Rule 6 — cross-references this standard's `grep` dash-argument guidance
