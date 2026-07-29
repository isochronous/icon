## Task: ICON-0098
## Branch: feature/ICON-0098-migrate-executable-content-to-node
## Objective: Settle where executable content lives — judgement stays as prose, deterministic execution moves to a script taking `argv` — as an ADR, then classify every fenced block against it and migrate the clear wins. Closes GitHub issue #23 (Milestone 3, final item), widened from "the five script files" to executable content wherever it lives.
## Folder: .context/tasks/ICON-0098-migrate-executable-content-to-node/

## Phase State
- **Phase plan**: investigation → architecture → implementation → completion
- **Completed**: investigation, architecture, implementation
- **Current**: completion   (status: in-progress)
- **Next**: —
- **Loaded skill**: task-plan-phase-completion
- **Branch**: feature/ICON-0098-migrate-executable-content-to-node
- **Attempts (current phase)**: 1

## Decisions
- Task ID `ICON-0098` from `local_task_id_prefix` + next free slot, **not** from issue #23.
- **`architecture` is in the phase plan.** This sets a convention every future skill inherits and adds an ADR that must be reconciled against ADR-005 and ADR-016. Same reasoning as ICON-0095, which needed it.
- **Scope widened by the maintainer, this turn.** #23's task list names the five `.sh`/`.ps1` files. First census: **142 fenced `bash`/`powershell` blocks in `skills/`** and 10 in `context_template/`, against **11 script files** repo-wide. The original scope was ~7% of the target.

## The rule to settle
| Content | Home |
|---|---|
| judgement, branching, "decide whether…" | prose in `SKILL.md` |
| deterministic execution — parse, walk, rewrite, validate | a script taking `argv` |

## Why three problems close together under it — ALL THREE CORRECTED BY INVESTIGATION
My original framing overstated the payoff in three places. Corrections below are measured; **the ADR must use these, not the claims above them.**

- **~~A `.mjs` is shellchecked~~ — FALSE.** shellcheck does not read JavaScript and there is **no `.mjs`/`.js` lint gate anywhere in the repo**. The gate's scope is `*.sh|.githooks/pre-commit|.githooks/post-commit`; CI mirrors it. Population today: **10 `.sh` + 2 hooks; 0 of the 164 fenced blocks.** What migration actually buys: 99,137 B of unlinted shell **ceases to exist** rather than becoming linted, and the `.mjs` output falls under `semgrep --config p/ci` — a security ruleset, not a correctness linter. **#48 is shrunk, not closed**: the residual bash preamble stays fenced and unlinted.
- **The twin does not fully die.** Copilot CLI has **no path variable** (`plugin-resource-paths.md`, both tables: *"(no official variable)"*). Every migrated invocation needs a 3–4 line bash preamble reconstructing the documented install layout, plus a PowerShell preamble on Windows. The twin shrinks from ~4 kB of logic to ~4 lines of path construction — a large win, but the ADR must not claim elimination.
- **The size argument is `upgrade-repo`-specific, not corpus-wide.** `upgrade-repo` verified at 92,797 B with **67,434 B (72.7%) in shell fences**. But **6 of the 10 over-cap files have zero or negligible fenced shell** — `rfc` 0, `writing-skills` 393 B, `anthropic-best-practices` 396 B, three others 0. Migration meaningfully helps **2**: `context-specialist-impl-leaf` (discharged outright) and `upgrade-repo` (still 1.6× over afterwards).
- **The byte-parity check does not police bash↔PowerShell twins at all.** It polices **cross-skill copies** — 3 × `.sh` and 3 × `.ps1` of `append-retrospective-entry` against a canonical. Migration takes its population from **6 files to 3**, because the "skills cannot reference files outside their own directory" rule still forces three copies. **#23's task "retire the byte-parity check once its population is empty" is not achievable by migration alone** and the ADR should say so rather than promise it.

ICON-0097 did demonstrate the mechanism — three twins collapsed, verified under PowerShell 7 — but its actual instrument was **inline `node -e`, not a committed script**.

