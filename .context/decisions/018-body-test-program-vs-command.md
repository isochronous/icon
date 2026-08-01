# ADR-018: A program belongs in a committed `.mjs` — the body test, and one Node guard for both homes

**Date**: 2026-08-01
**Status**: Accepted
**Supersedes**: ADR-017 (the Deterministic row's default for *programs*, the invocation contract's Node-presence obligations, and the Copilot CLI path reconstruction only — the four-tier classification, the four triggers, § Disqualified, the trivial test, the Node floor, the two exclusion axes and the shared-set rule all stand)
**Superseded-by**: none

## Context

**Both defects corrected here are the same misfiling: a rule attached to the *delivery mechanism*
when the hazard it names is something else.** That is the whole thesis, and each correction is a
consequence of it rather than an independent fix.

ADR-017 settled where executable content lives and made **inline `node -e` the default** for a
deterministic block, with a committed `.mjs` reached only through four triggers. Applying it across
ICON's corpus (ICON-0099) surfaced two places where it files a rule against mechanism:

- **The four triggers ask about fence-local correctness.** State crossing a fence boundary,
  mutation, repeated invocation, an unavoidable apostrophe — every one is a property of *how the
  block is delivered inside a markdown file*. **None asks whether the block is a program or a
  command.** A 2,943 B parser with three named helpers and a recursive walk classified inline
  because no trigger fired, while the property that actually makes a block cost a fixture to test
  and a careful pass to review — that it has a second locus of control the reader must jump to —
  was never asked about.
- **The `.mjs` invocation contract's precondition gates the mechanism on a shared hazard.** It
  required *"a degradation path the skill already has"* and added *"if a skill has no such state,
  it is not ready to migrate."* The stated ground for the surrounding guard is that a `.mjs`
  reporting Node's absence is self-defeating. That ground establishes **the guard must be prose**;
  it does not reach *the skill must already possess a degradation path*, and the self-defeating
  property is not a `.mjs` property at all — **an inline `node -e` reporting Node's absence is
  equally self-defeating.** A general truth about *Node-dependent executable content* was filed
  under *the `.mjs` invocation contract*, and a second obligation was appended to it that its
  argument never reached.

Taken together the two produce a specific perversity: **the better mechanism is gated on a hazard
both mechanisms share, which makes the worse one cheaper to adopt.**

### The evidence that arrived after ADR-017

ADR-017's inline default was correct on the evidence it had. Three measurements defeated it.

1. **Inline does not get the full portability win** (issue #62, measured by ICON-0099 on
   PowerShell 5.1.26100.8875). Windows PowerShell 5.1 strips a `"` embedded in a native command's
   argument, so `node -e '…process.stdout.write("HELLO\n")…'` reaches Node with the quotes deleted
   and dies on a `SyntaxError`. Every one of the 22 single-quoted inline sites contains a `"`
   (re-verified for this record — see the counter-example note under the corpus table). The `.mjs` form
   — `node "<absolute path>"` — has no quote *inside* an argument value and was measured running
   clean on the same shell. This falsifies one clause of ADR-017's *Alternatives Considered* 4:
   *"inline `node -e` already gets the portability win with none of that overhead."* The rest of
   that alternative's rejection stands.
2. **The Node-absence exposure is identical on both forms** — measured on bash, PowerShell 7 and
   Windows PowerShell 5.1 with `node` off `PATH`, against a positive control (`command -v node`
   → exit 1). Both forms produced byte-identical behaviour on all three channels (stdout, stderr,
   exit status), and `$LASTEXITCODE` stayed stale at a primed `3` after both on both PowerShells.
   ICON-0096's staleness finding — ADR-017's *second* stated ground for a prose guard — applies
   equally to both. The gate has no asymmetry to rest on.
3. **The corpus splits cleanly on program-vs-command, and not on size.** See the Decision.

