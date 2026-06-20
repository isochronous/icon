# Cross-Cutting Audit — Raw Findings

## Summary

The standalone-repo split landed cleanly across the five domain investigations: no domain reported critical regressions, both MKT-0087 Criticals (CC-C1 + CC-C2) are confirmed fixed and survived the split (see Brief 03 at `research/03-context-specialist-init.md:5` and `:134-135`), and the verdict has moved from MKT-0087's POOR/release-blocking to **GOOD with one Moderate doc-conflict and a recurring carry-forward plateau**. Net delta against MKT-0087: −2 Critical, two new in-scope Moderates (M-U1 plugin-audit unmigrated paths from Brief 04 at `research/04-utility-skills.md:15-26`; M-1 release-plugin SKILL.md ⇄ workflows/changelog.md doc conflict from Brief 05 at `research/05-infrastructure.md:17-18`), and a stable Moderate plateau across the agents and process domains (M-A1/M-A2/M-A3 carry-forwards in Brief 01; M-P1/M-P2 carry-forwards in Brief 02). The dominant cross-cutting concerns are (1) **token-economics drift**: the 9× common-constraints duplication (~216 lines, Brief 01 M-A2 at `research/01-agents.md:18`) is now compounded by ~6,955 words of always-loaded agent + shared-constraint text and a 90-line `using-skills` mandate that fires unconditionally on every dispatcher invocation; (2) **a sweep-incompleteness pattern** that now has three concrete instances (Brief 04 Pattern A at `research/04-utility-skills.md:90`); (3) **a recurring meta-finding** that the `plugin-audit` skill itself was missed by the marketplace → standalone migration — the audit-orchestration tooling is template-shaped against the old layout (Brief 04 M-U1 at `research/04-utility-skills.md:15-26`); and (4) **a retrospective signal**: 6 of the last 16 marketplace retro entries name the same failure class — "sweep visits primary surface, stops short of companion files" (see Retrospective Pattern Analysis). The onboarding surface is healthy but thin: 1 README + 4 commands and no `GETTING_STARTED.md`/`BEST_PRACTICES.md`, with `icon-status:161` carrying a user-facing broken suggestion to `/release-plugin` (Brief 04 m-U8 at `research/04-utility-skills.md:62-63`).

## Defect Findings

Per brief's "cite by reference; do not duplicate domain findings" instruction, cross-cutting defects are systemic patterns visible only across briefs — not domain defects re-listed.

### Critical

None observed. The repo split was non-destructive for every domain investigated.

### Moderate

**M-CC1 · Sweep-incompleteness is a recurring pattern with cross-domain visibility, not a one-off authoring miss.** The marketplace → standalone split moved every file but stopped at SKILL.md primary surfaces — the same failure class that produced MKT-0087's `writing-skills` Common-Workflows-table-removal residue (Brief 02 M-P1-adjacent, Brief 04 M-U2 at `research/04-utility-skills.md:28-32`) and `synthesis-template.md:122` line-coupled MKT-0046 residue (Brief 04 m-U6 at `research/04-utility-skills.md:56-57`). Three concrete instances now share the same shape:
- Brief 04 M-U1 (`research/04-utility-skills.md:15-26`): `plugin-audit/SKILL.md` + all 6 briefs still use `plugins/<plugin>/...` paths — 30+ stale placeholders missed by the split sweep.
- Brief 02 M-P2 (`research/02-process-skills.md:27-34`): `task-plan-phase-completion:46, :80-81` still routes `.context/` writes directly while `task-retrospective:104-109` routes through @context-specialist — the empirical resolution (ICON-0001 used the specialist path per `.context/retrospectives.md:6-9`) never made it onto disk.
- Brief 05 M-1 (`research/05-infrastructure.md:17-18`): `release-plugin/SKILL.md:105-108` "insert" vs `workflows/changelog.md:11` "rename" — the workflow doc is the operationally-correct copy (v1.15.3 release evidence) but SKILL.md is the diverged one. ICON-0001 retro flagged this and shipped without filing the follow-up (`.context/retrospectives.md:9`).

