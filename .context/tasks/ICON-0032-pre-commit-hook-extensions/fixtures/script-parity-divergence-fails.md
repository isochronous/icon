# Fixture: script-parity divergence fails

This is a driver scenario, not a single-file fixture.

When ANY of the three copies of `append-retrospective-entry.{sh,ps1}`
diverges from the canonical (post-incident-review) copy, the hook MUST
fail with exit 1 and report the diverging copy by path.

Driver setup:
  1. Mutate ONE copy of `append-retrospective-entry.sh` — e.g., change a
     single comment line in `skills/task-retrospective/scripts/`.
  2. Stage that mutated file with `git add`.
  3. Run `.githooks/pre-commit`.
  4. Assert: exit 1, stderr contains
       `[pre-commit] error: <path> diverges from <canonical path>`
       `  fix: re-sync the copies (all three must be byte-identical)`

Cleanup: revert the mutation before committing other work.

See `script-parity/README.md` for the divergence-simulation tooling.

Expected hook behavior (divergence simulation):
  exit 1
  stderr contains the diverging copy's path
  stderr contains `re-sync the copies`
