# Process Skills Audit — Raw Findings

## Summary

The process-skills domain entered this audit cycle in strong shape after the ICON-0015/0016–0036 improvement sprint closed all five ICON-0015 process Moderates and all five ICON-0015 process Minors on disk. The biggest structural issues — the retrospectives write-path three-surface contradiction (M-CC-NET2 / M-P-B), the `three-layer-enforcement.md` dead reference (M-CC-NET3), the phase-skill template-override duplication (O-T3), and the verification-checklist Gate heading prefix (m-P-6) — are all confirmed fixed. The domain now presents zero Critical and zero Moderate defects under current tiering rules.

Three net-new Minor issues were found: (1) `agent-vs-skill-invocation.md:23` still carries a stale `keep-last-15` prose example after the ICON-0036 cap reduction to 10, and the companion `context-maintenance/append-retrospective-entry.md:3` header also says "last 15 entries" — the bash script was corrected but these two prose sites were missed. (2) The `append-retrospective-entry.md` companion doc at `context-maintenance/append-retrospective-entry.md` has an internal inconsistency: its What-it-does block says "if count ≥ 15, removes one oldest entry" (the pre-ICON-0036/0041 single-prune logic) while the actual script now converges to ENTRY_CAP=10 on every insert. (3) `task-retrospective/SKILL.md` Steps 6–7 ("Completion Gates") create a verified-twice pattern: manager.agent.md Task Completion Step 2 already invokes `verification-checklist` before the retro, and then the retro repeats the same gate at its own Steps 6–7. Neither instance is wrong alone, but the duplication means every task gets verification applied twice without the double-check being intentional or documented.

Four improvement opportunities are presented, all positive-design suggestions requiring no defect correction.

---

## Defect Findings

### Critical

None observed.

### Moderate

None observed. All five ICON-0015 Moderates in the process-skills domain are confirmed fixed on disk (details in the ICON-0015 Delta section below).

### Minor

**m-P-NEW-1 — `agent-vs-skill-invocation.md:23` stale `keep-last-15` example after ICON-0036 cap reduction**

`skills/task-plan-phase-completion/agent-vs-skill-invocation.md:23` reads: `rolling-log behavior (e.g., \`retrospectives.md\` keep-last-15) lives inside the specialist's owned scripts`. The cap was reduced from 15 to 10 in ICON-0036 and the script was corrected to `ENTRY_CAP=10` by ICON-0041, but this inline example was not updated. The number `15` in this sentence now actively misinforms any agent that reads this SSOT doc about the rolling-log behavior. The CHANGELOG confirms ICON-0036 updated `task-retrospective/SKILL.md`, `task-plan-phase-completion/SKILL.md`, `context_template/context/META.md`, and `context_template/README.md`, but `agent-vs-skill-invocation.md` was not in that sweep.

- File: `skills/task-plan-phase-completion/agent-vs-skill-invocation.md:23`
- Fix: change `keep-last-15` to `keep-last-10` (one word). Could also be rephrased to `keep-last-\`ENTRY_CAP\`` to avoid the next cap change requiring another sweep.

**m-P-NEW-2 — `context-maintenance/append-retrospective-entry.md:3` stale "last 15 entries" header and pre-ICON-0041 behavior description**

`skills/context-maintenance/append-retrospective-entry.md:3` reads: `rolling log of last 15 entries`. The same file's "What the script does" block at line 32 says: `If the count is ≥ 15, removes the oldest (last) entry` — describing the pre-ICON-0041 single-prune behavior. The actual script now (a) uses cap=10, not 15, and (b) converges the file to `ENTRY_CAP` on every insert rather than removing one entry. The companion doc that explains the script's behavior is doubly stale.

- Files: `skills/context-maintenance/append-retrospective-entry.md:3` (cap value), `skills/context-maintenance/append-retrospective-entry.md:32` (single-prune description)
- Fix: update header to "rolling log of last 10 entries"; rewrite the behavior block to describe the converge-to-cap logic (matching the actual script comments at `scripts/append-retrospective-entry.sh:24-25`).

**m-P-NEW-3 — Double-verification: `task-retrospective` Steps 6–7 duplicate `manager.agent.md` Task Completion Step 2**

`manager.agent.md:201` ("Step 2: Verify all planned work items are done — invoke `verification-checklist` skill") runs before Step 3 (retrospective). Inside the retrospective, `task-retrospective/SKILL.md:129-130` has a "Completion Gates" block with the same two checks ("Verify all planned work items are done" / "Confirm all builds and tests pass — invoke `verification-checklist` skill"). The result is that an agent following the canonical manager Task Completion flow invokes `verification-checklist` twice: once at manager Step 2 (correct position — before the retro), and once again inside the retrospective at retro Steps 6–7. There is no comment explaining the double-check is intentional. It creates ambiguity: if a test run at Step 2 passes, should the agent re-run it again inside the retro? If the retro Steps 6–7 are authoritative, what is the purpose of manager Step 2?