Scope: systemic (process). Risk: each carrier defect is individually Moderate, but the pattern signals that the standing `.context/standards/plugin-structure.md § "Skill Evolution Cross-Surface Sweep"` rule (referenced in CHANGELOG `[1.13.3-beta.6]` MKT-0065) is enforced at SKILL.md scope, not skill-folder scope. The rule itself needs widening, or the next refactor will produce a fourth instance.

**M-CC2 · The `plugin-audit` skill is the only audit-orchestration tool the plugin ships, and it is broken against its own current repo layout — a self-verification posture problem.** Documented at Brief 04 M-U1 (`research/04-utility-skills.md:15-26`). The ICON-0003 task plan compensates via a "Layout delta vs marketplace baseline" translation table (`.context/tasks/ICON-0003-plugin-audit/plan.md:43-59`), but that workaround is plan-level, not skill-level — future invocations without an analogous plan-level patch will silently mis-baseline (Phase 1 returns zero counts on the marketplace-shaped commands at `skills/plugin-audit/SKILL.md:40-45`). The meta-finding: the very tool used to surface this audit's findings cannot find itself; the audit-orchestration discipline has no automated self-test gate beyond the audit it ran here. Scope: systemic (self-verification). Tied to M-CC1 (same sweep-incompleteness pattern) but distinct because the affected surface is the *audit infrastructure itself* — a higher-leverage trim than any individual carry-forward.

### Minor

**m-CC1 · Onboarding-surface gap — no `GETTING_STARTED.md` / `BEST_PRACTICES.md` and `commands/*.md` are the sole entry points beyond README.** The plan-level note ("There is no `GETTING_STARTED.md` or `BEST_PRACTICES.md` in this repo (those were never split out)") is correct — these files were marketplace-only and the new repo onboards exclusively through `README.md` (246 lines) + 4 `commands/*.md` files. The README's "What do you want to do?" intent index at `README.md:34-49` is well-shaped, but the 4 commands are all **Claude-Code-only role/hook commands** (`disable-manager-default`, `enable-manager-default`, `manager`, `pm`); none of them index the plugin's *content* (skills, agents, workflows). A first-time Copilot CLI user installing ICON has zero slash-command entry points beyond the implicit `/icon-init` (which is a *skill*, not a command — visible via the `## Skills` table at `README.md:147-205` only after they read the README). Scope: systemic (discoverability). Risk: low; the README index does most of the heavy lifting, and the skill catalog is searchable via Claude Code's `/help` surface — but the asymmetry between "the README has 10 entry rows" and "the `commands/` directory has 4 commands all gated on Claude Code" is worth noting.

**m-CC2 · `icon-status:161` ships a broken suggestion (`/release-plugin`) to end-user consumers — discoverability defect of the M-CC2 class.** Documented at Brief 04 m-U8 (`research/04-utility-skills.md:62-63`). `release-plugin` lives at `.claude/skills/release-plugin/SKILL.md` (maintainer-only, not shipped per `research/05-infrastructure.md:79`). End users running `/icon-status` who follow the suggestion will get "skill not found." Scope: systemic (discoverability — UI text references a non-shipped artifact). Carries the same root cause as M-CC2: the `release-plugin` skill *was* shipped in the marketplace under `plugins/ICON/skills/`; the post-split move to `.claude/skills/` is invisible to `icon-status`.

**m-CC3 · CHANGELOG retains marketplace `plugins/ICON/...` paths inside historical release notes** (verified by `grep -n 'plugins/ICON' CHANGELOG.md | wc -l` returning >40 hits in the `[1.13.3-beta.*]` and `[1.14.0]` blocks — see e.g. `CHANGELOG.md:51, :52, :68, :74-96`). This is **correct historical preservation** — those entries record changes that did, in fact, touch `plugins/ICON/...` paths at the time — but the same prefix is the lint signal Brief 04 Pattern B (`research/04-utility-skills.md:92`) names as "a strong drift signal post-split." A future `git grep "plugins/ICON"` lint would need to either exclude CHANGELOG by path or accept ~40 known historical hits. Scope: systemic (informational). Recording so a future lint design doesn't trip on the historical text.

