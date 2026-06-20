# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added

- `agents/researcher.agent.md` and `agents/manager.agent.md` — added prompt-injection defenses so agents treat content fetched from external systems (Jira, Confluence, web pages, CI/pipeline output, GitLab MR comments) as untrusted data rather than instructions, preventing a malicious issue or page from steering agents into write-capable tool calls, command execution, or data exfiltration; the mitigation is documented in the new `.context/standards/security.md`. (ICON-0072)
- `hooks/guardrail-pretooluse.mjs` — a harness-enforced `PreToolUse` guardrail for GitHub Copilot CLI and Claude Code that blocks the agent from writing credential-like secrets into files and from piping a remote fetch into a shell, regardless of prose instructions, and writes a local tool-use audit log; controls and tuning are documented in `.context/standards/security.md`. (ICON-0073)
- Documented cryptographic commit signing (GPG/SSH) as verifiable attribution complementing the forgeable `Co-authored-by` trailer, and the protected-branch + human-merge setup prerequisite on `main`, across `branching.md`, `commit-conventions.md`, `CONTRIBUTING.md`, and the consumer template scaffolds. (ICON-0074)
- `.gitlab-ci.yml` and `.githooks/pre-commit` — a security CI stage (gitleaks secret-scan, semgrep SAST, shellcheck) plus matching pre-commit secret-scan and shellcheck gates now block credential leaks and shell defects before they reach `main`; the two pinned MCP packages gain a documented quarterly CVE-review cadence in `.context/standards/security.md`. (ICON-0075)
- `security-review` skill and `secure-coding` standard — a runnable checklist and the rules behind it for security-reviewing changes to ICON's own shell/JS hooks and scripts (fail-open enforcement, never-log-secrets, tight credential regexes, ADR-005/006/007) before merge. (ICON-0076)
- `context-specialist-impl-branch` gains a Verify step (parity with impl-leaf/impl-root) that catches missing/placeholder branch-node context before commit. (ICON-0077)
- Documents the `${VAR+x}` presence-test vs `${VAR:-fallback}` convention as Rule 5 in the shell-portability standard; `icon-init` and `icon-status` now cite it instead of re-explaining inline. (ICON-0079)

### Changed

- Retrospective pruning now archives entries to `.context/retrospectives-archive.md` instead of discarding them when the rolling log exceeds its cap. (ICON-0073)
- `icon-init` and `upgrade-repo` now configure a repo-root `.gitattributes` giving retrospective logs a `merge=union` driver, so concurrent retrospective appends across branches merge cleanly instead of conflicting; `upgrade-repo` adds it idempotently to existing repos. (ICON-0073)

### Fixed

- `initialize-multimodule` now dispatches a `context-specialist-impl-root` agent after sub-project initialization, generating root `overview.md` and `projects.md` that map all sub-projects; previously a multi-module repo got no root context map (parity with `initialize-monorepo`). (ICON-0078)

## [1.22.0] - 2026-06-17

### Added

- `.context/rules-index.md` — a generated index that makes `standards/`/`workflows/`/`decisions/` rules discoverable to agents (previously only `domains/` was); created at init, updated on `/upgrade-repo`, and kept in sync automatically. (ICON-0069)

### Changed

- `agents/manager.agent.md` and the `task-plan` completion templates — moved the Task Completion elaboration to the on-demand `phase-completion.md` companion, shrinking the always-loaded manager role. (ICON-0070)

### Fixed

