# Process Skills Audit — Raw Findings

**Domain**: 02 — Orchestration and discipline skills
**Audit**: ICON-0089 (2026-07-26), plugin v2.0.0 + `[Unreleased]` (ICON-0088)
**Prior baseline**: ICON-0058 (2026-06-10, v1.19.0 + `[Unreleased]`)
**Structural check**: `bash .claude/skills/icon-audit/scripts/structural-check.sh` → **all checks passed** (B.1, B.2, B.3, B.4, B.6 OK).

---

## Summary

The domain's *defect* posture improved materially since ICON-0058: the single Moderate (M-P-0058-1, the `##` vs `###` retrospective-template mismatch that would silently reject consumer entries) is **fixed in both copies**, and the triple-`verification-checklist` redundancy (m-P-0058-1) is **fixed** by an explicit single-owner statement at `agents/manager.agent.md:214` and a deferral note at `skills/task-retrospective/SKILL.md:129`. The 2.0.0 phase-template surface is in better shape than expected: all five `phase-*.md` templates exist in both the shipped and internal trees, each carries exactly one `## Phase Entry` and one `## Phase Exit`, and the `Section Guidance` bodies are semantically equivalent across the two copies.

What the interval did *not* do is reconcile the older, pre-session-per-phase layer of `task-plan` with the model that replaced it. Four net-new Moderates all trace to the same root: **session-per-phase was added alongside the on-demand phase-skill model rather than superseding it**, and the seams where the two meet were never swept. `task-plan/SKILL.md` now contains two mutually contradictory descriptions of how phases are selected (§19–36 vs §38–63); its Built-in Fallback Format omits the two sections (`## Phase State`, `## Phase Handoff Log`) that all five phase skills fail closed without; the **shipped** `base.md` preamble still enumerates a nine-section "core sections agents depend on" list that omits both, while the ICON-internal copy was updated with a reconciling paragraph; and `## Review Checkpoint` — the artifact close-gate item (1) keys on, fail-closed — is specified in no template at all. Three Minors carry forward, one of them **regressed**: `task-plan-phase-completion` still asserts "Keep this skill minimal" while having grown 832 → 1,459 words (+75%) since ICON-0058, and ADR-008 explicitly exempts phase skills from the only word budget in the system, so nothing catches it.

On the user-directed **script-offload** lens, this domain is as dense a source as predicted, and unusually well-evidenced: three of the eight candidates below are backed by *named, already-occurred* failures recorded in `.context/retrospectives.md` where the retro itself states no gate caught the problem, and one (the ADR-008 word-count gate) is named as "Candidate for a future hook" **by the ADR itself**. The strongest single candidate — a retrospectives separator/entry-count cross-check — would replace ~600 words of triplicated prose (200 words × 3 files) that asks an LLM to remember a two-command comparison, with roughly ten lines of shell in a hook that already reads that exact file.

---

## Defect Findings

### Critical

**None observed.**

### Moderate

#### M-P-0089-1 — `task-plan` describes two contradictory phase-selection models in one file

`skills/task-plan/SKILL.md:19–36` (§ Phase Skills (On-Demand)) states:

> "For medium and complex tasks, phase skills give structured guidance for the task's **primary concern**. The manager identifies the concern at task start and loads **ONE matching skill — not all skills in sequence**."

`skills/task-plan/SKILL.md:38–47` (§ Phase Plan & Phase-Per-Session Model) states, for the *same* task class:

> "**Medium and complex tasks** record a per-task phase plan in `plan.md` `## Phase State`: an **ordered subsequence** of the canonical five phases … A pure refactor might be `[implementation, testing, completion]`; an investigation-heavy task uses all five."

These cannot both govern. The first says one skill total, selected by primary concern; the second says an ordered sequence of phases, each loading its own skill, `completion` always last. The § Phase Skills table at `:25–31` reinforces the superseded reading by listing `task-plan-phase-completion` as the entry for "Closing any task" *within a one-skill-only selection model*.

The second model is the live one — `agents/manager.agent.md:41` dispatches on a phase directive, `agents/manager.agent.md:83` requires a handoff block at each boundary, and all five phase skills open with a Phase Entry protocol that presumes prior phases. The first is residue from the pre-2.0.0 model that was never removed.

- Files: `skills/task-plan/SKILL.md:19–36` (contradicting `:38–63`); reinforced at `:25–31`
- Classification: **Moderate** — `task-plan` is the router every phase skill defers to for the phase model ("This skill is a router", `:59`). A manager reading §19–36 first loads exactly one phase skill and never produces a handoff log, silently defeating cold-resume for that task. Net-new vs ICON-0058.

#### M-P-0089-2 — `task-plan` Built-in Fallback Format omits the two sections every phase skill fails closed without

`skills/task-plan/SKILL.md:76–100` defines the Built-in Format used when `.context/workflows/task-plan/base.md` is absent (`:14–17` — "Built-in format below — only if `base.md` is absent"). Verified section list: `Task`, `Branch`, `Objective`, `Folder`, `Decisions`, `Key Files`, `Progress`, `Open Questions / Blockers`, `Constraints`. Grep for `Phase State` / `Phase Handoff` across `:76–101` returns **0**.

Every one of the five phase skills opens by requiring both:

- `skills/task-plan-phase-investigation/SKILL.md:19–29`
- `skills/task-plan-phase-architecture/SKILL.md:20–30`
- `skills/task-plan-phase-implementation/SKILL.md:19–29`
- `skills/task-plan-phase-testing/SKILL.md:20–30`
- `skills/task-plan-phase-completion/SKILL.md:19–30`

each of the form: "Read `## Phase State`, confirm this run's phase matches `Current`/`Next` … and **fail closed** — if a required input is missing … STOP and surface the gap."

A repo on the fallback path therefore gets a `plan.md` with no `## Phase State`, and the first phase-skill entry check must fail closed on a required input that the plan format it was told to use never provides. The two outcomes are both bad: the phase halts, or the agent rationalizes past its own fail-closed rule on the first task.

