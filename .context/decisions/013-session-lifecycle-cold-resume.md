# ADR-013: Session lifecycle — phase-per-session cold resume via hardened plan.md

**Date**: 2026-07-17
**Status**: Accepted
**Supersedes**: none
**Superseded-by**: none

## Context

A task-plan phase can be run in its own fresh, externally-launched session (a cold
start with no in-memory carry-over from the preceding phase), rather than only
back-to-back inside one interactive session. Nothing today governs how a phase resumes
cold: the phase skills write forward but read from `plan.md` only in narrow exceptions
(reconcile-at-close and the post-compaction re-entry note), and the load-bearing handoff
state — verbatim sub-agent findings, reviewer findings, verification evidence, the
warmstart synthesis, the working-tree state — lives only in session memory. A cold
phase run therefore has no durable carrier and would silently re-derive (re-investigate)
missing inputs, which is exactly the failure mode this decision exists to prevent.

No prior ADR governs session lifecycle or cold resume. The decision must also fit within
existing constraints: portability across Claude Code and Copilot CLI (ADR-004), the
`main`-only branch model (ADR-002), the always-loaded manager/PM token budget (ADR-008),
the no-build-step / pure-content posture (ADR-005), and the `.context/` knowledge graph
seams (ADR-012).

## Decision

Make committed `plan.md` the sole cold-start carrier between phase runs, and split the
portable core from the one harness-specific artifact.

- **Harden `plan.md` as the durable carrier.** Add a lean `## Phase State` pointer
  (phase plan as an ordered subsequence of the canonical five phases, plus
  completed / current / next / loaded-skill / branch / attempts) immediately after the
  header block, and an append-only `## Phase Handoff Log` (one `###` block per completed
  phase) carrying the previously session-only state: verbatim sub-agent outputs, reviewer
  findings, verification evidence, decisions/key-files deltas, the next-phase warmstart
  synthesis, and the completion-phase retro Stage-1 draft.
- **Flip phase entry from write-forward-only to reconstruct-from-plan.md-first,
  fail-closed.** Every phase opens by reading Phase State and the preceding handoff block,
  validating a per-phase entry contract (required inputs present, prerequisite phases
  `done`, `HEAD` carries the expected trailer, branch matches, working tree clean). If any
  check fails the phase STOPS and surfaces the gap rather than silently backfilling by
  re-investigating.
- **Phase boundaries are commit points.** Each boundary ends with a commit that includes
  the updated `plan.md` and all source/artifact changes the phase produced, marked with a
  `Phase-Handoff: <phase>` trailer. This makes the committed tree the deterministic state,
  eliminates any uncommitted working-tree serialization problem, and gives a
  self-consistent integrity check with no commit-SHA self-reference (the branch tip is the
  anchor; the trailer confirms the just-completed phase).
- **Ship the launcher generator as a portable skill emitting a harness-specific script.**
  A `generate-phase-launcher` skill is portable instruction-content; only the emitted
  launcher script is harness-specific (`target-harness` ∈ claude-code / copilot-cli /
  generic), matching ICON's established "skill that generates an artifact" convention and
  preserving ADR-004. The generated script parses Phase State, checks the fail-closed
  integrity gate, launches one fresh session per phase, and never auto-advances on failure.

This decision complements rather than supersedes the constraining ADRs: it operates within
ADR-002 (all phase commits land on the feature branch; the release is still the tag on
`main`), ADR-004 (portable core, harness-specific only in the emitted script), ADR-008
(only a ~2-line phase-directive rule enters the always-loaded manager role; the heavy
reconstruct/handoff logic stays in on-demand phase skills), and ADR-012 (context discovery
runs once and its reachable set is persisted into `plan.md`, read on later phase entry).

## Consequences

**Positive:**
- Cold cross-session (and cross-machine) resume becomes possible: one committed file
  reconstructs the phase context, so a fresh session never re-investigates to recover lost
  state.
- The hardened `plan.md` helps every task, not only launcher-driven ones — an interactive
  single-session run now also writes the handoff block and Phase State at each boundary, so
  the durable artifact is produced universally while the per-session split stays opt-in and
  purely additive.
- The commit-at-boundary principle turns "serialize the working tree" into "guarantee a
  clean commit," which is cheaper and already how ICON operates; each boundary is a clean,
  resumable checkpoint.
- Fail-closed entry converts a silent re-derivation (the failure this work targets) into a
  visible defect report against the prior phase's handoff.
- Portability is preserved: the generator and hardened core ship to all consumers; only the
  emitted launcher is harness-specific.

**Negative:**
- `plan.md` grows per phase, raising cold-read cost; mitigated by bounded entry reads
  (preceding handoff + distilled cumulative state, not every verbatim transcript) and by
  persisting the ADR-012 context set once.
- Fail-closed entry can false-positive (e.g. a legitimately skipped phase reading as
  "missing"); mitigated by checking the task's declared phase plan rather than the fixed
  five — a phase not in the plan is a skip, not a failure.
- Per-phase commits increase feature-branch commit count (~5 vs 1–2); mitigated by a
  conventional subject plus the `Phase-Handoff:` trailer and an optional squash-on-merge.
- A cross-session handoff embeds sub-agent findings into the next entrypoint prompt,
  widening the prompt-injection surface; the launcher passes only
  `{task_id, task_folder, phase}` (never free-form instructions), handoff findings remain
  DATA under the manager's existing untrusted-content rule, and the generated launcher is
  routed through ICON `security-review`.

## Alternatives Considered

1. **Separate `handoff.json` / per-phase carrier files, or git commit messages / `git
   notes` as the carrier:** rejected. A separate JSON file splits the source of truth,
   breaks the "one file resumes cold" invariant, and adds a parser dependency (ADR-005
   friction); commit messages / notes are fragile, hard to author by hand, and invisible to
   the reconstruct-first read. Keeping the carrier inside `plan.md` preserves the single
   authoritative, human-authorable handoff record.
2. **Embed the handoff commit SHA in `plan.md`:** rejected — a commit cannot contain its own
   SHA, and a stored SHA drifts. The branch tip is the integrity anchor and the
   `Phase-Handoff:` trailer confirms the completed phase, avoiding the self-reference trap.
3. **Fixed always-five phase sequence, or a make-every-phase-load-all-five model:**
   rejected in favor of a per-task declared phase plan (an ordered subsequence of the
   canonical order). This preserves ICON's "load only the concern(s) this task needs"
   philosophy while making the sequence explicit and machine-advanceable.
4. **Push the phase-advance logic into the always-loaded manager role, or into the
   SessionStart bootstrap hook:** rejected — it would load reconstruct/handoff instructions
   into the surface ADR-008 most tightly budgets. Only a minimal phase-directive rule enters
   the manager; the phase directive arrives via the `-p` prompt, not the hook.