- `skills/icon-init` and `skills/icon-status` — removed references to a non-existent "plugin-lint" check, citing the real shell self-check rule instead. (ICON-0071)
- `skills/initialize-monorepo`, `skills/initialize-multimodule`, and `skills/initialize-workspace` — removed `disable-model-invocation: true` from their frontmatter; because these agent-dispatched initializers are also `user-invocable: false`, the property left them invocable by no one and silently broke `/icon-init` on monorepo, multi-module, and multi-root-workspace repos, which now initialize correctly when dispatched. (ICON-0066)
- `context_template/context/workflows/prune-context.sh` (and the plugin's own copy) — the post-commit cache-prune step now skips dir-keeper dotfiles, so `.context/cache/.gitkeep` is no longer deleted as "stale" on every commit (which removed the directory marker and churned it on each checkout). (ICON-0066)
- `skills/mr-discipline/SKILL.md`, `agents/context-specialist.agent.md`, and `agents/manager.agent.md` — MR titles and the context-specialist's own commits now read the repo's `icon-init`-discovered `.context/workflows/commit-conventions.md` and apply it exactly (the MR title was a hardcoded generic format with no pointer, and the specialist's commit fallback bypassed the file), with the generic format demoted to fallback-when-absent and the manager close-gate gaining a fifth check asserting commits and MR titles match the discovered convention, so agents stop emitting the wrong commit/MR format. (ICON-0067)
- `agents/manager.agent.md` — close-gate now runs `verification-checklist` once (not three times) and treats lint as N/A where there's no lint command, so doc-only closes don't stall. (ICON-0068)
- `skills/rfc/SKILL.md` — fixed two internal contradictions (markup descriptor and bold-label syntax) so the instructions match the skill's own schema and example. (ICON-0068)

## [1.21.0] - 2026-06-12

### Changed

- `agents/manager.agent.md` and the `task-plan` phase templates — @reviewer now runs as a primary pass during implementation (before a task is reported done), recorded as a `## Review Checkpoint` in `plan.md`; the completion close-gate's review item is now conditional and fail-closed, re-running @reviewer only when code changed since that checkpoint (or no checkpoint exists) instead of always running a separate review at close. (ICON-0065)

## [1.20.0] - 2026-06-12

### Added

- `CONTRIBUTING.md` — added a new-skill integration checklist (README row, `using-skills` routing, consuming-agent wiring) and documented the `<!-- ICON-PLACEHOLDER -->` sentinel that the pre-commit hook now blocks, so contributors catch the skill-registration gap before opening an MR. (ICON-0060)
- `skills/characterization-testing/SKILL.md` — new skill for legacy code with no test coverage; agents now lock the code's actual current behavior as characterization tests before making any change, so regressions in untested areas surface immediately rather than silently. (ICON-0049)

### Changed

- `skills/using-skills/SKILL.md` — `characterization-testing` added to the process-skills priority list (before `testing-discipline`) with routing guidance for the legacy-code scenario, added to the rigid-skills list, and a new routing example; `agents/tester.agent.md` Step 2 updated to check for existing coverage and invoke `characterization-testing` instead of jumping straight to `testing-discipline` when no tests exist. (ICON-0049)
- `agents/manager.agent.md` — the `task-retrospective` skill is now Hardcoded (Non-Negotiable) instead of Default (On Unless Explicitly Disabled); it can no longer be skipped for medium or complex tasks, even on explicit user request. (ICON-0056)
- `agents/manager.agent.md` and `skills/verification-checklist/SKILL.md` — the manager now treats a task as closable only after a non-skippable, itemized close-gate passes (@reviewer over the actual changed-file set, project lint with output shown, test coverage per `testing-discipline`, and `verification-checklist`), with a green test suite explicitly satisfying none of them, and the verification checklist now reads an unexplained test-count drop as a sign tests stopped running or were deleted rather than as noise. (ICON-0057)
- `agents/manager.agent.md` — for reopened or "not done right / not using X properly / rework" tasks, the manager now states the architectural principle being asked for and surfaces stylistic decision points as one up-front question before delegating, instead of acting on a symptom-level audit that produces multi-round rework. (ICON-0057)
- `shared/common-constraints.md` — all agents gain a Context Economy rule directing them to reference files by path and the relevant lines rather than re-pasting full contents and to summarize prior outputs instead of echoing them verbatim, cutting per-task token use without suppressing diagnostics. (ICON-0057)

### Fixed

- `context_template/context/workflows/task-plan/phase-completion.md` — the shipped retrospective template now begins each entry with a `### ` heading (was `## `), matching what `append-retrospective-entry.sh` requires; consumer repos following the template previously hit a silent exit-1 that skipped retro insertion and left the rolling-log cap unenforced. (ICON-0059)
- `skills/ecological-impact/SKILL.md` — the `ecological-impact` skill's Option-A monthly-usage path and report header are now platform-neutral with a dedicated Claude Code sub-option, so Claude Code users can run the skill instead of hitting Copilot-only "Remaining Reqs" and billing-quota instructions. (ICON-0059)
- `skills/upgrade-repo/SKILL.md` and `context_template/context/retrospectives.md` — corrected stale retrospective rolling-log cap references from 15 to 10 to match the actual `ENTRY_CAP`, so shipped guidance no longer tells consumers to keep 15 entries when the script keeps 10. (ICON-0060)
- `README.md` — registered the `characterization-testing` and `mcp-tools-first` skills in the Internal Skills table; both shipped but were missing from the README and therefore undiscoverable there. (ICON-0060)
- `hooks/inject-manager-role.mjs` — the SessionStart hook now injects a small (<2KB) bootstrap that directs the model to read and adopt `agents/manager.agent.md`, instead of the full ~31KB role body; under Claude Code 2.1.165 the oversized body was silently persisted to a file with only a ~2KB preview reaching the model, so `managerDefault` sessions ran on a truncated role definition (missing the Session Start steps, delegation rules, and Anti-Rationalization table). (ICON-0061)
- `hooks/hooks.json` — the SessionStart matcher now also fires on `clear`, so the manager role is re-established after a `/clear` instead of being lost for the rest of the session. (ICON-0062)

## [1.19.0] - 2026-06-08

### Added

- `CONTRIBUTING.md` — new top-level doc routing defect reports and feature suggestions to the project's GitLab issues board, and instructing code contributors to author changes using Claude Code or Copilot CLI with ICON installed, following the literal `New task: …` / `task complete` flow and a holistic cross-skill review before opening the MR. (ICON-0050)

### Changed

- `rfc` skill's ORG-004 output schema now requires a mandatory metadata table (Summary, Created, Owner, Current Version, Contributors, Target Version, Other Stakeholders, Requirements, Approvers) as the first RFC body element in place of the `## Summary` prose section; scaffold path collects table fields as inputs, refactor path extracts them from existing drafts, and the quality checklist and example file are updated to match. (ICON-0051)

## [1.18.2] - 2026-05-29

### Fixed

- `README.md` install and update sections now use the correct two-step Claude Code/Copilot CLI pattern — `plugin marketplace add <url>` followed by `plugin install ICON@datascan-marketplace` — instead of attempting to `plugin install` the marketplace URL directly. The previous instructions did not work; consumers following them would have registered nothing and installed nothing. (ICON-0049)

## [1.18.1] - 2026-05-28

### Changed

- `skills/writing-skills/SKILL.md` gained a `## Where Skills Live` section naming the three skill destinations (plugin `<plugin-repo>/skills/`, repo-only `<repo>/.claude/skills/`, user-global `~/.claude/skills/`) with a per-scope decision rule and a worked example contrasting `release-plugin` (maintainer-only, repo-level) against `writing-skills` itself (ships with the plugin); closes a gap where the skill described the internal folder layout but never named where the folder belongs, which let a baseline subagent wrongly route a maintainer-only skill into `skills/`. (ICON-0047)

## [1.18.0] - 2026-05-28

### Added

- `skills/mr-feedback-triage/SKILL.md` — new user-invocable skill (`/mr-feedback-triage`) that fetches open human review threads from a GitLab MR, assesses each for necessity (Blocking / Recommended / Optional), and produces a prioritized resolution plan; the skill assesses and reports only — it never posts replies or resolves threads — registered in `README.md` skills table. (ICON-0046, ICON-0050)

### Changed

- `skills/mr-discipline/SKILL.md` now requires authors to invoke `context-maintenance` before re-requesting review if any addressed feedback changed documented behavior in `.context/`, enforced by two new anti-rationalization rows and a Red Flag entry. (ICON-0046)

### Fixed

- Corrected outdated `keep-last-15` retrospective-cap references in `skills/task-plan-phase-completion/agent-vs-skill-invocation.md` and `skills/context-maintenance/append-retrospective-entry.md` to the current `keep-last-10` value with multi-prune convergence behavior. (ICON-0048)
- Corrected wrong filename in `skills/context-specialist-impl-root/SKILL.md` Step 15 verify checklist (`patterns-template.md` → `patterns.md`). (ICON-0048)
- Removed `audit` from the modes-that-commit list across `agents/context-specialist.agent.md`, `skills/task-plan-phase-completion/agent-vs-skill-invocation.md`, and `skills/manager-routing-guide/SKILL.md` to match the canonical read-only definition of `mode: audit`. (ICON-0048)
- Trimmed `agents/context-specialist.agent.md` description to a single sentence per the `agent-evaluation` sub-agent rule. (ICON-0048)
- Added the missing `(Off Unless Explicitly Requested)` parenthetical to the `agents/manager.agent.md` Discretionary heading to match sibling agents. (ICON-0048)
- Added the missing `user-invocable: false` frontmatter key to `skills/mcp-tools-first/SKILL.md`. (ICON-0048)

## [1.17.2] - 2026-05-26

### Changed

- `skills/mcp-tools-first/SKILL.md` grew a hardening layer (Red Flags list, schema-unknown handling, rationalization-prevention table) that closes the "MCP tool exists but I don't know its parameters — let me check `which glab` first" loophole; the skill now tells agents to load an unknown MCP tool's schema via their harness's tool-schema-discovery mechanism (Claude Code: `ToolSearch select:<name>`; Copilot: `tool_search_tool_regex`) instead of falling back to a familiar CLI. The body was also rephrased to be harness-neutral — tool-name prefixes (`mcp__gitlab__*` vs `gitlab-*`) and schema-discovery syntax now footnote both Claude Code and Copilot rather than pinning Claude Code as the only target. (ICON-0045)

## [1.17.1] - 2026-05-26

### Fixed

- `context_template/context/iconrc.json` `version` bumped from `1.2` to `1.3` to retroactively flag the template content that shipped in 1.17.0 (decisions/-folder layout, phase-template tweaks, META + UPDATE_LOG + commit-conventions updates) — the bump was missed at 1.17.0 release time, so consumers running `/upgrade-repo` against 1.17.0 silently skipped those updates; the next `/upgrade-repo` against this release will pick them up. (ICON-0044)

## [1.17.0] - 2026-05-26

### Added

- ADR-009 (`skill-description-callers`) and ADR-010 (`template-promotions-and-carryforward-retier`) recorded with `skills/plugin-audit/briefs/*.md` updated in lockstep — Common Check Pattern 3 ("Caller-listing in description") removed from the briefs that carried it, and a `## ADR / Decision-Log Pointer` section across all six briefs directs future audit cycles to consult `.context/decisions/` for scope carve-outs (ADR-007 for `2>/dev/null`, ADR-009 for caller-listing) and accepted carry-forward findings (ADR-010) before tiering. (ICON-0035, ICON-0039)
- `.githooks/pre-commit` extended with two new invariant classes — a `.context/<subdir>/<file>.<ext>` dead-reference resolver scoped to `agents/`, `skills/`, `shared/`, `commands/`, and a byte-equality gate across the three `append-retrospective-entry.{sh,ps1}` script copies under `skills/{post-incident-review,task-retrospective,context-maintenance}/scripts/`. (ICON-0032)
- `skills/writing-skills/skill-creation-checklist.md` — new sibling file holding the TDD-adapted skill creation checklist extracted from `writing-skills/SKILL.md`. (ICON-0033)
- `skills/agent-evaluation/SKILL.md` gained a `## Frontmatter Conventions` section codifying folded block scalar (`description: >`) as canonical for agent `description:` frontmatter; only user-invocable agents (`user-invocable: true`) may have rich multi-paragraph descriptions, sub-agents stay one-sentence regardless of structural complexity. (ICON-0034)
- Manager's Task Completion section now includes an `mr-discipline` step between commit and session-clear, and `skills/using-skills/SKILL.md` Skill Priority section gained a task-completion chain example modeling the dominant `task-plan → task-plan-phase-* → task-retrospective` workflow alongside the existing debugging-chain example. (ICON-0034)
- `.claude-plugin/plugin.json` now declares `"$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json"` for IDE validation against the SchemaStore-hosted Claude Code plugin schema. (ICON-0038)
- Folder Split Rule added in `skills/context-document-guidelines/SKILL.md` (16,000-byte threshold ≈ 200 lines × 80 chars + ≥3-peer-`##`-section gate) that `skills/context-maintenance/SKILL.md` § File Size Rule now enforces post-write to convert oversized context docs into `<name>/README.md` + one-file-per-topic peers. (ICON-0040)
- Flat-`decisions.md` → `decisions/` folder migration added to `skills/upgrade-repo/SKILL.md` Phase 1/2 — detects an existing `.context/decisions.md`, splits each `## ADR-NNN:` block into `.context/decisions/<NNN>-<slug>.md`, generates a Decision Log `README.md`, and preserves any non-ADR preamble as `_preserved-content.md` (bash + PowerShell parity, idempotent, malformed-header guard, pure-bash parser portable to mawk). (ICON-0040)
- `skills/mcp-tools-first/SKILL.md` — new skill that fires when an agent is about to access GitLab, Jira, or Confluence and points it at the bundled `mcp__gitlab__*` / `mcp__atlassian__*` tools instead of `curl`, `gh`/`glab`, or web URLs; loaded on-demand via the skill description, not always-loaded. (ICON-0041)
- `skills/plugin-design/SKILL.md` — new user-invocable + auto-invocable skill bundling 11 files (thin router + 2 mode entries + 5 create-phase + 3 audit-phase) for scaffolding Claude Code plugins from scratch (`create` mode: boilerplate → basic info → repo setup → context init → optional marketplace) and auditing existing plugins for structure, consistency, and improvement opportunities (`audit` mode, hard-requires `/icon-init`). Plugin-agnostic; sibling to maintainer-only `icon-audit`. (ICON-0043)
- `agents/manager.agent.md` Session Start Step 5 gains a Task ID Source rule and an Anti-Rationalization row that block deriving Jira ticket IDs from MR numbers, PR numbers, issue numbers, or any other non-Jira numeric reference (coincidental overlap like MR 2942 → WSD-2942 is common and dangerous); `skills/commit-discipline/SKILL.md` adds a matching Common Mistakes row and Red Flags bullet so the rule is enforced at commit time as well. (ICON-0042)

### Changed

- Hardcoded organization-specific examples (DataScan / .NET / WMS / `ngWi` / `wms-api`) across `initialize-monorepo`, `initialize-workspace`, `initialize-multimodule`, and `context-specialist-impl-root` replaced with angle-bracketed placeholders (`<service-a>`, `<your-domain>`, etc.); `find-context-template` retains its `datascan-marketplace` default with inline documentation of the `MARKETPLACE_NAME` env-var override for forks. (ICON-0035)
- The entry-point-detection bash conditional is now defined in exactly one place — `skills/context-specialist-detect-tree-position/SKILL.md` § "Entry-Point Detection Primitive (callable)" — and the three init orchestrators reference that section via prose instructions rather than carrying inline copies; the `upgrade-repo` Phase 3 sample-check spec (spot-check 5 random class names, ≥2 absent triggers `context-maintenance`) is now inline in `skills/upgrade-repo/SKILL.md` and the orchestrator sub-session prompts cross-reference it instead of inlining. (ICON-0035)
- Template-override rule for phase-skill local overrides centralized in `skills/task-plan/SKILL.md` (new `## task-plan: Template-Override Rule` H2); the five `skills/task-plan-phase-{architecture,completion,implementation,investigation,testing}/SKILL.md` files now carry a byte-identical one-line pointer instead of the duplicated 6-line paragraph. (ICON-0033)
- `agents/reviewer.agent.md` Default-tier bullet replaced the verbatim 6-category enumeration with a single-source-of-truth pointer to `code-quality-rules`; the SSOT enumeration earlier in the file is preserved. (ICON-0033)
- `skills/writing-skills/SKILL.md` brought under its self-imposed 500-line cap (549 → 499 lines) by extracting the Skill Creation Checklist to `skill-creation-checklist.md` and consolidating per-skill-type testing guidance into the existing `testing-skills-with-subagents.md` companion. (ICON-0033)
- Agent frontmatter standardized to folded block scalars (`description: >`) across all nine agents — `agents/manager.agent.md` retains its rich multi-paragraph folded content (the only user-invocable agent with a substantial description); `agents/context-specialist.agent.md` and the other seven agents use single-sentence folded form (sub-agents are dispatched programmatically and have no user-facing render surface, so enrichment offers no benefit) — and `agents/product-manager.agent.md` Session Start reordered before When to Invoke with a common-constraints acknowledgement step added for parity with manager. (ICON-0034)
- Manager's repeated-failure escalation no longer hardcodes "3+ attempts" — both the Escalation Handling prose and the Anti-Rationalization row delegate the numeric threshold to `systematic-debugging`, eliminating the skill-vs-agent contradiction; Default-tier researcher-invocation wording also disambiguated to "during Session Start step 7". (ICON-0034)
- Retrospective rolling-log cap reduced from 15 to 10 entries — `ENTRY_CAP=10` in `skills/task-retrospective/scripts/append-retrospective-entry.sh` is the single source of truth, and prose in `skills/task-retrospective/SKILL.md`, `skills/task-plan-phase-completion/SKILL.md`, `.context/META.md`, `context_template/context/META.md`, `context_template/README.md`, and `context_template/UPDATE_LOG.md` now cites `ENTRY_CAP` rather than restating the literal; consumer `retrospectives.md` files auto-prune at 10 instead of 15 after this release. (ICON-0036)
- "Does NOT cover" footer terminology aligned across the five `skills/task-plan-phase-*/SKILL.md` files to use consistent noun forms (`implementation phase`, `testing phase`, `architecture review`), and the four `### Gate N:` headings in `skills/verification-checklist/SKILL.md` prefixed with `verification-checklist:` per the MKT-0083 heading convention. (ICON-0036)
- `.github/copilot-instructions.md` fallback qualifier reframed from in-transition "if not yet migrated" / "for repos that haven't migrated" to durable back-compat note "on repos still on the legacy path" across 15 sites (`skills/{start-worktree,task-plan-phase-investigation,resolve-repo-context,task-plan-phase-completion}/SKILL.md`, `agents/{manager,product-manager,researcher,reviewer,coder,tester}.agent.md`, and `context_template/context/workflows/commit-conventions.md`); single voice across the repo. (ICON-0037)
- `skills/rfc/SKILL.md` Step 3 schema now flows directly into Step 4 — the inline "Section-5 resolution (Operationalization ⊇ Security)" design-history paragraph that previously interrupted the prescriptive flow has been relocated to a new `## Design Notes` section at file end. (ICON-0037)
- `skills/setup-mcp-servers/SKILL.md` Step 3 reframed from "Choose one option. Option A is recommended for most users." to a direct single-option instruction; no Option B was ever documented, so the multi-option hint was misleading. (ICON-0037)
- `context_template/README.md` `context/` directory diagram now lists `iconrc.json` and `.gitignore` — both already ship in `context_template/context/` but were absent from the diagram. (ICON-0038)
- `context_template/context/workflows/task-plan/phase-completion.md` Retrospective Template section now leads with a 2-line note instructing authors to append via the `append-retrospective-entry` script rather than editing `retrospectives.md` by hand; new consumer repos initialized via `/icon-init` get this guidance baked into their phase-completion template (template version bumped 1.3 → 1.4; existing repos retain their copy). (ICON-0039)
- Replaced `context_template/context/decisions.md` (flat file with seeded ADR-001 example) with `context_template/context/decisions/README.md` (intro + ADR Template + empty Decision Log) so new `/icon-init` repos ship the folder layout, and updated 12 sites across `context_template/` and the `context-specialist-impl-{leaf,branch,root}`, `task-plan-phase-{architecture,investigation,completion}`, `design-first`, `initialize-{workspace,monorepo}`, and `merge-phase-templates` skills to reference `decisions/` instead of the flat file. (ICON-0040)

### Removed

- `skills/plugin-audit/` no longer ships to consumers — moved to `.claude/skills/icon-audit/` (maintainer-only, parallel to `release-plugin`) and renamed to reflect its actual ICON-specific scope (briefs reference ICON ADRs, finding IDs like `m-A-1` / `m-U-K`, and the carry-forward registry that do not generalize). Consumer-side `/plugin-audit` invocation is no longer available; the generic plugin-audit-for-any-plugin use case is tracked separately as issue #28. (ICON-0042)
- `"license": "MIT"` field removed from `.claude-plugin/plugin.json` — no `LICENSE` file existed at the repo root and ICON is intentionally a private internal plugin with no open-source license. (ICON-0038)
- `skills/icon-status/SKILL.md` no longer emits a `consider /release-plugin` hint when `CHANGELOG [Unreleased]` has commits since the last tag; the maintainer-only `release-plugin` skill lives at `.claude/skills/release-plugin/` and is not shipped to consumers. (ICON-0038)

### Fixed

- `append-retrospective-entry.{sh,ps1}` (all three byte-equal copies under `skills/{post-incident-review,task-retrospective,context-maintenance}/scripts/`) now converges the retrospectives file to `ENTRY_CAP` after each insertion rather than dropping only one entry per call; a file that grew above cap (e.g., via the prior single-prune logic accumulating headroom, or a future cap reduction) shrinks back to `ENTRY_CAP` on the next entry. The PowerShell copy's stale `EntryCap = 15` (predating ICON-0036's cap reduction) is also corrected to `10` for parity with bash. (ICON-0041)
- `find-context-template` PowerShell snippets normalized to `/` separators throughout for byte-symmetry with the bash variants; `resolve-repo-context` schema example annotates the `instructions` field with the `.github/copilot-instructions.md` fallback rule inline; `initialize-workspace` Step 7 MR template "How to Test" row corrected from `copilot-instructions.md` to `.claude/claude.md` for parity with `initialize-multimodule`. (ICON-0035)
- Refreshed user-facing docs (README, `.claude/claude.md`, and the `/ICON:enable-manager-default` / `/ICON:disable-manager-default` command frontmatter and bodies) to describe the post-ICON-0012 plugin-scoped `SessionStart` hook architecture; opt-out is via `managerDefault` in `~/.claude/icon-user-settings.json` rather than a user-side hook wire-up. (ICON-0031)
- Cleaned up 13 dead `.context/<subdir>/<file>.<ext>` references across `agents/product-manager.agent.md`, `skills/context-specialist-impl-root/SKILL.md`, `skills/task-plan-phase-completion/SKILL.md`, `skills/upgrade-repo/SKILL.md`, `skills/task-retrospective/SKILL.md`, `skills/initialize-monorepo/SKILL.md`, and `skills/initialize-workspace/SKILL.md` — re-pointing `architecture/patterns.md` references to `patterns-template.md` and rewriting legacy or example paths so installed plugin instances no longer cite files that don't ship in `context_template/`. (ICON-0032)
- `agents/planner.agent.md` code-fence count balanced by adding the missing opening fence for the second output-format block, and `agents/context-specialist.agent.md` scope-discipline refinement (`.context/` siblings) restructured as a sub-bullet under the generic Scope Discipline rule rather than a parallel statement. (ICON-0034)
- `skills/ecological-impact/SKILL.md` stale model-name references (Claude Sonnet 4.6 / GPT-4.1) at `:86` and `:221` replaced with the runtime-resolved `<model-in-use>` placeholder so the canonical example output stays current across future model generations. (ICON-0037)
- Copilot-CLI-only tool literals replaced with runtime-agnostic phrasing — `skills/jira-story/SKILL.md`'s `` `create` tool `` and `skills/writing-skills/{skill-creation-checklist,persuasion-principles}.md`'s `TaskCreate` now read as "your available file-write tool" and "your runtime's task-tracking tool" so the instructions work in both Claude Code and Copilot CLI. (ICON-0037)
- `skills/plugin-audit/synthesis-template.md:122` dangling external `MKT-0046 audit-report.md` reference removed — the precedent value was already encoded in the `plugin-audit` overview, and the external link was unresolvable from this repo. (ICON-0037)

## [1.16.0] - 2026-05-21

### Added
- `.githooks/pre-commit` — pure-bash hook that keeps the `<!-- BEGIN: common-constraints -->` … `<!-- END: common-constraints -->` block in every `agents/*.agent.md` byte-equal to `shared/common-constraints.md`, auto-rewriting and re-staging drifted files; aborts on missing source or orphaned marker. Wired via the repo's existing `core.hooksPath = .githooks` configuration. (ICON-0011)
- `hooks/hooks.json` — plugin-scoped SessionStart wiring (matcher `startup|resume`) that invokes the manager-injection wrapper via exec-form `node "${CLAUDE_PLUGIN_ROOT}/hooks/inject-manager-role.mjs"`. Activates automatically on plugin install — no user-side setup required. (ICON-0012)
- `hooks/inject-manager-role.mjs` — single cross-platform Node.js wrapper that replaces the separate bash and pwsh hook scripts. Honors a new user-level opt-out at `~/.claude/icon-user-settings.json` (`managerDefault: false`), fails open on parse errors with a stderr warning, and otherwise emits the same JSON-envelope `additionalContext` payload as the deleted scripts. (ICON-0012)
- `Reconcile plan.md` gate at the start of the completion phase — five sub-checks (Progress, Decisions, Key Files, Open Questions, Constraints) added to `skills/task-plan-phase-completion/SKILL.md` and `context_template/context/workflows/task-plan/phase-completion.md`; `skills/mr-discipline/SKILL.md` pre-open checklist now references the reconcile step so reviewers can spot-check. (ICON-0014)

### Changed
- SessionStart hook for the manager-default role moved from user-scope `~/.claude/settings.json` to plugin-scoped `hooks/hooks.json`. Fixes the `Hook command references ${CLAUDE_PLUGIN_ROOT} but the hook is not associated with a plugin` error at session start. (ICON-0012)
- Manager-default opt-out now lives in `~/.claude/icon-user-settings.json` (key: `managerDefault`). `/ICON:enable-manager-default` and `/ICON:disable-manager-default` now toggle that key; both also auto-clean any legacy `inject-manager-role` entry from `~/.claude/settings.json` on first run, making the migration idempotent. (ICON-0012)
- Canonicalized the retrospective write path — manager drafts Q1 (Avoid) + Q2 (Repeat) + entry text, `@context-specialist` (`mode: maintenance`) inserts via the `append-retrospective-entry` script and stages writes with `git add` only, the manager owns the commit at Task Completion Step 4 — closing the three-surface contradiction across `manager.agent.md`, `task-retrospective/SKILL.md`, and `agent-vs-skill-invocation.md`, and folding in a `mode: maintenance`-specific exception to the `context-specialist` Hardcoded "must commit before report" rule so the new flow is mechanically deliverable. (ICON-0027)

### Fixed
- Removed dead `.context/standards/three-layer-enforcement.md` cross-reference from `manager.agent.md` delegation template; the surrounding instruction ("name all three layers and their exact file locations in the delegation prompt") is self-sufficient. (ICON-0028)
- Added `phase-testing.md` row to the `merge-phase-templates` Step 2 routing table; previously, testing-related custom content from old-format templates was misrouted to `phase-completion.md` by the catch-all row, conflating the testing and completion phases. (ICON-0029)
- Replaced the unfilled `<path-to-prior-audit-report.md>` placeholder across all six `plugin-audit` briefs and SKILL.md Phase 1 Discovery with a `find`-based discovery snippet that picks the most recent prior audit and falls through to a "baseline run" path when no prior audit folder survives (e.g., after task-folder pruning). Uses portable `sort` (not GNU-only `sort -V`) for macOS compatibility. (ICON-0030)

### Removed
- `hooks/inject-manager-role.sh` and `hooks/inject-manager-role.ps1` — replaced by a single cross-platform Node.js wrapper at `hooks/inject-manager-role.mjs`. Eliminates the two-script-parity bugs prior retrospectives warned about. (ICON-0012)

## [1.15.4] - 2026-05-15

### Added
- `task-plan-phase-completion/agent-vs-skill-invocation.md` — new SSOT reference file co-located with the skill documenting when the manager delegates to `@context-specialist` versus invokes a skill directly. (ICON-0006)
- `initialize-multimodule` Steps 4 and 8 — per-sub-repo `chore/initialize-agent-context` branch creation and per-repo MR push, bringing multi-module initialization to parity with `initialize-workspace` and `initialize-monorepo`. (ICON-0008)

### Changed
- `context-specialist` agent — `mode: upgrade` now routes from the agent body directly to `upgrade-repo` instead of the dead-code path in `context-specialist-create`. Mode table, dispatch routing, Hardcoded constraint, and role intro all updated to converge. (ICON-0007)
- `task-plan-phase-completion` Context Update Checklist and Relationship section — `.context/` writes route through `@context-specialist mode: maintenance` instead of direct `context-maintenance` invocation, matching `task-retrospective`. (ICON-0006)
- `initialize-multimodule` dispatch prompts now pass `git_root` and `feature_branch` to sub-sessions, mirroring `initialize-workspace`. (ICON-0008)
- `initialize-multimodule` and `initialize-monorepo` frontmatter aligned to canonical key order; `initialize-multimodule` gained `disable-model-invocation: true` for parity across the three orchestrators. (ICON-0008)
- `plugin-audit` skill migrated to standalone-repo layout — all `plugins/<plugin>/` path references replaced with repo-root paths; stale file enumerations removed; Phase 1 baseline commands now produce non-zero counts without a plan-level translation table. (ICON-0004)
- `manager-routing-guide` `@context-specialist` row enumerates all four modes (`create`, `upgrade`, `maintenance`, `audit`) with their routing targets named inline. (ICON-0007)
- `design-first` Step 3 "hard gate" phrasing replaced with advisory framing matching the skill's own optional-pass framing at the top. (ICON-0005)
- `release-plugin` Step 5 prose rewritten to describe the rename-`[Unreleased]`-to-`[X.Y.Z]` procedure that matches `workflows/changelog.md` and the shipped CHANGELOG shape; Error Conditions row no longer references `sed` directly and points at `bump-versions.sh` with explicit `git diff` verification. (ICON-0010)
- `context_template/context/workflows/prune-context.sh` fixed to handle the parse pipeline failing under `set -euo pipefail` when no match is found, preventing post-commit hook crashes in consumer repos. (ICON-0002)

### Fixed
- `writing-skills` no longer instructs registration in the dropped `using-skills` Common Workflows table — Discoverability and Skill Creation Checklist sections now redirect to the consuming agents' workflow sections. (ICON-0009)

## [1.15.3] - 2026-04-30

### Changed
- `create-iconrc` now requires `local_task_id_prefix` to be distinct from detected Jira ticket prefixes; default placeholder is `LOCAL`; local task IDs require ≥3-digit zero-padded numeric suffix. (MKT-0092)
- Removed default `model` frontmatter pin from all ICON agents so users can pick the model their account has access to. (MKT-0093)

## [1.15.2] - 2026-04-30

### Added
- `upgrade-repo` now updates the `.context/iconrc.json` schema `version` field to match the template, preserving all customized values (`excludes`, `local_task_id_prefix`, etc.).

### Changed
- Repointed stale `task-workflow-template.md` references in `context_template/META.md`, `context_template/overview.md`, `manager.agent.md`, and `task-plan/SKILL.md` to the per-phase templates in `workflows/task-plan/`.
- `inject-manager-role.sh` and `inject-manager-role.ps1` now emit JSON `hookSpecificOutput.additionalContext` so the manager role lands as a system-reminder injection (stronger attention signal than plain stdout) and survives `/clear` via SessionStart re-fire. (MKT-0091)
- `manager.agent.md` Anti-Rationalization table gained a row for the read-cascade-into-edit failure mode: create branch + `plan.md` before the first Edit/Write tool call. (MKT-0091)

### Removed
- `initialize-repo` no longer installs the deprecated `task-workflow-template.md`. (MKT-0090)
- `upgrade-repo` now deletes `task-workflow-template.md` (running `merge-phase-templates` first when customized) instead of overwriting it with the stock template. (MKT-0090)

## [1.15.1] - 2026-04-30

### Fixed
- **`agent-evaluation/SKILL.md`**: removed reference to `.context/standards/anti-rationalization-tables.md`, which is not distributed with the plugin; carveout is now self-contained.

## [1.15.0] - 2026-04-29

### Changed
- **`context-specialist-impl-leaf/SKILL.md`**: added root-level `claude.md` redirect step so Copilot CLI users receive project instructions; corrected documentation that falsely stated Copilot CLI loads from `.claude/` automatically. (MKT-0089)
- **`upgrade-repo/SKILL.md`**: added "Ensure root-level `claude.md` redirect" phase (post-migration check with skip-guard for Case 3) and added redirect presence to the final verification checklist. (MKT-0089)
- **`context_template/context/iconrc.json`**: bumped template schema version to `1.2`. (MKT-0089)

## [1.14.0] - 2026-04-29

### Fixed
- Fixed release-blocking bug where `initialize-monorepo`, `initialize-workspace`, and `initialize-multimodule` orchestrators only checked legacy `.github/copilot-instructions.md` for both classification and post-dispatch verification, causing infinite re-dispatch loops or fresh-init misclassification on any repo following the documented `.claude/claude.md` modern flow. (MKT-0088)
- Fixed release-blocking bug where `create-iconrc` Step 2 hardcoded a marketplace-relative path that raised `FileNotFoundError` in every end-user repo init; the version source now resolves through `$TEMPLATE_DIR` like all sibling init skills. (MKT-0088)
- Corrected `@context-specialist` agent frontmatter to enumerate all four modes (create, upgrade, maintenance, audit) and reference the audit's full Phase 0/1/2 scope, matching the body's parameter table. (MKT-0088)

### Changed
- Reinforced the Anti-Rationalization tables in `plugins/ICON/agents/manager.agent.md` (8 rows restored — delegation skip, source-investigation, plan-in-head, retro skip, self-delegation, plan/git misroute) and `plugins/ICON/agents/product-manager.agent.md` (5 rows added — research skip, GATE RULE bypass, jira-story skip, sub-agent trigger skip, missing technical notes) targeting the workflow shortcuts users reported. (MKT-0081)
- Codified the load-bearing-redundancy principle in `.context/standards/anti-rationalization-tables.md` and added an AR-table carveout under RULE 2 in `plugins/ICON/skills/agent-evaluation/SKILL.md` so future agent-system audits do not re-trim AR rows on single-source-of-truth grounds. (MKT-0081)
- **`context-specialist-impl-leaf/SKILL.md`**: corrected wrong skill-name prefix on step headings; retitled H1 to match sibling impl pattern. (MKT-0083)
- **B1 step-heading prefix sweep across 13 skills**: numbered Step/Phase/Pass/Rule/Question headings now carry a skill-name prefix; em-dash separators standardized on colon. (MKT-0083)
- **Dropped line-coupled cross-references** in `migration-planning`, `plugin-audit`, `post-incident-review` — replaced with skill-name-only references. (MKT-0083)
- **Hardened 8 discipline skills** with rationalization tables, red-flags lists, and violation-symptom descriptions: `systematic-debugging`, `testing-discipline`, `code-quality-rules`, `verification-checklist`, `post-incident-review`, `commit-discipline`, `using-skills`, `dependency-management`. (MKT-0084)
- **`using-skills/SKILL.md`**: adopted upstream superpowers patterns (`<SUBAGENT-STOP>`, `<EXTREMELY-IMPORTANT>`, richer rationalization table, Instruction Priority section); dropped the Common Workflows table. (MKT-0084)
- **Scoped `using-skills` mandate to dispatcher agents** — moved from `shared/common-constraints.md` into the `manager` and `product-manager` agent definitions; sub-agents no longer carry it. (MKT-0084)
- **`mr-discipline` (new skill)**: split `commit-discipline § 5 PR/MR Lifecycle` into a discipline-class skill with G2/G3/G4 hardening. (MKT-0085, MKT-0086)
- **Token-efficiency extractions across 6 skills**: moved heavy worked examples and reference content to sibling files — `rfc` (canonical RFC), `post-meeting` (two examples), `sprint-goals` (three examples), `context-specialist-impl-leaf` (Step 4 per-file content), `context-maintenance` (append-retrospective-entry reference), `ecological-impact` (formulas reference). (MKT-0085)
- **README skills table**: added `mr-discipline` row; trimmed "PR/MR lifecycle" from the `commit-discipline` row. (MKT-0085, MKT-0086)
- **Cross-skill cleanup**: dropped residual line-coupled cross-refs in `plugin-audit`/`synthesis-template`; removed stale `using-skills` mandate from `context-specialist.agent.md` (now relies on `<SUBAGENT-STOP>`); retargeted `initialize-workspace` MR description reference to `mr-discipline`; dropped self-contained-skills violation in `post-incident-review`. (MKT-0085)
- **Standardized on GitLab MR terminology** across the plugin: PR / pull-request mentions in `code-quality-rules`, `commit-discipline`, `initialize-workspace`, `initialize-monorepo`, `context-specialist-impl-{leaf,root}`, and the reviewer agent template now use MR / merge request. (MKT-0086)

## [1.13.3-beta.8] - 2026-04-27

### Changed
- **`plugins/ICON/.mcp.json`**: replaced `tools: ["*"]` on both `gitlab` and `atlassian` server entries with explicit allowlists (70 + 51 tools), excluding all destructive ops, gitlab file-write tools, pipeline create/cancel, draft notes, wiki, and admin/specialized noise. (MKT-0080)
- Codified changelog discipline (one-sentence entries, no fenced code, ticket-ID-at-end) in `.context/standards/changelog-discipline.md`; both release skills now cite the standard. (MKT-0079, back-filled MKT-0088)

## [1.13.3-beta.7] - 2026-04-27

### Changed
- **All `SKILL.md` frontmatter `description:` fields converted to YAML folded block scalar (`description: >`)**: fixes silent parse failures in `jira-story`, `post-meeting`, and `sprint-goals` — plain-scalar descriptions containing `: ` or `[…]` mid-value were dropping these skills from the loadable-skill list with no log line. (MKT-0078)
- **`plugins/ICON/skills/writing-skills/SKILL.md`**: mandates the block form for new skills via a frontmatter rule and an Anti-Patterns table row. (MKT-0078)

## [1.13.3-beta.6] - 2026-04-25

### Added
- **`plugins/ICON/hooks/inject-manager-role.ps1`** (new): PowerShell sibling of `inject-manager-role.sh`. Same behavior and diagnostics — selected by `/ICON:enable-manager-default` when `bash` is unavailable (pure-Windows PowerShell environments). (MKT-0051)
- **`plugins/ICON/skills/context-maintenance/scripts/append-retrospective-entry.ps1`** (new): PowerShell sibling of `append-retrospective-entry.sh`. 1:1 behavioral port — same CLI, same exit codes (0/1/2), same output format, same atomic-write discipline. `[regex]::Split` with `\r?\n\r?\n+` replaces awk `RS=""` paragraph mode. (MKT-0051)
- **`plugins/ICON/commands/` (new directory, 4 commands)**: Claude-Code-only slash commands for role defaulting and switching between the two user-facing agents. `/ICON:enable-manager-default` writes a `SessionStart` hook into the user's `~/.claude/settings.json` that auto-adopts the manager role in any project with a `.context/` folder; `/ICON:disable-manager-default` removes it. `/ICON:pm` and `/ICON:manager` are sticky mid-session role switches — each stays in effect until the other is invoked or the session ends. (MKT-0050)
- **`plugins/ICON/hooks/inject-manager-role.sh`** (new, executable): `SessionStart` hook script resolved via `${CLAUDE_PLUGIN_ROOT}`. No-op outside projects with a `.context/` folder. Not declared in any plugin manifest — opt-in only via `/ICON:enable-manager-default`. (MKT-0050)
- **`README.md`** (plugin): new "Default Role (Claude Code)" section under Installation documenting the one-time setup command and the mid-session role-switch commands. (MKT-0050)
- **`CHEAT_SHEET.md`**: new "Role Switching (Claude Code only)" section; Claude Code Launch & Setup row rewritten to reference `/ICON:enable-manager-default` instead of "auto-selected based on task description". (MKT-0050)
- **`BEST_PRACTICES.md`**: Claude-Code-only callout in "Starting a Session" explaining the sticky-switch model between `@manager` and `@product-manager`. (MKT-0050)
- **`plugins/ICON/skills/icon-init/`** and **`plugins/ICON/skills/icon-status/`** (new user-facing meta-skills): wired into plugin README skills table, `using-skills` Common Workflows, GETTING_STARTED, and BEST_PRACTICES. Promoted plugin-distributed-artifact convention. (MKT-0057)
- **`plugins/ICON/skills/plugin-audit/`** (new user-invocable skill): promotes the MKT-0046 audit methodology to a reusable skill. Addressed all reviewer findings (M-1, M-2, M-3). (MKT-0060)
- **Self-verification mechanisms**: new pre-commit `validate-manifests.sh` (STEP-01) and `plugin-lint.sh` with 3 content checks (STEP-03); revised scope dropped CI in favor of pre-commit-only enforcement. (MKT-0056)
- **`.context/standards/skill-decomposition.md § "Skills Cannot Share Scripts"`** (+60 lines): codifies the rule that skills must be self-contained, with the allowed delegation pattern documented. Each of `task-retrospective/scripts/`, `post-incident-review/scripts/`, and `context-maintenance/scripts/` now owns its own `append-retrospective-entry.{sh,ps1}` copy. (MKT-0066)
- **`.context/standards/plugin-structure.md § "Skill Evolution Cross-Surface Sweep"`**: standing rule promoted from MKT-0063 M-CC1 — when a skill is renamed, removed, moved, or has its public surface changed, the same MR must sweep all caller-side references. (MKT-0065)
- **`.context/standards/coder-delegation.md § "Verify Ticket Citations Before Acting"`**: standing rule promoted from MKT-0076 retrospective — sub-agents executing audit-followup tickets must verify on-disk state matches ticket citations before editing. (MKT-0076)
- **`.gitlab-ci.yml` `lint` stage**: runs `.claude/scripts/validate-manifests.sh` + `plugin-lint.sh` on `alpine:3.19` with `bash` for every MR and branch push; `secret_detection` job preserved; dead `test` stage removed. (MKT-0069)
- **`plugins/ICON/skills/initialize-multimodule/SKILL.md` Step 0 "Branch Guard"**: halts on a dirty tree or task branch (anything other than main/master/dev/develop) with a `--force` escape, matching the `/icon-init` pattern; subsequent steps renumbered. (MKT-0070)
- **`plugins/ICON/README.md`**: new "What do you want to do?" intent index (10 rows) between Design Principles and Installation; each row maps a user situation to a command + section anchor. (MKT-0073)
- **`plugins/ICON/skills/icon-init/SKILL.md`**: new Step 5a unconditional next-step hint pointing at `/icon-status`; new Step 5b conditional MCP onboarding hint that suggests `/setup-mcp-servers` only when both `GITLAB_PERSONAL_ACCESS_TOKEN` and `JIRA_API_TOKEN` are unset (uses `${VAR+x}` presence check per `.context/standards/bash-scripting.md`). (MKT-0073)

### Changed
- **Caller-side staleness sweep (5 fixes)**: `manager.agent.md:95` (`initialize-repo` → `/icon-init`); `architect.agent.md:150` (PM defer removed — `@planner` is the sole correct referent after `manager-routing-guide` de-listed PM); `coder.agent.md:18` and `tester.agent.md:19` (re-pointed from deleted `verification-checklist` self-review content to "completion quality gates"); `task-plan-phase-architecture/SKILL.md:71` (false-invocation claim softened to "no agent currently invokes design-first as part of this workflow"). (MKT-0065)
- **`release-plugin/SKILL.md` + `release-plugin-beta/SKILL.md`**: new "Canonical paths" preamble naming `plugins/ICON/CHANGELOG.md` as the authoritative changelog for both stable and beta release flows. Substitutes for the rejected shared-helpers extraction (would have violated "Skills Cannot Share Scripts"); `plugins/ICON-beta/CHANGELOG.md` is no longer maintained as a separate file. (MKT-0070)
- **`agents/manager.agent.md`**: added `### Discretionary` subsection with `*None — all manager behavior is mandatory orchestration.*` placeholder, restoring tier uniformity across all 9 agents. (MKT-0071)
- **`agents/product-manager.agent.md`**: triple-duplicated default-story-path rule resolved — canonical statement now lives only in `## Story Output Location`; `## Task Artifacts` collapsed to a 3-line pointer (net −10 / +1). (MKT-0071)
- **Heading-prefix sweep on 3 skills**: bare `## Step N:` replaced with `## <skill-name>: Step N:` per `writing-skills/SKILL.md:99-118` convention in `release-plugin` (9 headings), `rfc` (7 headings), and `context-specialist-impl-root` (15 headings). (MKT-0072)
- **`.github/copilot-instructions.md` cite-as-canonical references converted to canonical/fallback parenthetical pattern** in 6 files: `reviewer.agent.md:17`, `tester.agent.md:28`, `task-plan-phase-investigation/SKILL.md:26`, `task-plan-phase-completion/SKILL.md:43`, `resolve-repo-context/SKILL.md:18`, `commit-conventions.md:3` template. (MKT-0072)
- **`skills/find-context-template/SKILL.md`**: Copilot CLI install path string parameterized via `MARKETPLACE_NAME` env var with `datascan-marketplace` default (bash + PowerShell variants, both using explicit `${VAR+x}` presence-check fallback per `.context/standards/bash-scripting.md`); "callable primitive" language added to Overview positioning the skill as the canonical install-path resolver for other skills. (MKT-0074)
- **`skills/design-first/SKILL.md` softened to advisory (option β)**: frontmatter description opens with "Optional design pass"; `## When to Use` prefaced with "This is an optional design pass — not a required step"; `## When NOT to Use` renamed `## When to Skip` with new "self-evident structural changes" bullet. Compatible with MKT-0065's task-plan-phase-architecture softening. (MKT-0075)
- **MKT-0076 audit-followup meta-task closed**: 10 phases executed across 2 sessions; 10 GitLab follow-ups from the MKT-0063 audit closed (#36, #37, #38, #41, #42, #43, #44, #45, #46, #47); 1 principled deferral (`initialize-sub-project-loop` extraction — investigation found 3 init skills have structurally different loop semantics that resist clean extraction). 3 standards promotions across the lineage. 0 out-of-scope modifications across 10 sub-agent dispatches.
- **`plugins/ICON/skills/*`**: each skill that previously shared a script via cross-skill reference now ships its own copy under `scripts/`; resolves M-P2 ordering issue surfaced by the MKT-0063 self-audit. (MKT-0066)
- **`plugins/ICON/skills/plugin-audit/`**: refined audit briefs to close skill-coverage gaps surfaced by the MKT-0063 live self-test (AC-6); audit artifacts produced and triaged into MKT-0064/MKT-0076. (MKT-0063)
- **`plugins/ICON/skills/task-plan/templates/`**: phase templates populated with ICON-specific triggers and context files; companion utility-skills brief records the rfc-consolidation case study (MKT-0060 follow-up). (MKT-0062)
- **Manager Delegation hardened (O-M1) + missing-skill gaps closed (O-M2, O-M3, O-M4)**: agent and skill set reshaped to eliminate gaps surfaced by the MKT-0046 audit. (MKT-0059)
- **`/initialize-*` skills flipped to `user-invocable: false`**: user-facing entry point is now `/icon-init` exclusively; user-facing docs point at `/icon-init`. Promoted skill-visibility-change audit checklist. (MKT-0058)
- **`agents/manager.agent.md` slimmed; `shared/common-constraints.md` trimmed**: planner-discipline and collision-check rules promoted; baseline measurements recorded in planner report. (MKT-0055)
- **Consolidated `skills/rfc-format/` and `skills/rfc-refactor/` into a single `skills/rfc/` skill** (MKT-0061): single user-invocable skill with a branching Step 1 ("Do you have a draft?") that routes to either the scaffold path (no draft — collect inputs) or the refactor path (polish existing rough draft). Shared authoritative ORG-004 schema, one canonical Notification Service example, merged quality checklist and best-practices. Resolves the section-5 schema drift between the two source skills in favor of **Operationalization** as section 5, with **Security** rendered as a `### Security` subsection under Operationalization (not a top-level peer). Cross-references updated in `plugins/ICON/README.md` (two rows → one), `CHEAT_SHEET.md` (`/rfc-format` → `/rfc`), `skills/using-skills/SKILL.md` (Formatting skills list + Flexible skills list), `skills/writing-skills/SKILL.md` (Format category example), and `.context/domains/skill-system.md` (two entries → one). Net source-tree delta: −443 lines across the two deleted skills + one new 457-line skill. Source: GitLab #33; audit source: MKT-0046 M-U1 + O-S2.
- **SSOT and duplication consolidation across agents and process skills** (MKT-0052):
  - `agents/manager.agent.md`: added `@product-manager` row to Capabilities table with standalone-tool annotation (not in the manager's delegation chain); `delegate to @manager` rule consolidated to Hardcoded tier with back-references from Scope and Agent Selection; Anti-Rationalization row removed; 7 AR rows restated from Hardcoded/Default tiers pruned.
  - `agents/context-specialist.agent.md`: `cannot delegate` rule reduced from 5 restatements to 2 (frontmatter + Hardcoded tier).
  - `agents/tester.agent.md`: `testing-discipline` skill invocation reduced from 3 call-sites to 1 (workflow step 2 only); standalone Testing Discipline section removed; 4 Scope Guard rows merged into Anti-Rationalization with 1 redundant row pruned.
  - `agents/architect.agent.md`: removed hardcoded "3+ attempts" retry threshold from Debugging Escalation; systematic-debugging owns the numeric trigger; 5 Scope Guard rows merged into Anti-Rationalization.
  - `agents/coder.agent.md`, `planner.agent.md`, `reviewer.agent.md`, `researcher.agent.md`, `product-manager.agent.md`: Scope Guard sections merged into Anti-Rationalization (item #11 — O-T7); AR rows redundant with Hardcoded-tier rules pruned (item #12 — O-T6).
  - `skills/task-plan/SKILL.md`: paraphrased Section Guidance and "The Checklist Trap" subsection removed (Option α); legacy `task-workflow-template.md` fallback and built-in code-block fallback retained for uninitialized-repo safety.
  - `context_template/context/workflows/task-workflow-template.md` and `.context/workflows/task-workflow-template.md`: `[DEPRECATED — use task-plan/base.md + phase files]` banner prepended to both copies.
  - `skills/task-plan-phase-{investigation,architecture,implementation,testing,completion}/SKILL.md`: template-override boilerplate extracted into a single shared preamble per skill; 13 per-section restatements removed across the 5 files.
  - `skills/systematic-debugging/SKILL.md`: confirmed as the sole owner of the 3-attempt debugging threshold. Audit item #10 (duplicate regression-test guidance between `systematic-debugging` and `testing-discipline`) was re-evaluated and **closed as mooted** — the two sections cover functionally distinct concerns (incident response vs. test-authoring methodology), not duplicated content. No cross-reference retained (skills must be self-contained; cross-folder references are not supported in both Copilot CLI and Claude Code).
  - `skills/task-plan-phase-implementation/SKILL.md`, `task-plan-phase-testing/SKILL.md`: 3-attempt/3+-times references replaced with "invoke `systematic-debugging` when stalled — that skill owns the numeric trigger."
  - `skills/testing-discipline/SKILL.md`: no cross-reference added (see systematic-debugging entry above).
  - `skills/verification-checklist/SKILL.md`: paraphrased 4-point Self-Review Checklist section removed entirely — the skill's unique contribution (Evidence-Based Verification Gate, Red Flags, 4-gate Completion Quality Gate) carries the verification discipline. The generic completeness/quality/avoid-overbuilding/evidence questions remain stated in `shared/common-constraints.md` (synced into every agent via pre-commit hook), so the skill no longer restates them. "How to Use This Skill" step 3 updated to point at the Completion Quality Gate rather than the deleted section. No cross-file reference added — skills are self-contained per plugin architecture.
  - Net diff: +63 / −119 across 20 files (not counting this changelog entry). Line-count reduction fell short of the audit's ≥100-line target by 44 lines; reviewer accepted the shortfall after a re-audit found no further dedup targets that would not weaken three-layer enforcement. Option α for item #6 alone retained ~30 lines deliberately.
- **`plugins/ICON/commands/enable-manager-default.md`**: added Step 1 shell auto-detection via `command -v bash` / `command -v pwsh`; the written hook command is the bash-wrapper variant when bash is available, pwsh variant otherwise. Already-enabled detection and disable-filter substring widened from `inject-manager-role.sh` to `inject-manager-role` so both `.sh` and `.ps1` hook entries round-trip through a single enable/disable cycle. (MKT-0051)
- **`plugins/ICON/commands/disable-manager-default.md`**: filter substring widened to match both `.sh` and `.ps1` hook variants. (MKT-0051)
- **`plugins/ICON/skills/context-maintenance/SKILL.md`**: Tooling section renamed from "append-retrospective-entry.sh" to "append-retrospective-entry"; dual-shell Usage blocks added (Bash + PowerShell); Common Mistakes row updated to reference both variants. (MKT-0051)
- **`plugins/ICON/skills/task-retrospective/SKILL.md`**: Rolling Log Maintenance and Full Process Checklist invocation pointers clarified as Bash-or-PowerShell; behavior identical across variants. (MKT-0051)
- **`plugins/ICON/plugin.json`**: added `"commands": "./commands/"` field. Other two manifest variants (`.claude-plugin/plugin.json`, `.github/plugin/plugin.json`) unchanged — Claude Code auto-discovers `commands/` for its own manifest, and Copilot does not support commands. (MKT-0050)
- **`agents/manager.agent.md`**: added single authoritative "Platform Notes: `explore` Sub-Agent" subsection after Session Start Step 7 and qualified the three `explore` dispatch sites (Step 3, Step 7, and the "When to Invoke @researcher" section) to reference the note — prevents hard failures and hallucinated dispatches when the manager runs under Claude Code, where the Copilot-CLI-only `explore` sub-agent does not exist. (MKT-0047)
- **`skills/create-iconrc/SKILL.md`**: Python create block now reads `"version"` from the canonical template (`plugins/ICON/context_template/context/iconrc.json`) at create time instead of hardcoding `"1.0"` — future template version bumps propagate automatically. Added Canonical Schema blockquote pointing to the template as single source of truth. (MKT-0047)
- **`skills/initialize-workspace/SKILL.md`**: Step 4b and Step 6 now dispatch `ICON:context-specialist` (Step 4b with `mode: upgrade`; Step 6 with `tree_position: root`) instead of the generic `general-purpose` sub-agent. Step 6 removes ~60 lines of inlined prompt duplicating `context-specialist-impl-root`; dispatch shape now mirrors `initialize-monorepo` Step 5. (MKT-0047)
- **`skills/context-specialist-impl-root/SKILL.md`**: Step 12 now copies `task-workflow-template.md` and `prune-old-tasks.sh` (with `chmod +x`); Step 15 verification checklist items 8–9 verify both files exist and the prune script is executable — closes a latent regression where post-commit hooks silently failed after workspace or monorepo init. (MKT-0047)

### Fixed
- **Five Tier-1 correctness fixes from the MKT-0063 audit**: `release-plugin-beta` Step 6 write and Step 9 read now both reference `plugins/ICON/CHANGELOG.md` (M-U1 — beta releases were posting the previous beta's notes); `/icon-init` Step 1 now actually invokes the `upgrade-repo` skill on already-initialized repos rather than printing prose (M-I1); `commit-discipline/SKILL.md:30-35` orphan bullets reparented under `## When to Invoke` (M-P3); `[Unreleased]` `### Changed` deduplication restored to a single block (M-X1); CHANGELOG version sections restored to reverse-chronological order (M-X2). (MKT-0064)
- `context-specialist-impl-root` Step 14 no longer hardcodes `repo_type: monorepo`; callers now pass the correct value via dispatcher prompt variable, eliminating the double-invocation workaround in `initialize-workspace` (issue #34). (MKT-0054)
- **Release skills wired to `bump-versions.sh` companion scripts.** Fixes silent under-match when the base version carries a `-dev.N` suffix; removes the `$(SUMMARY)` bash-subshell bug in `release-plugin`; removes the non-existent `plugins/ICON-beta/CHANGELOG.md` staging in `release-plugin-beta`. (MKT-0048)

### Removed
- `skills/rfc-format/` (406 lines) and `skills/rfc-refactor/` (494 lines): consolidated into `skills/rfc/`. No replacement mapping required — both slash-command names were user-invocable, and `/rfc` subsumes both entrypoints via the Step 1 branching question. (MKT-0061)
- `skills/knowledge-graduation/`: retired (MKT-0049); no replacement — skill additions now user-requested on demand.

## [1.13.3-beta.5] - 2026-04-21

### Changed
- `context-maintenance/SKILL.md`: updated script path, description, and usage examples for relocated script
- `task-retrospective/SKILL.md`: updated script path references to `scripts/` subdirectory
- `upgrade-repo/SKILL.md`: added Retrospectives File Migration section for repos with old preamble format
- `task-workflow-template.md`: upgraded from v1.1 to v1.2 (concern-based skill loading model)
- `context_template/context/retrospectives.md`: updated to preamble-free format

### Fixed
- `context-maintenance` script: replaced broken NUL-byte delimiter approach with native awk paragraph mode (`RS=""`) — previous implementation collapsed all entries into one block, preventing pruning and stripping separators

### Internal
- MKT-0043: enforce unconditional split override in context-specialist skills
- MKT-0044: fix `mcpServers: Invalid input` — add `./` prefix to plugin.json path refs; prune retrospectives log to 15 entries

## [1.13.3-beta.4] - 2026-04-17

### Added
- **`skills/context-specialist-create/`** (new skill, `user-invocable: false`): encapsulates the create-mode behavior of `@context-specialist` so the agent can route between `create` and `maintenance` modes without inlining the full procedure twice.

### Changed
- **`agents/context-specialist.agent.md`**: refactored as a mode-based router — `mode: create` dispatches to `context-specialist-create`; `mode: maintenance` dispatches to `context-maintenance`. Previous monolithic agent definition split for clarity and reuse.
- **`skills/context-maintenance/SKILL.md`**: expanded into a prescriptive agent-loadable skill (was descriptive-only); adds explicit steps for `@context-specialist` to invoke when maintaining existing `.context/` documents.
- **`skills/task-retrospective/SKILL.md`**: Step 3 `.context/` writes now dispatch to `@context-specialist` with `mode: maintenance` rather than inlining file-write instructions.
- **`agents/manager.agent.md`**: updated to invoke `@context-specialist` with `mode: maintenance` for context-update delegations (previously implicit).
- **`README.md`**: added `context-specialist-create` to the skills table.

### Fixed
- **`skills/context-specialist-create/SKILL.md`**: frontmatter corrected from outer-skill shape to inner-skill shape (`user-invocable: false`).
- **`skills/context-maintenance/SKILL.md`**: no-changes case now returns a structured no-op result instead of silently exiting; capabilities table corrected.

### Internal
- MKT-0041: deferred — `disable-model-invocation` field proved not viable cross-tool (Claude Code ignores it on some skill types). Minimized internal-skill descriptions as a partial mitigation; added `icon-beta` context doc documenting the deferral rationale.

## [1.13.3-beta.3] - 2026-04-16

### Added
- **`skills/task-plan-phase-testing/`** (new skill): testing-as-primary-concern phase dispatch; loaded on-demand by the manager via the concern-based dispatch table.
- **`skills/context-specialist-detect-tree-position/`** (new skill, `user-invocable: false`): extracts tree-position detection logic (LEAF / BRANCH / ROOT / WORKSPACE) from `context-specialist.agent.md` into a dedicated skill so all four `initialize-*` orchestrators share a single detection implementation.

### Changed
- **`skills/task-plan/SKILL.md`**: dispatch table refactored from linear 7-phase model to concern-based 5-concern model (investigation, architecture, implementation, testing, completion); template-version bumped 1.1 → 1.2.
- **`context_template/context/workflows/task-workflow-template.md`** (v1.2): concern-based skill loading replaces linear phase enumeration; phase-testing row added; phase-completion description tightened.
- **`skills/task-plan-phase-investigation/`, `task-plan-phase-architecture/`, `task-plan-phase-implementation/`, `task-plan-phase-completion/`**: reframed with concern-based language; `phase-completion` Step removed redundant `@tester` delegation structure (closing steps only; testing now dispatches through `phase-testing`).
- **`skills/context-specialist-impl-leaf/SKILL.md`**: copy block count expanded 5 → 6 to include the new `phase-testing.md` per-phase template.
- **`skills/upgrade-repo/SKILL.md`**: audit list, bash copy loop, and PowerShell file array all include `phase-testing.md`.
- **`agents/context-specialist.agent.md`**: 57-line inline tree-detection block replaced with a reference to the new detection skill (–55 lines); sub-agent delegation constraint narrowed to preserve legitimate sub-agent use.
- **`README.md`**: added `task-plan-phase-testing` and `context-specialist-detect-tree-position` to the skills table; corrected `phase-completion` description.

## [1.13.3-beta.2] - 2026-04-16

### Added
- **`task-workflow-template.md`** (both `context_template/` and `.context/` copies): Task Document Template section now contains the full canonical `plan.md` format with all sections — `Objective`, `Decisions`, `Key Files`, `Progress` (checkbox + `← IN PROGRESS` marker), `Open Questions / Blockers`, and `Constraints` — replacing the previous stub that only said "invoke the task-plan skill." Added inline section guidance bullets explaining the *why* behind each section. Added `<!-- template-version: 1.0 -->` comment for future upgrade-repo detection.
- **`context_template/context/workflows/task-workflow-template.md`**: Phase 5 now includes the Pre-dispatch checklist (previously only present in the marketplace `.context/` copy — new repos bootstrapped from `initialize-repo` now get it).
- **4 composable phase skills**: `task-plan-phase-investigation` (Phases 1–3), `task-plan-phase-architecture` (Phase 4), `task-plan-phase-implementation` (Phase 5), `task-plan-phase-completion` (Phases 6–8). All are `user-invocable: false` and loaded on-demand by the manager agent. Each skill provides delegation structures, checklists, and exit criteria for its respective phase.
- **5 per-phase workflow templates** installed to `.context/workflows/task-plan/` by `initialize-repo` and `upgrade-repo`: `base.md`, `phase-investigation.md`, `phase-architecture.md`, `phase-implementation.md`, `phase-completion.md`.
- **`skills/code-quality-rules/SKILL.md`** (new skill, `user-invocable: false`): structured code review methodology with a 5-pass approach (Correctness & Logic, Security & Trust Boundaries, Integration & Side Effects, Maintainability & Clarity, Test & Verification Coverage) plus three severity levels (Critical, Moderate, Minor) and domain-specific checklists for Code Quality, Security, Performance, Testing, Verification, and Maintainability. Loaded on-demand by `reviewer.agent.md` and `coder.agent.md`.
- **`context_template/context/workflows/commit-conventions.md`**: new template file deployed to consumer repos by `initialize-repo` and `upgrade-repo`, providing the project commit conventions reference locally in `.context/workflows/`.

### Changed
- **`skills/task-retrospective/SKILL.md`**: Full Process Checklist step 3 now explicitly delegates `.context/` writes to **@context-specialist** — "Write or update the relevant `.context/` files with promoted lessons — delegate to @context-specialist to perform the actual writes."
- **`skills/find-context-template/SKILL.md`**: Replaced fragile `find`-based template discovery with deterministic path construction. Copilot CLI (bash/zsh) now resolves `${COPILOT_HOME:-$HOME/.copilot}/installed-plugins/datascan-marketplace/ICON/context_template`; PowerShell uses the equivalent with `$env:COPILOT_HOME` / `$HOME\.copilot` fallback. Claude Code (bash/zsh) uses the officially documented `${CLAUDE_PLUGIN_ROOT}/context_template`; PowerShell uses `$env:CLAUDE_PLUGIN_ROOT\context_template`. "If the Result Is Empty" error-handling now gives tool-appropriate guidance — path-existence checks for Copilot CLI (where `$TEMPLATE_DIR` is always assigned) and empty-variable checks for Claude Code (where `$CLAUDE_PLUGIN_ROOT` may be unset). Callers (`initialize-repo`, `upgrade-repo`, `initialize-monorepo`, `initialize-multimodule`) are unaffected.
- **`skills/task-plan/SKILL.md`**: Added deferral mechanism — when `.context/workflows/task-workflow-template.md` exists in the repo, the skill instructs the agent to read the `## Task Document Template` section and use the format defined there. Falls back to built-in format only when no local template exists or no `## Task Document Template` section with a markdown code block is found. Renamed `## Canonical Format` to `## Built-in Format (Fallback)` and `## Format` section to `## Format Selection`. Also added format selection precedence chain (`base.md` → `task-workflow-template.md` → built-in) and phase skills dispatch table.
- **`README.md`**: Updated `task-plan` skill table entry to reflect new deferral behavior. Added entries for 4 new phase skills.
- **`agents/manager.agent.md`**: Updated "Invoke the `task-plan` skill for the canonical format" to "Invoke the `task-plan` skill to determine and write the plan.md format." Also added git operations carveout — manager is explicitly permitted to run git commands directly without delegating to a specialist; enforced at three layers (inline Exception in Agent Selection section, Hardcoded Behavior Tier bullet, Anti-Rationalization table row).
- **`task-workflow-template.md`** (v1.1): trimmed to phase-navigation stubs — full phase guidance now lives in dedicated phase skills.
- **`skills/initialize-repo/SKILL.md`** and **`skills/upgrade-repo/SKILL.md`**: updated to install the five per-phase workflow templates to `.context/workflows/task-plan/` alongside the existing `task-workflow-template.md`.
- **Agent files, skill files, and `context_template/` files**: updated to reference `.claude/claude.md` as the canonical agent-system instructions path; `.github/copilot-instructions.md` retained as legacy fallback in detection heuristics.
- **`upgrade-repo/SKILL.md`**: new Phase 0 migration step detects pre-migration repos and moves `.github/copilot-instructions.md` → `.claude/claude.md`; handles already-migrated and neither-exists cases.
- **`initialize-repo/SKILL.md`**: pre-requisite section now creates `.claude/claude.md` as canonical path.
- **`initialize-multimodule/SKILL.md`**: sub-project discovery recurses up to 5 levels deep (was depth 1); skips `node_modules`, dot-directories, `vendor`, `dist`, and `build`; adds `.claude/claude.md` detection check alongside legacy `.github/copilot-instructions.md`.
- **`agents/architect.agent.md`**: added constraint preventing the architect from writing user stories or decomposing tasks — defer to `@planner` and `@product-manager`.
- **`agents/reviewer.agent.md`**: quality review criteria extracted from the inline agent definition into the new `code-quality-rules` skill; agent now loads the skill on demand rather than maintaining a static inline checklist.
- **`agents/coder.agent.md`**: removed hardcoded 3-attempt retry limit and redundant no-new-patterns constraint; now references `code-quality-rules` skill for quality standards.
- **`agents/tester.agent.md`**: removed inline TDD cycle content; now defers to `testing-discipline` skill for the full TDD cycle.
- **`agents/context-specialist.agent.md`**: added `*.code-workspace` as a ROOT signal in tree-position detection (was previously falling through to LEAF); added Input Parameters section documenting `working_directory`, `git_root`, `feature_branch`, `tree_position`, and `mode`; steps 2–6 now reference these parameters explicitly so delegation parameters are not silently ignored.
- **`skills/initialize-workspace/SKILL.md`**: Step 4a dispatch changed from `general-purpose` to `ICON:context-specialist` agent type, matching the pattern used by `initialize-monorepo` and `initialize-multimodule`; eliminates the double-nesting failure mode introduced by the MKT-0029 refactor.
- **`context_template/context/workflows/prune-old-tasks.sh`**: synced cache pruning logic with the live marketplace script — all improvements accumulated in the repo copy are now propagated to consumer repos on `initialize-repo` and `upgrade-repo`.

### Fixed
- **`agents/coder.agent.md`, `architect.agent.md`, `planner.agent.md`, `researcher.agent.md`, `reviewer.agent.md`, `tester.agent.md`**: Corrected `user-invokable: false` → `user-invocable: false` in frontmatter of all six specialist agent files.
- **`.context/standards/plugin-structure.md`**: Corrected `user-invokable` → `user-invocable` in example frontmatter and field description (3 occurrences).
- **`start-worktree/SKILL.md`**: detection heuristic now checks both `.claude/claude.md` and `.github/copilot-instructions.md` without breaking on pre-migration repos.
- **`skills/initialize-workspace/SKILL.md`** and **`skills/start-worktree/SKILL.md`**: removed `2>/dev/null` stderr-silencing from shell commands, restoring diagnostic signal per the shell command self-check mandate.

---

## [1.13.3] - 2026-04-10

### Fixed
- **`.mcp.json`**: bumped `mcp-atlassian` server from `0.21.0` to `0.21.1` to resolve a bug in one of the Atlassian MCP tools present in the previous version.

---

## [1.13.2] - 2026-04-09

### Fixed
- **`manager`**: Turn Start protocol now includes a **write gate** for `plan.md` currency. Previously the protocol only re-read the plan if context had been reset; it did not check whether the on-disk plan reflected the current task state. The manager now verifies completed steps are marked done, the in-progress step is identified, and the next step is clear — and updates the plan before proceeding if it is stale (closes #3).
- **`manager`**: `plan.md` and other `.context/tasks/` orchestration artifacts are now explicitly exempt from the always-delegate rule via three-layer enforcement: an inline `Exception` note in the Agent Selection section, a Hardcoded Behavior Tier bullet, and an Anti-Rationalization table row. Previously the broad "always delegate to specialist agents" constraint inadvertently captured plan.md writes, requiring an unnecessary @coder round-trip for the manager's own working document (closes #4).

---

## [1.13.1] - 2026-04-09

### Fixed
- **`upgrade-repo`**: added `.context/iconrc.json` to the Phase 1 new-required-files audit and added a conditional `create-iconrc` invocation in Phase 2 when `iconrc.json` is absent. Previously, running `upgrade-repo` on an existing repo would never generate an `.iconrc` — only fresh `initialize-*` runs produced one.

---

## [1.13.0] - 2026-04-09

### Added
- **`resolve-repo-context`** (new skill): determines the correct context root, instructions path, and available skills for any non-project repo (monorepo, VS Code workspace, multi-module). Invoked by `@manager` as an isolated sub-agent during Session Start. Returns structured JSON including `repo_type`, `resolved_context`, `available_skills`, and `projects`. Replaces the dedicated workspace-manager/monorepo-manager delegation chain.
- **`invoke-sub-project-skill`** (new skill): loads and frames a skill from an arbitrary sub-project path so that `@manager` can invoke project-specific skills discovered by `resolve-repo-context`. Bridges the gap between skill discovery and skill execution in multi-project repos.
- **`create-iconrc`** (new skill): sole owner of `.context/iconrc.json` create and update operations. Manages `version`, `repo_type`, `local_task_id_prefix`, `default_branch`, `cache_expires_after_days`, and `excludes`. Invoked by all four `initialize-*` skills.
- **`initialize-multimodule`** (new skill): bootstraps a multi-module parent directory that is not itself a project. Populates `.context/` at the parent level and invokes `initialize-repo` for each sub-module discovered.
- **`context_template/context/iconrc.json`**: canonical `.iconrc` template with all supported fields, inline comments, and sensible defaults — deployed by `initialize-repo`, `initialize-monorepo`, `initialize-workspace`, and `initialize-multimodule`.
- **`context_template/context/.gitignore`**: gitignores `.topology-cache.json` so the resolution cache never pollutes consumer repo status — deployed alongside `iconrc.json`.

### Changed
- **`manager`**: Session Start Step 3 now reads `.context/iconrc.json` and, for non-project repos, invokes `resolve-repo-context` as an isolated sub-agent. The returned `resolved_context` paths and `local_task_id_prefix` are used throughout the session. Removes the prior pattern of silently assuming project-root context for all repo types. Adds explicit handling for `scope: cross-project` resolution — surfaces the ambiguity to the user before proceeding rather than silently using the git root.
- **`manager`**: `available_skills` from `resolve-repo-context` are now loaded at Session Start with an explicit activation rule — prefer a discovered sub-project skill over a standard ICON skill when a match exists, via `invoke-sub-project-skill`.
- **`manager`**: Delegation JSON branch (Step 5) clarified as an intentional extensibility hook for external tooling and future orchestrators, not a remnant of the retired agents.
- **`initialize-repo`**: added Step 6 to invoke `create-iconrc` for the project; added `.context/.gitignore` to the bootstrap file copy list.
- **`initialize-monorepo`**: added root-level `create-iconrc` invocation; fixed stale `@monorepo-manager` references in verbatim sub-agent prompts and documentation.
- **`initialize-workspace`**: added root-level `create-iconrc` invocation; fixed stale `@workspace-manager` references in verbatim sub-agent prompts, post-dispatch comments, and MR templates.
- **`upgrade-repo`**: Phase 1 audit and Phase 2 copy now respect the `excludes` array from `.context/iconrc.json`, skipping listed directories. Added `.context/.gitignore` to the new-required-files audit and copy steps.
- **`using-skills`**: added `initialize-multimodule` to the Common Workflows table.

### Removed
- **`workspace-manager`** agent: retired. All VS Code workspace routing is now handled by `@manager` via `resolve-repo-context`. No user-facing behavior is lost.
- **`monorepo-manager`** agent: retired. All monorepo routing is now handled by `@manager` via `resolve-repo-context`. No user-facing behavior is lost.

---

## [1.12.4] - 2026-04-08

### Fixed
- **`manager`**: broadened Session Start step 7 research gate into two explicit branches — codebase exploration (`explore` agent, for areas not covered in `.context/domains/`) and external research (`@researcher`, for library/API patterns). Previously the gate only checked for @researcher, causing codebase exploration to be skipped entirely.

---

## [1.12.3] - 2026-04-08

### Changed
- **`manager`**: added Session Start step 7 ("Assess research need") — an explicit checklist gate that fires before @planner or @coder, with four specific triggers (version-specific library patterns, migrations/upgrades, undocumented external patterns, evolved APIs). Fixes the failure mode where the manager jumps straight from `.context/` review to @coder delegation without considering @researcher.
- **`manager`**: consolidated @researcher trigger criteria in Session Start step 7 as the single authoritative source; the "When to Invoke @researcher" section now references step 7 rather than duplicating the list. Default tier bullet updated to reference step 7.
- **`manager`**: added Anti-Rationalization table row for the execution-context loophole — "I'm operating as the CLI agent / in a different context" does not exempt the manager from the always-delegate constraint.
- **`common-constraints`** (all agents): replaced the passive `2>/dev/null` prohibition with a **"Shell command self-check"** mandate. Leads with a proactive scan requirement and explicitly names reflexive training-data insertion as the root cause — agents are instructed to scan every proposed command before execution, not rely on a prohibition they will add without noticing. Propagated to all 10 agents via pre-commit hook.

---

## [1.12.2] - 2026-04-07

### Changed
- **`manager`**: extended the "no source investigation" rule in Context Discovery to explicitly cover grep/bash/shell commands, not just file reads. Added cascade-risk explanation ("every quick check invites another"). Updated the matching Anti-Rationalization table row to cover the same scope.
- **`manager`**: strengthened Progress Tracking to make clear plan.md must be updated *before* starting each step, not after completing a batch. Added a matching Anti-Rationalization row for "I'll update plan.md when I'm done."
- **`common-constraints`** (all agents): replaced bare `2>/dev/null` prohibition with a rationale — stderr is diagnostic signal; silencing it is itself a silent workaround. Propagated to all 10 agents via pre-commit hook.

---

## [1.12.1] - 2026-04-06

### Changed
- **`manager`**: added explicit "delegate goals, not scripts" principle to the Delegation section and a matching anti-rationalization row. Prevents the manager from authoring artifact content verbatim and passing it to a specialist to transcribe — which removes specialist judgment and bypasses quality checks.

---

## [1.12.0] - 2026-04-06

### Added
- **MCP server bundling**: the plugin now ships `plugins/ICON/.mcp.json` with pre-configured GitLab (`@zereight/mcp-gitlab@2.0.36` via `npx`) and Atlassian (`mcp-atlassian==0.21.0` via `uvx`) MCP server definitions. All credentials use `${VAR}` placeholder substitution — no secrets are committed. Both `plugin.json` manifests (Copilot CLI and Claude Code) declare `"mcpServers": ".mcp.json"` so servers activate automatically on plugin install.
- **`setup-mcp-servers` skill**: user-invocable skill that guides users through prerequisites (Node.js/npx for GitLab, uv/uvx for Atlassian), all eight required environment variables with examples, shell profile export, and verification steps for both Copilot CLI (`/mcp show`) and Claude Code.

### Fixed
- **`manager`**: corrected self-delegation loop — manager no longer routes tasks to itself when no other specialist matches. Tightened `using-skills` invocation discipline to prevent the skill-check from becoming a distraction that consumes the entire turn without delegating.

---

## [1.11.0] - 2026-04-06

### Changed
- **Plugin renamed from `datascan-agent-system` to `ICON` (Independent Context Orchestration Network)**. The plugin directory is now `plugins/ICON/`, all five manifest files carry `"name": "ICON"`, and all install/update commands use `ICON`. Consumers who installed via `copilot plugin install datascan-agent-system@datascan-marketplace` must reinstall using `copilot plugin install ICON@datascan-marketplace`. The marketplace name `datascan-marketplace` is unchanged.
- `find-context-template`: install path updated from `~/.copilot/installed-plugins/datascan-marketplace/datascan-agent-system/` to `~/.copilot/installed-plugins/datascan-marketplace/ICON/` in all four variants (Bash + PowerShell × Copilot + Claude).
- `release-plugin`: skill updated to reference `plugins/ICON/` throughout, including the five-manifest version check command and the git tag format (`ICON/vX.Y.Z`).
- Tag format changed from `datascan-agent-system/vX.Y.Z` to `ICON/vX.Y.Z`. Existing tags are not rewritten.

---

## [1.10.2] - 2026-04-03

### Fixed
- `task-retrospective`: skill now instructs agents to scan `.context/retrospectives.md` for legacy format/legend sections (e.g., `## Entry Format`, `## Format`, `## Legend`) and remove them before appending a new entry. The canonical format lives in the skill, not the file — stale format blocks were causing duplicate documentation and potential confusion.

---

## [1.10.1] - 2026-04-02

### Fixed
- `manager`: task completion sequence was missing a commit step — after running the retrospective and updating `.context/` documents, the manager would stop without committing any of the resulting changes. Added explicit Step 4 to stage and commit all task artifacts (source changes, `.context/` updates, `plan.md`) using the `commit-discipline` skill before clearing the active task. Added a corresponding anti-rationalization row to prevent the skip.

---

## [1.10.0] - 2026-03-30

### Changed
- `manager`: refactored Turn Protocol into explicit **Session Start** and **Turn Start** sections — one-time setup steps are now clearly separated from per-turn continuation, reducing cognitive load and preventing agents from re-running setup on every turn.
- `manager`: merged redundant "Delegation Protocol" and "Delegation Warmstart Template" sections into a single `## Delegation` section, preserving the union of useful content from both.
- `manager`: moved Progress Tracking section immediately after Turn Start so plan.md creation rules appear before workflow/delegation machinery; added "THE MOMENT" urgency framing to eliminate ambiguity on when to create the task folder.
- `manager`: restored explicit `using-skills` invocation as Step 1 of Session Start (regression from protocol refactor); replaced fragile step-number cross-references with label-based references.
- `manager`: fixed bug-fix-with-unknown-cause routing — previously routed to `@tester` (incorrect); now routes to `@coder` + `systematic-debugging` skill; investigation is a named plan step before the fix.
- `shared/common-constraints.md`: strengthened codebase respect rule, clarified tool-agnostic constraint, toughened no-silent-workarounds language, added Scope Discipline rule. Synced to all 10 agents via pre-commit hook.
- `systematic-debugging` skill: added "Collaborative Investigation" subsection to Phase 1 guidance.
- `task-plan` skill: added "Investigation-First Plans" section with canonical two-step pattern for unknown-cause bugs.

### Removed
- `do` skill: removed as redundant — its only purpose was to invoke the `task-plan` skill, which agents call directly. Removed all references from `README.md` and `BEST_PRACTICES.md`.

---

## [1.9.1] - 2026-03-26

### Fixed
- `writing-skills`: corrected `user-invocable` to `true` — this skill is explicitly for users authoring and editing skills in the system.

---

## [1.9.0] - 2026-03-26

### Changed
- `shared/common-constraints.md`: tightened from 74 lines to 29 lines — removed Skill Awareness section, Three Laws of Verification, Rationalization Escalation procedure, and self-review numbered checklist; condensed remaining rules. Framing prose removed; constraints now expressed as tight, direct rules. Synced to all 10 agents via pre-commit hook.
- `coder`: added `verification-checklist` invocation as step 2 of the Workflow, loading evidence gates, self-review checklist, and rationalization red flags up-front before implementation begins.
- `tester`: added `verification-checklist` invocation as step 3 of the Workflow (alongside existing `testing-discipline` invocation), applying the same completion standards.
- `release-plugin` skill: revised workflow to enforce dev-first discipline — Step 1 now verifies the current branch is `dev` before proceeding; Step 7 commits and pushes to `dev`; Step 8 merges `dev` → `main` (the merge is the release). Removed the old post-release main→dev sync step. Fixed `user-invokable` misspelling to `user-invocable`.
- All 27 plugin skills: added `user-invocable` frontmatter field to every skill. Agent-only skills (commit-discipline, context-document-guidelines, knowledge-graduation, task-plan, task-retrospective, testing-discipline, verification-checklist, writing-skills, agent-evaluation) marked `false`; user-facing skills marked `true`.

---

## [1.8.0] - 2026-03-26

### Changed
- All agents (all 10): common constraints are now inlined directly into each agent's `## Constraints` section between sync markers, replacing the pattern of invoking the `common-constraints` skill at session start. Constraints are always present in context from the first token — no invocation required, survives context compaction, stays current with plugin updates via pre-commit hook.
- `using-skills`: removed stale reference to invoking `common-constraints` first; updated description to reflect it is invoked by the inlined constraint block, not independently
- `shared/common-constraints.md` (new): canonical source of truth for common constraints, replacing `skills/common-constraints/SKILL.md`. Contains only the constraint sections — framing text removed.
- `.githooks/pre-commit` (new): syncs `shared/common-constraints.md` content into all agent files on every commit, keeping inlined copies in sync automatically
- `README.md`: removed `common-constraints` from the skills table (it is no longer a skill)

---

## [1.7.2] - 2026-03-26

### Added
- `task-plan`: new skill defining the canonical `plan.md` format as a handoff document — includes Decisions, Key Files, Progress, Open Questions/Blockers, and Constraints sections; explains why a checklist-only plan.md fails cross-session handoff

### Changed
- `manager`: `common-constraints` promoted to **Step 0** of the Turn Protocol — was previously referenced only in Behavior Tiers and a Constraints block at the bottom of the file, making it easy to skip
- `manager`: new-task keyword detection now explicitly handles "new task", "start", "begin" triggers
- `manager`: invoking `task-plan` skill is now a required step when creating a medium or complex task
- `manager`: `plan.md` Progress Tracking section trimmed — canonical format moved to `task-plan` skill (single source of truth)
- `manager`: added raw-source rule — manager reads `.context/` files for context but does not read raw source files to understand code; delegates that to sub-agents or a focused explore pass that also writes to `.context/domains/`
- `architect`: producing a formal ADR promoted from Discretionary to Default tier
- `task-workflow-template.md`: task document template block replaced with a reference to the `task-plan` skill

### Removed
- `manager`: Scope Guard section (redundant with Anti-Rationalization)
- `manager`: Discretionary behavior tier
- `manager`: `MANDATORY FIRST ACTION` block at bottom of Constraints (superseded by Step 0 in Turn Protocol)

---

## [1.7.1] - 2026-03-25

### Changed
- `manager`: task folder names now require a brief kebab-case description suffix (e.g., `PROJ-1234-payment-refactor`) — raw task IDs alone are no longer valid folder names; lookup-by-prefix matching already supported this format

### Fixed
- `BEST_PRACTICES.md`, `GETTING_STARTED.md`: corrected CLI command from `copilot chat` to `copilot`

---

## [1.7.0] - 2026-03-25

### Added
- `initialize-workspace`: new skill for setting up VS Code multi-root workspaces — reads the `.code-workspace` file, wires both repos to the agent system, and populates `.context/` for each project
- `knowledge-graduation`: new skill for graduating validated `.context/` patterns into local skill definitions (L2 → L1 pipeline); evaluates stability and breadth criteria, proposes skill additions to the manager for approval before writing
- `do`: new shorthand skill for starting or resuming a task — type `/do TASK-ID` or `/do TASK-ID description` to hand off to the manager agent with full task context

### Changed
- All 8 specialist agents (`manager`, `coder`, `tester`, `researcher`, `reviewer`, `architect`, `planner`, `product-manager`): added Behavior Tiers table (Hardcoded / Default / Discretionary), Anti-Rationalization table, and Scope Guard table; removed redundant Constraints bullets already expressed as Hardcoded tiers
- `manager`: added Planning Heuristics section (when to plan vs. act) and Delegation Warmstart pattern (pre-loading specialist context to reduce round-trips)
- `common-constraints`: added Three Laws of Verification (run before claiming, quote specific output, no assumptions after changes) and Rationalization Escalation table
- `verification-checklist`: expanded to a 4-gate Completion Quality Gate (evidence exists, scope fidelity, pattern consistency, no rationalization residue)
- `task-retrospective`: redesigned promotion pipeline — skill now captures lessons AND immediately promotes generalizable ones to `.context/` at task close; removed deferred-promotion model; added "Where to Promote Lessons" decision table and cross-reference to `knowledge-graduation` for L2→L1 graduation
- `knowledge-graduation`: collapsed from 3-stage (L3→L2→L1) to 2-stage (L2→L1) pipeline; skill no longer reviews retrospective entries directly — `task-retrospective` handles immediate `.context/` writes; `knowledge-graduation` focuses exclusively on graduating stable `.context/` patterns into local skill definitions

### Fixed
- `task-retrospective`: restored "Where to Promote Lessons" decision table and immediate `.context/` write steps that had been removed in a prior refactor
- `BEST_PRACTICES.md`: corrected stale description of `knowledge-graduation` that incorrectly stated it reviews raw retrospective entries and writes to `.context/`
- `.context/retrospectives.md`: updated Entry Format header to match `task-retrospective` spec (`Avoid`/`Repeat`/`Updated` format)

---

## [1.6.1] - 2026-03-24

### Changed
- `release-plugin`: added Step 8 to merge `main` back into `dev` after every release, keeping branches in sync

---

## [1.6.0] - 2026-03-24

### Added
- `context-document-guidelines`: new skill establishing atomicity standards for `.context/` files — size heuristics by file type, when-to-split signals, naming guidance for split files, anti-patterns table, and rationalization prevention table

### Changed
- `upgrade-repo`: narrowed scope to infrastructure-only; Phase 3 ("Content Refresh") replaced with a delegation note to `context-maintenance`, eliminating duplicated guidance; frontmatter description and When to Use updated to remove content-drift triggers; stale Common Mistakes row replaced; `META.md`/`retrospectives.md`/`tasks/` protection clause added to Phase 3 delegation
- `initialize-monorepo`: updated Phase 3 sub-agent instructions to align with the new `upgrade-repo` model — delegates to `context-maintenance` on significant drift, skips otherwise; explicit protection added for `META.md`, `retrospectives.md`, and `tasks/`
- `initialize-repo`: added atomicity requirement to Quality Bar — files covering multiple concerns should be split rather than expanded; references `context-document-guidelines` for signals
- `context-maintenance`: added Scope and Size subsection to Pruning — context files grow through accretion; check scope drift alongside staleness when pruning
- `manager`: added atomicity reminder to Domain Documentation section — one facet per file; references `context-document-guidelines` when creating or updating domain files
- `README.md`: registered `context-document-guidelines` in the skills table; updated `upgrade-repo` description to reflect infrastructure-only scope

---

## [1.5.5] - 2026-03-20

### Changed
- `manager`: enforce `plan.md` written to disk for medium/complex tasks — task creation step now explicitly says to create `.context/tasks/TASK-ID/` and write `plan.md` immediately; Progress Tracking section reframed as a required artifact (not just a format suggestion); new Constraints bullet makes it a hard rule; all three changes consistently distinguish session state (tracks active task ID) from `plan.md` on disk (authoritative plan record)
- `writing-skills`: extended step heading format rule to cover stage→step sub-process hierarchies; added correct/incorrect examples for `skill-name: Stage N: Step N` pattern

---

## [1.5.4] - 2026-03-19

### Changed
- All skills with numbered processes: prefixed every step/phase heading with the skill name (e.g. `## initialize-repo: Step 2`) so agents can distinguish skill steps from task plan steps when both appear in the same context window — affects `start-worktree`, `initialize-repo`, `initialize-monorepo`, `upgrade-repo`, `systematic-debugging`, `design-first`, `dependency-management`, `ecological-impact`, `post-meeting`, `rfc-refactor` (53 headings total)
- `writing-skills`: added step heading format rule and correct/incorrect examples to the Body Structure guideline

---

## [1.5.3] - 2026-03-19

### Changed
- `initialize-monorepo`: replaced terminal sub-instance spawning (bash PID management, tool detection, log files) with task tool background agent dispatch — works identically in Copilot CLI and Claude Code; context isolation is automatic
- `common-constraints`: strengthened `/dev/null` restriction with explicit example (`DO NOT INCLUDE 2>/dev/null IN COMMANDS`)

---

## [1.5.2] - 2026-03-12

### Changed
- `testing-discipline`: added Change-Driven Coverage Completeness section — requires deriving test cases from changed decision points (primary path, counter path, adjacent branches, external contract); introduces the standardized Coverage Evidence Block format for reporting which branches are covered or intentionally skipped
- `tester`: moved `testing-discipline` skill invocation to step 2 (before writing tests) so TDD guidance and coverage completeness apply from the start; removed end-of-workflow duplicate invocation; stripped key-principle summaries from the Testing Discipline section to prevent drift
- `reviewer`: added Coverage Evidence Block check to the Testing review criterion — reviewer notes gaps as coaching feedback, not an automatic blocker
- `common-constraints`: clarified `/dev/null` restriction to cover both piping and redirection (`pipe or redirect`)
- `using-skills`: removed stale `start-worktree` row from skill routing table

### Fixed
- `GETTING_STARTED.md`: corrected Copilot CLI launch alias

---

## [1.5.1] - 2026-03-11

### Changed
- `manager`: clarified that simple work (single-file fixes, lint errors, quick bug fixes) must still be delegated to the appropriate specialist — the manager never implements, tests, reviews, or researches directly, regardless of task size; added explicit delegation rule callout and expanded agent selection table with common trivial-seeming patterns that require a specialist
- `using-skills`: added `start-worktree` to the skill routing table for tasks where the human is active in the repo concurrently

---

## [1.5.0] - 2026-03-11

### Added
- `ecological-impact`: new skill that calculates the environmental cost of a Copilot/AI session, expressing inference energy as intuitive ecological equivalents — trees burned, gallons of water, CO₂, LED/refrigerator hours, and solar panel offsets
- `start-worktree`: new skill for setting up a Git worktree so the agent and the human can work in the same repo concurrently without interfering; manager agents may also invoke this when dispatching parallel agents to the same repository

---

## [1.4.5] - 2026-03-11

### Changed
- `manager`: refined Sub-Agent Context Isolation — @researcher, @coder, @tester, and @reviewer run in isolated context windows (noisy I/O, manager needs artifacts only); @planner and @architect run in shared context (collaborative, iterative, compact output)

---

## [1.4.4] — 2026-03-11

### Added
- `manager`: added Sub-Agent Context Isolation section — specialists must always be invoked via the task tool in separate context windows; for verifiable tasks (compilation, test counts, lint), the delegation prompt must require the agent to include command output as proof of correctness
- `researcher`: Research Process now checks `.context/cache/` for a valid document (3-day TTL) before fetching from the web; fresh fetches request `Accept: text/markdown` header (Cloudflare Markdown for Agents) for clean markdown; results written to `.context/cache/<topic>-<YYYY-MM-DD>.md` as comprehensive self-contained reference documents
- `context_template/context/META.md`: `cache/` directory added to structure with TTL and naming convention

### Changed
- `skills/initialize-monorepo/SKILL.md`: replaced hardcoded `copilot chat` invocation with runtime tool detection (`claude --print` or `copilot`) so the skill works in both Claude Code and Copilot CLI
- `agents/architect.agent.md`, `coder.agent.md`, `planner.agent.md`, `researcher.agent.md`, `reviewer.agent.md`, `tester.agent.md` — added `user-invokable: false` frontmatter; specialist agents are invoked by manager, not directly by users

---

## [1.4.3] — 2026-03-10

### Added
- `skills/systematic-debugging/SKILL.md` — added Production Incidents section to Phase 1 (observability-first reproduction for live failures) and Post-Incident Follow-Up section (regression test, monitoring, runbook, retrospective entry)
- `skills/design-first/SKILL.md` — added API Design Considerations (contract, backward compatibility, consistency, validation boundary) and Security Threat Considerations (60-second threat assessment during design)
- `skills/commit-discipline/SKILL.md` — expanded PR/MR section into full lifecycle: pre-open checklist, richer description template, PR size guidance, handling review feedback, and merge conflict resolution

### Changed
- `agents/reviewer.agent.md` — expanded Security checklist: clarified trust boundaries, output encoding for XSS, authz enforced at service layer, new endpoints/data paths must have access controls, auth/authz changes get extra scrutiny
- `skills/using-skills/SKILL.md` — removed trigger-condition lookup table (replaced by skill descriptions in the tool catalog); added `dependency-management` to common workflows; updated "create or edit a skill" workflow to drop `using-skills` trigger table step
- `skills/writing-skills/SKILL.md` — updated skill registration instructions to match: add to `README.md` table required, add to `using-skills` common workflows only if participating in a multi-skill sequence
- `skills/initialize-monorepo/SKILL.md` — added `disable-model-invocation: true` frontmatter field
- `README.md` — updated skill descriptions for `systematic-debugging`, `design-first`, and `commit-discipline`; added `dependency-management` skill entry

---

## [1.4.2] — 2026-03-10

### Changed
- `skills/common-constraints/SKILL.md` — added `MANDATORY FIRST ACTION — NO EXCEPTIONS` block requiring all agents to invoke the `using-skills` skill before starting any task, mirroring the emphatic language agents use when requiring `common-constraints`
- `skills/common-constraints/SKILL.md` — added `No silent workarounds` rule to General Restrictions: agents must stop and raise an error to the user when a required step cannot be followed, rather than silently substituting an alternative approach

---

## [1.4.1] — 2026-03-10

### Changed
- `agents/manager.agent.md` — description expanded with concrete working-directory detection rule (project manifest present at CWD root), trigger conditions, and usage examples; notes that monorepo-manager and workspace-manager use manager as a sub-orchestrator
- `agents/monorepo-manager.agent.md` — description expanded with concrete working-directory detection rule (repo root contains .git/ but no top-level project manifest; manifests live in sub-directories) and example directory trees illustrating the pattern
- `agents/workspace-manager.agent.md` — description expanded with concrete working-directory detection rule (.code-workspace file present, CWD contains only dot folders/files) and example directory trees illustrating the pattern
- All three `plugin.json` files (`.github/plugin/`, `.claude-plugin/`, root) — version bumped to `1.4.1`

---

## [1.4.0] — 2026-03-07

### Added
- `agents/monorepo-manager.agent.md` — new orchestrator for monorepos with multiple solution groups or sub-projects; discovers areas from `.context/projects.md` (generated by `initialize-monorepo`) with fallback to `.sln` parsing and manifest scanning; classifies scope as single-area, cross-area, or repo-wide; delegates to @manager using the same JSON delegation protocol as @workspace-manager; enforces single-branch discipline across all area delegations
- `skills/initialize-monorepo/SKILL.md` — new skill that bootstraps context across an entire monorepo: creates a feature branch off the integration branch, discovers solution groups via `.sln` parsing (or npm workspaces / manifest scanning for other repo types), runs `initialize-repo` or `upgrade-repo` per area in isolated Copilot sessions (max 2–3 in parallel), then generates root-level cross-project context and opens an MR for human review

### Changed
- All 9 agent files — `## Constraints` opening line strengthened from soft suggestion to hard mandate: `MANDATORY FIRST ACTION — NO EXCEPTIONS: Before responding to the user or taking any other action, invoke the \`common-constraints\` skill. Invoke the skill, don't just read it. This is not optional.`
- `README.md` — agents table updated to include `@monorepo-manager`; agent model versions corrected to `claude-sonnet-4.6`; new "Monorepos" section added after "Multi-Project Workspaces"
- All three `plugin.json` files (`.github/plugin/`, `.claude-plugin/`, root) — version bumped to `1.4.0`; descriptions updated to include `monorepo-manager`

---

## [1.3.1] — 2026-03-06

### Changed
- `agents/product-manager.agent.md` — added missing `common-constraints` skill invocation at session start (bug fix; all other agents already had this)

### Removed
- `## Task Artifacts` section removed from 6 specialist agents (`architect`, `coder`, `planner`, `tester`, `researcher`, `reviewer`) — the section only deferred to `common-constraints`, which is already loaded at session start; removes ~120 words of redundant overhead

---

## [1.3.0] — 2026-03-06

### Added
- `skills/find-context-template/SKILL.md` — new non-user-invocable skill that dynamically locates the plugin's `context_template/` directory using `find`/`Get-ChildItem`; replaces hardcoded path lists and `$COPILOT_PLUGIN_DIR` references in `initialize-repo` and `upgrade-repo`

### Changed
- All 8 agent files — replaced `$COPILOT_PLUGIN_DIR` path line with explicit `common-constraints` skill invocation
- `skills/initialize-repo/SKILL.md` — hardcoded path fallback list replaced with `find-context-template` skill invocation; `$TEMPLATE_DIR` variable used throughout copy commands
- `skills/upgrade-repo/SKILL.md` — hardcoded path reference replaced with `find-context-template` skill invocation
- `skills/using-skills/SKILL.md` — description updated to mandate framing; "Available Skills" catalog table removed (redundant with tooling); `common-constraints` and `find-context-template` trigger rows added; "Common Workflows" section added
- `README.md` — skills table updated: `setup-env` removed, `common-constraints` and `find-context-template` added
- `GETTING_STARTED.md` (marketplace root) — "Configure Your Environment" step removed from both Copilot CLI and Claude Code sections; steps renumbered; Quick-Reference table updated

### Removed
- `skills/setup-env/` — environment variable configuration no longer required; all path discovery is now dynamic via `find-context-template`
- `context_template/SETUP_PROMPT.md` — manual bootstrap prompt superseded by `initialize-repo` skill

---

## [1.2.2] — 2026-03-06

### Changed
- `agents/tester.agent.md` — added explicit iteration-vs-full-suite guidance: during RED-GREEN-REFACTOR cycles the agent must run only the specific test file/case being worked on; full suite runs are reserved for final validation before reporting complete

---

## [1.2.1] — 2026-03-06

### Changed
- All agents (`manager`, `planner`, `architect`, `coder`, `tester`, `reviewer`, `researcher`, `product-manager`, `workspace-manager`): default model updated from `claude-sonnet-4.5` to `claude-sonnet-4.6`

---

## [1.2.0] — 2026-03-06

### Added
- `skills/upgrade-repo/SKILL.md` — run on an already-initialized repo to bring it up to current spec and optionally refresh `.context/` content
- `skills/setup-env/SKILL.md` — one-time per-user setup of environment variables required by the plugin (e.g., `$COPILOT_PLUGIN_DIR`)

### Changed
- `skills/initialize-repo/SKILL.md` (renamed from `initial-setup`) — now inspects git log to detect project commit format and branch naming conventions; reads convention once discovered so subsequent agents use it automatically
- `skills/commit-discipline/SKILL.md` — reads project-detected commit format before generating commit messages; respects per-repo conventions
- `skills/initial-setup/SKILL.md` — renamed to `initialize-repo` to clarify it is a one-time per-repo operation
- `context_template/context/workflows/prune-old-tasks.sh` — replaced mtime-based 90-day pruning with branch-aware logic: only prunes tasks older than 90 days since the last `dev`/`main`/`master` commit on the current branch, preserving tasks on old release branches
- All agents and skills: `.context/` and `copilot-instructions.md` now live at project root (not git repo root); copilot-instructions is discovered in the project folder when the project is not at repo root
- `common/common-constraints.md` — extracted repeated "Task Context" boilerplate as canonical `## Task Artifacts` rule; all 7 sub-agents now reference common-constraints instead of duplicating it

**Agent-evaluation fixes (clean separation of concerns):**
- `agents/researcher.agent.md` — replaced "When to Use This Agent" (routing trigger list) with "Scope" section; routing decisions belong to orchestrator; removed `### Next Steps` block from output format; removed "Always recommend which agent should act on findings" constraint
- `agents/architect.agent.md` — escalation section reframed: routing path is now explicit as manager → architect, not coder/tester → architect directly

**Writing-skills discipline applied to all authored skills:**
- `skills/agent-evaluation/SKILL.md` — triggers-only description, added `## Overview` and `## When to Use` sections
- `skills/systematic-debugging/SKILL.md` — removed redundant opening paragraph; replaced with `## Overview`
- `skills/testing-discipline/SKILL.md` — description fix; replaced redundant intro with `## Overview`
- `skills/verification-checklist/SKILL.md` — same discipline fixes
- `skills/task-retrospective/SKILL.md` — same discipline fixes
- `skills/setup-env/SKILL.md` — description fix; labeled intro as `## Overview`
- `skills/context-maintenance/SKILL.md` — removed non-standard "Integration" cross-reference section
- `skills/design-first/SKILL.md` — description fix; removed "Integration with Other Agents" section

---

## [1.1.1] — 2026-03-06

### Added
- SSH install command variants to README for all three install methods (Copilot CLI, Claude Code, manual clone)
- `context_template/context/workflows/prune-old-tasks.sh` — bash script that removes `.context/tasks/` folders with mtime > 90 days
- `context_template/context/workflows/post-commit` — tracked git hook that calls `prune-old-tasks.sh` after each commit; installed via `.githooks/` + `git config core.hooksPath`
- `SETUP_PROMPT.md` Step 3.5: wiring the automatic task-pruning git hook

### Changed
- Renamed `skills/context-setup` → `skills/initial-setup`; comprehensive rewrite merging the full `SETUP_PROMPT.md` instructions into the skill with:
  - Exhaustive per-file population guidance for every `.context/` file type
  - Shallow vs. thorough quality bar table with concrete examples
  - Domain file 8-point minimum standard (entities, lifecycle, API table, business rules, SQL patterns, code paths, gotchas)
  - Prune hook wiring included in setup steps
- Updated all `context-setup` references across README, using-skills, context-maintenance, task-retrospective, and writing-skills

### Removed
- `skills/context-setup/SKILL.md` — superseded by `skills/initial-setup/SKILL.md`

---

## [1.1.0] — 2026-03-05

### Added

**New skills — discipline & process:**
- `skills/systematic-debugging/SKILL.md` — 4-phase debugging: reproduce → root-cause trace → defense-in-depth → verify; escalation rule after 3 failed attempts
- `skills/verification-checklist/SKILL.md` — evidence-based verification gate and self-review process before reporting completion
- `skills/testing-discipline/SKILL.md` — comprehensive TDD guidance, RED-GREEN-REFACTOR, anti-patterns with code examples, mock strategy, AAA pattern
- `skills/task-retrospective/SKILL.md` — structured retrospective with promotion decision table and rolling log guidance
- `skills/using-skills/SKILL.md` — meta-skill listing all skills with trigger conditions, priority ordering, and rationalization prevention

**New skills — workflow:**
- `skills/design-first/SKILL.md` — pre-implementation exploration; propose 2-3 approaches with trade-offs, get approval before coding; hard gate on premature implementation
- `skills/commit-discipline/SKILL.md` — atomic commits, meaningful messages, verified checkpoints, branch hygiene, PR descriptions
- `skills/context-maintenance/SKILL.md` — keeping `.context/` current: when/how to update domain docs, promote retrospective lessons, prune task artifacts

**New skills — meta:**
- `skills/writing-skills/SKILL.md` — how to author new skills: SKILL.md structure, frontmatter conventions, discoverability (CSO), token efficiency, discipline hardening, quality checklist

### Changed

**Agent enhancements (discipline enforcement):**
- `common/common-constraints.md` — added "Skill Awareness" (universal skill check), "Verification Before Completion" (evidence gate), "Self-Review Before Reporting" (4-point checklist), rationalization prevention table
- `agents/coder.agent.md` — added self-review step; debugging discipline section references `systematic-debugging` skill
- `agents/tester.agent.md` — added TDD RED-GREEN-REFACTOR workflow; testing anti-patterns section references `testing-discipline` skill
- `agents/reviewer.agent.md` — added independent verification steps and enhanced review checklists
- `agents/planner.agent.md` — added task granularity section (exact file paths, independently verifiable steps)
- `agents/manager.agent.md` — added design approval gate, parallel dispatch guidance, escalation handling, verification spot-checks; retrospective section references `task-retrospective` skill
- `agents/architect.agent.md` — debugging escalation section references `systematic-debugging` skill

**Skill frontmatter cleanup:**
- All 16 skills updated to use only valid frontmatter fields (`name`, `description`, `argument-hint`, `user-invocable`)
- Removed invalid fields: `tools`, `license`, `metadata` from pre-existing skills
- `skills/using-skills/SKILL.md` — set `user-invocable: false` (background knowledge, not a user command)

---

## [1.0.0] — 2026-03-05

### Added
- **Copilot CLI plugin manifest** (`.github/plugin/plugin.json`) — enables `copilot plugin install`
- **Claude Code plugin manifest** (`.claude-plugin/plugin.json`) — dual-tool compatibility using same `agents/` and `skills/` directories
- **`skills/context-setup/SKILL.md`** — converted from `context_template/SETUP_PROMPT.md`; three-level path fallback for locating template files
- **`skills/agent-evaluation/SKILL.md`** — converted from `prompts/agent-evaluation.prompt.md`

### Changed
- All 8 agents updated: path variable `$COPILOT_AGENT_DIR` → `$COPILOT_PLUGIN_DIR` with full fallback chain
- `agents/product-manager.agent.md` — removed all project-specific domain knowledge (Wi/DAS/4x paths, Type/Area mapping table, hard-coded path examples); agent now derives context exclusively from `.context/` and `copilot-instructions.md`
- `skills/jira-story/SKILL.md` — replaced all project-specific examples (WSD- IDs, datascan package names, CCT/Makes) with generic equivalents
- `README.md` — updated installation section for plugin install workflow

### Removed
- `prompts/` folder entirely (all prompts converted to skills or deleted)
- `skills/feature-research/SKILL.md` (project-specific content, not broadly applicable)

---

## [0.6.0] — 2026-03-04

### Added
- `skills/` directory with initial skills:
  - `skills/sprint-goals/SKILL.md` — sprint goal generation from Jira CSV exports
  - `skills/jira-story/SKILL.md` — Jira story formatting
  - `skills/post-meeting/SKILL.md` — meeting transcription summaries
  - `skills/rfc-format/SKILL.md` — RFC document creation
  - `skills/rfc-refactor/SKILL.md` — RFC draft polishing
- `prompts/` directory with agent-evaluation and feature-research prompts
- `agents/product-manager.agent.md` — product manager specialist agent

### Changed
- Mandatory code review before task completion (`Make code review mandatory before task completion`)
- Clarified task naming convention: Jira ID + kebab-case description

---

## [0.5.0] — 2026-02-27

### Added
- `agents/workspace-manager.agent.md` — orchestrates tasks spanning multiple projects in a VS Code multi-root workspace; delegates single-project work to @manager with full context

---

## [0.4.0] — 2026-02-23 – 2026-02-26

### Added
- `common/common-constraints.md` — shared constraints file loaded by all agents via path variable

### Changed
- `context_template/SETUP_PROMPT.md` — added "before you run" instructions and technical domain examples
- Expanded domain definitions to include technical/infrastructure domains (routing, state management, lifecycle, authentication) in addition to business domains
- Task resume logic updated to use fuzzy matching on folder names (e.g., "WSD-1234" matches `WSD-1234-payment-refactor`)
- Added complexity threshold: task artifacts and folders only created for medium/complex work

---

## [0.3.0] — 2026-02-17 – 2026-02-20

### Added
- **v2.0 rewrite** of all agent definitions and context template (`Rewrite agent definitions and context template for v2.0`)
- Domain documentation triggers: agents now create/update `.context/domains/` files when working in undocumented code areas
- Context separation guidance: `.github/copilot-instructions.md` for big picture; `.context/` for detailed area-specific knowledge

### Changed
- Fixed task state management, delegation protocol, and sub-agent task awareness
- Manager's sub-agents marked `user-invokable: false`

---

## [0.2.0] — 2026-02-10 – 2026-02-16

### Added
- `agents/researcher.agent.md` — research specialist for docs, best practices, and library patterns
- `context_template/workflows/task-workflow-template.md` — reference workflow template for agents
- Preflight pattern in manager: reads `.context/` and project instructions at the start of every turn (replaces failed attempt to use conversation compaction as an event hook)

### Changed
- Updated agent definitions with new `.context/` specifications
- Cleaned up redundancies across agent definitions
- README and manager edits following initial stabilization

---

## [0.1.0] — 2026-02-04

### Added
- `.context/` template directory (`context_template/`) — standardized structure for per-project context:
  - `domains/` — business and technical domain knowledge
  - `tasks/` — active task plans and artifacts
  - `standards/` — coding conventions
  - `testing/` — test strategies
  - `styling/` — UI/CSS conventions
  - `architecture/` — system design
  - `workflows/` — CI/CD and branching processes
  - `retrospectives.md` — rolling lessons-learned log
- `SETUP_PROMPT.md` — guided setup for initializing `.context/` in a new project
- Reorganized repo structure for use as a git submodule

### Changed
- Removed duplicate coordinator agent

---

## [0.0.1] — 2026-01-27

### Added
- Initial check-in: manager, planner, architect, coder, tester, and reviewer agents
- Basic README
