# ICON-0090 — `/upgrade-repo` Phase 0 + Phase 1 Audit (dogfood run)

**Target**: `C:\dev\ai\icon\.context\`
**Branch**: `feature/ICON-0090-dogfood-upgrade-repo`
**Platform**: Windows 11; Git Bash (GNU grep 3.0, GNU sed) + PowerShell 7
**Skill under test**: `skills/upgrade-repo/SKILL.md`
**Status**: **STOPPED at the Phase 1 confirmation gate.** No file modified. This report is the only write.

---

## 0. Headline

The mechanical delta list is short and mostly benign. The important result is a **semantic** one:

> **ICON's `.context/` is not a stale copy of the template — it is a maintained fork of it.**
> `upgrade-repo` is built on the premise that installed files share a lineage with template files and that a version mismatch means "installed is behind." For ICON that premise is false in both directions. Every version comparison the skill performed produced a technically-correct-but-meaningless result, and the one delta the skill would auto-apply (`iconrc.json` `version`) would write a **false claim**.

Recommended Phase 2 scope: **apply nothing automatically.** Details in §5.

---

## 1. Phase 0 — Instructions file

| Check | Result |
|---|---|
| `.github/copilot-instructions.md` | absent |
| `.claude/claude.md` | **present** (verified real filename, not a case alias) |
| Root `claude.md` | **absent** |

**Case 2** (already migrated). No `git mv` would occur.

**But the "Ensure root-level `claude.md` redirect" step (SKILL.md:75-98) would fire and create a file.** Its bash guard is:

```bash
if [ -f ".claude/claude.md" ]; then
  if [ ! -f "claude.md" ]; then
    cat > claude.md << 'EOF'
