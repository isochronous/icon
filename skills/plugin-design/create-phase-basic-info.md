# Create — Phase 2: Basic Info

## Overview

Interactively collect plugin metadata and write it to `plugin.json` and `README.md`, replacing the Phase 1 placeholders. Validate each input before writing.

## Fields to Collect

Ask for each field in order, validating as you go.

| Field | Validation | Notes |
|-------|------------|-------|
| `name` | lowercase, alphanumeric + hyphens; ≤ 64 chars; no leading/trailing hyphen | Becomes the plugin slug. Example: `my-cool-plugin`. |
| `version` | SemVer `MAJOR.MINOR.PATCH`; pre-release allowed (`0.1.0-alpha.1`) | Default `0.1.0`. |
| `description` | one sentence, ≤ 200 chars | Used by `using-skills` and marketplace listings. |
| `author` | name (required), email and url (optional) | If a single string is given, treat as name only. |
| `license` | SPDX identifier (`MIT`, `Apache-2.0`, etc.) OR explicit `null` | `null` for intentionally unlicensed internal plugins. |
| `entry-point intent` | free-text (e.g., "manager-style orchestrator", "slash-command bundle", "hook injector") | Not written to `plugin.json`; informs later phases (especially marketplace README). |

If a field fails validation, surface the rule and prompt again rather than proceeding with bad input.

## Before running either writer

**Precondition — confirm Node is present.** Run `node -v` and read its **output**, not its exit
status. If Node is absent, do not run the writers — invoke `check-node-runtime`, which reports what
stops working and offers a per-platform install. Scaffolding cannot proceed without Node unless you
take the `jq` path below, which covers only the manifest and only in bash.

**Both writers print an affirmative token.** A write that succeeded says so; **empty stdout means
the writer did not run and the file was not touched.** Do not go on to the next field or the next
phase on silence — for a mutation, "never ran" and "rewrote the file" are otherwise the same
observation, and the `## Validation` re-parse at the end of this page cannot tell them apart either
because an untouched manifest is still valid JSON.

Both writers take the collected values as **arguments**, never interpolated into a program body: an
apostrophe in a description or an author name (`O'Brien`) would otherwise close the shell quote and
abort the write. A double-quoted argument carries `'` through unchanged in bash and PowerShell; a
literal `"` inside a value still needs that shell's own escape (`\"` in bash, `` `" `` in
PowerShell). Verified end to end with `Siobhan O'Brien` as the author name on bash 5.3.9,
PowerShell 7.6.3 and Windows PowerShell 5.1.26100.8875.

## Update plugin.json

Two forms. The `jq` form is **bash only** — its `--arg` flags and backslash line
continuations are parse errors in PowerShell. Use it in bash when `jq` is installed;
otherwise — and in PowerShell always, whether or not `jq` is installed — use the Node
writer below.

```bash
jq --arg n "<name>" \
   --arg v "<version>" \
   --arg d "<description>" \
   --arg a "<author-name>" \
   --arg l "<license-or-null>" \
   '.name = $n
    | .version = $v
    | .description = $d
    | .author = {name: $a}
    | (if $l == "null" then .license = null else .license = $l end)' \
   .claude-plugin/plugin.json > .claude-plugin/plugin.json.tmp \
   && mv .claude-plugin/plugin.json.tmp .claude-plugin/plugin.json
```

Node writer (no `jq` required). It takes five positional arguments in the order `name`, `version`,
`description`, `author-name`, `license-or-null`, and rewrites `.claude-plugin/plugin.json` in place
relative to the current directory. Two-space indent and a trailing newline, matching the `jq` output
above — other tooling matches the serialized `"version": "…"` literally, so do not change the indent
or reorder keys. The literal string `null` in the fifth slot writes a JSON `null`.

| stdout | exit | Meaning |
|---|---|---|
| `WROTE .claude-plugin/plugin.json` | 0 | The manifest was rewritten with all five values. |
| *(nothing)* | non-zero | Nothing was written — the manifest is absent, unreadable, or not valid JSON, and the trace is on stderr. |
| *(nothing)* | 0 | The script did not run at all. Re-check the path in the invocation before re-running. |

**Supply all five arguments.** Arity is not checked: a short call assigns `undefined`, and
`JSON.stringify` drops a key whose value is `undefined`, so the missing fields are **deleted from
the manifest** rather than refused. The result is still valid JSON, so the `## Validation` re-parse
below does not catch it either.

### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/update-plugin-json.mjs" "<name>" "<version>" "<description>" "<author-name>" "<license-or-null>"
```

### Copilot CLI (Bash)

```bash
# Resolve this skill's install directory. Set MARKETPLACE_NAME=<slug> to pin one marketplace;
# otherwise every installed marketplace is searched and an ambiguous result fails closed.
ROOT="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins"
S="plugin-design"; P="scripts/update-plugin-json.mjs"
if [ -n "${MARKETPLACE_NAME+x}" ]; then G="$MARKETPLACE_NAME"; else G="*"; fi
F=""; N=0
for f in "$ROOT"/$G/ICON/skills/"$S/$P" "$ROOT"/$G/ICON/*/skills/"$S/$P"; do
  [ -f "$f" ] || continue; F="$f"; N=$((N+1))
done
[ "$N" = 1 ] || { echo "ICON: $N matches for $S/$P under $ROOT (marketplace ${MARKETPLACE_NAME-<any>}) — set MARKETPLACE_NAME; see: copilot plugin list" >&2; exit 1; }
node "$F" "<name>" "<version>" "<description>" "<author-name>" "<license-or-null>"
```

## Update README.md

Replaces the placeholder title and description line with the real values: line 1 becomes `# <name>`,
and the first subsequent non-blank line that is not a heading becomes the description. Takes two
positional arguments, `name` then `description`, and rewrites `README.md` relative to the current
directory. Written back LF-terminated with no BOM regardless of platform — using the host's line
ending here would rewrite every line of the file.

| stdout | exit | Meaning |
|---|---|---|
| `WROTE README.md` | 0 | The title and description line were replaced. |
| *(nothing)* | non-zero | Nothing was written — `README.md` is absent or unreadable, and the trace is on stderr. |
| *(nothing)* | 0 | The script did not run at all. Re-check the path in the invocation before re-running. |

### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/update-readme.mjs" "<name>" "<description>"
```

### Copilot CLI (Bash)

```bash
# Resolve this skill's install directory. Set MARKETPLACE_NAME=<slug> to pin one marketplace;
# otherwise every installed marketplace is searched and an ambiguous result fails closed.
ROOT="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins"
S="plugin-design"; P="scripts/update-readme.mjs"
if [ -n "${MARKETPLACE_NAME+x}" ]; then G="$MARKETPLACE_NAME"; else G="*"; fi
F=""; N=0
for f in "$ROOT"/$G/ICON/skills/"$S/$P" "$ROOT"/$G/ICON/*/skills/"$S/$P"; do
  [ -f "$f" ] || continue; F="$f"; N=$((N+1))
done
[ "$N" = 1 ] || { echo "ICON: $N matches for $S/$P under $ROOT (marketplace ${MARKETPLACE_NAME-<any>}) — set MARKETPLACE_NAME; see: copilot plugin list" >&2; exit 1; }
node "$F" "<name>" "<description>"
```

## Validation

Re-parse `plugin.json` after every edit to catch malformed writes. Identical in every shell:

```
node -e 'JSON.parse(require("fs").readFileSync(".claude-plugin/plugin.json", "utf8"))'
```

Exit code 0 with no output means the file is valid. Any output is the parse error.
