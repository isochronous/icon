# Secure-Coding Standard

Secure-coding rules for ICON's own shell and JS hook/script source — grounded in observed ICON practice.

## Rules

1. **Fail-open enforcement hooks** — a `PreToolUse` hook that throws or exits non-zero makes the harness fail-CLOSED: Copilot reads the error as a deny on *every* tool call and bricks the session. Wrap the entire hook body so any internal error is swallowed, ALWAYS `exit 0`, and emit a deny decision only on a positive rule match. The absence of a decision must always mean "allow". (ICON-0073 guardrail.)

2. **Never log secret values** — a security gate logs only a redacted reference or the pattern NAME, never the matched secret. The guardrail audit log records the log-safe `pattern` name for a secret-scan hit, never the credential bytes. (ICON-0073.)

3. **Node built-ins only** — hook and helper scripts import only `node:*` modules; no external dependencies, no `package.json`, no lockfile. ICON has no build/install step, so a third-party import has nothing to resolve it. (ADR-005.)

4. **Tight, real-token regexes** — credential patterns match the real shape of a token (length-bounded, charset-bounded), not a bare prefix. A bare-prefix pattern fires on docs, placeholders, and prose; a shape-bounded pattern does not. (ICON-0073/0075.)

5. **Fail-open on missing config/env** — a missing environment variable or an unparseable config file resolves to a stderr warning plus `exit 0` with safe defaults; it never throws or exits non-zero. `inject-manager-role.mjs` degrades to no-op rather than blocking the session when its inputs are absent. (inject-manager-role.mjs.)

6. **`grep -Eq -e "$pat"` for dash-leading patterns** — when a regex or string passed to `grep` can begin with `-` (e.g. a PEM header), pass it after `-e` (or `--`) so `grep` does not parse it as an option. Remember that an `if grep …` guard treats grep's option-error (exit 2) as "no match", so a malformed pattern fails SILENTLY-OPEN — the gate looks live but never fires. Test every pattern against a known-positive fixture. (See the `shell-portability` standard; ICON-0075.)

7. **`set -euo pipefail`** — every bash script opens with `set -euo pipefail` so an unset variable, a failed command, or a broken pipe aborts rather than continuing on bad state. (The fail-open hook bodies of Rule 1 are the deliberate exception: they catch their own errors and still exit 0.)

8. **No secrets in source** — use credential placeholders, never real tokens. The pre-commit secret-scan and the CI gitleaks gate block a real credential before it reaches `main`; matching the placeholder convention keeps fixtures and examples scannable without tripping the gate. (ADR-006.)

9. **Scoped stderr-suppression discipline** — `2>/dev/null` (and similar) is **permitted** in ICON's own autonomous scripts (`.githooks/*`, `skills/*/scripts/*.sh`, etc.) where it suppresses genuinely-expected noise — the `.githooks/pre-commit` itself does this on git plumbing probes. What is disallowed is suppression that would hide a real failure or diagnostic. The ban on output suppression that ships in `shared/common-constraints.md` applies only to commands an agent proposes or executes during a CLI session — not to autonomous hook/script code. (ADR-007.)

10. **Operator logs outside the repo** — audit and telemetry logs write under `~/.icon/` (or a similar operator path), never into the tracked tree. They are operator telemetry, not project artifacts; the guardrail audit log lives at `~/.icon/guardrail-audit.log`. (ICON-0073 guardrail audit log.)

11. **Fail-OPEN at runtime, fail-CLOSED at commit time** — match a gate's failure mode to *when* it runs. A RUNTIME enforcement hook (e.g. a `PreToolUse` guardrail on a fail-closed harness — Rule 1) must fail-OPEN: wrap the body, always `exit 0`, and deny only on a positive rule match. A COMMIT-TIME gate (a `.githooks/pre-commit` check) must fail-CLOSED: invoke the checker as `… || { echo "…"; exit 1; }` — never `if checker; then …`, which swallows the checker's own crash as "no violation" — and give the checker a **3-value exit contract**: `0` clean / `1` violation / `2` parser-or-environment error, where "zero units discovered on a non-empty tree" resolves to `2`. This closes the fail-OPEN-gate class for a fail-CLOSED gate: a parser bug that finds nothing can never be misread as a clean pass. (ICON-0081; extends the runtime fail-OPEN invariant of Rule 1 / ICON-0073 and the silent-fail-open grep trap of ICON-0075.)

12. **Pin CI GitHub Actions to a commit SHA** — every `uses:` in a `.github/workflows/*.yml` job pins a full 40-char commit SHA, never a mutable tag or branch (`@v4`, `@main`) — a tag can be silently repointed (supply-chain risk). Enforced by the semgrep `github-actions-mutable-action-tag` rule in the `security` workflow; a mutable `uses:` fails CI. Before committing a pin, verify the SHA against the upstream tag: `gh api repos/<owner>/<repo>/git/refs/tags/<tag> --jq '.object.sha,.object.type'` (dereference an annotated `tag` object to its commit) rather than copying a SHA blind. (ICON-0087.)

Changes to ICON's hooks or scripts should be checked with the `security-review` skill before shipping.
