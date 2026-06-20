# Cross-Cutting Audit — Dispatch Brief

## Scope

Synthesize-axis concerns that transcend individual domains. This brief is dispatched **after** briefs 01–05 are complete; you consume those outputs as inputs. Investigate: token economics (what is loaded on every session vs on-demand), discoverability UX (can a new user find the right skill quickly), onboarding flow cohesion (anchored on `README.md`), retrospective-derived patterns (failure classes that recur across tasks), and net-new drift classes introduced since the prior audit.

## Inputs (read-only)

- `<task-folder>/research/01-agents.md` — agents domain findings (required; wait for completion)
- `<task-folder>/research/02-process-skills.md` — process skills findings (required)
- `<task-folder>/research/03-context-specialist-init.md` — init domain findings (required)
- `<task-folder>/research/04-utility-skills.md` — utility skills findings (required)
- `<task-folder>/research/05-infrastructure.md` — infrastructure findings (required)
- `.context/retrospectives.md` (full log — read for recurring failure patterns)
- `README.md` (skills table and onboarding flow — evaluate discoverability)
- Prior audit pointer: discover via `find .context/tasks -maxdepth 2 -name audit-report.md | sort | tail -n 1` (returns the most recent prior audit report, or empty if none survive). If empty, treat this run as the baseline — skip the prior-audit reading step and report all findings as net-new in your delta section. When a prior audit is found, read specifically its **Cross-Cutting and Improvement Opportunities** sections before any investigation.
- `CHANGELOG.md`

## Prior-Audit Pointer

Read the prior audit's cross-cutting findings and Improvement Opportunities section **before** any investigation. Distinguish:
- (a) known-fixed — items the prior audit flagged that are no longer present
- (b) known-unfixed or regressed — items still present or worse
- (c) net-new — drift patterns not present in the prior audit

## ADR / Decision-Log Pointer

Read `.context/decisions/` (the Decision Log) before any investigation. The Decision Log records ICON-wide architectural decisions including scope carve-outs for rules a naive grep would otherwise re-flag. Specifically:

- **ADR-007** (`2>/dev/null` ban scope) — the ban applies to agent-invoked commands only. Findings in autonomous scripts (`.githooks/*`, `context_template/context/workflows/*.sh`, `.claude/skills/*/scripts/*.sh`, `skills/*/scripts/*.sh`) are out of scope. Do not tier such findings as Minor.
- **ADR-009** (skill `description` callers) — skill frontmatter `description` fields are not required to enumerate callers; missing caller lists are not a defect. Do not tier such findings as Minor.
- **ADR-010** (carry-forward re-tier registry) — accepted carry-forward findings (m1 autonomous-script `2>/dev/null` instances per ADR-007 scope; m9 DataScan-flavored example shapes per ICON-0035 disposition) are recorded as "watch / accepted" and must not be re-tiered as Minor without first revisiting the ADR-010 rationale.

For any other ADR in the Decision Log that bears on this brief's domain, apply the same "consult before tiering" rule.

## Forward-Looking Improvements Mandate

Per MKT-0046 user directive: a "no issues found" result is unacceptable. Even if no cross-cutting defects are found, produce at least **3 improvement opportunities** — positive-design suggestions. Examples: skills table reorganization (user-facing vs internal), always-loaded token surface reduction, onboarding funnel streamlining, missing skill-workflow chains in `using-skills`, retrospective-wisdom automation.

## Output Shape

Produce a single file at `<task-folder>/research/06-cross-cutting.md` with the following sections in order:

- `# Cross-Cutting Audit — Raw Findings`
- `## Summary` — one paragraph framing the cross-cutting state and movement since prior audit
- `## Defect Findings` → `### Critical`, `### Moderate`, `### Minor` (tier by risk; cross-cutting defects are often systemic — clearly label scope)
- `## Improvement Opportunities` — minimum 3; title each, cite Effort/Impact; organize by the 5 standard categories used in the synthesis template (Token Efficiency / Discoverability / Consolidation / Missing Skills / Self-Verification)
- `## Token Economics Analysis` — inventory what loads on every session vs on-demand; flag the highest-impact trim candidates
- `## Discoverability UX Analysis` — evaluate `README.md` skills table, `using-skills` common-workflows table, onboarding flow; flag gaps
- `## Retrospective Pattern Analysis` — identify failure classes that have appeared in 3+ retrospective entries; evaluate whether any warrants a new skill or standard
- `## <Prior-Audit-ID> Delta`
  - `### Fixed since <Prior-Audit-ID>`
  - `### Still present or partial`
  - `### Net-new drift classes`

Every finding must cite `<file>:<line-range>` or `<file>:<line>`. No conclusions without locations.

## Non-Goals

- Do not re-audit individual domains — brief 06 is a synthesis lens, not a seventh domain investigation. Cite domain findings by reference; do not duplicate them.
- Do not propose fixes in the plugin source — this is report-only.
- Do not dispatch sub-agents — this is a leaf-node investigation.
- Do not edit any file outside `<task-folder>/research/`.
