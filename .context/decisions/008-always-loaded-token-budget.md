# ADR-008: Always-loaded session token budget for manager and PM dispatchers

**Date**: 2026-05-21
**Status**: Accepted

## Context

- Audit cycles (ICON-0015, ICON-0033 antecedents) have repeatedly observed that the always-loaded dispatcher surface — manager.agent.md or product-manager.agent.md plus the nine inlined `shared/common-constraints.md` blocks plus `skills/using-skills/SKILL.md` — has grown incrementally with no formal ceiling. Each individual addition looks reasonable at PR review time; the cumulative drift is invisible.
- The Brief 06 estimate cited approximately 7,865 words for the manager session. The ICON-0033 baseline measurement (see `.context/tasks/ICON-0033-token-economy-trims/word-count-snapshot.md`) put it at 8,062 words — roughly 2.5% drift between audit cycles with no formal trigger to surface it.
- Without a stated budget, the audit cycle is the only friction signal, and the cycle fires on retrospective discovery rather than at the moment of growth. A budget makes the question "are we within ceiling?" answerable on every PR, not only at audit time.

## Decision

- **Per-session word budget**: manager = **8,500 words**; PM = **7,000 words**. Both are descriptive-with-modest-headroom: 5.4% headroom over the manager baseline (8,062) and 6.6% over the PM baseline (6,564). The budget is a **ceiling, not a target** — the desired steady state is the current baseline; the headroom exists to absorb minor edits without churning this ADR, not as a "spend it" allowance.
- **Per-component cap**: no single always-loaded component may exceed **40%** of its session budget (3,400 words for manager; 2,800 words for PM).
- **Always-loaded inventory** (defines the surface this budget governs):
  - `agents/manager.agent.md` OR `agents/product-manager.agent.md` (one per session, depending on dispatcher).
  - Nine inlined copies of `shared/common-constraints.md` (one per dispatched agent, synced by `.githooks/pre-commit`).
  - `skills/using-skills/SKILL.md` (always loaded as part of the manager workflow).
- **Re-audit trigger**:

  > Any pull request that grows the manager session total or the PM session total by **≥ 5% of the budget cap** (≥ 425 words for manager, ≥ 350 words for PM) must re-run the word-count inventory before merge and update both ADR-008 and the snapshot artifact (`.context/tasks/<latest>/word-count-snapshot.md` pattern) with the new numbers.

  - **Cumulative-drift re-inventory trigger (audit-scoped)**: independent of the per-PR trigger above, a re-inventory is **mandatory** whenever an audit measures any single always-loaded component to have grown **≥ 5% of its session budget above its baseline** (≥ 425 words for the manager, ≥ 350 words for PM), regardless of whether any individual PR ever tripped the per-PR threshold. The per-PR trigger is PR-scoped and provably misses slow drift: the manager grew **+978 words** cumulatively (4,148 → 5,126) without any single PR's net delta reaching 425 words. The two triggers are complementary — the per-PR gate catches fast growth at merge time; the cumulative-drift gate catches slow accretion at audit time. When this gate fires, follow the same re-inventory + ADR-update procedure defined below, and additionally decide per the per-component cap whether to reduce the component or record an explicit accept-with-rationale overage (see Consequences).

  Operational definition:
  - **Baseline** = the most recent audit-measured snapshot of the always-loaded surface — initially the "Before" column in `.context/tasks/ICON-0033-token-economy-trims/word-count-snapshot.md` after ICON-0033 lands, and thereafter the latest snapshot produced by a re-inventory under either trigger. The snapshot artifact becomes a permanent reference, not a per-task scratch file; each re-inventory supersedes the prior baseline.
  - **"Grows"** = sum of `wc -w` deltas across every file in the always-loaded inventory for that session. Counted in words, not lines. Moving words between files (extracting a block to a sibling) does not trip the trigger — only net session growth counts.
  - **"Re-run the inventory"** = re-execute `wc -l -w` on every file in the snapshot's "Always-loaded surface" table; update both the "after" columns and the session totals.
  - **"Re-audit"** = refresh the snapshot, edit this ADR to update the baseline numbers in Consequences, and decide whether the cap itself needs revision (either reaffirm or change it with fresh rationale).
  - **Scope of "always-loaded"**: the surface defined above. Phase skills, sub-agent files, and on-demand skills are NOT in the always-loaded set and do not count toward the trigger.
  - The trigger is **PR-scoped**, not commit-scoped: a single PR's net delta is what matters. Internal commits within a PR that grow-then-trim are fine.
