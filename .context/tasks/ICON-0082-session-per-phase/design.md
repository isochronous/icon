# Architectural Design: ICON-0082 Session-Per-Phase

> Design-only artifact. No `agents/`, `skills/`, `hooks/`, `context_template/`,
> or scripts were modified. A later @coder implements from this after user
> sign-off. Produced by @architect via `design-first`.

## Summary

Enable each task-plan PHASE to run in its own fresh, externally-launched session,
with committed `plan.md` as the sole cold-start carrier between phase runs. Achieved
by (1) hardening `plan.md` with a lean `## Phase State` pointer + an append-only
`## Phase Handoff Log`; (2) flipping every phase from write-forward-only to
**reconstruct-from-plan.md-first, fail-closed**; (3) formalizing the existing
`manager.agent.md:46` delegation-JSON seam into a `{task_id, task_folder, phase}`
entrypoint over a per-task phase state machine; and (4) shipping a portable
**launcher-generator skill** that emits a harness-specific per-phase launcher from a
`target-harness` option. The portable core benefits every consumer regardless of
harness; only the emitted launcher is harness-specific (ADR-004 preserved).

## Recommendation

**Decision**: Approve with modifications (design choices below need user sign-off on
the open questions in §7 before implementation).

**Rationale**: The change is additive and backward-compatible. The plan.md hardening
and reconstruct-first protocol are pure-content and portable — they improve cold-resume
for *all* tasks (even human-driven single-session ones), independent of the launcher.
The per-session split is opt-in and launcher-driven, so nothing regresses for users who
never generate a launcher. The one genuinely harness-specific artifact (the launcher
script) is generated on demand, matching ICON's established "skills that generate
artifacts" pattern (`initialize-*`, `context-specialist-*`).

---

## 1. Phase-Handoff Contract — the hardened `plan.md`

### Design principle: phase boundaries are commit points

The single most important simplification: **every phase boundary ends with a commit.**
A cold phase-N+1 run checks out the branch and reads the committed tree — so if the
boundary is always a clean commit, the working tree is deterministic and gap item #5
(working-tree / staged / uncommitted state) **disappears**: there is nothing uncommitted
to serialize. A phase that leaves uncommitted work has not completed its handoff and must
not advance. This turns "serialize the working tree" into "guarantee a clean commit,"
which is far cheaper and already how ICON operates.

### Carrier choice (alternatives considered)

- **A — New sections inside `plan.md` (RECOMMENDED).** Keeps the single authoritative
  handoff record the whole system already reads; human-authorable; consistent with
  `base.md` + `context-document-guidelines`. Cost: plan.md grows per phase.
- **B — Separate `handoff.json` / per-phase files.** Machine-clean, but splits the
  source of truth, breaks the "one file resumes cold" invariant, and adds a parser
  dependency (ADR-005 friction). Rejected.
- **C — Git commit messages / `git notes` as carrier.** Zero new file content, but
  fragile, hard to author by hand, and invisible to the reconstruct-first read. Rejected.

### New sections added to `base.md`

**`## Phase State`** — placed immediately after the header block (`Task`/`Branch`/
`Objective`/`Folder`), before `Decisions`. Deliberately **lean** so the launcher and a
cold session can parse the pointer cheaply without reading the whole handoff log.

```markdown
## Phase State
- **Phase plan**: investigation → architecture → implementation → testing → completion
- **Completed**: investigation, architecture
- **Current**: implementation   (status: in-progress | done | blocked | pending)
- **Next**: testing
- **Loaded skill**: task-plan-phase-implementation
- **Branch**: feature/ICON-NNNN-slug
- **Attempts (current phase)**: 1
```

- **Phase plan** is the per-task ordered subsequence of the canonical five phases (see
  §3). It is written when the task is created and only changes on an explicit re-open.
- **Completed / Current / Next / Loaded skill** together resolve gap item #1 (active-phase
  / loaded-skill pointer — the skill identity now lives on disk, not just inferred from
  the `← IN PROGRESS` Progress line).
- **Branch** is the integrity anchor for the launcher (checkout target). No commit SHA is
  embedded here — see "SHA/PR handling" below.