```

Both conditions hold. **Per the task's scope boundary I did not create it — reporting only.** It would write a ~6-line redirect stub at the repo root.

Adjudication — **INAPPLICABLE, leaning ACTIVELY WRONG for ICON.**
The redirect exists so Copilot CLI users of a *consumer* repo reach `.claude/claude.md`. ICON's root already carries `README.md`, `CONTRIBUTING.md`, and `CHEATSHEET.md` as its public face; adding a stub `claude.md` that only says "read the other file" adds a root-level file to the repo that *defines* this convention, for a benefit ICON's own contributors do not need (they run Claude Code, which loads `.claude/claude.md` directly). If ICON wants Copilot parity it should be a deliberate maintainer decision, not a side effect of an upgrade run.

Note this step has **no confirmation gate** — unlike Cases 1/2 which show-and-confirm, the redirect block is an unguarded `cat >`. That is a gap: Phase 0 can mutate the working tree before the Phase 1 audit the user is supposed to approve.

---

## 2. `find-context-template` — **DEFECT D1 (blocking on PowerShell)**

The skill directs: *"Invoke `find-context-template` to locate the template directory and establish `$TEMPLATE_DIR`."* It gives **no instruction to validate the result** before use. Confirms the ICON-0089 finding.

Observed, verbatim:

**PowerShell branch** (`$TEMPLATE_DIR = "$env:CLAUDE_PLUGIN_ROOT/context_template"`):
```
CLAUDE_PLUGIN_ROOT = []
TEMPLATE_DIR = [/context_template]
CLAUDE_PLUGIN_ROOT is not set - plugin runtime may not have injected it
Test-Path TEMPLATE_DIR = False
```

Carried into the skill's own Phase 2 PowerShell block at SKILL.md:503:
```
FAILED: ItemNotFoundException: Cannot find path 'C:\context_template\context\iconrc.json' because it does not exist.
```

**Bash branch** worked — but *not* for the reason it appears to:
```
TEMPLATE_DIR=[c:/dev/ai/icon//context_template]
directory exists
CLAUDE_PLUGIN_ROOT=[<unset>]
```

The env var is unset in **both** shells. The bash variant succeeded only because the harness **substituted `$CLAUDE_PLUGIN_ROOT` at skill-render time**, baking a literal path into the markdown. The PowerShell variant uses `$env:` syntax the renderer does not substitute, so it reaches the shell unexpanded and evaluates to `/context_template`. Note the render artifact: `c:/dev/ai/icon//context_template` — a **double slash** from a trailing-slash plugin root.

**Impact**: a Windows/PowerShell consumer running `/upgrade-repo` gets a `$TEMPLATE_DIR` that silently resolves to a non-existent path off the drive root. `Copy-Item` fails loudly; but `Test-Path`-guarded branches take the wrong path *silently* — e.g. the task-plan installer at SKILL.md:581 (`if (-not (Test-Path $Target))`) would attempt `Copy-Item` from a bogus source, and the deprecated-file `Compare-Object` at SKILL.md:134 would throw on the missing template side.

I proceeded using the working value `C:\dev\ai\icon\context_template` — which, in this dogfood run, **is the repo itself**. Template source and upgrade target are the same working tree.

---

## 3. Phase 1 audit results

`.context/iconrc.json` `excludes`: `["architecture", "testing", "styling"]` — honored throughout; never flagged below.

### 3.1 Infrastructure files

| Item | Result |
|---|---|
| `.context/workflows/prune-context.sh` | present; **differs from template in exactly one line** (see §3.6) |
| `.githooks/post-commit` | present; **byte-identical to `$TEMPLATE_DIR/context/workflows/post-commit`** |
| `.githooks/pre-commit` | present (ICON-only; no template counterpart) |

### 3.2 Directories

Required by SKILL.md:110 — `standards/ architecture/ testing/ tasks/ workflows/ domains/ styling/`:

| Dir | Status |
|---|---|
| `standards/` `tasks/` `workflows/` `domains/` | present |
| `architecture/` `testing/` `styling/` | **excluded** — correctly absent |

Also present, not on the skill's list: `decisions/` (81 task folders under `tasks/`, `cache/` with `.gitkeep`).

**DEFECT D7 (minor)**: `decisions/` is a required directory in the current spec — the skill's own Phase 2 depends on it and `rules-index.md` indexes it — but it is **absent from the Phase 1 directory checklist**. A consumer whose `decisions/` went missing would pass this audit.

### 3.3 Deprecated-file checks — both confirmed non-triggering

Run verbatim from SKILL.md:120-129 and :152-159 (bash), and :133-144 and :163-169 (PowerShell). Identical results in both shells:

```
task-workflow-template.md: not present — nothing to do
decisions/: folder already present — no migration needed
```

**ICON-0089 C1 does not reproduce here** — confirmed as the warmstart predicted. The stock-vs-CUSTOMIZED misclassification path is unreachable because ICON has no `task-workflow-template.md`. **The defect is not disproved, merely not exercised.** It remains live for any consumer that does have the file.

Same for the flat-`decisions.md` dead-code path.

### 3.4 New required files — all present

| File | Status |
|---|---|
| `workflows/commit-conventions.md` | present |
| `workflows/branching.md` | present |
| `.context/.gitignore` | present, **byte-identical to template** |
| `.context/iconrc.json` | present (§3.7) |
| `.context/rules-index.md` | present, fully populated (45 lines vs the template's 23-line sentinel scaffold) |

### 3.5 Root `.gitattributes` — **PASS**

Present, with both required entries plus a substantial explanatory comment:
```
retrospectives.md          merge=union
retrospectives-archive.md  merge=union
```
Phase 2's append block is correctly guarded by `grep -qF 'retrospectives.md'` and would **skip**. Idempotent. No action.

### 3.6 `prune-context.sh` — one line differs, and it is a deliberate customization

```diff
-# ICON repo uses a main-only branch model. There is no dev/develop branch.
-# All commits land on main; the release IS the tag push.
-INTEGRATION_BRANCHES="^main$"
+# Customize to match this repository's integration branch names.
+INTEGRATION_BRANCHES="^(main|master|dev|develop|trunk)$"
```

That is the **entire** diff. All script logic is current.

Adjudication — **ACTIVELY WRONG to apply.** `^main$` implements ADR-002 (main-only branch model, per `.claude/CLAUDE.md`: *"This repo is `main`-only. There is no `dev` branch."*). Overwriting it re-arms task pruning on four branch names ICON has decided will never exist.

**DEFECT D5 — dangerous ambiguity.** SKILL.md:434-443 opens conditionally (*"if the old script uses a hardcoded `=~` regex without a named variable"* — ICON's does **not**; it has the named variable) but closes with prose that reads unconditionally:

> *"Then run the standard `cp $TEMPLATE_DIR/context/workflows/prune-context.sh .context/workflows/` — the rename preserves the hook reference; the copy overwrites stale logic with the current template."*

A literal executor applies that `cp` and silently reverts the customization. The skill's own Common Mistakes table warns against exactly this outcome (*"Resetting `INTEGRATION_BRANCHES` to generic defaults | Extract old regex first, preserve it"*), and Phase 4 check #1 would then be validating a value the upgrade just broke. The guard exists in prose; the trap is in the same paragraph.

### 3.7 `iconrc.json` version — **the central judgment call**

Phase 2's bash block, executed read-only (the `sed -i` suppressed):
```
grep (GNU grep) 3.0
TEMPLATE_VER=[1.12]
INSTALLED_VER=[1.2]
WOULD RUN: sed -i "s/\"version\": \"1.2\"/\"version\": \"1.12\"/" .context/iconrc.json
iconrc.json version: 1.2 → 1.12
```

**The ICON-0089 GNU-only Moderate did NOT reproduce on this platform.** Git Bash for Windows ships GNU grep 3.0 and GNU sed, so `grep -oP` and `sed -i` both work. It printed the correct transition, not `already at `. **The defect is real but platform-specific — it remains live for macOS (BSD grep/sed).** Reporting what happened, not what was predicted.

The version-*comparison* concern also did not manifest as feared: `[ "$INSTALLED_VER" != "$TEMPLATE_VER" ]` is a **string** compare, so `1.2` ≠ `1.12` is detected correctly. **DEFECT D3** is the related-but-different problem: the compare is **undirected**. A repo whose installed value is *ahead* of the template would be silently **downgraded**, and Phase 4 check #7 (*"`version` field matches the template"*) would call that success.

#### Should the bump be applied? **NO — ACTIVELY WRONG as a bare field write.**

Three pieces of evidence, in order of decisiveness:

**(a) There is no schema delta. None.**
```
installed keys: cache_expires_after_days, default_branch, excludes, local_task_id_prefix, repo_type, version
template  keys: cache_expires_after_days, default_branch, excludes, local_task_id_prefix, repo_type, version
SCHEMA DELTA: NONE - identical field sets
```
The skill calls this field the *"schema version"* (SKILL.md:174, :489). It is not one. Ten "versions" carry **zero** schema change.

**(b) The field is a template-tree content counter, not a version of `iconrc.json`.**
`.claude/CLAUDE.md` states the invariant enforced by `.githooks/pre-commit`: *any* commit staging *any* change under `context_template/` must bump this field. Git history confirms — every bump was driven by unrelated template content:

| Ver | Commit | What actually changed |
|---|---|---|
| 1.12 | `9c581cb` | ICON-0088 — `task-plan/phase-completion.md` |
| 1.11 | `403e23c` | ICON-0083 — terseness pass across `architecture/`, `styling/`, `workflows/` |
| 1.10 | `d1c279f` | ICON-0082 — session-per-phase, all 6 `task-plan/` files |
| 1.9 | `2866f2b` | ICON-0081 — `## Related` graph seam across `domains/`, `standards/`, `architecture/` |
| 1.8 | `3418e84` | ICON-0080 — GitHub conversion, `branching.md` / `commit-conventions.md` |

So `1.12` asserts *"this `.context/` reflects template-tree state 1.12."* Writing it without applying the content — which §3.8 and §4 show ICON mostly **must not** apply — is **a false claim recorded in a file `icon-status` displays to users.** This is precisely the plan.md Open Question, and the answer is: the bare field write is not sufficient, and worse than doing nothing.

**(c) 1.2 and 1.12 were never on the same numbering track.**
```
=== history of INSTALLED .context/iconrc.json ===
22d5b4c|2026-06-20|chore: establish git baseline of ICON working tree
--- 22d5b4c:   "version": "1.2",
```
One commit. Ever. The installed file has been untouched since the git baseline — **and at that same baseline commit the template already read `1.7`.** `1.2` is not "ten behind 1.12"; it is a residue of an older, abandoned numbering lineage (ICON's `.context/` was migrated in from MKT-0095 — see `.context/tasks/ICON-0001-migrate-context-from-mkt-0095/`). The arithmetic "1.2 → 1.12" describes no real upgrade path.

**Also latent (not triggered here)**: the `sed` pattern interpolates `$INSTALLED_VER` unescaped, so the `.` is a live regex metacharacter. Harmless for `1.2`, but the construction is wrong.

### 3.8 Task-plan phase templates — **6 of 6 flagged; 0 actionable**

Run with the skill's own Phase 2 logic (read-only):

```
REVIEW REQUIRED: base.md                   (installed: [1.2], template: [1.1])
REVIEW REQUIRED: phase-investigation.md    (installed: [1.2], template: [1.1])
REVIEW REQUIRED: phase-architecture.md     (installed: [1.2], template: [1.1])
REVIEW REQUIRED: phase-implementation.md   (installed: [1.3], template: [1.2])
REVIEW REQUIRED: phase-testing.md          (installed: [1.2], template: [1.1])
REVIEW REQUIRED: phase-completion.md       (installed: [1.7], template: [1.9])
```

**Five installed files are AHEAD of the template. One is BEHIND.** The skill's output cannot express that distinction — `!=` yields the same string for both. 100% flag rate, 0% signal.

**DEFECT D4 — the version-marker mechanism assumes a lineage that does not exist here.** These are not stale copies; they are **ICON-specific forks** whose markers advanced on an independent track. The `phase-completion.md` diff (107 changed lines) is unambiguous — content present **installed-only**, absent from the "newer" template 1.9:

- the entire `## Update CHANGELOG [Unreleased]` section
- `**Final-state edits need their own commit.**` (the SHA/PR two-commit rule)
- a Context Update Checklist naming ICON's real domain/standards files and annotated for ICON's `excludes`
- the `ICON-0088` attribution on the merge-coalescing hazard
- ICON's actual reviewer standards list (`skill-decomposition.md`, `changelog-discipline.md`)

Template 1.9 replaces all of that with generic placeholders (`[TASK-ID]`, `.context/standards/code-style.md`, `**Tests:** [N added...]` — meaningless in a repo with no test runner, ADR-005).

Adjudication — **ACTIVELY WRONG to apply, all six.** Template 1.9 is **not a superset** of installed 1.7. "Upgrading" `phase-completion.md` would delete ICON's CHANGELOG step and SHA/PR rule and substitute a test-results field for a repo that has no tests. The five installed-ahead files are, if anything, an argument for back-porting *to* the template — which is out of scope here and would trip the template-version pre-commit invariant.

The skill **fails safe** (flag, never auto-overwrite), which is the right default and it held. But the report it produces is pure noise for this repo.

### 3.9 `local_task_id_prefix` collision — **DEFECT D2, false positive**

Current value: `ICON`. Running the check as specified (SKILL.md:175):

```
--- distinct prefixes in git log --oneline -100 ---
      1 ADR
     44 ICON
```

Applying the skill's rule literally — *"if the local prefix matches one (case-insensitive), report a finding"* — produces:

> `Local prefix 'ICON' collides with detected external ticket prefix 'ICON' — recommend changing to 'LOCAL' or another distinct value`

**The check has no exclusion for the local prefix's own commits.** It samples `git log`, which in any repo that has been using ICON for a while is *dominated* by commits carrying the local prefix. The prefix therefore always collides with itself, and the emitted finding is self-contradictory on its face ("collides with detected **external** prefix 'ICON'" — ICON is not external; it is the value being tested).

**This is a general consumer-facing defect, not an ICON quirk.** Every mature ICON repo hits it. Severity is limited because Phase 2 does not auto-rewrite the field (SKILL.md:515-519) — the damage is a false recommendation that a user might act on, renaming a working prefix to `LOCAL` and orphaning their task-ID history.

Secondary: `ADR` is also a false positive — it comes from `ADR-006` in a commit *subject*, a document reference, not a ticket. The `[A-Za-z]{2,}-\d+` pattern cannot distinguish them.

Adjudication of the finding itself — **INAPPLICABLE. Do not change `local_task_id_prefix`.** `ICON` is correct, documented in `.claude/CLAUDE.md`, and used by 81 task folders.

### 3.10 Hook wiring — **PASS with one real gap**

```
$ git config --get core.hooksPath
.githooks
```

But:
```
$ git ls-files -s .githooks/
100644 b84d11bf...  .githooks/post-commit
100644 7199b475...  .githooks/pre-commit
$ git config --get core.fileMode
false
```

**Both hooks are mode `100644` in the git index — not `100755`.** Phase 4 check #2 requires *"`.githooks/post-commit` is executable"* and it would **fail** on a strict reading.

This is a **genuine, ICON-owned, cross-platform defect** — and note the audit surfaced it only because I checked the index mode rather than trusting `core.hooksPath`. On Windows (`core.fileMode=false`) Git runs the hook via its shebang regardless, so it works here. **On a fresh macOS or Linux clone, a `100644` hook does not execute** — cache and task pruning silently never run for those contributors.

`prune-context.sh` is *not* affected (also 100644, but `.githooks/post-commit:6` invokes it as `bash "$(...)/prune-context.sh"`, so its own bit is irrelevant).

Phase 1 as written does **not** check the exec bit — it only asks whether the hook is "present and current". The check lives in Phase 4, i.e. after the writes. Recommend fixing via `git update-index --chmod=+x` — **out of scope for this dispatch; flagging for triage.**

### 3.11 Workflow-file set — deltas both directions

| In template, not installed | Adjudication |
|---|---|
| `workflows/ci-cd.md` | **INAPPLICABLE.** ADR-005 pure-content repo; ICON's CI is `.github/workflows/security.yml` (gitleaks/semgrep/shellcheck), documented in `overview.md`. Not a missing file. |
| `workflows/task-workflow-template.md` | **ACTIVELY WRONG.** Deprecated by this very skill (§3.3). Its presence in the template is itself questionable. |
| `workflows/post-commit` | **INAPPLICABLE.** Correctly installed at `.githooks/post-commit`, byte-identical. Not missing — relocated by design. |

| In installed, not in template | Adjudication |
|---|---|
| `workflows/changelog.md` | ICON-specific; `rules-index.md` routes to it. Keep. Not drift. |
| `workflows/task-start-conventions.md` | ICON-specific. Keep. Not drift. |
| `.context/retrospectives-archive.md` | Keep — `.gitattributes` gives it `merge=union`. Note the **template has no `retrospectives-archive.md`**, so a fresh consumer gets the `.gitattributes` entry for a file that will not exist until first archive. Cosmetic. |

### 3.12 Content files — correctly untouched, correctly divergent

`overview.md` (48 vs 224 lines), `META.md` (103 vs 103, ICON-specialized), `rules-index.md` (45 populated vs 23 sentinel) all differ substantially from the template.

Adjudication — **INAPPLICABLE by design, and the skill agrees.** Phase 2 states *"Content files (`overview.md`, `decisions/`, domain files) are never touched here"* and `rules-index.md` is explicitly *"Create it only if absent — NEVER overwrite."* All three are populated. **No action, and the skill correctly takes none.** Recording it so the divergence is not later mistaken for drift.

### 3.13 `## Related` graph seam — **DEFECT D6, confirmed**

```
=== does upgrade-repo mention '## Related' / graph seam? ===
NO MATCHES in upgrade-repo/SKILL.md
```

Confirmed: **the Phase 1 audit does not surface this at all.** The seam ships in 11 template files (`domains/entities.md`, `domains/glossary.md`, `standards/code-style.md`, `workflows/branching.md`, …) and is handled by `context-specialist-impl-leaf` / `-impl-root` / `context-maintenance` — **all init-or-maintenance paths.** There is no upgrade path.

Evidence of the consequence in ICON itself: only **one** `.context/` content file carries a `## Related` section (`domains/github-access.md`) — plus a design doc under `tasks/`. ICON-0081 shipped the seam to the template at template version 1.9 and it never reached ICON's own `.context/`, which is the exact class of failure this dogfood run was commissioned to detect.

Adjudication — **CORRECT to apply, but not by `upgrade-repo`.** The seam belongs in ICON's `.context/`. The right vehicle is `context-maintenance` (Phase 3), not a template file copy, because the `## Related` links must be derived from ICON's actual file graph. **This is a skill gap to fix, logged for triage — not something to hand-patch during this run.**

---

## 4. Skill defects observed — summary

| # | Defect | Severity | Reproduced |
|---|---|---|---|
| **D1** | `find-context-template` PowerShell branch yields broken `$TEMPLATE_DIR` (`CLAUDE_PLUGIN_ROOT` unset → `/context_template`); `upgrade-repo` never validates before use | **High** | Yes — `ItemNotFoundException`, verbatim in §2 |
| **D2** | `local_task_id_prefix` collision check has no self-exclusion → false positive in every mature ICON repo | **High** (consumer-wide) | Yes — §3.9 |
| **D4** | task-plan version markers assume shared lineage; `!=` cannot express direction → 6/6 flagged, 0 actionable | **Med-High** | Yes — §3.8 |
| **D8** | `iconrc.json` `version` is a template-tree content counter, but the skill calls it a "schema version" and treats a bare field write as the upgrade | **High** | Yes — §3.7 |
| **D5** | `prune-context.sh` `cp` sits in a conditional paragraph but reads unconditional → reverts deliberate `INTEGRATION_BRANCHES` | **Medium** | Ambiguity confirmed; not executed |
| **D6** | No `## Related` graph-seam step in `upgrade-repo` | **Medium** | Yes — §3.13 |
| **D3** | Version compare is undirected; an ahead-of-template repo is silently downgraded and Phase 4 #7 calls it success | **Medium** | Logic confirmed |
| **D7** | `decisions/` absent from the Phase 1 directory checklist | **Low** | Yes — §3.2 |
| **D9** | Phase 0 root-`claude.md` creation is an unguarded `cat >` — mutates the tree before the Phase 1 approval gate | **Low-Med** | Condition confirmed live |

**Predicted defects that did NOT reproduce:**
- **C1** (`task-workflow-template.md` stock-vs-CUSTOMIZED misclassification) — path unreachable; file absent. Not disproved, just not exercised.
- Flat `decisions.md` migration — path unreachable; `decisions/` present.
- **GNU-only `grep -oP` / `sed -i`** — **did not fail on Windows.** Git Bash ships GNU grep 3.0 + GNU sed; the block printed the correct `1.2 → 1.12`, not the predicted silent `already at `. **Still live on macOS/BSD.**

**Environment friction (not a skill defect, but a trap for Windows users):** `python3` in PowerShell resolves to the Windows Store stub (`WindowsApps\python3.exe`), which prints *"Python was not found"* and exits non-zero. Real Python is `python` (`C:\Python314`). `skills/icon-status/SKILL.md:108` and `.claude/CLAUDE.md`'s JSON-validation command both invoke `python3` and will fail this way on a default Windows box.

---

## 5. Recommendation for the go/no-go

### Apply nothing automatically. Recommended Phase 2 = **empty.**

| Item | Verdict | Action |
|---|---|---|
| `iconrc.json` `1.2 → 1.12` | **ACTIVELY WRONG as a bare write** | **Do not apply.** No schema delta; the field is a template-tree counter; writing `1.12` falsely asserts template-1.12 content that §3.8 shows ICON must *not* adopt. If the field is to be corrected, do it as a deliberate, documented maintainer decision — not as an upgrade side effect. |
| task-plan phase templates (all 6) | **ACTIVELY WRONG** | **Do not apply.** 5 installed-ahead, 1 (`phase-completion`) is a customized fork the template does not supersede. |
| `prune-context.sh` | **ACTIVELY WRONG** | **Do not copy.** `^main$` implements ADR-002. Rest of script already current. |
| Root `claude.md` redirect | **INAPPLICABLE** | Leave absent unless the maintainer wants Copilot parity deliberately. |
| `local_task_id_prefix` → `LOCAL` | **INAPPLICABLE (false positive)** | Keep `ICON`. |
| `ci-cd.md`, `task-workflow-template.md`, `workflows/post-commit` | **INAPPLICABLE** | Not missing — excluded, deprecated, and relocated respectively. |
| `.gitattributes`, `.context/.gitignore`, `.githooks/post-commit` content, `rules-index.md`, all required dirs & files | **Already correct** | No-op. |

### Genuinely worth doing — but as separate, triaged work

1. **`## Related` graph seam is missing from ICON's `.context/`** (1 of N files has it). **CORRECT to close** — via `context-maintenance`, which can derive real links. Also fix D6 so consumers get it.
2. **`.githooks/*` are mode `100644`.** Real cross-platform defect in ICON's own repo — hooks silently do not run on macOS/Linux clones. `git update-index --chmod=+x` on both.
3. **D1, D2, D8, D4, D5** are consumer-facing skill defects. D2 and D8 affect every consumer; D1 affects every Windows/PowerShell consumer.

### Phase 3 (content currency) — recommend running

Not part of this dispatch, but the §3.13 finding is direct evidence of content drift (ICON-0081's seam never landed). The 5-name sample check is cheap and the `## Related` gap suggests it will trip the ≥2-of-5 threshold.

### The dogfooding verdict

The run did what it was commissioned to do. **Every defect it surfaced is in the *judgment* layer, not the mechanical one** — the file copying is basically fine; the version *semantics* are wrong. `upgrade-repo` is safe to run (it fails safe on every write it would make) but its Phase 1 report is, for this repo, **6 false "REVIEW REQUIRED", 1 false collision finding, and 1 recommended write that would record an untrue claim.** A consumer following it literally would revert a documented ADR and rename their task-ID prefix.

The deeper structural point for triage: **`upgrade-repo` has no concept of a customized installed file.** Its only two states are "matches template" and "differs from template," and it maps the second onto "behind." Until it can distinguish *stale* from *forked*, its version-marker reporting will be noise for exactly the mature repos that most need upgrading.
