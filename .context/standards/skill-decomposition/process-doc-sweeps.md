# Process Doc Sweeps and Guard Scope

Discipline that applies when editing a process doc and when building a mechanical guard to protect a swept defect class: sweep all three distribution surfaces, and scope any guard from the enumerated defect-site list rather than a generic "where this file lives" heuristic.

## Process Doc Sweep

When editing a process doc under `.context/workflows/`, the change has **three distribution surfaces**, not one. A change to the local file alone is structurally incomplete — it only propagates to this repo, not to consumers.

**The three surfaces:**

1. **Local SSOT** — `.context/workflows/<doc>.md` (or `.context/workflows/<area>/<doc>.md`). The authoritative file for this repo. Edit here first; this is the version humans and agents read in-tree.
2. **Distribution mirror** — `context_template/context/workflows/<same path>`. Verbatim copy used by `/icon-init` greenfield installs to scaffold target repos' `.context/` trees. Must be kept byte-equal to the local SSOT (modulo template-version comments and any documented template variables) so newly-initialized consumers receive the current rule.
3. **Fallback SSOT** — `skills/<phase>/SKILL.md` (e.g., `skills/task-plan-phase-completion/SKILL.md`). The version downstream repos consume when they have no local override. Must contain the same rule, framed for skill consumers (often with a "Loaded by ..." preamble and the heading prefix used by the skill).

**The rule**: A process-doc edit is not complete until all three surfaces carry the same rule. Editing only the local file leaves greenfield installs and override-less downstream repos on the prior version indefinitely.

**Pointer-resolution corollary (ICON-0070)**: When the edit extracts always-loaded content behind a pointer (e.g., moving manager elaboration into a `phase-completion.md § …` companion and replacing it with a reference), the pointer *target* must exist on every surface the shipped pointer can resolve against — verify the moved section landed in the local SSOT, the `context_template/` mirror, AND the `skills/<phase>/SKILL.md` fallback, not just the repo-local copy, or consumers hit a dead reference.

**Verification (before claiming the edit is done):**

```bash
grep -n "<distinctive phrase from new rule>" \
  .context/workflows/<doc>.md \
  context_template/context/workflows/<doc>.md \
  skills/<phase>/SKILL.md
```

All three paths should return matches. A missing match on any of the three is a sweep gap.

**Anti-rationalization:**

| Excuse | Reality | Correct Action |
|---|---|---|
| "The four obvious files in the diff are the whole sweep" | The local file is one of typically 5+ surfaces; `context_template/` + the skill fallback are easy to forget because they don't appear in the local-file grep. | Enumerate all three surfaces explicitly in the plan's Key Files section before delegating. |
| "Downstream repos will pick up the new rule next `/icon-init`" | `/icon-init` only runs once per repo. Existing repos never re-scaffold; they consume the SKILL fallback. | Update the SKILL fallback in the same commit as the local file. |
| "The `context_template/` mirror is a low-priority follow-up" | Greenfield installs immediately receive the stale rule and bake it into their repo's `.context/` from day one. | Mirror in the same commit, with a template-version bump if the doc has one. |

**Exception — repo-local conventions**: When the process-doc change is a repo-local convention deliberately not meant for consumer repos (e.g., a maintainer workflow step that relies on this repo's own `CHANGELOG.md`), the three-surface sweep does NOT apply. The bypass must be named explicitly in plan.md Decisions with rationale, and the OUT-of-scope list in the @coder dispatch must name the two surfaces NOT to touch (`context_template/` mirror and `skills/<phase>/SKILL.md` fallback). Sweep only `.context/`. (Precedent: ICON-0026.)

**Exception — intentionally divergent template copies (ICON-0074)**: A few `.context/workflows/` docs are NOT byte-equal mirrors of their `context_template/context/workflows/` counterparts — they are intentionally divergent by audience. The live copies are ICON-specific (main-only branch model, `ICON-NNNN` IDs, this repo's own signing/protected-branch setup); the template copies are generic consumer scaffolds (Gitflow, `TICKET-NNN`, tier-agnostic phrasing). `branching.md` and `commit-conventions.md` are the known instances. For these, edit EACH copy for its own audience — do not cross-contaminate (no ICON-specific text into the generic scaffold, no consumer-generic text into the live doc) and do not "sync them" to byte-equal. The byte-equal rule in surface #2 above still governs all other workflow docs; this exception is per-file, not blanket. The version-bump coupling is unchanged: only the `context_template/` edit trips the ADR-044 template-version gate, so bump `context_template/context/iconrc.json` in the same commit; the live `.context/` edit does not. Diff both trees read-only up front so you treat each as its own audience rather than reaching for a wrong "sync them" move or missing the bump.

**Precedent (ICON-0014)**: The plan.md freshness gate landed in `.context/workflows/task-plan/phase-completion.md` plus three other surfaces, but the first @coder pass missed both the `context_template/` mirror AND `skills/task-plan-phase-completion/SKILL.md`. Reviewer caught the gap as Critical + Moderate. The plan invoked the ICON-0007 cross-surface-sweep lesson but didn't enumerate the three distribution surfaces by name; the brief inherited that gap.

## Guard Scope From the Enumerated Defect-Site List

When a **mechanical guard** (a pre-commit gate, a CI check, a lint rule) is added to prevent a swept defect class from recurring, its file/scope coverage must be derived from the **enumerated defect-site list** — the actual sweep surfaces where the defect lives — not from a generic "where this kind of file lives" heuristic. A guard scoped by the convenient generic heuristic can pass clean on every commit while leaving the highest-value sites (notably the consumer-shipped `context_template/` mirror) unguarded — which is exactly the sweep-incompleteness failure the guard was built to close.

**The rule**: before finalizing a guard's path scope, list the concrete sites the defect actually occupies (the same multi-surface enumeration the Process Doc Sweep section demands) and confirm the guard's scope is a superset of that list. If the guard's scope and the defect-site list diverge, the guard is decorative on the gap it was motivated by.

**Anti-rationalization:**

| Excuse | Reality | Correct Action |
|---|---|---|
| "The guard covers `agents/skills/shared/commands` — that's where this kind of file lives" | The defect's highest-multiplier site (`context_template/` mirror, consumer-shipped) sits outside that generic set; the guard passes clean while its own motivating bug is unguarded. | Scope the guard from the enumerated sweep-site list, then verify it as a superset of where the defect actually occurs. |
| "The gate is green, so the defect class is closed" | A green gate over the wrong file set proves nothing about the unguarded sites. | Add a regression check at each real defect site (not just at the guarded set) and confirm the gate fires there. |

**Precedent (ICON-0060)**: the O-M1b cap-literal gate covered `agents/skills/shared/commands`, but the 15→10 drift it targeted lived in `context_template/context/retrospectives.md` and `.context/standards/skill-decomposition/process-sweeps.md` — both outside that scope. The gate would have passed clean while leaving its own motivating bug unguarded; the gap was caught by cross-referencing gate scope against the sweep-site list, and the reviewer's regression tests at the real bug locations confirmed it.

---

See [`../skill-decomposition.md`](../skill-decomposition.md) for the full skill-decomposition index.