- Files: `skills/task-plan/SKILL.md:76–100`; failing entry contracts at the five sites above
- Classification: **Moderate** — an unsatisfiable fail-closed gate on the fallback path. Net-new vs ICON-0058 (the fallback predates session-per-phase; the 2.0.0 change added the requirement without updating it).

#### M-P-0089-3 — Shipped `base.md` preamble's "core sections" list omits Phase State / Phase Handoff Log; the ICON-internal copy was fixed and the template was not

`context_template/context/workflows/task-plan/base.md:1` is `<!-- template-version: 1.1 -->`; its preamble at `:8–10` reads:

> "Keep the core sections (Task, Branch, Objective, Folder, Decisions, Key Files, Progress, Open Questions/Blockers, Constraints) — **agents depend on these headings**. Add team-specific sections after Constraints."

`.context/workflows/task-plan/base.md:1` is `<!-- template-version: 1.2 -->` and carries a reconciling paragraph the shipped copy lacks, at `:13–16`:

> "`Phase State` and `Phase Handoff Log` are additive phase-handoff sections (see ADR-013 / the session-per-phase design). They carry the cross-session cold-resume state; they supplement — never replace — the required core sections above."

Both files' `## Template` blocks *do* contain the two sections (`context_template/…/base.md:21,36`), so the shipped file contradicts itself: the template shows two sections the preamble's authoritative enumeration excludes and then invites the consumer to treat anything outside that enumeration as optional/team-specific. A consumer trimming their `base.md` to "just the core sections agents depend on" removes exactly the two sections all five phase skills fail closed on.

This is a textbook instance of the failure class ICON-0088 promoted a standard about — `.context/retrospectives.md:2` trap (2): "A parenthetical member enumeration at a **satellite** site … went stale the instant the exempt class widened — and it was the site an agent consults for exactly that obligation. Satellites point by reference; only the canonical site enumerates. **Caught by @reviewer, not by any gate.**"

- Files: `context_template/context/workflows/task-plan/base.md:8–10` (vs `:21,36`); compare `.context/workflows/task-plan/base.md:8–16`
- Classification: **Moderate** — consumer-facing. This is the shipped artifact; the internal copy being correct means the divergence is invisible to anyone testing inside the ICON repo. Net-new vs ICON-0058. (Directly echoes ICON-0058 Structural Observation 2: "Template divergence is the highest-risk structural gap for consumer repos.")

#### M-P-0089-4 — `## Review Checkpoint` is load-bearing for the fail-closed close-gate but is defined in no template

Close-gate item (1), `agents/manager.agent.md:218`, is fail-closed on this artifact:

> "(1) @reviewer has covered every code change up to the current changed-file set: **satisfied by the `plan.md` `## Review Checkpoint`** if no @coder/@tester step ran after it; otherwise (code changed after it, **or no checkpoint**) re-run @reviewer over that diff first (fail-closed default)"

It is also the completion-phase entry contract (`skills/task-plan-phase-completion/SKILL.md:24`), the testing-phase entry contract (`skills/task-plan-phase-testing/SKILL.md:25`), the re-review condition (`agents/manager.agent.md:213`), and an anti-rationalization row (`agents/manager.agent.md:263`).

The only place its *creation* is described is `skills/task-plan-phase-implementation/SKILL.md:87–88`: "record a `## Review Checkpoint` **line** in `plan.md` naming the reviewed step and findings-resolution status."

No template defines it. It appears in neither `## Template` block (`context_template/context/workflows/task-plan/base.md:14–56`, `.context/workflows/task-plan/base.md:19–…`), nor in `task-plan`'s Built-in Format (`skills/task-plan/SKILL.md:78–100`). Its shape is self-contradictory across sites — referenced everywhere as a `##` section, but authored as "a line". Whether it goes before or after `## Constraints` is unstated, and `base.md:10` says team-specific sections go after Constraints, which a `##`-level Review Checkpoint would be indistinguishable from.

Consequence: the single most consequential gate in the close path (review coverage) keys on an artifact with no specified location, no specified shape, and no template slot — which is also precisely why it cannot currently be mechanized (see **S6**).

- Files: `agents/manager.agent.md:213,218,263`; `skills/task-plan-phase-completion/SKILL.md:24,53`; `skills/task-plan-phase-testing/SKILL.md:25`; `skills/task-plan-phase-implementation/SKILL.md:87–88`; absent from `context_template/context/workflows/task-plan/base.md` and `skills/task-plan/SKILL.md:78–100`
- Classification: **Moderate** — undefined shape for a fail-closed gate's evidence artifact. Net-new vs ICON-0058.

### Minor

#### m-P-0089-1 — `Does NOT cover` footer gaps persist into a third audit cycle

- `skills/task-plan-phase-investigation/SKILL.md:149–150`: "architecture review, implementation phase, testing phase, retrospective." — omits **completion**.
- `skills/task-plan-phase-architecture/SKILL.md:102`: "investigation, implementation phase, testing phase, completion." — omits **retrospective**.

The other three footers are complete: implementation `:118–119`, testing `:121–122`, completion `:144–145` (correctly silent on retrospective, which it owns internally).

Reported as ICON-0046 IO-P-2, re-reported as ICON-0058 m-P-0058-2, unchanged in both files. No CHANGELOG entry indicates an attempted fix.

- Classification: **Minor**, carry-forward (third cycle). Trivial to fix; the persistence is the signal — see **S8**.

#### m-P-0089-2 — `task-plan-phase-completion` "Keep this skill minimal" regressed 832 → 1,459 words (+75%)

`skills/task-plan-phase-completion/SKILL.md:12–13`:

> "**Keep this skill minimal** — it loads at the end of every task; token cost matters."

Measured body: **1,459 words / 10,694 bytes** — the largest of the five phase skills by a wide margin (investigation 948, implementation 811, testing 779, architecture 693). ICON-0058 measured it at 832 words and flagged the unbounded claim as m-P-0058-3; it has since grown 75%.

