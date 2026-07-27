# Architectural Assessment: ADR-005 disposition (ICON-0091 / roadmap R-0a)

## Summary

ADR-005's Decision is correct and still held; four supporting statements decayed and a fifth
(the ADR-004 citation) was wrong when written. The correct disposition is **amend in place with
a dated `## Amendments` section — not supersede**, and the standing scope is *no manifest, no
install step, no generated artifacts, no test framework* versus *committed scripts run in place
on an already-present runtime*, which was always permitted.

## Recommendation

**Decision**: Approve with modifications — amend ADR-005 in place; do **not** create ADR-016.

**Rationale**: Superseding would assert a decision reversal that never occurred, and would freeze
a record that 18 other documents still cite as the live rule. Details in Q1 below.

---

## Q1 — Amend, or supersede?

### The general convention this repo should adopt

> An ADR records a **decision**, not a snapshot of the repo. When one goes stale, the disposition
> turns on one question: **did the position change, or only the world it described?**

| What went stale | Disposition |
|---|---|
| A supporting fact, a consequence, or a rejection's stated grounds — the Decision still holds | **Amend in place**, `## Amendments` entry, `**Status**` stays `Accepted` |
| One sub-decision is now decided differently, the rest stands | **Scope-supersede** (already conventionalized, ICON-0085) |
| The Decision itself no longer holds | **Supersede** |

ADR-005 is row 1. Amend.

### Why supersede loses

The ICON-0089 audit proposed a new ADR-016 scope-superseding 005's Consequences and Alternatives
(`research/05-infrastructure.md:329-333`). Four arguments against, the fourth decisive:

1. **It would assert something false.** `**Supersedes**: ADR-005` means "a later decision replaced
   an earlier one." No such decision was ever taken. The Node wrapper *predates* the ADR text that
   appears to forbid it — ADR-005's own Decision paragraph names `inject-manager-role.mjs` as
   compliant while its Alternatives paragraph rejects "a Node toolchain." That is an internal
   contradiction present at authoring time, not a position that changed. A supersede record
   manufactures a deliberation that never happened and sends future readers looking for it.

2. **It adds a hop instead of removing the error.** `rules-index.md`'s ADR table routes on
   "applies when…". An errata ADR has no distinct "applies when" — it answers the same question as
   005. A reader routed to 016 must still read 005; a reader landing on 005 directly still reads
   the stale text. The failure the audit found (reader reaches stale record) survives the fix.

3. **It would blur a convention that currently has one clean meaning.**
   `skills/context-document-guidelines/SKILL.md:151` defines scope-supersede as "a new ADR resolves
   only a PRIOR ADR's specific *sub-decision*." A wrong *reason recorded for* a decision is not a
   sub-decision resolved differently. Reusing the machinery here costs the convention its edge.

4. **Superseding freezes the record — and ADR-005 must stay live.**
   `skills/context-document-guidelines/SKILL.md:94`: *"A superseded or withdrawn ADR … falls under
   the exemption's point-in-time snapshot case: supersession freezes its Decision/Consequences
   content"* — versus *"An ADR that still carries a live, normative rule is, in shape, a
   topic-organized guidance doc … the gates apply in full."* ADR-005 is cited by number as the live
   rule in ~18 places. Marking it superseded would make it simultaneously frozen and live, which the
   repo's own convention does not permit. **Supersede is structurally wrong here.**

### Answering "amending erases history"

It does not have to, and the repo already owns the idiom: ADR-006 and ADR-011 carry a dated
`> **Superseded (2026-06-20, ICON-0080).**` blockquote explaining what changed and why the record
is retained. The errata analogue is a dated, task-attributed `## Amendments` section. This is
*better* preservation than a supersede, because a supersede preserves the wrong sentence without
ever labelling it wrong. Git history is the exhaustive record; `## Amendments` is the discoverable one.

### Where the convention goes, and in what words

**Primary — `skills/context-document-guidelines/SKILL.md`**, as a new subsection immediately
preceding the existing `### ADR supersede bold-fields` bullets (that section is declared the
*single authority* for the supersede seam at `:106`; putting the when-to-supersede rule anywhere
else splits the authority):

