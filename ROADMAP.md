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
| ICON-0096 | #55 | node-detection skill (#22) — `check-node-runtime`, the hook's silent paths given a visible signal, `$LASTEXITCODE` fail-open documented |
| ICON-0097 | #57 | `python3` → Node (#21) — 9 sites, 3 of them behaviour fixes; prune-first deleted from the split rule; `shell-portability` and `context-maintenance` split |

Also landed inside those: `.context/domains` hook count + matcher literal, stale single-hook claims in 3 files, `## Related` graph seam across 20 docs, git hooks made executable (they were silently dead on fresh macOS/Linux clones), `skill-decomposition` index tallies removed. From ICON-0093 specifically: two latent bugs in the shipped task-ID generator (`$MAX` never assigned; zero-padded IDs parsed as octal), a fail-open `sed` guard in `/upgrade-repo`, and a gawk escape warning firing on every retrospective append.

---

## Reordered — 2026-07-27

Two maintainer decisions changed the running order. Milestones keep their original numbers so existing cross-references stay valid; **execution order is now M0 → M3 → M1 → M2 → M4 → M5 → M6.**

```
M0  #51  hot-cold-skill-separation      ✅ DONE (#52)
M3  #22 → #21 → #23                     ✅ DONE (#55, #57, #58) — ADR-017 settled
M3  #59, #60, #61, #56                  ← current; migration waves + the iconrc writer
M1  #14, #16, #18                       (#17, #15 done)
M2 … M6                                 unchanged
```

**M0 is landed.** ADR-016 caps `SKILL.md` at 16,000 bytes and companions at 8,000, with a 2,000-byte floor; `skill-decomposition/hot-cold-path.md` carries the authoring rules. Three things follow for the work below:

