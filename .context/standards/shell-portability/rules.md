# Shell Portability Rules

The numbered construct rules. Each names a construct, the direction it fails in, the portable form, and the precedent that produced it. **Rules are cited by number across this repo — the numbers are immutable once assigned.** The premise these rest on, that shipped shell runs in the consumer's environment rather than the maintainer's, is in the [index](../shell-portability.md).

## Rule 1. No gawk extensions in awk blocks

Two extensions are forbidden because mawk 1.3.x does not implement them:

- **3-argument `match()`** — `match($0, /regex/, arr)` with a capture-group array is gawk-only. Use `match($0, /regex/)` + `RSTART`/`RLENGTH` + `substr()`, or move parsing into bash with `[[ ... =~ ... ]]` + `${BASH_REMATCH[N]}`.
- **`printf -v <var>`** — bash builtin syntax, not awk. Awk's `printf` has no `-v` flag. For variable assignment, do it in the shell layer.

(ICON-0040: both shipped together in one awk block in a file-splitting routine. On mawk 1.3.4 it emitted zero output files while the surrounding bash ran on to an unconditional `git rm .context/decisions.md` — consumer data loss, invisible to diff-reading. Caught by live-running the extracted block against a mawk fixture (Rule 3); fixed with the pure-bash `BASH_REMATCH` form (Rule 2).)

## Rule 2. Prefer pure bash for non-trivial parsing

When awk's pattern-action structure is not pulling its weight — multi-step capture, variable mutation, or conditional branching — prefer pure bash (`while IFS= read -r`, `[[ =~ ]]`, `BASH_REMATCH`). Simpler, more portable, and easier to live-test than an awk block embedded in a markdown fenced code block.

## Rule 3. Live-test shell blocks that write or delete files

Any shipped shell snippet that writes, renames, or deletes files must be live-tested against the platform-default toolchain before merge. Diff-reading is not sufficient — mawk failures produce empty output with exit 0, invisible to reviewers.

## Rule 4. `grep` with a pattern that can start with `-`: pass `-e`, and don't trust an `if grep` guard

A regex or string whose first character is `-` (e.g. a PEM header `-----BEGIN`) is parsed by `grep` as options, not a pattern — `grep` exits 2 with "unrecognized option". When wrapped in `if … | grep -Eq …`, the `if` reads grep's exit-2 *error* as "no match" and falls through silently — the check fails **OPEN**: it looks like it works but never fires. For a security gate (secret-scan, etc.) that is a silently-disabled control. Two rules: (a) whenever a pattern can begin with `-`, use `grep -e <pat>` (or `--`) to force end-of-options; (b) never trust an `if grep` guard to report its own breakage — test every pattern against a known-positive fixture (the contents-not-exit-code discipline of Rule 3 applied to match logic). Applies to all ICON shell — `.githooks/pre-commit`, the retrospective scripts, `check-rules-index.sh` — not just shipped skill blocks. (ICON-0075: the `pem-private-key` secret-scan pattern would have NEVER fired until fixed to `grep -Eq -e "$re"`.)

## Rule 5. Use `${VAR+x}` for presence tests, not `${VAR:-fallback}`

`${VAR+x}` is a POSIX **presence test**: it expands to `x` when `VAR` is set (even if set-but-empty) and to empty string when `VAR` is unset. Use it — e.g. `[ -z "${VAR+x}" ]` (unset) / `[ -n "${VAR+x}" ]` (set) — whenever distinguishing "unset" from "set-but-empty" is load-bearing (e.g. credential-presence checks in generated shell).

`${VAR:-literal}` is a **fallback substitution**, not a presence test: it yields `literal` only when `VAR` is unset *or* empty, so an empty-but-set variable silently defeats a presence check written with it.

The `icon-init` MCP-onboarding gate and the `icon-status` credential check rely on this.

## Rule 6. PowerShell `-replace` inside a .NET method-call argument list: parenthesize it

Inside a .NET method call's argument list, PowerShell parses the two commas of a `-replace 'pattern','replacement'` expression as **method-argument separators**, not as part of the `-replace` operator. So this passes `TryParse` the wrong number of arguments:

```powershell
[int]::TryParse((Get-Content $f -replace '\D',''), [ref]$n)   # BROKEN
```

PowerShell reads it as three arguments — `(Get-Content $f -replace '\D'`, `''`, `[ref]$n` — which throws under `Set-StrictMode` / `$ErrorActionPreference='Stop'`. Wrap the `-replace` expression in its **own** parentheses so its commas are contained within the operand, not the argument list:

