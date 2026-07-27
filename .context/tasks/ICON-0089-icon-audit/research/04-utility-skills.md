# Utility Skills Audit — Raw Findings

*Domain 04 — ICON-0089, 2026-07-26, plugin v2.0.0 + `[Unreleased]` (ICON-0088). Branch `feature/ICON-0089-icon-audit`.*

## Summary

The utility-skill domain is in materially better shape than at ICON-0058, and the reason is mechanical, not editorial. **Four of the five ICON-0058 findings are closed**, including the headline Moderate: the `ecological-impact` ADR-004 Copilot coupling — framed at ICON-0058 as a third-cycle carry-forward — was closed by ICON-0059 (`CHANGELOG.md:91`), the very next task. **It did not survive four cycles; it survived one more week.** The README registration gap (m-U-5) closed *and stayed closed* because ICON-0080 added a fail-closed pre-commit gate (`.githooks/pre-commit:708-732`): all 50 skills carry a README table row this cycle, against 2 misses in ICON-0058 and 1 in ICON-0046. That single data point is the strongest available argument for this cycle's script-offload directive, and I treat it as the proof case throughout.

What remains is concentrated in the surfaces that have **no gate at all**. `writing-skills` violates its own 500-line cap for the third audit cycle and is now *worse* than when ICON-0058 flagged it (524 → **532 lines**). Every net-new defect I found falls into one of four ungated classes: frontmatter/description schema drift (3 in-scope skills; 1 undocumented key; 14 skills on an unwritten convention), ordered-sequence discontinuity left behind by the 2.0.0 removals (`icon-init` Step 5a with no 5b; `icon-status` Signal 1 → Signal 3), path-coupled cross-skill references that `writing-skills:305-314` forbids (3 live instances), and literal drift in sibling sites (`README.md:162` still calls `ecological-impact` a "Copilot session" 30 tasks after the skill was generalized). The one substantive correctness defect is in `ecological-impact`: its worked example disagrees with its own formulas by 1000×, and its headline energy constant disagrees with its own cited source by ~57×.

Rename/removal residue in `skills/` is otherwise **clean** — zero references to `mr-discipline`, `mr-feedback-triage`, `jira-story`, `mcp-tools-first`, `setup-mcp-servers`, or `sprint-goals`, and zero GitLab/Jira/Confluence/Atlassian mentions anywhere under `skills/`. The residue that survived the sweep is structural (orphaned step letters) and lexical (README row wording), not nominal.

`bash .claude/skills/icon-audit/scripts/structural-check.sh` → **exit 0, all checks pass** (B.1 sections, B.2 six brief skeletons, B.3 synthesis template, B.4 one-way `agent-evaluation` reference, B.6 frontmatter).

---

## Defect Findings

### Critical

None observed.

---

### Moderate

#### M-U-1 — `ecological-impact` worked example contradicts its own formulas by 1000×, and the headline constant contradicts its cited source by ~57× (net-new)

- **Location**: `skills/ecological-impact/SKILL.md:102-103` (rate vs. source basis), `:210-227` (Reference Example block), `:108` / `:118` / `:130-132` (the formulas the example is supposed to demonstrate), `skills/ecological-impact/formulas-reference.md:12,28` (propagates the same rate)
- **Problem — two independent arithmetic defects:**

  **(a) The example is 1000× below its own formula.** `:108` defines `energy_kWh = estimated_tokens × 0.000001`. For the example's 18,000 tokens (`:213`) that is **0.018 kWh**; the example states `~0.000018 kWh`. Every downstream figure inherits the error: `:118` gives `co2_grams = 0.018 × 386 = 6.95 g`, the example states `0.007 g` (`:217`).

  **(b) The example is also internally inconsistent with itself.** `:131` defines `trees_mT = trees_burned × 1,000`. Line `:215` states `0.008 milliTrees (= 0.000000008 trees)` — but `0.000000008 × 1000 = 0.000008`, not `0.008`. Same 1000× break in the annual line (`:220`: `0.0096 trees`; `0.000000008 × 1200 = 0.0000096`). The car-equivalent is independently wrong: `:227` claims "driving a car about 0.6 feet", but `0.007 g ÷ 404 g/mile × 5280 = 0.09 feet` (~6.6× overstated). The water, CO₂-annual, LED and refrigerator lines *are* self-consistent with the (wrong) energy figure — so the example is a mix of correct-relative-to-a-wrong-input and outright-wrong, which is harder to spot than a uniform error.

  **(c) The rate does not follow from its stated basis.** `:102` sets `0.001 kWh per 1,000 tokens`; `:103` cites the basis as "~3.5 Wh/M tokens input + ~14 Wh/M tokens output". 17.5 Wh per *million* tokens is `0.0000175 kWh` per 1,000 tokens — the stated rate is **~57× higher** than the source it cites. `formulas-reference.md:28` repeats the rate and the citation together, so the companion file does not resolve the discrepancy either.
- **Why Moderate**: this is the one skill in the domain whose entire output is numbers. `writing-skills:238` and the `## Quick Reference` pointer at `:240` both frame `formulas-reference.md` as the "cross-step verification or spot-checking" surface — an agent doing exactly that will reconcile against a broken example and either propagate the error or stall. The skill's own `**Key principle**: Be honest about uncertainty` (`:35`) is undercut by an example that is wrong by three orders of magnitude, not by estimation variance.
- **Delta from ICON-0058**: Net-new axis. ICON-0058 M-U-1 and ICON-0046 M-U-NET1 both examined this file for **ADR-004 platform coupling** and never checked the arithmetic. ICON-0037 (`CHANGELOG.md:197`) touched `:86`/`:221` for stale model names — inside the example block — without recomputing it. Four audits have now read this example without verifying it.

#### M-U-2 — `rfc` cites `ORG-004` and `RFC-001` as normative standards with no definition anywhere in the plugin (net-new; regression introduced by the ICON-0058 m-U-3 fix)

- **Location**: `skills/rfc/SKILL.md:4` (description: "polish rough drafts into **ORG-004** compliant form"), `:12` ("documents meeting ORG-004 standards"), `:17`, `:19`, `:53`, `:75` ("per **RFC-001** versioning"), `:100`, `:136` (`## rfc: Step 3: ORG-004 Output Schema (Authoritative)`), `:273`; also `README.md:172` ("Create RFCs from scratch or polish rough drafts (ORG-004)")
- **Problem**: ICON-0058 m-U-3 flagged the live `onedatascan.atlassian.net` URLs at `:19`. Those are gone — `:19` now reads `` `<your-rfc-process-doc>` (RFC-001 RFC Process) · `<your-rfc-guidance-doc>` (General RFC Guidance) ``. But removing the link removed the **only definition** of what ORG-004 and RFC-001 are, while leaving both identifiers in nine places including the description (the auto-invocation surface) and an `(Authoritative)` step heading. A consumer now reads "meeting ORG-004 standards" as a normative requirement against a document that is, from inside the plugin, undefined. `grep -rn "ORG-004" .context/ README.md context_template/` returns only `README.md:172` and a superseded ADR — no definition exists.
- **The sanction is also gone.** ADR-011 (`.context/decisions/011-datascan-production-instance.md:28`) previously ruled DataScan body-prose references — "`onedatascan.atlassian.net`, **ORG-004**, internal DataScan Confluence/Jira URLs" — "intentional production content, not portability bugs". That ADR is **`Status: Superseded by ICON-0080`** (`:4`). ADR-010 m9 is likewise recorded Closed (ICON-0080) as "moot after the GitHub-only conversion". So neither carve-out covers these identifiers any more; this is not a re-tier of an accepted finding.
- **Why Moderate rather than Minor**: it is in the `description:` field, which drives auto-invocation, and the schema step is labelled `(Authoritative)`. An unresolvable authority in an authoritative-labelled step is a comprehension blocker, not cosmetic. The fix is a one-line definition or a clean removal — cheap, but it must be decided rather than left half-swept.

