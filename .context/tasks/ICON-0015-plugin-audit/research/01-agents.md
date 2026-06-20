# Agents Audit — Raw Findings

**Auditor:** ICON-0015 leaf agent (Agents domain)
**Date:** 2026-05-20
**Scope:** 9 `agents/*.agent.md` files + `shared/common-constraints.md`
**Plugin version on main:** 1.15.4 (post-ICON-0012 merge, ICON-0014 still pending MR)
**User focuses:** (1) Internal consistency — cross-file contradictions, frontmatter
divergence, routing tension; (2) Token efficiency — always-loaded surface, duplicate
text, verbosity with no decision value.

---

## Summary

The agent surface is structurally sound and shows clear improvement since ICON-0003:
M-I1 (`mode: upgrade` routing contradiction) closed by ICON-0007; M-P2 (context-update
delegation path) closed by ICON-0006; M-I3 (`initialize-multimodule` missing
`disable-model-invocation`) closed by ICON-0008; M-U2 (`writing-skills` stale
registration instructions) closed by ICON-0009; M-A3 (architect AR table) and
M-A2 (9× common-constraints duplication) both policy-accepted with mechanical
enforcement (ICON-0011 pre-commit hook confirmed byte-identical across all 9 agents).

Two net-new Moderate defects emerged this cycle:

1. **M-A-NET1**: `manager.agent.md:151` (delegation template) references
   `.context/standards/three-layer-enforcement.md` — a file that was never created
   when the plugin migrated from the marketplace repo. Every manager delegation that
   touches a three-layer-enforced rule receives a dead cross-reference in the warmstart
   template. This has persisted since MKT-0059 (April 2026) and was not caught by
   ICON-0003.

2. **M-A-NET2**: ICON-0014 (`plan.md` freshness gate) is complete on its feature
   branch — retro written, plan.md reconciled, reviewer approval in plan.md — but has
   not been merged to `main`. The task brief states the gate "was added," but the
   current working tree does NOT have it. `agents/manager.agent.md` on `main` lacks
   step 0 and the supporting Hardcoded tier entry. Until merge, every manager session
   operates without the gate.

The carry-forward plateau from ICON-0003 (M-A1 planner odd fence count; m-A1
"3+" threshold; m-A4/m-A5 PM Session Start ordering/acknowledgement; m-A6 no
`mr-discipline` reference in any agent; m-A7 step-7 wording tension) remains
unchanged — none of the minor/moderate carry-forwards were addressed between
ICON-0003 and this audit.

The token-efficiency focus surfaces two net-new improvement opportunities beyond
what ICON-0003 documented: reviewer checklist category duplication within a single
agent body (reviewer.agent.md), and the manager Delegation section's verbosity
relative to its own "delegate goals not scripts" principle.

---

## Defect Findings

### Critical

None observed.

---

### Moderate

#### M-A-NET1 — Dead cross-reference in manager delegation template (net-new)

`agents/manager.agent.md:151` contains:

```
- Three-layer enforcement (if this change touches a rule enforced at all three layers):
  name all three layers and their exact file locations — see
  `.context/standards/three-layer-enforcement.md` for the layer definitions and
  delegation notes.
```

`.context/standards/three-layer-enforcement.md` does not exist. Confirmed via
`ls .context/standards/` (only `changelog-discipline.md` and `skill-decomposition.md`
present) and `git log --all --diff-filter=A -- .context/standards/three-layer-enforcement.md`
(no commit ever created it).

The reference was introduced in MKT-0059 (`f2fbcbf`, April 2026) when the manager
Delegation section was hardened; the file was cited as existing but never created.
The standalone-repo migration (ICON-0001) did not create it, and ICON-0003 did not
flag it.

**Impact:** Any manager session delegating a rule that spans multiple enforcement
layers reads a warmstart instruction pointing to a non-existent document.
The enforcement note is visible on every delegation where the scope-boundaries block
is included — a high-frequency path.

**Location:** `agents/manager.agent.md:151`
**Missing file:** `.context/standards/three-layer-enforcement.md`

[see agent-evaluation]

