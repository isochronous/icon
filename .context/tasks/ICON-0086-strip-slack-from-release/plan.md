## Task: ICON-0086
## Branch: feature/ICON-0086-strip-slack-from-release
## Objective: Remove all Slack-announcement machinery from the maintainer-only `release-plugin` skill. This is a personal fork of ICON; there is no point broadcasting releases, and the current Step 10 references the upstream org's "AI-Council" Slack channel/webhook. A release should end at Step 9.
## Folder: .context/tasks/ICON-0086-strip-slack-from-release/

## Decisions
- **Remove entirely** (not "keep but off") — user directive ("yep" to full removal). No configurable Slack path remains.
- Maintainer-only tooling: `.claude/skills/release-plugin/` does NOT ship to consumers (per CLAUDE.md) → **no CHANGELOG `[Unreleased]` entry** (nothing consumer-facing changes).
- Simple/mechanical removal; no design pass. @coder removes; @reviewer verifies nothing dangling.

## Key Files (from grep)
- `.claude/skills/release-plugin/SKILL.md` — remove: Step 10 (`:298-344`, "Post release to Slack"); the Maintainer-setup Slack section (`:28-51`, SLACK_WEBHOOK_URL export + AI-Council canvas + preflight `:51`); the two Slack error-handling rows (`:373-374`); any other `SLACK_WEBHOOK_URL`/preflight Slack checks. Fix any surviving "Step 10" cross-references (renumber/prune).
- `.claude/skills/release-plugin/scripts/format-slack.sh` — DELETE.
- Check for a `format-slack.ps1` sibling / any other reference to `format-slack` or Slack (README skill row, other skills, script-parity gate).

## Progress
- [x] ICON-0085 merged (PR #6); branch off fresh main
- [x] Create branch + plan.md
- [x] @coder (Sonnet) stripped Slack: removed the Maintainer-setup Slack section, Step 10 (Slack post), the 2 error-table rows; deleted `format-slack.sh`; **folded legitimate former Step 11 (marketplace verify) into Step 9** (flow now 1→9). Swept downstream refs: `CLAUDE.md` guard ("Slack noise"/"post announcement"), `CONTRIBUTING.md` setup para, `changelog-discipline.md` rationale clause. Grep: zero SLACK/format-slack/AI-Council in release tooling + cleaned docs.
- [x] @reviewer (Sonnet) → **APPROVED**, no blocking. Release logic 1→9 intact (version bump/changelog rename/commit/tag/force-move `latest`); Step-11 fold clean + coherent; no dangling refs; guard coherent; form rules still stand. 1 minor → line-85 anecdote reworded (coder, Haiku) — zero slack now.
- [x] Reconcile plan (this pass — checkpoint below).
- [ ] Retrospective (brief; medium task) → commit → PR ← IN PROGRESS

## Review Checkpoint
Stamped 2026-07-18. @reviewer (code-quality-rules) covered the full ICON-0086 diff + the line-85 fix. Verdict: **APPROVED — no blocking findings.** Release flow contiguous 1→9 with all release logic intact (only the Slack announcement excised + a pronoun fix from the Step-11 fold); zero dangling `SLACK_WEBHOOK_URL`/`format-slack`/`AI-Council`/`Step 10`/`Step 11` references (unrelated step-numbering in other skills + historical task artifacts correctly left); `format-slack.sh` deletion breaks no script/gate; CLAUDE.md guard still forbids all release actions; changelog form rules stand without the Slack rationale. Gates green (context-graph 48 nodes, check-rules-index exit 0). No `plugin.json`/CHANGELOG change (maintainer-only → no consumer-facing change). Close-gate review item satisfied.

## Final Changed-File Set (ICON-0086, reviewed + green)
**Modified (4):** `.claude/skills/release-plugin/SKILL.md`, `.claude/claude.md`, `CONTRIBUTING.md`, `.context/standards/changelog-discipline.md`. **Deleted (1):** `.claude/skills/release-plugin/scripts/format-slack.sh`. (+ task folder.)
**Untouched (guards):** `.claude-plugin/plugin.json` (no release); release logic Steps 1-9. No CHANGELOG entry (maintainer-only tooling).

## Open Questions / Blockers
- Does deleting `format-slack.sh` affect the pre-commit script-parity or shellcheck gates? (Parity = the byte-identical `append-retrospective-entry` trio only; shellcheck globs `*.sh` — deleting one is fine.) Confirm no gate references the deleted script.
- Any `Step 10` / `format-slack` cross-reference elsewhere (README, other release-plugin scripts, icon-audit)?

## Constraints
- Pure-content (ADR-005). Portability (ADR-004). Terse (terseness-calibration standard) for any rewording.
- `.githooks/pre-commit` gates run on commit (rules-index/context-graph don't touch `.claude/`; but README skill-registration + shellcheck may). Keep green.
- Release guard: no `plugin.json` bump / no release this task.
- Do NOT touch the actual release LOGIC (version bump, tag, latest-move) — only remove the Slack announcement.