#### M-U-3 — Three Format-type skills carry workflow-summarising descriptions that violate the rule `writing-skills` documents with a named failure story (net-new)

- **Location**: `skills/github-issue/SKILL.md:4`, `skills/post-meeting/SKILL.md:4`, `skills/rfc/SKILL.md:4`; rule at `skills/writing-skills/SKILL.md:160` and `:165-183`
- **Problem**: `writing-skills:160` states `description` must be "Third person. Starts with 'Use when…'. ONLY triggering conditions — **never the workflow**." `:165-183` then justifies it with a concrete observed failure: *"When a description summarises a skill's workflow, agents follow the description instead of reading the full skill. A description saying 'code review between tasks' caused an agent to do ONE review even though the skill body's flowchart showed TWO."* All three of these descriptions are exactly the shape that story warns about:
  - `github-issue:4` — "**Renders** provided story content into a standard GitHub issue (Markdown issue body) **with title, description, acceptance criteria as a task list, labels, and cross-references.**" No "Use when"; no trigger conditions at all; enumerates the output schema.
  - `post-meeting:4` — "**Transforms** meeting transcriptions into structured summaries **with key points, Q&A, and action items.** Use when…" Leads with the workflow, trigger relegated to sentence two.
  - `rfc:4` — "**Create** RFC documents from scratch or polish rough drafts into ORG-004 compliant form. Use when… **Handles both scaffold-from-inputs and refactor-existing-draft entrypoints.**" Workflow both before and after the trigger clause.
- **Concrete risk, not theoretical**: `github-issue` has a live divergence of exactly the story's shape. Its description says it "renders" — but `:29-35` mandates a *three*-step execution that ends in a **file write**, with an explicit guard: *"**Do not** output the issue as chat text only — the file must be written to disk."* An agent that acts on the description's "renders … issue body" and skips the body does precisely the documented failure: performs step 1 of 3.
- **Common thread**: all three are the **Format** type in `writing-skills:73`'s taxonomy. This is a type-correlated pattern, not three coincidences — see Structural Observation 2.
- **ADR check**: ADR-009 exempts *missing caller lists* from being defects. It does not exempt workflow summarisation or a missing "Use when" opener. Not re-tiered under ADR-009.

---

### Minor

#### m-U-1 — `writing-skills` line-cap self-violation, third cycle, now regressed further (still present from ICON-0058 m-U-1)

- **Location**: rule at `skills/writing-skills/SKILL.md:208` ("Keep SKILL.md under 500 lines; split into supporting files beyond that"); file is **532 lines / 3,181 words / 23,301 bytes**
- **Problem**: ICON-0033 fixed this by extracting `skill-creation-checklist.md` (549 → 499 lines, `CHANGELOG.md:172`). ICON-0047's `## Where Skills Live` addition (`:77-100`) reopened it at 524 (ICON-0058 m-U-1). It is now **532** — eight lines worse than when the previous audit flagged it, with no intervening fix. The word-count axis is separately over `:270`'s "Standard skills: < 500 words" at 3,181, though `:271` ("Complex discipline skills: can go longer, but earn every line") arguably self-exempts that axis; the **line cap at `:208` carries no such exemption clause.**
- **Why this keeps recurring**: the rule is enforced only by audit. Three cycles, three manual detections, one fix. There is no `wc -l` gate anywhere in `.githooks/pre-commit` (confirmed — no line-count check exists). See SO-2.
- **Classification**: Minor. Self-consistency defect in the authority document for skill authoring; the correction requires a split decision (which section), which is judgment.

#### m-U-2 — Ordered-sequence discontinuity left behind by the 2.0.0 removals: two live instances (net-new; rename/removal residue)

- **Location A**: `skills/icon-init/SKILL.md:211-221` — `## icon-init: Step 5: Post-init affordances` contains exactly one sub-step, `### icon-init: Step 5a: Next-step hint (always)`. A lone "5a" is only meaningful against a sibling. `CHANGELOG.md:327` (MKT-0073) confirms 5a and 5b were introduced as a pair: *"new Step 5a unconditional next-step hint … new Step 5b conditional MCP onboarding hint that suggests `/setup-mcp-servers`"*. ICON-0080 removed `setup-mcp-servers` (`CHANGELOG.md:40`) and deleted 5b, leaving the orphaned letter and the now-inaccurate plural framing at `:213` ("print the following hint**s** in order").
- **Location B**: `skills/icon-status/SKILL.md:118` (`# Signal 1: .context/domains/ missing or empty`) and `:130` (`# Signal 3: task branch with a stale plan.md`) — **no Signal 2**. `CHANGELOG.md:188` (ICON-0038) records the removal of the `consider /release-plugin` hint from this skill; the surviving numbering shows the sequence was never closed up.
- **Problem**: both are the class `writing-skills:235-240` was written to prevent, and that section states plainly that nothing catches it: *"the pre-commit hooks do not catch numbering or structure drift"* (`:237`) and *"A dangling 'see Step 8' now meaning Step 9 is invisible to the hooks, caught only by review"* (`:239`). `.context/retrospectives.md:55` (ICON-0078) is the originating evidence — a stale `Step 8` reference "caught by @reviewer, not by any gate" — and `:56` records the chosen remedy: **add prose to `writing-skills`**. These two instances are direct evidence the prose remedy did not hold across the 2.0.0 removals. `.context/retrospectives.md:8` independently names the same class: folding a removed step back in "rather than leaving a numbering gap."
- **Classification**: Minor individually (a reader can follow either skill). Collectively they are the clearest mechanization case in the domain — see SO-3.

#### m-U-3 — Path-coupled cross-skill references violating `writing-skills:305-314`: three live instances (net-new)

- **Location**: `skills/manager-routing-guide/SKILL.md:79` (`see \`task-plan-phase-completion/agent-vs-skill-invocation.md\``); `skills/agent-evaluation/SKILL.md:103` (`This matches the convention \`skills/writing-skills/SKILL.md\` mandates for skills`); `skills/icon-init/SKILL.md:233` (`the "Shell command self-check" rule in \`shared/common-constraints.md\``)
- **Problem**: `writing-skills:305-309` mandates citing skills **by name only** and marks the path form as forbidden — "❌ `See skills/testing/test-driven-development` (path-coupled, brittle)". `:314` goes further: "**Skills must be self-contained.** A skill cannot rely on files outside its own directory — no portable cross-skill resource mechanism works across every agent runtime." `manager-routing-guide:79` is the sharpest instance: it reaches into a *different skill's* directory for a specific companion file. All three targets currently exist, so nothing is dangling today — the defect is the coupling, which is precisely what makes the `mr-*` / `jira-story` rename class expensive.
- **Same-class evidence**: `.context/retrospectives.md:43` (ICON-0080) — *"under-scoped the skill cross-reference sweep (missed `find-context-template` and `context-maintenance` …), forcing a gap pass — give sweep coders a whole-tree grep mandate, not just a hand-curated file list."* `:8` repeats it as a general rule for removals.
- **Note on the `.context/` half**: the equivalent problem for `.context/` paths **is** already gated — `writing-skills:316` documents the pre-commit dead-`.context/`-reference gate and the by-name fix. The `skills/`-to-`skills/` half has no equivalent. See SO-4.

