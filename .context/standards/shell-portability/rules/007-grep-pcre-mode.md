# Rule 7. `grep -P`/`-oP` (PCRE mode) is a GNU extension — triage before swapping the flag

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

## Related

- Index: [shell portability rules](README.md)
- See also: [Rule 4](004-grep-dash-leading-patterns.md) — the other `grep` trap, which this rule is explicitly distinct from
