# Utility Skills Audit — Raw Findings

## Summary

The utility skill set shows strong net improvement since ICON-0046. Four of the six net-new findings from that cycle are confirmed fixed on disk: `mcp-tools-first` gained `user-invocable: false` (ICON-0048); `context-specialist.agent.md` was trimmed to one sentence (ICON-0048); plugin-lint Check A/B references remain undefined (still present, carried forward as Minor); and the `ecological-impact` Copilot-product coupling — the only ICON-0046 Moderate — persists with no structural change. The ICON-0051 `rfc` metadata-table rewrite is conformant: both scaffold and refactor paths, the ORG-004 schema, and the quality checklist are consistent. The new `characterization-testing` skill (ICON-0049) is structurally clean but absent from the README internal-skills table, creating a discoverability gap that mirrors the prior `mcp-tools-first` pattern. The dominant findings this cycle are: (1) `ecological-impact` M-U-NET1 from ICON-0046 is a third-cycle carry-forward — no structural remediation has been applied to the Copilot-specific Option-A calculation path; (2) `writing-skills` now violates its own line-cap rule at 524 lines (the "Keep SKILL.md under 500 lines" rule at line 210 was the very rule ICON-0033 restored compliance with; ICON-0047's `Where Skills Live` addition reopened it); (3) two new net-new Minors — `rfc`'s live org URL at line 19, and the `characterization-testing` README registration gap.

---

## Defect Findings

### Critical

None observed.

### Moderate

#### M-U-1 — `ecological-impact` Copilot-product coupling in Option-A path (ADR-004 violation, third-cycle carry-forward)

- **Location**: `skills/ecological-impact/SKILL.md:4` (description: "their AI/Copilot session"), `:12` ("Copilot/AI usage"), `:17` ("the Copilot session itself"), `:21` ("the current Copilot session"), `:43-74` (Option A: "Copilot status bar shows Remaining Reqs", "GitHub Copilot Business plan", quota tiers Free 50 / Pro 300 / Pro+ 1,500 / Business 300 / Enterprise 1,000), `:45-50` (asks user "What does your Remaining Reqs show right now?"), `:74` ("whenever the user can provide Remaining Reqs"), `:149` (output template header: "🌍 Copilot Ecological Impact Report"), `:199` ("not captured by the Remaining Reqs counter"), `:208` (example output header: "🌍 Copilot Ecological Impact Report")
- **Problem**: ADR-004 mandates tool-agnostic content. The "Remaining Reqs" status bar is GitHub Copilot UI; the quota table (Free 50 / Pro 300 / Business 300 / Enterprise 1,000) is the GitHub Copilot billing structure. Neither concept exists in Claude Code. A Claude Code user who invokes this skill is told to "ask the user what their Remaining Reqs shows" — a question that has no answer in their runtime. The output template and example both hardcode "Copilot Ecological Impact Report". The calculation core (Steps 2–6) is fully generic; only Step 1 Option A is broken for non-Copilot runtimes.
- **Delta from ICON-0046**: No change. ICON-0046 flagged this as M-U-NET1 citing the same lines. The ICON-0046 audit-report recommended ICON-0047 for remediation; ICON-0047 addressed `writing-skills` instead. This is the third consecutive audit cycle touching the same root cause.
- **Classification**: Moderate (Option B — session-only path — still works for any runtime; skill degrades rather than fails completely).

### Minor

#### m-U-1 — `writing-skills` line-cap self-reference violation (regression from ICON-0033)

- **Location**: `skills/writing-skills/SKILL.md:210` ("Keep SKILL.md under 500 lines; split into supporting files past that"), current file: **524 lines**
- **Problem**: ICON-0033 explicitly fixed this violation by reducing the file from 549 → 499 lines. ICON-0047 added the `## Where Skills Live` section (lines 79–102, ~24 lines), pushing the file back above the cap to 524 lines. The `## Where Skills Live` section is load-bearing discipline content (addresses a confirmed agent failure mode, per the ICON-0047 retro) but was added without applying the skill's own split-to-supporting-files guidance. The word-count axis ("Standard skills: aim for < 500 words" at line 265) is a separate and prior violation at 3,160 words — still present from ICON-0046 m-U-net1, unchanged.
- **Classification**: Minor. The skill still functions; the violation is a self-consistency defect whose correction requires a split decision.

#### m-U-2 — `sprint-goals` live org URL at lines 20 and 196 (still present from ICON-0046 m-U-net3)

- **Location**: `skills/sprint-goals/SKILL.md:20` ("All formatting, status indicators, and best practices follow **[ORG-004 Engineering Sprint Goal Guidelines and Best Practices](https://onedatascan.atlassian.net/wiki/spaces/DAA/pages/7093321734/...)**.") and `:196` (identical URL in Reference section)
- **Problem**: The URL points to the DataScan Confluence org. It will 404 for every ICON consumer other than DataScan. Per ADR-004, skills must not embed org-specific assumptions. ADR-010 m9 covers DataScan-flavored example *shapes* (prefix tags, sample story titles) as Accepted (watch); the live URL in the mandatory-reference prose is not within that acceptance. The description already carries a DataScan-convention note (line 4) which is the correct handling; the body URL is a harder coupling.
- **Delta from ICON-0046**: No change. ICON-0046 flagged this as m-U-net3 at the same lines; ICON-0048's hygiene sweep listed it (O-M5) but the fix was not included in the bundle.
- **Classification**: Minor. The skill functions; the URL is advisory not mechanically required, but it will mislead non-DataScan consumers.

#### m-U-3 — `rfc` skill embeds live org URLs at line 19 (net-new)

- **Location**: `skills/rfc/SKILL.md:19` ("Reference documentation: [RFC-001 RFC Process](https://onedatascan.atlassian.net/wiki/spaces/DAA/pages/5982879965/RFC-001+RFC+Process) · [General RFC Guidance](https://onedatascan.atlassian.net/wiki/spaces/DAA/pages/6080626827/General+RFC+Guidance)")
- **Problem**: The same ADR-004 / ADR-010 logic that governs `sprint-goals` applies here. The RFC-001 and General RFC Guidance links are DataScan Confluence pages that will 404 for non-DataScan consumers. The `rfc` skill body otherwise keeps DataScan framing strictly in the example file (`examples/notification-service-email.md`) — the live URL in the overview prose is inconsistent with that pattern and was present in the pre-ICON-0051 skill as well. ADR-010 m9 covers example *shapes*, not reference URLs in the overview section.
- **Delta from ICON-0046**: Net-new finding. ICON-0046 did not flag the `rfc` overview URL (likely because the pre-ICON-0051 overview didn't call out reference documentation as prominently; the current form post-ICON-0051 has the URL in a dedicated "Reference documentation:" line that is now visible).
- **Classification**: Minor. The skill functions without the links; a non-DataScan consumer simply cannot follow the cited reference.

#### m-U-4 — `plugin-design` description names "Claude Code plugin" while body claims plugin-agnosticism (still present from ICON-0046 m-U-net4)

- **Location**: `skills/plugin-design/SKILL.md:4` (description: "scaffold a new **Claude Code** plugin"), `:12` ("A two-mode skill for building and reviewing **Claude Code** plugins"), `:14` ("This skill is plugin-agnostic — it ships with ICON but applies to any Claude Code plugin"), `:18` ("Starting a new Claude Code plugin from an empty directory")
- **Problem**: Line 14 states "this skill is plugin-agnostic" immediately before the sentence that scopes it to "any Claude Code plugin." The claim of plugin-agnosticism is not honored — the skill covers only Claude Code plugins, not Copilot CLI plugins. The description trigger names "Claude Code plugin" which creates a narrow activation condition for Copilot CLI consumers. This is a soft ADR-004 tension and an internal consistency issue.
- **Delta from ICON-0046**: No change. ICON-0046 flagged as m-U-net4 at the same lines.
- **Classification**: Minor (the skill is internally consistent about being Claude Code-scoped; line 14's "plugin-agnostic" claim is the actual defect — a misleading generalization the body doesn't deliver).

#### m-U-5 — `characterization-testing` absent from README Internal Skills table (net-new)

- **Location**: `README.md:180-213` (Internal Skills table — lists `code-quality-rules`, `commit-discipline`, `context-document-guidelines`, and all other internal skills, but `characterization-testing` does not appear), `skills/characterization-testing/SKILL.md:1-6` (frontmatter: `user-invocable: false`, confirming it is an internal skill)
- **Problem**: The README Internal Skills table at lines 180–213 is the discoverability surface for skills that are auto-invoked rather than user-invocable. `characterization-testing` was added in ICON-0049 as `user-invocable: false` and wired into `using-skills` (Skill Priority list, Rigid skills list, new routing example). The README table was not updated. This is the same gap pattern as ICON-0046 m-U-net2 for `mcp-tools-first` (which was subsequently closed by ICON-0048). `mcp-tools-first` is also still absent from the README Internal Skills table — ICON-0048 added `user-invocable: false` to the skill's frontmatter but did not add it to the README table.
- **Classification**: Minor. Both `mcp-tools-first` and `characterization-testing` are absent from the README Internal Skills table. This is a dual instance of the same pattern.

#### m-U-6 — "plugin-lint Check A/B" labels referenced in skills with no discoverable formal definition (still present from ICON-0046 m-new-03)

- **Location**: `skills/icon-init/SKILL.md:225` ("`${VAR:-literal}` — that pattern is rejected by plugin-lint Check B"), `:245` ("`>/dev/null` is banned by plugin-lint Check A"), `skills/icon-status/SKILL.md:214` ("Triggers plugin-lint Check B")
- **Problem**: Three references to "plugin-lint Check A" and "plugin-lint Check B" as named formal catalog entries, with no canonical definition anywhere on disk. No lint tool named `plugin-lint` exists; no `## Plugin-Lint Checks` section exists in any shared doc; the pre-commit hook doesn't label its checks as "A" or "B." Maintainers or authors encountering these references have no path to the underlying rule definition.
- **Delta from ICON-0046**: No change. ICON-0046 flagged as m-new-03 at the same locations; ICON-0048's hygiene sweep listed it (O-S2) but the fix was not included in the bundle.
- **Classification**: Minor (low runtime risk; moderate maintainability cost).

---

## Improvement Opportunities

### IO-U-1 — Generalize `ecological-impact` Option-A to be runtime-agnostic (closes M-U-1)

**Effort: Low. Impact: High (correctness).**

The calculation core (Steps 2–6) is generic. The Copilot-specific coupling is entirely within Step 1 Option A. The fix requires four targeted changes:

1. Rename Option A heading from "Monthly Usage via Remaining Reqs (Preferred)" to "Monthly Usage (Preferred)" and reframe the data-gathering instruction as platform-neutral: "Ask the user to provide their monthly interaction count, or help them derive it from whatever usage dashboard their AI platform provides."
2. Add a Claude Code-specific sub-option: "For Claude Code, check the usage panel or estimate from the session-turn count."
3. Replace "GitHub Copilot Business plan" quota table with a generic "typical AI platform tiers" framing; keep values as reference examples rather than authoritative billing facts.
4. Replace "Copilot Ecological Impact Report" in the output template (`:149`) and example (`:208`) with "AI Session Ecological Impact Report" or `<platform> Ecological Impact Report`.

The description at line 4 may retain "AI/Copilot" as a compound trigger since both runtimes are explicitly named there — the violation is in the body, not the trigger.

### IO-U-2 — Add `mcp-tools-first` and `characterization-testing` to README Internal Skills table (closes m-U-5)

**Effort: Trivial. Impact: Medium.**

Two internal skills added since the last README update are absent from the Internal Skills table at `README.md:180-213`. Both are `user-invocable: false` and auto-invoked by description match. Add:

- `mcp-tools-first` — Use when about to access GitLab, Jira, or Confluence; checks for bundled MCP tools first.
- `characterization-testing` — Lock existing code behavior as characterization tests before modifying untested legacy code.

This follows the precedent the ICON-0048 fix established for `mcp-tools-first`'s frontmatter: adding the key was only half the discoverability fix; the README table entry is the second half.

### IO-U-3 — Replace live org URLs in `sprint-goals` and `rfc` with placeholder references (closes m-U-2 and m-U-3)

**Effort: Trivial. Impact: Low-Medium.**

Both skills embed live DataScan Confluence URLs that will 404 for non-DataScan consumers:

- `skills/sprint-goals/SKILL.md:20,:196` — Replace `https://onedatascan.atlassian.net/...ORG-004...` with: "See your organization's Sprint Goal Guidelines document (replace this link with your org's equivalent)."
- `skills/rfc/SKILL.md:19` — Replace the RFC-001 and General RFC Guidance live links with: "Reference documentation: [RFC Process](<!-- replace with your org's RFC process link -->) · [General RFC Guidance](<!-- replace with your org's general RFC guidance link -->)" or remove the reference line and note that org-specific process documentation should be linked in the RFC header itself.

ADR-010 m9 covers DataScan-flavored example *shapes* as Accepted (watch); these live URLs in the body prose are outside that acceptance.

### IO-U-4 — Resolve `writing-skills` line-cap self-violation by splitting `## Where Skills Live` to a companion file (closes m-U-1)

**Effort: Low. Impact: Low-Medium.**

`writing-skills/SKILL.md` now stands at 524 lines against its own "Keep SKILL.md under 500 lines" rule (line 210). The `## Where Skills Live` section (lines 79–102, ~24 lines) was the addition that pushed it back over the cap. The section is load-bearing discipline content but qualifies as the "separate files for heavy reference" pattern the skill itself defines at lines 114–115. Options:

1. Extract `## Where Skills Live` (with the decision rule and worked example) to `skills/writing-skills/skill-placement-guide.md` and reference it with a single line in SKILL.md.
2. Accept the violation and amend line 210 from a hard "under 500" to a tiered cap ("under 500 for standard skills; complex discipline skills earn every line beyond — see token-efficiency targets at line 264").
3. Audit whether any other section added after ICON-0033 could be extracted instead.

Option 1 maintains self-consistency with the existing rule; Option 2 resolves the structural tension more honestly (since `writing-skills` itself is a complex discipline skill, not a "standard skill").

### IO-U-5 — Resolve `plugin-design` "plugin-agnostic" self-contradiction (closes m-U-4)

**Effort: Trivial. Impact: Low.**

`skills/plugin-design/SKILL.md:14` claims the skill "is plugin-agnostic" in the same sentence that scopes it to "any Claude Code plugin." Pick one:

- (a) Accept the Claude Code scope: remove "plugin-agnostic" from line 14 and replace with "This skill ships with ICON but applies to any Claude Code plugin in any Claude Code consumer repo."
- (b) Deliver actual plugin-agnosticism: add a Copilot CLI plugin sub-path to the create mode and update the description at `:4` to remove "Claude Code" from the trigger.

Option (a) is the cheaper and more honest fix; Option (b) is a feature addition that would require authoring a Copilot-specific scaffold path.

### IO-U-6 — Define or eliminate "plugin-lint Check A/B" labels (closes m-U-6)

**Effort: Trivial. Impact: Low.**

Three skill references point to a labeled catalog that doesn't exist. Two clean options:

- (a) Remove the "plugin-lint Check A/B" label and replace with the plain rule citation: "banned by `shared/common-constraints.md` § Shell command self-check" (for Check A) and "required by the `${VAR+x}` presence-test pattern per ICON bash-scripting standards" (for Check B).
- (b) Define the labels formally: add a `## Plugin-Lint Checks` section to a shared document, define Check A (no `>/dev/null` in agent-invoked bash blocks) and Check B (`${VAR+x}` not `${VAR:-literal}` in presence tests), and cross-reference from both skill common-mistakes tables.

ICON-0046's O-S2 recommended option (b); option (a) requires fewer new artifacts.

---

## Utility-Skills-Specific Structural Observations

### Observation 1 — Partial-fix recurrence: `ecological-impact` ADR-004 violation is at three cycles without structural remediation

The ICON-0046 audit framed M-U-NET1 as the "third audit cycle touching the same root cause" with a different surface each time (ICON-0015 m-U-A fixed the model name; ICON-0037 fixed other literals; the Option-A Copilot product framing was never in scope for any of these fixes). In this cycle, ICON-0047 was the suggested follow-up for M-U-NET1, but it addressed `writing-skills` instead. The deeper pattern: when an audit Moderate is labeled with a suggested task ID, it does not automatically become that task's scope unless the user explicitly accepts the recommendation. The audit-report → follow-up-task handoff is informal, and scope decisions made during task planning override the audit recommendation silently.

### Observation 2 — README Internal Skills table is the persistently-late discoverability surface

The README Internal Skills table has now missed two consecutive skills added as `user-invocable: false`: `mcp-tools-first` (flagged in ICON-0046; frontmatter fixed in ICON-0048 but table still absent) and `characterization-testing` (ICON-0049; table entry never created). Every other internal skill appears in the table. The pattern suggests that when a new internal skill is wired into `using-skills`, the README table update is the step most likely to be omitted. A pre-commit check gate or a writing-skills checklist addition for the README table entry could close this recurrence.

### Observation 3 — `rfc` metadata-table rewrite (ICON-0051) is structurally clean

The ICON-0051 change — adding a mandatory metadata table as the first RFC body element — is correctly implemented at both entrypoints. The scaffold path collects all nine table fields explicitly (Step 2-S, lines 70–81); the refactor path extracts them from existing drafts with explicit `TBD` marking for absent fields (Step 2-R, lines 106–114); the ORG-004 schema at Step 3 reflects the table; the quality checklist at Step 6 enforces it at both paths; and the example file cross-reference is live. No conformance issues found.

---

## ICON-0046 Delta

### Fixed since ICON-0046

| ICON-0046 ID | Description | Closing task / evidence |
|---|---|---|
| m-U-net2 | `mcp-tools-first` missing `user-invocable` frontmatter key | ICON-0048; `skills/mcp-tools-first/SKILL.md:9` now reads `user-invocable: false` |
| m-A-NET-NEW-1 | `context-specialist.agent.md` 3-sentence description violating sub-agent 1-sentence rule | ICON-0048; CHANGELOG confirms "Trimmed agents/context-specialist.agent.md description to a single sentence" |
| m-A-NET-NEW-2 | `manager.agent.md` Discretionary heading missing `(Off Unless Explicitly Requested)` | ICON-0048; CHANGELOG confirms parenthetical added |
| m-new-01 | `context-specialist-impl-root` Step 15 verify item 4 wrong filename (`patterns-template.md`) | ICON-0048; CHANGELOG confirms corrected to `patterns.md` |
| m-P-NEW-1/2 | `keep-last-15` stale references in task-plan-phase-completion and context-maintenance | ICON-0048; CHANGELOG confirms updated to `keep-last-10` with multi-prune behavior |

### Still present or partial

| ICON-0046 ID | Current state |
|---|---|
| **M-U-NET1** | `ecological-impact` Copilot-product framing in Option-A path. No structural change since ICON-0046. Same lines flagged. Third-cycle carry-forward. Re-tiered as M-U-1 in this report. |
| m-U-net1 (word-count axis) | `writing-skills` word-count self-violation: 3,160 words against "aim for < 500 words" at `:265`. Still present. Additionally, the line-cap self-violation has re-opened at 524 lines (m-U-1 this cycle). |
| m-U-net3 | `sprint-goals` live org URL at `:20,:196`. Still present; ICON-0048 O-M5 listed it but did not fix it. Re-tiered as m-U-2 in this report. |
| m-U-net4 | `plugin-design` "plugin-agnostic" self-contradiction. Still present at `:14`. Re-tiered as m-U-4 in this report. |
| m-new-03 | "plugin-lint Check A/B" labels in `icon-init` and `icon-status` with no formal definition. Still present. Re-tiered as m-U-6 in this report. |
| m-U-net5 | `icon-audit` Quality Checklist references `writing-skills` Iron Law without on-disk RED-phase TDD evidence. Still present at `.claude/skills/icon-audit/SKILL.md:144-152`. Informational — status unchanged. |

### Net-new

1. **m-U-1 (new axis)** — `writing-skills` line-cap self-violation at 524 lines against its own rule at line 210. The prior m-U-net1 covered the word-count axis; this is the line-cap axis re-opened by ICON-0047's `## Where Skills Live` addition.

2. **m-U-3** — `rfc/SKILL.md:19` embeds live DataScan Confluence URLs for RFC-001 RFC Process and General RFC Guidance. First audit of the current `rfc` skill (post-ICON-0051 rewrite). ADR-010 m9 does not cover these reference URLs.

3. **m-U-5** — `characterization-testing` absent from README Internal Skills table. New skill (ICON-0049); table entry was never created. Plus: `mcp-tools-first` is also still absent from the README table — ICON-0048 fixed the frontmatter key but did not add the table entry. Both skills are now flagged together as one finding.
