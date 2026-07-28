---
name: upgrade-repo
description: >
  Use when a repository has an existing .context/ folder that may be behind the
  current agent system spec — infrastructure files are outdated, new required files
  are missing (commit-conventions.md, branching.md), or the git hook is unwired.
user-invocable: true
---

# Upgrade Repository

## Overview

Bring an already-initialized `.context/` up to current spec without losing
customized content. **Audit first, act second, always confirm before replacing.**

## When to Use

- `.context/` exists but `prune-context.sh` lacks the `INTEGRATION_BRANCHES` variable
- `commit-conventions.md` or `branching.md` are missing from `.context/workflows/`
- The git hook is missing or not wired (`git config core.hooksPath`)
- You just ran `upgrade-repo` on another repo in this workspace and want consistency

**Do not use** if `.context/` doesn't exist yet — use `initialize-repo` instead.

## The Process

### upgrade-repo: Phase 0: Detect and Migrate Instructions File

Offer to migrate the legacy `.github/copilot-instructions.md` to the canonical
`.claude/claude.md`. Claude Code loads `.claude/claude.md` automatically; Copilot CLI
reaches it via a root-level `claude.md` redirect (created below).

**Case 1: Needs migration** — `.github/copilot-instructions.md` exists AND `.claude/claude.md` does not.

Show what will happen and **get confirmation before acting**:

> Ready to migrate instructions file:
> - `mkdir -p .claude`
> - `git mv .github/copilot-instructions.md .claude/claude.md`
>
> Proceed? (y/n)

If confirmed:

```bash
mkdir -p .claude
git mv .github/copilot-instructions.md .claude/claude.md
```

Then offer to migrate any optional sibling directories with the same
show-and-confirm pattern (one confirmation per directory):

```bash
# If .github/skills/ exists — offer:
git mv .github/skills/ .claude/skills/

# If .github/agents/ exists — offer:
git mv .github/agents/ .claude/agents/
```

After migration, note: *"Both Claude Code and Copilot CLI will now load
instructions from `.claude/claude.md`."*

**Case 2: Already migrated** — `.claude/claude.md` exists.

Skip this phase and note: *"`.claude/claude.md` already exists — migration complete. Continuing to Phase 1."*

**Case 3: Neither exists** — neither `.github/copilot-instructions.md` nor `.claude/claude.md` is present.

Skip this phase and note: *"No instructions file found. Create `.claude/claude.md`
before running `upgrade-repo`, or run `initialize-repo` to set up from scratch.
Continuing to Phase 1."*

### upgrade-repo: Ensure root-level `claude.md` redirect

After Cases 1 and 2, check whether a root-level `claude.md` redirect exists. Skip
in Case 3 — a redirect pointing at a non-existent `.claude/claude.md` would mislead
Copilot CLI users. Skip silently if `claude.md` already exists.

If `.claude/claude.md` exists and root `claude.md` does not, show what will be
written and **get confirmation before acting**:

> Ready to create a root-level `claude.md` redirect so Copilot CLI reaches
> `.claude/claude.md`:
>
> ```
> # Project Instructions
>
> This file is a redirect. The canonical project instructions live in `.claude/claude.md`.
>
> Read `.claude/claude.md` for the full project overview, tech stack, key commands,
> and conventions.
> ```
>
> Decline if this repo does not use Copilot CLI — nothing else in the upgrade
> depends on it.
>
> Proceed? (y/n)

If confirmed:

```bash
if [ -f ".claude/claude.md" ]; then
  if [ ! -f "claude.md" ]; then
    cat > claude.md << 'EOF'
# Project Instructions

This file is a redirect. The canonical project instructions live in `.claude/claude.md`.

Read `.claude/claude.md` for the full project overview, tech stack, key commands,
and conventions.
EOF
  fi
fi
```

**Case 3 note** — if `.claude/claude.md` does not exist: *Redirect not created — `.claude/claude.md` must exist first. Create it and re-run `upgrade-repo`.*

---

### upgrade-repo: Phase 1: Audit (no changes yet)

Invoke `find-context-template` to locate the template directory and establish `$TEMPLATE_DIR`, then run its **mandatory `## Validate` block** for the active tool and **halt this skill immediately if it exits non-zero** — do not continue to the audit, and do not guess a fallback path. Every step below reads from `$TEMPLATE_DIR`; on an unresolved path the audit does not fail loudly, it silently misreports (a failed `diff` against a nonexistent template reads as "files differ", flagging stock files as CUSTOMIZED).

Read `.context/iconrc.json` if it exists and extract the `excludes` array (empty if absent or no `excludes` key). Any directory named in `excludes` is intentionally omitted — never flag it as missing or create/update it in any later phase.

Check and report:
- **Infrastructure files**: `prune-context.sh`, `.githooks/post-commit` — present and current?
- **Directories**: all of `standards/ architecture/ testing/ tasks/ workflows/ domains/ decisions/ styling/` exist? *(Skip any in `excludes` — intentionally absent.)* A missing `decisions/` is easy to overlook: the flat-`decisions.md` check below reports *"nothing to do"* when neither the folder nor the flat file is present, so this list is the only place it gets caught. Phase 2 restores it from the template.

**Special check — deprecated `task-workflow-template.md`**

`task-workflow-template.md` is replaced by the per-phase templates in
`.context/workflows/task-plan/`. If present, remove it during this upgrade — but
only after migrating any team customizations to the phase files. Compare against
the stock reference to decide whether migration is required first.

```bash
if [ -f ".context/workflows/task-workflow-template.md" ]; then
  # On an unresolved $TEMPLATE_DIR, diff -q's target path doesn't exist, so
  # diff exits non-zero and this falls to the CUSTOMIZED branch -- the safe
  # direction (it blocks the bare-git-rm path in Phase 2), but it is still a
  # false finding produced by an unresolved path rather than a real compare.
  # This is incidental, not a designed guard; do not rely on it elsewhere.
  if diff -q ".context/workflows/task-workflow-template.md" \
             "$TEMPLATE_DIR/context/workflows/task-workflow-template.md" > /dev/null 2>&1; then
    echo "task-workflow-template.md: deprecated (stock) — will be deleted"
  else
    echo "task-workflow-template.md: deprecated (CUSTOMIZED) — merge-phase-templates required before deletion"
  fi
else
  echo "task-workflow-template.md: not present — nothing to do"
fi
```

```powershell
if (Test-Path ".context\workflows\task-workflow-template.md") {
    # Same StrictMode-safe $TEMPLATE_DIR guard as the prune-context.sh step
    # below -- required here too, and for a sharper reason than "misreports":
    # on an unresolved $TEMPLATE_DIR, Get-Content on the template side errors
    # non-terminating and yields $null, Compare-Object then fails parameter
    # binding so $diff stays $null, and `$null -eq $diff` reads as "stock".
    # Phase 2 deletes a file reported "stock" with a bare git rm -- no
    # merge-phase-templates, no migration -- so this specific false finding
    # routes straight to an unguarded deletion of real customizations.
    $TemplateDirShown = if (Test-Path Variable:\TEMPLATE_DIR) { "[$TEMPLATE_DIR]" } else { '[<unset>]' }
    if (-not (Test-Path Variable:\TEMPLATE_DIR) -or [string]::IsNullOrWhiteSpace($TEMPLATE_DIR) -or -not (Test-Path -LiteralPath (Join-Path $TEMPLATE_DIR 'context') -PathType Container)) {
        Write-Error "`$TEMPLATE_DIR does not resolve to a context template: $TemplateDirShown -- run find-context-template (Discovery Command + Validate) and halt on its non-zero exit before re-running this step. Refusing to report, because a wrong 'stock' finding here deletes real customizations with no migration step."
        exit 1
    }
    $diff = Compare-Object `
        (Get-Content ".context\workflows\task-workflow-template.md") `
        (Get-Content "$TEMPLATE_DIR\context\workflows\task-workflow-template.md")
    if ($null -eq $diff) {
        Write-Host "task-workflow-template.md: deprecated (stock) — will be deleted"
    } else {
        Write-Host "task-workflow-template.md: deprecated (CUSTOMIZED) — merge-phase-templates required before deletion"
    }
} else {
    Write-Host "task-workflow-template.md: not present — nothing to do"
}
```

**Special check — flat `decisions.md` → `decisions/` folder migration**

The flat `decisions.md` is replaced by the `decisions/` folder layout (one ADR per `NNN-kebab-slug.md`, `README.md` index). Check whether migration is needed:

<!-- pre-commit:dead-ref-ok-start -->
```bash
if [ -d ".context/decisions" ]; then
  echo "decisions/: folder already present — no migration needed"
elif [ -f ".context/decisions.md" ]; then
  echo "decisions.md: flat file present — migration to decisions/ required"
else
  echo "decisions.md: not present — nothing to do"
fi
```

```powershell
if (Test-Path ".context\decisions") {
    Write-Host "decisions/: folder already present — no migration needed"
} elseif (Test-Path ".context\decisions.md") {
    Write-Host "decisions.md: flat file present — migration to decisions/ required"
} else {
    Write-Host "decisions.md: not present — nothing to do"
}
```
<!-- pre-commit:dead-ref-ok-end -->

- **New required files**: `workflows/commit-conventions.md`, `workflows/branching.md`, `.context/.gitignore`, `.context/iconrc.json`, `.context/rules-index.md` — present?
- **`iconrc.json` schema version**: if present, compare its `version` against the template and report whether an update is needed.
- **`local_task_id_prefix` collision check**: see the Special check below.
- **Task plan phase templates**: does `.context/workflows/task-plan/` exist? If yes,
  report which of the 6 phase files are present and their `<!-- template-version: X.Y -->`
  markers. If absent, note it as "awaiting installation" — a new addition, not a
  critical missing file.
- **Hook wiring**: `git config --get core.hooksPath` points at `.githooks/`?
- **Root-level `.gitattributes`**: present, with `merge=union` for the retrospective files (`retrospectives.md`, `retrospectives-archive.md`)?
- **`## Related` graph seam**: do the content docs under `domains/`, `standards/`, `workflows/`, `architecture/`, `testing/`, and `styling/` carry a `## Related` footer — **or are they otherwise reachable** (a `rules-index.md` row, a folder `README.md` index)? Run `context-graph --check`; see `context-maintenance` § Tooling: context-graph for the invocation and the fail-closed exit contract. Report the orphan and dangling counts. ADRs under `decisions/` are orphan-checked but are **not** footer candidates — do not report them as missing footers. Expect a repo initialized before the seam shipped to report **every** `domains/` file as an orphan, plus every `standards/`/`workflows/` file when `rules-index.md` is also absent: that is the finding, not a parser error. Phase 2 closes it.

**Special check — `local_task_id_prefix` collision**

Compare the local prefix against ticket prefixes actually used in this project's
commit history — excluding the local prefix itself (it is the value under test,
not evidence against itself) and excluding mid-subject document references such
as `ADR-005`. Anchor extraction at the **start** of the subject line, where
`commit-conventions.md` requires a real ticket prefix to sit; a document
reference is never at that position.

