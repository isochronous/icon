# ICON-0032 pre-commit hook fixtures

Each fixture's filename names the case it guards (fixture-as-spec per
ICON-0013). A reader should be able to scan filenames and infer the
contract.

## Single-file fixtures (markdown content encodes the case)

| Fixture | Hook behavior | Notes |
|---------|---------------|-------|
| `dead-context-ref-fails.md` | exit 1 | `.context/` ref to non-existent target |
| `dead-context-ref-in-backticks-fails.md` | exit 1 | ref resolver is fence-blind |
| `valid-context-ref-passes.md` | exit 0 | ref resolves under context_template/ |
| `bare-directory-ref-passes.md` | exit 0 | regex requires `.<ext>` suffix |

## Driver scenarios (mutate live files; see script-parity/README.md)

| Fixture | Hook behavior | Driver action |
|---------|---------------|---------------|
| `script-parity-identical-passes.md` | exit 0 | no mutation; baseline |
| `script-parity-divergence-fails.md` | exit 1 | mutate one of the 3 copies |

The two parity fixtures are documentation of test scenarios, not files
the hook directly consumes. The driver (@tester) mutates the live
`skills/{post-incident-review,task-retrospective,context-maintenance}/scripts/append-retrospective-entry.{sh,ps1}`
files to simulate the case, then runs the hook. See
`script-parity/README.md` for setup tooling and restore-after-test
invariants.

## Driver verification (ICON-0013 lesson)

To prove the fixture suite has detection value, @tester should at least
once temporarily mutate the hook (e.g., remove the `system("test -f ...")`
existence call in the dead-ref resolver awk) and confirm at least one
fixture catches the regression — for instance, neutering the existence
test would flip `dead-context-ref-fails.md` from exit 1 to exit 0. A
fixture that passes regardless of the hook's correctness is not a guard
— it is a placebo.
