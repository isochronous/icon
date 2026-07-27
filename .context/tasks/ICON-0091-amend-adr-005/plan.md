## Task: ICON-0091
## Branch: feature/ICON-0091-amend-adr-005
## Objective: Resolve roadmap item **R-0a** from the ICON-0089 audit — ADR-005 is `Status: Accepted` while asserting four things that are no longer true, one of which (its rejection of a Node toolchain) blocks the mechanization roadmap. Bring the decision record back into agreement with reality so subsequent work is not arguing against a live ADR.
## Folder: .context/tasks/ICON-0091-amend-adr-005/

## Phase State
- **Phase plan**: architecture → implementation → completion
- **Completed**: —
- **Current**: architecture   (status: in-progress)
- **Next**: implementation
- **Loaded skill**: task-plan-phase-architecture
- **Branch**: feature/ICON-0091-amend-adr-005
- **Attempts (current phase)**: 1

## Decisions
- **Branched off `main` (`6a57e1b`), not the open ICON-0090 branch.** PR #11 does not touch `.context/decisions/` (ADRs are categorically excluded from the `## Related` seam), so there is no overlap and no reason to stack.
- **This is an architecture task, not an edit task.** The substantive question — amend in place vs. supersede with a new ADR — is a decision about how this repo treats decision records, not a wording fix. Routed to @architect (tier `complex`, the role default) before any text is written.
- **Authorized scope is R-0a only.** The user authorized starting R-0a specifically; the remaining ICON-0089 dispositions and the nine `upgrade-repo` defects stay untriaged. R-0b (a CI job re-running the existing invariants) is the natural next step but is **not** in this task.

## Key Files
- `.context/decisions/005-no-build-step.md` — the subject.
- `.context/decisions/README.md` — Decision Log table; needs a row update if status changes or a new ADR is added.
- `.context/rules-index.md` — routes to decisions; `check-rules-index.sh` is a pre-commit gate, so any ADR add/rename must keep it resolving.
- `.context/decisions/004-tool-agnostic-content.md` — ADR-005 cites it as grounds for rejecting Node tooling; whether that citation was ever sound is part of the question.
- `.context/domains/hooks.md`, `.context/standards/shell-portability.md` — describe the current hook and script reality ADR-005 must not contradict.

## Phase Handoff Log

*(appended at each phase boundary)*

## Progress
- [x] Read ADR-005 in full; catalogued the false assertions (below)
- [x] @architect: **amend in place**, no new ADR. Rejected the audit's own ADR-016 proposal on four grounds, decisively that supersession *freezes* an ADR's content while ADR-005 carries a live rule cited in ~18 places. Also established the ADR-004 citation was never sound — a category error from authoring, not decay.
- [x] Implemented across `.context/` (`0878547`) and `skills/` + `.claude/claude.md` + CHANGELOG (`b82785d`)
- [x] **Review round 1 → changes requested (1 Critical).** The amendment introduced a *new* false assertion into ADR-005's Decision with a fabricated `(ADR-004)` citation — the exact defect class this task exists to remove. Fixed in `7df153a`, plus 4 Moderates and the minors.
- [x] ADR-013's inherited over-broad ADR-005 reading amended (`7281072`) — first use of the new convention by a non-author; applied without ambiguity.
- [x] **Review round 2 → changes requested (7 Moderate).** Replacement enumerations incomplete again; a same-commit self-contradiction; a rule violated by its own first use. Fixed in `9ea91e3` by removing the inventory claims rather than correcting them.
- [x] **Review round 3 → approved with comments.** One Moderate: the caveat sentence written to stop undercounts contained one. Fixed in `de65ee2`.
- [ ] Retrospective, then PR ← IN PROGRESS

## The Enumeration Failure (the task's main lesson)

The count of unpaired shell scripts was stated **four times and wrong four times** — 6 (manager brief), 7 (ADR text), 8 (fix commit message), against an independently rebuilt **9**. One file, `context_template/context/workflows/post-commit`, evaded **five** successive passes, three of which explicitly verified "against the repo," and appeared in one commit message's reasoning while being absent from every enumeration that commit wrote.

The cause is not carelessness. **"The set of committed scripts" has no reliable representation**: extension misses the extensionless git hooks, a shebang grep matches `launcher-templates.md` (a doc containing fenced shebangs), and directory membership misses the `context_template/` copies. No single cheap command yields the true set.

This is a boundary condition on the ICON-0089 audit's mechanization thesis, which held that *a class becomes mechanizable exactly when its invariant has a representation to compare against*. Here there is none — so neither a script nor a more careful reader would have fixed it. The working fix was to **stop making the claim**: the ADR now states where scripts live and explicitly disclaims inventorying them. Worth carrying into the audit's follow-up as a documented counterexample rather than a failure.

## The four false assertions (verified against the tree)

| # | ADR-005 says | Reality |
|---|---|---|
| 1 | "pure content (markdown + JSON + **two shell hooks**)" (Context) | There are **no** shell hooks. `hooks/` holds two **Node** wrappers, `inject-manager-role.mjs` and `guardrail-pretooluse.mjs`. |
| 2 | "its **single** cross-platform Node.js wrapper (`hooks/inject-manager-role.mjs`)" (Decision) | Two wrappers since ICON-0073 added the `PreToolUse` guardrail. |
| 3 | "**No CI flakiness** — the only runtime check is `python3 -c ...json.load...`" (Consequences) | CI exists (GitHub Actions security stage: gitleaks, semgrep, shellcheck) and `.githooks/pre-commit` runs ten gates. Separately, that `python3` command **does not execute on Windows** — it resolves to the Store stub — so the one check the ADR names as its entire validation story is broken on the maintainer's own platform. |
| 4 | "Build a Node-based agent-spec validator: **rejected** — would introduce a Node toolchain that contradicts ADR-004" (Alternatives) | **The Node toolchain already shipped.** Two `.mjs` hooks run in both harnesses; Node is a hard prerequisite of Claude Code and Copilot CLI. This is the load-bearing item: the audit's roadmap recommends portable `.mjs` as the default for new deterministic checks, and every such item currently contradicts a live `Accepted` ADR. |

Also stale: the Negative consequences cite the `plugin-audit` skill, renamed to `icon-audit` by ICON-0042.

## Open Questions / Blockers
- **Amend in place or supersede?** The core decision ("no build step, no test runner, no package manager") appears **still correct and still held** — what rotted is the supporting context, one consequence, and one alternative-rejection whose grounds were overtaken by shipped code. If the decision stands and only its evidence is wrong, superseding may misrepresent history as a reversal; amending may erase the record of what was believed when. This is the architect's call and should be stated as a general convention, not a one-off.
- **What is the decision's actual scope?** "No build step" and "no Node scripts" are not the same claim, and conflating them is what makes item 4 load-bearing. The amended record should draw that line explicitly so the next contributor does not re-derive it.
- Does anything else in `.context/` cite ADR-005's Node-rejection as grounds? If so it inherits the error and needs the same correction.

## Constraints
- ICON is pure-content (ADR-005 itself, in its still-valid part) — verification is the structural checkers plus `.githooks/pre-commit`.
- **Release guard**: no `.claude-plugin/plugin.json` bump, no `[Unreleased]` rename, no tag, no `latest` move.
- `context_template/` is out of scope — ICON's own ADRs are not shipped template content, so no template-schema version bump is owed.
- ADR numbers are immutable once assigned; superseded ADRs stay in place with status updated (`decisions/README.md` convention).
- Do not implement other roadmap items. R-0a only.
