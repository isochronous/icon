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
Copilot CLI users.

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

Skip silently if `claude.md` already exists.

**Case 3 note** — if `.claude/claude.md` does not exist: *Redirect not created — `.claude/claude.md` must exist first. Create it and re-run `upgrade-repo`.*

---

### upgrade-repo: Phase 1: Audit (no changes yet)

Invoke `find-context-template` to locate the template directory and establish `$TEMPLATE_DIR`.

Read `.context/iconrc.json` if it exists and extract the `excludes` array (empty if absent or no `excludes` key). Any directory named in `excludes` is intentionally omitted — never flag it as missing or create/update it in any later phase.

Check and report:
- **Infrastructure files**: `prune-context.sh`, `.githooks/post-commit` — present and current?
- **Directories**: all of `standards/ architecture/ testing/ tasks/ workflows/ domains/ styling/` exist? *(Skip any in `excludes` — intentionally absent.)*

**Special check — deprecated `task-workflow-template.md`**

`task-workflow-template.md` is replaced by the per-phase templates in
`.context/workflows/task-plan/`. If present, remove it during this upgrade — but
only after migrating any team customizations to the phase files. Compare against
the stock reference to decide whether migration is required first.

```bash
if [ -f ".context/workflows/task-workflow-template.md" ]; then
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
- **`local_task_id_prefix` collision check**: read the current value; sample commits with `git log --oneline -100`; extract any `[A-Za-z]{2,}-\d+` ticket-prefix patterns (case-insensitive, to catch a team that started lowercase); if the local prefix matches one (case-insensitive), report a finding (`Local prefix '<X>' collides with detected external ticket prefix '<X>' — recommend changing to 'LOCAL' or another distinct value`). Reporting only — Phase 2 does not auto-rewrite the field.
- **Task plan phase templates**: does `.context/workflows/task-plan/` exist? If yes,
  report which of the 6 phase files are present and their `<!-- template-version: X.Y -->`
  markers. If absent, note it as "awaiting installation" — a new addition, not a
  critical missing file.
- **Hook wiring**: `git config --get core.hooksPath` points at `.githooks/`?
- **Root-level `.gitattributes`**: present, with `merge=union` for the retrospective files (`retrospectives.md`, `retrospectives-archive.md`)?

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

**Special case — `prune-context.sh` pre-`INTEGRATION_BRANCHES`** (or a still-present
legacy `prune-old-tasks.sh`): if the old script uses a hardcoded `=~` regex without
a named variable, extract that regex, copy the new script, and set
`INTEGRATION_BRANCHES` to the extracted value — do not reset to the generic default.
If a legacy `prune-old-tasks.sh` is present in `.context/workflows/`, `git mv` it to
`prune-context.sh` so the `.githooks/post-commit` reference resolves. (If heavily
customized and you want the rename + overwrite in the diff, `git rm` it instead before
copying.) Then run the standard
`cp $TEMPLATE_DIR/context/workflows/prune-context.sh .context/workflows/` — the rename
preserves the hook reference; the copy overwrites stale logic with the current template.

For any missing new required files, run the git log analysis from `initialize-repo`
Step 1a to create them with real examples:

```bash
git log --oneline -50   # commit format → commit-conventions.md
git branch -r           # branch naming  → branching.md
```

After creating `branching.md`, update `INTEGRATION_BRANCHES` in
`prune-context.sh` to match the integration branches it documents.

If `.context/.gitignore` is missing, copy it from the template:

```bash
cp "$TEMPLATE_DIR/context/.gitignore" .context/
```

**Ensure root-level `.gitattributes`**

Migrate the repo to a root-level `.gitattributes` giving retrospective logs the
`union` merge driver. The grep-before-append guard is idempotent and preserves
pre-existing entries (Pattern D — create if absent, append if missing, skip if present):

```bash
# Ensure repo-root .gitattributes gives retrospective logs a union merge driver,
# so concurrent retrospective appends across branches merge cleanly instead of
# conflicting. Idempotent — safe to re-run.
ROOT=$(git rev-parse --show-toplevel)
GA="$ROOT/.gitattributes"
if [ -f "$GA" ] && grep -qF 'retrospectives.md' "$GA"; then
  echo ".gitattributes: retrospective union-merge entries already present — skipped"
else
  {
    printf '\n# ICON retrospective logs are append-mostly; the union merge driver keeps\n'
    printf '# both sides'"'"' entries instead of conflicting on concurrent appends.\n'
    printf 'retrospectives.md          merge=union\n'
    printf 'retrospectives-archive.md  merge=union\n'
  } >> "$GA"
  echo "Ensured retrospective union-merge entries in $GA"
