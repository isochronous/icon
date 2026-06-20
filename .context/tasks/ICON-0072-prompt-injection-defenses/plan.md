## Task: ICON-0072
## Branch: feature/ICON-0072-prompt-injection-defenses
## Objective: Add prompt-injection defenses so ICON agents treat fetched external content (Jira/Confluence/CI output/web pages) as untrusted data, not instructions — closing the top data-leakage risk from the ICON AI RFC security review (GitLab #39, RFC Q3).
## Folder: .context/tasks/ICON-0072-prompt-injection-defenses/

## Decisions
- Local task ID ICON-0072 (next free after ICON-0071); GitLab issue #39 referenced for traceability — issue numbers are not Jira IDs (task-ID-source rule).
- Placement = Option 2 TARGETED (@architect): edit `researcher` (only direct fetcher) + `manager` (orchestrator that ingests findings & routes write tools) directly; NOT shared/common-constraints. Rationale: common-constraints is already ADR-008 over-cap (421w ×9 = 54% of PM budget); a universal line ×9 trips the PM ≥350w re-audit trigger for marginal gain. product-manager covered via @researcher delegation; mr-feedback-triage already forbids MR write calls.
- ADR-008 deltas: researcher +~95w (NOT in always-loaded inventory → no trigger); manager +~70w (under 425w per-MR trigger → no re-inventory). common-constraints unchanged. Note manager delta in MR body.
- Security doc = NEW `.context/standards/security.md` (governing rule, not domain knowledge); sibling issues #40/#42/#43 append `## <Topic>` sections. Register in rules-index.md.

## Key Files
- agents/researcher.agent.md: CHANGED — added `## Untrusted Content` section (only direct web fetcher).
- agents/manager.agent.md: CHANGED — added "Untrusted external content" paragraph to Session Start Step 7 (orchestrator that ingests findings).
- .context/standards/security.md: CREATED — canonical security standards doc; "Untrusted External Content (Prompt-Injection Mitigation)" section; shaped for siblings #40/#42/#43 to append.
- .context/rules-index.md: CHANGED — registered the new `security` standard row.
- CHANGELOG.md: CHANGED — Unreleased ### Added entry.
- shared/common-constraints.md: deliberately UNTOUCHED (ADR-008 over-cap).

## Progress
- [x] Create branch + task folder + initial plan.md
- [x] Read-only Explore — findings: 9 agents all carry byte-synced common-constraints (md5 identical, synced by .githooks/pre-commit between BEGIN/END markers); researcher = only DIRECT web fetcher; manager/product-manager fetch indirectly via @researcher; mr-feedback-triage skill reads attacker-controllable MR comments; mcp-tools-first governs all Jira/Confluence/GitLab reads; NO security doc exists; context_template/ has NO common-constraints copy (no template-version bump needed); no existing "untrusted/injection" wording to match.
- [x] @architect exact-edit-spec — Option 2 targeted; spec delivered (4 files: researcher, manager, new standards/security.md, rules-index.md)
- [x] @coder applies edits — 4 files (researcher, manager Step 7, new standards/security.md, rules-index.md); all grep ACs pass; common-constraints untouched (grep 0); context_template/ clean
- [x] @reviewer checkpoint — APPROVED with comments (0 Critical/Moderate). Placement confirmed outside common-constraints block (byte-identical to main); cross-refs resolve; scope = 4 files; ADR-008 agreed (no re-inventory). One Minor applied: security.md provenance reworded "Q3 security review" → "ICON AI RFC security review (question 3; GitLab #39)". Nit (GitHub/GitLab wording asymmetry) left as-is — researcher is legitimately the broader fetcher.
- [x] changelog-entry — added ### Added Unreleased entry (consumer-shipped agents changed)
- [x] Reconcile plan.md against final state
- [x] Retrospective (two-stage) — entry inserted (ICON-0062 pruned); "referenced-artifact existence check" corollary promoted to task-start-conventions.md
- [x] Commit (64ccc8f; pre-commit hook green) + push + open MR !56
- [ ] PAUSE — awaiting user go-ahead to merge → push → wait pipeline → delete branch → next item (#40)

## Review Checkpoint
@reviewer approved the full diff (researcher + manager agent edits, new standards/security.md, rules-index.md row). Covers the complete changed-file set; the only post-checkpoint edit was the reviewer-requested provenance wording fix in security.md — no new @coder/@tester work after this stamp.

## Open Questions / Blockers
- RESOLVED: No security doc existed → created `.context/standards/security.md` as canonical home (Explore confirmed).
- RESOLVED: Placement → targeted (manager+researcher), not universal common-constraints (@architect, ADR-008 economics).

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- common-constraints.md edits must go through the shared source; the pre-commit hook byte-syncs it into every agents/*.agent.md.
- If any file under context_template/ changes, bump context_template/context/iconrc.json template-version (ICON-0044 gate).
