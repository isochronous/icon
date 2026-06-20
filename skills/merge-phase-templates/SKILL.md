---
name: merge-phase-templates
description: >
  Internal upgrade-repo skill. Do not invoke without explicit direction.
user-invocable: false
---

# Merge Phase Templates

## Overview

Extract custom additions from a repo's deprecated `task-workflow-template.md` and route them into the appropriate phase template files. This unblocks the standard upgrade path so the deprecated file can be deleted without losing custom workflow content.

## When to Use

- `upgrade-repo` Phase 1 flagged `task-workflow-template.md` as `deprecated (CUSTOMIZED)`
- The repo has a pre-phase-templates copy of the file with team-specific additions that must be preserved before deletion
- **Do not invoke manually** — always invoked by `upgrade-repo` when customization is detected

## Preconditions

`$TEMPLATE_DIR` must be established before this skill begins. It is set by `upgrade-repo` Phase 1 (via the `find-context-template` skill). Do not invoke this skill standalone without first ensuring `$TEMPLATE_DIR` points to the plugin's `context_template/` directory.

## The Process

### merge-phase-templates: Step 1: Identify Custom Content

Read `.context/workflows/task-workflow-template.md` and the stock template from
`$TEMPLATE_DIR/context/workflows/task-workflow-template.md`. Diff the two:

- Lines present in the installed file but absent from stock → **custom additions** — must be preserved
- Lines absent from the installed file but present in stock → **custom deletions** — surface to user (Step 4)

Focus on custom additions first.

### merge-phase-templates: Step 2: Route Custom Additions to Phase Files

Use this heuristic to determine which phase file each addition belongs to:

| Custom content describes | Route to |
|--------------------------|----------|
| Research, context gathering, discovery, initial planning, @researcher / @planner work | `phase-investigation.md` |
| Architecture decisions, structural validation, design review, @architect work | `phase-architecture.md` |
| Implementation steps, coding, file changes, @coder work | `phase-implementation.md` |
| Testing, test coverage, regression checks, @tester work | `phase-testing.md` |
| Code review, retrospective, completion, sign-off, @reviewer work | `phase-completion.md` |
| Applies broadly across multiple phases or is structural metadata | `base.md` |

If a custom addition is ambiguous — plausibly belonging to two or more phase files — **stop and ask the user** before proceeding. Show the addition text and the candidate destinations. Do not guess.

### merge-phase-templates: Step 3: Apply Additions to Phase Files

For each routed addition:
1. Read `.context/workflows/task-plan/<phase-file>.md` (copy from template first if absent)
2. Identify the most semantically appropriate section within that file
3. Stage the proposed change as a diff — do not write yet

Once all additions are staged, show the full set of proposed diffs together and **get a single user confirmation** before writing any of them.

### merge-phase-templates: Step 4: Handle Custom Deletions

If any stock sections are absent from the installed file:
- Show the missing sections to the user
- Ask: *"The installed template omitted these sections. Were they intentionally removed? If yes, I'll note them as intentional. If not, they'll be restored in the next upgrade step."*
- Do not restore without explicit confirmation

### merge-phase-templates: Step 5: Report and Hand Off

After all merges are confirmed and written:
1. Summarize what moved and where it landed
2. Note any items still requiring user decision
3. If no items from Step 3 or Step 4 are still pending user decision, confirm: *"`task-workflow-template.md` can now be deleted — all custom content has been migrated to the phase files."* Otherwise, note what remains unresolved and do not confirm deletion yet.
4. Return control to `upgrade-repo` Phase 2 to complete the file deletion

## Routing Ambiguity Examples

| Custom addition | Likely route | Ambiguous? |
|-----------------|-------------|------------|
| "Delegate to @researcher to check API rate limits" | `phase-investigation` | No |
| "Document ADR in `.context/decisions/`" | `phase-architecture` | No |
| "@coder must run integration tests after changes" | `phase-implementation`, `phase-testing`, or `phase-completion` | **Yes — ask** |
| "Get stakeholder sign-off before proceeding" | Depends on timing in workflow | **Yes — ask** |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Routing ambiguous content without asking | Ask when two destinations are plausible |
| Writing phase files without confirmation | Show diff and confirm for every file changed |
| Silently discarding custom deletions | Surface them — they may be intentional |
| Marking task complete before `upgrade-repo` deletes the deprecated file | Handoff to `upgrade-repo` is required to close the loop |
