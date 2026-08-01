# Executable Content in Skills

Where a skill's executable content lives: prose, an untagged fence, an inline `node -e`, or a
committed `.mjs` under the skill's own `scripts/`. These files are the authoring spec. The reasoning,
the corpus measurements, the rejected boundary axes and the portability caveat live in
[ADR-017](../../../decisions/017-executable-content-home.md) and
[ADR-018](../../../decisions/018-body-test-program-vs-command.md), which flipped the default for
programs.

Judgement stays as prose. Deterministic execution moves to a program taking `argv`. These files state
where the line falls and what an author must write on each side of it.

| File | Covers |
|---|---|
| [classification.md](classification.md) | **Where does this block belong?** The four-tier rule, the body test that splits a deterministic block into program (a committed `.mjs`) and command (inline `node -e`), the four triggers that override the command default, why size is never one of them, the trivial test, the two exclusion axes, and what an untagged fence means |
| [invocation-contract.md](invocation-contract.md) | **What must I write around a migrated script?** The two-clause prose Node guard, the untagged Claude Code fence, the hardened Copilot CLI reconstruction, the outcomes table, and the prose-contract survival test |
| [script-and-gates.md](script-and-gates.md) | **What must the committed file satisfy, and what does its arrival oblige?** The Node floor, the shared-copy-set rule, and extending the repo's dead-reference and cap-literal gates to `.mjs` |

## Related

- Index: [skill-decomposition](../../skill-decomposition.md)
- Governed by: [ADR-018 the body test, program vs command](../../../decisions/018-body-test-program-vs-command.md) — the current default for a deterministic block, and the two-clause Node guard
- Governed by: [ADR-017 executable content home](../../../decisions/017-executable-content-home.md) — the four tiers, the triggers, the trivial test, the exclusions and § Disqualified, all still live
