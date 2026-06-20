## Task: ICON-0080
## Branch: feature/ICON-0080-github-conversion
## Objective: Convert this personal ICON install from a multi-platform (GitLab + Jira/Atlassian, DataScan-flavored) orientation to a GitHub-only orientation for user `isochronous`, then bring `.context/` in line via `/context-maintenance`. Full replace (not dual-platform): MR→PR, "Jira ticket"→"GitHub issue", remove bundled GitLab/Atlassian MCP servers (use `gh` CLI / GitHub directly), and replace DataScan identity with `isochronous`.
## Folder: .context/tasks/ICON-0080-github-conversion/

## Decisions
- Full GitHub-only replace (not "keep neutral fallbacks"): user uses GitHub + GitHub Issues exclusively; multi-platform portability is intentionally dropped for this personal build. (User, round-1 Q1.)
- Remove the two bundled MCP servers (`.mcp.json`: gitlab + atlassian); rely on `gh`/GitHub directly. (User, round-1 Q2.)
- Replace DataScan identity (onedatascan, jeremy.mcleod, DataScan-flavored examples) with GitHub user `isochronous`. (User, round-1 Q3.)
- `sprint-goals` skill: REMOVE (Jira-CSV + hardcoded Confluence URL; no GitHub analogue worth keeping for a personal install). (User, round-2 Q1.)
- `.gitlab-ci.yml`: PORT to `.github/workflows/` (keep gitleaks/semgrep/shellcheck security scans), then delete the GitLab file. (User, round-2 Q2.)
- Skill renames (sensible defaults; user can adjust): `mr-discipline`→`pr-discipline`, `mr-feedback-triage`→`pr-feedback-triage` (rewrite to `gh pr`/`gh api`), `jira-story`→`github-issue` (reframe to GitHub issue body).
- Skill removals: `mcp-tools-first` (premise inverts once MCP servers gone), `setup-mcp-servers` (sets up the removed servers), `sprint-goals`.
- Skill light reframe (keep): `post-meeting` (de-flavor examples only), `rfc` (replace hardcoded onedatascan Confluence URLs/example).
- `.context/tasks/` (90+ historical plans) and `CHANGELOG.md` history are NOT rewritten — historical record; only `CHANGELOG [Unreleased]` gets a new entry. Retros left as history; `/context-maintenance` re-promotes, does not rewrite history.
- Git: working copy had no `.git`; user authorized `git@github.com:isochronous/icon.git`. Remote was an empty starter (`Initial commit` w/ LICENSE+.gitignore). Re-rooted local baseline onto it; LICENSE preserved. Baseline import committed with the `.githooks` gate bypassed for that ONE import commit (pre-existing example token in `setup-mcp-servers`, which is being deleted anyway); gate active for all conversion commits.
- NOT releasing. No version bump to `.claude-plugin/plugin.json`, no tag, no `/release-plugin` — per repo release-guard, releasing requires explicit current-turn instruction.

## Key Files
Grouped by work batch (full per-file inventory in this folder's discovery notes / conversation). Disjoint groups in Phase 2 are parallel-safe (one working tree, coders don't run git).

- **Phase 1 — Infra (manager git ops + @coder content):**
  - DELETE `.mcp.json`
  - `.claude-plugin/plugin.json` — drop `mcpServers` ref; description; `author.name`→isochronous; `repository`→github
  - `.claude-plugin/marketplace.json` — `owner.name`→isochronous
  - `.claude/settings.json` — remove `mcp__gitlab__*` perms
  - `.claude/settings.local.json` — remove gitlab/atlassian enabled servers
  - `.gitlab-ci.yml` → port to `.github/workflows/security.yml`, then delete
  - `hooks/guardrail-pretooluse.mjs`, `.githooks/pre-commit` — gitlab-pat/atlassian-token regexes kept (defense-in-depth); update MR-prose comments only
