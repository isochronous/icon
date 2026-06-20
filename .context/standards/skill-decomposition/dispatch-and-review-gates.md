# Dispatch and Review Gates

Discipline that applies to what goes INTO a dispatch and how the result is reviewed: echo decisional inputs verbatim into the @coder dispatch, decide when a single @reviewer pass suffices versus when Pass 2 is required, and terminate the architecture spec or @coder dispatch in a runnable verbatim acceptance-gate checklist.

## Echo Decisional Inputs Into Dispatch

When dispatching @coder (or any specialist) with task work, restate any decisional input that could be reflexively missed — out-of-scope surfaces, project-specific rules (no-`2>/dev/null`, no-mocks-in-tests), or user clarifications from the issue body. Echo them verbatim inside the dispatch prompt's Hard Constraints or sub-task body, not by reference. The cost is ~30-50 tokens per restatement; the saved cost is one round-trip when the @coder silently inherits a reflexive habit.

**Three narrow sub-patterns observed:**

1. **Out-of-scope surface restatement** (ICON-0026) — when a process-doc convention is repo-local and the standard three-surface sweep does NOT apply, name the two surfaces NOT to touch explicitly inside the dispatch's OUT-of-scope list. Prevents the @coder from sweeping `context_template/` and `skills/<phase>/SKILL.md` on reflex.
2. **Project-rule restatement** (ICON-0030) — when a project rule is likely to be reflexively violated (`2>/dev/null` suppression, in that case), name the constraint AND the alternative pattern in the dispatch's Hard Constraints section. The alternative-pattern half is load-bearing; "don't do X" alone leaves the @coder to invent a substitute.
3. **User-clarification restatement** (ICON-0034, ICON-0035, ICON-0037, ICON-0038) — when the user has clarified scope on the GitLab issue (or in a recent message), quote the clarification verbatim inside the relevant sub-task body. The clarification often contradicts the issue body's original recommendation; quoting it removes the ambiguity for @coder. ICON-0035 added a "Maintainer revisions (echo verbatim)" section to the dispatch listing three maintainer comments ("put it in the skill, not in .context", "what is the purpose of listing callers?", "rewrite to be company-agnostic") — @coder produced angle-bracketed placeholders rather than renaming "DataScan" to "Acme", removed Pattern 3 entirely rather than narrowing it, and placed the primitive in the skill rather than in `.context/`. Zero scope drift. ICON-0037 echoed three user-resolved decisions (m-U-B generic verb, m-U-E single-option, m-U-I drop) AND the user's per-line conditional rule for briefs verbatim into the per-sub-task brief sections of the @coder dispatch; @reviewer Pass 1 found zero deviation from user-intended scope. ICON-0038 echoed three user-resolved decisions (O-M2 drop verbatim, O-M3 remove field, m-1 partial-ship with .mcp.json deferred) quoted verbatim in plan.md Decisions AND in @coder dispatch with "(verbatim from user-resolved scope)" labels; reviewer Pass 1 found zero deviation from user intent.

**Why not just rely on the issue body**: dispatched sub-agents read the issue body via the prompt, but reflexive habits and prior-training-data defaults can override what the body says when the body is read as background rather than as a Hard Constraint. The verbatim echo elevates the input from "context the agent should remember" to "constraint the agent is being held to."

**When NOT to use**: trivial single-line edits where the entire dispatch is one acceptance criterion. The pattern is for multi-sub-task dispatches where the @coder might satisfy one sub-task by skipping a constraint that came from elsewhere.

**Precedents**: ICON-0026 (out-of-scope-surface restatement, zero three-surface drift), ICON-0030 (project-rule restatement, zero stderr-suppression introduced), ICON-0034 (user-clarification restatement, zero deviation from user-intended scope), ICON-0035 (user-clarification restatement, second instance at the same narrow sub-pattern with three distinct maintainer revisions echoed verbatim), ICON-0037 (user-clarification restatement, third instance — three user-resolved decisions plus a per-line conditional rule echoed verbatim across the dispatch, zero scope deviation), ICON-0038 (user-clarification restatement, fourth instance — three user-resolved decisions with "(verbatim from user-resolved scope)" labels, zero scope deviation). Six instances on the broad axis across three distinct narrow sub-patterns — broad-axis stability gate met with the user-clarification sub-pattern now confirmed across four independent tasks.

## Reviewer Pass Cadence: When Single-Pass Suffices

A single @reviewer pass is sufficient — and a second pass is ceremony without signal — when **all three** of these gates hold:

1. The diff is **small** (< 50 lines net change, or < 10 files — whichever is more permissive).
2. The changes are **mechanical** (no judgment calls inside the change itself — e.g., frontmatter normalization, fence balance, threshold delegation by reference, doc renumber).
3. The dispatch brief **explicitly names** the cross-surface risk axes the reviewer must check (e.g., "verify the ICON-0014 renumber-backref invariant; verify the ICON-0027 inverse-phrasing sweep against peer agents; verify the ICON-0031 frontmatter parse-test gate").

Pass 1 with zero Critical/Moderate findings under these conditions is a reliable signal. Adding Pass 2 finds nothing new and costs ~2 minutes of reviewer time.

**Counter-rule (multi-pass IS required)**: process-rule changes that touch multiple agents' Hardcoded tiers (ICON-0027); state-machine implementations with N orthogonal flags (ICON-0013); frontmatter edits where the parse-test was never run inside the dispatch (ICON-0031). When the diff makes Hardcoded-tier invariants negotiable or introduces structural complexity, Pass 2 catches what Pass 1 misses.

**Anti-rationalization:**

| Excuse | Reality | Correct Action |
|---|---|---|
| "Reviewer said GOOD, that's enough" | Reviewer GOOD on a multi-Hardcoded-tier process-rule change is the failure mode ICON-0027 caught with Pass 2. | If condition (2) or (3) fails, run Pass 2 even after Pass 1 GOOD. |
| "Single-pass is fine, the diff is small" | Size is condition (1) of three. A small diff that introduces a state machine still needs Pass 2. | All three conditions must hold; "small" alone is not the gate. |
| "Naming risk axes is over-engineering for small edits" | Without named axes, Pass 1 GOOD reflects only the surfaces the reviewer happened to check. Named axes turn Pass 1 into a covering check. | The dispatch brief's "verify these specific risks" list IS the single-pass-sufficiency justification. |

**Precedents**: ICON-0027 small process-rule edit (1 pass, GOOD), ICON-0028 single-line edit (1 pass, GOOD), ICON-0029 skill-internal consistency (1 pass, GOOD), ICON-0034 multi-file mechanical sweep (1 pass, GOOD), ICON-0037 18-file bundled utility-skill sweep with 7 explicitly-named cross-surface risk axes (1 pass, 1 Minor + 1 out-of-scope flag, zero rework — confirms the pattern scales to 18-file bundled sweeps when the risk axes are pre-named in the dispatch), ICON-0038 release-flow + infrastructure hardening with 9 risk axes named (JSON correctness, bash logic, portability, no-stderr-suppression, dead-conditional cleanup, scope discipline, tree well-formedness, no accidental fs changes, voice consistency) — single Opus pass returned one Minor + zero out-of-scope drift. Six instances on the broad axis; stability gate met.

## Verbatim Acceptance-Gate Checklist in Architecture Spec or Coder Dispatch

When the @architect spec (or, when no @architect pass is needed, the @coder dispatch directly) terminates in an acceptance-gates section, that section must be a **runnable bash checklist** — exact commands, expected output, and explicit ties to the risk axes the brief names. The coder pastes raw output for each gate; the reviewer independently re-runs a sample; PASS/FAIL is mechanical rather than interpretive. The investment shifts judgment from the implementation/review phase (where ambiguity is expensive) to the architect (or dispatch-author) phase (where it is cheap).

**When to require verbatim gates in the architect spec**:

- Audit-finding tasks touching 5+ files (the gate-density-per-file ratio justifies the investment).
- Bundled sweeps with multiple sub-tasks (one gate or more per sub-task is necessary for sub-task-level acceptance).
- Any task with named risk axes in the brief (the gates are how the risk axes get verified; without them the risk-axis naming is decorative).

**What makes a gate "verbatim"**: three components, all required.

1. **Exact bash command** — copy-pasteable, including paths, flags, and any pipelines. Not "grep for X" but `grep -rinE "<exact-regex>" <exact-path>`.
2. **Expected output verbatim** — either the exact match list, or "empty" (zero matches), or a numeric value. Not "should be small" or "no leftover instances".
3. **Explicit tie to a risk axis or sub-task acceptance criterion** — name which sub-task or which risk axis the gate is verifying. E.g., "Gate G4 verifies the ICON-0014 renumber-aware-backref invariant for the m5 sub-task". The tie is what turns the gate from a check into a covering check.

**Cost-benefit at four task scales**:

