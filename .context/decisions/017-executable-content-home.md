# ADR-017: Where executable content lives — prose, inline `node -e`, or a committed `.mjs`

**Date**: 2026-07-28
**Status**: Accepted
**Supersedes**: none
**Superseded-by**: none

## Context

ICON's skills carry a large body of executable content in fenced code blocks. Measured across
`skills/` and `context_template/`: **164 fenced `bash`/`powershell` blocks totalling 126,041 B**,
against **11 committed script files repo-wide**. Classified against the rule this record settles,
**78 blocks (99,137 B — 78.7% of the mass) are deterministic execution**: parse a manifest, walk a
directory, rewrite a file, validate a structure. Only **one** block in the whole corpus is
genuinely judgement.

That mass is a problem on three axes at once.

- **Shell parity.** 30 of those blocks are `bash`/`powershell` twins — 60 blocks, of which the 30
  PowerShell halves alone are 54,848 B. Every twin is a hand-maintained duplicate with nothing
  detecting drift between the halves. ADR-005 records the direction — *"the gap closes by migration
  to Node, not by adding PowerShell twins"* — and explicitly defers *"the migration itself"* as
  separate work. **This record is that work's rule.**
- **Nothing lints any of it.** shellcheck's gate scope is `*.sh` plus the two `.githooks/` files;
  **zero of the 164 fenced blocks are inside it.**
- **Cross-skill duplication.** The `.gitattributes` union-merge block exists in three skills — two
  copies already drifted, today, with nothing detecting it.

Against that sits a real counter-argument that has to survive: **a skill instructs an *agent*,
which sometimes needs to adapt a command mid-flight** — substitute a path, skip a step, branch on
what it found. A rigid script cannot be adapted, and some fences are illustrative rather than
runnable. That argument covers judgement. It does not cover parsing JSON or walking a directory.
What was missing was the boundary, not the direction.

## Decision

### The rule has four tiers, and inline `node -e` is the default

| Class | Home | Test |
|---|---|---|
| **Judgement** | prose, **no fence** | Could two competent agents, both following the instruction correctly, emit *different* commands? |
| **Illustrative** | fence with **no language tag** | Is this output to recognise, or a command to run? |
| **Trivial** | fence kept in place, **never migrate** (retagging is not migrating) | See *The trivial test* below. |
| **Deterministic** | **inline `node -e` — the default** | Shell-agnostic, no path resolution, no new file, no runtime guard. |
| **Deterministic + a trigger** | a committed `.mjs` under the invoking skill's own `scripts/` | One of the four triggers below. |

Inline `node -e` is formalised, not invented: **9 sites across 7 files** already use it, six of them
in untagged fences. Its one hazard is documented — interpolated text closes the program on a literal
`'`. Pass values through `process.argv`, never by interpolation.

**Untagged is not a synonym for illustrative.** An untagged fence carries either illustrative output
*or* a **shell-agnostic command** — one byte-identical in bash and PowerShell, where tagging it for
either shell would be a lie about which shells it works in. Nothing inside the fence separates the
two, so the surrounding prose must. That second reading is what lets a parity pair **retire**: where
a `bash` block and its `powershell` twin are already byte-identical, the twin is deleted and the tag
dropped from the survivor. **Retagging is not migrating**, so the **Trivial** row does not forbid it
— that row forbids rewriting a trivial block in another language, not dropping a shell tag it never
needed. The untagged Claude Code invocation fence below is the same case, reached by construction.

**A committed `.mjs` is the exception, not the target.** Four triggers, any one of which suffices:

1. **State crosses a fence boundary** — a variable set in one fence is read in another. Fences are
   independently runnable and nothing enforces their order, so this is a latent correctness bug
   whichever language it is written in.
2. **It mutates state** — `secure-coding` Rule 3 obliges live-fixture testing, and a committed file
   can be executed where a fence must be copy-pasted first.
3. **Invoked twice or more in the same skill** with different arguments.
4. **It cannot be single-quoted** — a literal `'` is structurally required by the program. Rephrase
   to avoid it first; this trigger is a last resort.

> ### Disqualified: `SKILL.md` being over the ADR-016 size gate is NOT a trigger
>
> **This is the control that stops cap-evasion, and it is load-bearing.** A `.mjs` is invisible to
> ADR-016's byte gate. That makes "move code into a script" look like a way to satisfy the gate by
> relocating bytes rather than reducing them. It is not, and it must never be the motive.
>
> An oversized `SKILL.md` is an ADR-016 **split obligation**, discharged by a companion `.md` the
> caps still measure. Relocating code into a file the gate cannot see does not discharge it — it
> conceals it. If a skill is over the gate and the only reason a block is being migrated is the
> byte count, **the migration is refused and the split is performed instead.**
>
> Size is never a trigger. Not as a tiebreaker, not as supporting evidence, not "among other
> reasons". The four triggers above are the whole list.

