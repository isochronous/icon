# Context-Specialist & Init Audit — Raw Findings

## Summary

ICON-0007 and ICON-0008 closed the three most consequential prior-audit Moderates
(M-I1 `mode: upgrade` routing contradiction, M-I2 multimodule MR-parity gap, M-I3
missing `disable-model-invocation: true`) and are confirmed fully landed. All five
sections of `agents/context-specialist.agent.md` now converge on the `upgrade` →
`upgrade-repo` routing. The three init orchestrators carry uniform frontmatter.
`initialize-multimodule` now has feature-branch + per-repo MR parity through a
new Step 4 and Step 8. The common-constraints block in `context-specialist.agent.md`
is byte-equal to `shared/common-constraints.md` (enforced by the ICON-0011
pre-commit hook). No Critical defects are present.

The surviving carry-forward Minors (m1 through m10, minus m2, m6, m8 which are
fixed) continue from ICON-0003 unchanged. Net-new findings are two: a legacy
`copilot-instructions.md` reference in the `initialize-workspace` Step 7 MR
template (introduced by ICON-0008 and missed in that task's review), and a
missing `phase-testing.md` row in `merge-phase-templates`'s routing table (the
routing table has 5 rows but the phase file set has 6 files, conflating testing
content into `phase-completion`). The token-efficiency focus areas — entry-point
detection block repeated six times across three orchestrators, drift-trigger
sampling spec inlined three times — remain structurally open.

---

## Defect Findings

### Critical

None observed. Both prior Criticals (CC-C1 entry-point detection, CC-C2
`create-iconrc` template path) confirmed fixed and stable since MKT-0088.

---

### Moderate

**M-I-A — `merge-phase-templates` routing table is missing `phase-testing.md`
as a routing destination. (Net-new.)**

The Step 2 routing table (`merge-phase-templates/SKILL.md:42-46`) lists four
phase-file destinations: `phase-investigation.md`, `phase-architecture.md`,
`phase-implementation.md`, and `phase-completion.md`. The actual phase template
set (as enumerated by `context-specialist-impl-leaf/SKILL.md:267`) contains six
files, including `phase-testing.md`. Testing-related custom content from a
deprecated `task-workflow-template.md` will be routed to `phase-completion.md`
by the catch-all "Testing, code review, retrospective, completion" row — an
incorrect conflation that loses the separation of concerns between the testing
and completion phases.

- `skills/merge-phase-templates/SKILL.md:42-46` — routing table (4 rows, no
  `phase-testing.md`)
- `skills/context-specialist-impl-leaf/SKILL.md:267` — authoritative 6-file
  enumeration: `base.md`, `phase-investigation.md`, `phase-architecture.md`,
  `phase-implementation.md`, `phase-testing.md`, `phase-completion.md`
- `context_template/context/workflows/task-plan/` — 6 files on disk, confirming
  `phase-testing.md` exists

---

### Minor

**m1 — `prune-context.sh` template still propagates 8 `2>/dev/null` / `>/dev/null`
instances to every initialized repo. (Carry-forward from ICON-0003 / MKT-0087.)**

The agent's Constraints block (`context-specialist.agent.md:130`) explicitly bans
output-suppression patterns and instructs the agent to scan-and-remove them. The
shipped template contains 8 instances.

- `context_template/context/workflows/prune-context.sh:26, :43, :44, :67, :71, :90, :102, :106`

