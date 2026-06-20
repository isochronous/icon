# ICON-0007: context-specialist mode:upgrade routing

**Status**: ready for review
**Branch**: `feature/ICON-0007-context-specialist-mode-upgrade`
**GitLab issue**: [#4 (M-I1)](https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/work_items/4)
**Source audit finding**: ICON-0003 audit-report, M-I1 (carry-forward from MKT-0087 M1)

## Objective

Eliminate the dead-code path where `@context-specialist mode: upgrade` was being routed to `context-specialist-create` (a fresh-init impl skill with no upgrade branch). Per user decision (Option A), route `mode: upgrade` directly from the agent body to `upgrade-repo` — and sweep all the other places in the agent file (and adjacent files) that still claimed the old routing.

## Approach

### `agents/context-specialist.agent.md` — five edits

1. **Role intro (`:21-22`)**: changed from "for creation and upgrade work you load `context-specialist-create`" to three distinct skill targets — `context-specialist-create` (creation), `upgrade-repo` (upgrades), `context-maintenance` (maintenance and audits).
2. **Mode table (`:46`)**: row now names routing target inline (`via context-specialist-create`, `via the upgrade-repo skill`).
3. **Scope guard (`:32`)**: tree-position detection guard now applies only to `create` mode (since `upgrade-repo` doesn't need tree-position detection).
4. **Dispatch routing (`:55-77`)**: inserted explicit `mode == upgrade` branch BEFORE the "Otherwise" branch; narrowed "Otherwise" to `create or absent` only. New branch explicitly warns "Do not load `context-specialist-create`" to prevent the dead-code reentry.
5. **Hardcoded constraint (`:89-90`)**: rewritten to enumerate all four modes correctly. Old wording: `maintenance` → `context-maintenance`; `create/upgrade/absent` → `context-specialist-create`. New wording: `maintenance/audit` → `context-maintenance`; `upgrade` → `upgrade-repo`; `create/absent` → `context-specialist-create`. Also fixes the pre-existing `audit` mode omission.
6. **Discretionary tier (`:100-102`)**: removed the "Upgrade an existing .context/" bullet (upgrade is now a primary route, not a discretionary side-capability). Section now reads "*None — all behavior is mode-driven and described in the mode table above.*"

### `skills/context-specialist-create/SKILL.md` — one edit

Description prose at `:10-11` no longer claims to handle `mode: upgrade`. Now: "Initialize a `.context/` directory... loaded inline by `@context-specialist` when `mode` is `create` or absent (default)."

### `skills/manager-routing-guide/SKILL.md` — one edit

Routing-table row for `@context-specialist` at `:79`: was bundling `create`/`upgrade` as a single responsibility. Now enumerates all four modes with routing targets named: creation (`mode: create`), upgrades (`mode: upgrade` via `upgrade-repo`), maintenance updates (`mode: maintenance`), drift audits (`mode: audit`).

## Key files

- `agents/context-specialist.agent.md` — 6 surgical edits across role intro, mode table, scope guard, dispatch routing, Hardcoded constraint, Discretionary tier
- `skills/context-specialist-create/SKILL.md` — 1 edit (description prose)
- `skills/manager-routing-guide/SKILL.md` — 1 edit (routing-table cell)

## Verification

```bash
# Three skill targets in role intro
grep -n "for creation you load .context-specialist-create" agents/context-specialist.agent.md
grep -n "for maintenance and audits you load .context-maintenance" agents/context-specialist.agent.md

# Hardcoded constraint enumerates all four modes
grep -nE "maintenance./audit. → .context-maintenance" agents/context-specialist.agent.md
grep -nE "upgrade. → .upgrade-repo" agents/context-specialist.agent.md
grep -nE "create./absent → .context-specialist-create" agents/context-specialist.agent.md

# Old wrong wording is gone
grep -nE "create./upgrade./absent" agents/context-specialist.agent.md
# expected: 0 hits
grep -n "Upgrade an existing" agents/context-specialist.agent.md
# expected: 0 hits

# Dispatch routing has explicit upgrade branch
grep -n "mode == upgrade" agents/context-specialist.agent.md
# expected: 1 hit

# create-skill no longer claims upgrade
grep -nE "create.*upgrade.*absent|or upgrade" skills/context-specialist-create/SKILL.md
# expected: 0 hits

# manager-routing-guide row is properly enumerated
grep -nE "mode: create./upgrade." skills/manager-routing-guide/SKILL.md
# expected: 0 hits
grep -n "via .upgrade-repo" skills/manager-routing-guide/SKILL.md
# expected: 1 hit
```

## Done

- [x] @coder applied initial 3-file edit (agent dispatch + create-skill prose)
- [x] @reviewer flagged 2 Critical findings (role intro contradiction at :21-22 + Hardcoded constraint contradiction at :89-90) + 1 Moderate (manager-routing-guide:79 bundling)
- [x] @coder applied polish — all Critical + Moderate addressed in a second pass. Also caught Critical Fix 3 (Discretionary upgrade bullet) and Critical Fix 4 (Scope guard) as part of the sweep.
- [ ] Commit + push + open MR
- [ ] User review/approval
- [ ] Merge to main
- [ ] Retrospective entry

## Notes

- The reviewer's polish pass also caught a pre-existing bug: the Hardcoded constraint's old wording (`maintenance → context-maintenance; create/upgrade/absent → context-specialist-create`) omitted `audit` mode entirely, even though the dispatch block at `:62-66` already routed `audit` through `context-maintenance`. The corrected constraint enumerates all four modes — closes both M-I1 and the pre-existing audit-omission silently.
- Reviewer's Minor notes about frontmatter description and mode-table bulleting were left as-is — they're style preferences, not correctness issues. Filed separately if desired.
- The audit-issue author's recommended Option B (drop the parameter entirely) would have been simpler but would also have removed a useful degree of freedom from agent invocation. Option A is more conservative.
