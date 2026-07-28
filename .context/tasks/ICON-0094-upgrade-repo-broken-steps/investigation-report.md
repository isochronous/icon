I have everything I need. Here is the report.

---

# ICON-0094 — `/upgrade-repo` broken steps: current-state findings

**Baseline**: `HEAD = 9c4c49f`, working tree clean. `skills/upgrade-repo/SKILL.md` is **665 lines**.
**Line-drift result**: ICON-0093 (`89cc68f`, `b846c74`) added **+6 lines** at old `489–500`. Everything at or after old line 501 is now at **+6**. Everything before line 489 is **unchanged**. So the issue's `:75-98`, `:110`, `:175`, `:434-443`, `:108-181` are all still accurate; the issue's `:619-627` is now **`:623-633`**; the issue's `:491-500` / `:502-513` are now **`:491-506`** / **`:508-519`**.

---

## D1 — Template-path resolution is advisory, not enforced — **VERIFIED (and worse than described)**

### The checks: `skills/find-context-template/SKILL.md:59-99`

Verbatim, current:

```
59  ## If the Result Is Empty or the Path Does Not Exist
60
61  ### Copilot CLI
62
63  `$TEMPLATE_DIR` is always assigned a string — checking for an empty variable isn't meaningful. Instead verify the path exists on disk:
64
65  **Bash / zsh:**
66  ```bash
67  [ ! -d "$TEMPLATE_DIR" ] && echo "Template not found at: $TEMPLATE_DIR"
68  ```
69
70  **PowerShell:**
71  ```powershell
72  if (-not (Test-Path $TEMPLATE_DIR)) { Write-Host "Template not found at: $TEMPLATE_DIR" }
73  ```
74
75  If the path doesn't exist, the plugin may not be installed or may be at a non-standard location. Ask the user to verify:
76
77  ```bash
78  copilot plugin list
79  ```
80
81  ### Claude Code
82
83  `$CLAUDE_PLUGIN_ROOT` may be unset if the plugin runtime didn't inject it, making `$TEMPLATE_DIR` empty or null. Check before using it:
84
85  **Bash / zsh:**
86  ```bash
87  [ -z "$TEMPLATE_DIR" ] && echo "CLAUDE_PLUGIN_ROOT is not set — plugin runtime may not have injected it"
88  ```
89
90  **PowerShell:**
91  ```powershell
92  if (-not $env:CLAUDE_PLUGIN_ROOT) { Write-Host "CLAUDE_PLUGIN_ROOT is not set — plugin runtime may not have injected it" }
93  ```
94
95  If the variable is unset, ask the user to verify:
96
97  ```bash
98  claude plugin list
99  ```
```

### Why they are advisory — four independent reasons, all fixable

1. **No non-zero exit anywhere.** All four checks terminate in `echo` / `Write-Host`. Nothing sets an exit status, throws, or aborts. Compare `skills/create-iconrc/SKILL.md:60`, which is the only place in the repo that *does* exit:
   `[ -z "$TEMPLATE_DIR" ] && echo "Run find-context-template before continuing — \$TEMPLATE_DIR is not set" && exit 1`

2. **The section is framed as troubleshooting, not as a step.** The heading is a conditional (`## If the Result Is Empty or the Path Does Not Exist`) sitting *between* `## Discovery Command` (line 28) and `## After Discovery` (line 101). `## After Discovery` (101-111) says only *"Use `$TEMPLATE_DIR` as the source in all subsequent copy commands"* — there is no "and only after the check passes". A caller doing the documented Read-and-Use pattern (described at `:12`: *"read this `SKILL.md`, run the Discovery Command block for the active tool, then use `$TEMPLATE_DIR`"*) never touches lines 59-99 at all — the skill's own self-description skips the validation section.

3. **The Claude Code bash check at `:87` can never fire.** `$TEMPLATE_DIR` is assigned at `:50` as `"${CLAUDE_PLUGIN_ROOT}/context_template"`. That string is *never* empty — with `CLAUDE_PLUGIN_ROOT` unset it is `/context_template`, 16 characters. `[ -z "$TEMPLATE_DIR" ]` is therefore always false. The prose at `:83` (*"making `$TEMPLATE_DIR` empty or null"*) is factually wrong, and the Copilot section at `:63` states the correct reasoning (*"`$TEMPLATE_DIR` is always assigned a string — checking for an empty variable isn't meaningful"*) for the *other* branch. The bash Claude-Code guard is dead code; the PowerShell twin at `:92` tests the right variable and would fire. **This is a bash/PowerShell parity defect inside the guard itself.**

4. **The Copilot bash guard at `:67` inverts under `set -e`.** `[ ! -d "$TEMPLATE_DIR" ] && echo …` exits **1 when the directory exists** (the `[` fails, `&&` short-circuits, the list's status is the `[`'s status). Any caller that pastes it into a `set -euo pipefail` script aborts on the *success* path. It cannot be promoted to a guard by adding `&& exit 1`; it needs restructuring to `if [ ! -d … ]; then …; exit 1; fi`.

### Caller audit — every caller ignores it; one reimplements it

| Caller | Current line | Verbatim | Verdict |
|---|---|---|---|
| `skills/upgrade-repo/SKILL.md` | **104** | `Invoke `find-context-template` to locate the template directory and establish `$TEMPLATE_DIR`.` | **IGNORES.** No validation sentence, no guard, no exit. Next line (`:106`) moves straight on to reading `iconrc.json`. |
| `skills/context-specialist-impl-leaf/SKILL.md` | **113** | `Invoke the `find-context-template` skill to locate the template directory and establish `$TEMPLATE_DIR`.` | **IGNORES.** Line 120 is already `cp "$TEMPLATE_DIR/context/META.md" .context/`. |
| `skills/context-specialist-impl-root/SKILL.md` | **219** | `Invoke the `find-context-template` skill to locate `$TEMPLATE_DIR`, then:` | **IGNORES.** `cp` block begins at 222. |
| `skills/context-specialist-impl-branch/SKILL.md` | **108** | `3. **Copy infrastructure files**: Invoke the `find-context-template` skill to locate `$TEMPLATE_DIR`, then copy `$TEMPLATE_DIR/context/META.md` and `$TEMPLATE_DIR/context/.gitignore` verbatim.` | **IGNORES.** Guard and use in the same sentence. |
| `skills/create-iconrc/SKILL.md` | **55-63**, **86-90** | bash `[ -z "$TEMPLATE_DIR" ] && … && exit 1`; python `if not template_dir: raise RuntimeError(…)` | **REIMPLEMENTS** — and inherits reason 3: the bash form tests the always-non-empty `$TEMPLATE_DIR`, so it is dead in the Claude Code path too. The python form is the only genuinely working guard in the repo, and only because `TEMPLATE_DIR` there comes from `os.environ`, which *can* be absent. |
| `skills/merge-phase-templates/SKILL.md` | **22** | `` `$TEMPLATE_DIR` must be set before this skill begins — `upgrade-repo` Phase 1 sets it (via `find-context-template`). Do not invoke standalone without first ensuring `$TEMPLATE_DIR` points to the plugin's `context_template/` directory.`` | **PROSE PRECONDITION ONLY.** No executable check. |

### Mechanism — how it lands off the drive root (PowerShell)

`skills/find-context-template/SKILL.md:56`:

```powershell
$TEMPLATE_DIR = "$env:CLAUDE_PLUGIN_ROOT/context_template"
```

When the plugin runtime does not inject `CLAUDE_PLUGIN_ROOT`, `$env:CLAUDE_PLUGIN_ROOT` interpolates to the empty string, so `$TEMPLATE_DIR` becomes the literal `"/context_template"`. PowerShell on Windows treats a leading `/` as **rooted on the current drive**, so every subsequent provider call resolves it to `C:\context_template`. ICON-0090 §2 captured exactly this:

```
CLAUDE_PLUGIN_ROOT = []
TEMPLATE_DIR = [/context_template]
Test-Path TEMPLATE_DIR = False
…
FAILED: ItemNotFoundException: Cannot find path 'C:\context_template\context\iconrc.json' because it does not exist.
```

The bash sibling at `:50` uses `${CLAUDE_PLUGIN_ROOT}` — a form the Claude Code skill renderer substitutes at render time, which is why the bash branch appeared to work in the dogfood run (it produced the double-slashed `c:/dev/ai/icon//context_template`) while the `$env:`-syntax PowerShell branch reached the shell unexpanded. **Neither branch has a working guard; only one of them happens to be papered over by the harness.**

### The two *silent* consequences (this is the part worth fixing, not the loud ones)

