## Task: ICON-0076
## Branch: feature/ICON-0076-security-review-skill-and-standard
## Objective: Add an ICON-specific `security-review` skill (a checklist runnable against ICON's own shell/JS changes) and a short `secure-coding` standard for ICON's own scripts. Closes #43 (RFC security review Q7 + Q8 — the process/skill/standard side; the CI/tooling side was #42/ICON-0075).

## Folder: .context/tasks/ICON-0076-security-review-skill-and-standard/

## Decisions
- **New `security-review` skill, NOT extend `code-quality-rules`** (Explore): code-quality-rules is `user-invocable:false`, framed for reviewing arbitrary CONSUMER code, embedded in a 5-pass structure; its Pass 2 is generic web-app security (SQLi/XSS/authz). A security-review of ICON's OWN infra has a distinct trigger ("about to ship a change to a `.mjs` hook / `.sh` script / `.githooks/`"), distinct checklist (fail-open hooks, never-log-secrets, ADR-005/006/007, grep `-e`, Node-builtins-only), and a distinct audience (ICON maintainers). Extending Pass 2 would contaminate a consumer-code review pass.
- **Invocation**: `user-invocable: true` + `commands/security-review.md` → `/ICON:security-review` (plugin-namespaced; no collision with Anthropic's bare `/security-review`). Maintainer-runnable against the current diff; @reviewer also applies it when ICON hook/script files are in a diff. (Flag this invocation choice in the MR.)
- **New `.context/standards/secure-coding.md`** (NOT a section in security.md or shell-portability.md): security.md is runtime-security (prompt injection, harness controls, MCP CVE); shell-portability.md is portability. Secure-coding is about HOW ICON's own scripts are authored — a distinct discriminator. It codifies the ~10 conventions ICON's scripts ALREADY follow (grounded in observed practice, not generic OWASP): fail-open hooks; never log secret values; Node built-ins only (ADR-005); tight real-token regexes; fail-open on missing config; `grep -Eq -e` for dash-leading patterns (shell-portability Rule 4); `set -euo pipefail`; ADR-006 credential placeholders; ADR-007 devnull discipline; audit logs outside the repo tree.
- **ICON-INTERNAL standard** (ICON's own scripts) → do NOT create a `context_template/` consumer copy → no iconrc template-version bump. (Verify security.md/shell-portability.md are likewise ICON-local, not templated, to confirm the pattern.)
- **OWASP/CWE mapping = OUT of scope** (issue: "if compliance is needed" — none stated). Note as optional follow-up; keep the standard tight and ICON-grounded.
- The skill cites the secure-coding standard by path (`.context/standards/secure-coding.md`) in prose, and references `shell-portability` by skill name — matching how `guardrail-pretooluse.mjs` cites `security.md`.

## Key Files
- `skills/security-review/SKILL.md`: CREATE — `user-invocable: true`; a checklist skill (named-heading + rationalization-table + red-flags style, per writing-skills). Items map to the secure-coding standard's rules; trigger = reviewing/shipping a change to ICON's hooks/scripts/`.githooks`. Under the 500-line / earn-every-line cap.
- `commands/security-review.md`: CREATE — `description:`-only frontmatter (filename = command name), per the existing `commands/*.md` pattern.
- `README.md`: CHANGE — add `| `security-review` | … |` row to the user-facing Skills table (O-V1 pre-commit gate REQUIRES this in the same commit).
- `.context/standards/secure-coding.md`: CREATE — the ~10 rules, each grounded in an ICON convention/task ref.
- `.context/rules-index.md`: CHANGE — add a `secure-coding` row (rules-index freshness gate REQUIRES this in the same commit).
- `CHANGELOG.md`: CHANGE — `[Unreleased]` entry.

## Progress
- [x] Create branch + task folder + initial plan.md
- [x] Read-only Explore — code-quality-rules structure, no existing security-review skill, skill/standard conventions, the 10 observed script conventions, registration requirements (findings in Decisions)
- [x] @coder authors skill + standard + registration — security-review skill (user-invocable, 55 lines), secure-coding standard (10 ICON-grounded rules), command file, README + rules-index rows; confirmed secure-coding is ICON-local (template standards are a different set); pre-commit green
- [x] @reviewer checkpoint — APPROVE-WITH-FIXES, 0 Critical; all 10 rule citations verified accurate, role boundary vs code-quality-rules clean. Two Moderate fixes applied: (1) dropped the dead-ref exemption marker → reference the standard by name (gate-free, matches writing-skills); (2) reframed Rule 9 — it contradicted/miscited ADR-007 (which EXEMPTS autonomous `.githooks/*` + `skills/*/scripts/*.sh` from the devnull ban) → now "Scoped stderr-suppression discipline" aligned with ADR-007.
- [x] changelog-entry — done by coder (### Added, ICON-0076)
- [x] Reconcile plan.md
- [x] Retrospective (two-stage) — entry inserted (ICON-0066 pruned → archived); promoted "verify a cited ADR's scope" (verify-design-claims-against-artifacts, 4th firing) + "by-name not path for .context docs in skills" (writing-skills) — committed 9093b74
- [x] Commit + push + open MR — deliverables committed; MR !60 opened (label security, remove_source_branch)
- [ ] PAUSE — awaiting user go-ahead to merge !60 → delete branch. FINAL item — #39-#43 RFC security backlog complete after this.

## Review Checkpoint
@reviewer APPROVED the full diff (security-review skill, secure-coding standard, command file, README + rules-index registration, CHANGELOG) — APPROVE-WITH-FIXES, 0 Critical/Moderate-unresolved. Independently verified all 10 secure-coding rules against ICON's actual code/ADRs, the role boundary vs `code-quality-rules` (clean: consumer-code/user-invocable:false vs ICON-infra/user-invocable:true; no ambiguous double-fire), and re-ran the pre-commit gate (exit 0). The two reviewer-requested Moderate fixes (by-name reference; ADR-007 reconciliation of Rule 9) were applied and re-verified (gate green without the exemption marker) — so this checkpoint covers the complete changed-file set.

## Open Questions / Blockers
- Invocation style (user-invocable slash command vs reviewer-auto-applied) — defaulting to user-invocable:true + command; flag in MR for user confirmation.

## Constraints
- ICON is pure-content (ADR-005). Verification = grep for the new files/sections + pre-commit green (O-V1 skill-registration gate + rules-index freshness gate). The ICON-0075 secret-scan/shellcheck pre-commit gates are now active (the new files are markdown — no tokens, no `.sh`).
- `.claude-plugin/plugin.json` is the plugin version SSOT (ADR-003) — do NOT bump.
- `writing-skills` Iron Law: author the skill per its conventions (description = triggering conditions only; named-prefixed headings; cross-ref by skill name).