```bash
# There is nothing to compare against if the file is absent -- and this check
# exists precisely to stop bogus collision findings, so it must not emit one
# about itself. Without this, an absent iconrc.json leaves LOCAL_PREFIX empty and
# the report reads "Local prefix '' collides with ... ICON".
if [ ! -f ".context/iconrc.json" ]; then
  echo "local_task_id_prefix collision check: .context/iconrc.json not present — skipped (create-iconrc runs in Phase 2; pass any external prefixes then)"
  exit 0
fi
# Match the key and its value together, so a single-line/minified iconrc.json
# parses the same as a pretty-printed one -- a line-wise `tail -1` over the whole
# file picks the last quoted token on that line, not this key's value.
LOCAL_PREFIX=$(grep -oE '"local_task_id_prefix"[[:space:]]*:[[:space:]]*"[^"]*"' .context/iconrc.json | sed 's/.*"\([^"]*\)"$/\1/')
if [ -z "$LOCAL_PREFIX" ]; then
  echo "local_task_id_prefix collision check: no local_task_id_prefix in .context/iconrc.json — skipped (nothing to collide)" >&2
  exit 0
fi
# -e is required: a prefix value may begin with `-`, which grep would otherwise
# parse as options (shell-portability Rule 4a).
EXTERNAL_PREFIXES=$(git log --format='%s' -100 | grep -oE '^[A-Za-z]{2,}-[0-9]+' | sed 's/-[0-9]*$//' | sort -uf | grep -vixF -e "$LOCAL_PREFIX" || true)
if [ -n "$EXTERNAL_PREFIXES" ]; then
  echo "Local prefix '$LOCAL_PREFIX' collides with detected external ticket prefix(es): $(echo "$EXTERNAL_PREFIXES" | tr '\n' ' ')— pass these as forbidden_prefixes when re-invoking create-iconrc to choose a distinct value"
fi
```

```powershell
# Same skip as the bash twin. Under StrictMode an absent file abandons the
# assignment below, and every later reference to $LocalPrefix abandons its own
# statement, so the check silently produces nothing at exit 0 while bash emits a
# bogus "Local prefix '' collides ..." finding. Neither is a usable report.
if (-not (Test-Path ".context\iconrc.json" -PathType Leaf)) {
    Write-Host "local_task_id_prefix collision check: .context\iconrc.json not present - skipped (create-iconrc runs in Phase 2; pass any external prefixes then)"
    exit 0
}
# Guard the missing-KEY case too, not just the missing-file case above: under
# StrictMode, accessing .local_task_id_prefix directly throws
# PropertyNotFoundException when an installed iconrc.json simply lacks the
# key, which abandons the assignment the same way an absent file does above --
# silently, at exit 0, with no report. .PSObject.Properties[...] is the
# StrictMode-safe existence check (an absent key returns $null instead of
# throwing); only once the key is confirmed present is direct member access safe.
$IconRc = Get-Content ".context\iconrc.json" | ConvertFrom-Json
if (-not $IconRc.PSObject.Properties['local_task_id_prefix'] -or [string]::IsNullOrWhiteSpace($IconRc.local_task_id_prefix)) {
    Write-Host "local_task_id_prefix collision check: no local_task_id_prefix in .context\iconrc.json - skipped (nothing to collide)"
    exit 0
}
$LocalPrefix = $IconRc.local_task_id_prefix
$ExternalPrefixes = git log --format='%s' -100 |
    Select-String -Pattern '^[A-Za-z]{2,}-[0-9]+' |
    ForEach-Object { ($_.Matches[0].Value -replace '-[0-9]+$', '') } |
    Sort-Object -Unique |
    Where-Object { $_ -ine $LocalPrefix }
if ($ExternalPrefixes) {
    Write-Host "Local prefix '$LocalPrefix' collides with detected external ticket prefix(es): $($ExternalPrefixes -join ', ') — pass these as forbidden_prefixes when re-invoking create-iconrc to choose a distinct value"
}
```

Reporting only — Phase 2 does not auto-rewrite the field. The surviving
external-prefix set above is exactly what gets handed to `create-iconrc` as
`forbidden_prefixes` if the user later chooses a replacement — see the
resolution step in Phase 2 below.

Summarize and **get confirmation before touching any existing file**.

### upgrade-repo: Phase 2: Upgrade Infrastructure

Replace outdated infrastructure files from the template. **Content files
(`overview.md`, `decisions/`, domain files) are never touched here.**
**Excluded directories** (names in `excludes` from Phase 1): never create, restore,
or populate them, even if absent.

**Special case — delete deprecated `task-workflow-template.md`**

If Phase 1 reported the file as **not present**, skip this section.

If Phase 1 flagged the file as **deprecated (CUSTOMIZED)**:
- Invoke the `merge-phase-templates` skill, which extracts custom content and
  distributes it to the appropriate phase template files in
  `.context/workflows/task-plan/`.
- After `merge-phase-templates` confirms migration is complete, delete the file:

  ```bash
  git rm .context/workflows/task-workflow-template.md
  ```

If Phase 1 reported the file as **deprecated (stock)**, delete it directly:

```bash
git rm .context/workflows/task-workflow-template.md
```

---

<!-- pre-commit:dead-ref-ok-start -->
**Special case — migrate flat `decisions.md` to `decisions/` folder**

If Phase 1 reported `decisions/: folder already present` or `decisions.md: not present`, skip this section.

If Phase 1 reported `decisions.md: flat file present`, show what will happen and **get confirmation before acting**:

> Ready to migrate `.context/decisions.md` to `.context/decisions/`:
> - Parse each `## ADR-NNN:` block → create `.context/decisions/NNN-kebab-slug.md`
> - Generate `.context/decisions/README.md` (intro + Template + Decision Log table)
> - Preserve any non-ADR content in `.context/decisions/_preserved-content.md`
> - `git rm .context/decisions.md`
>
> Proceed? (y/n)

If confirmed, run the migration:

```bash
set -euo pipefail

mkdir -p .context/decisions

# Use mktemp for the preamble buffer so the script works in restricted /tmp envs
# and avoids fixed-name collisions. Clean up on exit.
tmp_preamble=$(mktemp)
trap 'rm -f "$tmp_preamble"' EXIT

# Extract non-ADR content (intro, template block, miscellaneous notes) before the first ## ADR- header.
# The one-liner stops at the first ADR header and uses no gawk-specific features (portable to mawk).
awk '/^## ADR-/{exit} {print}' .context/decisions.md > "$tmp_preamble"

# Match PowerShell's `\S` semantics: only write the preserved-content file if the
# preamble contains at least one non-whitespace character. `[ -s ... ]` would
# trigger on whitespace-only preambles and diverge from the PS branch.
if grep -q '[^[:space:]]' "$tmp_preamble"; then
  {
    echo "<!-- Content preserved from .context/decisions.md before ADR sections. -->"
    echo "<!-- Review and integrate into decisions/README.md as appropriate. -->"
    echo ""
    cat "$tmp_preamble"
  } > .context/decisions/_preserved-content.md
fi

# Parse ADR blocks in pure bash. Avoids two gawk-isms that break on mawk
# (Debian/Ubuntu/WSL/Alpine default): 3-arg `match()` with a capture array,
# and `printf -v <var>` (which is bash syntax, not awk syntax).
outfile=""
while IFS= read -r line || [ -n "$line" ]; do
  if [[ "$line" =~ ^##[[:space:]]ADR-([0-9]+):[[:space:]](.+)$ ]]; then
    num="${BASH_REMATCH[1]}"
    title="${BASH_REMATCH[2]}"
    # Zero-pad to 3 digits BEFORE using in the filename (slug uses the title only).
    printf -v padnum "%03d" "$num"
    slug=$(printf '%s' "$title" \
      | tr '[:upper:]' '[:lower:]' \
      | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')
    outfile=".context/decisions/${padnum}-${slug}.md"
    # Promote h2 → h1 for the header line.
    printf '# ADR-%s: %s\n' "$padnum" "$title" > "$outfile"
  elif [[ "$line" =~ ^##[[:space:]]ADR- ]]; then
    # Malformed ADR header (no number / no title). Warn and drop the line —
    # do NOT append it (or any orphan body that follows it) to the previous
    # ADR's file.
    printf 'warning: skipping malformed ADR header: %s\n' "$line" >&2
    outfile=""
  elif [ -n "$outfile" ]; then
    printf '%s\n' "$line" >> "$outfile"
  fi
done < .context/decisions.md

# Generate README.md with Decision Log table populated from parsed ADRs
{
  echo "# Architecture Decision Records (ADRs)"
  echo ""
  echo "This folder tracks significant architectural decisions made for this project. Each ADR captures the context, the decision, and its trade-offs so future contributors do not relitigate the same trade-offs from scratch."
  echo ""
  echo "One ADR per file, numbered sequentially: \`NNN-kebab-slug.md\`. ADR numbers are immutable once assigned; superseded ADRs stay in place with their status updated."
  echo ""
  echo "## Template"
  echo ""
  echo '```markdown'
  echo "# ADR-NNN: Title"
  echo ""
  echo "**Date**: YYYY-MM-DD"
  echo "**Status**: Accepted | Superseded by ADR-XXX | Deprecated"
  echo ""
  echo "## Context"
  echo "What problem prompted this decision?"
  echo ""
  echo "## Decision"
  echo "What did we choose?"
  echo ""
  echo "## Consequences"
  echo "What is now easier or harder as a result?"
  echo ""
  echo "## Alternatives Considered"
  echo "What did we reject and why?"
  echo '```'
  echo ""
  echo "## Decision Log"
  echo ""
  echo "| ADR | Title | Status | Date |"
  echo "|-----|-------|--------|------|"
  # One row per ADR file found. The `|| true` on each grep keeps the loop
  # alive under `set -e` when a freshly-migrated ADR is missing its Status
  # or Date lines — we want a row with blank cells, not an aborted script.
  for f in .context/decisions/[0-9]*.md; do
    [ -f "$f" ] || continue
    fname=$(basename "$f" .md)
    num=$(echo "$fname" | sed 's/^\([0-9]*\)-.*/\1/')
    # Read title from h1 line
    title=$(grep -m1 '^# ADR-' "$f" | sed 's/^# ADR-[0-9]*: //' || true)
    status=$(grep -m1 '^\*\*Status\*\*:' "$f" | sed 's/\*\*Status\*\*:[[:space:]]*//' || true)
    date=$(grep -m1 '^\*\*Date\*\*:' "$f" | sed 's/\*\*Date\*\*:[[:space:]]*//' || true)
    echo "| [$num]($fname.md) | $title | $status | $date |"
  done
} > .context/decisions/README.md

git rm .context/decisions.md
```

```powershell
# Known divergence from the bash twin above: that script starts with
# `set -euo pipefail` and aborts if `.context/decisions.md` is absent. This
# block has no equivalent StrictMode guard or existence check, so running it
# without the file silently regenerates decisions/README.md at rc=0 and
# discards nothing that mattered here -- but reaching this block at all
# requires an operator to confirm the (y/n) migration prompt above, which the
# prose already says to skip when Phase 1 found no decisions.md. Left as-is;
# not fixed as part of this pass.
New-Item -ItemType Directory -Force -Path ".context\decisions" | Out-Null

# Extract non-ADR preamble content
$lines = Get-Content ".context\decisions.md"
$preamble = @()
foreach ($line in $lines) {
    if ($line -match '^## ADR-\d+:') { break }
    $preamble += $line
}
if ($preamble -join "" -match '\S') {
    $preserved = @(
        "<!-- Content preserved from .context/decisions.md before ADR sections. -->",
        "<!-- Review and integrate into decisions/README.md as appropriate. -->",
        ""
    ) + $preamble
    $preserved | Set-Content ".context\decisions\_preserved-content.md"
}

