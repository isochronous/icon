## Task: ICON-0030
## Branch: feature/ICON-0030-plugin-audit-prior-audit-discovery
## Objective: Close M-U-A (GitLab #15) — replace the unfilled `<path-to-prior-audit-report.md>` placeholder across all six `plugin-audit` briefs (and SKILL.md Phase 1 Discovery) with a discovery command that the sub-agent runs itself. Handle the pruned-folder / no-prior-audit case gracefully so a `/plugin-audit` invocation in a repo with no surviving audit folder produces a baseline-run report without manager-side workarounds.

## Folder: .context/tasks/ICON-0030-plugin-audit-prior-audit-discovery/

## Decisions
- **Use `find` not `ls` for the discovery command.** Rationale: `find .context/tasks -maxdepth 2 -name audit-report.md` returns empty cleanly when no matches exist (assuming `.context/tasks/` exists, which is guaranteed in any ICON-initialized repo). `ls .context/tasks/*/audit-report.md` errors on no-match. **And no `2>/dev/null`** — the user's constraint explicitly bans reflex stderr suppression; explicit handling of the empty case is the correct pattern.
- **Discovery snippet inline in each brief**, not a shared script. Briefs are dispatched standalone to sub-agents; each one needs the snippet inline (per the "Skills Cannot Share Scripts" rule in `.context/standards/skill-decomposition.md`).
- **Synthesis-template.md is out of scope.** Its `<PRIOR-AUDIT-ID>` / `<date>` / `<version>` placeholders are *runtime variables* that the synthesizing agent fills from the discovered baseline. They are not the "dispatcher injects this" category the issue is closing. The issue's grep acceptance is scoped to `briefs/`, which agrees with this scope decision.
- **No "manager plan.md baseline preamble template" to update.** Issue Step 4 names a hypothetical shipped surface; in this plugin, the manager's `plan.md` baseline preamble is task-specific (not templated). The fix lives entirely in the skill body and briefs.

## Key Files
- `skills/plugin-audit/SKILL.md` Phase 1 Discovery (line 34) — replace `ls .context/tasks/*/audit-report.md` with the robust `find … | sort -V | tail -n 1` shape that selects the most recent prior audit and falls through to "baseline run" when none exists.
- `skills/plugin-audit/briefs/01-agents.md:10` — replace `<path-to-prior-audit-report.md>` placeholder line with a discovery snippet.
- `skills/plugin-audit/briefs/02-process-skills.md:10` — same.
- `skills/plugin-audit/briefs/03-context-specialist-init.md:13` — same.
- `skills/plugin-audit/briefs/04-utility-skills.md:14` — same.
- `skills/plugin-audit/briefs/05-infrastructure.md:35` — same.
- `skills/plugin-audit/briefs/06-cross-cutting.md:16` — same (note: the cross-cutting brief reads "Cross-Cutting and Improvement Opportunities sections" instead of a per-domain section name; preserve that).
- `CHANGELOG.md` — `[Unreleased]` entry under `### Fixed`.

## Discovery snippet (canonical inline form, briefs)

```
- Prior audit pointer: discover via `find .context/tasks -maxdepth 2 -name audit-report.md | sort -V | tail -n 1` (returns the most recent prior audit report, or empty if none survive). If empty, treat this run as the baseline — skip the prior-audit reading step and report all findings as net-new in your delta section.
```

The per-brief domain qualifier ("specifically the Process Skills domain sections" etc.) becomes a sentence after the snippet, e.g.: "When a prior audit is found, read specifically its **Process Skills** domain sections before any investigation."

## SKILL.md Phase 1 Discovery snippet

```bash
# 1.1 — find the most recent prior plugin audit, if any
PRIOR_AUDIT=$(find .context/tasks -maxdepth 2 -name audit-report.md | sort -V | tail -n 1)
if [ -n "$PRIOR_AUDIT" ]; then
  echo "Baseline: $PRIOR_AUDIT"
else
  echo "No prior audit found — this is a baseline run. All findings will be reported as net-new."
fi
```

## Progress
- [x] Branch + task folder created, plan.md drafted, surfaces enumerated by grep
- [x] @coder dispatched (Sonnet) — 7 files edited; acceptance greps all clean
- [x] @reviewer pass (Sonnet) — flagged Moderate: `sort -V` is GNU-only (macOS BSD `sort` does not support `-V`). Fixed in-MR by switching to portable `sort` across all 7 files + adding an explanatory comment in SKILL.md noting the assumption (zero-padded ICON-NNNN IDs make lex sort correct).
- [x] CHANGELOG.md `[Unreleased]` entry under `### Fixed`
- [x] task-retrospective — manager drafted Q1 (portability re-check on copy-pasted snippets) + Q2 (restate likely-violated rules inline in dispatch). @context-specialist staged retro entry (15-cap, ICON-0002 pruned). No `.context/` promotions: both lessons below 3+-task stability gate.
- [ ] Commit, push, open MR closing #15 ← IN PROGRESS

## Open Questions / Blockers
- None.

## Constraints
- **No `2>/dev/null`** anywhere in the new snippets — per shell-self-check rule in common-constraints (`shared/common-constraints.md`). If a command can produce stderr in the no-match case, restructure (use `find` not `ls`, or wrap with an existence check) rather than suppressing.
- ICON is pure-content; verification is grep + reading.
- Acceptance: `grep -rn '<path-to-prior-audit-report' skills/plugin-audit/` returns 0 hits; the 6 brief snippets use the same canonical shape (find-based discovery + explicit empty-case fallthrough); `grep -n '2>/dev/null\|>/dev/null' skills/plugin-audit/` returns 0 hits (no stderr suppression introduced).
