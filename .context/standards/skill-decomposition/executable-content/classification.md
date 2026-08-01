# Classifying a Block: Where It Belongs

Which of the four homes a fenced block belongs in, and — once it is deterministic — whether it is a
*program* that gets a committed `.mjs` or a *command* that stays inline.

## The Rule

| Class | Home | Test |
|---|---|---|
| **Judgement** | prose, **no fence** | Could two competent agents, both following correctly, emit *different* commands? |
| **Illustrative** | fence with **no language tag** | Is this output to recognise, or a command to run? |
| **Trivial** | fence kept in place, **never migrate** (retagging is not migrating) | See *The Trivial Test*. |
| **Deterministic — a *command*** | **inline `node -e`** | It has **no body**. See *The Body Test*. Runs in bash, sh, zsh and PowerShell 7; no path resolution, no new file. **Not** Windows PowerShell 5.1 if the program body contains a `"` — see below. |
| **Deterministic — a *program*** | **committed `.mjs`** under the invoking skill's own `scripts/` | It has a **body**. See *The Body Test*. |
| **A command that fires a trigger** | committed `.mjs` | One of the four triggers below overrides the command default. |

Where a block is a command, inline `node -e` is the right home, not a compromise. Pass values
through `process.argv` — **never by interpolating them into the program text.** An interpolated
value containing a literal `'` closes the program. Inline runs as CommonJS, so use `require("fs")`
there; the "never `require`" rule in [script-and-gates.md](script-and-gates.md) is scoped to `.mjs`.

## The Body Test

**This is what decides between the two Deterministic rows.** Apply it only after *The Rule* has
already classified a block Deterministic.

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

The principle underneath both clauses is **one locus of control.** A command reads top to bottom in
a single pass: each branch does one thing and nothing is named for later. A program has a second
locus — a callable the reader must jump to, or a branch that is itself a small procedure. That is
what makes a block cost a fixture to test and a careful pass to review.

**Do not rephrase to dodge it.** Collapsing `if (x) { a(); b(); }` into `if (x) (a(), b());` removes
the body without removing the program. An author writing that has answered the question. No gate can
check this; it is author-honoured, like the other obligations in this spec.

**It is not size in disguise, and size may not be substituted for it.** ADR-018 measured a 269 B
program and a 402 B command in the same corpus; no monotone byte threshold reproduces the partition.
Apply the structural test, not a byte count.

**Say which shells the block runs in, in the prose next to it.** Windows PowerShell 5.1 does not
escape a `"` embedded in a native command's argument, so an inline `node -e` program whose body
contains a double quote reaches Node with those quotes deleted and dies on a `SyntaxError` —
measured on 5.1.26100 across the 22 inline sites that existed before ADR-018. ICON-0099 converted
the 19 of those that were programs to committed `.mjs`; the 3 still inline are commands, and all 3
contain a double quote. PowerShell 7 and bash are unaffected, and so is the `.mjs` invocation form,
which has no quote inside an argument value. `shell-portability` Rule 11 carries the measurement, the
pairing with a silent-pass contract that turns the failure into a false pass, and why
outer-double/inner-single is not a general fix. A block that must run on 5.1 is a block that belongs
in a committed `.mjs`.

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
fence is the same case reached by construction rather than by inspection.

**Retagging is not migrating.** The **Trivial** row forbids rewriting a trivial block in another
language; it does not oblige a block to keep a shell tag it never needed. A byte-identical
`git`/`gh` pair collapsing into one untagged fence is that row being applied, not evaded.

## The Four Triggers — Overrides on the Command Default

**Order of application: classification → the body test → the triggers.**

**Classification precedes trigger evaluation.** The triggers below are reached only by a block *The
Rule* has already classified **Deterministic**. A block classified Judgement, Illustrative or
Trivial never reaches this list at all — so the Trivial row's *never migrate* never competes with a
trigger. A trivial block that mutates state is still trivial and still stays fenced: trigger 2 is
never evaluated for it. ADR-017 *Alternatives Considered* 2 settles that case explicitly — mutation
is a trigger, not the boundary, precisely because as the boundary it would drag trivial one-line
`git`/`gh` mutations across it.

**The body test precedes them too, and they are no longer the whole list.** A block the body test
calls a **program** is already a `.mjs` and does not need a trigger. These four exist to pull a
**command** across the line anyway. Any **one** suffices; none of them is size.

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
> Not as a tiebreaker, not as supporting evidence, not "among other reasons". Neither the body test
> nor the four triggers admits a byte count.
>
> **ADR-018 made this control matter more, not less.** A rule that sends every program into a file
> the gate cannot see is exactly the rule an author reaches for when a `SKILL.md` is over cap. Size
> is never a trigger and **never an acceptance criterion** — do not write a byte reduction into a
> task's acceptance criteria, and do not report one as the win.

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
is a signal the boundary is on the wrong axis — see
[boundary-axis-selection.md](../boundary-axis-selection.md).

## Related

- Index: [executable content](README.md)
- Governed by: [ADR-018 the body test, program vs command](../../../decisions/018-body-test-program-vs-command.md) — the body test, and why it is not size in disguise
- Governed by: [ADR-017 executable content home](../../../decisions/017-executable-content-home.md) — the four tiers, the triggers, the trivial test and the exclusions
- Next: [invocation-contract.md](invocation-contract.md) — what to write once a block is classified `.mjs`
- See also: [shell portability Rule 10](../../shell-portability/rules/010-port-semantics-not-shape.md) — matching a shell construct's semantics rather than its shape when migrating it
- See also: [shell portability Rule 9](../../shell-portability/rules/009-pass-values-as-arguments.md) — the `process.argv` obligation the inline command form rests on
- See also: [shell portability Rule 11](../../shell-portability/rules/011-powershell-51-strips-embedded-quotes.md) — the Windows PowerShell 5.1 limit on the surviving inline `node -e` tier