The largest single contributor is the ~200-word **Merge-coalescing hazard** paragraph at `:105`, which is duplicated verbatim in two more files (see **S1**).

The self-reference violation is sharper than a generic size complaint, because the skill's own stated rationale is frequency of loading. Under the only per-skill budget in the system — `skills/writing-skills/SKILL.md:269` "Frequently-loaded skills: < 200 words" — a skill that by its own text "loads at the end of every task" is the definition of frequently-loaded, and it is 7.3× that figure.

Checked for a superseding ADR per the brief's consult-before-tiering rule: **ADR-008 does not apply.** `.context/decisions/008-always-loaded-token-budget.md:31` explicitly carves it out — "Phase skills, sub-agent files, and on-demand skills are NOT in the always-loaded set and do not count toward the trigger." So no budget, trigger, or gate in the system observes this file's growth.

- Files: `skills/task-plan-phase-completion/SKILL.md:12–13` (claim), `:105` (largest contributor); budget at `skills/writing-skills/SKILL.md:266–271`; carve-out at `.context/decisions/008-always-loaded-token-budget.md:31`
- Classification: **Minor**, carry-forward and **regressed**.

#### m-P-0089-3 — Two phase skills give contradictory instructions on whether `design-first` is ever invoked

- `skills/task-plan-phase-investigation/SKILL.md:140–141`: "**`design-first`**: When investigation reveals multiple valid implementation approaches, **invoke** to explore and select one before planning."
- `skills/task-plan-phase-architecture/SKILL.md:96–97`: "**`design-first`**: A user-invocable skill for starting an architectural change; **no agent currently invokes it in this workflow**."

The architecture skill's claim is falsified by the investigation skill sitting one directory over. `skills/design-first/SKILL.md:5` is `user-invocable: true` and its description frames it as an optional pass, consistent with the investigation site.

- Files: `skills/task-plan-phase-investigation/SKILL.md:140–141`; `skills/task-plan-phase-architecture/SKILL.md:96–97`
- Classification: **Minor** — a reader consulting the architecture skill concludes an available design pass is dead machinery. Net-new (not reported in ICON-0058; likely latent since before it).

#### m-P-0089-4 — `systematic-debugging` is cited as owning "the numeric trigger" but states two different numbers

Three sites defer to it with the definite article:

- `skills/task-plan-phase-implementation/SKILL.md:72`: "the manager escalates by invoking `systematic-debugging` — **that skill owns the numeric trigger**."
- `skills/task-plan-phase-implementation/SKILL.md:109–110`, `skills/task-plan-phase-testing/SKILL.md:89–91,113–115`: same phrasing.

The owning skill states two thresholds and labels neither:

- `skills/systematic-debugging/SKILL.md:4` (frontmatter): "Use when a bug persists after **2+** fix attempts on the same issue"
- `skills/systematic-debugging/SKILL.md:72–73` (Escalation Rules): "Fix attempt **1-2** fails → Re-read the error carefully"; "Fix attempt **3** fails → Stop."
- `skills/systematic-debugging/SKILL.md:104` (Red Flags): "**Three or more** fix attempts have failed"

The two numbers are arguably distinct obligations (2+ = when to *load*; 3 = when to *stop and re-trace*), and that reading is coherent — but nothing in the file says so, and the three deferring sites ask for "the numeric trigger" as a single value in a context (an agent stalling) where either could apply.

- Classification: **Minor** — ambiguity in a rule three other skills delegate to by reference. Net-new.

#### m-P-0089-5 — `check-rules-index.sh` has no PowerShell sibling, unlike both of its script neighbours

`skills/context-maintenance/scripts/` contains `append-retrospective-entry.{sh,ps1}` and `context-graph.{sh,ps1}` — but `check-rules-index.sh` only. `skills/context-maintenance/SKILL.md:260–292` documents Claude Code (Bash) and Copilot CLI (Bash) invocations and no PowerShell variant, while the sibling reference for `context-graph` (`:299`) explicitly documents "both the `.sh` and `.ps1` variants."

The script is not optional: `skills/context-maintenance/SKILL.md:93` makes it mandatory for the Index-coverage-gap audit ("**Detect with `check-rules-index.sh` — do not hand-scan**") and `.githooks/pre-commit:755` invokes it as a hard gate (`|| exit 1`).

Noted as a parity/consistency gap rather than a functional break — ICON's own environment supplies Git Bash, and the pre-commit hook is Bash throughout.

- Files: `skills/context-maintenance/scripts/`; `skills/context-maintenance/SKILL.md:93,260–292`; `.githooks/pre-commit:746–755`
- Classification: **Minor**. Net-new.

---

## Common Check Patterns — Coverage

Per the brief, each pattern applied to every in-scope file; "no instances" recorded explicitly.

1. **Self-reference violation** — **Instances found**: m-P-0089-2 (`task-plan-phase-completion` asserts minimality at 1,459 words). Also observed as a domain-wide pattern, reported as **Observation 3** below rather than as a per-file defect, because `writing-skills:271` ("Complex discipline skills: can go longer, but earn every line") is an unbounded self-asserted escape hatch that makes per-file tiering unsound.
2. **Template / standard cross-reference** — **No instances of broken cross-reference.** Verified every `phase-<name>.md` `## Phase Entry` / `## Phase Exit` target cited by the five phase skills resolves in **both** trees (10/10 files present, each with exactly one of each heading); `base.md` Section Guidance bodies semantically equivalent across copies; `context-document-guidelines § Folder Split Rule → Split Exemptions` cited by `context-maintenance:177` exists at `skills/context-document-guidelines/SKILL.md:47,80`. The one *content* divergence found is M-P-0089-3 (preamble, not a dangling reference).
3. **Operational defensiveness** — **Partial instances.** `context-maintenance` has a genuine dry-run equivalent (Phase 0 scope gate, `mode: audit` → "Modify no `.context/` files", `:63–74`) and explicit staging-not-committing semantics (`:208–210`). `append-retrospective-entry` is deterministic with a documented validation gate. **Gap**: no phase skill defines a partial-failure recovery path for a phase that fails *after* writing its handoff block but *before* committing it — the entry contract (`Phase-Handoff:` trailer on `HEAD`) will then fail closed on the next run with no stated remedy. Folded into **S2**.
4. **Frontmatter parser-fragility** — **No instances.** All 13 in-scope skills use `description: >` folded scalar on line 3 with consistent indentation. Verified mechanically across the full set.