---

#### M-A-NET2 — ICON-0014 plan.md freshness gate not merged to main (net-new)

ICON-0014 (branch `feature/ICON-0014-plan-md-freshness-gate`) implements a
gated `plan.md` reconciliation step (step 0 of Task Completion) in:

- `agents/manager.agent.md` — step 0 in "Task Completion and Retrospective" + Hardcoded tier entry + AR row
- `.context/workflows/task-plan/phase-completion.md` — `## Reconcile plan.md` section (template-version 1.3)
- `context_template/context/workflows/task-plan/phase-completion.md` — same section mirrored (template-version 1.3)
- `skills/task-plan-phase-completion/SKILL.md` — `## task-plan: Completion: Reconcile plan.md` fallback section
- `skills/mr-discipline/SKILL.md` — pre-flight bullet + red flag
- `skills/task-retrospective/SKILL.md` — precondition note

The ICON-0014 plan.md shows all Progress items checked including the dogfood
reconciliation pass, with only the final MR/merge step still marked IN PROGRESS.

**Current main-branch state:** None of the above edits are present.
`agents/manager.agent.md` on main lacks step 0; the `phase-completion.md` files are
at version 1.2 and 1.1 respectively; `task-plan-phase-completion/SKILL.md` has no
reconcile section.

**Impact:** The audit brief describes the gate as having been added and instructs
the auditor to "verify it's wired into the manager agent." It is not — on main. The
feature is ready to ship but the merge has not occurred. Each task completed between
the branch cut and the merge runs without the gate.

**Location:**
- `agents/manager.agent.md` (main): missing step 0 — compare with `git show feature/ICON-0014-plan-md-freshness-gate:agents/manager.agent.md:198-200`
- `.context/tasks/ICON-0014-plan-md-freshness-gate/plan.md` (on ICON-0014 branch): Progress last item `[ ] Manager: run retrospective, commit artifacts, push branch, open MR closing #10 ← IN PROGRESS`

---

### Minor

#### m-A-1 (carry-forward from ICON-0003 M-A1) — Planner odd code-fence count

`agents/planner.agent.md` has 3 code fences (odd count → structural imbalance).
Line 45 opens the "story splitting" output block; line 60 closes it. The
"general task breakdown" output format begins at line 63 (`### When called for general
task breakdown`) without an opening fence, but closes with ` ``` ` at line 87.
The second output block is neither labeled nor fenced consistently.

**Location:** `agents/planner.agent.md:45,:60,:87`

---

#### m-A-2 (carry-forward from ICON-0003 m-A1) — Manager "3+" failure threshold magic number

`agents/manager.agent.md:182` and `:247` both hardcode "3+" as the escalation
threshold. Neither the Escalation Handling section nor the AR row references a named
constant or allows the threshold to be adjusted per task complexity.

**Location:** `agents/manager.agent.md:182,:247`

---

#### m-A-3 (carry-forward from ICON-0003 m-A4) — PM Session Start lacks common-constraints acknowledgement

`agents/product-manager.agent.md:14-16` (Session Start) has no "Apply common
constraints" step comparable to `agents/manager.agent.md:33` ("Apply common constraints —
always active, no invocation required"). PM sessions begin without the explicit
constraint-activation reminder the manager carries.

**Location:** `agents/product-manager.agent.md:14-16` vs `agents/manager.agent.md:33`

---

#### m-A-4 (carry-forward from ICON-0003 m-A5) — PM Session Start positioned after "When to Invoke"

`## When to Invoke` appears at line 10 and `## Session Start` at line 14 in
`product-manager.agent.md`. The section labeled "MANDATORY FIRST ACTION" sits after
the optional-entry description. Manager places Session Start immediately after the
role description, before any other sections.

**Location:** `agents/product-manager.agent.md:10` (`## When to Invoke`) vs `:14` (`## Session Start`)

---

#### m-A-5 (carry-forward from ICON-0003 m-A6) — No agent references `mr-discipline`

