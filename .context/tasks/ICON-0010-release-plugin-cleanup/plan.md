# ICON-0010: release-plugin CHANGELOG-shape + Error Conditions cleanup

**Status**: ready for review
**Branch**: `feature/ICON-0010-release-plugin-cleanup`
**GitLab issues**: [#8 (M-1)](https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/work_items/8) + [#9 (M-2)](https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/work_items/9)
**Source audit findings**: ICON-0003 audit-report, M-1 (net-new) + M-2 (3rd-cycle carry-forward)

## Objective

Reconcile two drifts in `.claude/skills/release-plugin/SKILL.md`:

1. **Step 5 prose** (#8): said "Insert a new entry immediately below `[Unreleased]`" — contradicting `.context/workflows/changelog.md:11` (rename pattern) and shipped `CHANGELOG.md:9-11` (rename-pattern result). Step 7's `awk` extraction is the strongest internal consistency check: it only works on the rename-pattern output, confirming rename has always been the operationally-correct procedure.
2. **Error Conditions row** (#9): named `sed` directly when Step 6 actually invokes `bump-versions.sh`.

## Approach

Two surgical Edits on the same file, plus one polish edit from review feedback.

### Edit 1 — Step 5 prose (lines 106-110)

Old prose: "Insert a new entry immediately below the `[Unreleased]` block".
New prose: "**Rename** the existing `[Unreleased]` header to `[X.Y.Z] - YYYY-MM-DD`... then **insert a fresh empty `[Unreleased]` section above it**."

Code block updated to show `[Unreleased]` on top followed by `[X.Y.Z]` — matches workflow doc shape and shipped CHANGELOG.

### Edit 2 — Error Conditions row (line 263)

Old: ``| `sed` leaves the manifest at the old version | Stop. Report the file was not updated |``
After polish (from reviewer feedback): ``| Manifest not updated after Step 6 | Stop. Check the `bump-versions.sh` exit code; run `git diff .claude-plugin/plugin.json` to see what (if anything) was changed |``

The polish replaced the initial "inspect for `sed` errors in the script's diff output" with a more accurate instruction (`bump-versions.sh` doesn't print a diff — maintainer must `git diff` themselves).

## Key files

- `.claude/skills/release-plugin/SKILL.md` — Step 5 prose + code block, Error Conditions row at :263

## Verification

```bash
grep -n "Insert a new entry" .claude/skills/release-plugin/SKILL.md
# expected: 0 hits

grep -n "Rename" .claude/skills/release-plugin/SKILL.md
# expected: 1 hit in Step 5 (line 106)

grep -n "bump-versions.sh" .claude/skills/release-plugin/SKILL.md
# expected: 2 hits — Step 6 invocation (:142) + new Error Conditions row (:263)

grep -n "diff .claude-plugin" .claude/skills/release-plugin/SKILL.md
# expected: line :263
```

## Done

- [x] @coder applied Edit 1 + Edit 2 (verification output captured)
- [x] @reviewer approved (no critical/moderate findings; two minor notes)
- [x] @coder applied polish for Minor #2 (Error Conditions accuracy)
- [ ] Commit + push + open MR
- [ ] User review/approval
- [ ] Merge to main
- [ ] Retrospective entry

## Notes

- Reviewer's sweep confirmed no other live references to the old "insert below" pattern in the repo — residuals exist only in frozen task artifacts (`.context/tasks/ICON-0003-plugin-audit/...`), which are correctly preserved as audit provenance.
- Step 7's `awk '/^## \[[0-9]/'` extraction at SKILL.md:224 is the strongest evidence that the rename pattern was always operationally correct — it only works on the rename-pattern output.
- Reviewer's Minor #1 (mirror the parenthetical clarifier into `.context/workflows/changelog.md`) was NOT applied — it would expand scope beyond the issue. If desired, file as a separate follow-up.
