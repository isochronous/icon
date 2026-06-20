# Process Skills Audit — Raw Findings

## Summary

The process-skills domain is in solid shape at the SKILL.md level: both prior Moderate carry-forwards (M-P1 `design-first` hard-gate wording, M-P2 `task-plan-phase-completion` context-delegation routing) are confirmed fixed and the ICON-0006 agent-vs-skill-invocation SSOT is properly co-located and shipped with the plugin. The most actionable finding is a **Moderate structural drift**: all five phase-skill workflow-template distribution mirrors (`context_template/context/workflows/task-plan/phase-*.md`) are one or more template-versions behind their local counterparts at `.context/workflows/task-plan/phase-*.md`, with meaningful content divergence (not just version string drift). This violates the three-surface rule that ICON-0014 is codifying — and ICON-0014 itself is not yet merged, meaning the rule, the reconcile-plan.md gate, and the four surfaces it touches (manager.agent.md, mr-discipline, task-retrospective, task-plan-phase-completion/SKILL.md) are all pending. The secondary finding is a **long-standing Minor that has crossed into Moderate territory**: the `manager.agent.md:204` note ("retrospectives.md is written directly by the manager") contradicts `task-retrospective/SKILL.md:113` ("delegate entry insertion to @context-specialist"), and `agent-vs-skill-invocation.md` explicitly acknowledges this as "Known unresolved" without a resolution date or issue reference. Token-efficiency findings cluster around the five phase-skills: byte-identical frontmatter descriptions across all five, a 5× repeated template-override rule paragraph, and "Does NOT cover" footers with terminology drift relative to each skill's own Relationship section.

---

## Defect Findings

### Critical

None observed.

### Moderate

#### M-P-A: Distribution-mirror drift — all five phase-skill workflow templates out of sync

The local SSOT copies under `.context/workflows/task-plan/` are one or more template-versions ahead of their distribution mirror counterparts under `context_template/context/workflows/task-plan/`. This is an internal-consistency failure in the three-surface model ICON-0014 is codifying.

| File | Local version | Mirror version | Diff lines |
|------|--------------|----------------|-----------|
| `phase-completion.md` | 1.2 | 1.1 | ~70 |
| `phase-implementation.md` | 1.1 | 1.0 | ~43 |
| `phase-investigation.md` | 1.1 | 1.0 | ~64 |
| `phase-architecture.md` | 1.1 | 1.0 | ~56 |
| `phase-testing.md` | 1.1 | 1.0 | ~66 |

Representative delta for `phase-completion.md`: `.context/workflows/task-plan/phase-completion.md:1` (version 1.2) vs `context_template/context/workflows/task-plan/phase-completion.md:1` (version 1.1). The local file contains ICON-specific reviewer delegation fields (`Ticket: ICON-NNNN`, ICON-specific standards references), a hardened context-update checklist with script-invocation note ("Append via the `append-retrospective-entry` script — do not edit retrospectives.md by hand"), a `Release impact:` field in the Completion Summary, and updated retrospective-template ordering. The mirror still has generic placeholder text.

The five other phase templates show proportional drift with ICON-specific dispatch constraints, version-stamp hardening, and structural decisions that accumulated since MKT-0021. Greenfield installs from `context_template/` and downstream repos without local overrides read from the mirrors; they receive a materially older process.

**Why Moderate**: The ICON-0014 branch was supposed to introduce the three-surface rule as the governing standard, bump `phase-completion.md` mirror to 1.3, and add the Reconcile section to both surfaces. But that branch is not yet merged, and even when it lands, the other four mirrors remain at 1.0 (one cycle below even the ICON-0006 local bump). This is a systemic drift, not a single-file oversight.

- `.context/workflows/task-plan/phase-completion.md:1` vs `context_template/context/workflows/task-plan/phase-completion.md:1`
- `.context/workflows/task-plan/phase-implementation.md:1` vs `context_template/context/workflows/task-plan/phase-implementation.md:1`
- `.context/workflows/task-plan/phase-investigation.md:1` vs `context_template/context/workflows/task-plan/phase-investigation.md:1`
- `.context/workflows/task-plan/phase-architecture.md:1` vs `context_template/context/workflows/task-plan/phase-architecture.md:1`
- `.context/workflows/task-plan/phase-testing.md:1` vs `context_template/context/workflows/task-plan/phase-testing.md:1`

