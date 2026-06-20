# Architecture: ICON-0032 — pre-commit hook extensions

**Task:** ICON-0032
**Spec for:** @coder
**Scope:** Design only. No code edits. Deliverable is this doc.

---

## Summary

Add two new diff-style invariant checks to `.githooks/pre-commit`:

1. **Check A — Angle-bracket placeholder grep + `.context/<subdir>/<file>.<ext>` reference resolver**, scoped to staged files under `agents/`, `skills/`, `shared/`, `commands/`. Fence-stripping logic is reused from the existing common-constraints awk pass.
2. **Check B — Byte-equality gate** across the three `append-retrospective-entry.{sh,ps1}` script pairs (post-incident-review / task-retrospective / context-maintenance).

Both checks run only when their relevant files are staged (path-prefix branching). The hook is local repo infrastructure (`.githooks/` does not ship to consumers) — the three-surface sweep rule does NOT apply.

---

## Recommendation

**Decision:** Approve as designed below.

**Rationale:** Existing fence-aware awk in `.githooks/pre-commit` (ICON-0011 + ICON-0013) is reusable for fence-stripping. The exception-marker convention is the load-bearing piece; without one that surfaces zero false positives on the ~20 legitimate-placeholder files in the repo today, the hook is unusable. The design below specifies a marker convention that satisfies all three constraints (no natural occurrence, inline-safe, supports per-file mode), enumerates the N-flag transition matrix, and resolves the three dead refs by fixing the references (not by adding files to the template).

---

## Section 1 — Exception-marker convention

### Constraints (from preflight audit)

- (a) Cannot appear naturally in agent/skill prose.
- (b) Must work both for individual `<placeholder>` matches AND for whole-file allowances (synthesis-template.md is wall-to-wall placeholders across 156 lines).
- (c) Must survive both inside backtick-quoted spans and in plain markdown body.

### Chosen syntax

**Two forms, both HTML-comment-based:**

| Form | Syntax | Scope | Where it goes |
|------|--------|-------|---------------|
| **Per-file** | `<!-- icon:allow-placeholders file -->` | Whole file — suppress placeholder check for every line | Anywhere in the file (recommended: line 1 or just after frontmatter) |
| **Per-line** | `<!-- icon:allow-placeholders -->` | The line it appears on only | End of the line containing the placeholder |

Both forms are HTML comments and render as nothing in markdown viewers, including GitHub/GitLab and Claude Code's surface previews.

### Justification against the three constraints

