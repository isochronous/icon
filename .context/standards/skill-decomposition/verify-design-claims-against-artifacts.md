# Verify Design Claims About Gate/Hook/Config Behavior Against the Artifact

Discipline that applies BEFORE dispatching @coder on a design: a design or @architect deliverable's claim about what a gate, hook, event matcher, or config requires is a hypothesis about another file's behavior, not an observation of it — cross-check it against the actual artifact before relying on it.

## Verify Design Claims Against the Artifact

A design or @architect deliverable that states what a gate, hook, event matcher, or config **requires** (or does NOT require) is an unverified claim until it is cross-checked against the actual artifact. Before dispatching @coder on the design, open the named gate/hook/matcher/config file and confirm the claim holds. A confident, well-reasoned design is exactly the failure mode here — its fluency makes the wrong behavioral assertion read as settled fact, and the dispatched @coder inherits it without re-checking.

**The check is mechanical and cheap**: the design names the runtime element (a pre-commit gate, a `hooks.json` matcher, an `iconrc.json` field, a CI rule); open that file, locate the relevant rule, and confirm the design's claim matches what the file actually does. Cost is one file read; the saved cost is a blocked commit, a shipped-but-wrong runtime claim, or a mid-implementation @coder round-trip when the gate fires unexpectedly.

**Four occurrences on this axis:**

1. **ICON-0061** — a SessionStart bootstrap design claimed the manager role "persists across `/clear`", but at design time `hooks/hooks.json`'s SessionStart matcher was `startup|resume` (no `clear`), so the hook never re-fired on `/clear`. The confident runtime claim would have shipped into user-facing payload text. Caught by cross-checking the claim against the matcher before dispatching @coder.
2. **ICON-0065** — the @architect design asserted that no `context_template/context/iconrc.json` version bump was required for the change, but the ICON-0044 `.githooks/pre-commit` gate (made release-aware in ICON-0062) requires that bump on ANY `context_template/` change and would have blocked the commit. Caught by cross-checking the design's claim against the actual gate before dispatching @coder.
3. **ICON-0073** — a PreToolUse guardrail-hook spec built from Copilot CLI's official docs + its SDK type definitions was wrong on three runtime counts (hook-loading path, snake_case vs. camelCase stdin keys, which `hooks.json` field form actually executes), and one would have bricked every Copilot session — a hook that errors makes Copilot fail-CLOSED and deny every tool call. Caught by a live probe (patch the installed plugin's `hooks/hooks.json`, run `copilot -p`, capture stdin/env/exit, restore) before any commit.
4. **ICON-0076** — a secure-coding rule restated ADR-007 as a blanket "no new `2>/dev/null` in ICON's own scripts", but ADR-007 scopes the devnull ban to agent-invoked SESSION commands and explicitly EXEMPTS autonomous `.githooks/*` and `skills/*/scripts/*.sh` — the opposite of the claim for exactly those files. The miscited rule would have flagged the pre-commit hook's own git-probe suppressions. Caught by @reviewer reading the ADR's scope section against the claim.

**External-tool corollary (ICON-0073)**: when the "artifact" whose behavior a design depends on is an external tool or harness rather than a static file in this repo, "verify against the artifact" means EXECUTE against the real tool — probe its actual I/O (stdin shape, env, exit codes, which config field runs) by running it, not by reading its documentation or SDK type definitions, which can be wrong, stale, or harness-specific. Weight this higher when the integration is fail-closed or safety-critical: there a wrong runtime assumption does not merely fail loudly at commit time, it can brick every session (an erroring fail-closed enforcement hook denies all tool calls). For such paths the verification step is a live probe, and the design's worst case must be fail-OPEN by construction.

**Cited-ADR-scope corollary (ICON-0076)**: an ADR is an artifact too — when a rule, standard, or doc restates an ADR as its authority, read the ADR's scope section and confirm it actually decides what you claim, because an ADR is often narrower than its title suggests. In ICON-0076 a secure-coding rule restated ADR-007 as a blanket "no new `2>/dev/null` in ICON's own scripts" — but ADR-007 decides the OPPOSITE for those files: it scopes the devnull ban to agent-invoked SESSION commands and explicitly EXEMPTS autonomous `.githooks/*` and `skills/*/scripts/*.sh`. The rule miscited its own authority and would have flagged the pre-commit hook's own git-probe suppressions. Citing an ADR by title or remembered gist is the same hypothesis-not-observation failure as restating a gate's requirement; open the ADR and confirm its scope before relying on it.

**Anti-rationalization:**

| Excuse | Reality | Correct Action |
|---|---|---|
| "The architect already reasoned about the gate; restating its requirement is settled" | The architect's claim about a gate is a hypothesis about another file's behavior, not an observation of it. | Open the gate/hook/matcher/config file and confirm the claim before dispatch. |
| "The design is internally consistent and well-argued" | Internal consistency is independent of whether the external artifact behaves as the design assumes. Both ICON-0061 and ICON-0065 had fluent, self-consistent — and wrong — claims. | Treat fluency as a reason to verify, not a substitute for it. |
| "If the claim were wrong the gate would just fail and we'd catch it then" | Catching it at commit time is a blocked commit and a @coder round-trip; ICON-0061's class would have shipped into user-facing text where no gate fires. | Cross-check before dispatching implementation, not after the gate fires. |

**When NOT to use**: designs that make no claim about a gate/hook/matcher/config requirement — pure content or structure edits with no runtime-behavior assertion. The check applies specifically to design claims about what an enforcement artifact requires or permits.

**Precedents**: ICON-0061 (design claimed `/clear` re-injection the `hooks.json` matcher did not support — caught against the matcher), ICON-0065 (design claimed no `iconrc.json` version bump required — caught against the `.githooks/pre-commit` gate), ICON-0073 (spec built from Copilot CLI docs + SDK types was wrong on three runtime counts, one session-bricking — caught by a live `copilot -p` probe), ICON-0076 (a rule miscited ADR-007's scope as the opposite of what the ADR decides for the files in question — caught by reading the ADR's scope section). Four instances on this axis; the ICON-0073 firing extended the principle to external-tool/harness runtime contracts (verify by live execution, weight higher when fail-closed), and the ICON-0076 firing extended it to a cited ADR's scope (read the ADR before restating its authority).


---

See [`../skill-decomposition.md`](../skill-decomposition.md) for the full skill-decomposition index.