- **`upgrade-repo:120-129` misclassifies stock as CUSTOMIZED.**
  ```bash
  if diff -q ".context/workflows/task-workflow-template.md" \
             "$TEMPLATE_DIR/context/workflows/task-workflow-template.md" > /dev/null 2>&1; then
  ```
  With a bogus `$TEMPLATE_DIR`, `diff` exits **2** with its error suppressed by `2>&1`. The `if` reads any non-zero as "they differ" and prints `task-workflow-template.md: deprecated (CUSTOMIZED) — merge-phase-templates required before deletion`. This is `.context/standards/shell-portability.md` Rule 4's failure class ("an `if grep` guard masks the tool's own errors") applied to `diff`. Silent, wrong branch, no error text.

- **`upgrade-repo:492-506` writes an empty version and reports success.** With a bogus `$TEMPLATE_DIR`, `grep '"version"' "$TEMPLATE_DIR/context/iconrc.json"` exits 2 and `TEMPLATE_VER=""`. Then `[ "1.2" != "" ]` is true, `sed` succeeds, `mv` succeeds, and the block prints `iconrc.json version: 1.2 → ` while leaving `"version": ""` in the consumer's `.context/iconrc.json`. **This survived ICON-0093** — the `if`/`else` it added guards `sed` *failure*, not an empty template version. It is a live data-corruption path gated only on D1.

### Proposed fix

1. In `find-context-template/SKILL.md`, replace the advisory section with a **mandatory `## Validate` step** placed *before* `## After Discovery`, exiting non-zero, testing the path (not the variable) in all four variants:
   ```bash
   if [ ! -d "$TEMPLATE_DIR/context" ]; then
     echo "ERROR: context template not found at: $TEMPLATE_DIR" >&2
     echo "  CLAUDE_PLUGIN_ROOT=[${CLAUDE_PLUGIN_ROOT-<unset>}]" >&2
     echo "  Verify the plugin install: claude plugin list  (or: copilot plugin list)" >&2
     exit 1
   fi
   ```
   ```powershell
   if (-not (Test-Path (Join-Path $TEMPLATE_DIR 'context'))) {
     Write-Error "context template not found at: $TEMPLATE_DIR"
     exit 1
   }
   ```
   Test `$TEMPLATE_DIR/context` rather than `$TEMPLATE_DIR` — it is the subdirectory every caller actually reads from, and it distinguishes "wrong root" from "root exists but is not a template".
   Use `${CLAUDE_PLUGIN_ROOT-<unset>}` (presence form) in the diagnostic per shell-portability Rule 5.
   Delete or repair the dead `-z "$TEMPLATE_DIR"` check at `:87` and correct the false prose at `:83`.
2. Update `:12` (the callable-primitive contract) to say the Validate block is **mandatory**, not optional.
3. In each of the four callers (`upgrade-repo:104`, `impl-leaf:113`, `impl-root:219`, `impl-branch:108`), change the invocation sentence to name the guard explicitly, e.g.: *"Invoke `find-context-template` to establish `$TEMPLATE_DIR`, then **run its Validate block and halt this skill if it exits non-zero** — every step below assumes a resolved template."*
4. In `create-iconrc:60`, replace the dead `-z` bash form with the same path test.

---

## D2 — Version-sync fails silently on Mac — **ALREADY FIXED for the stated symptom; TWO residual gaps, one of which is a real parity break**

### Current bash branch, `skills/upgrade-repo/SKILL.md:491-506`

