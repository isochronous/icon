# Utility Skills Audit — Raw Findings

**Auditor:** ICON-0015 sub-agent (Brief 04)
**Scope audit:** `agent-evaluation`, `rfc`, `post-meeting`, `sprint-goals`, `jira-story`, `setup-mcp-servers`, `ecological-impact`, `writing-skills`, `start-worktree`, `post-incident-review`, `plugin-audit` (self-audit), `release-plugin` (maintainer-only)
**Prior baseline:** ICON-0003 (2026-05-14, v1.15.3)
**Plugin version inspected:** v1.15.4 (+ current [Unreleased] block)

---

## Summary

The utility-skills domain is in materially better shape than ICON-0003. All seven Moderate/Minor items that ICON-0003 closed via follow-up tasks (M-U1, M-U2, M-1, M-2) are confirmed fixed on disk. Three prior-audit minors remain as carry-forwards: `jira-story`'s Copilot-CLI-specific `create` tool reference, `ecological-impact`'s stale "Claude Sonnet 4.6" model example, and the `start-worktree` "not yet migrated" phrasing. One net-new moderate defect was surfaced: all six `plugin-audit` briefs still contain the unfilled `<path-to-prior-audit-report.md>` placeholder that ICON-0004's sweep left untouched, making the Prior-Audit Pointer unusable on every dispatch without a task-level workaround. One net-new minor defect: `writing-skills:495` references `TaskCreate`, a Copilot-CLI-only tool not available in Claude Code. Token-efficiency is largely healthy after MKT-0085's example extractions, with one outlier: `writing-skills` remains at 549 lines / 3,271 words against its own 500-line / 500-word self-imposed caps. Internal consistency is the stronger concern this cycle — the brief placeholder defect, the stale model name, and the tool-name ambiguity are all instances of content that was correct at authorship and has not tracked the runtime environment.

---

## Defect Findings

### Critical

None observed.

### Moderate

#### M-U-A: `plugin-audit` briefs all contain unfilled `<path-to-prior-audit-report.md>` placeholder

All six dispatch briefs (`01-agents.md` through `06-cross-cutting.md`) carry the same Inputs line:

```
- Prior audit pointer: `<path-to-prior-audit-report.md>` — specifically the <Domain> sections
```

ICON-0004 swept `plugins/<plugin>/` path strings across SKILL.md and the briefs, but did not resolve this template-style placeholder to the actual audit-report path. As a result, every future plugin-audit invocation requires the dispatching manager to inject a translation or the sub-agents will not be able to locate the prior-audit report — exactly the problem M-U1 described in ICON-0003. The ICON-0003 retrospective (`.context/retrospectives.md:28`) explicitly named this class: "validate that enumerated inputs in companion files still resolve in the new layout."

The canonical path is: `.context/tasks/<LAST-AUDIT-ID>-plugin-audit/audit-report.md`. The briefs should contain a specific path (or a standard discovery command such as `ls .context/tasks/*/audit-report.md | sort | tail -1`) rather than an angle-bracket placeholder.

**Files:**
- `skills/plugin-audit/briefs/01-agents.md:10`
- `skills/plugin-audit/briefs/02-process-skills.md:10`
- `skills/plugin-audit/briefs/03-context-specialist-init.md:13`
- `skills/plugin-audit/briefs/04-utility-skills.md:14`
- `skills/plugin-audit/briefs/05-infrastructure.md:35`
- `skills/plugin-audit/briefs/06-cross-cutting.md:16`

**Risk:** Every next plugin-audit invocation dispatches six sub-agents without a usable prior-audit pointer unless a workaround is added to the plan.md. This is the same active defect class that M-U1 described — just at a different depth of the same skill folder.

### Minor

#### m-U-A: `ecological-impact` example cites stale model name "Claude Sonnet 4.6"

Two locations reference "Claude Sonnet 4.6" as an example model name:
- `skills/ecological-impact/SKILL.md:86` — "Note the model if known (e.g., Claude Sonnet 4.6, GPT-4.1)"
- `skills/ecological-impact/SKILL.md:221` — reference example block: `⚡ Model: Claude Sonnet 4.6 | ...`

Per the brief, the current model lineup is Claude 4.7 / 4.6 / Haiku 4.5. The example at line 221 is used as the canonical output format reference; an agent following it will produce stale output. The text at line 86 is a parenthetical suggestion — lower urgency but still misleading. This carry-forward from ICON-0003 (m-U3) is still present.

