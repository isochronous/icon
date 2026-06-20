# ICON-0006: process-skills context-update delegation reconciliation

**Status**: ready for review
**Branch**: `feature/ICON-0006-process-skills-reconciliation`
**GitLab issue**: [#3 (M-P2)](https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/work_items/3)
**Source audit finding**: ICON-0003 audit-report, M-P2 (3rd-cycle carry-forward; concrete instance of M-CC1 sweep-incompleteness)

## Objective

Reconcile `task-plan-phase-completion` ⇄ `task-retrospective` on context-update delegation, and codify the SSOT in a new standards file so future skill authors have a single source of truth.

## Approach

### Skill edit — `skills/task-plan-phase-completion/SKILL.md`

Two surgical Edits routing through `@context-specialist`:

- `:46` "Invoke `context-maintenance` if broad" → "delegate to **@context-specialist** with `mode: maintenance`. See [`./agent-vs-skill-invocation.md`](./agent-vs-skill-invocation.md) for the SSOT."
- `:80-81` (Relationship section) — replaced `context-maintenance` bullet with `@context-specialist` bullet cross-referencing the in-folder reference file. Parenthetical preserves the in-place reminder that direct `context-maintenance` invocation is for the specialist itself.

### NEW reference file — `skills/task-plan-phase-completion/agent-vs-skill-invocation.md`

The SSOT lives in the skill folder so it ships with the plugin (the originally-planned `.context/standards/` location does NOT ship to installed plugin instances — only `agents/`, `skills/`, `commands/`, etc. distribute). 63 lines, 6 sections:

1. **The Rule** — specialist agents own their domain's writes; manager delegates rather than invokes context-domain skills directly. Domain → specialist → invocation-path table covers `.context/`, source code, tests, architecture.
2. **Why** — pre-write audit, idempotency + provenance, pruning + rotation invariants the specialist enforces.
3. **When the manager invokes a skill directly** — names the manager-owned skills (`task-plan`, `commit-discipline`, `mr-discipline`, `verification-checklist`, `task-retrospective`).
4. **Specialist-internal skill chaining** — added in response to reviewer Finding 2; clarifies that a specialist-owned skill (e.g., `upgrade-repo`) MAY invoke another specialist-owned skill (e.g., `context-maintenance`) without violating the standard. Concrete examples include the initialize-monorepo / workspace / multimodule dispatch prompts.
5. **Anti-Rationalization** — three excuses + corrections.
6. **Source** — traces the standard to ICON-0003 M-P2, ICON-0001 retro, GitLab #3. Includes a **Known unresolved** note flagging the `retrospectives.md` ownership contradiction (`manager.agent.md:204` vs `skills/task-retrospective/SKILL.md:113`) as out of scope and filed separately.

## Key files

- `skills/task-plan-phase-completion/SKILL.md` — 2 Edits (`:46`, `:80-81`)
- `skills/task-plan-phase-completion/agent-vs-skill-invocation.md` — new (63 lines, in-folder reference)

## Verification

```bash
# Skill edits
grep -n "@context-specialist\|context-maintenance" skills/task-plan-phase-completion/SKILL.md
# expected: 2 @context-specialist hits, 1 context-maintenance parenthetical

grep -n "agent-vs-skill-invocation.md" skills/task-plan-phase-completion/SKILL.md
# expected: 2 hits (one each in :46 and :80)

# In-folder reference file structure
grep -nE "^## " skills/task-plan-phase-completion/agent-vs-skill-invocation.md
# expected: The Rule / Why / When the manager invokes / Specialist-internal / Anti-Rationalization / Source

grep -n "mode: audit" skills/task-plan-phase-completion/agent-vs-skill-invocation.md
# expected: at least 1 hit (the modes table now includes all four modes)

# Symmetry with task-retrospective
grep -n "@context-specialist.*mode: maintenance" skills/task-plan-phase-completion/SKILL.md skills/task-retrospective/SKILL.md
# expected: both files mention the same delegation phrase
```

## Done

- [x] @coder applied SKILL.md edits + created reference file (initially at `.context/standards/`)
- [x] @reviewer flagged 3 Moderate findings — addressed via polish pass
  - F1: Added `mode: audit` to modes table (was missing the fourth mode from `context-specialist.agent.md:46`)
  - F2: Added "Specialist-internal skill chaining" section clarifying that `upgrade-repo`-invokes-`context-maintenance` etc. are not standard violations
  - F3: Added "Known unresolved" note flagging the `retrospectives.md` ownership contradiction (`manager.agent.md` vs `task-retrospective`); resolution deferred as a separate follow-up
- [x] Commit + push + open MR (MR !6 — original)
- [x] User feedback: `.context/` doesn't ship with the plugin — move the reference file into the skill folder
- [x] Relocate file: `.context/standards/` → `skills/task-plan-phase-completion/` (via `git mv`); update cross-reference links in SKILL.md from `../../.context/standards/...` to `./agent-vs-skill-invocation.md` (relative)
- [ ] Re-commit + push (updates MR !6)
- [ ] User review/approval
- [ ] Merge to main
- [ ] Retrospective entry

## Notes

- Reviewer initially called out 4 sibling skill references (`upgrade-repo:338,377`, `initialize-monorepo:232`, `initialize-multimodule:208`, `initialize-workspace:239`) as sweep-incomplete. On closer inspection, all 5 references are inside `@context-specialist`-owned skills or dispatch prompts to `@context-specialist` sub-sessions — they are the specialist invoking its own tools, not the manager bypassing the specialist. The new "Specialist-internal skill chaining" section in the reference file explicitly addresses this distinction.
- The `retrospectives.md` ownership contradiction is real but pre-existing and orthogonal to M-P2. Resolving it would require coordinated edits to `manager.agent.md:204` and `skills/task-retrospective/SKILL.md:113` — file as a separate follow-up.
- **Distribution correction**: The reference file was initially placed in `.context/standards/`, which is the plugin's own internal documentation directory — `.context/` does NOT ship to installed plugin instances. Per user direction, supporting reference files must live inside the skill folder so they distribute with the plugin. The file was relocated via `git mv` from `.context/standards/agent-vs-skill-invocation.md` to `skills/task-plan-phase-completion/agent-vs-skill-invocation.md`, and cross-reference links updated to relative paths (`./agent-vs-skill-invocation.md`).
