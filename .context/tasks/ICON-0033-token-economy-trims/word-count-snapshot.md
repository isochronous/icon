# ICON-0033 — Word-Count Snapshot

> Baseline measured: `2026-05-21` (before edits)
> After-edit measured: `2026-05-21` (post @coder, pre @reviewer)

## Always-loaded surface

| File | Lines (before) | Words (before) | Lines (after) | Words (after) | Δ words |
|------|---------------:|---------------:|--------------:|--------------:|--------:|
| agents/manager.agent.md | 289 | 4,148 | 289 | 4,148 | 0 |
| agents/product-manager.agent.md | 267 | 2,650 | 267 | 2,650 | 0 |
| shared/common-constraints.md | 21 | 354 | 21 | 354 | 0 |
| skills/using-skills/SKILL.md | 90 | 728 | 90 | 728 | 0 |
| **Manager session total** | — | **8,062** | — | **8,062** | **0** |
| **PM session total** | — | **6,564** | — | **6,564** | **0** |

### Why the always-loaded total didn't move
The issue body explicitly took the two biggest reducible always-loaded blocks **out of scope**:
- Common-constraints inlining (ADR-004 policy-accepted)
- Anti-rationalization tables (load-bearing per `.context/standards/anti-rationalization-tables.md`)

The named trims (O-T2/O-T3/O-T4) all land on **adjacent on-demand surfaces** (reviewer.agent.md, the 5 phase skills, writing-skills/SKILL.md). The session token bill at dispatcher start is unchanged; the value is in (a) the formal ceiling ADR-008 establishes for future growth, (b) the on-demand-load savings, and (c) the dedup elimination on the dispatch-path quality gates.

## Adjacent on-demand surface (heavily loaded, not always-loaded)

| File | Lines (before) | Words (before) | Lines (after) | Words (after) | Δ words |
|------|---------------:|---------------:|--------------:|--------------:|--------:|
| agents/reviewer.agent.md | 119 | 1,057 | 119 | 1,054 | −3 |
| skills/writing-skills/SKILL.md | 549 | 3,271 | 499 | 2,908 | **−363** |
| skills/task-plan/SKILL.md | 83 | 527 | 95 | 601 | +74 |
| skills/task-plan-phase-architecture/SKILL.md | 78 | 478 | 73 | 438 | −40 |
| skills/task-plan-phase-completion/SKILL.md | 106 | 858 | 101 | 820 | −38 |
| skills/task-plan-phase-implementation/SKILL.md | 86 | 525 | 81 | 487 | −38 |
| skills/task-plan-phase-investigation/SKILL.md | 129 | 757 | 124 | 717 | −40 |
| skills/task-plan-phase-testing/SKILL.md | 100 | 591 | 95 | 551 | −40 |
| **task-plan cluster subtotal** (canonical + 5 phases) | 582 | 3,736 | 569 | 3,614 | **−122** |
| **All on-demand surface Δ** | — | — | — | — | **−488** |

New sibling files (offset some of the cumulative content reduction; load only when explicitly referenced):

| File | Lines | Words |
|------|------:|------:|
| skills/writing-skills/skill-creation-checklist.md (NEW) | 41 | 309 |
| skills/writing-skills/testing-skills-with-subagents.md (extended, was 364 lines) | 376 | 2,077 |

## Per-sub-task local impact (final)

### Sub-task A — ADR-008 establishment
- New file: `.context/decisions/008-always-loaded-token-budget.md`
- Budget caps adopted: **8,500 words (manager)** / **7,000 words (PM)** — descriptive-with-headroom (5.4% / 6.6% over baseline)
- Per-component cap: 40% of session budget
- Re-audit trigger: MR-scoped, ≥ 5% of cap (≥ 425 manager / ≥ 350 PM)
- Two known overages acknowledged in Consequences: manager.agent.md at 48.8%; 9 × common-constraints at 45.5% of PM budget.

### Sub-task B — `agents/reviewer.agent.md:68` dedup
- Words: −3 (verified: 1,057 → 1,054)
- Behavior: identical (the 6-category enumeration now sourced exclusively from `:25` and `code-quality-rules` skill)
- Closes **m-A-NET3**.

### Sub-task C — Phase-skill template-override collapse
- 5 phase skills − ~52-word paragraph each + ~22-word pointer each: net **−122 words** across the cluster (after accounting for the canonical paragraph added to `task-plan/SKILL.md`)
- Single source of truth for the rule: future edits land in one file instead of five.

### Sub-task D — `writing-skills/SKILL.md` extraction + secondary trims
- **Line count: 549 → 499** (under the < 500 acceptance gate with 1 line of margin)
- **Words on SKILL.md: −363** (3,271 → 2,908)
- Content not lost — relocated to:
  - `skill-creation-checklist.md` (NEW, 309 words) — Skill Creation Checklist
  - `testing-skills-with-subagents.md` (existing, extended) — `## Testing By Skill Type` per-type guidance
- Closes **m-U-G** (the defining self-reference violation: writing-skills no longer exceeds its own 500-line cap).

## Notes
- The "always-loaded total unchanged" result is the expected outcome of an audit cycle whose named trim candidates target only adjacent surfaces. ADR-008 makes that ceiling explicit so future cycles have a concrete number to argue against when proposing reductions to the in-scope-but-policy-accepted blocks (common-constraints decomposition is the obvious next-tier candidate).
- The on-demand surface savings (488 words across the task-plan cluster + writing-skills) reduce the per-task token cost of medium/complex tasks that load phase skills + writing-skills concurrently.
- This snapshot is the ADR-008 effective baseline. Future re-audits update or supersede it.
