# ADR-005: No build step, no test runner, no package manager

**Date**: (originating principle; recorded here post-split)
**Status**: Accepted
**Supersedes**: none
**Superseded-by**: none

## Context

ICON is pure content: markdown agent/skill/command definitions, JSON manifests, and a number of
committed scripts that run in place. Those scripts live under `hooks/` (Node `.mjs` harness hooks),
`.githooks/` (bash git hooks), `skills/*/scripts/` (bash and PowerShell helpers shipped with the
plugin), `.claude/skills/*/scripts/` (bash maintainer helpers), and the `workflows/` directories of
`.context/` and `context_template/`. One of them is worth calling out because it reaches outside the
repo: `skills/writing-skills/render-graphs.js` imports only Node's standard library, but shells out
to a Graphviz `dot` binary the environment must already provide.

**This record describes where those scripts live; it does not inventory them.** The set changes
whenever one is added, so any file-by-file list here goes stale on the next commit and misleads the
next reader. A reader who needs the current set should derive it — `git ls-files '*.sh' '*.ps1'`
covers the extension-bearing scripts, and the git hooks are extensionless.

Adding a *build* step — a generated artifact, a dependency-install step, or a framework that must be
provisioned before the repo can be validated — would impose install and CI infrastructure on every
contributor and every environment.

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

**Assumed runtimes.** Node is the assumed runtime for shipped scripts, and `hooks/*.mjs` is the
rule for new harness hooks — `domains/hooks.md § Cross-Platform Hooks: Single Node.js Wrapper`
sources that to Claude Code being itself a Node CLI. Treat it as a strong default, not a guarantee:
that reasoning is recorded
for Claude Code only, and a bundled-runtime install need not expose `node` on PATH. A script that
depends on `node` should verify it rather than presume it.

Bash and PowerShell are both in use, and *not* only in maintainer tooling. Repo-local gates under
`.githooks/` and maintainer scripts under `.claude/skills/*/scripts/` are bash-only. Scripts under
`skills/*/scripts/` are shipped with the plugin and run in the **consumer's** environment, not the
maintainer's — `standards/shell-portability.md` governs them. Because neither shell is universally
present, a shipped script a consumer may need to run on either platform needs cross-platform
coverage; `context-graph` and `append-retrospective-entry` reach it today by shipping `.sh`/`.ps1`
parity pairs. Coverage is partial: shipped and repo-local scripts that are bash-only remain, an
outstanding portability gap rather than a rule this record states. Which ones they are is not
enumerated here, for the reason the *Context* paragraph gives.

**The gap closes by migration to Node, not by adding PowerShell twins** (user decision, 2026-07-26).
ICON standardizes on Node as the scripting runtime, and scripts migrate to a single portable `.mjs`
where practical — the same reasoning `domains/hooks.md § Cross-Platform Hooks: Single Node.js Wrapper` already applies to
harness hooks, where one `.mjs` replaced a `.sh`/`.ps1` pair and structurally removed parity drift.
The migration itself is separate work and is not scoped by this record.

**`python3` is not an assumed runtime** and must not be relied on — on Windows it resolves to a
non-executing Store stub.

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
  `python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))"`." CI security scanning
  has existed since ICON-0075, first as the `security` stage of `.gitlab-ci.yml`; ICON-0080 deleted
  that file and ported the three jobs to `.github/workflows/security.yml`. And that `python3`
  command does not execute on Windows. It was invoked by nothing; it was prose in a document.
- *Consequences* cited the `plugin-audit` skill, renamed `icon-audit` in ICON-0042.
- *Alternatives* rejected "a Node-based agent-spec validator" because it "would introduce a Node
  toolchain that contradicts ADR-004's tool-agnostic stance." **That citation was never sound.**
  ADR-004 forbids content that couples to *one* harness, and both shipped hooks are `.mjs`, which
  `domains/hooks.md` makes the rule for new hooks. Reading that as ADR-004 arguing *for* `.mjs` is
  an inference drawn here, not a claim either record makes: `domains/hooks.md` grounds the `.mjs`
  rule in Claude Code's hook schema having no per-platform conditional, and cites ADR-004 nowhere.
  What is verifiable is narrower and sufficient — ADR-004 does not forbid Node. The real concern was
  this ADR's own — an install step — and
  the Decision now names it directly. The original sentence also contradicted this record's own
  Decision paragraph, which already described a committed `.mjs` wrapper running in place as
  compliant.

This is a correction, not a reversal: no position changed, so no superseding ADR was created. See
`decisions/README.md` and `context-document-guidelines § Correcting a stale ADR`.

**2026-07-26 (ICON-0091, second pass).** The Decision is unchanged. The amendment above introduced
a new false statement while correcting the old ones; review caught it and it is corrected here.

- *Decision* — the "Assumed runtimes" paragraph added above — said bash and PowerShell "are assumed
  only in maintainer/repo-local scripts, and only in parity pairs, since neither is universally
  present **(ADR-004)**." Every clause failed. Shell scripts under `skills/*/scripts/` ship with the
  plugin and run in the consumer's environment — the premise of `standards/shell-portability.md`,
  and what this record's own *Context* paragraph already said. Parity pairing is real but partial:
  `context-graph` and `append-retrospective-entry` ship `.sh`/`.ps1` pairs, while other shipped and
  repo-local scripts are bash-only — `check-rules-index.sh` among them, which this same Decision
  names as in-scope. And **ADR-004 says nothing about shell parity pairs**; that citation was
  invented. The paragraph is now a description of what the repo does, with the gap named as a gap
  and no file-by-file list to go stale, sourced to `standards/shell-portability.md`.
- *Decision* also said Node is assumed present because "**both** harnesses are Node CLIs, so `node`
  is on PATH wherever ICON runs (see `domains/hooks.md`)." `domains/hooks.md` makes that argument
  for Claude Code only, and "the harness is a Node CLI" does not entail "`node` is on PATH" — a
  native-installer install need not expose `node` on PATH even where the harness bundles a runtime.
  Node remains the assumed runtime for shipped scripts; the guarantee is downgraded to a default
  worth verifying.
- *Context* enumerated the committed scripts as if complete, omitting both copies of
  `prune-context.sh` and `skills/writing-skills/render-graphs.js`.
- The *Amendments* entry above attributed the `security` CI workflow to ICON-0075. ICON-0075 added
  the `security` stage to `.gitlab-ci.yml`; ICON-0080 deleted that file and ported the jobs to
  `.github/workflows/security.yml` (`security.yml:1`).
- The same entry asserted "ADR-004 argues *for* `.mjs`" as though sourced. It was an inference, and
  is now labelled as one.

The generalizable lesson is the defect's own shape: the first pass corrected five unsourced claims
and, in the same edit, wrote a sixth with a fabricated citation. A correction pass is not
self-verifying — each replacement assertion needs checking against the repo exactly as the
assertions it replaces did.