# Parse ADR blocks and write individual files.
# Split on well-formed `## ADR-NNN:` headers only. Lines like `## ADR- ` (no
# number) are treated as malformed: warn and drop, rather than letting the
# regex-split glue their orphan body onto the prior ADR's file.
$content = Get-Content ".context\decisions.md" -Raw
$blocks = [regex]::Split($content, '(?m)^(?=## ADR-\d+:)')
foreach ($block in $blocks) {
    if ($block -notmatch '^## ADR-(\d+): (.+)') {
        # Check whether this block was led by a malformed ADR header so we can
        # surface a warning. Preamble (no `## ADR-` at all) is silently skipped
        # here — it's handled by the preamble block above.
        if ($block -match '(?m)^## ADR-(?!\d+:)(.*)$') {
            $bad = $matches[0]
            Write-Warning "skipping malformed ADR header: $bad"
        }
        continue
    }
    $num    = $matches[1]
    $title  = $matches[2].Trim()
    $padnum = $num.PadLeft(3, '0')
    $slug   = ($title.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
    $outfile = ".context\decisions\$padnum-$slug.md"
    # Promote h2 to h1 for the header line, keep rest as-is
    $body = $block -replace "^## ADR-$num`: $([regex]::Escape($title))", "# ADR-$num`: $title"
    $body | Set-Content $outfile
}

# Generate README.md with Decision Log table
$rows = @()
Get-ChildItem ".context\decisions\*.md" | Where-Object { $_.Name -match '^\d' } | Sort-Object Name | ForEach-Object {
    $fname  = $_.BaseName
    $numStr = $fname -replace '^(\d+)-.*', '$1'
    $fcont  = Get-Content $_.FullName
    $titleLine = ($fcont | Where-Object { $_ -match '^# ADR-' } | Select-Object -First 1)
    $adrTitle  = $titleLine -replace '^# ADR-\d+: ', ''
    $statusLine = ($fcont | Where-Object { $_ -match '^\*\*Status\*\*:' } | Select-Object -First 1)
    $adrStatus  = $statusLine -replace '\*\*Status\*\*:\s*', ''
    $dateLine = ($fcont | Where-Object { $_ -match '^\*\*Date\*\*:' } | Select-Object -First 1)
    $adrDate  = $dateLine -replace '\*\*Date\*\*:\s*', ''
    $rows += "| [$numStr]($fname.md) | $adrTitle | $adrStatus | $adrDate |"
}
$readme = @(
    "# Architecture Decision Records (ADRs)",
    "",
    "This folder tracks significant architectural decisions made for this project. Each ADR captures the context, the decision, and its trade-offs so future contributors do not relitigate the same trade-offs from scratch.",
    "",
    "One ADR per file, numbered sequentially: ``NNN-kebab-slug.md``. ADR numbers are immutable once assigned; superseded ADRs stay in place with their status updated.",
    "",
    "## Template",
    "",
    '```markdown',
    "# ADR-NNN: Title",
    "",
    "**Date**: YYYY-MM-DD",
    "**Status**: Accepted | Superseded by ADR-XXX | Deprecated",
    "",
    "## Context",
    "What problem prompted this decision?",
    "",
    "## Decision",
    "What did we choose?",
    "",
    "## Consequences",
    "What is now easier or harder as a result?",
    "",
    "## Alternatives Considered",
    "What did we reject and why?",
    '```',
    "",
    "## Decision Log",
    "",
    "| ADR | Title | Status | Date |",
    "|-----|-------|--------|------|"
) + $rows
$readme | Set-Content ".context\decisions\README.md"

git rm ".context\decisions.md"
```
<!-- pre-commit:dead-ref-ok-end -->

**Special case — `prune-context.sh` and the `INTEGRATION_BRANCHES` value**

`INTEGRATION_BRANCHES` in `.context/workflows/prune-context.sh` is a **consumer
customization, not template state**. It is the regex naming which branches the
post-commit hook may prune `.context/tasks/` on, and `initialize-repo` sets it from
the repo's real branch model. The template ships a deliberately broad default;
copying that default over an installed script silently reverts the repo's branch-model
decision and re-arms pruning on branches it may have decided will never exist.

The copy is still required — it is how a consumer receives genuine script-logic
updates. So the operation is never "copy" and never "skip". It is always
**extract → copy → restore**. Find the row matching the installed state:

| Installed state | Action |
|---|---|
| `prune-context.sh` present **with** a named `INTEGRATION_BRANCHES` | Extract the whole assignment line, copy the template script, then restore the extracted line. Never leave the template default in place. |
| `prune-context.sh` present with a hardcoded `=~` regex and **no** named variable | Extract the regex from the `=~` test, copy the template script, then set `INTEGRATION_BRANCHES` to the extracted regex. |
| A legacy `prune-old-tasks.sh` is present | `git mv` it to `prune-context.sh` **first** — that keeps the `.githooks/post-commit` reference resolving — then apply whichever row above matches its contents. If both files are present, stop and let the user resolve it. |
| Neither present | Copy the template script, then set `INTEGRATION_BRANCHES` from the integration branches `branching.md` documents (see the `branching.md` step below). |

**Every row that copies is followed by a restore step in the same row. There is no
unconditional `cp` in this section** — if you are about to run a bare `cp` of
`prune-context.sh`, you have skipped an extraction.

Rows 1 and 2 are read off the **live** lines only; a commented-out assignment or
branch test is history, not policy. Where the installed script does not land
cleanly in one row, the block **stops with a non-zero exit and changes nothing** —
more than one live assignment or branch test, a `=~` operand that is a variable
reference rather than a literal regex, an operand that is quoted or contains a
shell expansion, or a pattern the regex engine rejects. Every one of those means
the repo's real integration-branch policy is somewhere the block cannot see, and
writing a guess there is the data loss this whole section exists to prevent. When
it stops, report the error to the user and let them add an explicit
`INTEGRATION_BRANCHES="<regex>"` line; do not hand-copy the template over it.

The block below implements all four rows. Run it as a unit; never lift the `cp` out
of it and run that alone.

```bash
# Preserve INTEGRATION_BRANCHES across the prune-context.sh refresh.
# Extract -> copy -> restore, in that order. No path through this block copies
# without restoring.
WF=".context/workflows"
DEST="$WF/prune-context.sh"
LEGACY="$WF/prune-old-tasks.sh"
SRC="$TEMPLATE_DIR/context/workflows/prune-context.sh"

# Row 3 first -- a legacy prune-old-tasks.sh becomes prune-context.sh, so the
# `bash .../prune-context.sh` line in .githooks/post-commit keeps resolving.
# After the rename it is an ordinary installed script and rows 1/2/4 apply to
# its contents. Both files present is a human decision, not a guess.
if [ -f "$LEGACY" ]; then
  if [ -f "$DEST" ]; then
    echo "ERROR: both prune-old-tasks.sh and prune-context.sh are present in $WF." >&2
    echo "       Resolve by hand before re-running: merge any customization from the" >&2
    echo "       legacy file into prune-context.sh, then 'git rm' the legacy file." >&2
    exit 1
  fi
  git mv "$LEGACY" "$DEST" || {
    echo "ERROR: git mv of the legacy pruning script failed; nothing has been changed." >&2
    exit 1
  }
  echo "Renamed prune-old-tasks.sh -> prune-context.sh (post-commit hook reference preserved)"
fi

# Extract BEFORE anything overwrites it.
#
# One pass over the installed script collects both candidate shapes at once.
# Lines whose first non-blank character is `#` are skipped throughout: leaving
# the previous branch test commented out above the live one is an ordinary
# editing habit, and reading that dead line as policy silently re-arms pruning
# on the branches the repo deliberately dropped.
COMMENT_RE='^[[:space:]]*#'
# Row 1 selector. Deliberately wider than `^INTEGRATION_BRANCHES=`: an `export`
# prefix and leading indentation are ordinary ways to write the same assignment,
# and a strictly `^`-anchored selector pushes those scripts into row 2 -- where
# the stock `[[ ! "$CURRENT_BRANCH" =~ $INTEGRATION_BRANCHES ]]` line matches and
# the literal variable reference gets captured as if it were the value. That
# destroys the real setting and leaves the script fatal under `set -u`.
# Case-sensitive on purpose, and the PowerShell twin uses -cmatch/-clike to
# agree: prune-context.sh expands the upper-case name, so a lower-case
# `integration_branches=` is a different variable, not this one.
ASSIGN_RE='^[[:space:]]*(export[[:space:]]+)?INTEGRATION_BRANCHES='
# Row 2 selector. CURRENT_BRANCH must be the LEFT OPERAND of the `=~`, not merely
# present somewhere on the line -- see the scan loop below for why.
TEST_RE='CURRENT_BRANCH\}?"?[[:space:]]+=~'
SAVED_LINE=""
if [ -f "$DEST" ]; then
  ASSIGN_LINE=""
  ASSIGN_COUNT=0
  TEST_LINE=""
  TEST_TAIL=""
  TEST_COUNT=0
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ $line =~ $COMMENT_RE ]]; then
      continue
    fi
    if [[ $line =~ $ASSIGN_RE ]]; then
      ASSIGN_COUNT=$((ASSIGN_COUNT + 1))
      if [ "$ASSIGN_COUNT" -eq 1 ]; then ASSIGN_LINE="$line"; fi
      continue
    fi
    # Row 2 selector. CURRENT_BRANCH must be the LEFT OPERAND of the `=~`, not
    # merely present on the same line. prune-context.sh tests the cache TTL with
    # `=~` well before it tests the branch, so "first `=~` in the file" extracts
    # the TTL pattern -- and "the line mentions CURRENT_BRANCH and contains `=~`"
    # only narrows that, it does not close it. A line such as
    #   if [ -n "$CURRENT_BRANCH" ] && [[ "$CACHE_DAYS" =~ ^[0-9]+$ ]]; then
    # satisfies both substring tests independently while carrying no branch policy
    # at all, and reading it restores the TTL regex as the integration-branch list.
    # So require the name, an optional `}` and closing quote, whitespace, then
    # `=~`, with nothing else in between.
    #
    # Count matches, not `=~` occurrences: a compound condition
    # (`[[ ... =~ A ]] || [[ ... =~ B ]]`) carries two policies on one line, and
    # capturing only the first would silently drop the second. Each pass consumes
    # exactly the text it matched, so an unrelated `=~` elsewhere on the line
    # neither inflates the count nor shifts which operand gets read.
    #
    # Known edge of a textual scan, accepted deliberately: this reads lines, it
    # does not parse shell. A `CURRENT_BRANCH ... =~ ...` sequence that occurs
    # only inside a string literal -- say `echo "... $CURRENT_BRANCH =~ x ]] ..."`
    # -- is counted as a live branch test. Reaching that outcome requires the
    # decoy to be the file's ONLY such sequence, which means the script carries no
    # real branch policy to lose; and the alternative, parsing shell, is exactly
    # the guessing every refusal below declines to do.
    rest="$line"
    while [[ $rest =~ $TEST_RE ]]; do
      TEST_COUNT=$((TEST_COUNT + 1))
      rest="${rest#*"${BASH_REMATCH[0]}"}"
      # Keep the whole line for diagnostics, but parse from the matched `=~`
      # onward -- parsing from the start of the line is what let an earlier,
      # unrelated `=~` supply the operand.
      if [ "$TEST_COUNT" -eq 1 ]; then TEST_LINE="$line"; TEST_TAIL="=~$rest"; fi
    done
  done < "$DEST"

  if [ "$ASSIGN_COUNT" -gt 1 ]; then
    echo "ERROR: $DEST has $ASSIGN_COUNT live INTEGRATION_BRANCHES assignments." >&2
    echo "       Which one is authoritative is a human decision, not a guess." >&2
    echo "       Refusing to copy -- collapse them to a single assignment in" >&2
    echo "       $DEST, then re-run." >&2
    exit 1
  fi

  if [ "$ASSIGN_COUNT" -eq 1 ]; then
    # Row 1 -- a named INTEGRATION_BRANCHES assignment. Keep the whole line
    # verbatim: the value is a regex and must never be re-parsed or re-quoted.
    SAVED_LINE="$ASSIGN_LINE"
  else
    # Row 2 -- no named variable; recover the regex from the hardcoded =~ test.
    if [ "$TEST_COUNT" -eq 0 ]; then
      echo "ERROR: $DEST has no INTEGRATION_BRANCHES assignment and no branch test" >&2
      echo "       matching CURRENT_BRANCH ... =~ ..., so its integration-branch policy" >&2
      echo "       cannot be recovered. Refusing to copy -- the template default" >&2
      echo "       would silently replace whatever this repo actually intends." >&2
      echo "       Fix by hand: add an explicit INTEGRATION_BRANCHES=\"<regex>\" line to" >&2
      echo "       $DEST naming this repo's integration branches, then re-run." >&2
      exit 1
    fi
    if [ "$TEST_COUNT" -gt 1 ]; then
      echo "ERROR: $DEST has $TEST_COUNT branch tests matching" >&2
      echo "       CURRENT_BRANCH ... =~ ... . Which one carries the integration-branch" >&2
      echo "       policy is a human decision, not a guess -- and a superseded test left" >&2
      echo "       behind in a trailing '# ...' comment counts, because telling a comment" >&2
      echo "       '#' from a literal '#' inside a regex is not something this step will" >&2
      echo "       guess at either. Refusing to copy. Fix by hand: delete the superseded" >&2
      echo "       test, or add an explicit INTEGRATION_BRANCHES=\"<regex>\" line to" >&2
      echo "       $DEST, then re-run." >&2
      exit 1
    fi
    OLD_TEST="$TEST_LINE"
    # The `=~` operand is the next whitespace-delimited word, and the closing `]]`
    # is a separate word. Whitespace *inside* an unquoted operand is not a syntax
    # error -- bash accepts `[[ $b =~ ^(main| dev)$ ]]`, and it matches -- but it
    # is legal only where paren depth is greater than zero. Such a line is still
    # refused, and the step that refuses it is the *parse* below, not the validity
    # probe further down: the pattern requires the captured word to be followed by
    # whitespace and then `]]`, and on `^(main| dev)$ ]]` the word `^(main|` is
    # followed by `dev)$`, so the match fails outright and the "could not parse"
    # path fires. (The validity probe catches a different shape -- one that parses
    # cleanly but yields an unusable regex, such as a truncated `^(main|rel-[0-9`.)
    # That is what makes "take the word, then require a whitespace-separated `]]`"
    # safe, and why hunting for a `]]` delimiter is not: hunting is what made the
    # two shells disagree. Neither the `]]` inside a bracket expression
    # (^(main|v[]])$) nor the `]]` inside a trailing `# see [[branching]]` comment
    # is preceded by whitespace, so neither can be mistaken for the closing token,
    # on either shell.
    BRANCH_TEST_RE='=~[[:space:]]*([^[:space:]]+)[[:space:]]+\]\]'
    if [[ $TEST_TAIL =~ $BRANCH_TEST_RE ]]; then
      CANDIDATE="${BASH_REMATCH[1]}"
    else
      echo "ERROR: could not parse the branch test in $DEST:" >&2
      echo "         $OLD_TEST" >&2
      echo "       Expected the form [[ ! \"\$CURRENT_BRANCH\" =~ <regex> ]]." >&2
      echo "       Refusing to copy -- guessing here would discard this repo's" >&2
      echo "       integration-branch list. Add an explicit INTEGRATION_BRANCHES=" >&2
      echo "       line to $DEST by hand, then re-run." >&2
      exit 1
    fi
    # A bare variable reference is not a value. It means this script DOES keep
    # its policy in a named variable and row 1 is the right row -- so capturing
    # the reference would delete the real value and leave prune-context.sh
    # aborting on every commit with an unbound-variable error.
    if [[ $CANDIDATE =~ ^\$\{?[A-Za-z_] ]]; then
      echo "ERROR: the branch test in $DEST reads its pattern from a variable:" >&2
      echo "         $OLD_TEST" >&2
      echo "       '$CANDIDATE' is a reference, not a value, so this repo holds its" >&2
      echo "       integration-branch policy somewhere this step could not see." >&2
      echo "       Writing the reference back would destroy the real value and make" >&2
      echo "       the script fail on every commit. Refusing to copy. Fix by hand:" >&2
      echo "       add an explicit INTEGRATION_BRANCHES=\"<regex>\" line to $DEST" >&2
      echo "       carrying this repo's real value, then re-run." >&2
      exit 1
    fi
    # Anything else that is not a self-contained literal regex. A quote makes the
    # test a literal-string comparison rather than a regex; a backtick, or a `$`
    # that is not a trailing or alternation anchor, is a shell expansion. Neither
    # can be re-emitted as an assignment without changing what it means.
    EXPANSION_RE='\$[^)|]'
    if [[ $CANDIDATE == *\"* ]] || [[ $CANDIDATE == *\'* ]] \
       || [[ $CANDIDATE == *\`* ]] || [[ $CANDIDATE =~ $EXPANSION_RE ]]; then
      echo "ERROR: the branch pattern extracted from $DEST is not a plain regex:" >&2
      echo "         $CANDIDATE" >&2
      echo "       It contains a quote, a backtick, or a shell expansion, so it" >&2
      echo "       cannot be re-emitted as an INTEGRATION_BRANCHES assignment without" >&2
      echo "       changing its meaning. Refusing to copy. Add an explicit" >&2
      echo "       INTEGRATION_BRANCHES=\"<regex>\" line to $DEST by hand, then re-run." >&2
      exit 1
    fi
    # Validate before writing. `[[ =~ ]]` returns 0 on match, 1 on no-match, and
    # >1 on an unusable pattern -- and bash prints its own diagnostic to stderr,
    # which is left visible on purpose. A bad capture must fail loud, not ship.
    if [[ icon-regex-probe =~ $CANDIDATE ]]; then RE_RC=0; else RE_RC=$?; fi
    if [ "$RE_RC" -gt 1 ]; then
      echo "ERROR: the regex extracted from $DEST is not usable: $CANDIDATE" >&2
      echo "       (bash's own diagnostic for it is printed above.) Refusing to copy." >&2
      exit 1
    fi
    # Single-quoted. The value is a regex, and double quotes would reinterpret
    # the characters it is made of -- `\\` collapses to `\`. The checks above
    # have already refused anything containing a single quote.
    SAVED_LINE="INTEGRATION_BRANCHES='$CANDIDATE'"
  fi
  # A trailing CR is a line terminator, not part of the value. `git ls-files
  # --eol` reports prune-context.sh as `i/lf w/crlf`, and core.autocrlf=true is
  # the Windows default, so a Windows consumer's installed copy IS CRLF and the
  # row-1 path -- which keeps the whole line verbatim -- would otherwise carry the
  # CR into the assignment. Strip it here; the restore below re-applies whatever
  # terminator the destination file actually uses. (Row 2 is already clean: `\r`
  # is in [[:space:]], so the capture cannot include it.)
  SAVED_LINE="${SAVED_LINE%$'\r'}"
fi

# Refuse to copy if the copy would discard a value we cannot put back.
if [ -n "$SAVED_LINE" ]; then
  echo "Preserving existing value: $SAVED_LINE"
  if [ -z "$(sed -n '/^INTEGRATION_BRANCHES=/{p;q;}' "$SRC")" ]; then
    echo "ERROR: $SRC has no INTEGRATION_BRANCHES assignment to replace." >&2
    echo "       Refusing to copy -- that would discard $SAVED_LINE." >&2
    exit 1
  fi
else
  # Row 4 -- nothing to preserve.
  echo "No existing INTEGRATION_BRANCHES found; set it from branching.md after the copy."
fi

cp "$SRC" "$DEST" || {
  echo "ERROR: failed to copy $SRC to $DEST" >&2
  exit 1
}

# Restore. The saved line is emitted with printf, never fed to a regex
# replacement: sed's replacement side treats & and \ as metacharacters, and this
# value legitimately contains ^ $ ( ) | and may contain & or \.
#
# The replaced line takes the terminator the destination line already had, and
# every other line passes through byte-for-byte (`read -r` with IFS= keeps a
# trailing CR in "$line"). This step's job is to carry one value across a
# template refresh, not to re-line-end the file: on a Windows checkout the
# template itself is CRLF, so normalizing here would make the restore path
# disagree with the plain-copy path one row above it, and with the other shell.
#
# One acknowledged difference from a plain `cp`: if the template's last line has
# no terminator, `printf '%s\n'` gives it one, so the restored file gains a
# trailing newline the plain-copy path would not. Unreachable with the shipped
# template (it ends CR LF) and harmless to a shell script; recorded so the next
# reader does not mistake it for byte-for-byte fidelity in every case.
if [ -n "$SAVED_LINE" ]; then
  if { while IFS= read -r line || [ -n "$line" ]; do
         case "$line" in
           INTEGRATION_BRANCHES=*$'\r') printf '%s\r\n' "$SAVED_LINE" ;;
           INTEGRATION_BRANCHES=*)      printf '%s\n'   "$SAVED_LINE" ;;
           *)                           printf '%s\n'   "$line" ;;
         esac
       done < "$DEST" > "$DEST.tmp"; } && mv "$DEST.tmp" "$DEST"; then
    echo "Restored: $SAVED_LINE"
  else
    rm -f "$DEST.tmp"
    echo "ERROR: failed to restore INTEGRATION_BRANCHES in $DEST ($SAVED_LINE)" >&2
    exit 1
  fi