#### m-U-4 — Fourteen skills use an undocumented `description` convention that directly contradicts `writing-skills:160` (net-new, systematic)

- **Location**: `skills/manager-routing-guide/SKILL.md:4` (in scope) plus 13 siblings — `context-specialist-{create,detect-tree-position,impl-branch,impl-leaf,impl-root}`, `find-context-template`, `invoke-sub-project-skill`, `merge-phase-templates`, `resolve-repo-context`, `task-plan-phase-{architecture,completion,implementation,investigation,testing}` — all reading some form of "Internal &lt;X&gt; skill. Do not invoke without explicit direction."; rule at `skills/writing-skills/SKILL.md:160`
- **Problem**: this form contains **zero triggering conditions**, which `:160` makes the sole permitted content of a description. It is almost certainly *correct* behaviour — these skills are loaded by name on demand, and giving them trigger phrases would cause spurious auto-invocation. But the convention is written down **nowhere**: `grep -rn "Do not invoke without explicit direction" skills/writing-skills/ .claude/ README.md` returns nothing. The result is a de-facto second frontmatter contract, followed by 28% of the skill corpus, that a new author cannot discover and that any conformance check would flag as 14 false positives.
- **Classification**: Minor as a defect; **blocking prerequisite** for SO-1 (a frontmatter gate cannot ship until the sanctioned form is written down). See IO-1.

#### m-U-5 — `agent-evaluation` carries an off-topic section that violates its own RULE 4, plus the plugin's only undocumented frontmatter key (net-new)

- **Location**: `skills/agent-evaluation/SKILL.md:89-115` (`## Frontmatter Conventions`), `:5` (`argument-hint:`), rule at `:49-54` (RULE 4)
- **Problem — three distinct issues in one section:**
  1. **Self-violation.** `:49-54` RULE 4 states "A skill must do ONE thing (format/call/return)" and "Flag any skill whose rules change depending on what the agent is trying to do." `agent-evaluation` does two things: it evaluates agent-system designs, and it is the SSOT for `agents/*.agent.md` frontmatter shape. The skill that audits systems for single-responsibility violations is itself a two-responsibility skill.
  2. **Structural placement.** The skill body from `:24` onward is a *prompt* addressed to the model ("You are an expert AI agent architect. I am going to describe my agent system to you"), terminating in `$ARGUMENTS` at `:120`. `## Frontmatter Conventions` (`:89-115`, 27 lines including a 4-row anti-rationalization table) sits **between** the response-format spec (`:65-85`) and the `$ARGUMENTS` slot — i.e. inside the prompt payload, unrelated to the user's submitted system.
  3. **Undocumented frontmatter key.** `:5` is `argument-hint: "description of your agent system"`. It is the **only** occurrence of this key across all 50 skills, and `writing-skills:148-161` documents exactly three keys (`name`, `description`, `user-invocable`). Either the key is load-bearing and should be documented, or it is inert and should go.
- **Also**: the path-coupled reference at `:103` is counted under m-U-3.
- **Classification**: Minor. Nothing breaks; the cost is that agent-frontmatter rules live in a skill nobody would think to open for them. See IO-2.

#### m-U-6 — `manager-routing-guide` attributes the model-tier decision to ADR-004; the owning ADR is ADR-014 (net-new)

- **Location**: `skills/manager-routing-guide/SKILL.md:133` (`### Tier → model realization (ADR-004)`)
- **Problem**: ADR-004 is *Tool-agnostic content; no runtime-specific code* (`.context/decisions/004-tool-agnostic-content.md:1`) and contains no tier table. The decision that owns tiers is **ADR-014** — *Model-aware delegation — required per-delegation tier* (`.context/decisions/014-model-aware-delegation.md:1`), which itself records that "the tier→model table live[s] in the on-demand `manager-routing-guide` skill" (`:29-30`). The citation is defensible in origin — ADR-014:31 reasons "Per ADR-004 the rule is stated in tier terms" — but as written the heading routes a reader to a portability ADR with no tier content, and silently drops the pointer to the ADR that actually governs the section. `grep -rn "ADR-004" skills/ agents/` shows this is the only site pairing ADR-004 with tier/model language.
- **Fix shape**: `### Tier → model realization (ADR-014; portability constraint per ADR-004)`.
- **Classification**: Minor. Citation precision in an on-demand reference table.

#### m-U-7 — `README.md` skill rows carry literals the skills themselves no longer use (net-new; sweep incompleteness)

- **Location**: `README.md:162` — "`ecological-impact` | Calculate and display the environmental footprint of a **Copilot** session in Trees Burned…"; `README.md:172` — "`rfc` | Create RFCs from scratch or polish rough drafts (**ORG-004**)"
- **Problem**: ICON-0059 made `ecological-impact` platform-neutral end to end — `:4` now reads "their AI session", `:43` is "Option A — Monthly Usage (Preferred)" with three co-equal platform branches (Copilot `:47-51`, Claude Code `:53-56`, Other `:58`), and both report headers (`:152`, `:211`) read "🌍 AI Ecological Impact Report". The README row was not swept and still describes the skill as Copilot-specific — the one surface a prospective user reads *before* opening the skill. `README.md:172` is the same failure against M-U-2's identifier removal.
- **This is the standing literal-drift class**: a value corrected in its primary site persisting in a sibling. `.context/retrospectives.md:8` names it directly — "A repo-wide grep for the feature's own identifiers … is what makes the removal complete." The existing `O-M1b` cap-literal gate (`.githooks/pre-commit:650-700`) implements exactly this idea, but for **one** hard-coded literal (`ENTRY_CAP`). See SO-5.
- **Classification**: Minor. Documentation-only; no runtime effect.

#### m-U-8 — Two operational-defensiveness gaps in state-mutating utility skills (net-new)

- **Location A**: `skills/github-issue/SKILL.md:29-35` — the Execution block mandates "Write the file to `{output_path}/{output_filename}` using your file-write tool" with no existence check, no overwrite guard, no dry-run, and no idempotency statement. The skill's only precondition is that the two path inputs are present (`:35`). Re-running it against an existing filename silently destroys the prior issue draft. Per the brief's Common Check Pattern 3, a skill that writes to disk should state at least one of these; this one states none.
- **Location B**: `skills/icon-status/SKILL.md:106-111` — every other data-gathering block in Step 2 explicitly "handles missing data gracefully" per `:44-45`, using the ADR-007-compliant `2>&1 | grep -v "^fatal"` idiom (`:50`, `:51`, `:59`, `:71`, `:132`). The `iconrc.json` block is the exception: `python3 -c 'import json,sys; print(json.load(open(".context/iconrc.json")).get("version","?"))'` has a `.get(…, "?")` default for a *missing key* but no handling for **malformed JSON or absent `python3`** — either emits a raw traceback into a user-facing dashboard. Note `icon-init:69-77` solves the same problem correctly, with `try/except` plus `2>&1 | grep -v "^Traceback"`, so the safe idiom already exists in the codebase one skill away.
- **Classification**: Minor both. A-side is a data-loss-adjacent gap in a user-invocable skill; B-side is cosmetic degradation.