- **Attempts** bounds automated retries (loop-termination safety, §4).

**`## Phase Handoff Log`** — placed after `Key Files`, before `Open Questions`. Append-only;
one `###` block per phase as it completes. This carries the heavy, previously session-only
state (gap items #2, #3, #4, #6, #7).

```markdown
## Phase Handoff Log

### Handoff: architecture → implementation   (commit: <trailer-marked>)
**Sub-agent outputs** (gap #2):
- @architect assessment: [verbatim recommendation + rationale, or a faithful quote of
  the load-bearing parts — not a lossy one-line summary]
**Reviewer findings** (gap #3): [each finding + resolution status, or "N/A this phase"]
**Verification evidence** (gap #4): [structural checks run + pass/fail; runtime smoke
  transcript snippets — the actual output, copied, not "passed"]
**Decisions delta**: [decisions made this phase — also mirrored into ## Decisions]
**Key files delta**: [files touched this phase — also mirrored into ## Key Files]
**What the next phase needs** (gap #7): [the warmstart synthesis, written down instead
  of re-derived from memory: entry inputs the next phase must have]
**Retro Stage-1 draft** (gap #6, completion-phase block only): [Avoid / Repeat / Updated
  draft, persisted here instead of "in session state"]
```

### What each gap item maps to

| # | Gap (session-only today) | Where it now lives |
|---|--------------------------|--------------------|
| 1 | Active-phase / loaded-skill pointer | `## Phase State` (Current/Next/Loaded skill) |
| 2 | Verbatim sub-agent findings | Handoff block → **Sub-agent outputs** |
| 3 | Reviewer findings detail | Handoff block → **Reviewer findings** (supplements the one-line `## Review Checkpoint`) |
| 4 | Verification / evidence state | Handoff block → **Verification evidence** |
| 5 | Working-tree / staged state | **Eliminated** by the commit-at-boundary principle |
| 6 | Retro Stage-1 draft | Completion handoff block → **Retro Stage-1 draft** |
| 7 | Prior-work warmstart synthesis | Handoff block → **What the next phase needs** |
| 8 | Post-commit-only fields (SHA/PR#) | See below |

### SHA / PR# handling (gap #8) — avoid the self-reference trap

A commit cannot contain its own SHA, so **do not embed the handoff commit SHA in
`plan.md`.** Instead:

- **Integrity anchor = branch tip.** The launcher checks out `Branch` from Phase State;
  the committed tree IS the state. No stored SHA to drift.
- **Phase-completion marker = a commit trailer.** Each phase-boundary commit carries a
  trailer `Phase-Handoff: <phase>` (e.g. `Phase-Handoff: implementation`). Phase entry
  (§2) verifies `HEAD` carries the trailer for the expected just-completed phase — a
  cheap, self-consistent integrity check with no self-reference.
- **Completion SHA/PR#** remain governed by the existing, already-correct rule in
  `phase-completion.md:23-28` ("Final-state edits need their own commit"). The
  completion phase records SHA/PR# via the small follow-up
  `ICON-NNNN: reconcile plan.md to final state` commit. No new mechanism needed; the
  design simply reaffirms it as the completion-phase exit step.

### What MUST be committed at each boundary

For a cold cross-machine run to resume, the phase-boundary commit MUST include:
`plan.md` (updated Phase State + new Handoff Log block + Decisions/Key Files/Progress
deltas) **and** all source/artifact changes the phase produced. The commit trailer
`Phase-Handoff: <phase>` marks it. Uncommitted work at a boundary = incomplete handoff =
the next phase fails closed.

---

## 2. Phase-Entry Protocol — flip write-forward → reconstruct-first

Today only `phase-completion.md:8-28` (reconcile at close) and the investigation
checklist's "if re-entering after compaction" exception read *from* plan.md on entry.
This design makes **reconstruct-first the mandatory opening step of every phase.**

Add a `## Phase Entry` section to the top of each `phase-*.md` template, and a
corresponding opening step to each `task-plan-phase-*` skill:

```markdown
## Phase Entry (run FIRST, before any phase work)
1. Read `## Phase State`. Confirm this run's `phase` matches `Current`/`Next`, and that
   every phase listed before it in the **Phase plan** has status `done`.
2. Read the immediately-preceding phase's `## Phase Handoff Log` block, plus the
   cumulative `## Decisions`, `## Key Files`, and `## Constraints`. (Bounded read — you
   do NOT need every prior verbatim transcript; you need the preceding handoff + the
   distilled cumulative state.)
3. **Validate the entry contract** for THIS phase (per-phase required inputs below). If a
   required input is missing, or a prerequisite phase is not `done`, or `HEAD` lacks the
   expected `Phase-Handoff:` trailer, or the working tree is unexpectedly dirty —
   **STOP and surface the gap. Do not guess, do not re-investigate to backfill.**
4. Confirm branch == Phase State `Branch`.
```

**Per-phase entry requirements** (fail-closed contract — the minimum the preceding
handoff must supply):

| Phase | Requires from prior handoff |
|-------|-----------------------------|
| investigation | (entry phase — needs only task header + objective) |
| architecture | Investigation findings + scope + open questions |
| implementation | Approved approach/decisions + key files + (if present) architecture assessment |
| testing | Changed-file set + implementation outcomes + Review Checkpoint status |
| completion | Verification evidence + Review Checkpoint covering current changed files |

**Fail-closed rationale**: silently re-deriving missing inputs re-investigates in a cold
session with no memory — exactly the failure mode this task exists to prevent. Surfacing
the gap tells the operator the prior phase's handoff was incomplete (a real defect to fix),
rather than papering over it.

Add a mirrored `## Phase Exit / Handoff` section to each phase template describing the
write-then-commit obligation: write the Handoff Log block + Phase State update + deltas,
then commit with the `Phase-Handoff:` trailer, then mark `Current` done / set `Next`.

---

## 3. Formalized Entrypoint + Phase State Machine

### The entrypoint contract

Formalize the undefined `action` at `manager.agent.md:46` into a phase directive. The
launcher passes:

```json
{ "task_id": "ICON-NNNN", "task_folder": ".context/tasks/ICON-NNNN-slug", "phase": "next" }
```

- `phase` ∈ `{investigation, architecture, implementation, testing, completion, next}`.
- `next` (recommended default the launcher passes) = "read Phase State, run the next
  `pending` phase." This keeps the launcher dumb — it never needs to know the phase list;
  the manager derives it. Explicit phase names remain valid for targeted re-runs.

**Backward compatibility / field choice (alternatives):**
- **A — Repurpose the existing `action` field** to carry the phase directive
  (RECOMMENDED). Smallest change to the pre-existing seam; `action` currently has no
  producers and no defined values, so defining it breaks nothing.
- **B — Add a separate `phase` field**, leaving `action` for future non-phase directives.
  Cleaner separation but adds surface now with no second consumer (YAGNI). Rejected for v1;
  revisit if a non-phase directive ever appears.

The manager entrypoint change (Session Start step 5) stays **minimal** (ADR-008): "if the
delegation JSON carries a phase directive, load that one phase skill and follow its
`## Phase Entry` protocol; execute exactly that phase, write its handoff, commit, update
Phase State, then stop." All the heavy reconstruct/handoff logic lives in the on-demand
phase skills/templates, not in the always-loaded manager role.

### The state machine (reconciling "one primary-concern skill loaded")

Today the manager loads exactly ONE phase skill (the task's primary concern), not all five
in sequence. The per-session model needs an explicit sequence without abandoning that
philosophy. Resolution:

- **Per-task declared phase plan** (RECOMMENDED, vs. a fixed always-five sequence). At task
  creation the manager writes an ordered **subsequence** of the canonical order
  `investigation → architecture → implementation → testing → completion` into Phase State.
  A pure refactor might be `[implementation, testing, completion]`; an investigation-heavy
  task uses all five. This preserves "load only the concern(s) this task needs" while making
  the sequence explicit and machine-advanceable.
- **Canonical order is fixed; the task plan is a subsequence of it.** `completion` is always
  last (it owns the close-gate).
- **Transitions are linear for v1.** Re-open (e.g. reviewer findings route fixes back to
  implementation) is modeled by the manager re-marking the target phase `pending` and
  re-appending it after testing in the phase plan — an explicit, recorded edit, not an
  implicit jump. The launcher then re-runs it.
- **One phase per fresh session.** The entrypoint runs exactly one phase then stops and
  reports `phase X done; next: Y`. It does NOT auto-continue — triggering the next session
  is the launcher's job.

### Backward compatibility with interactive single-session flow

The phase-per-session split activates **only** when the entrypoint receives a phase
directive. A human driving interactively still runs phases back-to-back in one session as
today — but now **always writes the Handoff Log block + Phase State at each boundary.** So
the hardened artifact is produced universally; the per-session execution is the opt-in
overlay. This is the key backward-compat guarantee: the plan.md hardening helps everyone,
the launcher is purely additive.

---

## 4. The Launcher-Generator Skill

**Name**: `generate-phase-launcher` (user-invocable; optional thin `commands/` wrapper for
the Claude Code surface — see changed-file set). Follows the ICON "skill that generates an
artifact" convention. The **generator is portable instruction-content** (markdown + per-harness
script templates as heredoc blocks); only the **emitted script** is harness-specific — this is
the ADR-004 split.

**Config — `target-harness`** ∈ `{claude-code, copilot-cli, generic}`:
- Primary: skill argument (`target-harness=claude-code`).
- Optional default: an OPTIONAL `.context/iconrc.json` field
  `phase_launcher.target_harness` (only if a consumer wants a persisted default). Keep the
  iconrc addition optional to minimize schema churn.

### Harness-agnostic algorithm the generated script implements

1. Parse `plan.md` `## Phase State` → determine the next `pending` phase.
2. **Termination**: if `completion` is `done` (or no `pending` phase remains) → exit 0,
   "task complete." (loop end)
3. **Failure gate**: if the current phase is `blocked`, or `Attempts` ≥ max (e.g. 2) →
   STOP, exit non-zero, alert; **do not advance.**
4. Check out `Branch`; verify working tree clean and `HEAD` carries the expected
   `Phase-Handoff:` trailer for the last completed phase (fail-closed integrity check).
5. Launch a **fresh session/run** executing that phase via the entrypoint (pass
   `{task_id, task_folder, phase: next}`).
6. **On success** (phase reports done AND a new `Phase-Handoff:` commit exists AND Phase
   State advanced): trigger/schedule the next phase run (or exit and let the scheduler
   re-invoke).
7. **On failure** (non-zero, or Phase State did NOT advance): increment `Attempts`, do
   NOT advance, surface the error, stop the loop. Re-running a failed phase from its clean
   committed predecessor state is a safe retry (bounded by `Attempts`).

### Per-harness realization of "fresh session" + "next trigger"

| Harness | Fresh session | Next-phase trigger |
|---------|---------------|--------------------|
| **claude-code** | `claude -p "<delegation JSON>"` headless/print mode — each invocation is a fresh session; the SessionStart hook injects the manager role, the `-p` prompt carries `{task_id, task_folder, phase: next}` | wrapper loop re-invoking `claude -p` until Phase State shows complete, OR a cron entry re-running the script |
| **copilot-cli** | `copilot -p "<delegation JSON>"` analogous headless invocation | same loop / cron pattern |
| **generic (cron/CI)** | a bash+PowerShell-parity script invoked by cron or a CI stage, calling the configured harness CLI | CI job-per-phase with `needs:` on the prior job — CI dependency edges give fail-closed + no-auto-advance-on-failure for free |

### Loop termination & failure handling (explicit)

- Terminates when `completion` is `done` / no pending phase.
- A failed or `blocked` phase **halts** the loop and never auto-advances (§4 step 3/7).
- `Attempts` in Phase State bounds retries to prevent an infinite re-run loop on a
  persistently failing phase.
- The generator ships only script TEMPLATES (no always-on ICON executable), keeping ICON
  pure-content (ADR-005). Any helper the script itself needs (plan.md phase-state parse) is
  embedded in the emitted script and provided in both bash and PowerShell (ADR-005 parity).

---

## 5. Interactions & Cost

**ICON-0081 context-graph discovery per phase.** Context Discovery (graph `--emit` +
bounded traversal) runs at Session Start for medium/complex tasks. Under per-phase
sessions each phase is a fresh session → naive cost is N× the traversal + file reads.
**Recommendation**: run full discovery **once** (first phase) and persist the reachable
context set — the enumerated `.context/` files + applicable `rules-index.md` rows — into
plan.md (a short `Context set:` line in the first handoff block, or folded into Key Files).
Later phases read that distilled list on entry (already mandated by reconstruct-first) and
**skip re-traversal**, reading only their slice. Net: one traversal per task, bounded reads
thereafter — consistent with "reconstruct from plan.md first."

**Main-only (ADR-002) + per-phase commits.** Each boundary is a commit → ~5 commits/task
instead of 1–2. All land on the feature branch (no ADR-002 conflict; the release is still
the tag on `main` post-merge). Each commit is a clean, resumable checkpoint — a feature for
cold resume, not noise. Use a conventional subject (`ICON-NNNN: <phase> phase handoff`) +
the `Phase-Handoff:` trailer so boundaries are identifiable; the PR can squash on merge if a
consumer prefers a single commit.

**ADR-008 always-loaded budget.** The manager Session Start / entrypoint additions stay
lean: only a ~2-line "phase directive → load that phase skill, follow its Phase Entry
protocol, run one phase, stop" rule enters the always-loaded role. Phase State parsing,
the reconstruct-first protocol, and handoff-write instructions all live in the **on-demand**
phase skills/templates. The SessionStart bootstrap (`inject-manager-role.mjs`, <2 KB) is
**not** touched — it needs no phase knowledge; the phase directive arrives via the `-p`
prompt, not the hook.

---

## 6. Changed-File Set, Template Mirror, iconrc Bump, ADR-013

### Portable core (ships to all consumers via both trees)

| File | Change | Version bump |
|------|--------|--------------|
| `.context/workflows/task-plan/base.md` | Add `## Phase State` + `## Phase Handoff Log` sections + Section Guidance | template-version 1.1 → 1.2 |
| `.context/workflows/task-plan/phase-investigation.md` | Add `## Phase Entry` + `## Phase Exit / Handoff` | bump |
| `.context/workflows/task-plan/phase-architecture.md` | same | bump |
| `.context/workflows/task-plan/phase-implementation.md` | same | bump |
| `.context/workflows/task-plan/phase-testing.md` | same | bump |
| `.context/workflows/task-plan/phase-completion.md` | Add `## Phase Entry`; reaffirm SHA/PR follow-up commit as completion exit | bump |
| `skills/task-plan/SKILL.md` | Document Phase State, per-task phase plan, phase-per-session model, entry-protocol pointer | — |
| `skills/task-plan-phase-*/SKILL.md` (all 5) | Add reconstruct-first opening step + handoff-write exit step | — |
| `agents/manager.agent.md` | Formalize `action`/`phase` directive at Session Start step 5 (minimal); note handoff-at-boundary in Progress Tracking | — |

### Template mirror (forces iconrc bump)

All six `context_template/context/workflows/task-plan/*.md` files mirror the `.context/`
changes (divergent version tracks per ADR-010). Touching `context_template/` triggers the
`.githooks/pre-commit` invariant → **bump `context_template/context/iconrc.json` version
1.9 → 1.10** in the same commit.

### New artifacts

| File | Purpose |
|------|---------|
| `skills/generate-phase-launcher/SKILL.md` (+ per-harness script templates under `scripts/` or `references/`) | The launcher-generator (§4) |
| `commands/generate-phase-launcher.md` (OPTIONAL) | Thin Claude Code surface wrapper; Copilot users invoke the skill directly (portability preserved — the skill is the portable surface) |
| `.context/decisions/013-session-lifecycle-cold-resume.md` + README.md log row | ADR-013 (below) |
| `CHANGELOG.md` `[Unreleased]` entry | User/maintainer-facing note |
| `.context/domains/` doc (OPTIONAL) | Session-lifecycle / phase-per-session reference if the domain warrants it |

**Release guard**: no `.claude-plugin/plugin.json` bump. This is eligibility for a future
release, not authorization to cut one.

### ADR-013 (recommended — session lifecycle is a project-wide decision)

```markdown
### Architecture Decision — Session lifecycle: phase-per-session cold resume
**Date:** 2026-07-17
**Decision:** Approve
**Rationale:** Per-phase fresh sessions need a durable cross-session carrier. Committed
plan.md (hardened with Phase State + Phase Handoff Log), reconstruct-first fail-closed
phase entry, phase boundaries as commit points, and a portable launcher-generator
(harness-specific only in the emitted script) together deliver cold resume without
breaking portability (ADR-004), main-only branching (ADR-002), or the always-loaded
budget (ADR-008). No prior ADR governs session lifecycle / cold resume.
**Modifications required:** Confirm the §7 open questions (opt-in scope, target-harness
config location, `action` vs `phase` field, retry policy) before implementation.
**Risks flagged:** plan.md read-cost growth; fail-closed false positives; cross-session
prompt-injection surface (untrusted findings embedded in a handoff must remain DATA).
**Promote to ADR?:** yes — ADR-013 drafted.
```

---

## 7. Risks & Open Questions (user go/no-go)

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| plan.md read-cost grows each phase (cold session reads whole file) | M | M | Bounded reads: entry needs preceding handoff + distilled cumulative state, not every verbatim transcript. Persist ICON-0081 context set once. |
| Fail-closed false positives halt automation (e.g. a legitimately skipped phase reads as "missing") | M | M | "Phase not in the task's phase plan = skip, not fail." Entry checks the phase plan, not the fixed five. |
| Cross-session prompt injection: untrusted sub-agent findings in a handoff block get embedded in the next entrypoint prompt | L | H | Manager's existing untrusted-content rule (`manager.agent.md:72`) applies; handoff findings are DATA. Launcher passes only `{task_id, task_folder, phase}`, never free-form instructions. Run ICON `security-review` on the generated launcher. |
| Automated launcher runs git/shell headless with no human in loop | M | M | Fail-closed entry; bounded `Attempts`; launcher never advances on failure; branch-tip + trailer integrity check. |
| Retro draft / completion spanning sessions | L | M | Retro Stage-1 draft persisted in the completion handoff block (gap #6). |
| Commit noise on the feature branch | H | L | Conventional subject + `Phase-Handoff:` trailer; squash-on-merge option. |

### Open questions for sign-off

1. **Opt-in scope**: confirm phase-per-session is launcher-only, with interactive
   single-session preserved (recommended). Yes/no?
2. **`target-harness` config**: skill argument only, or also an optional
   `.context/iconrc.json` `phase_launcher.target_harness` default?
3. **Entrypoint field**: repurpose existing `action` (recommended, minimal) or add a new
   `phase` field?
4. **Retry policy**: is `Attempts` max = 2 acceptable for automated re-runs before halt?
5. **Command wrapper**: ship the optional `commands/generate-phase-launcher.md` Claude
   surface, or skill-only?
6. **Delivery split**: land the portable core (plan.md hardening + entry protocol +
   entrypoint) and the `generate-phase-launcher` skill together under ICON-0082, or split
   the generator into a follow-up so the hardening merges first?
7. **SHA-less integrity**: confirm the branch-tip + `Phase-Handoff:` trailer approach
   (no embedded SHA) over storing a handoff SHA in plan.md (recommended — avoids the
   self-reference trap).

### Implementation notes for @planner / @coder

- Implement the portable core (base.md + phase templates + skills + manager entrypoint)
  **before** the generator — the generator depends on the Phase State shape existing.
- Every `context_template/` edit MUST pair with the iconrc 1.9→1.10 bump in the same commit
  (pre-commit hook enforces).
- The `agents/manager.agent.md` change is a code-change gate surface (all-nine
  common-constraints block untouched); keep the entrypoint addition to a couple of lines.
- The generated launcher script is a hook/script-class artifact → route it through ICON
  `security-review` before merge, and provide bash + PowerShell parity (ADR-005).
```