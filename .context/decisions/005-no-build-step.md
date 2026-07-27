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
