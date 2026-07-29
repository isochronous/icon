# Rule 1. No gawk extensions in awk blocks

Two extensions are forbidden because mawk 1.3.x does not implement them:

- **3-argument `match()`** — `match($0, /regex/, arr)` with a capture-group array is gawk-only. Use `match($0, /regex/)` + `RSTART`/`RLENGTH` + `substr()`, or move parsing into bash with `[[ ... =~ ... ]]` + `${BASH_REMATCH[N]}`.
- **`printf -v <var>`** — bash builtin syntax, not awk. Awk's `printf` has no `-v` flag. For variable assignment, do it in the shell layer.

(ICON-0040: both shipped together in one awk block in a file-splitting routine. On mawk 1.3.4 it emitted zero output files while the surrounding bash ran on to an unconditional `git rm .context/decisions.md` — consumer data loss, invisible to diff-reading. Caught by live-running the extracted block against a mawk fixture (Rule 3); fixed with the pure-bash `BASH_REMATCH` form (Rule 2).)

## Related

- Index: [shell portability rules](README.md)
- See also: [Rule 2](002-prefer-pure-bash-parsing.md) — the pure-bash form this rule's precedent was fixed with
- See also: [Rule 3](003-live-test-file-mutating-blocks.md) — the live-fixture run that caught it