**(a) Does not appear naturally.** Repo-wide grep:
- `grep -rnF 'icon:allow-placeholders' .` returns zero results in agents/, skills/, shared/, commands/, .context/, context_template/. The string `icon:allow-placeholders` is a coined marker.
- HTML comments `<!-- ... -->` are already used for the BEGIN/END markers in shared/common-constraints.md and agents/*.agent.md; the syntax is established repo vocabulary, not foreign.

**(b) Per-file form handles synthesis-template.md.** A single marker line at the top of synthesis-template.md suppresses all 100+ legitimate placeholder lines without per-line annotation. The per-line form is for files that contain ONE legitimate placeholder in otherwise checkable content (e.g., a single `<task-folder>` reference in an agent dispatch template).

**(c) Inline-safe in both prose and backticks.** HTML comments are not consumed by markdown's inline-code parser — `<!-- icon:allow-placeholders -->` after a backtick-quoted placeholder like `` `<task-folder>` `` is treated as trailing HTML in the surrounding block, not as content of the inline-code span. Critically, the marker syntax cannot itself contain `<placeholder>` characters that would self-trigger.

### Alternatives considered and rejected

- Trailing `# icon:allow-placeholders` shell-style comment — visually pollutes rendered markdown.
- YAML frontmatter key — many target files have no frontmatter; would force adding it.
- Escape angle brackets (`\<task-folder\>`) — mutates rendered prose.
- External allowlist file — two surfaces drift on every rename. Marker-with-content wins.
- Path-based exemption (e.g., exempt `skills/plugin-audit/` wholesale) — coarser than needed; per-file marker is explicit and reviewable.

### How @coder applies the convention

For each of the ~20 files identified in the preflight audit, the @coder must:

1. Determine per-file vs per-line scope by counting placeholders.
   - **Heuristic:** 3+ placeholder lines or wall-to-wall template content → per-file marker.
   - **Heuristic:** 1–2 placeholders in otherwise checkable prose → per-line markers.
2. For per-file: add `<!-- icon:allow-placeholders file -->` on a line by itself near the top (after frontmatter if present; otherwise as the first line).
3. For per-line: append ` <!-- icon:allow-placeholders -->` (with leading space) at the end of each placeholder line.

The audit lists per-file vs per-line decisions for the known ~20 files; @coder follows that, and any newly-discovered placeholder is added the same way.

---

## Section 2 — Fence-stripping reuse and N-flag transition matrix

### Reuse target

The existing awk pass at `.githooks/pre-commit` lines 70–225 already implements CommonMark §4.5 fenced-code-block detection with two flags: `inside_block` and `inside_fence`. This logic is the SSOT for fence detection in the hook.

**Strategy:** Refactor the fence-detection portion into a reusable awk subroutine OR (simpler) keep two parallel awk passes that share the SAME fence-detection logic via a copy-paste-with-comment pointing to the SSOT. **Recommendation: separate awk script per check class**, because the existing pass mutates the file (in-block content drop + replacement) and the new checks are read-only (grep-style). Mixing read-only with rewrite logic in one awk pass produces a state machine that's hard to reason about and hard to fixture-test.

The new placeholder-check awk only needs the **fence-detection half** (the `is_fence` block at lines 107–166), not the BEGIN/END marker logic. Copy-paste with a header comment: `# Fence detection: see .githooks/pre-commit lines 107-166 for the authoritative implementation. Keep in sync.`

(A future refactor could extract a shared awk include, but awk's `@include` is GAWK-only; we cannot use it cross-platform. ICON-0030 portability lesson applies. The duplication is mechanically constrained because the script-parity check itself doesn't gate the hook script — but the duplication is small (~60 lines of awk) and inside a single file, so reviewable.)

### New flag

The placeholder check introduces ONE new flag:

- `in_allow_block` — set to 1 for the entire file after seeing `<!-- icon:allow-placeholders file -->` anywhere; never resets.

The per-line form is handled at line-evaluation time, not as a flag: check `index(line, "<!-- icon:allow-placeholders -->") > 0` on the same line that has the placeholder match.

### Full 3-flag transition matrix

Flags: `inside_fence`, `in_allow_block`, plus the per-line predicate `line_has_marker` (a per-iteration boolean, not a state flag).

| Current state                                  | Input line                                | New state                                      | Action                                                                 |
|------------------------------------------------|-------------------------------------------|------------------------------------------------|------------------------------------------------------------------------|
| `inside_fence=0, in_allow_block=0`             | Fence-open line (3+ `` ` `` or `~`)       | `inside_fence=1, in_allow_block=0`             | No check. Pass line.                                                   |
| `inside_fence=0, in_allow_block=0`             | `<!-- icon:allow-placeholders file -->`   | `inside_fence=0, in_allow_block=1`             | No check on this line. Pass.                                           |
| `inside_fence=0, in_allow_block=0`             | Line with `<placeholder>` match, no per-line marker | unchanged                            | **FAIL** — record finding.                                             |
| `inside_fence=0, in_allow_block=0`             | Line with `<placeholder>` match AND `<!-- icon:allow-placeholders -->` on same line | unchanged   | Pass — per-line allowance honored.                                     |
| `inside_fence=0, in_allow_block=0`             | Line without placeholder match            | unchanged                                      | Pass.                                                                  |
| `inside_fence=1, in_allow_block=0`             | Fence-close line (matching char, same len, no info) | `inside_fence=0, in_allow_block=0`   | Pass. No placeholder check (we're transitioning out, line itself is fence). |
| `inside_fence=1, in_allow_block=0`             | Any non-fence line (inside fenced block)  | unchanged                                      | Pass. **No placeholder check** — fenced content is exempt by design.   |
| `inside_fence=1, in_allow_block=0`             | `<!-- icon:allow-placeholders file -->` inside fence | unchanged (NOT activated)             | Pass. Marker inside fence is literal content, not a directive.         |
| `inside_fence=0, in_allow_block=1`             | Fence-open                                 | `inside_fence=1, in_allow_block=1`             | No check (allow-block suppresses anyway). Pass.                        |
| `inside_fence=0, in_allow_block=1`             | Any line                                   | unchanged                                      | Pass — file-wide allowance.                                            |
| `inside_fence=1, in_allow_block=1`             | Fence-close                                 | `inside_fence=0, in_allow_block=1`             | Pass.                                                                  |
| `inside_fence=1, in_allow_block=1`             | Any line                                   | unchanged                                      | Pass.                                                                  |

**Critical invariants the matrix encodes:**

1. **Placeholder-check only fires when both `inside_fence=0` AND `in_allow_block=0`.** This is the read-equivalent of the ICON-0013 in-block drop predicate (`inside_block==1` was sufficient there because in-block content was unconditionally dropped — here, placeholder check is unconditionally skipped when either suppressor is active).
2. **The per-file marker inside a fenced code block does NOT activate `in_allow_block`.** This prevents code-block examples that contain the marker as literal text (e.g., this design doc explaining the syntax) from accidentally suppressing the check across the whole file. The check for the marker is gated on `inside_fence==0`.
3. **`in_allow_block` is monotonic (set-once, never reset).** Once activated, it stays active for the rest of the file. There is no `<!-- icon:disallow-placeholders -->` counterpart; the semantics are "this file is a template" not "this region is a template."

### Why this matrix is safe vs ICON-0013's leak

ICON-0013's bug was that the IN-block drop predicate depended on `inside_fence` state, and a stale fence opener inside the to-be-replaced block flipped `inside_fence=1` and broke the predicate. Here:

- The placeholder check is read-only — no in-block state to corrupt.
- `in_allow_block` does not depend on `inside_fence` transitions (it's set by a marker line, not by entering/leaving any region).
- The dependency graph between the three flags is acyclic: `inside_fence` is computed per-line independently; `in_allow_block` is set once based on a single line shape; `line_has_marker` is per-line only.

No flag is mutated as a side effect of another flag's state. ICON-0013's leak required two flags to interact at a state boundary; this matrix has no such interaction.

---

## Section 3 — `.context/<subdir>/<file>.<ext>` reference resolver

### Regex

```
\.context/[a-zA-Z0-9_/-]+\.[a-zA-Z0-9]+
```

Requirements baked into the regex:
- Specific filename only — must end in `.<ext>`. Bare directory references like `.context/architecture/` (no filename, no extension) are NOT flagged. (Issue spec: directories are intentional pointers.)
- Allows nested subdirs (`.context/workflows/task-plan/base.md`).
- Allows underscores and hyphens in filenames.

Edge case: `.context/iconrc.json` — matches the regex (json extension). This is correct; if a doc references `.context/iconrc.json` it should resolve against `context_template/context/iconrc.json`.

### Path-mapping rule

For each match `.context/<rest>`:

```
verify_path = "context_template/context/" + rest
```

If `verify_path` does not exist as a regular file in the repo, **FAIL** with:
```
[pre-commit] error: <staged-file>:<line>: dead .context/ reference -> '.context/<rest>'
  expected at: context_template/context/<rest>
  fix: re-point the reference or add the file to context_template/
```

### Fence-stripping behavior for the ref resolver

**Decision: the ref resolver runs WITHOUT fence-stripping.** A path-in-backticks like `` `.context/architecture/patterns.md` `` is just as load-bearing as the same path in plain prose — both are user-facing guidance that an installed plugin instance will surface to a reader who tries to open the path. Skipping fenced content here would silently exempt the most common citation style (backtick-quoted paths in skill SKILL.md files).

Implication: the ref resolver scans every line of every staged file in scope, regardless of fence state. The `<!-- icon:allow-placeholders -->` markers do NOT apply here — they are for the placeholder check only.

(If a future need surfaces for legitimately-dead refs — e.g., a historical example in a retro entry — add a separate marker `<!-- icon:allow-dead-ref -->`. Not in scope for ICON-0032.)

### The three known dead refs

These are pre-flight findings. The hook would fail on day 1 if not fixed. @coder MUST fix these in the same PR before the hook is enabled:

1. `skills/context-specialist-impl-root/SKILL.md:257` → `.context/architecture/patterns.md`
2. `skills/task-plan-phase-completion/SKILL.md:59` → `.context/architecture/patterns.md`
3. `skills/upgrade-repo/SKILL.md:194` → `.context/workflows/prune-old-tasks.sh`

See Section 7 for resolution decisions per ref.

---

## Section 4 — Script-parity check

### Scope: three pairs, not two

**Decision: gate all three pairs.**

The audit confirmed all three copies (post-incident-review, task-retrospective, context-maintenance) are currently byte-identical:

```
diff -q skills/post-incident-review/scripts/append-retrospective-entry.sh \
        skills/task-retrospective/scripts/append-retrospective-entry.sh
diff -q skills/post-incident-review/scripts/append-retrospective-entry.sh \
        skills/context-maintenance/scripts/append-retrospective-entry.sh
diff -q skills/post-incident-review/scripts/append-retrospective-entry.ps1 \
        skills/task-retrospective/scripts/append-retrospective-entry.ps1
diff -q skills/post-incident-review/scripts/append-retrospective-entry.ps1 \
        skills/context-maintenance/scripts/append-retrospective-entry.ps1
```

**Rationale:** Issue #17 named only two copies because the third copy was not on the issue author's radar (Brief 04 of the audit verified only two pairs). Gating only two would leave a latent divergence class — if a future change updates the post-incident-review and task-retrospective copies but forgets context-maintenance, the hook would not catch it. The marginal cost is one extra `diff -q` per pair; the marginal benefit is closing the third-copy hole permanently.

If a future task ever justifies the three copies diverging (e.g., context-maintenance gains incident-specific behavior), the hook fails, the divergence is surfaced as a PR concern, and the decision becomes explicit — which is the correct behavior. The hook is not making policy; it is enforcing the current policy ("these three are byte-identical").

### Implementation shape

Fail-fast on first divergence. Using post-incident-review as the canonical source:

```bash
canonical_sh="$repo_root/skills/post-incident-review/scripts/append-retrospective-entry.sh"
canonical_ps1="$repo_root/skills/post-incident-review/scripts/append-retrospective-entry.ps1"
script_copies_sh=(
  "$repo_root/skills/task-retrospective/scripts/append-retrospective-entry.sh"
  "$repo_root/skills/context-maintenance/scripts/append-retrospective-entry.sh"
)
script_copies_ps1=(
  "$repo_root/skills/task-retrospective/scripts/append-retrospective-entry.ps1"
  "$repo_root/skills/context-maintenance/scripts/append-retrospective-entry.ps1"
)

for copy in "${script_copies_sh[@]}"; do
  if ! diff -q "$canonical_sh" "$copy" >&2; then
    echo "[pre-commit] error: $copy diverges from $canonical_sh" >&2
    echo "  fix: re-sync the copies (all three must be byte-identical)" >&2
    exit 1
  fi
done

for copy in "${script_copies_ps1[@]}"; do
  if ! diff -q "$canonical_ps1" "$copy" >&2; then
    echo "[pre-commit] error: $copy diverges from $canonical_ps1" >&2
    echo "  fix: re-sync the copies (all three must be byte-identical)" >&2
    exit 1
  fi
done
```

Notes:
- `diff -q` output goes to stderr (no `2>/dev/null` — ICON-0030 lesson).
- `diff -q` exit codes: 0 = identical, 1 = differ, 2 = error. The `if ! diff -q ...` clause handles 1 and 2 the same way (fail), which is correct.

### Choice of canonical source

`post-incident-review` is the canonical source because:
- Brief 04 of the audit (the source for the issue) used it as the comparison baseline.
- Alphabetically first among the three (post-incident-review < task-retrospective; context-maintenance is first alphabetically but came later by audit ordering).

The choice is mechanical — if any of the three diverge, the hook fails regardless of which is canonical. The canonical name appears in the error message so the @coder knows which file to align with.

---

## Section 5 — Scope-by-path-prefix branching

### Existing pattern

The current hook uses `shopt -s nullglob` + `agents/*.agent.md` to scope the common-constraints sync. New scoping uses the staged-files list, which is the standard pre-commit pattern.

### Staged-files filter

```bash
# All staged files (Added, Copied, Modified, Renamed; not Deleted).
mapfile -t staged < <(git diff --cached --name-only --diff-filter=ACMR)

# Filter to files under the four target prefixes.
placeholder_check_files=()
for f in "${staged[@]}"; do
  case "$f" in
    agents/*|skills/*|shared/*|commands/*)
      placeholder_check_files+=("$f")
      ;;
  esac
done

# Script-parity check triggers if ANY of the six tracked copies is staged.
script_parity_needed=0
for f in "${staged[@]}"; do
  case "$f" in
    skills/post-incident-review/scripts/append-retrospective-entry.sh|\
    skills/post-incident-review/scripts/append-retrospective-entry.ps1|\
    skills/task-retrospective/scripts/append-retrospective-entry.sh|\
    skills/task-retrospective/scripts/append-retrospective-entry.ps1|\
    skills/context-maintenance/scripts/append-retrospective-entry.sh|\
    skills/context-maintenance/scripts/append-retrospective-entry.ps1)
      script_parity_needed=1
      ;;
  esac
done
```

### Plug-in points in the existing hook

The hook currently:
1. Reads source file, computes `agent_files`.
2. Loops `for file in "${agent_files[@]}"; do … awk … done`.
3. `exit 0`.

Insertion shape (no rewrites of existing logic):

```
existing common-constraints sync loop
  ↓
NEW: compute staged list
  ↓
NEW: if script_parity_needed=1, run diff-q checks (fail-fast)
  ↓
NEW: for each f in placeholder_check_files, run new awk pass:
       - placeholder grep (fence-aware, allow-block-aware)
       - .context ref resolver (fence-blind)
       - accumulate findings
     fail-fast or accumulate-then-report — accumulate-then-report
     gives better UX (lists all problems in one run).
  ↓
exit 0
```

Failure messaging shape:

```
[pre-commit] error: placeholder check failed:
  agents/foo.agent.md:42: unmarked placeholder '<task-id>'
  skills/bar/SKILL.md:7: unmarked placeholder '<repo-name>'
  fix: add `<!-- icon:allow-placeholders -->` to the line, or
       `<!-- icon:allow-placeholders file -->` near the top of the file.

[pre-commit] error: dead .context/ reference:
  skills/baz/SKILL.md:99: '.context/architecture/patterns.md'
    expected at: context_template/context/architecture/patterns.md
```

---

## Section 6 — Header comment for `.githooks/pre-commit`

Append (after the existing header that documents common-constraints sync):

> **Additional invariants (ICON-0032):**
>
> 1. **Placeholder + ref check** — for staged files under `agents/`, `skills/`, `shared/`, `commands/`: flags unfilled `<placeholder>` patterns outside fenced code blocks, and flags `.context/<subdir>/<file>.<ext>` references whose corresponding `context_template/context/<subdir>/<file>.<ext>` does not exist. Legitimate template placeholders are opted out with `<!-- icon:allow-placeholders -->` (per-line) or `<!-- icon:allow-placeholders file -->` (whole file). Fence detection is shared with the common-constraints awk pass (CommonMark §4.5). The ref check is fence-blind: references in backticks are checked the same as references in prose.
> 2. **Script-parity check** — when any `append-retrospective-entry.{sh,ps1}` copy is staged, requires the three copies (post-incident-review, task-retrospective, context-maintenance) to be byte-identical. Canonical source: `skills/post-incident-review/scripts/`.
>
> Note: `.githooks/` is local-only repo infrastructure and does not ship to consumers. The three-surface sweep rule (`.context/workflows/` ↔ `context_template/` ↔ `skills/<phase>/SKILL.md`) does NOT apply to this hook. See `.context/standards/skill-decomposition.md` § "Exception — repo-local conventions" (ICON-0026 precedent).

---

## Section 7 — Resolution for the three dead `.context/` refs

For each ref, the question is: **fix the reference** (re-point or remove) or **add the missing file** (template gap)?

### Ref 1 — `skills/context-specialist-impl-root/SKILL.md:257` → `.context/architecture/patterns.md`

**Surrounding text (line 257):** "Verify all root-level files are present: … 4. `.context/architecture/patterns.md` exists (or is explicitly omitted)"

**Resolution: fix the reference.** Change line 257 to `.context/architecture/patterns-template.md` (the file that actually ships in `context_template/context/architecture/patterns-template.md`).

**Rationale:** The verify-list is asking whether the file the @context-specialist created exists. The template ships `patterns-template.md` — when a consumer's @context-specialist instantiates it, they typically copy/rename to a domain-specific name OR leave it as `patterns-template.md`. The existing line 257 was written assuming a rename-to-`patterns.md` convention that the rest of the codebase does not enforce. Re-pointing to the actually-shipped filename is the smallest correct fix.

Also: check `.context/architecture/patterns-template.md` at line 257 maps to `context_template/context/architecture/patterns-template.md`, which exists. The hook will pass.

### Ref 2 — `skills/task-plan-phase-completion/SKILL.md:59` → `.context/architecture/patterns.md`

**Surrounding text (line 59):** "**Architecture files**: Did this task introduce or change a pattern? If yes, update `.context/architecture/patterns.md`."

**Resolution: fix the reference.** Change to `.context/architecture/patterns-template.md` for the same reason as Ref 1.

**Alternative considered:** Generalize the prose to "update files under `.context/architecture/`" (drop the specific filename). Rejected because the bullet's intent is to direct the reader to the canonical patterns file — vagueness here loses guidance. The fix-the-reference path is more useful.

### Ref 3 — `skills/upgrade-repo/SKILL.md:194` → `.context/workflows/prune-old-tasks.sh`

**Surrounding text (line 189–194):** "Special case — `prune-context.sh` pre-`INTEGRATION_BRANCHES` (or a still-present legacy `prune-old-tasks.sh`): if the old script uses a hardcoded `=~` regex without a named variable, extract that regex, copy the new script, and set `INTEGRATION_BRANCHES` to the extracted value. Do not reset to the generic default. If a legacy `prune-old-tasks.sh` is present, rename it with `git mv .context/workflows/prune-old-tasks.sh .context/workflows/prune-context.sh`"

**Resolution: this is a special case — the ref is INTENTIONALLY pointing to a legacy filename that does not exist in the current template.** It is describing migration logic: "if you find this legacy file, rename it." The path is correctly NOT in `context_template/`; that is the entire point.

**Fix: this ref appears inside a backtick-quoted `git mv` command line and inside narrative prose. Both occurrences in the same skill must be marked.**

Recommended approach: wrap the migration paragraph in a fenced code block where appropriate (the `git mv` line is already inside `` ` `` inline code — the resolver as designed in Section 3 is fence-blind, so this does NOT help). Therefore the marker is needed.

**Use a per-line marker** on the line containing `git mv .context/workflows/prune-old-tasks.sh ...`:

```
`git mv .context/workflows/prune-old-tasks.sh .context/workflows/prune-context.sh` <!-- icon:allow-placeholders -->
```

**BUT** — Section 1's marker is named `icon:allow-placeholders`, which semantically covers angle-bracket placeholders, not dead `.context/` refs. Section 3 says: "If a future need surfaces for legitimately-dead refs … add a separate marker `<!-- icon:allow-dead-ref -->`. Not in scope for ICON-0032."

**This is that future need, surfacing in scope.** Two options:

**Option 7A** — Add `<!-- icon:allow-dead-ref -->` as a second marker class IN this task. Cost: one extra grep clause + one extra fixture pair. Benefit: semantically clean.

**Option 7B** — Rewrite the migration paragraph so the dead path appears only in narrative form ("if a legacy `prune-old-tasks.sh` is present in `.context/workflows/`, rename it to `prune-context.sh`") without a literal `.context/workflows/prune-old-tasks.sh` path that the resolver would flag. The regex in Section 3 requires `.context/<subdir>/<file>.<ext>` — splitting the directory and filename across the sentence avoids the match.

**Recommendation: Option 7B.** Reasons:
1. Smaller change. One paragraph rewrite, no new marker class, no new fixtures.
2. Option 7A creates two marker classes that look identical (`icon:allow-*`); future readers must remember which applies to which. Avoiding the second class keeps the hook semantics tight.
3. The migration logic is fully expressible without a literal stale-path token. The reader's job is to look for `prune-old-tasks.sh` in their `.context/workflows/` directory; the prose can describe it that way.

@coder applies Option 7B: rewrite the paragraph to refer to `prune-old-tasks.sh` and its containing directory `.context/workflows/` separately, never as a joined path. The `git mv` command line stays in inline backticks but the resolver does not match `prune-old-tasks.sh` standalone (no `.context/` prefix) — verify with the regex from Section 3.

**Verify after rewrite:** run `grep -nE '\.context/[a-zA-Z0-9_/-]+\.[a-zA-Z0-9]+' skills/upgrade-repo/SKILL.md` and confirm no remaining matches resolve to a dead target.

### Summary of dead-ref resolutions

| Ref | Decision | File the @coder edits |
|-----|----------|----------------------|
| 1 | Re-point to `patterns-template.md` | skills/context-specialist-impl-root/SKILL.md:257 |
| 2 | Re-point to `patterns-template.md` | skills/task-plan-phase-completion/SKILL.md:59 |
| 3 | Rewrite to split path | skills/upgrade-repo/SKILL.md:~189-200 paragraph |

None of the three resolutions adds a file to `context_template/`. Reasoning: in all three cases the referenced filename is wrong (Refs 1, 2) or is a deliberately-legacy filename being described in migration prose (Ref 3) — none is a real template gap.

---

## Affected Areas

| Area | Impact | Notes |
|------|--------|-------|
| `.githooks/pre-commit` | High | Hook body extended; existing common-constraints sync untouched. |
| `skills/context-specialist-impl-root/SKILL.md` | Low | One-line re-point. |
| `skills/task-plan-phase-completion/SKILL.md` | Low | One-line re-point. |
| `skills/upgrade-repo/SKILL.md` | Low | One paragraph rewritten. |
| ~20 files under `agents/`, `skills/`, `shared/`, `commands/` | Medium | Each gains one or more `<!-- icon:allow-placeholders -->` markers. No prose changes. |
| `.context/tasks/ICON-0032-pre-commit-hook-extensions/fixtures/` | Medium | New fixture files per ICON-0013 naming convention. @coder authors; @tester drives. |
| `CHANGELOG.md` `[Unreleased]` | Low | One entry. |

---

## Dependencies

- **Requires:** Existing `.githooks/pre-commit` fence-detection logic (lines 107–166) as the SSOT for fence detection. No new external dependencies.
- **Provides:** Mechanical enforcement of Pattern A (cross-surface sweep depth) and Pattern B (script byte-equality across copies). Closes M-U-A, M-CC-NET3, m-U-J as collateral.
- **New dependencies:** None. Awk, grep, diff are POSIX baseline.

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Marker syntax accidentally activates inside a fenced code block | Low | Medium (false-negative — file would appear marker-protected when it isn't) | Matrix entry: marker is gated on `inside_fence==0`. Fixture: `marker-inside-fence-does-not-activate.md`. |
| Per-line marker overlooked on a new placeholder added in a future commit | Medium | Low | The hook fails loudly with the line number and the suggested marker. Author adds the marker and re-commits. |
| Cross-platform awk divergence (gawk vs mawk vs BSD awk) | Low | High | Reuse existing awk subset already shipping (ICON-0011 hook works cross-platform). No new awk features. ICON-0030 portability lesson applies. |
| `git diff --cached --diff-filter=ACMR` produces no output during `git commit --amend --no-edit` | Low | Low | The hook simply skips the checks (empty filter result is a no-op). Documented in fixture. |
| Path with a space staged | Very low | Medium | `mapfile -t` + array iteration handles spaces correctly. Avoid `for f in $(...)`. |
| `diff -q` output ordering differs across platforms | Low | Low | We use exit code, not output text, for the gate. Output is informational only. |
| @coder mass-applies markers to bypass real checks | Low | Medium | @reviewer pass examines marker placement; spurious markers are a review finding. The marker is auditable (grep `icon:allow-placeholders`). |

---

## Alternatives Considered

| Alternative | Why rejected |
|-------------|--------------|
| Single awk pass that does both common-constraints sync AND new checks | Read+write state mixed with read-only state. ICON-0013 lesson: state-machine complexity is a Critical-bug class. Separate passes. |
| Use `grep -P` (Perl-compatible regex) for placeholder match | GNU-only flag. ICON-0030 portability lesson. POSIX `grep -E` suffices. |
| Use `find` with `-execdir grep` instead of awk | Less precise — would re-implement fence-stripping in shell. The awk in this hook already solves it. |
| External tool (`pre-commit` framework, `lefthook`) | Adds installation step for every contributor. Current `.githooks/` setup needs only `git config core.hooksPath .githooks`. Don't change the substrate. |
| Allowlist file at `.githooks/placeholder-allowlist.txt` | Two surfaces (allowlist + source) drift on every rename. Marker-with-content wins. |

---

## Implementation Notes (for @coder)

1. **Write the placeholder-check awk as a separate pass.** Do not merge it into the existing common-constraints awk. Header-comment it: "Fence detection: see .githooks/pre-commit lines 107-166 for the authoritative implementation. Keep in sync."

2. **Apply the markers BEFORE enabling the hook.** Sequence:
   - Step 1: Add hook code (do not stage `.githooks/pre-commit` yet).
   - Step 2: Apply markers to the ~20 files. Stage and commit those first.
   - Step 3: Fix the three dead refs (Section 7). Stage and commit.
   - Step 4: Stage `.githooks/pre-commit`. The hook now runs against the marker-clean tree.

   This avoids a chicken-and-egg situation where the hook fails on its own commit because the source tree hasn't been prepared.

3. **Fixture-as-spec naming** (ICON-0013 convention):
   - `placeholder-outside-fence-fails.md` — placeholder, no marker, no fence → hook fails.
   - `placeholder-inside-fence-passes.md` — placeholder inside ```` ``` ```` → hook passes.
   - `placeholder-with-per-line-marker-passes.md` — placeholder + trailing `<!-- icon:allow-placeholders -->` → hook passes.
   - `placeholder-in-file-marker-passes.md` — file starts with `<!-- icon:allow-placeholders file -->` → hook passes.
   - `marker-inside-fence-does-not-activate.md` — file marker appears inside a fence → hook STILL fails on a real placeholder elsewhere in the file.
   - `dead-context-ref-fails.md` — `.context/<sub>/<missing>.md` → hook fails.
   - `dead-context-ref-in-backticks-fails.md` — same ref but inside `` ` `` → hook STILL fails (fence-blind for refs).
   - `valid-context-ref-passes.md` — `.context/architecture/patterns-template.md` (exists) → hook passes.
   - `bare-directory-ref-passes.md` — `.context/architecture/` (no filename) → hook passes.
   - `script-parity-divergence-fails.md` — synthetic divergence between two copies → hook fails.
   - `script-parity-identical-passes.md` — baseline → hook passes.

4. **Driver corruption-detection sanity check** (ICON-0013 lesson — repeat pattern): @tester should temporarily mutate the hook (e.g., disable the `inside_fence` reset) and confirm at least one fixture catches the regression.

5. **Cross-platform shell**: no `sort -V`, no `grep -P`, no `mapfile` substitute issues. `mapfile -t` is bash 4+; macOS ships bash 3.2 by default but the existing hook already uses bash 4 features (`shopt`, `mapfile`-compatible patterns). Document at the top of the hook: `#!/usr/bin/env bash` + `set -euo pipefail` already present.

6. **No `2>/dev/null`** anywhere. ICON-0030 lesson. All `diff -q` and `awk` stderr must reach the developer's terminal.

7. **CHANGELOG entry**: add to `[Unreleased]` after @reviewer pass, per `changelog-entry` skill — a single line describing the new hook invariants.

---

## Open Questions

None for the @coder. All seven sections specify concrete decisions. The marker convention is named, the matrix is enumerated, the dead-ref resolutions are decided, and the script-parity scope is chosen.

If during implementation @coder discovers a NEW class of legitimate placeholder that doesn't fit either form, escalate to @architect before adding a third marker class — do not invent new markers in flight.

---

## Files referenced

- `.githooks/pre-commit` — existing hook, fence detection SSOT at lines 107–166.
- `skills/context-specialist-impl-root/SKILL.md:257`, `skills/task-plan-phase-completion/SKILL.md:59`, `skills/upgrade-repo/SKILL.md:~189-200` — dead-ref fix-ups.
- `skills/plugin-audit/synthesis-template.md` — per-file marker target (wall-to-wall placeholders).
- `skills/{post-incident-review,task-retrospective,context-maintenance}/scripts/append-retrospective-entry.{sh,ps1}` — six gated copies; post-incident-review is canonical.
- `context_template/context/architecture/patterns-template.md` — re-point target for Refs 1 & 2.
- `.context/standards/skill-decomposition.md` § "Exception — repo-local conventions" — ICON-0026 precedent for the three-surface bypass.

---

## Addendum: 2026-05-21 Scale-back

**Status:** the original design above is preserved for historical record. The implementation has since been scaled back during MR !16 review. The sections that follow describe what was actually shipped after the user redirect.

### What was kept

- **Section 3 — `.context/<subdir>/<file>.<ext>` reference resolver** (dead-ref check). Fence-blind. Regex unchanged. All 13 dead-ref fixes from the original implementation remain in the diff because they are real bugs benefiting consumers regardless of which checks ship.
- **Section 4 — Script-parity byte-equality** across the three `append-retrospective-entry.{sh,ps1}` copies. Canonical = post-incident-review. Accumulate-then-report.
- **Section 5 — Scope-by-path-prefix branching**. `agents/`, `skills/`, `shared/`, `commands/` for `.md|.sh|.ps1|.js` files. Used for the dead-ref check.
- **Section 6 — Header comment** in `.githooks/pre-commit`. Updated to describe only the two surviving check classes.
- **Section 7 — Dead-ref resolutions**. All three architect-known refs + the 10 additional refs caught during implementation. Option 7B (split-path rewrite) applied uniformly.

### What was dropped

- **Section 1 — Exception-marker convention** (all three forms: HTML/shell/JS). Removed.
- **Section 2 — Fence-stripping reuse + N-flag transition matrix** for the placeholder-check awk. Removed; the dead-ref resolver is fence-blind and doesn't need fence detection.
- **Placeholder grep portion of Section 3**. Removed.
- All 25 marker annotations across the tree (15 per-file + 10 per-line).
- 5 placeholder-related fixtures (`placeholder-outside-fence-fails.md`, `placeholder-inside-fence-passes.md`, `placeholder-with-per-line-marker-passes.md`, `placeholder-in-file-marker-passes.md`, `marker-inside-fence-does-not-activate.md`).

### Why

User redirect during MR !16 review: the placeholder check has a cost/benefit problem. Most matches of `<lowercase-token>` syntax in the repo are legitimate notation — dispatch template substitution slots, XML element references in prose, naming-convention examples, CLI usage docs — not unfilled-fill-in-slot bugs. The repo has no programmatic tag-replacement mechanism (other than the common-constraints inject, which has its own byte-equality check). The bug class the placeholder check was foreclosing (M-U-A — unfilled placeholders surviving copy-paste) was caught once in 8 audit cycles by human review. The ongoing cost (25 marker annotations + every new author learning the convention + every new placeholder-style notation needing a marker added defensively) was disproportionate to the catch frequency.

The dead-ref resolver and script-parity gate were retained because their cost/benefit is clearly positive: the dead-ref resolver catches real broken references that installed plugin instances would surface to readers; the script-parity gate prevents real divergence between three byte-identical copies. Both are mechanically enforceable without ongoing annotation burden.

An "inverse-signal" alternative (require authors to mark TODO-style intentional fill-ins affirmatively, e.g., `<TODO: file>` or `[FILL]`) was considered and rejected as a connectors-style abstraction without demonstrated need in this plugin.

### Acceptance criteria for the scale-back

- `.githooks/pre-commit` no longer contains the placeholder-check awk pass or any `icon:allow-placeholders` recognition logic.
- 25 marker annotations removed from the tree (15 per-file + 10 per-line).
- 5 placeholder-related fixtures deleted; 6 remaining fixtures (4 dead-ref + 2 script-parity) still match their named outcomes.
- Hook still exits 0 against the staged tree.
- Header comment, fix-message, and `fixtures/README.md` updated to reflect only the surviving check classes.
