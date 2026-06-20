#!/usr/bin/env bash
# ============================================================
# structural-check.sh
# ============================================================
# Validates that icon-audit skill files have the required
# structural headings and frontmatter per planner-report.md §7
# checks B.1–B.4 and B.6.
#
# Usage:
#   bash .claude/skills/icon-audit/scripts/structural-check.sh
#
# Exit codes:
#   0  All structural checks pass
#   1  One or more required headings or frontmatter fields missing

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
# Script lives at .claude/skills/icon-audit/scripts/structural-check.sh, so
# repo root is four levels up (scripts -> icon-audit -> skills -> .claude -> repo).
REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
SKILL_ROOT="${REPO_ROOT}/.claude/skills/icon-audit"

FAIL=0

fail() {
  echo "${SCRIPT_NAME}: MISSING: $*" >&2
  FAIL=1
}

check_heading() {
  local file="$1"
  local pattern="$2"
  if ! grep -q "${pattern}" "${file}"; then
    fail "${pattern} not found in ${file}"
  fi
}

# ============================================================
# B.1 — SKILL.md required top-level sections
# ============================================================
echo "B.1 — SKILL.md sections"
SKILL_MD="${SKILL_ROOT}/SKILL.md"

check_heading "${SKILL_MD}" "^## Overview"
check_heading "${SKILL_MD}" "^## When to Use"
check_heading "${SKILL_MD}" "^## icon-audit: Phase 1"
check_heading "${SKILL_MD}" "^## icon-audit: Phase 2"
check_heading "${SKILL_MD}" "^## icon-audit: Phase 3"
check_heading "${SKILL_MD}" "^## Self-Application"
check_heading "${SKILL_MD}" "^## Cross-References"

if [[ "${FAIL}" -eq 0 ]]; then
  echo "  OK"
fi

# ============================================================
# B.2 — All six brief files exist with skeleton headings
# ============================================================
echo "B.2 — Brief skeleton headings"
B2_FAIL=0

for brief in 01-agents 02-process-skills 03-context-specialist-init 04-utility-skills 05-infrastructure 06-cross-cutting; do
  brief_file="${SKILL_ROOT}/briefs/${brief}.md"
  if [[ ! -f "${brief_file}" ]]; then
    fail "brief file not found: ${brief_file}"
    B2_FAIL=1
    continue
  fi
  for heading in "^## Scope" "^## Inputs" "^## Prior-Audit Pointer" "^## Forward-Looking Improvements Mandate" "^## Output Shape" "^## Non-Goals"; do
    if ! grep -q "${heading}" "${brief_file}"; then
      fail "${heading} not found in ${brief_file}"
      B2_FAIL=1
    fi
  done
done

if [[ "${B2_FAIL}" -eq 0 && "${FAIL}" -eq 0 ]]; then
  echo "  OK"
elif [[ "${B2_FAIL}" -eq 0 ]]; then
  : # B.1 already set FAIL; B.2 is clean
else
  : # failures already emitted
fi

# ============================================================
# B.3 — synthesis-template.md required sections
# ============================================================
echo "B.3 — synthesis-template.md sections"
SYNTHESIS="${SKILL_ROOT}/synthesis-template.md"
B3_FAIL=0

for heading in \
  "^## Executive Summary" \
  "^### Scorecard" \
  "^## Critical Findings" \
  "^## Moderate Findings" \
  "^## Minor Findings" \
  "^## Improvement Opportunities" \
  "^### Category 1 " \
  "^### Category 2 " \
  "^### Category 3 " \
  "^### Category 4 " \
  "^### Category 5 " \
  "^## Prioritized Fix Tiers" \
  "^### Tier 1 " \
  "^### Tier 2 " \
  "^### Tier 3 " \
  "^### Tier 4 " \
  "^## Open Questions" \
  "^## Suggested Follow-up Tasks"; do
  if ! grep -q "${heading}" "${SYNTHESIS}"; then
    fail "${heading} not found in ${SYNTHESIS}"
    B3_FAIL=1
  fi
done

if [[ "${B3_FAIL}" -eq 0 ]]; then
  echo "  OK"
fi

# ============================================================
# B.4 — agent-evaluation cross-reference is one-way
# ============================================================
echo "B.4 — agent-evaluation one-way reference"
B4_FAIL=0

AGENTS_BRIEF="${SKILL_ROOT}/briefs/01-agents.md"
AE_SKILL="${REPO_ROOT}/skills/agent-evaluation/SKILL.md"

ae_in_brief=$(grep -c "agent-evaluation" "${AGENTS_BRIEF}" || true)
if [[ "${ae_in_brief}" -lt 1 ]]; then
  fail "agent-evaluation not referenced in briefs/01-agents.md (expected >= 1)"
  B4_FAIL=1
fi

pa_in_ae=$(grep -c "icon-audit\|plugin-audit" "${AE_SKILL}" || true)
if [[ "${pa_in_ae}" -ne 0 ]]; then
  fail "icon-audit (or legacy plugin-audit) found in agent-evaluation/SKILL.md (expected 0 — one-way reference violated)"
  B4_FAIL=1
fi

if [[ "${B4_FAIL}" -eq 0 ]]; then
  echo "  OK"
fi

# ============================================================
# B.6 — SKILL.md frontmatter shape
# ============================================================
echo "B.6 — SKILL.md frontmatter"
B6_FAIL=0

if ! head -6 "${SKILL_MD}" | grep -q "^name: icon-audit"; then
  fail "SKILL.md frontmatter missing 'name: icon-audit'"
  B6_FAIL=1
fi

# Folded scalar (`description: >`) puts the description body on continuation
# lines with leading indent — accept either `description: Use when` (plain
# scalar) or a folded form whose first body line starts with `Use when`.
if ! head -6 "${SKILL_MD}" | grep -qE "^description: Use when|^[[:space:]]+Use when"; then
  fail "SKILL.md frontmatter description does not start with 'Use when'"
  B6_FAIL=1
fi

if ! head -6 "${SKILL_MD}" | grep -q "^user-invocable: true"; then
  fail "SKILL.md frontmatter missing 'user-invocable: true'"
  B6_FAIL=1
fi

if [[ "${B6_FAIL}" -eq 0 ]]; then
  echo "  OK"
fi

# ============================================================
# Final result
# ============================================================
if [[ "${FAIL}" -eq 0 ]]; then
  echo "All structural checks passed."
  exit 0
else
  echo "${SCRIPT_NAME}: one or more structural checks failed." >&2
  exit 1
fi
