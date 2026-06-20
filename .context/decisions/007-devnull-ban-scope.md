# ADR-007: `2>/dev/null` ban applies to agent-invoked commands only, not to autonomous scripts

**Date**: 2026-05-21
**Status**: Accepted

## Context

The `shared/common-constraints.md § Shell command self-check` rule directs every ICON agent to scan its own commands for `2>/dev/null`, `>/dev/null`, and `1>/dev/null` before running them. The rule has been in place since well before the ICON-0015 audit and now ships into every `agents/*.agent.md` file via the `.githooks/pre-commit` common-constraints sync.

The in-rule justification given to the agent is a correctness frame: "stderr is diagnostic signal; suppressing it converts visible failures into hidden ones." That framing reads as a general bash-hygiene rule, which led successive audit cycles (ICON-0003, prior MKT-numbered cycles, and ICON-0015) to flag `2>/dev/null` occurrences anywhere they appeared — including in autonomous scripts that ship to consumer repos and run with no agent in the loop. Audit finding **m1** (`context_template/context/workflows/prune-context.sh` — 7 occurrences as of ICON-0015) is on its fourth carry-forward cycle for exactly this reason.

The actual maintainer rationale, surfaced during the ICON-0015 work-item #24 (O-X2) re-tier discussion, is narrower: `2>/dev/null` triggers Copilot CLI's "potentially dangerous shell command" sandbox prompt and requires explicit user permission before the command runs. The cost of the rule is therefore an *in-session friction cost* paid by users of agent runtimes, not a correctness debt paid by consumers running shipped scripts.

## Decision

The `2>/dev/null` ban applies **only to commands an agent proposes or executes during a Claude / Copilot CLI session**. It does **not** apply to:

- `.githooks/*` (post-commit, pre-commit, etc.) — run autonomously by git in consumer repos.
- `context_template/context/workflows/*.sh` — shipped scripts invoked by git hooks in consumer repos.
- `.claude/skills/*/scripts/*.sh` — maintainer-only release helpers run from a fully-trusted shell (`release-plugin`, `changelog-entry`).
- `skills/*/scripts/*.sh` — utility scripts called by skills via documented invocations where the agent has already approved the call shape once.

Audit briefs and reviewers must check execution context before tiering a `2>/dev/null` finding. If the script in question is not directly invoked by an agent's `Bash` tool call during normal use, the finding is **out of scope of the ban** and should not be raised as a Minor.

The user-facing rule text in `shared/common-constraints.md` retains its current "stderr is diagnostic signal" framing — that wording is doing its job (steering the agent away from the pattern in the moment) and replacing it with the longer Copilot-CLI-friction explanation would weaken the immediate signal. This ADR is the source of truth for the *scope* of the rule; the agent-facing rule is the source of truth for the *behavior*.

## Consequences

**Positive:**
- Audit cycles stop re-surfacing `2>/dev/null` findings in autonomous scripts (`prune-context.sh` m1, plus any future similar findings) as carry-forward Minors.
- Authors of new shipped scripts know they do not need to contort around `2>/dev/null` for stylistic reasons; they should use it where it genuinely improves the script.
- The agent-facing rule stays terse and load-bearing — agents do not have to parse a scope carveout in the moment.

**Negative:**
- Reviewers must apply the scope check manually; there is no automated lint that distinguishes "agent-invoked" from "autonomous" scripts. The plugin-lint `>/dev/null` check referenced in `skills/icon-init/SKILL.md:245` operates on the agent surface only.
- The diagnostic-signal framing in `common-constraints.md` is technically a partial fiction (or at least, a secondary effect dressed up as the primary one). Future maintainers who read both the rule and this ADR will see the gap. The framing is preserved deliberately; this ADR is the place that gap gets reconciled.

## Alternatives Considered

1. **Rewrite the in-agent rule to cite the Copilot CLI prompt directly.** Rejected — the prompt-friction phrasing is less mechanically forcing than the stderr-as-signal phrasing. Agents apply the rule more reliably when the framing makes suppression look like a correctness bug, not a UX irritant.
2. **Strip `2>/dev/null` from all autonomous scripts anyway, for consistency.** Rejected — `prune-context.sh` and similar scripts legitimately use `2>/dev/null` to suppress expected "not found" errors during pattern matches over a directory tree that may or may not contain a given file. Removing the suppression would either require restructuring the scripts around `[[ -f ... ]]` guards (more code, same effect) or accept visible noise in consumer post-commit output for no user benefit.
3. **Add the scope carveout to `common-constraints.md` directly.** Rejected — `common-constraints.md` ships byte-equal into every agent file via the pre-commit sync; lengthening it lengthens the always-loaded surface by 8–10x (once per agent). The ADR is the right home for context that reviewers and audit briefs need, not the agent runtime.

## Cross-references

- Agent-facing rule: `shared/common-constraints.md § Shell command self-check` (line 16).
- Audit finding that prompted this ADR: ICON-0015 m1 (`prune-context.sh` 4th carry-forward), work item #24 Sub-task B (O-X2).
- Related: [ADR-004](004-tool-agnostic-content.md) (tool-agnostic content) — this ADR refines the scope of one tool-agnostic rule; it does not contradict ADR-004.
