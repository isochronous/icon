# ICON-0067 — Commit / MR Format Enforcement: Architectural Design

**Author:** @architect
**Skills consulted:** `agent-evaluation` (5-rule lens), `icon-audit` (maintainer audit perspective)
**Status:** Design only — no files edited. Hand to @planner / @coder for implementation.

---

## Summary

Two enforcement gaps cause agents to emit wrong commit/MR formats despite each repo's
correct format being discovered at init and written to `.context/workflows/commit-conventions.md`
(commit SSOT) and `.context/workflows/branching.md` (branch + MR workflow). The commit gap is
PARTIAL (the skill wires correctly; two call sites bypass or under-assert it). The MR gap is a
true missing-pointer bug (no wiring at all). The fix follows the ICON-0057 precedent: do not add
prose; convert the soft expectation into a discoverable pointer plus a hard, non-skippable gate
assertion at the manager's existing close-gate.

---

## Governing precedent (ICON-0057, restated)

From `.context/retrospectives.md` ICON-0057 (Repeat clause):

> "For failures that are the model ignoring rules ICON ALREADY states … more prose has near-zero
> value — the lever is converting the soft rule into a single hard, itemized, non-skippable
> close-gate (the ICON-0056 pattern) … rejected redundant role-discipline prose and an
> over-engineered new skill, keeping the change to ~18 net lines and honoring 'earn your place'."

This design applies that lever per-gap. Every proposed edit is either (a) a one-line wired
pointer that removes a fork that bypasses the SSOT, or (b) an assertion folded into the manager's
existing non-skippable Task Completion close-gate (`manager.agent.md:210` / Hardcoded tier `:233`).
No new skill. No duplicated format spec. No new prose section.

---

## Per-gap fix decisions

### Gap A — commit-discipline skill itself

**Decision: NO CHANGE.**

`skills/commit-discipline/SKILL.md:14-29` already wires correctly: it instructs the agent to read
`.context/workflows/commit-conventions.md`, use **exactly** that format, and treats the generic
Rule 3 structure as an explicit fallback-when-absent (`:27-29`). This is the canonical pattern the
other sites should mirror. Touching it would be redundant-prose churn. Leave it.

---

### Gap B — context-specialist commit fallback (commit-side, sub-agent that commits)

**Site:** `agents/context-specialist.agent.md:88` (Default tier).
Current text: *"Use the commit convention from the delegation prompt if provided; otherwise detect
from `git log`."*

**Problem (mechanism, not prose):** This is a routing fork that BYPASSES the SSOT. On
maintenance/upgrade runs the file `.context/workflows/commit-conventions.md` already exists, yet
this fallback jumps straight to `git log` detection — strictly weaker than reading the recorded
convention, and the one place a committing sub-agent (`:82`) can emit a wrong format. The fork
order is backwards: SSOT must come before `git log`.

**Chosen mechanism: WIRED POINTER (re-order the fallback chain to defer to the skill).**
Not a gate — the manager's close-gate cannot police a sub-agent's own commit. Not new prose — we
correct the existing one-line rule to point at the same SSOT `commit-discipline` already mandates,
collapsing two divergent commit-format instructions into one source of truth (RULE 2). This is the
minimal change that closes the bypass.

**Exact edit** — replace the bullet at `agents/context-specialist.agent.md:88`:

> - Use the commit convention from the delegation prompt if provided; otherwise detect from `git log`.

with:

> - For commit-message format, apply the `commit-discipline` skill: read `.context/workflows/commit-conventions.md` and use exactly that format. Use the delegation prompt's convention only if it is explicitly provided; fall back to `git log` detection **only when** `commit-conventions.md` is absent.

Rationale tie to ICON-0057: the rule already exists (in `commit-discipline`); the failure is a
call site ignoring it. We do not restate the format — we point the call site at the single hard
source and demote `git log` to explicit last-resort fallback.

---

### Gap C — manager commit step (commit-side, owner of task commits)

**Site:** `agents/manager.agent.md:208` (Task Completion Step 4).
Current text: *"Apply `commit-discipline` skill."*

**Problem:** "Apply the skill" is a soft pointer; it does not assert the file-read prerequisite, so
on a run where the manager has the format loosely in context it can skip the
`commit-conventions.md` read. This is exactly the "model ignoring a rule ICON already states"
class.