fi
```

If `.context/iconrc.json` is absent, invoke the `create-iconrc` skill to generate it.

**`iconrc.json` schema version update**: if the file is present and its `version` field is behind the template, update only that field — all customized values (`excludes`, `local_task_id_prefix`, etc.) are preserved:

```bash
TEMPLATE_VER=$(grep '"version"' "$TEMPLATE_DIR/context/iconrc.json" | grep -oP '[\d.]+')
INSTALLED_VER=$(grep '"version"' .context/iconrc.json | grep -oP '[\d.]+')
if [ "$INSTALLED_VER" != "$TEMPLATE_VER" ]; then
  sed -i "s/\"version\": \"$INSTALLED_VER\"/\"version\": \"$TEMPLATE_VER\"/" .context/iconrc.json
  echo "iconrc.json version: $INSTALLED_VER → $TEMPLATE_VER"
else
  echo "iconrc.json version: already at $INSTALLED_VER"
fi
```

```powershell
$TemplateVer = (Get-Content "$TEMPLATE_DIR\context\iconrc.json" | ConvertFrom-Json).version
$InstalledVer = (Get-Content ".context\iconrc.json" | ConvertFrom-Json).version
if ($InstalledVer -ne $TemplateVer) {
    (Get-Content ".context\iconrc.json") -replace `
        """version"": ""$InstalledVer""", `
        """version"": ""$TemplateVer""" | Set-Content ".context\iconrc.json"
    Write-Host "iconrc.json version: $InstalledVer → $TemplateVer"
} else {
    Write-Host "iconrc.json version: already at $InstalledVer"
}
```

**`local_task_id_prefix` collision (manual resolution)** — if Phase 1 flagged the
local prefix as colliding with a detected external ticket prefix, this upgrade does
not rewrite the field. Resolution is a manual choice: the user re-invokes
`create-iconrc` with the new prefix (and `forbidden_prefixes` populated from the audit
finding) once they have decided on a replacement.

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

if [ ! -d "$TASK_PLAN_DIR" ]; then
  mkdir -p "$TASK_PLAN_DIR"
  cp "$TASK_PLAN_TEMPLATE/"*.md "$TASK_PLAN_DIR/"
  echo "Installed: $TASK_PLAN_DIR (6 files)"
else
  for FILE in base.md phase-investigation.md phase-architecture.md \
              phase-implementation.md phase-testing.md phase-completion.md; do
    TARGET="$TASK_PLAN_DIR/$FILE"
    SOURCE="$TASK_PLAN_TEMPLATE/$FILE"
    if [ ! -f "$TARGET" ]; then
      cp "$SOURCE" "$TARGET"
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
$TaskPlanDir = ".context\workflows\task-plan"
$TaskPlanTemplate = "$TEMPLATE_DIR\context\workflows\task-plan"

if (-not (Test-Path $TaskPlanDir)) {
    New-Item -ItemType Directory -Force -Path $TaskPlanDir | Out-Null
    Copy-Item "$TaskPlanTemplate\*.md" $TaskPlanDir
    Write-Host "Installed: $TaskPlanDir (6 files)"
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

**New: Generate `rules-index.md` if absent**

`.context/rules-index.md` is an on-demand router into `standards/`/`workflows/`/`decisions/`. **Create it only if absent — NEVER overwrite an existing copy.** Unlike the template-versioned infrastructure files above, it is not version-markered: it derives from the repo's own rule files, so the installed copy is always the source of truth.

If missing, generate it by scanning the three directories and building the three-section table per `context-specialist-impl-leaf` Step 4.5 — one row per top-level `standards/`/`workflows/` file (a parent row for an indexed sub-directory), one row per `decisions/NNN-*.md` ADR, each with an "Applies when…" trigger and a link. If present, skip.

### upgrade-repo: Phase 3: Content Currency (delegate)

Infrastructure and content currency are separate concerns. After upgrading infrastructure, run the **content-currency sample check** below; only invoke `context-maintenance` if the sample indicates real drift. Do not touch `META.md`, `retrospectives.md`, or `tasks/` in this delegation.

**Content-currency sample check** (canonical spec — orchestrators reference this section):

Spot-check 5 random class/function/type names or file paths from `.context/domains/*.md` against the codebase with `grep`. If at least 2 of the 5 are absent, invoke `context-maintenance` for a full audit; otherwise skip the content refresh. `context-maintenance` owns the full content refresh when invoked.

### upgrade-repo: Phase 4: Verify and Commit

1. `prune-context.sh` contains a correct `INTEGRATION_BRANCHES` value
2. `.githooks/post-commit` is executable
3. `git config core.hooksPath` is set
4. `commit-conventions.md` and `branching.md` exist with real content
5. Flag any remaining gaps rather than leaving shallow docs
6. Root-level `claude.md` exists
7. `.context/iconrc.json` `version` field matches the template
8. `.context/rules-index.md` exists (generated during this upgrade if it was absent)
9. Root-level `.gitattributes` contains `merge=union` for both retrospective files.

Commit using this repo's format from `commit-conventions.md`.

## Retrospectives File Migration

Repos initialized before MKT-0045 have a `retrospectives.md` with a preamble and
`## Log` header. The current format starts directly with the first `### ` entry —
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