#### M-P-B: `retrospectives.md` write-path contradiction — acknowledged but unresolved with no resolution anchor

`manager.agent.md:204` states:

> "`retrospectives.md` is written directly by the manager — it is a task orchestration artifact, not a source file."

`task-retrospective/SKILL.md:113` states:

> "Delegate entry insertion to @context-specialist — provide the drafted entry text. The specialist will run the append-retrospective-entry script from the `context-maintenance` skill's own `scripts/` folder."

`skills/task-plan-phase-completion/agent-vs-skill-invocation.md:63` acknowledges:

> "Known unresolved: `manager.agent.md:204` says `retrospectives.md` is written directly by the manager. `skills/task-retrospective/SKILL.md:113` says retrospective-entry insertion is delegated to `@context-specialist`. These two paths cannot both be canonical. This standard does not resolve the contradiction; resolving it is filed as a separate follow-up."

No follow-up issue number, no resolution branch, no ADR reference. The "filed as a separate follow-up" claim is not backed by any traceable artifact in the task folder, CHANGELOG, or retrospectives. This has been present since ICON-0006 closed (v1.15.4, 2026-05-15) — over a full sprint with no action.

**Why Moderate** (re-tiered from prior Minor m-P4 basis): This is no longer a known-unresolved pattern with a plausible short path to resolution. The `agent-vs-skill-invocation.md` SSOT was created specifically to resolve the M-P2 contradiction, but it explicitly punted on this sub-issue. Every task that closes with a retrospective entry currently produces ambiguous behavior: the manager may write the entry directly (violating the specialist-path benefits articulated in the SSOT) or delegate it (violating the manager.agent.md:204 note). The inconsistency is now documented but unfixed across all retrospective-writing code paths.

- `agents/manager.agent.md:204`
- `skills/task-retrospective/SKILL.md:113`
- `skills/task-plan-phase-completion/agent-vs-skill-invocation.md:63`

### Minor

#### m-P-1: Identical frontmatter descriptions across all five phase skills (carry-forward from m-P2)

All five `task-plan-phase-*/SKILL.md` files share the same frontmatter description: "Internal task-plan phase skill. Do not invoke without explicit direction." This provides no trigger-differentiation for any phase. An agent consulting the skill catalog cannot distinguish which phase to load from the description alone.

- `skills/task-plan-phase-investigation/SKILL.md:3-4`
- `skills/task-plan-phase-architecture/SKILL.md:3-4`
- `skills/task-plan-phase-implementation/SKILL.md:3-4`
- `skills/task-plan-phase-testing/SKILL.md:3-4`
- `skills/task-plan-phase-completion/SKILL.md:3-4`

#### m-P-2: "Does NOT cover" footer terminology inconsistency across phase skills (carry-forward from n-P1)

Each phase skill's Relationship section ends with a "**Does NOT cover:**" footer, but the terminology is inconsistent across skills and partially redundant with the Relationship section above:

| Skill | "Does NOT cover" includes | Relationship section uses |
|-------|--------------------------|--------------------------|
| investigation | "@coder dispatch" | "task-plan-phase-implementation" (no @coder mention) |
| architecture | "@coder dispatch", "testing", "completion" | None of these appear |
| implementation | "testing delegation", "retrospective", "completion docs" | "task-plan-phase-testing", "task-plan" |
| testing | "@coder dispatch", "context updates", "completion summary" | "task-plan-phase-implementation", "task-plan-phase-completion" |
| completion | "implementation dispatch" | "task-retrospective", "@context-specialist" |

"@coder dispatch" and "implementation dispatch" refer to the same thing; "testing" and "testing delegation" are inconsistently abbreviated. The footers partially state the negative of what the Relationship sections already state positively.

