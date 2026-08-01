# ICON-0099 Wave 1 — Fenced-block classification and disposition

Investigation artifact. Read-only pass; no source file was modified.

**Scope of this document**: every fenced block in `skills/plugin-design/audit-phase-structure.md`,
`skills/plugin-design/audit-phase-consistency.md`, `skills/icon-status/SKILL.md`, and
`.claude/skills/icon-audit/`. 24 blocks total. Wave 2, `skills/upgrade-repo/`, the five `.sh`/`.ps1`
script files, and `context_template/` are out of scope and are not analysed here.

**Method**: fences were enumerated programmatically (open/close scan, byte count of the body
excluding the fence lines) against the working tree at
`feature/ICON-0099-migrate-fenced-blocks-waves-1-2`, which is clean against `HEAD` — so
`git show HEAD:<path>` and the working copy are byte-identical, and every line number below was read
off the live file rather than taken from issue #59.

---

## Headline findings

1. **The four `python3 - <<'PY'` heredocs in `skills/plugin-design/` are the last live `python3`
   invocations anywhere in the repo.** A sweep of `skills/ agents/ commands/ shared/ hooks/
   .claude/skills/ context_template/ .github/ .githooks/` across `.md/.sh/.ps1/.mjs/.yml` returns
   exactly these four call sites; every other `python3` hit in the tree is prose *about* python3
   being unavailable. ICON-0097 removed nine; these four were missed.
2. **Two of the four have no Windows path at all — not even a broken one.**
   `audit-phase-consistency.md` checks 1 (skill-reference resolution) and 3 (description quality)
   ship a `bash`+`python3` block and **no PowerShell variant**. On Windows those two checks are not
   merely broken, they are absent.
3. **`yaml.safe_load` has no Node standard-library equivalent, and 100% of ICON's own frontmatter
   uses folded scalars.** All 50 `skills/*/SKILL.md` and all 9 `agents/*.agent.md` declare
   `description: >`. A naive line-scanner replacement reports "empty description" for every one of
   them. This is the single highest-risk semantics issue in wave 1 and it is discussed at length
   below — it is not a detail the coder can be left to discover.
4. **`icon-status` has 10 deterministic blocks, not 9.** Issue #59 counted Step 2's nine and missed
   the Step 1 fresh-repo guard at `SKILL.md:29-31`.
5. **Three cross-fence state chains in `icon-status` are dead code on this harness today.** `TASK_ID`,
   `PLAN_FILE` and `ICONRC_STATE` are each set in one fence and read in another. Claude Code's Bash
   tool contract states shell state does not persist between calls, so unless the agent concatenates
   the fences into one invocation, Suggestions signals 3 and 4 and the `PLAN_FILE` lookup never fire.
   That is ADR-017 trigger 1's stated failure mode, live.
6. **No wave-1 block requires a committed `.mjs`.** Every disposition below is inline `node -e`, the
   ADR-017 default. Trigger 1 is the only trigger that fires anywhere in wave 1, and it is *cured*
   rather than accommodated — see § icon-status.

---

## Classification table

