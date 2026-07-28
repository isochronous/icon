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
| ICON-0093 | #49 | shipped-content portability (#17) — 4 GNU-only construct classes cleared, `MKT` prefix removed, portability rules 7–8 added |
| ICON-0094 | #50 | `/upgrade-repo` broken steps (#15) — 7 defects + 10 steps that reported success for work they had not performed |
| ICON-0095 | #52 | hot/cold skill separation (#51) — ADR-016, the `hot-cold-path` standard, an advisory size gate, nine size rules reduced to two |

Also landed inside those: `.context/domains` hook count + matcher literal, stale single-hook claims in 3 files, `## Related` graph seam across 20 docs, git hooks made executable (they were silently dead on fresh macOS/Linux clones), `skill-decomposition` index tallies removed. From ICON-0093 specifically: two latent bugs in the shipped task-ID generator (`$MAX` never assigned; zero-padded IDs parsed as octal), a fail-open `sed` guard in `/upgrade-repo`, and a gawk escape warning firing on every retrospective append.

---

## Reordered — 2026-07-27

Two maintainer decisions changed the running order. Milestones keep their original numbers so existing cross-references stay valid; **execution order is now M0 → M3 → M1 → M2 → M4 → M5 → M6.**

```
M0  #51  hot-cold-skill-separation      ✅ DONE (#52)
M3  #22 → #21 → #23                     ← current
M1  #14, #16, #18                       (#17, #15 done)
M2 … M6                                 unchanged
```

**M0 is landed.** ADR-016 caps `SKILL.md` at 16,000 bytes and companions at 8,000, with a 2,000-byte floor; `skill-decomposition/hot-cold-path.md` carries the authoring rules. Three things follow for the work below:

- **The cut follows the condition, not the topic** — one companion per if→then block, all siblings of `SKILL.md`, none referencing another. Nesting is not available: a file referenced *from* a referenced file may be `head`-previewed rather than read, silently.
- **The advisory gate reports 11 findings across 8 skills today.** It becomes fail-closed once **#24** lands a CI backstop; two things must be settled first (it measures the working tree rather than the staged blob, and is line-ending sensitive), both recorded against ADR-016's promotion condition.
- **`upgrade-repo` was deliberately not the proving case** — its platform axis cross-cuts every mode branch, so splitting before #23 writes companion pairs the Node migration then deletes. It follows #23.

**Why M0 first.** A skill's whole `SKILL.md` loads on invocation, but a run executes only part of it — and ADR-008's scope explicitly excluded on-demand skills, so until ADR-016 nothing governed this at all. Hot/cold decides where *instructions* live; M3 decides where *code* lives. Designing the former first means the `.mjs` migration lands content in the right structure instead of moving it twice.

The load-bearing number is not size but **survivability**: Claude Code re-attaches each skill after compaction keeping only the **first 5,000 tokens**. `skills/upgrade-repo/SKILL.md` at **92,797 B ≈ 23,000 tokens is ~4.6× past that**, so roughly 78% of it is silently dropped on every compaction today — no error, no warning. ADR-016 sets the caps in **bytes** (`SKILL.md` ≤ 16,000, companion ≤ 8,000, floor 2,000); measure with `wc -c`.

