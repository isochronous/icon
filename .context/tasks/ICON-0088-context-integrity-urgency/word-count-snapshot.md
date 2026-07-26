# ICON-0088 — Word-Count Snapshot (ADR-008 re-inventory)

> Baseline measured: `2026-05-21` (ICON-0033, "before" column — carried forward unchanged)
> Current measured: `2026-07-26` (ICON-0088, post-implementation, pre-@reviewer)
> Superseded: `.context/tasks/ICON-0033-token-economy-trims/word-count-snapshot.md` (per ADR-008 § Operational definition, "each re-inventory supersedes the prior baseline" — that file is retained as history, not deleted)

## Trigger

**Cumulative-drift re-inventory trigger fired** (ADR-008 § Re-audit trigger, second bullet): `agents/manager.agent.md` grew from the ICON-0033 baseline of 4,148 words to **4,620 words — a +472-word increase**, exceeding the 425-word threshold (5% of the 8,500-word manager session budget). This crossed during ICON-0088's own implementation step (+64 words for the P0/P1/P2 urgency-rule trigger), which is why this re-inventory is owed by ICON-0088 itself rather than a future audit cycle.

No other component's cumulative growth reached its threshold: the nine `shared/common-constraints.md` copies grew +135 words total (354→369 per copy, ×9) against a 350-word PM threshold — below trigger. `agents/product-manager.agent.md` *shrank* (2,650→2,394); the trigger is growth-only. `skills/using-skills/SKILL.md` grew +16 words (728→744) — far below either threshold.

The per-PR trigger (≥425 manager / ≥350 PM in one PR) did not independently fire — ICON-0088's own edit was only +64 words. This is the cumulative-drift path, not the per-PR path, consistent with how the same gate fired at ICON-0033→now for the manager file overall (978-word drift across multiple PRs, per ADR-008's own worked example).

## Always-loaded surface

Measured with `wc -l -w` on each file directly (2026-07-26):

```
$ wc -l -w agents/manager.agent.md agents/product-manager.agent.md shared/common-constraints.md skills/using-skills/SKILL.md
  312  4620 agents/manager.agent.md
  252  2394 agents/product-manager.agent.md
   23   369 shared/common-constraints.md
   92   744 skills/using-skills/SKILL.md
  679  8127 total
```

| File | Lines (ICON-0033 before) | Words (ICON-0033 before) | Lines (now) | Words (now) | Δ words |
|------|---------------:|---------------:|--------------:|--------------:|--------:|
| agents/manager.agent.md | 289 | 4,148 | 312 | 4,620 | **+472** |
| agents/product-manager.agent.md | 267 | 2,650 | 252 | 2,394 | −256 |
| shared/common-constraints.md (single copy) | 21 | 354 | 23 | 369 | +15 |
| skills/using-skills/SKILL.md | 90 | 728 | 92 | 744 | +16 |
| **Manager session total** (manager.agent.md + 9× common-constraints + using-skills) | — | **8,062** | — | **8,685** | **+623** |
| **PM session total** (product-manager.agent.md + 9× common-constraints + using-skills) | — | **6,564** | — | **6,459** | **−105** |

Note: per the ADR-008 method this snapshot inherits from ICON-0033, `shared/common-constraints.md` is counted once as a single-file row and again ×9 inside each session total — the established (slightly double-counting) arithmetic, carried forward unchanged per the caller's instruction not to silently switch methods. Observation, not a proposed fix: the single-copy row exists for per-file Δ tracking; the ×9 multiplication in the session totals is what the budget actually governs.

## Session totals vs. budget (ADR-008: manager 8,500 / PM 7,000)

| Session | Total (words) | Budget | vs. budget |
|---|---:|---:|---:|
| Manager | 8,685 | 8,500 | **+185 words over (102.2%)** |
| PM | 6,459 | 7,000 | 541 words under (92.3%) |

**The manager session now exceeds its 8,500-word ceiling.** At the ICON-0033 baseline the manager session sat at 8,062 (94.8% of budget, within the 5.4% headroom the budget was sized for). It is now over the ceiling outright, driven by the +472-word growth in `agents/manager.agent.md` plus +135 words of common-constraints drift (×9) plus +16 words of using-skills drift. This is a session-total overage in addition to the pre-existing per-component overage below.

## Per-component vs. 40% cap

| Component | Words | % of its session budget | vs. 40% cap |
|---|---:|---:|---:|
| agents/manager.agent.md (manager session, cap 3,400) | 4,620 | 54.4% | **over — was 48.8% at ICON-0033** |
| 9× common-constraints (manager session, cap 3,400) | 3,321 | 39.1% | under (was 37.5% at ICON-0033: 3,186/8,500) |
| skills/using-skills/SKILL.md (manager session, cap 3,400) | 744 | 8.8% | under |
| agents/product-manager.agent.md (PM session, cap 2,800) | 2,394 | 34.2% | under (was 37.9% at ICON-0033) |
| 9× common-constraints (PM session, cap 2,800) | 3,321 | 47.4% | **over — was 45.5% at ICON-0033** |
| skills/using-skills/SKILL.md (PM session, cap 2,800) | 744 | 10.6% | under |

Both previously-known overages (`agents/manager.agent.md` in the manager session; the nine common-constraints copies in the PM session) persist and have both grown in absolute and percentage terms since ICON-0033. No new component crossed into overage.

## Notes

- This snapshot is now the ADR-008 effective baseline, superseding the ICON-0033 snapshot per the ADR's operational definition ("each re-inventory supersedes the prior baseline"). The ICON-0033 file is retained unmodified as historical record — `decisions/` conventions apply by extension (never delete history that explains why a number changed).
- `agents/product-manager.agent.md`'s −256-word shrink and `shared/common-constraints.md`'s +15-word (×9 = +135) growth both occurred between ICON-0033 and this audit, outside ICON-0088's own edits (ICON-0088 touched only `agents/manager.agent.md`, +64 words, folded into the +472 total above). Their origin task(s) are not identified here — out of scope for this re-inventory, which measures current state rather than attributing intermediate history.
- Per ADR-008 § Re-audit, the cap-revision question was considered: no change to the 8,500 / 7,000 / 40% figures is proposed here — that decision is out of scope per this task's Scope Boundaries, and is recorded as an explicit accept-with-rationale in ADR-008 Consequences (updated alongside this snapshot) rather than a silent carry-forward.