Nothing else in ADR-017 was found stale, which is why this record scope-supersedes rather than
supersedes. Its 164-block / 126,041 B corpus measurement, its 78/59 split and its `.gitattributes`
copy-set finding were **not re-measured here** — nothing in ICON-0099 contradicted them, and its two
`## Amendments` entries already record the one correction that pass did produce. Absence of a
contradiction is weaker than a re-measurement, and is stated as such.

## Decision

### 1. The body test: a program's default home is a committed `.mjs`

> **A deterministic block is a *program*, and belongs in a committed `.mjs` under the invoking
> skill's own `scripts/`, if it has a body.**
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
in a single pass: each branch does one thing and nothing is named for later. A program has a second
locus — a callable the reader must jump to, or a branch that is itself a small procedure.

**This flips ADR-017's Deterministic-row default for programs only.** Commands keep it. The
surviving inline tier is "one-liners you would type at a prompt", which is a coherent tier rather
than a vestige.

### Ordering, and what the four triggers now do

Classification runs first and is unchanged: **Judgement → Illustrative → Trivial → Deterministic.**
The body test then splits **Deterministic** into *command* → inline and *program* → `.mjs`. The
four triggers run **last** and remain **overrides**: a block the body test calls a command still
becomes a `.mjs` if any trigger fires.

*Classification precedes trigger evaluation* is preserved verbatim — nothing the Trivial row
excluded reaches the triggers. The body test is **not a fifth trigger**; it replaces the
Deterministic row's default, which is what makes this a Decision change rather than a list
extension.

Trigger 2 (mutation) demonstrably still does independent work: site 18 below is bodyless — nine
straight-line statements, no braces anywhere — and rewrites `.claude-plugin/plugin.json`. The body
test alone would leave it inline. Triggers 1, 3 and 4 are argued from constructed cases only; the
corpus contains no member where they do work the body test does not. **All four are kept.** Trigger
3 is the weakest and is the one to watch; deleting it would be a second change to the same record
for no measured benefit.

### The corpus, classified

The **classification** rows below are the design artifact's, derived by reading each of the 22
programs rather than by regex. The **site counts and byte figures** were re-derived independently
for this record on 2026-08-01 (working tree at branch
`feature/ICON-0099-migrate-fenced-blocks-waves-1-2`) by a fence parser over every `.md` outside
`.git/`, `node_modules/` and `.context/`, and reproduce the artifact's exactly:

| Population | Sites | Raw program-body bytes |
|---|---|---|
| All **single-quoted** inline `node -e` sites | **22** | **23,271** |
| Shipped (`skills/`) | 21 | 18,128 |
| Classified **program** | **18** | — |
| Classified **command** | **4** | — |
| Converting to `.mjs` (18 programs + site 18 on trigger 2) | **19** | **22,934** |
| Staying inline, permanently | **3** | **337** |

The three that stay are `skills/icon-status/SKILL.md` (185 B), and two byte-identical 76 B
`JSON.parse` manifest checks in `skills/plugin-design/create-phase-basic-info.md` and
`create-phase-boilerplate.md` — the same idiom `.claude/CLAUDE.md` documents as the manifest parse
check.

*Counter-example found while re-deriving the count, and it is why the first row says
**single-quoted**:* a **23rd** inline `node -e` exists at `.claude/claude.md:18` — the manifest parse
check — written with **double** outer quotes, so it is outside every population above and outside
`shell-portability` Rule 11's *"all 22 contain a `"`"* claim (re-verified for this record: of 23
matches, the 22 single-quoted ones all contain a `"`; the double-quoted one does not). It is repo
instructions rather than a skill, so no disposition here reaches it.

By skill, the 19: `icon-status` 8, `plugin-design` 9, `initialize-workspace` 1, `icon-audit` 1.

