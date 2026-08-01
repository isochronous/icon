# ICON-0099 Wave 2 — cross-skill fenced-block copy-sets

**Status**: investigation output. No file was modified to produce it.
**Scope**: every fenced block appearing in ≥2 skills under `skills/` and `.claude/skills/`.
**Method**: mechanical sweep, not prose. Every number below was measured.

## Method and completeness

A Node sweep parsed **87 `.md` files** under `skills/` and `.claude/skills/` (CommonMark §4.5 fence
tracking: 3+ backticks/tildes, up to 3 leading spaces, closer must match char and run-length and
carry no info string) and extracted **341 fenced blocks**. Byte figures below are **fence-body
bytes**, excluding the two delimiter lines.

Three independent passes ran over that corpus, so a missed copy-set would have to evade all three:

1. **Exact match** on the normalized body (CRLF stripped, trailing whitespace stripped, trimmed) —
   **5 groups** spanning ≥2 distinct skills.
2. **Near-duplicate clustering** — Jaccard token similarity ≥0.38 on bodies ≥40 B, single-linkage
   union-find — **16 clusters** spanning ≥2 distinct skills.
3. **Shared-line-run detection** — every 4-consecutive-non-blank-line window ≥100 chars, indexed
   across all blocks. This catches partial overlaps that similarity scoring misses.
   Pass 3 surfaced **12 distinct site-sets, all of them already members of pass-2 clusters.** No
   copy-set exists that only pass 3 could see.

`.claude/skills/icon-audit/SKILL.md` and `.claude/skills/release-plugin/SKILL.md` were both scanned.
Neither participates in any cross-skill duplicate.

---

## 1. Copy-set inventory

Eight distinct cross-skill sets exist. Three are ADR-017 **deterministic**; five are not, for
reasons stated per set.

### Set A — `.gitattributes` retrospective union-merge

| Member | Tag | Body bytes | In scope? |
|---|---|---|---|
| `skills/context-specialist-impl-leaf/SKILL.md:229-246` | `bash` | 785 | yes |
| `skills/context-specialist-impl-root/SKILL.md:253-270` | `bash` | 785 | yes |
| `skills/upgrade-repo/SKILL.md:1250-1283` | `bash` | 1,523 | **no — issue #61** |

**What it does**: idempotently appends `merge=union` attributes for `retrospectives.md` and
`retrospectives-archive.md` to the repo-root `.gitattributes`.

**Drift — ADR-017's claim is directionally right and factually wrong.** The ADR states *"two copies
already drifted."* Measured: **impl-leaf and impl-root are byte-identical (785 B each, SHA prefix
`ad9fd238c8f30198`)**. Exactly **one** copy — `upgrade-repo` — has diverged, and it diverged
*upward*: it is a hardened rewrite, not a decayed one. Actual diff (`impl-leaf` → `upgrade-repo`):

```diff
 # Ensure repo-root .gitattributes gives retrospective logs a union merge driver,
 # so concurrent retrospective appends across branches merge cleanly instead of
 # conflicting. Idempotent — safe to re-run.
-ROOT=$(git rev-parse --show-toplevel)
+#
+# Both the path lookup and the append are checked. An unchecked `git rev-parse`
+# yields an empty ROOT and turns the target into the filesystem-root
+# `/.gitattributes`, and an unconditional success echo after the append reports
+# "Ensured ..." even when the redirection never wrote a byte.
+ROOT=$(git rev-parse --show-toplevel) || {
+  echo "ERROR: git rev-parse --show-toplevel failed — not inside a git work tree." >&2
+  echo "       Refusing to guess a repository root." >&2
+  exit 1
+}
+if [ -z "$ROOT" ]; then
+  echo "ERROR: git rev-parse --show-toplevel returned an empty path; refusing to" >&2
+  echo "       write .gitattributes at the filesystem root." >&2
+  exit 1
+fi
 GA="$ROOT/.gitattributes"
 if [ -f "$GA" ] && grep -qF 'retrospectives.md' "$GA"; then
   echo ".gitattributes: retrospective union-merge entries already present — skipped"
-else
-  {
+elif {
     printf '\n# ICON retrospective logs are append-mostly; the union merge driver keeps\n'
     printf '# both sides'"'"' entries instead of conflicting on concurrent appends.\n'
     printf 'retrospectives.md          merge=union\n'
     printf 'retrospectives-archive.md  merge=union\n'
-  } >> "$GA"
+  } >> "$GA"; then
   echo "Ensured retrospective union-merge entries in $GA"
+else
+  echo "ERROR: failed to append retrospective union-merge entries to $GA" >&2
+  exit 1
 fi
```