- **The cut follows the condition, not the topic** — one companion per if→then block, all siblings of `SKILL.md`, none referencing another. Nesting is not available: a file referenced *from* a referenced file may be `head`-previewed rather than read, silently.
- **The advisory gate reports 11 findings across 8 skills today.** It becomes fail-closed once **#24** lands a CI backstop; two things must be settled first (it measures the working tree rather than the staged blob, and is line-ending sensitive), both recorded against ADR-016's promotion condition.
- **`upgrade-repo` was deliberately not the proving case** for either M0 or M3 — its platform axis cross-cuts every mode branch, so splitting before the migration writes companion pairs the migration then deletes. Split (#42) first, migrate (#61) second.

**Why M0 first.** A skill's whole `SKILL.md` loads on invocation, but a run executes only part of it — and ADR-008's scope explicitly excluded on-demand skills, so until ADR-016 nothing governed this at all. Hot/cold decides where *instructions* live; M3 decides where *code* lives. Designing the former first means the `.mjs` migration lands content in the right structure instead of moving it twice.

The load-bearing number is not size but **survivability**: Claude Code re-attaches each skill after compaction keeping only the **first 5,000 tokens**. `skills/upgrade-repo/SKILL.md` at **92,797 B ≈ 23,000 tokens is ~4.6× past that**, so roughly 78% of it is silently dropped on every compaction today — no error, no warning. ADR-016 sets the caps in **bytes** (`SKILL.md` ≤ 16,000, companion ≤ 8,000, floor 2,000); measure with `wc -c`.

*(Two figures previously stated here were wrong and are corrected above: the "a fifth" estimate inherited from #51 measures at ~36%, and the word count has been restated in the governing unit so the roadmap does not circulate a fifth measure.)*

**Why M3 before M1/M2.** ICON-0094 needed six review passes, and after the first round nearly every Critical was PowerShell-specific or a bash/PowerShell divergence — the exact asymmetry #23 exists to remove. Every further fix inside a `SKILL.md` pays that doubled cost. **Standing policy, now permanent and codified in ADR-017: no new PowerShell twins.** The existing ones come out over #59, #60 and #61.

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
#22  node-detection-skill               ✅ DONE (#55) — the runtime is now verifiable
#21  replace-python3-with-node          ✅ DONE (#57) — 9 sites; 6 more ticketed to #23 and #56
#23  migrate-scripts-to-node            ✅ DONE (#58) — ADR-017 settled; proved on icon-init
#59  migrate-fenced-blocks-waves-1-2    ← next; wave 1 leads with a Windows bug (4 python3 heredocs)
#60  migrate-sh-ps1-script-files        ← #23's original scope; sequence after #48
#61  migrate-upgrade-repo-fences        ← 67.6% of the target; blocked on #42's split
#56  create-iconrc-config-writer        ← spun out of #21; a contract change across 5 call sites
```

**#23 is done, and it was widened twice before it landed.** Its original scope was the five `.sh`/`.ps1` script *files*. The real target is executable content **wherever it lives** — and most of it lives in fenced blocks inside `SKILL.md`, not in scripts. Measured: **164 blocks, 126,041 B, of which 78 are deterministic (99,137 B, 78.7%)**. The rule was settled as **ADR-017** and proved on `icon-init`; the remaining waves are #59, #60 and #61. The rule ADR-017 settled:

| Content | Home |
|---|---|
| judgement, branching, "decide whether…" | prose in `SKILL.md` |
| trivial — fixed-argument tool calls, no control flow | fenced, as-is |
| illustrative — output to recognise, not run | fenced, as-is |
| deterministic execution — parse, walk, rewrite, validate | inline `node -e`, or a committed `.mjs` on one of four triggers |

**Size is explicitly disqualified as an extraction trigger.** A `.mjs` is invisible to the ADR-016 gate, so if being over cap could justify extraction the two rules would fight and migration would become cap-evasion. `icon-init` grew slightly; that is the expected outcome, not a failure.

Three problems move under that rule rather than one at a time, because a `.mjs` needs no PowerShell twin and does not count against a `SKILL.md` cap. **ICON-0098 disproved the third leg of this claim**: a `.mjs` is *not* shellchecked — no JavaScript correctness linter exists anywhere in this repo, and `semgrep --config p/ci` is a security ruleset, not a lint. Migration shrinks #48's surface; it does not close it.
- **#48** — the pre-commit shellcheck gate fires only on staged `*.sh`, so fenced bash is linted by nothing. That is where most consumer-executed shell lives. Migrated blocks leave that surface; the residual bash preamble stays in it, unlinted.
- **the twin convention** — #23's own body says it *"has drifted three times"*, and the only thing holding the pairs together is a byte-parity check that exists *because* they drifted. **That check does not retire**: it polices cross-skill *copies*, not bash/PowerShell twins, and migration refills its population rather than emptying it. #23's retirement task is closed won't-do; the group list belongs in #30's data file.
- **ADR-016** — `upgrade-repo` is 92,797 B and **1,253 of its 1,631 lines are inside code fences**. The size problem is largely a code-in-prose problem — but per ADR-017 that is #42's job, not the migration's.

ICON-0097 demonstrated the mechanism: it **collapsed three PowerShell twins rather than maintaining them**, verified under PowerShell 7, because a `node -e` invocation is shell-agnostic. A Node rewrite is the twin-removal tool, not something needing a twin of its own.

**#22 and #21 are landed**, so the runtime is verifiable and the one-liner sites are done. Findings from both that bind the rest:

- **Never guard on exit status to test whether a command exists.** PowerShell does not update `$LASTEXITCODE` on `CommandNotFoundException` — the exception fires before any process starts, so a missing binary leaves the previous value in place and the guard reports success. Measured on 7.6.3 and 5.1; bash returns 127, cmd returns 9009. The failure is **directional** — present-and-working updates correctly — so happy-path testing cannot find it. Read the command's **output**. `shell-portability/testing-pattern.md` carries it as the fourth shape of the PowerShell fail-open family.
- **Two Node floors, stated separately.** Technical: the **12.20 / 14.13** line, imposed by the hooks' `node:`-prefixed imports. Supported: the lowest major still receiving security updates, with the value, its measurement date and its source — because a bare EOL-derived integer in shipped content goes wrong once a year in silence. `check-node-runtime` is the reference; do not introduce a third number.
- **The `python3` adjacency is closed, but `python3` is not gone.** ICON-0097 removed it from `icon-init` and `icon-status`, so the two skills that report whether Node is present no longer use an unverified runtime to check for a runtime. **Four heredocs remain** in `skills/plugin-design/audit-phase-structure.md` and `audit-phase-consistency.md`, which means those audit phases do not run on a stock Windows box. #59 wave 1 leads with them.

**The twin problem is what the remaining waves buy.** ICON-0094 spent roughly half its six review passes on defects that exist solely because one behaviour is written twice in two languages: a guard that failed open on one side only, a missing `[regex]::Escape`, a `catch` that abandoned its own handler under `Set-StrictMode`, and PowerShell accepting regexes bash rejects. ADR-017 removes the twin at the source — a Claude Code invocation fence is **untagged** because `${CLAUDE_SKILL_DIR}` is substituted before the model reads it, making the line byte-identical in every shell. Copilot CLI has no path variable, so ~4 lines of bash preamble survive per migrated skill; that is the whole residue.

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
M0 #51  →  M3 #23                       ✅ satisfied (#52 → #58)
M0 #51  →  M1 #14                       (same file; don't race the refactor)
M1 #17  →  M4 #26                       ✅ satisfied (#49)
M1 #14  →  M4 #31
M1 all  →  M6 #42
M4 #24  →  everything else in M4
M5 #35  →  M6 #43
M5 #33  →  M6 #39
M2 #20  →  M2 #19
M3 #22  →  M3 #21, #23                  ✅ satisfied
M3 #23  →  M3 #59, #60, #61             ✅ satisfied (ADR-017 governs all three)
M6 #42  →  M3 #61                       (split upgrade-repo before migrating its fences)
M4 #48  →  M3 #60                       (the .sh files lose their only gate until #48 lands)
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
