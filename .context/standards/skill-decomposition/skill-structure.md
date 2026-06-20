# Skill Structure

How to refactor multi-mode skills safely, verify references before commit, justify new skills with verbatim citations, and lay out skills that bundle heavy reference content.

## Multi-Mode Skill Refactoring

When refactoring a skill that has both `initialize` and `upgrade` paths, enumerate **both paths explicitly** in the coder delegation prompt.

A coder refactoring the initialize path often misses that `initialize-monorepo`/`initialize-multimodule` also reference the same skill via their upgrade delegation prompt. If the upgrade prompt points to a new impl skill containing only initialization instructions, the upgrade contract silently breaks.

**Prevention**: Before delegating any skill refactor, grep for all references to the skill:

```bash
grep -rn "skill-name\|upgrade-repo\|initialize-repo" skills/initialize-monorepo/ skills/initialize-multimodule/
```

Explicitly call out each occurrence in the delegation prompt with its expected behavior after the refactor.

## Skill Reference Verification

Before committing any change to an agent file that adds a new skill invocation, verify the skill directory exists:

```bash
ls skills/foo-bar/SKILL.md
```

A forward reference to a non-existent skill fails silently at runtime.

**Example consequence (MKT-0026/MKT-0032)**: `reviewer.agent.md` acquired a reference to `code-quality-rules` skill that was never created on the integration branch. The reference was silently broken for months.

## Earn Your Place: Verbatim Citations

When adding a new skill (or a significant agent-mode) to the plugin, the "earn your
place" justification in `plan.md`, commit message, or planner report must include
verbatim one-liner quotes from the source retros or audit findings — not merely cite
the retro ID.

**Why**: Quoting makes the justification reviewable in-place without re-reading
retrospectives. Observed in MKT-0059 §5 and MKT-0055: when the planner quoted retro
text (e.g., "...name all three layers and their exact file locations in the delegation
prompt"), the reviewer validated the earn-your-place without running `git show` on
prior retros. Citing only the retro ID forces the reviewer to chase archaeology.

**Rule**: Cite verbatim one-liner quotes from retros or audit paragraphs — not just
IDs. Include the source location (commit SHA or current-tree line range) so the
reviewer can re-verify without archaeology.

## Sub-File Layout for Heavy-Template Skills

When a skill bundles heavy reference content — templates ≥ 100 lines total, reusable
scripts, or per-domain dispatch briefs — use a **sub-file layout** under the skill
directory rather than inlining everything in `SKILL.md`.

**Layout convention**:
- `skills/<name>/SKILL.md` — the entry point: describes phases, dispatch logic, and
  self-application. Keep to ~150 lines or fewer.
- `skills/<name>/<template-or-reference>.md` — heavy content referenced by relative
  path from `SKILL.md` (e.g., `synthesis-template.md`).
- `skills/<name>/<subdir>/<file>.md` — per-domain or per-variant content loaded only
  at dispatch time (e.g., `briefs/01-agents.md`).
- `skills/<name>/scripts/<file>.sh` — executable reference scripts.

**Why**: Observed in MKT-0060. `icon-audit` (originally `plugin-audit`, renamed +
moved to `.claude/skills/` in ICON-0042) bundles 6 per-domain dispatch briefs, a
synthesis template, and a structural-check script. Inlining all of that in a single
`SKILL.md` would produce a 500–700 line file, exceeding the size guidance in
`writing-skills/SKILL.md:140-152`. The sub-file layout
(`briefs/01-agents.md` … `briefs/06-cross-cutting.md`, `synthesis-template.md`,
`scripts/structural-check.sh`) kept `SKILL.md` to 143 substantive lines while isolating
per-domain content to files loaded only when dispatched.

**Precedents**:
- `context-maintenance/scripts/` — established the sub-script pattern with
  `append-retrospective-entry.sh`.
- `.claude/skills/icon-audit/{briefs,scripts}/` (originally `skills/plugin-audit/`,
  renamed + moved in ICON-0042) — extends this to a full template + briefs + scripts
  layout for a maintainer-only skill.

**When NOT to use**: Skills under 200 lines that require no reusable scripts or
templates should remain single-file. Sub-file layout adds navigation cost; only
introduce it when inlining would make `SKILL.md` unwieldy.

---

See [`../skill-decomposition.md`](../skill-decomposition.md) for the full skill-decomposition index.