#### m-U-9 — `start-worktree` instructs writing a `plan.md` section that no plan.md schema declares (net-new)

- **Location**: `skills/start-worktree/SKILL.md:93-102` (Step 4: "record the worktree path in `plan.md`" under a `## Worktree` heading)
- **Problem**: `plan.md`'s section set is owned by `skills/task-plan/SKILL.md:76-98` (Built-in Format) and `context_template/context/workflows/task-plan/base.md`. `grep -rn "Worktree" skills/task-plan/ context_template/` returns **nothing** — neither declares a `## Worktree` section. `start-worktree` therefore writes an undeclared section into an artifact another skill owns, and `context-document-guidelines:98-102` notes that `base.md`'s section structure is treated as *a parse contract* whose fixed shape agents depend on.
- **Classification**: Minor. Additive and harmless in practice; the SSOT ownership is what is off.

#### m-U-10 — Six of fourteen in-scope skills omit `## When to Use` from the `writing-skills` body skeleton (net-new, low severity)

- **Location**: absent in `skills/github-issue/SKILL.md`, `skills/post-meeting/SKILL.md`, `skills/using-skills/SKILL.md`, `skills/icon-init/SKILL.md`, `skills/code-quality-rules/SKILL.md`, `skills/manager-routing-guide/SKILL.md`; skeleton at `skills/writing-skills/SKILL.md:187-206`; present in the other eight
- **Problem**: `:208` does say "Not every skill needs every section," so this is not a hard violation — and four of the six have a defensible substitute (`code-quality-rules:72-78` has "When to Use All Passes"; `manager-routing-guide:10` states its invocation trigger in the opening line; `using-skills` *is* the invocation gate; `icon-init:12-14` covers it in Overview). The two with no substitute at all are **`github-issue`** and **`post-meeting`** — which are also two of the three skills in M-U-3 whose descriptions carry no trigger conditions either. Those two skills consequently have **no trigger surface anywhere**, in frontmatter or body.
- **Classification**: Minor. Reported for the `github-issue` / `post-meeting` intersection with M-U-3, not as a blanket skeleton-conformance complaint.

#### m-U-11 — `rfc` sub-step headings omit the skill-name prefix the full-path rule requires (net-new)

- **Location**: `skills/rfc/SKILL.md:88` (`### 2-R.1 Read and Understand the Draft`), `:100` (`### 2-R.2 …`), `:121` (`### 2-R.3 …`); rule at `skills/writing-skills/SKILL.md:220-233`
- **Problem**: `writing-skills:220` requires that a skill with sub-processes "include both stage and step identifiers — the canonical path through the process", and `:229-230` marks both `### Stage 1: Step 1: Do X` (missing skill name) and `### skill-name: Step 1: Do X` (missing stage) as wrong. `rfc`'s top-level headings are conformant (`## rfc: Step 2-R: Refactor Path…` at `:86`), but its three sub-steps drop the `rfc:` prefix entirely — the exact failure `:233` describes, where an agent reading a heading in isolation cannot tell which skill it belongs to. `rfc` is the only in-scope skill with sub-step headings, so it is the only place the rule bites; all 14 in-scope skills are otherwise clean on top-level step prefixing.
- **Classification**: Minor.

---

## Improvement Opportunities

### IO-U-1 — Write down the "Internal skill" description contract as a sanctioned second form in `writing-skills`

**Effort: Trivial. Impact: High (unblocks SO-1).**

Fourteen skills (28% of the corpus) follow an unwritten description convention that contradicts the only written one. Add a short subsection to `writing-skills` after `:163` defining two sanctioned forms:

- **Discoverable form** (default): `Use when <triggering conditions>` — for any skill an agent should reach by description match.
- **Directed-load form**: `Internal <owner> skill. Do not invoke without explicit direction.` — for skills loaded by name by a named caller, where trigger phrases would cause spurious auto-invocation. State the decision rule (does anything auto-match this, or does exactly one caller load it by name?) and name the owner in the text.

This is positive-design work, not a patch: it converts an emergent convention into a contract, makes the choice explicit for new authors, and is the precondition for any mechanical frontmatter check (SO-1) that would otherwise report 14 false positives.

### IO-U-2 — Consolidate the frontmatter SSOT: move `agent-evaluation`'s `## Frontmatter Conventions` to the skill-authoring home

**Effort: Low. Impact: Medium.**

This is the MKT-0061 `rfc-format` + `rfc-refactor` → `rfc` shape the brief names as the reference pattern, and the preconditions match: **shared artifact schema** (both documents specify YAML frontmatter with a `description: >` folded-scalar mandate), **shared audience** (anyone authoring an agent or skill file), and **observable drift** (`agent-evaluation:103` already has to reach across by path to assert "This matches the convention `skills/writing-skills/SKILL.md` mandates for skills" — a cross-reference that exists only because the rule is stated twice).

Proposal: `writing-skills` becomes the single frontmatter authority for both `skills/*/SKILL.md` and `agents/*.agent.md`, absorbing the agent-specific rules (`agent-evaluation:104` — user-invocable agents may be multi-paragraph, sub-agents stay one sentence) and the 4-row anti-rationalization table (`:109-114`). `agent-evaluation` keeps a one-line by-name pointer. Net effect: `agent-evaluation` returns to one responsibility (satisfying its own RULE 4), the prompt payload stops carrying 27 lines of unrelated schema, one path-coupled reference disappears, and there is exactly one place to check when a frontmatter gate ships.

### IO-U-3 — Split `writing-skills` along the proven ICON-0033 seam rather than trimming it for one cycle

**Effort: Low. Impact: Medium.**

`writing-skills` has now crossed its own 500-line cap twice and been trimmed once; at 532 lines it is 8 lines worse than at last audit. The trim-and-drift cycle repeats because the file is the natural home for every new authoring lesson (ICON-0047 added `## Where Skills Live`, ICON-0076/0077 added the by-name paragraph at `:316`, ICON-0078 added `### Editing an Existing Numbered Skill`).

The durable move is a structural seam, not another trim. ICON-0033 already proved the pattern by extracting `skill-creation-checklist.md`; the file has six healthy companions today (`anthropic-best-practices.md`, `persuasion-principles.md`, `testing-skills-with-subagents.md`, `graphviz-conventions.dot`, `render-graphs.js`, `examples/`). Extract the frontmatter + naming + discoverability material — `### Frontmatter (YAML)` (`:148-163`), `### Why description must NOT summarise workflow` (`:165-183`), `## Discoverability` (`:242-262`), and `## Cross-Referencing Other Skills` (`:303-316`) — into `skills/writing-skills/skill-frontmatter-reference.md` (~65 lines), leaving a pointer. This lands the file near 465 lines with headroom, and — combined with IO-U-2 — creates one obvious destination for every frontmatter rule in the plugin and the natural companion doc for a conformance script to be specified against.

