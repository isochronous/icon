# Audit — Phase 1: Structure Validation

## Overview

Verify the plugin's file/folder layout and frontmatter are well-formed. These findings block marketplace listing — a plugin that fails structural validation will not load cleanly in Claude Code.

## Checks

For each check, report a pass/fail line with a path if applicable.

1. **`plugin.json` parses as valid JSON** — required.
2. **`plugin.json` declares `$schema`** — recommended; ideally `https://json.schemastore.org/claude-code-plugin-manifest.json` for IDE validation.
3. **`plugin.json` declares `name`, `version`, `description`** — required.
4. **Standard directories exist** — `agents/`, `skills/`, `commands/`, `hooks/`, `shared/`. Not all are mandatory (a skill-only plugin may omit `agents/`), but report each present/absent for a sanity-check.
5. **Every `agents/*.agent.md` has a frontmatter block** declaring at least `name` and `description`. The script below verifies the block is present and that both keys are non-empty. It does **not** verify that the block is valid YAML — see the fidelity limit under *Frontmatter parse*.
6. **Every `skills/*/SKILL.md` has a frontmatter block** declaring at least `name` and `description`. Same scope and same limit as check 5.
7. **`CHANGELOG.md` exists** and contains an `## [Unreleased]` block.

## Validation Snippets

Each check below invokes a committed script from this skill's own `scripts/` directory. What the
script decides, which signals it keys on, and what every outcome means stay here; only the mechanics
of *how* the answer is computed live in the file. Every script reads paths relative to the current
directory, so run them from the root of the plugin being audited.

**Precondition — confirm Node is present before running any block in this file.** Run `node -v` and
read its **output**, not its exit status. If Node is absent, do not run the blocks — invoke
`check-node-runtime`, which reports what stops working and offers a per-platform install.

**Silence is never a pass here.** Each script prints a verdict on stdout on every branch that
reaches one, so empty stdout means **no verdict was produced** — the script did not run, or it
crashed before printing. stderr distinguishes the two; both are *not clean*, and neither may be
reported as a pass. Node being present does not establish that a block ran: an unresolved script
path exits 1 with `Cannot find module` and no stdout at all, which is exactly the shape a clean
audit used to have. Where a script reports findings, stdout carries either `OK` or the finding
lines, never both.

**Shell.** The invocation is `node "<absolute path>"`, which carries no quote *inside* an argument
value and so is not exposed to the Windows PowerShell 5.1 defect that broke the inline `node -e`
form these blocks replaced (`shell-portability` Rule 11). Measured for all three blocks in this
file, on bash 5.3.9, PowerShell 7.6.3 and Windows PowerShell 5.1.26100.8875 with Node v24.18.0:
identical stdout and the same exit status on all three hosts, against a positive control in which
the old inline form still fails on 5.1 with its quotes visibly stripped. Not measured under `cmd`.

### plugin.json required fields

Check 3. Reads `.claude-plugin/plugin.json` and reports whether `name`, `version` and `description`
are all present as keys. **Presence is the whole test** — an empty string counts as declared, and
judging the content is Phase 2's description-quality check, not this one.

| stdout | exit | Meaning |
|---|---|---|
| `OK` | 0 | All three keys are present. |
| `MISSING <keys>` | 1 | The named keys are absent, comma-separated in the order `name, version, description`. |
| *(nothing)* | non-zero | No verdict was reached: the manifest is absent, unreadable, or not valid JSON, and the trace is on stderr. Fix the tree and re-run. **Never read this as a pass.** |

The `MISSING` verdict goes to **stdout**, not stderr as the inline form emitted it. Once `OK` prints
on the passing branch, leaving the failure on stderr would put empty stdout back to meaning either
"fields are missing" or "never ran" — the ambiguity the token exists to remove.

#### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/check-manifest-fields.mjs"
```

#### Copilot CLI (Bash)

```bash
# Resolve this skill's install directory. Set MARKETPLACE_NAME=<slug> to pin one marketplace;
# otherwise every installed marketplace is searched and an ambiguous result fails closed.
ROOT="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins"
S="plugin-design"; P="scripts/check-manifest-fields.mjs"
if [ -n "${MARKETPLACE_NAME+x}" ]; then G="$MARKETPLACE_NAME"; else G="*"; fi
F=""; N=0
for f in "$ROOT"/$G/ICON/skills/"$S/$P" "$ROOT"/$G/ICON/*/skills/"$S/$P"; do
  [ -f "$f" ] || continue; F="$f"; N=$((N+1))
done
[ "$N" = 1 ] || { echo "ICON: $N matches for $S/$P under $ROOT (marketplace ${MARKETPLACE_NAME-<any>}) — set MARKETPLACE_NAME; see: copilot plugin list" >&2; exit 1; }
node "$F"
```

### Frontmatter parse

Checks 5 and 6. Walks every `agents/*.agent.md` and `skills/*/SKILL.md` and reports each file with
no frontmatter block, or whose `name` or `description` is missing or empty. A missing `agents/` or
`skills/` directory contributes no files rather than erroring — check 4 above already allows a
skill-only plugin — and so does one that exists but is a regular file rather than a directory.

| stdout | exit | Meaning |
|---|---|---|
| `OK` | 0 | Every file it scanned has a frontmatter block and both keys are non-empty. **Not** that the YAML is valid — read the fidelity limit below before treating this as more than that. |
| one `<path>: <finding>` line per finding | 1 | Either `missing frontmatter` or `missing or empty "<key>"`. One line per key, so a file can produce two. |
| *(nothing)* | non-zero | No verdict was reached; the trace is on stderr. **Never read this as a pass.** |

**Fidelity limit — read this before treating `OK` as YAML validation.** Node ships no YAML parser
and ICON forbids third-party imports (ADR-005), so the script parses a deliberate subset: top-level
`key: value`, and `>` / `>-` / `|` / `|-` block scalars. Block-scalar folding is shared with the
Phase 2 description-quality check, which uses the same parser
(`audit-phase-consistency.md § Frontmatter description quality`), and it is load-bearing here too —
in a narrower case than Phase 2's. Where a block scalar *has* content, folding changes nothing this
check can see: the test is only non-emptiness, and an unfolded `>` is itself a non-empty string, so
a folding-skipped parser produces byte-identical output over this repo. The case that matters is an
**empty** block scalar. `description: >` with nothing indented under it folds to the empty string
and is reported; a folding-skipped parser stores the literal `">"`, finds it non-empty, and says
nothing. That is a false pass, so the folding stays. Mutation-verified on a two-key `name: x` /
`description: >` fixture: this script printed `missing or empty "description"` and exited 1, while
the folding-skipped mutant printed `OK` and exited 0.

Two findings the previous Python version emitted are **not reproduced**, because a subset parser
cannot produce them honestly. They are not equivalent, and the difference matters:

- **`YAML parse error`** — malformed YAML is not detected at all; a broken block is read for
  whatever `key:` lines it still exposes. **This one can become a false pass.** A file whose
  frontmatter is unparseable YAML but still exposes non-empty `name:` and `description:` lines
  produces no finding, and if it is the only defect present the run prints `OK` and exits 0.
  **Under the inline form that false pass was silence; now the script asserts it.** That is the same
  defect stated more loudly, not a new one, and it is the reason `OK` must be read as "the subset
  parser found nothing", never as "the frontmatter parses". Measured against the Python original
  over two such files (an unterminated double-quoted scalar, and a tab-indented line): the original
  reported `YAML parse error` for both and exited 1; this script printed `OK` and exited 0.
- **`frontmatter is not a mapping`** — a scalar or sequence frontmatter block **does** still produce
  findings, under a less precise name: it surfaces as missing `name` *and* missing `description`
  rather than as a type error. Measured on a sequence-valued block: the original emitted one
  `frontmatter is not a mapping`, this script emitted those two lines, and both exited 1. No false
  pass here.

So `OK` is **not** YAML validation. The retired PowerShell variant detected YAML errors no better —
it matched `name:` / `description:` by regex — so this is not a loss relative to what Windows
already had. It is still a real gap: a plugin that needs YAML validation should run `yq` or a YAML
linter separately, and a CI gate must not treat exit 0 from this block as proof the frontmatter
parses.

Three **cosmetic** divergences from the Python original are also deliberate. They affect only how a
finding is worded, never whether it fires. Two of them were originally *forced*: the program was
delivered as a single-quoted shell word and could hold no apostrophe. **A committed `.mjs` removes
that constraint**, so the wording is now retained by choice rather than by necessity — re-diverging
shipped message text is a behaviour change, and a mechanism conversion is the wrong place for one.
The third is the ASCII-only rule, so the text survives every ASCII-compatible console codepage, and that cause still
holds.

| Python original | These scripts | Where | Cause |
|---|---|---|---|
| `missing or empty 'name'` | `missing or empty "name"` | this block | originally the no-apostrophe rule; now retained by choice |
| `repr(desc)` → `'TODO'` | `JSON.stringify(desc)` → `"TODO"` | Phase 2 description quality | same |
| `aim for ≥ 20` | `aim for >= 20` | Phase 2 description quality | ASCII only — still binding |

The script is also **stricter about where frontmatter starts**: the file must open with a `---` line,
and the block ends at the next line that is exactly `---`. The Python version split on the first two
`---` sequences anywhere in the text, so a file with no frontmatter but a `---` horizontal rule in
its body was read as having one. Anchoring to line starts is the intended meaning. Measured on such
a file: the original reported `frontmatter is not a mapping`, this script reports
`missing frontmatter`, and both exit 1.

#### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/check-frontmatter.mjs"
```