## Improvement Opportunities

Minimum 3 required per brief; 7 below, organized by the 5 standard synthesis categories.

### Token Efficiency

**IO-CC1 · Token-economy trim: single-source the common-constraints inclusion.** Brief 01 M-A2 (`research/01-agents.md:18`) quantified the 9× duplication at ~216 lines / 9 byte-identical blocks (SHA `b3ac3bff…ade885`). At ~354 words for the shared file, the always-loaded duplicate surface is ~3,186 words (9 × 354) of byte-identical text. Closing this reclaims ~192 lines / ~2,832 words from the always-loaded baseline. Closure is structural: either (a) loader-time inclusion (the design decision Brief 01 IO-1 names), (b) pre-commit-hook substitution at distribution time, or (c) just accept the duplication and trim the *content* of `shared/common-constraints.md` instead. **Effort: medium · Impact: high.** Pairs with Brief 01 IO-1.

**IO-CC2 · Audit the always-loaded surface end-to-end.** Manager (`agents/manager.agent.md`, 288 lines / 3,951 words) + product-manager (`agents/product-manager.agent.md`, 268 lines / 2,650 words) + 1 of 7 sub-agents per task (avg ~135 lines / ~1,500 words) + `shared/common-constraints.md` (21 lines / 354 words, 9× = ~3,186 words duplicated) + `using-skills/SKILL.md` (90 lines / ~1,100 words, mandate-loaded on every dispatcher session) = **~10,000+ words of always-or-near-always-loaded text per dispatcher session**, of which ~32% is the common-constraints duplication. A formal inventory + trim pass (start with M-A2, then look at common-constraints content itself for "earn your place" tightening) is a low-effort token-economy win. **Effort: medium · Impact: high.** Net-new at cross-cutting scope.

### Discoverability

**IO-CC3 · Add a single `commands/index.md` (or expand `README.md § "What do you want to do?"`) to inventory all user-invocable slash commands across Copilot CLI + Claude Code.** Closes the m-CC1 onboarding gap. Today the 4 `commands/*.md` are Claude-Code-only role-switching commands; the user-invocable *skills* (`/icon-init`, `/icon-status`, `/setup-mcp-servers`, `/upgrade-repo`, `/plugin-audit`, `/icon:pm`, `/icon:manager`) are scattered across the README skills table. A single index that distinguishes "slash commands" from "user-invocable skills" — or merges them, since both surface as `/<name>` invocations to the user — would clarify what a first-time installer can actually type. **Effort: trivial (one new file or a 10-row addition to `README.md:38-49`).** **Impact: medium (onboarding clarity for Copilot CLI users).**

**IO-CC4 · Fix or gate the `icon-status:161` `/release-plugin` suggestion** (closes m-CC2 / Brief 04 m-U8). Three options at Brief 04 IO-U4 (`research/04-utility-skills.md:82`). Recommend option (a) — drop the suggestion entirely — since `release-plugin` is by-design maintainer-only post-split and a runtime detection heuristic for "is this the maintainer repo?" is over-engineered for a 1-line suggestion. **Effort: trivial.** **Impact: medium (removes a user-visible broken suggestion).**

### Consolidation

**IO-CC5 · Promote `.context/standards/plugin-structure.md § "Skill Evolution Cross-Surface Sweep"` from SKILL.md scope to skill-folder scope.** The standing rule (referenced in CHANGELOG `[1.13.3-beta.6]` as MKT-0065 promotion) currently treats SKILL.md as the sweep unit; the M-CC1 evidence (3 concrete instances) shows companion files — briefs, scripts, templates, retro-noted follow-ups — are routinely missed. A 5-line rule extension naming "skill-folder is the sweep unit" + a one-line grep lint (`git grep -l plugins/<plugin>/ skills/`) wired into `.githooks/post-commit` (or a new pre-commit hook) closes the recurrence vector. **Effort: low (rule extension + lint script).** **Impact: high (prevents the next instance of the same defect class).** Tied to the M-CC1 systemic pattern.

