# Utility Skills Audit — Raw Findings

## Summary

The utility skill set is in substantially improved condition relative to ICON-0015. All seven items closed by ICON-0037 (m-U-A model placeholder, m-U-B jira-story write literal, m-U-C legacy-path framing, m-U-D TaskCreate, m-U-E setup-mcp-servers Option A, m-U-F rfc design-history, m-U-I MKT-0046 synthesis ref) are confirmed fixed on disk. ICON-0038 closed m-U-H (release-plugin git-repo guard) and m-U-K (format-slack.sh strict mode) — both verified on disk. ICON-0032 closed m-U-J (script-parity SSOT drift) via a pre-commit byte-equality gate across all three `append-retrospective-entry.{sh,ps1}` copy pairs. ICON-0033 closed m-U-G (writing-skills self-cap violation at the line level — 549 → 499 lines), though a residual word-count self-reference gap remains. Three new-since-prior-audit skills (`mcp-tools-first`, `plugin-design`, `icon-audit`) are evaluated fresh. The dominant net-new findings are: (1) `ecological-impact` retains hard-coupled Copilot-specific product framing (quota plan names, "Copilot status bar", "Remaining Reqs" UI label) in its core calculation path despite ADR-004's tool-agnostic mandate; (2) `writing-skills` self-reference violation survives at the word-count axis (499 lines / 2,908 words against its own "< 500 words" target for standard skills at line 240); (3) `sprint-goals` embeds a live `onedatascan.atlassian.net` URL at lines 20 and 196 that will be unresolvable for every consumer except one; (4) `mcp-tools-first` has no `user-invocable` frontmatter key; and (5) `plugin-design`'s description names "Claude Code plugin" explicitly, coupling the trigger to a specific runtime when the skill body explicitly claims plugin-agnosticism.

---

## Defect Findings

### Critical

None observed.

### Moderate

#### M-U-NET1 — `ecological-impact` embeds Copilot-product-specific framing throughout the calculation path (ADR-004 violation)

- **Location**: `skills/ecological-impact/SKILL.md:4` (description), `:12` ("Copilot/AI usage"), `:17` ("Copilot session"), `:21` ("current Copilot session"), `:43-74` (Option A: "Copilot status bar", "Remaining Reqs", "GitHub Copilot Business plan", quota tiers keyed to GitHub billing plans), `:45-50` (step 1 asks for "Remaining Reqs"), `:148-149` (output template says "Copilot Ecological Impact Report"), `:208` (example output says same), `:199` ("Remaining Reqs counter")
- **Problem**: ADR-004 states "Skills, agents, and commands are written as portable markdown … Skills must not embed runtime-only assumptions." The "Remaining Reqs" status bar is GitHub Copilot UI; the monthly-quota tier table (Free: 50 / Pro: 300 / Business: 300 / Enterprise: 1,000) is the GitHub Copilot billing structure. Neither concept exists in Claude Code. A Claude Code consumer who invokes this skill is told to "ask the user what their Remaining Reqs shows" — a question that has no answer in their runtime. The output template hardcodes "Copilot Ecological Impact Report". The description trigger includes "their AI/Copilot session" which is at least partially tool-aware but acceptable as a general coupling; the _body_ is where the violation is concrete.
- **Risk**: The skill's most valuable calculation path (Option A, "Preferred") is entirely inoperable for Claude Code consumers. Option B (session-only) works for any runtime but is demoted to fallback. The report header will always say "Copilot" even for Claude Code sessions. This is a user-facing correctness problem, not just an internal hygiene issue.
- **Classification**: Moderate (not Critical because Option B still works; the skill degrades rather than fails completely).

### Minor

#### m-U-net1 — `writing-skills` word-count self-reference violation persists after ICON-0033 line-count fix

- **Location**: `skills/writing-skills/SKILL.md:185` ("Keep SKILL.md under 500 lines"), `:240` ("Standard skills: aim for < 500 words"), and the current file: 499 lines / 2,908 words
- **Problem**: ICON-0033 brought the file from 549 → 499 lines (fixed the `:185` rule). The `:240` word-count rule ("Standard skills: aim for < 500 words") remains violated at 2,908 words — nearly 6× the target. The self-reference violation that drove ICON-0033 was originally described as m-U-G in ICON-0015; the line-cap axis is fixed but the word-cap axis is not. The skill creation checklist extraction reduced lines but did not reduce words proportionally because the remaining content is dense.
- **Classification**: Minor (the skill still functions; the violation is now the word axis only).

