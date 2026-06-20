---
name: jira-story
description: >
  Renders provided story content into the standard Jira story format. Note: examples reference DataScan's Jira prefix conventions and Angular stack; the rendering logic itself is generic.
user-invocable: true
---

# Jira Story Writer Skill

## Overview

Render the provided story content into the standard Jira story format.

## Inputs

**Required:**
- Story content (can be rough ideas, research findings, or existing story text to refine)
- `output_path`: Absolute directory path where the file should be written (e.g., `/home/user/Repos/project/.context/tasks/2026-03-04/`)
- `output_filename`: File name for the story (e.g., `PROJ-1042-filter-panel-autocomplete.md`)

**Optional:**
- Research findings (file paths, methods, patterns discovered during codebase exploration)
- Technical context (architectural constraints, dependencies, risks identified)
- Story type/area preference (e.g., "NgWi", "Domain API", "SPIKE")
- Existing story for refinement

## Execution

Upon invocation, perform these steps in order — do not stop at rendering the story in chat:

1. Render the complete story content using the format defined in **Story Output Format** below.
2. Write the file to `{output_path}/{output_filename}` using your available file-write tool.
3. Confirm the file was saved by reporting the full path written.

**Do not** output the story as chat text only. The file must be written to disk. If `output_path` or `output_filename` are missing, ask for them before proceeding.

## Outputs

A professionally formatted Jira story following the exact project standard format with:
- **Title**: `[Type/Area] Concise Summary`
- **Objective**: 1-3 sentences stating the goal clearly
- **Why is this needed**: Business value/rationale
- **Acceptance Criteria**: Observable, testable conditions scoped to the correct layer (frontend vs backend)
- **Technical Notes**: Actionable implementation guidance with specific file paths, methods, and patterns (filtered for relevance)
- **Open Questions**: Unresolved decisions requiring input

## Story Output Format

Follow this exact format for all stories (project standard). Use Jira markdown formatting:

```
## [Type/Area] Summary of Story

---

### Objective
[1-3 sentences. Clear and concise statement of what this story accomplishes. Professional language for all stakeholders.]

### Why is this needed
[1-3 sentences. Explain the reason and importance. Include rationale and minor context to help stakeholders understand value.]

### Acceptance Criteria

[List conditions that must be met for completion from a QA/testing perspective. Each AC should be:
* Written from the user's or tester's point of view, not developer perspective
* Observable and manually testable (QA should be able to verify without looking at code)
* Specific about user actions, system responses, and expected outcomes
* Avoid mentioning unit tests, integration tests, or code-level details
* Include functional behavior, UI states, error scenarios, and permissions

Format as Given-When-Then for clarity:]
* Given [precondition/state], when [user action], then [observable outcome].
* Given [different context], when [user action], then [different observable outcome].
* [Include edge cases like invalid inputs, permission denials, loading states, error messages that QA can observe and verify.]

**Avoid:** "All tests pass", "Code is refactored", "Follows coding standards" — these are developer concerns, not acceptance criteria for QA.

### Technical Notes
[Include ONLY information that is:
1. **Non-obvious** — Don't state what developers already know about the project
2. **Actionable** — Specific files, methods, patterns to follow or modify
3. **Risk-surfacing** — Complexity, blockers, architectural concerns

**Filter out:**
* ❌ "Angular Material is already available" (obvious for Angular projects)
* ❌ "Follow project coding standards" (implicit expectation)
* ❌ "All tests should pass" (not an acceptance criterion)
* ❌ Listing every import or dependency that's standard for the project

**Include:**
* ✅ Specific files to modify with line numbers: `serial-info-fields.component.html` (lines 63-71)
* ✅ Patterns to follow: "Use same autocomplete pattern as loan-transfers modal (lines 74-86)"
* ✅ Non-standard dependencies: "Requires upgrade to @datascan-ui/das-ui-service-client-api v2.3.0+"
* ✅ Migration notes: "Replaces legacy dropdown logic in `LoanRequestService.getMakes()`"
* ✅ Configuration impacts: "Story blocked until CHECK_VALID_MAKE feature flag enabled in QA environment"

**For enhancements/refactors:**
* Existing files: `actual/file/paths` with specific lines if applicable
* Methods to modify: `SpecificService.methodName()` with signature if complex
* Models/DTOs: Only if they're changing or non-standard

**For brand new areas from refactors:**
* Legacy files being replaced: `old/file/paths` and key methods
* Migration path: [what functionality is moving where]

**For completely new features (no existing area):**
* Reference implementation: `path/to/similar/component` (specific lines if helpful)
* Reusable services: Only if they're NOT standard project utilities
* Patterns: "Follow same error handling as payments module"

**Dependencies section rules:**
* Use Jira links for parent stories, don't describe their content
* Only list external dependencies if they require action (e.g., version upgrade, new package install)
* Omit standard project dependencies (e.g., "Angular Material" in an Angular project)

Minor helpful additions acceptable if they support implementation without overengineering. Keep brief if minimal technical context exists.]

### Open Questions
* [] [Unresolved decisions requiring PM, Engineering, or Design input]
```

**Jira Markdown Reference:**
- Headings: `#` (h1), `##` (h2), `###` (h3), `####` (h4), `#####` (h5), `######` (h6)
- Bold: `**text**` or `__text__`
- Italic: `*text*` or `_text_`
- Monospace/code: `` `text` ``
- Bullet lists: `*` or `-` at start of line
- Horizontal rule: `---` or `***`
- Checkboxes: `[] ` (note the space after brackets)

## Example Comparison

### ❌ BEFORE (Verbose, redundant)

**Acceptance Criteria:**
* Given the ENABLE_ADVANCED_FILTER configuration is ON, when the user opens the filter panel, then only the advanced filter options are shown.
* Given the ENABLE_ADVANCED_FILTER configuration is OFF, when the user opens the filter panel, then only basic filter options are shown.

**Technical Notes:**
Dependencies:
* Parent story: PROJ-1042 (Backend API must return FilterOptionDTO[] with both code and label fields)
* Client library: @myorg/api-client package must have updated filter endpoints returning FilterOptionDTO[]
* UI library: DatePickerModule (already available in the project)

---

### ✅ AFTER (Concise, actionable)

**Acceptance Criteria:**
* Given a user opens the filter panel, when advanced filters are enabled, then only filter options relevant to the selected category are displayed with their labels.
* Given the user types text in the filter field, when it matches a code or label, then the autocomplete filters to show matching results.

**Technical Notes:**
*Blocked by:* PROJ-1042 (link in Jira)

*Files to modify:*
* `filter-panel.component.html` (lines 40-55) — Replace static list with dynamic autocomplete
* `filter-panel.component.ts` — Update `filterOptions` type from `string[]` to `FilterOptionDTO[]`

*Pattern to follow:*
* Reference: `search-modal.component.html` (lines 30-44) for existing autocomplete implementation

*Risk:* Custom validator must check selected value against the `FilterOptionDTO[]` returned by the API.