```bash
491  ```bash
492  TEMPLATE_VER=$(grep '"version"' "$TEMPLATE_DIR/context/iconrc.json" | grep -oE '[0-9.]+')
493  INSTALLED_VER=$(grep '"version"' .context/iconrc.json | grep -oE '[0-9.]+')
494  if [ "$INSTALLED_VER" != "$TEMPLATE_VER" ]; then
495    INSTALLED_VER_RE=${INSTALLED_VER//./[.]}
496    if sed "s/\"version\": \"$INSTALLED_VER_RE\"/\"version\": \"$TEMPLATE_VER\"/" .context/iconrc.json > .context/iconrc.json.tmp && mv .context/iconrc.json.tmp .context/iconrc.json; then
497      echo "iconrc.json version: $INSTALLED_VER → $TEMPLATE_VER"
498    else
499      rm -f .context/iconrc.json.tmp
500      echo "ERROR: failed to update iconrc.json version ($INSTALLED_VER → $TEMPLATE_VER)" >&2
501      exit 1
502    fi
503  else
504    echo "iconrc.json version: already at $INSTALLED_VER"
505  fi
506  ```
```

### Current PowerShell branch, `:508-519`

```powershell
508  ```powershell
509  $TemplateVer = (Get-Content "$TEMPLATE_DIR\context\iconrc.json" | ConvertFrom-Json).version
510  $InstalledVer = (Get-Content ".context\iconrc.json" | ConvertFrom-Json).version
511  if ($InstalledVer -ne $TemplateVer) {
512      (Get-Content ".context\iconrc.json") -replace `
513          """version"": ""$InstalledVer""", `
514          """version"": ""$TemplateVer""" | Set-Content ".context\iconrc.json"
515      Write-Host "iconrc.json version: $InstalledVer → $TemplateVer"
516  } else {
517      Write-Host "iconrc.json version: already at $InstalledVer"
518  }
519  ```
```

### (a) Is the original symptom still reachable? **No — not via the platform path it was filed for.**

The two GNU-only constructs are gone. Confirmed by `git diff 0484620..4eea2a2`:
- `grep -oP '[\d.]+'` → `grep -oE '[0-9.]+'` (both lines). This is the *correct* shape of the Rule 7 fix — the `\d` was translated to `[0-9]`, not just re-flagged. Verified against a real line: `  "version": "1.13",` yields `1.13`.
- `sed -i "s/…/…/" .context/iconrc.json` → temp-file-and-`mv` with `&&`, which sidesteps the GNU/BSD `-i` suffix divergence (Rule 8) entirely.
- The bare success `echo` is now inside an `if`, with an `else` that cleans the temp file, writes to **stderr**, and `exit 1`s.

On macOS/BSD today, this block either updates the version and prints the transition, or prints an error and exits non-zero. It cannot print a success line while leaving the version unchanged.

### (b) Do the branches now agree? **No — three ways.**

1. **Regex-metacharacter escaping is bash-only.** Line 495 builds `INSTALLED_VER_RE=${INSTALLED_VER//./[.]}` so `1.2` becomes `1[.]2`. The PowerShell branch at `:513` interpolates `$InstalledVer` **raw into a `-replace` regex**, where `.` is still a live metacharacter. `"version": "1.2"` will also match `"version": "1x2"`. This is the exact latent bug ICON-0090 §3.7 flagged ("the `sed` pattern interpolates `$INSTALLED_VER` unescaped") — ICON-0093 fixed it on one side only. Low practical blast radius (version strings are digits and dots), but it is a straight parity break introduced by the fix.
2. **There is no failure path in PowerShell at all.** Bash has `else … exit 1`. PowerShell has no error branch: `Set-Content` failing (read-only file, encoding error, locked file) leaves `Write-Host "iconrc.json version: … → …"` on the *next* line, unconditionally. **The exact symptom the ticket describes — "prints a success message while the version never changes" — is still live in the PowerShell branch**, just not on the platform the ticket named.
3. **Different extraction, different failure modes.** Bash uses `grep`+regex; PowerShell uses `ConvertFrom-Json`. On a malformed `iconrc.json`, bash silently yields `""` while PowerShell throws. Neither is checked.

Plus the D1-coupled gap already stated: **`TEMPLATE_VER=""` corrupts the file and reports success in bash**, and `$TemplateVer = $null` does the same in PowerShell (`-ne $null` is true for any non-null installed version, and the replacement writes `"version": ""`).

### (c) Is there anything left for this ticket item?

**Yes, but scoped — and it is not a re-fix of what ICON-0093 did.** Leave lines 491-506 alone. The remaining work is:

1. Parenthesize/escape the PowerShell pattern: `$InstalledVerRe = [regex]::Escape($InstalledVer)` and use `"""version"": ""$InstalledVerRe"""` as the pattern (the replacement side stays literal — but note `$` in a `-replace` replacement string is a substitution metacharacter, so if template versions ever contain `$` this needs `[regex]::Escape` on the pattern only, plus `'$$'` doubling on the replacement).
2. Add the missing PowerShell failure branch (`try`/`catch` around `Set-Content`, `Write-Error`, `exit 1`) so it matches bash's contract.
3. Add an empty-value guard to **both** branches before the comparison:
   ```bash
   if [ -z "$TEMPLATE_VER" ] || [ -z "$INSTALLED_VER" ]; then
     echo "ERROR: could not read a version from template or installed iconrc.json — aborting" >&2
     exit 1
   fi
   ```
   This is the belt to D1's braces; it is cheap and it closes the corruption path even if D1 slips.

If the coder does nothing else, **item 3 is the one that matters** — items 1 and 2 are parity hygiene.

**Do not** "reuse the PowerShell branch below it" as the issue's task list suggests. The PowerShell branch is currently the *weaker* of the two.

---

## D3 — Clashing-prefix check flags every established project against itself — **VERIFIED**

### Current text, `skills/upgrade-repo/SKILL.md:175` (single line)

```
- **`local_task_id_prefix` collision check**: read the current value; sample commits with `git log --oneline -100`; extract any `[A-Za-z]{2,}-\d+` ticket-prefix patterns (case-insensitive, to catch a team that started lowercase); if the local prefix matches one (case-insensitive), report a finding (`Local prefix '<X>' collides with detected external ticket prefix '<X>' — recommend changing to 'LOCAL' or another distinct value`). Reporting only — Phase 2 does not auto-rewrite the field.
```

### What it compares against what

- **Left side**: the `local_task_id_prefix` value read from `.context/iconrc.json` (`ICON` here; `LOCAL` in the shipped template default, `context_template/context/iconrc.json:4`).
- **Right side**: the set of all substrings in the last 100 `git log --oneline` subjects matching `[A-Za-z]{2,}-\d+`, prefix-part only, folded case-insensitively.
- **Membership test**: case-insensitive set membership. **No exclusion of the left side from the right side.**

Since every task commit in an ICON-managed repo is required by `commit-conventions.md` to carry `<PREFIX>-NNNN` in its subject, the right-hand set is dominated by the left-hand value. **The check is structurally guaranteed to fire on any repo with ≥1 prior task commit in the last 100.** Reproduced live just now on ICON:

```
$ git log --oneline -100 | grep -oE '[A-Za-z]{2,}-[0-9]+' | sed 's/-[0-9]*$//' | sort | uniq -c
     70 ICON
      7 ADR
      1 adr
```

Applying the rule literally emits the self-contradictory finding ICON-0090 §3.9 recorded verbatim:

> `Local prefix 'ICON' collides with detected external ticket prefix 'ICON' — recommend changing to 'LOCAL' or another distinct value`

Severity is bounded by `:521-525` (Phase 2 does not rewrite the field) but the recommended remedy — renaming to `LOCAL` — would orphan 81 task folders under `.context/tasks/` and every historical commit subject.

### The second clause — "document references that merely look like ticket IDs"

The `ADR` (7) and `adr` (1) hits above are the false positives. They come from **ADR references inside commit subjects**, not from a ticket tracker:

```
9ea91e3 ICON-0091: stop ADR-005 asserting inventories it cannot keep accurate
7281072 ICON-0091: amend ADR-013's inherited over-broad reading of ADR-005
0878547 ICON-0091: amend ADR-005 in place and correct the sites that inherited it
1edc78b ICON-0091: record architecture assessment on ADR-005 disposition
2a605e9 ICON-0091: create task plan for amending ADR-005 (roadmap R-0a)
9366e0d ICON-0080: reconcile .context/ knowledge base to GitHub-only (supersede ADR-006/011)
```

`ADR-NNN` is a `.context/decisions/NNN-*.md` document reference — the same shape as a ticket ID, in the same field, and unreachable by any pattern refinement on `[A-Za-z]{2,}-\d+` alone.

**The distinguishing signal is position.** A real ticket prefix is written at the **start of the commit subject** (the `<TYPE>: <TICKET>-<NNNN>` / `<TICKET>-<NNNN>: <summary>` conventions both put it there); a document reference appears mid-subject. Anchoring eliminates the noise completely — verified live:

```
$ git log --format='%s' -100 | grep -oE '^[A-Za-z]{2,}-[0-9]+' | sed 's/-[0-9]*$//' | sort | uniq -c
     55 ICON
```

`ADR` gone, zero false positives, zero loss of real signal.

### Proposed fix for `:175`

Rewrite the bullet to specify, in order:
1. Read `local_task_id_prefix` from `.context/iconrc.json`.
2. Sample subjects with `git log --format='%s' -100` (not `--oneline`, whose leading SHA defeats `^` anchoring).
3. Extract prefixes **anchored at subject start**: `^[A-Za-z]{2,}-[0-9]+` — note **`[0-9]+`, not `\d+`**; the current prose's `\d` is PCRE-only and a coder transliterating it into `grep -oE` walks straight into shell-portability Rule 7's silent-mismatch case (`[\d]` in ERE is the literal set `{\, d}`).
4. **Remove the local prefix from the extracted set (case-insensitive) before comparing** — it is the value under test, not evidence against itself.
5. Report a finding only if the remaining set is non-empty and contains a case-insensitive match.
6. Reword the finding so it names the colliding *external* prefix and does not recommend `LOCAL` blindly — hand the surviving set to `create-iconrc` as `forbidden_prefixes` (the field is already defined for exactly this at `skills/create-iconrc/SKILL.md:49`, and `upgrade-repo:521-525` already routes there).

Optional hardening: also exclude prefixes that resolve to an existing `.context/decisions/NNN-*.md` (that catches `ADR` even in a repo whose commit convention puts the ADR ref first).

Both a bash and a PowerShell variant should be given — this bullet currently has neither, which is part of why it gets executed as loose prose.

---

## D4 — Pruning-script paragraph reads unconditionally and destroys consumer customization — **VERIFIED. This is the destructive one.**

### Verbatim, `skills/upgrade-repo/SKILL.md:434-443`

```
434  **Special case — `prune-context.sh` pre-`INTEGRATION_BRANCHES`** (or a still-present
435  legacy `prune-old-tasks.sh`): if the old script uses a hardcoded `=~` regex without
436  a named variable, extract that regex, copy the new script, and set
437  `INTEGRATION_BRANCHES` to the extracted value — do not reset to the generic default.
438  If a legacy `prune-old-tasks.sh` is present in `.context/workflows/`, `git mv` it to
439  `prune-context.sh` so the `.githooks/post-commit` reference resolves. (If heavily
440  customized and you want the rename + overwrite in the diff, `git rm` it instead before
441  copying.) Then run the standard
442  `cp $TEMPLATE_DIR/context/workflows/prune-context.sh .context/workflows/` — the rename
443  preserves the hook reference; the copy overwrites stale logic with the current template.
```

### Anatomy

- **The condition** (`:435-436`): *"if the old script uses a hardcoded `=~` regex without a named variable"*. ICON's installed script has the named variable, so the condition is **false** for ICON and for every repo initialized after `INTEGRATION_BRANCHES` was introduced — i.e. for the overwhelming majority of repos `/upgrade-repo` will ever run against.
- **The instruction** (`:441-443`): *"Then run the standard `cp $TEMPLATE_DIR/context/workflows/prune-context.sh .context/workflows/`"*.
- **Where the conditional scope breaks** — precisely: the paragraph contains **two independent conditions**, and the terminal `Then` attaches to neither.
  - Condition A opens at `:435` (`if the old script uses a hardcoded =~ regex…`) and its consequent closes at `:437` with the em-dash clause `— do not reset to the generic default.` The full stop ends A.
  - Condition B is a **new sentence** at `:438` (`If a legacy prune-old-tasks.sh is present…`), with its own consequent (`git mv`) and a parenthetical alternative at `:439-441`.
  - `Then run the standard …` at `:441` begins immediately after B's closing parenthesis, in the same sentence flow. Grammatically it reads as B's second step; *semantically* it is written as the paragraph's terminal action ("the standard", definite article, "**the** rename preserves the hook reference; **the** copy overwrites stale logic" — both definite, both presented as things that simply happen).
  - Because A's guard sits nine lines earlier behind a completed sentence and an intervening unrelated condition, a literal executor arriving at `:441` has no syntactic cue that `cp` is conditional at all. The paragraph opens with a guard and closes with an unguarded imperative.
- **The customized value at risk**: `INTEGRATION_BRANCHES` — a shell regex naming which branches the post-commit hook is allowed to prune `.context/tasks/` on.
  - **Where it lives**: `.context/workflows/prune-context.sh`, line 24 (consumed at line 92: `if [[ ! "$CURRENT_BRANCH" =~ $INTEGRATION_BRANCHES ]]; then exit 0; fi`).
  - **The template default** (`context_template/context/workflows/prune-context.sh:22-24`):
    ```bash
    # Customize to match this repository's integration branch names.
    # Updated by initialize-repo based on git log / git branch analysis.
    INTEGRATION_BRANCHES="^(main|master|dev|develop|trunk)$"
    ```
  - **ICON's customized value** (`.context/workflows/prune-context.sh:22-24`):
    ```bash
    # ICON repo uses a main-only branch model. There is no dev/develop branch.
    # All commits land on main; the release IS the tag push.
    INTEGRATION_BRANCHES="^main$"
    ```
  - ICON-0090 §3.6 confirmed this is **the entire diff** between installed and template — the copy would revert a deliberate ADR-002 decision and re-arm pruning on four branch names ICON has decided will never exist, for zero benefit.
- **The mistakes-table entry that warns against this** — `:659-661`:
  ```
  659  | Mistake | Fix |
  660  |---|---|
  661  | Resetting `INTEGRATION_BRANCHES` to generic defaults | Extract old regex first, preserve it |
  ```
- **The final check that would then validate the broken value** — Phase 4 item 1, `:625`:
  ```
  625  1. `prune-context.sh` contains a correct `INTEGRATION_BRANCHES` value
  ```
  After a blind `cp`, the file *does* contain a syntactically valid, well-formed `INTEGRATION_BRANCHES`. The check as worded ("a correct value") cannot distinguish "the repo's value" from "the template's value", so it passes and stamps the destruction as verified.

### Second, independent unconditional write to the same variable — `:453-454`

```
453  After creating `branching.md`, update `INTEGRATION_BRANCHES` in
454  `prune-context.sh` to match the integration branches it documents.
```

This fires whenever `branching.md` was missing (a Phase 1 "new required file"), and it too has no preserve-existing clause. In a repo that has a customized `INTEGRATION_BRANCHES` **and** a missing `branching.md`, these two instructions compound. Any fix to `:434-443` that does not also address `:453-454` leaves half the hazard.

### Proposed fix

1. **Restructure `:434-443` into an explicit decision table** so no branch can be read as unconditional. Sketch:

   | Installed state | Action |
   |---|---|
   | `prune-context.sh` present **with** a named `INTEGRATION_BRANCHES` | **Extract the existing value first.** Copy the template script, then restore the extracted value. Never leave the generic default in place. |
   | `prune-context.sh` present with a hardcoded `=~` regex, no named variable | Extract the regex, copy the template script, set `INTEGRATION_BRANCHES` to the extracted regex. |
   | Legacy `prune-old-tasks.sh` present | `git mv` to `prune-context.sh` first (preserves the `.githooks/post-commit` reference), then apply whichever row above matches its contents. |
   | Neither present | Copy the template script verbatim; set `INTEGRATION_BRANCHES` from `branching.md`. |

   Every row that ends in a copy must be followed by an explicit "restore the extracted value" step. **There must be no sentence anywhere in the section that says `cp …` without a preceding extraction in the same row.**

2. **Give it real shell**, extract-then-restore, in both `.sh` and `.ps1`. Portability constraints for whoever writes it:
   - Extraction must not use `grep -P` (Rule 7). `sed -n 's/^INTEGRATION_BRANCHES=//p'` is the safe shape.
   - Restoration must not use `sed -i` bare (Rule 8). Use the temp-file-and-`mv` form **with the full `|| { rm -f file.tmp; exit 1; }` fence** — Rule 8 documents at length that the shortened `|| rm -f file.tmp` form exits 0 on failure.
   - The extracted value is a **regex containing `^`, `$`, `(`, `)`, `|`** — it will be substituted into a `sed` replacement, where `&` and `\` are metacharacters. Escaping is mandatory and is the most likely place a naive fix breaks.
   - Live-test it (Rule 3 + the Testing Pattern section) on both the preserve path and the failure path. Fenced bash inside `SKILL.md` is **never shellchecked** by `.githooks/pre-commit` or CI — see Ancillary.

3. **Sharpen Phase 4 item 1 at `:625`** so it can actually fail: e.g. *"`prune-context.sh` contains an `INTEGRATION_BRANCHES` value that matches this repo's real integration branches — if the upgrade replaced the script, confirm the pre-upgrade value was restored, not the template default `^(main|master|dev|develop|trunk)$`."*

4. **Fold `:453-454` into the same table** as a conditional: apply only when `branching.md` was newly created *and* no prior customized value was extracted.

---

## D5 — Root redirect file written before user approval — **VERIFIED**

### The step, `skills/upgrade-repo/SKILL.md:75-98`

```
75  ### upgrade-repo: Ensure root-level `claude.md` redirect
76
77  After Cases 1 and 2, check whether a root-level `claude.md` redirect exists. Skip
78  in Case 3 — a redirect pointing at a non-existent `.claude/claude.md` would mislead
79  Copilot CLI users.
80
81  ```bash
82  if [ -f ".claude/claude.md" ]; then
83    if [ ! -f "claude.md" ]; then
84      cat > claude.md << 'EOF'
85  # Project Instructions
86
87  This file is a redirect. The canonical project instructions live in `.claude/claude.md`.
88
89  Read `.claude/claude.md` for the full project overview, tech stack, key commands,
90  and conventions.
91  EOF
92    fi
93  fi
94  ```
95
96  Skip silently if `claude.md` already exists.
97
98  **Case 3 note** — if `.claude/claude.md` does not exist: *Redirect not created — `.claude/claude.md` must exist first. Create it and re-run `upgrade-repo`.*
```

**File created**: `claude.md` at the **repository root** — a 6-line redirect stub (the heredoc body, lines 85-90). It is created by an unguarded `cat >`, with no prompt and no diff shown. ICON-0090 §1 confirmed both guard conditions hold on a repo that is already fully migrated (`.claude/claude.md` present, root `claude.md` absent), i.e. **the write fires on the common, already-healthy case.**

Note that this step sits in **Phase 0**, before the Phase 1 audit gate at `:183` (*"Summarize and **get confirmation before touching any existing file**"*). Two problems with relying on that gate: it is downstream of the write, and its wording says *existing* file — a newly created one is not covered even in spirit.

### The house pattern to copy — `:34-49` (Phase 0, Case 1)

```
34  **Case 1: Needs migration** — `.github/copilot-instructions.md` exists AND `.claude/claude.md` does not.
35
36  Show what will happen and **get confirmation before acting**:
37
38  > Ready to migrate instructions file:
39  > - `mkdir -p .claude`
40  > - `git mv .github/copilot-instructions.md .claude/claude.md`
41  >
42  > Proceed? (y/n)
43
44  If confirmed:
45
46  ```bash
47  mkdir -p .claude
48  git mv .github/copilot-instructions.md .claude/claude.md
49  ```
```

and its restatement at `:51-52`:

```
51  Then offer to migrate any optional sibling directories with the same
52  show-and-confirm pattern (one confirmation per directory):
```

A second instance of the same pattern, for a Phase 2 write, is at `:219-229` (the `decisions.md` migration): *"show what will happen and **get confirmation before acting**"* → blockquote listing each effect → `> Proceed? (y/n)` → *"If confirmed, run the migration:"* → fenced code.

### Proposed fix

Restructure `:75-98` into the identical four-part shape:

```
### upgrade-repo: Ensure root-level `claude.md` redirect

After Cases 1 and 2, check whether a root-level `claude.md` redirect exists. Skip
in Case 3 — a redirect pointing at a non-existent `.claude/claude.md` would mislead
Copilot CLI users. Skip silently if `claude.md` already exists.

If `.claude/claude.md` exists and root `claude.md` does not, show what will be
written and **get confirmation before acting**:

> Ready to create a root-level `claude.md` redirect so Copilot CLI reaches
> `.claude/claude.md`:
>
> ```
> # Project Instructions
>
> This file is a redirect. The canonical project instructions live in `.claude/claude.md`.
>
> Read `.claude/claude.md` for the full project overview, tech stack, key commands,
> and conventions.
> ```
>
> Decline if this repo does not use Copilot CLI — nothing else in the upgrade
> depends on it.
>
> Proceed? (y/n)

If confirmed:

```bash
… existing guarded heredoc, unchanged …
```
```

Keep the `[ -f ]` guards inside the fence (idempotence), and keep the Case 3 note at `:98`.

**Interaction with Phase 4 item 6** (`:630`: `6. Root-level `claude.md` exists`): if the user declines, that check now fails on a healthy repo. Reword to `6. Root-level `claude.md` exists, or its creation was declined at the Phase 0 prompt.`

---

## D6 — No step for the `## Related` cross-reference footers — **VERIFIED (zero occurrences), but the supporting evidence has DRIFTED**

### Zero-occurrence claim: confirmed

A repo-wide grep for `## Related|context-graph` across `skills/` returns hits in `context-document-guidelines`, `context-maintenance` (SKILL.md, `context-graph.md`, both scripts), `context-specialist-impl-root:206,210`, and `context-specialist-impl-leaf:287,291`. **`skills/upgrade-repo/SKILL.md` returns zero hits for either string.** Also zero for `graph`, `seam`, and `orphan`.

### Drift you must know about before writing the report's justification

The issue says *"In this repo exactly one context file had them."* **That is no longer true.** Commit `f6e134b` — *"ICON-0090: close the .context Related seam and make the git hooks executable"* — added footers to 19 content docs on 2026-07-26. Current state:

```
$ bash skills/context-maintenance/scripts/context-graph.sh --check .context
[context-graph] OK: 49 nodes, no dangling references, no orphans
```

22 files under `.context/` (excluding `tasks/`) now carry `## Related`. **ICON's own tree is healed; the skill gap is not.** Do not cite ICON's `.context/` as live evidence — cite `f6e134b`'s existence as evidence that the fix had to be applied by hand because no skill would do it.

### The working implementations to parallel

`skills/context-specialist-impl-leaf/SKILL.md:287-294`:

```
287  ## context-specialist-impl-leaf: Step 4.6: Emit the `## Related` graph seam
288
289  Every content doc you populated in Step 4 — files under `domains/`, `standards/`, `workflows/`, `architecture/`, `testing/`, and `styling/` — feeds the `.context/` knowledge graph. Give each an explicit relationship footer so no doc is a silent orphan:
290
291  1. **Append a `## Related` section as the LAST `## ` section** of each content doc, built from the cross-references you identified while scanning (by-name mentions and related files otherwise buried in prose). Use bulleted `label: [text](path)` links.
292  2. When you generate an **ADR** (`decisions/NNN-*.md`) that supersedes an earlier one, emit the `**Supersedes**` / `**Superseded-by**` bold-fields alongside `**Status**`.
293
294  Follow `context-document-guidelines § Related Section (graph seam)` for the exact format, placement, ADR bold-field convention, and the sparing use of escape-hatch markers — do not restate it here.
```

`skills/context-specialist-impl-root/SKILL.md:206-213` is the same structure, scoped to what impl-root generates:

```
206  ## context-specialist-impl-root: Step 11b: Emit the `## Related` graph seam
207
208  Every content doc you generated in Steps 6–11 — files under `domains/`, `architecture/patterns.md`, and `workflows/` — feeds the `.context/` knowledge graph. Give each an explicit relationship footer so no doc is a silent orphan:
209
210  1. **Append a `## Related` section as the LAST `## ` section** of each generated content doc, built from the cross-references you identified while synthesizing across areas. Use bulleted `label: [text](path)` links.
211  2. When you generate an **ADR** (`decisions/NNN-*.md`) that supersedes an earlier one, emit the `**Supersedes**` / `**Superseded-by**` bold-fields alongside `**Status**`.
212
213  Follow `context-document-guidelines § Related Section (graph seam)` for the exact format, placement, ADR bold-field convention, and the sparing use of escape-hatch markers — do not restate it here.
```

Both delegate the format to `context-document-guidelines § Related Section (graph seam)` (`skills/context-document-guidelines/SKILL.md:104-227`) rather than restating it. **The upgrade step must do the same** — restating the format would create a third copy to drift.

### Scope question resolved: **NOT every `.context/` file. Not even every node.**

`skills/context-maintenance/scripts/context-graph.sh:98-127` is the authority:

```bash
classify() {
  local rel="$1"
  case "$rel" in
    overview.md)          echo overview ;;
    projects.md)          echo projects ;;
    rules-index.md)       echo rules-index ;;
    iconrc.json)          echo config ;;
    retrospectives.md)    echo retrospective ;;
    tasks/*/plan.md)      if [[ "$include_tasks" -eq 1 ]]; then echo task; fi ;;
    tasks/*)              : ;;   # other task-subtree files are never graph nodes
    README.md|*/README.md) echo folder-index ;;
    decisions/[0-9]*.md)  echo decision ;;
    decisions/*.md)       echo decision ;;
    domains/*.md)         echo domain ;;
    standards/*.md)       echo standard ;;
    workflows/*.md)       echo workflow ;;
    architecture/*.md)    echo architecture ;;
    testing/*.md)         echo testing ;;
    styling/*.md)         echo styling ;;
    *) : ;;
  esac
  return 0
}

is_content_kind() {
  case "$1" in
    domain|standard|workflow|decision|architecture|testing|styling) return 0 ;;
    *) return 1 ;;
  esac
}
```

Orphan checking (`:399-406`) runs **only over `is_content_kind` nodes**, minus the three always-reachable roots (`:394-397`: `overview.md`, `projects.md`, `rules-index.md`) and minus anything carrying `<!-- context-graph:orphan-ok -->`. `context-graph.ps1:95-106` is byte-equivalent in behavior (`IsContentKind` lists the same seven kinds).

Three consequences the coder must encode:

1. **In scope for footers**: `.md` files under `domains/`, `standards/`, `workflows/`, `architecture/`, `testing/`, `styling/` — **including sub-directory files** (bash `case` globs match `/`, so `standards/skill-decomposition/skill-structure.md` classifies as `standard`).
2. **Out of scope**: `README.md` at any depth (classifies as `folder-index`, non-content — and it is the thing that *provides* `covers` edges); `overview.md`, `projects.md`, `rules-index.md` (roots); `META.md` (**not a node at all** — `classify` has no case for it); `retrospectives.md` / `retrospectives-archive.md`; `iconrc.json`; everything under `tasks/`; `prune-context.sh` and other non-`.md` files.
3. **`decisions/NNN-*.md` are content-kind and ARE orphan-checked, but must NOT get a `## Related` footer.** `skills/context-document-guidelines/SKILL.md:217` is explicit: *"an ADR does **NOT** get a `## Related` footer (ICON-0081 F1, ICON-0084) … The `## Related` footer seam is for **content docs only** (`domains/`, `standards/`, `workflows/`, `architecture/`, `testing/`, `styling/`) — do not append one to an ADR."* ADRs earn reachability from `rules-index.md` rows (`indexed-by` edges) and `**Supersedes**`/`**Superseded-by**` bold-fields.

**And the sharper point: a footer is not the only way to be non-orphan.** ICON's own tree proves it — seven content docs have no `## Related` and the graph is green:

```
.context/standards/skill-decomposition.md
.context/workflows/task-plan/base.md
.context/workflows/task-plan/phase-architecture.md
.context/workflows/task-plan/phase-completion.md
.context/workflows/task-plan/phase-implementation.md
.context/workflows/task-plan/phase-investigation.md
.context/workflows/task-plan/phase-testing.md
```

They are reachable via `rules-index.md` rows — including the parent-row-to-directory expansion at `context-graph.sh:281-290`, where a rules-index row targeting a *directory* emits a `covers` edge to each direct-child `.md`. `f6e134b`'s commit message records the same judgement: *"Deliberately without a footer: skill-decomposition.md (its Topic Index already carries the same out-edges), the 16 ADRs … and the ICON-0088 exempt scaffolds and append-only records."*

So the step's success criterion is **`context-graph --check` exits 0**, not "every file has a footer". That framing also prevents a well-meaning agent from bolting tenuous links onto scaffolds, which pollutes the graph the seam exists to serve.

### Correction to the issue's stated consequence

The issue says missing footers *"disables the dangling-reference detection the maintenance skill relies on."* That is not the mechanism. Dangling detection (`context-graph.sh:408-416`) runs over **every** resolved markdown link regardless of whether it sits in a `## Related` section — missing footers remove edges, they do not blind the checker.

The real mechanism is worse and more specific:

- `domains/*.md` files are content-kind, are **not** covered by `rules-index.md` (which indexes `standards/`, `workflows/`, `decisions/` — see `impl-leaf:280-281` and the pre-commit trigger scope at `.githooks/pre-commit:552-558`), and in a pre-2.0.0 repo have no footers. So **every `domains/` file is an orphan**.
- `context-graph --check` therefore exits **1**.
- `skills/context-maintenance/SKILL.md:309` invokes it as `bash "…/context-graph.sh" --check "$(git rev-parse --show-toplevel)/.context" || exit 1`, and the contract at `:302` is explicit that any non-zero must abort (*"invoke as `… || exit 1`, never `if context-graph …; then`"*).
- **The Phase 1 audit aborts on the orphan flood before it reports anything else.** That is how the maintenance skill gets disabled — not by a blinded check, but by a fail-closed check that can never go green until a human hand-applies what no skill emits.

### Proposed new step

**Three insertion points**, all in `skills/upgrade-repo/SKILL.md`:

1. **Phase 1 audit bullet**, appended after `:181` (the `.gitattributes` bullet, currently the last):
   > `- **`## Related` graph seam**: do the content docs under `domains/`/`standards/`/`workflows/`/`architecture/`/`testing/`/`styling/` carry a `## Related` footer, or are they otherwise reachable (a `rules-index.md` row, a folder `README.md` index)? Run `context-graph --check` (see `context-maintenance § Tooling: context-graph` for the invocation and the fail-closed exit contract) and report the orphan/dangling counts. Repos initialized before the seam shipped will report every `domains/` file as an orphan — that is the finding, not a parser error.`

   Keep the ADR exclusion visible here so the audit does not flag ADRs as missing footers.

2. **A new Phase 2 (or early Phase 3) step**, e.g. `**New: Emit the `## Related` graph seam**`, placed after the `rules-index.md` generation at `:609-613` (that ordering matters — rules-index rows *are* reachability edges, so generating the index first minimizes the set that actually needs footers). Contents:
   - Scope: exactly the six content directories, excluding `README.md` and excluding `decisions/`, per the `context-graph` classification above.
   - **Never overwrite an existing `## Related` section** — append only where absent, and preserve any pre-existing footer verbatim. (Same posture as `rules-index.md` at `:611`: *"Create it only if absent — NEVER overwrite an existing copy."*)
   - **Derive links from the doc's own body** — by-name mentions of other `.context/` docs, shared subject matter — not from template text. `f6e134b` states the operative discipline: *"Links are limited to relationships already named in each document's body, since a footer of tenuous cross-references pollutes the graph the seam exists to serve."*
   - Delegate format to `context-document-guidelines § Related Section (graph seam)`; do not restate it.
   - Explicitly: **do not append a footer to an ADR**; use `**Supersedes**` / `**Superseded-by**` bold-fields instead.
   - Escape hatch: a genuinely-unlinkable stub gets a file-level `<!-- context-graph:orphan-ok -->`, used sparingly.
   - Termination condition: re-run `context-graph --check` until exit 0.

3. **Phase 4 verify item 10**, appended after `:633`:
   > `10. `context-graph --check` exits 0 for `.context/` — no dangling references, no orphan content docs.`

---

## D7 — First-phase directory checklist omits `decisions/` — **VERIFIED**

### The checklist, `skills/upgrade-repo/SKILL.md:108-110`

```
108  Check and report:
109  - **Infrastructure files**: `prune-context.sh`, `.githooks/post-commit` — present and current?
110  - **Directories**: all of `standards/ architecture/ testing/ tasks/ workflows/ domains/ styling/` exist? *(Skip any in `excludes` — intentionally absent.)*
```

Seven directories listed. `decisions/` is **absent**. Confirmed against `context-specialist-impl-leaf:117`, which creates exactly the same seven on init (`mkdir -p .context/{standards,architecture,testing,tasks,workflows,domains,styling}`) and then obtains `decisions/` separately at `:123` by copying it from the template (`cp -r "$TEMPLATE_DIR/context/decisions" .context/`) — which is why it fell out of the mirrored list.

### Later phases that depend on `decisions/` existing

1. **Phase 2 `rules-index.md` generation, `:609-613`** — the strongest dependency. `:613` verbatim: *"generate it by scanning the three directories and building the three-section table per `context-specialist-impl-leaf` Step 4.5 — one row per top-level `standards/`/`workflows/` file (a parent row for an indexed sub-directory), **one row per `decisions/NNN-*.md` ADR**, each with an "Applies when…" trigger and a link."* With `decisions/` missing, the generated index silently loses its whole third section, and Phase 4 item 8 (`:632`: `` `.context/rules-index.md` exists ``) passes anyway because it only checks existence.
2. **The flat-`decisions.md` migration check, `:152-159`** — its third branch converts a genuinely-missing `decisions/` into a clean pass:
   ```bash
   if [ -d ".context/decisions" ]; then
     echo "decisions/: folder already present — no migration needed"
   elif [ -f ".context/decisions.md" ]; then
     echo "decisions.md: flat file present — migration to decisions/ required"
   else
     echo "decisions.md: not present — nothing to do"
   fi
   ```
   A repo with neither is told *"nothing to do"*. Because the directory checklist at `:110` also does not ask, **nothing in Phase 1 ever notices that `decisions/` is gone.** ICON-0090 §3.2 recorded the same conclusion: *"A consumer whose `decisions/` went missing would pass this audit."*
3. **Phase 2's migration output path** (`:234` `mkdir -p .context/decisions`, `:336` `New-Item …`) creates it — but only on the flat-file branch, which is exactly the branch a decisions-less repo does not take.

### Proposed fix

Change `:110` to:

```
- **Directories**: all of `standards/ architecture/ testing/ tasks/ workflows/ domains/ decisions/ styling/` exist? *(Skip any in `excludes` — intentionally absent.)*
```

and add a Phase 2 restore for the missing case — `decisions/` is one of the few directories with template content to restore, so it is not merely a `mkdir`:

```bash
if [ ! -d ".context/decisions" ]; then
  cp -r "$TEMPLATE_DIR/context/decisions" .context/
fi
```
```powershell
if (-not (Test-Path ".context\decisions")) {
    Copy-Item "$TEMPLATE_DIR\context\decisions" .context\ -Recurse
}
```

Two cautions:
- Place this **before** the rules-index generation at `:609`, or the index will be generated against an empty decisions set.
- Honour `excludes` — a repo may legitimately list `decisions` there. The `*(Skip any in `excludes`)*` note on `:110` already covers the audit side; the Phase 2 restore must repeat the check, per `:189-190` (*"**Excluded directories** … never create, restore, or populate them, even if absent"*).

---

## Interaction and ordering

### Region map (all in `skills/upgrade-repo/SKILL.md` unless noted)

| Fix | Primary region | Secondary regions |
|---|---|---|
| D1 | `find-context-template/SKILL.md:59-99` (+ `:12`, `:83`, `:87`) | `upgrade-repo:104`, `impl-leaf:113`, `impl-root:219`, `impl-branch:108`, `create-iconrc:60` |
| D2 | `:508-519` (PowerShell only) | new empty-value guard at `:494`; **do not touch `:491-506`** |
| D3 | `:175` | `:521-525` (the `forbidden_prefixes` handoff) |
| D4 | `:434-443` | `:453-454`, `:625` (Phase 4 #1), `:661` (mistakes table) |
| D5 | `:75-98` | `:630` (Phase 4 #6) |
| D6 | new step after `:613` | new audit bullet after `:181`, new verify item after `:633` |
| D7 | `:110` | new Phase 2 restore before `:609` |

### Genuine collisions

1. **D7 and D6 share the Phase 1 audit list (`:108-181`).** D7 edits line 110; D6 appends after 181. Different lines, same list — safe sequentially, merge-conflict-prone if two agents rewrite the list wholesale. Assign them to the same agent, or make D6 strictly an append.
2. **D6 and D4 share the Phase 4 list (`:623-633`).** D4 rewrites item 1 (`:625`); D6 appends item 10 after `:633`. Adjacent, low risk, but both renumber-sensitive. D5's Phase 4 item 6 reword (`:630`) is in the same list — three fixes, one nine-item list. **Consolidate all Phase 4 edits into a single pass at the end.**
3. **D1 and D2 are causally coupled.** D2's residual empty-`TEMPLATE_VER` corruption is only fully closed by D1's guard. Land D1 first; D2's local empty-value check is defense in depth, not a substitute.
4. **D1 and D7 are two lines apart** (`:104` and `:110`) in the same Phase 1 preamble. Trivial but real.
5. **D6 depends on D7 landing first** — the D6 step must run after `decisions/` is guaranteed present, otherwise `rules-index.md` regeneration (which D6 orders itself after) is generated against a missing directory and the ADR reachability edges never exist.
6. **D3 and D2 are adjacent in Phase 2** (`:508-519` vs `:521-525`) but do not overlap.

### No contradictions

I found no pair whose *correct* fixes pull in opposite directions. The nearest thing to tension: D5 adds a decline path that makes Phase 4 item 6 unsatisfiable as currently worded, and D4 makes Phase 4 item 1 stricter. Both are Phase 4 edits and are resolved by the consolidation above.

### Recommended order

```
1. D1   (find-context-template + 5 caller sentences)      — unblocks the silent paths under D2/D4
2. D7   (:110 + Phase 2 decisions/ restore)               — prerequisite for D6
3. D3   (:175 + :521-525)                                  — self-contained
4. D5   (:75-98)                                           — self-contained
5. D4   (:434-443 + :453-454)                              — highest risk, wants its own review round
6. D6   (audit bullet + new step + verify item)            — largest, depends on 2
7. D2   (PowerShell parity + empty-value guards)           — small, last
8. One consolidated pass over Phase 4 (:623-633) folding in D4 #1, D5 #6, D6 #10
```

### Safe parallelization

**Wave A (three agents, fully disjoint files/regions):**
- Agent 1 → **D1**: `find-context-template/SKILL.md` + the one-sentence caller edits in `impl-leaf`, `impl-root`, `impl-branch`, `create-iconrc`. Only touches `upgrade-repo:104`.
- Agent 2 → **D5**: `upgrade-repo:75-98` only.
- Agent 3 → **D3**: `upgrade-repo:175` + `:521-525` only.

**Wave B (two agents, after Wave A):**
- Agent 4 → **D4** + **D2**: `:434-443`, `:453-454`, `:491-519`. Contiguous Phase 2 territory, one owner.
- Agent 5 → **D7** + **D6**: `:110`, the Phase 2 restore, the new seam step, the new audit bullet. One owner for the whole Phase 1-list-and-new-step story.

**Wave C (single agent):** the Phase 4 consolidation at `:623-633`.

Do **not** parallelize D4 with D6 — both want to append to Phase 4, and D4's is the one whose wording change is load-bearing.

---

## Ancillary

### Portability of the proposed fixes (`.context/standards/shell-portability.md`, rules 1-8 + Testing Pattern)

The document has 8 numbered rules plus `## Testing Pattern` (`:85-111`) and a `## Related` footer at `:117-119`. Rules that bind here:

- **Rule 7 (`grep -P`)** — binds **D3** directly. The current `:175` prose specifies `[A-Za-z]{2,}-\d+`. `\d` is PCRE-only. Per Rule 7's middle case, a coder who re-flags to `grep -oE '[A-Za-z]{2,}-\d+'` gets a pattern that matches the literal letter `d`, silently. **The fix must write `[0-9]+` in the prose so nobody has to make that translation.** Same caution for any character-class shorthand in D4's extraction pattern.
- **Rule 8 (`sed -i`)** — binds **D4**. The `INTEGRATION_BRANCHES` restore is an in-place edit. Use the temp-file-and-`mv` form **including the full `|| { rm -f file.tmp; exit 1; }` fence**. Rule 8 spends a paragraph on why `|| rm -f file.tmp` alone is fail-open (`rm -f` succeeds, so the list exits 0 and `set -euo pipefail` sails past a failed edit).
- **Rule 4 (`if grep` masks errors)** — binds **D1**. It is the named class of the `diff -q … 2>&1` misclassification at `:121-122`. If the fix adds any `if <tool>` guard on a path that may not exist, it recreates the defect.
- **Rule 5 (`${VAR+x}`)** — binds **D1**. Use `${CLAUDE_PLUGIN_ROOT+x}` for presence, not `${CLAUDE_PLUGIN_ROOT:-…}`, in any diagnostic or check that distinguishes unset from set-but-empty.
- **Rule 6 (PowerShell `-replace` in a method arg list)** — binds **D2** if the `[regex]::Escape` fix is written inline. `[regex]::Escape($InstalledVer)` takes one argument so the arity trap does not fire, but any `(… -replace 'a','b')` passed into a .NET call must get its own parentheses.
- **Rule 3 + `## Testing Pattern`** — binds **D4** and any shell D3/D6 add. Every block that writes or deletes must be live-tested against a fixture, and **contents inspected**, not just exit code.
- **The ICON-0093 lesson at `:97-109`** — *"Passing this procedure can still ship the wrong failure mode… Correcting a portability defect on one platform can silently trade a loud failure for a quiet one."* This is directly on point for **D1**: adding a guard converts today's loud `ItemNotFoundException` into an early exit — good — but if the guard is written as `[ ! -d "$TEMPLATE_DIR" ] && echo …` (the existing `:67` shape) it *also* exits non-zero on the success path under `set -e`. Verify what the new failure mode is on **each** of the four shells (Claude Code bash, Claude Code PowerShell, Copilot bash, Copilot PowerShell), not merely that the old error stopped reproducing.
- **No new rule is required.** All eight existing rules cover the proposed changes.

### `.sh` / `.ps1` parity obligations

- **`find-context-template/SKILL.md`** ships four shell variants (Copilot bash `:32-36`, Copilot PS `:40-45`, Claude bash `:49-51`, Claude PS `:55-57`) and four validation snippets (`:67`, `:72`, `:87`, `:92`). **All eight must move together.** The current guards are already out of parity (bash Claude tests `$TEMPLATE_DIR`, PS Claude tests `$env:CLAUDE_PLUGIN_ROOT`) — that asymmetry is part of the bug, not a style choice.
- **`upgrade-repo/SKILL.md`** pairs bash and PowerShell for: the deprecated-file check (`:119-130` / `:132-145`), the decisions migration (`:231-333` / `:335-431`), the version sync (`:491-506` / `:508-519`), the task-plan installer (`:539-568` / `:570-607`). **D2's PowerShell repair and D4's new `INTEGRATION_BRANCHES` extraction both incur a two-branch obligation.** Note that D3's `:175` and D4's `:434-443` currently have **no** shell at all — if either fix adds a fenced block, it must add both.
- **`context-graph.sh` / `context-graph.ps1`** are a declared parity pair (`context-graph.md:19-20`: *"Both variants produce identical output, edge ordering, and exit codes, verified against the same fixtures (ADR-004 parity)"*). **No fix here needs to modify either script** — D6 only *invokes* them, reusing the invocations already published at `context-maintenance/SKILL.md:305-320`. If a coder is tempted to change the classifier to make the upgrade easier, that is a scope escape and a two-file parity change.
- **`append-retrospective-entry.{sh,ps1}`** — three byte-identical copies each, enforced by `.githooks/pre-commit:586-616`. Untouched by any proposed fix; the task-close retrospective must be appended **via the script**, never hand-edited, or parity breaks.

### Does any fix require touching `context_template/`?

**No — and that is worth stating explicitly, because it is the single most expensive accidental scope escape available here.**

- D1 changes skills only.
- D2 changes `upgrade-repo` only.
- D3 changes `upgrade-repo` only.
- D4 changes `upgrade-repo`'s *instructions*. It must **not** change `context_template/context/workflows/prune-context.sh` — the generic default `^(main|master|dev|develop|trunk)$` at `:24` is correct **as a template default**; the bug is that the upgrade overwrites a customized copy with it.
- D5 changes `upgrade-repo` only.
- D6 changes `upgrade-repo` only. It is tempting to also add `## Related` footers to the nine template content docs currently lacking them —
  ```
  context_template/context/workflows/ci-cd.md
  context_template/context/workflows/commit-conventions.md
  context_template/context/workflows/task-workflow-template.md
  context_template/context/workflows/task-plan/{base,phase-architecture,phase-completion,phase-implementation,phase-investigation,phase-testing}.md
  ```
  **Do not.** ICON-0093 already considered and rejected exactly this for `commit-conventions.md` (plan.md: *"No `## Related` section is added to the two template files… adding one to just the edited file would create asymmetry in the shipped scaffold and is outside this task's remit"*). It also would not fix D6 — D6 exists because the footers must be **derived from the consumer's own file graph**, which a template copy by definition cannot do.
- D7 changes `upgrade-repo` only. The `decisions/` restore copies from the template; it does not modify it.

**Therefore no `context_template/context/iconrc.json` version bump is required** (currently `"1.13"`), and `.githooks/pre-commit:74-220` will not fire its gate. **If any coder does touch `context_template/`, the bump becomes mandatory in the same commit** — the gate compares the staged version against the `latest` tag (Tier 1), and the commit is hard-blocked otherwise.

### `.githooks/pre-commit` checks that will fire on the likely changed-file set

Expected changed files: `skills/upgrade-repo/SKILL.md`, `skills/find-context-template/SKILL.md`, `skills/context-specialist-impl-{leaf,root,branch}/SKILL.md`, `skills/create-iconrc/SKILL.md`, `.context/tasks/ICON-0094-*/plan.md`, `CHANGELOG.md`, `.context/retrospectives.md`.

| Check | Line | Armed? | Notes |
|---|---|---|---|
| `context_template/` version-bump gate | 74-220 | **No** | Unless the coder escapes scope. |
| `common-constraints` sync | 222-463 | **Runs always** | `agents/*.agent.md` exist; will re-stage on drift. Not affected by these edits. |
| Script-parity (`append-retrospective-entry`) | 586-616 | **No** — unless the retrospective script is edited (don't) | |
| Placeholder sentinel (`<!-- ICON-PLACEHOLDER -->`) | 625-647 | **Yes** — `skills/*.md` | Never leave a sentinel in a draft step. |
| **Cap-literal consistency** | 662-702 | **Yes** — `skills/*.md` **and** `.context/*.md` (excl. `tasks/`) | ⚠️ The pattern `older than the [0-9]+th` matches `upgrade-repo:651` — *"Remove entries older than the 10th."* `ENTRY_CAP` is read from `skills/post-incident-review/scripts/append-retrospective-entry.sh`. **Any reflow of the Retrospectives File Migration section that changes that number blocks the commit.** Leave it alone. |
| Skill registration in `README.md` | 712-735 | **Yes** — any `skills/*` path | Passes today; no new skill is being added. If D6 were ever split into its own skill, a README row becomes mandatory. |
| rules-index freshness | 746-756 | **Only if** `.context/standards/*`, `.context/workflows/*`, `.context/decisions/*.md`, or `.context/rules-index.md` is staged | `.context/tasks/**` does **not** arm it. Arms only if a coder adds a shell-portability rule (none needed). |
| **`context-graph --check` on `.context/`** | 791-808 | **Yes** — any `.context/*` path, including `.context/tasks/ICON-0094/plan.md` | Parses the whole tree (`tasks/*` are not nodes). Currently green at 49 nodes; should stay green. Fail-closed: exit 1 **or** 2 blocks. |
| `context-graph --check` on `context_template/context/` | 810-818 | **No** | Unless scope escapes. |
| **`.context/` dead-ref resolver** | 833-908 | **Yes** — `skills/*.md` | ⚠️ **The highest-probability blocker for D6.** Every `.context/<subdir>/<file>.<ext>` string written into a `skills/*.md` file must resolve at `context_template/context/<subdir>/<file>.<ext>`. It is **fence-blind** — a path inside backticks or a ```` ```bash ```` fence is checked identically to prose. Concretely: `.context/domains/entities.md` ✅ (exists in template), `.context/workflows/task-plan/base.md` ✅, but any illustrative path that does not exist in the template ❌. Wrap genuine consumer-only paths in `<!-- pre-commit:dead-ref-ok-start -->` … `<!-- pre-commit:dead-ref-ok-end -->` (already used at `:151/:171`, `:214/:432`). Bare directory refs like `.context/decisions/` do **not** match the regex — only `<name>.<ext>` forms do. |
| Secret scan | 918-947 | **Yes** | No risk. |
| **shellcheck** | 953-973 | **Only** on staged `*.sh` / `.githooks/*` | ⚠️ **Fenced bash inside `SKILL.md` is never shellchecked** — locally or in CI. This is the known gap filed as issue #48 during ICON-0093 (*"the `.githooks/pre-commit` shellcheck gate only fires on staged `*.sh` files, so fenced bash inside `SKILL.md` files — which is exactly where three of the four violations live — is never shellchecked"*). **There is no automated safety net for the new shell in D1/D3/D4/D2.** Live-fixture testing per shell-portability Rule 3 is the only backstop. |

### `## Related` sections in files to be edited

- **None of the `skills/*/SKILL.md` files in scope carry a `## Related` section.** The seam is a `.context/`-document convention (`context-document-guidelines:112`: *"Every **content doc** — a file under `domains/`, `standards/`, `workflows/`, `architecture/`, `testing/`, or `styling/`"*), not a skill-file convention. Verified: `skills/upgrade-repo/SKILL.md`, `find-context-template/SKILL.md`, `context-specialist-impl-{leaf,root,branch}/SKILL.md`, `create-iconrc/SKILL.md` — zero `^## Related`. **No footer updates required.**
- **Only if** a coder decides to add a shell-portability rule: `.context/standards/shell-portability.md` **does** have a `## Related` at `:117-119`, and the seam requires it to remain the **last** `##` section — a new `### 9.` must be inserted before it, and the file's rules-index row re-checked. I judge no new rule is warranted (rules 4, 5, 7, 8 already cover every construct these fixes touch).

