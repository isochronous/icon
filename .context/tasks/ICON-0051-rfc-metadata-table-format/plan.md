## Task: ICON-0051
## Branch: fix/rfc-skill-metadata-table-and-format
## Objective: Update the `rfc` skill to produce a mandatory ORG-004-compliant metadata table as the first body element, replacing the former `## Summary` prose section, and fix the output schema, example, and quality checklist to match.
## Folder: .context/tasks/ICON-0051-rfc-metadata-table-format/

## Decisions
- Replace `## Summary` prose section with metadata table: The existing `## Summary` section did not match the ORG-004 standard enforced in RFC-001. The table format (Summary, Created, Owner, Current Version, Contributors, Target Version, Other Stakeholders, Requirements, Approvers) aligns with the Confluence-based RFC template used in practice.
- Collect metadata fields in scaffold path (Step 2-S): Users scaffolding a new RFC now provide table fields up front; fields not provided default to `TBD` — never invented.
- Extract metadata fields in refactor path (Step 2-R.2): Refactor path extracts existing values from the draft before mapping body sections; preserves existing Created and version values.
- Version semantics documented per RFC-001: New drafts start at `0.1.0`, approved RFCs at `1.0.0`; bump minor for ready-for-comment states.
- Optional intro paragraph slot added after `---`: A brief 1–2 sentence elaboration paragraph may follow the horizontal rule if meaningful; omit otherwise.

## Key Files
- `skills/rfc/SKILL.md`: Updated output schema, scaffold/refactor paths, quality checklist, What to Avoid, Usage Guidelines, and Design Notes
- `skills/rfc/examples/notification-service-email.md`: Rewritten with metadata table, corrected broken RFC-042 link, and proper Markdown format
- `CHANGELOG.md`: `### Changed` entry added under `[Unreleased]` (ICON-0051)
- `.context/tasks/ICON-0051-rfc-metadata-table-format/plan.md`: This file (retroactively created — workflow gap)
- `.context/retrospectives.md`: Retrospective entry appended (retroactively — workflow gap)

## Progress
- [x] Updated `skills/rfc/SKILL.md` — metadata table added to schema, scaffold/refactor paths, quality checklist, and supporting sections
- [x] Updated `skills/rfc/examples/notification-service-email.md` — metadata table, fixed broken link, corrected Markdown
- [x] Added changelog entry to `CHANGELOG.md` under `[Unreleased] ### Changed`
- [x] Created task folder and plan.md (retroactively — missed at task start)
- [x] Appended retrospective entry to `.context/retrospectives.md`

## Open Questions / Blockers
- None

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- Skill changes must not break the existing two-path (scaffold / refactor) structure.
- Metadata fields that are absent must always be marked `TBD` — never invented.