#### m-U-net2 — `mcp-tools-first` missing `user-invocable` frontmatter key

- **Location**: `skills/mcp-tools-first/SKILL.md:1-9` (frontmatter block — only `name` and `description` present, `user-invocable` absent)
- **Problem**: Every other skill in scope has `user-invocable` declared. The field drives slash-command exposure and the skill-catalog presentation. Its absence creates parser ambiguity about whether the skill is user-invocable (the ICON loader's default behavior when the field is missing is to treat it as `false`, which is correct here since `mcp-tools-first` is auto-invoked by description match, not by user slash command). However, absent explicit declaration, a future author might add `user-invocable: true` assuming they're completing missing boilerplate, incorrectly exposing it as a slash command.
- **Classification**: Minor.

#### m-U-net3 — `sprint-goals` embeds a live `onedatascan.atlassian.net` Confluence URL at lines 20 and 196 (ADR-004 + discoverability risk)

- **Location**: `skills/sprint-goals/SKILL.md:20` (`https://onedatascan.atlassian.net/wiki/spaces/DAA/pages/7093321734/ORG-004+Engineering+Sprint+Goal+Guidelines+and+Best+Practices`) and `:196` (identical URL in the Reference section)
- **Problem**: The URL is org-specific — it will 404 for every ICON consumer other than DataScan. Per ADR-004, skills should not embed runtime-only or org-only assumptions. The description at line 4 already carries a `Note:` about DataScan convention for the prefix-removal list, which is the correct handling for org-flavored content. The embedded live URL is a harder coupling: it's in the "all formatting follows" mandatory reference sentences and is cited twice. Note: ADR-010 Part B registers `m9` (DataScan-flavored examples) as "Accepted (watch)" for `sprint-goals` _examples_ — but the live URL in the body is not a shape example and is not covered by the m9 acceptance. The description note and the example prefix tags are within ADR-010 scope; the live URL in the body is not.
- **Classification**: Minor (the skill still functions; the URL is advisory, not mechanically required for execution).

#### m-U-net4 — `plugin-design` description names "Claude Code plugin" specifically, while skill body claims platform-agnosticism

- **Location**: `skills/plugin-design/SKILL.md:4` (description: "Use when about to scaffold a new **Claude Code** plugin…"), `:12` (body: "A two-mode skill for building and reviewing **Claude Code** plugins"), `:14` (body: "This skill is plugin-agnostic — it ships with ICON but applies to any Claude Code plugin")
- **Problem**: The `:14` line claims the skill "applies to any Claude Code plugin" and then immediately says "Claude Code plugin" again — so the portability claim is actually scoped to Claude Code, which is inconsistent with a true plugin-agnostic posture. For the description specifically: a Copilot CLI user who has installed the ICON plugin would correctly see the skill in their catalog but might not self-identify as working on a "Claude Code plugin" — they might call it a "Copilot plugin." The ADR-004 guidance for path variables says "both forms are documented" — but the description trigger here is implicitly Claude-Code-only in naming. This is a mild ADR-004 tension, not a clear violation, since the underlying skill may legitimately be Claude Code-specific in scope.
- **Classification**: Minor (soft ADR-004 tension; the skill is internally consistent about being Claude Code-scoped; the "plugin-agnostic" claim in line 14 is the real mismatch since it makes a generalization claim the skill then doesn't honor by covering Copilot or other runtimes).

#### m-U-net5 — `icon-audit` Quality Checklist is orphaned from `writing-skills`' Iron Law (self-reference check)

- **Location**: `.claude/skills/icon-audit/SKILL.md:144-152`
- **Problem**: The Quality Checklist says "verify against the Skill Creation Checklist in `writing-skills`." `writing-skills` mandates a RED-GREEN-REFACTOR TDD cycle for all new skills. There is no on-disk evidence this cycle was followed when `icon-audit` was created (ICON-0042 plan.md documents the rename but not the new-skill TDD cycle since the skill was moved and renamed, not authored from scratch). This is a structural observation about process gap rather than a correctness defect.
- **Classification**: Minor / informational. The rename from `plugin-audit` to `icon-audit` is arguably not "creating a new skill" per the Iron Law's definition; the skill's behavior was established through prior audit cycles. Retaining as a finding-flag rather than a defect.

---

## Improvement Opportunities

### IO-U-1 — Generalize `ecological-impact` to work with Claude Code's session metrics (Closes M-U-NET1)

**Effort: Low. Impact: High.**

The calculation core (Steps 2–6) is already fully generic — it works from token count alone. The Copilot-specific coupling is isolated to Step 1 Option A's data-gathering path. The fix is:

1. Rename Option A from "Monthly Usage via Remaining Reqs (Preferred)" to "Monthly Usage (Preferred)" and reframe the data-gathering question as platform-neutral: "Ask the user to provide their monthly interaction count, or help them derive it from whatever usage dashboard their AI platform provides."
2. Add a Claude Code-specific sub-option: "For Claude Code, check `~/.claude/settings.json` or the session transcript for token usage, or estimate from the session-turn count."
3. Replace "GitHub Copilot Business plan" quota table with a generic "typical AI platform tiers" framing and keep the values as reference examples rather than authoritative figures.
4. Replace "Copilot Ecological Impact Report" in the output template and example (lines 149, 208) with "AI Session Ecological Impact Report" or use a runtime-aware placeholder `<platform> Ecological Impact Report`.

This directly resolves the ADR-004 violation in M-U-NET1.

### IO-U-2 — Extract `ecological-impact` formulas-reference.md cross-link into SKILL.md body (Operational defensiveness)

**Effort: Trivial. Impact: Low-Medium.**

`skills/ecological-impact/SKILL.md:237` reads "A flat lookup table of every formula and constant used in this skill … lives in `formulas-reference.md`." This reference is load-bearing for verification but the file is never named in the Quick Reference section. A one-line "See also: `formulas-reference.md` for cross-step verification" addition to Step 6 makes the cross-check path discoverable without loading the extra file until needed. Low token cost.

### IO-U-3 — Add `using-skills` Skill Priority entry for `mcp-tools-first` (Discoverability gap)

**Effort: Trivial. Impact: Medium.**

`skills/using-skills/SKILL.md:69-76` contains the Skill Priority ordering. `mcp-tools-first` is not referenced anywhere in `using-skills`, `manager-routing-guide`, or any agent file (verified by grep). The skill relies entirely on description-match auto-invocation. Adding a one-line callout to the Process skills category — "For GitLab/Jira/Confluence access, check the catalog for `mcp-tools-first` before any external tool call" — would reduce the failure mode ICON-0045 was created to address: agents that know the skill exists but bypass description matching under schema-unknown pressure.

### IO-U-4 — Add `user-invocable: false` and explicit `disable-model-invocation` to `mcp-tools-first` (Frontmatter completeness)

**Effort: Trivial. Impact: Low.**

`mcp-tools-first` currently has no `user-invocable` key (m-U-net2). The correct value is `false` — the skill is auto-invoked by description match, not user slash command. Adding the key closes the parser-ambiguity gap and follows the pattern of every other skill in scope. The `disable-model-invocation` key is an optional defense-in-depth (consistent with O-X3 from ICON-0015 for non-user-invocable skills).

### IO-U-5 — Replace live `onedatascan.atlassian.net` URL in `sprint-goals` with a placeholder or organization-configurable reference (Closes m-U-net3)

**Effort: Trivial. Impact: Low-Medium.**

`skills/sprint-goals/SKILL.md:20` and `:196` each contain a hard link to `https://onedatascan.atlassian.net/wiki/spaces/DAA/pages/7093321734/ORG-004+Engineering+Sprint+Goal+Guidelines+and+Best+Practices`. The description already carries the DataScan-convention note (line 4), which correctly signals that example content is org-flavored. The ORG-004 URL should be replaced with a placeholder: "See your organization's Sprint Goal Guidelines and Best Practices document (replace this link with your org's equivalent)." This follows the ADR-010 m9 pattern of keeping shapes generic while flagging org-specific content.

### IO-U-6 — Consolidate `jira-story` and `sprint-goals` under a shared "Jira Output Skills" group with a branching-step-1 dispatcher (Token efficiency / Consolidation)

**Effort: Medium. Impact: Medium.**

Both skills are Format-type skills targeting Jira workflows, both are DataScan-flavored in their examples, and both write structured output documents. The consolidation pattern established by MKT-0061 (rfc-format + rfc-refactor → rfc) would apply: a single `jira-outputs` skill with a branching Step 1 ("Are you writing a story or a sprint goals communication?") routing to the appropriate sub-path. Shared content: the Jira markdown reference (currently in jira-story), the ORG-004 reference (currently in sprint-goals), the DataScan-convention disclosure note. Net delta: two user-invocable rows collapse to one; the shared markdown and convention material is single-sourced. This is a forward-looking consolidation candidate, not a defect.

### IO-U-7 — Promote `plugin-design/audit-mode.md`'s Hard Precondition check to an operational guard in `SKILL.md` (Operational defensiveness check)

**Effort: Low. Impact: Medium.**

`plugin-design/audit-mode.md:7-11` correctly requires `.context/iconrc.json` before running the audit. This precondition check is inside a companion file loaded lazily by the mode-detection step. A first-time user who invokes the skill and reaches mode detection may not see the precondition until mid-flow. Adding a one-line note to `plugin-design/SKILL.md:43` (in the Audit mode row of the Mode Detection table) — "Run the precondition check in `audit-mode.md` before loading audit-phase files" — surfaces the guard earlier. The check itself is already implemented; this is a discoverability improvement.

---

## Utility-Skills-Specific Structural Observations

### Observation 1 — Copilot product naming in `ecological-impact` predates ADR-004 but post-dates its recording

The `ecological-impact` Copilot coupling (M-U-NET1) is not a new drift — the skill was authored with Copilot framing intentionally when ICON was primarily a Copilot CLI plugin. Since ICON-0012 established Claude Code as a co-equal runtime, the Copilot-specific UI framing has become a compliance gap. The m-U-A fix (model name placeholder) addressed one surface of this pattern in ICON-0037 but did not address the deeper runtime-coupling in the calculation path. The full remediation requires the IO-U-1 reframe.

### Observation 2 — `writing-skills` self-reference gap is a structural tension, not a one-time fix

The word-count cap ("Standard skills: aim for < 500 words", line 240) is aspirational guidance, not a hard rule — it says "aim for" rather than "must be under." At 2,908 words, `writing-skills` is a complex discipline skill, and its own taxonomy (`writing-skills/SKILL.md:70-76`) places discipline skills in the "can go longer, but earn every line" category. The tension is that the same skill uses both "Keep SKILL.md under 500 lines" (line 185, hard-sounding) and "aim for < 500 words" (line 240, soft-sounding) — the distinction between hard and aspirational cap is not communicated clearly. A future reader will see "under 500 lines" as the hard rule (which ICON-0033 restored compliance with) and may incorrectly dismiss the word-count axis. Clarifying the line 240 phrasing to "frequently-loaded skills" vs "complex discipline skills" scope (matching the sentence structure at line 238–240) would eliminate the self-reference tension without changing the behavior.

### Observation 3 — `mcp-tools-first` is missing from the Skill Priority list in `using-skills` (Systemic discoverability gap)

The three most frequently auto-invoked discipline/tool skills — `mcp-tools-first`, `systematic-debugging`, `verification-checklist` — are all referenced in `using-skills/SKILL.md:70-83`. `mcp-tools-first` is absent. ICON-0045's retrospective documents a real agent failure mode (agent knew the MCP tool existed, still fell back to CLI). Adding a catalog mention in `using-skills` closes the remaining discovery path that hardened description-triggers alone can't address.

---

## ICON-0015 Delta

### Fixed since ICON-0015

| ICON-0015 ID | Description | Closing task / evidence |
|---|---|---|
| m-U-A | `ecological-impact` stale "Claude Sonnet 4.6" model name | ICON-0037; `:86` now reads `<model-in-use>`, `:221` verified |
| m-U-B | `jira-story:32,:35` Copilot-CLI `create` tool literal | ICON-0037; line 32 now reads "your available file-write tool" |
| m-U-C | `start-worktree` "not yet migrated" framing (3 cited + 12 drift sites) | ICON-0037; all sites now read "on repos still on the legacy path" |
| m-U-D | `writing-skills` TaskCreate references in sub-files | ICON-0037; `skill-creation-checklist.md:6` + `persuasion-principles.md:36` now use "your runtime's task-tracking tool" |
| m-U-E | `setup-mcp-servers` "Choose one option" / Option A only | ICON-0037; removed; Step 3 now gives a direct instruction |
| m-U-F | `rfc:139` design-history paragraph mid-schema | ICON-0037; moved to `## Design Notes` at end of file (line 296) |
| m-U-G | `writing-skills` exceeds its own 500-line cap (549 lines) | ICON-0033; now 499 lines (word-count axis still open — see m-U-net1) |
| m-U-H / m-7 | `release-plugin` no git-repo guard before `git branch --show-current` | ICON-0038; line 31 now has `git rev-parse --is-inside-work-tree` guard |
| m-U-I | `synthesis-template.md:122` MKT-0046 unresolvable reference | ICON-0037; sentence removed from synthesis-template |
| m-U-J | `post-incident-review` / `task-retrospective` script SSOT drift | ICON-0032; pre-commit byte-equality gate across all three `append-retrospective-entry.{sh,ps1}` copy pairs |
| m-U-K / m-4 | `format-slack.sh` no `set -euo pipefail` | ICON-0038; line 17 now has `set -euo pipefail` |
| M-U-A (ICON-0015 Moderate) | Six `plugin-audit` briefs with unfilled `<path-to-prior-audit-report.md>` placeholder | ICON-0030; briefs now contain a discovery command (`find .context/tasks -maxdepth 2 -name audit-report.md | sort | tail -n 1`) |

### Still present or partial

| ICON-0015 ID | Current state |
|---|---|
| m-U-G (word-count axis) | `writing-skills` still 2,908 words against its own "aim for < 500 words" guidance. The line-cap axis was fixed by ICON-0033; the word-count axis was not. See m-U-net1. |
| m9 (ADR-010 accepted) | DataScan-flavored examples in `sprint-goals` examples and `jira-story` (ADR-010 "watch/accepted" — retained per the registry decision). The live URL at `sprint-goals:20,:196` is a distinct and non-accepted issue (see m-U-net3). |

### Net-new

1. **M-U-NET1 — `ecological-impact` Copilot-product framing throughout Option A calculation path.** Not present in ICON-0015 (m-U-A only addressed the model name; the broader Copilot UI coupling was not flagged). ADR-004 violation affecting the skill's primary calculation path for Claude Code consumers.

2. **m-U-net1 — `writing-skills` word-count self-reference violation.** ICON-0015 m-U-G was framed around the 500-line cap. The word-count cap at line 240 ("Standard skills: aim for < 500 words") is a distinct axis the prior audit did not measure. Now surfaced as a residual partial-fix gap.

3. **m-U-net2 — `mcp-tools-first` missing `user-invocable` frontmatter key.** New skill first audited this cycle (ICON-0041/0045).

4. **m-U-net3 — `sprint-goals` live `onedatascan.atlassian.net` URL in skill body (not examples).** ADR-010 m9 covers DataScan-flavored _examples_ as accepted; the URL in the body text is not covered by that acceptance. Net-new finding distinct from m9.

5. **m-U-net4 — `plugin-design` description names "Claude Code plugin" while body claims plugin-agnosticism.** New skill first audited this cycle (ICON-0043). Soft ADR-004 tension.

6. **m-U-net5 — `icon-audit` Quality Checklist lacks on-disk TDD-compliance evidence per `writing-skills` Iron Law.** New skill (ICON-0042 rename). Informational / process-observability gap.

7. **IO-U-3 (gap) — `mcp-tools-first` is absent from `using-skills` Skill Priority and all agent files.** New skill; the discovery-gap was partially observed in ICON-0045 but the cross-reference fix was not included in that task's scope.