**m3 — `find-context-template` PowerShell block uses `\` path separators while
Bash uses `/`. (Carry-forward from ICON-0003 / MKT-0087 m3 / MKT-0077 L4.)**

PowerShell tolerates either separator so this is not a runtime failure, but the
literal mismatch is a maintenance hazard if separator handling is ever
standardized. The two Discovery Command blocks use different separator characters
for the same path.

- `skills/find-context-template/SKILL.md:34` (Bash: `/installed-plugins/...`)
  vs `:42` (PowerShell: `\installed-plugins\...`)

**m4 — `find-context-template` description still understates the skill's caller
list. (Carry-forward from ICON-0003 / MKT-0087 m4.)**

Frontmatter description reads "Internal context initialization skill. Do not
invoke without explicit direction." (line 3-4). Body at lines 10-12 documents
that five skills (`upgrade-repo`, `merge-phase-templates`,
`context-specialist-impl-leaf`, `context-specialist-impl-branch`,
`context-specialist-impl-root`) use this as a callable primitive. Common Check
Pattern 3 violation — callers are under-documented in the discovery surface.

- `skills/find-context-template/SKILL.md:3-4` vs `:10-12`

**m5 — `resolve-repo-context` schema example omits the fallback `instructions`
path. (Carry-forward from ICON-0003 / MKT-0087 m5.)**

The JSON schema at line 99 shows `"instructions": "/absolute/path/.claude/claude.md"`.
Prose at line 121 explains the fallback: "use `.claude/claude.md` if present,
otherwise fall back to `.github/copilot-instructions.md`." A consumer reading
the schema example alone would miss the fallback rule.

- `skills/resolve-repo-context/SKILL.md:99` vs `:121`

**m7 — `context-specialist.agent.md` doubled scope-discipline statement.
(Carry-forward from ICON-0003 / MKT-0087 m7 / MKT-0077 L6.)**

Line 133 (inside the common-constraints block) states "Scope Discipline: Stay
within assigned scope." Line 138-139 (immediately outside the block) adds a
more specific refinement: "Do not read or modify `.context/` files in sibling
or parent directories — scope is strictly the target directory." The textual
proximity creates a fragile reading; the refinement should be a continuation or
clarifying note, not a second standalone statement.

- `agents/context-specialist.agent.md:133, :138-139`

**m9 — Hardcoded DataScan / .NET / WMS examples still present across four init
skills. (Carry-forward from ICON-0003 / MKT-0087 m9.)**

These may be intentional reference shapes for the ICON maintainer's own repos;
they reduce cross-organization reusability but are not bugs.

- `skills/initialize-monorepo/SKILL.md:72, :123-133, :159, :355`
- `skills/initialize-workspace/SKILL.md:64-65, :138-139, :326`
- `skills/initialize-multimodule/SKILL.md:160-161, :363`
- `skills/context-specialist-impl-root/SKILL.md:64`

**m10 — `upgrade-repo` Phase 3 still has the vague drift-trigger spec while
three orchestrators inline the precise version. (Carry-forward from ICON-0003 /
MKT-0087 m10 / MKT-0077 M-I5.)**

`upgrade-repo/SKILL.md:338` says only "if documentation has also drifted from
the codebase, invoke `context-maintenance`" (no threshold). Three orchestrator
dispatch prompts inject the precise spec: "spot-check 5 random class names...
if at least 2 of the 5 are absent..."

- `skills/upgrade-repo/SKILL.md:338`
- `skills/initialize-monorepo/SKILL.md:230-232`
- `skills/initialize-workspace/SKILL.md:237-239`
- `skills/initialize-multimodule/SKILL.md:289-291`

**m-new-A — `initialize-workspace` Step 7 MR description template uses legacy
`copilot-instructions.md` path in the "How to Test" row. (Net-new — introduced
by ICON-0008.)**

The Step 7 MR description example correctly uses `.claude/claude.md` in the
Summary section (line 326: "Added .claude/claude.md and .context/ for: ngWi,
wi-ui-service") but the "How to Test" row at line 336 says "Review each
project's copilot-instructions.md". The sibling `initialize-multimodule` Step 8
MR template at line 400 correctly uses ".claude/claude.md". This was introduced
by ICON-0008, which mirrored workspace Step 7 to multimodule but updated one
site while leaving the other stale.

- `skills/initialize-workspace/SKILL.md:336` — stale `copilot-instructions.md`
- `skills/initialize-multimodule/SKILL.md:400` — correct `.claude/claude.md`
- `skills/initialize-workspace/SKILL.md:326` — correct `.claude/claude.md`
  in the same template's Summary section

---

## Improvement Opportunities

**IO-1 — Single-source the entry-point detection block across all three
orchestrators.**

Each of the three init orchestrators carries two instances of the same
`{ [ -f ".../.claude/claude.md" ] || [ -f ".../.github/copilot-instructions.md" ]; }`
block — one for classify-action and one for verify. That is six inline copies
in three files. MKT-0088 had to fix all six simultaneously. A shared bash
function or a canonical one-liner in `context_template/context/workflows/` (or
in `context-specialist-detect-tree-position/SKILL.md` as a documented primitive)
would close this recurring drift surface.

Closes: architectural observation A1. Effort: medium. Impact: high (structural).

**IO-2 — Extract the Phase 3 drift-trigger sampling spec from orchestrator
dispatch prompts into `upgrade-repo` Phase 3 body.**

The "spot-check 5 random ... if at least 2 of the 5 are absent" rule is inlined
verbatim into three orchestrator dispatch prompts and is absent from
`upgrade-repo/SKILL.md:338` (which has only vague prose). The canonical location
is `upgrade-repo` Phase 3. Each orchestrator prompt then becomes a single line:
"follow Phase 3 sampling rule in `upgrade-repo`."

Closes: m10 (carry-forward 3rd cycle). Effort: low. Impact: medium.

**IO-3 — Add `phase-testing.md` as an explicit routing destination in
`merge-phase-templates` Step 2.**

The current 4-row table conflates testing content with completion content, losing
the separation that the 6-file phase structure was designed to provide. A fifth
row covering "@tester dispatch, coverage review, regression checks" routes to
`phase-testing.md` and the `phase-completion` row is narrowed to "retrospective
entries, sign-off confirmation, post-deployment verification."

Closes: M-I-A (the only Moderate net-new in this domain). Effort: trivial.
Impact: medium.

**IO-4 — Sweep `2>/dev/null` instances from `prune-context.sh` template.**

8 instances remain in the template shipped to every initialized repo. The agent
that copies it explicitly bans the pattern. The ICON-0002 retro established the
`|| true` / explicit `|| echo ""` replacement pattern. Most instances already
have a `|| echo ""` or `|| echo "$NOW"` fallback — only the stderr suppression
part needs to be removed.

Closes: m1 (carry-forward 4th cycle). Effort: low. Impact: low.

**IO-5 — Consider extracting `icon-init` Step 2 detection into a delegated call
to `context-specialist-detect-tree-position` (or a unified detection skill).**

`icon-init` Step 2 explicitly acknowledges it is derived from
`context-specialist-detect-tree-position/SKILL.md` and adds a "If that skill's
detection signals change, update this step to match" warning. The inline copy
means any signal change (e.g., deprecating `.github/copilot-instructions.md`
fallback, adding a new manifest type) must be applied in two places. An explicit
delegation would eliminate the drift risk at the cost of a small structural
coupling.

Alternative: codify the "derived from" relationship as a lint check (e.g., a
comment-marker in both files that a future CI step can grep for version parity).
Effort: medium. Impact: medium.

**IO-6 — Add `disable-model-invocation: true` to all five `context-specialist-impl-*`
and `context-specialist-detect-tree-position` skills.**

The three init orchestrators carry `disable-model-invocation: true` to prevent
model auto-invocation and enforce the `/icon-init` entry point. The impl skills
(`context-specialist-impl-leaf`, `context-specialist-impl-branch`,
`context-specialist-impl-root`, `context-specialist-create`,
`context-specialist-detect-tree-position`) are equally internal (all carry
`user-invocable: false`) but lack the invocation guard. Symmetry and defense-in-
depth argue for adding the key; cost is five one-line frontmatter edits.

Effort: trivial. Impact: low (defense-in-depth only; no known auto-invocation
surface).

---

## Architectural Coherence Observations

**A1 — Six entry-point detection inline copies, three orchestrators.**

`initialize-monorepo` (lines 147, 255), `initialize-workspace` (lines 154, 261),
and `initialize-multimodule` (lines 148, 316) each contain two verbatim copies
of the `{ [ -f ".../.claude/claude.md" ] || [ -f ".../.github/copilot-instructions.md" ]; }`
block. MKT-0088 had to fix all six at once. The O5 improvement opportunity
(single-source this block) from the ICON-0003 audit remains open and grows
slightly in urgency now that `initialize-multimodule` has been extended to full
feature-branch parity (the new Step 4 branch-guard block and Step 6 verify block
each reproduce the pattern).

**A2 — ICON-0007 routing-fix fully propagated across all five agent sections.**

Per the ICON-0007 retro's "routing-rule sweep" lesson, all five sections of
`agents/context-specialist.agent.md` were verified against the `upgrade` →
`upgrade-repo` routing:

| Section | Status |
|---------|--------|
| Role intro (`:21-22`) | CORRECT — "for upgrades you load `upgrade-repo`" |
| Scope/skip guard (`:29-36`) | CORRECT — no routing contradictions |
| Mode table (`mode` parameter, `:46`) | CORRECT — `upgrade` → `upgrade-repo` skill |
| Dispatch routing (`:55-76`) | CORRECT — `mode == upgrade` → load `upgrade-repo` |
| Hardcoded constraint (`:89-90`) | CORRECT — "`upgrade` → `upgrade-repo` skill" |

`context-specialist-create/SKILL.md:11` (previously claimed upgrade mode at
the ICON-0003 baseline) now correctly says only "create or absent (default)".
`manager-routing-guide/SKILL.md:79` correctly lists all four modes with targets.
M-I1 and m6 are fully closed.

**A3 — ICON-0008 renumbering left no backref drift in the common-mistakes table.**

The ICON-0008 retro warned that step renumbering creates inline backref drift.
Verification: all backrefs in `initialize-multimodule/SKILL.md` (`Step 1`, `Step 4`,
`Step 5`, `Step 6`, `Step 7`, `Step 7b`, `Step 8`) match their corresponding
section headers. Common Mistakes table entries at lines 447-454 are consistent
with the current 0-indexed step structure (Steps 0-9 present on disk).

**A4 — Frontmatter key order normalized across all three init orchestrators.**

ICON-0008 normalized key order: all three orchestrators now carry
`user-invocable: false` then `disable-model-invocation: true` (where present).
`initialize-monorepo`: lines 9-10. `initialize-workspace`: lines 10-11.
`initialize-multimodule`: lines 10-11. M-I3 and m8 closed.

**A5 — `merge-phase-templates` is the only init-chain skill with a
route-to-wrong-destination defect.**

All other routing tables in scope (agent mode table, `icon-init` dispatch table,
`context-specialist-create` impl-skill table, `resolve-repo-context` priority
table) are internally consistent. Only `merge-phase-templates`'s Step 2 routing
table (5 rows, misses `phase-testing.md`) has a routing error. See M-I-A.

**A6 — Common Check Patterns applied; findings:**

- **Pattern 1 (self-reference):** `context-specialist.agent.md:130` bans
  `2>/dev/null`; agent ships `prune-context.sh` template with 8 instances (m1).
  `upgrade-repo/SKILL.md:124` `> /dev/null 2>&1` violation from ICON-0003 is
  FIXED — `upgrade-repo` no longer contains this pattern.
- **Pattern 2 (template cross-reference):** All 6 skills that use `$TEMPLATE_DIR`
  correctly invoke `find-context-template` first. No drift.
- **Pattern 3 (caller-listing):** `find-context-template:3-4` understates callers
  (m4 carry). All other in-scope skills correctly tagged.
- **Pattern 4 (operational defensiveness):** `create-iconrc` idempotent (create
  vs update path). `upgrade-repo` show-and-confirm before write. `icon-init`
  `--force` escape. `merge-phase-templates` diff-before-write with single
  confirmation. Gap: orchestrator re-dispatch loops on failure with no retry cap
  (carried from ICON-0003 A8 observation — no defect tier, still open).
- **Pattern 5 (frontmatter parser-fragility):** All in-scope skills use YAML
  folded scalar (`description: >`). No plain-scalar instances.

---

## ICON-0003 Delta

### Fixed since ICON-0003

- **M-I1 (Moderate) — `mode: upgrade` routing contradiction** — FIXED by
  ICON-0007. All five sections of `agents/context-specialist.agent.md` now
  converge on `upgrade` → `upgrade-repo`. `context-specialist-create:11` no
  longer claims upgrade-mode support (was "create, upgrade, or absent"; now
  "create or absent (default)"). Verified at:
  `agents/context-specialist.agent.md:22, :46, :68-71, :89-90`;
  `skills/context-specialist-create/SKILL.md:11`.

- **M-I2 (Moderate) — `initialize-multimodule` missing feature-branch + MR
  parity** — FIXED by ICON-0008. New Step 4 (per-repo branch creation) and
  Step 8 (push + per-repo MR) added. Sub-session dispatch prompts in Step 5
  now pass both `git_root` and `feature_branch`. Verified at:
  `skills/initialize-multimodule/SKILL.md:165-216` (Step 4),
  `:219-304` (Step 5 prompts with `git_root` and `feature_branch`),
  `:370-411` (Step 8).

- **M-I3 (Moderate) — `initialize-multimodule` missing `disable-model-invocation:
  true`** — FIXED by ICON-0008. Also normalized key order across all three
  orchestrators (m8 closed simultaneously). Verified at:
  `skills/initialize-multimodule/SKILL.md:10-11`;
  `skills/initialize-monorepo/SKILL.md:9-10`;
  `skills/initialize-workspace/SKILL.md:10-11`.

- **m2 (Minor) — `upgrade-repo:124` `> /dev/null 2>&1`** — FIXED. No `>/dev/null`
  or `2>/dev/null` instances remain in `skills/upgrade-repo/SKILL.md`.

- **m6 (Minor) — `context-specialist-create:11` claimed upgrade mode** — FIXED
  as a collateral of ICON-0007. Description now reads "when `mode` is `create`
  or absent (default)" only.

- **m8 (Minor) — init orchestrator frontmatter key-order divergence** — FIXED
  by ICON-0008. All three orchestrators now use `user-invocable: false` then
  `disable-model-invocation: true`.

---

### Still present or partial

- **m1 — `prune-context.sh` 8× `2>/dev/null` instances** — still present at
  lines 26, 43, 44, 67, 71, 90, 102, 106. Fourth audit cycle.

- **m3 — `find-context-template` PowerShell `\` vs Bash `/` separators** —
  still present. Bash block uses `/` (line 34), PowerShell block uses `\`
  (line 42). Each block uses the separator appropriate for its shell; the
  finding is a maintenance-hazard observation rather than a runtime defect.

- **m4 — `find-context-template` description under-lists callers** — still
  present. Five callers documented in body; zero named in frontmatter
  description.

- **m5 — `resolve-repo-context` schema example omits fallback path** — still
  present at lines 99 vs 121.

- **m7 — `context-specialist.agent.md` doubled scope-discipline statement** —
  still present at lines 133 and 138-139.

- **m9 — Hardcoded DataScan / .NET / WMS examples** — still present in four
  init skills. See Minor findings section for file:line citations.

- **m10 — `upgrade-repo` Phase 3 vague spec + three orchestrators duplicate
  precise version** — still present. `upgrade-repo/SKILL.md:338` (vague);
  three orchestrators each inline "spot-check 5 random..." at the lines cited
  in the Minor findings section.

---

### Net-new

- **M-I-A (Moderate, net-new) — `merge-phase-templates` routing table missing
  `phase-testing.md`** — 5-row routing table covers only
  `phase-investigation`, `phase-architecture`, `phase-implementation`,
  `phase-completion`, and `base`; `phase-testing.md` is absent. Testing content
  is conflated into `phase-completion`. Introduced by the 6-file phase template
  set; not present in the ICON-0003 baseline (the routing table predates this
  audit cycle).

- **m-new-A (Minor, net-new) — `initialize-workspace` Step 7 MR template uses
  legacy `copilot-instructions.md` path in "How to Test"** — introduced by
  ICON-0008 when the workspace Step 7 MR template was updated. The sibling
  `initialize-multimodule` Step 8 template correctly uses `.claude/claude.md`.
  `skills/initialize-workspace/SKILL.md:336`.
