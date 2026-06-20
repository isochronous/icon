# Context-Specialist & Init Audit — Dispatch Brief

## Scope

Investigate the `@context-specialist` agent and its full skill tree, plus the repository initialization and upgrade skills: `context-specialist-detect-tree-position`, `context-specialist-create`, `context-specialist-impl-leaf`, `context-specialist-impl-branch`, `context-specialist-impl-root`, `initialize-repo`, `initialize-monorepo`, `initialize-workspace`, `initialize-multimodule`, `upgrade-repo`, `merge-phase-templates`, `find-context-template`, `resolve-repo-context`, `invoke-sub-project-skill`, `create-iconrc`.

Focus on: architectural coherence between the init path variants, delegation chain integrity, hardcoded references (e.g., project-specific names), parity between leaf/branch/root impl skills, and alignment with the `icon-init` entry point.

## Inputs (read-only)

- `agents/context-specialist.agent.md`
- `skills/<skill-name>/SKILL.md` for each skill in scope
- Prior audit pointer: discover via `find .context/tasks -maxdepth 2 -name audit-report.md | sort | tail -n 1` (returns the most recent prior audit report, or empty if none survive). If empty, treat this run as the baseline — skip the prior-audit reading step and report all findings as net-new in your delta section. When a prior audit is found, read specifically its **Context-Specialist & Init** domain sections before any investigation.
- `.context/retrospectives.md` (recent entries mentioning init, upgrade, or context setup)
- `CHANGELOG.md` (what changed in these files since prior audit)

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

Per MKT-0046 user directive: a "no issues found" result is unacceptable. Even if no defects are found, produce at least **3 improvement opportunities** — positive-design suggestions, not defect patches. Examples: init-path unification, tree-position detection simplification, branch/root parity gaps, hardcoded string extraction, `upgrade-repo` vs `mode: upgrade` dual-path resolution.

## Output Shape

Produce a single file at `<task-folder>/research/03-context-specialist-init.md` with the following sections in order:

- `# Context-Specialist & Init Audit — Raw Findings`
- `## Summary` — one paragraph framing what you found and why
- `## Defect Findings` → `### Critical`, `### Moderate`, `### Minor` (tier by risk; empty tiers may be omitted with a "None observed" note)
- `## Improvement Opportunities` — minimum 3; title each, cite Effort/Impact
- `## Architectural Coherence Observations` — use for structural patterns transcending individual findings (e.g., 4-path init fan-out vs single-entry-point ideal)
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
- Do not audit domains other than context-specialist and init skills — the synthesis pass cross-checks.
- Do not dispatch sub-agents — this is a leaf-node investigation.
- Do not edit any file outside `<task-folder>/research/`.
