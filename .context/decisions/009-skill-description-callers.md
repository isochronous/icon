# ADR-009: Skill `description` frontmatter does not enumerate callers

**Date**: 2026-05-22
**Status**: Accepted

## Context

Common Check Pattern 3 ("Caller-listing in description") has shipped in all five `skills/plugin-audit/briefs/*.md` files since the briefs were first written. The pattern instructs reviewers to flag any skill whose frontmatter `description` does not name every agent or skill that invokes it; missing callers were claimed to "reduce discoverability and obscure ownership." The pattern has been applied across multiple audit cycles (MKT-numbered, ICON-0003, ICON-0015) and has produced steady Minor-tier findings in each cycle — most of them carry-forwards from the prior cycle, because the underlying rule produces a maintenance burden the team has not opted into.

The maintainer's position (issue #20, 2026-05-22 comment) is direct: "what is the purpose of listing callers? It just takes up context for no value." The position is structurally sound for three reasons:

1. **Caller lists are read-rarely / write-often.** A skill's `description` is loaded by every agent that has the skill in its searchable catalog — that loading happens hundreds of times per release cycle. The caller list is read only when a maintainer is editing the skill. The token cost is paid every load; the discoverability benefit is realized once per edit cycle.
2. **Caller lists drift.** When a new agent starts using a skill, the skill's `description` has no automated reminder to add the new caller. Drift accumulates silently and the lists become stale, at which point they actively mislead — a worse outcome than no list at all.
3. **Discoverability is structurally elsewhere.** Skill discoverability is provided by the skill catalog (loaded by `using-skills` and by per-tool harness skill-search mechanisms), not by reading 50+ `description` fields looking for one's own agent name. Ownership, when it matters, is recorded in `.context/decisions/` and in retrospectives, not in skill frontmatter.

## Decision

Skill `description` frontmatter fields are **not required** to enumerate the agents or skills that invoke them.

Reviewers and audit briefs must not tier a missing caller list as a defect of any severity. Concretely:

- Common Check Pattern 3 ("Caller-listing in description") is removed from all five `plugin-audit/briefs/*.md` files in the same commit as this ADR is accepted.
- Future audit cycles that surface "skill X does not list its callers" findings are out of scope of the audit and should not be raised as Minor or higher.
- The remaining Common Check Patterns (Self-reference violation, Template / standard cross-reference, Operational defensiveness, Frontmatter parser-fragility) continue to apply unchanged.

This decision does not prohibit caller mentions in `description` — a skill author may name a primary caller if the relationship is load-bearing for the skill's purpose (e.g., "Internal @context-specialist skill. Do not invoke without explicit direction." is an ownership signal, not a caller enumeration). The prohibition is specifically on auditing for completeness of the list.

## Consequences

**Positive:**
- Audit cycles stop re-surfacing caller-list findings as carry-forward Minors.
- Skill authors do not need to maintain a hand-tracked list of callers that drifts the moment a new agent invokes the skill.
- The always-loaded surface stays smaller — `description` fields ship into every agent's catalog and skill-discovery context, so trimming optional content is a net token-budget win (see ADR-008 framing for the dispatcher token budget).

**Negative:**
- Discoverability of "who uses this skill?" falls back on grep across the repo (`grep -rn 'skill: <name>'` or `grep -rn 'Load and execute the .<name>. skill'`) rather than a frontmatter field. For maintainers actively touching the skill, this is a one-command lookup; for casual readers, the lookup never happened anyway.
- Authors who previously listed callers as documentation cannot rely on the audit to keep those lists honest. The lists either need to be removed proactively when they go stale, or the author accepts that staleness is now an unaudited surface.

## Alternatives Considered

1. **Soft-deprecate Pattern 3 (keep it in briefs, mark "advisory only").** Rejected — the audit briefs already produce too much "advisory only" output and reviewers cannot reliably distinguish advisory from binding when both appear in the same Common Check Patterns list. A hard delete is cleaner.
2. **Replace Pattern 3 with a "callers documented somewhere" rule.** Rejected — moves the maintenance burden from `description` to a separate doc surface without removing the underlying drift problem. The cost was the maintenance, not the location.
3. **Keep Pattern 3 but exempt specific skill categories.** Rejected — every category exemption adds a tiering decision per finding. The blanket removal aligns with the maintainer's stated rationale ("no value"), and any future exception can be a per-skill author decision rather than an audit-cycle policy.

## Cross-references

- Maintainer rationale: issue #20 comment, 2026-05-22.
- Sister scope-carveout ADR: [ADR-007](007-devnull-ban-scope.md) — both ADRs are scope carve-outs that prevent audit cycles from re-flagging findings the maintainer has consciously declined to act on. ADR-007 carves out a domain (autonomous scripts); ADR-009 carves out a check pattern (caller-listing).
- Affected briefs (all updated in the same commit):
  - `skills/plugin-audit/briefs/01-agents.md`
  - `skills/plugin-audit/briefs/02-process-skills.md`
  - `skills/plugin-audit/briefs/03-context-specialist-init.md`
  - `skills/plugin-audit/briefs/04-utility-skills.md`
  - `skills/plugin-audit/briefs/05-infrastructure.md`
- ADR-consultation step added to each brief above so the next audit cycle reads this ADR before tiering.
