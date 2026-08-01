# Testing Pattern for Shipped Shell

How to establish that a shipped shell block — or a correction to one — actually works. [Rule 3](rules/003-live-test-file-mutating-blocks.md) creates the obligation; this file is the procedure and the lessons about where it still falls short.

## The Procedure

1. Create a temp directory (`mktemp -d`; pair with `trap 'rm -rf "$tmpdir"' EXIT`).
2. Write a fixture file covering all edge cases: valid blocks, malformed headers, whitespace-only preambles, special characters.
3. Extract the shell block from the SKILL.md markdown via an awk sweep on the fenced ` ```bash ` … ` ``` ` markers.
4. Run the extracted shell against the fixture.
5. Inspect each expected output file's **contents** — not just exit code, and not just file existence.

Step 5 is the critical difference: `mawk + gawk extension` exits 0 with zero bytes written; a contents check catches it, an existence check does not.

## The Procedure Covers Prescribed Idioms, Not Only Replaced Code

**This procedure applies to a fix, and to any idiom this document prescribes for others to copy — not just the code being replaced.** A corrected portability defect — or a rule's own illustrative fence — is a hypothesis about correct behavior, not a verified one, until it runs in the exact form printed. Rule 8's own `|| rm -f file.tmp` cleanup fence shipped for a full review round before a reviewer copied it out of the document and ran it — that run is what surfaced the exit-0 defect Rule 8 now documents.

## Passing the Procedure Can Still Ship the Wrong Failure Mode

**Passing this procedure can still ship the wrong failure mode.** Correcting a portability defect on one platform can silently trade a loud failure for a quiet one on another, and a quiet failure is worse. The `mktemp -p DIR .retro_tmp_XXXXXX.md` case is the worked example — two independent defects stacked at the same call site:

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

## PowerShell Is a Fail-Open Generator

**PowerShell is a fail-open generator in four measured shapes; the bash twins failed closed in every one.** Three come from its non-terminating-error model (ICON-0094): a non-terminating cmdlet error yields `$null`, indistinguishable downstream from "no differences"; under `Set-StrictMode`, a `catch` that dereferences the variable whose absence it is reporting itself throws, abandoning the `try`/`catch` before its own `exit 1` runs; and cleanup placed before `exit 1` can itself throw, with the same result. Guard with `Test-Path Variable:\NAME` before `IsNullOrWhiteSpace`, and put `Write-Error` + `exit 1` before cleanup or wrap cleanup in its own `try`/`catch`. For every success message in a script, ask what makes it print when the work did not happen.

**The fourth shape is the sharpest — it needs no error handling at all to go wrong (ICON-0096).** `$LASTEXITCODE` is not updated when PowerShell cannot resolve a command. `CommandNotFoundException` is raised before any process starts, so the variable retains whatever value it held before the call — measured on 7.6.3 and 5.1. The obvious existence check, `node -v` followed by `if ($LASTEXITCODE -ne 0)`, reads that stale value and reports the command **present** in exactly the case the check exists to catch. bash returns 127 and `cmd` returns 9009 for the same absent-command case (`cmd` needs `cmd /v:on` — the naive `& echo %errorlevel%` reports 0 through parse-time expansion, a second trap of its own); only PowerShell is silent. The consequence is directional: with the command present, `$LASTEXITCODE` updates correctly, so a guard keyed on exit status fails **only** in the absent direction, and happy-path testing cannot surface it. To test whether a command exists, read its **output**, not its exit status — and note that `$out = cmd 2>&1 | Out-String` does not help either: it yields an empty string in the same case, since the exception fires before any stream exists for the redirect to capture.

## A Detector Whose Pass State Is Silence

The four shapes above are PowerShell's. This one is not — it is a property of the block's own
contract, and any runtime can produce it. **A detector whose pass state is silence cannot
distinguish "ran and found nothing" from "did not run."** Both write zero bytes to stdout. Every
guard written as *"prints nothing when everything is fine"* is one failed invocation away from
reporting the healthy answer about a program that never executed.

The contract fix is one line: **the pass requires empty stdout *and* empty stderr — never quiet
alone.** Silence on stdout is the finding; silence on stderr is the evidence the finding was
produced. ICON-0099 measured two independent ways to lose the second half, on the same block:

- **Windows PowerShell 5.1**, which strips the embedded `"` out of an inline `node -e` program
  ([Rule 11](rules/011-powershell-51-strips-embedded-quotes.md)) — `SyntaxError`, 0 bytes of
  stdout, `$LASTEXITCODE` 1 through `-Command`.
- **Node absent from `PATH`** under PowerShell 7 — 0 bytes of stdout, and `$LASTEXITCODE` keeps its
  *prior* value, so exit status is clean too (the ICON-0096 shape above, arriving through a
  different door).

Exit status is not a substitute for the stderr half. Measured on this repo's own fixtures, a `.ps1`
whose native command exits 3 still reports **0** through `powershell.exe -File` on both 5.1 and 7 —
so through that invocation path a failed run and a clean run are indistinguishable on both stdout
and exit code, leaving stderr as the only channel that carries the difference.

`skills/icon-status/SKILL.md` Step 1 is the live worked example: a fresh-repo guard that prints
`NOT_INITIALIZED` or nothing, where reading silence as a pass skips a **hard stop** on a repo that
has no `.context/` at all. Its prose now states the stdout-and-stderr requirement inline, next to
the block, rather than leaving it to a reader to infer.

**When authoring a silent-pass detector, prefer inverting it.** A block that prints an explicit
`OK` token on the healthy path needs no contract paragraph — the absence of the token *is* the
failure signal, in every runtime, with no second channel to remember. Where the silent form is
kept (it reads better in a nine-block dashboard), the stdout-and-stderr sentence is not optional
garnish; it is the whole contract.

## Related

- Index: [shell portability](../shell-portability.md)
- See also: [rules](rules/README.md) § Rule 3 — the obligation this procedure discharges
- See also: [rules](rules/README.md) § Rule 11 — the quoting defect that turns a silent-pass block
  into a false pass on Windows PowerShell 5.1