---

## Script-Offload Candidates

Ranked by leverage. Every candidate was checked against the existing inventory first — `.githooks/pre-commit` is already a 975-line multi-gate harness with an accumulate-then-report idiom (`:477–580` staged-file classification; `:649–704` cap-literal gate; `:737–756` rules-index delegation; `:949–975` shellcheck arming), so **six of the eight below extend it rather than adding a new hook.**

### S1 — Retrospectives entry-separator / entry-count cross-check — **HIGH leverage × LOW effort**

**(a) Current LLM-carried obligation.** ~200 words of prose, triplicated verbatim (measured: 200 / 201 / 200 words), instructing an agent to remember a two-command comparison after any merge:
`skills/task-plan-phase-completion/SKILL.md:105`; `.context/workflows/task-plan/phase-completion.md:~105`; `context_template/context/workflows/task-plan/phase-completion.md:~105`. The operative sentence: *"**Cheap detection**: after any merge that touches `retrospectives.md`, confirm `grep -c '^### '` and an `awk RS=""` record count agree; a mismatch means a separator was coalesced and needs manual repair."*

**(b) Observed failure mode.** **Already occurred.** `.context/retrospectives.md:2` trap (4) and `:4` item (4) record the `merge=union` driver coalescing two branches' blank-line separators during the ICON-0086/ICON-0087 merge, undercounting the append script's `awk RS=""` parser by one against the heading count and causing the rolling-log cap to **over-retain**. The retro states it is *"invisible in rendered Markdown and **undetected by any pre-commit gate**"* and records that the coalesced separator had to be repaired by hand in the ICON-0088 pass.

**(c) Mechanization.** In `.githooks/pre-commit`, arm on `.context/retrospectives.md` ∈ staged files (the classifier at `:477–580` already has a `cap_check_files` arm touching this exact file, `:531–535`). Compute `grep -c '^### '` and an `awk 'BEGIN{RS=""}END{print NR}'` record count; on mismatch, `exit 1` naming the two counts and the likely coalesced boundary. **Fully fail-closed** — it is a pure equality assertion over one file with no judgment component. ~10 lines.

**(d) Residual judgment.** Which blank line to restore, and whether the affected entries should instead be re-appended via the script. The gate detects and localizes; a human/agent repairs.

**(e)** Low effort × high leverage. Also retires ~600 words of triplicated prose, directly reducing m-P-0089-2.

### S2 — Phase entry/exit contract verifier (`check-phase-state.sh`) — **HIGH leverage × MEDIUM effort**

**(a) Current LLM-carried obligation.** The fail-closed entry contract is restated in prose at **ten** sites — five phase skills (`task-plan-phase-{investigation:19–29, architecture:20–30, implementation:19–29, testing:20–30, completion:19–30}/SKILL.md`) plus five `phase-*.md` templates × two trees. Each asks the agent to verify, by reading: (i) `## Phase State` parses and `Current`/`Next` match this run's phase, (ii) every earlier phase is `done`, (iii) `HEAD` carries the expected `Phase-Handoff: <phase>` trailer, (iv) the tree is not unexpectedly dirty.

**(b) Observed failure mode.** No observed *entry-contract* failure yet — the mechanism is new in 2.0.0 and this audit found the templates internally consistent. But the adjacent precedent is exact and recorded: `.context/retrospectives.md:33` (ICON-0082) — the launcher *advertised* a bounded-retry guarantee while **nothing incremented the persisted `Attempts` field**, so the bare-cron realization would re-invoke forever. The retro's own lesson: *"A claimed safety/liveness bound is a hypothesis until you trace the mechanism that ENFORCES it actually fires in EVERY execution mode."* An entry contract enforced only by prose is that same unenforced bound. Note also that `Attempts` ownership is currently split between the launcher and the agent (`skills/generate-phase-launcher/SKILL.md:78–99`; `base.md` Section Guidance) — a script is the natural single owner.

**(c) Mechanization.** A new `skills/task-plan/scripts/check-phase-state.sh <plan.md> <expected-phase>` returning the ICON-standard 3-value contract already established for `context-graph` (`0` clean / `1` violation / `2` parser-or-environment error, per `.context/standards/secure-coding.md` Rule 11): parse `## Phase State` fields; assert phase ordering; `git log -1 --format=%B | grep -q '^Phase-Handoff: '`; `git status --porcelain`. Invoked as the literal first action of each phase skill's Phase Entry (`… || exit 1`), replacing ten prose restatements with one cited command. **Fail-closed by construction**, including "zero fields parsed on a non-empty plan ⇒ exit 2" so a parser bug cannot pass as clean.

**(d) Residual judgment.** Whether a dirty tree is *expected* (the phase legitimately in progress) vs anomalous; what to do once the gap is surfaced — resume, re-open a phase, or escalate. The script decides *whether the contract holds*, never *what to do about it*.

**(e)** Medium effort × high leverage. Highest structural payoff in the domain: it is the only candidate that converts the 2.0.0 session-per-phase model's central guarantee from advertised to enforced, and it collapses the domain's single largest block of duplicated prose.

### S3 — Markdown table column-count gate — **MEDIUM-HIGH leverage × LOW effort**

**(a) Current LLM-carried obligation.** Authoring care only. Promoted to prose at `.context/standards/terseness-calibration.md` (per `.context/retrospectives.md:4` item 3: "added the table column-count companion beside the existing row-count invariant").

**(b) Observed failure mode.** **Already occurred, silently.** `.context/retrospectives.md:2` trap (3): *"A 3-cell row written into a 2-column Markdown table silently drops its last cell at render — **the entire Correct Action column vanished** — and **no gate catches column-count mismatch**."* The dropped column was an anti-rationalization table's corrective-action column: the rule shipped with its operative half invisible.

