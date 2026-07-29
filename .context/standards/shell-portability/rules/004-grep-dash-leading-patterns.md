# Rule 4. `grep` with a pattern that can start with `-`: pass `-e`, and don't trust an `if grep` guard

A regex or string whose first character is `-` (e.g. a PEM header `-----BEGIN`) is parsed by `grep` as options, not a pattern — `grep` exits 2 with "unrecognized option". When wrapped in `if … | grep -Eq …`, the `if` reads grep's exit-2 *error* as "no match" and falls through silently — the check fails **OPEN**: it looks like it works but never fires. For a security gate (secret-scan, etc.) that is a silently-disabled control. Two rules: (a) whenever a pattern can begin with `-`, use `grep -e <pat>` (or `--`) to force end-of-options; (b) never trust an `if grep` guard to report its own breakage — test every pattern against a known-positive fixture (the contents-not-exit-code discipline of Rule 3 applied to match logic). Applies to all ICON shell — `.githooks/pre-commit`, the retrospective scripts, `check-rules-index.sh` — not just shipped skill blocks. (ICON-0075: the `pem-private-key` secret-scan pattern would have NEVER fired until fixed to `grep -Eq -e "$re"`.)

## Related

- Index: [shell portability rules](README.md)
- See also: [Rule 7](007-grep-pcre-mode.md) — the distinct `grep` trap of PCRE-only syntax, which a pattern can trigger independently of this one
- See also: [secure coding](../../secure-coding.md) § Rule 6 — cross-references this rule's dash-argument guidance
