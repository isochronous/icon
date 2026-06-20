# Fixture: script-parity baseline (identical copies pass)

This is a driver scenario, not a single-file fixture.

When all three copies of `append-retrospective-entry.{sh,ps1}` are
byte-identical across:
- `skills/post-incident-review/scripts/` (canonical)
- `skills/task-retrospective/scripts/`
- `skills/context-maintenance/scripts/`

…and any of the six copies is staged, the script-parity check MUST exit
0 (all `diff -q` invocations return exit code 0).

Driver setup:
  1. Stage one or more of the six tracked script copies (no edits).
  2. Run `.githooks/pre-commit`.
  3. Assert: exit 0, no `[pre-commit] error:` output for parity.

See `script-parity/README.md` for divergence-simulation tooling.

Expected hook behavior (baseline):
  exit 0
  no parity findings
