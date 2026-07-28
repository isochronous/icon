## Task: ICON-0095
## Branch: feature/ICON-0095-hot-cold-skill-separation
## Objective: Adopt hot path / cold path separation for skills — `SKILL.md` keeps only the instructions every invocation executes, and conditional content (modes, platform branches, rarely-taken paths) moves into companion files loaded deliberately. Establish the standard, the ADR, and a mechanical gate, then prove it on `skills/upgrade-repo/SKILL.md`. Closes GitHub issue #51 (new Milestone 0 — runs before M3).
## Folder: .context/tasks/ICON-0095-hot-cold-skill-separation/

## Phase State
- **Phase plan**: investigation → architecture → implementation → completion
- **Completed**: investigation, architecture
- **Current**: implementation   (status: in-progress)
- **Next**: completion
- **Loaded skill**: task-plan-phase-implementation
- **Branch**: feature/ICON-0095-hot-cold-skill-separation
- **Attempts (current phase)**: 1

## Decisions
- Task ID `ICON-0095` from `local_task_id_prefix` + next free slot — **not** from issue #51 (`.context/workflows/commit-conventions.md` § Task ID Generation).
- **`architecture` is in the phase plan**, unlike ICON-0093/0094. This task defines a convention every future skill inherits and adds a governing ADR that must be reconciled against an existing one — that is a structural decision, not an implementation detail. Ambiguity here is cheap to fix now and expensive later.
- **Sequenced before Milestone 3** (user decision): hot/cold decides where *instructions* live, M3's `.mjs` migration decides where *code* lives. Designing this first means the migration lands content in the right structure instead of moving it twice. Both point at `upgrade-repo`.
- **The cut follows the condition, not the topic** (maintainer directive, this turn). The failure mode to design against: a companion file that bundles two branches, so taking branch A drags B into context anyway — you pay the indirection *and* still load the bulk, which is worse than not splitting. The unit of extraction is **one if→then block**: everything needed when a condition holds, and nothing else. Two tests define correct granularity:
  - **Cohesion** — for a companion file, is there any invocation that loads it and uses only *part* of it? If yes it bundles more than one condition and must split further.
  - **Coupling** (the inverse, to prevent confetti) — is there any pair of companion files always loaded together? If yes they are one condition and should merge.

  This is independently forced by the harness: references must stay **one level deep** or they degrade into silent partial reads, so the decomposition cannot be hierarchical. Flat fan-out, one file per condition, siblings that never reference each other.
- **Corollary — a threshold measured on `SKILL.md` alone is gameable and would actively incentivise the bundling defect.** It rewards moving bulk anywhere, including into one giant companion. The gate must measure the companions too, or measure the *loaded set* per branch rather than the entry file.
- **This extends existing practice rather than inventing a mechanism.** The pattern already exists unnamed in four places — `skill-decomposition.md` is a thin index over seven topic sub-files; `task-plan` loads exactly one `task-plan-phase-*` per phase; `context-maintenance` holds `context-graph.md` as an on-demand reference (ADR-008 cites it as precedent); `skill-structure.md` already covers "sub-file layout for heavy-template skills". The deliverable is a governed rule with a threshold and a gate, not a new idea.