### Missing Skills

**IO-CC6 · Consider a `release-plugin-maintainer` orientation skill or a `MAINTAINING.md` for the standalone repo.** Post-split, the release flow is invisible to consumers (correct, per design) but also unprotected by the plugin's audit infrastructure — Brief 05 Structural Observation at `research/05-infrastructure.md:79` notes "the audit-skill, `plugin-audit`, scans the shipped plugin only — `.claude/skills/release-plugin/` was added to this audit's scope by explicit brief override." A maintainer-facing orientation surface that documents the release flow, the doc-conflict between `changelog.md:11` and `release-plugin/SKILL.md:105-108` (M-1), and the M-CC2 self-verification gap would be a coherent home for these concerns. Could also live as a `.context/workflows/release-flow.md` aimed at maintainers, not consumers. **Effort: low-to-medium (one new file).** **Impact: medium (codifies maintainer-only knowledge that today lives partly in retros and partly in the bare `.claude/skills/release-plugin/` skill).**

### Self-Verification

**IO-CC7 · Wire a `plugins/<plugin>/` lint gate that catches the M-CC1 / M-CC2 / m-CC3 class at commit time, not at audit time.** A 4-line bash script run by `.githooks/post-commit` (or a new pre-commit) that does `git diff --cached --name-only | xargs -I{} grep -l 'plugins/<plugin>\|plugins/ICON' {} | grep -v '^CHANGELOG\.md$'` and exits 1 if any match is found in a skills/, agents/, or briefs/ path would have caught every instance of the 30+ stale placeholders Brief 04 M-U1 names. Closes the self-verification gap M-CC2 names — the plugin gains an automated check that "the repo's own discipline is being applied to its own files." **Effort: trivial (4-line shell script + hook wire-up).** **Impact: high (closes the dominant net-new drift vector from the split).** Pairs with Brief 05 O-2 (manifest-schema validator on the same hook).

## Token Economics Analysis

**Always-loaded surface, dispatcher session (manager or product-manager invocation):**

| Surface | Lines | Words | Always loaded? | Trim candidate? |
|---------|-------|-------|----------------|------------------|
| `agents/manager.agent.md` OR `product-manager.agent.md` | 288 / 268 | 3,951 / 2,650 | Yes — one of two per session | Modest — already lean; ~12 AR rows reviewable |
| `shared/common-constraints.md` (shared file) | 21 | 354 | Yes — referenced by every agent | No — already the canonical short form |
| Inlined common-constraints (9× duplicate in each agent file) | 24 × 9 = 216 | ~3,186 total | Yes — present in each loaded agent file | **YES — M-A2 / IO-CC1 closes ~192 / ~2,832 words** |
| `skills/using-skills/SKILL.md` (mandate, dispatcher-only post-MKT-0084) | 90 | ~1,100 | Yes — manager Step 1 + PM mandate force-load | Modest — already MKT-0084-scoped |
| `skills/manager-routing-guide/SKILL.md` (manager on-demand) | n/a (not measured) | n/a | On-demand only per `manager.agent.md:123` | n/a |
| One dispatched sub-agent body (avg) | ~135 | ~1,500 | Yes per dispatch (1 of 7) | n/a — task-driven |

**Top-3 trim candidates by leverage:**

1. **M-A2 common-constraints 9× duplication (Brief 01).** ~2,832 words always-loaded, 100% redundancy. IO-CC1 closes it; medium effort, high impact. **Largest single trim.**
2. **PM Session Start asymmetry with manager (Brief 01 m-A4/m-A5 at `research/01-agents.md:28-29`).** Cosmetic but the m-A4 fix adds two lines (restoring symmetry); the m-A5 fix removes four lines (reordering). Net wash to slightly negative. Not a trim leverage.
3. **`writing-skills/SKILL.md` self-length-cap violation (Brief 04 m-U7 at `research/04-utility-skills.md:59-60`).** 549 lines / 3,262 words against a 500-line self-imposed cap. Reading-time-only (this is a flexible skill, not always-loaded), but the cap is self-stated. Closure is a tightening pass, not a structural change. Modest impact.

