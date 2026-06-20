## Task: ICON-0070
## Branch: feature/ICON-0070-token-governance
## Objective: Implement GitLab work item #35 (ICON-0058 audit, Tier 3 — structural): close the ADR-008 cumulative-drift gap so slow per-component growth gets caught even when no single MR trips the per-MR trigger; reduce the manager's always-loaded word count (it is over the 40% per-component cap) by extracting Task Completion *elaboration* to an on-demand companion while keeping every Hardcoded gate inline; and add an audit-finding → follow-up-task disposition ledger so re-scoped findings surface as tracked items.
## Folder: .context/tasks/ICON-0070-token-governance/

## Decisions
- Local task ID **ICON-0070** (next free; work item #35 carries no pre-baked ID after the earlier retitle). References #35.
- Three deliverables: **O-T1a** ADR-008 cumulative-drift trigger; **O-T1b** manager Task Completion elaboration → on-demand companion (keep Hardcoded close-gate one-liner inline); **O-V3** audit disposition ledger. To be sequenced by @architect.

## Architect design (approved — full spec in session)
- **O-T1a**: 3 edits to `008-*.md` — (i) cumulative-drift audit-scoped trigger after the per-MR block; (ii) generalize Baseline to "most recent audit-measured snapshot"; (iii) explicit manager-overage-accepted bullet (≈4,874w still over cap; load-bearing close-gate/AR table can't be cut). Cap literals (3,400/40%) reused verbatim to avoid the cap-literal gate.
- **O-T1b**: extract ~252w from manager (Step 1 reviewer prose → pointer `§ @reviewer Delegation Template` [existing]; Step 3 a/b/c → pointer `§ Two-Stage Retrospective Handoff` [NEW]). Manager target ≤4,920w & < 5,126. The new section added to ALL THREE phase-completion surfaces (ICON-local + template + shipped skill) so the consumer-facing pointer resolves → touches `context_template/` → **iconrc bump 1.7→1.8** + template-version header bumps (local 1.5→1.6, template 1.6→1.7). **ATOMIC**: manager + 3 surfaces + iconrc in one commit (else dead-ref/iconrc gate fails).
- **O-V3**: `## Post-Review Dispositions` table → `.claude/skills/icon-audit/synthesis-template.md`; checklist item → `.claude/skills/icon-audit/SKILL.md`. Maintainer-only, no consumer reach, no rules-index row, no bump. ADR-010 unchanged.
- **No new rules-index rows** (ADR-008 indexed; phase-completion under task-plan parent row; icon-audit is `.claude/`).

## Key Files (per architect spec)
- `.context/decisions/008-always-loaded-token-budget.md`: add the cumulative-drift re-inventory trigger (≥5% cumulative growth-from-baseline measured by an audit, independent of the per-MR gate). May also record the manager per-component overage decision (reduce vs explicitly accept-with-rationale).
- `agents/manager.agent.md`: extract the Task Completion **elaboration** (the verbose step-by-step prose) to an on-demand companion; keep the Hardcoded close-gate one-liner + tier bullets inline. Net word reduction is the goal. NOTE: ICON-0069 just added ~121 words here — recheck current count vs the per-component cap.
- On-demand companion (location TBD): likely a manager-adjacent doc or an existing phase doc (`.context/workflows/task-plan/phase-completion.md` already holds completion elaboration — candidate target vs a new companion). Investigation to determine.
- Audit infra for O-V3: the `icon-audit` skill and/or an audit-report template / `.context/`-adjacent ledger. Generalizes ADR-010's carry-forward registry.
- `.context/tasks/ICON-0033-token-economy-trims/word-count-snapshot.md`: the baseline + measurement method for the manager word count.

## Enumeration findings (read-only Explore)
- **O-T1a (ADR-008)**: `.context/decisions/008-*.md`. Caps at lines 14–15 (manager 8,500 / 40%=3,400). Per-MR trigger at line 21 ("≥5% / ≥425 words per MR... moving words between files does NOT trip it; MR-scoped"). Overage recorded at 41–42 (manager 48.8% at baseline). Slot the cumulative-drift clause after line 22, before "Operational definition:"; generalize the "Baseline" sub-def (line 25) from "ICON-0033 snapshot" to "most recent audit-measured snapshot". Not release-aware (no ICON-0062 ref). Already indexed in rules-index (line 35).
- **O-T1b (manager extraction)**: `wc -w agents/manager.agent.md` = **5,126** (baseline 4,148; **150.8% of per-component cap**, 60.3% session; +978 cumulative drift, never tripped per-MR gate). Movable elaboration = Step 1 reviewer-checkpoint prose (~66w, lines 206) + Step 3 two-stage retro flow (~186w, lines 208–211) = **~252w**. KEEP INLINE (load-bearing): Step 6 close-gate (line 214, 206w) + its Hardcoded mirror (line 238, 181w); the one-liner steps; the common-constraints block (277–301, byte-synced). After extraction ≈ 4,874w — still over per-component cap → O-T1a must ALSO record the overage explicitly with rationale.
- **O-T1b destination + MULTI-SURFACE**: `.context/workflows/task-plan/phase-completion.md` already holds completion elaboration (Reconcile checklist, @reviewer Delegation Template, Retrospective Template) and the manager already points at it 3× (lines 205/228/260); it is NOT always-loaded (confirmed vs ADR-008 inventory). BUT phase-completion exists on THREE surfaces — ICON-local `.context/workflows/task-plan/phase-completion.md` + shipped `context_template/context/workflows/task-plan/phase-completion.md` + shipped skill `skills/task-plan-phase-completion/SKILL.md`. The manager's pointer must resolve for CONSUMERS too → extracted elaboration must land in the template (and likely the shipped skill) copy, not just ICON-local. **Touching `context_template/` trips the ICON-0044 iconrc version-bump gate** (template version currently 1.7 → 1.8). @architect to map exactly which surfaces get the content + whether the shipped skill already has it (investigation says it partly does).
- **O-V3 (disposition ledger)**: add a `## Post-Review Dispositions` table (`Finding ID | Tier | Recommended task | Disposition | Reason`) to `.claude/skills/icon-audit/synthesis-template.md` (after "Suggested Follow-up Tasks") + a Quality Checklist item in `.claude/skills/icon-audit/SKILL.md`. `icon-audit` is **maintainer-only** (`.claude/skills/`, does NOT ship) → no rules-index row, no consumer impact. Prototype = ICON-0058 `audit-report.md § Post-Review Dispositions` (lines 284–290). ADR-010 carry-forward registry (lines 34–40, `Finding|Cycle|Status|Disposition|Rationale`, in-ADR table, "accepted watch" only) stays unchanged — complementary.
- **rules-index**: none of the three needs a new row (ADR-008 already indexed; phase-completion covered by `task-plan` parent row; icon-audit is `.claude/` not `.context/`).

## Progress
- [x] Confirm next free ID (0070), create branch + folder + plan.md
- [x] Read-only enumerate-and-classify pass — 3 deliverables scoped (see findings); multi-surface + template-bump flagged for O-T1b
- [x] @architect designed full spec — O-T1a (3 ADR edits), O-T1b (extract to 3 surfaces + iconrc bump, atomic), O-V3 (maintainer-only ledger); word target ≤4,920w; grep+wc acceptance
- [x] Implement via @coder — all 3 deliverables applied; 3-surface sweep verified (handoff section in all 3); iconrc 1.7→1.8; pre-commit EXIT 0. **Word-count ruling**: manager 5,126 → **4,976** (−150w net off always-loaded). Architect's ≤4,920 was an estimate, not the issue requirement; issue acceptance ("reduce OR accept-with-rationale") satisfied by BOTH the −150w reduction AND the explicit-overage ADR bullet. Did NOT cut load-bearing close-gate/AR content to chase 56 more words. ADR 1a-iii figure corrected 4,874→4,976 to match the true measurement.
- [x] @reviewer checkpoint over the full diff — **APPROVED**, 0 critical / 0 moderate (2 minor: one applied — "session cap"→"session budget" terminology; one left as historical record). See `## Review Checkpoint`.
- [x] changelog-entry — terse one-line `### Changed` (leaner manager); ADR/audit-ledger internal, omitted from consumer changelog
- [x] reconcile plan.md; task-retrospective (entry inserted, cap pruned ICON-0060; lesson promoted to `process-doc-sweeps.md`)
- [x] Commit `83cb02a` (pre-commit EXIT 0); push; open MR — **!54** (https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/merge_requests/54), targets `main`, Closes #35
- [x] Close-gate verification — all 5 PASS (O-T1a 3 edits present; manager 4,976w & a/b/c gone; handoff on 3 surfaces; O-V3 ledger+checklist present; pre-commit EXIT 0)
- [x] **Template-version correction (user-directed)**: released (`latest`/v1.21.0) template iconrc = **1.5**; main drifted to 1.7 via prior unreleased MRs (ICON-0066/0069); the architect/coder followed the per-MR bump pattern → 1.8, but the intended model (ICON-0061) is one bump per release. Corrected `context_template/context/iconrc.json` **1.8 → 1.6** (released 1.5 + one cycle bump). Gate passes (1.6 ≠ main-merge-base 1.7; the ICON-0044 gate checks inequality, not monotonic increase). Merging this branch consolidates main 1.7 → 1.6. **Root cause (gate compares main-merge-base not the release tag; release-plugin doesn't consolidate the template version) is tracked as m16 in #36 — fix there.** pre-commit EXIT 0 after correction.

## Close-Gate (non-skippable, 5 items)
1. **@reviewer covered every code change** — ✅ `## Review Checkpoint` covers the full diff; only a one-phrase terminology fix ran after (reviewer-suggested, no behavior change). Approved 0 critical / 0 moderate.
2. **Project lint ran / output shown** — ✅ N/A pure-content (ADR-005); pre-commit hook EXIT 0 on the commit (the codified substitute).
3. **Code changes covered by tests** — ✅ N/A per `testing-discipline`: doc/governance + agent-prose edits in a no-test repo; verification = grep + `wc -w` + pre-commit gates.
4. **verification-checklist passed** — ✅ run at close; Gates 1–4 pass with fresh command output (O-T1a/b/V3 grep+wc all green, hook EXIT 0).
5. **commit/MR format match discovered conventions** — ✅ `commit-conventions.md` Pattern 1 (`ICON-0070: <imperative>`); MR !54 title matches.

## Review Checkpoint
- **Reviewer**: @reviewer (ICON:reviewer.agent), `code-quality-rules`. **Verdict: Approved.** Covers the full diff (O-T1a ADR-008 ×3 edits, O-T1b manager extraction + 3 phase-completion surfaces + iconrc bump, O-V3 maintainer-only audit ledger). No @coder/@tester step after the applied terminology fix → satisfies close-gate review.
- **Findings**: 0 critical, 0 moderate, 2 minor. Minor #1 (terminology "session cap"→"session budget") APPLIED. Minor #2 (two adjacent overage bullets) left as historical-record per ADR supersede convention — no action.
- **Verified (independent evidence)**: extraction faithful (every Stage-1/2 detail preserved in companion); manager close-gate + AR table + common-constraints UNTOUCHED; `wc -w` 4,976 (<5,126, a/b/c prose gone); handoff section byte-identical across the 2 `.md` surfaces + present in skill; both manager pointers resolve (template + ICON-local); iconrc 1.7→1.8, ICON-0044 gate satisfied; no 4,874 residue; O-V3 maintainer-only (no rules-index row); pre-commit EXIT 0.

## Open Questions / Blockers
- O-T1b destination: extend the existing `phase-completion.md` companion, or create a new manager-completion companion? Must not break the Hardcoded close-gate (the load-bearing one-liner stays inline; only elaboration moves). How does the manager currently reference phase-completion.md (is the pointer already there)?
- O-T1 acceptance allows EITHER reducing the word count OR explicitly accepting the overage in the ADR with rationale — decide which (reduction preferred per the issue, but @architect to assess feasibility without gutting load-bearing content).
- O-V3 ledger home: a section in each audit report, a standing `.context/` table, or part of the `icon-audit` skill output? Generalizes ADR-010 — investigate that registry's current shape first.

## Constraints
- ICON pure-content (no build/test/lint) — ADR-005. Verification = grep acceptance + pre-commit hook + word-count measurement.
- **ADR-008 is the subject AND a constraint**: manager always-loaded budget = 8,500 words; per-component cap = 40% (3,400 words); manager already over it. The extraction must genuinely move words OFF the always-loaded surface (a companion that the manager loads on-demand, NOT inlined). Re-audit trigger = ≥425 words/MR.
- `agents/*.agent.md` carry a byte-synced `common-constraints` block (pre-commit enforced) — do not desync it.
- **rules-index freshness (ICON-0069, just shipped)**: if any new rule file lands under `standards/`/`workflows/`/`decisions/`, it needs a `rules-index.md` row (the pre-commit gate enforces it). ADR-008 edit is an existing ADR (already indexed) — fine.
- Manager owns plan.md + git; specialists do source edits. CHANGELOG entries terse (what+effect, no internal mechanism).
