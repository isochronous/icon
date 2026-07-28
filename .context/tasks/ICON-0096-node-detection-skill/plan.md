## Task: ICON-0096
## Branch: feature/ICON-0096-node-detection-skill
## Objective: Add a skill that detects whether Node is available, reports the result visibly, and guides installation when it is missing or too old — and make the session-start hook's current silent failure visible and routed to it. Closes GitHub issue #22 (Milestone 3, first item; prerequisite for #21 and #23).
## Folder: .context/tasks/ICON-0096-node-detection-skill/

## Phase State
- **Phase plan**: investigation → implementation → completion
- **Completed**: investigation
- **Current**: implementation   (status: pending)
- **Next**: completion
- **Loaded skill**: task-plan-phase-implementation
- **Branch**: feature/ICON-0096-node-detection-skill
- **Attempts (current phase)**: 1

## Decisions
- Task ID `ICON-0096` from `local_task_id_prefix` + next free slot — **not** from issue #22 (`.context/workflows/commit-conventions.md` § Task ID Generation).
- Phase plan omits `architecture`: the issue prescribes a bounded deliverable with its two hard constraints already stated. Unlike ICON-0095 this establishes no convention other skills inherit. If investigation shows the detector's shape is genuinely contested, add the phase then rather than pre-emptively.
- **#22 runs before #21 and #23** because both increase reliance on Node and the detector is what makes that safe. Sequencing set when M3 moved ahead of M1/M2.

## The two constraints (from the issue)
1. **The detector cannot itself be a Node script.** A `.mjs` that reports Node is missing is self-defeating.
2. **It must produce a visible signal, not a silent no-op.** Reproducing the current failure mode would be worse than not building this. Harness hooks must **fail open** — so the signal has to be a message, never a block.

**Constraint 1 is satisfied by `node -v`** (maintainer, this turn). It is one command that runs identically in bash and PowerShell, so the detection needs no `.sh`/`.ps1` pair and **the "no new PowerShell twins until #23" policy is not engaged at all.** An earlier draft of this plan treated the detector's shape as an open design question and flagged a policy conflict; both were manufactured by overweighting the easy half of the task. Recorded because the same reflex — assuming a cross-platform primitive needs a twin — would produce the same false conflict again.

**The real work is constraint 2**, and it is where the only genuine unknown sits: what, if anything, either harness surfaces when a `SessionStart` hook cannot execute.

### If constraint 2 conflicts with reality, the constraint changes
Maintainer ruling, this turn: *"if a technical requirement conflicts with reality, then the technical requirement should change, because reality isn't going to."*

This matters here because of a near-tautology: **a hook that cannot run cannot report that it did not run.** The only thing that can report the hook's absence is something that executes later. Pre-committing to the disposition so it is not decided under pressure once the answer arrives:

| Investigation finds | Disposition |
|---|---|
| A failed hook can still inject context (the mechanism the hook already uses for role injection) | Requirement stands as written — implement it in the hook. |
| Stderr surfaces only somewhere narrow (debug log, `/doctor`, a flag) | Requirement is **reworded** from "visible signal" to "visible in *X*". Shipping "visible" while meaning "visible with `--debug`" overstates what the fix delivers. |
| Nothing surfaces at all | **Amend issue #22's task list.** State plainly that the hook cannot report its own non-execution, and move the signal to paths that do execute: `icon-init` at setup, `icon-status` on demand, and the manager's Session Start noticing the role is absent. |

### Pattern worth watching — third instance this session
Three M1/M3 audit follow-ups have now carried a stated requirement that did not survive contact with the code: #15's D2 said to "reuse the PowerShell branch below it" when that branch was the *weaker* of the two and reusing it would have been a regression; #15's D6 asserted missing footers "disable the dangling-reference detection" when the real mechanism was an orphan flood aborting the audit; and #22 may be the third. That is a property of how audit findings were converted into tickets, not bad luck. **If it recurs, the fix belongs in the finding→ticket step, not in any individual ticket** — worth raising with the maintainer rather than absorbing silently a fourth time.

## Key Files
- `hooks/inject-manager-role.mjs` — the silent-failure path. If Node is absent the hook never runs, the manager role never injects, and the user gets no signal at all.
- `hooks/hooks.json` — the wiring; determines what the harness does when the hook fails.
- `.context/decisions/005-no-build-step.md` § Decision / "Assumed runtimes" — records that a bundled-runtime install need not expose `node` on PATH, and that a script depending on Node should verify rather than presume. This ADR is the warrant for the whole task.
- `.context/domains/hooks.md` § Cross-Platform Hooks — the Node-CLI reasoning is recorded **for Claude Code only**; Copilot CLI is unestablished.
- `skills/icon-init/SKILL.md` — the initialization path the new skill must be named from, so a fresh setup surfaces the problem before it causes one.
- `skills/using-skills/SKILL.md` + `README.md` — skill registration; `.githooks/pre-commit` gates the README row.
- `CHANGELOG.md` — `[Unreleased]` entry at task close.

## Investigation findings — measured on Claude Code v2.1.220

