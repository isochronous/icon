---
name: icon-audit
description: >
  Use when auditing the ICON plugin's own agent definitions, skills, infrastructure, and cross-cutting quality concerns — especially after a major refactor, before a release, or when retrospective entries cluster around a recurring failure class. Maintainer-only: this skill audits ICON itself and references ICON-specific architecture, ADRs, and finding IDs; it does not generalize to other plugins.
user-invocable: true
---

# ICON Audit

## Overview

Run a 6-domain parallel audit that dispatches one sub-agent per domain, then synthesizes findings into a tiered report with scorecard, defect inventory, improvement opportunities, delta vs prior audit, and fix-tier recommendations. Even when no defects are found, each domain sub-agent must produce at least 3 forward-looking improvement opportunities.

## When to Use

- Before a major release to establish a health baseline.
- After a large refactor to check for structural drift.
- On a recurring cadence (e.g., after every 10–15 task completions).
- When retrospective entries start clustering around a common failure class.
- When you suspect an agent's scope, responsibility, or skill-routing has drifted.

**When NOT to use:**
- For single-agent or single-skill spot checks — use `agent-evaluation` directly.
- For context-document health checks only — use `context-maintenance`.

---

## icon-audit: Phase 1: Discovery

Before dispatching any sub-agents, establish the baseline.

```bash
# 1.1 — find the most recent prior plugin audit, if any
# (plain `sort` — not `sort -V` — for macOS BSD compatibility; correct because
#  ICON-NNNN task IDs are zero-padded to ≥3 digits, so lexicographic sort
#  matches numeric order for the task folder prefix.)
PRIOR_AUDIT=$(find .context/tasks -maxdepth 2 -name audit-report.md | sort | tail -n 1)
if [ -n "$PRIOR_AUDIT" ]; then
  echo "Baseline: $PRIOR_AUDIT"
else
  echo "No prior audit found — this is a baseline run. All findings will be reported as net-new."
fi

# 1.2 — check retrospectives log size; read recent entries for patterns
wc -l .context/retrospectives.md

# 1.3 — check plugin CHANGELOG size; read entries since prior audit
wc -l CHANGELOG.md

# 1.4 — confirm filesystem scale
ls agents/ | wc -l       # agent count
ls skills/ | wc -l       # skill count
find . -maxdepth 3 -name 'plugin.json' -type f -not -path './.context/*' -not -path './.git/*' | wc -l  # manifest count
```

**Phase 1 output** — record in `plan.md` Decisions before dispatching Phase 2:
- Prior audit ID and date (e.g., "baseline: MKT-0046, 2026-04-21").
- Count of retrospective entries since baseline.
- Count of CHANGELOG entries since baseline.
- Current counts: agents, skills, manifests.
- 1–2 line "known-churning areas" note distilled from retros and CHANGELOG.

Every domain brief references this preamble — it ensures all six sub-agents use the same agreed baseline.

**If no prior audit exists**, record "no prior audit — this is baseline run" and skip the Delta section in synthesis. Treat all findings as net-new.

---

## icon-audit: Phase 2: Parallel Dispatch

Before dispatching, set up the task folder using `task-plan`:
- Create `.context/tasks/<TASK-ID>-icon-audit/plan.md` (seed it with the Phase 1 baseline preamble).
- Create `.context/tasks/<TASK-ID>-icon-audit/research/` (empty; sub-agents write here).

Dispatch all six domain sub-agents in parallel. Each receives its brief from `./briefs/` and writes its output to `<task-folder>/research/<NN>-<domain>.md`.

| # | Brief | Domain scope |
|---|-------|--------------|
| 01 | `./briefs/01-agents.md` | Agent definitions — frontmatter, sections, role overlap |
| 02 | `./briefs/02-process-skills.md` | Orchestration and discipline skills |
| 03 | `./briefs/03-context-specialist-init.md` | Context-specialist agent + init skill tree |
| 04 | `./briefs/04-utility-skills.md` | Standalone utility skills |
| 05 | `./briefs/05-infrastructure.md` | Manifests, scripts, CI, documentation |
| 06 | `./briefs/06-cross-cutting.md` | Token economics, discoverability, onboarding, retrospective patterns |

**Dispatch rules:**
- Each sub-agent reads its brief in full before investigating.
- Each sub-agent reads the prior audit's findings for its domain before writing anything — to distinguish fixed, still-present, and net-new items.
- Sub-agent 06 (cross-cutting) consumes outputs from 01–05; dispatch it after the others complete.
- No sub-agent edits plugin source files. All output goes to `<task-folder>/research/`.