---

## Risks / surprises

1. **⚠️ The single most dangerous naive implementation is D4.** A coder who "moves the `cp` inside the condition" and stops has fixed the *wording* and left the *behavior* — because the correct behavior on the common path (script present **with** a named `INTEGRATION_BRANCHES`) is not "skip the copy", it is "extract the value, copy, restore the value". Skipping the copy entirely means the consumer never receives genuine script-logic updates. **Both** halves are required; only the extract-and-restore version satisfies both `:661` (preserve the regex) and `:443`'s legitimate intent (ship current logic).

2. **⚠️ D1's guard can itself be the new defect.** The existing `[ ! -d "$TEMPLATE_DIR" ] && echo …` idiom at `:67` returns **non-zero when everything is fine**. Copy-pasting it into a mandatory guard under `set -euo pipefail` aborts the upgrade on healthy repos. This is precisely the ICON-0093 lesson at `shell-portability.md:97-109` — a portability/guard fix trading one failure mode for another. Write the guard as an explicit `if … then … exit 1; fi`.

3. **⚠️ The dead-ref resolver will block D6's first draft.** Any path of the form `.context/<subdir>/<file>.<ext>` written into `skills/upgrade-repo/SKILL.md` — including inside code fences and backticks — is validated against `context_template/context/`. A step that illustrates a consumer's own file (`.context/domains/payments.md`, say) fails the hook. Either use paths that exist in the template, keep illustrations at directory granularity (`.context/domains/`, which the regex does not match), or bracket them in the `dead-ref-ok` markers.

