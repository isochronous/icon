## Task: ICON-0036
## Branch: feature/ICON-0036-phase-skill-polish
## Objective: Apply phase-skill polish bundle from GitLab issue #21 — align "Does NOT cover" footer terminology across the five phase skills (O-S7 + m-P-2), reduce the retrospective rolling-log cap from 15 to 10 (m-P-3), and prepend the skill-name prefix to verification-checklist Gate headings (m-P-6). Origin: ICON-0015 audit carry-forwards.
## Folder: .context/tasks/ICON-0036-phase-skill-polish/

## Decisions
- **m-P-1 dropped as working-as-designed**: Phase skills are deliberately non-auto-invocable (`user-invocable: false`, identical generic descriptions); differentiating their descriptions would defeat the design. User confirmed in GitLab comment 2026-05-22. Issue #21 acceptance criterion for m-P-1 (`grep -A1 '^name: task-plan-phase' … shows unique descriptions`) is revised in the close-out comment.
- **m-P-3 cap = 10, not 15**: User chose to reduce the retrospective rolling-log cap (rationale: retro entries have grown long). The cap value lives in three classes of locations: (1) the canonical SSOT — `ENTRY_CAP` constant in `append-retrospective-entry.sh`; (2) prose in two SKILL.md files; (3) META-class documentation (`.context/META.md`, `context_template/context/META.md`, `context_template/README.md`, `context_template/UPDATE_LOG.md`). All non-canonical references now cite `ENTRY_CAP` by name so future cap changes only require touching the script.
- **m-P-3 scope expanded mid-task**: Reviewer found three Critical META-class drift sites that were not in the issue body; my own follow-up sweep found a fourth (`context_template/UPDATE_LOG.md`). Lesson: the "two prose locations" framing in the issue was too narrow — the acceptance grep needs to be repo-wide, not file-scoped, to catch all references to a cap value before declaring SSOT alignment. Recorded for retrospective.
- **Footer fix: Option B (terminology standardization)**: Per issue #21 author recommendation. Lower risk than Option A (remove footers + expand Relationship intro); preserves the footer-as-quick-reference shape. All five footers now use the consistent noun forms "implementation phase", "testing phase", and "architecture review".
- **Prefix convention**: `verification-checklist:` prefix per MKT-0083 — matches phase-skill heading style already in use elsewhere in the repo.

## Key Files
- `skills/task-plan-phase-investigation/SKILL.md:128` — "Does NOT cover" footer terminology aligned.
- `skills/task-plan-phase-architecture/SKILL.md:78` — "Does NOT cover" footer terminology aligned.
- `skills/task-plan-phase-implementation/SKILL.md:85` — "Does NOT cover" footer terminology aligned.
- `skills/task-plan-phase-testing/SKILL.md:94` — "Does NOT cover" footer terminology aligned (incl. `architecture` → `architecture review` per review).
- `skills/task-plan-phase-completion/SKILL.md:77,100` — rolling-log prose now "most recent 10 entries — enforced by the append script's `ENTRY_CAP`"; footer terminology aligned.
- `skills/task-retrospective/SKILL.md:93,125` — rolling-log prose now references `ENTRY_CAP` by name.
- `skills/task-retrospective/scripts/append-retrospective-entry.sh:39` — `ENTRY_CAP=10` (canonical SSOT); comment at `:24` updated to match.
- `skills/verification-checklist/SKILL.md:46,49,55,62` — Gate headings prefixed with `verification-checklist:`.
- `.context/META.md:55,70` — rolling-log cap text updated; cites `ENTRY_CAP`.
- `context_template/context/META.md:53,68` — same META text for downstream consumer template.
- `context_template/README.md:31` — tree-comment cap updated.
- `context_template/UPDATE_LOG.md:32` — template UPDATE_LOG cap updated.

## Progress
- [x] Read GitLab issue #21 and user clarification comment — m-P-1 dropped, m-P-3 cap → 10.
- [x] Create task branch and folder; draft plan.md.
- [x] Delegate implementation to @coder — round 1 (8 files): five phase-skill footers, two SKILL.md prose locations, append script ENTRY_CAP, verification-checklist Gate prefixes.
- [x] @reviewer pass — Critical findings: META.md drift in 3 locations; Moderate: nested-paren prose + bare `architecture` in testing footer.
- [x] @coder round 2 — fix META.md drift (`.context/META.md` ×2, `context_template/context/META.md` ×2, `context_template/README.md` ×1), nested-paren prose flattened, `architecture` → `architecture review`.
- [x] Manager sweep — caught one more residue in `context_template/UPDATE_LOG.md:32`; @coder round 3 fixed it.
- [x] Final acceptance grep `grep -rnE "10[-–]15" .context/ context_template/ skills/` → 0 hits outside historical audit artifacts and unrelated `plugin-audit/SKILL.md:18` (about audit cadence, not retro cap).
- [x] Reconcile plan.md against final state.
- [ ] Add CHANGELOG `[Unreleased]` entry (via `changelog-entry` skill) ← IN PROGRESS
- [ ] Update GitLab issue #21: close-out comment with revised acceptance criteria for m-P-1 (WAD) and m-P-3 (cap=10).
- [ ] Run retrospective (manager Stage 1 + @context-specialist Stage 2).
- [ ] Commit all task artifacts and close.

## Open Questions / Blockers
- None.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003.
- Script and prose must stay aligned: `ENTRY_CAP` in `append-retrospective-entry.sh` is canonical; prose statements must reference it (not duplicate the number in a way that creates a second source of truth).
- Final acceptance: `grep -rnE "10[-–]15" .context/ context_template/ skills/` returns hits only in historical audit artifacts (`.context/tasks/ICON-0003-plugin-audit/`, `.context/tasks/ICON-0015-plugin-audit/`), this task's own plan.md (historical record), and `skills/plugin-audit/SKILL.md:18` (unrelated — audit cadence, not retro cap).
- Final acceptance: `grep -nE "^### Gate [0-9]+:" skills/verification-checklist/SKILL.md` returns 0 hits.