```markdown
### Correcting a stale ADR: amend, scope-supersede, or supersede

An ADR records a **decision**, not a snapshot of the repo. When one goes stale, the disposition
turns on a single question: **did the position change, or only the world it described?**

| What went stale | Disposition | Mechanism |
|---|---|---|
| A supporting fact, a consequence, or a rejection's stated grounds — the Decision still holds | **Amend in place** | Correct the prose and append a dated `## Amendments` entry. `**Status**` stays `Accepted`. No new ADR. |
| One sub-decision is now decided differently; the rest stands | **Scope-supersede** | New ADR plus scoped bold-fields in both directions (below). The old Decision prose is left intact. |
| The Decision itself no longer holds | **Supersede** | New ADR plus bold-fields; the old ADR's `**Status**` becomes `Superseded by ADR-NNN` and its content freezes. |

**Do not supersede an ADR whose Decision still stands.** `**Supersedes**: ADR-NNN` asserts that a
later decision replaced an earlier one; where no such decision was taken, the record manufactures a
deliberation that never happened. Superseding also *freezes* the old ADR (see § Split Exemptions),
which is wrong for a record other documents still cite as the live rule — and it leaves the stale
text in place for anyone who lands on it directly, adding a hop rather than removing the error.

**An amendment must not erase what was believed.** Every correction gets an `## Amendments` entry —
dated and task-attributed — naming what the text said, what is true, and, where the original
reasoning was wrong rather than merely overtaken, why. Git history is the exhaustive record; the
`## Amendments` section is the discoverable one.