### The requirement changed, per the maintainer's ruling. Issue #22 amended.
A throwaway project with an exec-form `SessionStart` hook pointing at a nonexistent binary, run three ways, plus a control that spawns and exits 3.

**The harness detects the spawn failure and synthesizes a message** — `hook_response` in `--output-format stream-json` carries `"Executable not found in $PATH: …"` with `exit_code: 1`, `outcome: "error"`, and the debug log gets a distinct `[ERROR] Hook command failed to spawn (SessionStart:startup)` line the control does **not** produce.

**But plain `-p` mode showed nothing — for the ENOENT case and for the control.** No hook-error notice surfaced in headless output for either failure class. Whether the documented transcript notice is interactive-only was not settled and would need an interactive test.

**The decisive point is what ICON can change: nothing.** That signal belongs to the harness, about a script that never executed. No code inside `inject-manager-role.mjs` can make its own absence louder — the file is never read. Unsatisfiable, not hard. → **Issue #22's task rewritten**: detection moves to `icon-init` and `icon-status`, which execute regardless; the harness's own surfacing paths get documented so a user debugging "the role isn't injecting" knows where to look; `systemMessage` covers failures the hook *can* report.

### Two design questions closed by the same test
- **Exec form stays.** Shell form was attractive only because a shell emits "command not found" into the documented non-zero-exit path — but neither form surfaces anything in `-p`, so there is no visibility to buy, and the quoting / `.cmd`-shim problems `.context/domains/hooks.md` cites as the reason exec form was adopted stay avoided.
- **`/doctor` is not a fallback.** It validates hook configuration *shape* — a config-time linter, not a runtime health check — so it never reports a hook that failed to spawn.

### `systemMessage` — a mechanism worth knowing, and distinct from what the hook already uses
Documented universal JSON field, exit-0 only. `hookSpecificOutput.additionalContext` (what the hook uses today) injects into **Claude's** context as a system reminder; `systemMessage` displays a warning line **to the user**. Both can be emitted together. Applies when the script runs and finds a problem — not to the missing-Node case.

### Minimum Node version — ICON's to set, not the harness's
Nothing in the repo states one. Plain `.mjs` with `import`/`export`, `process`, JSON and strings has needed no flag since **Node 12** (April 2019) — the honest language floor. Node 12/13 printed an ESM `ExperimentalWarning` that cleared by 14, and since `SessionStart` surfaces stderr only on non-zero exit, that warning would not be user-visible anyway. **State the technical floor and note separately that anything pre-18 is EOL**, rather than asserting one number as if the harness imposed it.

### Version gates that determine what any of this means
- **v2.1.199** — `SessionStart`/`Setup`/`SubagentStart` show exit-code-2 stderr in the transcript. Earlier: debug log only, i.e. **silent by design**.
- **v2.1.204** — `hook_started` / `hook_progress` / `hook_response` stream events.

## Phase Handoff Log

_(no handoffs yet)_

## Progress
- [x] Investigation — hook spawn-failure behaviour measured empirically on v2.1.220; `systemMessage` mechanism found; version gates identified; minimum-Node question resolved as ICON's to set
- [x] Requirement amended on issue #22 — the hook cannot report its own non-execution
- [x] Update this plan with findings before any edit
- [x] Implementation — `skills/check-node-runtime/SKILL.md` (9,315 B, **no companion**; gate 1 never fires), wired into `icon-init` and `icon-status`, README row added
- [x] Implementation — harness surfacing paths documented split by audience; `systemMessage` added to the hook's three silent failure paths
- [x] **@reviewer pass** (tier complex, executed) — **changes requested**: 2 Moderate + 2 Minor, all shipped text; nothing structural
- [x] Remediation — all four fixed, plus two further stale `18` references the sweep caught
- [x] **@reviewer confirmation** — **approved**; Node EOL facts and the PowerShell wording both independently verified against external sources
- [x] `CHANGELOG.md` — two bullets, 22 and 20 words, distinct fix-classes on separate lines
- [ ] Completion: retrospective, commit, PR ← IN PROGRESS

## Implementation findings

### The load-bearing discovery: PowerShell does not update `$LASTEXITCODE` on `CommandNotFoundException`
The obvious detector — `node -v` then `if ($LASTEXITCODE -ne 0)` — reads a **stale** value and reports "Node present" in exactly the case the skill exists to catch. Measured on 7.6.3 **and** 5.1:
```
seeded LASTEXITCODE = 0
CAUGHT: System.Management.Automation.CommandNotFoundException
LASTEXITCODE AFTER node -v = [0]        <-- stale
```
bash returns 127, cmd returns 9009 (needs `cmd /v:on`; the naive `& echo %errorlevel%` reports 0 through parse-time expansion — a trap of its own). **Only PowerShell is silent about it.** @reviewer additionally established the *directionality*: with Node present, `$LASTEXITCODE` updates correctly, so exit-status checking fails **only** in the absent direction — a pure fail-open, the ICON-0094 shape, never a false "absent".

The skill therefore keys on **output strings**, not exit status. @reviewer attacked that replacement — a directory named `node` on PATH, a broken shim exiting 1, a shim printing nothing and exiting 0, locale variation — and **every failure mode degrades toward "absent", never toward a false "present"**, the opposite of the exit-status approach's failure direction. Its real weakness is label precision, not correctness.

