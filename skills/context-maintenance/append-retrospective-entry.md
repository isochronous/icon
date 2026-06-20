# `append-retrospective-entry` — Tooling Reference

Companion reference for the `context-maintenance` skill. Documents the script that mutates `.context/retrospectives.md` (rolling log of last 10 entries).

---

The `append-retrospective-entry` script (located in the `scripts/` subdirectory at
`skills/context-maintenance/scripts/`) provides deterministic
insertion and rolling-log maintenance for `.context/retrospectives.md`.

Two variants ship side by side — pick the one that matches the calling shell:

- `append-retrospective-entry.sh` — Bash (Linux, macOS, WSL, Git-Bash)
- `append-retrospective-entry.ps1` — PowerShell (Windows without Git-Bash/WSL)

Both variants produce identical behavior, exit codes, and output. Pick by host
environment; no semantic differences.

**This is the only approved way to mutate `retrospectives.md` — do not edit
it directly.**

### When to use

Call this script whenever a new retrospective entry needs to be appended to
a project's `.context/retrospectives.md`. It is invoked by @context-specialist
(in maintenance mode) after the manager has drafted the entry text following a
task retrospective.

### What the script does

1. Counts `### ` entry blocks from the top of the file.
2. If the count is ≥ 10, trims oldest entries until the post-insert count equals 10 (multi-prune convergence — not just one removal per call).
3. Prepends the new entry at the top of the file, making it the newest.
4. Preserves the trailing HTML comment.
5. Writes atomically (temp file in the same directory → `mv` / `Move-Item -Force`).

### Usage — Bash

```bash
# Pass entry text via stdin
echo '### MKT-0045: Short description
- **Avoid**: ...
- **Repeat**: ...
- **Updated**: ...' | ./scripts/append-retrospective-entry.sh \
    .context/retrospectives.md -

# Pass entry text from a file
./scripts/append-retrospective-entry.sh \
    .context/retrospectives.md entry.txt
```

### Usage — PowerShell

```powershell
# Pass entry text via stdin
@'
### MKT-0045: Short description
- **Avoid**: ...
- **Repeat**: ...
- **Updated**: ...
'@ | pwsh -NoProfile -File ./scripts/append-retrospective-entry.ps1 `
    .context/retrospectives.md -

# Pass entry text from a file
pwsh -NoProfile -File ./scripts/append-retrospective-entry.ps1 `
    .context/retrospectives.md entry.txt
```

### Entry format

The entry text must begin with a `### ` heading (the canonical format from the
`task-retrospective` skill):

```
### TASK-ID: Short description
- **Avoid**: Specific mistake and how to prevent it.
- **Repeat**: Specific technique that worked.
- **Updated**: Which .context/ file was updated, or "nothing to promote".
```

### Exit codes

| Code | Meaning |
|------|---------|
| 0 | Success — file updated |
| 1 | Usage or validation error (bad args, entry missing `### ` heading) |
| 2 | File access error (missing, unreadable, or not writable) |