**Files:** `skills/ecological-impact/SKILL.md:86`, `skills/ecological-impact/SKILL.md:221`

#### m-U-B: `jira-story` uses `create` tool literal — Copilot-CLI-specific, not portable to Claude Code

Lines 32 and 35 instruct the agent to "Call the `create` tool to write the story." In Claude Code the equivalent tool is `Write`; `create` is a Copilot-CLI tool name. A Claude Code agent executing this skill will either fail silently (no `create` tool) or invent a fallback — neither is the intended path. This carry-forward from ICON-0003 (m-U1) is still present.

**Files:** `skills/jira-story/SKILL.md:32`, `skills/jira-story/SKILL.md:35`

#### m-U-C: `start-worktree` retains "not yet migrated" phrasing — dated post-MKT-0089

Three locations in start-worktree use `(.github/copilot-instructions.md if not yet migrated)` as a qualifier on the canonical `.claude/claude.md` path:
- `skills/start-worktree/SKILL.md:87` — Step 3 confirmation block
- `skills/start-worktree/SKILL.md:111` — Step 5 context re-read bullet
- `skills/start-worktree/SKILL.md:162` — Common Mistakes rationalization row

MKT-0089 (v1.15.0) shipped the modern `.claude/claude.md` redirect as the standard; the "not yet migrated" qualifier was accurate when the skill was written but misleads agents about the current expected state. The CHANGELOG at `CHANGELOG.md:72` shows this was addressed in context-specialist-impl-leaf and upgrade-repo but not swept to start-worktree. This carry-forward from ICON-0003 (m-U10) is still present.

**Files:** `skills/start-worktree/SKILL.md:87`, `skills/start-worktree/SKILL.md:111`, `skills/start-worktree/SKILL.md:162`

#### m-U-D (net-new): `writing-skills:495` references `TaskCreate` — Copilot-CLI-only tool

The Skill Creation Checklist at line 495 says:

```
**Use `TaskCreate` to track each phase.**
```

`TaskCreate` is a Copilot-CLI tool not available in Claude Code. A Claude Code agent following the checklist cannot comply with this instruction. The self-reference violation check requires the skill to follow its own rules (Common Check Pattern 1); `writing-skills` instructs authors to be "platform-agnostic" in tool names yet uses a platform-specific tool here. The fix is to either name both tools (`TaskCreate` in Copilot CLI, `TodoWrite`/task-tracking in Claude Code) or use a generic verb ("track each phase in your task tracker").

**File:** `skills/writing-skills/SKILL.md:495`

#### m-U-E (net-new): `setup-mcp-servers` says "Choose one option" but only Option A is documented

Step 3 header says "Choose one option. Option A is recommended for most users" at line 100, implying an Option B exists. No Option B is present in the skill. This carry-forward from ICON-0003 (m-U originally for setup-mcp-servers) was not closed. Either Option B (e.g., per-session `export` commands or a `.env`-based approach) should be documented, or the introductory framing should be revised to remove the multi-option hint.

**File:** `skills/setup-mcp-servers/SKILL.md:100-102`

#### m-U-F (carry-forward, still present): `rfc:139` design-history paragraph interrupts mid-schema

Immediately following the closing ` ``` ` of the ORG-004 Output Schema (Step 3) is a block of design rationale explaining the Section-5 Operationalization ⊇ Security decision and naming predecessor skills (`rfc-format`, `rfc-refactor`). This paragraph is useful context for authors of the `rfc` skill, but it interrupts the step flow: a user reading Step 3 to apply the schema sees legacy-resolution prose before Step 4. The design history belongs in a `## Design Notes` appendix or a companion file — not mid-schema. This carry-forward from ICON-0003 (m-U5) is still present.

**File:** `skills/rfc/SKILL.md:139`

#### m-U-G (carry-forward): `writing-skills` exceeds its own length cap — self-reference violation

The skill states "Keep SKILL.md under 500 lines; split into supporting files past that" at line 185 and "Standard skills: aim for < 500 words" at line 240. The current file is 549 lines and 3,271 words — both figures exceed the cap. This is the defining self-reference violation (Common Check Pattern 1). The skill demonstrates the anti-pattern it warns against. This carry-forward from ICON-0003 (O-T3) is still present.

**File:** `skills/writing-skills/SKILL.md:185`, `skills/writing-skills/SKILL.md:240` (cap definitions); full file is 549 lines / 3,271 words.

#### m-U-H (carry-forward): `release-plugin` Step 1 does not guard against "not a git repo"