### Two corrections to this plan, made by the work
- **The Node floor stated here (12) was understated.** Both hooks import `node:`-prefixed specifiers (`node:fs`, `node:os`, `node:path`), which arrived in the **12.20 / 14.13** line — below that the imports fail outright. That is the *technical* floor, imposed by the code.
- **The supported floor is a separate claim and was initially wrong.** Set at Node 18 on EOL grounds — but 18 EOL'd 2025-04-30 and 20 EOL'd 2026-04-30, so the skill would have emitted `Node runtime: OK` for a runtime ~15 months unpatched, from its primary output. Now stated as *"the lowest major still receiving security updates"* with the measured value (**Node 22**), the measurement date, and a source pointer — because a bare EOL-derived integer in shipped content goes wrong once a year in silence, with no gate that can catch it.

### The hook did have silent paths — three of them
`process.stderr.write` followed by `process.exit(0)`, and `SessionStart` surfaces stderr only on **non-zero** exit. Two of them skipped injection entirely while carrying a comment saying *"a real problem the user should see"* — a mechanism that never delivered it. Now emit `systemMessage` alongside; the malformed-settings path emits **both** fields, so a warning never costs the injection. The `stderr` writes were kept, which is what bounds the Copilot CLI risk: `systemMessage` is a Claude Code field and Copilot is expected — not verified — to ignore an unknown key. On the inject path the envelope is **byte-identical to before**, so the common path carries zero new exposure.

### A scope call that turned out to be required, not overreach
`.context/domains/hooks.md` asserted *"`node` is always on PATH wherever Claude Code runs"* — the premise this task disproves. @coder corrected it and flagged the call. @reviewer found it stronger than that: **ADR-005:43 names `domains/hooks.md § Cross-Platform Hooks` as the source of the overstatement.** The ADR downgraded the claim and left its own cited source contradicting it; this closed an incomplete edit rather than expanding scope.

### Discovered, not fixed — belongs to #21
`skills/icon-init/SKILL.md` Step 2b and `skills/icon-status/SKILL.md` both shell out to **`python3`**, which ADR-005 records as not an assumed runtime. Same defect class one layer down, in the two skills this task wired the Node detector *into*. Noted on #21 along with the `$LASTEXITCODE` finding, since any `python3`→Node rewrite guarding on a runtime hits the identical trap.

## Open Questions / Blockers
- **The one real unknown: what does each harness do when a `SessionStart` hook cannot execute?** Whether its stderr reaches the user at all is the premise the entire "visible signal" requirement rests on. If neither harness surfaces it, the fix cannot live in the hook and has to change shape. **Verify before designing** — `.context/workflows/task-start-conventions.md` § Referenced-convention existence (ICON-0081): a claimed behaviour is a hypothesis until checked.
- **How does a skill get invoked when the thing that would invoke it is broken?** If Node is missing the manager role never injects, so the agent may not be under the role that routes to this skill. Naming it from `icon-init` covers fresh setup; the already-installed-but-Node-disappeared path is open.
- **Minimum Node version — likely a smaller question than the issue implies.** ICON's hooks are plain `.mjs` with no exotic features, so the floor is roughly "supports ES modules", which is ancient. Check what the hooks actually use before inventing a number; if nothing in the repo states a minimum, say so and pick the lowest defensible one rather than an aspirational one.
- **`python3` must not appear in the detector either** — ADR-005 records it as not an assumed runtime (on Windows it resolves to a non-executing Store stub).

### Resolved without investigation
- ~~How to detect Node without Node~~ → `node -v`, one command, both shells.
- ~~The PowerShell-twin policy conflict~~ → never existed; see The two constraints.

## Constraints
- ICON is pure-content: no build step, no test runner, no package manager (ADR-005). A committed, dependency-free script run in place IS in scope.
- ADR-004: content must work on both Claude Code and Copilot CLI.
- **ADR-016 caps** (new, ICON-0095): `SKILL.md` ≤ 16,000 B, companion ≤ 8,000 B, 2,000 B floor. A new skill starts compliant — keep it that way, and apply the hot/cold rule from the start rather than retrofitting.
- **Standing policy: no new PowerShell twins until #23 lands** — in direct tension with constraint 1 above. Must be resolved explicitly.
- Shipped shell must run on GNU, BSD/macOS and busybox — `.context/standards/shell-portability.md` rules 1–8 plus the Testing Pattern lesson that a fix must be executed in the exact form the document prints.
- `.claude-plugin/plugin.json` is the version SSOT (ADR-003) — do not bump; this is not a release.
- Any `context_template/` change requires a same-commit `iconrc.json` version bump (currently `1.13`).
- `.githooks/pre-commit` gates: README skill registration fires on any `skills/*` path; the dead-ref resolver validates `.context/<file>.<ext>` strings inside `skills/*.md` against `context_template/context/` and is **fence-blind**.
- **Changelog**: one short sentence per user-facing story, ticket ref parenthesized at the end, ≤ ~30 words (`changelog-discipline` Rule 1, hardened this session).