All 9 `agents/*.agent.md` files contain zero references to `mr-discipline`.
The skill was created in MKT-0085/MKT-0086 as a split from `commit-discipline`.
The manager agent's Task Completion section (`:197-208`) instructs on commits and
artifacts but never cues `mr-discipline` for MR opening — the skill that owns
that checklist.

**Location:** All 9 `agents/*.agent.md` (confirmed via `grep -rni "mr-discipline" agents/` → no output)

---

#### m-A-6 (carry-forward from ICON-0003 m-A7) — Step-7 "Invoke @researcher at Session Start" wording tension

`agents/manager.agent.md:32` (Session Start step 1): "do **not** invoke them yet —
complete all remaining Session Start steps first."
`agents/manager.agent.md:233` (Default tier): "Invoke @researcher at Session Start
when any step-7 trigger applies."

Step 7 is part of Session Start, so the instructions are technically consistent,
but the Default tier's phrasing "at Session Start" contradicts the step-1 deferral
instruction for a reader who reads the Default tier first.

**Location:** `agents/manager.agent.md:32` vs `:233`

---

#### m-A-NET3 (net-new) — Reviewer checklist category list duplicated in Default tier

`agents/reviewer.agent.md:25` (Review Checklist section) names the six categories:
"Code Quality, Security, Performance, Testing, Verification, Maintainability."
`agents/reviewer.agent.md:68` (Default tier) repeats the identical comma-delimited
list verbatim. The Default tier adds no new decision value beyond "apply all six" —
which the skill invocation already mandates.

**Location:** `agents/reviewer.agent.md:25,:68`

---

#### m-A-NET4 (net-new) — Manager frontmatter description diverges from sub-agent description format

`agents/manager.agent.md:2-20` and `agents/context-specialist.agent.md:2-14` use
the YAML `>` folded scalar for `description`, spanning multiple lines with examples
and usage notes. The other 7 agents use single-quoted one-line strings. This produces
a discoverable inconsistency for grep-based tooling and CI lint — two agents are
parseable only if the consumer handles multi-line folded scalars.

The manager description's multi-paragraph structure is arguably justified (it carries
detection examples), but the inconsistency creates a parser-fragility risk when
the frontmatter is consumed by tools that assume the single-line form.

**Location:**
- Multi-line folded: `agents/manager.agent.md:2-20`, `agents/context-specialist.agent.md:2-14`
- Single-quoted: all other 7 agents (lines 2 in each)

---

## Improvement Opportunities

### IO-A1 — Create `.context/standards/three-layer-enforcement.md` (closes M-A-NET1)

**Description:** Write the missing standards document that `manager.agent.md:151`
has referenced since MKT-0059. Content is derivable from the skill-decomposition.md
retro citations and the ICON-0007 retro lesson (routing rules appear in: role intro,
scope/skip guards, mode tables, dispatch routing, Hardcoded constraints, Default/
Discretionary tiers, sibling routing-guide tables). A 30–50 line doc covering the
three layer definitions and delegation notes resolves the dead-reference defect and
provides the intended enforcement guidance.

**Effort:** Low. **Impact:** High (closes the only agent-domain Moderate that can be
addressed without a branch merge).

---

### IO-A2 — Merge ICON-0014 to close the plan.md freshness gate (closes M-A-NET2)

**Description:** The ICON-0014 branch is review-approved, dogfooded, and retro-written.
The only remaining step is `Manager: run retrospective, commit artifacts, push branch,
open MR`. This is an operational action, not a design change. Every task completed
on main between now and merge runs without the gated reconciliation step.

**Effort:** Trivial (the work is done). **Impact:** High (closes the freshness-gate
that was the design objective of a full task cycle).

---

### IO-A3 — Promote PM Session Start parity with manager (closes m-A-3 + m-A-4)

**Description:** Two 1–2 line edits:
1. Move `## Session Start` before `## When to Invoke` in `product-manager.agent.md`.
2. Add "Apply common constraints — always active, no invocation required" as step 2
   of the PM Session Start, mirroring `manager.agent.md:33`.

**Effort:** Trivial. **Impact:** Low-medium (symmetric structure reduces the chance
that PM sessions begin without constraint-awareness).

