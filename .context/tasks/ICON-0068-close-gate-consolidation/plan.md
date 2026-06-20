## Task: ICON-0068
## Branch: feature/ICON-0068-close-gate-consolidation
## Objective: Implement GitLab work item #33 (audit follow-up, originally proposed as ICON-0061): collapse the triple `verification-checklist` close-path invocation to a single authoritative gate, assign close-gate lint-evidence ownership so doc-only closes don't stall, and fix two internal `rfc` skill contradictions. Tier 2 defect cleanup from the ICON-0058 audit.
## Folder: .context/tasks/ICON-0068-close-gate-consolidation/

## Decisions
- Local task ID is **ICON-0068**, not ICON-0061: the work item #33 title bakes in the audit-time ID `ICON-0061`, but that ID (and 0062–0064) were already consumed locally by unrelated tasks (`ICON-0061-sessionstart-hook-bootstrap`, etc.); the local sequence has reached 0067. Next free ID is 0068. The audit report (`.context/tasks/ICON-0058-icon-audit/audit-report.md:289`) records the intended `ICON-0061 → #33` mapping; this task carries the work on under 0068 and references #33 for traceability. The GitLab work item still carries the stale ICON-0061 title — renaming it is the user's call, out of scope here.
- Follow the ICON-0057/0065/0066/0067 close-gate-change precedent (retrospectives): read-only enumerate-and-classify pass first → @architect designs exact edit text + grep-checkable acceptance criteria + cross-reference re-validation list → @coder applies → @reviewer checkpoint during implementation. Dogfood: this task's own close exercises the consolidated gate.
- O-S1 must be **atomic**: remove the verification-checklist invocation from BOTH retro Steps 6–7 AND manager Step 2 in one change, leaving the close-gate (item 4) as the sole authoritative gate plus a one-line standalone-invocation note. The partial-fix history of this exact finding (double→triple across ICON-0046/0057) is the cautionary tale.

- **O-S1a (manager Step 2)**: REPURPOSE in place, do NOT delete/renumber. grep proved zero `Step 2` cross-refs exist, while renumbering would break three `Step 4` refs (lines ~206/207/257). Step 2 → points at the close-gate (Step 6, item 4) instead of independently invoking the skill.
- **O-S1b (retro Steps 6–7)**: DEMOTE the `### Completion Gates (Steps 6–7)` block to a single `### Completion Gate` pointer note — gate owned by manager close-gate; standalone retro users told to invoke `verification-checklist` themselves. Leaves a trace (skill is user-invocable standalone).
- **O-S1 atomicity**: O-S1a + O-S1b land in the SAME commit (partial-fix history is the cautionary tale).
- **m2 (lint owner)**: append N/A-for-pure-content clause to close-gate item (2) at BOTH sites (`manager.agent.md` close-gate prose + Hardcoded-tier mirror); item (2) satisfied by `.githooks/pre-commit` having run. Owned by manager at the gate; no new @coder step, no new lint tool (ADR-005 forbids).
- **No mirror copies**: confirmed `context_template/` and `.context/workflows/task-plan/phase-completion.md` carry no close-gate/completion-gate wording — edits are complete in the 3 files. No edit inside the common-constraints fence.

## Key Files
- `agents/manager.agent.md`: close-path owner. Step 2 verification-checklist invocation to remove; close-gate (Step 6 / Hardcoded tier ~line 210, 233) is the authoritative gate to keep; m2 lint-evidence ownership note to add (Task Completion / close-gate).
- `skills/task-retrospective/SKILL.md`: Steps 6–7 (~lines 127–130) verification-checklist invocation to remove, replaced with a one-line standalone-invocation pointer note.
- `skills/rfc/SKILL.md`: `:312` "Confluence wiki markup" → "Markdown (CommonMark)" (m12); `:182` `*bold*` → `**bold**` (m13).
- `CHANGELOG.md`: `[Unreleased]` entry at task close.

## Enumeration findings (read-only Explore, all 4 findings STILL OPEN)
Verified current state; ICON-0065 (reviewer re-check) and ICON-0067 (commit/MR item 5) ADDED close-gate content but did NOT touch any of these. Close-gate is now **5 items**; verification-checklist is item **(4)**.
- **O-S1 — STILL OPEN.** Three invocation sites (four lines): (a) `agents/manager.agent.md:203` Step 2 "Verify all planned work items are done (invoke `verification-checklist` skill)."; (b) `skills/task-retrospective/SKILL.md:129–130` `### Completion Gates (Steps 6–7)` — Step 6 "Verify all planned work items are done", Step 7 "Confirm all builds and tests pass (invoke `verification-checklist` skill)"; (c) authoritative close-gate item (4) at `manager.agent.md:210` (Task Completion Step 6 prose) AND its Hardcoded-tier mirror `:233`. Authoritative site to KEEP = the close-gate (210/233). Non-close-path invocations to LEAVE ALONE: `agents/coder.agent.md:18,22`, `agents/tester.agent.md:21`, and the skill's own def file.
- **m2 — STILL OPEN.** No Task Completion step assigns lint; ICON has NO lint command (ADR-005 `.context/decisions/005-no-build-step.md`: pure content, no package.json/Makefile/CI). In-practice substitution already exists: `ICON-0067` plan.md recorded "(2) Lint: N/A — pure-content repo (ADR-005)… Substituting gate = pre-commit hook (`.githooks/pre-commit`) ran and passed." Fix = codify this N/A-for-pure-content + pre-commit-hook substitution into the close-gate so doc-only closes don't stall.
- **m12 — STILL OPEN.** `skills/rfc/SKILL.md:312` "It is formatted in Confluence wiki markup" — contradicts `:142` "Output is **Markdown** (CommonMark)" and the actual example. → "Markdown (CommonMark)".
- **m13 — STILL OPEN.** `skills/rfc/SKILL.md:182` metadata-table labels "via `*bold*` syntax" (renders italic) — schema `:149`, Formatting checklist `:301`, example all use `**bold**`. → `**bold**`.

