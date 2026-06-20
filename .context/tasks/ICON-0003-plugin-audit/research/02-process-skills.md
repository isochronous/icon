# Process Skills Audit — Raw Findings

**Audit date:** 2026-05-14
**Plugin version:** ICON `1.15.3` on `main` (standalone repo; post-`254ff7c` split)
**Baseline for delta:** MKT-0087 (2026-04-29)
**Brief:** `/home/jmcleod/.claude/plugins/cache/datascan-marketplace/ICON/1.15.3/skills/plugin-audit/briefs/02-process-skills.md`
**Skills in scope (13):** `task-plan`, `task-plan-phase-investigation`, `task-plan-phase-architecture`, `task-plan-phase-implementation`, `task-plan-phase-testing`, `task-plan-phase-completion`, `systematic-debugging`, `testing-discipline`, `verification-checklist`, `commit-discipline`, `design-first`, `task-retrospective`, `context-maintenance`. (`mr-discipline` is out of scope for this brief — covered in domain 04.) Total **1,609 lines** (range 78–233).

## Summary

The process-skill domain survived the marketplace → standalone-repo split with zero structural regressions in scope and zero residual `plugins/ICON/...` path references. Every check pattern reaches a clean result: no line-coupled cross-references (the only `line 42` hit at `commit-discipline/SKILL.md:112` is an example inside a commit-message code fence); no `pull request`/`PR` terminology residue; every in-scope skill's description is in YAML folded block scalar form (`description: >` + 2-space indent); the four discipline skills (`systematic-debugging`, `testing-discipline`, `verification-checklist`, `commit-discipline`) all carry the G2/G3/G4 hardening shape (rationalization table + Red-Flags STOP list + violation-symptom prose). The two MKT-0087 carry-forward Moderates remain on disk unchanged: **M-P1** (`design-first` Step 3 body still says `This is a hard gate:` while description/When-to-Use/Skip framing is advisory) and **M-P2** (`task-plan-phase-completion` invokes `context-maintenance` directly while `task-retrospective` routes context writes through `@context-specialist` — delegation-path disagreement). The MKT-0087 minors (`m-P1` verification-checklist Gate-heading prefix gap, `m-P2` five-phase-skills identical description, `m-P3` rolling-log "10–15" prose drift, `m-P4` task-retrospective two-path script invocation, `m-P5` phase-completion partial retro restatement) all persist on disk verbatim. **Net-new findings:** one Minor — the four "Does NOT cover" footer bullets across the five phase skills duplicate exactly what the "Relationship to Other Skills" bulleted lists immediately above already say (n-P1). One Improvement Opportunity is plugin-audit-specific (O-7): `task-retrospective` Full Process Checklist step 4 nests a 3-clause meta-explanation about script-ownership that drains attention from the actual instruction (insert the entry).

## Defect Findings

### Critical

None observed.

### Moderate

**M-P1 — `design-first` Step 3 body still claims "This is a hard gate", contradicting the softened surface (carry-over from MKT-0087 M-P1 → MKT-0077 M-P1 → MKT-0063 M-P4).**
- **Location:** `skills/design-first/SKILL.md:103` (`This is a hard gate:`) versus `:4` (description "Optional design pass... Not a hard gate"), `:14-16` (When to Use — "This is an optional design pass — not a required step"), `:26-31` (When to Skip).
- **Problem:** Description, When-to-Use, and When-to-Skip frame design-first as advisory and optional. Step 3 inside the body (`### design-first: Step 3: Get Approval` at `:99`) reads `This is a hard gate:` followed by three context-dependent branches (autonomous/user-available/manager-delegated). A reader who skims to Step 3 sees a hard-gate instruction with workarounds — exactly the inconsistency MKT-0063 → MKT-0077 → MKT-0087 each flagged.
- **Risk:** Skill self-contradiction. Top says "advisory, optional, skip when self-evident"; body says "hard gate, do NOT start implementing." Per agent grep (`grep -rln "design-first" agents/` → 0 hits), the skill is currently agent-orphan, so the inconsistency does not propagate into autonomous execution paths — but a user invoking `/design-first` directly will hit the contradiction.
- **Classification:** **MKT-0087 still-present** — survived the repo split unchanged.