### The invocation contract

**The guard is a prose precondition, not shell and not a script.** It cannot be a script:
`check-node-runtime` records that a `.mjs` reporting Node's absence is *"self-defeating — it cannot
run in the case it is meant to detect"*. It cannot be shell either: ICON-0096 measured
`$LASTEXITCODE` staying stale on PowerShell's `CommandNotFoundException`, so
`node x.mjs; if ($LASTEXITCODE -ne 0)` reads the *previous* command's status and fails open
silently.

So the skill instructs the agent, in prose, to run `node -v`, **read its output rather than its
exit status**, and on absence take **a degradation path the skill already has**. *If a skill has no
such state, it is not ready to migrate.*

**The Claude Code fence is untagged.** `${CLAUDE_SKILL_DIR}` is substituted *before the model reads
the skill*, so what the agent sees is `node "<absolute path>"` — byte-identical in bash, sh, zsh,
PowerShell 5.1 and 7, and cmd. **That is where the twin dies.**

```
node "${CLAUDE_SKILL_DIR}/scripts/<name>.mjs"
```

**The Copilot CLI fence is the only survivor**, because Copilot exposes no path variable at any
level. Four lines of path reconstruction, matching the existing `context-maintenance` precedent:

```bash
# Override via MARKETPLACE_NAME=<your-marketplace-slug>, or edit this line in forks.
[ -n "${MARKETPLACE_NAME+x}" ] || MARKETPLACE_NAME="icon-marketplace"
SKILL_DIR="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins/${MARKETPLACE_NAME}/ICON/skills/<skill-name>"
node "$SKILL_DIR/scripts/<name>.mjs"
```

`${VAR+x}` is a presence test, per `shell-portability` Rule 5. **No PowerShell Copilot variant
ships** — the existing precedent ships none, and adding one recreates the whole parity burden this
record exists to remove, for a path string.

A migrated script takes its input from `argv`, prints its result to **stdout**, its diagnostics to
**stderr**, and never merges the two. Its exit code and its stdout must agree; where they can
disagree, the caller treats the run as failed.

### Node floor: no third number

`.mjs` is ESM, so **`node:`-prefixed `import` is permitted and preferred** — those specifiers
arrived in the 12.20 / 14.13 line, which *is* the published technical floor. **Never `require`**:
`require("node:fs")` is what raises the floor to 14.18 / 16, and `.mjs` has no `require` anyway. No
shebang. Standard library only (ADR-005). Shipped scripts match `hooks/*.mjs` exactly — with one
deliberate inversion: the harness hooks fail **open** by design, and a detector or validator must
fail **closed**.

### Exclusions: two axes, not a list

Per `skill-decomposition/boundary-axis-selection.md`, a carve-out list with five members signals the
wrong axis. There are two.

- **E1 — not executed from this repo by an ICON agent.** `generate-phase-launcher`'s launcher
  templates (emitted *into a consumer repo*, carry `ICON-NNNN` placeholders, and the skill already
  argues this itself in writing); **`context_template/`** (ships into consumer repos where the
  script would have to exist too, and ADR-016 excluded it on the same reasoning); non-program
  fragments that reference variables they do not set, and so have no entry point to hand an `argv`.
- **E2 — bootstrap.** `find-context-template`, whose job *is* resolving the plugin install path an
  invocation would need — irreducibly circular. `context-maintenance`'s invocation wrappers, which
  *are* instances of this contract rather than candidates for it.

`start-worktree` and `pr-feedback-triage` are **not** exclusions. The trivial test below already
excludes them correctly, and listing them would imply the rule needed help.

### The trivial test

> **If the Node version would have to shell out to do the same work, the block is already in the
> right language.**

Formally: it invokes only external tools with fixed arguments, has no control flow, sets no variable
another block reads, and a JavaScript rewrite would just wrap `child_process`. **Converse**: control
flow over a tool's *output* is deterministic, not trivial.

Grounding: 59 of the 164 blocks are trivial — **36% of the blocks, 4.1% of the bytes.** Migrating
one costs a file, an invocation preamble, a runtime guard and a degradation path to save 87 bytes.