**(c) Mechanization.** In `.githooks/pre-commit`, for staged `*.md`: detect GFM tables (header row + `|---|` delimiter row), count delimiter columns, assert every subsequent body row in the block has the same cell count. Report all offenders accumulate-then-report, matching the existing idiom at `:625–648`/`:665–704`. **Fail-closed.** Escape hatch: reuse the established `<!-- pre-commit:…-ok-start/end -->` region convention already used for dead-ref suppression (`.context/retrospectives.md:38`).

**(d) Residual judgment.** None for detection — column count is a pure syntactic invariant. Judgment is only in the fix (which cell was intended).

**(e)** Low effort × medium-high leverage. This domain is table-dense (every discipline skill carries a 2- or 3-column rationalization table), and the failure is *silent at render*, which is the worst detectability class.

### S4 — Intra-skill `Step N` / numbered cross-reference resolver — **MEDIUM leverage × MEDIUM effort**

**(a) Current LLM-carried obligation.** `skills/writing-skills/SKILL.md § Editing an Existing Numbered Skill` instructs the author to grep every `Step N` mention after an insert or renumber.

**(b) Observed failure mode.** **Occurred twice.** `.context/retrospectives.md:55` (ICON-0078): inserting a new Step 7 and renumbering left a stale "Step 8" cross-reference in Step 4 prose — *"caught by @reviewer, **not by any gate** … the dangling-reference class is **invisible to the pre-commit hooks**."* The same retro records ICON-0077 as the co-occurrence that justified promoting the rule. Two occurrences, prose-only remedy, explicitly noted as ungated.

**(c) Mechanization.** Extend `.githooks/pre-commit`'s existing `ref_check_files` dead-reference resolver (`:833–909`) with an intra-file pass: for each staged skill, collect the set of defined `## <skill>: Step N:` / `Phase N` headings, then assert every in-body `Step N` / `Phase N` reference resolves to a defined one. **Fail-closed.**

**(d) Residual judgment.** Whether a renumbering was intended at all, and which target a stale reference *should* point to. Detection is mechanical; retargeting is authorial.

**(e)** Medium effort (needs care to avoid false positives on prose like "Step 1-2 fails" at `systematic-debugging:72`) × medium leverage. Two recorded occurrences make it more than speculative.

### S5 — ADR-008 always-loaded word-count gate — **MEDIUM leverage × LOW effort**

**(a) Current LLM-carried obligation.** `.context/decisions/008-always-loaded-token-budget.md` requires a reviewer to manually re-run a `wc -w` inventory whenever a PR grows the manager or PM session by ≥5% of budget.

**(b) Observed failure mode.** **Occurred, and the ADR says so.** Its own Consequences section states: *"Reviewers must apply the trigger check manually; there is **no automated pre-commit lint counting session totals**. **(Candidate for a future hook.)**"* The recorded drift it failed to catch: *"the manager grew **+978 words** cumulatively (4,148 → 5,126) **without any single PR's net delta reaching 425 words**"* — the per-PR trigger provably misses slow accretion. As of the ICON-0088 re-inventory the manager session is **over budget outright** (8,685 / 8,500 = 102.2%) and the manager component is at 54.4% against a 40% cap.

**(c) Mechanization.** `.githooks/pre-commit` arms when any file in the ADR-008 always-loaded inventory is staged (`agents/manager.agent.md`, `agents/product-manager.agent.md`, the nine `shared/common-constraints.md` inlines, `skills/using-skills/SKILL.md` — the hook already syncs the common-constraints copies, so it knows this set). Sum `wc -w`, compare against the snapshot baseline and the 8,500/7,000 ceilings. **Deliberately fail-OPEN (warn, exit 0)** — per `.context/standards/secure-coding.md` Rule 11's runtime-vs-commit-time distinction, and because ADR-008 records *accepted* overages; a hard block would fail every commit today. The value is restoring the friction signal at the moment of growth, which the ADR names as its entire purpose.