**The drift is a live defect, and it is in the in-scope copies.** `impl-leaf` and `impl-root` run an
unchecked `git rev-parse --show-toplevel`. Outside a work tree that yields an empty `ROOT`, making
`GA` the literal `/.gitattributes` — the filesystem root — and the append proceeds. They also print
`Ensured …` unconditionally, so a failed redirection reports success. `upgrade-repo` fixed both.
ADR-017's underlying argument holds exactly: nothing detected this, and the fix reached one of three
copies.

**Tier**: Deterministic + **trigger 2** (mutates state — writes a file in the consumer's repo).
Not trivial: control flow branches on `grep -qF`'s result, and a Node version would use
`readFileSync`/`appendFileSync`, not `child_process`.
**Disposition**: **migrate to a per-skill `.mjs`** — 3 copies (`impl-leaf`, `impl-root`,
`upgrade-repo`), byte-identical, registered with the parity check in the same commit. **Deferred:
see §5.** One member is out of this task's scope.

### Set B — integration-branch detection and feature-branch creation

| Member | Tag | Body bytes | In scope? |
|---|---|---|---|
| `skills/initialize-monorepo/SKILL.md:27-52` | `bash` | 855 | yes |
| `skills/initialize-multimodule/SKILL.md:167-169` | `bash` | 52 | yes |
| `skills/initialize-multimodule/SKILL.md:176-186` | `bash` | 474 | yes |
| `skills/initialize-multimodule/SKILL.md:190-198` | `bash` | 321 | yes |
| `skills/initialize-workspace/SKILL.md:93-95` | `bash` | 59 | yes |
| `skills/initialize-workspace/SKILL.md:101-111` | `bash` | 474 | yes |
| `skills/initialize-workspace/SKILL.md:115-123` | `bash` | 321 | yes |

**Total 2,556 B. All seven members are in scope — this is the only fully-in-scope deterministic
set.**

**What it does**: resolves a git root, probes `origin/develop|main|master` for the integration
branch (falling back to parsing `git remote show origin`), then creates or checks out
`chore/initialize-agent-context` from it.

**Drift**: two shapes, three skills.
- `multimodule` and `workspace` carry the **`git -C "$GIT_ROOT"` per-root** shape. Their 474 B
  detection fragments are **byte-identical** (`8c1762e6dbcd479d`); their 321 B checkout fragments are
  **byte-identical** (`e6a42277d0e79ba0`). Only the tiny `GIT_ROOT=` preamble differs (52 B vs 59 B —
  `"$proj"` vs `"$FOLDER_PATH"`).
- `monorepo` carries a **single-root `cd`-based** shape as one 855 B block. Same algorithm, different
  plumbing, plus two `echo` progress lines the others lack:

```diff
-REPO_ROOT="$(git rev-parse --show-toplevel)"
-cd "$REPO_ROOT"
-
-# Detect integration branch
-INTEGRATION_BRANCH=""
-for candidate in develop main master; do
-  if git show-ref --verify --quiet "refs/remotes/origin/$candidate"; then
-    INTEGRATION_BRANCH="$candidate"
-    break
-  fi
-done
-[ -z "$INTEGRATION_BRANCH" ] && INTEGRATION_BRANCH="$(git remote show origin | grep 'HEAD branch' | awk '{print $NF}')"
-[ -z "$INTEGRATION_BRANCH" ] && { echo "ERROR: Cannot detect integration branch"; exit 1; }
-
-FEATURE_BRANCH="chore/initialize-agent-context"
-
-if git show-ref --verify --quiet "refs/heads/$FEATURE_BRANCH"; then
-  git checkout "$FEATURE_BRANCH"
-  echo "Resumed existing branch: $FEATURE_BRANCH"
-else
-  git fetch origin
-  git checkout -b "$FEATURE_BRANCH" "origin/$INTEGRATION_BRANCH"
-  echo "Created branch: $FEATURE_BRANCH (from $INTEGRATION_BRANCH)"
-fi
+   INTEGRATION_BRANCH=""
+   for candidate in develop main master; do
+     if git -C "$GIT_ROOT" show-ref --verify --quiet "refs/remotes/origin/$candidate"; then
+       INTEGRATION_BRANCH="$candidate"; break
+     fi
+   done
+   [ -z "$INTEGRATION_BRANCH" ] && \
+     INTEGRATION_BRANCH=$(git -C "$GIT_ROOT" remote show origin | grep 'HEAD branch' | awk '{print $NF}')
+   [ -z "$INTEGRATION_BRANCH" ] && { echo "ERROR: Cannot detect integration branch for $GIT_ROOT"; exit 1; }
```

**Tier**: Deterministic + **trigger 1** and **trigger 2**.
- Trigger 1 fires literally: in `multimodule`/`workspace`, `INTEGRATION_BRANCH` is set in the fence at
  `:176`/`:101` and read in the fence at `:190`/`:115`. Both files also instruct the agent to record
  it for a later step. That is the exact latent-correctness-bug shape trigger 1 names.
- Trigger 2 fires: `git checkout -b` and `git fetch` mutate the consumer's repo.

**On the trivial test — this set passes the converse clause, but not comfortably.** A Node rewrite
would call `git show-ref`, `git remote show`, `git fetch` and `git checkout` through
`child_process`, which reads like "shell out to do the same work." What excludes it from trivial is
the ADR's explicit converse: *"control flow over a tool's output is deterministic, not trivial."*
There are three such branches here — on `show-ref`'s exit status, on `remote show origin`'s stdout,
and on the resulting emptiness. **This is the weakest tier call in the report and I am flagging it
rather than burying it** (see §5).

**Disposition**: **migrate to a per-skill `.mjs` — 3 copies**, one each in
`initialize-monorepo/scripts/`, `initialize-multimodule/scripts/`, `initialize-workspace/scripts/`,
byte-identical, taking the git root on `argv` (which subsumes both the `cd` and the `git -C` shapes)
and printing the resolved integration branch as its single stdout token. **Conditional: see §5.**

### Set C — root-level `claude.md` redirect

| Member | Tag | Body bytes | In scope? |
|---|---|---|---|
| `skills/context-specialist-impl-leaf/SKILL.md:46-57` | `bash` | 276 | yes |
| `skills/upgrade-repo/SKILL.md:103-116` | `bash` | 321 | **no — issue #61** |

**What it does**: writes a root `claude.md` stub redirecting Copilot CLI to `.claude/claude.md`,
skipping if one already exists.

**Drift**: the two have diverged — `upgrade-repo` wraps the whole thing in an outer
`.claude/claude.md` existence guard the `impl-leaf` copy lacks:

```diff
-if [ ! -f "claude.md" ]; then
-  cat > claude.md << 'EOF'
+if [ -f ".claude/claude.md" ]; then
+  if [ ! -f "claude.md" ]; then
+    cat > claude.md << 'EOF'
 # Project Instructions
 …
 EOF
+  fi
 fi
```

**Tier**: Deterministic + **trigger 2** (writes a file). Not trivial — a Node version uses
`existsSync`/`writeFileSync`.
**Disposition**: migrate to a per-skill `.mjs`, 2 copies. **Deferred — one member is in
`upgrade-repo` (#61).** See §5.

### Set D — push the feature branch (trivial, stays)

| Member | Tag | Body bytes |
|---|---|---|
| `skills/initialize-multimodule/SKILL.md:392-396` | `bash` | 128 |
| `skills/initialize-workspace/SKILL.md:322-326` | `bash` | 128 |

Byte-identical (`74e01e0f1beb69ad`). A `for` loop over `UNIQUE_GIT_ROOTS` running
`git push --set-upstream` with fixed arguments.

**Tier: Trivial.** No control flow over any tool's output — the loop iterates a list, it does not
branch on a result. A Node version would be a `child_process` wrapper around `git push` and nothing
else. **Disposition: leave in place.** ADR-017: *"if the Node version would have to shell out to do
the same work, the block is already in the right language."* Duplication does not change this;
migrating 256 B into two files plus two invocation preambles plus two degradation paths is the exact
trade the ADR's trivial-test grounding rejects.

`skills/initialize-monorepo/SKILL.md:294-296` (48 B) and `skills/start-worktree/SKILL.md:116-118`
(53 B) are single-line `git push` commands with different arguments. They are not a copy-set and are
individually trivial.

### Set E — Copilot CLI path reconstruction (this *is* the ADR-017 contract)

| Member | Tag | Body bytes |
|---|---|---|
| `skills/context-maintenance/SKILL.md:225-230` | `bash` | 350 |
| `skills/context-maintenance/SKILL.md:257-262` | `bash` | 373 |
| `skills/find-context-template/SKILL.md:32-36` | `bash` | 271 |
| `skills/icon-init/SKILL.md:102-107` | `bash` | 305 |

All four are the three-to-four-line `MARKETPLACE_NAME` / `SKILL_DIR` preamble ADR-017 § *The
invocation contract* **prescribes verbatim**. `icon-init`'s copy is the ICON-0098 output.

**Tier: not a candidate at all.** ADR-017 exclusion **E2** names `context-maintenance`'s invocation
wrappers explicitly as *"instances of this contract rather than candidates for it"*, and
`find-context-template` as the bootstrap case. The ADR also states outright that *"the residual bash
preamble on every Copilot invocation stays fenced and stays unlinted."* **Disposition: leave in
place.** These will *increase* in number as migration proceeds — every new `.mjs` adds one.

### Set F — `node -v` (trivial; wave-1 intersection)

| Member | Tag | Body bytes |
|---|---|---|
| `skills/check-node-runtime/SKILL.md:32-34` | untagged | 7 |
| `skills/icon-status/SKILL.md:136-138` | untagged | 7 | **wave 1** |

Byte-identical. **Already in ADR-017's prescribed end state**: untagged because it is
shell-agnostic, with surrounding prose in both files doing the disambiguation the ADR requires
(`check-node-runtime`: *"It is byte-identical in bash, sh, zsh, PowerShell, and cmd"*; `icon-status`:
*"The command is identical in every shell — run it as-is"*). Migrating it is also structurally
impossible — a `.mjs` cannot report Node's absence.
**Disposition: leave in place. No action in either wave.** See §4.

### Set G — `$TEMPLATE_DIR` validation guards (bootstrap; stays)

| Member | Tag | Body bytes |
|---|---|---|
| `skills/create-iconrc/SKILL.md:61-67` | `bash` | 248 |
| `skills/create-iconrc/SKILL.md:69-75` | `powershell` | 468 |
| `skills/find-context-template/SKILL.md:78-86`, `:90-97`, `:101-108` | `powershell`/`bash` | 696 / 258 / 566 |

**Tier: excluded on two independent grounds.** `find-context-template` is named in ADR-017 exclusion
**E2** as the irreducibly circular bootstrap case. Both skills' guards additionally read
`$TEMPLATE_DIR` **from the calling shell session** — a variable they do not set and that no `.mjs`
can observe across a process boundary. That is exclusion **E1**'s *"non-program fragments that
reference variables they do not set."* **Disposition: leave in place.**

### Set H — non-executable duplicated fences (out of ADR-017's domain entirely)

| Cluster | Members | Bytes |
|---|---|---|
| `context-specialist` leaf-init sub-session prompts | `initialize-monorepo:169`, `initialize-multimodule:234`, `initialize-workspace:204` | 3,181 |
| `context-specialist` leaf-upgrade sub-session prompts | `initialize-monorepo:201`, `initialize-multimodule:266`, `initialize-workspace:236` | 2,607 |
| `context-specialist` root sub-session prompts | `initialize-monorepo:262`, `initialize-multimodule:327`, `initialize-workspace:293` | 2,421 |
| `context-specialist-impl-branch:19`, `context-specialist-impl-root:24` | 2 | 1,649 |
| PR-body templates (`markdown`) | `initialize-multimodule:405`, `initialize-workspace:332` | 1,413 |
| Retrospective-entry templates (`markdown`) | `context-maintenance/append-retrospective-entry.md:74`, `task-retrospective/SKILL.md:78` | 477 |
| Plan `## Progress` templates (`markdown`) | `task-plan:106`, `task-plan-phase-investigation:102` | 272 |
| **Total** | | **12,020** |

All are **untagged or `markdown` fences carrying prompt text and document templates, not
commands**. All three of the large untagged clusters have drifted — every member of each is a
distinct body — but they have drifted *deliberately*: the deltas are `<REPO_ROOT>`→`<GIT_ROOT>`,
`<AREA_PATH>`→`<PROJECT_PATH>`, "functional area"→"sub-project"→"project", monorepo-specific
sibling-directory guidance. This is per-skill specialization, not decay.

**Tier: none. ADR-017 governs executable content; these are not executable.**
**Disposition: leave in place. Not a wave-2 concern, and not a byte-parity candidate** — a parity
check over them would fail immediately and correctly.

**This set is almost certainly the origin of the ticket's `~11,000 B` figure.** See §2.

---

## 2. Total measured bytes vs the ticket's `~11,000 B`

**The `~11,000 B` claim does not survive measurement. It is off by roughly 2.5×.**

| Category | Bytes |
|---|---|
| **Deterministic, migratable, in this task's scope** (A in-scope + B + C in-scope) | **4,402** |
| Deterministic, migratable, out of scope (`upgrade-repo`, #61) | 1,844 |
| **Deterministic total across the whole copy-set population** | **6,246** |
| Trivial duplicates that stay (D, F, plus the two unrelated `git push` one-liners) | 371 |
| Invocation-contract preambles, E2 (E) | 1,299 |
| Bootstrap guards, E1+E2 (G) | 2,236 |
| Non-executable prompt/template fences (H) | 12,020 |
| **Grand total, all cross-skill duplicated fence bytes** | **22,172** |

**Where `~11,000` likely came from**: the untagged sub-session-prompt clusters plus the `markdown`
PR-body templates in Set H sum to **11,271 B** — within 3% of the ticket's figure. Those blocks
contain no commands. If the ticket's number was produced by "duplicated fences, ≥2 skills, sizeable",
it counted prompt text as executable content.

**Corrected figure to carry forward: 4,402 B in scope, 6,246 B including the `upgrade-repo`
members.** Per ADR-017 this number is a scoping input only — it must not appear in any acceptance
criterion as a reduction target, because migration *grows* `SKILL.md`.

---

## 3. Byte-parity check impact

The check is at `.githooks/pre-commit`. It is called the **script-parity check** in the file, is
declared in two places, and its scope is stated in the header comment at lines 28-31:

> ```
> #   2. Script-parity check — when any append-retrospective-entry.{sh,ps1}
> #      copy is staged, requires the three copies (post-incident-review,
> #      task-retrospective, context-maintenance) to be byte-identical.
> #      Canonical source: skills/post-incident-review/scripts/.
> ```

**Population today: exactly one tracked group, six files.** Arming, `.githooks/pre-commit:512-522`:

```bash
  # Script-parity check fires if ANY of the six tracked copies is staged.
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
```

Enforcement, `.githooks/pre-commit:608-638`:

```bash
if (( script_parity_needed == 1 )); then
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

  parity_fail=0
  for copy in "${script_copies_sh[@]}"; do
    if ! diff -q "$canonical_sh" "$copy" >&2; then
      echo "[pre-commit] error: $copy diverges from $canonical_sh" >&2
      echo "  fix: re-sync the copies (all three must be byte-identical)" >&2
      parity_fail=1
    fi
  done
  for copy in "${script_copies_ps1[@]}"; do
    if ! diff -q "$canonical_ps1" "$copy" >&2; then
      echo "[pre-commit] error: $copy diverges from $canonical_ps1" >&2
      echo "  fix: re-sync the copies (all three must be byte-identical)" >&2
      parity_fail=1
    fi
  done
  if (( parity_fail == 1 )); then
    exit 1
  fi
fi
```

### What a wave-2 migration removes: nothing

**No wave-2 migration removes a single entry.** The six tracked files are `.sh`/`.ps1` script files
under three `scripts/` directories — issue **#60**'s scope, not wave 2's. Wave 2 touches only fenced
blocks inside `.md` files, none of which are tracked by this check today.

### What it adds

| Set | Files added | Condition |
|---|---|---|
| A (`.gitattributes`) | 3 | requires #61 |
| B (branch guard) | 3 | in scope |
| C (`claude.md` redirect) | 2 | requires #61 |

Best case for this task alone (Set B only): **6 → 9 files, 1 → 2 tracked groups.** Full wave 2
including the `upgrade-repo` members: **6 → 14 files, 1 → 4 groups.**

**ADR-017's "refills rather than empties" warning is confirmed, and understated.** The ADR frames it
as 6 → 3 → 6. Measured, the trajectory is **6 → (3 after #60) → 11 after wave 2** and it only grows
from there. Issue **#23**'s "retire the byte-parity check once its population is empty" is not merely
unachievable by migration — **migration is the mechanism that permanently prevents it.** Close #23
won't-do, as ADR-017 already recommends.

### The exact registration shape — and why it is not a copy-paste

**The check is hard-coded to exactly one group.** `script_parity_needed` is a single scalar flag;
`canonical_sh` / `canonical_ps1` / `script_copies_sh` / `script_copies_ps1` are single-group
variables. There is no group table and no iteration over groups. Registering a second copy-set is a
**refactor of the block, not an added row.**

The minimum-diff shape a second group requires:

1. **A second arming flag** beside `script_parity_needed=0` (line 481), e.g.
   `mjs_parity_needed=0`, with its own `case "$f" in … esac` in the `for f in "${staged[@]}"` loop.
2. **A second enforcement block** duplicating the `if (( … == 1 )); then … fi` structure with its own
   canonical and copies arrays.
3. Or — preferably, once there are 2+ groups — **generalize once**: a
   `parity_groups=("canonical_path:copy1:copy2" …)` table with one loop, replacing the hard-coded
   variables. Doing this at group 2 costs less than doing it at group 4.

Two narrations must be updated in the same commit or they go stale:
- line 512, `# Script-parity check fires if ANY of the six tracked copies is staged.` — the count is
  written into the comment.
- lines 28-31, the header's `three copies (post-incident-review, task-retrospective,
  context-maintenance)` enumeration.

Both are exactly the *satellite enumeration* failure class `.context/retrospectives-archive.md:143`
records. Neither is caught by any gate. Note that `.githooks/pre-commit` is itself in the shellcheck
gate's scope (line 584: `*.sh|.githooks/pre-commit|.githooks/post-commit`), so the refactor is
linted.

**Two migration-adjacent gates already cover `.mjs` and need no change** — ADR-017's first
application extended the dead-ref resolver (line 508: `agents/*.mjs|skills/*.mjs|…`) and the
cap-literal check (line 543) to `.mjs`. A new `skills/<name>/scripts/*.mjs` lands inside both
automatically.

---

## 4. Wave-1 intersections

**One, and it is inert.**

`skills/icon-status/SKILL.md:136-138` — the 7-byte untagged `node -v` fence — pairs with
`skills/check-node-runtime/SKILL.md:32-34`. Set F above.

**Why the manager can treat this as a non-constraint**: the block is trivial, is already in ADR-017's
prescribed end state (untagged, shell-agnostic, prose-disambiguated on both sides), and is
structurally unmigratable — a `.mjs` cannot detect its own runtime's absence, which
`check-node-runtime` records and ADR-017 § *The invocation contract* restates. **Wave 2 recommends no
change to it, so wave 1 is free to treat it as untouched.** The only sequencing risk would be wave 1
retagging or rewording it in a way that breaks byte-identity with `check-node-runtime` — worth a
one-line note to the wave-1 agent, nothing more.

`skills/plugin-design/*` (28 blocks across 10 files) and `.claude/skills/icon-audit/SKILL.md`
(scanned) participate in **zero** cross-skill copy-sets. No intersection.

---

## 5. Whole-set-or-nothing verdict

**Recommendation: narrow this task to Set B only, or defer wave 2 in full and re-cut it after #61.
Do not attempt Sets A or C in ICON-0099.**

### Sets A and C are blocked, hard

Both have a member in `skills/upgrade-repo/SKILL.md`, which issue **#61** owns and this dispatch
places out of scope. ADR-017 is unambiguous: *"the set migrates as a whole or not at all — a
half-migrated set is strictly worse than either end state."* Migrating two of Set A's three copies
would leave a two-member parity group that silently permits the third to keep drifting — the precise
failure the set already exhibits, re-encoded with a gate that looks like it covers the problem and
does not. **Refuse.**

**Set A is the strongest migration candidate in the entire wave**, and this is the one place the
ticket's "do not split this across tasks" instruction and its scope boundary contradict each other.
It has confirmed drift, and the drift is a real defect sitting in the two in-scope copies (a
filesystem-root write and a lying success message). The manager has two clean options and one dirty
one:

- **(a) Pull `upgrade-repo`'s two blocks — only those two — into ICON-0099**, migrating Sets A and C
  whole. This is the option ADR-017's rule actually argues for. It requires the manager to widen the
  scope boundary, which is the manager's call and not mine.
- **(b) Move Sets A and C to #61** and let that task own them end-to-end.
- (c) Half-migrate. Forbidden.

**Independently of the migration decision**: the `impl-leaf` / `impl-root` filesystem-root-write bug
is live today and does not need ADR-017 to fix. Back-porting `upgrade-repo`'s guards into the two
in-scope copies would make all three byte-identical and remove the defect, with no migration and no
parity registration. That is a smaller, safer change than either option above and could ship now. It
is out of *this dispatch's* read-only scope to do, but the manager should know it exists.

### Set B is migratable in this task — with two preconditions

All seven members are in scope, both triggers fire cleanly, and the two skills that share fragments
share them byte-for-byte already. But:

**Precondition 1 — none of the three skills has a Node-absence degradation path.** Verified by
grep: `initialize-monorepo`, `initialize-multimodule` and `initialize-workspace` contain no `node -v`
probe, no `check-node-runtime` reference, and no degradation prose. `initialize-workspace:47` already
runs an inline `node -e`, so it depends on Node without guarding it — an existing gap, not one
migration creates. ADR-017: *"if a skill has no such state, it is not ready to migrate."*

There **is** an adjacent state to attach to: all three already halt with
`ERROR: Cannot detect integration branch; exit 1` when detection fails, and that halt is a hard stop
for everything downstream. Reusing it as the Node-absent path is coherent — but it is **authoring
work, not a pre-existing state**, so the strict reading of the ADR is that the precondition is not
met yet. I am flagging rather than deciding.

**Precondition 2 — the trivial call is close.** Set B is the only candidate where a Node rewrite is
substantially `child_process` wrapping git. It clears the trivial bar on the ADR's converse clause
(three branches on tool output) and on trigger 1 (a genuine cross-fence variable), but the value
delivered is thinner than Set A's: the copies are already byte-identical where they overlap, so
there is no drift to detect — the parity check would be added to *prevent* a divergence that has not
happened, at a cost of three `.mjs` copies, three invocation preambles, three degradation paths, and
a pre-commit refactor.

**My recommendation, plainly**: if the manager takes option (b) above and leaves Sets A and C to #61,
then Set B alone is **not worth the pre-commit refactor in this task**. Set B's honest justification
is trigger 1 (the cross-fence `INTEGRATION_BRANCH`), which is a correctness argument about *one*
skill pair, not a duplication argument — and the ADR's duplication machinery is heavy for it.
**Prefer sequencing Set B behind #61** so the parity-check generalization is done once, for 3-4
groups at once, rather than twice.

If the manager takes option (a) — pulling `upgrade-repo`'s two blocks in — then **do all three sets
in one pass.** The parity refactor is amortized, Set A's defect gets fixed, and the whole-set rule is
honoured everywhere.

**Either way, recommending less than the ticket asks is the evidence-supported answer.** The ticket's
premise — a large, coherent, migrate-in-one-pass copy-set of ~11,000 B — is not what is in the tree.
What is in the tree is 4.4 kB of in-scope deterministic content, split across three sets, two of
which are structurally blocked by a scope boundary the ticket itself drew.

---

## 6. Per-set degradation paths and prose-contract notes

Applies only to sets whose disposition is *migrate*. Match `skills/icon-init/SKILL.md:82-92`, which
is the ADR-017 proving case and the shape to copy.

### Set A — `impl-leaf`, `impl-root`, `upgrade-repo`

- **Degradation path: does not exist. Must be authored before migration.** No probe or fallback
  prose in either `context-specialist-impl-*` file. The natural state to attach to is each skill's
  existing post-condition checklist item — `impl-leaf:309` / `impl-root:303`, *"Root-level
  `.gitattributes` exists and contains `merge=union`…"* — inverted into: Node absent → skip the step,
  record the checklist item as unmet, and tell the user to add the two attribute lines by hand. The
  consequence is bounded and non-destructive (concurrent retrospective appends conflict instead of
  union-merging), which makes it a legitimate degraded state rather than a silent failure.
- **Prose that must survive in `SKILL.md`**: that the operation is idempotent and re-runnable; the
  skip-if-already-present semantics; *why* union-merge is wanted (append-mostly logs, concurrent
  branch appends); and the outcome table — `ensured` / `already present, skipped` /
  `not a git work tree` / `append failed`, with what the caller does for each. If either file's
  section collapses to "run the script", ADR-017 § *Migration is not cap-evasion* obligation 1 is
  breached and the migration must be reverted.
- **Copy count does not drop: 3 copies of the `.mjs` ship**, one per skill directory, byte-identical.
  `skill-decomposition/infrastructure-and-distribution.md § Skills Cannot Share Scripts` — an
  installed skill cannot reference a file outside its own directory. Migration makes the drift
  *detectable*; it does not remove it.

### Set B — `initialize-monorepo`, `initialize-multimodule`, `initialize-workspace`

- **Degradation path: does not exist. Must be authored.** See precondition 1 in §5. Reuse the
  existing `Cannot detect integration branch` halt: Node absent → the skill cannot establish its
  feature branch → halt with a diagnostic naming Node as the cause and pointing at
  `check-node-runtime`. Do **not** offer "run the bash fence instead" as the fallback — keeping the
  fence for the fallback means the block was never migrated.
- **Prose that must survive**: the `develop → main → master` probe order and why it is that order;
  the `git remote show origin` fallback; that failure to determine the branch is a hard stop, never a
  guess; the resume-vs-create semantics of `chore/initialize-agent-context`; and that
  `INTEGRATION_BRANCH` is consumed by later steps and by every sub-session prompt. **This last point
  is the whole reason trigger 1 fires — it must be stated in prose, as the script's stdout contract,
  not left implicit.**
- **Outcome contract**: stdout carries the resolved integration-branch name and nothing else; stderr
  carries probe diagnostics; exit 0 on success, non-zero on undetectable. Never merge the channels.
  Where exit code and stdout disagree, the caller treats the run as failed (ADR-017 § *The invocation
  contract*).
- **3 copies of the `.mjs` ship.** One script shape serves all three skills: take the git root on
  `argv[2]`, defaulting to `git rev-parse --show-toplevel` when absent — that subsumes `monorepo`'s
  `cd` shape and the other two's `git -C "$GIT_ROOT"` shape without a per-skill variant. A per-skill
  variant would defeat byte-parity registration entirely.

### Set C — `impl-leaf`, `upgrade-repo`

- **Degradation path: does not exist.** Both sites already have a documented skip semantic
  (`impl-leaf:59` *"Skip silently if `claude.md` already exists"*; `upgrade-repo`'s Case 3 note), and
  the `upgrade-repo` site is already gated behind an explicit user confirmation prompt. Node absent →
  report the redirect as not created and give the user the file's contents to paste. Bounded
  consequence: Copilot CLI users do not receive project instructions until they create it.
- **Prose that must survive**: that the file is a *redirect*, not content; that Copilot CLI reads
  root `claude.md` but not `.claude/claude.md`; the skip-if-exists rule; and — for `upgrade-repo` —
  the Case 3 precondition that `.claude/claude.md` must exist first, which is the entire content of
  the drift between the two copies and must not be lost when they are unified.
- **2 copies ship.**

### Sets D, E, F, G, H — no migration, no obligations

No degradation path is owed for a block that stays where it is.

---

## Open questions and assumptions

- **Assumption**: "byte-parity check" in the ticket and in ADR-017 refers to the
  `.githooks/pre-commit` **script-parity check** (its name in the file). There is no other parity
  check in the repo. Manager: correct if wrong.
- **Assumption**: `skills/upgrade-repo/SKILL.md` is out of scope for its *fenced blocks* as well as
  its script files, per the dispatch's "`skills/upgrade-repo/` — separately ticketed as #61". If #61
  is scoped to something narrower and upgrade-repo's fences are actually available to this task,
  Sets A and C unblock and option (a) in §5 becomes the recommendation without qualification.
- **Open question (blocking, for the manager not for me)**: Sets A and C cannot be completed under
  the scope boundary as drawn. §5 states the three options. This needs a decision before any
  implementation phase starts.
- **Open question (non-blocking)**: whether authoring a Node-absence degradation path counts as
  satisfying ADR-017's *"if a skill has no such state, it is not ready to migrate"*, or whether that
  clause requires a state that pre-exists the migration. I read it as the latter (the strict reading)
  and flagged Set B accordingly, but proceeded to give Set B a full disposition under the assumption
  that authoring one is acceptable if the manager reads it the other way.
- **Assumption**: block byte counts exclude the fence delimiter lines. Stated in § *Method*; every
  total is internally consistent on that basis.