## The counter-argument, which must survive into the ADR
A skill instructs an *agent*, which sometimes needs to adapt a command mid-flight — substitute a path, skip a step, branch on what it found. A rigid script cannot be adapted. Some fences are illustrative rather than runnable. **That argument covers judgement, not parsing JSON or walking a directory** — but the ADR has to state the boundary, not assume it.

## Key Files
- 142 fenced blocks across `skills/` — the classification target.
- `skills/*/scripts/` (5 files, 2 parity pairs + `check-rules-index.sh`) and `.claude/skills/*/scripts/` (2) — #23's original scope.
- `hooks/*.mjs` — the only two `.mjs` in the repo. Conventions: no shebang, invoked via `"command": "node"`, `node:`-prefixed builtins, named imports. **Their failure posture is fail-open by design** — the opposite of what a check needs.
- `.context/decisions/005-no-build-step.md` — authorises the direction, and explicitly defers *"the migration itself"* as separate work. This task is that work.
- `.context/decisions/016-skill-hot-cold-path.md` + `skill-decomposition/hot-cold-path.md` — the caps and the split rule this interacts with.
- `.githooks/pre-commit` — the parity check to retire once its population is empty; the shellcheck gate that would newly see migrated content.

## Classification — 164 blocks, 126,041 B
| Class | Blocks | Bytes | % bytes |
|---|---:|---:|---:|
| **DETERMINISTIC** | **78** | **99,137** | **78.7%** |
| TRIVIAL | 59 | 5,164 | 4.1% |
| ILLUSTRATIVE | 26 | 21,074 | 16.7% |
| JUDGEMENT | **1** | 666 | 0.5% |

**The mass is deterministic — this is a multi-task migration, not an ADR-only task.** But two qualifiers bite hard:
- **59 blocks (36%) are TRIVIAL and total 4% of the mass.** Migrating them is strictly negative.
- **`upgrade-repo` alone is 66,978 of the 99,137 deterministic bytes — 67.6% of the entire target sits in one file.**

The single JUDGEMENT block is `release-plugin:217`, the release commit, which instructs the agent to author a summary from the diff before running. Blocks considered for JUDGEMENT and **rejected**: every `if [ -f … ]` (a script evaluates those), `icon-init`'s probes, `icon-status`'s signals, and every "offer, then on confirm run this" block — that is a **caller** decision, not judgement inside the block.

**30 bash/PowerShell parity pairs, 60 blocks.** The 30 PowerShell halves total **54,848 B — 43.5% of all fenced-shell bytes**; `upgrade-repo`'s 8 halves alone are 39,298 B. Two pairs in `create-phase-repo-setup` are **byte-identical between the "bash" and "PowerShell" blocks** — pure duplication, collapsible by deletion.

**Cross-skill duplication, independent of the shell axis**: the `.gitattributes` union-merge block is byte-identical (785 B) in `impl-leaf` and `impl-root`, with a drifted 1,523 B variant in `upgrade-repo` — three copies, two already diverged. Integration-branch detection is byte-identical (474 B) in `initialize-multimodule` and `initialize-workspace`.

## Blocks that must NOT migrate — with the repo's own reasoning
- **`generate-phase-launcher/references/launcher-templates.md`** (4 blocks, 17,703 B — 14% of the corpus). The repo **already argues this in writing** at `generate-phase-launcher/SKILL.md:170-181`: templates are fences *"NOT as `scripts/*.sh`"* because they *"are not standalone runnable scripts (they carry `ICON-NNNN` placeholders)"* and migrating would *"trip both gates on content never executed from this repo."* These are **emitted into a consumer repo**, not run. Migrating contradicts a live skill's documented design.
- **`find-context-template`** (12 blocks) — **structurally circular**. Its job is resolving the plugin install path; a script invocation needs that path. Irreducible bootstrap. Same for `context-maintenance`'s 4 invocation wrappers — they *are* the idiom.
- **Fragments that are not programs** — e.g. `context-specialist-detect-tree-position:85`: `# $dir is the directory to verify; $ok and FAILURES are caller-owned`. Issue #48 makes the general point independently: *"fragments that are not standalone scripts"*.
- **`start-worktree`** (10 of 11 TRIVIAL) and **`pr-feedback-triage`** (7 of 7 TRIVIAL) — 1,387 B of `git`/`gh` one-liners.
- **`context_template/`** — ships into consumer repos where the script would have to exist too; changing it forces an `iconrc.json` bump.