- **ICON-0032** (single-skill plus 12-file refactor): the architecture spec's acceptance-gates list let @coder paste raw output per gate; reviewer re-ran them all; Pass 1 returned GOOD with only Minor findings. Without the verbatim gates the reviewer would have had to reconstruct the check protocol from scratch.
- **ICON-0033** (single-config edit + Testing-All-Skill-Types extraction): the architecture spec named the line-count gate, the extraction-success gate, and the cross-reference-integrity gate; @coder pasted line counts; Pass 1 GOOD.
- **ICON-0035** (16-file bundled sweep, 8 sub-tasks): 13 gates G1–G13 with exact bash commands, expected output, and explicit ties to risk axes (ICON-0014 renumber-aware, ICON-0027 inverse-phrasing, ICON-0030 portability, ICON-0031 frontmatter parse-test). Coder pasted raw output for each gate; reviewer re-ran a sample and reached the same PASS/FAIL conclusions. Zero gate-interpretation ambiguity across the bundled sweep.
- **ICON-0037** (18-file bundled utility-skill sweep, 7 sub-tasks, no @architect pass): per-sub-task `grep -nE ...` gates with expected output lived directly in the @coder dispatch (m-U-A through m-U-I sections). @coder ran each gate and pasted raw output; @reviewer re-ran them all in a single pass and returned 1 Minor + 1 out-of-scope flag, zero rework. Confirms the pattern scales DOWN to mechanical-sweep tasks where @architect would be overhead — the gates simply move one layer earlier (into the dispatch) without losing any of the structural properties. Named sub-pattern: **gates-at-dispatch-layer** — when the task is mechanical enough that no @architect spec is warranted, the verbatim gate checklist lives in the @coder dispatch directly, same gate format, just at a different layer.
- **ICON-0038**: 11-gate checklist (G1-G8 + CC1-CC4) in @coder dispatch; @coder pasted raw output; @reviewer independently re-ran a subset. Single Opus pass returned one Minor and zero scope drift.

The cost (a 10–20 line block at the end of the spec or dispatch) is fixed; the benefit scales linearly with file count. At 16 files the investment pays back many times over in saved reviewer-round-trip cost; at 18 files with gates-at-dispatch-layer the saving is also the @architect round-trip itself.

**Known limitation — self-tripping gates**: when the spec prescribes new documentation that *describes* the defect class the gate detects, the gate's regex may match the prescribed text (the gate sees the new doc as a re-instantiation of the defect). Three mitigations, pick one: (i) write the gate regex to exclude the prescribed block paths, (ii) paraphrase the gate's target tokens to avoid the new doc's vocabulary, or (iii) accept the self-trip and document it inline in the gate as a known limitation. (Surfaced at ICON-0035 G10 — `caller.*description|description.*caller|enumerate caller|caller lists` matched the ADR/Decision-Log Pointer block the spec itself prescribed; accept-via-context resolution required.)

**Anti-rationalization**:

| Excuse | Reality | Correct Action |
|---|---|---|
| "The coder will figure out what 'works' means" | Coder reasoning is not verification. Implicit pass/fail criteria become arguments at review time. | Pin every acceptance criterion to a runnable command with verbatim expected output. |
| "These gates are over-specified for a small change" | The gate spec cost is fixed (~10 lines); a single saved reviewer round-trip recovers it. Below 5 files the ratio is borderline; above 10 it is conclusive. | Below 5 files, use judgement. Above 5, require verbatim gates. |
| "The risk axes in the brief are already named; the gate names are redundant" | The brief names the risk; the gate verifies it. Without the tie, the gate is an isolated check rather than a covering check. | Tie each gate to a sub-task acceptance criterion or to a named risk axis from the brief. |

**Precedents**: ICON-0032 (single-skill + 12-file refactor, gates in @architect spec), ICON-0033 (single-config + extraction, gates in @architect spec), ICON-0035 (16-file bundled sweep, 13 gates G1–G13, gates in @architect spec), ICON-0037 (18-file bundled sweep, gates-at-dispatch-layer — first precedent for the no-@architect narrow sub-pattern), ICON-0038 (11-gate checklist in @coder dispatch, gates-at-dispatch-layer second precedent, single Opus reviewer pass returned one Minor + zero scope drift). Five instances on the broad axis with monotonic surface-count growth; 3+-task stability gate met; gates-at-dispatch-layer narrow sub-pattern confirmed across two independent tasks.


---

See [`../skill-decomposition.md`](../skill-decomposition.md) for the full skill-decomposition index.