Byte counts are the fence **body** (excluding the ``` lines). Line ranges are the opening and
closing fence lines inclusive.

### `skills/plugin-design/audit-phase-structure.md` (3,760 B file, 5 fences)

| # | File:line | Bytes | Tag | What it does | ADR-017 tier | Disposition | Grounds |
|---|---|---|---|---|---|---|---|
| 1 | `audit-phase-structure.md:26-35` | 279 | (none) | `node -e` — asserts `plugin.json` declares `name`/`version`/`description` | Deterministic | **Leave as-is — already compliant** | Already inline `node -e`, already untagged, already shell-agnostic. This is the in-file precedent the four python ports must match (ICON-0097). |
| 2 | `audit-phase-structure.md:41-67` | 811 | `bash` | `python3` heredoc — parses YAML frontmatter of every `agents/*.agent.md` + `skills/*/SKILL.md`, reports missing/unparseable/non-mapping frontmatter and missing-or-empty `name`/`description` | Deterministic | **Migrate → inline `node -e`, untagged** | Live bug (python3 does not execute on Windows, ADR-005). Control flow over file content; no trigger fires. |
| 3 | `audit-phase-structure.md:71-87` | 555 | `powershell` | PowerShell twin of #2 — regex presence-check for `name:`/`description:` | Deterministic | **Delete — absorbed by #2's port** | ADR-017 "that is where the twin dies". Not byte-identical to #2, so retagging is unavailable; only migration retires it. See § Fidelity decision. |
| 4 | `audit-phase-structure.md:91-93` | 85 | `bash` | `grep -q '^## \[Unreleased\]' CHANGELOG.md && echo OK \|\| echo MISSING` | Deterministic | **Migrate → inline `node -e`, untagged** | Borderline against Trivial; resolved to Deterministic. See § The borderline call. |
| 5 | `audit-phase-structure.md:97-99` | 115 | `powershell` | PowerShell twin of #4 (`Select-String -Quiet`) | Deterministic | **Delete — absorbed by #4's port** | Twin retirement, same as #3. |

### `skills/plugin-design/audit-phase-consistency.md` (6,491 B file, 4 fences)

| # | File:line | Bytes | Tag | What it does | ADR-017 tier | Disposition | Grounds |
|---|---|---|---|---|---|---|---|
| 6 | `audit-phase-consistency.md:18-48` | 1,212 | `bash` | `python3` heredoc — regex-scans agent/skill bodies for `/foo` slash-invocations and reports any with no `skills/foo/SKILL.md`, with a context-window skip-list | Deterministic | **Migrate → inline `node -e`, untagged** | Live bug; **no PowerShell twin exists**, so this check has no Windows implementation at all. No trigger fires. |
| 7 | `audit-phase-consistency.md:52-80` | 1,036 | `bash` | `python3` heredoc — dead-ref resolver: finds `.context/<path>.<ext>` references in `agents/ skills/ shared/ commands/` and reports those resolving under neither `context_template/context/` nor `.context/` | Deterministic | **Migrate → inline `node -e`, untagged** | Live bug. No trigger fires. |
| 8 | `audit-phase-consistency.md:84-105` | 830 | `powershell` | PowerShell twin of #7 | Deterministic | **Delete — absorbed by #7's port** | Twin retirement. Behaviourally closer to #7 than #3 is to #2, but still not byte-identical. |
| 9 | `audit-phase-consistency.md:109-134` | 876 | `bash` | `python3` heredoc — frontmatter `description` quality: empty / equals `name` / literal `TODO`/`<DESCRIPTION>` / under 20 chars | Deterministic | **Migrate → inline `node -e`, untagged** | Live bug; **no PowerShell twin exists**. No trigger fires. Highest semantics risk in wave 1 (folded scalars). |

### `skills/icon-status/SKILL.md` (8,323 B file, 14 fences)

| # | File:line | Bytes | Tag | What it does | ADR-017 tier | Disposition | Grounds |
|---|---|---|---|---|---|---|---|
| 10 | `icon-status/SKILL.md:29-31` | 43 | `bash` | Step 1 fresh-repo guard: `[ -d ".context" ] \|\| echo "NOT_INITIALIZED"` | Deterministic | **Migrate → inline `node -e`, untagged** | Not trivial: a Node rewrite is `existsSync`, not a `child_process` wrap. `[ -d ]` is bash-only. **This is the block issue #59's count of 9 missed.** |
| 11 | `icon-status/SKILL.md:36-38` | 110 | (none) | The "not yet ICON-initialized" message the agent emits | **Illustrative** | **Leave alone** | Output to recognise and reproduce, not a command. Correctly untagged already. |
| 12 | `icon-status/SKILL.md:49-54` | 267 | `bash` | Repo name from `git remote get-url origin`, with two fallbacks | Deterministic | **Migrate → inline `node -e`, untagged** | Fails the Trivial test's "no control flow" clause — a three-step fallback chain over git's output. Shells out to `git`, which is fine; the *logic* is the program. |
| 13 | `icon-status/SKILL.md:58-63` | 181 | `bash` | `BRANCH` from `git rev-parse --abbrev-ref HEAD`; `TASK_ID` via `grep -oE '[A-Z]+-[0-9]+' \| head -1` | Deterministic **+ trigger 1 (producer)** | **Migrate → inline `node -e`, untagged; make self-contained** | `TASK_ID` is read by #14 and #20. See § Cross-fence state. |
| 14 | `icon-status/SKILL.md:69-78` | 250 | `bash` | `find .context/tasks -maxdepth 2 -name plan.md -path "*$TASK_ID*" \| head -1` | Deterministic **+ trigger 1 (consumer and producer)** | **Migrate → inline `node -e`, untagged; re-derive `TASK_ID` in-fence** | Reads `$TASK_ID` from #13; sets `$PLAN_FILE` read by #20. |
| 15 | `icon-status/SKILL.md:82-88` | 152 | `bash` | Last 3 `### TASK-ID` headings from `.context/retrospectives.md`, or a "(no retrospectives.md)" note | Deterministic | **Migrate → inline `node -e`, untagged** | Control flow over file presence + line matching. |
| 16 | `icon-status/SKILL.md:95-102` | 227 | `bash` | For six fixed subdir names, if `.context/$d` is a directory, count `*.md` files at depth 1 | Deterministic | **Migrate → inline `node -e`, untagged** | **The Rule 10 exhibit of wave 1** — two different filesystem probes in one block needing two different Node idioms. See § Semantics. |
| 17 | `icon-status/SKILL.md:106-128` | 946 | `bash` | Reads `.context/iconrc.json` `version` via a nested `node -e`, guards the empty capture, sets `ICONRC_STATE` | Deterministic **+ trigger 1 (producer)** | **Migrate → single inline `node -e`, untagged** | Already Node at the core; the bash is a wrapper. `ICONRC_STATE` is read by #19. |
| 18 | `icon-status/SKILL.md:136-138` | 7 | (none) | `node -v` | **Excluded — E2 (bootstrap)** | **Leave alone** | It *is* the invocation contract's guard, not a candidate for it (ADR-017 § Exclusions E2, `check-node-runtime`). Already untagged and shell-agnostic. **Byte-identical to `skills/check-node-runtime/SKILL.md:32-34`** — flagged as a duplicate, but excluded, so not a wave-2 item. |
| 19 | `icon-status/SKILL.md:151-161` | 398 | `bash` | Suggestions signal 1 — `.context/domains/` missing or empty | Deterministic | **Migrate → inline `node -e`, untagged** | Recomputes the same count as #16 with the same Rule 10 hazards. |
| 20 | `icon-status/SKILL.md:168-171` | 134 | (none) | The signal-2 suggestion text template | **Illustrative** | **Leave alone** | Output template with `<placeholders>`; correctly untagged. |
| 21 | `icon-status/SKILL.md:176-183` | 382 | `bash` | Suggestions signal 3 — branches on `$ICONRC_STATE` | Deterministic **+ trigger 1 (consumer)** | **Migrate → inline `node -e`, untagged; re-derive iconrc state in-fence** | Reads `$ICONRC_STATE` from #17. Dead code today. |
| 22 | `icon-status/SKILL.md:185-193` | 335 | `bash` | Suggestions signal 4 — `plan.md` not modified in 48h, via `find -maxdepth 0 -mmin +2880` | Deterministic **+ trigger 1 (consumer)** | **Migrate → inline `node -e`, untagged; re-derive `TASK_ID`/`PLAN_FILE` in-fence** | Reads `$TASK_ID` and `$PLAN_FILE`. Dead code today. |
| 23 | `icon-status/SKILL.md:205-226` | 384 | (none) | The rendered dashboard template | **Illustrative** | **Leave alone** | Output shape; correctly untagged. |

### `.claude/skills/icon-audit/` (SKILL.md 9,591 B, 1 fence; `briefs/*.md` and `synthesis-template.md` contain **zero** fences)

| # | File:line | Bytes | Tag | What it does | ADR-017 tier | Disposition | Grounds |
|---|---|---|---|---|---|---|---|
| 24 | `.claude/skills/icon-audit/SKILL.md:32-54` | 962 | `bash` | Phase 1 discovery: newest prior `audit-report.md` via `find \| sort \| tail -1` with a baseline/no-baseline branch; `wc -l` on retrospectives and CHANGELOG; agent/skill/manifest counts | Deterministic (with trivial sub-parts) | **Migrate → inline `node -e`, untagged — lowest priority** | The 1.1 sub-block has control flow over `find`'s output, which the Trivial row's converse makes Deterministic. 1.2–1.4 are counts a Node rewrite need not shell out for. Maintainer-only; see § Sequence for the drop condition. |

**Totals**: 24 blocks — 4 Illustrative (leave), 1 E2-excluded (leave), 1 already compliant (leave), 3 PowerShell twins retired by their bash sibling's port, 15 migrated to inline `node -e`. **Zero committed `.mjs`.**

---

## Per-site analysis

### Site A — `skills/plugin-design/audit-phase-structure.md` + `audit-phase-consistency.md`

#### Inline `node -e` or committed `.mjs`?

**Inline `node -e`, all five ports (#2, #4, #6, #7, #9). No trigger fires.**

| Trigger | Verdict |
|---|---|
| 1. State crosses a fence boundary | **No.** Each heredoc is a closed program that reads from disk, prints findings, and exits. No fence in either file consumes a variable another fence sets. |
| 2. It mutates state | **No.** All five are read-only: `read_text`, `glob`, `exists`. Nothing writes. |
| 3. Invoked ≥ 2× in the same skill with different arguments | **No.** #2 and #9 both walk the same file set and both parse frontmatter, but they are two *different programs* answering two different questions, not one program invoked twice. Trigger 3 does not reach "two programs that resemble each other". |
| 4. A literal `'` is structurally required | **No, after rephrasing — and rephrasing is required, not optional.** #2's message `f"{p}: missing or empty '{required}'"` contains literal apostrophes, and #9's `{desc!r}` emits Python-repr single quotes. Both must be rephrased to double quotes (or `JSON.stringify`) in the port. ADR-017 makes rephrasing the first move and trigger 4 a last resort; it is available here, so trigger 4 does not fire. **The coder must not carry the apostrophes across and then reach for a `.mjs`.** |

Neither file is near an ADR-016 cap (3,760 B and 6,491 B against the 8,000 B companion cap), so the
Disqualified clause is not even in play. Recording it anyway: **size played no part in this
disposition, in either direction.**

#### Node-absent degradation path — **READY, and the question is moot for this site**

`plugin-design` has **no Node-absent degradation path**, and does not need one, because
**Phase 1 already depends on Node unconditionally and without a guard**:
`audit-phase-structure.md:23-24` introduces the existing `node -e` block with

> "Identical in every shell — run it as-is, in whatever shell the session uses. Silence
> and exit 0 mean all three fields are declared; anything else goes to stderr and exits 1."

Checks 1–3 of Phase 1 are already unrunnable without Node. Porting the four python blocks to
`node -e` therefore **adds no new runtime dependency to this skill** — it removes one (`python3`)
from a skill that already requires the other. There is nothing to degrade *to* that is not already
degraded today.

**And, decisively: ADR-017 does not impose the guard on inline `node -e` at all.** The Deterministic
row's own test column reads *"Shell-agnostic, no path resolution, no new file, **no runtime
guard**"*, and Alternatives Considered 4 rejects mass-`.mjs` precisely because
*"inline `node -e` already gets the portability win with none of that overhead"* — the overhead
enumerated immediately before being *"an invocation preamble, a runtime guard and a degradation
path"*. The `node -v` precondition and the "not ready to migrate" clause live inside
**§ The invocation contract**, which is the contract for invoking a committed `.mjs`.

> **Correction for the plan.** `plan.md:45` records the open question as *"whether the migrated
> skills have an existing degradation path for Node-absent"* with the "not ready to migrate" quote
> attached. That gate binds `.mjs` migrations. Since every wave-1 disposition is inline `node -e`,
> **the gate is not engaged at any of the three sites** and no site is blocked on it. Each site's
> path is reported below regardless, because the answer changes if a `.mjs` is ever proposed here.

*Optional, non-blocking, and explicitly not part of this migration*: `audit-mode.md § Hard
Precondition` (lines 7-41) is the natural home for a stated Node prerequisite for consumers running
`/plugin-design audit` on their own plugins. Adding one would be **inventing** a degradation path,
which ADR-017 forbids doing as part of a migration. Raise it as a follow-up or leave it.

#### Prose-contract survival

The `## Checks` lists at `audit-phase-structure.md:9-17` and `audit-phase-consistency.md:9-12` are
already the prose contract, and they are **outside the fences** — so the migration cannot shrink
this file to "run the script" by accident. What must be written or preserved:

- **`audit-phase-structure.md:37-39`** currently reads *"Frontmatter parse (Python, no yq
  dependency) — `yq` is not always installed; this Python snippet parses the YAML block…"*. That
  heading and sentence are **factually dead after the port** and must be rewritten, not just
  re-tagged. The replacement prose must state the new fidelity limit (below), because it is a
  *reduction in what the check detects* and a reader must not be left believing YAML is parsed.
- **`audit-phase-structure.md:69`** — the sentence introducing the PowerShell twin ("*uses
  `powershell-yaml` if available, otherwise falls back to a hand parser…*") is deleted with the
  twin. The fidelity caveat it carried moves into the surviving prose.
- **`audit-phase-consistency.md:10`** — *"This generalizes the dead-ref pattern from ICON's own
  pre-commit hook"* — keep; it is the provenance of check 2 and it is what makes the extension
  below correct.
- **Untagged-fence disambiguation (ADR-017's third author obligation).** Every ported fence loses
  its language tag. Nothing inside an untagged fence distinguishes a command from illustrative
  output, so each one needs a lead-in that says *run this*. `audit-phase-structure.md:23-24` is the
  model to copy verbatim in shape.
- **Outcome semantics per check.** Each ported block's stdout must be described: what a silent run
  means, what a finding line looks like, and what exit code accompanies each. The existing
  `node -e` block at :26 already does this in one sentence; match it.

#### Semantics to preserve (Rule 10) — extract each original with `git show HEAD:skills/plugin-design/<file>` and diff against it

**S1 — `yaml.safe_load` has no Node standard-library equivalent. This is a fidelity decision, not a
port.** ADR-005 forbids third-party imports, and Node ships no YAML parser. Affects #2 and #9.

- **The 100% folded-scalar fact.** Every one of the 50 `skills/*/SKILL.md` and all 9
  `agents/*.agent.md` declare `description: >` followed by an indented continuation block. A
  line-scanner that reads the text after `description:` gets `>` or the empty string for **every
  ICON file**. #9's checks (`not desc` → "empty description"; `len(desc) < 20` → "too short") would
  fire on all 59. **A port that does not fold `>` and `|` block scalars produces a 100%
  false-positive rate on ICON's own self-audit** — and `plugin-design` audit mode is run against
  ICON itself (`audit-phase-consistency.md:10` and the `context_template/context/` fallback in #7
  exist specifically for that case).
- **Required minimum fidelity for the port**: recognise `key:` at column 0 in the frontmatter
  region; for `key: value` take the inline value, stripping matched surrounding quotes; for
  `key: >` / `key: >-` / `key: |` / `key: |-` join the following more-indented lines (spaces for
  `>`, newlines for `|`) until a line at or below the key's indentation. That is the subset ICON's
  frontmatter actually uses. **Anything beyond that subset is out of reach and must be stated as a
  limitation in prose, not silently dropped.**
- **What is genuinely lost**: `yaml.safe_load`'s syntax-error detection (#2's *"YAML parse error"*
  finding) and its type check (#2's *"frontmatter is not a mapping"* finding). A line-scanner
  cannot produce either. Two options, and the coder must pick one **explicitly and record it**:
  **(a)** drop both findings and say so in the `## Checks` list — this matches the fidelity the
  PowerShell twin already ships, so no Windows user loses anything and no user gains a false pass;
  **(b)** keep a weakened "frontmatter is not a mapping" as "no `key:` line found between the
  delimiters". **(a) is recommended** — (b) invents a check with a different meaning under the same
  name. Do not report either option as a faithful port.

**S2 — `str.split("---", 2)` is *maxsplit*; `String.split("---", 2)` is a *result cap that discards
the remainder*.** Affects #2 and #9. Verified on this machine:

```
Python:  "---\nname: x\n---\nbody --- more".split("---", 2)
      -> ['', '\nname: x\n', '\nbody --- more']

Node:    "---\nname: x\n---\nbody --- more".split("---", 2)
      -> ["", "\nname: x\n"]                      // "\nbody " silently dropped
         .split("---", 3)
      -> ["", "\nname: x\n", "\nbody "]           // still truncated at the 3rd "---"
```

Copying Python's literal `2` into JS makes `parts.length < 3` **unconditionally true**, so **every
file is reported as "missing frontmatter"** — a 100% false positive that a smoke test on one file
will reproduce, but that a reviewer skimming the diff will not see. The array length is the only
thing this code reads from the split, and `limit: 3` reproduces the length correctly for 0, 1 and
≥2 delimiters, so `limit: 3` is a correct minimal fix. Preferring an explicit frontmatter extractor
(`if (!txt.startsWith("---\n")) → missing; find the next line that is exactly "---"`) is safer
still and sidesteps the whole class — note that the Python original is **not** line-anchored, so a
file with no frontmatter but a `---` horizontal rule in its body is treated by the original as
having frontmatter. If the port anchors to line starts it is *more* correct than the original; that
is an intentional divergence and must be written down as one.

**S3 — `pathlib` glob on a missing directory yields nothing; `readdirSync` throws `ENOENT`.**
Affects #2, #6, #9 (`Path("agents").glob(...)`) and #7 (which already guards with
`if not base.exists(): continue`). This is the **highest-consequence divergence in Site A** because
`audit-phase-structure.md:14` explicitly documents the triggering case:

> "Not all are mandatory (a skill-only plugin may omit `agents/`), but report each present/absent
> for a sanity-check."

So a naive `readdirSync("agents")` **crashes the audit on exactly the plugin shape the skill says is
legitimate**. Every directory read in the port needs an existence guard or a caught `ENOENT`, and
the guard must yield "no files" — not "check skipped", and not a stack trace.

**S4 — dot-entry handling must be chosen deliberately, per construct.** `pathlib.Path.glob("*")` and
shell `*` do **not** agree on leading-dot entries, and `readdirSync` agrees with neither by default.
Rule 10's whole point is that there is no blanket mapping. In ICON's own tree the difference is
immaterial (`agents/` and `skills/` hold no dot-entries), but `plugin-design` audits arbitrary
consumer plugins. **Pick a behaviour, write it in a comment next to the filter, and make sure #2, #6
and #9 all pick the same one** — they walk the same file set and must not disagree about it.

**S5 — regex translation, #6 specifically.** The pattern is
`r'(?:^|(?<=[\s`]))/([a-z][a-z0-9-]+)(?=[\s`.,;:!?)\]]|$)'` with `re.MULTILINE`.

- `re.MULTILINE` → JS `m` flag. `finditer` → `matchAll`, which **throws `TypeError` unless the regex
  also carries `g`.** Two flags, not one.
- `m.start()` → `m.index`; `m.end()` → `m.index + m[0].length`; `m.group(1)` → `m[1]`.
- Lookbehind `(?<=…)` is supported in Node. No rewrite needed.
- **`$` under MULTILINE differs on CRLF.** Python's `$` matches only before `\n`; JS's `m`-mode `$`
  also matches before `\r`, ` ` and ` `. The repo's `.gitattributes` sets no `eol`/`text`
  normalisation (it contains only two `merge=union` rules), so a consumer plugin checked out on
  Windows can legitimately carry CRLF. On a CRLF file the JS regex accepts one match position the
  Python one rejects. Low impact, but name it in a comment so the next reader does not re-derive it.
- The backticks inside the character classes are safe in a single-quoted shell word in **both** bash
  and PowerShell (neither treats a backtick as special inside single quotes), so the untagged fence
  stays valid. Do **not** switch to double quotes to "fix" them — that is what would break it.

**S6 — `p.suffix not in (".md", ".sh", ".ps1", ".js")` in #7 is now out of sync with the gate it
generalizes.** `.githooks/pre-commit` was extended to `.mjs` under ADR-017 — the dead-ref resolver
matches `agents/*.mjs|skills/*.mjs|shared/*.mjs|commands/*.mjs` at line 508, with the comment at
line 495 stating *"`*.js` does NOT glob-match `.mjs`, so the .mjs row is required"*. #7 claims to
generalize that hook and does not include `.mjs`. **Add `.mjs` to the suffix list in the port.**
(Note also that the hook's own header comment at `.githooks/pre-commit:33` still lists the old
scope — that is a separate stale-comment defect in a file outside wave 1's scope; recorded here only
so it is not mistaken for evidence that the gate was never extended.)

**S7 — `rglob("*")` → recursive walk.** #7 uses `base.rglob("*")` then filters by suffix. Python's
`rglob` yields directories as well as files and does not follow symlinked directories.
`readdirSync(dir, {recursive: true, withFileTypes: true})` matches on the symlink axis and needs an
explicit `isFile()` filter for the directory axis (the suffix filter mostly covers it, but a
directory named `foo.md` would reach `readFileSync` and throw `EISDIR`). Requires Node 20.1+ for
`recursive`; ICON's floor is Node 22 (`icon-status/SKILL.md:163-164`), so that is safe.

**S8 — the quoted heredoc is what made these blocks apostrophe-safe, and `node -e '…'` is not.**
This is ICON-0097's retrospective (`.context/retrospectives.md`, *"a language port can regress on
quoting while getting the logic right"*) and it is the exact same file being touched again.
**Assessment for these four blocks specifically: no value is interpolated into any program body** —
all four read their inputs from disk at runtime. So Rule 9's hazard does not bite *through
substitution*. It bites through **literal apostrophes in the program source**, which is trigger 4's
territory and is handled above. Both directions must be checked; neither may be assumed.

**S9 — `p.read_text()` encoding.** Python's `read_text()` without an encoding uses the locale
default on Python ≤ 3.14. These files contain `—`, `≥` and other non-ASCII. `readFileSync(p,
"utf8")` is unambiguous and strictly better. No action; noted so the diff's behaviour change is
understood rather than discovered.

#### The borderline call — #4/#5 (the CHANGELOG check)

`grep -q '^## \[Unreleased\]' CHANGELOG.md && echo "OK" || echo "MISSING [Unreleased]"` is 85 B and
ADR-017's Trivial section observes that migrating a trivial block *"costs a file, an invocation
preamble, a runtime guard and a degradation path to save 87 bytes."* The resemblance is close enough
to be worth answering directly.

**Resolved to Deterministic and migrated. Three grounds, and the cost sentence does not apply.**

1. The quoted cost is the cost of a **`.mjs`**. An inline `node -e` costs no file, no preamble, no
   guard and no degradation path. The trade the ADR is warning against is not the trade on offer.
2. It **is** control flow, and a Node rewrite does **not** shell out — `readFileSync` plus
   `/^## \[Unreleased\]/m.test(...)`. It fails the Trivial test's headline and its "no control flow"
   clause.
3. **It is a live parity twin and migration is the only thing that retires it.** #4 and #5 are not
   byte-identical, so ADR-017's retagging path is unavailable — the twin only dies by being ported.
   Two blocks become one untagged fence.

A fourth reason, sufficient on its own to justify rewriting the block regardless of tier: **the
current block loses an outcome the check is specified to produce.** `audit-phase-structure.md:17`
specifies check 7 as *"`CHANGELOG.md` **exists** and contains an `## [Unreleased]` block"* — two
conditions. `grep -q` on a missing file exits 2, so the `||` branch fires and the block prints
`MISSING [Unreleased]` for a plugin that has **no CHANGELOG at all**. The port must emit three
distinct outcomes: file absent, file present without the block, file present with the block.

---

### Site B — `skills/icon-status/SKILL.md`

#### Inline `node -e` or committed `.mjs`?

**Inline `node -e` for all ten blocks. Trigger 1 fires and is cured; no other trigger fires.**

| Trigger | Verdict |
|---|---|
| 1. State crosses a fence boundary | **Fires today, on three chains** (below). **Disposition: cure it, do not accommodate it.** |
| 2. It mutates state | **No.** Every block is a read: `git`, `find`, `grep`, `readFileSync`, `stat`. `icon-status` writes nothing. |
| 3. Invoked ≥ 2× with different arguments | **No.** Ten distinct one-shot probes. |
| 4. Literal `'` required | **No.** The blocks' string content is plain. `grep -oE '[A-Z]+-[0-9]+'` and `'*.md'` become JS regexes and string literals with no apostrophes. |

**The three chains, verified by reading the file:**

| Chain | Set at | Read at | Status today |
|---|---|---|---|
| `BRANCH`, `TASK_ID` | `:59-60` (fence #13) | `:70` (#14), `:187` (#22) | Unset in the consumers |
| `PLAN_FILE` | `:73` (#14) | `:187` (#22) | Unset in the consumer |
| `ICONRC_STATE` | `:120`, `:126` (#17) | `:178`, `:180` (#21) | Unset in the consumer |

Claude Code's Bash tool contract states that the working directory persists between calls but
**shell state (env vars, functions) does not**. Unless the agent happens to paste several fences
into one invocation, `$TASK_ID`, `$PLAN_FILE` and `$ICONRC_STATE` are all empty at their read sites,
which means **the `plan.md` lookup, Suggestions signal 3 and Suggestions signal 4 never fire.** This
is not a hypothetical: it is ADR-017 trigger 1's stated rationale — *"Fences are independently
runnable and nothing enforces their order, so this is a latent correctness bug whichever language it
is written in"* — observed live.

**Why the cure rather than a `.mjs`.** Trigger 1's condition is literally *"a variable set in one
fence is read in another."* Make each fence re-derive what it needs and the condition is **false**,
not evaded — the correctness bug the trigger exists to detect is gone, which is a strictly better
outcome than a `.mjs` that merely internalises it. The re-derivation cost is one extra `git
rev-parse` and one extra 200-byte JSON read per run. Against that, a `.mjs` would cost a new file, a
`${CLAUDE_SKILL_DIR}` invocation fence, a four-line Copilot path-reconstruction fence, a `node -v`
prose precondition, an outcome table, and gate-scope maintenance — for a skill whose entire job is
to print a dashboard. ADR-017 is explicit that `.mjs` is *"the exception, not the target"* and
Alternatives 4 rejects reaching for it by default.

**Do not "cure" a chain by deleting the dependent behaviour.** Signal 4 needs `PLAN_FILE`, so its
fence must re-run the `plan.md` lookup; signal 3 needs the iconrc outcome, so its fence must re-read
`.context/iconrc.json`. Dropping the dependency and the behaviour together would turn a latent bug
into a silent feature removal.

**Recommended fence layout after migration** (six untagged `node -e` fences; the `###` headings and
their prose stay exactly where they are, so the document's structure is unchanged):

| Fence | Absorbs | Self-contained because |
|---|---|---|
| Step 1 guard | #10 | Never depended on anything |
| Repo name | #12 | Never depended on anything |
| Branch + task + plan | #13, #14 | Two adjacent fences under one topic; the `TASK_ID`→`PLAN_FILE` hop becomes intra-program |
| Retrospectives | #15 | Never depended on anything |
| Context health | #16 | Never depended on anything |
| iconrc version | #17 | Never depended on anything |
| Signal 1 | #19 | Never depended on anything |
| Signal 3 | #21 | **Re-reads `.context/iconrc.json`** instead of reading `$ICONRC_STATE` |
| Signal 4 | #22 | **Re-derives `TASK_ID` from the branch and re-runs the `plan.md` lookup** |

Merging #13+#14 is a genuine merge (they sit under one `###` heading, `:56` "Current branch and
active task", separated only by three lines of prose at `:65-67`). #21 and #22 stay where they are
under `### Suggestions`; only their inputs change. **Do not merge #21 or #22 into the blocks that
currently feed them** — that would move Suggestions logic out of the Suggestions section and damage
the document.

#### Node-absent degradation path — **READY. A real one exists and is quotable.**

`icon-status:140-142`:

> "Report the version string on the dashboard's `Node` line. **Read the output, not the exit
> status** — PowerShell leaves `$LASTEXITCODE` stale when a command is not found. If the output is a
> not-recognized / command-not-found message rather than a version, record `Node: not found`."

`icon-status:163-174` (Suggestions signal 2):

> "**Signal 2: Node absent, or below ICON's supported floor.** Read from the `node -v` probe above.
> … If `node` was not found, or the major version is below 22, add: `- Node runtime <not found | …>
> — invoke check-node-runtime for the install and version guidance.`"

`icon-status:117-123` and the section rule at `:236`:

> "`iconrc.json` line | Never omitted — report the version, `not found`, or `(unreadable)`. A blank
> after 'version' is indistinguishable from a healthy read."

**Precise scope of that path, stated so it is not over-claimed.** It covers **two dashboard lines**
— the `Node` line and the `iconrc.json` line — plus one Suggestions entry. It does **not** cover
Step 2's other five data-gathering topics, which are bash today and would fail on a Node-absent box
after migration where they currently succeed.

**Assessment.** For the inline `node -e` disposition this is sufficient and the site is ready:
ADR-017 imposes no guard on inline `node -e` (see Site A's treatment of the same question), and
`icon-status` already reads `.context/iconrc.json` through a nested `node -e` at `:108`, so it
already fails partially without Node.

**Non-blocking but worth the coder's attention**: after migration, Node absence takes the whole
dashboard rather than two lines of it. `icon-status:132` already states the stakes — *"ICON's
session-start hook is a Node script, so a missing `node` silently costs the manager role"* — so a
Node-less ICON is already non-functional and a dashboard that reports that fact is arguably the
correct output. **Widening the existing path to cover the whole dashboard would be inventing one,
which ADR-017 forbids as part of a migration.** Flag it for the manager; do not do it here.

#### Prose-contract survival

- **`:43-45`** — *"Run each block below. Every block handles missing data gracefully — if a file or
  directory is absent, emit a 'not found' note rather than empty output."* This is the contract for
  all of Step 2 and it must survive verbatim in force. Every port must honour it, which in Node
  means catching `ENOENT` rather than letting `readdirSync`/`readFileSync` throw.
- **`:114-116`** — the three-line comment on the iconrc empty-capture guard (*"An empty capture must
  never reach the dashboard as a value: 'version ' with nothing after it reads as a healthy line"*).
  This is a hard-won invariant. It must survive as **prose**, not merely as a line of JavaScript, and
  the ported program must still implement it.
- **`:228-238`** — the Section rules table, especially the two "Never omitted" rows. Unchanged, but
  the ports must keep satisfying it.
- **`:65-67`** — the `main`/`dev`/`master` branch rule. This is *agent* logic, not block logic, and
  it must stay in prose exactly as it is; do not absorb it into the branch fence.
- **New, required**: a lead-in for each newly untagged fence saying "run this" (ADR-017's
  untagged-fence disambiguation obligation). `:23-24` of `audit-phase-structure.md` and `:133-135`
  of `icon-status` itself are both usable models.
- **New, required**: for each fence whose inputs changed from inherited to re-derived (signals 3 and
  4), one sentence saying the block is now independently runnable and why. That sentence is the
  documentation of the bug fix, and without it the change looks like gratuitous duplication.
- **New, recommended**: an outcome line per fence — what its stdout looks like and what the agent
  does with it. Several fences currently emit `KEY=value` lines with no stated contract.

#### Semantics to preserve (Rule 10) — extract with `git show HEAD:skills/icon-status/SKILL.md`

**S10 — #16 is wave 1's Rule 10 exhibit, and it needs two different Node idioms in one block.**

```bash
for d in domains standards workflows architecture testing styling; do
  if [ -d ".context/$d" ]; then
    COUNT=$(find ".context/$d" -maxdepth 1 -name '*.md' -type f | wc -l)
```

| Construct | Behaviour | Faithful Node port |
|---|---|---|
| `[ -d ".context/$d" ]` | **Follows** symlinks/junctions | `statSync(p).isDirectory()` — **not** `lstatSync`, **not** a `Dirent.isDirectory()` |
| `find … -name '*.md'` | **Matches** leading dots (Rule 10 states this explicitly for `find`) | Plain suffix/glob match with **no** dot exclusion |
| `find … -type f` | Does **not** follow symlinks | `Dirent.isFile()` — the equivalence here **is** real (Rule 10) |

`[ -d ]` follows links and `-type f` does not, **in the same six-line block**. This is verbatim Rule
10's *"Two probes in one script can need two different Node idioms"*, and it is the same shape as
the ICON-0098 defect that produced the rule. Using `readdirSync(…,{withFileTypes:true})` for both
inverts the first probe. Build the differential fixture so the divergent element is **decisive** —
a `.context/domains` reached through a junction, and a `.hidden.md` that changes a count from 0 to 1
— per Rule 10's *"a passing fixture set does not discharge this"*.

Same three constructs recur in **#19** (`.context/domains` presence + count) and the `-type f`/dot
axis in **#14**. All three must be ported consistently.

**S11 — `find -maxdepth 2` in #14 is a depth budget, not a glob.** `find .context/tasks -maxdepth 2
-name "plan.md" -path "*${TASK_ID}*"` matches `.context/tasks/plan.md` (depth 1) **and**
`.context/tasks/<dir>/plan.md` (depth 2). `-name` matches leading dots. `-path` is an fnmatch over
the **whole path as `find` prints it** (i.e. beginning `.context/tasks/…`), so `*ICON-0099*` can
match on the directory component *or* on `.context/tasks` itself if a task ID ever appeared there.
`head -1` takes the first in `find`'s traversal order, which is **directory order, not sorted** —
`readdirSync` order is likewise unsorted but need not agree. If a repo has two matching plan files
the two implementations may pick different ones. **Sort explicitly in the port and say so** — that
is a deliberate improvement over an unspecified original, not a silent behaviour change.

**S12 — `find "$PLAN_FILE" -maxdepth 0 -mmin +2880` in #22.** GNU `find` computes the age in whole
minutes and truncates, so `+2880` is true when `floor(age_minutes) > 2880`, i.e. at **2,881
minutes**, not at 2,880. A naive `(Date.now() - mtimeMs)/60000 > 2880` fires up to one minute early.
Sub-minute divergence on a 48-hour threshold — harmless in effect, but it is exactly the kind of
"looks equivalent" mapping Rule 10 is about, so match it or write down that you chose not to. Also:
`-mmin` is a GNU/BSD extension, not POSIX — one more reason the block is not portable today.

**S13 — `2>&1 | grep -v "^fatal"` / `grep -v "^find:"` appears in #12, #14 and #22.** This merges
stderr into stdout and then filters the merged stream by a message prefix — the exact anti-pattern
ADR-017 forbids for migrated code (*"prints its result to stdout, its diagnostics to stderr, and
never merges the two"*). It is also fragile: it depends on git's and find's **English** error text.
The port replaces it with `try`/`catch` around `execFileSync` and an `existsSync` guard. **This is a
real improvement, and it changes behaviour**: a git error message that does not begin with `fatal`
currently leaks into `$REPO_NAME`. Note the change; do not present it as a pure port.

**S14 — `git remote get-url origin | sed 's|.*[/:]||' | sed 's|\.git$||'` in #12.** Greedy `.*[/:]`
takes everything up to the **last** `/` or `:`. The Node equivalent is
`url.replace(/^.*[/:]/, "").replace(/\.git$/, "")` — note `.*` is greedy in JS too, so this one
transfers cleanly. `[ -z "$REPO_NAME" ]` after the pipeline catches both the no-remote and the
not-a-repo cases; the fallback chain has **three** rungs (remote → toplevel basename → `(unknown)`)
and all three must survive.

**S15 — `grep -oE '[A-Z]+-[0-9]+' | head -1` in #13.** `grep -o` prints **every** match on every
line, one per line; `head -1` takes the first. On a branch name `feature/ICON-0099-migrate-…` the
first match is `ICON-0099`. JS: `str.match(/[A-Z]+-[0-9]+/)` returns the first match — equivalent.
But note POSIX `[A-Z]` is locale-dependent in some `grep` builds while JS `[A-Z]` is always ASCII;
prefer the ASCII reading, which is what the task-ID convention means.

**S16 — `wc -l` output padding.** `COUNT=$(find … | wc -l)` — **BSD/macOS `wc` left-pads with
spaces**, and `$COUNT` is then interpolated into `echo "  .context/$d/ — $COUNT files"`, producing
`.context/domains/ —        7 files` on macOS. A cosmetic defect the port removes for free. The
`-eq` comparison in #19 tolerates the padding, so only the display line is affected.

**S17 — `head -3` in #15 is first-three-in-file-order.** `.context/retrospectives.md` is
newest-first (the `.gitattributes` comment states entries are prepended), so "first three" **is**
"most recent three". The port must take the first three matches in file order — **not** sort, and
not take the last three. Reversing this is an easy and invisible mistake.

**S18 — `[ -f ]` vs `existsSync`.** #15 and #17 both guard with `[ -f "…" ]`, which **follows
symlinks and requires a regular file**. `existsSync` follows symlinks but does not check the type;
`statSync(p).isFile()` is the faithful pair. Immaterial for these two paths in practice, named for
consistency with S10 — the point of Rule 10 is that you check rather than assume.

**S19 — the nested `node -e` at `:108-113` is already correct and is the model.** It writes the
value to `process.stdout` and the diagnostic to `process.stderr`, never merging them. Preserve that
discipline when the surrounding bash is absorbed.

---

### Site C — `.claude/skills/icon-audit/SKILL.md`

#### Inline `node -e` or committed `.mjs`?

**Inline `node -e`. No trigger fires.** `PRIOR_AUDIT` is set and read inside the same fence, and it
is the **only** fence in the entire skill directory — the six `briefs/*.md` and
`synthesis-template.md` contain zero fenced blocks, verified by scan. There is therefore no fence
boundary for state to cross. Nothing is mutated. It is invoked once. No apostrophe is required.

#### Node-absent degradation path — **NONE EXISTS. Stating it rather than inventing one.**

`icon-audit` has no Node-absent handling anywhere: no `node -v` probe, no fallback, no mention of
Node. Its only executable content is this one bash block. **Migrating it introduces Node as a
dependency of a skill that currently has none.**

Under the `.mjs` contract that would make the site not-ready. **It is not blocking here** for two
reasons, and both must hold or the disposition changes: (a) the disposition is inline `node -e`, for
which ADR-017 imposes no guard and no degradation path (Alternatives 4); and (b) the skill is
**maintainer-only** — it lives under `.claude/skills/`, does not ship to consumers, and runs in this
repo, whose `CLAUDE.md` already prescribes `node -e` as the manifest parse check. Its blast radius
is one maintainer on one machine.

**If anyone later proposes a `.mjs` for this site, the answer is not-ready** until a degradation path
exists — and none may be invented as part of that migration.

#### Prose-contract survival

**`SKILL.md:56-65`** is already the contract and is entirely outside the fence:

> "**Phase 1 output** — record in `plan.md` Decisions before dispatching Phase 2: Prior audit ID and
> date … Count of retrospective entries since baseline … Current counts: agents, skills, manifests …
> **If no prior audit exists**, record 'no prior audit — this is baseline run' and skip the Delta
> section in synthesis."

Nothing there needs rewriting. Two additions are required:

- The `# 1.1 … # 1.4` comments **inside** the fence carry the reasoning, and one of them is
  load-bearing: *"plain `sort` — not `sort -V` — for macOS BSD compatibility; correct because
  ICON-NNNN task IDs are zero-padded to ≥3 digits, so lexicographic sort matches numeric order."*
  **That justification is about a tool the port removes.** It must be **rewritten**, not carried
  across — the Node port sorts strings, so the surviving note is "lexicographic sort over
  zero-padded task IDs is numerically correct", with the BSD `sort -V` rationale deleted as no
  longer applicable. Copying it verbatim would leave a comment explaining a decision the code no
  longer makes.
- A "run this" lead-in for the newly untagged fence.

#### Semantics to preserve (Rule 10) — extract with `git show HEAD:.claude/skills/icon-audit/SKILL.md`

**S20 — `find … -name audit-report.md | sort | tail -n 1`** is a **lexicographic** sort over the full
found paths, deliberately (see the comment). `Array.prototype.sort()` with no comparator is also
lexicographic by UTF-16 code unit — close, and identical over the ASCII path characters in play.
`tail -n 1` is the **last** element. Do not substitute a numeric or `localeCompare` sort; both
change the documented behaviour.

**S21 — `-maxdepth 2` from `.context/tasks`** matches `.context/tasks/<task-dir>/audit-report.md`,
which is the real layout. Same depth-budget point as S11.

**S22 — `wc -l <file>` on a missing file prints an error and exits non-zero, unguarded.** `wc -l
.context/retrospectives.md` and `wc -l CHANGELOG.md` have no `[ -f ]` guard. In a repo missing
either file, Phase 1 currently emits a `wc:` error into the agent's transcript and the count is
absent. `readFileSync` throws `ENOENT` in the same situation — **do not let it**; report
`(not found)` and keep going, per the same "handle missing data gracefully" principle Step 2 of
`icon-status` states explicitly. This is a fix, so say so.

**S23 — `ls agents/ | wc -l` excludes dot-entries; `readdirSync` does not.** `ls` without `-a`
suppresses leading-dot entries, and `wc -l` counts lines because `ls` is one-per-line when not
attached to a tty. `readdirSync("agents").length` **includes** dot-entries. Same class as S4; filter
explicitly. Also: `ls` on a missing directory errors to stderr and `wc -l` reports `0`;
`readdirSync` throws. Guard it.

**S24 — the manifest count** `find . -maxdepth 3 -name 'plugin.json' -type f -not -path './.context/*'
-not -path './.git/*'`. Three constraints to reproduce exactly: depth ≤ 3 from `.`, `-type f`
(does not follow symlinks — `Dirent.isFile()` is the faithful pair per Rule 10), and the two path
exclusions matching on the printed `./…` form. A recursive `readdirSync` walk must apply the
exclusions **before** descending, or it will walk `.git` — which is slow and can surface a stray
`plugin.json` in a packed object path.

---

## Recommended implementation sequence

**1. `skills/plugin-design/audit-phase-structure.md` + `audit-phase-consistency.md` — first, together, one commit.**

- It is the only **live bug** in wave 1: four checks that do not execute on Windows at all, two of
  which have no Windows implementation of any kind. Everything else in wave 1 is a refactor with a
  correctness dividend.
- It closes ICON-0097's sweep: these are the last four live `python3` invocations in the repo, and
  leaving them means the "python3 is not an assumed runtime" rule has four standing exceptions.
- The two files must move together: they are Phase 1 and Phase 2 of one audit run, they share the
  frontmatter-parsing fidelity decision (S1), and the three `agents/`+`skills/` walks (#2, #6, #9)
  must agree with each other on S3 and S4. Splitting them across commits invites two answers to one
  question.
- **Highest risk in wave 1** — do it while attention is freshest. S1 (folded scalars) and S2 (split
  semantics) each have a 100%-false-positive failure mode, and both are invisible to a diff review.

**Gate before moving on**: run each ported check against this repo and assert **zero** findings on
59 files. Any non-zero count is S1 or S2 firing. Also run each against a synthetic plugin with **no
`agents/` directory** — that is S3, and it is the one that crashes rather than mis-reports.

**2. `skills/icon-status/SKILL.md` — second.**

- Largest block count (10) and the only site with a structural change beyond a language swap (the
  cross-fence cure). It benefits from the plugin-design work having already settled the house style
  for an untagged `node -e` fence and its lead-in prose.
- It carries the wave's clearest Rule 10 trap (S10) — the same shape as the ICON-0098 defect. Doing
  it after a site where the Rule 10 discipline has already been exercised reduces the chance of
  repeating that class.
- Its three dead signals are a real bug, but a *silently degraded dashboard* is a lower-severity
  failure than *an audit phase that cannot run*, which is why it is second and not first.

**Gate before moving on**: run every ported fence **individually, in a fresh shell each time**, and
confirm signals 3 and 4 produce output — that is the whole point of the cure and it is the one thing
a combined run would hide.

**3. `.claude/skills/icon-audit/SKILL.md` — last.**

- One block, maintainer-only, not shipped, zero consumer impact. Its migration buys consistency plus
  three small robustness fixes (S22, S23, S24) and nothing else.
- It is the only wave-1 site that **introduces** a Node dependency rather than removing a `python3`
  one or replacing bash that already nests Node.

**Drop condition, stated so the decision is pre-made rather than improvised**: if wave 1 runs long,
or if the plugin-design fidelity decision (S1) turns out to need a design round-trip, **drop
`icon-audit` from this task and re-ticket it.** Grounds: it is the only wave-1 site with no
user-visible defect and no shipped surface, so deferring it costs nothing that a later task cannot
recover, whereas rushing sites 1 and 2 costs correctness on content that ships. Do **not** drop it
merely to save time if sites 1 and 2 land cleanly — one fence is a small tail.

**Nothing else in wave 1 should be deferred.** All three sites are independent: no site's migration
changes a file another site reads, and none of the 24 blocks is shared with another skill.

### Ordering notes that apply across all three

- **Per-site commits, not one wave-1 commit.** Each site is independently revertable and the
  plugin-design half is a user-facing bug fix that may want to move to a release on its own timing.
- **No `.githooks/pre-commit` change is required by wave 1.** No block becomes a `.mjs`, so no gate
  scope moves; and no wave-1 block is duplicated into another skill, so the byte-parity population
  is untouched. (The `.mjs` rows already exist in the dead-ref and cap-literal gates from ICON-0098 —
  lines 508 and 543 — so nothing is missing there either.)
- **`CHANGELOG.md`**: one `[Unreleased]` entry. The plugin-design fix is user-facing and warrants
  efficient rather than terse phrasing; `icon-status` and `icon-audit` are internal.

---

## Cross-skill duplication — wave-2 boundary check

The scope boundary requires flagging, without disposition, any wave-1 block also copied into another
skill. Distinctive fragments of every wave-1 block were grepped across `skills/`, `.claude/skills/`,
`agents/`, `commands/` and `shared/`:

| Block | Result |
|---|---|
| #18 `node -v` (`icon-status:136-138`) | **Duplicate found** — byte-identical to `skills/check-node-runtime/SKILL.md:32-34`. **Flagged, no disposition taken.** It is E2-excluded (it *is* the invocation contract's guard) and 7 bytes long, so it is not a migration candidate under any wave, but the manager should confirm it is not swept into wave 2's copy-set by a byte-similarity search. |
| #17 iconrc `version` read | **Not a duplicate.** `skills/upgrade-repo/SKILL.md:1290-1291` reads the same field of the same file, but via `grep '"version"' \| grep -oE '[0-9.]+'` — a different implementation. The comment at `icon-status:114` (*"same shape as upgrade-repo on this same field of this same file"*) refers to the **empty-capture guard's shape**, not to shared code. `upgrade-repo` is out of scope (#61) and stays untouched. |
| All other 22 blocks | **No duplicates.** `NOT_INITIALIZED`, the six-name context-health loop, the retrospectives `head -3`, the four `python3` heredocs and their PowerShell twins, and the `icon-audit` Phase 1 block each appear exactly once in the tree. |

**Conclusion: wave 1 and wave 2 do not intersect.** Wave 1 can proceed without waiting on the
parallel wave-2 agent, and no wave-1 block needs to be held back under ADR-017's
"whole set or not at all" rule.

---

## Corrections to inputs

Recorded so they are not silently absorbed.

1. **`icon-status` has 10 deterministic blocks, not 9.** Issue #59 and `plan.md:26` count Step 2's
   nine and miss the Step 1 fresh-repo guard at `SKILL.md:29-31`.
2. **The Node-absent degradation-path gate does not bind wave 1.** `plan.md:45` carries it as an
   open question against all migrated skills. It is part of ADR-017 § The invocation contract, which
   governs committed `.mjs` files; the Deterministic row's test column and Alternatives Considered 4
   both state that inline `node -e` carries no runtime guard and no degradation path. Every wave-1
   disposition is inline, so the gate is not engaged. Each site's path is reported above anyway.
3. **`plan.md:51`'s "never `require`" is a `.mjs` rule and must not be applied to inline
   `node -e`.** ADR-017 § Node floor scopes it: *"`.mjs` is ESM… and `.mjs` has no `require`
   anyway."* An inline `node -e` program runs as CommonJS, has no `import` without
   `--input-type=module`, and **must** use `require("fs")`. Every shipped precedent does —
   `audit-phase-structure.md:28`, `icon-status:109`, `plugin-design/create-phase-basic-info.md:94`,
   `create-phase-boilerplate.md:137`. A coder applying the `.mjs` rule to an inline block will
   produce a program that does not run.
4. **The four `python3` line numbers in the ticket are correct** (`audit-phase-structure.md:42`;
   `audit-phase-consistency.md:19, 53, 110` — the `python3` line in each case, with the fence opening
   one line above). No drift. All other line numbers in this document were read off the live files.

## Adjacent observations — out of scope, not dispositions

Recorded because they were found while reading, not because wave 1 should act on them.

- `audit-phase-structure.md` check 2 (*"`plugin.json` declares `$schema`"*) has **no validation
  snippet**; the block at `:26` implements checks 1 and 3 only. A gap in the file, unrelated to
  migration.
- The `node -e` at `:26` conflates a `plugin.json` **parse** failure (check 1) with a **missing
  field** (check 3): `JSON.parse` throws and the stack trace is the check-1 signal. Pre-existing.
- `skills/plugin-design/audit-mode.md:16-24` and `:30-38` are a `bash`/`powershell` precondition twin
  pair. **Not in this dispatch's scope**, and the manager should decide whether it belongs to wave 2
  or to a follow-up — it is in `plugin-design`, so it is adjacent to site A, but the dispatch names
  only the two `audit-phase-*` files.
- `.githooks/pre-commit:33`'s header comment lists the dead-ref scope as `.md, .sh, .ps1, .js` while
  the implementation at `:504-509` includes `.mjs`. Stale comment; separate file, separate concern.
