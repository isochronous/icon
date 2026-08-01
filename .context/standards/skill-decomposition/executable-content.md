# Executable Content in Skills

Where a skill's executable content lives: prose, an untagged fence, an inline `node -e`, or a
committed `.mjs` under the skill's own `scripts/`. This file is the authoring spec. The reasoning,
the corpus measurements, the rejected boundary axes and the portability caveat live in
[ADR-017](../../decisions/017-executable-content-home.md).

Judgement stays as prose. Deterministic execution moves to a program taking `argv`. This file states
where the line falls and what an author must write on each side of it.

## The Rule

| Class | Home | Test |
|---|---|---|
| **Judgement** | prose, **no fence** | Could two competent agents, both following correctly, emit *different* commands? |
| **Illustrative** | fence with **no language tag** | Is this output to recognise, or a command to run? |
| **Trivial** | fence kept in place, **never migrate** (retagging is not migrating) | See *The Trivial Test*. |
| **Deterministic** | **inline `node -e` — the default** | Runs in bash, sh, zsh and PowerShell 7; no path resolution, no new file, no runtime guard. **Not** Windows PowerShell 5.1 if the program body contains a `"` — see below. |
| **Deterministic + a trigger** | committed `.mjs` under the invoking skill's own `scripts/` | One of the four triggers below. |

Inline `node -e` is the default, not a compromise. Pass values through `process.argv` — **never by
interpolating them into the program text.** An interpolated value containing a literal `'` closes
the program.

**Say which shells the block runs in, in the prose next to it.** Windows PowerShell 5.1 does not
escape a `"` embedded in a native command's argument, so an inline `node -e` program whose body
contains a double quote reaches Node with those quotes deleted and dies on a `SyntaxError` —
measured on 5.1.26100, and true of all 22 such sites shipped today. PowerShell 7 and bash are
unaffected, and so is the `.mjs` invocation form below, which has no quote inside an argument
value. `shell-portability` Rule 11 carries the measurement, the pairing with a silent-pass contract
that turns the failure into a false pass, and why outer-double/inner-single is not a general fix.
A block that must run on 5.1 is a block that belongs in a committed `.mjs`.

**Port the block's semantics, not its shape** — per `shell-portability` Rule 10, a Node API that
mirrors a shell construct's shape can be inverted against its behaviour, so check each construct
against the original rather than adopting one mapping for the whole block.

### An untagged fence means one of two things

**Untagged is not a synonym for illustrative.** A fence with no language tag carries either:

- **illustrative output** — something to recognise, not to run; or
- **a shell-agnostic command** — one byte-identical in bash and PowerShell, where tagging it for
  either shell would be a lie about which shells it works in.

Nothing inside the fence separates the two, so **the surrounding prose must**: say "run this" for a
command, and name what is being shown for output. The Illustrative row's test asks the same
question; an untagged command is the other answer to it, not an exception to the table.

The shell-agnostic reading is what **retires a parity pair.** Where a `bash` block and its
`powershell` twin are already byte-identical, delete the twin and drop the tag from the survivor:
one fence, correct in both shells, with nothing left to drift. The invocation contract's Claude Code
fence below is the same case reached by construction rather than by inspection.

**Retagging is not migrating.** The **Trivial** row forbids rewriting a trivial block in another
language; it does not oblige a block to keep a shell tag it never needed. A byte-identical
`git`/`gh` pair collapsing into one untagged fence is that row being applied, not evaded.

## The Four Triggers For a Committed `.mjs` — Deterministic Blocks Only

**Classification precedes trigger evaluation.** The triggers below are reached only by a block *The
Rule* has already classified **Deterministic**. A block classified Judgement, Illustrative or
Trivial never reaches this list at all — so the Trivial row's *never migrate* never competes with a
trigger. A trivial block that mutates state is still trivial and still stays fenced: trigger 2 is
never evaluated for it. ADR-017 *Alternatives Considered* 2 settles that case explicitly — mutation
is a trigger, not the boundary, precisely because as the boundary it would drag trivial one-line
`git`/`gh` mutations across it.