- `skills/task-plan-phase-investigation/SKILL.md:128-129`
- `skills/task-plan-phase-architecture/SKILL.md:78`
- `skills/task-plan-phase-implementation/SKILL.md:85-86`
- `skills/task-plan-phase-testing/SKILL.md:99-100`
- `skills/task-plan-phase-completion/SKILL.md:86-87`

#### m-P-3: Rolling-log "10–15" prose vs script-canonical "15" (carry-forward from m-P3)

Two prose statements say "keep last 10–15 entries" while the script enforces a hard cap of 15. The range suggests flexibility that the script does not implement.

- `skills/task-plan-phase-completion/SKILL.md:63` — "rolling log, keep last 10–15 entries"
- `skills/task-retrospective/SKILL.md:91` — "Keep the most recent 10-15 entries"
- `skills/task-retrospective/scripts/append-retrospective-entry.sh:39` — `ENTRY_CAP=15` (canonical)

#### m-P-4: `task-retrospective` two-path script invocation (carry-forward from m-P4)

`task-retrospective/SKILL.md` gives two contradictory invocation paths for the append script:

- Line 92: "use `./scripts/append-retrospective-entry.sh` (Bash) or `./scripts/append-retrospective-entry.ps1` sibling" — implies direct invocation by the agent or manager.
- Line 113: "Delegate entry insertion to @context-specialist — provide the drafted entry text. The specialist will run the append-retrospective-entry script from the `context-maintenance` skill's own `scripts/` folder."

Line 92 and line 113 describe mutually exclusive execution paths. The note at line 113 says "this skill keeps its own copy under `./scripts/` for any future inline use" — an aspirational justification that does not resolve which path applies NOW.

- `skills/task-retrospective/SKILL.md:92`
- `skills/task-retrospective/SKILL.md:113`

#### m-P-5: `manager.agent.md:182` "3+ attempts" threshold vs `systematic-debugging` "2+" (carry-forward from m-A1, in-scope via manager-routing-guide domain)

`manager.agent.md:182` says "When an agent reports repeated failures (3+ attempts at the same issue)". `systematic-debugging/SKILL.md:4` (description) triggers on "2+ fix attempts" and line 104 says "Three or more fix attempts have failed" as a Red Flag stop condition. The manager's threshold is "3+" while the skill's description trigger is "2+". The manager should route to `systematic-debugging` at the skill's own trigger threshold, not a later one.

- `agents/manager.agent.md:182`
- `skills/systematic-debugging/SKILL.md:4` (description trigger)

#### m-P-6: Verification-checklist Gate headings missing skill-name prefix (carry-forward from m-P1)

The four Gate headings in `verification-checklist/SKILL.md` use plain `### Gate N:` form rather than the `### verification-checklist: Gate N:` prefix form standardized in MKT-0083 for phase-skill headings. This is inconsistent with the heading-prefix convention applied to all five phase skills and `systematic-debugging`.

- `skills/verification-checklist/SKILL.md:46` — `### Gate 1: Evidence Exists`
- `skills/verification-checklist/SKILL.md:49` — `### Gate 2: Scope Fidelity`
- `skills/verification-checklist/SKILL.md:55` — `### Gate 3: Pattern Consistency`
- `skills/verification-checklist/SKILL.md:62` — `### Gate 4: No Rationalization Residue`

#### m-P-7: ICON-0014 branch not yet merged — four surfaces pending

The critical-context note for this audit states that ICON-0014 added a step-0 plan.md reconcile to `task-plan-phase-completion`. On disk, `feature/ICON-0014-plan-md-freshness-gate` contains:

1. New `## task-plan: Completion: Reconcile plan.md` section in `skills/task-plan-phase-completion/SKILL.md`
2. `## Reconcile plan.md` section in `context_template/context/workflows/task-plan/phase-completion.md` (bumped to 1.3)
3. Step 0 in `agents/manager.agent.md` Task Completion section
4. Pre-flight bullet + Red Flag in `skills/mr-discipline/SKILL.md`
5. Precondition note in `skills/task-retrospective/SKILL.md`