### Cross-skill duplication migrates as a whole set, or not at all

`skill-decomposition/infrastructure-and-distribution.md § Skills Cannot Share Scripts` already
settles the shape: an installed skill cannot reference files outside its own directory, so **n
copies ship, and the duplication is the price.** What migration changes is not the copy count —
it is that **prose duplication is not preventing drift, it is hiding it.** Three copies of the
`.gitattributes` block exist today with two already diverged and nothing detecting it.

Therefore: when a migrated block is shared by **n ≥ 2** skills, adding the copy-set to the
`.githooks/pre-commit` byte-parity check is **mandatory in the same commit**, and the set migrates
**as a whole or not at all** — a half-migrated set is strictly worse than either end state.

### Relationship to ADR-005

**Peer, not amendment.** ADR-005 records the *direction* (Node, not more PowerShell twins) and
defers the migration; this record defines **"where practical"** and nothing in ADR-005 went stale,
so it gains a cross-reference and no `## Amendments` entry. ADR-005's constraints bind fully: no
package manifest, no lockfile, no install step, no third-party import, standard library only.

### Relationship to ADR-016

**Peer, non-overlapping scope — with the hazard stated rather than assumed away.** ADR-016 caps
per-file bytes for files an agent *reads*; this record governs where content an agent *executes*
lives. The contact points:

- **A `.mjs` is invisible to the ADR-016 size gate, by design.** That is a known hazard, not an
  oversight. The *Disqualified* block above is its control. So the invisibility does not silently
  widen, the dead-reference and cap-literal gates in `.githooks/pre-commit` were extended to
  `.mjs` in the same commit as this record's first application — `*.js` does not glob-match `.mjs`,
  so without that extension a migration is a **net loss of two gates**.
- **ADR-016 Alternative 4's rejection of `${CLAUDE_SKILL_DIR}` scopes to prose pointers and does
  not reach invocations.** Three grounds. The pointer case had a variable-free option — a bare
  filename the model can glob — and **the invocation case has none**: `node "scripts/x.mjs"`
  resolves against the consumer's cwd, not the skill directory. The failure is **loud**
  (`Cannot find module`, non-zero exit) where a mis-resolved pointer fails **silently**. And the
  invocation ships as a labelled per-harness pair by construction, which a prose pointer does not.
  **No ADR-016 amendment** — Alternative 4 is already titled for pointers; a paragraph scoping its
  rejection to prose pointers, and stating why invocations differ, was added to
  `skill-decomposition/hot-cold-path.md § Pointer Syntax`.

### Migration is not cap-evasion — the axis that settles it

Three acts, distinguished by **who the audience was**:

| Act | Audience | Verdict |
|---|---|---|
| **Withholding** — content removed, agent never gets it | the agent | Forbidden. |
| **Splitting** — content moved to a companion the agent `Read`s | the agent | Prescribed (ADR-016). |
| **Migrating executable content** to a script | **nobody — the agent was never the audience** | Permitted, gated below. |

A companion is *read* in order to know what to do. A script is read by nobody at runtime. Removing
bytes that served the machine withholds nothing from a reader who was never there.

Two obligations gate it, both hard:

1. **The prose contract must survive.** What the script decides, what each outcome means, and what
   the caller does with each — all stay in `SKILL.md`. **If the section shrinks to "run the script",
   the migration failed** and must be reverted or rewritten.
2. **Size may not be the motive.** See *Disqualified*, above.

### Portability: designed for, untested

ADR-004 requires content to work on both Claude Code and Copilot CLI. Everything above is
established for **Claude Code** from its published documentation: `${CLAUDE_SKILL_DIR}` is
documented and inline-substituted before the model reads the skill.

**Copilot CLI's script-invocation semantics are unestablished.** What *is* established is narrow and
negative: Copilot exposes **no path variable** at plugin level or skill level
(`domains/plugin-resource-paths.md`, both tables). Everything else — whether a plugin-shipped script
is present on disk at the reconstructed install path, whether the marketplace slug is stable,
whether an agent may execute a file from the plugin directory at all — is **designed for and
untested. It must not be described as verified.**

Two settling tests, in order:

1. Install ICON under Copilot CLI and run the Copilot fence verbatim from a repo root; observe
   whether the reconstructed `SKILL_DIR` path resolves to a real file.
2. Invoke the migrated skill under Copilot CLI on one repo that detects cleanly and one that must
   fail closed; observe whether the token reaches the agent and whether the failure path is taken.

Until both run, the Copilot half of this contract is a design, not a measurement.