fi
```

```powershell
# Preserve INTEGRATION_BRANCHES across the prune-context.sh refresh.
# Extract -> copy -> restore, in that order. No path through this block copies
# without restoring.
#
# --- $TEMPLATE_DIR guard (StrictMode-safe) -----------------------------------
# This runs FIRST, before $TEMPLATE_DIR is dereferenced anywhere below, and the
# clause order is load-bearing. Under `Set-StrictMode -Version Latest`, merely
# *referencing* a never-set variable raises InvalidOperation -- and that error
# abandons the enclosing statement rather than stopping the script, so execution
# resumes at the NEXT statement. Interpolating $TEMPLATE_DIR (or $Src) in a
# guard's condition, or in the catch that is supposed to report the failure,
# therefore skips the `exit 1` and falls straight through to this block's
# "Preserving ..." / "Restored: ..." success lines with nothing copied.
# `Test-Path Variable:` is the only one of the three clauses safe to evaluate
# when the variable was never assigned, so it leads; the blank check runs next;
# the path test runs last, because Join-Path raises its own error on a blank
# path. Same three clauses, same order, as create-iconrc's pre-requisite guard.
$TemplateDirShown = if (Test-Path Variable:\TEMPLATE_DIR) { "[$TEMPLATE_DIR]" } else { '[<unset>]' }
if (-not (Test-Path Variable:\TEMPLATE_DIR) -or [string]::IsNullOrWhiteSpace($TEMPLATE_DIR) -or -not (Test-Path -LiteralPath (Join-Path $TEMPLATE_DIR 'context') -PathType Container)) {
    Write-Error "`$TEMPLATE_DIR does not resolve to a context template: $TemplateDirShown -- run find-context-template (Discovery Command + Validate) and halt on its non-zero exit before re-running this step. Refusing to copy."
    exit 1
}