## Progress
- [x] Fetch work item #33, resolve task-ID collision, set up branch + folder + plan.md — ICON-0068, branch `feature/ICON-0068-close-gate-consolidation`
- [x] Read-only enumerate-and-classify pass — all 4 findings confirmed STILL OPEN (see above); not pre-empted by ICON-0065/0067
- [x] @architect designed exact edit spec — O-S1a repurpose-in-place, O-S1b demote-to-pointer, m2 two-site N/A clause, m12/m13 string swaps; grep-checkable acceptance criteria + no-mirror-copies confirmed
- [x] @coder applied the six edits (O-S1a/b, m2×2, m12, m13) across the 3 files; all 13 acceptance greps matched expected counts; left uncommitted
- [x] @reviewer checkpoint over the diff — APPROVED, no critical/moderate findings (see `## Review Checkpoint`)
- [x] changelog-entry — two `[Unreleased] ### Fixed` bullets added (consolidation+lint-owner; rfc m12/m13), both `(ICON-0068)`
- [x] reconcile plan.md (all sections reflect final state); task-retrospective — entry inserted (cap pruned ICON-0058), lessons promoted to `.context/workflows/task-start-conventions.md`, writes staged
- [x] Commit (`ec16f15`, pre-commit hook passed); push; open MR — **!52** (https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/merge_requests/52), targets `main`, Closes #33
- [x] Close-gate verification — all 5 items PASS (see `## Close-Gate` below)

## Close-Gate (non-skippable, all 5 PASS)
1. **@reviewer covered every code change** — ✅ `## Review Checkpoint` covers the full six-edit diff; no @coder/@tester step ran after it (close-gate condition satisfied without re-run). Verdict: approved, 0 critical / 0 moderate.
2. **Project lint ran / output shown** — ✅ N/A for this pure-content repo (ADR-005, no lint command) — satisfied by the pre-commit hook (`.githooks/pre-commit`), which ran on commit `ec16f15` and re-ran post-commit with **EXIT 0**. (This is the exact m2 clause this task added — dogfooded.)
3. **Code changes covered by tests** — ✅ N/A per `testing-discipline`: prose/agent-def edits in a no-test repo have no executable behavior to assert; verification is the grep-based acceptance suite (13 checks), all matched expected counts (output captured in completion).
4. **verification-checklist passed** — ✅ run at close (the now-single authoritative invocation); Gates 1–4 pass, fresh command output captured.
5. **commit/MR format match discovered conventions** — ✅ read `.context/workflows/commit-conventions.md`; commit uses Pattern 1 (`ICON-0068: <imperative>`, no trailing period, no version); MR !52 title matches the commit subject.

## Review Checkpoint
- **Reviewer**: @reviewer (ICON:reviewer.agent), `code-quality-rules` applied. **Verdict: Approved.**
- **Covers**: the full working-tree diff for all six edits (O-S1a/b, m2×2, m12, m13) across `agents/manager.agent.md`, `skills/task-retrospective/SKILL.md`, `skills/rfc/SKILL.md`. No @coder/@tester step runs after this checkpoint → satisfies the close-gate review requirement.
- **Findings**: 0 critical, 0 moderate. 2 observational (minor: Step 2 forward-ref coordinates are positional — inherent to numbered procedure, deliberate architect choice; nit: prose-vs-Hardcoded m2 phrasing asymmetry matches house style). No changes required.
- **Verified**: single authoritative close-path invocation (close-gate item 4); O-S1 atomic; `Step 4` Commit cross-refs intact (repurpose-in-place, no renumber); m2 both sites consistent + no invented lint tool (ADR-005); EDIT 2 preserves standalone-retro contract; no out-of-scope/fence/version/changelog collateral; markdown clean.

## Open Questions / Blockers
- m2 lint owner: ICON is pure-content (ADR-005) with no lint command — the resolution is likely a close-gate NOTE clarifying that for doc/context-only closes the lint-evidence requirement is satisfied by N/A (or by whatever check the plugin does run), not a new coder lint step. @architect to determine the exact framing so the close-gate does not stall on a non-existent command.

## Constraints
- ICON is pure-content (no compile/test/package manager / no lint command) — see ADR-005. This is the crux of the m2 finding.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003. (Version bump handled at release, not in this task.)
- O-S1 changes are cross-reference-sensitive: per retrospective (2026, ICON close-gate work), renumbering a stepwise procedure can silently break internal "go to Step N" references — re-validate every step cross-reference in manager.agent.md and task-retrospective after removal.
- Three-layer / multi-copy risk: verification-checklist wiring may appear in `agents/`, `skills/`, AND `context_template/` copies — enumeration must sweep all copies so the removal is complete, not partial.
