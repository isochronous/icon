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

> **The split trigger lives in `hot-cold-path.md` (§ The Two Gates).** A skill splits when
> `SKILL.md` exceeds **16,000 bytes** AND contains ≥ 2 condition-guarded regions of ≥ 2,000 bytes
> each. This section covers the *directory layout* a split produces; that file covers *when* to
> split, *where* the cut goes, and how companions are pointed at and named.

The trigger used to be a content **type** — "templates ≥ 100 lines, reusable scripts, or per-domain
dispatch briefs". That is why the rule never caught `upgrade-repo`: it has no templates and no
scripts, only procedure. The gate is now on bytes, so procedure counts.

**Layout convention**:
- `skills/<name>/SKILL.md` — the entry point: describes phases, dispatch logic, and
  self-application.
- `skills/<name>/<template-or-reference>.md` — heavy content referenced by relative
  path from `SKILL.md` (e.g., `synthesis-template.md`).
- `skills/<name>/<subdir>/<file>.md` — per-domain or per-variant content loaded only
  at dispatch time (e.g., `briefs/01-agents.md`).
- `skills/<name>/scripts/<file>.sh` — executable reference scripts.

**Why**: Observed in MKT-0060. `icon-audit` (originally `plugin-audit`, renamed +
moved to `.claude/skills/` in ICON-0042) bundles 6 per-domain dispatch briefs, a
synthesis template, and a structural-check script. Inlining all of that in a single
`SKILL.md` would put it well past the byte gate. The sub-file layout
(`briefs/01-agents.md` … `briefs/06-cross-cutting.md`, `synthesis-template.md`,
`scripts/structural-check.sh`) kept `SKILL.md` to 143 substantive lines while isolating
per-domain content to files loaded only when dispatched.

**Precedents**:
- `context-maintenance/scripts/` — established the sub-script pattern with
  `append-retrospective-entry.sh`.
- `.claude/skills/icon-audit/{briefs,scripts}/` (originally `skills/plugin-audit/`,
  renamed + moved in ICON-0042) — extends this to a full template + briefs + scripts
  layout for a maintainer-only skill.

**When NOT to use**: a `SKILL.md` under 16,000 bytes stays single-file. So does one over
16,000 bytes that fails gate 2 — a single unconditional narrative with no ≥ 2,000-byte
condition-guarded regions gets the finding recorded and stays whole. And never create a companion
below the **2,000-byte floor**: sub-file layout adds navigation cost, and below the floor the cost
exceeds the saving.

## Related

- Index: [skill-decomposition](../skill-decomposition.md)
- See also: [hot-cold-path](hot-cold-path.md)