### IO-U-4 — Make `ecological-impact`'s worked example self-verifying

**Effort: Low. Impact: Medium.**

M-U-1 exists because a hand-written example block drifted from hand-written formulas across four audits, and the `formulas-reference.md` companion added by MKT-0085 as the verification surface duplicated the constant instead of deriving it. The whole calculation is deterministic and takes about 30 lines of arithmetic.

Proposal: add `skills/ecological-impact/scripts/compute-example.sh` that takes a token count and emits the complete report block from the constants in `formulas-reference.md`; regenerate `:210-236` from it. Then the example can never disagree with the formulas, because it is not authored — and the same script gives an agent a real spot-check tool where today it has a broken reference. Independently, reconcile `:102`'s rate against `:103`'s cited basis (~57× apart): either restate the basis to one that supports 0.001 kWh/1k tokens, or restate the rate.

### IO-U-5 — Give `github-issue` and `post-meeting` real trigger surfaces

**Effort: Trivial. Impact: Medium.**

These two are the intersection of M-U-3 and m-U-10: no `Use when` opener, no trigger conditions in the description, and no `## When to Use` section — so nothing in either file tells an agent *when* to reach for it. Both are user-invocable, so they are reachable by slash command, but auto-invocation has nothing to match on. Rewrite both descriptions to trigger-first form and add a short `## When to Use` block. For `github-issue` this also fixes the M-U-3 execution risk directly: a description that names the trigger rather than the output stops competing with the "must be written to disk" mandate at `:35`.

### IO-U-6 — Define or retire `ORG-004` / `RFC-001` in `rfc`

**Effort: Trivial. Impact: Medium (closes M-U-2).**

Now that ADR-011 is superseded and ADR-010 m9 is Closed, no carve-out protects these identifiers. Two clean options:

- **(a) Define locally.** Add one line under `:19`: "ORG-004 here names the RFC document standard specified in Step 3 below; substitute your organization's equivalent standard ID." The `(Authoritative)` label at `:136` then points at something real — the schema in the skill itself.
- **(b) Retire the labels.** Replace "ORG-004 compliant form" with "the standard RFC schema in Step 3" at `:4`, `:12`, `:17`, `:53`, `:136`, `:273`; replace "per RFC-001 versioning" at `:75` with the versioning rule stated inline (it already is: `0.1.0` → minor for comments → `1.0.0` on approval). Sweep `README.md:172` in the same change.

Option (b) is the better fit for a plugin with no org affiliation left, and it removes the last opaque org identifiers from `skills/`.

---

## Utility-Skills-Specific Structural Observations

### Observation 1 — A gate closed a three-cycle recurring finding permanently; prose did not

The README registration gap ran across ICON-0046 (m-U-net2) and ICON-0058 (m-U-5) — two consecutive audits, three skills between them. Two remedies were tried. ICON-0060 added a **prose checklist** to `CONTRIBUTING.md` (`CHANGELOG.md:77`: "a new-skill integration checklist (README row, `using-skills` routing, consuming-agent wiring)"). ICON-0080 added a **fail-closed script gate**, `.githooks/pre-commit:708-732`, which requires an anchored `` | `<name>` | `` row in `README.md` for every `skills/<dir>/`.

The outcome is measurable. This cycle: **50 of 50 skills registered, zero misses.** And `.context/retrospectives.md:43` records the gate actually firing in anger — *"the README skill-registration gate (every `skills/<dir>/` needs a README table row) blocked committing the renamed skills until README was updated"* — during the highest-churn task in the interval (ICON-0080 renamed three skills and deleted three more). The prose checklist shipped first and did not prevent the ICON-0058 miss; the gate has not been beaten since.

Two of the three items in ICON-0060's checklist remain prose-only: `using-skills` routing registration and consuming-agent wiring. Neither has produced a finding this cycle, so I am not claiming they are broken — only that the one item that got a gate is the one that stopped recurring.

### Observation 2 — Every net-new defect this cycle sits in an ungated class, and the classes are type-correlated

Sorting the eleven net-new findings by what would have caught them:

| Class | Findings | Gate status |
|---|---|---|
| Frontmatter / description schema | M-U-3, m-U-4, m-U-5 (`argument-hint`) | **none** |
| Ordered-sequence continuity | m-U-2 (×2), m-U-11 | **none** — `writing-skills:237` says so explicitly |
| Cross-reference form (`skills/`→`skills/`) | m-U-3 (×3) | **none** (`.context/` half **is** gated) |
| Literal drift into sibling sites | m-U-7 (×2), M-U-2 | **partial** — `O-M1b`, one hard-coded literal |
| Skill size | m-U-1 | **none** |
| Content correctness / judgment | M-U-1, m-U-8, m-U-9, m-U-10 | not mechanizable |

Nothing in the first five rows requires judgment to *detect*; all of it requires judgment to *fix*. That split is what makes this domain unusually good territory for offload.

The M-U-3 finding is additionally **type-correlated**: all three workflow-summarising descriptions belong to the **Format** type in `writing-skills:73`'s taxonomy (`github-issue`, `rfc`, `post-meeting` — and those are exactly the three skills that taxonomy lists). None of the Discipline, Technique, Pattern or Reference skills in scope has this defect. The likely mechanism: a Format skill's identity *is* its output shape, so the natural description is "what it renders" — which is the workflow. Worth a targeted sentence in `writing-skills` rather than a general reminder.

### Observation 3 — The `ecological-impact` carry-forward closed one week after being labelled a three-cycle failure

ICON-0058 M-U-1 recorded this as a "third-cycle carry-forward" with a structural diagnosis (Observation 1 of that report): *"when an audit Moderate is labeled with a suggested task ID, it does not automatically become that task's scope … The audit-report → follow-up-task handoff is informal."* The brief for this cycle asked me to check whether it had now survived four.

**It had not.** `CHANGELOG.md:91` records ICON-0059 — the task immediately following the audit — shipping the fix: *"the `ecological-impact` skill's Option-A monthly-usage path and report header are now platform-neutral with a dedicated Claude Code sub-option, so Claude Code users can run the skill instead of hitting Copilot-only 'Remaining Reqs' and billing-quota instructions."* Verified on disk: every line ICON-0058 cited is remediated, and Option A now branches across three platforms as co-equals rather than treating Copilot as the default with others as fallbacks.

The reason it closed is worth recording, because it is the counter-case to Observation 1: the previous audit **named the fix precisely** — ICON-0058's IO-U-1 listed four numbered edits with exact target lines — and the very next task executed that specification. Where the ICON-0046 → ICON-0047 handoff drifted to a different skill, a sufficiently concrete recommendation did not. That is a real finding about audit-report quality, but note the asymmetry with Observation 1: this mechanism closed the item *once*. The gated item has stayed closed across a rename of three skills and a deletion of three more.

The residue (`README.md:162`, m-U-7) shows the sweep stopped at the file the recommendation named — which is exactly the literal-drift class SO-5 targets.

---

## Script-Offload Candidates