```powershell
[int]::TryParse(((Get-Content $f) -replace '\D',''), [ref]$n)   # correct
```

(ICON-0082: a persisted-`Attempts` parse in the PowerShell phase-launcher template silently broke the same bounded-retry guarantee in PS mode until the `-replace` was wrapped in its own parentheses `((… -replace '\D',''))`.)

## Rule 7. `grep -P`/`-oP` (PCRE mode) is a GNU extension — triage before swapping the flag

`-P` enables Perl-compatible regex matching in GNU `grep`. BSD/macOS `grep` and busybox `grep` do not implement it at all — they exit with "invalid option -- P" (or an "unsupported" error), so a shipped skill that hardcodes `-P`/`-oP` breaks outright on those platforms, not just subtly. The trap is that the fix is **not a uniform flag swap** — which fix applies depends on what the pattern actually uses. Before touching the flag, scan the pattern for `\d`, `\w`, `\s`, `\K`, a lookaround (`(?=`, `(?!`, `(?<=`, `(?<!`), or a lazy quantifier (`+?`, `*?`), and route to one of three fixes:

- **No PCRE-only feature present** — the pattern only used `-P` incidentally; `-oP` → `-oE` is behavior-identical (e.g. `grep -oP '"[^"]+\.csproj"'`, which has no PCRE shorthand).
- **`\d`/`\w`/`\s` shorthand present, no `\K`/lookaround/lazy quantifier** — a bare flag swap **silently changes the meaning**. POSIX ERE has no backslash-digit escapes: outside a bracket expression, `\d` is an escaped literal `d`, matching the letter "d", not a digit. Inside a bracket expression — as in this rule's own example, `[\d.]+` — POSIX gives backslash **no special meaning at all**, so `[\d.]` is a three-member set of the literal characters `\`, `d`, and `.` — not "digit or dot". The pattern must be translated, not just re-flagged: `\d` → `[0-9]`, `\w` → `[A-Za-z0-9_]`, `\s` → `[[:space:]]`, then run under `-E`.
- **`\K`, a lookaround, or a lazy quantifier present** — POSIX ERE has **no equivalent** for any of these; no flag swap or translation can preserve the pattern's behavior in `grep -E`. Move the extraction to a different tool: a `sed` capture group with `-n … p` to filter to only matching lines (`sed -n 's/^TICKET-\([0-9][0-9]*\).*/\1/p'`), or `grep -oE` the whole token followed by a separate strip step.

```bash
grep -oP '[\d.]+'                          # BROKEN: -oP unsupported on BSD/busybox
grep -oE '[\d.]+'                          # BROKEN: flag-only swap; set is {\,d,.} — against `  "version": "1.12",` prints "." not the version
grep -oE '[0-9.]+'                         # correct: shorthand translated, then re-flagged

grep -oP 'TICKET-\K[0-9]+'                 # BROKEN: -oP unsupported; \K (digits after the prefix, prefix excluded) has no ERE form at all
sed -n 's/^TICKET-\([0-9][0-9]*\).*/\1/p'  # correct: extraction moved to a capture group, -n/p filters non-matching lines
```

This rule is distinct from Rule 4: Rule 4 covers a pattern misparsed as an *option* because it starts with `-`, regardless of engine; this one covers a pattern using *PCRE-only syntax* unsupported by non-GNU `grep`, regardless of where it starts. A pattern can trigger either, both, or neither — check each independently. (ICON-0093: `grep -oP` with no PCRE feature in `skills/initialize-monorepo/SKILL.md`, `grep -oP '[\d.]+'` in `skills/upgrade-repo/SKILL.md`, and `grep -oP 'MKT-\K[0-9]+'` in `context_template/context/workflows/commit-conventions.md` were three different shapes of the same unnamed gap — each needed a different fix.)

## Rule 8. `sed -i` requires an explicit backup-suffix argument for BSD/macOS compatibility

GNU `sed -i` treats the backup suffix as **optional** — `sed -i 's/foo/bar/' file` edits in place with no backup. BSD/macOS `sed -i` treats the suffix as **mandatory**: it consumes whatever token comes next as that suffix. Given `sed -i "s/foo/bar/" file`, BSD/macOS `sed` reads the script as the suffix and `file` as the script — not valid `sed` syntax, so it errors out ("command garbled" or "unterminated address regex") rather than editing anything.