- Files: `agents/manager.agent.md:201`, `skills/task-retrospective/SKILL.md:129-130`
- This is not dangerous (double-verification is safe), but the redundancy adds execution cost and reader confusion. See Improvement Opportunity IO-P-1 for the resolution path.

---

## Improvement Opportunities

**IO-P-1 — Clarify the verification gate ownership between manager Task Completion and task-retrospective**

The double-verification (m-P-NEW-3 above) can be resolved in one of two ways: (a) **Remove Steps 6–7 from task-retrospective** and document that the retro runs after verification has already passed (manager Step 2 is the gate); or (b) **Move verification from manager Step 2 into the task-retrospective** and have the manager's step 3 note read "invoke task-retrospective — includes verification gates." Option (a) is lower token cost (the retro skill loses 2 checklist steps) and preserves the manager orchestration model where the manager owns the gating sequence. Option (b) makes the retro more self-contained for callers who invoke it outside the manager workflow.

Effort: trivial. Impact: low-medium (removes reader confusion and one redundant tool-call per task).

**IO-P-2 — Sweep the `Does NOT cover` footers for the investigation and architecture phase skills for missing exclusions**

`task-plan-phase-investigation/SKILL.md:123-124` lists "architecture review, implementation phase, testing phase, retrospective" but omits "completion" — the completion phase is just as out-of-scope for investigation as the others. `task-plan-phase-architecture/SKILL.md:73` lists "investigation, implementation phase, testing phase, completion" but omits "retrospective" — architecture doesn't cover the retro either. While the footers are not load-bearing safety gates, inconsistency across the five footers means the "what I don't do" signpost is unreliable. A single sweep to make all five footers enumerate the same five sibling phases (minus self) would close this. ICON-0036 aligned terminology but did not fill the missing items.

Effort: trivial. Impact: low.

**IO-P-3 — Promote `task-plan-phase-completion`'s self-described "Keep this skill minimal" to a stated word cap**

`task-plan-phase-completion/SKILL.md:12-13` declares "Keep this skill minimal. It loads at the end of every task; token cost matters." This is a self-description without a measurable bound. The skill currently runs 832 words — more than investigation (720), testing (552), implementation (487), or architecture (439). That ordering is arguably correct (completion has the most steps), but the "minimal" aspiration has no enforcement vector. Either remove the aspirational claim (if the current size is accepted), or establish a stated per-skill ceiling in the frontmatter or a comment (e.g., "<!-- target ≤ 800 words -->") so future edits can be measured against it. This pairs with the ADR-008 always-loaded budget work.

Effort: trivial. Impact: low (framing only, but self-reference violations erode trust in the discipline skill ecosystem).

**IO-P-4 — Consider whether `task-retrospective` completion gates (Steps 6–7) should invoke `verification-checklist` by name or defer to phase-completion**

Related to IO-P-1. The `task-retrospective` skill is designed to be invoked inside the completion phase AND also as a standalone skill for users who invoke it directly (the description says "Use when completing a task, before marking it done"). For the standalone-invocation case, having verification as Steps 6–7 is load-bearing — there is no prior manager step that ran the gate. For the within-phase-completion case, it's redundant. Rather than silently accepting the double-verification, a one-line note at the top of the Completion Gates section — "If invoked from within `task-plan-phase-completion`, Step 2 of the manager's Task Completion sequence already ran this gate; these steps are confirmation, not the primary gate" — would make the duplication intentional rather than ambiguous.

Effort: trivial. Impact: low-medium (removes ambiguity for all agent callers of this skill).

---

## Process-Skills-Specific Structural Observations

**Observation 1 — The cap-value prose sweep is a recurring class**

Three files still said "15" after the ICON-0036 cap reduction: `agent-vs-skill-invocation.md:23`, `append-retrospective-entry.md:3`, and `append-retrospective-entry.md:32`. The ICON-0036 sweep caught four of the five documented prose sites but missed two out-of-scope-for-that-sweep companions. The ICON-0036 retro ("manager final repo-wide sweep after reviewer catches the literal pattern") identifies the pattern. A `grep -rn "last.15\|keep.15\|cap.15\|15.entries" skills/ agents/` run would have caught both sites. This is the same sweep-incompleteness class noted in the ICON-0015 audit cycle.

**Observation 2 — The agent-vs-skill-invocation.md SSOT is the highest-leverage single file in the process domain**

This file resolved M-CC-NET2 / M-P-B (three-surface retrospectives contradiction), hosts the template-override rule cross-reference, and is the document the manager loads for delegation routing decisions. It is also the only file in this domain that carries a stale numerical value (m-P-NEW-1) after a cap change. Given that this file is cited by phase-completion, manager, and task-retrospective, keeping it current should be treated as a Tier 2 maintenance obligation, not a routine typo fix.

**Observation 3 — Phase-skill `Does NOT cover` footers are correct in terminology (ICON-0036 fix confirmed) but not in coverage (missing exclusions)**