4. **⚠️ The cap-literal check will block an innocuous reflow.** `upgrade-repo:651` contains *"Remove entries older than the 10th."* inside a fenced block in the Retrospectives File Migration section. The hook regex `older than the [0-9]+th` matches it and compares `10` against `ENTRY_CAP`. Reflowing that section, or changing the number for any reason, blocks the commit.

5. **⚠️ ICON-0090's D-numbering and this ticket's D-numbering do not match.** The audit uses D1–D9; the ticket uses D1–D7. The mapping is: ticket D1 = audit D1 (§2); ticket **D2** = audit's *"GNU-only `grep -oP`/`sed -i`"* predicted-defect (§3.7, §4 "Predicted defects that did NOT reproduce"), **not** audit D2; ticket **D3** = audit **D2** (§3.9); ticket **D4** = audit **D5** (§3.6); ticket D5 = audit **D9** (§1); ticket D6 = audit D6 (§3.13); ticket D7 = audit D7 (§3.2). Audit D3, D4, and D8 (undirected version compare, forked-lineage version markers, iconrc `version` semantics) are **not in this ticket's scope** — they are the "version model" the issue's opening line defers.

6. **Stale evidence in the issue text.** *"In this repo exactly one context file had them"* is no longer true (fixed by `f6e134b`; 22 files now, graph green at 49 nodes). Do not write a plan whose justification depends on ICON's own `.context/` being broken — it isn't. The skill gap is the finding.