Ranked by leverage. Existing inventory checked first (baseline preamble §*Existing deterministic scripts*, plus a direct read of `.githooks/pre-commit`): the hook currently runs the `context_template/` version-bump gate, script-parity, the `O-M1a` placeholder sentinel, the `O-M1b` cap-literal check, `check-rules-index.sh`, `context-graph.sh --check`, the dead-`.context/`-reference check, the `O-V1` README skill-registration gate, and shellcheck. `.github/workflows/` contains **only** `security.yml` — there is no content-lint CI job. Verified absent from the hook: any frontmatter check, any `wc -l`/size check, any `skills/`→`skills/` reference check.

All five proposals target `skills/**` and `agents/**`, none touches `context_template/`, so none triggers the ICON-0044 iconrc version-bump invariant. All should follow the 3-value exit contract in `secure-coding` Rule 11 (0 clean / 1 violation / 2 parser-or-environment error) and be invoked `|| { …; exit 1; }`, per `.context/retrospectives.md:40`.

---

### SO-1 — Skill frontmatter schema conformance gate

**Effort: Low × Leverage: High.** *(prerequisite: IO-U-1)*

**(a) Current LLM-carried obligation.** `skills/writing-skills/SKILL.md:159-161` (name charset + 64-char cap; description third-person, "Use when…" opener, triggering-conditions-only, 1024-char cap; `user-invocable` semantics), `:163` (**"Always use the YAML folded block scalar form (`description: >`) — never a plain scalar"**), and the Anti-Patterns row at `:501`. Every one of these is prose an author must remember at edit time.

**(b) Observed failure mode.** Documented and severe. `CHANGELOG.md:305` (MKT-0078): *"All `SKILL.md` frontmatter `description:` fields converted to YAML folded block scalar (`description: >`): **fixes silent parse failures** in `jira-story`, `post-meeting`, and `sprint-goals` — plain-scalar descriptions containing `: ` or `[…]` mid-value were **dropping these skills from the loadable-skill list with no log line.**" Three skills were invisible to the loader with zero diagnostic output. The remedy applied was prose (`writing-skills:163` + the `:501` table row). Live drift today, after that remedy: three descriptions violate the "Use when"/no-workflow rule (M-U-3), fourteen follow an undocumented form (m-U-4), one undocumented key exists (m-U-5). The folded-scalar rule specifically **is** currently holding — all 50 use `description: >` — which is precisely why it is worth locking before it drifts again.

**(c) Mechanization.** `skills/writing-skills/scripts/check-skill-frontmatter.sh`, invoked from `.githooks/pre-commit` beside the existing `O-V1` gate at `:708`, scoped to staged `skills/*/SKILL.md` and `.claude/skills/*/SKILL.md`. Per file, assert: frontmatter delimited by `---` at line 1; `name:` present and byte-equal to the parent directory name and ≤64 chars; `description:` present in **exactly** `description: >` folded form; description body ≤1024 chars and matching *either* `^Use when ` *or* the sanctioned directed-load form from IO-U-1; `user-invocable:` present and `true|false`; **no keys outside the documented set** (this is what surfaces `argument-hint`). Accumulate-then-report, matching the `O-M1a`/`O-M1b` style at `:619-700`. **Fail-closed** — every check is a byte-level string assertion with no ambiguity.

**(d) Residual judgment (do not mechanize).** Whether a description names the *right* triggers — the symptoms, error strings, and synonyms `writing-skills:246-252` asks for. Whether it subtly summarises workflow (M-U-3 is a semantic judgment; a grep can enforce the opener and reject the obvious "Renders…"/"Transforms…" leads, but not adjudicate borderline cases). Which of the two sanctioned forms a new skill should use.

**(e) Note.** The `name == directory` check alone would have caught any of the three 2.0.0 renames if a directory had moved without its frontmatter, and costs one line.

---

### SO-2 — Ordered-sequence continuity gate

**Effort: Medium × Leverage: High.**

**(a) Current LLM-carried obligation.** `skills/writing-skills/SKILL.md:235-240`, `### Editing an Existing Numbered Skill`. The section **states its own unenforceability twice**: `:237` — "keep it internally consistent — **the pre-commit hooks do not catch numbering or structure drift**"; `:239` — "A dangling 'see Step 8' now meaning Step 9 is **invisible to the hooks, caught only by review**."

**(b) Observed failure mode.** `.context/retrospectives.md:55` (ICON-0078): *"inserting the new Step 7 and renumbering (old 7→8, 8→9, 9→10) left one stale 'Step 8' cross-reference in Step 4 prose … **caught by @reviewer, not by any gate**."* `:56` records the remedy chosen — promote the lesson into `writing-skills` prose. **Two live instances this cycle prove the prose did not hold**: `icon-init:215` (orphaned Step 5a; `CHANGELOG.md:327` confirms 5b was its pair, removed by ICON-0080) and `icon-status:118,130` (Signal 1 → Signal 3, residue of ICON-0038). Neither was a renumber — both are *removal* residue, a case the prose does not even mention. `.context/retrospectives.md:8` names the same class again in ICON-0086's retro ("rather than leaving a numbering gap"), making this at minimum a three-occurrence pattern.

**(c) Mechanization.** `skills/writing-skills/scripts/check-sequence-continuity.sh`, staged-file-scoped, same hook position. Three passes: **(i) Heading sequence** — extract `^#{2,4} <name>: (Step|Phase|Stage) ([0-9]+)([a-z]?)`, assert integers are gapless from 1, and that any lettered sub-series has ≥2 members (catches `icon-init` Step 5a). **(ii) In-body ordinal markers** — same for `^#*\s*(Signal|Case|Rule|Pass) ([0-9]+)` in comments and headings (catches `icon-status` Signal 2). **(iii) Backward reference** — grep prose for `Step N` / `Phase N` mentions and flag any N above the file's own maximum (catches the ICON-0078 case directly). Pass (i) can also assert the `writing-skills:220-233` full-path prefix rule, catching m-U-11 for free. **Fail-closed**, with an inline `<!-- icon-seq-ok: <reason> -->` escape hatch matching the existing `<!-- pre-commit:dead-ref-ok-start -->` / `<!-- context-graph:orphan-ok -->` marker family already documented at `context-document-guidelines:157-158`.

**(d) Residual judgment.** Whether to **renumber or repurpose in place** when a step is removed — `.context/retrospectives-archive.md:32` records this as a real decision made on grep evidence ("zero `Step 2` cross-refs vs. three live `Step 4` Commit refs made the no-renumber choice decisive"), and it is exactly the judgment a script must not take. Also: whether a numbering gap is deliberate (a reserved slot), which is what the escape hatch is for.

**(e) Note.** Medium effort because pass (iii) needs care to avoid matching the illustrative `Step N` strings inside `writing-skills`'s own code fences at `:215-231` — the same fence-blindness caveat the existing dead-ref check documents at `.githooks/pre-commit:36`.

---

### SO-3 — `skills/`→`skills/` reference-integrity gate (dangling + path-coupled)

**Effort: Medium × Leverage: High.**

**(a) Current LLM-carried obligation.** `skills/writing-skills/SKILL.md:305-314` — cite skills by name only (`:307-309`, with the path form explicitly marked ❌), and "**Skills must be self-contained.** A skill cannot rely on files outside its own directory" (`:314`).

