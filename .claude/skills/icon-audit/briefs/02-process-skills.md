# Process Skills Audit — Dispatch Brief

## Scope

Investigate skills whose function is orchestration, debugging discipline, TDD discipline, or workflow gating: `task-plan`, `task-plan-phase-investigation`, `task-plan-phase-architecture`, `task-plan-phase-implementation`, `task-plan-phase-testing`, `task-plan-phase-completion`, `systematic-debugging`, `testing-discipline`, `verification-checklist`, `commit-discipline`, `design-first`, `task-retrospective`, `context-maintenance`.

## Inputs (read-only)

- `skills/<skill-name>/SKILL.md` for each skill in scope
- Prior audit pointer: discover via `find .context/tasks -maxdepth 2 -name audit-report.md | sort | tail -n 1` (returns the most recent prior audit report, or empty if none survive). If empty, treat this run as the baseline — skip the prior-audit reading step and report all findings as net-new in your delta section. When a prior audit is found, read specifically its **Process Skills** domain sections before any investigation.
- `.context/retrospectives.md` (recent entries mentioning workflow, debugging, or test failures)
- `CHANGELOG.md` (what changed in these skills since prior audit)

## Prior-Audit Pointer

Read the prior audit's findings for this domain **before** any investigation. Distinguish:
- (a) known-fixed — items the prior audit flagged that are no longer present
- (b) known-unfixed or regressed — items still present or worse
- (c) net-new — issues not present in the prior audit

## ADR / Decision-Log Pointer

Read `.context/decisions/` (the Decision Log) before any investigation. The Decision Log records ICON-wide architectural decisions including scope carve-outs for rules a naive grep would otherwise re-flag. Specifically:

- **ADR-007** (`2>/dev/null` ban scope) — the ban applies to agent-invoked commands only. Findings in autonomous scripts (`.githooks/*`, `context_template/context/workflows/*.sh`, `.claude/skills/*/scripts/*.sh`, `skills/*/scripts/*.sh`) are out of scope. Do not tier such findings as Minor.
- **ADR-009** (skill `description` callers) — skill frontmatter `description` fields are not required to enumerate callers; missing caller lists are not a defect. Do not tier such findings as Minor.
- **ADR-010** (carry-forward re-tier registry) — accepted carry-forward findings (m1 autonomous-script `2>/dev/null` instances per ADR-007 scope; m9 DataScan-flavored example shapes per ICON-0035 disposition) are recorded as "watch / accepted" and must not be re-tiered as Minor without first revisiting the ADR-010 rationale.

For any other ADR in the Decision Log that bears on this brief's domain, apply the same "consult before tiering" rule.

## Forward-Looking Improvements Mandate

Per MKT-0046 user directive: a "no issues found" result is unacceptable. Even if no defects are found, produce at least **3 improvement opportunities** — positive-design suggestions, not defect patches. Examples: skill consolidation candidates, phase-skill overlap reduction, discipline skill rationalization table quality, workflow-chain gaps.

## Output Shape

Produce a single file at `<task-folder>/research/02-process-skills.md` with the following sections in order:

- `# Process Skills Audit — Raw Findings`
- `## Summary` — one paragraph framing what you found and why
- `## Defect Findings` → `### Critical`, `### Moderate`, `### Minor` (tier by risk; empty tiers may be omitted with a "None observed" note)
- `## Improvement Opportunities` — minimum 3; title each, cite Effort/Impact
- `## Process-Skills-Specific Structural Observations` — optional; use for patterns transcending individual findings (e.g., duplicate step-prefix residues across phase skills)
- `## <Prior-Audit-ID> Delta`
  - `### Fixed since <Prior-Audit-ID>`
  - `### Still present or partial`
  - `### Net-new`

Every finding must cite `<file>:<line-range>` or `<file>:<line>`. No conclusions without locations.

## Common Check Patterns

Apply each pattern below to every file in scope. Either report a finding or note "no instances" — silent omission is treated as missed coverage.

1. **Self-reference violation** — Does this skill or agent follow its own rules? (E.g., a `writing-skills` document that exceeds its own length cap.)
2. **Template / standard cross-reference** — Does this skill cite the template, standard, or workflow document that callers are expected to follow? Drift risk if the cited template diverges.
3. **Operational defensiveness** — For any skill that writes, releases, or mutates state: is there a dry-run mode, idempotency guarantee, or partial-failure recovery path?
4. **Frontmatter parser-fragility** — Are descriptions in `>` folded scalar form, or do they mix indentation? Parser-fragile frontmatter breaks grep-based discovery and CI lint.

## Non-Goals

- Do not propose fixes in the plugin source — this is report-only.
- Do not audit domains other than process skills — the synthesis pass cross-checks.
- Do not dispatch sub-agents — this is a leaf-node investigation.
- Do not edit any file outside `<task-folder>/research/`.