7. **D2's "the PowerShell branch immediately below it is already correct" is wrong.** The issue's task list says *"Rewrite the version-sync step with portable commands, or reuse the PowerShell branch below it."* The bash branch is now the stronger of the two: it escapes the regex metacharacter and has a failure path; the PowerShell branch has neither. Reusing PowerShell as the model would be a regression.

8. **ICON is a degenerate test target for `/upgrade-repo`.** ICON-0090 §2 recorded that in a dogfood run `$TEMPLATE_DIR` resolves to ICON's own working tree — *"Template source and upgrade target are the same working tree."* Any live verification of D1/D4/D7 done inside this repo is testing an aliasing case, not a consumer case. Use a scratch fixture repo under the scratchpad, not `.context/`.

9. **Gap I could not close.** I did not execute the proposed fixes — this was a read-only pass. In particular I have **not** verified: (a) the `[regex]::Escape` form for D2 against a real `iconrc.json` on PowerShell 7; (b) any `sed`-based `INTEGRATION_BRANCHES` extract-and-restore against a value containing `^`, `$`, `|`, `(`, `)` — the escaping there is the most likely place a D4 fix breaks silently, and shell-portability's Testing Pattern applies in full; (c) `context-graph --check` behavior on a synthetic pre-2.0.0 `.context/` with zero footers — I inferred the orphan flood from `classify()` and the rules-index coverage boundary rather than reproducing it. If the coder wants a hard number for the D6 justification, building that fixture is the cheapest way to get one.