Step 1 of `release-plugin/SKILL.md` runs `git --no-pager branch --show-current` and `git --no-pager status --short` without first checking that the CWD is a git repository. In a freshly checked-out environment, both commands may produce misleading output or fail silently. This carry-forward from ICON-0003 (m-7) is still present. Note: `release-plugin` is maintainer-only at `.claude/skills/release-plugin/` — operational risk is low since the skill is only invoked by the plugin maintainer, but a one-line guard (`git rev-parse --is-inside-work-tree || { echo "Not a git repo."; exit 1; }`) would eliminate false-positive confusion.

**File:** `.claude/skills/release-plugin/SKILL.md:31`

#### m-U-I (carry-forward): `synthesis-template.md:122` external reference to MKT-0046 audit report cannot be resolved from this repo

The synthesis template's `Audit-process observation` section contains:

```
See the MKT-0046 audit-report.md (in the upstream marketplace repo) for the precedent that gave rise to plugin-audit itself.
```

ICON-0004 improved this from a line-coupled path reference to a prose description, but the reference is still unresolvable from the standalone ICON repo. A reader or agent following the link cannot access the marketplace repo. The precedent value is already encoded in the plugin-audit SKILL.md overview and the consolidated `rfc` skill (MKT-0061 case study in the brief). This is a partial fix — the line coupling is gone but the dead external reference remains.

**File:** `skills/plugin-audit/synthesis-template.md:122`

#### m-U-J (carry-forward): `post-incident-review` scripts SSOT risk — two copies of append-retrospective-entry scripts

`skills/post-incident-review/scripts/append-retrospective-entry.{sh,ps1}` are byte-identical to `skills/task-retrospective/scripts/append-retrospective-entry.{sh,ps1}` (verified via `diff`). The SSOT risk: if `task-retrospective`'s copy is updated (e.g., for a format change), the `post-incident-review` copy silently drifts. Unlike the common-constraints block (which now has a pre-commit hook enforcing byte-equality), there is no automated guard here. This carry-forward from ICON-0003 (m-U9) is still present.

**Files:** `skills/post-incident-review/scripts/append-retrospective-entry.sh` vs `skills/task-retrospective/scripts/append-retrospective-entry.sh` (currently identical; drift risk on next edit)

#### m-U-K (carry-forward): `release-plugin` format-slack.sh lacks strict-mode header

`.claude/skills/release-plugin/scripts/format-slack.sh` runs without `set -euo pipefail`. Errors in any of the five `sed` pipeline stages will be silently swallowed — the script will output a malformed Slack message and exit 0. The release-plugin Step 9 treats "Slack: posted successfully" (from the `curl && echo` tail) as evidence the message was well-formed, but does not verify that the formatter itself succeeded. This carry-forward from ICON-0003 (m-4) is still present.

**File:** `.claude/skills/release-plugin/scripts/format-slack.sh:1-4`

---

## Improvement Opportunities

### IO-U1: Replace unfilled `<path-to-prior-audit-report.md>` placeholder in all six briefs with a discovery command

**Effort: trivial. Impact: high.**

Replace the placeholder at `briefs/0{1-6}.md` with a standard discovery command that sub-agents can run:

```bash
ls .context/tasks/*/audit-report.md | sort | tail -1
```

Alternatively, the Phase 1 preamble written to `plan.md` already includes the prior audit ID; the briefs could instruct sub-agents to "read plan.md § Phase 1 Baseline Preamble for the prior-audit path." Either approach eliminates the manager workaround. This closes M-U-A and is the single highest-leverage trivial fix in this domain.

### IO-U2: Trim `writing-skills` to its own word cap — extract the Skill Creation Checklist to a sibling file

**Effort: low. Impact: medium.**

`writing-skills/SKILL.md` is 549 lines / 3,271 words against its own 500-line / ~500-word caps. The Skill Creation Checklist (lines 493–531, ~430 words) is a structured checklist that benefits from offline reference rather than inline reading — it is precisely the kind of content the skill's own "Separate files for heavy reference" rule targets. Extracting it to `writing-skills/skill-creation-checklist.md` and replacing the inline content with a one-line cross-reference would bring the SKILL.md under 500 lines and close m-U-G (self-reference violation).

### IO-U3: Standardize ecological-impact model name as a placeholder, not a specific version string

**Effort: trivial. Impact: medium.**

Replace the hardcoded `Claude Sonnet 4.6` at lines 86 and 221 with `[current default model]` (or equivalent). Model names will continue to advance; a placeholder forces the agent to insert the actual model in use at report time rather than copying a stale string. This closes m-U-A and prevents the same issue from reappearing after the next model generation.