## Key Files
- `skills/upgrade-repo/SKILL.md` — **12,796 words / 1,631 lines**, the proving case. A 4× outlier: next largest is 3,314. A run executes perhaps a fifth of it (Phase 0 branches 3 ways on repo state, Phase 2's pruning step 4 ways on installed state, and every executable block ships as a bash/PowerShell pair of which exactly one runs).
- `.context/decisions/008-always-loaded-token-budget.md` — the existing budget (8,500 manager / 7,000 PM session; 40% per-component cap) and, critically, the scope line that leaves this ungoverned: *"Phase skills, sub-agent files, and on-demand skills are NOT in the always-loaded set."* The new ADR must reconcile against it, not overlap it.
- `.context/standards/skill-decomposition.md` + `skill-decomposition/skill-structure.md` — the partial precedent ("sub-file layout for heavy-template skills") that must be reconciled rather than left as a second convention.
- `.context/standards/context-document-guidelines.md` / `skills/context-document-guidelines/SKILL.md` — holds the 16,000-byte folder-split threshold for `.context/` docs. Precedent for how a size threshold is expressed and enforced here.
- `.githooks/pre-commit` — where a mechanical gate would live. ADR-008 names "no automated pre-commit lint counting session totals" as a candidate future hook; ADR-005 permits a committed dependency-free script run in place.
- `skills/writing-skills/SKILL.md` — authoring guidance; must teach the new rule or it will not be followed.
- `README.md` — skill registration table; a pre-commit check gates it, so new companion files must not break it.

## Size census (2026-07-27, shipped skills, `wc -w`)
| Skill | Words | Lines |
|---|---|---|
| `upgrade-repo` | **12,796** | 1,631 |
| `context-document-guidelines` | 3,314 | 265 |
| `writing-skills` | 3,181 | 532 |
| `context-maintenance` | 2,702 | 339 |
| `rfc` | 2,500 | 349 |
| `initialize-multimodule` | 2,481 | 471 |
| `context-specialist-impl-leaf` | 2,193 | 350 |
| `initialize-workspace` | 1,901 | 363 |

The distribution matters for threshold-setting: one extreme outlier, a cluster at 2,000–3,300, and a long tail below. A threshold that catches only `upgrade-repo` is a bug report with a gate attached (the ROADMAP "Not building" section rejects exactly that shape for the skill-size gate). A threshold that catches the 2,000–3,300 cluster is a real convention. **Which is intended is an architecture question, not a coder's call.**

## Harness findings (Claude Code) — the premise is verified, and the case is stronger than efficiency
Source: live fetches of `code.claude.com/docs/en/skills.md`, `code.claude.com/docs/en/plugins-reference.md`, and `platform.claude.com/.../agent-skills/best-practices`. Documented claims separated from inference below.

**The premise holds.** On invocation, only the rendered `SKILL.md` body enters context, as a single message. Companion files enter **only** if the model subsequently issues its own `Read`. Verbatim: *"Reference these files from your `SKILL.md` so Claude knows what they contain and when to load them"*, and *"No context penalty for large files: Reference files, data, or documentation don't consume context tokens until actually read."* So the split is mechanically real, not cosmetic.

**The stronger argument — a correctness bug that exists today, independent of efficiency.** Verbatim: *"When the conversation is summarized to free context, Claude Code re-attaches the most recent invocation of each skill after the summary, keeping the first 5,000 tokens of each. Re-attached skills share a combined budget of 25,000 tokens."*

`upgrade-repo` at 12,796 words is roughly 16–17k tokens (estimate, not a documented conversion) — **more than 3× the 5,000-token per-skill retention cap.** So on any compaction, everything past roughly the first 5,000 tokens is **silently dropped**, not merely deprioritised. Given a `/upgrade-repo` run is long and multi-phase, compaction mid-run is likely, and the content most likely to be dropped is the late-phase conditional material. This reframes the task: it is not primarily a token-economy optimisation, it is repairing a skill that already cannot survive its own runtime. That belongs in the ADR's Context section.

**The documented pattern has a name and a prescribed shape.** "Progressive disclosure", three patterns; **Pattern 3 — Conditional details** is exactly ours (*"SKILL.md shows the basic/default path inline, and links to a companion only for the non-default branch"*). Adopt the documented shape rather than inventing one.

**One level deep — this is a hard constraint, and it directly reinforces the granularity rule.** Verbatim: *"Claude may partially read files when they're referenced from other referenced files… Claude might use commands like `head -100` to preview content rather than reading entire files, resulting in incomplete information. **Keep references one level deep from SKILL.md.**"* A chained reference degrades **silently into a partial read** — no error. So the decomposition must be a **flat fan-out from `SKILL.md`, never a tree.** Combined with the maintainer's granularity rule, that fully determines the shape: one file per condition, all siblings, none referencing each other. Where two branches share content, duplicate the few shared lines or promote them back into `SKILL.md` — do **not** chain.

**Reference mechanism.** `${CLAUDE_SKILL_DIR}` is substituted **by the harness before the model sees the text**, and resolves to the skill's own directory (`${CLAUDE_PLUGIN_ROOT}` resolves to the plugin root and would need manual re-appending, breaking if a skill moves). Use `[${CLAUDE_SKILL_DIR}/x.md](${CLAUDE_SKILL_DIR}/x.md)`. A plain relative link probably works but rests on inference, not a documented resolution guarantee — prefer the documented mechanism in a standard. **Always forward slashes**, even authoring on Windows.

**Other documented constraints to encode:**
- *"Keep `SKILL.md` under 500 lines"* — a recommendation, not enforced. Note the unit is **lines**, a third unit alongside ADR-008's words and `context-document-guidelines`' bytes.
- Files over 100 lines should carry their own table of contents, so a partial read still surfaces scope.
- Descriptive filenames tied to content; never `doc2.md`.
- Installed plugins **cannot reference files outside their own directory** — `../shared-utils` breaks post-install. Rules out sharing one companion across skills via `../`.
- The `description`/`when_to_use` frontmatter is the **only** thing driving discovery; companions have no frontmatter and contribute nothing. **Trap**: if the refactor trims the description while moving detail out, Claude may load the skill correctly and then not know a relevant companion exists. The description must still name every scenario now living in a companion.
- Skill *listing* has its own separate budget: 1,536 chars per skill description, whole listing scaling at 1% of context. `/doctor` and `/context` report actual cost — worth checking given how many skills ICON ships.

**MUST VERIFY in architecture — a hole that would invalidate part of the design.** Verbatim: *"Subagents with preloaded skills work differently: the full skill content is injected at startup."* If any of ICON's nine agent definitions declare a `skills:` frontmatter field, those skills' bodies load **unconditionally at agent spawn**, regardless of whether the branch is ever taken. Check `agents/*.agent.md` for a `skills:` field before finalising the standard; if present, those skills need different treatment.

**Genuinely unknowable without empirical testing** (flagged as such by the specialist, not to be papered over):
- whether Claude reliably takes the `Read` for a Pattern-3 conditional link *as we phrase it*, versus guessing the branch content. Both under-reading (*"Does Claude fail to follow references… Your links might need to be more explicit or prominent"*) and over-reading (*"If Claude repeatedly reads the same file, consider whether that content should be in the main SKILL.md"*) are documented observed failure modes with no mechanical guarantee.
- **Settling test**: the `skill-creator` eval workflow, 3+ realistic prompts per branch, before and after the split, diffing whether the correct companion was read (visible in the subagent tool-call trace) and tokens/duration per invocation. Worth running once on `upgrade-repo` before enshrining the standard.

## Corpus findings — and two decisions they forced

### The bundling defect has already shipped, twice — in `skills/`
- **`skills/writing-skills/anthropic-best-practices.md` — 5,002 w / 38,305 B.** Larger than every `SKILL.md` except `upgrade-repo`; 2.4× the 16 kB `.context/` threshold; 147% of ADR-008's per-component cap. And `writing-skills/SKILL.md:21` says *"Read before authoring your first skill"* — it is on the **modal** path, not a rare branch.
- **`skills/generate-phase-launcher/references/launcher-templates.md` — 2,857 w / 23,043 B.** Bundles all five launcher templates (A-bash, B-pwsh, C1/C2/C3-generic) when an invocation needs exactly one. **This is the maintainer's named defect, already in the tree.**

### A `SKILL.md`-only threshold is provably gameable — measured, not argued
| Skill | `SKILL.md` | Companions | **Directory total** |
|---|---:|---:|---:|
| `upgrade-repo` | 12,796 | 0 | **12,796** |
| `writing-skills` | 3,181 | 8,930 | **12,111** |
| `icon-audit` (maintainer) | 1,310 | 5,302 | **6,612** |
| `plugin-design` | 431 | 4,106 | **4,537** |
| `generate-phase-launcher` | 1,677 | 2,857 | **4,534** |

By `SKILL.md`, `writing-skills` ranks #3 and `plugin-design` #47 of 49. By directory total, `writing-skills` is **#2 at 95% of `upgrade-repo`**. A `SKILL.md` measure declares it compliant while it carries nearly the same burden as the file this task exists to fix.

> **SUPERSEDED by @architect (D3.4).** This section's *measurement* is right — a `SKILL.md`-only gate is gameable — but the inference "therefore sum the directory" does **not** follow. Measured in bytes, a directory-sum gate flags `plugin-design` (**35,832 B**), the corpus's best-decomposed skill and the exemplar the standard is built on, as a **worse** offender than `context-document-guidelines` (22,518 B), the proving case. A standard whose own model fails it is not a standard. The correct anti-gaming construct is a **per-companion cap** — see `## Architecture decision` below. Retained here because the reasoning that produced it is sound and the reversal is instructive.

### Violation population by threshold — the decision-relevant number
| Measure | Threshold | Population |
|---|---:|---:|
| `SKILL.md` alone | > 3,500 w | **1** — ROADMAP's "bug report with CI attached" objection stands verbatim |
| `SKILL.md` alone | > 3,300 w | 3 |
| `SKILL.md` alone | > 2,000 w | 7 |
| **Directory total** | **> 4,000 w** | **4** — three of which have *already split* and are still over |
| Per-companion cap | 2,500 w | 2 — exactly the two demonstrable cohesion failures |

There is a **9,482-word gap between #1 and #2** on `SKILL.md`; any threshold in 3,315–12,795 finds exactly one file. Directory total is what clears the ROADMAP objection.

### Empirical size of a well-formed companion
Median skill companion: **~660 w / ~5,100 B**. 25 of 30 fall in 170–970 w — that is what one condition costs when an author writes one condition per file (`plugin-design`, the `icon-audit` briefs, `context-maintenance`). The 1,200–2,200 w cluster is "topic chapter" shaped. Only two exceed 23 kB, and both are the cohesion failures above.

### Nine size rules, four units, one enforced — consolidate, don't add a tenth
`writing-skills:208` says "under 500 lines"; `skill-structure.md:56` says "~150 lines or fewer" — **a live 3.3× contradiction**. `writing-skills:270` (<500 w for a standard skill) is violated by **13 of 49** shipped skills. ADR-008 chose words and explicitly rejected lines; `context-document-guidelines` chose bytes and explicitly rejected lines. `skill-structure.md:67` cites `writing-skills:140-152` as its source for size guidance — **that citation is stale**; those lines are now a layout example. Adding a tenth rule in a fifth unit makes this worse. **The standard must retire the contradicting statements, not sit beside them.**

### Why `skill-structure.md`'s existing rule never caught `upgrade-repo`
Not negligence — the rule is out of domain. Its trigger is *content type* ("templates ≥ 100 lines, reusable scripts, or per-domain dispatch briefs"); `upgrade-repo` has none of those, it has **procedure** — 1,253 of 1,631 lines are inline migration shell inside 23 fences. And its "~150 lines" cap is stated as a property of skills that *have already adopted* the layout, never as "a skill over 150 lines must adopt it". No mechanical enforcement anywhere.

### Shape E — the best precedent, and it was missing from issue #51
`skills/plugin-design/` is a 431-word pure router over **10 companions**, with a mode-detection table, a **"Loaded by" column** making the load graph auditable, an explicit *"The mode entry loads the relevant phase files in sequence — do not pre-load them"*, and an ambiguity handler (*"ask which mode they want before loading either companion file. Do not guess."*). Every companion is 173–723 w — all pass cohesion. It uses **bare filenames**, which is what the `writing-skills` no-`@`, no-literal-path rules require. Five distinct shapes exist in the repo; this is the one to standardise on.

### `upgrade-repo` — why it is the wrong proving case
- **The platform axis cross-cuts completely.** All 8 PowerShell fences sit **inside** mode-conditional regions; there is no region that is platform-conditional but not also mode-conditional. Splitting both **multiplies**: ~16 files where a post-#23 design needs ~5.
- **The largest block cannot be split by condition at all.** C2d (prune-context, lines 552–1207) is **656 lines — 40% of the file** — a four-way branch resolved *inside one indivisible script*, and the skill forbids decomposition in its own text: *"Run it as a unit; never lift the `cp` out of it and run that alone."* Any companion bundles four conditions by construction. It is also precisely what #23 rewrites.
- **A correct split does not fix it.** ~900 lines move; `SKILL.md` lands near 700 lines / ~5,000 w — still the largest skill in the repo and still over any threshold that catches anything else. **Only #23 brings it under.**
- Conditions are **interleaved, not nested**: C2e/C2f are the deferred second half of C2d's rows, sitting 650 lines away with unrelated always-run content wedged between.
- **Correction to issue #51**: it claims "a typical run touches perhaps a fifth of it". Line accounting says **~36%**. Do not cite the issue's figure in the ADR.

### Two decisions taken (user, this turn)
1. **Prove the standard on `context-document-guidelines`, not `upgrade-repo`.** It is 57% cold with clean, non-interleaved conditions and no platform twins — *"the best-shaped candidate in the corpus"*. `upgrade-repo` is deferred to after #23. This keeps M0 first as decided while avoiding ~8 platform companion pairs that #23 would delete.
2. **The gate ships advisory, and becomes fail-closed once #24 lands a CI backstop.** #24 states verbatim that *"adding an eleventh gate to an unbacked, bypassable, opt-in stack raises the surface without raising the guarantee"* and *"do this before building any new check in this milestone"*. Verified: `.github/workflows/` holds only `security.yml` (gitleaks/semgrep/shellcheck) and re-runs **none** of the ten pre-commit checks. The ADR records the promotion condition.

### Mechanical hazards for implementation
- **The `dead-ref-ok` marker pair is the most likely breakage.** `upgrade-repo` wraps lines 324–550 — exactly condition C2c, exactly a block a split would move. The awk is per-file with `BEGIN { in_exempt = 0 }`, so a split leaving `-start` in one file and `-end` in another **silently disables the check to EOF in one and fails immediately in the other**. Markers must move as a balanced pair.
- **The dead-ref resolver scans companion files too** — `skills/*.md` is a bash `case` glob, and `*` matches `/`. Sibling references like `phase-two.md` do not match its `.context/…` regex, so they are safe; literal `.context/` paths in a companion are not.
- **`context-graph` gates do not see `skills/` at all.** So a split gains no orphan detection — if a pointer is later deleted from `SKILL.md`, nothing notices the orphaned companion. Shape E's "Loaded by" manifest is the only existing construct that would make that auditable.
- **README registration**: companion `.md` files are safe (the check globs one level and keys on `SKILL.md` presence). Shape B — separate registered skills — costs a README row each.
- **Skills cannot rely on files outside their own directory** (`writing-skills:310-316`) — rules out any shared cold-path library across skills.
- **`context_template/` has no skill-shaped content**, so no `iconrc.json` bump. But `context_template/context/workflows/task-plan/` is a sixth instance of this pattern and is already exempt from the `.context/` size rule under the Distributed Template arm — reconcile if the standard ever extends there.
- **Open**: does the `## skill-name: Step N:` heading-prefix rule apply inside companion files? `writing-skills:210-216` is silent; `plugin-design`'s companions are the existing answer and were not read.

### Still unverified — carry into architecture
- **The no-`@`-link rationale is stated as a runtime claim, not a verified property**: *"in some runtimes the `@` prefix force-loads a file the moment surrounding text is read"*. Every precedent complies, but nothing in the repo demonstrates the behaviour. The Claude Code side is now documented (see Harness findings above); **Copilot CLI is not**. ADR-004 requires both.
- Whether measurement should be bytes, words, or tokens. For `upgrade-repo` the units disagree in direction — 77% of it is code fences, where `wc -w` badly undercounts tokens (`"$TEMPLATE_DIR/context/decisions"` is one word, ~8 tokens).
- **`.githooks/pre-commit` carries two live fail-opens**, neither in #46's enumerated list — a gap in that issue. **Line numbers below are post-gate-insertion and current**; the earlier citations (`:662`, `:862-869`) were pre-shift.
  - **`:671`** — `grep -oP '^ENTRY_CAP=\K[0-9]+'`, a Rule 7 violation that **fails open**: on BSD, `ENTRY_CAP` is empty, the `[[ -n "$ENTRY_CAP" ]]` guard fails, and the cap check silently no-ops. The hook's header exempts it only from the three-surface sweep; `shell-portability.md:24` explicitly claims `.githooks/pre-commit`.
  - **`:920-926`** — the dead-ref exemption sets `in_exempt = 1` then `next`, making the same-line `-end-->` check unreachable, so a line containing **both** markers opens an exemption that never closes. `skills/context-document-guidelines/SKILL.md:224` is the live instance; lines 225–265 are silently unchecked today. (That file is being split this task — confirm whether the split resolves the instance or relocates it.)

## Architecture decision (design of record — @architect, tier complex)

### Both must-verify holes closed clean
- **No `agents/*.agent.md` declares a `skills:` frontmatter field** — all nine carry only `description:` + `user-invocable:`. The "preloaded skills inject at startup unconditionally" hazard does not exist in ICON. The standard carries a one-line note so a future author does not re-open it.
- **No heading prefix in companions** — all 23 shipped companions use a plain descriptive H1 and unprefixed `##`. One exception codified: a companion carrying a numbered step of the parent's process names the parent in its H1.
- **The `wc -w` undercounts-fences concern is REFUTED at file scale.** Bytes-per-word spans **6.79–8.06** across 0%–79% fence density — a 19% spread against a 29× size spread. Nothing rests on it.

### D1 — Canonical shape: Shape E, flattened to strict depth-1
`plugin-design` **is** currently exposed to silent partial reads — its phase files are discovered *from* the mode files, and 5 of 10 exceed the 100-line preview boundary. A tempting rescue (its manifest names all ten paths in `SKILL.md`, so arguably all are "one level deep") is **rejected as a design principle**: it bets on unverified harness behaviour, which is exactly what a standard exists not to do. Treat the manifest as mitigation, not licence. Flattening `plugin-design` is a follow-up, not this task.

Binding spec: **bare backticked sibling filename** (`` `split-exemptions.md` ``) — not a Markdown link, not `@`, not `${CLAUDE_SKILL_DIR}`. The condition is stated **twice** — once in a required `## Companion Files` manifest with a **`Load when`** column, once inline at the branch point. (`Loaded by` is vacuous in a flat graph; the *condition* is what the tests operate on.) The manifest is required whenever a skill has ≥1 companion — it is the only construct making the load graph auditable, since `context-graph` does not see `skills/` at all. **No frontmatter on companions.** Companions >100 lines carry their own ToC. Forward slashes always.

### D1.6 — Section-name preservation (new rule, forced by a hazard the investigation missed)
`context-document-guidelines` has **14 inbound `§ section-name` citations** — from `.context/decisions/` ×3, `.context/standards/` ×3, `skills/` ×6, and **`context_template/context/decisions/README.md:32`**. When an extraction moves a section other files cite, the companion's **H1 must be the section name verbatim**, or all 14 need sweeping — and one of them reaching `context_template/` would force an `iconrc.json` bump for no benefit. Preservation is what keeps this task's "no template change" property true.

### D2 — Bare filenames over `${CLAUDE_SKILL_DIR}`
The `writing-skills` ban reads on **cross-skill** path coupling and `@`-links; `skill-structure.md:57` explicitly blesses sibling relative references. So bare filenames are not banned — they are prescribed. The real decision is ADR-004: `${CLAUDE_SKILL_DIR}` is documented-portable *within Claude Code only*, and a bare filename rests on inference in **both** harnesses. Tiebreaker is the **failure mode**: an unsubstituted `${CLAUDE_SKILL_DIR}/x.md` is a literal `$`-string naming no file (**unrecoverable**); an unresolved `` `x.md` `` is still a legible filename the model can glob (**recoverable**). Choose graceful degradation. Adoption cost is zero — all five precedents already do this. **The no-`@`-link runtime claim is NOT load-bearing and must not be cited as support** — the decision is unchanged whether it is true or false.

### D3 — Unit, thresholds, and the directory-sum reversal
**Unit: bytes.** Not because words undercount fences (refuted), but because it reuses `context-document-guidelines`' existing constant and unit rather than adding a fifth; converts to tokens by a stable public constant (÷4) where words has none (1.3–1.5, unstable); and `wc -c` is POSIX with zero dependencies. **Lines is retired entirely** — both ADR-008 and `context-document-guidelines` independently rejected it, and it is the unit of the live 3.3× contradiction. Repo ends with **two** units, each with a stated domain: words for the always-loaded surface (ADR-008), bytes for on-demand skill files (ADR-016). Four → two.

| Gate | Cap | Provenance |
|---|---|---|
| Every `SKILL.md` | **16,000 B** | **Derived** — 4,000 tokens = 80% of the documented 5,000-token compaction retention cap, leaving 20% for the harness wrapper. Six such skills = 24,000, just inside the 25,000-token combined re-attach budget. Coincides with the existing `.context/` constant, so one number governs both domains. |
| Every companion `.md` | **8,000 B** | **Empirical** — median well-formed companion ~5,100 B; 25 of 30 sit in 1,200–7,000 B. Top of the healthy band. |
| **Floor — do not create a companion below** | **2,000 B** | The anti-confetti stop, and what makes the cohesion test *terminate*. |

**Sensitivity, stated**: the 16,000 B cap keeps `SKILL.md` under the cliff for any true ratio ≥ **3.2 B/token**; at ÷4 there is 20% margin. If a measurement disagrees, only the constant moves.

**Why not the directory total.** Any directory-sum threshold that catches the proving case declares `plugin-design` (35,832 B) a worse violator than `context-document-guidelines` (22,518 B). The two per-file caps are strictly better: they catch everything the sum catches (`writing-skills` trips them **four times** and *names which four files*), they are ungameable (bulk moved out of `SKILL.md` must land in cohesive ≤8 kB pieces — compliance, not evasion), and they do not punish correct decomposition (`plugin-design`'s largest companion is 6,491 B; all ten pass).

### D3.5 — The two-gate conjunctive structure carries over
**Gate 1** = the byte cap (mechanical). **Gate 2** = *does the file contain ≥2 regions guarded by a condition statable in one sentence, each ≥2,000 B?* Counting `##` sections would be vacuous — every skill has 3+ by template. Gate 2 is deliberately **not** mechanically checkable; the advisory hook's job is to make the author answer it, exactly as `context-document-guidelines:54` does. A genuinely unconditional oversized skill records the finding and stays whole. The corpus already demonstrates the conjunction earning its keep: `step-4-file-content.md` (9,382 B) trips gate 1 but fails gate 2 on the scope test.

### D9 — The third granularity test, and why the floor matters
> **Scope test.** Is the condition resolved **once per invocation**, or **once per item the invocation iterates over**? Only invocation-scoped conditions may be extracted. An item-scoped condition sits inside a loop — a single run encounters items on both sides and loads every arm anyway, so the extraction adds a `Read` per iteration and saves nothing. **Mechanical tell**: find the condition and ask whether any enclosing step says *"for each …"*.

The three tests compose and **terminate**: **scope** (is it invocation-scoped? if not, don't extract) → **cohesion** (does any invocation use only part of it? if so, split — *bounded by the 2,000 B floor*) → **coupling** (always loaded together? merge). Without the floor, cohesion fragments infinitely, since almost any procedure has a step some run skips.

### D5 / D6 / D7 — boundary, argument, scope
- **ADR-016 is a peer to ADR-008, not an amendment.** They constrain different quantities on the one file in both scopes (`using-skills`): ADR-008 caps its *session contribution* in words; ADR-016 caps its *single-file compaction survivability* in bytes. Provably non-contradictory: 16,000 B ÷ 7.1 B/word ≈ 2,250 words < ADR-008's 3,400-word cap, so ADR-016 is strictly tighter. Add a cross-reference line to ADR-008; **no `## Amendments` entry** — nothing went stale, its exclusion was a deliberate scope line.
- **The Context section leads with correctness, not efficiency.** `upgrade-repo` at 92,797 B ≈ 23,000 tokens is **~4.6× past the 5,000-token retention cap**, so ~78% of it is silently dropped on every compaction today. Both caps ship, each labelled with its provenance so a future reader knows which one moves if the harness changes.
- **Scope**: shipped `skills/` **and** `.claude/skills/` — identical failure mode, same harness, same compaction, and **free** (measured population zero; max `SKILL.md` 12,839 B). **Excludes `context_template/context/workflows/task-plan/`** — it is not a skill (no `SKILL.md`, no frontmatter, no invocation), it is already governed and already exempt under the Distributed Template arm, and touching it forces an `iconrc.json` bump for zero benefit. The exclusion is stated *in* the standard so it is not re-litigated at the next audit.

### D4 — Nine rules → the retirements
Delete `writing-skills:208`'s 500-line cap clause and `:270`'s "<500 words" (violated by 13 of 49 — a rule a quarter of the corpus breaks governs nothing); rewrite `:300` to `wc -c`; keep `:269` reworded as an explicit *target*, and `:271` (qualitative, no contradiction). In `skill-structure.md`: delete `:56`'s "~150 lines" (the 3.3× contradiction) and `:67`'s **verified-stale** citation into `writing-skills:140-152`; rewrite `:50`'s content-*type* trigger to the byte gate — that trigger is precisely why the rule never caught `upgrade-repo`, which has no templates or scripts, only procedure. `context-document-guidelines`' 16,000 B rule survives unchanged.

### Violation population — the ROADMAP entry is overturned by measurement
**11 findings across 8 distinct skills**: 7 `SKILL.md` over 16,000 B (`upgrade-repo` 92,797 · `writing-skills` 23,301 · `context-document-guidelines` 22,518 · `context-maintenance` 18,842 · `initialize-multimodule` 18,634 · `context-specialist-impl-leaf` 18,517 · `rfc` 18,418) and 4 companions over 8,000 B. `.claude/skills/` contributes zero. **`ROADMAP.md:176` and issue #32 must be updated** — leaving "its entire violation population is one file" standing reproduces the very failure this task ends.

### Second live fail-open found incidentally
`.githooks/pre-commit:862-869` sets `in_exempt=1` then `next`, so a line containing **both** `dead-ref-ok` markers opens an exemption that never closes. `context-document-guidelines/SKILL.md:224` is exactly such a line — **lines 225–265 are silently exempt from the dead-ref check today.** Harmless now, same fail-open class as `:662`. → follow-up on #46.

### Undecidable without empirical testing — none blocks implementation
1. **Copilot CLI semantics are entirely unestablished** — not whether it renders only `SKILL.md`, not whether it resolves a bare sibling filename, not whether it eagerly loads a directory. **The ADR must state two-harness portability as designed-for and untested**, never as verified. Test: run the post-split skill under Copilot CLI on one triggering and one non-triggering prompt.
2. Whether the model reliably takes the `Read` as phrased. Test: `skill-creator` eval, 3+ prompts per branch, before/after, diffing which companion was read.
3. The bytes→tokens constant. Test: tokenize the corpus once; if <3.2 B/token, lower the cap to `5000 × ratio × 0.8`.
4. Whether separately-`Read` companions count against the 25,000-token re-attach budget. The headline argument does not depend on it.

## Maintainer directive, mid-implementation: records are not capped
> "ADRs, snapshots, framework files (META.md, overview.md, README.md, retrospectives.md, etc.) DO NOT GET THE MAX FILE SIZE CAP" … "any historical or operational record"

**Which rule this changes**: `context-document-guidelines`' Folder Split Rule (16,000 B + ≥3 peer `##` sections, governing `.context/*.md`) — **not** ADR-016's skill caps.

**What already existed** (ICON-0088, extracted into `split-exemptions.md` by this task): two arms — *historical record* (append-only logs, point-in-time snapshots: `retrospectives.md` + archive) and *distributed template* (fixed-shape scaffolds whose section structure is a parse contract: `overview.md`, `META.md`, `rules-index.md`, task-plan templates). **ADRs and `README.md` were not covered, and the arms were enumerated rather than principled.**

**The change**: re-axe rather than add a third list. `boundary-axis-selection.md` governs exactly this — when an exemption needs a special case for a member of its own domain, the special case signals the wrong axis. The principled form: *a file that records what happened or what is, rather than instructing what to do, is exempt* — with the two existing arms demoted to examples. Note ADRs are amended in place (`## Amendments`), so a naive "append-only" test would still miss them; the chosen axis must actually catch them.

**Why it is principled and not a loophole**: the size rule exists because a large *instructional* file costs context on every read and buries its own rules. A record is read selectively by lookup, and its length is a function of history rather than authorial sprawl — capping it would force splitting a chronology, destroying the property that makes it useful.

**Resolves review Minor 4 outright.** ADR-016 was flagged at 15,467 B — **96.7% of the cap it shares**, with 533 B of headroom on a document carrying a promotion condition (#24) and a violation baseline both designed to be edited later. Under the widened exemption it is not capped at all.

**Boundary to state explicitly**: no `skills/` file is a historical or operational record — skills are instructional by definition, so **ADR-016's caps take no exemption**. Stating it prevents a future author arguing a large companion is "reference material, therefore a record."

## Phase Handoff Log

### Handoff: architecture → implementation → completion   (commit: <trailer-marked>)
**Sub-agent outputs**: 1 claude-code-guide harness pass (live doc fetches), 1 Explore corpus investigation, 1 @architect design pass, 7 @coder dispatches, 3 @reviewer passes (2 full at tier complex, 1 confirmation), 1 @context-specialist maintenance pass. Final verdict **approved**.

**Reviewer findings**: R1 2 Moderate / 3 Minor · R2 2 Moderate / 5 Minor · confirmation 0. **No structural or functional defect in either full round**, and R2 confirmed no regression against R1's approvals. All Moderates and Minors remediated except those explicitly recorded as accepted or deferred.

**Verification evidence**: `[check-rules-index] OK` · `[context-graph] OK: 52 nodes, no dangling references, no orphans` · `git status --porcelain context_template/` empty · `iconrc.json` still `1.13` · `plugin.json` untouched · full `.githooks/pre-commit` run end-to-end at **exit 0** with only the three known advisory findings. Proving case `22,518 → 8,396 B` with companions at 7,976 / 5,352 / 5,327 B, all inside `[2,000 , 8,000]`. ADR 20,245 B (exempt as an ADR, four peer `##`, fails gate 2). Standard 11,599 B against the 16,000 B `.context/` gate.

**Decisions delta**: the directory-total measure was adopted then **reversed** on the `plugin-design` counter-example; bytes chosen over words/lines with the `SKILL.md` cap *derived* from the 5,000-token compaction cap; the gate ships advisory pending #24; the proving case moved off `upgrade-repo`; the exemption re-axed to record-vs-instruct carrying both halves of the directive; no `skills/` file can be a record. All mirrored into `## Decisions` and `## Architecture decision`.

**Key files delta**: 2 created in `.context/` (ADR-016, `hot-cold-path.md`), 3 created under `skills/context-document-guidelines/`, plus edits to `skill-decomposition.md`, `skill-structure.md`, `writing-skills/SKILL.md`, `anthropic-best-practices.md`, `context-maintenance/SKILL.md`, `boundary-axis-selection.md`, `decisions/README.md`, ADR-008, `rules-index.md`, `.githooks/pre-commit`, `ROADMAP.md`, `CHANGELOG.md`. **No `context_template/` change, so no `iconrc.json` bump** — a property that holds only because cited section names were preserved verbatim.

**What the next phase needs**: nothing — `completion` is last. Follow-ups to file are listed under `### Deferred to follow-ups`.

**Retro Stage-1 draft**: see `.context/retrospectives.md` — "ICON-0095: A rule that governs nothing is worse than no rule".

## Progress
- [x] Investigation — harness semantics (Claude Code) verified from live docs; full corpus census and conditionality analysis; five existing shapes found (a sixth in `context_template/`); threshold populations measured
- [x] Update this plan with findings before any design decision
- [x] Two sequencing decisions taken with the user — proving case moved off `upgrade-repo`; gate ships advisory
- [ ] **Architecture** — the split rule and its granularity tests, the shape to standardise on, the measure and threshold, the ADR boundary against ADR-008, and which of the nine contradicting size rules get retired ← IN PROGRESS
- [x] Implementation — ADR-016 (15,467 B) + `hot-cold-path.md` standard (9,531 B), both under the cap they define; six size-rule retirements landed; advisory gate in `.githooks/pre-commit`, verified firing correctly and exiting 0
- [x] Implementation — proving case: `context-document-guidelines/SKILL.md` **22,518 B → 8,396 B** plus three companions at 5,393 / 5,352 / 5,327 B, all inside the [2,000 , 8,000] band
- [x] **@reviewer pass** (tier complex, executed) — **changes requested, narrowly**: 2 Moderate + 3 Minor, **no structural or functional defect**. Split and citation-resolution both attacked directly and found sound; reviewer explicitly declined to manufacture a finding there.
- [x] Remediation round 1 — 3 review findings + the records-exemption directive (re-axed per `boundary-axis-selection.md`, not given a third arm) + the satellite site the widening made stale
- [x] **@reviewer round 2** — **changes requested, narrowly**: 2 Moderate + 5 Minor, no structural or functional defect, no regression
- [x] Remediation round 2 — all 7 fixed
- [x] **@reviewer confirmation pass** — **approved**, executed; every stated figure matched measured reality; full `.githooks/pre-commit` run end-to-end at exit 0 with only the three known advisory findings
- [x] `CHANGELOG.md` — four new `[Unreleased]` entries, **and the ICON-0088 exemption entry rewritten rather than appended to** (same subject, both unreleased, so the reader sees only the end state) per the cumulative-effect rule
- [ ] Completion: retrospective, commit, PR ← IN PROGRESS

### Round-2 findings — disposition
- **M1 — the exemption's warrant was falsified by three of its own named members.** `:23` claimed every exempt member independently fails gate 2 anyway — the sentence carrying the whole "principled, not a loophole" argument. True for chronologies (0 peer `##`) and ADRs (template facets of one decision); **false for `META.md` (9 peer `##`), `overview.md` (5), `rules-index.md` (3)**, whose sections are unrelated topics that would divide cleanly. Latent — none reaches gate 1 — but unearned. → **fixed**: the claim is now scoped to the historical arms, with the measured counter-evidence stated for the operational arm.
- **M1b — `META.md` failed the *primary* test, and its row's justification was fabricated.** `META.md:5` — *"explains when and how to update `.context/` documentation"* — is instructional under the file's own definition. It was exempt only because a row asserted *"fixed-shape scaffolds whose headings agents parse"* — **unsupported**: `context-graph.sh:98-120` classifies by **filename**, and `check-rules-index.sh` has no heading parse at all. A row asserting membership the axis does not derive is precisely the symptom `boundary-axis-selection.md` names, and the re-axing existed to remove it.
  - **The root cause was a lost half of the directive.** The maintainer said *"any historical **or operational** record"*; the implementation captured *historical* and dropped *operational*. `overview.md` and `rules-index.md` are now **derived** as operational records — they state the instance's composition, not what to go and do.
  - **`META.md` still is not derived, and @coder declined to force a justification** — the right call, since a warrant you have to strain for is the defect repeating. It found a verifiable second ground instead: `context-specialist-impl-root` Step 12 does `cp "$TEMPLATE_DIR/context/META.md" .context/` under *"Copy verbatim — do not customize template files"*, so it is a template artifact rather than authored guidance and splitting diverges the repo from what `cp` writes. Recorded as a **stated exception outside the table**, with `:29` amended so an author obeying *"apply the test, do not look the file up here"* does not gate it. **Open for the maintainer**: keep the recorded exception, or drop `META.md` and let it be gated. Exempt today because the directive named it.
- **M2 — the census number did not reproduce from its own published pattern.** Stated 17/12; the grep returned 18/12. The delta was exactly one: **the census sentence matched itself.** Three agents produced three counts across this task because the number is a function of the counting file's own prose. → **fixed by deleting the number** and stating the property plus the pattern. The section immediately below argues that a line-number citation into a living file is stale by construction; a self-referential measured count is the same defect in another unit.
- **m3/m3b/m4/m5/m7/m8** — stale self-measurement corrected to a verified fixed point with a re-measure instruction; the decisive self-exemption reason added (ADR-016 has exactly four peer `##`, fails gate 2, so the pre-change rule already said "do not split" — the exemption only suppresses a report line); the truncation argument attributed to the `SKILL.md` cap alone, with the conclusion preserved on the independent primary argument; a "router is not an index" bullet resolving the `skill-decomposition.md` collision; ADR claims qualified as true of ICON-authored rules only; the vendored-file note widened to all three contexts and **labelled mitigation, not a fix**.

### Judgements the review was asked to make rather than describe
- **Is the exemption principled or a loophole?** *Principled in its primary axis, with the stated secondary check falsified* — hence M1. The sharpening question genuinely separates a standards file from a chronology, and the Not-Exempt section fences the obvious over-reach.
- **Is ADR-016's self-exemption sound, or a document exempting itself?** *Sound*, on a reason nobody had stated: **it was never splittable.** Four peer `##` that are the ADR template's facets of one decision → fails gate 2 → the pre-change rule already returned "do not split". The exemption's whole practical effect on this file is suppressing a maintenance-report line item.
- **Does a moving measured count belong in a standard?** *No* — see M2.
- **Was the vendored-file header note a fix or mitigation?** *Mitigation, correctly chosen*, given the body must not be rewritten. Now labelled as such.

### Review findings — disposition
- **MODERATE 1 — the retired 500-line rule survives on the modal path.** Deleted from `writing-skills/SKILL.md:208`, but alive three times in `writing-skills/anthropic-best-practices.md` (`:243`, `:1079`, `:1089` — the last a checklist item), a companion of the *same skill* that `SKILL.md:21` says to *"Read before authoring your first skill"*. **ADR-016's claims that "lines are retired entirely" and "nine rules in four units become two in two" are therefore false as shipped** — the 3.3× contradiction was not resolved, half of it moved into a document authors work through. → **fixing** via a precedence line in the file's existing ICON-conventions header; the body is a **vendored verbatim copy of Anthropic's published guidance** and must not be silently rewritten.
- **MODERATE 2 — the standard undercounts its own citation census**, by exactly the trap it warns about. Claims 13 across 9 files; measured **14 across 10** excluding retrospectives, **16 across 11** including. The miss is `upgrade-repo:1576`, which writes `` `context-document-guidelines` § … `` with the backtick **inside**. The passage's whole job is *"This is not hypothetical"* plus a measured number. → **fixing**, and recording the grep that catches every shape.
- **MINOR 3 — this task falsified a previously-correct statement.** `.context/decisions/README.md:47-48` calls `§ Correcting a stale ADR` a *"sub-section"*; verified against `main` it genuinely was nested, and is now a peer. Not pre-existing — **introduced here.** → **fixing** (one word).
- **MINOR 4 — ADR-016 at 96.7% of its shared cap.** → **resolved by the maintainer's records-exemption directive**, not by a workaround.
- **MINOR 5 — the gate is line-ending sensitive and reads the working tree, not the staged blob.** New files are LF while the repo is mixed CRLF; the same content measures ~1 B/line larger after normalisation (~1.5% at the cap). Fine for an advisory check and disclosed in its comment — **but both must be settled before the #24 fail-closed promotion**, since a blocking gate that disagrees with the committed bytes is a support burden. → **recorded in ADR-016's promotion condition, not fixed now.**

### Reviewer's assessment of two things the architecture did not specify
- **The stub sections Agent B invented are correct and not novel** — they are the shape `process-doc-sweeps.md:61` already prescribes for satellite sites (gloss the canonical rule by reference, never re-enumerate its members). They half-duplicate *definitions*, not *data*, so drift risk is low, and they buy citation resolution at both sites — which is what makes a 16-citation sweep unnecessary.
- **The 2,000 B floor earned its keep on first application**, unusual for a freshly-invented constant: `related-section-seam.md`'s three arms measure 1,503 / 1,769 / 1,212 B — **every one below the floor**, so cohesion says split and the floor says stop. The tests terminate exactly as designed.
- [ ] Completion: reconcile plan.md, changelog, retrospective, commit, PR

### Deferred to follow-ups (file at task close, do not fold in)
- **Split `upgrade-repo`** — after #23 removes the platform axis. Note in #23 that the split follows it.
- **`skills/writing-skills/anthropic-best-practices.md` (5,002 w) and `generate-phase-launcher/references/launcher-templates.md` (2,857 w)** — the two shipped cohesion failures. They are the standard's first real violations; splitting them is the natural second application, not this task's proof.
- **`.githooks/pre-commit:662`'s fail-open `grep -oP '\K'`** — add to #46, whose enumerated list omits it.
- **Issue #51's "a fifth" figure is wrong (~36%)** — correct it on the issue when closing.

### Manager-owned corrections still pending on `ROADMAP.md`
Agent A owns `ROADMAP.md` this turn (the "Not building" entry). **After it reports, the manager must additionally fix the `## Reordered — 2026-07-27` block, which I wrote and which carries two now-falsified claims:**
- *"a run executes maybe a fifth of it"* — measured at **~36%** by line accounting. Same error as issue #51; it propagated from there into the roadmap.
- *"12,796 words"* — correct, but the standard measures **bytes** (92,797 B). Restate in the governing unit so the roadmap does not become the fifth unit in circulation.
- The sentence *"nothing governs this"* is now stale on merge — ADR-016 governs it.

## Open Questions / Blockers
- **What is the loading mechanism, exactly?** A companion file only helps if an agent loads it *deliberately and conditionally*. If the harness eagerly loads a skill directory, or if agents habitually read every referenced file, the split saves nothing and adds indirection. **This must be established by investigation before any design work** — it is the premise the whole task rests on, and `.context/workflows/task-start-conventions.md` § Referenced-convention existence (ICON-0081) says a claimed convention is a hypothesis until verified.
- **Threshold: what number, measured in what unit?** ADR-008 uses words and argues explicitly against lines ("lines vary with formatting in ways that don't correlate with token cost"); `context-document-guidelines` uses bytes for `.context/` docs. Three units in play across three rules is itself a smell.
- **Does the gate fail closed?** `.githooks/pre-commit` is opt-in per clone and `--no-verify`-bypassable with no CI backstop (#24) — so a fail-closed gate here raises surface without raising guarantee until #24 lands. Advisory-with-a-loud-message may be the honest choice.
- **Does the rule apply to shipped skills only, or also to `.claude/skills/` maintainer tooling and `context_template/`?** A `context_template/` change forces an `iconrc.json` version bump.
- **Does splitting `upgrade-repo` belong in this task or a follow-up?** Issue #51 lists it as a task. It is also #23's largest target and #14's working file. Splitting it here proves the standard; deferring it leaves the standard unexercised. Decide in architecture, with the interaction against #14 and #23 stated.

## Constraints
- ICON is pure-content: no build step, no test runner, no package manager (ADR-005). A committed, dependency-free script run in place IS in scope, so a mechanical gate is permitted.
- `.claude-plugin/plugin.json` is the version SSOT (ADR-003) — do not bump; this is not a release.
- ADR-004: content must work on both Claude Code and Copilot CLI. Any loading mechanism must exist in both harnesses, or the convention is not portable.
- **No new PowerShell twins** — standing policy until #23 lands (this session's user decision, recorded in ROADMAP.md).
- Any `context_template/` change requires a same-commit `context_template/context/iconrc.json` bump (currently `1.13`), enforced by `.githooks/pre-commit`.
- Splitting a skill must not break: the README skill-registration check, the `.context/` dead-ref resolver (fence-blind), or the `context-graph` gates.
- The ROADMAP's "Not building" section already rejected a skill-size gate whose "entire violation population is one file" as "a bug report with CI attached". A threshold that only catches `upgrade-repo` reproduces exactly that objection — this task must either clear the bar or explicitly overturn that decision with reasoning.
