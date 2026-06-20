## Task: ICON-0051
## Branch: feature/ICON-0051-decomposition-rfc
## Objective: Author an ORG-004 RFC capturing the ICON decomposition design discussion (audit Brief 07 + Slack thread + conversational refinement) into a single reviewable document. Include the 5-plugin proposal, abandoned alternatives with pros/cons, identified issues, and a proposal for an "ecosystem switchboard" extensibility pattern. Output is a design artifact for team review; no plugin source files change in this task.
## Folder: .context/tasks/ICON-0051-decomposition-rfc/

## Decisions
- **Format: ORG-004 RFC** (via `rfc` skill scaffold path) — proposes architectural change for team review, has team-buy-in requirement. Captures pros/cons natively in Abandoned Ideas section.
- **Location: `.context/tasks/ICON-0051-decomposition-rfc/rfc.md`** — proposal phase. Graduates to an ADR in `.context/decisions/` only if the team accepts a specific decomposition path.
- **Scope: design document only, no implementation** — this task delivers the RFC. Each carve-out (ds-mcp, agentic-toolkit, context-reader, etc.) would be its own follow-up task with its own branch.
- **Switchboard included** — user explicitly asked for the extensibility pattern. Frame it as a proposal within the RFC, not a separate document, since it's tightly coupled to the decomposition.
- **Discussion-history is captured in Background, not a separate "history" section** — keeps RFC schema-compliant. The "How we got here" subsection of Background carries the narrative.

## Key Files
- `.context/tasks/ICON-0051-decomposition-rfc/rfc.md` (new, primary deliverable)
- `.context/tasks/ICON-0051-decomposition-rfc/plan.md` (this file)
- (Optional) `.context/tasks/ICON-0051-decomposition-rfc/dependency-graph.md` — if a separate diagram file helps; otherwise inline in the RFC
- `CHANGELOG.md` — append `[Unreleased]` entry at task close (design-doc addition, not a behavior change)

## Progress
- [x] Feature branch created
- [x] Task folder + plan created
- [x] Draft RFC.md written (all 7 ORG-004 sections + Addendum; ~330 lines)
- [ ] User review of draft ← IN PROGRESS
- [ ] Apply any revisions
- [ ] CHANGELOG `[Unreleased]` entry appended (only if user wants this RFC checked in; some teams prefer RFCs ungated until accepted)
- [ ] Commit + push branch (merge to main is user's call)

## Open Questions / Blockers
- Should this RFC live permanently in the repo? If accepted: promote to ADR. If rejected or deferred: keep as task artifact (prunable). Default for this draft: keep in task folder, decide on promotion after review.
- Switchboard plugin: is this a real proposal for ICON to build, or just a conceptual sketch to inform downstream decisions? Drafting as "proposal under consideration" — actual implementation would be its own RFC.
- Naming for the carve-outs: `ds-mcp`, `agentic-toolkit`, `context-reader` are working names. The Slack thread surfaced umbrella-branding tension; final names need leadership sign-off and are out of scope for this RFC's technical proposal.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003. (No version bump for this task; design-doc only.)
- Per common-constraints data-exfiltration rule + auto-memory: no GitLab issue auto-filing for the decomposition phases referenced in this RFC unless user explicitly directs.
- Per auto-memory: do not release / tag / Slack-post on this task.
- Per auto-memory: CHANGELOG `[Unreleased]` edit boundary — anchor on `## [Unreleased]\n\n` only.
- This RFC supersedes (but does not replace) `.context/tasks/ICON-0046-icon-audit/research/07-plugin-decomposition.md` — that file remains the audit research artifact; this RFC is the team-review-ready synthesis.