- **Phase 1 — Skill structural (manager `git mv` + @coder rewrite):**
  - RENAME `skills/mr-discipline`→`skills/pr-discipline`; `skills/mr-feedback-triage`→`skills/pr-feedback-triage`; `skills/jira-story`→`skills/github-issue` (rewrite frontmatter `name:` + content)
  - REMOVE `skills/mcp-tools-first/`, `skills/setup-mcp-servers/`, `skills/sprint-goals/`
  - REFRAME (keep) `skills/post-meeting/` (examples), `skills/rfc/` (URLs/example)
- **Phase 2 — Reference sweeps (parallel @coder, disjoint groups):**
  - `agents/` — product-manager, manager, researcher, reviewer, planner
  - `skills/` (incidental refs) — commit-discipline, code-quality-rules, using-skills, writing-skills, manager-routing-guide, resolve-repo-context, initialize-{monorepo,multimodule,workspace}, icon-init, icon-status, create-iconrc, context-specialist-impl-{root,leaf}(+step-4), task-plan-phase-completion(+agent-vs-skill), upgrade-repo, post-incident-review, plugin-design/*
  - top-level docs — README.md, CHEATSHEET.md, CONTRIBUTING.md, CHANGELOG.md `[Unreleased]`
  - `.claude/` maintainer tooling — claude.md, skills/release-plugin (gitlab→github/marketplace; flag Slack as org-specific), skills/icon-audit briefs/04+05
  - `context_template/` — branching.md, commit-conventions.md, task-workflow-template.md, task-plan/phase-completion.md **+ bump `context_template/context/iconrc.json` `version` (pre-commit invariant)**
- **Phase 3 — `.context/` via `/context-maintenance` (@context-specialist mode=maintenance):**
  - Supersede ADR-011 (datascan-production-instance) and ADR-006 (mcp-credentials, moot); update domains/{mcp-servers,skill-system}, workflows/{branching,commit-conventions,changelog,task-start-conventions,task-plan/phase-completion}, standards/{security,changelog-discipline,skill-decomposition/*}, rules-index.md, overview.md. Leave retrospectives as history.

## Progress
- [x] Session start, skills check, repo context (`repo_type: project`, prefix ICON) — done
- [x] Scope decisions confirmed with user (2 rounds) — done
- [x] Git init + remote + re-root onto origin/main starter; baseline committed; feature branch — done
- [x] Discovery inventory of all references (~75–80 files) — done
- [x] Write plan.md — done
- [ ] Phase 1: infra removal/port + skill renames/removals/reframes ← IN PROGRESS
- [ ] Phase 2: parallel reference sweeps (agents / skills / docs / .claude / context_template)
- [ ] Phase 3: `/context-maintenance` over `.context/`
- [ ] Review Checkpoint (@reviewer over full changed-file set)
- [ ] Task retrospective + CHANGELOG entry
- [ ] Commit all artifacts; push; open PR (SSH now working)

## Open Questions / Blockers
- Skill rename targets (`pr-discipline`, `pr-feedback-triage`, `github-issue`) are my defaults — flag if you'd prefer different names.
- `release-plugin` / `marketplace.json`: the GitLab marketplace consumption model (`latest` tag → datascan-marketplace) doesn't map cleanly to a personal GitHub install. Phase 2 will convert platform URLs/identity; the Slack release-announce webhook is org-specific and will be flagged rather than rewired.

## Constraints
- ICON is pure-content (no compile/test/package manager) — verification is structural: JSON parses, paths resolve, `common-constraints` byte-equal across agents (see ADR-005). Lint item is N/A; satisfied by `.githooks/pre-commit` passing.
- Never edit the embedded `common-constraints` block in agent files directly — edit `shared/common-constraints.md`; the `.githooks/pre-commit` hook re-injects + re-stages.
- Any edit under `context_template/` REQUIRES bumping `context_template/context/iconrc.json` `version` (pre-commit invariant), currently `1.7`.
- `.claude-plugin/plugin.json` `version` is the release SSOT — do NOT bump it; not releasing this turn.
- Skill add/rename/remove must stay in sync across all registries: README + CHEATSHEET tables, plugin.json description, `.context/domains/skill-system.md`, `.claude/skills/icon-audit/briefs/04-utility-skills.md`, CONTRIBUTING checklist.
