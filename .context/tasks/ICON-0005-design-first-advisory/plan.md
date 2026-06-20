# ICON-0005: design-first hard-gate contradiction

**Status**: ready for review
**Branch**: `feature/ICON-0005-design-first-advisory`
**GitLab issue**: [#2 (M-P1)](https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/work_items/2)
**Source audit finding**: ICON-0003 audit-report, M-P1 (3rd-cycle carry-forward)

## Objective

Replace contradictory `This is a hard gate:` framing at `skills/design-first/SKILL.md:103` with phrasing that matches the skill's advisory framing established at `:4`, `:14-16`, and `:26-31`. The three approval-flow branches at `:104-106` must remain intact.

## Approach

Single-line Edit. Replace:

- **Before**: `This is a hard gate:`
- **After**: `When you do run a design pass, the approval flow looks like:`

No other text in the skill changes. The three approval-flow bullets continue to function as an exhaustive switch over the three contexts (autonomous / user-available / manager-delegated).

## Key files

- `skills/design-first/SKILL.md` — single Edit at line 103

## Verification

```bash
grep -n "hard gate" skills/design-first/SKILL.md
# expected: only line :4 "Not a hard gate" remains

grep -n "When you do run a design pass" skills/design-first/SKILL.md
# expected: line :103 match

sed -n '99,107p' skills/design-first/SKILL.md
# expected: H3 heading at :99 unchanged; bullets at :104-106 unchanged
```

## Done

- [x] @coder applied the Edit (verification commands run, output captured)
- [x] @reviewer approved (no findings)
- [ ] Commit + push + open MR
- [ ] User review/approval
- [ ] Merge to main
- [ ] Retrospective entry in `.context/retrospectives.md`

## Notes

This is a 3rd-cycle carry-forward finding (MKT-0063 → MKT-0077 → MKT-0087 → ICON-0003). The skill is currently agent-orphan (`grep -rln "design-first" agents/` → 0 hits), so the inconsistency does not propagate to autonomous execution — but any user invoking `/design-first` directly hits the contradiction. This 1-line edit closes the carry-forward without scope creep.