ICON-0036 confirmed to fix terminology drift (switching from `@coder dispatch` to `implementation phase` etc.) across the footers. What it did not address was completeness: investigation omits "completion" and architecture omits "retrospective". These are the last two gaps in an otherwise clean set of five footers.

---

## ICON-0015 Delta

### Fixed since ICON-0015

| ICON-0015 ID | Description | Closing task / evidence |
|---|---|---|
| M-CC-NET2 / M-P-B | `retrospectives.md` write-path contradiction (manager.agent.md vs task-retrospective vs SSOT "Known unresolved") | ICON-0027; `manager.agent.md:203-204` now describes the two-stage specialist delegation; `agent-vs-skill-invocation.md:63` cites #12 as closed; no "Known unresolved" block remains. |
| M-CC-NET3 | `manager.agent.md:151` dead `three-layer-enforcement.md` reference | ICON-0028; grep returns no output for "three-layer-enforcement" in manager.agent.md — confirmed removed. |
| M-I-A | `merge-phase-templates` Step 2 routing table missing `phase-testing.md` row | ICON-0029; `skills/merge-phase-templates/SKILL.md:45` now has "Testing, test coverage, regression checks, @tester work → `phase-testing.md`". |
| M-U-A | `plugin-audit` brief `<path-to-prior-audit-report.md>` placeholder unfilled | ICON-0030; `briefs/02-process-skills.md:10` now carries the `find`-based discovery snippet. |
| m-P-1 | Five phase-skill frontmatter descriptions byte-identical | ICON-0033 addressed by making them intentionally identical (one-sentence form "Internal task-plan phase skill. Do not invoke without explicit direction."). This is now confirmed acceptable — the ICON-0033 agent-evaluation frontmatter conventions section established that sub-agents use single-sentence folded form. Finding retired. |
| m-P-2 | "Does NOT cover" footer terminology drift across five phase skills | ICON-0036; terminology is now aligned to noun forms ("implementation phase", "testing phase", "architecture review") across all five. Minor coverage gaps remain but are a separate new finding (IO-P-2 / Structural Observation 3). |
| m-P-3 | "10–15" prose vs script-canonical "15" | ICON-0036; `task-retrospective/SKILL.md` now says "10 entries" and cites ENTRY_CAP; `task-plan-phase-completion/SKILL.md:77` says "10 entries". The _new_ net-new finding m-P-NEW-1/2 covers the two missed prose sites. |
| m-P-4 | `task-retrospective` two-path (direct line 92 vs delegate line 113) | ICON-0027; the skill now has a single two-stage flow (Stage 1: manager drafts, Stage 2: @context-specialist writes). No direct-manager invocation of the append script remains in the skill body. |
| m-P-6 | `verification-checklist` Gate headings missing skill-name prefix | ICON-0036; all four gates now carry `verification-checklist:` prefix (lines 46, 49, 55, 62). |
| O-T3 | Five phase-skill 6-line template-override paragraphs | ICON-0033; all five phase skills now carry a byte-identical one-line pointer to `task-plan`; the full policy is centralized in `task-plan/SKILL.md:39-49`. |
| O-S4 | Canonicalize retrospectives write path (close "Known unresolved") | ICON-0027; agent-vs-skill-invocation.md now cites #12 as the resolution; no "Known unresolved" language remains. |

### Still present or partial

| ICON-0015 ID | Current status |
|---|---|
| m-P-NEW-1 (net-new this cycle) | `agent-vs-skill-invocation.md:23` stale `keep-last-15` — open |
| m-P-NEW-2 (net-new this cycle) | `append-retrospective-entry.md:3,:32` stale cap description — open |
| m-P-NEW-3 (net-new this cycle) | Double-verification gap between manager Step 2 and retro Steps 6–7 — open |
| IO-P-2 (observation, not a prior finding) | `Does NOT cover` footers: investigation omits "completion", architecture omits "retrospective" — open |

No ICON-0015 process-skills Minors that were carried forward remain unfixed or partially addressed. The "m-P-4 two-path" item is fully resolved; the only remaining question (whether the retro's Steps 6–7 duplication of manager Step 2 is intentional) is re-tiered as a new observation rather than the prior m-P-4.

### Net-new since ICON-0015

1. **m-P-NEW-1** — `agent-vs-skill-invocation.md:23` stale `keep-last-15` value after ICON-0036 cap reduction. The ICON-0036 sweep did not include this file.
2. **m-P-NEW-2** — `context-maintenance/append-retrospective-entry.md:3,:32` stale "last 15 entries" header and single-prune behavioral description. The ICON-0041 cap-convergence fix updated all three scripts but not their companion reference doc.
3. **m-P-NEW-3** — Double-verification in the canonical task-close flow (manager Step 2 + retro Steps 6–7). Not a regression; it was always present, but the ICON-0027 canonicalization surfaced the ordering clearly enough to diagnose.
