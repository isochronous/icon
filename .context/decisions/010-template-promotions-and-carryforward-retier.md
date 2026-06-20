# ADR-010: Phase-template promotions and carry-forward re-tier registry

**Date**: 2026-05-23
**Status**: Accepted

## Context

GitLab #24 (ICON-0039) asked for two documentation artifacts in a single pass:

1. **O-S3 — Phase-template promotions.** Walk the per-phase deltas between this repo's `.context/workflows/task-plan/phase-*.md` files and the shipped `context_template/context/workflows/task-plan/phase-*.md` base templates. Promote generalizable content to the base; leave repo-specific content repo-local.

2. **O-X2 — Carry-forward re-tier.** Several Minor-tier audit findings have survived three or more audit cycles without being fixed. Evaluate whether they should be permanently accepted (with written rationale), and record the disposition so future audit cycles stop re-tiering them without cause.

Both sub-tasks share an audience: authors of future audit briefs who need to know which base-template changes are canonical and which recurring Minor findings are intentionally accepted. Bundling them into one ADR avoids split-brained consultation.

## Decision

### Part A — Phase-template promotions

The ICON-0039 exploration pass enumerated 22 candidate PROMOTE / 24 LEAVE / 5 NEUTRAL classifications across the five `phase-*.md` pairs. After architect validation against actual file contents, exactly **one promotion** was confirmed generalizable:

**Promoted:**
- `phase-completion.md` lines 65–66: the 2-line note "Append via the `append-retrospective-entry` script — do not edit `retrospectives.md` by hand" was inserted immediately after the `## Retrospective Template` heading in `context_template/context/workflows/task-plan/phase-completion.md`. The `append-retrospective-entry` script ships in the initializer payload, so every consumer repo has access to it. The instruction is tool-agnostic, workflow-generic, and adds no ICON-specific vocabulary.
- `context_template/context/workflows/task-plan/phase-completion.md` version bumped from `1.3` → `1.4`.

**Intentionally left repo-local (not promoted):**
- CHANGELOG `[Unreleased]` block format — ICON-specific convention, not in the base.
- Context Update Checklist (`phase-completion.md`) — ICON-specific checklist items reference ICON-internal paths (`overview.md`, `.claude/claude.md` update gate); pushing these would embed ICON-specifics in a general-purpose template.
- Ticket-ID format (`ICON-NNNN` Jira-prefix shape in retrospective headers) — every consumer repo has its own project key.
- All content in `phase-investigation.md`, `phase-architecture.md`, `phase-implementation.md`, `phase-testing.md` — every delta examined either (a) was already present in the base template in more generalized form, or (b) contained ICON-specific phrasing (skill decomposition standards refs, ICON-NNNN ticket shape). Pushing those deltas would un-generalize the base. No promotions from these four files.

### Part B — Carry-forward re-tier registry

The following findings have appeared in three or more consecutive audit cycles. Each has been evaluated and re-tiered from Minor to "watch / accepted." If a finding appears here with Status "Accepted (watch)", it must not be re-tiered as Minor without first revisiting the rationale in the Disposition column.

| Finding | Cycle | Status | Disposition | Rationale |
|---------|-------|--------|-------------|-----------|
| **m1** — `prune-context.sh` contains `2>/dev/null` in `context_template/` (7 instances) | 4 | Accepted (watch) | Repo-local — scope-exempted by ADR-007 (autonomous scripts are out of scope of the `2>/dev/null` ban) | The script runs unattended in consumer repos; suppressing stderr on fallback paths is the intended behavior. ADR-007 already documents the carve-out. The audit re-greps the literal pattern without consulting the ADR, which is why the finding keeps re-surfacing. |
| **m9** — DataScan-flavored examples in `skills/post-meeting`, `skills/rfc/examples/notification-service-email.md`, `skills/jira-story`, `skills/sprint-goals` and its examples | 3 | Accepted (watch) | Repo-local — intentional reference material per ICON-0035 disposition | ICON-0035 evaluated this candidate and chose to keep DataScan-flavored example *shapes* (Jira prefix list, sample story titles) while moving prose to placeholders. The retained literal references are reference shapes, not branding. |

The six audit briefs (`.claude/skills/icon-audit/briefs/01-agents.md` through `.claude/skills/icon-audit/briefs/06-cross-cutting.md` — originally `skills/plugin-audit/briefs/`, moved + renamed in ICON-0042) reference ADR-010 in their `## ADR / Decision-Log Pointer` section, so the consultation gate fires on every audit cycle regardless of which brief is dispatched first.

## Consequences

**Positive:**
- The base `phase-completion.md` template now ships the script-invocation note, so new consumer repos get it without manual post-init edits.
- Audit cycles have a single consultation point for m1 and m9. The finding descriptions no longer need to include their own rationale — a pointer to this ADR is sufficient.
- The six audit briefs are in lockstep: all cite ADR-010, so the consultation behavior is predictable regardless of which brief is dispatched first.

**Negative:**
- The "watch / accepted" tier is informal — it relies on brief authors actually reading the ADR before tiering. If the ADR pointer is bypassed, m1 and m9 will re-surface.
- ADR-010 must be updated if either finding is re-evaluated (e.g., if `prune-context.sh` is restructured in a way that removes the `2>/dev/null` instances, the m1 row should be marked closed).

## Alternatives Considered

1. **`shared/<name>.md` (plugin-wide doc).** Rejected — both m1 and m9 have ICON-repo-specific disposition rationale (ADR-007 scope for m1; ICON-0035 example-shape decision for m9). A `shared/` doc would add indirection without benefit.
2. **`.claude/MAINTAINING.md`.** Rejected — the audit cycle is invoked from within the repo, so a repo-local ADR is the right consultation point. `.claude/MAINTAINING.md` is user-facing documentation; the Decision Log is the intended home for policy rationale of this kind.
3. **Two separate ADRs (one for promotions, one for re-tier).** Rejected — GitLab #24 bundles both items ("one documentation artifact covering both"), and the audit briefs benefit from a single consultation point rather than two separate ADR pointers in the `## ADR / Decision-Log Pointer` section.