- **Snapshot artifact**: `.context/tasks/ICON-0033-token-economy-trims/word-count-snapshot.md` is the ADR-008 effective baseline. Future re-audits update or supersede it.

## Consequences

**Positive:**
- Growth has a visible ceiling. MRs that approach the 5% headroom trigger an explicit re-inventory conversation instead of drifting silently.
- The 40% per-component cap prevents the worst case where one file consumes half the session.
- The snapshot artifact gives reviewers a concrete number to compare an incoming PR against, with no extra tooling.

**Negative / known overages at adoption:**
- `agents/manager.agent.md` is at **48.8%** of the manager budget (4,148 / 8,500) — over the 40% cap. Acknowledged at adoption; the next token-economy audit cycle is the venue for reducing it (out-of-scope here per ICON-0033 plan). This is the **next-tier candidate** for the token-economy audit cycle, tracked as a separate ticket.
- **Manager per-component overage, explicitly accepted (ICON-0070, 2026-06)**: after extracting the Task Completion elaboration to the on-demand `phase-completion.md` companion (O-T1b), `agents/manager.agent.md` measures ≈ 4,976 words — still over the 3,400-word (40%) per-component cap. Per issue #35's acceptance ("reduce the count **or** explicitly accept the overage with rationale"), the residual overage is **accepted with rationale**: the remaining bulk is load-bearing and non-extractable — the Hardcoded close-gate (Step 6 + its Hardcoded-tier mirror) and the Anti-Rationalization table are the manager's enforcement surface and cannot move to an on-demand file without losing always-loaded enforcement; the verbose elaboration that *could* move has been moved. This overage is revisited only if a future structural decision (e.g., decomposing the AR table or the common-constraints inlining per ADR-004) makes further reduction possible without weakening enforcement.
- Nine inlined copies of `shared/common-constraints.md` = 3,186 words = **45.5%** of the PM budget — over the 40% cap. Out-of-scope per ADR-004 (inlining is policy-accepted); decomposing constraints would require a structural decision before any reduction is possible. Flagged as the structurally hardest component to trim.
- Reviewers must apply the trigger check manually; there is no automated pre-commit lint counting session totals. (Candidate for a future hook.)

## Alternatives Considered

1. **Trim-to-fit budget (e.g., 7,500 / 6,500)** — rejected. Would force immediate trims of load-bearing content with no plan for what to ship first; manufactures debt the next task must absorb. ICON-0033 already declared common-constraints inlining and AR tables out of scope — the two biggest reducible blocks. Setting a budget below baseline without a shipping plan is process theatre.
2. **Generous budget (e.g., 9,500 / 7,500, roughly current+15%)** — rejected. A cap that far above the baseline silently blesses incremental growth as "within budget" and erases the friction signal. The audit ADR's whole purpose is the friction signal.
3. **No per-component cap; only session cap** — rejected. Without a per-component check, one file can consume the entire session budget while the inventory still passes; the diagnostic value is lost.
4. **Trigger on line count instead of word count** — rejected. Words are the unit the token economy actually pays in; lines vary with formatting (table cells, code blocks) in ways that don't correlate with token cost.
5. **Trigger on every PR (no threshold)** — rejected. Re-inventorying on every documentation typo fix is process friction with no signal. 5% is the smallest threshold that fires only when growth is structural.

## Cross-references

- Baseline measurements: `.context/tasks/ICON-0033-token-economy-trims/word-count-snapshot.md`.
- [ADR-004](004-tool-agnostic-content.md): established the common-constraints inlining policy that puts 9 × 354 words into every session.
- [ADR-005](005-no-build-step.md): no build step; precludes auto-generated session size checks.
- Issue #18 (O-T1 audit, O-T2 / O-T3 / O-T4 trims shipped under the same PR).
