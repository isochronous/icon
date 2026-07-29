# Rule 9. Pass values as arguments — never interpolate them into a program body

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

- Index: [shell portability rules](README.md)
- See also: [Rule 10](010-port-semantics-not-shape.md) — the other half of reviewing a language port: quoting is this rule, semantics is that one