### IO-U4: Decide the policy on `icon-status:161` `/release-plugin` suggestion and act on it

**Effort: trivial. Impact: medium.**

`icon-status:161` emits `consider /release-plugin` to end users when CHANGELOG [Unreleased] is non-empty, but `release-plugin` is maintainer-only at `.claude/skills/release-plugin/` and is not shipped to consumers. Three options:
- (a) Drop the `/release-plugin` suggestion from `icon-status` Signal 2 — replace with no suggestion or a generic "consider tagging a release."
- (b) Keep the suggestion but gate it behind a heuristic (e.g., check whether `.claude/skills/release-plugin/SKILL.md` exists before emitting the suggestion).
- (c) Re-examine whether `release-plugin` should be shipped to consumers.

Option (a) is recommended — `release-plugin` is intentionally maintainer-only post-split, and the suggestion misleads consumers. This deferred item from ICON-0003 (m-U8) has a trivial fix.

**File:** `skills/icon-status/SKILL.md:161`

### IO-U5: Introduce a pre-commit script parity test for the two append-retrospective-entry script copies

**Effort: low. Impact: medium.**

The `.githooks/pre-commit` hook already enforces byte-equality for common-constraints across agents. The same pattern applies to the two copies of `append-retrospective-entry.{sh,ps1}`: add a two-line diff check to the pre-commit hook:

```bash
diff skills/task-retrospective/scripts/append-retrospective-entry.sh \
     skills/post-incident-review/scripts/append-retrospective-entry.sh \
  || { echo "append-retrospective-entry.sh drift detected"; exit 1; }
```

This converts the SSOT risk (m-U-J) from a periodic audit finding into a commit-time gate. Closes m-U-J.

### IO-U6: Resolve the `jira-story` tool-name ambiguity with a conditional or runtime-agnostic instruction

**Effort: trivial. Impact: medium.**

Rather than naming `create` (Copilot CLI) or `Write` (Claude Code) directly, replace lines 32 and 35 with a runtime-agnostic instruction: "Use the file-write tool available in your runtime (Write in Claude Code, create in Copilot CLI) to write the story." Alternatively, follow the `writing-skills` recommendation to keep skills self-contained and simply say "write the file using your available file-write tool." Closes m-U-B without requiring a platform split.

### IO-U7: Extract the `rfc` design-history paragraph to a `## Design Notes` appendix

**Effort: trivial. Impact: low.**