#### Copilot CLI (Bash)

```bash
# Resolve this skill's install directory. Set MARKETPLACE_NAME=<slug> to pin one marketplace;
# otherwise every installed marketplace is searched and an ambiguous result fails closed.
ROOT="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins"
S="plugin-design"; P="scripts/check-frontmatter.mjs"
if [ -n "${MARKETPLACE_NAME+x}" ]; then G="$MARKETPLACE_NAME"; else G="*"; fi
F=""; N=0
for f in "$ROOT"/$G/ICON/skills/"$S/$P" "$ROOT"/$G/ICON/*/skills/"$S/$P"; do
  [ -f "$f" ] || continue; F="$f"; N=$((N+1))
done
[ "$N" = 1 ] || { echo "ICON: $N matches for $S/$P under $ROOT (marketplace ${MARKETPLACE_NAME-<any>}) — set MARKETPLACE_NAME; see: copilot plugin list" >&2; exit 1; }
node "$F"
```

### CHANGELOG `[Unreleased]` block

Check 7. Read stdout **and** the exit code together; the last row is the one with no verdict in it
at all, so exit alone would misreport it as an ordinary failure:

| stdout | exit | Meaning |
|---|---|---|
| `OK` | 0 | `CHANGELOG.md` exists and carries an `## [Unreleased]` heading. |
| `MISSING [Unreleased]` | 1 | The file exists but has no `## [Unreleased]` heading. |
| `MISSING CHANGELOG.md` | 1 | There is no `CHANGELOG.md` at all. |
| *(nothing)* | non-zero | The script reached no verdict — a `CHANGELOG.md` that is a *directory* throws `EISDIR` out of the read, with the trace on stderr. Fix the tree and re-run. |

The `MISSING CHANGELOG.md` outcome is not in the original. Check 7 is two conditions — the file
exists *and* it carries the block — and the previous `grep -q` form collapsed them, reporting
`MISSING [Unreleased]` for a plugin with no changelog whatsoever.

#### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/check-changelog.mjs"
```

#### Copilot CLI (Bash)

```bash
# Resolve this skill's install directory. Set MARKETPLACE_NAME=<slug> to pin one marketplace;
# otherwise every installed marketplace is searched and an ambiguous result fails closed.
ROOT="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins"
S="plugin-design"; P="scripts/check-changelog.mjs"
if [ -n "${MARKETPLACE_NAME+x}" ]; then G="$MARKETPLACE_NAME"; else G="*"; fi
F=""; N=0
for f in "$ROOT"/$G/ICON/skills/"$S/$P" "$ROOT"/$G/ICON/*/skills/"$S/$P"; do
  [ -f "$f" ] || continue; F="$f"; N=$((N+1))
done
[ "$N" = 1 ] || { echo "ICON: $N matches for $S/$P under $ROOT (marketplace ${MARKETPLACE_NAME-<any>}) — set MARKETPLACE_NAME; see: copilot plugin list" >&2; exit 1; }
node "$F"
```
