# Harness Trust — Verifying the Verification Tool

A verification result is only as trustworthy as the tool that produced it. `shell-portability.md`
covers writing shell that behaves correctly across platforms; this standard covers a different
failure class — the tool used to *check* that behavior lying about what it observed. Six traps
have each already produced a false pass or false fail on ICON tasks, and none of them was a bug
in the code under test.

## The Rule

**When a verification result surprises you, suspect the harness before the subject.** A test that
unexpectedly passes, an assertion that unexpectedly fails, or an expected value that doesn't match
a fixture is exactly as likely to be the verification tool mangling something as it is to be a
real defect — and three separate agents on ICON-0094 lost time to a harness that lied, with one
nearly reporting a real defect as non-reproducible because the first (harness-broken) run looked
clean.

## Six Traps, Each Already Caught Once

1. **`sed`/`awk` silently strip `\r` on output**, even when the defect under test is *about* line
   endings — a CRLF host checks out CRLF, but a `sed`/`awk` step anywhere in the verification
   pipeline normalizes it away before the comparison runs, so a real line-ending divergence reads
   as identical. `cmp`, `od`, and `tr` do not do this; use one of them when line endings are the
   thing being checked (ICON-0094).
2. **`set -e` exempts non-final commands in an `&&` list.** A guard's inverted condition can look
   like it never fires when tested as a standalone snippet, and only reproduces when re-run the way
   a real caller actually invokes it — as its own script, or sourced (ICON-0094; the same class as
   `shell-portability/rules/` Rule 4's `if grep` masking).
3. **A required interpreter absent from the test tool's `PATH` fails silently, not loudly.**
   `bash` was not on `PATH` in the PowerShell tool used for this task, so a fixture-rebuild script
   invoked from PowerShell silently never ran — a whole PowerShell review round tested stale
   fixtures from the previous round, and it surfaced only because one row printed an unexpected
   message (ICON-0094).
4. **Slicing an expected value through an interpreter can corrupt the expectation, not the
   subject.** A byte-equality check read FAIL until traced to `awk` collapsing `\&` in the
   *expectation string* itself during test setup — the code under test was correct throughout.
   Slice expected values directly from the committed fixture rather than round-tripping them
   through a shell/awk step (ICON-0094).
5. **`exit N` inside a dot-sourced PowerShell script does not propagate through `pwsh -File`.**
   Dot-sourcing always reports exit code 0 to the outer driver, regardless of what the sourced
   script actually did — every PowerShell exit-code assertion made this way is meaningless.
   Concatenate the blocks into the driver script instead of dot-sourcing them when the exit code
   is the thing under test (ICON-0094).
6. **JavaScript `String.replace` treats `$` sequences in the replacement string as substitution
   patterns**, not literal text — `$'`, `` $` ``, `$&`, `$$`, and `$<name>` all have special
   meaning. A scripted text edit that passes an unescaped replacement string containing `$` can
   silently substitute the wrong text while reporting success. Use a replacer *function*
   (`str.replace(pattern, () => literalText)`) when the replacement text isn't a compile-time
   literal known to be `$`-free (ICON-0094).

## Anti-Rationalization

| Excuse | Reality | Correct Action |
|---|---|---|
| "The test failed, so the code must be wrong" | A failing assertion can be the harness corrupting the expectation or the fixture, not the subject | Re-derive the expectation from the committed fixture directly before trusting the failure |
| "The test passed, so this platform/shell is fine" | A pass can mean the check silently never ran (absent interpreter, dot-sourced exit code swallowed) rather than that it ran and succeeded | Confirm the check actually executed — inspect intermediate output, not just the final exit code |
| "It's just a `sed`/`awk` step in the test harness, not the shipped code" | The harness step can mask or manufacture the exact defect class under test | Prefer `cmp`/`od`/`tr` or byte-level comparison when the property under test is line endings, escaping, or exact bytes |

## Related

- See also: [shell portability](shell-portability.md) — writing shell that behaves correctly across
  platforms, as distinct from this standard's concern (the tool that checks that behavior lying)
- See also: [skill-decomposition/verify-design-claims-against-artifacts](skill-decomposition/verify-design-claims-against-artifacts.md) — verifying a *design's claim* against an artifact before relying on it; this standard covers a verification *result already obtained* being untrustworthy, not a claim never checked
