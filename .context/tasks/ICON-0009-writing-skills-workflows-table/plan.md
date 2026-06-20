# ICON-0009: writing-skills dead workflows-table refs

**Status**: ready for review
**Branch**: `feature/ICON-0009-writing-skills-workflows-table`
**GitLab issue**: [#7 (M-U2)](https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/work_items/7)
**Source audit finding**: ICON-0003 audit-report, M-U2 (3rd-cycle carry-forward)

## Objective

Remove two stale references in `skills/writing-skills/SKILL.md` to a "Common Workflows table" that was dropped from `skills/using-skills/SKILL.md` by MKT-0084 but never swept in companion files.

## Approach

Two surgical Edits redirecting authors to anchors that actually exist:

- `:232` (Discoverability) → "document the sequence in the consuming agent's workflow section (manager Workflow Orchestration, product-manager Workflow) rather than in `using-skills`"
- `:530` (Registration checklist) → matching wording

Anchor verification confirmed by reviewer:

- `agents/manager.agent.md:99` — `## Workflow Orchestration` (exists, load-bearing)
- `agents/product-manager.agent.md:18` — `## Workflow` (exists, load-bearing)

## Key files

- `skills/writing-skills/SKILL.md` — two Edits (`:232`, `:530`)

## Verification

```bash
grep -nE "common workflows table|Common Workflows" skills/writing-skills/SKILL.md
# expected: 0 hits

grep -n "consuming agent" skills/writing-skills/SKILL.md
# expected: 2 hits at :232 and :530

grep -rn "common workflows table" agents/ skills/ commands/ README.md
# expected: 0 hits (sweep-completeness check)
```

## Done

- [x] @coder applied both Edits (verification output captured)
- [x] @reviewer approved (no findings; anchor verification + repo-wide sweep both clean)
- [ ] Commit + push + open MR
- [ ] User review/approval
- [ ] Merge to main
- [ ] Retrospective entry

## Notes

This is a concrete instance of the **M-CC1 sweep-incompleteness pattern** flagged in the ICON-0003 audit. The original 2024 sweep visited the primary surface (`using-skills/SKILL.md`) but didn't sweep companion files (`writing-skills/SKILL.md`). Reviewer confirmed the fix itself does NOT repeat that pattern: repo-wide grep for "common workflows table" / "Common Workflows" returns 0 live references across `agents/`, `skills/`, `commands/`, and `README.md`. The 2 hits in `.context/tasks/ICON-0003-plugin-audit/research/` are the audit's own evidence-capture and correctly left in place.
