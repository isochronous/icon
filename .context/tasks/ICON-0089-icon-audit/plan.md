## Task: ICON-0089
## Branch: feature/ICON-0089-icon-audit
## Objective: Run the repo-level `icon-audit` skill against the ICON plugin at v2.0.0, with a user-directed focus on identifying opportunities to offload responsibility from the LLM to deterministic scripts (hooks, gates, generators). Produce a tiered audit report with scorecard, defect inventory, improvement opportunities, delta vs ICON-0058, and fix-tier recommendations.
## Folder: .context/tasks/ICON-0089-icon-audit/

## Phase State
- **Phase plan**: investigation → completion
- **Completed**: —
- **Current**: investigation   (status: in-progress)
- **Next**: completion
- **Loaded skill**: task-plan-phase-investigation
- **Branch**: feature/ICON-0089-icon-audit
- **Attempts (current phase)**: 1

## Decisions
- Task is investigation-only (audit produces a report, not source changes): phase plan is `investigation → completion`, skipping architecture/implementation/testing. Rationale: `icon-audit` Phase 2 dispatch rule — "No sub-agent edits plugin source files. All output goes to `<task-folder>/research/`."
- Branched off freshly-updated `main` (`ae4cf39`, PR #9 / ICON-0088 merged) rather than the ICON-0088 feature branch. Rationale: audit the released + merged state, not an in-flight branch.
- User-directed focus this cycle: **script-offload opportunities** — every domain brief carries an added directive to surface work currently done by LLM judgment that a deterministic script, hook, or generator could do instead. This is additive to the standard brief scope, not a replacement.
- Six domain sub-agents dispatched per the standard brief set (01–05 in parallel, 06 cross-cutting after). Model tier `complex` (Opus) for all six — audit findings are architectural/cross-cutting judgment work, the explicit `complex` trigger in `manager-routing-guide`.
- **Brief premise correction (domain 04)**: the dispatch brief asserted the `ecological-impact` / ADR-004 Moderate was a three-cycle carry-forward heading for a fourth. False — ICON-0059 closed it (`CHANGELOG.md:91`), verified on disk. The stale premise came from the manager's dispatch prompt, not from the ICON-0058 report. Recorded here so synthesis reports the correction rather than the premise, and so future audit dispatches derive carry-forward status from the CHANGELOG rather than from the prior report alone.
- **`.context/` inaccuracies corrected in-task, not queued** (`context-maintenance § Ownership and Urgency`, ICON-0088 P0 tier). Dispatched to @context-specialist `mode: maintenance` concurrently with the domain-06 pass; the Hardcoded rule forbids deferring an identified `.context/` inaccuracy to a follow-up, since every agent that loads the file is misled until the fix lands. Outcome — **one of the two dispatched claims was itself false, and the sweep found two defects nobody had cited**:
  - `.context/domains/github-access.md:11` — **claim invalidated.** The line already described the ICON-0080 removal in the past tense and was accurate against the current `skills/` tree. Left untouched. The stale premise originated in the manager's dispatch prompt, not in the domain-04 research file.
  - `.context/domains/github-access.md:24` — **net-new, found by the sweep.** Said "a single Node.js hook wrapper"; corrected to two, with a cross-reference to `domains/hooks.md`.
  - `.context/domains/hooks.md:52` — **confirmed as cited.** "One hook" → two, plus the missing `guardrail-pretooluse` table row (`PreToolUse`, matcher `*`).
  - `.context/domains/hooks.md` hook table — **net-new, found by the sweep.** The `inject-manager-role` matcher literal read `startup|resume`; `hooks/hooks.json` actually registers `startup|resume|clear`. Corrected to source.
  - Lesson for the audit's own method, worth carrying into the report: **2 of the 4 corrections came from the instruction to sweep the file for the whole staleness class rather than fixing only the cited line, and 1 of the 2 cited lines was wrong.** A manager-relayed finding is a lead, not a verified fact — the "verify against source before editing" instruction is what caught it. This is the same verify-don't-assume class as the ICON-0085 retro entry.

## Key Files
- `.claude/skills/icon-audit/SKILL.md` — the audit procedure being executed.
- `.claude/skills/icon-audit/briefs/01-agents.md` … `06-cross-cutting.md` — per-domain sub-agent briefs.
- `.claude/skills/icon-audit/synthesis-template.md` — structural guide for `audit-report.md`.
- `.context/tasks/ICON-0058-icon-audit/audit-report.md` — prior-audit baseline for the delta section.
- `.context/tasks/ICON-0089-icon-audit/research/01..06-*.md` — sub-agent outputs (this task).
- `.context/tasks/ICON-0089-icon-audit/audit-report.md` — the synthesis deliverable.

## Phase Handoff Log

*(appended at each phase boundary)*

## Progress
- [x] Phase 1 Discovery — baseline established (see Baseline Preamble below)
- [x] Create branch + task folder + plan.md
- [x] Phase 2a — domains 01–05 dispatched in parallel, all returned. Raw counts before synthesis dedup: **5 Critical** (3 × domain 03 consumer-facing, 2 × domain 05 release-path), **25 Moderate**, **39 Minor**, **~34 script-offload candidates**.
- [x] Phase 2b — domain 06 (cross-cutting) returned. 34 candidates merged to 20 + 2 prerequisites; corrected two upstream specifications and one premise in the dispatch brief.
- [x] In-task `.context/` correction (P0, ICON-0088 urgency rule) — 4 fixes, committed `8de5f48`. One dispatched claim invalidated; 2 of 4 fixes found by class-sweep rather than the cited line.
- [x] Phase 3 — `audit-report.md` synthesized (706 lines). Deduplicated: **5 Critical / 24 Moderate / 39 Minor** + 33 improvement opportunities. Delta vs ICON-0058: ~24 fixed / 19 still-present-or-partial / 13 net-new. Verdict **FAIR**, down from STRONG.
- [x] @reviewer pass over the only content change on this branch (commit `8de5f48`, two `.context/domains` files)
- [x] Commit audit artifacts (research ×6 + audit-report.md + plan.md) — `02a9020`
- [x] @reviewer verdict: **Approved**. All four values in `8de5f48` verified against `hooks/hooks.json`, the `hooks/` listing, and `guardrail-pretooluse.mjs`. No scope creep. Two informational notes (missing `## Related` footers on both files, pre-dating the commit).
- [x] Retrospective — entry appended via script (11 → 10 entries, 2 pruned to ICON-0073 archive), lesson promoted to `.context/standards/skill-decomposition/verify-design-claims-against-artifacts.md` as a 7th occurrence + a net-new "Relayed-finding corollary (ICON-0089)".
- [x] Post-audit verification addendum added to `audit-report.md` — `x-89-1` confirmed on the fact, corrected on the implication (see below).
- [ ] Second P0 `.context/` sweep — stale single-hook claims in `META.md`, `standards/security.md`, `workflows/branching.md` (+ `overview.md` adjudication), found by the reviewer ← IN PROGRESS
- [ ] Post chat summary; offer to file follow-up tasks as GitHub issues (user confirmation required)
- [ ] Completion — commit remaining artifacts, close-gate, PR

## Post-Audit Verification Results

- **`x-89-1` (retro log over cap) — fact confirmed, implication corrected.** The log was at 11 against `ENTRY_CAP=10` (`append-retrospective-entry.sh:41`), exactly as found. But the append pruned **2** entries (both archived, not discarded) and landed the file exactly at cap — the script's documented multi-prune convergence (`:24-26`), not a broken mechanism. R-9's corrected spec still ships, but as a **detection-latency gate, not a correctness gate**: its value is catching the drift window in which a reader (this audit, for one) infers a broken mechanism from a state the mechanism absorbs on next write. The coalescing assertion is unaffected and remains a genuine correctness check.
- **Stale single-hook claim is wider than the two files first corrected.** Found live in `META.md:7`, `standards/security.md:43` (self-contradicting against its own `:18`), `workflows/branching.md:162`. Bears directly on the roadmap: four of the five sites had not been touched by any recent commit, so **no staged-file-scoped hook could ever have caught them** — the concrete justification for R-2/R-3 being CI-venue rather than pre-commit.
- **`decisions/005-no-build-step.md:12` deliberately not corrected.** Same stale claim, but ADR-005 is the subject of roadmap item **R-0a** (amend or supersede) awaiting user triage; fixing it in passing would pre-empt a decision the report puts to the maintainer.

## Review Checkpoint
- **Stamped**: after commit `8de5f48`, covering the complete changed-file set of content changes on this branch — `.context/domains/hooks.md` and `.context/domains/github-access.md`. Reviewer: @reviewer (tier `default`), dispatched to verify each corrected value against its source of truth (`hooks/hooks.json`, `hooks/`, `.claude-plugin/plugin.json`, `standards/security.md`), sweep-completeness, and `context-document-guidelines` conformance.
- **Not covered, by design**: `.context/tasks/ICON-0089-icon-audit/**` (audit artifacts — the deliverable, produced by six independent domain agents plus a synthesis agent, each of which verified its own findings against source and cited `file:line`) and `plan.md` (manager-owned orchestration artifact). No plugin source file was modified by this task, so there is no source diff to review.

## Open Questions / Blockers
- Whether audit follow-ups get filed as GitHub issues is a user decision at triage time — do not file without confirmation.
- `## Post-Review Dispositions` table (icon-audit quality checklist) requires user triage of every Moderate+ finding; that step is user-gated and may land after the report is written.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005. Lint N/A; the `.githooks/pre-commit` run is the substitute close-gate evidence.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- Release guard: this audit must NOT bump a version, rename `[Unreleased]`, tag, or move `latest`. Audit findings are eligibility for future work, not authorization to release.
- No sub-agent edits plugin source files during the audit; all output is confined to `.context/tasks/ICON-0089-icon-audit/research/`.
- Every finding must cite `<file>:<line-range>` — no conclusions without locations.

---

## Phase 1 Baseline Preamble

*(Every domain brief references this preamble so all six sub-agents share one agreed baseline.)*

- **Prior audit (delta baseline)**: `ICON-0058` — dated **2026-06-10**, audited **v1.19.0 + [Unreleased]**, verdict **STRONG (holding)**, 0 Critical / 3 Moderate / ~17 Minor / ~30 improvement opportunities. Report at `.context/tasks/ICON-0058-icon-audit/audit-report.md`; its research files are in that folder's `research/`.
- **Prior audits before that**: ICON-0046 (2026-05-27, v1.17.2), ICON-0015, ICON-0003.
- **This audit**: ICON-0089, 2026-07-26, plugin version **2.0.0** (tag `v2.0.0`, 2026-07-18) plus an `[Unreleased]` block carrying ICON-0088. Branch `feature/ICON-0089-icon-audit` off `main@ae4cf39`.
- **Interval since baseline**: ICON-0059 → ICON-0088 (~30 tasks), including the **2.0.0 breaking release**: GitHub-only conversion (GitLab/Atlassian MCP servers removed; `mr-*`→`pr-*`, `jira-story`→`github-issue`; CI ported to GitHub Actions), the `.context` knowledge graph + `context-graph` script, session-per-phase execution (`## Phase State` / `## Phase Handoff Log`, phase launcher), model-aware isolated delegation (Haiku/Sonnet/Opus tiers), isolated @architect/@planner, prompt-injection defenses, the `guardrail-pretooluse.mjs` PreToolUse hook, a security CI stage (gitleaks/semgrep/shellcheck), and the ICON-0088 `.context` maintenance urgency tiers + split-gate exemptions.
- **Retrospectives**: `.context/retrospectives.md` = 56 lines (rolling, capped; older entries archived to `.context/retrospectives-archive.md` per ICON-0073).
- **CHANGELOG**: 1065 lines; `[Unreleased]` holds 3 ICON-0088 entries.
- **Current scale**: **9** agents under `agents/`, **50** skills under `skills/` (+ 3 maintainer-only under `.claude/skills/`: `icon-audit`, `release-plugin`, `security-review`, plus `changelog-entry` and `work-roadmap-auto`), **1** plugin manifest (`.claude-plugin/plugin.json`).
- **Existing deterministic scripts (the script-offload starting inventory)**: `hooks/inject-manager-role.mjs`, `hooks/guardrail-pretooluse.mjs`, `.githooks/pre-commit`, `.github/workflows/*` (security CI), `skills/context-maintenance/scripts/{append-retrospective-entry.sh,.ps1, check-rules-index.sh, context-graph.sh,.ps1}`, `skills/task-retrospective/scripts/append-retrospective-entry.{sh,ps1}`, `skills/post-incident-review/scripts/append-retrospective-entry.{sh,ps1}`, `skills/writing-skills/render-graphs.js`, `.context/workflows/prune-context.sh` (+ template copy), `.claude/skills/icon-audit/scripts/structural-check.sh`, `.claude/skills/release-plugin/scripts/bump-versions.sh`.
- **Known-churning areas**: (1) *reach-at-the-moment-of-need* — the ICON-0058 meta-finding that an existing rule is not reached when it applies; ICON-0060 (reach automation), ICON-0069 (rules-index discoverability), and ICON-0088 (binding urgency) are successive attempts at it, which makes it the natural anchor for this cycle's script-offload focus. (2) *sweep incompleteness* — a literal fixed in two named sites persisting in siblings, the standing motivation for a literal-grep gate. (3) *token governance* — ICON-0070/0083 trims and ADR-008 budgets under the manager's cumulative growth.
