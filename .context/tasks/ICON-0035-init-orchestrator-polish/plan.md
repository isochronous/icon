## Task: ICON-0035
## Branch: feature/ICON-0035-init-orchestrator-polish
## Objective: Sweep the init + context-resolution chain to close the revised set of audit findings from GitLab issue #20 (O-S5, O-S6+m10, m3, m5, m9, m-new-A). Also document the two won't-fix decisions (m1 via existing ADR-007, m4 via new ADR-009) and prune Common Check Pattern 3 from the plugin-audit briefs so the next audit cycle doesn't re-flag them.
## Folder: .context/tasks/ICON-0035-init-orchestrator-polish/

## Decisions

- **Source ticket**: GitLab issue #20 — author revisions captured in 2026-05-22 comment; issue body rewritten to match revised scope on 2026-05-22.
- **O-S5 primitive placement (SUPERSEDED — see next bullet)**: ~~The shared entry-point detection primitive lives inside `context-specialist-detect-tree-position/SKILL.md` (per user directive on issue #20 — "put it in the skill, not in .context"), NOT in `context_template/context/workflows/`. The three init orchestrators retain inline bash but each block gains a `# CANONICAL: see ... — keep in sync` cross-reference comment. The architecture spec deliberately kept inline bash (rather than `source`-ing a snippet file) to preserve the read-and-execute contract — the skill is documentation; sourcing a file would introduce a runtime dependency consumer repos would inherit.~~ Maintainer feedback post-MR-open (2026-05-22): keeping the inline bash defeats the single-source goal — there are still 6 copies that drift independently. Revised below.
- **O-S5 primitive placement (REVISED, 2026-05-22 post-MR feedback)**: The orchestrators no longer carry the inline detection conditional. Each of the six bash blocks (three detection-form, three verification-form) is replaced with a prose-level instruction directing the agent to apply the canonical Entry-Point Detection Primitive defined in `context-specialist-detect-tree-position/SKILL.md`. The primitive's bash text exists in exactly one place — the skill. The orchestrators contain higher-level loop scaffolding plus a prose-level "apply the primitive here" reference. True single-source: when the detection rule changes, only the skill needs updating.
- **O-X3 deferred**: `disable-model-invocation: true` propagation to five `context-specialist-impl-*` skills is OUT of scope for this PR. User reports prior testing showed agents could not invoke the skills when the flag was set; this needs a reproducible test before any propagation. Tracked as deferred — a separate ticket should be filed if/when the regression is reproducible.
- **m1 won't-fix already documented**: ADR-007 (`devnull-ban-scope`, 2026-05-21) already establishes that the `2>/dev/null` ban is agent-invoked-only and does not apply to autonomous scripts including `context_template/context/workflows/*.sh`. `prune-context.sh` is in scope of the carve-out. No further code changes for m1; the ADR-pointer added to all 5 audit briefs (see brief edits below) makes ADR-007 a required pre-tier consultation for future audit cycles.
- **m4 won't-fix → ADR-009**: User: "what is the purpose of listing callers? It just takes up context for no value." Captured as a new ADR (ADR-009 — `skill-description-callers`) and the Common Check Pattern 3 ("Caller-listing in description") is removed from all five `plugin-audit/briefs/*.md` files. The briefs gain a new `## ADR / Decision-Log Pointer` H2 section between Prior-Audit Pointer and Forward-Looking Improvements Mandate, byte-identical across all 5 briefs (md5 `432c89f7081ca320a1c9746ae4109ce7`).
- **m9 → Generalize (Q2 resolution)**: Architect chose angle-bracketed placeholders (`<service-a>`, `<service-b>`, `<your-webapp>`, `<workspace>`, `<resource-folder>`). Example tables collapsed from 11/4/2 rows to 2–3 rows; the "mixed types in one repo" hint preserved.
- **m3 + Q3 resolution (REVISED, 2026-05-22 post-MR feedback)**: `find-context-template` PowerShell separators normalized to `/` (both Copilot CLI variant at lines 41-42 AND Claude Code variant at line 54 — coder caught the line 54 residue via Gate G7's empty-grep requirement; line 54 was not in the original spec enumeration but is consistent with m3 intent). `MARKETPLACE_NAME` default stays `datascan-marketplace` — this plugin ships pre-configured to resolve under DataScan's marketplace, the canonical install path. The renames to `your-marketplace` in the first commit are reverted. Re-configurability is supported via `$MARKETPLACE_NAME` env var (overrides default) or by maintainers editing the default line in their fork; surrounding comments make the override mechanism explicit so forkers know where to change it.
- **m5 + Q1 resolution**: Schema example annotated inline (`// canonical; falls back to ...`) rather than forked into a second example. Keeps the schema example terse.
- **m-new-A + Q4 resolution**: Single-token replacement at `:336` (`copilot-instructions.md` → `.claude/claude.md`). Surrounding prose not rewritten.
- **Pattern renumber + Q5 resolution**: Common Check Patterns renumbered 4→3, 5→4 (not "leave a gap"). Pre-flight confirmed zero inline backrefs by number, so the renumber is mechanically safe within the briefs. Historical research files in `.context/tasks/ICON-0003-*/` and `.context/tasks/ICON-0015-*/` were NOT touched (they describe what was applied at audit time).
- **ADR Pointer placement + Q6 resolution**: New H2 `## ADR / Decision-Log Pointer` section placed between `## Prior-Audit Pointer` and `## Forward-Looking Improvements Mandate` in all 5 briefs (uniform structure, no special-cased brief).
- **Gate G13 substitute**: `.claude/skills/release-plugin/scripts/plugin-lint.sh` does not exist in this standalone repo (per ICON-0003 research note: "did not migrate" from marketplace). Coder substituted with JSON-parse validation across all 5 plugin JSON files. Reviewer accepted the substitute as preserving gate intent.
- **Plan format**: per `.context/workflows/task-plan/base.md` (template-version 1.1).
- **Branch shape**: `feature/ICON-NNNN-short-description` per branching.md convention.

## Key Files

### Sub-task O-S5 (entry-point detection primitive)
- `skills/context-specialist-detect-tree-position/SKILL.md`: new canonical-primitive section.
- `skills/initialize-monorepo/SKILL.md:147,:255`: replace inline bash with cross-ref.
- `skills/initialize-workspace/SKILL.md:154,:261`: replace inline bash with cross-ref.
- `skills/initialize-multimodule/SKILL.md:148,:316`: replace inline bash with cross-ref.

### Sub-task O-S6 + m10 (Phase 3 sampling spec extraction)
- `skills/upgrade-repo/SKILL.md:338` (Phase 3): inline the precise sampling spec.
- `skills/initialize-monorepo/SKILL.md:230-232`: replace with one-line cross-ref.
- `skills/initialize-workspace/SKILL.md:237-239`: replace with one-line cross-ref.
- `skills/initialize-multimodule/SKILL.md:289-291`: replace with one-line cross-ref.

### Sub-task m3 (find-context-template separator literal)
- `skills/find-context-template/SKILL.md:34,:42`: normalize bash + PowerShell to `/` separators (or document divergence).

### Sub-task m5 (resolve-repo-context schema fallback)
- `skills/resolve-repo-context/SKILL.md:99,:121`: schema example shows or annotates the `.claude/claude.md` → `.github/copilot-instructions.md` fallback rule.

### Sub-task m9 (generalize examples)
- `skills/initialize-monorepo/SKILL.md:72,:123-133,:159,:355`
- `skills/initialize-workspace/SKILL.md:64-65,:138-139,:326`
- `skills/initialize-multimodule/SKILL.md:160-161,:363`
- `skills/context-specialist-impl-root/SKILL.md:64`

### Sub-task m-new-A (workspace MR template stale ref)
- `skills/initialize-workspace/SKILL.md:336`: replace `copilot-instructions.md` with `.claude/claude.md` (matching the parallel `initialize-multimodule:400` template).

### Won't-fix documentation
- `.context/decisions/009-skill-description-callers.md`: NEW ADR — skill descriptions do not enumerate callers.
- `.context/decisions/README.md`: add ADR-009 row to the Decision Log table.
- `skills/plugin-audit/briefs/01-agents.md` § Common Check Patterns: remove Pattern 3; add ADR-consultation step.
- `skills/plugin-audit/briefs/02-process-skills.md` § Common Check Patterns: same.
- `skills/plugin-audit/briefs/03-context-specialist-init.md` § Common Check Patterns: same.
- `skills/plugin-audit/briefs/04-utility-skills.md` § Common Check Patterns: same.
- `skills/plugin-audit/briefs/05-infrastructure.md` § Common Check Patterns: same.

### Plan and artifacts
- `.context/tasks/ICON-0035-init-orchestrator-polish/plan.md`: this file.
- `.context/tasks/ICON-0035-init-orchestrator-polish/architecture.md`: architect spec (803 lines, 13 acceptance gates).
- `CHANGELOG.md`: `[Unreleased]` entry added on close (via `changelog-entry` skill).
- `.context/retrospectives.md`: retro entry on close (via `task-retrospective` skill).

## Progress

- [x] Confirm user revisions to issue #20 acceptance criteria
- [x] Create branch and task folder
- [x] Write plan.md (this file)
- [x] Update GitLab issue #20 description with revised body (user-confirmed; updated_at 2026-05-22T19:26:06Z)
- [x] Pre-flight Explore: verified all sub-task file/line citations match `main`; surfaced 6 open questions for architect; confirmed inverse-phrasing sweep and three-surface rule clear
- [x] Architect dispatch: produced 803-line `architecture.md` with all 6 open questions resolved (Q1–Q6) and 13 verbatim acceptance gates G1–G13
- [x] Coder dispatch: all 8 sub-tasks landed; all 13 gates passed (G13 via JSON-parse substitute); 4 out-of-spec deviations reported and justified; changes staged
- [x] Reviewer pass: verdict APPROVED, zero Critical, zero Moderate, 3 Minor (all spec-prescribed or trivial cosmetics — not gated). All 4 deviations ACCEPTED; all 5 risk axes PASS; independent frontmatter parse-test on 8 files OK
- [x] Step-0 reconcile plan.md against final state
- [x] Task retrospective (manager Stage 1 + @context-specialist Stage 2)
- [x] CHANGELOG `[Unreleased]` entry via changelog-entry skill
- [x] Commit all artifacts (source, .context updates, plan.md, architecture.md) — commit e0ef3cb
- [x] Push branch + open MR — !19 (https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/merge_requests/19)
- [x] Post-MR feedback round 1 received: MARKETPLACE_NAME default needs revert; O-S5 single-source defeated by inline-bash + comment shape
- [x] Fix-up: revert MARKETPLACE_NAME default + add re-config doc — `datascan-marketplace` restored across all 4 sites in `find-context-template`; override comment added inline at each default-setting line
- [x] Fix-up: O-S5 true single-source refactor — inline bash conditionals removed from 6 sites across 3 orchestrators; replaced with prose-level instructions referencing `context-specialist-detect-tree-position` § "Entry-Point Detection Primitive (callable)"; canonical bash exists in exactly one place now
- [x] Reviewer pass on fix-ups — one Moderate (multimodule Step 6 missing `.context/domains/` from verification — fixed in follow-up haiku-coder pass)
- [x] Cumulative-effect CHANGELOG edits + plan.md re-reconcile + issue #20 + MR #19 description updates ← IN PROGRESS
- [ ] Commit fix-ups + push

## Open Questions / Blockers

- **O-X3 follow-up ticket**: not created in this task. Filing left to maintainer discretion once a reproducible test for the `disable-model-invocation: true` regression is available.
- **Reviewer Minor #1** (`context-specialist-detect-tree-position/SKILL.md:96-98`): spec-prescribed prose says "the snippet below" but snippets are above. Cosmetic; deferred to a future polish pass to avoid round-tripping for a one-word fix.
- ~~**Reviewer Minor #3** (`find-context-template` default rename): the `your-marketplace` default produces a `$TEMPLATE_DIR` that does not exist; out-of-the-box discovery fails until `MARKETPLACE_NAME` is set. Intentional per Q3 — consumer-facing signal that this plugin requires marketplace configuration. Worth confirming downstream skills surface a clear error if asked to follow up.~~ Resolved by fix-up round: default reverted to `datascan-marketplace`; OOB discovery works against the canonical marketplace.

## Constraints

- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- Per ADR-007: do not propose stripping `2>/dev/null` from `context_template/context/workflows/*.sh` (autonomous-script carve-out).
- Per ADR-004 (tool-agnostic content): example generalization must not introduce DataScan/.NET/WMS or any organization-specific names.
- Per `.context/standards/skill-decomposition/process-sweeps.md` (Process Doc Sweep / three-surface rule): any change to `.context/workflows/<doc>.md` must also land in `context_template/context/workflows/<same path>` and `skills/<phase>/SKILL.md`. This task does not touch those workflow surfaces but reviewer should verify the rule still holds.
- Per ICON-0026 retro precedent: when an existing standard borders new content, cross-reference rather than duplicate. ADR-009 should reference ADR-007's framing (both are scope carve-outs) without restating it.
- Per ICON-0030/0032/0033 retro precedent: pre-flight Explore must use `character-grade` instructions — not just "list matches" but "characterize each match against the revised acceptance criteria."
- Per ICON-0027 retro: sweep tasks need an inverse-phrasing sweep — when Pattern 3 is removed from briefs, also grep for any other location (`audit-report.md`, `research/*.md`, etc.) that re-instantiates "list callers" as a defect class.
- Per ICON-0014 retro (renumber-aware backref): if Pattern numbering shifts (Patterns 4, 5 currently sit below the removed Pattern 3), audit each brief for inline backrefs to "Pattern 3" / "Pattern 4" / "Pattern 5" before declaring done.