---

### IO-A4 — Add `mr-discipline` cue to manager task completion (closes m-A-5)

**Description:** `agents/manager.agent.md` Task Completion and Retrospective section
(lines 197–208) orchestrates review, verification, retrospective, and commit. It
never cues `mr-discipline` for MR opening. Adding a step 5 (or a note inside step 4)
— "Apply `mr-discipline` skill before opening an MR" — closes the discovery gap.
Sub-agents do not need this; only the manager opens MRs.

**Effort:** Trivial. **Impact:** Medium (MR quality gate is skipped unless the user
knows to invoke it manually).

---

### IO-A5 — Trim reviewer Default tier redundant category list (closes m-A-NET3)

**Description:** `agents/reviewer.agent.md:68` repeats the six-category list that
`reviewer.agent.md:25` already provides verbatim. The Default tier entry could be
simplified to "Review against all six checklist categories defined in the
`code-quality-rules` skill" without listing them again. 14-word reduction, no
information loss.

**Effort:** Trivial. **Impact:** Low (token micro-efficiency; clarity improvement).

---

### IO-A6 — Normalize agent frontmatter description format (closes m-A-NET4)

**Description:** Standardize on one of the two forms across all 9 agents. Option A:
trim the manager and context-specialist to single-quoted one-liners (losing the
multi-paragraph usage notes from manager's description). Option B: formalize multi-line
folded scalar as the standard and expand the 7 thin descriptions. Option A is lower
effort; Option B produces richer grep output. A hybrid — manager keeps `>` form,
others adopt `>` where description exceeds one sentence — is also viable. The
decision should be explicit; the current state is drift, not policy.

**Effort:** Low. **Impact:** Low-medium (parser resilience, grep-based tooling
consistency, CI lint readiness).

---

### IO-A7 — Resolve step-7 wording tension in manager Default tier (closes m-A-6)

**Description:** Reword `agents/manager.agent.md:233` from "Invoke @researcher at
Session Start when any step-7 trigger applies" to "Invoke @researcher at Session
Start step 7 when any trigger in that step applies." The word "at Session Start"
is ambiguous when step 1 says "do not invoke yet." A step reference removes the
ambiguity with minimal diff.

**Effort:** Trivial. **Impact:** Low (prevents confusion in edge-case readings of
the Default tier).

---

## Agents-Specific Structural Observations

### 1. Common-constraints policy-accepted; pre-commit hook verified working

The 9× byte-identical common-constraints duplication (23 lines per agent, ~207 repo-
wide) is mechanically enforced by `.githooks/pre-commit` (ICON-0011). All 9 agents
produce the same SHA256 hash for their `<!-- BEGIN: common-constraints --> ... <!-- END: common-constraints -->` block. The duplication is policy-accepted per the ICON-0011
retro and ADR-004. Token-efficiency observations about the always-loaded surface are
still valid (IO-T2 from ICON-0003 remains open), but the duplication is not a defect
in this cycle.

### 2. Dead cross-reference pattern echoes M-CC1 sweep-incompleteness

The `three-layer-enforcement.md` dead reference (M-A-NET1) follows the same shape as
ICON-0003's M-CC1 sweep-incompleteness pattern: a document reference is inserted into
one surface (the manager delegation template) without creating or migrating the
referenced artifact. The ICON-0006 retro codified a distribution-layout rule ("reference
files consumed by distributed skills must live in the consuming skill's folder") but
the `three-layer-enforcement.md` case is a `.context/standards/` reference — a local
context file that the manager expects to read, not a distributed reference file. The
existing standards do not explicitly protect against this class of gap (creating a
reference before creating the referent).

### 3. ICON-0014 branch readiness vs. merge status gap

The ICON-0014 branch is in a "ship it" state (all Progress items checked, reviewer
APPROVED, retro entry ready, only MR-open step pending). The audit brief's assertion
that ICON-0014 "added" the freshness gate is technically forward-looking — the feature
is complete but unshipped. The gap between "feature branch ready" and "main reflects
the feature" is a process observation, not a defect in the feature itself. The relevant
standard is `merge speed`: a complete feature sitting in a pending branch is subject to
merge-conflict risk and delays the enforcement of the new gate for active sessions.

### 4. Sub-agent role boundaries are clean

Scope section wording is consistent across all 7 sub-agents: "Your job ends when you
hand back [output type] — routing decisions belong to the orchestrator, not to you."
No sub-agent contains forwarding logic or re-dispatches work. The Hardcoded tier on
each sub-agent cleanly separates the agent's implementation scope from orchestration
decisions. This is a structural strength the prior audit flagged as PASS and has held.

---

## ICON-0003 Delta

### Fixed since ICON-0003

| ICON-0003 ID | Description | Evidence |
|---|---|---|
| M-I1 | `mode: upgrade` routing contradiction in context-specialist | ICON-0007; `context-specialist.agent.md:89-90` now correctly routes `upgrade` → `upgrade-repo` |
| M-P2 | task-plan-phase-completion delegated context-maintenance directly | ICON-0006; `skills/task-plan-phase-completion/SKILL.md:46` routes through `@context-specialist mode: maintenance` |
| M-I3 | `initialize-multimodule` missing `disable-model-invocation: true` | ICON-0008; CHANGELOG 1.15.4 confirms frontmatter alignment |
| M-U2 | `writing-skills` stale skill-registration instructions | ICON-0009; CHANGELOG 1.15.4 Fixed entry confirms removal |
| M-P1 | `design-first` Step 3 "hard gate" phrasing | ICON-0005; CHANGELOG 1.15.4 confirms advisory rewrite |
| M-A2 (as defect) | common-constraints 9× duplication — re-classed to policy-accepted | ICON-0011 pre-commit hook; ICON-0003 retro ADR-004 update. Byte-equality mechanically enforced. Improvement opportunity IO-T1/IO-T2 still open. |
| m-6 (context-specialist doubled scope) | `context-specialist.agent.md` doubled scope rule inside/outside common-constraints | ICON-0007 sweep confirmed — agent body now has single scope statement at `:26-32`; constraints block `:138-139` carries only the sibling-directory exclusion, which is complementary, not duplicative. Fixed. |
| m-8 (initialize-multimodule key order) | frontmatter key-order divergence | ICON-0008 confirmed via CHANGELOG |

### Still present or partial

| ICON-0003 ID | Description | Current location |
|---|---|---|
| M-A1 | Planner odd code-fence count | `agents/planner.agent.md:45,:60,:87` — now m-A-1 (carry-forward) |
| M-A3 | Architect AR table 4 abstraction-family rows with same shape | `agents/architect.agent.md:103-117` — carry-forward; per audit brief, no wholesale removal proposals |
| m-A1 | Manager hardcoded "3+" threshold | `agents/manager.agent.md:182,:247` — now m-A-2 |
| m-A4 | PM Session Start lacks common-constraints acknowledgement | `agents/product-manager.agent.md:14-16` — now m-A-3 |
| m-A5 | PM Session Start positioned after `## When to Invoke` | `agents/product-manager.agent.md:10,:14` — now m-A-4 |
| m-A6 | No agent references `mr-discipline` | All 9 agents — now m-A-5 |
| m-A7 | Manager step-7 / Default tier wording tension | `agents/manager.agent.md:32,:233` — now m-A-6 |

### Net-new

| ID | Description | Location |
|---|---|---|
| M-A-NET1 | Dead cross-reference: `three-layer-enforcement.md` cited but never created | `agents/manager.agent.md:151` |
| M-A-NET2 | ICON-0014 plan.md freshness gate complete but unmerged | `feature/ICON-0014-plan-md-freshness-gate` branch; absent from `main` |
| m-A-NET3 | Reviewer checklist category list duplicated in Default tier | `agents/reviewer.agent.md:25,:68` |
| m-A-NET4 | Manager and context-specialist frontmatter use `>` folded scalar; other 7 use single-quoted string | `agents/manager.agent.md:2`, `agents/context-specialist.agent.md:2` vs. remaining 7 |