**Chosen mechanism: HARD GATE ASSERTION folded into the existing close-gate.**
Step 4 stays as-is (it is the action). The non-skippable close-gate at `manager.agent.md:210`
already itemizes evidence-bearing checks (review / lint / tests / verification). Add one more
itemized check there asserting the format prerequisite. This reuses the proven ICON-0056/0057
forcing function rather than inventing a new one, and is symmetric with the MR assertion (Gap D),
so both formats are gated at one place.

**Exact edit** — in `manager.agent.md:210` close-gate, append a fifth numbered check. Current
gate ends:

> … (4) verification-checklist passed. Missing any one = task is NOT closed. A green test suite satisfies NONE of these four …

Change to:

> … (4) verification-checklist passed, (5) commit messages and the MR title match this repo's discovered conventions — confirm `.context/workflows/commit-conventions.md` was read before committing (or is genuinely absent), and the MR title follows the same format. Missing any one = task is NOT closed. A green test suite satisfies NONE of these five …

Mirror the same fifth item in the Hardcoded-tier restatement at `manager.agent.md:233` (which
duplicates the close-gate verbatim by design — this is a load-bearing tier restatement, not a
RULE 2 violation; both copies must stay in sync).

Rationale tie to ICON-0057: converts a soft "apply the skill" into a hard, itemized,
non-skippable close-gate line — the exact lever the precedent prescribes — with zero added prose
section.

---

### Gap D — mr-discipline title format (MR-side, true missing-pointer bug)

**Site:** `skills/mr-discipline/SKILL.md:37`.
Current text: *"**Title**: Same format as commit messages (`Jira Ticket ID: Brief description`)."*

**Problem:** This HARDCODES a generic title format with NO pointer to the discovered convention.
"Same format as commit messages" is correct in spirit but dead-ends — it never tells the agent
that the commit format itself is the discovered one in `commit-conventions.md`. There is no MR-side
equivalent of the `commit-discipline:14-29` SSOT-read block. This is the wiring that is entirely
missing.

**Chosen mechanism: WIRED POINTER (mirror the commit-discipline SSOT-read pattern).**
Not a gate (the gate lives in the manager, Gap C, and now covers the MR title). Not a new
duplicated spec — we point at the existing commit SSOT, since the MR title format IS the commit
format. This makes `commit-conventions.md` the single source for both commit and MR-title format
(RULE 2), exactly as the working commit side already does.

**Exact edit** — replace `skills/mr-discipline/SKILL.md:37`:

> - **Title**: Same format as commit messages (`Jira Ticket ID: Brief description`).

with:

> - **Title**: Use the same format as commit messages — read `.context/workflows/commit-conventions.md` and apply **exactly** that format (ticket prefix, case, separator). If that file is absent, fall back to `Jira Ticket ID: Brief description`.

Rationale tie to ICON-0057: this is the missing-pointer half — a one-line wired pointer to the
SSOT the agent must read, with the generic format demoted to explicit fallback-when-absent. No new
skill, no MR-specific format spec invented.

---

## "Do NOT do" list (tempting changes that violate the precedent)

1. **Do NOT edit `context_template/context/workflows/branching.md` MR Description Template
   (`:153`).** It is a generic onboarding scaffold (`[TICKET-123]`) shipped to consumers; it is
   cosmetic and explicitly out of primary scope. Editing it triggers the ICON-0044/0062
   release-aware template-version gate for zero enforcement benefit. Leave it.
2. **Do NOT create a new "format-enforcement" skill.** ICON-0057 explicitly rejected an
   over-engineered new skill for this failure class. The wiring belongs in the existing skill +
   agent + manager gate.
3. **Do NOT duplicate the commit/MR format spec into multiple files.** The format lives in
   `.context/workflows/commit-conventions.md` (per-repo SSOT). Every fix here POINTS at it; none
   restates it. Restating it anywhere re-creates the RULE 2 drift this task exists to remove.
4. **Do NOT add a prose paragraph to manager / mr-discipline explaining "why format matters."**
   That is the near-zero-value prose ICON-0057 warns against. The lever is the pointer + gate, not
   explanation.
5. **Do NOT touch `commit-discipline/SKILL.md`.** It already wires correctly (Gap A). Adding
   "reinforcement" there is redundant.
6. **Do NOT add an MR-title format block to `branching.md` (the SSOT for branch/MR workflow).**
   The MR title format equals the commit format; pointing `mr-discipline` at `commit-conventions.md`
   is sufficient. Introducing a second MR-title spec in `branching.md` re-creates dual-source drift.
