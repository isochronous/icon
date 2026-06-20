---
name: sprint-goals
description: >
  Generates sprint goals from Jira CSV exports following ORG-004 guidelines. Use when creating sprint start communications, mid-sprint updates, or end-of-sprint summaries. Analyzes story data to produce developer-focused goals with clear deliverables and dependencies. Note: the prefix-removal list (`[NgWi]`, `[Domain API]`, `[ngDas]`, `[WI Ui Service]`) is DataScan convention.
user-invocable: true
---

# Sprint Goals Generator

## Overview

An expert Agile scrum master and technical communicator that transforms Jira CSV exports into clear, outcome-focused sprint goals for company-wide communication. Creates goals that resonate with both technical and non-technical stakeholders without requiring Jira access.

Sprint goals serve as the primary communication mechanism for engineering progress:
- **Company-wide visibility**: Executives, product, sales, and support all read these
- **Transparency**: Demonstrates what engineering is delivering each sprint
- **Accountability**: Clear commitments with status indicators
- **Historical record**: Documents what was accomplished and why

All formatting, status indicators, and best practices follow **[ORG-004 Engineering Sprint Goal Guidelines and Best Practices](https://onedatascan.atlassian.net/wiki/spaces/DAA/pages/7093321734/ORG-004+Engineering+Sprint+Goal+Guidelines+and+Best+Practices)**.

## When to Use This Skill

- Creating sprint start communications with planned goals
- Providing mid-sprint status updates to stakeholders
- Generating end-of-sprint reports with accomplishments
- Communicating engineering progress to non-technical audiences
- Documenting sprint deliverables for historical reference

## Target Audience

- **Executives**: Need business impact and strategic alignment
- **Product Teams**: Need feature delivery and roadmap alignment
- **Cross-functional Teams**: Sales, support, customer success need to know what's changing
- **Engineering Team**: Need alignment on priorities and dependencies
- **Assumption**: Audience does NOT have access to Jira

## Inputs Required

### Required Data
- **CSV file**: Jira export with columns:
  - Issue Type, Issue key, Issue id, Summary, Assignee, Priority, Status
  - Parent key, Parent summary, Story Points, Due date
- **Sprint identifier**: Sprint number and date range (e.g., "2024.Q4 Sprint 15 (Nov 1 - Nov 14)")
- **Sprint phase**: Start, Mid-Sprint, or End-of-Sprint

### Optional Context
- Known blockers or dependencies
- Reason for descoped items (mid-sprint/end-of-sprint)
- Additional work completed outside original plan (end-of-sprint)

## Expected Output

Formatted sprint goals document with:
- Sprint header with number and date range
- Goals grouped by Epic/Feature area
- Outcome-focused bullets (not task lists)
- Status indicators appropriate to sprint phase
- Explanations for blocked/descoped/incomplete items (when applicable)

## Step-by-Step Process

### sprint-goals: Step 1: Gather Required Inputs

Collect from the user:
- CSV file with Jira export data
- Sprint number and date range
- Sprint phase (Start, Mid-Sprint, or End-of-Sprint)

### sprint-goals: Step 2: Analyze the CSV Data

**Group by Epic/Feature:**
- Use the **Parent summary** column to group related items
- If no parent summary, group by theme/topic based on issue summaries
- Create short, recognizable group headings (e.g., "Payment Schedule API", "User Dashboard")

**Identify Story Relationships:**
- Look for coupled items (e.g., story + QA automation task for same feature)
- Combine tightly coupled items into a single goal
- Separate truly independent work into individual goals

**Clean Up Summaries:**
- Remove prefix tags like `[NgWi]`, `[Domain API]`, `[ngDas]`, `[WI Ui Service]`
- Transform technical summaries into outcome-focused goals:
  - ❌ "Create payment schedule API endpoint"
  - ✅ "Enable loan officers to create custom payment schedules"
- Keep goals succinct and business-relevant
- Focus on "what's being delivered" not "what tasks are being done"

### sprint-goals: Step 3: Determine Status Indicators

**Start of Sprint:**
- No status indicators needed
- Goals are aspirational/planned
- Format: Simple bullet list of goals per epic

**Mid-Sprint Update:**
- Include status for each goal:
  - ✅ [Complete]: Goal is done
  - ✅ [On Target]: On track to complete by sprint end
  - ⚠️ [Blocked] or [At Risk]: Impeded or behind schedule
  - ❌ [Descoped]: Removed from sprint scope

**End-of-Sprint Report:**
- Include status for each goal:
  - ✅ [Complete]: Goal was completed
  - ❌ [Not Complete]: Goal was not completed
- Add "Additional Deliverables" section if work was completed outside original goals

### sprint-goals: Step 4: Add Explanations for Issues

**Any ⚠️ or ❌ goal MUST include:**
- **WHY** the team is blocked/at risk, descoped, or didn't complete
- **WHAT** the expected outcome or plan is now
- **HOW** it impacts the overall deliverable in the Plan of Record

### sprint-goals: Step 5: Format the Output

Use exact format based on sprint phase (see Sprint Phase Guidance section).

### sprint-goals: Step 6: Validate Quality

Check all items in Quality Checklist before outputting.

## Sprint Phase Guidance

### Start of Sprint Format

```
**{Year}.{Quarter} Sprint {Number} ({Start Date} - {End Date}) - Sprint**

**{Epic / Feature Group 1}**

* {Outcome-focused goal}
* {Outcome-focused goal}

**{Epic / Feature Group 2}**

* {Outcome-focused goal}
```

### Mid-Sprint Format

```
**{Year}.{Quarter} Sprint {Number} ({Start Date} - {End Date}) - Mid-Sprint Update**

**{Epic / Feature Group 1}**

* ✅ [Complete] {Goal}
* ✅ [On Target] {Goal}
* ⚠️ [Blocked] {Goal}
    *Explanation: WHY behind, WHAT the expected outcome is, HOW it impacts the overall deliverable.*
* ❌ [Descoped] {Goal}
    *Explanation: WHY descoped, WHAT the plan is, HOW it impacts the overall deliverable.*
```

### End-of-Sprint Format

```
**{Year}.{Quarter} Sprint {Number} ({Start Date} - {End Date}) - End-of-Sprint Report**

**{Epic / Feature Group 1}**

* ✅ [Complete] {Goal}
* ❌ [Not Complete] {Goal}
    *Explanation: WHY not accomplished, WHAT the plan is, HOW it impacts the overall deliverable.*

**Additional Deliverables**

* ✅ [Complete] {Extra accomplishment not in original goals}
```

## Examples

Three worked examples — each showing the same epic structure at a different sprint phase — live in `examples/`:

- [`examples/start-of-sprint.md`](examples/start-of-sprint.md) — initial sprint plan, no status indicators.
- [`examples/mid-sprint.md`](examples/mid-sprint.md) — same goals with mid-sprint status (complete, blocked, descoped) and the WHY/WHAT/HOW explanations required for ⚠️ and ❌.
- [`examples/end-of-sprint.md`](examples/end-of-sprint.md) — end-of-sprint report including an Additional Deliverables section.

## Quality Checklist

Before outputting, verify:
- ✅ All goals are outcome-focused, not task descriptions.
- ✅ No Jira keys, story points, or assignee names.
- ✅ Prefix tags ([NgWi], [Domain API], [ngDas], etc.) removed; company-wide audience can read without Jira access.
- ✅ Tightly coupled work combined into single goals (story + QA = one goal); independent work kept separate.
- ✅ Within each group: features before fixes; higher priority first; dependencies first when relevant.
- ✅ One line per goal (occasionally two for complex goals); no technical jargon without context.
- ✅ Status indicators correct for the sprint phase.
- ✅ Every ⚠️ and ❌ has WHY (root cause), WHAT (plan), HOW (impact).
- ✅ Format matches the exact template for the sprint phase (see Sprint Phase Guidance).

## Reference

All formatting follows: **[ORG-004 Engineering Sprint Goal Guidelines and Best Practices](https://onedatascan.atlassian.net/wiki/spaces/DAA/pages/7093321734/ORG-004+Engineering+Sprint+Goal+Guidelines+and+Best+Practices)**
