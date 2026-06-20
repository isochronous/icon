## Task: ICON-0059
## Branch: feature/ICON-0059-tier1-correctness
## Objective: Close the two Tier-1 correctness findings from the ICON-0058 audit (GitLab #31). M1: the shipped consumer retrospective template uses `##` headers that the append-retrospective-entry script rejects (entries must start with `###`), so consumer repos silently fail to insert retro entries and the rolling-log cap goes unenforced. M2: `ecological-impact` Option-A is Copilot-only and inoperable from a Claude Code session.
## Folder: .context/tasks/ICON-0059-tier1-correctness/

## Decisions
- Address #31 as its own branch/MR (not bundled with #32/#29): user-directed (three separate branches); the items map to separately-filed task IDs and are heterogeneous concerns.
- Fix the retro-template header in BOTH locations atomically (consumer template + ICON's own copy) — per ICON-0048 lesson, audit citations of one line usually propagate; coder must grep for every `## Retrospective` template occurrence, not just the two cited.
- Verify M1 by actually running `append-retrospective-entry.sh` against an entry produced from the corrected template — acceptance is script exit 0 + entry inserted, not visual inspection.
- M2 is a SKILL.md edit → `writing-skills` + the `ecological-impact` skill must be invoked BEFORE the first edit (ICON-0047/0054 governing-skill rule), and the report's § O-M3 four targeted edits are the baseline.

## Key Files
- `context_template/context/workflows/task-plan/phase-completion.md` (~:53–62): shipped consumer retro template — `## Retrospective — [TASK-ID]` → `### `; bump template-version comment.
- `.context/workflows/task-plan/phase-completion.md` (~:68–79): ICON's own copy of the same template — same fix.
- `skills/context-maintenance/scripts/append-retrospective-entry.sh` (~:115–118): the `### `-requiring consumer; reference only (defines the contract — do NOT relax it).
- `skills/ecological-impact/SKILL.md` (:4,12,17,21,43–74,149,208): Option-A platform-neutral framing + Claude Code sub-option; remove Copilot-only "Remaining Reqs"/billing-quota/header references.
- `.context/tasks/ICON-0058-icon-audit/audit-report.md` (§ O-M3, M1, M2): source findings with file:line citations and the 4 targeted O-M3 edits.
- `CHANGELOG.md` `[Unreleased]`: entry — both changes are consumer-facing (template behavior + skill usable on a new platform).
- `context_template/context/iconrc.json`: template version 1.3→1.4 — required by the ICON-0044 pre-commit gate because a `context_template/` file changed (signals consumers to apply the template update).

## Progress
- [x] Establish task: branch + folder + plan.md created — ICON-0058 confirmed merged to main; on feature/ICON-0059-tier1-correctness
- [x] M1 — fixed retro template header `##`→`###` in both phase-completion.md files + bumped template-version (1.4→1.5 consumer, 1.3→1.4 ICON); body also aligned to canonical `- **Avoid/Repeat/Updated**` form. Grep confirmed no other template occurrences.
- [x] M1 — verified: append-retrospective-entry.sh accepts new format (exit 0, entry inserted) and still rejects old `##` form (exit 1) against a temp file; real retrospectives.md untouched
- [x] M2 — @coder invoked writing-skills + ecological-impact, then reframed Option-A platform-neutral with Claude Code sub-option; output header "Copilot…"→"AI Ecological Impact Report"; residual `copilot` grep = 1 justified cross-platform sub-bullet
- [x] CHANGELOG [Unreleased] → new `### Fixed` block, 2 bullets (M1 template, M2 skill)
- [x] @reviewer pass: 0 Critical, 1 Moderate (eco-impact "skip to Step 4" should be "Step 2" — a token-total user would skip the energy/CO₂ calcs), 2 no-action Minors. Moderate fixed by @coder (now points to Step 2 / "Calculate Energy Consumption"). M1 independently reproduced by reviewer (script exit 0 new format, exit 1 old).
- [ ] Reconcile plan.md; retrospective (manager draft → @context-specialist insert) ← IN PROGRESS
- [x] Committed (1d6d8ea), pushed; MR !42 opened → https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/merge_requests/42 (Closes #31)

## Outcome
- M1: retro template `##`→`###` + body aligned to canonical Avoid/Repeat/Updated form, both copies; template-version bumped (consumer 1.5, ICON 1.4). Verified against append-retrospective-entry.sh.
- M2: ecological-impact Option-A platform-neutral (Claude Code + GitHub Copilot + Other sub-options); output header "AI Ecological Impact Report"; Step-reference bug fixed post-review.
- Reviewer-noted Minor (the two template copies still carry different template-version values, pre-existing divergence) intentionally NOT addressed this task — out of scope for #31.

## Open Questions / Blockers
- None blocking. Note: the audit report links assume !41 is merged — confirmed merged to main, so the references resolve.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005. The only runnable verification here is the bash append script (M1).
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003 (not touched this task).
- Do NOT relax the append script's `### ` requirement to accommodate the template — the template is wrong, the script is the contract.
- The consumer template and ICON's own copy must stay byte-consistent in the header convention.