**(d) Residual judgment.** Whether an overage is accept-with-rationale (the ADR's established mechanism) or must be trimmed. The script supplies the number; the ADR update is a judgment call.

**(e)** Low effort × medium leverage. Uniquely well-justified: the decision record itself specifies the hook.

### S6 — `## Review Checkpoint` coverage vs the changed-file set — **MEDIUM leverage × MEDIUM-HIGH effort (blocked)**

**(a) Current LLM-carried obligation.** Close-gate item (1), `agents/manager.agent.md:218`, fail-closed: confirm the checkpoint covers the current changed-file set, else re-run @reviewer. Restated at `:213`, `:263`, `skills/task-plan-phase-completion/SKILL.md:53–58`, `skills/task-plan-phase-testing/SKILL.md:25`.

**(b) Observed failure mode.** No observed failure yet in the interval. `.context/retrospectives-archive.md:17` records the gate being successfully dogfooded when introduced, and notes the fail-closed default is what prevents the conditional degrading into an escape hatch.

**(c) Mechanization.** Given a checkpoint that recorded the reviewing commit SHA, the check is mechanical: `git diff --name-only <checkpoint-sha>..HEAD` ∩ reviewable paths must be empty, else the gate demands a re-review. **Blocked on M-P-0089-4** — the checkpoint currently has no defined location, shape, or SHA field, so there is nothing to parse. The prerequisite is a template slot with a fixed shape (e.g. `## Review Checkpoint` with `- **Reviewed-at**: <sha>` / `- **Findings**: resolved|open`). Hook point: the same `check-phase-state.sh` from **S2**, run at completion-phase entry. Fail-closed once the shape exists.

**(d) Residual judgment.** Whether a given changed file is *reviewable* (a `plan.md` progress tick is not a code change), and the substance of the review itself — entirely LLM work. The script answers only "is there a checkpoint whose SHA covers every changed file?"

**(e)** Medium-high effort (requires the M-P-0089-4 schema fix first) × medium leverage. Sequenced *after* S2.

### S7 — `plan.md` required-section presence gate — **MEDIUM leverage × LOW effort**

**(a) Current LLM-carried obligation.** `base.md:8–10` ("agents depend on these headings") and `task-plan/SKILL.md:114–120` (§ When to Update) rely entirely on author discipline. `skills/task-plan-phase-completion/SKILL.md:36–39` is candid about the reliability of this class: *"Author-discipline checks degrade quickly — a 'remember to update plan.md' rule does not fire on the 30% of tasks where it matters most (the messy ones)."*

**(b) Observed failure mode.** No observed instance of a *missing section* in the interval. The skill's own quoted admission is the standing argument, and M-P-0089-2/M-P-0089-3 show the required-section set itself drifting across documents — which a gate reading one canonical list would have surfaced.

**(c) Mechanization.** In `.githooks/pre-commit`, arm on staged `.context/tasks/*/plan.md`: assert the canonical `## ` headings are present. Derive the expected set from `.context/workflows/task-plan/base.md` rather than hardcoding it, so the gate and the template cannot drift (this is what makes it worth more than a lint). **Fail-closed.**

**(d) Residual judgment.** Whether each section's *content* is accurate and reconciled — the entire substance of the five-item Reconcile checklist (`skills/task-plan-phase-completion/SKILL.md:41–49`). Section *presence* is mechanizable; section *truthfulness* is irreducibly judgment and must not be mechanized.

**(e)** Low effort × medium leverage. Naturally folds into S2's script.

### S8 — Phase-skill conformance matrix gate — **LOW-MEDIUM leverage × LOW effort**

**(a) Current LLM-carried obligation.** Keeping the five phase skills mutually consistent — each having a Phase Entry, a Phase Exit, and a `Does NOT cover` footer naming exactly the other four phases.

**(b) Observed failure mode.** **Occurred and persisted across three audits.** m-P-0089-1: `investigation:149–150` omits `completion` and `architecture:102` omits `retrospective`, first reported as ICON-0046 IO-P-2, re-reported as ICON-0058 m-P-0058-2, still unfixed. Three cycles of a human-caught, human-unfixed one-line defect is the strongest available argument that this class should not be carried by review attention.

**(c) Mechanization.** Extend `.claude/skills/icon-audit/scripts/structural-check.sh` (which already runs clean and owns exactly this kind of assertion — B.1 SKILL.md sections, B.6 frontmatter) with a B.7: for each `skills/task-plan-phase-*/SKILL.md`, assert one `## …: Phase Entry`, one `## …: Phase Exit`, and a `Does NOT cover:` footer whose named phases are the complement of that skill's own phase. **Fail-closed.** Cheapest possible siting — no new file, no hook change, and it runs as part of the audit that keeps re-finding the defect.

**(d) Residual judgment.** Whether a phase legitimately *should* cover a neighbour's concern (completion correctly omits `retrospective` because it owns it) — so the expected-set rule needs one documented exception, not a blanket complement.

**(e)** Low effort × low-medium leverage per-defect, but it closes a defect class that has survived three audits, which is its real argument.

**Ranked by leverage: S2 > S1 > S3 > S5 > S4 > S7 > S6 (blocked) > S8.**

---

## Improvement Opportunities

### IO-P-0089-1 — Adopt a "prose describing a deterministic check must cite the script that performs it" authoring rule

**Not a patch for any single finding** — a generalization of what S1/S3/S4 have in common. Three separate places in this domain spend 200–600 words instructing an agent to *perform a comparison a shell command performs better*: the merge-coalescing cross-check (triplicated, `skills/task-plan-phase-completion/SKILL.md:105` + 2 copies), the table column-count invariant, and the `Step N` re-grep. In each case the prose was written *after* the failure, as the remedy — and in each case the retro itself notes no gate catches it.

The rule: when a `.context/` standard or skill states an obligation whose check is expressible as a deterministic command over committed files, the doc must either cite the script that runs it or record why one is impractical. This gives `writing-skills` / `context-document-guidelines` a positive authoring test and converts the reflex "write a warning paragraph" into "write a gate, cite it in one line."

- **Effort**: low (one section in `writing-skills` or `context-document-guidelines`). **Impact**: high — it is the durable form of this cycle's entire script-offload directive, and it would have prevented three of the eight candidates above from ever becoming prose.

### IO-P-0089-2 — Extract the phase entry/exit contract to one canonical reference the phase skills cite by name

The Phase Entry and Phase Exit blocks are ~90% identical across five skills (verified: `investigation:19–29/122–134`, `architecture:20–30/78–92`, `implementation:19–29/91–105`, `testing:20–30/94–108`, `completion:19–30/119–133`), differing only in the phase name and a parenthetical entry-contract payload. With the two template trees, the same contract is restated **ten** times.

The phase skills already demonstrate the better pattern: `task-plan/SKILL.md:65–74` § Template-Override Rule states the rule once and each phase skill cites it in a single line ("**Template-override rule**: … see `task-plan` for the full policy"). Apply the identical treatment to the entry/exit contract — one canonical statement in `task-plan`, one line plus the phase-specific payload in each phase skill.

Pairs naturally with **S2**: once a script performs the check, the prose shrinks to a script invocation plus the payload list.

- **Effort**: medium (touches 5 skills + 10 template files; the sweep must be complete or it reproduces the drift class it fixes). **Impact**: high — removes the domain's largest duplication block, cuts `task-plan-phase-completion` toward its own minimality claim, and gives the contract a single site to change.

### IO-P-0089-3 — Give phase skills a declared token tier so `writing-skills`' budget has an enforcement surface

`skills/writing-skills/SKILL.md:268–271` states three tiers — frequently-loaded < 200 words, standard < 500, "complex discipline skills: can go longer, but **earn every line**." Measured against the 13 in-scope skills, the "< 500" tier has **zero** members (smallest: `task-plan-phase-architecture` at 693) and no skill declares which tier it belongs to, so the third tier's open-ended escape hatch absorbs everything. ADR-008 explicitly excludes phase and on-demand skills (`:31`), so no other budget applies either.

The forward-looking fix is not a trim pass — it is making the tier *declared and checkable*: add an optional frontmatter field (e.g. `token-tier: frequent | standard | complex`) and either recalibrate the numeric targets to the observed distribution or keep them and accept the overages explicitly, the way ADR-008 handles the manager. Either way the claim becomes falsifiable, and a gate (an S5 sibling) becomes possible.

This also gives m-P-0089-2 a real resolution: `task-plan-phase-completion` would have to declare `frequent` — consistent with its own "loads at the end of every task" rationale — and either meet that budget or record why not.

- **Effort**: low-medium. **Impact**: medium-high — converts the system's only per-skill budget from a dead letter into an enforceable surface.

### IO-P-0089-4 — Give the phase skills anti-rationalization coverage

Measured across the domain, the split is exact: all six `task-plan*` skills have **zero** `Rationalization` and **zero** `Red Flags` sections; all five discipline skills (`systematic-debugging`, `testing-discipline`, `verification-checklist`, `commit-discipline`, `design-first`) plus `context-maintenance` have at least one.

This is backwards relative to bypass risk. The discipline skills' rules are mostly self-contained and locally verifiable. The phase skills carry the system's *most* bypassable obligations — fail-closed entry contracts, "commit at the boundary", "run this LAST", "never rewrite earlier blocks" — each of which has an obvious, plausible-sounding excuse available ("the tree is dirty but it's just plan.md", "I'll write the handoff after the next step", "this phase clearly follows from the last one, no need to re-read"). `task-retrospective` is likewise uncovered despite being Hardcoded in the manager.

A 4–6 row table per phase skill, in the established format, targeting the specific excuses each contract invites.

- **Effort**: low-medium. **Impact**: medium-high — anti-rationalization tables are ICON's demonstrated mechanism for exactly this failure class, and the phase contracts are currently the largest uncovered surface.

### IO-P-0089-5 — Make `.context/` gates uniformly available on both shells, or state the Bash dependency once

`check-rules-index.sh` (m-P-0089-5) is Bash-only while its two `scripts/` neighbours ship `.ps1` parity, and `context-maintenance`'s Tooling section documents only Bash invocation paths for both script-backed audits. Rather than fixing one script, decide the policy: either (a) all skill-invoked gates ship `.sh` + `.ps1` parity, with the existing byte-parity discipline extended to cover the new pair, or (b) record a single explicit decision that ICON's gates assume a POSIX shell (Git Bash on Windows) and cite it from `shell-portability`, so the absence is intentional rather than an oversight a future audit re-flags.

- **Effort**: low (policy statement) to medium (full parity script). **Impact**: medium — removes a recurring ambiguity and prevents the same finding recurring each cycle.

---

## Process-Skills-Specific Structural Observations

### Observation 1 — Every net-new Moderate is a *seam* left by session-per-phase, not a defect *in* it

M-P-0089-1 through M-P-0089-4 share one root cause. The 2.0.0 session-per-phase machinery is, on inspection, well-built: templates complete in both trees, entry/exit sections present and singular, Section Guidance semantically equivalent across copies, `Attempts` ownership explicitly reasoned about in the launcher skill. What was not done is the *sweep* — the older on-demand-phase-skill model (M-P-0089-1), the fallback plan format (M-P-0089-2), the shipped template's core-section enumeration (M-P-0089-3), and the `## Review Checkpoint` schema (M-P-0089-4) were all left describing the pre-2.0.0 world.

This is precisely the **sweep incompleteness** class the baseline preamble names as a known-churning area, and precisely the lesson `.context/retrospectives.md:8` (ICON-0086) promotes: *"A feature removal is complete only when every DEPENDENT reference is swept, not just the feature's primary machinery."* The generalization this cycle supplies is that the rule holds for feature *replacement* as much as removal — and that the dependents most likely to be missed are the ones stating the **superseded** model, because a grep for the new model's identifiers (`Phase State`, `Phase-Handoff:`) finds every site that was updated and none of the sites that should have been.

A concrete gate follows: after introducing a model that supersedes another, grep for the *old* model's distinctive phrasing, not the new one's. Here, `grep -rn "loads ONE matching skill\|not all skills in sequence"` would have found M-P-0089-1 immediately.

### Observation 2 — The domain's remedy reflex is prose, and the retrospectives say prose is not catching these

Four separate entries in the current rolling log record a failure and note, in the entry itself, that **no gate caught it**: `.context/retrospectives.md:2` traps (2), (3), (4), and `:55` (ICON-0078). In every case the remedy shipped was a promoted prose rule — a standards section, a companion invariant row, a 200-word hazard paragraph triplicated across three files. In no case was a gate added, though in at least three the check is a one-liner (S1, S3, S8).

This is the "reach-at-the-moment-of-need" meta-finding from ICON-0058 in its most concrete form yet. ICON-0060 (reach automation), ICON-0069 (rules-index discoverability), and ICON-0088 (binding urgency) each attacked *reach* — making the right rule easier to find or harder to defer. None attacked *representation*: a rule expressed as prose must be reached to fire, so improving reach has a ceiling that a rule expressed as a gate does not have. IO-P-0089-1 is the proposed next move on that axis, and the eight script-offload candidates are its backlog.

### Observation 3 — The domain has no per-skill size signal, by explicit ADR carve-out

`.context/decisions/008-always-loaded-token-budget.md:31` excludes phase, sub-agent, and on-demand skills from the only measured budget in the system. `skills/writing-skills/SKILL.md:268–271` supplies targets with an unbounded third tier and no per-skill declaration. The result is that the 13 skills in this domain — 15,412 words in total, loaded selectively but repeatedly — grow with **no trigger, no snapshot, and no gate** of any kind. `task-plan-phase-completion`'s +75% between audits is what that looks like in practice, and the only reason it surfaced is that a prior audit happened to record a word count.

Worth flagging to synthesis as a cross-domain question rather than a domain-02 defect: ADR-008's carve-out was reasonable when phase skills were small and singular; under session-per-phase, one phase skill loads per session as a matter of design, which is closer to "always-loaded per session" than the carve-out assumed. Re-examining the carve-out's premise may matter more than trimming any individual file.

---

## ICON-0058 Delta

### Fixed since ICON-0058

| ICON-0058 ID | Description | Evidence of fix |
|---|---|---|
| **M-P-0058-1** (Moderate) | `context_template/…/phase-completion.md` shipped a `## Retrospective — [TASK-ID]` template incompatible with `append-retrospective-entry.sh`'s `### ` validation | **Fixed in both copies.** `context_template/context/workflows/task-plan/phase-completion.md:80–91` now ships `### [TASK-ID]: [Short description]` with `**Avoid**` / `**Repeat**` / `**Updated**`; `.context/workflows/task-plan/phase-completion.md:106–118` likewise. Both now carry a "Append via the `append-retrospective-entry` script — do not edit by hand" directive. Script validation unchanged at `skills/task-retrospective/scripts/append-retrospective-entry.sh:115–118`. |
| **m-P-0058-1** (Minor) | Triple-`verification-checklist` invocation across manager Step 2, retro Steps 6–7, and the close-gate, with no documented intent | **Fixed, via ICON-0058's recommended Option (a).** `agents/manager.agent.md:214` now reads "`verification-checklist` **runs once, at the close-gate** (Step 6, item 4); **don't invoke it separately here**." `skills/task-retrospective/SKILL.md:129` now defers explicitly: "The completion gate is owned by the manager's Task Completion close-gate … When running this retrospective **standalone** … invoke `verification-checklist` yourself." Single owner, documented standalone fallback. |

### Still present or partial

| ICON-0058 ID | Current status |
|---|---|
| **m-P-0058-2** — `Does NOT cover` footer gaps | **Still present, unchanged, third cycle** (ICON-0046 IO-P-2 → ICON-0058 m-P-0058-2 → ICON-0089 m-P-0089-1). `skills/task-plan-phase-investigation/SKILL.md:149–150` still omits `completion`; `skills/task-plan-phase-architecture/SKILL.md:102` still omits `retrospective`. Now proposed for mechanization (**S8**) rather than a fourth manual report. |
| **m-P-0058-3** — `task-plan-phase-completion` "Keep this skill minimal" unbounded | **Still present and REGRESSED.** 832 → **1,459 words** (+75%). ICON-0058's IO-P-0058-3 proposed a `≤ 850` word ceiling; no ceiling was added and the file has since exceeded that proposed figure by 72%. ADR-008:31 confirms no automated budget observes it. See m-P-0089-2 and IO-P-0089-3. |
| **IO-P-0058-4** — cross-reference from `task-plan-phase-completion` to the manager's close-gate | **Still absent.** `skills/task-plan-phase-completion/SKILL.md:135–145` § Relationship to Other Skills lists `task-retrospective`, `@context-specialist`, `commit-discipline`, `task-plan-phase-testing` — no mention of the (now five-item) close-gate at `agents/manager.agent.md:218`. A consumer using the phase skill as the workflow authority still cannot see the gate. Not re-tiered as a defect (it was an improvement opportunity, not a finding, in ICON-0058); carried forward as still-open. |

### Net-new

1. **M-P-0089-1** (Moderate) — `task-plan/SKILL.md:19–36` contradicts `:38–63` on phase selection. Introduced by the 2.0.0 session-per-phase addition, which added the new model without removing the old.
2. **M-P-0089-2** (Moderate) — `task-plan/SKILL.md:76–100` Built-in Fallback Format omits `## Phase State` / `## Phase Handoff Log`, making the five phase skills' fail-closed entry contract unsatisfiable on the fallback path.
3. **M-P-0089-3** (Moderate) — `context_template/context/workflows/task-plan/base.md:8–10` (template-version 1.1) core-section enumeration omits both phase sections; `.context/…/base.md:8–16` (1.2) was updated with a reconciling paragraph and the shipped copy was not. Consumer-facing.
4. **M-P-0089-4** (Moderate) — `## Review Checkpoint` has no template slot, no defined shape, and no SHA field, despite being the evidence artifact for fail-closed close-gate item (1).
5. **m-P-0089-3** (Minor) — `task-plan-phase-architecture/SKILL.md:96–97` asserts no agent invokes `design-first`; `task-plan-phase-investigation/SKILL.md:140–141` instructs invoking it. (Possibly latent before ICON-0058; not previously reported.)
6. **m-P-0089-4** (Minor) — `systematic-debugging` cited by three sites as owning "the numeric trigger" while stating both 2+ (`:4`) and 3 (`:73`, `:104`) without labelling which governs which obligation.
7. **m-P-0089-5** (Minor) — `check-rules-index.sh` lacks the `.ps1` parity both its `scripts/` neighbours ship, and is documented Bash-only despite being a mandatory audit step and a hard pre-commit gate.

### ADR consult log (per brief's consult-before-tiering rule)

- **ADR-007** (`2>/dev/null` ban scope) — no in-scope finding involves output suppression in any file. Not applicable.
- **ADR-009** (skill `description` callers) — no finding tiered on a missing caller list. Not applicable.
- **ADR-010** (carry-forward re-tier registry) — neither accepted carry-forward (m1 autonomous-script `2>/dev/null`; m9 DataScan-flavored examples) is touched by any finding above. No re-tiering of an ADR-010 item performed.
- **ADR-008** (always-loaded token budget) — **materially applied.** Its `:31` scope carve-out is what prevents m-P-0089-2 from being tiered as an ADR-008 violation, and is itself flagged for re-examination in Observation 3. Its Consequences section supplies the self-identified hook candidate in **S5**.
- **ADR-005** (no build step) — governs the verification substitute used throughout: the pre-commit hook run stands in for lint/test. Consistent with every gate proposed above being sited in `.githooks/pre-commit` or an existing `scripts/` entry rather than a new build-time tool.