## Consequences

**Positive:**

- The boundary is stated once, on an axis that does not need a special case for any member of its
  own domain, and every future skill inherits it.
- The bash/PowerShell twin collapses to a single untagged Claude Code fence plus four lines of
  Copilot path reconstruction — from ~4 kB of duplicated logic per pair to ~4 lines.
- Cross-skill duplication becomes **mechanically detectable** by the byte-parity check instead of
  drifting unobserved.

**Negative, and each of these is a live cost rather than a hypothetical:**

- **Issue #48 is shrunk, not closed.** There is **no `.mjs` correctness linter anywhere in this
  repo** — shellcheck does not read JavaScript, and its gate scope is `*.sh` plus the two
  `.githooks/` files. `semgrep --config p/ci` in the `security` workflow does cover `.mjs`, but it
  is a **security** ruleset, not a correctness one. What migration actually buys is that unlinted
  shell **ceases to exist** rather than becoming linted. The residual bash preamble on every Copilot
  invocation stays fenced and stays unlinted.
- **The byte-parity check refills rather than empties.** Migrating `append-retrospective-entry`
  takes its tracked population from 6 files to 3 — the "skills cannot share scripts" rule still
  forces three copies. Migrating the `.gitattributes` copy-set then adds 3 back. **Issue #23's task
  "retire the byte-parity check once its population is empty" is not achievable by migration in any
  wave**, and should be closed **won't-do** rather than carried forward.
- **A `.mjs` is invisible to the ADR-016 size gate by design.** The *Disqualified* reason above is
  the control that keeps that from becoming an evasion route, and the dead-reference and cap-literal
  gates were extended to `.mjs` so the invisibility does not silently widen to the repo's other
  checks. It remains a hazard that depends on authors honouring a rule a machine cannot check.
- **Migration is not a size-reduction technique and must not be counted as one in any task's
  acceptance criteria.** `SKILL.md` may well **grow**: the invocation contract, the Node-presence
  guard, and the outcome table cost more prose than the deleted fences cost in explanation. A task
  that migrates and reports a byte reduction as the win has applied this record incorrectly.

**Also negative, more ordinarily:**

- Three new obligations land on every migrating author — the prose-contract survival check, the
  parity-check registration for shared sets, and the surrounding-prose disambiguation of an untagged
  fence (nothing inside the fence separates illustrative output from a shell-agnostic command, so
  the prose around it must) — none of which a gate can enforce.
- The Copilot invocation hard-codes an install-layout path. If that layout changes upstream, every
  migrated skill's Copilot fence breaks at once, and nothing in this repo detects it.

## Alternatives Considered

1. **A byte threshold on the program — "over N bytes of logic, it becomes a script" — rejected.**
   Two independent reasons, the second decisive. First, it measures the wrong property: a 200 B
   block that sets a variable another fence reads is a latent correctness bug, and a 3 kB block of
   fixed-argument tool invocations is fine where it is. Second, **it is the same axis ADR-016
   already polices, and a second number on one axis is precisely the nine-rules-in-four-units defect
   ADR-016 exists to end.** Adding it would also hand cap-evasion a sanctioned form, which the
   *Disqualified* block exists to forbid.
2. **"Does it write?" alone as the boundary — rejected.** Mutation is a genuine trigger and is kept
   as one of the four. As the *whole* rule it is both over- and under-inclusive: it would migrate
   trivial one-line `git`/`gh` mutations that a Node version could only implement by shelling out
   (36% of the corpus by block count), while leaving read-only cross-fence state — the actual
   correctness bug — fenced.
3. **Reuse count alone ("invoked ≥ 2×") — rejected.** Also kept as one of the four triggers, and
   also insufficient alone. It says nothing about a block invoked once that mutates a consumer's
   repo, which is the highest-risk shape in the corpus, and it would drag trivial repeated
   one-liners across the boundary for no gain. Reuse is evidence of value, not of correctness risk.
4. **Migrate everything deterministic to committed `.mjs` — rejected.** 78 blocks and 99,137 B, of
   which one skill is 67.6%. It would create dozens of files each carrying an invocation preamble, a
   runtime guard and a degradation path, and it ignores that inline `node -e` already gets the
   portability win with none of that overhead. Hence inline `node -e` as the default and `.mjs` as
   the trigger-gated exception.
5. **Add PowerShell twins for the remaining bash-only scripts instead — rejected**, and already
   rejected by ADR-005 on a user decision. It doubles the surface it is meant to fix and adds no
   detection of drift between the halves.
