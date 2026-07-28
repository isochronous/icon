## Task: ICON-0097
## Branch: feature/ICON-0097-replace-python3-with-node
## Objective: Replace every `python3` dependency in consumer-shipped skills with Node, and fix the config-file writer that is pseudo-code inside an executable fence. Closes GitHub issue #21 (Milestone 3, second item).
## Folder: .context/tasks/ICON-0097-replace-python3-with-node/

## Phase State
- **Phase plan**: investigation → implementation → completion
- **Completed**: investigation
- **Current**: implementation   (status: in-progress)
- **Next**: completion
- **Loaded skill**: task-plan-phase-implementation
- **Branch**: feature/ICON-0097-replace-python3-with-node
- **Attempts (current phase)**: 1

## Decisions
- Task ID `ICON-0097` from `local_task_id_prefix` + next free slot, **not** from issue #21 (`.context/workflows/commit-conventions.md` § Task ID Generation).
- Phase plan omits `architecture`: the target runtime is already decided (#22 landed the detector; Node is the assumed runtime for shipped scripts), and each site is a mechanical rewrite of a known input to a known output. If investigation finds a site whose *behaviour* is contested rather than its language, add the phase then.
- **#22 is the prerequisite and is landed** — the runtime is now verifiable, which is what makes increasing reliance on it safe.

## Why `python3` is not an acceptable dependency here
ADR-005 records it plainly: `python3` is **not** an assumed runtime. On a stock Windows box the name resolves to a **Store stub** that prints "Python was not found" and exits non-zero — with a message that does not resemble a JSON error, so a caller parsing output gets garbage rather than a clean failure. Verified on the maintainer's own machine (ICON-0089, re-confirmed ICON-0090 §4).

## Site inventory (first pass — investigation must confirm and complete)
`grep -rn python3` over shipped trees returns **14 hits, 13 real** (the 14th is `check-node-runtime/SKILL.md:164`, which names `python3` as a mistake — **that one stays**).

| File | Sites | Notes |
|---|---|---|
| `skills/icon-init/SKILL.md` | `:82` | Workspace detection. **The most consequential** — see below. |
| `skills/icon-status/SKILL.md` | `:108` | Reads `iconrc.json` version. |
| `skills/initialize-workspace/SKILL.md` | `:44` | Workspace detection. |
| `skills/plugin-design/audit-phase-consistency.md` | `:19, :53, :110` | |
| `skills/plugin-design/audit-phase-structure.md` | `:24, :43` | |
| `skills/plugin-design/create-phase-basic-info.md` | `:44, :84, :117` | |
| `skills/plugin-design/create-phase-boilerplate.md` | `:137` | |
| `skills/plugin-design/create-phase-marketplace.md` | `:18` | |

**Plus two sites the `python3` grep does not find**: `skills/create-iconrc/SKILL.md` carries ```` ```python ```` fences at **`:97-137`** and **`:143-176`** — labelled by fence language, not invoked by command name. These are the ones the issue calls out hardest, and they are a different defect class (see below).

## Two sites that are more than a language swap
1. **`create-iconrc`'s config writer is pseudo-code in an executable fence.** Per the issue it *"references six variables it never defines"* — so an agent that pastes and runs it gets an error, not a config file. It is also **the sole owner of `.context/iconrc.json` across all four setup paths**, so this is not a peripheral site. Rewriting it in Node is necessary but not sufficient: **the six undefined variables must be resolved so it actually runs.** Investigation must name them and where their values come from.
2. **`icon-init`'s workspace detection fails open into a wrong branch.** When its Python fails, detection falls through and a JavaScript-workspace monorepo is **detected as a single project** — with only a user confirmation between that and single-project setup running on a monorepo root. That is a fail-open with a destructive-ish outcome, and the same shape ICON-0094 spent four review rounds on.

## Key Files
- The eight files above, plus `skills/create-iconrc/SKILL.md`.
- `skills/check-node-runtime/SKILL.md` — the reference for how a runtime guard is written now, and **the source of the Node floor wording**. Do not introduce a third floor number.
- `.context/decisions/005-no-build-step.md` — the warrant; also the source of "committed, dependency-free script run in place IS in scope".
- `.context/standards/shell-portability.md` — rules 1–8 plus `## Testing Pattern`.
- `CHANGELOG.md` — `[Unreleased]` at task close.

## Investigation findings

### The stub was measured, not assumed
```
$ V=$(python3 -c 'print(1)'); echo "captured=[$V] rc=$?"
Python was not found; run without arguments to install from the Microsoft Store, …
captured=[] rc=49
```
Three facts that drive every rewrite: it writes to **stderr**, exits **49** (not 9009 — that is cmd's not-recognized; this alias *does* execute), and **`python3` is on PATH** (`…\WindowsApps\python3.exe`). **A rewrite must not "fix" this with a `command -v python3` guard** — that guard passes.

### 15 sites, not 13. Two the `python3` grep cannot see.
`skills/create-iconrc/SKILL.md:97-137` and `:143-176` are ```` ```python ```` fences, matched by fence language rather than command name. The issue's line numbers are stale for two files (`create-iconrc` cited as `:81-121,127-160`; `icon-init` as `:69-77`).

**Correctly excluded**: `skills/check-node-runtime/SKILL.md:164` names `python3` as the mistake — it stays. And **20 hits in `skills/writing-skills/anthropic-best-practices.md`** are verbatim vendored Anthropic guidance inside ````markdown` fences, illustrating what *a skill* looks like (`pdfplumber`, `scripts/fill_form.py`). Nothing executes; rewriting them would corrupt quoted upstream material.

**The issue's fifth task — "sweep remaining `python3` in maintainer-facing documentation" — finds nothing to change.** The three `.claude/` and `.context/` hits are the *warrant* (ADR-005 stating it is not an assumed runtime), not the defect.

### `icon-init` is a guaranteed misdetection, not a fall-through
When the block fails, `DETECTED_TYPE` stays empty and Step 2c runs — and **`package.json` is the first manifest in its list**, which is precisely the precondition of the branch that just failed. So it sets `DETECTED_TYPE="project"`. Every JS-workspace monorepo lands there, and because the variable is now non-empty, Step 2e's `WARNING: Repo type could not be determined` **never fires**. The user sees a confident `Detected repo type: project` / `Skill to invoke: /initialize-repo`. The skill's own Common Mistakes table warns about the *opposite* failure (a false positive on empty `workspaces`); the shipped defect is a systematic false negative.

Also note `2>&1` merges the stub sentence into `WS_CHECK`, so the variable holds the sentence, not the empty string — both take the same branch.

### Two sites are broken independently of Windows
`audit-phase-consistency.md:110` and `audit-phase-structure.md:43` do **`import yaml`** — PyYAML, third-party, which ADR-005's no-package-manager rule forbids installing. They fail with `ModuleNotFoundError` on a real Python too. **"Behaviour-preserving" has no referent**; the only variant that runs today is the PowerShell twins' documented regex degradation (`audit-phase-structure.md:70`, `:81`). A rewrite matching it must *say in prose* that it is weaker than YAML parsing, or a future reader assumes the check is sound.

### Three sites where behaviour-preserving is the wrong goal
`icon-init:82` (preserving the `yes`/`no` contract preserves the bug — there is no third value for "could not determine"; target is fail-**closed**), `icon-status:108` (currently renders a blank version silently), `create-iconrc` (currently a `NameError` on the first free variable — there is no behaviour, only a contract to implement).

### The pattern `icon-status` should match, quoted
`upgrade-repo` reads the *same field* from the *same file* and guards both cases, `:1290-1298`:
```bash
# An unreadable template (bad $TEMPLATE_DIR) yields an empty TEMPLATE_VER. Without
# this guard the comparison below is true, sed and mv both succeed, and the block
# writes "version": "" into the consumer's file while reporting success.
if [ -z "$TEMPLATE_VER" ] || [ -z "$INSTALLED_VER" ]; then
  echo "ERROR: could not read a version …" >&2
  exit 1
fi
```
Guard the empty result *after* the read, name the file, write to stderr, never let an empty string flow onward as a value. For `icon-status` — which reports rather than writes — the equivalent is `version (unreadable)` plus a Suggestions row, never a blank.

### Output-format couplings a rewrite could silently break
- `initialize-workspace:44` emits **tab-separated** rows the agent transcribes into a table; paths contain spaces, so switching separator or format breaks it. It also **shell-interpolates `'$WORKSPACE_FILE'` into a Python string literal** — a path with `'` or `\` breaks the program, and `\` is a Python escape on Windows. **Pass paths via `process.argv`, never by interpolation.**
- `create-phase-marketplace:18` prints a **Python list repr** (`['author', …]`); `JSON.stringify` gives different quotes, and its PowerShell twin already emits a third format.
- `create-phase-boilerplate:137` / `create-phase-basic-info:117`: **silence on success is the documented contract** (`create-phase-boilerplate.md:140` — *"Exit code 0 with no output means the file is valid."*). A rewrite that helpfully prints `OK` breaks the stated rule — which makes `.claude/claude.md`'s `node -e … console.log('OK', …)` idiom a **bad** template for these two.
- `create-phase-basic-info:84` writes `"\n".join(lines) + "\n"` — LF, no BOM. `os.EOL` would churn every line on Windows.

### The `>/dev/null` ban interacts with the fix
`shared/common-constraints.md:16` bans suppression, and `icon-init:246` sanctions `2>&1 | grep -v "^pattern"` as the workaround — **but that idiom is exactly what makes `icon-init:82` fail open**, by folding a stub message into a value channel. The rewrite should stop merging streams into the capture and let stderr be stderr, not reach for a better grep filter.

### Sizes — two tight files
`initialize-workspace` **1,519 B headroom**; `audit-phase-consistency` **1,509 B** — and the latter is the site whose rewrite is most likely to grow. Note the ADR-016 gate is **advisory**, not blocking (`.githooks/pre-commit:749-751`, `:983`), so going over prints a finding rather than stopping the commit — but it creates a review obligation.

### No `skills/**/*.mjs` exists
The only two `.mjs` in the repo are under `hooks/`. Conventions there: **no shebang**, invoked explicitly via `"command": "node"`; `node:`-prefixed builtins only, named imports, double-quoted specifiers; a header comment stating the contract and failure posture. Note the hooks' posture is *fail-open by design* — **the opposite of what these sites need.**

There is also **no precedent for inline `node -e` in a shipped skill** — the only one in the repo is `.claude/claude.md:18`, maintainer-facing.

### Node floors — do not introduce a third number
Technical: the **12.20 / 14.13** line, from `node:`-prefixed imports. Supported: **Node 22**, measured 2026-07-28, per `check-node-runtime`. Features that would raise the technical floor and must be avoided: `fs.globSync` / `fs.promises.glob` (**22+**), `readdirSync({recursive:true})` (**18.17+**), `??=` / `structuredClone` (15/17). **Prefer a hand-rolled recursive `readdirSync` walk** where globbing is needed.

## Scope decision (user, this turn): one-liners now; scripts and `create-iconrc` deferred

**IN this task — the ~9 pure JSON reads, plus the three sites whose current behaviour is wrong:**
`icon-init:82` · `icon-status:108` · `initialize-workspace:44` · `audit-phase-structure:24` · `create-phase-basic-info:44, :84, :117` · `create-phase-boilerplate:137` · `create-phase-marketplace:18`

**DEFERRED to #23** — the four sites needing a committed `.mjs` (directory walks, regex sweeps, frontmatter parsing): `audit-phase-consistency:19, :53, :110` and `audit-phase-structure:43`. Rationale: no `skills/**/*.mjs` exists, and **ADR-005 authorises the direction but states "the migration itself is separate work and is not scoped by this record"** — which is #23's remit, not #21's. Landing the first one here would be precedent-setting by accident.

**DEFERRED to its own task — `create-iconrc:97, :143`.** Not a translation: its six variables are **all caller-supplied**, so the rewrite must invent an entry mechanism (argv/env/stdin) and then teach it to **five call sites** — `context-specialist-impl-leaf:326`, `context-specialist-impl-root:280`, `upgrade-repo:1285` and `:1361-1363`, and direct user invocation. Investigation flagged this as the part "most likely to be under-scoped", and two open questions compound it (below).

### Open questions carried into the deferred tasks, not resolved here
- **Nothing branches on `$ACTION`.** `create-iconrc` Step 1 sets `ACTION="create"|"update"` but Step 2 presents two fences as headings with no mechanical dispatch — the agent picks. Unifying them into one script that checks the file itself would be a behaviour *improvement* and a structural change.
- **`excludes` contradicts itself on the create path**: prose says *"Only active on re-runs"*, the create fence writes it anyway.
- **`upgrade-repo`'s sed depends on `create-iconrc`'s serialisation** — it matches the literal `"version": "1.13"` with one space after the colon. `JSON.stringify(obj, null, 2)` reproduces that exactly, so it is safe *provided* indent 2 is kept and keys are not reordered.
- **`generate-phase-launcher` reads an optional `phase_launcher.target_harness` key deliberately outside the schema.** A rewrite that whitelists fields on the update path would silently delete it; today's `config.update(overrides)` preserves it.

## Phase Handoff Log

_(no handoffs yet)_

## Progress
- [x] Investigation — 15 sites found (2 invisible to a `python3` grep), stub behaviour measured, `icon-init`'s misdetection traced, the `import yaml` sites found broken independently of Windows
- [x] Update this plan with findings before any edit
- [x] Scope decided with the user — one-liners now; `.mjs`-requiring sites to #23; `create-iconrc` to its own task
- [x] Implementation — 9 sites rewritten; **three PowerShell twins collapsed, none created**, all six blocks verified running under PowerShell 7
- [x] Deferrals filed — [#23 comment](https://github.com/isochronous/icon/issues/23#issuecomment-5110004381) for the four `.mjs`-requiring sites; **[#56](https://github.com/isochronous/icon/issues/56)** for `create-iconrc`
- [x] **@reviewer pass** (tier complex, executed) — **changes requested**: 3 Moderate + 4 smaller. The three headline behaviour changes were attacked with hostile fixtures and **held**.
- [x] Remediation — all seven fixed
- [x] **@reviewer confirmation** — **approved**, every fix verified by execution; the deleted-twin scope call independently endorsed
- [x] `CHANGELOG.md` — four bullets, 15–18 words each, one per distinct fix-class
- [ ] Completion: commit, PR ← IN PROGRESS

## Implementation and review findings

### A regression the rewrite introduced, and the sharpest lesson in the task
`node -e '…'` with agent-substituted free text **broke on an apostrophe**. `python3 - <<'PY'` is a *quoted* heredoc — no shell processing at all — so `'` passed through untouched and only `"` broke it. The port traded a rare breaking character for a common one; `Siobhan O'Brien` is an ordinary author name, and `description`'s own validation row does not exclude apostrophes.

**The same task had already fixed this exact class at `initialize-workspace`** (a Python string literal interpolated from shell) **and reintroduced it three sites later in the other direction.** Fixed by moving free text to `process.argv`; verified with `'` and `"` in the same value across both shells.

### The one twin collapse that was not like-for-like
Five of six were sound — `node -e` is genuinely shell-agnostic, and PowerShell's writes were byte-identical to bash's. The sixth removed a PowerShell heading from a section whose **other** block is bash-only `jq` (`--arg`, backslash continuations — 10 PowerShell parse errors). A Windows user *with jq installed* was routed into an unrunnable block and told the reason to skip was jq availability, not shell. **The replacement being portable does not make its neighbours portable.**

### A defect class both sweeps structurally could not see
`initialize-workspace:370`'s Common Mistakes row said *"use `os.path.realpath`"* — in a file that now contains no Python, in the row describing the behaviour this task reimplemented. It matched neither `python3` nor a ```` ```python ```` fence because it **names** the API rather than **invoking** it. When removing a dependency, sweep for what it is called, not only how it is run.

### A signal that reached the wrong stream
`initialize-workspace`'s missing-folder `NOTE:` went to stderr, but Step 0 builds its resolution table from **stdout** — and downstream the absent folder was classified `resource` and reported as *"documentation or data only"*, a false reason for a real problem. Fixed by carrying the state into a 4th TSV column. Fail-soft preserved: a `.code-workspace` naming a not-yet-cloned sibling is ordinary and VS Code tolerates it.

### The new rule shipped contradicted in its own file
The Common Mistakes row added at `icon-init:258` bans applying `2>&1 | grep -v` to a `$(…)` capture that is branched on — while `:102` did exactly that four lines from the fix, and `:105` branched on it. Pre-existing, same defect class, fixed here. The old form leaked `[: : integer expected` and fell through to `project`.

### Promotion deliberately skipped
The durable lesson — *pass values as arguments, never interpolate into a program body* — belongs in `shell-portability.md`. That file is at **15,695 B against a 16,000 B gate** and the lesson is ~1,200 B, so adding it re-trips the gate and hands this task the folder-split obligation. **That is exactly the accretion [#54](https://github.com/isochronous/icon/issues/54) was filed to decide.** Not creating the obligation rather than deferring one; #54 notified that its predicted trigger has arrived with a concrete item waiting.

### Watch item
`skills/initialize-workspace/SKILL.md` is at **251 B headroom** — the tightest file in the repo. Anything landing in it next needs a size decision first.

## Open Questions / Blockers
- **What are the six undefined variables in `create-iconrc`, and where do their values come from?** Named in the issue but not enumerated. Until they are, "rewrite in Node" is underspecified — the rewrite has to *define* them, which means knowing what the caller is expected to supply.
- **Do the `plugin-design` blocks run in the consumer's repo or the maintainer's?** `plugin-design` is a shipped skill, but its phases scaffold a *new plugin*. If some blocks only ever run against ICON itself the urgency differs — though the rewrite is cheap either way.
- **Does any block need more than JSON parsing?** The issue frames most of these as JSON reads. `node -e` handles that with no dependencies. Any block doing real work (globbing, multi-file traversal) may warrant a committed `.mjs` rather than an inline `-e`, which is a different shape and a different review burden.
- **How should a rewritten block fail?** #22 established that a runtime guard must not key on exit status, and that a fail-open is the defect. Each rewritten site should fail **closed and loudly** — especially `icon-init`'s, whose current failure mode picks the wrong setup path.
- **Is `python` (not `python3`) used anywhere?** The first grep covered `python3` only and missed the two ```` ```python ```` fences. Investigation must sweep for both, and for `py -3` on Windows.

## Constraints
- ICON is pure-content: no build step, no test runner, no package manager (ADR-005). A committed, dependency-free script run in place IS in scope.
- ADR-004 — both harnesses. **No new PowerShell twins** until #23 lands; a `node -e` one-liner is shell-agnostic and does not need one.
- **ADR-016 caps**: `SKILL.md` ≤ 16,000 B, companion ≤ 8,000 B, 2,000 B floor. Several of these files are `plugin-design` companions already — check headroom before adding.
- Shipped shell must run on GNU, BSD/macOS, busybox — `.context/standards/shell-portability.md` rules 1–8 + `## Testing Pattern`.
- `.claude-plugin/plugin.json` is the version SSOT (ADR-003) — do not bump; not a release. **Note several blocks *read* it; reading is fine.**
- Any `context_template/` change forces a same-commit `iconrc.json` bump (currently `1.13`).
- **Changelog**: one short sentence per user-facing story, ticket ref parenthesized, ≤ ~30 words (`changelog-discipline` Rule 1).
