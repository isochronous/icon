# Audit Mode

## Overview

Audit mode runs a three-phase structural review of an existing Claude Code plugin: file/folder + frontmatter structure, internal consistency, and improvement opportunities. Output is a structured findings report — no severity tiering (that is `icon-audit`-specific and does not generalize), but always at least three improvement opportunities even when no defects are found.

## Hard Precondition

Audit mode requires the plugin to have been initialized with `/icon-init`. Without a populated `.context/`, the audit degenerates into a generic file-structure linter — it cannot read the plugin's own standards, decisions, or domain docs to ground architectural-consistency checks.

Confirm this before sequencing any phases.

Bash:

<!-- pre-commit:dead-ref-ok-start -->
```bash
if [ ! -f .context/iconrc.json ]; then
  cat <<'MSG'
Audit mode requires the plugin to have been initialized with /icon-init.
No `.context/iconrc.json` found at the plugin root. Run /icon-init first, then re-run /plugin-design audit.
MSG
  exit 1
fi
```
<!-- pre-commit:dead-ref-ok-end -->

PowerShell:

<!-- pre-commit:dead-ref-ok-start -->
```powershell
if (-not (Test-Path .context/iconrc.json)) {
  @'
Audit mode requires the plugin to have been initialized with /icon-init.
No `.context/iconrc.json` found at the plugin root. Run /icon-init first, then re-run /plugin-design audit.
'@
  exit 1
}
```
<!-- pre-commit:dead-ref-ok-end -->

Halt the skill on failure. Do not continue to Phase 1.

## Phase Sequence

Load and execute each phase file in order. Each phase appends findings to the running report; final synthesis happens after Phase 3.

1. **Structure validation** — load `audit-phase-structure.md`. Check `plugin.json`, required directories, frontmatter validity, CHANGELOG presence.
2. **Internal consistency** — load `audit-phase-consistency.md`. Check skill references, file-path references, frontmatter quality, role-overlap heuristic.
3. **Improvement opportunities** — load `audit-phase-improvements.md`. Surface forward-looking suggestions; produce at least 3 even if no defects are found.

## Output Shape

After Phase 3, present the findings as a single report with three sections:

```
## Structure Findings
- <one line per finding, with file path and line if applicable>

## Consistency Findings
- <same shape>

## Improvement Opportunities
- <free-text suggestions, at least 3 entries>
```

Do **not** assign Critical / Moderate / Minor tiers — that is an ICON-internal convention. Generic consumers running this skill ad-hoc should evaluate findings against their own release-readiness bar.
