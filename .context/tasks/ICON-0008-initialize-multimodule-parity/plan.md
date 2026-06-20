# ICON-0008: initialize-multimodule feature-branch + MR parity + frontmatter

**Status**: ready for review
**Branch**: `feature/ICON-0008-initialize-multimodule-parity`
**GitLab issues**: [#5 (M-I2)](https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/work_items/5) + [#6 (M-I3)](https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/work_items/6)
**Source audit findings**: ICON-0003 audit-report, M-I2 (carry-forward from MKT-0087 M3) + M-I3 (net-new) + minor m8 (key-order)

## Objective

Bring `skills/initialize-multimodule/SKILL.md` to parity with `skills/initialize-workspace/SKILL.md`:

1. **Per-repo feature branch + MR governance** (#5 / M-I2): the multimodule orchestrator was missing the chore/initialize-agent-context branch creation and the post-Step-6 push+MR phase that its siblings have. For independent-git-repo sub-projects (the skill's primary use case), each sub-project could end up with a single commit on its integration branch with no MR review path.
2. **`disable-model-invocation: true` frontmatter** (#6 / M-I3): siblings (`initialize-monorepo`, `initialize-workspace`) carry the flag; multimodule did not. The MKT-0058 / MKT-0090 invariant ("`/icon-init` is the canonical user-facing entry point") was therefore not enforced uniformly.
3. **Frontmatter key-order normalization** (m8): the three orchestrators had divergent key ordering. Canonical order is now `user-invocable: false` first, then `disable-model-invocation: true`.

## Approach

### Frontmatter changes (3 files of which 2 modified)

| File | Change |
|---|---|
| `skills/initialize-multimodule/SKILL.md` | Added `disable-model-invocation: true` after `user-invocable: false` |
| `skills/initialize-monorepo/SKILL.md` | Swapped key order so `user-invocable: false` precedes `disable-model-invocation: true` |
| `skills/initialize-workspace/SKILL.md` | Already canonical; untouched |

### Structural changes to `initialize-multimodule/SKILL.md`

Mirrored the `initialize-workspace` pattern:

- **NEW Step 4 — Branch creation per sub-repo**: resolves `GIT_ROOT` for each sub-project, collects unique git roots, detects integration branch (develop → main → master → `remote show origin`), creates/checks out `chore/initialize-agent-context`, records per-repo `GIT_ROOT → INTEGRATION_BRANCH` map. Handles non-git sub-projects (note but don't fail). Honors `--force` from Step 0.
- **Step 5 (was Step 4) — Dispatch prompts updated**: both `initialize-repo` and `upgrade-repo` flavors now pass `git_root`, `working_directory`, `feature_branch: chore/initialize-agent-context` and the explicit "feature branch already exists — do not create a new branch and do not switch branches" instruction. Git ops run from `GIT_ROOT`; file scope is `PROJECT_PATH`.
- **NEW Step 8 — Push + per-repo MR**: per-unique-git-root `git push --set-upstream origin chore/initialize-agent-context` + MR creation following `mr-discipline` format, targeting that repo's integration branch. Explicit "Do not merge these MRs yourself" instruction.
- **All subsequent steps renumbered**: 4→5, 5→6, 6→7 (sub-steps 6a/6b → 7a/7b), 7→9. Step 8 is new.
- **Lead-in framing** at the top of the skill explicitly notes the per-repo branch + MR model.
- **Common Mistakes table** updated with two new rows: branch-per-repo and push-without-MR.

## Key files

- `skills/initialize-multimodule/SKILL.md` — frontmatter + structural rewrite (~165 lines insertion)
- `skills/initialize-monorepo/SKILL.md` — frontmatter key-order swap (2 lines)

## Verification

```bash
# Frontmatter parity (M-I3 + m8)
awk '/^user-invocable:|^disable-model-invocation:/{print FILENAME":"NR":"$0}' \
  skills/initialize-{monorepo,workspace,multimodule}/SKILL.md
# expected: each file lists user-invocable on lower line, disable-model-invocation on next line

grep -nE "^disable-model-invocation: true$" \
  skills/initialize-{monorepo,workspace,multimodule}/SKILL.md
# expected: exactly 3 lines

# Step structure (M-I2)
grep -nE "^## initialize-multimodule: Step [0-9]+:" skills/initialize-multimodule/SKILL.md
# expected: Steps 0-9 each once

grep -nE "^git_root:|^feature_branch:" skills/initialize-multimodule/SKILL.md
# expected: 2 hits each (one per dispatch prompt)

grep -nE "chore/initialize-agent-context" skills/initialize-multimodule/SKILL.md
# expected: at least 3 hits (Step 4 creation, Step 5 dispatch, Step 8 push)
```

## Done

- [x] @coder applied frontmatter changes (2 files) + structural rewrite (1 file)
- [x] @reviewer approved (no critical/moderate findings; 3 Minor parity-polish notes deferred)
- [ ] Commit + push + open MR
- [ ] User review/approval
- [ ] Merge to main
- [ ] Retrospective entry

## Notes

- Reviewer's three Minor notes are parity-preserving polish opportunities (e.g., wrapping example snippets in explicit `for` loops, populating `UNIQUE_GIT_ROOTS` array name). Each would also need to be applied to `initialize-workspace` to maintain parity, expanding the MR scope. Deferred — file as a separate follow-up if desired.
- Acceptance criterion's "end-to-end smoke test on a 2-sub-project multi-module setup" is NOT executed here — that requires a real fixture directory. The structural pattern matches workspace exactly, which has been exercised in real deployments.
- No external references to multimodule step numbers exist outside the SKILL.md (verified by sweep), so the renumber is internally self-contained.