**(b) Observed failure mode.** Three live path-coupled violations (m-U-3: `manager-routing-guide:79`, `agent-evaluation:103`, `icon-init:233`). No live *dangling* name reference — I checked every backticked kebab-case token across `skills/`, `agents/`, `commands/`, `.claude/skills/` and `README.md` against the on-disk skill and agent inventory; the only non-resolving tokens are the deliberate illustrative names in `writing-skills:255-258` (`creating-skills`, `git-commit-guidelines`, …) and the historical `rfc-format`/`rfc-refactor` mentions in `rfc:349`. That the 2.0.0 rename swept cleanly is a credit to the ICON-0080 sweep — but `.context/retrospectives.md:43` records that it did **not** sweep cleanly on the first pass: *"under-scoped the skill cross-reference sweep (missed `find-context-template` and `context-maintenance` … ), forcing a gap pass — give sweep coders a **whole-tree grep mandate**, not just a hand-curated file list."* A whole-tree grep mandate is a script specification written in prose.

**(c) Mechanization.** `skills/writing-skills/scripts/check-skill-refs.sh`, two passes over staged `skills/**` / `agents/**` / `commands/**` / `README.md`. **(i) Dangling-name** — every backticked token matching `^[a-z][a-z0-9]+(-[a-z0-9]+){1,4}$` resolves to `skills/<name>/`, `.claude/skills/<name>/`, or `agents/<name>.agent.md`; unresolved tokens are reported unless allowlisted (a small `writing-skills/ref-allowlist.txt` covers the naming-guidance examples). **(ii) Path-coupling** — reject any `skills/<name>/`, `<other-skill>/<file>.md`, or `shared/<file>.md` literal inside a skill body. This is the direct `skills/` analogue of the `context-graph.sh --check` dangling-ref gate that already runs at `.githooks/pre-commit:759-812` for `.context/`; the design precedent, the exit contract, and the marker convention all exist and can be reused rather than invented. **Fail-closed.**

**(d) Residual judgment.** Whether a cross-reference *should exist at all* — a reference the script can resolve may still be the wrong coupling. And the resolution when `:314`'s self-containment rule bites: duplicate the content into the citing skill, extract it to a shared surface, or restructure. `writing-skills:314` itself leaves that open ("copy it into the skill that needs it, **or** reference a sibling skill the agent loads explicitly"), and it should stay open.

**(e) Note.** Pass (i) is the class that would have made the `mr-*` / `jira-story` rename mechanically safe rather than sweep-dependent. Pass (ii) is cheap and would catch all three m-U-3 instances today.

---

### SO-4 — Generalize `O-M1b` from one hard-coded literal to a declared-literal registry

**Effort: Medium × Leverage: Medium.**

**(a) Current LLM-carried obligation.** The standing ICON-0015 O-V4 recommendation (a literal-grep gate), which the baseline preamble lists as unimplemented after 3+ cycles. It is in fact **partially** implemented: `.githooks/pre-commit:650-700` derives `ENTRY_CAP` from `skills/post-incident-review/scripts/append-retrospective-entry.sh` and checks four bespoke narrating patterns (`cap (N)`, `older than the Nth`, `keep-last-N`, `N entries to scan`) against it. That is one literal, four hand-written regexes, and no extension path — the general obligation stays with the LLM.

**(b) Observed failure mode.** m-U-7, twice, this cycle: `README.md:162` still describes `ecological-impact` as measuring "a **Copilot** session" thirty tasks after ICON-0059 made the skill platform-neutral; `README.md:172` still tags `rfc` "(ORG-004)" after ICON-0080 removed the defining URL. `.context/retrospectives.md:8` (ICON-0086) states the rule this violates: *"A feature removal is complete only when every DEPENDENT reference is swept … A repo-wide grep for the feature's own identifiers … is what makes the removal complete."* `.context/retrospectives.md:43` says it again for ICON-0080. The class has now produced retro entries in at least two consecutive tasks and two live defects in this audit.

**(c) Mechanization.** Replace the hard-coded `ENTRY_CAP` block with a loop over a declarative registry — `.context/literals.json`, each entry naming: a canonical source (file + extraction regex, or a literal value), a set of narrating patterns, and a scope glob. `ENTRY_CAP` becomes the first entry, preserving current behaviour exactly. New entries are then one JSON object rather than a hook edit: registering `ecological-impact`'s platform framing (pattern `Copilot [Ss]ession` scoped to `README.md` + `skills/ecological-impact/**`, expected: absent) and `rfc`'s `ORG-004` would have caught both m-U-7 instances at commit time. **Fail-closed.** Note the `O-M1b` comment block at `:646-648` already documents the discipline that makes this safe — patterns must be narrow enough not to match version strings or token counts — so the guardrail is written; only the indirection is missing.

**(d) Residual judgment.** *Which* literals earn registration — over-registering produces false positives and pattern-maintenance burden, and the existing comment's warning about narrowness is a judgment call per pattern. Also whether a detected mismatch is drift or a deliberate divergence (ADR-003 already carves `plugin.json`/semver out of scope for exactly this reason).

**(e) Note.** This is the one candidate that is *partially* discharged. Reporting it as unimplemented would be inaccurate; reporting it as done would be too. The gap is generality, not existence.

---

### SO-5 — Skill size gate

**Effort: Low × Leverage: Medium.**

**(a) Current LLM-carried obligation.** `skills/writing-skills/SKILL.md:208` — "Keep SKILL.md under 500 lines; split into supporting files beyond that" — plus the word-count targets at `:268-271` and the self-check idiom at `:297-301` (`wc -w skills/path/SKILL.md`), which is a script invocation the author is trusted to run and act on.

**(b) Observed failure mode.** m-U-1, three cycles. ICON-0033 fixed 549 → 499 (`CHANGELOG.md:172`); ICON-0047 reopened it to 524 (ICON-0058 m-U-1); it now stands at **532** — regressed further with no fix in the interval. Each detection has come from an audit, months apart. No other skill in scope is near the cap (next largest in scope: `rfc` at 349, `ecological-impact` at 248), so this is currently a one-file problem — which is what makes a gate cheap and safe to add now.

**(c) Mechanization.** Fold into SO-1's script: `wc -l` each staged `skills/*/SKILL.md`; compare against a cap. Because `writing-skills:271` already sanctions "Complex discipline skills can go longer, but earn every line", the gate needs either a per-skill declared budget (a `# icon-max-lines: N` comment, justified in the commit that raises it) or a two-tier cap. There is direct precedent for the shape: `context-document-guidelines:47-56` defines a **two-gate** size rule for `.context/` docs (16,000 bytes **AND** ≥3 peer `##` sections) with a documented exemption arm at `:80-102` — and that rule is already enforced mechanically via `context-maintenance § File Size Rule`. The same two-gate + exemption pattern transfers directly to skills. **Fail-closed** once budgets are declared; ship warn-only for one release to establish the baseline.

**(d) Residual judgment.** **Which section to extract** — the entire substance of the fix. IO-U-3 argues for the frontmatter/discoverability cluster; ICON-0033 chose the creation checklist; ICON-0058's IO-U-4 offered three options including amending the rule itself. A script can say "over budget"; only an author can say what the file is really two of.

**(e) Note.** Worth observing that `context-document-guidelines` itself is 16,767 bytes with ten peer `##` sections — it would trip both of its own gates if it were a `.context/` doc. It is not one, so this is not a violation; it is an argument that the threshold the skill chose is a realistic one for prose of this kind, and that a skills-side cap should be calibrated deliberately rather than inherited.

