# The Committed Script, and What Its Arrival Obliges

Constraints on the `.mjs` file itself, and the two repo-level obligations that land when one is
added.

## The Node Floor

`.mjs` files are ESM, so `node:`-prefixed `import` is permitted and preferred — those specifiers
arrived in the 12.20 / 14.13 line, which *is* the published technical floor.

- **Never `require`.** `require("node:fs")` raises the floor to 14.18 / 16, and `.mjs` has no
  `require` anyway. This is scoped to `.mjs`: an inline `node -e` command runs as CommonJS and must
  use `require("fs")`.
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
ships as *n* copies — see [infrastructure-and-distribution.md](../infrastructure-and-distribution.md)
§ Skills Cannot Share Scripts. Migration does not change that count. What it changes is that
duplication becomes **detectable** rather than silent.

Therefore, when *n* ≥ 2 skills carry **byte-identical copies of one block**:

- Add the copy-set to the byte-parity check in `.githooks/pre-commit` **in the same commit**.
- Migrate **the whole set or none of it.** A half-migrated set is worse than either end state.

**This does not reach the invocation preamble**, which is one template instantiated *n* times rather
than *n* identical copies — see [invocation-contract.md](invocation-contract.md) § 3. Do not stretch
the rule to cover it. ADR-018 records the open obligation there: a **normalized-form** check, which
compares each Copilot fence against the spec's block while excluding the per-site assignment line,
is the registrable invariant, and it is owed by the task that lands the last conversion.

## Extending the Repo's Gates

`*.js` does **not** glob-match `.mjs`. A block inside a `SKILL.md` is covered by the dead-reference
and cap-literal gates because the whole `.md` is; moving it into a `.mjs` removes it from both
unless the gate scopes are extended.

**The first `.mjs` added under a gated tree extends that gate in the same commit.** Verify the
extension by planting a deliberate violation and confirming the gate fires, then revert it — proving
it works, not asserting that it should.

## Related

- Index: [executable content](README.md)
- Governed by: [ADR-017 executable content home](../../../decisions/017-executable-content-home.md) — the Node floor and the shared-set rule
- Governed by: [ADR-018 the body test, program vs command](../../../decisions/018-body-test-program-vs-command.md) — why the invocation preamble is outside the shared-set rule, and the normalized-form check it leaves owed
- Prior step: [invocation-contract.md](invocation-contract.md) — the prose and fences that accompany the file
- See also: [infrastructure-and-distribution.md](../infrastructure-and-distribution.md) — why an installed skill cannot reference a script outside its own directory