A committed `.mjs` is the exception. Once a block is Deterministic, any **one** of these suffices;
none of them is size.

1. **State crosses a fence boundary.** A variable set in one fence is read in another. Fences are
   independently runnable and nothing enforces their order, so this is a latent correctness bug in
   whatever language it is written.
2. **It mutates state.** `secure-coding` Rule 3 obliges live-fixture testing, and a committed file
   can be executed where a fence must first be copy-pasted.
3. **It is invoked twice or more in the same skill** with different arguments.
4. **It cannot be single-quoted** — a literal `'` is structurally required. Rephrase to avoid this
   first; it is a last resort.

> ### Size is never a trigger
>
> **A `SKILL.md` over the 16,000 B gate is not a reason to migrate anything.** A `.mjs` is invisible
> to that gate, which makes migration *look* like a way to satisfy it. It is not.
>
> An oversized `SKILL.md` is an ADR-016 split obligation, discharged by a companion `.md` the gate
> still measures. If a skill is over the gate and the only reason a block is being migrated is the
> byte count, **refuse the migration and perform the split.**
>
> Not as a tiebreaker, not as supporting evidence, not "among other reasons". The four triggers
> above are the whole list.

## The Trivial Test

> **If the Node version would have to shell out to do the same work, the block is already in the
> right language.**

Formally, a block is trivial when all four hold: it invokes only external tools with fixed
arguments; it has no control flow; it sets no variable another block reads; and a JavaScript rewrite
would just wrap `child_process`.

**Converse:** control flow over a tool's *output* is deterministic, not trivial.

A `git`/`gh` one-liner is trivial. A loop over `git ls-files` that branches on what it finds is not.

## Exclusions

Two axes. If a block is outside both, the rule applies to it.

- **E1 — not executed from this repo by an ICON agent.** Content emitted *into* a consumer repo
  rather than run here (launcher templates carrying `ICON-NNNN` placeholders); everything under
  `context_template/`, which ships into consumer repos where the script would have to exist too;
  fragments that are not programs, because they reference variables they do not set and so have no
  entry point to hand an `argv`.
- **E2 — bootstrap.** Anything whose job is producing the path an invocation would need. Resolving
  the plugin install directory is irreducibly circular; so is an invocation wrapper, which *is* an
  instance of this contract rather than a candidate for it.

Do not add a third axis. A carve-out list that needs a special case for one member of its own domain
is a signal the boundary is on the wrong axis — see `boundary-axis-selection.md`.

## The Invocation Contract

Reproduce this shape. It is three parts and all three are required.

### 1. The guard is a prose precondition — not shell, not a script

It cannot be a script: a `.mjs` that reports Node's absence cannot run in the case it exists to
detect (`check-node-runtime`). It cannot be shell either: PowerShell leaves `$LASTEXITCODE` stale on
`CommandNotFoundException`, so `node x.mjs; if ($LASTEXITCODE -ne 0)` reads the *previous* command's
status and fails open silently (ICON-0096).

Write it as prose addressed to the agent:

> **Precondition — confirm Node is present before invoking.** Run `node -v` and read its **output**,
> not its exit status. If Node is absent, do not run the script — take <the skill's existing
> degradation path>.

**If the skill has no existing degradation path, it is not ready to migrate.** Do not invent one as
part of the migration.

### 2. The Claude Code fence is untagged

`${CLAUDE_SKILL_DIR}` is substituted *before the model reads the skill*, so the agent sees
`node "<absolute path>"` — byte-identical in bash, sh, zsh, PowerShell 5.1 and 7, and cmd. **The
untagged fence is what stops a PowerShell twin from being re-added later.** Do not tag it `bash`.