None of these are on the current base branch. Agents working from the current build see none of the reconcile gate. The `feature/ICON-0014-plan-md-freshness-gate` branch is complete (reviewer-approved, plan.md reconciled) but not merged.

**Numbering integrity on ICON-0014 branch**: verified correct. The "step 0" is inserted before existing steps 1-5; step numbering is preserved. The Anti-Rationalization row at `agents/manager.agent.md:251` says "Commit all artifacts as step 4 of task completion" — on the ICON-0014 branch, Commit is indeed step 4. No numbering drift found.

- `feature/ICON-0014-plan-md-freshness-gate:skills/task-plan-phase-completion/SKILL.md:22-39`
- `feature/ICON-0014-plan-md-freshness-gate:context_template/context/workflows/task-plan/phase-completion.md:1`
- `feature/ICON-0014-plan-md-freshness-gate:agents/manager.agent.md:198`
- `feature/ICON-0014-plan-md-freshness-gate:skills/mr-discipline/SKILL.md:30,92`
- `feature/ICON-0014-plan-md-freshness-gate:skills/task-retrospective/SKILL.md:24-27`

---

## Improvement Opportunities

### IO-P-1: Canonicalize retrospectives.md write path — close the "Known unresolved" in agent-vs-skill-invocation.md

**Problem**: The "Known unresolved" block in `agent-vs-skill-invocation.md:63` is not tracked by any issue number, ADR, or follow-up branch. It directs the reader to "prefer the specialist path" as the interim convention — but `manager.agent.md:204` still says "written directly by the manager".

**Proposed resolution** (two options): (a) Amend `manager.agent.md:204` to align with the specialist path — change "written directly by the manager" to "drafted by the manager, then inserted via @context-specialist with the append script"; (b) Change `task-retrospective/SKILL.md:113` to say the manager runs the local `./scripts/append-retrospective-entry.sh` inline and remove the specialist-delegation path for the entry append. Option (a) is consistent with the provenance, pruning, and idempotency benefits articulated in the SSOT; option (b) is simpler. Whichever is chosen, update `agent-vs-skill-invocation.md` to close the "Known unresolved" block with the resolution.

**Effort: low. Impact: medium** (resolves one of the two remaining post-M-P2 ambiguities; closes a documented "Known unresolved" that will recur on every future audit).

### IO-P-2: Add trigger-differentiating descriptions to the five phase-skill frontmatters

**Problem**: All five phase skills read "Internal task-plan phase skill. Do not invoke without explicit direction." at the description level. The `task-plan` skill's routing table (`task-plan/SKILL.md:25-31`) names the trigger for each, but the phase-skill itself does not expose that trigger in its own description.

**Proposed change**: Amend each description to include a one-clause trigger distinguisher:
- investigation: "…Load when task scope is unclear or approach is unknown."
- architecture: "…Load when evaluating or making architectural decisions is the primary work."
- implementation: "…Load when the plan is clear and primary work is writing code."
- testing: "…Load when fixing tests, adding coverage, or driving implementation via TDD."
- completion: "…Load after the primary concern skill's work is done, to close any task."

**Effort: trivial. Impact: low** (improves skill catalog discoverability; closes m-P-1).

### IO-P-3: Sync distribution mirrors for all five phase-skill workflow templates

**Problem** (M-P-A above): five `context_template/context/workflows/task-plan/phase-*.md` files are 1–2 template-versions behind their local SSOT counterparts, with substantive content divergence. Greenfield installs receive older process guidance.

**Proposed action**: Run a content-sync sweep: for each mirror, apply all content changes from the local file that generalize to non-ICON repos (removing ICON-specific string literals like `ICON-NNNN` and ICON-specific standards references; preserving structural changes like reordered checklist items, new fields, updated prose). Bump each mirror's template-version to match the local version. The ICON-0014 branch already has a pattern for this (its `phase-completion.md` diff is the model).

**Note**: When ICON-0014 merges, it will bump `phase-completion.md` mirror to 1.3. Bundle the other four mirrors in the same PR to close the drift in one sweep rather than piecemeal.

**Effort: low. Impact: medium** (consumers of context_template get current process guidance; closes M-P-A).