**No site was ambiguous in *applying* the test** — a claim about *these 22*, established by reading
each, not about every program an author could write. Four ways of constructing an ambiguity were
tried and recorded: a comma-operator dodge (no comma-operator sequence exists in any of the 22); a
named callable never called (none — every named callable in the 22 is invoked); a nested body
inside a named callable (B1 and B2 both fire and agree); and a single-statement branch whose one
statement is huge (unambiguously bodyless). **One site invites disagreement about the *outcome*
rather than the application**: `icon-status`'s `function git` wrapper, which a reader could
reasonably call "get the repo name — a command with a retry". The test says program because the
block resolves a name through a three-level fallback chain the reader must trace. Named here rather
than left to be rediscovered.

### It is not size in disguise, and § Disqualified is reaffirmed

**Measured for this record.** The boundary crosses byte order in both directions:

- Site 15 (`plugin-design/audit-phase-structure.md`) is a **program at 269 B**, while site 18
  (`create-phase-basic-info.md`) is a **command at 402 B**.
- Site 02 (`icon-status`) is a **command at 185 B**, smaller than that 269 B program.
- The largest command (402 B) exceeds two of the programs (269 B and 318 B).

**No *monotone* byte threshold reproduces this partition at any cut point** — the counter-example
attempted and recorded is that a non-monotone rule trivially could, by being a lookup table of the
22 sites, which is not a rule. The body test is available precisely *because* it needs no number.

> **§ Disqualified stands, unchanged and reaffirmed. Size is never a trigger and never an
> acceptance criterion.** Not as a tiebreaker, not as supporting evidence, not "among other
> reasons". An oversized `SKILL.md` is a split obligation discharged by a companion the byte gate
> still measures; relocating code into a file the gate cannot see conceals the obligation rather
> than discharging it.
>
> **Flipping the default for programs makes cap-evasion more tempting, not less, so this control
> matters more now than it did under ADR-017.** A rule that sends the largest blocks in the corpus
> into files the gate cannot see is exactly the rule an author will reach for when a `SKILL.md` is
> over cap. The motive test is unchanged: if the only reason a block is moving is the byte count,
> **the migration is refused and the split is performed instead.**

**The measured byte effect, and why it is not the win.** Three figures, each labelled by who
measured it:

- **Measured for this record.** The 19 converting sites carry **22,934 B** of raw program body; the
  three staying inline carry 337 B.
- **From the design artifact, not re-derived here.** The per-site invocation cost is ≈600 B with
  the hardened Copilot form below, giving **≈11.4 kB of invocation fences added** across 19 sites.
  `icon-audit`'s site is the cheap outlier at ≈118 B: a maintainer-only skill under `.claude/` is
  never installed through a marketplace, so it takes **no Copilot fence at all**.
- **One correction to the artifact's own comparison.** It sets ≈11.4 kB against *"14,545 B of
  program bodies removed"* and calls the result roughly flat. That 14,545 B is the **21 shipped
  sites with comment lines stripped** — a different population from the 19 that convert, on a unit
  the same artifact rules out earlier (*"Use the raw figures"*; the comments carry Rule-10
  semantics notes that ship and must be maintained). Re-measured like for like at **22,934 B raw**,
  the markdown *shrinks* by roughly 11 kB before ADR-017's independent prose obligations — the
  per-skill precondition and the per-script outcomes table, which the artifact prices at ≈753 B
  per script and which are owed whether or not the code moves. Add those back across 19 scripts and
  the net plausibly turns positive again, which is ADR-017's own prediction that `SKILL.md` may
  grow.

**The direction of the net is genuinely uncertain, and that is fine, because it may not be counted
in either direction.** A task that migrates and reports a byte reduction as the win has applied
this record incorrectly. The motive is the body test, the PowerShell 5.1 defect and the duplicated
walker logic — with the byte count removed from the argument.

### 2. The degradation-path precondition is deleted, not relocated

ADR-017's *"take a degradation path the skill already has"* and *"if a skill has no such state, it
is not ready to migrate"* are **removed**, along with the authoring spec's *"Do not invent one as
part of the migration."* They are not moved somewhere else, because measurement 2 above shows there
is no asymmetry for them to sit on.

