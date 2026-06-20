# Process Skills Audit — Raw Findings

## Summary

The process-skills domain enters this audit cycle in substantially improved condition
relative to ICON-0046. All three ICON-0046 Minor findings in this domain have been
addressed: the stale `keep-last-15` cap references (m-P-NEW-1/2) were fixed in ICON-0048,
and the double-verification pattern (m-P-NEW-3) evolved further with ICON-0057 — though
not in the direction the prior audit recommended. ICON-0056 made `task-retrospective`
Hardcoded (Non-Negotiable) in the manager, eliminating the most common process bypass.
ICON-0057 added a non-skippable, itemized four-item close-gate. The net effect is a
significantly stronger process backbone.

However, this cycle surfaces one Moderate and three Minor defects. The Moderate is
structural: `context_template/context/workflows/task-plan/phase-completion.md` ships a
Retrospective Template in "## Retrospective — [TASK-ID]" (double-hash) format, which is
incompatible with the `append-retrospective-entry.sh` script's validation requirement for
"### " (triple-hash) entry headers. Any consumer repo following the shipped template will
produce retro entries that the script rejects at the validation gate, leaving entries
uninserted and the rolling-log cap unenforced. This is a correctness defect, not a hygiene
issue. Two additional Minors persist from ICON-0046 (the `Does NOT cover` footer gaps in
investigation and architecture phase skills; the absence of a measurable word cap on the
"Keep this skill minimal" self-claim in phase-completion). The fourth defect is net-new:
ICON-0057's close-gate converted the prior double-verification into a triple-verification
pattern without documenting the intent.

---

## Defect Findings

### Critical

None observed.

### Moderate

**M-P-0058-1 — `context_template/phase-completion.md` Retrospective Template ships a format
incompatible with `append-retrospective-entry.sh`**

`context_template/context/workflows/task-plan/phase-completion.md:53–62` defines a
Retrospective Template block:

```markdown
## Retrospective — [TASK-ID]

**What to avoid next time:**
...
**What worked well:**
...
**Context updates needed:**
...
```

The `append-retrospective-entry.sh` script (all three copies at
`skills/{task-retrospective,post-incident-review,context-maintenance}/scripts/`) validates
at line 117–118 that entry text must begin with `### ` (triple-hash space). Any consumer
repo that uses the shipped template format will receive exit code 1 from the script, the
entry will not be inserted, and the rolling-log cap (ENTRY_CAP=10) will be silently
unenforced — the file grows without bound.

The canonical entry format in `skills/task-retrospective/SKILL.md:78–83` correctly uses
triple-hash `### [TASK-ID]: [Short description]` with `**Avoid**`, `**Repeat**`, and
`**Updated**` fields. The context_template version diverges on both heading level and
field names. `skills/context-maintenance/append-retrospective-entry.md:31` confirms the
script counts `### ` blocks; `append-retrospective-entry.sh:126` does the live count with
`grep -c '^### '`.