## The invocation contract — established, and it has a fail-open
`hooks/hooks.json` uses `"command": "node", "args": ["${CLAUDE_PLUGIN_ROOT}/hooks/x.mjs"]`. **Copilot has no equivalent variable**, so the precedent to match is `context-maintenance/SKILL.md:217-230` — `bash "${CLAUDE_SKILL_DIR}/scripts/x.sh"` on Claude Code, and on Copilot a reconstructed install-layout path with the marketplace slug parameterised by env var.

**A bare `node "$SKILL_DIR/scripts/x.mjs"` is a regression against the fenced bash it replaces**, which needs no runtime beyond the shell already running. And on PowerShell it fails **silently**: `$LASTEXITCODE` is not updated on `CommandNotFoundException` (ICON-0096's finding), so `node x.mjs; if ($LASTEXITCODE -ne 0)` reads the *previous* command's status. **Every migrated invocation needs a Node-presence guard that reads output, not exit status.**

## A third option I omitted from the rule table
**Inline `node -e`** — ICON-0097's actual chosen mechanism, already precedent **8 times** in the corpus (6 unlabeled `node -e` fences plus 2 inside labeled bash). Shell-agnostic, needs no path resolution, no new file. Its hazard is documented in ICON-0097's retrospective: interpolated text closes the program on `'`; the fix is `process.argv`, never interpolation. **This belongs as a third row in the rule table, not an omission.**

## Tension for the architect to resolve
If a `.mjs` is invisible to the ADR-016 size gate, **migration becomes a way to satisfy the cap by moving bytes rather than reducing them** — which this plan's own constraint list forbids (*"never withhold content to stay under a gate"* has the same spirit). Flagged, not resolved.

Also unresolved: **ADR-016 alternative 4 rejected `${CLAUDE_SKILL_DIR}` for prose pointers** on graceful-degradation grounds, while `context-maintenance` uses it for **script invocation** today. Whether that rejection scopes to pointers only, or extends to invocations, is a genuine tension the records do not settle.

## Architecture decision (design of record — @architect, tier complex)

### NEW FINDING: migration as briefed loses two gates. Verified, not inferred.
`*.js` does **not** glob-match `.mjs`. Run against the actual `case` globs:
```
skills/icon-init/scripts/detect-repo-type.mjs
  → NO MATCH: dead-`.context/`-reference gate   (agents|skills|shared|commands + .md/.sh/.ps1/.js)
  → NO MATCH: cap-literal consistency gate      (same scope)
```
A fenced block inside `SKILL.md` is **today** inside both gates, because the whole `.md` is. Move it to a `.mjs` and both stop seeing it. **Two-line fix in `.githooks/pre-commit`, same commit** — this is repair of damage the proving migration itself causes, not independent hardening. Shipping the convention without it sets a precedent whose first application weakens the repo's checks. **Manager ruling: in scope.**

### D1 — The rule has four tiers, and inline `node -e` is the DEFAULT
| Class | Home | Test |
|---|---|---|
| Judgement | prose, **no fence** | Could two competent agents correctly emit *different* commands? |
| Illustrative | fence with **no language tag** | Output to recognise, or a command to run? |
| Trivial | fence as-is, **never migrate** | See D5 |
| Deterministic | **inline `node -e` — the default** | shell-agnostic, no path resolution, no file, no runtime guard |
| Deterministic **+ a trigger** | committed `.mjs` under the invoking skill's own `scripts/` | one of four triggers below |

`.mjs` is the **exception**, not the target. Four triggers, any one sufficing: **state crosses a fence boundary** (a variable set in one fence read in another — fences are independently runnable and nothing enforces order, so this is a latent correctness bug); **it mutates state** (Rule 3 obliges live-fixture testing, and a file is executed where a fence must be copy-pasted); **invoked ≥2× in the same skill** with different arguments; **cannot be single-quoted** (a literal `'` is structurally required — rephrase first).

> **Disqualified: `SKILL.md` being over 16,000 B is NOT a trigger.** An oversized `SKILL.md` is an ADR-016 split obligation, discharged by a `.md` companion the caps still measure. Relocating code into a file the gate cannot see does not discharge it, and must never be the motive.

Precedent measured at **9 `node -e` sites across 7 files** (plan said 8) — six in untagged fences. The convention is formalised, not invented.

### D2 — The invocation contract, and the guard can be neither shell nor script
`check-node-runtime` forbids a script guard (*"self-defeating — it cannot run in the case it is meant to detect"*); ICON-0096 forbids a shell guard (`$LASTEXITCODE` stale on `CommandNotFoundException`). **So the guard is a prose precondition addressed to the agent**: run `node -v`, read its **output not its exit status**, and on absence take a **degradation path the skill already has**. *If a skill has no such state, it is not ready to migrate* — a second, independent reason `icon-init` is the right proving case, since Step 2e's `undetermined` and Step 3's override list already exist.

**The Claude Code fence is untagged** — `${CLAUDE_SKILL_DIR}` is substituted *before the model reads the skill*, so what the agent sees is `node "<absolute path>"`, byte-identical in bash, sh, zsh, PowerShell 5.1/7 and cmd. **That is where the twin actually dies.** The Copilot fence is the only survivor: 4 lines of path reconstruction, because Copilot exposes no path variable.

### D3 — Both tensions resolved
- **ADR-016 alt 4 scopes to prose pointers; it does not reach invocations.** Three grounds: the pointer case had a variable-free option (a bare filename the model can glob) and **the invocation case has none** — `node "scripts/x.mjs"` resolves against the consumer's cwd, not the skill dir; the failure is **loud** (`Cannot find module`, non-zero) where a mis-resolved pointer is **silent**; and the invocation ships as a labelled per-harness pair by construction. **No ADR-016 amendment** — alt 4 is already titled for pointers. One clarifying sentence in `hot-cold-path.md § Pointer Syntax`.
- **Migration is not cap-evasion, on a cleaner axis than mine.** Three acts: *withholding* (agent never gets it — forbidden), *splitting* (agent gets it on a `Read` — prescribed), *migrating executable content* (**the agent was never the audience**). A companion is *read* to know what to do; a script is read by nobody at runtime. Removing bytes that served the machine withholds nothing from a reader who was never there. Gated by two obligations: **the prose contract must survive** (what the script decides and what each outcome means — *"if the section shrinks to 'run the script', it failed"*), and **size may not be the motive**. Evidence the first application is clean: `icon-init` is **10,431 B**, comfortably under cap. **State plainly that migration is not a size-reduction technique and `SKILL.md` may well grow.**

### D4 — Carve-outs collapse to two axes, not a list of five
Per `boundary-axis-selection.md`. **E1 — not executed from this repo by an ICON agent**: `launcher-templates` (emitted into a consumer repo, and the skill argues this itself), `context_template/` (ADR-016 excluded it for the same reasons — cite the precedent), non-program fragments (reference variables they do not set, so there is no entry point to hand an `argv`). **E2 — bootstrap**: `find-context-template` (circular — its job is producing the path an invocation needs), `context-maintenance`'s wrappers (they *are* instances of the contract). **`start-worktree` and `pr-feedback-triage` are NOT carve-outs** — D5's trivial test excludes them correctly, and listing them implies the rule needed help.

### D5 — "Trivial", mechanically
> **If the Node version would have to shell out to do the same work, the block is already in the right language.**

Formally: invokes only external tools with fixed arguments, no control flow, sets no variable another block reads, and a JS rewrite would just wrap `child_process`. **Converse**: control flow over a tool's *output* is deterministic, not trivial. Grounding: 59 blocks, 4.1% of mass — migrating costs a file, preamble, guard and degradation path to save 87 bytes.

### D6 — Cross-skill duplication: already settled, and #23's retirement item is dead
`infrastructure-and-distribution.md § Skills Cannot Share Scripts` settles it — **n copies, "the duplication is the price."** The second-order answer: **prose duplication is not preventing drift, it is hiding it** (the `.gitattributes` block is 3 copies with 2 already diverged, *today*, with nothing detecting it). Migration makes drift **mechanically detectable**. When n ≥ 2, adding the copy-set to the byte-parity check is **mandatory in the same commit**, and a shared block migrates **as a whole set or not at all**.

**Correction sharper than the plan's**: migrating `append-retrospective-entry` takes the parity population 6 → 3; migrating `.gitattributes` adds 3 back. **Migration refills the check, it does not empty it.** #23's *"retire the byte-parity check once its population is empty"* should be closed **won't-do**, not carried forward.

### D7 — Peer to both ADR-005 and ADR-016
ADR-005 records the direction and defers *"the migration itself"*; **ADR-017 defines "where practical."** Nothing went stale → no amendment. ADR-016 contact points: scope non-overlap **with its hazard stated** (the `.mjs` invisibility is *known*, D1's disqualified reason is the control, and the two gates are being extended so it does not silently widen), plus the alt-4 clarification.

### Node floor — no third number, and my caution was misdirected
`.mjs` is ESM, so **`node:`-prefixed `import` is permitted and preferred** — those arrived in the 12.20/14.13 line, which *is* the published floor. **Never `require`** — `require("node:fs")` is what raises it to 14.18/16, and `.mjs` has no `require` anyway. So the floor holds and shipped scripts match `hooks/*.mjs` exactly.

### Scope modifications accepted
- **The proving migration is `icon-init` Steps 2a–2e, not 6/6.** Step 1 stays fenced: its result feeds a prose branch on a caller-supplied `--force`, and folding it in invents a flag contract across the boundary for a six-line existence test.
- The `.githooks/pre-commit` `.mjs` scope extension lands in the same commit.

## Phase Handoff Log

_(no handoffs yet)_

## Progress
- [x] Investigation — 164 blocks classified; three of my own claims corrected; carve-outs found with the repo's own reasoning behind them
- [x] Update this plan with findings before any design
- [x] **Architecture** — four-tier rule (not three), four extraction triggers with **size explicitly disqualified**, the invocation contract as a *prose* precondition, both tensions resolved. Found that `*.js` does not glob-match `.mjs`, making migration a silent net loss of two pre-commit gates; ruled in scope
- [x] Implementation — ADR-017, `executable-content.md`, `detect-repo-type.mjs`, the pre-commit gate extension, the free deletions, `icon-init` Steps 2a–2e
- [x] @reviewer pass — three rounds. R1 **changes requested**: Step 2d's `readdirSync` dirent filter was inverted from the shell's `*/` glob on both axes (dot-dirs in, symlinks out), producing a false `multimodule` on a `.github/` tipping vote and a false `project` on a junction module. R2 **approved** after the fix was re-derived across 23 fixtures. R3 closed three doc-precision minors
- [x] Completion: reconcile plan.md, changelog, retrospective, commit, PR

## Scope: this task is Wave 0 plus one proving case
Mirrors ICON-0095 — establish the rule, prove it on a friendly case, defer the hard one. **`upgrade-repo` is 67.6% of the target and gets its own task**; bundling it here repeats the mistake ICON-0095 deliberately avoided.

**IN**: the ADR and invocation contract · the explicit carve-outs · the **free deletions** (2 byte-identical `create-phase-repo-setup` pairs — 4 blocks, 186 B, collapsible by deleting the redundant half, zero new files) · **one proving migration: `icon-init`** (6/6 deterministic, 4,596 B, no parity pairs, no illustrative admixture, and it *reports* rather than writes, so a wrong answer is a report not a mutation).

**DEFERRED, as tickets**: Wave 2 the cross-skill duplicates done as one unit (~11,000 B; splitting them re-copies the same blocks); **Wave 3 `upgrade-repo` alone**, probably split further — its two largest blocks are 37,198 B for one logical operation and it writes into a consumer's repo, so every ICON-0093/0094 lesson applies at full force; Wave 4 the `.sh`/`.ps1` files (#23's original scope), plus a separate question of whether the 3-copy parity check can retire at all — it cannot, on migration alone.

**Also in Wave 1 but not this task** (same shape as `icon-init`, deferred only to keep the proving case clean): `icon-status` (9 DET), `plugin-design/audit-phase-*` (6 DET, 3 pairs — **priority beyond size**: three are `python3` heredocs that ADR-005 says do not run on Windows, so migration is a *fix*), `.claude/skills/icon-audit` (1 DET, maintainer-only).

## Open Questions / Blockers — all five resolved
- **How many of the 142 are genuinely deterministic?** ✅ **78 blocks, 99,137 B (78.7%)**. It is a multi-task migration. `upgrade-repo` alone is 67.6% of the deterministic bytes, so it was deferred to its own wave rather than bundled here.
- **What is the invocation convention for a shipped script?** ✅ Resolved as **two fences, not one**. Claude Code's is **untagged** — `${CLAUDE_SKILL_DIR}` is substituted before the model reads the skill, so the agent sees an absolute path, byte-identical in every shell. *That is where the PowerShell twin dies.* Copilot CLI has no path variable, so its fence is the only survivor: ~4 lines of bash path reconstruction with a `${VAR+x}` presence test, matching the `context-maintenance` precedent. No PowerShell Copilot variant, deliberately.
- **Does a migrated script need Node-presence handling?** ✅ Yes, and it can be **neither a script nor shell** — a script cannot report its own runtime missing (the ICON-0096 tautology), and a shell guard is unsafe because PowerShell leaves `$LASTEXITCODE` stale on `CommandNotFoundException`. It is therefore a **prose precondition** that reuses `check-node-runtime`'s Step 0 finding and degrades to `undetermined`, a state the skill already had.
- **`context_template/`'s 10 blocks** — ✅ **Excluded (E1)**, explicitly. A migrated block there would need the script to exist in the consumer's repo too, and any change forces an `iconrc.json` bump. Verified untouched at close.
- **What happens to the byte-parity pre-commit check** when its population empties? ✅ **It never empties.** Migrating `append-retrospective-entry` takes it 6 files → 3; migrating the `.gitattributes` copy-set adds 3 back. The check polices **cross-skill copies**, not bash/PowerShell twins — a distinction the investigation corrected. **#23's "retire the byte-parity check" item is unachievable by migration in any wave and should be closed won't-do.**

## Answered late, and worth carrying forward
- **`.mjs` is linted by nothing.** The roadmap's claim that a `.mjs` "**is** shellchecked" was false — no JavaScript correctness linter exists in this repo, and `semgrep --config p/ci` is a security ruleset. #48 is **shrunk, not closed**; roadmap corrected in this task.
- **`*.js` does not glob-match `.mjs`.** Migration was a silent net loss of the dead-ref and cap-literal gates until the pre-commit `case` arms were extended. Proven by running the pre-migration hook and the extended hook against the same file: `exit=0` vs `exit=1`.

## Constraints
- ADR-005: no build step, no package manager. A committed, dependency-free script run in place IS in scope — and this ADR is the "separate work" ADR-005 defers.
- ADR-004: both harnesses. Copilot CLI's skill-loading and script-invocation semantics are **unestablished** — do not assert them.
- **ADR-016 caps** apply to anything touched: `SKILL.md` ≤ 16,000 B, companion ≤ 8,000 B, floor 2,000 B. Note a `.mjs` is invisible to both that gate and the dead-ref resolver.
- **Node floors — no third number**: technical **12.20 / 14.13**; supported **Node 22** (measured 2026-07-28). `require("node:fs")` raises the technical floor to 14.18/16 — ICON-0097 used unprefixed `require("fs")` for that reason.
- **The split rule as of ICON-0097**: splitting is the response when both gates fire; pruning never discharges it; cost is not grounds to defer; and **never withhold content to stay under a gate**.
- `.claude-plugin/plugin.json` untouched (ADR-003) — not a release.
- **Changelog**: one short sentence per user-facing story, ticket ref parenthesized, ≤ ~30 words.
