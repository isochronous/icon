# Utility Skills Audit — Raw Findings

## Summary

Brief 04 audited 20 utility skills under `skills/` — the 16 enumerated in the brief plus `migration-planning`, `post-incident-review`, `mr-discipline`, and `plugin-audit` which live in `skills/` and were not covered by briefs 02 / 03 / 05 (verified by reading each sibling brief's `## Scope`). Post-split, the dominant new defect class is **stale `plugins/<plugin>/...` path placeholders inside `plugin-audit/SKILL.md` + `plugin-audit/briefs/*.md`** — the audit-orchestration skill that ran *this* very audit instructs Phase 1 to `ls plugins/<plugin>/agents/`, a command that returns nothing in this repo because `agents/` lives at the root. The ICON-0003 plan corrects this by passing each sub-agent a "Layout delta" table, but the skill itself is unmigrated; a future invocation without the plan-level correction will mis-baseline. A second material net-new defect: `icon-status/SKILL.md:161` suggests `/release-plugin` to end users, but `release-plugin` lives at `.claude/skills/release-plugin/` (maintainer-only, not shipped with the plugin per `plan.md` § "Maintainer-only release tooling") and is not exposed via the slash-command menu. End users following the suggestion will get "skill not found." All three Moderate findings from MKT-0087 carry forward unchanged: M-U1 (release-plugin manager-only guard) was inherited from marketplace and now lives in maintainer-only `.claude/skills/release-plugin/SKILL.md` — out of scope here per the plan's "Maintainer-only" note (delegated to brief 05); M-U2 (writing-skills "Common Workflows table" references) is unchanged at the same two line numbers; m-U8 (synthesis-template.md:122 line-coupled MKT-0046 cross-ref) is unchanged. MKT-0087 m-U6 / m-U7 (release-plugin/release-plugin-beta stale `sed` prose), m-U10 (orphan ICON-beta CHANGELOG), and m-U11 (release-plugin-beta missing argument-hint) are now ALL out-of-scope per the plan's "Inapplicable prior findings" — `release-plugin-beta` doesn't exist in this repo (no `-beta/` snapshot), and `release-plugin` is maintainer-only and owned by brief 05. m-U1 (jira-story `create` literal), m-U2 (setup-mcp Option A only), m-U3 (ecological-impact stale Sonnet 4.6 model), m-U4 (ecological-impact projection-basis mismatch), m-U5 (rfc Step 3 design-history paragraph), and m-U9 (writing-skills self-length-cap violation) all carry forward unchanged. Frontmatter parser-fragility (Pattern 5): all 20 SKILL.md files use the YAML folded-block-scalar form (`description: >`); the MKT-0078 fix is fully held. Discipline-skill shape (Rationalization Prevention + Red Flags blocks) is consistent across `dependency-management`, `code-quality-rules`, `mr-discipline`, `post-incident-review`, `migration-planning`, and `using-skills`. Token-efficiency sibling extractions (rfc/post-meeting/sprint-goals/ecological-impact) are clean post-MKT-0085 and survived the repo split intact.

## Defect Findings

### Critical

None observed.

### Moderate

**M-U1 (net-new) — `plugin-audit/SKILL.md` Phase 1 + all six briefs assume a `plugins/<plugin>/` repo layout that no longer applies.** This is the audit-orchestration skill responsible for running plugin audits; it has not been migrated since the marketplace → standalone-repo split. Its Phase 1 baseline commands will return empty or misleading results when run in this repo, leading to a wrong "Phase 1 output" record (zero agents, zero skills, zero manifests). The ICON-0003 task plan compensates by passing each sub-agent a "Layout delta vs marketplace baseline" table verbatim — but that compensation is a *task-level workaround*, not a skill-level fix. Future invocations without an analogous plan-level patch will silently mis-baseline.
- `skills/plugin-audit/SKILL.md:40` — `wc -l plugins/<plugin>/CHANGELOG.md`
- `skills/plugin-audit/SKILL.md:43-45` — `ls plugins/<plugin>/agents/ | wc -l`, `ls plugins/<plugin>/skills/`, `find plugins/<plugin> -name '*.json'`
- `skills/plugin-audit/SKILL.md:104` — auto-detect description: "look for `plugins/<plugin>/plugin.json`"
- `skills/plugin-audit/briefs/01-agents.md:5, 9, 12, 13` (4 stale refs)
- `skills/plugin-audit/briefs/02-process-skills.md:9, 12` (2 stale refs)
- `skills/plugin-audit/briefs/03-context-specialist-init.md:11, 12, 15` (3 stale refs)
- `skills/plugin-audit/briefs/04-utility-skills.md:13, 16` (2 stale refs — i.e., *this* brief still ships with the marketplace layout)
- `skills/plugin-audit/briefs/05-infrastructure.md:14-36` (14 stale refs covering every infrastructure path)
- `skills/plugin-audit/briefs/06-cross-cutting.md:15-19` (4 stale refs)

Total: 30+ stale path placeholders across `plugin-audit/`. Severity Moderate (not Critical) because the skill is still functionally usable — Phase 1 just produces zero-counts that a careful auditor would notice — and the surrounding ICON-0003 plan has already proven the workaround works.

**M-U2 (carry-forward, unchanged from MKT-0087 M-U2) — `writing-skills/SKILL.md` instructs authors to register skills in a Common Workflows table that no longer exists.** The MKT-0084 sweep dropped the Common Workflows table from `using-skills/SKILL.md`, but the registration instructions in `writing-skills` were not swept. Authors following discipline today will open `using-skills/SKILL.md`, find no table, and either silently skip the step or re-introduce the dropped table.
- `skills/writing-skills/SKILL.md:230-232` — Discoverability section: "If the skill participates in multi-skill sequences, add those sequences to the common workflows table in `skills/using-skills/SKILL.md`."
- `skills/writing-skills/SKILL.md:528-530` — Skill Creation Checklist: "[ ] Added to the common workflows table in `skills/using-skills/SKILL.md` if the skill participates in a multi-skill sequence."

Verified via grep that no Common Workflows table heading remains in `using-skills/SKILL.md` (file is 90 lines; greps for "Common Workflows" and "workflows table" return only the two `writing-skills` lines above).

### Minor

**m-U1 (carry-forward, unchanged from MKT-0087 m-U1 / MKT-0077 m-U2) — `jira-story/SKILL.md` Step 2 references the tool literal `create`.** Copilot CLI's tool is named `create`; Claude Code's equivalent is `Write`. The skill is platform-coupled in a way the rest of the plugin avoids.
- `skills/jira-story/SKILL.md:32, 35`

**m-U2 (carry-forward, unchanged from MKT-0087 m-U2 / MKT-0077 m-U3) — `setup-mcp-servers/SKILL.md` Step 3 promises "Choose one option. Option A is recommended" but only Option A is documented.** Option B never appears in the file.
- `skills/setup-mcp-servers/SKILL.md:100` — "Choose one option. Option A is recommended for most users."
- `skills/setup-mcp-servers/SKILL.md:102` — only `### Option A — Shell profile` heading exists; no `### Option B`.

**m-U3 (carry-forward, unchanged from MKT-0087 m-U3) — `ecological-impact/SKILL.md` example references `Claude Sonnet 4.6`.** Per `currentDate` 2026-05-14 and `gitStatus` showing audit on Opus 4.7, the model is stale. The skill's `formulas-reference.md` sibling does not mention models, so the staleness is confined to SKILL.md.
- `skills/ecological-impact/SKILL.md:86` — in-prose example: "(e.g., Claude Sonnet 4.6, GPT-4.1)"
- `skills/ecological-impact/SKILL.md:221` — Reference Example block: "Model: Claude Sonnet 4.6"

**m-U4 (carry-forward, unchanged from MKT-0087 m-U4) — `ecological-impact/SKILL.md` annual-projection scope mismatch.** Option A monthly path multiplies by `× 12`; Option B session-only path multiplies by `× 1,200`. Body, output template, and the Reference Example interleave the two without explicit naming, so a rendered report does not show which projection basis was used.
- `skills/ecological-impact/SKILL.md:69, 92` (formulas declaring each multiplier)
- `skills/ecological-impact/SKILL.md:129, 141` (trees-annual, water-annual formulas referencing the bound variable)
- `skills/ecological-impact/SKILL.md:157` (output-template projection line: "Projected Annual ([monthly × 12 | session rate × 1,200])")
- `skills/ecological-impact/SKILL.md:216` (Reference Example renders "(at this rate × 1,200 sessions/year)" with no explicit "Projection basis:" label)

**m-U5 (carry-forward, unchanged from MKT-0087 m-U5) — `rfc/SKILL.md` Step 3 contains a 9-line design-history paragraph mid-schema.** The `### Section-5 Resolution` provenance paragraph sits between the schema fence-block (`:120-137`) and the next subsection. Every agent reading the schema must scan past it.
- `skills/rfc/SKILL.md:139` (full paragraph)

**m-U6 (carry-forward, unchanged from MKT-0087 m-U8) — `synthesis-template.md:122` still cites `MKT-0046 audit-report.md:343-345`.** This is the residual line-coupled MKT-reference the MKT-0085 9619eb9 sweep missed; it survived the repo split unmodified. Per `writing-skills/SKILL.md:274-282` (C2 sweep guidance), line-coupling is brittle — line numbers drift.
- `skills/plugin-audit/synthesis-template.md:122`

**m-U7 (carry-forward, unchanged from MKT-0087 m-U9) — `writing-skills/SKILL.md` exceeds its own self-imposed length cap.** Section "Token Efficiency" (`:235-241`) says "Frequently-loaded skills: aim for < 200 words; Standard skills: aim for < 500 words; Keep SKILL.md under 500 lines." Current `writing-skills/SKILL.md` is **549 lines / 3,262 words** — over both the line cap and the word target by ~10× on the word target. Self-reference soft observation per MKT-0087 disposition (user-groomed deferral).
- `skills/writing-skills/SKILL.md:185, 239-241` (rules) vs. total file length (549 lines).

**m-U8 (net-new) — `icon-status/SKILL.md:161` suggests `/release-plugin` to end users, but the skill is not user-facing in this repo.** The release skill lives at `.claude/skills/release-plugin/SKILL.md` (maintainer-only working directory, not shipped). End users running `/icon-status` who see this suggestion and try `/release-plugin` will hit "skill not found." The marketplace baseline had this suggestion working because `plugins/ICON/skills/release-plugin/` was shipped; the post-split repo no longer ships it. Either remove the suggestion, gate it on "is this the ICON maintainer repo," or restore release-plugin to `skills/` (a brief 05 question, but the *symptom* surfaces here in `icon-status`).
- `skills/icon-status/SKILL.md:161` — `"- CHANGELOG [Unreleased] section is empty but $COMMITS_SINCE commits exist since $LAST_TAG — consider /release-plugin."`

**m-U9 (net-new, minor) — `post-incident-review/SKILL.md:123` cross-references a local copy of `append-retrospective-entry.{sh,ps1}` "for direct use when delegation is unavailable."** The files exist at `skills/post-incident-review/scripts/append-retrospective-entry.{sh,ps1}` (verified via `ls`). However, the `context-maintenance` skill (the canonical "maintenance mode" path) also owns an authoritative copy via `@context-specialist` routing. This creates a 2-location source-of-truth concern for the same script: if the canonical script evolves, the `post-incident-review/scripts/` copy must be hand-synced. Not a defect today (both copies match), but a Pattern A sweep-incompleteness risk (see Structural Observations).
- `skills/post-incident-review/SKILL.md:123` (cross-reference)
- `skills/post-incident-review/scripts/append-retrospective-entry.sh`, `.ps1` (the embedded copies)

**m-U10 (net-new, cosmetic) — `start-worktree/SKILL.md:87, 91, 111, 162` still document a `.claude/claude.md` vs `.github/copilot-instructions.md` fallback for "not yet migrated" repos.** Per CHANGELOG `[1.15.0]` (MKT-0089) the `claude.md` redirect is now a standard part of upgrade-repo / init flow, and `[1.15.2]` mentions "running merge-phase-templates first when customized." The "not yet migrated" framing is becoming dated. Minor — the language is defensive-correct (the fallback DOES still apply for legacy repos) — but it adds reading friction. Could collapse to "the canonical instructions file" once the marketplace-era legacy population shrinks.
- `skills/start-worktree/SKILL.md:87, 91, 111, 162`

## Improvement Opportunities

Minimum 3 required; 6 below. Effort/Impact tags follow the same scale as MKT-0087.

**IO-U1 · Migrate `plugin-audit` skill to standalone-repo layout.** Closes M-U1. Replace every `plugins/<plugin>/` in `plugin-audit/SKILL.md` and all six `briefs/*.md` with either (a) repo-root paths (`agents/`, `skills/`, `CHANGELOG.md`) — appropriate if `plugin-audit` is now ICON-specific — or (b) a templated `${PLUGIN_ROOT}` variable defaulting to `.` for the standalone case and `plugins/<plugin>/` for the marketplace case. Option (a) is the safe path; the skill *defaults to the ICON plugin* per `SKILL.md:104` and there is no current evidence of cross-plugin reuse. Sweep should also touch `briefs/04-utility-skills.md:13, 16` so the next ICON audit doesn't need a plan-level translation table. **Effort: medium (regex sweep across 8 files + one synthesis-template touch).** **Impact: medium (closes the only Moderate-tier net-new finding; makes the audit skill self-sufficient for future runs).**

**IO-U2 · Sweep `writing-skills` registration instructions.** Closes M-U2 (carry-forward from MKT-0087). Two edits at `writing-skills/SKILL.md:230-232` and `:528-530`: drop the Common Workflows table clause; replace with "If the skill participates in a multi-skill sequence, document the sequence in the consuming agent's workflow section (manager Workflow Orchestration, product-manager Workflow) rather than in `using-skills`." **Effort: trivial (5-line edit).** **Impact: low (closes a silent-failure authoring action — rare invocation surface, but the fix is so cheap that letting it carry forward a third audit cycle is the more expensive choice).**

**IO-U3 · Refresh `ecological-impact` to current model + add explicit projection-basis annotation.** Closes m-U3 + m-U4 in one pass. Replace `Claude Sonnet 4.6` with `Claude Opus 4.7 (1M context)` at `:86, :221`; add a single explicit line in the Reference Example: `Projection basis: monthly × 12` or `session × 1,200 sessions/year` based on which path was taken. **Effort: trivial.** **Impact: low (cosmetic), but closes two recurring Minors in one PR.**

**IO-U4 · Decide `icon-status:161` release-plugin suggestion policy.** Closes m-U8. Three viable approaches: (a) remove the suggestion entirely (cleanest, but loses the maintainer's own dashboard cue); (b) gate the suggestion behind a heuristic (e.g., only emit if `git remote get-url origin` matches a known ICON-maintainer URL pattern); (c) ship `release-plugin` to consumer repos (a brief-05 decision, but if accepted, m-U8 evaporates). The plan-level "Inapplicable prior findings" note already treats `release-plugin` as out-of-scope for this audit's defect tier — so option (a) or (b) is preferable here. **Effort: trivial (1-line edit) for (a); medium for (b); architectural for (c).** **Impact: medium (removes a user-visible broken suggestion).**

**IO-U5 · Consider rfc + post-meeting + sprint-goals → `org-004-document` consolidation (case study).** Per the brief's MKT-0061 case study (`rfc-format` + `rfc-refactor` → `rfc`), look for the next-tier consolidation candidate. `rfc`, `post-meeting`, and `sprint-goals` all (a) target ORG-004 outputs, (b) share the same audience (cross-functional stakeholders without Jira access), (c) produce structured markdown with a quality checklist, (d) all extract some form of "what happened / what was decided / what action items remain" content. Differences are real (rfc is forward-looking decision documentation; post-meeting is backward-looking conversational extraction; sprint-goals is calendared status reporting), so this is NOT the strong-form consolidation the rfc case study demonstrates. **Effort: high (would require designing a branching entrypoint that selects mode by input type — transcript vs. CSV vs. draft).** **Impact: low-to-medium (token-economics gain modest; consolidation forces a single canonical ORG-004 schema that currently differs subtly across the three skills).** Recommend deferring; record as a watch-pattern. The cleaner near-term consolidation is the IO-U1 migration of `plugin-audit` away from `plugins/<plugin>/` paths.

**IO-U6 · Extract or canonicalize `append-retrospective-entry.{sh,ps1}` source of truth.** Closes m-U9. The script is currently shipped both inside `post-incident-review/scripts/` and (per the cross-reference at `:123`) "owned by `@context-specialist` maintenance mode" elsewhere. Two clean options: (a) reference only the maintenance-mode canonical copy and remove the local copies (clean SSOT); (b) make `post-incident-review/scripts/` the SSOT and have `@context-specialist` resolve it via skill-path lookup. The plugin's "Skills Cannot Share Scripts" rule (per CHANGELOG MKT-0070) blocks (a); so option (b) — or a lint check that diffs the two — is the only viable closer. **Effort: low (lint script) to medium (refactor canonical location).** **Impact: low (current copies match; risk is future drift).**

## Utility-Skills-Specific Structural Observations

**Pattern A — sweep-incompleteness across the marketplace → standalone split.** The repo-split commit moved every file but the `plugin-audit` skill's internal references (path placeholders) were not updated to match the new layout. This is exactly the same sweep-incompleteness pattern MKT-0087 Pattern A documented for `writing-skills` (MKT-0084 dropped a table; instructions to write to that table remained) and `synthesis-template.md:122` (MKT-0085 dropped two of three line-coupled MKT-refs; one remained). The class is the same: **a sweep visits the primary surface but stops short of companion files** — companion briefs, companion scripts, companion templates. The plugin's standing `.context/standards/plugin-structure.md` "Skill Evolution Cross-Surface Sweep" rule (referenced by MKT-0087 Pattern A) should be extended to explicitly enforce "skill-folder is the sweep unit, not SKILL.md."

**Pattern B — `plugins/<plugin>/...` is now a strong drift signal.** Any new occurrence of this path prefix inside the standalone repo (outside of `plugin-audit`, which is intentionally template-shaped) signals stale content. A one-line `git grep` lint in a future plugin-lint pass would catch this class instantly. All 19 non-`plugin-audit` utility skills are clean on this check — only `plugin-audit/SKILL.md` and its briefs surfaced any matches.

**Pattern C — frontmatter parser-fragility (Pattern 5 from brief): no instances.** All 20 SKILL.md files use `description: >` folded block scalar. Verified by inspecting the first 7 lines of each file. MKT-0078 fix is fully held through the repo split. Of note: three of the user-facing skills (`jira-story`, `sprint-goals`, `post-meeting`) have descriptions containing the literal `Note: ` colon-space pair plus inline `[bracketed]` content — exactly the strings that broke MKT-0078-era plain scalars. The folded-block-scalar choice is doing its load-bearing work.

**Pattern D — caller-listing in description (Pattern 3 from brief).** Skills with explicit callers (`code-quality-rules`, `context-document-guidelines`, `manager-routing-guide`, `mr-discipline`, `using-skills`) all carry `user-invocable: false`. The "internal X skill. Do not invoke without explicit direction." caller-listing convention used by context-specialist sub-skills is NOT applied here — these are general-purpose internal skills invoked by multiple agents (e.g., `code-quality-rules` is invoked by `@reviewer`; `mr-discipline` is invoked by `@coder` and `@reviewer`; `manager-routing-guide` is invoked by `@manager`). The descriptions name triggering conditions instead of callers, which is correct per `writing-skills:142-160` (descriptions describe triggers, not callers, for non-restricted skills). No defect; convention applied correctly. The single exception is `manager-routing-guide/SKILL.md:4` which DOES use the "Internal manager skill. Do not invoke without explicit direction." pattern — appropriate because it is in fact manager-only.

**Pattern E — operational defensiveness (Pattern 4 from brief).** The user-facing utility skills are either read-only (`icon-status`), idempotent (`icon-init` with `--force`; `setup-mcp-servers` is instructional only), or content-rendering (`jira-story`, `post-meeting`, `rfc`, `sprint-goals`, `ecological-impact` — no state mutation). `start-worktree` mutates git state but uses `git worktree` operations that are themselves idempotent on second-call. `migration-planning` and `post-incident-review` are advisory only — no scripts that mutate state outside the retrospective-append helper. No operational-defensiveness gaps observed in this scope. The release-skill defensiveness gap (M-U1 from MKT-0087) lives in maintainer-only `.claude/skills/release-plugin/` and is out-of-scope per the plan.

**Pattern F — self-reference (Pattern 1 from brief).** Two skills self-violate:
- `writing-skills/SKILL.md` exceeds its own length cap (m-U7, soft observation).
- No other instances. `code-quality-rules`, `mr-discipline`, `dependency-management`, `migration-planning`, `post-incident-review`, `using-skills` all carry the discipline-skill shape they themselves prescribe (Rationalization Prevention + Red Flags STOP list); each is internally consistent.

**Pattern G — template / standard cross-reference (Pattern 2 from brief).** MKT-0087 noted `agent-evaluation/SKILL.md:40` carved out Anti-Rationalization tables and cross-referenced `.context/standards/anti-rationalization-tables.md`. CHANGELOG `[1.15.1]` records the *removal* of that path reference because the standard is not distributed with the plugin; the carveout was made self-contained. Verified at `agent-evaluation/SKILL.md:40` — the path is gone and the carveout text is self-contained. The fix from MKT-0087 (well after MKT-0087's audit date) is held. The standing template / standard cross-references in this scope are: `migration-planning:24-26` (refs `dependency-management` and `code-quality-rules`), `post-incident-review:26` (refs `systematic-debugging`), `using-skills:71-76` (refs all major process skills), `writing-skills:18` (refs `testing-discipline`). All cross-references use the skill-name-only convention prescribed by `writing-skills:274-282` — no path-coupled or `@`-prefixed refs.

**Pattern H — `plugin-audit` ownership extends across all six briefs.** Of the 30+ stale `plugins/<plugin>/` references, every one lives inside the `plugin-audit/` skill tree (SKILL.md, briefs/, synthesis-template.md). No utility skill outside `plugin-audit` is affected. The locality is good news for IO-U1: a single skill-folder sweep closes the entire defect class.

## MKT-0087 Delta

### Fixed since MKT-0087

- **`agent-evaluation/SKILL.md:40` carveout path** (out-of-band fix in `[1.15.1]`) — verified self-contained; no reference to `.context/standards/anti-rationalization-tables.md` remains.
- **YAML folded-block-scalar mandate held** across the repo split — all 20 in-scope SKILL.md files use `description: >`. No regression from the split.
- **Token-efficiency sibling extractions survived the split** — `rfc/examples/notification-service-email.md`, `post-meeting/examples/{sprint-planning,sprint-retrospective}.md`, `sprint-goals/examples/{start-of-sprint,mid-sprint,end-of-sprint}.md`, `ecological-impact/formulas-reference.md` all present and reachable via relative-path refs from their parent SKILL.md.
- **`using-skills` upstream-pattern adoption held** — `<SUBAGENT-STOP>` (`:8-10`), `<EXTREMELY-IMPORTANT>` (`:12-18`), Rationalization Prevention table (`:36-53`), Red Flags STOP list (`:55-65`) all present. Common Workflows table verified absent.
- **Discipline-skill shape uniform** across `dependency-management` (`:91, :101`), `code-quality-rules` (`:80, :93`), `mr-discipline` (`:75, :87`), `post-incident-review` (`:143, :155`), `migration-planning` (`:130`), `using-skills` (`:36, :55`).

### Still present or partial

- **M-U2** — `writing-skills/SKILL.md:230-232, :528-530` still instruct authors to register in the dropped Common Workflows table. Unchanged across MKT-0087 → ICON-0003. This is the third audit cycle in which a trivial-effort sweep would close a known finding.
- **m-U1** — `jira-story/SKILL.md:32, 35` `create` literal — unchanged (third cycle).
- **m-U2** — `setup-mcp-servers/SKILL.md:100, 102` Option A only — unchanged (third cycle).
- **m-U3** — `ecological-impact/SKILL.md:86, 221` `Claude Sonnet 4.6` — unchanged (currentDate now 2026-05-14, the staleness window is widening).
- **m-U4** — `ecological-impact/SKILL.md` projection-basis mismatch — unchanged.
- **m-U5** — `rfc/SKILL.md:139` Step 3 design-history paragraph — unchanged.
- **m-U8 (MKT-0087) / m-U6 (here)** — `synthesis-template.md:122` MKT-0046 line-coupled cross-reference — unchanged.
- **m-U9 (MKT-0087) / m-U7 (here)** — `writing-skills/SKILL.md` self-length-cap soft violation (549 lines, 3262 words) — unchanged from MKT-0087's 549 / 3262.

### Out-of-scope this audit (per plan's "Inapplicable prior findings")

These MKT-0087 findings targeted artifacts that did not migrate to the standalone repo or that brief 05 owns. They are not "fixed"; they were never *applicable* here:

- **MKT-0087 M-U1** — `release-plugin` / `release-plugin-beta` manager-only guard (carry-forward from MKT-0063). `release-plugin` is at `.claude/skills/release-plugin/` (maintainer-only, not shipped); `release-plugin-beta` doesn't exist post-split. Brief 05 owns. Out-of-scope here.
- **MKT-0087 m-U6** — `release-plugin/SKILL.md:258` stale `sed` Error Conditions row. Owned by brief 05.
- **MKT-0087 m-U7** — `release-plugin-beta/SKILL.md:94` stale `sed` prose. Skill doesn't exist post-split.
- **MKT-0087 m-U10** — orphan `plugins/ICON-beta/CHANGELOG.md`. No `ICON-beta/` snapshot in this repo.
- **MKT-0087 m-U11** — `release-plugin-beta` missing `argument-hint`. Skill doesn't exist post-split.

### Net-new

- **M-U1** (Moderate) — `plugin-audit/SKILL.md` + all six briefs assume marketplace `plugins/<plugin>/` layout; 30+ stale path placeholders. Compensated for this audit by the ICON-0003 plan's "Layout delta" table, but the skill itself is unmigrated.
- **m-U8** (Minor) — `icon-status/SKILL.md:161` suggests `/release-plugin` but the skill is maintainer-only / not shipped. End users get "skill not found."
- **m-U9** (Minor) — `post-incident-review/SKILL.md:123` cross-references both a local copy and a `@context-specialist` canonical copy of `append-retrospective-entry.{sh,ps1}` — 2-location source-of-truth risk per the "Skills Cannot Share Scripts" rule (CHANGELOG MKT-0070).
- **m-U10** (Minor, cosmetic) — `start-worktree/SKILL.md` "not yet migrated" framing for the `.claude/claude.md` vs `.github/copilot-instructions.md` fallback is becoming dated post-MKT-0089.

### Audit-process observation

Two structural observations carry forward from MKT-0087 with reinforced evidence: (1) the **sweep-incompleteness pattern** (Pattern A) now has a third concrete instance — the repo-split sweep visited the file-system layout but stopped at SKILL.md primary surfaces, leaving `plugin-audit/briefs/` and `plugin-audit/synthesis-template.md` unmigrated. The recommended escalation is to elevate the "Skill Evolution Cross-Surface Sweep" standard from SKILL.md-only to skill-folder-as-unit; the current scope has now demonstrably missed the same class of supporting-file in three separate audit cycles. (2) The same M-U2 / m-U1 / m-U2 / m-U3 / m-U4 / m-U5 carry-forwards from MKT-0077 → MKT-0087 → ICON-0003 (three consecutive cycles) signal these are accepted-risk-with-deferred-fix items rather than active defects; the audit synthesis pass should consider re-tiering them to "watch / accepted" rather than re-surfacing them as Minors a fourth time. The new defect class for ICON-0003 — split-driven path drift inside `plugin-audit` — is genuinely new and is the higher-leverage Tier-2 fix.