The ICON repo's own `.context/workflows/task-plan/phase-completion.md:68–79` also uses the
incompatible format (though `retrospectives.md` in this repo correctly uses triple-hash,
indicating the skill's guidance is followed in practice despite the template disagreeing).

ADR-010 notes the "Ticket-ID format (ICON-NNNN Jira-prefix shape in retrospective headers) —
every consumer repo has its own project key" as an accepted carry-forward on the prefix. The
*heading level and field name divergence* is a separate axis not covered by that disposition.

- Files: `context_template/context/workflows/task-plan/phase-completion.md:53–62`;
  `skills/context-maintenance/scripts/append-retrospective-entry.sh:115–118,126`;
  `skills/task-retrospective/SKILL.md:78–83`;
  `.context/workflows/task-plan/phase-completion.md:68–79`
- Classification: Moderate — consumer repos following the template will silently fail to
  insert retro entries. The failure mode is invisible (exit code not surfaced to the agent
  in the normal delegated flow) and the cap guarantee breaks.

### Minor

**m-P-0058-1 — Triple-verification: ICON-0057 close-gate adds a third `verification-checklist`
invocation without documenting intent**

`manager.agent.md:203` Step 2 invokes `verification-checklist`. `skills/task-retrospective/SKILL.md:130`
Steps 6–7 invoke `verification-checklist` (the double-verification m-P-NEW-3 from ICON-0046,
still present). `manager.agent.md:210` Step 6 close-gate item (4) also requires
`verification-checklist` passed. This creates three separate invocations per task close:
Step 2 (before retro), Step 6–7 inside the retro skill, and Step 6 close-gate confirmation.

The prior audit (ICON-0046 m-P-NEW-3) recommended resolving the double-verification via
O-S1. The fix was listed as follow-up task ICON-0049 in the audit report. In practice
ICON-0049 addressed characterization-testing instead; O-S1 was never executed. ICON-0057
then added the close-gate on top of the existing double pattern, making it triple.

No note appears in any of the three invocation sites explaining the triple-check is intentional.
An agent following the full Task Completion flow invokes `verification-checklist` three times
in one task close, with no semantic difference between invocations — the same 4-gate checklist
runs three times.

- Files: `agents/manager.agent.md:203,210`; `skills/task-retrospective/SKILL.md:127–130`
- Note: The close-gate (Step 6) is the most load-bearing of the three; the redundancy is
  safe, but the unintentional duplication erodes reader confidence that the documents are
  maintained carefully.

**m-P-0058-2 — `Does NOT cover` footers: investigation missing "completion", architecture
missing "retrospective" (carry-forward from ICON-0046 IO-P-2)**

`skills/task-plan-phase-investigation/SKILL.md:123–124` lists `Does NOT cover: architecture
review, implementation phase, testing phase, retrospective` — omitting `completion`. The
completion phase is equally out of scope for investigation; its absence suggests the footer
is incomplete rather than intentional.

`skills/task-plan-phase-architecture/SKILL.md:73` lists `Does NOT cover: investigation,
implementation phase, testing phase, completion` — omitting `retrospective`. The architecture
phase skill has no retro responsibility; the omission creates an inconsistent coverage
picture.

The implementation (`skills/task-plan-phase-implementation/SKILL.md:80–82`) and testing
(`skills/task-plan-phase-testing/SKILL.md:94–95`) footers are complete. Completion
(`skills/task-plan-phase-completion/SKILL.md:100–101`) is correctly silent on retrospective
since it includes the retro as an internal step.

This finding was reported in ICON-0046 as IO-P-2 and remained open. No CHANGELOG entry
indicates a fix was made.

- Files: `skills/task-plan-phase-investigation/SKILL.md:123–124`;
  `skills/task-plan-phase-architecture/SKILL.md:73`

**m-P-0058-3 — `task-plan-phase-completion` "Keep this skill minimal" self-claim has no
measurable bound (carry-forward from ICON-0046 IO-P-3)**

`skills/task-plan-phase-completion/SKILL.md:12–13` reads: "**Keep this skill minimal.** It
loads at the end of every task; token cost matters." The skill body is 832 words — the
longest of the five phase skills (investigation 720, testing 552, implementation 487,
architecture 439). The aspiration is stated without a ceiling that can be enforced or
measured. This was IO-P-3 in ICON-0046; it remains unaddressed.

Self-reference check: a skill that instructs "keep this minimal" while expanding to the
largest size in its peer group erodes trust in all size-related claims in the skill ecosystem.

- File: `skills/task-plan-phase-completion/SKILL.md:12–13`

---

## Improvement Opportunities

**IO-P-0058-1 — Canonicalize the Retrospective Template in `context_template/phase-completion.md`
to match `task-retrospective/SKILL.md` and the append script's validation requirement**

Fix M-P-0058-1. Replace the `## Retrospective — [TASK-ID]` block in
`context_template/context/workflows/task-plan/phase-completion.md:53–62` with the canonical
`### [TASK-ID]: [Short description]` format using `**Avoid**`, `**Repeat**`, `**Updated**`
fields. The template-version comment should bump from 1.4 → 1.5. Also apply the same fix to
`.context/workflows/task-plan/phase-completion.md:68–79` (this repo's own copy). The
`append-retrospective-entry.md` reference (line 71) already says "The entry text must begin
with a `### ` heading (the canonical format from the `task-retrospective` skill)" — the
template just doesn't match this instruction.

Effort: trivial. Impact: high (correctness — fixes silent entry-insertion failure in consumer
repos that follow the shipped template).

**IO-P-0058-2 — Resolve the triple-verification by removing `verification-checklist`
from `task-retrospective` Steps 6–7 with a one-line standalone-invocation note**

The close-gate in `manager.agent.md:210` is the most complete, most recently updated, and
most load-bearing of the three invocations. It subsumes Step 2 (which only checks planned
work items) and the retro's Steps 6–7 (which duplicate that check). Recommend:

Option (a): Remove Steps 6–7 from `skills/task-retrospective/SKILL.md:127–130` and add one
line: "If invoked from within the manager's Task Completion flow, the close-gate (Step 6)
already passed these gates — these steps apply only when the retro is invoked standalone
outside the full completion sequence." Then remove Step 2 from `manager.agent.md:203` and
let the close-gate serve as the single verification gate.

Option (b): Add an explanatory note at `task-retrospective/SKILL.md:127` documenting that
the triple-check is intentional: "These gates run inside the retro for standalone-invocation
safety. The manager's close-gate and Step 2 also run these checks when using the full Task
Completion flow."

Option (a) removes the redundancy and reduces agent execution cost. Option (b) preserves the
behavior and documents intent. Either closes the finding.

Effort: trivial. Impact: low-medium (removes confusion, saves one redundant tool-call per
task close, and documents the retro's standalone-invocation safety net).

**IO-P-0058-3 — Quantify the `task-plan-phase-completion` word budget or retire the
"Keep this minimal" claim**

Either add `<!-- target ≤ 850 words -->` inline at `skills/task-plan-phase-completion/SKILL.md:12`
to give the aspiration a measurable ceiling, or rephrase to "This skill loads at the end of
every task; each new step must justify its token cost." The current "Keep this skill minimal"
with 832 words and no ceiling provides no enforcement surface.

Effort: trivial. Impact: low.

**IO-P-0058-4 — Add a cross-reference from `task-plan-phase-completion` to the manager's
non-skippable close-gate**

`skills/task-plan-phase-completion/SKILL.md` has no mention of the itemized close-gate
introduced by ICON-0057 (`manager.agent.md:210,233`). If a consumer invokes phase-completion
as the workflow authority, they see reconcile → review → context-update → retro → completion
summary, but the four-item non-skippable close-gate is only in the manager agent. A one-line
callout in the Completion Summary section or the Relationship section
(`skills/task-plan-phase-completion/SKILL.md:92–101`) would surface the gate for readers
consulting the skill directly: "After the Completion Summary, the manager's close-gate (a
non-skippable itemized gate for @reviewer, lint, test coverage per `testing-discipline`, and
`verification-checklist`) must be confirmed before declaring the task closed."

Effort: trivial. Impact: low-medium (closes the visibility gap for consumers who use
phase-completion as the reference authority rather than the manager agent definition).

**IO-P-0058-5 — Sweep `Does NOT cover` footers to add the missing exclusions
(investigation + architecture)**

Sweep `skills/task-plan-phase-investigation/SKILL.md:123` to add "completion" and
`skills/task-plan-phase-architecture/SKILL.md:73` to add "retrospective". This is IO-P-2
from ICON-0046, still open.

Effort: trivial. Impact: low.

---

## Process-Skills-Specific Structural Observations

**Observation 1 — The ICON-0057 close-gate is the strongest process hardening in two cycles**

The four-item non-skippable close-gate at `manager.agent.md:210,233` is the single most
significant process change since the ICON-0027 retrospective-write-path canonicalization.
It converts four previously soft rules into a single non-skippable verification step with
evidence requirements for each. The ICON-0057 retro confirms this was validated by
dogfooding on the task itself. The gate subsumes and supersedes the prior verification-gate
structure — the remaining work is reconciling the three-layer verification pattern created
by its introduction alongside the existing Step 2 and retro Steps 6–7.

**Observation 2 — Template divergence is the highest-risk structural gap for consumer repos**

The `context_template/` content is what ships to new consumer repos and what existing
consumer repos receive on `/upgrade-repo`. The M-P-0058-1 Retrospective Template format
divergence means every new consumer repo gets a `phase-completion.md` that will silently
fail when used as instructed. This is a different risk class than the ICON-internal
process-skill inconsistencies — it affects the plugin's installed population, not just the
ICON repo itself.

**Observation 3 — The O-S1/m-P-NEW-3 carry-forward pattern echoes M-U-NET1 from ICON-0046**

ICON-0046 identified the "partial sweep" pattern — fixing the named literal without
investigating the structural cause — as the primary recurring defect vector. The
verification-gate ownership (m-P-NEW-3 → still present → upgraded to triple-verification)
demonstrates the same root cause: ICON-0048's audit-objective sweep fixed the cap-value
prose but did not address the structural ownership question. A future task targeting this
should own both the retro Steps 6–7 removal AND the Step 2 / close-gate rationalization
in one atomic change.

---

## ICON-0046 Delta

### Fixed since ICON-0046

| ICON-0046 ID | Description | Closing task / evidence |
|---|---|---|
| m-P-NEW-1 | `agent-vs-skill-invocation.md:23` stale `keep-last-15` | ICON-0048; confirmed: `skills/task-plan-phase-completion/agent-vs-skill-invocation.md:23` now reads `keep-last-10 with multi-prune convergence`. |
| m-P-NEW-2 | `append-retrospective-entry.md:3,:32` stale "last 15 entries" and single-prune description | ICON-0048; confirmed: `skills/context-maintenance/append-retrospective-entry.md:3` now reads "rolling log of last 10 entries" and line 32 describes multi-prune convergence behavior. |

### Still present or partial

| ICON-0046 ID | Current status |
|---|---|
| m-P-NEW-3 (double-verification, manager Step 2 + retro Steps 6–7) | Now triple-verification: ICON-0057 close-gate (Step 6 item 4) added a third `verification-checklist` invocation. The structural ownership question is unresolved. See m-P-0058-1. |
| IO-P-2 (`Does NOT cover` footer gaps: investigation missing "completion", architecture missing "retrospective") | Still present. No CHANGELOG entry indicates a fix. See m-P-0058-2. |
| IO-P-3 (task-plan-phase-completion "Keep this skill minimal" without measurable bound) | Still present at 832 words. See m-P-0058-3. |

### Net-new since ICON-0046

1. **M-P-0058-1** — `context_template/phase-completion.md` Retrospective Template ships
   incompatible `##`-heading format vs `append-retrospective-entry.sh`'s `### ` validation
   requirement. Consumer repos following the template silently fail entry insertion.
   First-observable this cycle because neither prior audit examined the context_template
   retrospective template format against the script's validation logic.

2. **m-P-0058-1** — Triple-verification pattern. ICON-0057's close-gate elevated the prior
   double-verification (m-P-NEW-3) to a triple. This is a change that happened between audits
   rather than a latent pre-existing defect, making it net-new in effect.