---

## icon-audit: Phase 3: Synthesis

After all six research files are produced, synthesize into `<task-folder>/audit-report.md` using `./synthesis-template.md` as the structural guide.

Synthesis steps:
1. Read all six research files in full.
2. Deduplicate findings that appear in multiple domains. Assign ownership to the most specific domain; note cross-domain overlap in the synthesis narrative.
3. Fill the Executive Summary scorecard using the 5-rule framework from `agent-evaluation` (borrowed lens; do not duplicate the rule definitions — cross-reference).
4. Tier all defects: Critical (correctness risk), Moderate (quality risk), Minor (style/clarity).
5. Collect all Improvement Opportunities; organize into the 5 standard categories (see `synthesis-template.md`).
6. Write the Delta section (fixed / still-present / net-new vs prior audit).
7. Write Fix Tiers, Open Questions, and Suggested Follow-up Tasks.
8. Post a summary in chat: top-line counts, delta, top 3 Tier-1 recommendations, offer to file follow-up tasks as issues (subject to user confirmation).

---

## Self-Application

This skill operates on the repo root. The plugin's manifest is at `.claude-plugin/plugin.json`. In this standalone repo there is only one plugin, so no auto-detection is required. (Earlier marketplace-monorepo invocations supported per-plugin-directory auto-detection with a user prompt on ambiguity — that path is retired.)

**What the user receives when the audit completes:**

1. A task folder `.context/tasks/<TASK-ID>-icon-audit/` containing:
   - `plan.md` (Phase 1 baseline preamble + dispatch record)
   - `research/01-agents.md` through `research/06-cross-cutting.md`
   - `audit-report.md` matching `synthesis-template.md` structure
2. A chat summary with:
   - Top-line counts (Critical / Moderate / Minor / Improvements)
   - Delta vs prior audit (fixed / still-present / net-new counts)
   - Top 3 Tier-1 recommendations
   - Offer to file Suggested Follow-up Tasks as GitLab issues (requires user confirmation per common-constraints data-exfiltration rule)

**Overriding the domain list** — for a non-ICON plugin whose domains don't map cleanly to the 6 defaults:
1. Copy `./briefs/` to `<task-folder>/briefs-custom/`.
2. Add, remove, or rename briefs as needed. Keep the shared skeleton headers intact (Scope / Inputs / Prior-Audit Pointer / Forward-Looking Improvements Mandate / Output Shape / Non-Goals). The `## Scope` section is the per-domain-variable slot — every brief names its own files and investigation axes here; the remaining five headers carry invariant preamble.
3. Update `synthesis-template.md`'s domain-specific sub-section tables to match.
4. In Phase 2 dispatch, point the brief enumeration at the custom path.

---

## Cross-References

- **`agent-evaluation`**: The synthesis scorecard borrows the 5-rule framework from `agent-evaluation`. That skill is independent and user-invocable on its own for single-agent design reviews. Do not replace it — reference it.
- **`context-maintenance`**: Run after the audit to apply any context-document drift the audit surfaces.
- **`task-plan`**: Seed the task plan in Phase 1 before dispatching Phase 2.
- **`writing-skills`**: Quality checklist for any skills found needing authoring as part of follow-up tasks.

---

## Quality Checklist

Before reporting the audit complete, verify against the Skill Creation Checklist in `writing-skills`. Additionally:

- [ ] Every finding in every research file cites `<file>:<line-range>` — no conclusions without locations.
- [ ] Synthesis scorecard rule names match the 5-rule framework in `agent-evaluation` verbatim.
- [ ] Each domain produced at least 3 improvement opportunities (forward-looking mandate).
- [ ] Delta section has three sub-sections: fixed / still-present or partial / net-new.
- [ ] Suggested follow-up tasks are filed as GitLab issues (or explicitly deferred with user confirmation).
- [ ] `## Post-Review Dispositions` table filled at user-triage — every Moderate-or-higher finding and every Improvement Opportunity has a disposition (accepted/deferred/rejected) with a reason and, where accepted, a linked follow-up task ID.
- [ ] Retrospective entry appended to `.context/retrospectives.md` via `@context-specialist` (`mode: maintenance`) running the `append-retrospective-entry` script.
