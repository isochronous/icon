# Infrastructure Audit — Dispatch Brief

## Scope

Investigate all infrastructure files: the plugin manifest (`.claude-plugin/plugin.json`; additionally `.github/plugin/plugin.json` and repo-root `plugin.json` if present), `CHANGELOG.md`, `README.md`, the GitHub Actions workflow `.github/workflows/security.yml` (if present), `.githooks/`, `hooks/`, per-skill `scripts/` directories, `.claude/skills/release-plugin/SKILL.md`. The bundled MCP server registry was removed, so there is no MCP config to audit. If a sibling `-beta` / `-dev` / `-staging` repo exists, treat it as a read-only distribution snapshot — note drift from the source but do not audit it as canonical.

Focus on: version consistency across manifest variants, schema key coverage, release-script correctness, documentation accuracy, and health-check/smoke-test gaps. CI/CD discipline applies only when CI config is present.

## Pre-Check: Infrastructure Discovery

Before consulting the file list in `## Inputs`, run a discovery pass from the repo root to catch infrastructure that may exist but is not enumerated:

- All READMEs at plugin level: `find . -maxdepth 2 -name 'README.md' -type f -not -path './.git/*'`
- All manifest variants: `find . -maxdepth 4 -name 'plugin.json' -type f -not -path './.context/*' -not -path './.git/*'`
- All hook scripts: `find . -maxdepth 3 -path '*/hooks/*' -type f -not -path './.context/*' -not -path './.git/*'`
- If a plugin family distributes both stable and `-beta` / `-dev` / `-staging` sibling REPOS, the audit must be run against each repo separately and findings reconciled in a cross-repo audit report. (Sibling variants are sibling repos in the standalone-repo layout, not sibling directories.)

For each result not already in `## Inputs`, you must either (a) audit it against the same rules as enumerated files or (b) document why it is intentionally out-of-scope in the research file's `## Infrastructure-Specific Structural Observations` section.

## Inputs (read-only)

- `.claude-plugin/plugin.json`
- `.github/plugin/plugin.json` (if present)
- `plugin.json` (repo root, if present)
- `CHANGELOG.md`
- `README.md`
- `.github/workflows/security.yml` (the GitHub Actions workflow, if present)
- `.githooks/` — git-hook directory (e.g., post-commit prune hook; honored via `git config core.hooksPath`)
- `hooks/` — Claude Code session hooks (different mechanism: invoked by Claude Code's harness on session events, not by git)
- `skills/*/scripts/` — per-skill helper scripts
- `.claude/skills/release-plugin/scripts/` — release-flow scripts
- `.claude/skills/release-plugin/SKILL.md`
- Prior audit pointer: discover via `find .context/tasks -maxdepth 2 -name audit-report.md | sort | tail -n 1` (returns the most recent prior audit report, or empty if none survive). If empty, treat this run as the baseline — skip the prior-audit reading step and report all findings as net-new in your delta section. When a prior audit is found, read specifically its **Infrastructure** domain sections before any investigation.
- `.context/retrospectives.md` (recent entries mentioning releases, manifests, or CI)
- `CHANGELOG.md` (what changed in infrastructure since prior audit)

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

Per MKT-0046 user directive: a "no issues found" result is unacceptable. Even if no defects are found, produce at least **3 improvement opportunities** — positive-design suggestions, not defect patches. Examples: `$schema` key coverage across manifests, manifest-schema validation in CI, release-script dry-run mode, CHANGELOG automation, CI schema validation step.

## Output Shape

Produce a single file at `<task-folder>/research/05-infrastructure.md` with the following sections in order:

- `# Infrastructure Audit — Raw Findings`
- `## Summary` — one paragraph framing what you found and why
- `## Defect Findings` → `### Critical`, `### Moderate`, `### Minor` (tier by risk; empty tiers may be omitted with a "None observed" note)
- `## Improvement Opportunities` — minimum 3; title each, cite Effort/Impact
- `## Infrastructure-Specific Structural Observations` — optional; use for systemic patterns (e.g., all 3 plugin.json variants missing the same keys)
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
- Do not audit domains other than infrastructure — the synthesis pass cross-checks.
- Do not dispatch sub-agents — this is a leaf-node investigation.
- Do not edit any file outside `<task-folder>/research/`.
