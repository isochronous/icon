# The Invocation Contract

What an author writes around a block that a committed `.mjs` now carries. Reproduce this shape — it
is four parts and all four are required — then satisfy the prose-contract test at the end.

## 1. The guard is a prose precondition — not shell, not a script

It cannot be a script: a `.mjs` that reports Node's absence cannot run in the case it exists to
detect (`check-node-runtime`). It cannot be shell either: PowerShell leaves `$LASTEXITCODE` stale on
`CommandNotFoundException`, so `node x.mjs; if ($LASTEXITCODE -ne 0)` reads the *previous* command's
status and fails open silently (ICON-0096).

**The guard applies to any Node-dependent block, inline or `.mjs`.** ADR-018 measured the
Node-absence exposure byte-identical on both forms across bash, PowerShell 7 and Windows PowerShell
5.1, so there is no asymmetry that would let the inline command tier skip it. It has two clauses.

**Clause 1 — Node presence.** Write it as prose addressed to the agent:

> **Precondition — confirm Node is present before running this block.** Run `node -v` and read its
> **output**, not its exit status. If Node is absent, do not run the block — invoke
> `check-node-runtime`, which reports what stops working and offers a per-platform install.

There is nothing per-skill to invent, and no skill needs a degradation path of its own before it may
migrate. `check-node-runtime` already ships that behaviour uniformly, and it is reachable in exactly
the case it detects: its detector is `node -v` and every interpretation step is a prose table, so it
needs no Node.

**Clause 2 — if the documented pass state is silence, emit an affirmative token instead.** Clause 1
cannot cover this, because **Node being present does not establish that the block ran.** Two
measured failure modes produce empty stdout with Node present: inline PowerShell 5.1 quote-stripping
(Rule 11), and, for `.mjs`, an unresolved script path (`Cannot find module`, exit 1). Where silence
is the pass, both read as clean and a documented hard stop is skipped.

Print a token on **every** branch — `NOT_INITIALIZED` / `INITIALIZED`, not one branch and silence —
and have the caller require one of them. **This binds on inline commands too**, not only on
migrated scripts.

## 2. The Claude Code fence is untagged

`${CLAUDE_SKILL_DIR}` is substituted *before the model reads the skill*, so the agent sees
`node "<absolute path>"` — byte-identical in bash, sh, zsh, PowerShell 5.1 and 7, and cmd. **The
untagged fence is what stops a PowerShell twin from being re-added later.** Do not tag it `bash`.

````markdown
### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/<name>.mjs"
```
````

## 3. The Copilot CLI fence is bash-tagged, and is the only survivor

Copilot exposes no path variable at any level, so the path is reconstructed. **Reproduce this block
byte-for-byte, substituting only the two placeholders on the `S=`/`P=` line.** It discovers the
marketplace directory rather than naming it, handles an install path carrying a version segment, and
**fails closed with the match count** on ambiguity rather than picking silently. `${VAR+x}` is a
presence test per `shell-portability` Rule 5 — `${MARKETPLACE_NAME:-*}` would violate it, because
Rule 5's live case is a fork setting the value deliberately empty and `:-` discards that.

````markdown
### Copilot CLI (Bash)

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
````

**This block is a template instantiated once per site, not a shared copy-set.** All per-site
variance is confined to the `S=`/`P=` line (plus the final `node` line if the script takes
arguments); every other line refers only to `$S` and `$P`. The byte-parity check in
[script-and-gates.md](script-and-gates.md) does **not** apply to it — registering non-identical text
there would fail on the first legitimate instantiation. Copy from *this* block, never from a sibling
skill's copy.

**A maintainer-only skill under `.claude/` takes no Copilot fence at all** — it is never installed
through a marketplace. Invoke it by a plain repo-relative path in one untagged fence.

**Ship no PowerShell Copilot variant.** No shipped Copilot *invocation* fence has one, and adding one
recreates the entire parity burden this rule exists to remove — for a path string. *Counter-example
found and scoped:* `find-context-template` does ship a Copilot PowerShell block, but it reconstructs
a **resource path** (`context_template/`) rather than invoking a script, and that skill is an E2
bootstrap exclusion. It is not a precedent for an invocation.

**The layout is designed for and untested.** The block was verified against eight constructed
fixtures, not against a real Copilot install; ADR-018 records what that does and does not establish.
Do not describe the Copilot half as verified.

## 4. Document the outcomes in `SKILL.md`

A table of every stdout token, its exit code, and what the caller does with each. This is not
optional garnish; it is half of what makes the prose contract survive.

## The Prose Contract Must Survive

**If the section shrinks to "run the script", the migration failed.** What stays in `SKILL.md`:

- What the script decides, and the signals it keys on.
- The precedence between those signals, where order is load-bearing.
- What every outcome means, and what the caller does with each.
- What happens when Node is absent, per the Clause 1 guard above.

What leaves: the mechanics of *how* the decision is computed.

The test: a reader who never opens the script should still be able to say what it will conclude for
a given repo, and what happens next. If they cannot, put the prose back.

**`SKILL.md` may grow as a result, and that is expected.** Migration is not a size-reduction
technique. Do not record a byte reduction as the win, and do not write one into a task's acceptance
criteria.

## Related

- Index: [executable content](README.md)
- Governed by: [ADR-018 the body test, program vs command](../../../decisions/018-body-test-program-vs-command.md) — the two-clause guard and the hardened Copilot reconstruction
- Governed by: [ADR-017 executable content home](../../../decisions/017-executable-content-home.md) — the untagged Claude Code fence and the prose-contract survival obligation
- Prior step: [classification.md](classification.md) — deciding whether a block reaches this contract at all
- See also: [shell portability Rule 5](../../shell-portability/rules/005-presence-test-var-plus-x.md) — the `${VAR+x}` presence test the Copilot fence turns on
- See also: [shell portability Rule 11](../../shell-portability/rules/011-powershell-51-strips-embedded-quotes.md) — one of Clause 2's two measured empty-stdout modes