### IO-P-4: Replace "10–15" prose with "15" (the script's cap) in two locations

**Problem** (m-P-3): Two prose statements imply a range (10–15) that the script does not implement — the script always caps at 15.

**Proposed change**: Change "keep last 10–15 entries" → "keep the most recent 15 entries (enforced by the append script)" in both locations. Optionally add a parenthetical explaining why 15: "15 entries is the default — repos with very high task volume may configure a higher cap by editing ENTRY_CAP in the script."

**Effort: trivial. Impact: low** (closes m-P-3; removes an implied configuration option that does not exist).

### IO-P-5: Collapse "Does NOT cover" footers into Relationship sections or align terminology

**Problem** (m-P-2): The five "Does NOT cover" footers partially duplicate the Relationship sections with inconsistent terminology ("@coder dispatch" vs "implementation dispatch", "testing" vs "testing delegation").

**Proposed change**: Either (a) remove the "Does NOT cover" footer and expand the Relationship section's introductory sentence ("This skill covers X; for Y see skill-Z"); or (b) standardize "Does NOT cover" terminology to use the same noun form as the Relationship section ("implementation phase" instead of "@coder dispatch", "testing phase" instead of "testing delegation"). Option (b) is lower-risk.

**Effort: low. Impact: low** (closes m-P-2; reduces terminology confusion between skill sections).

### IO-P-6: Collapse the 5× template-override rule paragraphs to a one-line directive

**Problem**: Each phase skill contains a 5-line "Template-override rule" paragraph (slightly different between skills but structurally identical). These paragraphs appear in every phase skill body, loaded every time any phase skill fires. Across five concurrent phase loads, that is 25 lines of repeated context.

**Proposed change**: Move the full template-override explanation to `task-plan/SKILL.md` (the dispatcher), and replace each phase skill's paragraph with one line: `**Template-override rule**: apply `.context/workflows/task-plan/phase-<name>.md` if present — it supersedes this skill. See \`task-plan\` for the full override policy.`

**Effort: low. Impact: low** (reduces token load when multiple phase skills are loaded; closes one instance of O-S8 from ICON-0003).

---

## Process-Skills-Specific Structural Observations

### Observation 1: Three-surface rule codified but not yet enforced

ICON-0014 codifies the three-surface rule for process-doc edits (local SSOT under `.context/workflows/`, distribution mirror under `context_template/`, fallback SSOT under `skills/<phase>/SKILL.md`) and adds a "Process Doc Sweep" section to `.context/standards/skill-decomposition.md`. However, the rule was not applied retroactively to the four other phase templates when it was established. The result is that the rule's own defining commit (ICON-0014) will close only one of five distribution-mirror gaps.

**Recommendation**: Bundle the four remaining mirror syncs (IO-P-3) into the ICON-0014 merge PR so the rule is fully enforced at the moment it ships.

### Observation 2: `agent-vs-skill-invocation.md` is a well-structured SSOT but carries an open liability

The ICON-0006 co-location of `agent-vs-skill-invocation.md` inside the consuming skill folder is the correct pattern (per the Distribution Layout standard). The document is clear, has an anti-rationalization table, and correctly calls out the "Known unresolved" contradiction rather than silently picking a winner. However, "Known unresolved" without a traceable follow-up item is a liability — it will recur verbatim in every future audit until closed. The recommendation (IO-P-1) is to attach a resolution commitment (ADR update or issue number) to the "Known unresolved" block, not just a prose preference.

### Observation 3: Manager Session Start step-7 and Default-tier @researcher wording are reconcilable

`manager.agent.md:32` says skills should not be invoked during Session Start (wait until the appropriate point in the workflow). `manager.agent.md:233` (Default tier) says "Invoke @researcher at Session Start when any step-7 trigger applies". These are reconcilable — step 7 IS part of Session Start — but the Default-tier phrasing uses "Session Start" loosely, potentially confusing it with "the first session-start step". A minor clarification ("Invoke @researcher during Session Start step 7 when any trigger applies") would eliminate the apparent tension without structural changes. This is m-A7 from the prior audit, retained as a process-skills carry-forward since manager-routing-guide is in scope.