````markdown
### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/<name>.mjs"
```
````

### 3. The Copilot CLI fence is bash-tagged, and is the only survivor

Copilot exposes no path variable at any level, so the path is reconstructed from the documented
install layout. `${VAR+x}` is a presence test, per `shell-portability` Rule 5.

````markdown
### Copilot CLI (Bash)

```bash
# Override via MARKETPLACE_NAME=<your-marketplace-slug>, or edit this line in forks.
[ -n "${MARKETPLACE_NAME+x}" ] || MARKETPLACE_NAME="icon-marketplace"
SKILL_DIR="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins/${MARKETPLACE_NAME}/ICON/skills/<skill-name>"
node "$SKILL_DIR/scripts/<name>.mjs"
```
````

**Ship no PowerShell Copilot variant.** The existing precedent ships none, and adding one recreates
the entire parity burden this rule exists to remove — for a path string.

### 4. Document the outcomes in `SKILL.md`

A table of every stdout token, its exit code, and what the caller does with each. This is not
optional garnish; it is half of what makes the prose contract survive.

## The Prose Contract Must Survive

**If the section shrinks to "run the script", the migration failed.** What stays in `SKILL.md`:

- What the script decides, and the signals it keys on.
- The precedence between those signals, where order is load-bearing.
- What every outcome means, and what the caller does with each.
- The degradation path, and when it is taken.

What leaves: the mechanics of *how* the decision is computed.

The test: a reader who never opens the script should still be able to say what it will conclude for
a given repo, and what happens next. If they cannot, put the prose back.

**`SKILL.md` may grow as a result, and that is expected.** Migration is not a size-reduction
technique. Do not record a byte reduction as the win, and do not write one into a task's acceptance
criteria.

## The Node Floor

`.mjs` files are ESM, so `node:`-prefixed `import` is permitted and preferred — those specifiers
arrived in the 12.20 / 14.13 line, which *is* the published technical floor.

- **Never `require`.** `require("node:fs")` raises the floor to 14.18 / 16, and `.mjs` has no
  `require` anyway.
- **No shebang.** Invoke via `node <path>`, matching `hooks/*.mjs`.
- **Standard library only.** No package manifest, no lockfile, no install step (ADR-005).
- **Fail closed.** The harness hooks under `hooks/` fail *open* by design because a failing
  `PreToolUse` hook would brick a session. A detector or validator is the opposite: on any
  unanticipated failure it reports the indeterminate outcome and a non-zero exit, never a
  confident answer.
- **stdout carries the result; stderr carries diagnostics; the two are never merged.** Folding a
  diagnostic into the value channel is how a probe fails open. The exit code and the stdout token
  must agree.

## Shared Blocks Migrate As a Whole Set

An installed skill cannot reference files outside its own directory, so a block used by *n* skills
ships as *n* copies — see `infrastructure-and-distribution.md § Skills Cannot Share Scripts`.
Migration does not change that count. What it changes is that duplication becomes **detectable**
rather than silent.

Therefore, when *n* ≥ 2:

- Add the copy-set to the byte-parity check in `.githooks/pre-commit` **in the same commit**.
- Migrate **the whole set or none of it.** A half-migrated set is worse than either end state.

## Extending the Repo's Gates

`*.js` does **not** glob-match `.mjs`. A block inside a `SKILL.md` is covered by the dead-reference
and cap-literal gates because the whole `.md` is; moving it into a `.mjs` removes it from both
unless the gate scopes are extended.

**The first `.mjs` added under a gated tree extends that gate in the same commit.** Verify the
extension by planting a deliberate violation and confirming the gate fires, then revert it — proving
it works, not asserting that it should.

## Related

- Index: [skill-decomposition](../skill-decomposition.md)
- Governed by: [ADR-017 executable content home](../../decisions/017-executable-content-home.md)
- See also: [shell portability Rule 10](../shell-portability/rules/010-port-semantics-not-shape.md) — matching a shell construct's semantics rather than its shape when migrating it
- See also: [shell portability Rule 9](../shell-portability/rules/009-pass-values-as-arguments.md) — the `process.argv` obligation this file's default rests on
- See also: [shell portability Rule 11](../shell-portability/rules/011-powershell-51-strips-embedded-quotes.md) — the Windows PowerShell 5.1 limit on this file's inline `node -e` default