$WF     = ".context\workflows"
$Dest   = "$WF\prune-context.sh"
$Legacy = "$WF\prune-old-tasks.sh"
$Src    = "$TEMPLATE_DIR\context\workflows\prune-context.sh"

# Row 3 first -- a legacy prune-old-tasks.sh becomes prune-context.sh, so the
# `bash .../prune-context.sh` line in .githooks/post-commit keeps resolving.
# After the rename it is an ordinary installed script and rows 1/2/4 apply to
# its contents. Both files present is a human decision, not a guess.
if (Test-Path $Legacy) {
    if (Test-Path $Dest) {
        Write-Error "Both prune-old-tasks.sh and prune-context.sh are present in $WF. Resolve by hand before re-running: merge any customization from the legacy file into prune-context.sh, then 'git rm' the legacy file."
        exit 1
    }
    git mv $Legacy $Dest
    # Verify the OUTCOME, not $LASTEXITCODE. If `git` is missing from PATH the
    # call raises CommandNotFoundException, which abandons that statement without
    # ever setting $LASTEXITCODE -- and under StrictMode reading an unset
    # $LASTEXITCODE then abandons the `if` too, skipping the `exit 1` and printing
    # "Renamed ..." for a rename that never happened. The two Test-Path calls
    # below take only literals, so nothing in this check can itself fail.
    if ((Test-Path $Legacy) -or -not (Test-Path $Dest)) {
        Write-Error "git mv of the legacy pruning script failed; nothing has been changed. Resolve by hand and re-run."
        exit 1
    }
    Write-Host "Renamed prune-old-tasks.sh -> prune-context.sh (post-commit hook reference preserved)"
}