**Two asymmetries do exist between the forms. Neither supports the precondition, and one runs
against it.**

1. `.mjs` has one failure mode inline does not: **an unresolved script path** — measured with Node
   present and a deliberately wrong path at exit 1, empty stdout, `Cannot find module`. That is the
   Copilot exposure below, and it argues for the hardened reconstruction, not for this gate.
2. Inline has one failure mode `.mjs` does not: **PowerShell 5.1 quote stripping**. That one runs
   the other way, and is part of why the flip is right.

Counter-example attempts recorded before writing "identical": a partial failure where a
consolidated script loses more than one fence would (a consequence of consolidation, available to
inline too); an agent-visibility difference (both forms surface the same stderr and exit status to
the tool layer); Node present but below ICON's floor (both run and both fail identically); and the
silent-pass inversion (identical — both emit zero stdout). None produced an asymmetry in the
Node-absence exposure.

### The replacement: a two-clause guard applying to *both* dispositions

**Clause 1 — confirm Node is present before running the block.** Run `node -v` and read its
**output**, not its exit status. If Node is absent, do not run the block; **invoke
`check-node-runtime`.** That skill already reports what stops working (its Step 4 absent-case text
names the session-start hook and the shipped helper scripts, alongside *"Everything else in ICON
still works"*) and already offers a per-platform install under *"Do not run an installer without
being asked."* **There is nothing per-skill to possess, invent, or discharge.**

The guard stays **prose**, which is all ADR-017's self-defeating-detector argument ever
established. **No bootstrap circularity:** `check-node-runtime`'s detector is `node -v` and every
interpretation step is a prose table, so it needs no Node and is reachable in exactly the case it
exists to detect. Its own Common Mistakes says the same of a `.mjs` detector.

**Clause 2 — a block whose documented pass state is silence must emit an affirmative token
instead.** This is the clause readers will miss, and it is not covered by Clause 1: **Node being
present does not establish that the block ran.** Two *measured* failure modes produce empty stdout
with Node present — inline PowerShell 5.1 quote-stripping, and, for `.mjs`, an unresolved script
path. Where silence is the pass, both read as clean, and a documented hard stop is skipped.

Clause 2 **binds at a site whether or not that site ever converts.** `icon-status`'s Step 1
fresh-repo guard stays inline permanently as a command under the body test, and is exactly the
false-pass issue #62 names; its fix is to print a token on both branches and have the caller
require one of the two.

**"Never gates" and "report the block as not-run" are compatible, not in tension.** The
`check-node-runtime` prohibition is scoped to the **session** — it reports, it never blocks, the
harness fails open. The false-pass requirement is scoped to **one block's result** — a block that
did not run is reported not-run, never clean. That skill's own Common Mistakes already asserts the
stronger half: *"Reporting nothing when Node is present — a silent pass is indistinguishable from
the skill never running."*

### 3. The Copilot CLI reconstruction is hardened

ADR-018 takes Copilot **invocation** fences from **2 shipped skills to about 6**. (Verified for this
record: `context-maintenance` and `icon-init` ship script-invocation fences today. A third skill,
`find-context-template`, ships a Copilot fence that reconstructs a **resource path** rather than
invoking anything, and is an E2 bootstrap exclusion — it is outside this count, and outside this
form.) Under ADR-017 the mitigation for an unverified install layout was keeping the count low. That
is no longer available, so **the reconstruction itself becomes the mitigation.** This replaces
ADR-017's four-line naming form:

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

**What each part earns:**

- **It discovers rather than names.** The marketplace slug becomes a glob. `MARKETPLACE_NAME` is
  kept and is **demoted from a guess to a pin.**
- **It handles a version segment** via the second glob, tried as a fallback so the documented
  layout still wins.
- **It fails closed on ambiguity.** Two marketplaces, or both path shapes present, produce a
  refusal naming the match count — never a silent pick. This is why a first-match `for … && break`
  one-liner was rejected.
- **`shell-portability` Rule 5 is honoured, and `${MARKETPLACE_NAME:-*}` would have violated it.**
  Rule 5's stated live case is a fork that deliberately sets `MARKETPLACE_NAME=""`; `:-` discards
  an empty value where the `if`/`then` form preserves it.
- **Space-safe.** Every expansion that must not split is quoted; only the two deliberate globs are
  bare. `set -- $MATCHES` was rejected for this reason — Windows home directories contain spaces.
- **No dependency, no GNU-only construct, no output suppression.** Shell globbing only, so no
  `find` and no `-maxdepth`/`-quit` portability question. An unmatched glob stays literal and fails
  `[ -f ]`, so no `nullglob` is needed. All diagnostics go to stderr and nothing is redirected away.
- **Bash only.** No PowerShell Copilot variant, per the standing rule — adding one recreates the
  parity burden this family of records exists to remove, for a path string.

**Why the slug was not left hard-coded.** The hard-coded slug is wrong for at least one real
installation. **Verified on this host for this record**: the local plugin cache holds
`~/.claude/plugins/cache/icon-local/ICON/1.22.0/` — the marketplace directory is `icon-local`, not
`icon-marketplace`, and the path carries an undocumented **version segment**. A second marketplace
directory (`claude-plugins-official`) is present alongside it, so the ambiguity case is real on
this machine too. That is **Claude Code's** cache rather than Copilot's `installed-plugins`, so it
does not establish that Copilot inserts a version segment — it demonstrates the *class* of failure
the reconstruction bets against, on a layout that can be seen.

**Why it is not hoisted to one resolver per skill.** Hoisting `SKILL_DIR` into a once-per-skill
block would roughly halve the cost and creates exactly the cross-fence state trigger 1 forbids,
in its most dangerous form: a stale `SKILL_DIR` left by a *different* skill's fence resolves to a
real directory and runs the wrong script silently. The existing precedent already re-derives per
fence. A 28-line / 970 B two-pass resolver variant passed the same fixtures and was rejected on
cost.

**Residual exposure — stated, not netted out.** This reconstruction is still a **guess about
Copilot's install layout.** It was tested against eight fixtures **built from ICON's own
documentation, not against a real Copilot install** — Copilot CLI is not installed on the design
host (`command -v copilot` not on `PATH`; `gh extension list` empty; `~/.copilot` holds only a lock
file with no `installed-plugins/` directory). **ADR-017's two settling tests remain unrun**, and
ADR-017's language carries forward verbatim: the Copilot half of this contract is **designed for
and untested. It must not be described as verified.** What the hardening buys is that a wrong guess
now fails **loudly and closed with an actionable message** naming where it looked, instead of
resolving to nothing or, worse, to the wrong marketplace. **It does not make the layout verified.**

What the fixtures do establish, and no more: the shell logic resolves the canonical layout, a
non-default slug, a version segment, an empty pinned slug and a `COPILOT_HOME` containing a space
(exit 0 in all five), and fails closed on no install, two marketplaces and both path shapes at once
(exit 1 in all three, each naming the match count), plus recovery — an ambiguous tree with a correct
pin resolves, a wrong pin fails closed. It also passes under POSIX `sh`.

**What is verified on the Claude Code half** is narrow but not nothing: a plugin-shipped `scripts/`
directory does materialise on disk at install time and Node can execute a file from it — confirmed
against three shipped `scripts/` directories in this host's install tree.

### The known gaming vector

An author can dodge B2 by collapsing a two-statement branch into a comma expression:
`if (x) { a(); b(); }` rewritten `if (x) (a(), b());`. **No comma-operator sequence exists in any of
the 22 sites**, so this is available to a future author rather than present today. It is handled the
way trigger 4's escape hatch already is: rephrasing to dodge the classification is a last resort,
and an author writing `(a(), b())` to avoid a body has answered the question. No gate can check
this; it joins the obligations ADR-017's Consequences already lists as author-honoured.

## Consequences

**Positive:**

- The largest programs in the corpus become **directly executable and directly testable**. Every
  ICON-0099 verification round had to extract a fence from markdown and re-run it as a shell word
  to test what actually ships.
- **Issue #62 shrinks from 22 affected sites to 3** — and its worst case closes. The three
  survivors all contain a `"` and all still fail on PowerShell 5.1, but all three fail **loudly**:
  two are `JSON.parse` validity checks whose failure is a visible parse error, and the third is
  covered by Clause 2's token inversion. #62 does **not** close.
- The program body stops being **banned from containing an apostrophe** — a language restriction
  the delivery mechanism imposed. ICON-0097 shipped a break on the name `Siobhan O'Brien`.
- The Node-presence guard becomes **one uniform sentence pointing at a skill that already ships the
  behaviour**, replacing a per-skill obligation that three of four affected skills did not satisfy.

**Negative, each a live cost:**

- **The invocation preamble becomes a new duplication class, and the existing parity check cannot
  police it.** This record creates roughly six copies of the Copilot preamble across skills, and
  they are **not byte-identical** — the skill and script names differ — so `.githooks/pre-commit`'s
  byte-parity check cannot be pointed at them as-is. This is precisely the drift shape ADR-017's
  own Context section names. Its disposition, in three parts:
  1. **ADR-017's shared-set rule does not fire and must not be stretched to fire.** That rule
     (`n ≥ 2` → register the copy-set in the byte-parity check, migrate the whole set or none) is
     about *n identical copies of one block*. This is **one template instantiated n times**.
     Registering non-identical text in a byte-parity check would fail on the first legitimate
     instantiation.
  2. **The invariant that *is* checkable, and the form above was shaped to make it cheap.** All
     per-site variance is confined to a single line — `S="<skill-name>"; P="scripts/<name>.mjs"`.
     Every other line of the block, including the diagnostic, refers only to `$S` and `$P`. So the
     registrable invariant is a **normalized-form check**: every Copilot invocation fence must
     match the authoring spec's block byte-for-byte after excluding that one assignment line.
     *Counter-example attempted and found:* a site that passes arguments also varies the final
     `node "$F"` line, so the exclusion set is two lines, not one, for any such site — the check
     must be written against the spec's block, not against a sibling copy.
  3. **This record does not add that gate, and the reason is not cost.** The population is **zero
     today** and reaches ~6 only when the conversions land.
     `standards/skill-decomposition/executable-content/script-and-gates.md § Extending the Repo's
     Gates` requires a new gate be verified by planting a deliberate violation and observing
     it fire; a gate written against a population that does not exist yet cannot be verified that
     way. **The obligation is therefore assigned: the task that lands the last conversion either
     registers the normalized-form check in the same commit, or files it with the measured copy
     count.** Until then the control is that the authoring spec is the single source and every
     converting commit copies from it — which is a prose control, and prose controls are what
     ADR-017's Context section demonstrates are insufficient.
- **Issue #48 is unchanged — converting buys no correctness checking.** There is still **no
  JavaScript correctness linter anywhere in this repo** (verified for this record: no `.eslintrc*`,
  no `eslint.config.*`, no `biome.json`; the `security` workflow's `semgrep --config p/ci` does
  read `.mjs` but is a security ruleset, and shellcheck's scope is `git ls-files '*.sh'`). What the
  flip changes is that 19 programs become **lintable in principle** — a real file can be fed to a
  checker where a fenced string cannot — with no linter existing. Do not describe this record as
  buying correctness checking.
- **The Copilot half remains a design, not a measurement** (above), and this record **enlarges the
  unverified surface from 2 skills to about 6.** ADR-017's two settling tests stay open work.
- **A `.mjs` remains invisible to the ADR-016 byte gate**, and this record routes far more content
  into that blind spot. § Disqualified is the control, and it depends on authors honouring a rule
  no machine checks.
- **The comma-operator dodge** is available and uncheckable (above).

**Neutral, and worth recording because it was checked:**

- **No conversion candidate is shared across skills**, so **no `.githooks/pre-commit` byte-parity
  registration is required by this record.** SHA-256 over all 22 program bodies found exactly one
  duplicate pair, and both members live in `skills/plugin-design/` — one skill, one `scripts/`
  directory, one copy — and both stay inline anyway. *Blind spot, named:* SHA-256 is exact-match, so
  two programs doing the same job with different text across two skills would not be detected.
- **Migrating the `icon-audit` site is gate-neutral, not a loss.** `skills/*.mjs` matches
  `skills/<skill>/scripts/<name>.mjs` in the hook's `case` globs, so any `.mjs` under `skills/`
  falls inside the dead-reference and cap-literal gates. `.claude/skills/…` does not match — but
  `.claude/` is in no gate scope today either.

## Alternatives Considered

1. **"Defines a function" as the whole test** — rejected. Partitions the corpus 9/13. It splits two
   sites doing the same job (validating required manifest keys) purely on whether the author hoisted
   an arrow into a `const`, and is **gameable by inlining a lambda**. Under-inclusive: it leaves a
   13-line loop and a 19-line block with nested error handling inline.
2. **"Control flow beyond a single guard"** — rejected; the partition is not computable without
   arbitration. It requires deciding whether `try`/`catch` is a guard, whether a `.filter()` is
   control flow, and whether a `catch` containing a conditional rethrow is one guard or two. **Five
   arguable members** against a bar of three.
3. **"More than one statement"** — rejected. Zero ambiguity (20/2), but over-inclusive: it converts
   a 185 B four-line `statSync` probe at the fixed cost of a file plus an invocation contract, which
   is the exact complaint ADR-017's trivial test makes, and it empties the inline tier down to two
   identical one-liners.
4. **"Declares bindings consumed later"** — rejected. Same 20/2 partition as 3, and **gameable by
   inlining a binding**: `const d = JSON.parse(x); if (!d.name)` would be a program while
   `if (!JSON.parse(x).name)` is a command, for no difference that matters. The body test does not
   have this hole — collapsing a two-statement branch means doing less, not hiding more.
5. **A byte threshold** — rejected, again and for ADR-017's original reasons plus a new one: the
   measured partition crosses byte order in both directions, so no monotone threshold reproduces it.
6. **Amend ADR-017 in place** — rejected. The disposition test is *"did the position change, or only
   the world it described?"* The position changed: which of two homes is the default. Amendment is
   reserved for a supporting fact, a consequence, or a rejection's grounds where the Decision still
   holds. ADR-017's `## Amendments` section also already carries two entries from this same task and
   **both open by asserting "The Decision has not changed"**; a third saying the opposite would
   contradict its own section's established reading.
7. **Fully supersede ADR-017** — rejected, and the guidance says so directly: *"Do not supersede an
   ADR whose Decision still stands."* Most of it does, it is cited as the live rule by
   `rules-index.md`, the authoring spec, `shell-portability` Rule 11 and `ROADMAP.md`, and freezing
   it would strand all of them.
8. **Two separate records, one per correction** — rejected. They are the same thesis and they must
   land together or the first is inert: making `.mjs` the default for programs while the unamended
   precondition still blocks conversions in skills with no degradation path would prescribe a
   disposition its own neighbour forbids.
9. **Keep the scope narrow and convert only one skill** — rejected once the two constraints behind
   it were answered rather than overruled. The degradation-path blocker is gone, and the Copilot
   blast radius is now mitigated at the mechanism rather than by keeping the count low. Going from
   2 skills to 6 with a form that discovers and refuses to guess is a better position than 2 skills
   with a form that names a slug this very machine contradicts. Reviewability is answered by
   sequencing the **commits** per skill, not by narrowing the scope.