*(Two figures previously stated here were wrong and are corrected above: the "a fifth" estimate inherited from #51 measures at ~36%, and the word count has been restated in the governing unit so the roadmap does not circulate a fifth measure.)*

**Why M3 before M1/M2.** ICON-0094 needed six review passes, and after the first round nearly every Critical was PowerShell-specific or a bash/PowerShell divergence — the exact asymmetry #23 exists to remove. Every further fix inside a `SKILL.md` pays that doubled cost. Standing policy until #23 lands: **no new PowerShell twins.** #23's scope is widened to fenced `SKILL.md` blocks, not just `.sh`/`.ps1` files ([comment](https://github.com/isochronous/icon/issues/23#issuecomment-5099114137)).

---

## Milestone 1 — Consumer-facing correctness

```
#17  shipped-content-portability        ✅ DONE (#49) — macOS/BSD verification now possible
#15  upgrade-repo-broken-steps          ✅ DONE (#50)
#14  upgrade-repo-customized-vs-stale   → adds the new schema field; feeds #31
#16  root-init-parity
#18  research-cache-lifetime
```

**#15 is landed.** Beyond its seven defects it cleared a class the ticket did not name: ten steps that printed a success message for work they had not performed. Four of those predate the release. Note for #14, which works the same file: `upgrade-repo` is the M0 refactor's proving case, so #14 should follow M0 rather than race it.

**#17 is landed**, so the blocker it described is gone: monorepo discovery no longer returns zero projects silently on macOS/BSD, and the `iconrc` sync no longer no-ops forever. A fix to #15 can now actually be verified on those platforms instead of looking correct because it fails quietly either way.

Two things #17 changed about how the rest of this list should be approached:

- **`.context/standards/shell-portability.md` now has rules 7 (`grep -P`) and 8 (`sed -i`)**, and its Testing Pattern section carries the lesson that a portability fix must be *executed in the exact form the document prints*, not reviewed. #17 needed three review rounds; two of them found a defect the previous round's own remediation had introduced.
- **A portability fix can trade a loud failure for a silent one.** `mktemp -p` hard-errors on macOS ≤ 13.x, but on macOS 14+ a mid-string `XXXXXX` silently produces a fixed filename with exit 0. Linux CI plus one manual test on a current Mac shows green either way. Relevant to #26.

**#14 before #16/#18** only because it introduces the new schema-version field, which #31 reads later. #16 and #18 are independent of everything.

Note for anyone touching `context_template/`: #17 took the template schema to **1.13**.

---

## Milestone 2 — Release safety

```
#20  json-validation-and-schemas        → gives #19 a validator to call
#19  release-preflight-and-rollback
```

**#20 first.** The pre-flight gate wants to assert "the manifest is valid" as one of its checks; building the validator first means #19 calls it rather than reimplementing it. Today nothing anywhere parses JSON, and the documented `python3` check does not execute on Windows.

---

## Milestone 3 — Standardize on Node   ← runs second, after M0

```
#22  node-detection-skill               → both migrations below can then assume a verified runtime
#21  replace-python3-with-node
#23  migrate-scripts-to-node            ← scope widened to fenced SKILL.md blocks
```

**#22 first**, because the other two increase reliance on Node and the detector is what makes that safe. Note it cannot itself be a `.mjs` script.

**#23's scope now includes fenced bash/PowerShell pairs inside `skills/*/SKILL.md`**, not only `.sh`/`.ps1` files. Those pairs are linted by nothing — the pre-commit shellcheck gate fires only on staged `*.sh` (#48) — and ICON-0094 spent roughly half its six review passes on defects that exist solely because one behaviour is written twice in two languages: a guard that failed open on one side only, a missing `[regex]::Escape`, a `catch` that abandoned its own handler under `Set-StrictMode`, and PowerShell accepting regexes bash rejects. `skills/upgrade-repo/SKILL.md` is the dominant instance and is also M0's proving case, so take it after M0's split.

---

## Milestone 4 — Enforcement

```
#24  ci-backstop-existing-checks        → makes every gate below actually binding
#25  generate-check-inventory           → mis-ranked low; do it early or gate docs rot again
#27  three-fail-closed-checks
#28  skill-metadata-check
#29  harden-security-workflow
#30  registry-driven-checks
#26  portability-check                  ← #17 landed; still needs #24
#31  template-drift-notice              ← needs M1 #14 (the new schema field)
#32  record-checks-not-built            (independent; 10 minutes)
#48  shellcheck-blind-to-md-fences      ← pairs with #26; share one fence extractor
```

**#26 and #48 are the same problem seen from two sides.** The pre-commit shellcheck gate only fires on staged `*.sh`, so fenced bash inside `SKILL.md` — where most of ICON's consumer-executed shell actually lives, and where three of #17's four defect sites were — has never been checked by anything. Both need an extractor that pulls fenced blocks out of markdown, and both hit the same false-positive problem (fragments that aren't standalone scripts, variables defined in surrounding prose). Build the extractor once.

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
M0 #51  →  M3 #23                       (split instructions before migrating code)
M0 #51  →  M1 #14                       (same file; don't race the refactor)
M1 #17  →  M4 #26                       ✅ satisfied (#49)
M1 #14  →  M4 #31
M1 all  →  M6 #42
M4 #24  →  everything else in M4
M5 #35  →  M6 #43
M5 #33  →  M6 #39
M2 #20  →  M2 #19
M3 #22  →  M3 #21, #23
M4 #48  ↔  M4 #26                       (shared fence extractor, not an ordering)
```

Everything not listed above is independent and can be picked up in any order.

---

## Filed during roadmap work — not yet slotted

| Issue | What | Why it isn't in a milestone yet |
|---|---|---|
| #46 | GNU-only `grep -P` / `\K` / octal-parse defects in ICON's **own** non-shipped docs (`.context/workflows/commit-conventions.md:58,89,91`), plus 9 residual `head -1` in shipped markdown | Doesn't reach consumers, so it missed #17's scope — but `:58` is load-bearing for `release-plugin` Step 2's release-boundary search, and ICON's task IDs are past `0090`, so the octal bug is live for maintainers on macOS |
| #47 | `context_template/UPDATE_LOG.md` ships ICON's internal decision log into every consumer repo | Needs a design call — whether the file belongs in the template at all — not a substitution. Genericizing it leaves a header and nothing else |

---

## Not building — decided

Recorded in #32 so they don't return as findings next cycle.

- **Skill size gate** — ~~its entire violation population is one file. A gate whose finding set is a single known file is a bug report with CI attached.~~ **Overturned by measurement (ICON-0095, 2026-07-27).** The one-file claim rested on a word-count measure of `SKILL.md` alone. Measured in bytes across `SKILL.md` *and* companions, the population is **11 findings across 8 distinct skills** — seven `SKILL.md` over 16,000 B and four companions over 8,000 B. The gate now ships advisory under ADR-016 and becomes blocking once #24 lands a CI backstop. Issue #32, which records these decisions, carries the same stale claim and needs the same correction.
- **Broad ordered-list resolver** — trains authors to renumber until green without checking the referent. The narrow form (require a section name beside `Step N`) is kept.