```bash
sed -i "s/foo/bar/" file        # BROKEN on BSD/macOS: consumes the script as the suffix, errors
sed -i.bak "s/foo/bar/" file    # correct everywhere — but leaves file.bak behind
```

Two portable forms, with a tradeoff between them:

- **`sed -i.bak "s/…/…/" file`** — works identically on GNU and BSD because the suffix is always explicit. Simple, but leaves a stray `file.bak` in the consumer's working tree that the skill must remember to clean up (or that pollutes `git status`).
- **Temp file + `mv`** — `sed "s/…/…/" file > file.tmp && mv file.tmp file || { rm -f file.tmp; exit 1; }` — avoids `-i` entirely, so the GNU/BSD divergence never applies, and leaves no backup artifact **provided the trailing cleanup runs**. Slightly more verbose, and both halves are load-bearing. The `mv` must be conditional on the `sed` succeeding (`&&`, not a separate statement): the redirect only ever writes to `file.tmp`, never to `file` itself, so a failed `sed` cannot truncate the original — but it can leave a partial or empty `file.tmp` behind, and an unconditional `mv` would then overwrite the good original with that broken temp file. The trailing `|| { rm -f file.tmp; exit 1; }` is what removes that leftover and preserves the failure; without it, "leaves no backup artifact" is false on the failure path. **Do not shorten it to `|| rm -f file.tmp`**, the obvious-looking fix: `rm -f` itself succeeds (with or without a file to remove), so its exit status becomes the whole list's and the construct exits 0 even though the `sed` failed and the edit never happened — under `set -euo pipefail` (how every shipped `.sh` in this repo runs) the script then continues past the failed edit as if it had succeeded.

(ICON-0093: `sed -i "s/…/…/" .context/iconrc.json` in `skills/upgrade-repo/SKILL.md` used the no-suffix GNU-only form.)

## Rule 9. Pass values as arguments — never interpolate them into a program body

A value spliced into the *text* of a program — a `node -e '…'` script, a `python3 -c "…"` string, a `jq` filter — is parsed as program source, not as data. Any character the surrounding quoting treats as special ends the value early: an apostrophe closes a single-quoted `-e` argument, a double quote closes a double-quoted one, and a backslash is an escape in most program grammars long before it is a path separator. This is not a platform divergence — it breaks everywhere — but it hides the same way the rest of this document's traps do, because the characters that trigger it (`'`, `"`, `\`) are rare in the fixtures an author writes and common in the values a consumer supplies: a Windows path, a description, a surname.

The rule is one line: **pass the value as an argument.** `process.argv` in Node, `--arg` in `jq`, `"$VAR"` as a positional to a script. Never a shell expansion sitting inside a quoted program body.

**The direction is not language-specific.** A construct that was safe in the outgoing language can be unsafe in the incoming one even when the logic is translated correctly, because the *delivery mechanism* changes shape along with it. `python3 - <<'PY'` is a **quoted heredoc**: the shell does no processing inside it, so an apostrophe in substituted free text passes through untouched. `node -e '…'` is a single-quoted shell word: the same apostrophe closes it. Review a language port for quoting, not only for logic — and treat both directions of the swap as suspect.

```bash
node -e "const ws = require('$WORKSPACE_FILE');"                 # BROKEN: a path containing ' or " ends the
                                                                 # program early; on Windows \ is a JS escape too
node -e 'const [ws] = process.argv.slice(1);' "$WORKSPACE_FILE"  # correct: the value is never parsed as source

node -e 'console.log("author: Siobhan O'Brien");'                     # BROKEN: the apostrophe closes the -e word
node -e 'console.log("author: " + process.argv[1]);' "Siobhan O'Brien" # correct: a double-quoted argument carries ' through
```

(ICON-0097: `initialize-workspace` interpolated `'$WORKSPACE_FILE'` into a Python string literal — a path containing `'` or `\` broke the program, and on Windows `\` is a Python escape as well; fixed via `process.argv`. Three sites later the same task substituted agent-supplied free text into a single-quoted `node -e` program in `create-phase-basic-info`, where `Siobhan O'Brien` in an author name broke a shipped skill that the Python version had handled — the same construct, reintroduced in the other direction, in the task that had just removed it.)

## Related

- Index: [shell portability](../shell-portability.md)
- See also: [testing pattern](testing-pattern.md) — how to live-test the constructs these rules prescribe
- See also: [secure coding](../secure-coding.md) § Rule 6 — cross-references Rule 4's `grep` dash-argument guidance
