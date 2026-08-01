# Audit — Phase 2: Internal Consistency

## Overview

Cross-file checks that detect drift between what a file claims and what other files contain. Structure can be valid (Phase 1) yet internally inconsistent — a skill referencing `/foo` when no `skills/foo/SKILL.md` exists, a placeholder description, or two agents whose responsibilities overlap.

## Checks

1. **Skill references resolve** — any `/foo` invocation in `agents/*.agent.md` or `skills/*/SKILL.md` body text must correspond to an existing `skills/foo/SKILL.md` (or a built-in slash command, which the auditor should distinguish if known).
2. **File-path references resolve** — any `.context/<subdir>/<file>.<ext>` reference in shipped surfaces (agents, skills, shared, commands) must resolve under the plugin's `.context/`. (For the ICON self-audit case where `.context/` content lives under `context_template/context/`, prefer that location when present.) This generalizes the dead-ref pattern from ICON's own pre-commit hook.
3. **Frontmatter `description` is non-boilerplate** — heuristic: must not be empty, must not equal the skill/agent name, must not be the literal `TODO` or `<description>`, must exceed 20 characters.
4. **Agent/skill role-overlap heuristic** — if two agents have first-sentence descriptions with overlapping responsibilities (similar verb + object), surface it as a concern. Heuristic only; flag for review, do not auto-fail.

## Validation Snippets

Checks 1–3 each invoke a committed script from this skill's own `scripts/` directory. What each
script decides, which signals it keys on, and what every outcome means stay here; only the mechanics
of *how* the answer is computed live in the file. Every script reads paths relative to the current
directory, so run them from the root of the plugin being audited.

**Precondition — confirm Node is present before running any block in this file.** Run `node -v` and
read its **output**, not its exit status. If Node is absent, do not run the blocks — invoke
`check-node-runtime`, which reports what stops working and offers a per-platform install.

**Silence is never a pass here, and in this file that is load-bearing.** All three scripts exit 0
whether or not they found anything, so **the exit code carries no verdict at all** — stdout is the
only channel that does. Each prints `OK` when it has no findings, so empty stdout means **no verdict
was produced**: the script did not run, or it crashed before printing. stderr distinguishes the two;
both are *not clean*, and neither may be reported as a pass. Node being present does not establish
that a block ran — an unresolved script path exits 1 with `Cannot find module` and no stdout.

**Shell.** The invocation is `node "<absolute path>"`, which carries no quote *inside* an argument
value and so is not exposed to the Windows PowerShell 5.1 defect that broke the inline `node -e`
form these blocks replaced (`shell-portability` Rule 11). Measured for all three blocks in this
file, on bash 5.3.9, PowerShell 7.6.3 and Windows PowerShell 5.1.26100.8875 with Node v24.18.0:
identical stdout and the same exit status on all three hosts, against a positive control in which
the old inline form still fails on 5.1 with its quotes visibly stripped. Not measured under `cmd`.

### Skill-reference resolution

Check 1. Scans `agents/*.agent.md` and `skills/*/SKILL.md` body text for `/name` tokens and reports
each one with no matching `skills/name/SKILL.md`. **This check reports, it does not gate** — the
built-in slash commands named in check 1 are indistinguishable from a dead reference here, and the
auditor is the one who tells them apart. Each finding is a *candidate*, not a verdict.

A `/name` token counts as an invocation only when it is preceded by start-of-line, whitespace or a
backtick and followed by whitespace, end-of-line, a backtick or common punctuation; a match whose
surrounding 20 characters contain a URL scheme, a `/usr/`-style absolute path, `.context/`,
`context_template/` or `github.com/` is skipped as a path rather than an invocation.

| stdout | exit | Meaning |
|---|---|---|
| `OK` | 0 | Every `/name` token in the scanned files has a matching `skills/name/SKILL.md`. |
| one `<path>: references /<name> but skills/<name>/SKILL.md not found` line per candidate | 0 | Each is a candidate for check 1 to adjudicate. **The exit code is 0 either way** — it is not the verdict. |
| *(nothing)* | any | No verdict was produced: the script did not run, or it crashed before printing. stderr distinguishes them. **Never read this as a pass.** |

The exit-0 promise depends on the target list holding only readable regular files, which is what the
`isFile` filter is for — without it, a *directory* named `something.agent.md` reaches the read and
the script dies on `EISDIR` with no findings at all. Anything that cannot be stat-ed as a file is
skipped rather than thrown.

#### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/check-skill-refs.mjs"
```

#### Copilot CLI (Bash)

```bash
# Resolve this skill's install directory. Set MARKETPLACE_NAME=<slug> to pin one marketplace;
# otherwise every installed marketplace is searched and an ambiguous result fails closed.
ROOT="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins"
S="plugin-design"; P="scripts/check-skill-refs.mjs"
if [ -n "${MARKETPLACE_NAME+x}" ]; then G="$MARKETPLACE_NAME"; else G="*"; fi
F=""; N=0
for f in "$ROOT"/$G/ICON/skills/"$S/$P" "$ROOT"/$G/ICON/*/skills/"$S/$P"; do
  [ -f "$f" ] || continue; F="$f"; N=$((N+1))
done
[ "$N" = 1 ] || { echo "ICON: $N matches for $S/$P under $ROOT (marketplace ${MARKETPLACE_NAME-<any>}) — set MARKETPLACE_NAME; see: copilot plugin list" >&2; exit 1; }
node "$F"
```

### File-path resolution (dead-ref)

Check 2. Recursively scans `agents/`, `skills/`, `shared/` and `commands/` for
`.context/<path>.<ext>` tokens and reports each one resolving under neither
`context_template/context/` nor `.context/`. Absent directories are skipped, as is one that exists
but is a regular file.

| stdout | exit | Meaning |
|---|---|---|
| `OK` | 0 | Every reference in every file it *scanned* resolves — see **Links** below for what it declines to scan. |
| one `<file>: dead ref <token>` line per finding | 0 | **The exit code is 0 either way** — it carries no verdict of its own. Read stdout. |
| *(nothing)* | any | No verdict was produced: the script did not run, or it crashed before printing. **Never read this as a pass** — a silent false-clean is the worst failure available to a dead-reference check. |

Scanned suffixes are `.md`, `.sh`, `.ps1`, `.js` **and `.mjs`**. `.mjs` is deliberate: `*.js` does
not glob-match `.mjs`, and the pre-commit gate this check generalizes was extended to `.mjs` under
ADR-017, so omitting it would leave this skill's own migrated scripts unscanned. Verified against a
fixture whose only dead reference lives in a `.mjs`: this script reports it, and the same script
with `.mjs` removed from the suffix list reports `OK`.

**Links.** Every entry is resolved with `statSync`, which follows links, so a directory reached
through a symlink or a Windows junction is descended into and its files are scanned. That is what
makes this script agree with the other three audit scripts — Phase 1 frontmatter, and the
skill-reference and description-quality scripts here — which resolve links the same way. Measured
on a fixture whose only dead reference sits behind a junction: this script reports it, while a
`Dirent`-based walk prints `OK` and exits 0 — a silent false-clean.

It diverges from `pathlib.rglob` in both directions, deliberately. `rglob` descends a junction
(`os.path.islink` is False for one) but stops at a true symlink; this script descends both, so it
reaches more of the tree. `rglob` also yields the symlinked directory itself, and the Python original
then died on `read_text()` (`PermissionError` on Windows, `IsADirectoryError` on POSIX), losing every
finding in the run; here a directory never reaches the read branch.

`realpathSync` and a visited set bound the walk. Without them a junction pointing at its own ancestor
is re-entered until the operating system refuses to resolve another link. Measured on a fixture whose
`agents/` holds `a.md` plus a real `sub/` holding `b.md`, with `sub/loop` junctioned back onto
`agents/`: this script reports those 2 files and exits 0, while the same script with the visited set
deleted reports the same 2 files many times over, one respelling per lap, and also exits 0. The
ceiling is the link-resolution limit rather than the path length — `statSync` raises `ELOOP` and
`isDir` then reports not-a-directory, so the walk stops there.

The set dedupes *directories*, not files: it is consulted only inside the walk, and the branch that
pushes a file never touches it. So a directory reachable by several links is walked once and its
files reported under the first path to reach it — measured on two sibling junctions onto one target,
where the shared directory's file was reported once, under the first spelling, and **both scanned
roots' own files were still reported.** A file carrying two names of its own is still reported under
each: one inode spelled `real.md`, `hard.md` and `alias.md` in a single `agents/` produced 3
findings, one per spelling, while a mutant deduping by inode produced 1. That over-reporting is the
safe direction for a dead-reference check, which would otherwise be hiding a path a reader can
follow. What the set costs is path spellings, not coverage. An entry `statSync` cannot resolve — a
broken link, or a link loop (`ELOOP`) — is skipped like any other unreadable entry.

#### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/check-dead-refs.mjs"
```

#### Copilot CLI (Bash)

```bash
# Resolve this skill's install directory. Set MARKETPLACE_NAME=<slug> to pin one marketplace;
# otherwise every installed marketplace is searched and an ambiguous result fails closed.
ROOT="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins"
S="plugin-design"; P="scripts/check-dead-refs.mjs"
if [ -n "${MARKETPLACE_NAME+x}" ]; then G="$MARKETPLACE_NAME"; else G="*"; fi
F=""; N=0
for f in "$ROOT"/$G/ICON/skills/"$S/$P" "$ROOT"/$G/ICON/*/skills/"$S/$P"; do
  [ -f "$f" ] || continue; F="$f"; N=$((N+1))