**Proportionality.** An `## Amendments` entry is owed when the corrected text was load-bearing —
a reader could have acted on it. A typo, a renamed skill, or a stale path is corrected in place
with no entry. Correcting one ADR's passing summary of *another* ADR's scope does count as
load-bearing: that is exactly the kind of sentence a reader acts on.
```

**Secondary — `.context/decisions/README.md`**, one pointer inserted after line 5 (which already
carries the closest existing statement, "ADR numbers are immutable once assigned; superseded ADRs
stay in place"). A pointer, not a restatement — `META.md` warns against duplicating between surfaces:

```markdown
**Correcting a stale ADR.** A record whose *Decision* still holds but whose supporting facts have
decayed is **amended in place** with a dated `## Amendments` entry — not superseded. Supersede only
when the position itself changed; scope-supersede when one sub-decision changed and the rest stands.
The full convention lives in `context-document-guidelines § Correcting a stale ADR`.
```

Note: the `skills/` edit is **consumer-shipped** content (a CHANGELOG `[Unreleased]` line is owed;
no version bump, per the release guard). It is not `context_template/`, so no iconrc bump is owed.

---

## Q2 — The standing decision's actual scope

**The manager's reading is correct, and it is not a new line — it is the repo's existing operative
line, drawn everywhere except in ADR-005 itself.**

- `.context/standards/secure-coding.md:11` — *"Node built-ins only … no external dependencies, no
  `package.json`, no lockfile. ICON has no build/install step, so a third-party import has nothing
  to resolve it. **(ADR-005.)**"* The correct boundary, attributed to the correct ADR, already
  normative.
- `.context/decisions/012-context-knowledge-graph.md:18` — a live `Accepted` ADR asserting that
  `context-graph.{sh,ps1}` *"honors ADR-005 (committed source run in-place)."* ADR-012 already
  reads ADR-005 the way this amendment codifies.
- `skills/security-review/SKILL.md:25` — same line, same wording.

So the amendment **ratifies existing practice**; it does not license anything new.

### The line, stated for a future contributor

**Forbidden:** a package manifest or lockfile; an install step (`npm install`, `pip install`);
third-party runtime dependencies; generated or compiled artifacts (a `Makefile`, transpiled output,
generated per-runtime copies); a test framework.

**Permitted, and always was:** committed scripts that run in place on a runtime the environment
already provides, importing only that runtime's standard library.

**Test it against reality** — every existing artifact resolves correctly:

| Artifact | Verdict | Consistent? |
|---|---|---|
| `hooks/*.mjs` (2) | permitted | yes — ships today |
| `.githooks/pre-commit` (~975 lines bash) | permitted | yes — ships today |
| `skills/context-maintenance/scripts/context-graph.{sh,ps1}`, `check-rules-index.sh` | permitted | yes — ADR-012:18 already says so |
| `.github/workflows/security.yml` (gitleaks/semgrep/shellcheck) | permitted | yes — user decision 2026-06-18, `ICON-0075/plan.md:8` |
| `markdownlint` pipeline | forbidden | yes — needs manifest + install; ADR-005 Alt. 1 already "deferred" |
| a future dependency-free `.mjs` manifest validator | permitted | the outcome R-0a exists to unblock |

**One sharpening the manager's formulation needs.** "A runtime the harness already requires" is
too loose to act on, because the runtimes are not equally available. State a runtime tier:

- **Node — assumed present.** Both harnesses are Node CLIs, so `node` is on PATH wherever ICON
  runs (`.context/domains/hooks.md:31`).
- **Bash / PowerShell — assumed only in maintainer/repo-local scripts, and only in parity pairs**,
  because neither is universally present (ADR-004; `standards/shell-portability.md`).
- **`python3` — NOT an assumed runtime.** On Windows it resolves to a non-executing Store stub.
  This is the direct replacement for false assertion #3, not an addition.

**Deliberate non-ruling.** The amendment must *permit* portable `.mjs` for new deterministic checks
without *mandating* it. Adopting `.mjs`-by-default is audit Open Question 5 (`audit-report.md:595`),
a separate item explicitly blocked on R-0a. Unblocking it is R-0a's job; deciding it is not.

---

## Q3 — Was the ADR-004 citation ever sound?

**No. It was a category error from the start**, and the correction is therefore larger than
"reality moved on."

ADR-005:28 rejects a Node validator because it *"would introduce a Node toolchain that contradicts
ADR-004's tool-agnostic stance."* Reading `004-tool-agnostic-content.md` in full:

1. **ADR-004 forbids *harness*-coupling, not runtimes.** Its Context (`:8`) is entirely about
   Claude Code exposing `${CLAUDE_PLUGIN_ROOT}` where Copilot CLI does not; its Decision (`:12`) is
   that skills "must not embed runtime-only assumptions" — i.e. must not work in one harness and
   break in the other. Node works in **both**. It supplies no premise for banning Node.

2. **ADR-004 argues *for* `.mjs`, not against it.** `domains/hooks.md:43` makes a single `.mjs` the
   **rule** for every new plugin hook precisely because a `.sh`/`.ps1` pair dual-runs and drifts —
   an ADR-004 portability failure. Node is the *most* ADR-004-compliant option available.

3. **The 004↔005 citation is sound in the other direction only.** ADR-004:28 rejects
   "generate runtime-specific copies from a single source" because it *"adds a build step … (see
   ADR-005)."* That is 004 correctly invoking 005. ADR-005's reverse citation has no counterpart in
   004's text.

4. **The record contradicted itself when written.** ADR-005's Decision paragraph (`:12`) already
   describes a committed `.mjs` wrapper running in place as compliant, while its Alternatives
   paragraph (`:28`) rejects "a Node toolchain." The author had the right distinction —
   in-place script vs. provisioned toolchain — but named it "Node toolchain" and cited the wrong
   ADR for it. The correct ground was ADR-005's **own**: an install step.

**Consequence for the fix.** Because the flaw is a misattribution and not decay, the `## Amendments`
entry must say so explicitly and quote the original sentence. That original wording is worth
preserving verbatim: it explains why downstream documents (notably ADR-008:61 and ADR-014:17) read
the way they do, and the amendment is the only place a reader will ever be told it was wrong.

---

## Q4 — Blast radius

**Triage rule used** (recommend adopting it, it keeps the sweep bounded): *does the site restate
ADR-005's scope as a rule the reader will apply — or merely record that a past design respected
ADR-005?* Fix the first; leave the second, because rewriting a past record's Context is exactly the
history-erasure the amend/supersede convention is designed to avoid.

### MUST FIX — asserts the scope as a live rule

| # | Site | Problem | Action |
|---|---|---|---|
| 1 | `.context/decisions/005-no-build-step.md:8,12,19,23,28` | the subject; all five defects | full replacement text below |
| 2 | `.claude/claude.md:9` | "the **single** `hooks/inject-manager-role.mjs` wrapper" — two ship; omits `guardrail-pretooluse.mjs` | replacement below |
| 3 | `.claude/claude.md:11-15` | declares the broken `python3` command as *the* validation, in the always-loaded project-instruction file — highest-frequency exposure of the claim the ADR is about to retract | replacement below |
| 4 | `.claude/claude.md:26` | `hooks/` described as the SessionStart hook only | replacement below |
| 5 | `.context/decisions/008-always-loaded-token-budget.md:61` | "ADR-005: no build step; **precludes auto-generated session size checks**" — a directly inherited false inference; it steered ICON-0033 and ICON-0088 away from a ~30-line dependency-free script | replacement + `## Amendments` entry below |
| 6 | `.context/workflows/task-plan/phase-architecture.md:63` | "ICON is pure-content (no build step) — **proposals must not require a compile/test pipeline**" — injected into *every* @architect dispatch; the sentence a future architect reads at the exact moment of proposing a mechanical check | replacement below |
| 7 | `.context/workflows/task-plan/phase-investigation.md:61` | same, in the @researcher template | replacement below |
| 8 | `.context/workflows/task-plan/base.md:62` | "ICON is pure-content (no compile/test/package manager) — see ADR-005" — true but one-sided; copied into every `plan.md` `## Constraints` | replacement below |
| 9 | `.context/rules-index.md` ADR-005 row | "Applies when… **Adding a build, compile, lint, or test step**" — a contributor proposing a dependency-free check script does not match this, so the router never sends them to the ADR that governs them | replacement below |

Verified: the `context_template/` counterparts of items 6–8 carry **no** ADR-005 prose (these are
ICON-local customizations), so no template change and no `iconrc.json` bump is owed. Confirms scope.

### NO CHANGE — already correct, and now *supported* rather than contradicted

- `.context/META.md:7` — "markdown + JSON + **two** Node.js hook wrappers". Correct. Do not churn.
- `.context/domains/github-access.md:24` — "**two** cross-platform Node.js hook wrappers (ADR-005…)". Correct.
- `.context/standards/secure-coding.md:11` — the correct line, correctly attributed. **Cite it in the amendment.**
- `.context/decisions/004-tool-agnostic-content.md:28` — sound; codegen *is* a build step under the corrected scope.
- `.context/decisions/012-context-knowledge-graph.md:18` — already states the correct reading.
- `.context/decisions/015-all-specialists-isolated.md:41`, `013:12` — "Pure-content (ADR-005)". Correct.
- `.context/standards/terseness-calibration.md:24-26`, `.context/workflows/task-plan/phase-testing.md:7-11` — "no test runner". Still true.
- `skills/security-review/SKILL.md:25` — correct.
- `agents/manager.agent.md:218,244` — "no lint command (pure-content repo, ADR-005)" — accurate use.
- `CONTRIBUTING.md` — **no ADR-005 restatement at all.** `:51-52` correctly routes contributors to
  `.context/decisions/` and to `.githooks/pre-commit`. Nothing owed. (Answers the manager's question.)
- All `.context/tasks/**` artifacts and `CHANGELOG.md:29` — historical. Leave.

### OPTIONAL — defensible either way, manager's call

- `.context/decisions/014-model-aware-delegation.md:17` — "(ADR-005 — no build/**gate** tooling)".
  "No gate tooling" is false. But it sits in ADR-014's *Context*, recording constraints as understood
  at the time — it is not a rule a reader takes from ADR-014. Leaving it is defensible; the ADR-005
  amendment makes the true scope discoverable. **Lean: leave.**
- `.context/overview.md:21` — "a single Node.js (`.mjs`) wrapper **for the SessionStart hook**" is
  literally true and ICON-0089 deliberately left it (`ICON-0089/plan.md:39`). But the same
  paragraph's *"Validation is 'the JSON parses' plus structural review"* is the same stale
  validation story. **Lean: append `plus the `.githooks/pre-commit` gates and the `security` CI
  workflow` to that clause only**, honoring ICON-0089's decision on the hook-count half.
- `agents/manager.agent.md:218,244` cite ICON's own `ADR-005` by number inside **consumer-shipped**
  content, where a consumer's ADR-005 is something else entirely. Out of scope for R-0a; flagging
  as a candidate finding for a future cycle.

### OUT OF SCOPE — do not do here

Building the manifest validator (audit IO-I-C), the CI re-run job (R-0b), and adopting
`.mjs`-by-default (Open Question 5). R-0a removes the prohibition; it does not exercise the licence.

---

## Proposed text — transcription-ready

### A. `.context/decisions/005-no-build-step.md` — full replacement

```markdown
# ADR-005: No build step, no test runner, no package manager

**Date**: (originating principle; recorded here post-split)
**Status**: Accepted
**Supersedes**: none
**Superseded-by**: none

## Context

ICON is pure content: markdown agent/skill/command definitions, JSON manifests, and a small number
of committed scripts that run in place — two Node `.mjs` harness hooks, two git hooks, and
bash/PowerShell helpers under `skills/*/scripts/` and `.claude/skills/`. Adding a *build* step — a
generated artifact, a dependency-install step, or a framework that must be provisioned before the
repo can be validated — would impose install and CI infrastructure on every contributor and every
environment.

## Decision

**Forbidden**: a package manifest or lockfile (`package.json`, `Cargo.toml`, `pyproject.toml`); an
install step (`npm install`, `pip install`); third-party runtime dependencies; generated or compiled
artifacts (a `Makefile`, transpiled output, generated per-runtime copies); and a test framework.

**Permitted, and always was**: *committed scripts that run in place* on a runtime the environment
already provides, importing only that runtime's standard library. `hooks/*.mjs`,
`.githooks/pre-commit`, and `skills/context-maintenance/scripts/{context-graph.{sh,ps1},check-rules-index.sh}`
are all in scope and always were. A new deterministic check is a script, not a build step, so long as
it adds no manifest, no lockfile, and no third-party import — the rule `standards/secure-coding.md`
Rule 3 already states operationally.

**Assumed runtimes.** Node is assumed present: both harnesses are Node CLIs, so `node` is on PATH
wherever ICON runs (see `domains/hooks.md`). Bash and PowerShell are assumed only in
maintainer/repo-local scripts, and only in parity pairs, since neither is universally present
(ADR-004). **`python3` is not an assumed runtime** and must not be relied on — on Windows it
resolves to a non-executing Store stub.

**Validation** is the `.githooks/pre-commit` gate set, the `security` GitHub Actions workflow
(gitleaks / semgrep / shellcheck), and structural review during PR. CI is permitted (user decision,
2026-06-18, ICON-0075); this record's original "no CI" framing described the repo's state at the
time, not a rule.

## Consequences

**Positive:**
- Zero dependency surface; `git clone` plus an already-present runtime is the entire toolchain.
  Nothing to install, nothing to keep current, no supply chain.
- Any contributor with a text editor can author or review changes.
- Verification is cheap to add: a new invariant costs a dependency-free script and a `pre-commit`
  call, not a pipeline.

**Negative:**
- No automated lint for markdown malformations (e.g. the YAML frontmatter `colon-space` parse
  failure that MKT-0078 caught manually).
- No regression test suite for agent behaviour — relies on the `icon-audit` skill and retrospective
  discipline.
- Every mechanical check is hand-written against a standard library, so shared logic is duplicated
  rather than factored into a dependency — the secret-pattern list exists in both
  `hooks/guardrail-pretooluse.mjs` and `.githooks/pre-commit`.

## Alternatives Considered

1. **Add a markdown linter (e.g. `markdownlint`)**: deferred — it requires a package manifest and an
   install step, which the Decision forbids, and no recurring class of bug yet justifies vendoring or
   reimplementing one.
2. **Build an agent-spec validator as a dependency-free `.mjs` script**: permitted. Not yet built;
   cost/benefit gates it, not policy.
3. **Build a validator framework requiring `npm install`**: rejected — that is the install step the
   Decision forbids.

## Amendments

**2026-07-26 (ICON-0091).** The Decision is unchanged. Four supporting statements were corrected
because the repo they described moved, and one because it was wrong when written.

- *Context* said "two shell hooks." There have never been shell harness hooks: ICON-0012
  consolidated a `.sh`/`.ps1` pair into a single `.mjs`, and ICON-0073 added a second,
  `guardrail-pretooluse.mjs`.
- *Decision* said "its **single** cross-platform Node.js wrapper." Two ship.
- *Consequences* claimed "No CI flakiness — the only runtime check is
  `python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))"`." A `security` CI
  workflow has existed since ICON-0075, and that `python3` command does not execute on Windows. It
  was invoked by nothing; it was prose in a document.
- *Consequences* cited the `plugin-audit` skill, renamed `icon-audit` in ICON-0042.
- *Alternatives* rejected "a Node-based agent-spec validator" because it "would introduce a Node
  toolchain that contradicts ADR-004's tool-agnostic stance." **That citation was never sound.**
  ADR-004 forbids content that couples to *one* harness; Node runs in both and is the runtime of
  both shipped hooks, which is why `domains/hooks.md` makes `.mjs` the rule for new hooks — ADR-004
  argues *for* `.mjs`, not against it. The real concern was this ADR's own — an install step — and
  the Decision now names it directly. The original sentence also contradicted this record's own
  Decision paragraph, which already described a committed `.mjs` wrapper running in place as
  compliant.

This is a correction, not a reversal: no position changed, so no superseding ADR was created. See
`decisions/README.md` and `context-document-guidelines § Correcting a stale ADR`.
```

*(≈600 words — comparable to ADR-011/015, well under ADR-008 at 1453 and ADR-013 at 1020. No split
gate risk. The `**Supersedes**` / `**Superseded-by**: none` fields are new to this ADR: 001–011 lack
them, 012+ carry them. Adding them here is optional but recommended — this task's entire question was
"is ADR-005 superseded?", and the fields make the answer machine-explicit at zero graph cost.)*

### B. `.claude/claude.md`

Line 9 →
```markdown
- **Node.js** for the two cross-platform hook wrappers (`hooks/inject-manager-role.mjs`, `hooks/guardrail-pretooluse.mjs`) and **Bash / PowerShell** for the `.githooks/` gates and the maintainer `release-plugin` scripts.
```

Lines 11–15 →
````markdown
There is **no build step**, **no test runner**, and **no package manager** (ADR-005) — but committed
scripts that run in place on an already-present runtime are in scope, and always were. Validation is
the `.githooks/pre-commit` gate set plus the `security` CI workflow. A manifest parse check:

```bash
node -e "const m=require('./.claude-plugin/plugin.json'); console.log('OK', m.name, m.version)"
```

`python3` is **not** an assumed runtime — on Windows it resolves to a non-executing Store stub.
````

> Verified on this machine: `node v24.17.0`; the command above prints `OK ICON 2.0.0`. The
> `python3` line it replaces is the one the audit verified non-executing.

Line 26 →
```markdown
| `hooks/` | Harness hooks: `SessionStart` manager-role injection and the `PreToolUse` security guardrail. |
```

### C. `.context/decisions/008-always-loaded-token-budget.md`

Line 61 →
```markdown
- [ADR-005](005-no-build-step.md): no build step or dependency install. A committed, dependency-free script run in place is in scope, so a mechanical size check is permitted — none has been built.
```

Append at end of file:
```markdown
## Amendments

**2026-07-26 (ICON-0091).** The Decision is unchanged. The ADR-005 cross-reference previously read
"no build step; precludes auto-generated session size checks" — it inherited ADR-005's own conflation
of a build step with a committed script. ADR-005 has never forbidden a dependency-free script run in
place, so a mechanical size check is permitted; whether to build one is a cost question, not a policy
one. (ADR-008's own scope remains open under ICON-0089 audit item O-T1.)
```

### D. Task-plan workflow constraint lines

`.context/workflows/task-plan/base.md:62` →
```markdown
- ICON is pure-content: no build step, no test runner, no package manager (ADR-005). Committed, dependency-free scripts run in place ARE in scope.
```

`.context/workflows/task-plan/phase-architecture.md:63` →
```markdown
  - ICON is pure-content (ADR-005) — no manifest, no install step, no generated artifacts. A committed, dependency-free script run in place is permitted and is the normal way to add a mechanical check.
```

`.context/workflows/task-plan/phase-investigation.md:61` →
```markdown
  - ICON is a pure-content plugin (ADR-005) — no manifest, install step, or generated artifacts. Recommendations may assume a committed, dependency-free script run in place; they must not assume a build or install.
```

### E. `.context/rules-index.md` — ADR-005 row "Applies when…" cell

```markdown
| 005 | Adding a build, lint, or test step — or deciding whether a proposed check script is permitted | [decisions/005-no-build-step.md](decisions/005-no-build-step.md) |
```

---

## Gate impact

| Gate | Effect | Why |
|---|---|---|
| `context-graph.sh --check` | fires (`.context/` staged), stays green | No node added or removed; no new edges. `**Supersedes**/**Superseded-by**: none` parses as zero edges — already proven by ADR-012/013 carrying `none` on a green tree. |
| `check-rules-index.sh` | fires, stays green | Row count and link targets unchanged; only the "Applies when…" cell wording changes, which the checker does not constrain. |
| README skill-registration (O-V1) | fires on the `skills/` edit, passes | `context-document-guidelines` already has its `README.md` row; the edit is content-only, no rename. |
| `context_template` version gate | does **not** fire | Nothing staged under `context_template/`; verified the three workflow counterparts carry no ADR-005 prose. |
| dead-reference resolver | fires, stays green | All new references are by-name (`standards/secure-coding.md`, `domains/hooks.md`) to existing files. |

**Sequencing** (per `domains/hooks.md:121-129` gate coupling): commit `.context/` first, then
`skills/context-document-guidelines/`. `.claude/claude.md` may ride with either.

**CHANGELOG**: the `skills/context-document-guidelines/` change is consumer-shipped → one
`[Unreleased]` line. `.context/` and `.claude/` changes are maintainer-internal. **No version bump,
no tag** (release guard).

---

## Risks

| Risk | L | I | Mitigation |
|---|---|---|---|
| Amendment is read as licence to start adding scripts freely | M | M | Decision text names the forbidden set first and explicitly defers `.mjs`-by-default to Open Question 5. |
| Future contributor still lands on stale downstream text | M | M | Blast-radius list above is exhaustive for `.context/`, `skills/`, `agents/`, `CONTRIBUTING.md`; the triage rule is stated so a later sweep can reapply it. |
| "Amend, don't supersede" gets over-applied to a genuine reversal | L | H | The convention's table leads with the discriminating question, and the proportionality paragraph bounds it. |
| Editing a shipped skill widens R-0a beyond its remit | L | L | Explicitly requested by the manager; single subsection; CHANGELOG line owed and noted. |

## Alternatives Considered

1. **New ADR-016 scope-superseding 005's Consequences + Alternatives** (the audit's own proposal,
   `05-infrastructure.md:329`). Rejected — Q1 arguments 1–4; decisively, superseding freezes a record
   that must stay live.
2. **Amend silently, no `## Amendments` section.** Rejected — the ADR-004 misattribution is the only
   explanation for how downstream docs (ADR-008:61, ADR-014:17) acquired their errors; deleting it
   removes the evidence trail and leaves a future auditor to re-derive this whole analysis.
