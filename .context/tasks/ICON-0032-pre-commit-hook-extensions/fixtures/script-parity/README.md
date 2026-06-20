# Script-parity fixtures: driver notes

The two script-parity fixtures (`script-parity-identical-passes.md` and
`script-parity-divergence-fails.md`) are **driver scenarios**, not single-
file fixtures. The hook's parity check operates on the live files at
`skills/{post-incident-review,task-retrospective,context-maintenance}/scripts/`,
not on copies under this folder.

## How the driver should set up each scenario

### Identical baseline

Default state of the repo. No setup needed — all three copies are kept
byte-identical by repository convention (and by this hook). The hook
exits 0 when run against staged-but-unchanged copies.

### Divergence simulation

Three ways to introduce divergence for testing:

1. **In-place comment edit** (simplest):
   Modify a single comment line in one copy:

   ```sh
   sed -i 's|^# Prepend a new entry|# CHANGED: Prepend a new entry|' \
     skills/task-retrospective/scripts/append-retrospective-entry.sh
   ```

2. **Replace with canned divergent fixture**:
   Stash the canonical contents into `canned/` here, then write a
   deliberately-different file in place. After the test, restore from
   the canonical (post-incident-review) copy:

   ```sh
   cp skills/post-incident-review/scripts/append-retrospective-entry.sh \
      skills/task-retrospective/scripts/append-retrospective-entry.sh
   ```

3. **Delete one copy**:
   `diff -q` returns exit code 2 (error) when a file is missing. The
   `if ! diff -q ...` branch in the hook catches this case the same as
   divergence. Useful for testing the file-missing edge case.

## Driver invariants

- The driver MUST restore the canonical state after each divergence test
  so subsequent runs are not affected.
- Run the hook via direct invocation (`.githooks/pre-commit`) rather than
  via `git commit`, to avoid creating accidental commits during fixture
  driving.
- The exit code is the assertion target. `diff -q` stderr text is
  informational only — do not match on its exact format (BSD vs GNU
  `diff` differ slightly).
