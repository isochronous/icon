# ADR-017 correction: designing the program-vs-command trigger

**Task**: ICON-0099 (#59) · **Phase**: architecture (inserted on maintainer re-open)
**Date**: 2026-08-01 · **Author**: @architect · **Status**: proposal for manager

Read-only design pass. Nothing outside this file was modified; `git status --short` was clean at
dispatch and no repo file was written.

---

## Measurements this design rests on

Every number below was measured on this host at `HEAD` = `ae5ad33`, from committed blobs where a
byte count is stated. Site enumeration was done by a fence parser over every `.md` under the repo
excluding `.git/`, `node_modules/`, `.context/` and `.context/tasks/`, extracting the body of each
`node -e '…'` occurrence.

| Quantity | Measured | Warmstart said |
|---|---|---|
| Inline `node -e` sites, shipped (`skills/`) | **21** | 21 ✔ |
| Plus maintainer-only (`.claude/skills/icon-audit`) | **1** (22 total) | 22 ✔ |
| Program-body bytes, 22 sites, raw | **23,271 B** | — |
| Program-body bytes, 21 shipped, raw | **18,128 B** | 14,842 B ✘ |
| Program-body bytes, 21 shipped, comment lines removed | **14,545 B** | 14,842 B (≈) |
| Largest single program, shipped, raw | **2,943 B** (`audit-phase-consistency:127`) | — |
| Largest single program, shipped, comments removed | **2,129 B** (`audit-phase-consistency:214`) | 2,067 B (≈) |
| Largest program overall | **5,143 B** (`icon-audit:57`) | — |
| Sites predating the task (at merge-base `1b8d651`) | **8** | 8 ✔ |

**Reconciliation of the two divergences.** The warmstart's `14,842 B` and `2,067 B` are
comment-stripped measurements of the 21 shipped sites, taken at a commit earlier than `ae5ad33`
(the two nearest current variants are 14,545 B and 2,129 B). The warmstart's *file* sizes
(18,534 / 17,580 / 11,245) reproduce exactly at `HEAD`. Nothing here contradicts the re-open's
argument — the corpus is larger than stated, not smaller. **Use the raw figures.** Comment-stripping
is not a defensible unit: the comments in these programs carry the Rule-10 semantics notes that six
review rounds produced, and they ship, are read, and must be maintained like the code.

---

## 1. The trigger

### The body test

> **A deterministic block is a *program*, and belongs in a committed `.mjs`, if it has a body.**
>
> A **body** is either:
>
> - **B1 — a named callable the block declares and calls.** A `function` declaration, a *named*
>   function expression (including a named IIFE), or a function/arrow expression bound to a name.
>   An anonymous callback passed directly as an argument is **not** one.
> - **B2 — a braced body holding two or more statements.** The body of an `if`, `else`, `for`,
>   `while`, `do`, `switch` case, `try`, `catch` or `finally` that does more than one thing.
>
> **A block with no body is a *command*, and stays inline.**

The principle underneath both clauses is **one locus of control**. A command is read top to bottom
in a single pass: each branch does one thing, and nothing is named for later. A program has a second
locus — a callable the reader must jump to, or a branch that is itself a small procedure. That is
the property that makes a block cost a fixture to test and a careful pass to review, and it is the
property ADR-017's four triggers never ask about.

The four existing triggers survive unchanged as **overrides**: a block the body test calls a command
still becomes a `.mjs` if any of them fires. See § 1.4.

### 1.1 Classification of all 22 sites

Derived by reading every program, not by regex. `B1`/`B2` name the specific construct that fires.

| # | Site | B1 | B2 | Class | Bytes |
|---|---|---|---|---|---|
| 01 | `.claude/skills/icon-audit/SKILL.md:57` | `lineCount`, `countEntries`, `countManifests` | ✔ | **program** | 5,143 |
| 02 | `skills/icon-status/SKILL.md:55` | — | — | **command** | 185 |
| 03 | `skills/icon-status/SKILL.md:100` | `function git` | — | **program** | 435 |
| 04 | `skills/icon-status/SKILL.md:131` | named IIFE `scan` | `for` body, 2 stmts | **program** | 969 |
| 05 | `skills/icon-status/SKILL.md:170` | — | `if` body, 2 stmts | **program** | 412 |
| 06 | `skills/icon-status/SKILL.md:194` | — | `for` body, 5 stmts | **program** | 605 |
| 07 | `skills/icon-status/SKILL.md:223` | — | `try` body 2 stmts; `if`/`else` bodies 2 stmts | **program** | 891 |
| 08 | `skills/icon-status/SKILL.md:273` | — | `if` body, 2 stmts | **program** | 593 |
| 09 | `skills/icon-status/SKILL.md:313` | — | `if` body, 2 stmts | **program** | 569 |
| 10 | `skills/icon-status/SKILL.md:337` | named IIFE `scan` | `for` body, 2 stmts | **program** | 1,045 |
| 11 | `skills/initialize-workspace/SKILL.md:46` | — | `if` body, 2 stmts | **program** | 589 |
| 12 | `skills/plugin-design/audit-phase-consistency.md:43` | `ls`, `isFile` | ✔ | **program** | 1,889 |
| 13 | `skills/plugin-design/audit-phase-consistency.md:127` | `isDir`, `isFile`, `walk` | ✔ | **program** | 2,943 |
| 14 | `skills/plugin-design/audit-phase-consistency.md:214` | `ls`, `isFile`, `fm` | ✔ | **program** | 2,513 |
| 15 | `skills/plugin-design/audit-phase-structure.md:39` | — | `if` body, 2 stmts | **program** | 269 |
| 16 | `skills/plugin-design/audit-phase-structure.md:111` | `ls`, `isFile`, `fm` | ✔ | **program** | 2,480 |
| 17 | `skills/plugin-design/audit-phase-structure.md:185` | — | `catch` body, 3 stmts | **program** | 318 |
| 18 | `skills/plugin-design/create-phase-basic-info.md:54` | — | — | **command** → `.mjs` by **trigger 2** | 402 |
| 19 | `skills/plugin-design/create-phase-basic-info.md:75` | — | `if` body, 2 stmts | **program** (also trigger 2) | 404 |
| 20 | `skills/plugin-design/create-phase-basic-info.md:93` | — | — | **command** | 76 |
| 21 | `skills/plugin-design/create-phase-boilerplate.md:136` | — | — | **command** | 76 |
| 22 | `skills/plugin-design/create-phase-marketplace.md:20` | `empty` | `if` body, 2 stmts | **program** | 465 |

**Totals: 18 programs, 4 commands.** One command (18) is pulled to `.mjs` by trigger 2 (it rewrites
`.claude-plugin/plugin.json`). **Net: 19 → `.mjs`, 3 stay inline** — sites 02, 20 and 21.

Sites 20 and 21 are byte-identical (SHA-256 `1fd8448001a24dc9…`) and are the same idiom
`.claude/CLAUDE.md:18` documents as the manifest parse check. The surviving inline tier is exactly
"one-liners you would type at a prompt", which is a coherent tier, not a vestige.

### 1.2 Is any site borderline?

**No site is ambiguous in *applying* the test.** Recorded attempts to construct one:

- **A comma-operator dodge** — `if (x) { a(); b(); }` rewritten `if (x) (a(), b());` would read as one
  statement. **Searched the corpus: no comma-operator sequence exists in any of the 22.** The dodge
  is available to a future author; § 1.5 says what to do about it.
- **A named callable that is never called** — would satisfy "declares" but not "and calls". **None
  found**; every named callable in the 22 is invoked.
- **A nested body inside a named callable** — sites 12, 14, 16 have `const ls = (d) => { try {…}
  catch (e) { …3 stmts } }`, where B1 and B2 both fire. Not an ambiguity: they agree.
- **A single-statement branch whose one statement is huge** — site 02's `if (!isDir)
  process.stdout.write(…)`. Unambiguously bodyless.

**One site invites disagreement about the *outcome*, not the application: site 03.** `function git`
is a three-line `execFileSync` wrapper, and a reader could reasonably call the whole block "get the
repo name" — a command with a retry. The test says program, because the block resolves a name
through a three-level fallback chain and the reader must trace it. I would not overturn the test for
it, but it is the one call a competent author might argue, and it should be named in the record
rather than discovered later.

### 1.3 Why this test and not the other three

All four candidates were applied to all 22 sites.

| Candidate | Partition | Verdict |
|---|---|---|
| **A — "defines a function"** | 9 programs / 13 commands (strict: named callables only) | **Rejected alone.** Splits sites 15 and 22, which do the same job — validate required manifest keys — purely on whether the author hoisted an arrow into a `const`. **Gameable by inlining a lambda.** Under-inclusive: leaves site 06 (a 13-line loop) and site 07 (19 lines, nested error handling) inline. |
| **B — "control flow beyond a single guard"** | not computable without arbitration | **Rejected.** Requires deciding whether `try/catch` is a guard (site 02), whether a `.filter()` is control flow (sites 15, 22), and whether a `catch` containing a conditional rethrow is one guard or two (site 17). **Five arguable members**; the dispatch's own bar is three. |
| **C — "more than one statement"** | 20 programs / 2 commands | **Rejected.** Zero ambiguity, but over-inclusive: it converts site 02 (185 B, four lines, one `statSync` probe) at a fixed cost of a file plus an invocation contract — the exact complaint ADR-017's trivial test makes. It also empties the inline tier down to two identical one-liners. |
| **D — "declares bindings consumed later"** | 20 programs / 2 commands | **Rejected.** Same partition as C, and **gameable by inlining a binding**: `const d = JSON.parse(x); if (!d.name)` is a program, `if (!JSON.parse(x).name)` is a command, for no difference that matters. |
| **Body test (B1 ∨ B2)** | **18 / 4** | **Recommended.** Zero ambiguity in application. Fixes A's hoisting split (15 and 22 both fire B2) and D's inlining hole (collapsing a two-statement branch means doing less, not hiding more). |

**The test is not size in disguise — measured, not asserted.** The boundary crosses byte order in
both directions:

- Site **15 → program at 269 B**, while site **18 → command at 402 B**.
- Site **02 → command at 185 B**, while site **15 → program at 269 B**.
- The largest command (18, 402 B) is larger than two of the programs (15 at 269 B, 17 at 318 B).

A monotone byte threshold cannot reproduce this partition at any cut point. ADR-017 § *Disqualified*
and *Alternatives Considered* 1 both stand untouched and are, if anything, reinforced: this trigger
is available precisely *because* it needs no number.

### 1.4 Consistency with the surviving parts of ADR-017

**Ordering.** Classification (Judgement / Illustrative / Trivial / Deterministic) runs first,
unchanged. The body test then splits **Deterministic** into command → inline and program → `.mjs`.
The four triggers run last and can push a *command* to `.mjs`. Nothing reaches the triggers that the
Trivial row already excluded — `executable-content.md § Classification precedes trigger evaluation`
is preserved verbatim.

**Do the four triggers still do independent work?**

| Trigger | Independent under the body test? | Evidence |
|---|---|---|
| 1 — state crosses a fence boundary | **Yes.** It is a property of the *relationship between two fences*, which the body test cannot see. A bodyless one-liner assigning a shell variable another fence reads is still a latent bug. | Constructed, not measured — the corpus has no surviving instance (this task cured `icon-status`'s three chains). |
| 2 — it mutates state | **Yes, and demonstrated.** **Site 18** is bodyless — nine straight-line statements, no braces anywhere — and rewrites `plugin.json`. The body test alone would leave it inline. | **Measured, corpus member.** |
| 3 — invoked ≥ 2× in the same skill with different arguments | **Weakly.** No corpus member where it does independent work: sites 04 and 10 duplicate the same named `scan` walker inside `icon-status`, but both are already programs. Sites 20 and 21 are identical but take no arguments, so it does not fire. | Constructed only. |
| 4 — it cannot be single-quoted | **Yes.** A bodyless one-liner with a structurally required `'` is still undeliverable inline. | Constructed only. |

**Recommendation: keep all four.** Trigger 3 is the weakest and is the one to watch, but deleting it
is a second change to the same record for no measured benefit. **Do not add a fifth.** The body test
is not a fifth trigger — it replaces the Deterministic row's *default*, which is what makes this a
Decision change rather than a list extension.

**The trivial test and its converse** are untouched. They govern whether a *shell* block should be
Node at all; the body test governs where an already-Node block lives. No block reaches both.

**E1 and E2 exclusions** are untouched — they run before classification.

**§ Disqualified** is untouched and stays. See § 6 for the one place it becomes live.

**Alternatives Considered 4** ("migrate everything deterministic to `.mjs`") is **not** reversed. It
rejected migrating 78 blocks / 99,137 B, most of them shell. This changes the disposition of 19
already-Node programs. What *is* falsified is one clause of its stated grounds — *"inline `node -e`
already gets the portability win with none of that overhead"* — because the PS 5.1 measurement shows
inline does **not** get the full portability win. That falsification is the substance of the change
and belongs in the new record's Context.

### 1.5 The known gaming vector

An author can dodge B2 by collapsing a two-statement branch into a comma expression. Handle it the
way ADR-017 already handles trigger 4's escape hatch: state that rephrasing to dodge the
classification is a last resort, and that an author writing `(a(), b())` to avoid a body has
answered the question. No gate can check this; it joins the three obligations ADR-017's Consequences
already lists as author-honoured.

---

## 2. Amendment or supersession

**Recommendation: scope-supersede. A new ADR-018, scoped to two coupled sub-decisions — the
Deterministic row's default, and the invocation contract's Node-presence obligations (§ 4.0).**

### 2.0 ADR-018 carries the § 4.0 correction too — it is not separable

**They must land together or ADR-018 is inert.** ADR-018 makes `.mjs` the default for programs; the
unamended precondition then blocks 12 of the 19 conversions that flip creates. A record that
prescribes a disposition its own neighbour forbids is worse than either half alone.

They are also the **same thesis**, which is what makes one ADR right rather than two. Both defects
are *a rule filed against delivery mechanism when the hazard is not mechanism-specific*: the four
triggers ask about fence-local correctness when the question was program-vs-command; the
degradation-path precondition gates `.mjs` on a Node-absence exposure measured identical for both
forms. ADR-018's Context states that once and derives both corrections from it.

This does **not** change the amend-vs-supersede answer. Coupled sub-decisions decided differently,
the rest of ADR-017 standing, is still row 2 of the table — one scope-supersession, not several
records. The bold-field widens accordingly:

`**Superseded-by**: ADR-018 (Deterministic-row default, the Node-presence obligations, and the
Copilot path reconstruction — the four tiers, the four triggers, § Disqualified and the rest of the
invocation contract all stand)`

**Three clauses, one thesis.** The Copilot hardening (§ 3.5) joins the scope for the same
land-together reason as § 4.0: ADR-018 multiplies Copilot fences from 2 skills to 6, so shipping it
without the hardened reconstruction would knowingly widen an unverified surface using a slug this
machine already contradicts. It is a consequence of this decision, not a separate one.

Edited in place as standard text, not superseded:
`executable-content.md § The Invocation Contract` — step 1 (the guard, now
`check-node-runtime`-based and applying to both dispositions), its `:141` *"Do not invent one"* line
(deleted), and step 3 (the hardened Copilot fence). Also
`domains/plugin-resource-paths.md`, whose skill-level Copilot pattern is the naming form § 3.5
replaces, and which should record the observed `icon-local` counter-example.

Argued against `skills/context-document-guidelines/correcting-a-stale-adr.md`:

**The deciding question is "did the position change, or only the world it described?"** The position
changed. Every measurement ADR-017 made is still true — 164 blocks, 126,041 B, the 78/59 split, the
`.gitattributes` copy-set. What changed is which of two homes is the default, on evidence ADR-017 did
not have. That rules out **row 1 (amend in place)**, which is reserved for "a supporting fact, a
consequence, or a rejection's stated grounds — the Decision still holds".

**Row 2 matches literally.** "One sub-decision is now decided differently; the rest stands." The
sub-decision is the Deterministic row's default. The rest of ADR-017 — the four-tier table's other
three rows, § Disqualified, the invocation contract, the Node floor, the two exclusion axes, the
trivial test, the shared-set rule, the cap-evasion axis, and the ADR-005 / ADR-016 relationships —
stands entirely and is cited by the new record rather than restated.

**Row 3 (full supersede) is wrong** and the guidance says so directly: *"Do not supersede an ADR
whose Decision still stands."* Most of ADR-017's Decision stands, it is cited as the live rule by
`rules-index.md:49`, `executable-content.md`, `shell-portability` Rule 11 and `ROADMAP.md:110`, and
freezing it would strand all of them.

**Three further reasons the middle row is right here, not just literally applicable:**

1. **ICON has a worked precedent with this exact shape.** ADR-014 → ADR-015 is a scope-supersession:
   `014` carries `**Superseded-by**: ADR-015 (inline-agent carve-out — the remainder stands)` and
   **kept `**Status**: Accepted`**; `015` carries the mirrored scoped field. Reproduce that shape.
2. **ADR-017's `## Amendments` section cannot carry this.** It already holds two entries from this
   task, and both open by asserting *"The Decision has not changed."* A third entry saying the
   Decision *has* changed would contradict its own section's established reading. The guidance's
   proportionality rule points the same way: amendments are for load-bearing *corrections*, not for
   reversing the operative rule.
3. **The deliberation deserves preserving, not compressing.** ADR-017's inline default was correct on
   its evidence — the overhead argument in Alternative 4 is sound, and it is why sites 02, 20 and 21
   still stay inline. It was defeated by evidence that arrived afterwards: a measured PS 5.1 defect
   and a diagnosed gap in the trigger list. That is what a new ADR records. An `## Amendments` bullet
   would flatten a real change of mind into a correction.

**The one real cost, and its mitigation.** Scope-supersession leaves *"inline `node -e` is the
default"* as live text in a heavily-cited record. Two mitigations, the first from the precedent and
the second slightly beyond it:

- The `**Superseded-by**` bold-field sits at **line 6**, before any prose, and carries the scope
  inline — a reader knows which part is superseded before reading the Decision. Suggested text:
  `**Superseded-by**: ADR-018 (Deterministic-row default only — the four tiers, the triggers, the
  invocation contract and § Disqualified all stand)`.
- Add a **one-line pointer inside the Decision's tier table row itself**, directing to ADR-018.
  ADR-014 did not do this. It does not edit the decision — it is navigation — but flag it to the
  maintainer as a deliberate extension of the precedent rather than a silent one.

**What moves with the ADR.** `.context/standards/skill-decomposition/executable-content.md` is the
operative file authors read, and it is a **standard, not an ADR** — it is edited in place, no
supersession machinery. Its Rule table's Deterministic row, its § *The Four Triggers* preamble and
its `Governed by:` footer all change. `.context/rules-index.md:49` needs its ADR-017 row updated.
`shell-portability` Rule 11's framing (*"the hazard attached to ADR-017's default disposition"*)
becomes stale the moment the default flips and needs re-pointing.

---

## 3. The Copilot CLI exposure

**Short answer: I could not verify it, I established why, and the blast-radius reduction is real and
is the main reason to prefer the narrow scope in § 4.**

### 3.1 Verification — attempted and blocked

| Probe | Result |
|---|---|
| `command -v copilot` | not on `PATH` |
| `gh extension list` | empty — no extensions installed |
| `~/.copilot` contents | exists, holds **only** `ide/d57d9c7b-….lock`. **No `installed-plugins/` directory.** |
| `COPILOT_HOME` | unset |
| `npm ls -g --depth=0` | empty |

**Neither of ADR-017's two settling tests can be run in this environment.** Copilot CLI is not
installed and installing it is outside a read-only design dispatch. The `"designed for and untested"`
language must carry forward verbatim into ADR-018 — not softened, and now with a recorded failed
attempt attached.

### 3.2 What *was* verified, and it is not nothing

The Claude Code half of the contract's central premise — *a plugin-shipped `scripts/` directory
materialises on disk at install time and Node can execute a file from it* — **is confirmed on this
host.** ICON is installed locally under Claude Code, and three shipped `scripts/` directories are
present in the install tree:

```
~/.claude/plugins/cache/icon-local/ICON/1.22.0/skills/context-maintenance/scripts/
  append-retrospective-entry.ps1   append-retrospective-entry.sh   check-rules-index.sh
```

`node -e 'fs.statSync(p)'` against `…/check-rules-index.sh` returned `isFile: true, size: 6556`. The
install is v1.22.0 against the repo's 2.0.0, which is why `skills/icon-init/scripts/` is absent there
— staleness, **not** a shipping failure. `scripts/` directories ship.

### 3.3 Two new pieces of evidence *against* the reconstructed path

Both surfaced from the local install and neither is in ADR-017 today.

1. **The hard-coded slug is wrong for at least one real installation — this one.** The Copilot fence
   defaults `MARKETPLACE_NAME="icon-marketplace"`. This machine's marketplace directory is
   **`icon-local`**. ICON already documents the `MARKETPLACE_NAME` override
   (`find-context-template/SKILL.md:16-26`), so this is not a new defect — but it upgrades the slug
   risk from hypothetical to **observed**, and that belongs in the record.
2. **Install layouts carry segments the documentation does not lead you to expect.** Claude Code's
   cache inserts a **version segment**: `…/icon-local/ICON/`**`1.22.0`**`/skills/…`. The Copilot
   reconstruction in `domains/plugin-resource-paths.md:44` has no such segment. I cannot claim
   Copilot's layout has one — different product, and I have no install to check. What this
   demonstrates is the *class* of failure the reconstruction bets against, on a layout I can see.

### 3.4 The answer: reduce the blast radius, and make the failure actionable

**(a) The narrow scope in § 4 does most of the work, and this is an independent reason for it.**
Copilot fences ship today in **two** skills (`icon-init`, `context-maintenance`). Converting only
`icon-status` takes that to **three**. Converting all 19 sites would take it to **six skills** and
add roughly nineteen hand-reconstructed paths. The exposure grows by one skill, not by five.

**(b) Consolidation reduces preamble count, and the motive is not size.** Each fence must be
independently runnable — that is trigger 1's own premise — so each fence carries its own four-line
preamble. `icon-status`'s eight programs therefore cost eight preambles if migrated one-to-one.
Sites 04 and 10 already duplicate the same named `scan` walker and both re-derive branch and task ID
from scratch; consolidating Step 2 into a small number of scripts removes duplicated logic **and**
divides the reconstructed-path count by the same factor. Record the motive as the duplication, so
§ Disqualified is not engaged.

**(c) Harden the reconstruction itself — see § 3.5. Superseded my original one-line presence check.**
With all 19 sites converting, scope is no longer the mitigation, so the reconstruction has to be one.

### 3.5 The hardened reconstruction — designed, and tested against eight fixtures

**A robust form does exist inside the constraints. It costs +176 B per fence and it is verified.**

```bash
# Resolve this skill's install directory. Set MARKETPLACE_NAME=<slug> to pin one marketplace;
# otherwise every installed marketplace is searched and an ambiguous result fails closed.
ROOT="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins"
S="<skill-name>"; P="scripts/<name>.mjs"
if [ -n "${MARKETPLACE_NAME+x}" ]; then G="$MARKETPLACE_NAME"; else G="*"; fi
F=""; N=0
for f in "$ROOT"/$G/ICON/skills/"$S/$P" "$ROOT"/$G/ICON/*/skills/"$S/$P"; do
  [ -f "$f" ] || continue; F="$f"; N=$((N+1))
done
[ "$N" = 1 ] || { echo "ICON: $N matches for $S/$P under $ROOT (marketplace ${MARKETPLACE_NAME-<any>}) — set MARKETPLACE_NAME; see: copilot plugin list" >&2; exit 1; }
node "$F"
```

**What changed and why each part earns its place:**

- **Discovers rather than names.** The slug becomes a glob, so the `icon-local` case (§ 3.3) resolves
  instead of failing. `MARKETPLACE_NAME` is kept and is now a *pin*, not a guess.
- **Handles the version segment** via the second glob, tried only as a fallback so the documented
  layout wins.
- **Fails closed on ambiguity.** Two marketplaces, or both path shapes present, produce a refusal
  naming the count — never a silent pick. This is the *"worse than the hard-coded one"* case the
  constraint names, and it is the reason a first-match `for … && break` one-liner was rejected.
- **Rule 5 is honoured, and `${MARKETPLACE_NAME:-*}` would have violated it.** Rule 5's stated live
  case is a fork that deliberately sets `MARKETPLACE_NAME=""`; `:-` discards an empty value, the
  `if`/`then` form preserves it. Fixture `empty` confirms it resolves the no-marketplace-directory
  layout.
- **Space-safe.** Every expansion that must not split is quoted; only the two deliberate globs are
  bare. `set -- $MATCHES` was rejected for exactly this reason — Windows home directories contain
  spaces.
- **No dependency, no GNU-only construct, no output suppression.** Shell globbing only — no `find`,
  so no `-maxdepth`/`-quit` portability question. An unmatched glob stays literal and fails `[ -f ]`,
  so no `nullglob` is needed. All diagnostics go to stderr and nothing is redirected away.
- **Bash only.** No PowerShell twin, per the standing rule.

**Test results** — eight fixtures under `COPILOT_HOME`, each a real directory tree with a real `.mjs`:

| Fixture | Layout | Exit | Result |
|---|---|---|---|
| `canon` | `icon-marketplace/ICON/skills/…` | 0 | ran the right file |
| `slug` | `my-org-mp/ICON/skills/…` — **the `icon-local` case** | 0 | ran the right file |
| `vers` | `icon-marketplace/ICON/2.0.0/skills/…` | 0 | ran the right file |
| `empty` | `MARKETPLACE_NAME=""`, `installed-plugins/ICON/skills/…` | 0 | ran the right file |
| `sp ace` | `COPILOT_HOME` containing a space | 0 | ran the right file |
| `none` | empty `installed-plugins/` | **1** | `0 matches …` on stderr, empty stdout |
| `ambig` | two marketplaces both carrying ICON | **1** | `2 matches … refusing` — no silent pick |
| `both` | one marketplace, both path shapes | **1** | `2 matches …` |

Plus two recovery checks: `ambig` + `MARKETPLACE_NAME=other-mp` → exit 0, correct file; `canon` +
`MARKETPLACE_NAME=typo-slug` → exit 1, fails closed. Also passes under POSIX `sh`, not just bash.

**Cost: 482 B / 8 lines, against the current 306 B / 4 lines — +176 B per fence, ≈ +3.3 kB across 19
sites.** That is affordable. An earlier 28-line / 970 B variant with a separate two-pass resolver was
built and tested first; it passed the same fixtures but cost ≈ 18 kB across 19 sites — **more than
the 14,545 B of program bodies the migration removes** — and was rejected on that measurement.

**Why it is not hoisted to one resolver per skill.** Hoisting `SKILL_DIR` into a once-per-skill block
would halve the cost, but it creates exactly the cross-fence state ADR-017 trigger 1 forbids, and the
dangerous case is real rather than theoretical: a stale `SKILL_DIR` left by a *different* skill's
fence resolves to a real directory and would run the wrong script silently. At 482 B per fence the
trade is not worth making. The existing precedent already re-derives per fence —
`context-maintenance/SKILL.md:226-228` and `:258-260` are two independent copies.

**Residual exposure, unchanged and still unverified:** this reconstruction is still a *guess about
Copilot's install layout*, tested against fixtures I built from ICON's own documentation rather than
against a real Copilot install (§ 3.1). What the hardening buys is that a wrong guess now **fails
loudly and closed with an actionable message**, instead of resolving to nothing or, worse, to the
wrong marketplace. It does not make the layout verified.

**(d) State the exposure, do not net it out.** ADR-018 must repeat ADR-017's *"designed for and
untested. It must not be described as verified"*, add the failed-verification record from § 3.1, add
the `icon-local` observation from § 3.3, and keep ADR-017's two settling tests as open work.

---

## 4. The degradation-path precondition, and scope

**Revised after a manager challenge (2026-08-01).** My first pass called the degradation-path
precondition a hard blocker on 12 of 19 conversions. **The manager's reading is correct and mine was
wrong**: the precondition is a second defect in ADR-017 of the same shape as the one being corrected.
§ 4.0 settles it by measurement. The scope recommendation below survives, but **its justification
changes from "blocked by rule" to "sequenced on risk"** — which is a materially different thing for
the manager to be acting on.

### 4.0 The precondition is a second defect on the same axis — measured

**The hazard is identical on both dispositions. There is no asymmetry that supports the gate.**

Measured on this host with `node` removed from `PATH`, against a positive control confirming the
removal (`command -v node` → exit 1; `node -v` → exit 127, `node: command not found`). The inline
case runs `plugin-design` site 15 verbatim; the `.mjs` case runs `skills/icon-init/scripts/detect-repo-type.mjs`
verbatim — a real shipped script, not a probe.

| Shell | Form | Exit | stdout | stderr |
|---|---|---|---|---|
| bash | inline `node -e '…'` | **127** | *(empty)* | `sh: line 1: node: command not found` |
| bash | `node "<abs path>.mjs"` | **127** | *(empty)* | `sh: line 1: node: command not found` |
| PowerShell 7 | inline | *(throws)* | — | `CommandNotFoundException`; **`$LASTEXITCODE` stale at primed 3** |
| PowerShell 7 | `.mjs` | *(throws)* | — | `CommandNotFoundException`; **`$LASTEXITCODE` stale at primed 3** |
| Windows PowerShell 5.1 | inline | *(throws)* | — | `CommandNotFoundException`; **`$LASTEXITCODE` stale at primed 3** |
| Windows PowerShell 5.1 | `.mjs` | *(throws)* | — | `CommandNotFoundException`; **`$LASTEXITCODE` stale at primed 3** |

**Byte-identical on all three channels, on all three shells.** `$LASTEXITCODE` was primed to 3 with
`cmd /c "exit 3"` before each invocation and held 3 after both — so ICON-0096's staleness finding,
which ADR-017 cites as the *second* ground for a prose guard, also applies equally to both forms.

**Two asymmetries do exist. Neither supports the precondition, and one runs against it.**

1. **`.mjs` has one failure mode inline does not: an unresolved script path.** Measured with Node
   present and a deliberately wrong path: exit **1**, empty stdout, `Cannot find module`. This is a
   real widening of the *"the block did not run"* surface — and it is the Copilot exposure of § 3,
   not a Node-absence concern. It argues for the presence check in § 3.4(c), not for this gate.
2. **Inline has one failure mode `.mjs` does not: PowerShell 5.1 quote stripping** (§ 6, measured).
   That one runs the other way, and is part of why the flip is right.

**Counter-example attempts recorded.** Before writing "identical", I tried: (a) a *partial* failure
where a consolidated script loses more than one fence would — that is a consequence of consolidation,
available to inline too, and not mechanism-inherent; (b) an agent-visibility difference — both forms
surface the same stderr and the same exit status to the Bash tool, so the agent sees the same thing;
(c) Node present but below ICON's floor — both forms run and both fail in whatever way the program
fails, identically; (d) the silent-pass inversion — identical, since both emit zero stdout. I could
not construct an asymmetry in the Node-absence exposure.

**The diagnosis.** ADR-017's stated ground establishes something narrower than the rule it carries:

> *It cannot be a script: `check-node-runtime` records that a `.mjs` reporting Node's absence is
> "self-defeating — it cannot run in the case it is meant to detect."*

That argument establishes **the guard must be prose**. It does not establish **the skill must already
have a degradation path** — and the self-defeating property is not a `.mjs` property at all. An
inline `node -e` that reports Node's absence is equally self-defeating. The whole guard paragraph is a
general truth about *Node-delivered executable content*, mis-filed under *the `.mjs` invocation
contract*, and a second obligation was appended to it that its argument never reached.

**That is the same defect shape being corrected.** The body test exists because ADR-017's triggers
were filed against fence-specific correctness hazards when the question was program-vs-command. This
clause is filed against **delivery mechanism** when the hazard is **Node dependence**. Its practical
effect is exactly what the manager described: it gates the *better* mechanism on a hazard both share,
making the worse one cheaper to adopt.

### 4.0.1 The correct rule — settled by the maintainer, and simpler than my formulation

**Superseded within this artifact (2026-08-01).** My first answer made the degradation path a
per-skill obligation discharged by in-scope work. The maintainer's answer is better and I withdraw
mine: *"The solution to node not being installed is to tell the user node is required and to offer to
install it."* **That behaviour already ships**, uniformly, in `skills/check-node-runtime/`. There is
nothing per-skill to possess, invent, or discharge.

Verified by reading the skill: Step 4 emits a visible `Node runtime: NOT FOUND` report naming exactly
what stops working; Step 5 offers a per-platform install (`brew` / `winget` / NodeSource / a version
manager) under *"Do not run an installer without being asked."*

**The restated guard, which replaces the per-skill degradation-path obligation entirely:**

> **Precondition — confirm Node is present before running this block.** Run `node -v` and read its
> **output**, not its exit status. If Node is absent, do not run the block — invoke
> `check-node-runtime`, which reports the absence and offers the install.

It applies to **any Node-dependent block, inline or `.mjs`**, on the § 4.0 measurement that the
exposure is identical. `icon-status` already routes to `check-node-runtime` from Signal 2, so the one
skill that had a degradation path was already doing the uniform thing.

**No bootstrap circularity** (the E2 concern): `check-node-runtime`'s detector is `node -v` and every
interpretation step is a prose table. It needs no Node to run, so it is reachable in exactly the case
it exists to detect. Its own Common Mistakes row says the same — *"Writing a `.mjs` script to detect
whether Node is available … self-defeating."*

### 4.0.2 Reconciling "never gates" with "report the block as not-run"

**They are compatible, and the skill already asserts the stronger of the two. Not a tension.**

The axis that separates them is **what is being stopped versus what is being reported**:

- `check-node-runtime`'s prohibition is scoped to the **session**: *"Blocking initialization or a
  session because Node is missing … This skill reports; it never gates. The harness must fail open."*
- The false-pass requirement is scoped to **one block's result**: a block that did not run is
  reported `not-run`, never `clean`.

These are different objects, and the skill's own Step 4 text already does both at once — it names
what stops working (*"shipped Node helper scripts will not run either"*) in the same breath as
*"Everything else in ICON still works."* That **is** component-reported-not-run with the session not
gated.

The decisive evidence is in the skill's own Common Mistakes: *"**Reporting nothing when Node is
present** — a silent pass is indistinguishable from the skill never running. Always emit the Step 4
line."* That is the identical principle to the false-pass fix, already held as a rule. Reading silence
as clean is the thing `check-node-runtime` most explicitly forbids about *itself*.

**What the prose must state at each site — two clauses, and the second is the one that is easy to
miss:**

1. **Every Node-dependent block** carries the § 4.0.1 precondition. This covers Node absence.
2. **Additionally, every block whose documented pass state is silence must emit an affirmative
   token instead.** The precondition cannot cover this case, because **Node being present does not
   establish that the block ran.** Two measured failure modes produce empty stdout with Node present:
   inline PS 5.1 quote-stripping (§ 6) and, for `.mjs`, an unresolved script path (§ 4.0, exit 1,
   `Cannot find module`). Where silence is the pass, both read as clean.

Clause 2 binds at three known sites — `icon-status` Step 1's hard-stop guard (site 02) and
`plugin-design`'s two *"silence means clean"* audit blocks. **It binds at site 02 whether or not that
site ever converts**, since site 02 stays inline permanently under the body test. Fixing it is the
token inversion already recommended in § 6 for #62.

### 4.0.3 Does the simplification change anything upstream?

Checked each, as asked:

- **The body test — no change.** It asks program-vs-command; the guard asks Node-dependence. Disjoint.
- **The 22-site classification — no change.** Re-derived nothing; the table in § 1.1 stands.
- **The amend-vs-supersede recommendation — no change in form.** Still one scope-supersession, still
  row 2. The *content* of ADR-018's second clause gets simpler: instead of relocating a per-skill
  obligation, it deletes one and points at a skill that already ships the behaviour.
- **§ 4.1's readiness survey — now moot as a gate.** It survives only as a record of what was
  searched, and its "cost to convert" column drops to zero for every row.

### 4.1 Degradation-path readiness — a survey, no longer a gate

The survey below stands as measured; only its consequence changes. Each skill searched twice: once
for Node-absence language (`node -v`, `check-node-runtime`, "node absent/missing/not present",
"degrad"), once for generic fallback language ("fall back", "manually", "if it fails", "cannot run",
"unavailable", "skip this step").

| Skill | Sites | Node-absence degradation path | Cost to convert |
|---|---|---|---|
| `skills/icon-status` | 9 (8 programs + site 02) | **Yes** — `SKILL.md:15-22` states it explicitly (*"with `node` off `PATH` all nine emit nothing and the dashboard degrades to its `Node — not found` line plus Signal 2's `check-node-runtime` suggestion"*), and Signal 2 at `:294-300` implements it. | **None — 8 sites, zero new behaviour** |
| `skills/plugin-design` | 11 | **None.** Zero hits on either search across all 11 files. The two "Node fallback" hits at `create-phase-basic-info.md:27,50` run the other way — Node is the fallback *for* `jq`. | One stated behaviour per mode: audit phases → "phase not run"; `create-*` phases mutate the manifest, so the honest answer is likely "Node is a hard requirement for scaffolding" |
| `skills/initialize-workspace` | 1 (site 11) | **None.** | One stated behaviour |
| `.claude/skills/icon-audit` | 1 (site 01) | **None.** | One stated behaviour — trivially "the audit cannot run" |

**The "cost to convert" column is now zero for every row.** It is retained as the record of what was
searched, and because it shows the shape of the mistake: three skills were read as *not ready* when
in fact no skill ever needed its own path. `icon-init`'s pointer at Step 3's `undetermined` branch is
a *skill-specific* refinement, not the general contract — the general contract is § 4.0.1's
`check-node-runtime` invocation, which every skill inherits without writing anything.

### 4.2 Scope — all 19 program sites convert in this task

**Manager decision, 2026-08-01, accepted: all 19 convert.** `icon-status` 8, `icon-audit` 1,
`plugin-design` 10. My earlier staged recommendation is withdrawn — both constraints it rested on
have been answered rather than merely overruled:

1. **The degradation-path blocker is gone** (§ 4.0.1). Nothing per-skill has to be written.
2. **The Copilot blast radius is now mitigated at the mechanism** (§ 3.5) rather than by keeping the
   count low. The hardened reconstruction resolves the two cases that made the count matter — a
   non-default slug and a version segment — and fails loudly and closed on everything else. Going
   from 2 skills to 6 with a form that discovers and refuses to guess is a better position than 2
   skills with a form that names a slug this very machine contradicts.

Reviewability remains a real cost and is not waved away — it is answered by sequencing the **commits**
rather than the scope: `plugin-design` → `icon-status` → `icon-audit`, one per skill, matching the
order the original implementation used, with the ADR and standard landing first so every commit is
reviewable against a rule already in the tree.

**Correcting my own count**: `plugin-design` contributes **10**, not 9. Its 11 sites are 8 programs
(12, 13, 14, 16, 17, 19, 22, 15) plus site 18 on trigger 2 — that is 9 — plus site 01 is `icon-audit`,
not `plugin-design`. Recount from § 1.1: `plugin-design` programs are 12, 13, 14, 15, 16, 17, 19, 22
= **8**, plus site 18 by trigger 2 = **9**. Sites 20 and 21 stay inline. So the correct split is
`icon-status` 8 + `icon-audit` 1 + `plugin-design` 9 = **18**, plus `initialize-workspace` site 11 =
**19**. The manager's "`plugin-design` 10" folds `initialize-workspace` in; the total of 19 is right
either way.

**One site I would still not convert, and the ground is the body test, not appetite:** none. All 19
are programs or trigger-2 mutations under § 1.1, and I could not construct a case for exempting any
individual one. **Sites 02, 20 and 21 are not exemptions** — they are commands, correctly inline, and
converting them would be applying the rule wrongly rather than conservatively.

**Site 01 (`icon-audit`) is the cheapest of the 19** and worth noting separately because its contract
differs: maintainer-only skills under `.claude/` are never installed through a marketplace, so it
takes **no Copilot fence at all**. Verified: no `CLAUDE_SKILL_DIR` and no `COPILOT_HOME` anywhere
under `.claude/`; the established convention is a plain repo-relative path, per
`release-plugin/SKILL.md:200` — `bash .claude/skills/release-plugin/scripts/bump-versions.sh "$NEW"`.
Its whole invocation contract is one untagged line, `node .claude/skills/icon-audit/scripts/<name>.mjs`.
Verified the form resolves: `node ./skills/icon-init/scripts/detect-repo-type.mjs` from the repo root
gave exit 0, `project` on stdout, diagnostics on stderr.

### 4.2.1 What this leaves

Two states, both intentional:

- **Migrated** — 19 sites across 4 skills.
- **Correctly inline, permanently** — sites 02, 20, 21. Commands under the body test.

**Site 02 still needs the § 4.0.2 clause-2 fix** — the token inversion — because it stays inline and
its pass state is silence. That is a small change inside this task's scope, not a follow-up, and it
closes the most dangerous residue of #62.

The maintainer's original objection — the largest shipped programs, which are `plugin-design`'s — is
**fully answered** by this scope.

### 4.3 Shared blocks and `.githooks/pre-commit`

**No conversion candidate is shared across skills.** SHA-256 over all 22 program bodies found exactly
one duplicate pair — sites 20 and 21 — and both are in `skills/plugin-design/`, i.e. one skill, one
`scripts/` directory, one copy. Both stay inline anyway. The `isFile`/`ls` helper text recurs four
times, all four inside `plugin-design`.

**Therefore: `n ≥ 2` never fires, and no byte-parity registration is required in any wave.** That is
worth stating in ADR-018, because it means this change does **not** refill the parity population that
ADR-017's Consequences worries about.

*Blind spot, named:* SHA-256 is exact-match. Two programs doing the same job with different text
across two skills would not be detected. I did not build a similarity sweep; the wave-2
investigation's Jaccard pass covered fenced blocks generally and found no cross-skill `node -e`
cluster.

**Gate coverage, verified by executing the hook's own `case` patterns:** `skills/*.mjs` **matches**
`skills/plugin-design/scripts/audit.mjs` (bash `case` globs cross `/`), so any `.mjs` under
`skills/` is inside both the dead-reference and cap-literal gates. `.claude/skills/icon-audit/…`
**does not match** — but `.claude/` is in no gate scope today either, so migrating site 01 would be
**gate-neutral**, not a loss. `.claude/skills/icon-audit/scripts/structural-check.sh` is the existing
precedent for maintainer-only scripts living there.

### 4.4 PR #65

Nothing on the branch is reverted, and no program is rewritten. All 19 sites are **re-delivered** —
the Rule-10 semantics work (S1–S24), the cured cross-fence chains, the `yaml`-folding fidelity
decision and the six rounds of fixture-tested behaviour all carry over into the `.mjs` files
unchanged. What changes is the delivery mechanism and the surrounding contract, not the code.

That is the argument for treating this as a continuation of #65 rather than a restart: the
expensive, six-rounds-deep asset is the **semantics**, and the flip does not touch it. The
`python3` → Node migration in `plugin-design` was a live Windows bug fix that stands on its own
regardless of where the code ends up living.

---

## 5. What ADR-017's obligations cost per converted site

Measured against the one shipped precedent, `skills/icon-init/SKILL.md`:

| Component | Bytes | Per what |
|---|---|---|
| Claude Code fence, untagged (`:94-98`) | **118** | per **site** |
| Copilot fence, **current** naming form (`:100-107`) | **306** | per **site** |
| Copilot fence, **hardened** discovery form (§ 3.5) | **482** (+176) | per **site** |
| Node-presence precondition prose (`:87-93`) | **557** | per **skill** — and now one uniform sentence pointing at `check-node-runtime` (§ 4.0.1), so it shrinks |
| Outcomes table (`:109-124`) | **753** | per script |
| Full `## Tooling` section (`:82-125`) | **1,942** | per script |

**The Outcomes table is not overhead.** ADR-017 § *The prose contract must survive* obliges it
whether or not the code moves; `icon-status` already carries most of it as prose (`:76-89` documents
which blocks always print and what silence means). The genuine per-site cost is the **fence pair**:
**600 B** with the hardened Copilot form, against 424 B with the current one.

Across the accepted 19-site scope: **19 × 600 B ≈ 11.4 kB of invocation fences added**, against
**14,545 B of program bodies removed** (the raw figure is 18,128 B for the 21 shipped sites; the 19
converting ones are the bulk of it). **Net roughly flat, and that is the expected outcome, not a
disappointment** — ADR-017 § *Migration is not cap-evasion* says so directly, and § 6 explains why
`icon-status` is the one file where the arithmetic still matters.

**Site 01 (`icon-audit`) is the cheap outlier at ~118 B**: no Copilot fence at all (§ 4.2).

**Degradation-path cost is now zero for every skill** (§ 4.0.1). The § 4.1 survey is retained as a
record of what was searched, not as a gate.

---

## 6. Dispositions for #62 and #64

### #62 — inline `node -e` on Windows PowerShell 5.1: **shrinks, does not close**

**Re-verified independently on this host** (`powershell.exe` 5.1.26100.8875), with a positive control
so the harness itself is validated:

| Test | Command | Exit | stdout | stderr |
|---|---|---|---|---|
| **A — the `.mjs` form** | `node "<abs path>\probe.mjs"` | **0** | `HELLO` | *(empty)* |
| **B — inline, positive control** | `node -e 'process.stdout.write("HELLO\n")'` | **1** | *(empty)* | `process.stdout.write(HELLO\n)` … `SyntaxError: Invalid or unexpected token` |

Test B reproduces #62 exactly — quotes visibly stripped — which is what makes Test A's clean pass
meaningful rather than a silent no-op. **The claim the flip rests on is confirmed on this machine.**

Disposition:

- **This task:** 22 affected sites → **3**. All 19 conversions clear.
- **#62 does not close.** Sites 02, 20 and 21 stay inline, all three contain a `"`, and all three
  still fail on 5.1.
- **But its worst case does close here.** Site 02 — the silence-is-the-pass guard #62 names as the
  false-pass — gets the § 4.0.2 clause-2 token inversion inside this task. What survives in #62 is
  then three blocks that fail **loudly** on 5.1: sites 20 and 21 are `JSON.parse(…)` validity checks
  whose failure is a visible parse error, and site 02 will print an affirmative token or nothing at
  all. **#62 shrinks from "22 sites, one of them silently wrong" to "3 sites, all loud."**

**The sharp finding, and it must go on the issue: the body test leaves #62's single most dangerous
site inline.** Site 02 is `icon-status`'s fresh-repo guard — `if (!isDir)
process.stdout.write("NOT_INITIALIZED\n")` — and #62 names it as the case where the failure inverts
into a **false pass**: on 5.1 the program dies at parse, prints nothing, and silence is documented as
"initialized", so a documented hard stop is skipped. The body test answers *program or command*; it
does not answer *does this survive 5.1*, and it should not be stretched to.

**Concrete suggestion for #62's own fix, cheaper than migration:** invert the contract so silence is
never the pass. Make site 02 print a token on both branches (`NOT_INITIALIZED` / `INITIALIZED`) and
have the caller require one of the two. That removes the false-pass without a file, a preamble or a
degradation path — and it applies equally to `plugin-design`'s two "silence means clean" blocks that
#62 names.

### #64 — `icon-status` size: **stays open, and its numbers need one correction**

**The two figures in #64 are working-tree measurements with CRLF line endings, not committed blobs.**
Measured: committed blob at `HEAD` = **18,534 B**; working tree = **18,955 B**; the file has **421
lines** and the delta is **exactly 421 bytes** — one per line. The same holds at the migration commit
`a814893`: blob 15,335 B, 388 lines, 15,723 B on a CRLF checkout. Both of #64's numbers are
internally consistent; they are just the checkout convention. `git check-attr` reports `text:
unspecified, eol: unspecified` for the file. **Substance is unaffected — both readings exceed the
16,000 B cap — but the issue should say which convention it uses, and ADR-016 arguably should too.**

Disposition:

- Migrating `icon-status`'s 8 programs will remove ~5,519 B of program bodies and add ~3.4 kB of
  fences (less if consolidated). The file will land near or under the cap.
- **Do not let that be the motive, and do not close #64 in the migration commit.** This is exactly the
  scenario ADR-017 § *Disqualified* exists to police, arriving legitimately. The control that keeps it
  honest is that the motive is documented and independent: the body test, the PS 5.1 defect and the
  duplicated `scan` walker all argue for the move with the byte count removed from the argument.
- **Recommended:** re-measure after the conversion; if the file is under cap, close #64 with the
  reason stated as *"its programs moved for correctness reasons and the size effect is a consequence,
  not the motive"*, citing this section. If it remains over, #64's real question — *"is gate 2 the
  right gate for a linear procedure at all?"* — survives and is unaffected by anything here.

### #48 — unchanged

Still shrunk-not-closed. There is no `.mjs` correctness linter in this repo; `semgrep --config p/ci`
in the `security` workflow reads `.mjs` but is a security ruleset. What the flip changes is that
**19 programs become lintable in principle** — a real `.mjs` file can be fed to a checker where a
fenced string cannot — without any linter existing yet. Worth one line on #48; not a disposition
change.

---

## 7. What I could not verify

Stated as gaps, not netted out.

1. **The entire Copilot CLI half.** Copilot CLI is not installed on this host (§ 3.1) and neither of
   ADR-017's two settling tests could be run. **This remains the largest unverified surface, and the
   accepted scope enlarges it from 2 skills to 6.** § 3.5's reconstruction was tested against eight
   **fixtures I constructed** from ICON's own documented layout — that establishes the shell logic is
   correct, space-safe, Rule-5-conformant and fail-closed, and it establishes nothing about whether
   Copilot's real layout matches any of the three shapes it searches. If the real layout differs in a
   way none of the three cover, every migrated skill's Copilot fence fails **loudly** with a `0
   matches` message naming where it looked — which is the design goal, but it is a graceful failure,
   not a success.
1a. **That the version-segment fallback is warranted at all.** The segment is real in *Claude Code's*
   plugin cache (§ 3.3, measured). I have no evidence Copilot inserts one; the second glob is
   insurance whose cost is one line and whose benefit is unproven.
2. **That the three surveyed skills have no degradation path.** Two keyword searches over 13 files;
   a path described in wording neither search covered would have been missed. Confidence: high for
   `initialize-workspace` and `icon-audit` (one file each, both read), medium for `plugin-design`
   (11 files, searched not read end-to-end). **Lower stakes after § 4.0** — this is now a cost
   estimate, not a gate, so a miss makes a conversion cheaper than stated rather than illegal.
2a. **That `.claude/skills/` is never installed through a marketplace** — the basis for site 01's
   zero-Copilot-exposure claim (§ 4.2). What I verified is narrower: no `CLAUDE_SKILL_DIR` and no
   `COPILOT_HOME` appears anywhere under `.claude/`, and `release-plugin` invokes its script by a
   plain repo-relative path. That establishes the **existing convention**, not the impossibility of
   a future install. The claim rests on `.claude/` being repo-local by construction, which I did not
   independently confirm against harness documentation.
2b. **That `node -v` reaching the agent is unaffected by any of this.** § 4.0 measured that the
   *invocations* behave identically with Node absent. I did not separately re-measure the bare
   `node -v` probe's own behaviour under each shell beyond the positive control, which covered bash
   only for stdout/stderr and all three shells for the exception and `$LASTEXITCODE`.
3. **That no cross-skill duplicate program exists.** SHA-256 is exact-match only (§ 4.3). A
   semantically duplicated program with different text would evade it.
4. **Triggers 1, 3 and 4 retaining independent work.** Argued from constructed cases. Only trigger 2
   has a corpus member (site 18) where it does work the body test does not.
5. **That no site is ambiguous under the body test.** Verified against these 22 by reading each; the
   four attack shapes I tried are listed in § 1.2. This is a claim about *this corpus*, not about
   every program an author could write — and § 1.5 names the one dodge I know of.
6. **The consolidation estimate for `icon-status`.** The ~3.4 kB fence cost assumes one-to-one
   conversion; I did not design the consolidated script set, so the post-migration file size is an
   estimate, not a measurement. #64's disposition is written to depend on a re-measurement, not on
   this number.
7. **Whether ADR-016's cap is meant to measure the blob or the checkout** (§ 6, #64). I measured
   both and reported both; I did not find the convention stated anywhere.