Move `rfc/SKILL.md:139` (the Section-5 resolution block naming `rfc-format` and `rfc-refactor` as predecessors) to a new `## Design Notes` section at the end of the file. The schema definition (Step 3 closing ` ``` `) then flows directly into Step 4 without interruption. The design history is valuable context for contributors — it simply belongs after the operational content. Closes m-U-F.

---

## Utility-Skills-Specific Structural Observations

### Observation 1: Companion-file coverage is the sweep gap, not SKILL.md itself

ICON-0004 successfully swept `plugins/<plugin>/` path strings across `plugin-audit/SKILL.md` and all six briefs. What it did not resolve: the template-style `<path-to-prior-audit-report.md>` placeholder in the same briefs. The ICON-0003 retrospective explicitly named this failure mode ("validate that enumerated inputs still resolve"), yet it recurred. The pattern: a sweep that targets a specific string pattern (stale paths) will not catch unfilled template placeholders, which use a different syntactic shape (`< >`). Any future sweep of companion files should include a pass for angle-bracket placeholders as a separate grep: `grep -rn '<[a-z-]' skills/plugin-audit/briefs/`.

### Observation 2: `writing-skills` is the only utility skill whose self-reference violation is architectural

Every other self-reference violation in this domain is a string-level stale reference (model name, tool name, path placeholder). `writing-skills` exceeds its own word and line counts at an architectural level — the checklist it requires authors to use is itself the largest single block contributing to the overflow. This creates a perverse incentive: following the skill's own rules (thorough checklist) worsens its primary quality metric (line count). The correct fix is extraction (IO-U2), not editing the checklist down.

### Observation 3: All three token-efficiency wins from MKT-0085 held

`post-meeting`, `sprint-goals`, and `rfc` all have their worked examples in `examples/` sibling directories, confirmed on disk. `ecological-impact` has `formulas-reference.md` as a sibling. These extractions are holding — no regression of heavy content back into SKILL.md was observed.

---

## ICON-0003 Delta

### Fixed since ICON-0003

- **M-U1 (plugin-audit skill unmigrated)** — FIXED by ICON-0004. All `plugins/<plugin>/` path references replaced with repo-root paths in SKILL.md, all six briefs, and synthesis-template.md. Phase 1 baseline commands now produce non-zero counts without a plan-level translation table. `skills/plugin-audit/SKILL.md:34` now reads `ls .context/tasks/*/audit-report.md`.

- **M-U2 (writing-skills registration instructions pointing at dropped using-skills Common Workflows table)** — FIXED by ICON-0009. The Discoverability section (`:230-232`) and Skill Creation Checklist (`:528-530`) now redirect to `README.md` skills table and consuming agent workflow sections respectively. No `using-skills` table registration instruction is present.

- **M-1 (release-plugin Step 5 CHANGELOG-shape conflict)** — FIXED by ICON-0010. `release-plugin/SKILL.md:105-108` now describes the correct "rename `[Unreleased]` to `[X.Y.Z]`, insert fresh empty `[Unreleased]` above" procedure, matching `workflows/changelog.md:11`. No longer says "insert new entry below `[Unreleased]`."

- **M-2 (release-plugin Error Conditions row references sed directly)** — FIXED by ICON-0010. Error Conditions table at `release-plugin/SKILL.md:263` now references `bump-versions.sh` and `git diff .claude-plugin/plugin.json` verification, not a raw `sed` call.

- **m-U3 (ecological-impact:86 example uses stale model)** — PARTIALLY FIXED / STILL PRESENT. See m-U-A below.

- **agent-evaluation:SKILL.md reference to .context/standards/anti-rationalization-tables.md** — FIXED in v1.15.1 (CHANGELOG:66). Verified absent.

### Still present or partial

- **m-U3 / m-U4 (ecological-impact model name + multiplier annotation)** — Still present at `SKILL.md:86` (model example) and `SKILL.md:221` (reference block). The multiplier annotation issue (m-U4) has been partially addressed: line 68 now says "Annual projection uses × 12 (12 months), not × 1,200" and line 92 separately defines `annual_multiplier = 1,200 # 100 sessions/month × 12 months`. The basis annotation is now explicit on line 68; however, the reference example at line 216 still uses `× 1,200 sessions/year` without inline basis. Tiered as m-U-A (model name only; multiplier annotation partially resolved).

- **m-U5 (rfc:139 design-history paragraph mid-schema)** — Still present. Re-filed as m-U-F.

- **m-U1 / jira-story Copilot-CLI `create` tool** — Still present at lines 32 and 35. Re-filed as m-U-B.

- **m-U10 / start-worktree "not yet migrated" framing** — Still present at lines 87, 111, 162. Re-filed as m-U-C.

- **m-U8 / icon-status:161 `/release-plugin` suggestion** — Still present. Confirmed deferred per user directive in this cycle; re-filed as IO-U4 for action in next cycle.

- **m-U9 (post-incident-review scripts SSOT risk)** — Still present but not regressed; both copies remain byte-identical. Re-filed as m-U-J.

- **m-7 (release-plugin Step 1 no git-repo guard)** — Still present. Re-filed as m-U-H.

- **m-4 (format-slack.sh no strict mode)** — Still present. Re-filed as m-U-K.

- **m-U7 (writing-skills exceeds own length cap)** — Still present (549 lines / 3,271 words). Re-filed as m-U-G.

- **m-U2 (setup-mcp-servers "Choose one option" implies Option B)** — Still present at line 100-102. Re-filed as m-U-E.

- **synthesis-template.md:122 external MKT-0046 reference** — Partially improved (ICON-0004 removed the line-coupled path; it now reads "in the upstream marketplace repo"). External reference is still unresolvable from this repo. Re-filed as m-U-I.

### Net-new

- **M-U-A: All six plugin-audit briefs contain unfilled `<path-to-prior-audit-report.md>` placeholder** — Not present as a distinct defect in ICON-0003 (M-U1 addressed path strings; this placeholder uses a different syntactic form). ICON-0004 swept path strings but did not resolve template placeholders. Tiered Moderate because it makes the Prior-Audit Pointer section non-functional on every dispatch. Files: all six `skills/plugin-audit/briefs/0*.md`.

- **m-U-D: `writing-skills:495` references `TaskCreate` (Copilot-CLI-only)** — Not flagged in ICON-0003. Consistent with the user's focus on internal consistency across runtimes.