**M-P2 — `task-plan-phase-completion` and `task-retrospective` still disagree on the context-update delegation path (carry-over from MKT-0087 M-P2 → MKT-0077 M-P2).**
- **Location:**
  - `skills/task-plan-phase-completion/SKILL.md:46` — "Invoke `context-maintenance` if the update scope is broad (multiple files across multiple areas)."
  - `skills/task-plan-phase-completion/SKILL.md:80-81` — Relationship section restates: "**`context-maintenance`**: Invoke if context updates are broad (multiple files across multiple areas)."
  - `skills/task-retrospective/SKILL.md:104-109` — "Delegate context updates to **@context-specialist** with `mode: maintenance`... The specialist performs all `.context/` writes — do not update these files inline."
- **Problem:** Two paths to the same outcome. Completion-phase guidance routes the manager to invoke the skill directly; retrospective guidance routes through the agent. When both skills are loaded at task close (the workflow's normal shape), the manager receives contradictory orchestration: completion says invoke `context-maintenance` directly; retrospective says all `.context/` writes go via @context-specialist.
- **Risk:** Manager workflow ambiguity. The retrospective's "do not update these files inline" rule is silently undercut by completion's direct-invoke language. The recently-completed ICON-0001 task explicitly used the @context-specialist path (`.context/retrospectives.md:6-9`), which is consistent with `task-retrospective` but not with `task-plan-phase-completion`.
- **Classification:** **MKT-0087 still-present (partial fix)** — phase-ordering subset fixed at MKT-0076; delegation-path subset unaddressed.

### Minor

**m-P1 — `verification-checklist` H3 Gate headings still lack the `verification-checklist:` skill-name prefix that MKT-0083 standardized on every other in-scope skill's numbered headings (carry-over from MKT-0087 m-P1).**
- **Location:** `skills/verification-checklist/SKILL.md:46, :49, :55, :62` — `### Gate 1: Evidence Exists`, `### Gate 2: Scope Fidelity`, `### Gate 3: Pattern Consistency`, `### Gate 4: No Rationalization Residue`. None carry the prefix.
- **Comparison points (prefix present):** `commit-discipline/SKILL.md:43, :66, :80, :118` (`### commit-discipline: Rule 1..4`); `systematic-debugging/SKILL.md:14, :37, :48, :61` (`## systematic-debugging: Phase 1..4`); `testing-discipline/SKILL.md:18, :33, :39` (`### testing-discipline: RED/GREEN/REFACTOR`); `task-retrospective/SKILL.md:28, :42, :51` (`### task-retrospective: Question 1..3`); `context-maintenance/SKILL.md:28, :41, :67, :85` (`## context-maintenance: Phase 0..3`); `design-first/SKILL.md:35, :45, :99, :108` (`### design-first: Step 1..4`); all five `task-plan-phase-*/SKILL.md` H2s.
- **Classification:** **MKT-0087 still-present** — single-instance editorial residue from MKT-0083's sweep scope.
- **Stability impact:** Cosmetic. Heading consistency across the discipline-skill class is the value.

**m-P2 — Five phase skills still share an identical frontmatter description (carry-over from MKT-0087 m-P2 → MKT-0077 M-P4 → MKT-0063 M-P7).**
- **Location:** `skills/task-plan-phase-investigation/SKILL.md:3-4`, `task-plan-phase-architecture/SKILL.md:3-4`, `task-plan-phase-implementation/SKILL.md:3-4`, `task-plan-phase-testing/SKILL.md:3-4`, `task-plan-phase-completion/SKILL.md:3-4` — all read `description: > / Internal task-plan phase skill. Do not invoke without explicit direction.`
- **Problem:** Five identical descriptions give the skill router zero discriminative signal. These are `user-invocable: false`, so the router-signal cost is structural (catalog representation) rather than UX-facing — but the `task-plan/SKILL.md:25-31` per-concern table is the only place a manager can disambiguate, and that signal lives outside the descriptions themselves.
- **Classification:** **MKT-0087 still-present** — survived the split unchanged.

**m-P3 — Rolling-log entry-count drift "10–15" vs. script-canonical "15" persists in two prose sites (carry-over from MKT-0087 m-P3 → MKT-0077 M-P6 → MKT-0063 M-P8).**
- **Location:**
  - `skills/task-plan-phase-completion/SKILL.md:63` — "rolling log, keep last 10–15 entries".
  - `skills/task-retrospective/SKILL.md:91` — "Keep the most recent 10-15 entries".
  - Authoritative (script-canonical): `skills/task-retrospective/SKILL.md:114` says "removes oldest when count ≥ 15" and `skills/context-maintenance/append-retrospective-entry.md:32-33` says "If the count is ≥ 15, removes the oldest (last) entry."
- **Problem:** Cosmetic SSOT drift — script is canonical at 15, prose hedges as "10–15".
- **Classification:** **MKT-0087 still-present**.

**m-P4 — `task-retrospective` is internally inconsistent on script-path canonicality (carry-over from MKT-0087 m-P4 → MKT-0077 M-P3).**
- **Location:**
  - `skills/task-retrospective/SKILL.md:91-92` (Rolling Log Maintenance) — "use `./scripts/append-retrospective-entry.sh` (Bash) or the `./scripts/append-retrospective-entry.ps1` sibling (PowerShell) — both live alongside this skill so each consumer remains self-contained."
  - `skills/task-retrospective/SKILL.md:113` (Full Process Checklist step 4) — "**Delegate entry insertion to @context-specialist** — provide the drafted entry text. The specialist will run the append-retrospective-entry script from the `context-maintenance` skill's own `scripts/` folder ... this skill keeps its own copy under `./scripts/` for any future inline use."
- **Problem:** Line 91 instructs the reader to invoke the local `./scripts/append-retrospective-entry.sh` directly. Line 113 instructs the reader to delegate to @context-specialist which runs the script from `context-maintenance`'s scripts folder. The skill never declares which path is canonical, so a reader following line 91 to the letter bypasses the @context-specialist routing the rest of the checklist enforces.
- **Classification:** **MKT-0087 still-present** — survived the split unchanged.

**m-P5 — `task-plan-phase-completion` Retrospective subsection still partially restates `task-retrospective` (carry-over from MKT-0087 m-P5 → MKT-0077 M-P7 → MKT-0063 M-P9).**
- **Location:** `skills/task-plan-phase-completion/SKILL.md:48-63`. Despite the explicit pointer at `:55` ("Invoke the `task-retrospective` skill for the full retrospective process"), lines 57-63 then restate the three questions and the rolling-log retention rule (where the "10–15" lives, per m-P3).
- **Classification:** **MKT-0087 still-present** — survived the split unchanged.

**n-P1 — Five phase skills duplicate "Does NOT cover" footers immediately below "Relationship to Other Skills" bullets that already encode the same coverage boundary.**
- **Location:**
  - `skills/task-plan-phase-investigation/SKILL.md:114-129` — Relationship section enumerates relations to 5 sibling skills, then line `:128-129` adds `**Does NOT cover:** architecture review, @coder dispatch, testing delegation, retrospective.`
  - `skills/task-plan-phase-architecture/SKILL.md:70-78` — Relationship section enumerates 3 siblings; line `:78` adds `**Does NOT cover:** investigation, @coder dispatch, testing, completion.`
  - `skills/task-plan-phase-implementation/SKILL.md:74-86` — Relationship section enumerates 4 siblings; line `:85-86` adds `**Does NOT cover:** investigation, architecture review, testing delegation, retrospective, completion docs.`
  - `skills/task-plan-phase-testing/SKILL.md:86-100` — Relationship section enumerates 4 siblings; line `:99-100` adds `**Does NOT cover:** investigation, architecture, @coder dispatch, retrospective, context updates, completion summary.`
  - `skills/task-plan-phase-completion/SKILL.md:77-88` — Relationship section enumerates 4 siblings; line `:87-88` adds `**Does NOT cover:** investigation, architecture review, implementation dispatch, testing delegation.`
- **Problem:** The "Does NOT cover" line is a negation of the positive list directly above it (e.g., investigation lists relationships to architecture/implementation/testing/completion/systematic-debugging, and the negation lists architecture/@coder/testing/retrospective — which IS that same set with naming variance: "@coder dispatch" instead of "implementation," "retrospective" instead of "completion"). Five copies of a redundant footer, with terminology drift between the positive list and its negation in each file.
- **Classification:** **Net-new since MKT-0087** — not flagged in prior audits.
- **Stability impact:** Cosmetic. Token cost is small per skill; pattern-level drift across five identical structures is the lint signal.

## Improvement Opportunities

**O-1 — Soften `design-first` Step 3 body to match the advisory framing the rest of the skill carries.** Replace `### design-first: Step 3: Get Approval` body's "This is a hard gate:" with "When you do run a design pass, the approval flow looks like:" — keep the three context branches, lose the contradictory gate language. Closes M-P1. **Effort:** trivial (1 line). **Impact:** moderate (closes the only carry-forward Moderate from MKT-0063, surfaces user-facing skill consistency).

**O-2 — Decide one delegation path for `.context/` writes at task close and update the looser site to match.** Either (a) update `task-plan-phase-completion:46, :80-81` to dispatch via @context-specialist (matching `task-retrospective:104-109`); or (b) update `task-retrospective:104-109` to route through `context-maintenance` directly. The pattern-level decision belongs in `.context/standards/agent-vs-skill-invocation.md` (new) or as an addendum to `skill-decomposition.md`. Closes M-P2. **Effort:** low (after the standards-level decision). **Impact:** moderate (removes recurring 4-audit ambiguity; ICON-0001 retro already followed the specialist path, so settle there).

**O-3 — Apply MKT-0083 heading-prefix convention to `verification-checklist` Gate headings.** Rename `### Gate 1: Evidence Exists` → `### verification-checklist: Gate 1: Evidence Exists` (and 3 siblings). Closes m-P1. **Effort:** trivial (4 heading edits). **Impact:** low (heading-style uniformity across discipline-skill class).

**O-4 — Add a 5–10-word trigger differentiator to each phase-skill frontmatter description.** Each shares `Internal task-plan phase skill. Do not invoke without explicit direction.` Add a short trigger after the boilerplate (e.g., `Load when scope is undefined.` for investigation, `Load when architecture question is the primary work.` for architecture, etc.). Closes m-P2. **Effort:** low (5 line edits). **Impact:** low (router-signal quality).

**O-5 — Sweep "10–15" → "15" in the two prose sites.** Both sites become e.g. "rolling log; the `append-retrospective-entry` script trims to the most recent 15 entries — no manual count management required." Removes the recurring drift class at its source. Closes m-P3. **Effort:** trivial (2 line edits). **Impact:** low.

**O-6 — Reconcile `task-retrospective` script-path canonicality.** Add a single sentence at the top of "Rolling Log Maintenance" (line 87) — e.g., "When closing a task, prefer the specialist-delegated path (Full Process Checklist step 4); the local copy under `./scripts/` is held for fallback when delegation is unavailable" — settles the ambiguity without removing the local copy (which is required by the `.context/standards/skill-decomposition.md § "Skills Cannot Share Scripts"` rule). Closes m-P4. **Effort:** trivial. **Impact:** low.

**O-7 — Inline the script-ownership meta-explanation in `task-retrospective:113` so the instruction comes first.** The 3-clause parenthetical "(the maintenance-mode skill owns its copy; this skill keeps its own copy under `./scripts/` for any future inline use, per the 'skills cannot share scripts' rule in `.context/standards/skill-decomposition.md`)" is the architectural rationale for the dual scripts directory, but it sits inside the imperative step "Delegate entry insertion to @context-specialist," burying the actual action. Either (a) move the rationale to a footnote/sibling under `## Rolling Log Maintenance`, or (b) trim to "(see `.context/standards/skill-decomposition.md` for the dual-copy rationale)." Net-new opportunity not flagged in MKT-0087. **Effort:** trivial (1 line edit). **Impact:** low (Full Process Checklist readability).

**O-8 — Collapse the "Does NOT cover" footers in the 5 phase skills or align the wording with the positive Relationship list.** Either (a) delete the footers (the positive list already encodes the boundary), or (b) regenerate them so the negation uses the same labels as the positive list ("@coder dispatch" ↔ "implementation dispatch," "retrospective" ↔ "completion-phase retrospective"). Closes n-P1. **Effort:** low (5 single-line decisions). **Impact:** low (consistency / token reduction).

## Process-Skills-Specific Structural Observations

1. **The marketplace → standalone split landed clean on this domain.** Zero `plugins/ICON/` or `plugins/<plugin>/` path references in the 13 in-scope skills. Zero `pull request` / `PR` terminology residues. Zero line-coupled cross-references (`SKILL.md:NNN`, `line NNN`). The one bash hit at `commit-discipline/SKILL.md:112` is an example commit message inside a code fence, not a cross-reference.

2. **G2/G3/G4 hardening shape is uniform across the four in-scope discipline skills.** Each has rationalization table, Red-Flags STOP list, and violation-symptom prose: `systematic-debugging/SKILL.md:86-96` + `:98-109`; `testing-discipline/SKILL.md:206-219` + `:221-233`; `verification-checklist/SKILL.md:28-40` + `:69-80`; `commit-discipline/SKILL.md:137-147` + `:149-162`. Descriptions carry the "including when X / when Y / when Z" violation-symptom pattern.

3. **MKT-0083 heading-prefix convention is adopted on 12 of 13 in-scope skills.** Adopted: `systematic-debugging`, `testing-discipline` (RED/GREEN/REFACTOR), `commit-discipline`, `design-first`, `context-maintenance`, `task-retrospective`, all 5 `task-plan-phase-*`, and `task-plan` (the single H2 at `:77`). Not adopted: `verification-checklist`'s Gate 1–4 H3s (m-P1).

4. **`task-plan` is the only in-scope skill whose H2s contain example/template content.** Lines `:42-62` are a literal `plan.md` template inside a fenced code block; `grep '^##'` consequently sees template-content headings (`## Task: [TASK-ID]`, `## Branch: [BRANCH-NAME]`, etc.) as if they were skill section headers. They are content of a fenced block, not skill structure — informational only.

5. **The "skills cannot share scripts" rule lives in `.context/standards/skill-decomposition.md` and is cited only from `task-retrospective:113`.** `context-maintenance/append-retrospective-entry.md` references the script location but not the rule. If the standards file is renamed or split, the single citation site is the only one that breaks.

6. **`testing-discipline/SKILL.md` is 233 lines** — the largest in scope. The `.context/` file-size norm at `context-maintenance/SKILL.md:52` ("Files exceeding ~200 lines") applies to `.context/` documents, not skill bodies — informational only.

7. **The "delegate to specialist vs. invoke skill directly" ambiguity (M-P2) survives a fifth audit (MKT-0046 → MKT-0063 → MKT-0077 → MKT-0087 → ICON-0003).** The ICON-0001 retrospective at `.context/retrospectives.md:6-9` records that the @context-specialist path was used in practice — so the working convention has been established empirically, but the `task-plan-phase-completion` skill still documents the bypass path.

8. **`design-first` agent-orphan status survived the split.** `grep -rln "design-first" agents/` → 0 hits. Consistent with the advisory framing in the description; user-discoverable via the `When to Use` prose and the `using-skills/SKILL.md:71, :84` references.

## MKT-0087 Delta

### Fixed since MKT-0087 (verified on disk)

- **None this pass.** No in-scope MKT-0087 findings have been closed; the marketplace → standalone split was content-preserving on these skills. The only relevant fix in CHANGELOG since MKT-0087 is ICON-0002 (prune script TTL), which does not touch any in-scope skill.

### Still present or partial (carried forward verbatim)

- **MKT-0087 M-P1 (design-first Step 3 hard-gate body inconsistency)** — **still present**. Surfaces here as M-P1. Survived the split unchanged.
- **MKT-0087 M-P2 (completion vs. retrospective delegation-path disagreement)** — **still present (partial)**. Surfaces here as M-P2. The empirical resolution (ICON-0001 used the @context-specialist path) does not appear on disk in either skill.
- **MKT-0087 m-P1 (`verification-checklist` Gate headings missing prefix)** — **still present**. Surfaces here as m-P1.
- **MKT-0087 m-P2 (5 phase skills with identical descriptions)** — **still present**. Surfaces here as m-P2.
- **MKT-0087 m-P3 (rolling-log "10–15" prose drift)** — **still present**. Surfaces here as m-P3.
- **MKT-0087 m-P4 (`task-retrospective` two-path script invocation)** — **still present**. Surfaces here as m-P4.
- **MKT-0087 m-P5 (`task-plan-phase-completion` retro restatement)** — **still present**. Surfaces here as m-P5.
- **MKT-0087 m-P7 (`design-first` agent-orphan)** — **still present, by-design** consistent with advisory framing. Now-net-fewer-instances (one orphan, not two — `mr-discipline` is out of scope for this audit).

### Net-new since MKT-0087

- **n-P1 (5-phase-skill duplicate "Does NOT cover" footers)** — net-new Minor. The footers existed in the prior audit but were not flagged as redundant against the positive Relationship lists in the same files. The redundancy + intra-file naming drift (e.g., "@coder dispatch" in negation vs. "implementation dispatch" in positive list) is the new lint signal surfaced this pass.

- **O-7 (`task-retrospective:113` script-ownership meta-explanation buried inside imperative step)** — net-new Improvement Opportunity. The 3-clause parenthetical was introduced by MKT-0066 (skill-decomposition rule codified) and survived four audits without comment; flagged here because the readability cost compounds with M-P2 and m-P4 — three sites in `task-retrospective` all dance around the same "two scripts exist, here's why" architectural fact that could be summarized once and pointered to thereafter.

**Domain stability summary:** zero regressions from the repo split; zero criticals; two carry-forward moderates (both user-groomed deferrals); five carry-forward minors; one net-new minor; two net-new improvement opportunities. The domain is **release-stable** in the same sense MKT-0087 found it — the audit history shows a stable plateau, not a degrading trajectory, on the in-scope skills.