7. **Do NOT widen scope to coder/tester/reviewer/planner agents.** Per findings, they do not
   commit. Only the manager (task commits) and `@context-specialist` (its own work) commit. Adding
   a commit-format rule to non-committing agents is dead prose.

---

## Three-layer / sync check

| Site | Layer model | Sync obligation |
|------|-------------|-----------------|
| `agents/context-specialist.agent.md:88` (Gap B) | Single-layer agent body | None — no `context_template/` copy of agent bodies. |
| `agents/manager.agent.md:210` + `:233` (Gap C) | Single-layer agent body, **two in-file copies** (close-gate + Hardcoded-tier restatement) | Both copies edited in the **same file**; keep them byte-aligned. This is an intra-file tier restatement, not a three-layer skill↔.context↔template propagation. |
| `skills/mr-discipline/SKILL.md:37` (Gap D) | Single-layer skill body | None — `mr-discipline` is not phase-copied into `.context/` or `context_template/`. |

**Conclusion:** All three primary fix sites are single-layer. **No `context_template/`
propagation is required** (confirming the brief's layering finding). The only "two copies"
concern is the manager's intra-file close-gate/Hardcoded-tier pair, which must stay synchronized.
The `context_template/.../branching.md` MR scaffold is deliberately excluded (see Do-NOT #1),
so the release-aware template-version gate is **not** triggered by this task.

---

## Acceptance criteria (objectively checkable on this pure-content repo)

A reviewer can confirm each by `grep`/read; no build or test exists.

**Gap A (no change):**
1. `skills/commit-discipline/SKILL.md` is unchanged by this task (no diff).

**Gap B — context-specialist:**
2. `agents/context-specialist.agent.md:88` no longer reads "otherwise detect from `git log`" as
   the first fallback; the bullet now references `commit-discipline` **and**
   `commit-conventions.md`, with `git log` demoted to "only when `commit-conventions.md` is absent".
   - Substring present: `commit-conventions.md` AND `commit-discipline`.
   - Substring present: `absent` (fallback-when-absent wording) gating the `git log` clause.

**Gap C — manager:**
3. `agents/manager.agent.md:210` close-gate contains a **fifth** numbered check `(5)` referencing
   `commit-conventions.md` and the MR title, and the closing sentence reads "Missing any one =
   task is NOT closed … NONE of these **five**" (count updated from four → five).
4. `agents/manager.agent.md:233` Hardcoded-tier restatement carries the identical fifth check
   (byte-aligned with `:210`).

**Gap D — mr-discipline:**
5. `skills/mr-discipline/SKILL.md:37` Title bullet contains the substring
   `.context/workflows/commit-conventions.md` and the word `exactly`, and the generic
   `Jira Ticket ID: Brief description` appears only as the explicit "If that file is absent"
   fallback.

**Scope / sync:**
6. `git diff --stat` for this task touches exactly three files:
   `agents/context-specialist.agent.md`, `agents/manager.agent.md`,
   `skills/mr-discipline/SKILL.md`. No file under `context_template/` is modified.
7. The format spec itself (ticket prefix / case / separator) is NOT restated in any edited file —
   each edit only POINTS at `.context/workflows/commit-conventions.md`.

**Net size guard (ICON-0057 "earn your place"):**
8. Total net added lines ≤ ~10 across all four edits (one re-ordered bullet, two gate-line
   appends that are the same text, one rewritten title bullet). No new section headers, no new
   skill files.

---

## agent-evaluation cross-check (5-rule lens)

- **RULE 1 (prompt vs skill):** Gap B/C are decision/routing rules → correctly placed in agent
  bodies. Gap D is a format-read instruction in a discipline skill → correctly placed in the
  skill, mirroring `commit-discipline`. No leakage.
- **RULE 2 (single source of truth):** All edits collapse onto one SSOT
  (`commit-conventions.md`); the Do-NOT list explicitly forbids re-creating dual sources. The
  manager `:210`/`:233` pair is an intentional load-bearing tier restatement (carved out, like
  AR tables), not a violation.
- **RULE 5 (orchestrator clarity):** The hard gate stays in the orchestrator (manager close-gate).
  The committing sub-agent (`@context-specialist`) gets only a wired pointer, not gate logic —
  routing intelligence remains with the manager.
