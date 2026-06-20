## Task: ICON-0034
## Branch: feature/ICON-0034-agent-polish-sweep
## Objective: Close GitLab work item #19 — a bundled sweep of small consistency, discoverability, and threshold-reconciliation fixes across `agents/*.agent.md`, with one cross-reference into `skills/using-skills/SKILL.md` and policy codification in `skills/agent-evaluation/SKILL.md`. All eight sub-tasks land as one PR per the work item's "sweep PR" framing.
## Folder: .context/tasks/ICON-0034-agent-polish-sweep/

## Decisions

- **Local task ID = ICON-0034**: The audit-report's proposed slate (ICON-0016 through ICON-0025 at `audit-report.md:328-337`) was never used — actual execution jumped to ICON-0026 and continues sequentially. ICON-0034 is the next free slot. GitLab work item #19 is a separate identifier (the GitLab tracker); local task IDs and GitLab work item numbers are independent.
- **Branch model = feature branch**: Per `.context/workflows/branching.md`, ICON uses `main`-only with `feature/ICON-NNNN-...` branches merged to `main`. Sweep PR targets `main`.
- **m-A-NET4 — Standardize on folded block scalar frontmatter (Option A — user clarification 2026-05-21 superseded the initial single-quoted reading)**: Per the user's GitLab comment on issue #19 ("standardize on scalars") and the follow-up clarification on 2026-05-21 ("I had intended for you to standardize on folded scalars, not single-quote scalars"), standardize all 9 agent descriptions on folded block scalars (`description: >`). Manager and context-specialist retain their pre-existing rich multi-paragraph content (~1000+ chars each); the 7 other agents (architect, coder, planner, product-manager, researcher, reviewer, tester) convert from single-quoted single-line form to folded form with single-sentence content — **do NOT enrich** the sub-agents (they are invoked by manager/product-manager, never user-invoked directly, so a rich description has no surface to render against). Codify the rule in `skills/agent-evaluation/SKILL.md` (the user clarified: `writing-skills` is for skills, `agent-evaluation` is for agents). The folded form aligns with `writing-skills`'s existing skill-frontmatter convention — unified convention across agents and skills.
- **m-A-NET4 — Quoting form**: Folded block scalars (`description: >`) tolerate all problematic YAML characters without escaping — em-dashes, backticks, parentheses, asterisks, colons, and apostrophes — because the YAML spec collapses internal newlines to spaces and content under a `>` indicator is read literally with no mapping-shape ambiguity. ICON-0031 retrospective surfaced a Critical when unquoted `description: Set managerDefault: true in ~/...` broke YAML mapping shape; the folded form was the recommended remediation in that retro. (Earlier in this task the standardization was attempted with single-quoted form before the user's 2026-05-21 clarification — that direction is superseded.)
- **m-A-NET4 — `writing-skills` boundary**: Skill frontmatter conventions remain owned by `writing-skills`; agent frontmatter conventions go in `agent-evaluation`. They are parallel rules in two siblings, not one rule with two homes.
- **m-A-2 — Delegate the numeric threshold to `systematic-debugging`**: Rewrite `manager.agent.md:182` and the AR row at `:247` to route through the skill rather than restating "3+". The skill description (`SKILL.md:4`) says "2+ fix attempts"; manager defers instead of duplicating.
- **m7 — Restructure as sub-bullet, not parallel statement**: Per the work item, the `.context/`-sibling refinement at `context-specialist.agent.md:138-139` becomes a sub-bullet of the generic Scope Discipline line in the common-constraints block, framed as "Specifically for context-specialist:".
- **Verification gate per ICON-0031**: After any frontmatter edit, parse-test the YAML with `python3 -c "import yaml; yaml.safe_load(open(f).read().split('---')[1])"` for each touched agent file before declaring done.
- **One sweep PR, not eight**: The work item explicitly endorses bundling. All eight sub-tasks are independent in subject but share the editor-open-on-each-agent cost; splitting would multiply ceremony for no review-quality benefit.
- **YAML parse-test was run via `node-js-yaml`**, not `pyyaml`: `python3 -c "import yaml"` failed in this WSL environment (`pyyaml` not installed; `pip` not available; `python3 -m pip install --break-system-packages` blocked). System Debian package `node-js-yaml` (4.1.0) at `/usr/share/nodejs/js-yaml` was the working alternative — invoked via `NODE_PATH=/usr/share/nodejs node -e "..."`. Both @coder verification Gate 1 and reviewer Pass 3 used this path. The ICON-0031 frontmatter-parse-test gate is satisfied; the choice of parser library does not affect the ICON-0031 lesson.
- **m-A-NET4 — Direction inverted post-MR-open**: First implementation (commit a5b300f) standardized on single-quoted scalars based on a misreading of "standardize on scalars" in the user's GitLab comment. User clarified intent on 2026-05-21 — they meant folded block scalars (`description: >`), matching the audit's original Option A and aligning with `writing-skills`'s skill-frontmatter convention. Fix commit b3efd1d converted all 9 agents to folded form; manager and context-specialist initially kept their rich content.
- **m-A-NET4 — context-specialist trimmed**: User further clarified on 2026-05-21 that context-specialist should also be minimized (`user-invocable: false`; always explicitly invoked by initialize-* skills or by manager during retrospectives — no user-facing render surface for the description). Third commit minimized `agents/context-specialist.agent.md` to a 230-char single-sentence folded description. **Only `manager.agent.md` retains rich multi-paragraph folded content** — it is the sole agent with a substantial user-facing dispatcher render surface in this plugin. The Frontmatter Conventions rule in `skills/agent-evaluation/SKILL.md` was tightened to scope "rich description allowed" by `user-invocable: true/false` rather than by named agents, with an AR row blocking the "context-specialist is complex enough to deserve a rich description" rationalization.
- **Single-pass review sufficient**: Per ICON-0027 ("two-reviewer-passes pattern now has three instances ... codifying now risks framing too narrowly") and ICON-0029 ("Skill-internal consistency review by a fresh @reviewer dispatch ... reliably catches downstream surface drift even on small changes"), this sweep's mechanical small-diff shape (6 files, +41/−41 net) cleared Pass 1 with zero findings and does not warrant a second pass. The reviewer Pass 1 brief explicitly invoked the ICON-0027 inverse-phrasing risk axis and the threshold-delegation surface; no contradictions surfaced.

## Key Files

**Modified — final state after both implementation commits (a5b300f + fix commit)**:
- `agents/manager.agent.md` — m-A-NET4 (frontmatter restored to original rich folded scalar at `:2`, 1062-char description) + O-D4 (new Step 5 "Open the MR" with `mr-discipline` cue) + m-A-2 (threshold delegation in prose and AR row) + m-A-6 (Default-tier wording clarified, "during Session Start step 7")
- `agents/context-specialist.agent.md` — m-A-NET4 (frontmatter is folded scalar with 230-char single-sentence content; intermediate b3efd1d state had restored rich content but was subsequently minimized) + m7 (scope-discipline refinement now framed as sub-bullet under generic rule, outside the common-constraints byte-equality block)
- `agents/architect.agent.md` — m-A-NET4 (`'...'` → `description: >` folded, single-sentence content unchanged)
- `agents/coder.agent.md` — m-A-NET4 (`'...'` → `description: >`)
- `agents/planner.agent.md` — m-A-NET4 (`'...'` → `description: >`) + m-A-1 (added opening ` ```markdown ` fence for the second output block; fence count now even at 4)
- `agents/product-manager.agent.md` — m-A-NET4 (`'...'` → `description: >`) + O-D3 (`## Session Start` moved before `## When to Invoke`; common-constraints acknowledgement added as Session Start step 2, mirroring `manager.agent.md:33`)
- `agents/researcher.agent.md` — m-A-NET4 (`'...'` → `description: >`)
- `agents/reviewer.agent.md` — m-A-NET4 (`'...'` → `description: >`)
- `agents/tester.agent.md` — m-A-NET4 (`'...'` → `description: >`)
- `skills/agent-evaluation/SKILL.md` — m-A-NET4 codification (`## Frontmatter Conventions` section establishing folded block scalar (`description: >`) as canonical for agent descriptions; user-invocable agents MAY have rich multi-paragraph descriptions, sub-agents stay one-sentence; anti-rationalization table blocks the single-quoted-is-simpler, sub-agent-enrichment-for-symmetry, and "colon-needs-quoting" rationalizations)
- `skills/using-skills/SKILL.md` — O-D1 / m-CC-2 (task-plan chain example line added directly after the existing debugging chain example)

**Task artifacts (created/maintained by manager directly)**:
- `.context/tasks/ICON-0034-agent-polish-sweep/plan.md` — this file
- `.context/retrospectives.md` — retro entry inserted by @context-specialist (committed in a5b300f)
- `.context/standards/skill-decomposition/process-sweeps.md` — two patterns promoted (Echo Decisional Inputs Into Dispatch; Reviewer Pass Cadence) — committed in a5b300f
- `.context/standards/skill-decomposition.md` — topic index updated — committed in a5b300f
- `CHANGELOG.md` — `[Unreleased]` entries describing the agent polish sweep (updated in fix commit to reflect folded-scalar direction)

## Progress

- [x] Session Start — read iconrc, claude.md, branching.md, retrospectives, agent frontmatter survey, agent-evaluation skill content
- [x] Create feature branch + task folder + plan.md
- [x] Dispatch @coder for the implementation sweep — all 8 sub-tasks closed in a single Sonnet delegation; @coder reported all 10 verification gates pass and staged via `git add` (no commit)
- [x] Dispatch @reviewer Pass 1 (Opus default) — verdict **GOOD**; zero findings at Critical/Moderate/Minor. js-yaml parse + common-constraints md5sum + 10 acceptance gates all confirmed. Per ICON-0027/0029 single-pass-sufficient rule for small mechanical sweeps, Pass 2 not required.
- [x] Reconcile plan.md against final state (phase-completion §0) — first reconcile (single-quoted direction)
- [x] Run task-retrospective (manager Stage 1 → @context-specialist Stage 2) — Echo Decisional Inputs + Reviewer Pass Cadence promoted to process-sweeps.md; ICON-0007 pruned per rolling-log cap
- [x] Add `[Unreleased]` CHANGELOG entries via `changelog-entry` skill (subsequently re-edited in fix commit to reflect folded direction)
- [x] Commit all artifacts on the feature branch (commit a5b300f) — pre-commit hook passed clean
- [x] Push branch and open MR !18 to `main` (https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/merge_requests/18)
- [x] **m-A-NET4 direction inversion (b3efd1d)**: User clarified on 2026-05-21 they intended folded scalars, not single-quoted. @coder dispatch redo flipped all 9 agent frontmatters from `'...'` to `description: >`, restored manager + context-specialist rich content (1062 + 809 chars), rewrote agent-evaluation Frontmatter Conventions section, updated CHANGELOG bullets.
- [x] Reconcile plan.md, commit b3efd1d, push, update MR !18 description.
- [x] **context-specialist minimized (third commit)**: User further clarified context-specialist should also be minimized (`user-invocable: false`; always explicitly invoked). @coder dispatch trimmed context-specialist frontmatter to 230-char single-sentence folded form; tightened agent-evaluation rule to scope rich descriptions by `user-invocable: true/false` instead of named agents; updated CHANGELOG bullets. All 7 verification gates pass.
- [x] Reconcile plan.md again to reflect the further narrowing ← THIS STEP
- [ ] Commit and push the third edit; update MR description ← IN PROGRESS

## Open Questions / Blockers

- None at task start. User clarified m-A-NET4 in the GitLab comment; remaining decisions are mechanical.

## Constraints

- ICON is pure-content (no compile/test/package manager) — see ADR-005. Verification means YAML parse + `python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))"` (not touched here) + grep-based acceptance checks.
- `.claude-plugin/plugin.json` version SSOT (ADR-003) is **not touched** by this task — agent-definition polish is a content-only change; a version bump is handled by the next `/release-plugin` run, not by individual tasks.
- ICON-0031 frontmatter-quoting lesson: collapsing folded scalars to one-liners must use single-quoted form when the description contains `:`, em-dash, backticks, or other characters that would change unquoted YAML mapping shape. Parse-test after each frontmatter edit.
- ICON-0014 three-surface sweep rule (`.context/workflows/` → `context_template/` → `skills/<phase>/SKILL.md`) **does not apply** here — this task touches `agents/*.agent.md` and `skills/{using-skills,agent-evaluation}/SKILL.md`, none of which have a three-surface distribution mirror.
- ICON-0027 cross-surface inverse-phrasing sweep: when the m-A-2 edit changes manager's threshold wording, grep `systematic-debugging/SKILL.md` for the corresponding numeric threshold and confirm the delegation phrasing matches what the skill actually says.
- Scope strictly the work item's eight sub-tasks. Do not touch reviewer.agent.md content (m-A-NET3 in the audit is out of scope here; only the reviewer frontmatter form is verified, not the body).
