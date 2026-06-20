## Task: ICON-0060
## Branch: feature/ICON-0060-reach-automation
## Objective: Close two recurring defect *classes* mechanically (ICON-0058 audit #32, "reach-at-the-moment-of-need automation"). Add pre-commit gates so sweep-incompleteness and skill-registration gaps fail at commit time instead of surfacing in the next audit, document the new-skill intake in CONTRIBUTING, and clear the current stale cap-literal sweep so the new gate has a clean baseline.
## Folder: .context/tasks/ICON-0060-reach-automation/

## Decisions
- Address #32 as its own branch/MR (user-directed three-branch split).
- **Stacked branches** (user-directed): this branch is based on `feature/ICON-0059-tier1-correctness`, NOT main, and ICON-0061 (#29) will branch off this one. MRs are accepted in order (#31 → #32 → #29) to avoid merge issues. ICON-0060's MR targets the ICON-0059 branch so its diff is isolated; GitLab auto-retargets it to main when !42 merges.
- Pair O-M1 and O-V1 in the SAME pre-commit hook block (adjacent invariants), per the issue.
- Do the stale "15→10" cap-literal sweep (m5) FIRST so the new cap-literal gate (O-M1b) has a clean baseline — a gate added over dirty state would either block the first commit or need a carve-out.
- Hook gates have false-positive risk (legitimate `<placeholder>` examples in skills/templates; `[TASK-ID]` template tokens). @architect designs the precise detection semantics BEFORE @coder implements — getting the grep wrong either blocks legitimate commits or misses real drift.

## Key Files
- `.githooks/pre-commit`: existing hook (already enforces iconrc version-bump + context_template path-resolution gates per ICON-0044). Add O-M1 (placeholder + cap-literal gates) and O-V1 (skill-registration invariant) here.
- `skills/context-maintenance/scripts/append-retrospective-entry.sh`: defines `ENTRY_CAP` (canonical cap = 10). Reference for the cap-literal gate's source-of-truth and for the sweep target value.
- `README.md`: Skills / Internal Skills tables — the registration target the O-V1 gate asserts against.
- `CONTRIBUTING.md` (~:44–53): add the 3-item new-skill integration checklist (README row / using-skills routing / consuming-agent wiring) — O-V2.
- m5 sweep sites (stale "15"→"10", architect-enumerated, all verified genuine cap refs):
  1. `skills/post-incident-review/scripts/append-retrospective-entry.sh:6` (canonical .sh)
  2. `skills/task-retrospective/scripts/append-retrospective-entry.sh:6`
  3. `skills/context-maintenance/scripts/append-retrospective-entry.sh:6` (canonical ENTRY_CAP=10 at :41)
  4. `skills/upgrade-repo/SKILL.md:616` (preserve 3-space indent)
  5. `context_template/context/retrospectives.md:1` (→ triggers iconrc bump)
  6. `.context/standards/skill-decomposition/process-sweeps.md:155`
  - Sites 1–3 are byte-locked by the existing .sh parity gate (canonical = post-incident-review) — edit together, re-verify `diff -q`. Do NOT touch the .ps1 siblings (already "10").
  - Coincidental numbers to NOT touch: `ecological-impact/SKILL.md:202` (15,000 tokens), CHANGELOG "15"s, version strings.
- O-V1 baseline: `README.md` Internal Skills table is missing TWO rows — `characterization-testing` AND `mcp-tools-first` (m14) — both must be added before the O-V1 gate can pass.
- `.context/tasks/ICON-0058-icon-audit/audit-report.md` (§ O-M1, O-V1, O-V2, m5, m14): source findings with citations.
- `CHANGELOG.md` `[Unreleased]`: entries — the pre-commit gates and CONTRIBUTING checklist affect what contributors do → user/maintainer-facing.

## Progress
- [x] Establish task: branch off ICON-0059 (stacked) + folder + plan.md
- [x] @architect: surveyed pre-commit; enumerated 6 sweep sites; found O-V1 baseline gap (2 missing README rows); designed 4 gates + O-V2 text
- [x] DECISION (user): O-M1a built as a **sentinel-convention gate** flagging `<!-- ICON-PLACEHOLDER -->` only — blanket `<…>` grep is infeasible (243 legit tokens). Scope-narrowing from #32's wording accepted: catches deliberately-marked TODOs, not forgotten raw tokens. O-M1b (cap-literal, narrow/file-scoped) and O-V1 (registration, anchored table-cell regex) unchanged.
- [x] Wave 1 (parallel): m5 sweep 6 sites + iconrc 1.4→1.5 + .sh parity verified (404d58c); README 2 rows alphabetical (4279ca4); CONTRIBUTING checklist + sentinel doc (6bc1160)
- [x] Committed Wave 1 — clean baseline established
- [x] Wave 2: 3 gates implemented in `.githooks/pre-commit` (5653fdf); each verified fires on bad input (exit 1) + clean tree passes (exit 0); manager re-ran hook spot-check (exit 0)
- [x] CHANGELOG (796e5f2): ### Added CONTRIBUTING checklist; ### Fixed cap-literal correction + README registration. Gates omitted (`.githooks/` = repo-internal, legitimate skip).
- [x] @reviewer: 1 Critical (O-M1b scope gap — excluded the 2 non-skills/ sites where the bug actually lived, incl. consumer template), fixed by widening scope to context_template/ + .context/ minus .context/tasks/ + 1 cosmetic Minor; re-reviewed/verified. O-M1a, O-V1 approved as-is.
- [ ] Reconcile plan; retrospective (manager draft → @context-specialist insert) ← IN PROGRESS
- [x] Committed plan+retro (01080de), pushed; MR !43 → https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/merge_requests/43 (targets ICON-0059 branch; Closes #32)

## Outcome
- m5 sweep: 6 stale "15"→"10" cap literals corrected; canonical ENTRY_CAP=10.
- O-M1a: placeholder-sentinel gate (`<!-- ICON-PLACEHOLDER -->`), per user decision (blanket grep infeasible).
- O-M1b: cap-literal gate, scoped to skills/agents/shared/commands + context_template/ + .context/ (excl .context/tasks/) — guards the consumer template where the drift lived.
- O-V1: skill-registration gate (anchored README table-cell regex); baseline fixed (2 missing rows added).
- O-V2: CONTRIBUTING new-skill checklist + sentinel convention doc.
- Key decision: O-M1a narrowed from #32's "blanket placeholder grep" (infeasible — 243 legit tokens) to a sentinel convention. Residual: catches deliberately-marked TODOs, not forgotten raw tokens.

## Gate designs (architect, approved)
- **O-M1a sentinel**: `grep -nF '<!-- ICON-PLACEHOLDER -->'` over staged `skills/*.md`+`agents/*.md` (reuse existing path-bucket loop). Exit 1 on any hit. Zero baseline occurrences. Doc-mention exemption via the existing region-marker precedent or backtick-ignore.
- **O-M1b cap-literal**: parse `ENTRY_CAP` from canonical .sh; for staged cap-narrating files only, assert literals matching `cap \((\d+)\)` / `older than the (\d+)th` / `keep-last-(\d+)` / `(\d+) entries to scan` == ENTRY_CAP. Deliberately narrow; do NOT police plugin.json (separate SSOT).
- **O-V1 registration**: for each `skills/*/SKILL.md`, assert `^\| \`<name>\` \|` present in README.md (anchored table-cell regex avoids substring collisions like initialize-repo/-monorepo). Trigger when skills/** or README staged.
- **O-V2**: append new-skill checklist bullet to CONTRIBUTING.md "Holistic review" section (~after :51); 3 items (README row / using-skills routing / consuming-agent wiring) + a line documenting the `<!-- ICON-PLACEHOLDER -->` sentinel.

## Open Questions / Blockers
- Placeholder-gate definition: what distinguishes an "unresolved" placeholder (a real defect, e.g. a left-in `<TASK-ID>` in shipped skill prose) from a legitimate one (a documented example/template token)? @architect must define this precisely or the gate is unusable. Likely needs an allowlist/heuristic (e.g. only flag outside code fences, or only specific token shapes).
- Cap-literal gate scope: which literals are "cap/version literals" that must match `ENTRY_CAP`? Over-broad matching will false-positive on unrelated numbers.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005. Hook logic IS testable via shell (stage bad input → expect non-zero exit).
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003 (untouched here).
- The new hook gates must not block legitimate commits — false-positive avoidance is a hard acceptance criterion, not a nice-to-have.
- Do not relax existing pre-commit gates (iconrc version-bump, path-resolution).