### Observation 4: ICON-0014 plan.md reconcile — no numbering drift, backref integrity confirmed

The user's critical-context note asked to verify that ICON-0014's step-0 insertion didn't introduce numbering drift. Verified on `feature/ICON-0014-plan-md-freshness-gate`: the existing Task Completion steps are re-labeled 0, 1, 2, 3, 4, 5 with "Commit all task artifacts" as step 4 — matching the Anti-Rationalization row at line 251 ("Commit all artifacts as step 4 of task completion"). No stale backrefs found.

---

## ICON-0003 Delta

### Fixed since ICON-0003

- **M-P1 — `design-first` Step 3 "This is a hard gate:" language** — FIXED by ICON-0005 (merged via `b39280f`). Line 103 now reads "When you do run a design pass, the approval flow looks like:" — advisory framing consistent with the description (:4) and When to Skip section (:26-31). The frontmatter description ("Not a hard gate —") was already advisory; the body now matches.

- **M-P2 — `task-plan-phase-completion` invokes `context-maintenance` directly; `task-retrospective` routes through @context-specialist** — FIXED by ICON-0006. The skill now delegates all `.context/` writes to `@context-specialist mode: maintenance` (`SKILL.md:46,80`). The SSOT `agent-vs-skill-invocation.md` is co-located at `skills/task-plan-phase-completion/agent-vs-skill-invocation.md` and ships with the plugin. The residual "Known unresolved" in that file (manager.agent.md:204 vs task-retrospective:113) is catalogued as M-P-B in this audit — a narrower sub-issue that ICON-0006 explicitly deferred.

- **m-P1 — verification-checklist heading prefix** — still present (m-P-6 in this audit). NOT fixed. Prior O-X5 recommended applying the prefix convention; no CHANGELOG entry confirms this was done. On-disk state confirms gates still use bare `### Gate N:` form.

### Still present or partial

- **m-P2 — 5 phase skills share identical frontmatter descriptions** — still present (m-P-1). No change since ICON-0003. Trivial-effort fix (O-X6); not batched into any closed task.

- **m-P3 — rolling-log "10–15" prose drift vs script-canonical "15"** — still present (m-P-3). No change since ICON-0003.

- **m-P4 — `task-retrospective` two-path script invocation** — partially present (m-P-4). The core dual-path ambiguity (line 92 direct vs line 113 delegate) remains. The note at line 113 was added to explain the rationale for the duplication, but it does not resolve which path the manager should take.

- **m-P5 (m-A1 basis) — manager "3+" vs systematic-debugging "2+"** — still present (m-P-5). No change since ICON-0003.

- **n-P1 — 5 phase skills' "Does NOT cover" footers** — still present (m-P-2). Prior O-X8 recommended collapsing; not yet batched.

### Net-new

- **M-P-A — Distribution-mirror drift on all five phase-skill workflow templates** — net-new. Not flagged in ICON-0003 because the three-surface rule itself was not yet codified. ICON-0014 codifies the rule and will partially close it (phase-completion), but the other four mirrors (implementation, investigation, architecture, testing) have drifted silently since the local overrides were updated without mirroring.

- **M-P-B — `retrospectives.md` write-path contradiction re-tiered Moderate** — elevated from m-P4 partial basis. The "Known unresolved" block in `agent-vs-skill-invocation.md` is now the primary on-disk record, making this a documented-but-untracked ambiguity rather than an implicit one. No issue, no ADR, no resolution date.

- **m-P-6 — verification-checklist Gate headings missing skill-name prefix** — reclassified from m-P1 (prior) as still-present carry-forward with no fixing PR in CHANGELOG.

- **m-P-7 — ICON-0014 branch complete but not yet merged** — informational. The four surfaces (manager.agent.md step 0, mr-discipline pre-flight, task-retrospective precondition, task-plan-phase-completion/SKILL.md reconcile section) are ready on the feature branch. Until merged, the process doc gap the user asked to verify is real on the production branch.
