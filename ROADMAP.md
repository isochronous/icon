# ICON Roadmap — post-audit

Ordered for dependency, not impact. `→` means the left item makes the right one easier or safer to do.

Source: ICON-0089 audit (`.context/tasks/ICON-0089-icon-audit/audit-report.md`) and the ICON-0090 dogfood run (`.context/tasks/ICON-0090-dogfood-upgrade-repo/upgrade-audit.md`).

---

## Done

| Task | PR | What |
|---|---|---|
| ICON-0089 | #10 | `icon-audit` run, script-offload focus — 5 Critical / 24 Moderate / 39 Minor / 33 opportunities |
| ICON-0090 | #11 | dogfood `/upgrade-repo` against ICON itself — 9 skill defects; applied nothing (would have deleted live content) |
| ICON-0091 | #12 | amend ADR-005 in place; corrected ADR-008, ADR-013 and 4 inheriting sites |
| ICON-0092 | #13 | remove `ecological-impact` |

Also landed inside those: `.context/domains` hook count + matcher literal, stale single-hook claims in 3 files, `## Related` graph seam across 20 docs, git hooks made executable (they were silently dead on fresh macOS/Linux clones), `skill-decomposition` index tallies removed.

---

## Milestone 1 — Consumer-facing correctness

```
#17  shipped-content-portability        → unblocks testing everything below on macOS/BSD
#15  upgrade-repo-broken-steps
#14  upgrade-repo-customized-vs-stale   → adds the new schema field; feeds #31
#16  root-init-parity
#18  research-cache-lifetime
```

**Why #17 first.** It carries the GNU-only `grep -oP` → `grep -oE` class. Until that lands, monorepo discovery returns zero projects on macOS/BSD *silently*, and the `iconrc` sync no-ops forever — so you cannot verify a fix to #15 on those platforms; it'll look like it works because it fails quietly either way.

**#14 before #16/#18** only because it introduces the new schema-version field, which #31 reads later. #16 and #18 are independent of everything.

---

## Milestone 2 — Release safety

```
#20  json-validation-and-schemas        → gives #19 a validator to call
#19  release-preflight-and-rollback
```

**#20 first.** The pre-flight gate wants to assert "the manifest is valid" as one of its checks; building the validator first means #19 calls it rather than reimplementing it. Today nothing anywhere parses JSON, and the documented `python3` check does not execute on Windows.

---

## Milestone 3 — Standardize on Node

```
#22  node-detection-skill               → both migrations below can then assume a verified runtime
#21  replace-python3-with-node
#23  migrate-scripts-to-node
```

**#22 first**, because the other two increase reliance on Node and the detector is what makes that safe. Note it cannot itself be a `.mjs` script.

---

## Milestone 4 — Enforcement

```
#24  ci-backstop-existing-checks        → makes every gate below actually binding
#25  generate-check-inventory           → mis-ranked low; do it early or gate docs rot again
#27  three-fail-closed-checks
#28  skill-metadata-check
#29  harden-security-workflow
#30  registry-driven-checks
#26  portability-check                  ← needs M1 #17 landed + #24
#31  template-drift-notice              ← needs M1 #14 (the new schema field)
#32  record-checks-not-built            (independent; 10 minutes)
```

**#24 is the real prerequisite.** The ten existing pre-commit checks are opt-in per clone, `--no-verify`-bypassable, and have no CI backstop — an eleventh gate raises surface without raising guarantee.

**#25 is under-priced.** Gate documentation has failed three cycles running (3-of-10 documented). Ten more gates makes it 3-of-20.

---

## Milestone 5 — Contradictions and stale content

```
#35  sweep-2.0.0-removal-residue        → fixes the tracker reference #43 depends on
#33  remove-superseded-plan-model       → defines the evidence record's shape, which #39 needs
#34  agent-io-contracts
#36  fix-three-format-skills
#37  repo-shape-detection-agreement
```

**#35 first**, specifically its tracker-reference part: the audit skill still says to file follow-ups as GitLab issues, two releases after the GitHub move. That stale line is what produced a wrong instruction in this very cycle.

---

## Milestone 6 — Collapse the duplication

```
#43  repair-audit-followup-loop         ← needs #35
#39  phase-contract-script              ← needs #33
#38  setup-manifest
#42  split-upgrade-skill                ← do AFTER M1; splitting a file mid-repair fights the repair
#41  split-skill-authoring-guide
#40  token-budget-scope
#44  readme-contributor-discoverability
#45  scaffold-github-directory
```

---

## Cross-milestone dependencies, in one place

```
M1 #17  →  M4 #26
M1 #14  →  M4 #31
M1 all  →  M6 #42
M4 #24  →  everything else in M4
M5 #35  →  M6 #43
M5 #33  →  M6 #39
M2 #20  →  M2 #19
M3 #22  →  M3 #21, #23
```

Everything not listed above is independent and can be picked up in any order.

---

## Not building — decided

Recorded in #32 so they don't return as findings next cycle.

- **Skill size gate** — its entire violation population is one file. A gate whose finding set is a single known file is a bug report with CI attached.
- **Broad ordered-list resolver** — trains authors to renumber until green without checking the referent. The narrow form (require a section name beside `Step N`) is kept.