---

## ICON-0058 Delta

### Fixed since ICON-0058

| ICON-0058 ID | Description | Closing task / evidence |
|---|---|---|
| **M-U-1** | `ecological-impact` Copilot-product coupling in the Option-A path (ADR-004) — the three-cycle carry-forward the brief asked me to check for a fourth | **ICON-0059**, `CHANGELOG.md:91`. Verified on disk: `:4` "their AI session"; `:43` "Option A — Monthly Usage (Preferred)"; three co-equal platform branches at `:47`/`:53`/`:58` incl. a Claude Code sub-option; report headers at `:152` and `:211` read "🌍 AI Ecological Impact Report". **Did not survive four cycles.** Residue: the README row (m-U-7). |
| m-U-3 | `rfc/SKILL.md:19` live DataScan Confluence URLs | Fixed — `:19` now reads `` `<your-rfc-process-doc>` … `<your-rfc-guidance-doc>` ``. Introduced a new defect in doing so (M-U-2). |
| m-U-5 | `characterization-testing` + `mcp-tools-first` absent from the README Internal Skills table | **ICON-0080**, and *mechanized*: `.githooks/pre-commit:708-732` `O-V1` gate. `characterization-testing` at `README.md:185`; `mcp-tools-first` removed entirely. **50/50 skills registered.** Gate confirmed firing in `.context/retrospectives.md:43`. |
| m-U-6 | "plugin-lint Check A/B" labels with no formal definition | **ICON-0071**, `CHANGELOG.md:60`. `grep -rn "plugin-lint" skills/ agents/ commands/ .claude/ README.md` → zero hits. |
| m-U-2 | `sprint-goals` live org URL at `:20`,`:196` | **Moot** — skill deleted by ICON-0080 (`CHANGELOG.md:40`). ADR-010 m9 records the disposition as Closed. |

### Still present or partial

| ICON-0058 ID | Current state |
|---|---|
| **m-U-1** | `writing-skills` line-cap self-violation. **Regressed**: 524 → **532 lines** against its own `:208` rule. Third audit cycle. Re-tiered as m-U-1 this report; mechanization proposed as SO-5. |
| m-U-1 (word-count axis) | 3,160 → **3,181 words** against `:270`'s "< 500 words". Arguably self-exempted by `:271` for complex discipline skills; the line cap is not. |
| m-U-4 | `plugin-design` "plugin-agnostic" self-contradiction — **still present** at `skills/plugin-design/SKILL.md:14` ("Plugin-agnostic — it ships with ICON but applies to any **Claude Code** plugin"), unchanged across three cycles. **Note**: `plugin-design` is not in this cycle's brief `## Scope` list (it was covered by ICON-0058's domain 04), so I am recording state for delta continuity, not claiming ownership. Flagging for the synthesis pass to assign. |
| ICON-0015 O-V4 | Literal-grep gate — **partial**, not absent. `O-M1b` (`.githooks/pre-commit:650-700`) implements it for one literal (`ENTRY_CAP`). Generalization proposed as SO-4. |

### Net-new

1. **M-U-1** — `ecological-impact` worked example (`:210-227`) disagrees with its own formulas by 1000×, is internally inconsistent on the milliTrees conversion, has a ~6.6×-wrong car equivalent, and the headline rate at `:102` is ~57× its own cited basis at `:103`. Four audits have read this block without checking the arithmetic.
2. **M-U-2** — `rfc` cites `ORG-004`/`RFC-001` as normative in nine places incl. the description and an `(Authoritative)` step heading, with no definition anywhere in the plugin. Regression introduced by the m-U-3 URL fix; ADR-011 (the sanction) is `Status: Superseded`, ADR-010 m9 is Closed.
3. **M-U-3** — `github-issue:4`, `post-meeting:4`, `rfc:4` carry workflow-summarising descriptions violating `writing-skills:160` and the named failure story at `:165-183`. Type-correlated: all three are the Format type.
4. **m-U-2** — Two ordered-sequence discontinuities from 2.0.0 removals: `icon-init:215` (orphaned Step 5a) and `icon-status:118,130` (Signal 1 → Signal 3).
5. **m-U-3** — Three path-coupled cross-skill references violating `writing-skills:305-314`: `manager-routing-guide:79`, `agent-evaluation:103`, `icon-init:233`.
6. **m-U-4** — Fourteen skills on an undocumented "Internal … Do not invoke" description convention contradicting `writing-skills:160`.
7. **m-U-5** — `agent-evaluation:89-115` off-topic frontmatter section (RULE 4 self-violation, placed inside the prompt payload before `$ARGUMENTS`) + `:5` `argument-hint`, the plugin's only undocumented frontmatter key.
8. **m-U-6** — `manager-routing-guide:133` attributes the tier→model decision to ADR-004; ADR-014 owns it.
9. **m-U-7** — `README.md:162` and `:172` carry literals the skills no longer use (post-ICON-0059 / post-ICON-0080 sweep residue).
10. **m-U-8** — `github-issue:29-35` file write with no overwrite guard or idempotency statement; `icon-status:106-111` unguarded `python3` in a user-facing dashboard where `icon-init:69-77` already models the safe idiom.
11. **m-U-9** — `start-worktree:93-102` writes an undeclared `## Worktree` section into `plan.md`, whose schema `task-plan` owns.
12. **m-U-10** — `github-issue` and `post-meeting` have no trigger surface in either frontmatter or body.
13. **m-U-11** — `rfc:88,100,121` sub-step headings omit the skill-name prefix required by `writing-skills:220-233`.

### Rename / removal residue sweep (2.0.0 interval) — result

Clean on names, dirty on structure and wording.

- `grep -rnE 'mr-discipline|mr-feedback-triage|jira-story|mcp-tools-first|setup-mcp-servers|sprint-goals'` across `skills/`, `agents/`, `commands/`, `.claude/`, `README.md`, `.claude-plugin/` → **zero hits**. (Surviving mentions are confined to `CHANGELOG.md`, `.context/tasks/`, `.context/retrospectives-archive.md`, and ADR history — all correct.)
- `grep -rniE 'gitlab|jira|confluence|atlassian|merge request' skills/` → **zero hits**.
- Backticked-identifier sweep against the on-disk skill/agent inventory → **no dangling name references**; all non-resolving tokens are deliberate naming-guidance examples (`writing-skills:255-258`) or historical predecessor mentions (`rfc:349`).
- **Orphaned skills**: none. All 50 have a README row (`O-V1` gate) and every in-scope skill is reachable from `using-skills`, a consuming agent, or the slash-command surface.
- **Residue found**: structural — `icon-init` Step 5a orphaned by the `setup-mcp-servers` removal (m-U-2); lexical — `README.md:162`/`:172` (m-U-7); conceptual — `rfc`'s `ORG-004`/`RFC-001` orphaned by their own URL removal (M-U-2).
- **One out-of-domain observation for the synthesis pass**: `.context/domains/github-access.md:11` references the `setup-mcp-servers` / `mcp-tools-first` skills in the present tense; both were removed by ICON-0080. Not a `skills/` defect and not in this brief's scope — flagging only because it is the same removal-residue class and I hit it while sweeping. `.context/decisions/006-*.md:21,31` also references `setup-mcp-servers`, but that is an ADR recording history and is correct as written.