done
[ "$N" = 1 ] || { echo "ICON: $N matches for $S/$P under $ROOT (marketplace ${MARKETPLACE_NAME-<any>}) — set MARKETPLACE_NAME; see: copilot plugin list" >&2; exit 1; }
node "$F"
```

### Frontmatter description quality

Check 3. Reports **at most one finding per file**, in the precedence order of check 3 above — empty,
then equals-name, then placeholder, then too-short. Precedence matters: an empty description is
reported as empty, not also as too short. Files with no frontmatter block are skipped silently;
Phase 1 already reports those.

| stdout | exit | Meaning |
|---|---|---|
| `OK` | 0 | No description tripped any of the four heuristics. |
| one line per file, one of `empty description` / `description equals name (boilerplate)` / `placeholder description (…)` / `description too short (N chars; aim for >= 20)` | 0 | **The exit code is 0 either way** — it carries no verdict. Read stdout. |
| *(nothing)* | any | No verdict was produced: the script did not run, or it crashed before printing. stderr distinguishes them. **Never read this as a pass.** |

Length is counted in **code points**, not UTF-16 units, matching Python's `len()` over a `str`.
Measured on a 19-emoji description — 19 code points, 38 UTF-16 units: this script reports
`too short (19 chars)`, while a `.length` mutant reports `OK`.

Same **YAML fidelity limit** as Phase 1 — a dependency-free subset parser, no syntax-error
detection, and the same three cosmetic message divergences (two of which are this script's); see
`audit-phase-structure.md § Frontmatter parse`.

One divergence is specific to this check and is an improvement. A frontmatter block that is a scalar
or a sequence rather than a mapping **crashed the Python original**: its `yaml.safe_load(...) or {}`
guard replaces `None` but not a non-dict, so the next `.get()` raised `AttributeError` and killed
the run before any finding printed. Here such a block yields no keys, so the file is reported
`empty description` and the scan continues.

**Block-scalar folding is load-bearing here, and most visibly here.** Descriptions are almost always
written as `description: >` with the text on the following lines, so a parser that skipped folding
would store the literal `">"` — one character. This check measures length, so files written that way
land on `description too short (1 chars)`. Note the finding is *too short*, not *empty*: `">"` is
non-empty, which is why Phase 1, whose test is only non-emptiness, is unaffected by *this* case.
Phase 1 has its own, narrower dependency on the folding — an **empty** block scalar, where dropping
it converts a real finding into a false pass — recorded there. Mutation-verified: replacing the
parser with a folding-skipped one turns this check's `OK` against this repo into **59 false
`description too short (1 chars)` findings**, while Phase 1's output over the same repo does not
change by a single byte.

#### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/check-description-quality.mjs"
```

#### Copilot CLI (Bash)

```bash
# Resolve this skill's install directory. Set MARKETPLACE_NAME=<slug> to pin one marketplace;
# otherwise every installed marketplace is searched and an ambiguous result fails closed.
ROOT="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins"
S="plugin-design"; P="scripts/check-description-quality.mjs"
if [ -n "${MARKETPLACE_NAME+x}" ]; then G="$MARKETPLACE_NAME"; else G="*"; fi
F=""; N=0
for f in "$ROOT"/$G/ICON/skills/"$S/$P" "$ROOT"/$G/ICON/*/skills/"$S/$P"; do
  [ -f "$f" ] || continue; F="$f"; N=$((N+1))
done
[ "$N" = 1 ] || { echo "ICON: $N matches for $S/$P under $ROOT (marketplace ${MARKETPLACE_NAME-<any>}) — set MARKETPLACE_NAME; see: copilot plugin list" >&2; exit 1; }
node "$F"
```

### Role-overlap heuristic

A judgment call, not a deterministic check. List every agent's `name` + first-sentence verb phrase, then surface pairs whose verb + object look similar (e.g. two agents that both "review code" or "manage tasks"):

- `coder` "implements features" vs `developer` "implements changes" → flag.
- `tester` "writes tests" vs `qa` "creates tests" → flag.
- `manager` "orchestrates workflows" vs `coordinator` "orchestrates work" → flag.

Report the pair, the overlapping phrase, and the recommended action: consult `agent-evaluation` for a deeper single-agent design review.

## Cross-references

When role overlap is detected, invoke `agent-evaluation` against the involved agents for a dedicated single-agent review.