**`using-skills` mandate scoping (MKT-0084):** Verified in place. Brief 04 cites the scope at `research/04-utility-skills.md:117` ("`using-skills` upstream-pattern adoption held"); manager carries it at `agents/manager.agent.md:32`; PM carries it at `agents/product-manager.agent.md:16`; the 7 sub-agents do NOT (verified by `grep -n "using-skills" agents/*.agent.md | grep -v manager | grep -v product-manager` returning empty). MKT-0084's scoping intervention is fully held — the mandate fires on dispatcher invocation only, not on every sub-agent dispatch. This is the right place to be.

**Net token-economics verdict:** The single largest always-loaded trim is M-A2 (common-constraints 9×). Everything else is sub-percent. The MKT-0084 sub-agent scoping is already paying back; the next leverage pass is structural (IO-CC1 / IO-CC2) not editorial.

## Discoverability UX Analysis

**Entry points (sole onboarding surface, per plan's explicit note that GETTING_STARTED/BEST_PRACTICES were not split out):**

1. **`README.md` (246 lines).** Carries the 10-row "What do you want to do?" intent index (`README.md:34-49`), an Installation section (`:51-90`), Default-Role docs (`:92-112`), Project Context overview (`:114-143`), the skills table split into 20 user-invocable + 26 internal (`:145-205`), MCP server docs (`:207-220`), and Workflow + Multi-project sections (`:222-247`).
2. **`commands/*.md` (4 files, all Claude-Code-only).** `disable-manager-default`, `enable-manager-default`, `manager`, `pm`. All four are role/hook commands; none surface plugin *content* (skills, agents, workflows).
3. **`/icon-init` and `/icon-status`** (slash-skills, user-invocable). `icon-init` auto-detects repo type and dispatches; `icon-status` orients the user in an existing repo.
4. **No `GETTING_STARTED.md`, no `BEST_PRACTICES.md`.** Per plan's explicit note (`.context/tasks/ICON-0003-plugin-audit/plan.md:69`), neither file was ever split out.

**Where a new user trips:**

1. **Copilot CLI user, post-install, no role-switching commands available** — the 4 `commands/*.md` are gated on Claude Code per their description text. A Copilot CLI user reading the README's `## Default Role` heading at `:92` sees "(Claude Code only)" and has no parallel onboarding path. The compensation is "interact with `@manager` and `@product-manager` directly as agents" (`README.md:112`), but this isn't itself a slash command — it's a per-message `@`-mention.
2. **First-time skill discoverability is README-table-only.** The 20-row user-invocable table at `README.md:149-170` is the primary surface. There is no `/help` / `/list-skills` slash command. The 4-row `## Internal Skills` table at `:172-205` (26 skills) helpfully separates author-facing from runtime-only — that split is the MKT-0094 win and survived the split.
3. **`icon-status:161` suggests `/release-plugin` to consumers** — broken (m-CC2). The dashboard cue is well-intended but points at a maintainer-only skill that was de-shipped at the split.
4. **The README skill table is alphabetical** (verified by reading the table). For 20 user-invocable skills, this is fine; for the 26-row internal table it scales poorly for "which skill do I edit if I want to change behavior X." Not a defect; an opportunity for the catalog-reorganization IO-CC3 names.

**Net discoverability verdict:** README + intent-index is doing most of the heavy lifting and doing it well; the 4 commands are well-scoped but cover only role-switching. The single concrete defect is m-CC2 (broken `/release-plugin` suggestion). Opportunity IO-CC3 (`commands/index.md` or README-index expansion) is the next-leverage fix.

## Retrospective Pattern Analysis

**This repo:** 1 retrospective entry (`.context/retrospectives.md:1-9`) covering ICON-0001 (migrate marketplace `.context/`) and ICON-0002 (prune-script TTL fix + rename). Both are single-task retros, not pattern-level. Notable: the ICON-0001 entry at line 9 explicitly names the M-1 release-plugin doc conflict as a deferred follow-up that was never filed — Brief 05 surfaces it as the dominant Moderate.

**Pre-split history (marketplace `.context/retrospectives.md`, 16 entries):** The pre-split retro log carries 6 entries that name the **same failure class — "sweep visits primary surface, stops short of companion files / cross-surface references":**

- **MKT-0095 (`/home/jmcleod/dev/ai-platform/marketplace/.context/retrospectives.md:8`)**: "Path-deletion refactors that orphan hooks/CI scripts. Deleting `plugins/ICON/` and `plugins/ICON-beta/` left `.githooks/pre-commit` pointing at `plugins/ICON/shared/common-constraints.md` and `.claude/scripts/validate-manifests.sh` (also deleted)." — sweep stopped at the directory; hooks referencing the directory were missed.
- **MKT-0093 (`marketplace/.context/retrospectives.md:23`)**: "When removing a piece of metadata from source files, scope the brief to also grep for *displays* of that metadata. Initial MKT-0093 brief covered agent frontmatter + CHANGELOG only; reviewer caught a stale `Model` column in `plugins/ICON/README.md` that reproduced the now-removed values." — sweep stopped at source-of-truth files; displays of the same data were missed.
- **MKT-0090 (`marketplace/.context/retrospectives.md:47`)**: "`grep -n` audit before *and* after editing across the entire plugin caught every cascading reference (`plugins/ICON/README.md` skill-table row, `merge-phase-templates/SKILL.md` 'When to Use' trigger string) that would otherwise have shipped as drift in newly initialized repos." — explicitly cites the cross-surface sweep as the *fix*; same class as the M-CC1 pattern.
- **MKT-0089 (`marketplace/.context/retrospectives.md:53`)**: "When adding new content to an existing skill that establishes a new behavioral expectation, check the surrounding text for claims the new content invalidates." — local-scope variant of the same class (sweep didn't reach the contradictory paragraph two paragraphs away).
- **MKT-0078 (`marketplace/.context/retrospectives.md:67`)**: "YAML plain-scalar `description:` values silently dropped 3 skills from the harness's loadable-skill list." — author-time sweep didn't reach the runtime-parser behavior; an ortho-axis variant but still "primary surface authored, companion behavior unreached."
- **MKT-0076 (`marketplace/.context/retrospectives.md:73`)**: "Trusting audit-ticket citations (file paths, line numbers, section names, hardcoded literals) without grep-verifying against the current tree at execution time. 4 of 10 phases hit citation drift." — even more direct: the audit-ticket-as-primary-surface sweep stops at filing; the executing sweep must re-verify each cited surface. Promoted to `coder-delegation.md`.

**Pattern verdict — promotable:** This class has appeared in ≥6 retrospective entries (and 3 fresh on-disk instances in this audit per M-CC1). The standing rule lives in `.context/standards/plugin-structure.md § "Skill Evolution Cross-Surface Sweep"` but is enforced at SKILL.md scope, not skill-folder scope, and not via automated lint. **The class warrants the IO-CC5 + IO-CC7 fixes** (rule widening + commit-time lint) rather than another retro-only entry. Promoting one more time to a *standard* without an automated gate has not stopped recurrence — the rule itself works; the enforcement layer doesn't reach companion files. This is now a 7-occurrence pattern; the next intervention should be automated, not editorial.

**A second pre-split pattern worth noting (3+ instances):** "agent dispatch silently failed on `claude-sonnet-4.6` in this environment" appears in MKT-0092, MKT-0093, MKT-0059 (`marketplace/.context/retrospectives.md:30, :25, :107`). Resolved by MKT-0093's removal of default model pins from agent frontmatter (CHANGELOG `[1.15.3]`) — the lesson is *now codified at the plugin layer*, not retro-only. No additional skill needed.

## MKT-0087 Delta

### Fixed since MKT-0087

- **CC-C1 (Critical, marketplace M-I orchestrator entry-point detection)** — Brief 03 confirms fixed and survived split (`research/03-context-specialist-init.md:134`).
- **CC-C2 (Critical, marketplace M-CS create-iconrc template path)** — Brief 03 confirms fixed (`research/03-context-specialist-init.md:135`).
- **MKT-0087 M2 / MKT-0077 M-I1 (context-specialist agent frontmatter "three modes")** — Brief 01 confirms fixed (`research/01-agents.md:59`); Brief 03 also confirms (`research/03-context-specialist-init.md:136`).
- **MKT-0087 M-U1 release-plugin manager-only guard** — Out-of-scope per the plan's "Inapplicable prior findings" note (`research/04-utility-skills.md:131-138`); release-plugin is maintainer-only post-split.
- **MKT-0087 m-U6 / m-U7 / m-U10 / m-U11 (release-plugin-beta + ICON-beta CHANGELOG)** — Out-of-scope per plan; the `-beta` channel doesn't exist post-split.
- **MKT-0087 m-1 marketplace.json / .gitlab-ci.yml / 7-manifest $schema gap** — Out-of-scope; those manifests don't exist in this repo (Brief 05 at `research/05-infrastructure.md:69`).
- **MKT-0087 m-9 README skills table mr-discipline omission** — Brief 05 confirms fixed (`research/05-infrastructure.md:96`); README:194 lists `mr-discipline`.
- **MKT-0087 O-2 (orphan ICON-beta CHANGELOG)** — Out-of-scope; no `-beta/` snapshot in this repo (Brief 05 at `research/05-infrastructure.md:97`).
- **Net Critical movement: −2.** The marketplace verdict moved from POOR/release-blocking to GOOD with one Moderate doc-conflict.

### Still present or partial

**Agent-domain carry-forwards (Brief 01):**
- M-A1 (planner code-fence imbalance) — line-shifted but unchanged (`research/01-agents.md:63`).
- M-A2 (common-constraints 9× duplication) — unchanged; hash-identical (`research/01-agents.md:64`).
- M-A3 (architect AR table density) — unchanged (`research/01-agents.md:65`).
- m-A1 / m-A2 / m-A3 / m-A4 / m-A5 / m-A6 / m-A7 — all 7 carry-forwards unchanged (`research/01-agents.md:66-72`).

**Process-skills-domain carry-forwards (Brief 02):**
- M-P1 (design-first Step 3 "hard gate" vs advisory framing) — unchanged (`research/02-process-skills.md:123`). Third audit cycle.
- M-P2 (completion vs retrospective delegation-path disagreement) — unchanged (`research/02-process-skills.md:124`). Empirical resolution (ICON-0001 used the specialist path) never made it onto disk.
- m-P1 through m-P5 — all unchanged (`research/02-process-skills.md:125-129`). Third audit cycle for each.

**Context-specialist + init carry-forwards (Brief 03):**
- M1 (orchestrator-vs-agent `mode: upgrade` contradiction) — unchanged (`research/03-context-specialist-init.md:142`).
- M2 (initialize-multimodule feature-branch + MR parity gap) — unchanged (`research/03-context-specialist-init.md:143`).
- m1 / m2 / m3 / m4 / m5 / m6 / m7 / m8 / m9 / m10 — all 10 unchanged (`research/03-context-specialist-init.md:144-153`).

**Utility-skills-domain carry-forwards (Brief 04):**
- M-U2 (writing-skills Common-Workflows-table residue) — unchanged; third audit cycle (`research/04-utility-skills.md:120`).
- m-U1 / m-U2 / m-U3 / m-U4 / m-U5 / m-U6 / m-U7 — all unchanged across MKT-0077 → MKT-0087 → ICON-0003 (`research/04-utility-skills.md:121-127`).

**Infrastructure carry-forwards (Brief 05):**
- m-1 ($schema missing on both manifests) — unchanged from MKT-0087 m-1; count dropped 7→2 because most marketplace manifests didn't migrate (`research/05-infrastructure.md:101`).
- M-2 (release-plugin Error Conditions `sed` row) — re-tiered to Moderate; third audit (`research/05-infrastructure.md:102`).
- m-3 (inject-manager-role bash/pwsh parity test missing) — unchanged (`research/05-infrastructure.md:103`).
- m-5 (bump-versions.sh regex hygiene) — same root class as MKT-0087 m-3 (`research/05-infrastructure.md:104`).

**Carry-forward signal:** The plateau is the dominant observation — ~20+ findings have now carried across MKT-0046 → MKT-0063 → MKT-0077 → MKT-0087 → ICON-0003. Brief 04's closing note (`research/04-utility-skills.md:148`) is apt: "the audit synthesis pass should consider re-tiering them to 'watch / accepted' rather than re-surfacing them as Minors a fourth time."

### Net-new drift classes (since MKT-0087)

The split is the dominant change vector; net-new drift classes correspond to artifacts that either changed home or didn't migrate.

1. **`plugin-audit` skill internally references the old layout** — M-CC2 / Brief 04 M-U1 (`research/04-utility-skills.md:15-26`). 30+ stale `plugins/<plugin>/...` placeholders across `plugin-audit/SKILL.md` + 6 briefs + `synthesis-template.md`. Net-new and high-leverage.
2. **Release flow now uncovered by automated infrastructure** — Brief 05 net-new at `research/05-infrastructure.md:108`. The MKT-0087 baseline had a CI lint stage running `validate-manifests.sh` + `plugin-lint.sh`; post-split, no CI exists (Brief 05 Structural Observation at `research/05-infrastructure.md:71`). Improvement opportunities O-2 / O-4 / O-5 in Brief 05 are all "the gap moved from CI scope to local-hook scope."
3. **Doc-conflict between `workflows/changelog.md:11` and `release-plugin/SKILL.md:105-108`** — Brief 05 M-1 (`research/05-infrastructure.md:17-18`). Net-new because `workflows/changelog.md` was created in ICON-0001 (migrated from marketplace). The v1.15.3 release proves the workflow-doc copy is operationally correct; SKILL.md is the diverged one. ICON-0001 retro at `.context/retrospectives.md:9` named this and shipped without filing the follow-up — the retrospective signal is unambiguous.
4. **`initialize-multimodule` missing `disable-model-invocation: true`** — Brief 03 M3 (`research/03-context-specialist-init.md:157`). Net-new frontmatter-divergence regression of MKT-0087 m8; the two sibling orchestrators carry the flag, multimodule was flipped to `user-invocable: false` but never got the matching key.
5. **`icon-status:161` references the now-unshipped `/release-plugin`** — m-CC2 / Brief 04 m-U8 (`research/04-utility-skills.md:62-63`). Net-new because `release-plugin` moved from `skills/` to `.claude/skills/` in the split.
6. **Hook + script asymmetries newly visible post-split** — Brief 05 m-2 (`hooks/inject-manager-role.ps1` mode 644 vs `.sh` 755), m-4 (`format-slack.sh` no strict-mode), m-7 (release-plugin no git-repo guard). All net-new visibility: marketplace audit didn't check file modes; some files (`format-slack.sh`) didn't exist pre-split.
7. **`post-incident-review/scripts/append-retrospective-entry.{sh,ps1}` 2-location SSOT risk** — Brief 04 m-U9 (`research/04-utility-skills.md:65-67`). Net-new since the canonical-paths post-MKT-0070 architecture now has both `post-incident-review/scripts/` and the `context-maintenance`-maintenance-mode canonical copy.

**Net-new defect count: 1 Moderate (M-1 release-plugin doc conflict) + 1 Moderate (M-U1 plugin-audit unmigrated paths, framed as M-CC1 in this synthesis) + 4-6 Minor depending on how m-CC1/m-CC2/m-CC3 are tiered. No net-new Critical.**

**Cross-cutting verdict:** The split was non-destructive at the domain level but introduced one systemic concern — the audit tool is broken against its own current layout (M-CC2) — and surfaced one previously-buried retrospective finding as an active defect (M-1). The next-leverage interventions are automated (IO-CC5 + IO-CC7: rule widening + commit-time lint) rather than editorial. The 20+ carry-forwards across 4-5 audit cycles signal a re-tiering decision is overdue.