3. **Amend ADR-005 only; leave the blast radius.** Rejected — `.claude/claude.md` is always-loaded,
   and `phase-architecture.md:63` is read at the precise moment an architect proposes a check. Fixing
   the ADR while leaving those two is the smaller half of the fix.
4. **Also mandate `.mjs` for new checks.** Rejected — that is audit Open Question 5, a separate item
   the manager explicitly excluded. R-0a removes the prohibition; it does not exercise the licence.

## Open Questions & Assumptions

- **Assumption**: correcting `.claude/claude.md` is within R-0a. It restates two of ADR-005's false
  claims and is the highest-frequency exposure of the broken `python3` command. Leaving it would make
  it the *last* home of a claim the ADR just retracted — strictly worse than before. Replacing one
  false one-liner with a verified-true one is not building the validator (audit IO-I-C, out of scope).
  **Manager: correct if you read the boundary differently.**
- **Open question (non-blocking)**: `.context/overview.md:21` was deliberately left by ICON-0089.
  Proceeding on the assumption that its "Validation is 'the JSON parses' plus structural review"
  clause may be corrected while its hook-count half is left alone. Drop it if you prefer to honor
  ICON-0089's decision wholesale.
- **Open question (non-blocking)**: whether ADR-014:17's "no build/**gate** tooling" is corrected.
  Recommended: leave (it is Context, not a rule).
- **No blocking gaps.** All four questions were answerable from the repo.
