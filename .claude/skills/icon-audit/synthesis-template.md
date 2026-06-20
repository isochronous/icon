# <Plugin Name> Audit Report — <TASK-ID>

**Task:** <TASK-ID>
**Date:** <YYYY-MM-DD>
**Plugin version audited:** <version> on <branch>
**Scope:** <N agents, M skills, K manifests, …>
**Method:** 6 parallel research agents per domain → synthesis. Baseline for delta comparisons: <PRIOR-AUDIT-ID> (<date>).
**Raw findings:** `./research/01-agents.md`, `02-process-skills.md`, `03-context-specialist-init.md`, `04-utility-skills.md`, `05-infrastructure.md`, `06-cross-cutting.md`.

---

## Executive Summary

**Overall health: <GOOD | FAIR | POOR>.**

<One paragraph framing the state of the plugin and movement since prior audit.>

<If applicable: theme consolidation — "The remaining issues cluster into three themes:">

### Scorecard

| Rule | Verdict | Movement vs <PRIOR-AUDIT-ID> |
|------|---------|------------------------------|
| RULE 1 — PROMPT vs SKILL SEPARATION | <✅ PASS / ⚠️ WARNING / ❌ FAIL> | <Held / Improved / Regressed / note> |
| RULE 2 — SINGLE SOURCE OF TRUTH | … | … |
| RULE 3 — SUB-AGENT JOB CLARITY | … | … |
| RULE 4 — SKILL RESPONSIBILITY | … | … |
| RULE 5 — ORCHESTRATOR CLARITY | … | … |

(The 5-rule scorecard borrows the framework from `agent-evaluation`. Cross-reference for rule definitions — do not duplicate them here.)

### Top-line counts

- **Defects**: **<X> Critical**, **<Y> Moderate**, **<Z> Minor** (total <T>).
- **Improvement Opportunities**: **<N>** spanning <categories>.
- **<PRIOR-AUDIT-ID> delta**: <A> items fixed; <B> still-present or partial; <C> new drift patterns.

---

## Critical Findings (<X>)

### C1 — <Short title>

- **Location**: `<file>:<line(s)>`
- **Problem**: <prose>
- **Risk**: <prose>
- **Fix**: <prose>

<Repeat for each critical finding.>

---

## Moderate Findings (<Y>)

*Full rationale and file:line references in the research files. This section is a consolidated inventory for triage.*

### <Sub-domain> (<count>)

| # | Finding | Location |
|---|---------|----------|
| M-<code>1 | <one-line finding> | `<file>:<line>` |

<Repeat sub-domain tables.>

---

## Minor Findings (<Z>)

Condensed list. Details in research files.

**<Sub-domain>**: <comma-separated or semicolon-separated condensed summary>.

---

## Improvement Opportunities (<N>)

*Items below are positive-design suggestions. None are defects; each is a judgment call the user can accept, defer, or reject.*

### Category 1 — Token Efficiency / Slim the Always-Loaded Surface (<count>)

**O-T1 · <Title>.**
<Prose.> **Effort: <low/medium/high>. Impact: <low/medium/high>.**

### Category 2 — Discoverability / Onboarding UX (<count>)

**O-D1 · <Title>.**
<Prose.> **Effort: <low/medium/high>. Impact: <low/medium/high>.**

### Category 3 — Consolidation / Structural Simplification (<count>)

**O-S1 · <Title>.**
<Prose.> **Effort: <low/medium/high>. Impact: <low/medium/high>.**

### Category 4 — Missing Skills / Workflow Gaps (<count>)

**O-M1 · <Title>.**
<Prose.> **Effort: <low/medium/high>. Impact: <low/medium/high>.**

### Category 5 — Self-Verification / Automate the Retrospective Wisdom (<count>)

**O-V1 · <Title>.**
<Prose.> **Effort: <low/medium/high>. Impact: <low/medium/high>.**

---

## <PRIOR-AUDIT-ID> Delta (Comparison with <date> baseline)

### Fixed since <PRIOR-AUDIT-ID> (<count>)

<bulleted list of items fixed since the prior audit>

### Still present or partial (<count>)

<bulleted list of items from the prior audit that remain unfixed or partially addressed>

### Net-new drift since <PRIOR-AUDIT-ID> (<count>)

<bulleted list of issues not present in the prior audit>

### Audit-process observation

<Optional paragraph — meta-observations about how the audit itself was run, methodology improvements surfaced, or self-referential notes about the audit skill's own performance.>

---

## Prioritized Fix Tiers

### Tier 1 — Fix immediately (correctness risk)

<Bulleted list of Critical findings and any Moderate findings with immediate correctness risk.>

### Tier 2 — Short-term consolidation (defect cleanup)

<Bulleted list of Moderate findings that represent quality debt but not immediate risk.>

### Tier 3 — Structural refactors (higher effort, higher payoff)

<Bulleted list of Minor findings and structural improvement opportunities worth scheduling.>

### Tier 4 — New capabilities (forward-looking)

<Bulleted list of Missing Skills / Workflow Gaps improvements for future planning.>

---

## Open Questions for the User

1. <Question>

---

## Suggested Follow-up Tasks

- **<NEW-TASK-ID>** — <title>. <One-line scope.>

Each is independent and can be triaged by priority and available bandwidth.

---

## Post-Review Dispositions

*Filled at user-triage, after the user reviews the findings — not at synthesis time. Records the accept/defer/reject decision and follow-up-task linkage for every Moderate-or-higher defect and every Improvement Opportunity, so re-scoped findings surface as tracked items rather than silently lapsing. Prototype: `.context/tasks/ICON-0058-*/audit-report.md § Post-Review Dispositions`. Complementary to — not a replacement for — ADR-010's in-ADR carry-forward registry (which tracks only accepted-watch items across audit cycles).*

| Finding ID | Tier | Recommended task | Disposition (accepted/deferred/rejected) | Reason |
|------------|------|------------------|------------------------------------------|--------|
| <C1 / M-x / O-Tn> | Critical / Moderate / IO | <NEW-TASK-ID or "none"> | accepted / deferred / rejected | <one-line rationale> |
