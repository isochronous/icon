# Harness Trust — Verifying the Verification Tool

A verification result is only as trustworthy as the tool that produced it. `shell-portability.md`
covers writing shell that behaves correctly across platforms; this standard covers a different
failure class — the tool used to *check* that behavior lying about what it observed, or a side
effect landing somewhere the habitual check cannot see it. Seven traps have each already produced
a false pass, a false fail, or an unseen filesystem write on ICON tasks. Six were pure harness
artifacts with no defect in the code under test; the seventh is the one exception, and is called
out as such where it appears below — the code it ran against had a real, separately-fixed defect,
and the trap is the *environment property* that turned running it into a real file write rather
than a contained one.

## The Rule

**When a verification result surprises you, suspect the harness before the subject.** A test that
unexpectedly passes, an assertion that unexpectedly fails, or an expected value that doesn't match
a fixture is exactly as likely to be the verification tool mangling something as it is to be a
real defect — and three separate agents on ICON-0094 lost time to a harness that lied, with one
nearly reporting a real defect as non-reproducible because the first (harness-broken) run looked
clean.

## Seven Traps, Each Already Caught Once

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
7. **On a Windows host, Git Bash's MSYS root (`/`) is the Git install directory, not `C:\`** —
   measured on this host: `cd / && pwd -W` returns `C:/Program Files/Git`, and `TMPDIR` is unset
   (`echo "${TMPDIR:-<unset>}"` prints `<unset>`). Any `/`-rooted absolute path, or a
   `"$TMPDIR/…"` fallback where `TMPDIR` is unset, writes into the Git installation with no error
   and no warning. **`git status` cannot detect the result at all** — the write is outside every
   repository, so the habitual working-tree-cleanliness check is blind to it; this is what let a
   single task leak into it four times before being caught. Three distinct shapes produced real
   files there in one task (ICON-0099): a `/`-rooted literal path from an unchecked
   `git rev-parse --show-toplevel` (empty output outside a work tree collapsed
   `"$ROOT/.gitattributes"` to `/.gitattributes`), separately, a mistyped redirect landing plain
   `git diff` output at `/d.txt`; an unset `$TMPDIR` collapsing `"$TMPDIR/copilot-block.txt"` to
   `/copilot-block.txt`; and an assumption that MSYS2 mounts drives at `/cygdrive/c/...` the way
   **Cygwin** does — it does not, so the path was created as a literal directory tree instead of
   resolving to a real Windows path. **The `.gitattributes` instance is the one exception noted
   above**: the pre-fix code being run *was* genuinely buggy (that unchecked `rev-parse` is what
   the fix corrected), and an agent ran that known-buggy block outside a work tree specifically to
   demonstrate the defect — this trap is that doing so demonstrated it for real instead of safely,
   because demonstrating a known-destructive block needs a disposable sandbox, not just care. The
   other three shapes have no code-under-test defect anywhere in the chain — pure agent/environment
   error. Guard: use a verified absolute scratch path — never a bare `/`-relative path or an
   unset-variable fallback — and check `/` itself, not just `git status`, before reporting a clean
   working tree (ICON-0099).

## Anti-Rationalization

| Excuse | Reality | Correct Action |
|---|---|---|
| "The test failed, so the code must be wrong" | A failing assertion can be the harness corrupting the expectation or the fixture, not the subject | Re-derive the expectation from the committed fixture directly before trusting the failure |
| "The test passed, so this platform/shell is fine" | A pass can mean the check silently never ran (absent interpreter, dot-sourced exit code swallowed) rather than that it ran and succeeded | Confirm the check actually executed — inspect intermediate output, not just the final exit code |
| "It's just a `sed`/`awk` step in the test harness, not the shipped code" | The harness step can mask or manufacture the exact defect class under test | Prefer `cmp`/`od`/`tr` or byte-level comparison when the property under test is line endings, escaping, or exact bytes |
| "`git status` is clean, my scratch work left no trace" | On Windows Git Bash, `git status` only sees inside repositories — a `/`-rooted or `$TMPDIR`-unset write lands in the Git install directory and is invisible to it | Verify the resolved absolute scratch path before use, and check `/` itself, not just `git status`, before reporting a clean working tree |

## Related

- See also: [shell portability](shell-portability.md) — writing shell that behaves correctly across
  platforms, as distinct from this standard's concern (the tool that checks that behavior lying)
- See also: [skill-decomposition/verify-design-claims-against-artifacts](skill-decomposition/verify-design-claims-against-artifacts.md) — verifying a *design's claim* against an artifact before relying on it; this standard covers a verification *result already obtained* being untrustworthy, not a claim never checked
