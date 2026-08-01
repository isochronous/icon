# Rule 11. Windows PowerShell 5.1 strips embedded `"` from a native command's arguments

Windows PowerShell 5.1 does not escape a double quote that appears *inside* an argument value when
it builds the command line for a native executable. The argument is wrapped in quotes and handed to
the Windows CRT parser, which then reads the embedded quotes as the wrapper's own. So a
single-quoted shell word whose body contains `"` arrives at the program with those quotes deleted:

```
=== Windows PowerShell 5.1 ===                   === PowerShell 7 / bash / sh ===
process.stdout.write(HELLO\n)                    HELLO
                     ^^^^^^  quotes gone
SyntaxError: Invalid or unexpected token         exit 0
```

Measured on 5.1.26100.8875 with Node v24.18.0, from the identical source line
`node -e 'process.stdout.write("HELLO\n")'`, through both `powershell.exe -File` and
`powershell.exe -Command`. PowerShell 7 and Git-Bash `bash`/`sh` run the same line correctly.

**This is the measurement that defeated ADR-017's inline default, and it still qualifies what
survives of it.** ADR-017 made an inline `node -e` program the default home for a deterministic
block, and a JavaScript program of any substance contains a `"` — `require("fs")`, a string literal,
a JSON key. As of ICON-0099 there are **21** single-quoted `node -e` invocations in ICON's shipped
content, plus **1** more in maintainer-only `.claude/` (**22** in total), and **all 22** contain a
double quote.

**ADR-018 flipped that default for *programs*, citing this rule as one of its three grounds** — but
it does not close the exposure. A deterministic block with no body is a **command** and still ships
inline. ADR-018 classifies 19 of the 22 as programs bound for a committed `.mjs`; the other 3 are
commands, stay inline permanently, and all three contain a `"`, so all three remain exposed here.
The `.mjs` form is unaffected: `node "<absolute path>"` has no quote *inside* an argument value, and
it was measured running correctly on 5.1.

## The sharp edge: a block whose pass state is silence

The failure is loud where the caller reads stdout for a result — zero bytes plus a `SyntaxError` on
stderr. **It is invisible where the block's contract makes silence the pass**, because "did not run"
and "ran and found nothing" produce the same empty stdout. Two measurements to keep separate:

- Through `-Command`, `$LASTEXITCODE` was `1`, so an exit-status check catches it.
- Through `-File`, the script reported **0** — but that is not a 5.1 quirk and not quoting-related:
  a `.ps1` whose native command exits 3 also reports 0 through `-File` on **both** 5.1 and 7. Exit
  status through `-File` is not evidence either way.

So do not write "the failure is always loud." Where silence is the pass, require **empty stdout and
empty stderr** — see [testing pattern](../testing-pattern.md) § A Detector Whose Pass State Is
Silence. `skills/icon-status/SKILL.md` Step 1 is the live worked example.

## What to do

1. **State the shell requirement in the prose next to the block** — "run this in bash or PowerShell
   7" — and say why, so a reader on 5.1 knows what they are seeing. This is what the four migrated
   ICON-0099 files do.
2. **If the block must run on 5.1, move it to a committed `.mjs`** and invoke it as
   `node "<path>"`. That form was measured working on 5.1.
3. **Do not reach for outer-double/inner-single as a general fix.** `node -e "…'…'…"` does run on
   5.1, 7 and bash — but it fails a falsification test that the single-quoted form passes: bash
   expands the body. A body containing `$HOME` produced the shell's `/c/Users/thegr` instead of the
   program's own constant, **exit 0, silently wrong**; a body containing a backticked template
   literal was command-substituted into garbage. Valid only for a body with no `$`, no backtick and
   no `\"`/`\\`/`\$` — verify that before using it, per file.

(ICON-0099: measured by the @tester through two independent invocation paths while re-verifying a
migration that took the shipped site count from 8 to 21 (22 in total counting the maintainer-only
`.claude/` site). Widening the count is what made the pre-existing gap worth a rule. The remedy was
then taken as a design call rather than left ticketed — ADR-018, later in the same task.)

## Related

- Index: [shell portability rules](README.md)
- See also: [Rule 9](009-pass-values-as-arguments.md) — the other quoting rule: that one is about a
  *value* interpolated into a program body, this one is about the program body's own quotes
- See also: [testing pattern](../testing-pattern.md) § A Detector Whose Pass State Is Silence — the
  contract that turns this loud failure into a silent one
- See also: [executable content — classification](../../skill-decomposition/executable-content/classification.md)
  — the authoring spec whose surviving inline command tier this rule qualifies
- Governed by: [ADR-018 the body test, program vs command](../../../decisions/018-body-test-program-vs-command.md)
  — the record that cites this measurement and flips the default for programs