# Extract BEFORE anything overwrites it.
#
# One pass over the installed script collects both candidate shapes at once.
# Lines whose first non-blank character is `#` are skipped throughout: leaving
# the previous branch test commented out above the live one is an ordinary
# editing habit, and reading that dead line as policy silently re-arms pruning
# on the branches the repo deliberately dropped.
#
# Every comparison below is case-SENSITIVE (-cmatch / -clike), matching the bash
# twin: prune-context.sh expands the upper-case INTEGRATION_BRANCHES, so a
# lower-case `integration_branches=` is a different variable, not this one. The
# case-insensitive default made PowerShell save the lower-case line and bash
# ignore it -- the same repo upgrading two different ways, both wrong.
#
# Row 2 selector. CURRENT_BRANCH must be the LEFT OPERAND of the `=~`, not merely
# present somewhere on the line -- see the scan loop below for why.
$TestRe      = 'CURRENT_BRANCH\}?"?\s+=~'
$SavedLine   = $null
$AssignLine  = $null
$AssignCount = 0
$TestLine    = $null
$TestTail    = $null
$TestCount   = 0
if (Test-Path $Dest) {
    foreach ($line in @(Get-Content $Dest)) {
        if ($line -cmatch '^\s*#') { continue }
        # Row 1 selector. Deliberately wider than an anchored bare
        # `INTEGRATION_BRANCHES=`: an `export` prefix and leading indentation are
        # ordinary ways to write the same assignment, and a stricter selector
        # pushes those scripts into row 2 -- where the stock
        # `[[ ! "$CURRENT_BRANCH" =~ $INTEGRATION_BRANCHES ]]` line matches and the
        # literal variable reference gets captured as if it were the value. That
        # destroys the real setting and leaves the script fatal under `set -u`.
        if ($line -cmatch '^\s*(export\s+)?INTEGRATION_BRANCHES=') {
            $AssignCount++
            if ($AssignCount -eq 1) { $AssignLine = $line }
            continue
        }
        # Row 2 selector. CURRENT_BRANCH must be the LEFT OPERAND of the `=~`, not
        # merely present on the same line. prune-context.sh tests the cache TTL with
        # `=~` well before it tests the branch, so "first `=~` in the file" extracts
        # the TTL pattern -- and "the line mentions CURRENT_BRANCH and contains `=~`"
        # only narrows that, it does not close it. A line such as
        #   if [ -n "$CURRENT_BRANCH" ] && [[ "$CACHE_DAYS" =~ ^[0-9]+$ ]]; then
        # satisfies both substring tests independently while carrying no branch policy
        # at all, and reading it restores the TTL regex as the integration-branch list.
        # So require the name, an optional `}` and closing quote, whitespace, then
        # `=~`, with nothing else in between.
        #
        # Count matches, not `=~` occurrences: a compound condition
        # (`[[ ... =~ A ]] || [[ ... =~ B ]]`) carries two policies on one line, and
        # capturing only the first would silently drop the second. Each pass consumes
        # exactly the text it matched, so an unrelated `=~` elsewhere on the line
        # neither inflates the count nor shifts which operand gets read.
        #
        # Known edge of a textual scan, accepted deliberately: this reads lines, it
        # does not parse shell. A `CURRENT_BRANCH ... =~ ...` sequence that occurs
        # only inside a string literal -- say `echo "... $CURRENT_BRANCH =~ x ]] ..."`
        # -- is counted as a live branch test. Reaching that outcome requires the
        # decoy to be the file's ONLY such sequence, which means the script carries no
        # real branch policy to lose; and the alternative, parsing shell, is exactly
        # the guessing every refusal below declines to do.
        $rest = $line
        while ($rest -cmatch $TestRe) {
            $TestCount++
            $hit  = $matches[0]
            $rest = $rest.Substring($rest.IndexOf($hit) + $hit.Length)
            # Keep the whole line for diagnostics, but parse from the matched `=~`
            # onward -- parsing from the start of the line is what let an earlier,
            # unrelated `=~` supply the operand.
            if ($TestCount -eq 1) { $TestLine = $line; $TestTail = '=~' + $rest }
        }
    }

    if ($AssignCount -gt 1) {
        Write-Error "$Dest has $AssignCount live INTEGRATION_BRANCHES assignments. Which one is authoritative is a human decision, not a guess. Refusing to copy -- collapse them to a single assignment in $Dest, then re-run."
        exit 1
    }

    if ($AssignCount -eq 1) {
        # Row 1 -- a named INTEGRATION_BRANCHES assignment. Keep the whole line
        # verbatim: the value is a regex and must never be re-parsed or re-quoted.
        $SavedLine = $AssignLine
    } else {
        # Row 2 -- no named variable; recover the regex from the hardcoded =~ test.
        if ($TestCount -eq 0) {
            Write-Error "$Dest has no INTEGRATION_BRANCHES assignment and no branch test matching CURRENT_BRANCH ... =~ ..., so its integration-branch policy cannot be recovered. Refusing to copy -- the template default would silently replace whatever this repo actually intends. Fix by hand: add an explicit INTEGRATION_BRANCHES=`"<regex>`" line to $Dest naming this repo's integration branches, then re-run."
            exit 1
        }
        if ($TestCount -gt 1) {
            Write-Error "$Dest has $TestCount branch tests matching CURRENT_BRANCH ... =~ ... . Which one carries the integration-branch policy is a human decision, not a guess -- and a superseded test left behind in a trailing '# ...' comment counts, because telling a comment '#' from a literal '#' inside a regex is not something this step will guess at either. Refusing to copy. Fix by hand: delete the superseded test, or add an explicit INTEGRATION_BRANCHES=`"<regex>`" line to $Dest, then re-run."
            exit 1
        }
        $OldTest = $TestLine
        # The `=~` operand is the next whitespace-delimited word, and the closing `]]`
        # is a separate word. Whitespace *inside* an unquoted operand is not a syntax
        # error -- bash accepts `[[ $b =~ ^(main| dev)$ ]]`, and it matches -- but it
        # is legal only where paren depth is greater than zero. Such a line is still
        # refused, and the step that refuses it is the *parse* below, not the .NET
        # validity probe further down: the pattern requires the captured word to be
        # followed by whitespace and then `]]`, and on `^(main| dev)$ ]]` the word
        # `^(main|` is followed by `dev)$`, so the match fails outright and the
        # "could not parse" path fires. (The validity probe catches a different
        # shape -- one that parses cleanly but yields an unusable regex, such as a
        # truncated `^(main|rel-[0-9`.) That is what makes "take the word, then
        # require a whitespace-separated `]]`" safe, and why hunting for a `]]`
        # delimiter is not: hunting is what made the two shells disagree. Neither
        # the `]]` inside a bracket expression (^(main|v[]])$) nor the `]]` inside a
        # trailing `# see [[branching]]` comment is preceded by whitespace, so
        # neither can be mistaken for the closing token, on either shell.
        if ($TestTail -cnotmatch '=~\s*(\S+)\s+\]\]') {
            Write-Error "Could not parse the branch test in $Dest : $OldTest -- expected the form [[ ! `"`$CURRENT_BRANCH`" =~ <regex> ]]. Refusing to copy -- guessing here would discard this repo's integration-branch list. Add an explicit INTEGRATION_BRANCHES= line to $Dest by hand, then re-run."
            exit 1
        }
        $Candidate = $matches[1]
        # A bare variable reference is not a value. It means this script DOES keep
        # its policy in a named variable and row 1 is the right row -- so capturing
        # the reference would delete the real value and leave prune-context.sh
        # aborting on every commit with an unbound-variable error.
        if ($Candidate -cmatch '^\$\{?[A-Za-z_]') {
            Write-Error "The branch test in $Dest reads its pattern from a variable: $OldTest -- '$Candidate' is a reference, not a value, so this repo holds its integration-branch policy somewhere this step could not see. Writing the reference back would destroy the real value and make the script fail on every commit. Refusing to copy. Fix by hand: add an explicit INTEGRATION_BRANCHES=`"<regex>`" line to $Dest carrying this repo's real value, then re-run."
            exit 1
        }
        # Anything else that is not a self-contained literal regex. A quote makes the
        # test a literal-string comparison rather than a regex; a backtick, or a `$`
        # that is not a trailing or alternation anchor, is a shell expansion. Neither
        # can be re-emitted as an assignment without changing what it means.
        if (($Candidate -cmatch '["''`]') -or ($Candidate -cmatch '\$[^)|]')) {
            Write-Error "The branch pattern extracted from $Dest is not a plain regex: $Candidate -- it contains a quote, a backtick, or a shell expansion, so it cannot be re-emitted as an INTEGRATION_BRANCHES assignment without changing its meaning. Refusing to copy. Add an explicit INTEGRATION_BRANCHES=`"<regex>`" line to $Dest by hand, then re-run."
            exit 1
        }
        # Validate before writing. A bad capture must fail loud, not ship -- and the
        # runtime that consumes this value is bash, whose `[[ =~ ]]` is POSIX ERE.
        # .NET is not a stand-in for it in either direction, so this takes two steps.
        #
        # (a) .NET is STRICTER on one construct a branch regex legitimately uses:
        # POSIX lets a bracket expression open with a literal `]` (`[]]` matches a
        # right bracket) and .NET throws on it. Probe a normalized copy so a good
        # value is not refused here; the value written out is always the untouched
        # capture.
        $Probe = $Candidate -replace '\[(\^?)\]', '[$1\]'
        try {
            [void][System.Text.RegularExpressions.Regex]::new($Probe)
        } catch {
            Write-Error "The regex extracted from $Dest is not usable: $Candidate -- $_. Refusing to copy."
            exit 1
        }
        # (b) .NET is LOOSER across the whole PCRE surface that ERE has no meaning
        # for, and that is the dangerous direction: a pattern ERE rejects makes
        # `[[ ! "$b" =~ $BAD ]]` return 2, `!` inverts that to true, and
        # prune-context.sh takes its early `exit 0` -- pruning disabled repo-wide,
        # shipped by an upgrade that reported success, on PowerShell only. `(?:` and
        # `\d` are ordinary PCRE habits, not exotica.
        #
        # What the list below IS: a best-effort denylist for the PCRE constructs a
        # branch regex realistically picks up, measured against bash rather than
        # reasoned about. What it is NOT: a proof that PowerShell's accept-set is a
        # subset of bash's. Nothing here re-implements ERE, so a shape nobody
        # thought to test can still get through -- a misspelled POSIX class name
        # such as [[:foo:]] is one known survivor (.NET reads it as an ordinary
        # bracket expression; ERE rejects it outright). Treat this as a net with a
        # measured mesh size, not a closed boundary, and re-measure when adding to
        # it. A previous revision of this comment claimed the subset property, and
        # a sweep found 22 shapes that disproved it.
        #
        #   \(\?                     group extensions -- (?: , (?i) , (?<name> . A
        #                            `?` after `(` has nothing to quantify in ERE.
        #   (?<!\\)(?:\\\\)*\\       letter escapes -- \d , \A , \p . \w \W \s \S \b
        #     (?![wWsSbB])[A-Za-z]   \B are excepted: GNU ERE honours those with the
        #                            same meaning. The leading lookbehind and pair
        #                            run skip an ESCAPED backslash, so `c\\d` (a
        #                            literal `\` then `d`) stays accepted as bash
        #                            accepts it, while `\\\d` is still refused.
        #   ^[*+?{]                  a quantifier with nothing to bind, at the very
        #                            start of the pattern.
        #   [(|][*+?{]               ditto, directly after `(` or `|`.
        #   (?<!\[)\^[*+?{]          ditto, directly after a `^` ANYWHERE -- `(^*x)`
        #                            and `^(main|^*dev)$` are invalid too, not just
        #                            a leading `^*`. The lookbehind exempts a `^`
        #                            that opens a negated class, keeping `[^*]` and
        #                            `[^]]` accepted.
        #   [*+?}][*+?]              stacked quantifiers -- lazy `.+?` `a*?` `a??`
        #                            `{2,3}?` and possessive `.++` `?+`. .NET rejects
        #                            the possessive/nested forms on its own, but not
        #                            the lazy ones, which are the common PCRE habit.
        #   \{(?!\d+(?:,\d*)?\})     a `{` that does not open a well-formed ERE
        #                            interval -- {,3} , {2, , main{ , { 2} , {a} .
        #                            .NET falls back to treating such a `{` as a
        #                            literal; ERE errors.
        #   \(\| \|\| \|\)           an empty alternation branch, as left by deleting
        #                            one name from ^(main|develop)$ but not its `|`.
        #   ^\| , \|$                the same deletion written WITHOUT parentheses --
        #                            `main|` and `|develop`. INTEGRATION_BRANCHES=
        #                            "main|develop" is an ordinary way to write it,
        #                            so these edges are not an exotic case.
        #
        # Accepted cost: the two brace rules also refuse a branch regex that uses a
        # literal `{` or `}` (`^[{]$`, `^a\{b$`, `^a}?$`). Those are valid ERE, so
        # this is a real over-refusal -- but it is loud, it carries the same
        # fix-by-hand instruction as every other refusal, and a brace in a branch
        # name is far rarer than the eight brace typos the rule catches. Each is
        # refused loudly, so the consumer never receives a silent downgrade.
        $NotEre = @(
            '\(\?'
            '(?<!\\)(?:\\\\)*\\(?![wWsSbB])[A-Za-z]'
            '^[*+?{]'
            '[(|][*+?{]'
            '(?<!\[)\^[*+?{]'
            '[*+?}][*+?]'
            '\{(?!\d+(?:,\d*)?\})'
            '\(\||\|\||\|\)'
            '^\|'
            '\|$'
        )
        foreach ($bad in $NotEre) {
            if ($Candidate -cmatch $bad) {
                Write-Error "The regex extracted from $Dest uses a construct POSIX ERE has no meaning for: $Candidate (matched /$bad/). prune-context.sh evaluates it with bash's [[ =~ ]], which rejects it -- and a rejected pattern silently disables pruning repo-wide. .NET accepts it, so this check is what stops PowerShell shipping a value bash cannot run. Refusing to copy. Fix by hand: rewrite it as a POSIX ERE -- \d becomes [0-9], (?:...) becomes (...) -- in an explicit INTEGRATION_BRANCHES=`"<regex>`" line in $Dest, then re-run."
                exit 1
            }
        }
        # Single-quoted, byte-identical to what the bash twin writes. The value is
        # a regex, and double quotes would reinterpret the characters it is made of
        # -- `\\` collapses to `\`. The checks above have already refused anything
        # containing a single quote.
        $SavedLine = "INTEGRATION_BRANCHES='" + $Candidate + "'"
    }
}

# Refuse to copy if the copy would discard a value we cannot put back.
if ($SavedLine) {
    Write-Host "Preserving existing value: $SavedLine"
    if (-not (Get-Content $Src | Where-Object { $_ -clike 'INTEGRATION_BRANCHES=*' })) {
        Write-Error "$Src has no INTEGRATION_BRANCHES assignment to replace. Refusing to copy -- that would discard $SavedLine."
        exit 1
    }
} else {
    # Row 4 -- nothing to preserve.
    Write-Host "No existing INTEGRATION_BRANCHES found; set it from branching.md after the copy."
}

try {
    Copy-Item $Src $Dest -Force -ErrorAction Stop
} catch {
    # $_ and literal text only. Interpolating $Src here would re-dereference
    # $TEMPLATE_DIR -- the very variable whose absence is the likeliest reason
    # this catch was entered -- and under StrictMode that raises its own error,
    # abandons the whole try/catch statement, skips this `exit 1`, and lets
    # execution resume at the "Restored: ..." line below. The guard at the top of
    # this block makes that unreachable; keeping the message self-contained means
    # it stays unreachable even if someone runs this fence on its own.
    Write-Error "failed to copy the template prune-context.sh into $Dest : $_"
    exit 1
}

# Restore. $SavedLine is emitted through a MatchEvaluator, never as a -replace
# replacement string, where `$` and `\` would be reinterpreted -- and this value
# legitimately contains ^ $ ( ) | and may contain & or \.
#
# Read and rewrite the whole file as text rather than round-tripping it through
# Get-Content: Get-Content discards each line's terminator, and rejoining on "`n"
# silently rewrites a CRLF file to LF. On a Windows checkout the template itself
# is CRLF (`git ls-files --eol` reports prune-context.sh as `i/lf w/crlf`, and
# core.autocrlf=true is the default), so normalizing here would make the restore
# path disagree with the plain-copy path one row above it, and with the bash twin.
# `[^\r\n]*` stops before the terminator, so the destination's own line endings --
# and every other byte in the file -- survive untouched.
if ($SavedLine) {
    $Path = (Resolve-Path $Dest).Path
    $Tmp  = "$Path.tmp"
    try {
        $raw = [System.IO.File]::ReadAllText($Path)
        $new = [System.Text.RegularExpressions.Regex]::Replace(
                   $raw, '(?m)^INTEGRATION_BRANCHES=[^\r\n]*', { $SavedLine })
        # Write a temp file and move it into place, matching the bash twin: a
        # failure part-way through WriteAllText on the live path would leave a
        # truncated prune-context.sh behind an error message that only mentions
        # INTEGRATION_BRANCHES.
        [System.IO.File]::WriteAllText($Tmp, $new)
        Move-Item -LiteralPath $Tmp -Destination $Path -Force -ErrorAction Stop
    } catch {
        # Report and exit FIRST; clean up afterwards, inside its own try/catch.
        # Cleanup ahead of the report is what made this catch fail open: if
        # Remove-Item throws -- $Tmp occupied by a non-empty directory is enough --
        # the terminating error abandons the whole try/catch statement, the
        # `exit 1` never runs, and execution resumes at the "Restored: ..." line
        # below, reporting the consumer's value as preserved while the file on
        # disk carries the template default. The report must not depend on the
        # cleanup succeeding.
        Write-Error "failed to restore INTEGRATION_BRANCHES in $Dest ($SavedLine): $_"
        try {
            if (Test-Path $Tmp) { Remove-Item -LiteralPath $Tmp -Force -ErrorAction Stop }
        } catch {
            Write-Error "additionally, the temporary file $Tmp could not be removed: $_"
        }
        exit 1
    }
    Write-Host "Restored: $SavedLine"
}
```

For any missing new required files, run the git log analysis from `initialize-repo`
Step 1a to create them with real examples:

```bash
git log --oneline -50   # commit format → commit-conventions.md
git branch -r           # branch naming  → branching.md
```

Once `branching.md` exists — **whether it was already present or you just created it
above** — set `INTEGRATION_BRANCHES` in `prune-context.sh` to match the integration
branches it documents, but **only if the pruning-script step above took the "neither
present" row** (it reported `No existing INTEGRATION_BRANCHES found`). This is that
row's deferred second half, not a separate instruction, and it is **not** conditional
on `branching.md` being one of the files this upgrade created. A repo whose
`prune-context.sh` was absent but whose `branching.md` was already present still needs
it; skip it there and the broad template default `^(main|master|dev|develop|trunk)$`
ships, re-arming task pruning on `dev`/`develop`/`trunk` in a repo that may never have
decided to allow it.

If a value **was** preserved (the step reported `Preserving existing value:` and
`Restored:`), leave it alone. The installed value is the repo's own answer; `branching.md`
was just derived from the same git history and is not a more authoritative source. Writing
it here would undo the restore that step performed and reintroduce the exact data loss the
extract → copy → restore sequence exists to prevent.

If `.context/.gitignore` is missing, copy it from the template:

```bash
cp "$TEMPLATE_DIR/context/.gitignore" .context/ || {
  echo "ERROR: failed to copy the template .gitignore into .context/" >&2
  echo "       Re-run the find-context-template guard and fix TEMPLATE_DIR." >&2
  exit 1
}
```

**Ensure root-level `.gitattributes`**

Migrate the repo to a root-level `.gitattributes` giving retrospective logs the
`union` merge driver. The grep-before-append guard is idempotent and preserves
pre-existing entries (Pattern D — create if absent, append if missing, skip if present):

```bash
# Ensure repo-root .gitattributes gives retrospective logs a union merge driver,
# so concurrent retrospective appends across branches merge cleanly instead of
# conflicting. Idempotent — safe to re-run.
#
# Both the path lookup and the append are checked. An unchecked `git rev-parse`
# yields an empty ROOT and turns the target into the filesystem-root
# `/.gitattributes`, and an unconditional success echo after the append reports
# "Ensured ..." even when the redirection never wrote a byte.
ROOT=$(git rev-parse --show-toplevel) || {
  echo "ERROR: git rev-parse --show-toplevel failed — not inside a git work tree." >&2
  echo "       Refusing to guess a repository root." >&2
  exit 1
}
if [ -z "$ROOT" ]; then
  echo "ERROR: git rev-parse --show-toplevel returned an empty path; refusing to" >&2
  echo "       write .gitattributes at the filesystem root." >&2
  exit 1
fi
GA="$ROOT/.gitattributes"
if [ -f "$GA" ] && grep -qF 'retrospectives.md' "$GA"; then
  echo ".gitattributes: retrospective union-merge entries already present — skipped"
elif {
    printf '\n# ICON retrospective logs are append-mostly; the union merge driver keeps\n'
    printf '# both sides'"'"' entries instead of conflicting on concurrent appends.\n'
    printf 'retrospectives.md          merge=union\n'
    printf 'retrospectives-archive.md  merge=union\n'
  } >> "$GA"; then
  echo "Ensured retrospective union-merge entries in $GA"
else
  echo "ERROR: failed to append retrospective union-merge entries to $GA" >&2
  exit 1
fi
```

If `.context/iconrc.json` is absent, invoke the `create-iconrc` skill to generate it.

**`iconrc.json` schema version update**: if the file is present and its `version` field is behind the template, update only that field — all customized values (`excludes`, `local_task_id_prefix`, etc.) are preserved:

```bash
TEMPLATE_VER=$(grep '"version"' "$TEMPLATE_DIR/context/iconrc.json" | grep -oE '[0-9.]+')
INSTALLED_VER=$(grep '"version"' .context/iconrc.json | grep -oE '[0-9.]+')
# An unreadable template (bad $TEMPLATE_DIR) yields an empty TEMPLATE_VER. Without
# this guard the comparison below is true, sed and mv both succeed, and the block
# writes "version": "" into the consumer's file while reporting success.
if [ -z "$TEMPLATE_VER" ] || [ -z "$INSTALLED_VER" ]; then
  echo "ERROR: could not read a version from the template or the installed iconrc.json — aborting before an empty version is written" >&2
  exit 1
fi
if [ "$INSTALLED_VER" != "$TEMPLATE_VER" ]; then
  INSTALLED_VER_RE=${INSTALLED_VER//./[.]}
  if sed "s/\"version\": \"$INSTALLED_VER_RE\"/\"version\": \"$TEMPLATE_VER\"/" .context/iconrc.json > .context/iconrc.json.tmp && mv .context/iconrc.json.tmp .context/iconrc.json; then
    echo "iconrc.json version: $INSTALLED_VER → $TEMPLATE_VER"
  else
    rm -f .context/iconrc.json.tmp
    echo "ERROR: failed to update iconrc.json version ($INSTALLED_VER → $TEMPLATE_VER)" >&2
    exit 1
  fi
else
  echo "iconrc.json version: already at $INSTALLED_VER"
fi
```

```powershell
# Same StrictMode-safe $TEMPLATE_DIR guard as the prune-context.sh step above --
# see there for why the three clauses must stay in this order. Without it, a
# never-set $TEMPLATE_DIR abandons the assignment below, and every later
# reference to $TemplateVer abandons its own statement in turn, so the whole
# block does nothing at exit 0 and the version silently never updates -- while
# the bash twin exits 1. Same repo, two shells, two outcomes.
$TemplateDirShown = if (Test-Path Variable:\TEMPLATE_DIR) { "[$TEMPLATE_DIR]" } else { '[<unset>]' }
if (-not (Test-Path Variable:\TEMPLATE_DIR) -or [string]::IsNullOrWhiteSpace($TEMPLATE_DIR) -or -not (Test-Path -LiteralPath (Join-Path $TEMPLATE_DIR 'context') -PathType Container)) {
    Write-Error "`$TEMPLATE_DIR does not resolve to a context template: $TemplateDirShown -- run find-context-template (Discovery Command + Validate) and halt on its non-zero exit before re-running this step."
    exit 1
}

$TemplateVer = (Get-Content "$TEMPLATE_DIR\context\iconrc.json" | ConvertFrom-Json).version
$InstalledVer = (Get-Content ".context\iconrc.json" | ConvertFrom-Json).version
# Same guard as the bash branch: an unreadable or malformed iconrc.json yields a
# null version, and the comparison below would then write "version": "" while
# reporting success.
if ([string]::IsNullOrWhiteSpace($TemplateVer) -or [string]::IsNullOrWhiteSpace($InstalledVer)) {
    Write-Error "could not read a version from the template or the installed iconrc.json - aborting before an empty version is written"
    exit 1
}
if ($InstalledVer -ne $TemplateVer) {
    # Escape the installed version before it is used as a regex: an unescaped `.`
    # is a metacharacter, so the pattern built for "1.2" also matches "1x2".
    $InstalledVerRe = [regex]::Escape($InstalledVer)
    # `$` is a substitution metacharacter on the REPLACEMENT side, so escaping the
    # pattern is not enough -- double it so the version is emitted literally.
    $TemplateVerLit = $TemplateVer -replace '\$', '$$$$'
    try {
        ((Get-Content ".context\iconrc.json") -replace `
            """version"": ""$InstalledVerRe""", `
            """version"": ""$TemplateVerLit""") | Set-Content ".context\iconrc.json" -ErrorAction Stop
    } catch {
        # Without this the block prints the success line below even when
        # Set-Content failed (read-only file, lock, encoding error).
        Write-Error "failed to update iconrc.json version ($InstalledVer -> $TemplateVer): $_"
        exit 1
    }
    Write-Host "iconrc.json version: $InstalledVer → $TemplateVer"
} else {
    Write-Host "iconrc.json version: already at $InstalledVer"
}
```

**`local_task_id_prefix` collision (manual resolution)** — if Phase 1 flagged the
local prefix as colliding with a detected external ticket prefix, this upgrade does
not rewrite the field. Resolution is a manual choice: the user re-invokes
`create-iconrc` with the new prefix, passing the `EXTERNAL_PREFIXES` set the Phase 1
Special check produced as `create-iconrc`'s `forbidden_prefixes` argument
(`skills/create-iconrc/SKILL.md:49`), once they have decided on a replacement.

**New: Install task-plan phase templates**

Process `.context/workflows/task-plan/` as follows. These files are team-customizable;
use the version-marker-aware logic below — never auto-overwrite an existing file.

| File | Condition | Action |
|------|-----------|--------|
| Any phase file | Not present | Copy from template — always safe (new addition) |
| Any phase file | Present, version matches | Skip — already current |
| Any phase file | Present, version differs | Flag for human review; do NOT overwrite |
| `base.md` specifically | Present, no version marker | Flag for human review; do NOT overwrite |

```bash
# Install task-plan phase templates
TASK_PLAN_DIR=".context/workflows/task-plan"
TASK_PLAN_TEMPLATE="$TEMPLATE_DIR/context/workflows/task-plan"

# Guard the source before anything reports success. With an unresolved
# $TEMPLATE_DIR the glob below expands to nothing, `cp` fails, and the
# unconditional echo that used to follow reported "Installed: ... (6 files)"
# over an empty directory at exit 0.
if [ ! -d "$TASK_PLAN_TEMPLATE" ]; then
  echo "ERROR: task-plan template directory not found: $TASK_PLAN_TEMPLATE" >&2
  echo "       Re-run the find-context-template guard and fix TEMPLATE_DIR." >&2
  exit 1
fi

if [ ! -d "$TASK_PLAN_DIR" ]; then
  mkdir -p "$TASK_PLAN_DIR" || {
    echo "ERROR: could not create $TASK_PLAN_DIR" >&2
    exit 1
  }
  cp "$TASK_PLAN_TEMPLATE/"*.md "$TASK_PLAN_DIR/" || {
    echo "ERROR: failed to copy the task-plan phase templates into $TASK_PLAN_DIR" >&2
    exit 1
  }
  # Report what actually landed rather than a hardcoded count.
  echo "Installed: $TASK_PLAN_DIR ($(find "$TASK_PLAN_DIR" -name '*.md' | wc -l | tr -d ' ') files)"
else
  for FILE in base.md phase-investigation.md phase-architecture.md \
              phase-implementation.md phase-testing.md phase-completion.md; do
    TARGET="$TASK_PLAN_DIR/$FILE"
    SOURCE="$TASK_PLAN_TEMPLATE/$FILE"
    if [ ! -f "$TARGET" ]; then
      cp "$SOURCE" "$TARGET" || {
        echo "ERROR: failed to copy $SOURCE to $TARGET" >&2
        exit 1
      }
      echo "Installed: $TARGET"
    else
      INSTALLED=$(grep -m1 'template-version:' "$TARGET" \
                  | sed 's/.*template-version: //' | sed 's/[[:space:]]*-->.*//')
      CURRENT=$(grep -m1 'template-version:' "$SOURCE" \
                | sed 's/.*template-version: //' | sed 's/[[:space:]]*-->.*//')
      if [ "$INSTALLED" != "$CURRENT" ]; then
        echo "REVIEW REQUIRED: $TARGET (installed: $INSTALLED, template: $CURRENT)"
      fi
      # No action if versions match — file is already current
    fi
  done
fi
```

```powershell
# Install task-plan phase templates
#
# Same StrictMode-safe $TEMPLATE_DIR guard as the prune-context.sh step above --
# see there for why the three clauses must stay in this order. Without it, a
# never-set $TEMPLATE_DIR abandons the $TaskPlanTemplate assignment, Copy-Item
# then abandons its own statement, and "Installed: ... (6 files)" printed over a
# freshly-created EMPTY directory at exit 0.
$TemplateDirShown = if (Test-Path Variable:\TEMPLATE_DIR) { "[$TEMPLATE_DIR]" } else { '[<unset>]' }
if (-not (Test-Path Variable:\TEMPLATE_DIR) -or [string]::IsNullOrWhiteSpace($TEMPLATE_DIR) -or -not (Test-Path -LiteralPath (Join-Path $TEMPLATE_DIR 'context') -PathType Container)) {
    Write-Error "`$TEMPLATE_DIR does not resolve to a context template: $TemplateDirShown -- run find-context-template (Discovery Command + Validate) and halt on its non-zero exit before re-running this step."
    exit 1
}

$TaskPlanDir = ".context\workflows\task-plan"
$TaskPlanTemplate = "$TEMPLATE_DIR\context\workflows\task-plan"

if (-not (Test-Path $TaskPlanTemplate -PathType Container)) {
    Write-Error "task-plan template directory not found: $TaskPlanTemplate. Re-run the find-context-template guard and fix TEMPLATE_DIR."
    exit 1
}

if (-not (Test-Path $TaskPlanDir)) {
    try {
        # `$null =` discards the DirectoryInfo that New-Item returns; it suppresses
        # nothing else. Errors stay visible and are made terminating by
        # -ErrorAction Stop, so the catch below sees them.
        $null = New-Item -ItemType Directory -Force -Path $TaskPlanDir -ErrorAction Stop
        Copy-Item "$TaskPlanTemplate\*.md" $TaskPlanDir -ErrorAction Stop
    } catch {
        Write-Error "failed to install the task-plan phase templates into $TaskPlanDir : $_"
        exit 1
    }
    # Report what actually landed rather than a hardcoded count.
    $Landed = @(Get-ChildItem -Path $TaskPlanDir -Filter '*.md' -File).Count
    if ($Landed -eq 0) {
        Write-Error "the task-plan template copy reported no error but $TaskPlanDir is empty. Refusing to report success."
        exit 1
    }
    Write-Host "Installed: $TaskPlanDir ($Landed files)"
} else {
    $Files = @(
        "base.md", "phase-investigation.md", "phase-architecture.md",
        "phase-implementation.md", "phase-testing.md", "phase-completion.md"
    )
    foreach ($File in $Files) {
        $Target = Join-Path $TaskPlanDir $File
        $Source = Join-Path $TaskPlanTemplate $File
        if (-not (Test-Path $Target)) {
            Copy-Item $Source $Target
            Write-Host "Installed: $Target"
        } else {
            $GetVer = { param($Path)
                (Select-String -Path $Path -Pattern 'template-version:' |
                 Select-Object -First 1).Line `
                     -replace '.*template-version:\s*', '' `
                     -replace '\s*-->', '' `
                     -replace '\s', ''
            }
            $Installed = & $GetVer $Target
            $Current   = & $GetVer $Source
            if ($Installed -ne $Current) {
                Write-Host "REVIEW REQUIRED: $Target (installed: $Installed, template: $Current)"
            }
            # No action if versions match
        }
    }
}
```

**New: Restore `decisions/` if absent**

If Phase 1 reported `decisions/` as missing — and `decisions` is **not** in `excludes` — restore it from the template before generating `rules-index.md` below. This is not a bare `mkdir`: `decisions/` ships with template content — the decision-log index that explains the ADR numbering and status conventions — and an empty directory would produce a `rules-index.md` with no ADR section.

Skip this step entirely if the directory already exists (including the case where the flat-file migration above just created it), or if `decisions` is listed in `excludes`.

The copy is checked. An unresolvable `$TEMPLATE_DIR` is exactly the case the `find-context-template` guard exists to stop, so reaching here with one means the guard was skipped — and reporting `Restored:` anyway is the ticket's own headline symptom. It is not a recoverable miss either: `rules-index.md` is generated next and is **never overwritten once created**, so a silent no-op here bakes an ADR-less index into the repo permanently.

```bash
if [ ! -d ".context/decisions" ]; then
  cp -r "$TEMPLATE_DIR/context/decisions" .context/ || {
    echo "ERROR: failed to copy $TEMPLATE_DIR/context/decisions into .context/" >&2
    echo "       Halting -- rules-index.md is generated next and is never" >&2
    echo "       overwritten, so continuing would bake in an ADR-less index." >&2
    echo "       Re-run the find-context-template guard and fix TEMPLATE_DIR." >&2
    exit 1
  }
  # Confirm the outcome rather than trusting cp's exit status alone: this
  # message is the operator's only evidence the ADRs are in place.
  if [ ! -d ".context/decisions" ]; then
    echo "ERROR: cp reported success but .context/decisions is still absent." >&2
    echo "       Halting -- rules-index.md is generated next and is never" >&2
    echo "       overwritten, so continuing would bake in an ADR-less index." >&2
    exit 1
  fi
  echo "Restored: .context/decisions/ (from template)"
fi
```

```powershell
# Same StrictMode-safe $TEMPLATE_DIR guard as the prune-context.sh step above --
# see there for why the three clauses must stay in this order. It runs before
# $TEMPLATE_DIR is dereferenced anywhere below, including inside the catch.
$TemplateDirShown = if (Test-Path Variable:\TEMPLATE_DIR) { "[$TEMPLATE_DIR]" } else { '[<unset>]' }
if (-not (Test-Path Variable:\TEMPLATE_DIR) -or [string]::IsNullOrWhiteSpace($TEMPLATE_DIR) -or -not (Test-Path -LiteralPath (Join-Path $TEMPLATE_DIR 'context') -PathType Container)) {
    Write-Error "`$TEMPLATE_DIR does not resolve to a context template: $TemplateDirShown -- run find-context-template (Discovery Command + Validate) and halt on its non-zero exit before re-running this step. Refusing to continue, because rules-index.md is generated next and is never overwritten."
    exit 1
}

if (-not (Test-Path ".context\decisions")) {
    try {
        Copy-Item "$TEMPLATE_DIR\context\decisions" .context\ -Recurse -ErrorAction Stop
    } catch {
        # $_ and literal text only -- no $TEMPLATE_DIR. Interpolating it here
        # re-dereferences the variable whose absence is the likeliest reason this
        # catch was entered; under StrictMode that raises its own error, abandons
        # the try/catch statement, skips this `exit 1`, and drops through to the
        # "Restored: ..." line below -- reporting a restore that never happened,
        # which is this ticket's own headline symptom.
        Write-Error "failed to copy the template decisions/ directory into .context\ : $_ -- halting, because rules-index.md is generated next and is never overwritten, so continuing would bake in an ADR-less index. Re-run the find-context-template guard and fix TEMPLATE_DIR."
        exit 1
    }
    # Confirm the outcome rather than trusting the absence of an exception:
    # this message is the operator's only evidence the ADRs are in place.
    if (-not (Test-Path ".context\decisions" -PathType Container)) {
        Write-Error "the copy of the template decisions/ directory reported no error but .context\decisions is still absent. Halting -- rules-index.md is generated next and is never overwritten."
        exit 1
    }
    Write-Host "Restored: .context/decisions/ (from template)"
}
```

**New: Generate `rules-index.md` if absent**

`.context/rules-index.md` is an on-demand router into `standards/`/`workflows/`/`decisions/`. **Create it only if absent — NEVER overwrite an existing copy.** Unlike the template-versioned infrastructure files above, it is not version-markered: it derives from the repo's own rule files, so the installed copy is always the source of truth.

If missing, generate it by scanning the three directories and building the three-section table per `context-specialist-impl-leaf` Step 4.5 — one row per top-level `standards/`/`workflows/` file (a parent row for an indexed sub-directory), one row per `decisions/NNN-*.md` ADR, each with an "Applies when…" trigger and a link. If present, skip.

**New: Emit the `## Related` graph seam**

The content docs under `domains/`, `standards/`, `workflows/`, `architecture/`, `testing/`, and `styling/` feed the `.context/` knowledge graph. A repo initialized before the seam shipped carries none of the footers, so `context-graph --check` fails closed on the orphan flood Phase 1 reported and every later `context-maintenance` run aborts on it before reporting anything else. Close the seam for the docs Phase 1 flagged:

1. **Clear each flagged doc by giving it an *inbound* link — the footer goes on the doc that names it, not on the orphan.** Orphan status turns on the in-edge: a `## Related` section creates out-edges, so a doc stops being an orphan only when *something else* links to it. Clear an orphaned domain file by adding a link to it in the footer of whichever doc's body mentions it — the architecture or testing doc, say — not by giving the orphan a footer of its own. Reciprocal links are normal and fine, but work the flagged list inbound or docs will stay orphaned after every one of them has a footer.
   **Footer mechanics**: append the `## Related` section as the LAST `## ` section of the doc that carries it, built from cross-references **already named in that doc's own body** — by-name mentions, shared subject matter. Use bulleted `label: [text](path)` links. Do not manufacture links from template wording or from directory adjacency: a footer of tenuous cross-references pollutes the graph the seam exists to serve.
2. **Never overwrite an existing `## Related` section** — append only where absent, and preserve any pre-existing footer verbatim, wording and link set alike.
3. **Do not append a footer to an ADR.** `decisions/NNN-*.md` files are orphan-checked but earn reachability from `rules-index.md` rows and from `**Supersedes**` / `**Superseded-by**` bold-fields — emit those instead where a supersede relationship exists.
4. A doc that **no other doc's body names** — so no honest footer anywhere can give it an in-edge — takes a file-level `<!-- context-graph:orphan-ok -->` marker instead of a fabricated one. This is the usual fate of an untouched scaffold, and of a corner of the repo nothing else cross-references. Use it sparingly: if a large share of the flagged list needs it, the docs are under-linked and that is the finding to report, not something to paper over.

Follow `context-document-guidelines` § Related Section (graph seam) for the exact format, placement, ADR bold-field convention, and the sparing use of escape-hatch markers — do not restate it here.

**Termination condition**: re-run `context-graph --check` until it exits 0. The goal is a green graph, **not** a footer on every file — a doc already reachable through a `rules-index.md` row or a folder `README.md` index is not an orphan and needs no footer. This step runs after the `rules-index.md` generation above for exactly that reason: index rows are reachability edges, so generating the index first shrinks the set that still needs one.

### upgrade-repo: Phase 3: Content Currency (delegate)

Infrastructure and content currency are separate concerns. After upgrading infrastructure, run the **content-currency sample check** below; only invoke `context-maintenance` if the sample indicates real drift. Do not touch `META.md`, `retrospectives.md`, or `tasks/` in this delegation.

**Content-currency sample check** (canonical spec — orchestrators reference this section):

Spot-check 5 random class/function/type names or file paths from `.context/domains/*.md` against the codebase with `grep`. If at least 2 of the 5 are absent, invoke `context-maintenance` for a full audit; otherwise skip the content refresh. `context-maintenance` owns the full content refresh when invoked.

### upgrade-repo: Phase 4: Verify and Commit

1. `prune-context.sh` contains an `INTEGRATION_BRANCHES` matching this repo's real integration branches — if the upgrade replaced the script, confirm the pre-upgrade value was restored, not the template default `^(main|master|dev|develop|trunk)$`.
2. `.githooks/post-commit` is executable
3. `git config core.hooksPath` is set
4. `commit-conventions.md` and `branching.md` exist with real content
5. Flag any remaining gaps rather than leaving shallow docs
6. Root-level `claude.md` exists, or its creation was declined at the Phase 0 prompt.
7. `.context/iconrc.json` `version` field matches the template
8. `.context/rules-index.md` exists (generated during this upgrade if it was absent)
9. Root-level `.gitattributes` contains `merge=union` for both retrospective files.
10. `context-graph --check` exits 0 for `.context/` — no dangling references and no orphan content docs. A footer on every file is not the bar; a green graph is.

Commit using this repo's format from `commit-conventions.md`.

## Retrospectives File Migration

Older repos have a `retrospectives.md` with a preamble and a `## Log` header before
the first entry. The current format starts directly with the first `### ` entry —
no preamble, no `## Log` heading.

**To migrate a repo**:

1. Open `.context/retrospectives.md`.
2. Delete everything from the top through and including the `## Log` line and its
   following blank line, leaving the first `### ` entry as line 1.
3. If the file has no `### ` entries yet (only the template placeholder), replace the
   whole file with just the trailing HTML comment:
   ```
   <!-- New entries go here, above older entries. Remove entries older than the 10th. -->
   ```

One-time migration. No script — the deletion is a targeted manual edit (or a 2-line
`sed` command targeting the specific heading).

## Common Mistakes

| Mistake | Fix |
|---|---|
| Resetting `INTEGRATION_BRANCHES` to generic defaults | Extract old regex first, preserve it |
| Invoking `context-maintenance` when infrastructure was the only concern | Only delegate to `context-maintenance` if documentation drift is actually present |
| Updating `decisions/` without confirmation | Decisions are intentional — show diff first |
| Running Phase 2 without the audit report | Audit first; surprises in the report may change the plan |

