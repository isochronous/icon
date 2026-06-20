---
name: rfc
description: >
  Create RFC documents from scratch or polish rough drafts into ORG-004 compliant form. Use when proposing new features, architectural changes, or technical decisions that need team review. Handles both scaffold-from-inputs and refactor-existing-draft entrypoints.
user-invocable: true
---

# RFC Skill

## Overview

This skill produces RFC (Request for Comments) documents that meet ORG-004 standards. It supports two entrypoints through a single branching procedure:

- **Scaffold path** — no draft exists; the skill collects inputs (problem, context, proposal, alternatives, implementation details, metadata table fields) and builds the RFC from scratch.
- **Refactor path** — a rough, informal, or incomplete draft exists; the skill reorganizes content into the standard sections, fills gaps with explicit markers, and improves clarity without changing the author's technical decisions.

Both entrypoints converge on the same authoritative ORG-004 schema and the same quality checklist — the output format does not diverge based on how the RFC was started.

Reference documentation: `<your-rfc-process-doc>` (RFC-001 RFC Process) · `<your-rfc-guidance-doc>` (General RFC Guidance) — link these to your team's RFC index (e.g. a `docs/rfc/` directory or the repository wiki).

### Why RFCs Matter

RFCs serve multiple critical functions:

- **Decision Documentation**: Capture the "why" behind technical choices for future reference.
- **Stakeholder Alignment**: Ensure all parties understand the proposal, alternatives, and trade-offs.
- **Knowledge Transfer**: Enable new team members to understand historical decisions.
- **Implementation Clarity**: Provide clear guidance for developers executing the work.
- **Risk Mitigation**: Surface concerns and abandoned ideas to prevent revisiting failed approaches.

## When to Use This Skill

Use this skill when you need to:

- Propose new features or capabilities.
- Document architectural changes or technical decisions.
- Evaluate multiple solution approaches.
- Ensure team alignment on significant technical work.
- Polish an informal draft into a reviewable RFC.
- Create a historical record of a decision-making process.

### Target Audience

- **Technical Leadership**: Need to evaluate feasibility and alignment with strategy.
- **Development Teams**: Need clear implementation guidance.
- **Product Management**: Need to understand user impact and business value.
- **Operations**: Need to understand deployment, monitoring, and operational requirements.
- **Future Team Members**: Need historical context for decisions made.

## rfc: Step 1: Entry Point — Do You Have a Draft?

Ask the user (or inspect the provided input):

- **No draft** → proceed to **Step 2-S: Scaffold Path**.
- **Rough draft exists** (even if incomplete, unstructured, or stream-of-consciousness) → proceed to **Step 2-R: Refactor Path**.

Both paths converge at Step 3 (ORG-004 Output Schema) and share Steps 4–6 for section guidance, path-specific quality checks, and final validation.

## rfc: Step 2-S: Scaffold Path — Collect Inputs

Gather the following from the user. Required inputs are needed before drafting; optional inputs shape the Implementation and Operationalization sections.

**Required**:

1. **Title** — concise, descriptive (e.g., "Enhance Notification Service with Email Delivery").
2. **Problem Statement** — what issue needs to be addressed?
3. **Context** — why is this needed now? What led to this proposal? Include links to related RFCs, documentation, or historical decisions.
4. **Proposed Solution** — high-level approach to solving the problem.

**Metadata Table Fields** (collect now; mark `TBD` for any not provided — never invent):

- **Summary** — 1–2 sentence summary of the RFC (fits inside the table cell).
- **Owner** — name of the RFC owner/author.
- **Contributors** — names of contributors (comma-separated).
- **Other Stakeholders** — teams or individuals with an interest (comma-separated).
- **Approvers** — names of required approvers (comma-separated).
- **Requirements** — links to relevant requirements, tickets, or documents (or leave blank).
- **Created** — defaults to today's date (`YYYY-MM-DD`); preserve if editing an existing RFC.
- **Current Version** — defaults to `0.1.0` for new drafts (per RFC-001 versioning: bump Minor when ready for comments, bump Major when approved → `1.0.0`).
- **Target Version** — defaults to `1.0.0` (the version if approved).

**Optional**:

5. **Alternatives Considered** — other approaches evaluated, and why they were rejected. If no alternatives were considered, state that explicitly with a brief reason.
6. **Implementation Details** — UX / UI / API specifics that the proposal commits to.
7. **Operational Considerations** — logging, monitoring, resilience, security expectations.

Once collected, proceed to **Step 3**. The scaffold path treats missing optional inputs as genuinely optional — do not fabricate content to fill them.

## rfc: Step 2-R: Refactor Path — Read, Extract, Map

### 2-R.1 Read and Understand the Draft

Carefully review the draft and any supplied context. Identify:

- What problem is being solved?
- What solution is being proposed?
- What implementation details are provided?
- What context or rationale is given?
- What is missing, unclear, or contradictory?

If the draft references external documents you cannot access, note what additional context is needed — do not invent it.

### 2-R.2 Extract and Map Content to ORG-004 Sections

**Metadata table fields — extract first:**

Before mapping body sections, extract (or note as `TBD`) all metadata fields needed for the table at the top of the RFC:

- **Summary** — 1–2 sentence summary from the draft.
- **Owner** / **Contributors** / **Other Stakeholders** / **Approvers** — extract from any authorship/ownership information present; mark `TBD` if absent — **never invent names**.
- **Requirements** — extract any links to tickets, specs, or requirements; leave blank if none.
- **Created** — preserve the existing date if present; use today's date only if absent.
- **Current Version** / **Target Version** — preserve existing values if present; default to `0.1.0` / `1.0.0` if absent.

Map draft content to the target body sections:

- **Background**: current state, desired state, context leading to the proposal.
- **Proposal**: the chosen approach, key components, high-level flow.
- **Abandoned Ideas**: alternatives mentioned, reasons for rejection, trade-offs.
- **Implementation**: ordered steps; database/schema changes; API changes; application changes.
- **Operationalization (including Security subsection)**: logging, monitoring, resilience, security considerations.
- **Addendum**: late-breaking items or future enhancements not central to the proposal.

### 2-R.3 Fill Gaps Explicitly — Never Invent

When information is missing:

- Mark the section as **"Requires Further Detail"** or **"To Be Determined"**.
- Add placeholder questions that guide completion.
- **Do NOT invent technical details.** The author's technical decisions are preserved; the skill's job is reorganization and clarification, not design.

When scope or constraints are mentioned:

- Create a dedicated Scope and Constraints subsection (see Step 4).
- State what is in scope vs. out of scope explicitly.

Once mapping is complete, proceed to **Step 3**.

## rfc: Step 3: ORG-004 Output Schema (Authoritative)

Single canonical definition — the schema does not vary by path. Output is **Markdown** (CommonMark).

```markdown
# [Page Title]

|  |  |  |  |
| --- | --- | --- | --- |
| **Summary** | [1–2 sentence summary] | | |
| **Created** | [YYYY-MM-DD] | **Owner** | [name] |
| **Current Version** | [SemVer e.g. 0.1.0] | **Contributors** | [names] |
| **Target Version** | [SemVer e.g. 1.0.0] | **Other Stakeholders** | [teams] |
| **Requirements** | [links or blank] | **Approvers** | [names] |

---

[Optional 1–2 sentence introductory paragraph — brief elaboration on the summary or context. Omit if nothing meaningful to add.]

## Background           (required — current state, desired state, rationale)
## Proposal             (required — high-level solution)
## Abandoned Ideas      (optional — alternatives + why rejected)
## Implementation       (optional — subsections below)
### UX                  (optional)
### UI                  (optional)
### API                 (optional)
## Operationalization   (optional — subsections below)
### Logging             (optional)
### Monitoring          (optional)
### Resilience          (optional)
### Security            (subsection of Operationalization — NOT top-level)
## Addendum             (optional — future enhancements, late-breaking items)
```

## rfc: Step 4: Section-by-Section Guidance

### Title

A concise, descriptive title that clearly indicates what the RFC proposes. Example: "Enhance Notification Service with Email Delivery".

### Metadata Table (Required)

The metadata table is the first element in the RFC body (before any prose). All fields use bold labels in the left column via `**bold**` syntax:

- **Summary** — 1–2 sentences that fit in a single table cell; a quick read that conveys the core proposal.
- **Created** — ISO date (`YYYY-MM-DD`) the RFC was first written. Scaffold path: default to today's date. Refactor path: preserve if present.
- **Owner** — primary author / DRI for the RFC. Mark `TBD` if not provided.
- **Current Version** — SemVer of the RFC document itself (not the software). New drafts: `0.1.0`. Ready for comment: bump minor (e.g. `0.2.0`). Approved: bump major → `1.0.0`.
- **Contributors** — comma-separated names of contributors. Mark `TBD` if not provided.
- **Target Version** — the version the RFC reaches if approved; typically `1.0.0`.
- **Other Stakeholders** — teams or individuals with an interest but not listed as contributors. Mark `TBD` if not provided.
- **Requirements** — links to tickets, specs, or requirements. Leave blank if none.
- **Approvers** — names of people who must approve before the RFC is finalised. Mark `TBD` if not provided.

After the table, add `---` (Markdown horizontal rule) and then the optional introductory paragraph.

### Background (Required)

Explain the context and rationale:

- **Current State**: what exists today, and what problems or limitations does it have?
- **Desired State**: goals and objectives of the proposal.
- **Context**: why is change necessary now? What led to this proposal?
- Include links to related RFCs, documentation, or historical decisions.

Goal: a new team member should understand why this RFC exists after reading this section.

### Proposal (Required)

Describe the proposed solution at a high level:

- What approach are we taking?
- What are the key components or changes?
- How does this address the problem stated in Background?

Focus on "what" and "how" conceptually, not detailed implementation.

### Abandoned Ideas (Optional)

Document alternatives considered and why they were rejected. Purpose: prevent revisiting dead-ends and provide insight into the decision-making process. If no alternatives were considered, state that explicitly rather than omitting the section.

### Implementation (Optional)

Break implementation into logical subsections:

- **UX** — changes to user workflows, backward-compatibility considerations, feature flags, phased rollout.
- **UI** — interface changes, wireframes, visual design, accessibility, responsive design.
- **API** — new or modified endpoints, request/response formats, auth, versioning, affected services.

### Operationalization (Optional)

Detail how the proposal will run in production. Operationalization contains four subsections:

- **Logging** — what is logged, where (Grafana, CloudWatch, etc.), retention, PII handling.
- **Monitoring** — metrics, dashboards, alerts, SLIs/SLOs.
- **Resilience** — health checks, redundancy, failover, circuit breakers, retry policy.
- **Security** — network security, authentication/authorization, data encryption (in-transit, at-rest), compliance, attack surface considerations.

### Addendum (Optional)

Future enhancements, deferred items, or late-breaking considerations that are related but not central to the current proposal.

### Scope and Constraints (Optional, refactor-path emphasis)

When the draft explicitly names scope or constraints, render them as a subsection (typically under Implementation or as its own `## Scope and Constraints` section):

- **In Scope**: what the proposal commits to.
- **Out of Scope / Constraints**: what is deliberately excluded, and why.

## rfc: Step 5: Apply Path-Specific Quality Checks

### Scaffold path (arrived from Step 2-S)

- Verify the metadata table is present as the first body element and all non-blank fields are populated (or explicitly marked `TBD`).
- Verify Created defaults to today's date and Current Version defaults to `0.1.0`.
- Verify every collected input is incorporated into the output.
- Confirm at least one alternative is documented in Abandoned Ideas, or the section explicitly states "no alternatives considered" with a reason.
- Verify optional sections were included only when there was content to fill them — do not pad.

### Refactor path (arrived from Step 2-R)

- Verify the metadata table is present as the first body element; fields extracted from the draft are used as-is — names and dates are never invented.
- Verify existing Created and Current Version values are preserved (not overwritten with defaults).
- Preserve the author's technical decisions — never change fundamental proposals.
- Preserve content: reorganize rather than rewrite. Never remove content from the original draft.
- Mark missing information as **"Requires Further Detail"** or **"To Be Determined"**. Never fabricate technical specifications.
- Verify stream-of-consciousness prose is reorganized into structured paragraphs but the original meaning is preserved.
- Highlight contradictions in the draft rather than resolving them by guessing — request clarification from the author.

## rfc: Step 6: Shared Quality Checklist

Before finalizing the RFC (both paths), verify:

**Structure**:
- [ ] Title clearly describes what is being proposed.
- [ ] Metadata table is present as the first body element with all fields populated or marked `TBD`.
- [ ] All required body sections are present (Background, Proposal).
- [ ] Sections appear in the order defined by the ORG-004 schema in Step 3.
- [ ] Security is a subsection of Operationalization, not a top-level peer.

**Content**:
- [ ] Metadata table Summary cell provides a 1–2 sentence overview of the proposal.
- [ ] Background explains current state, desired state, and rationale.
- [ ] Proposal articulates the high-level solution approach.
- [ ] Abandoned Ideas documents alternatives (or explicitly states none).
- [ ] Implementation provides actionable detail when included.
- [ ] Operationalization addresses production concerns when included.
- [ ] Missing information is clearly marked (refactor path) or genuinely optional content is omitted (scaffold path) — never fabricated.

**Clarity**:
- [ ] All jargon is explained or defined.
- [ ] A new team member could understand the context.
- [ ] Decision rationale is clear and well-documented.
- [ ] Trade-offs are explicitly discussed.
- [ ] Technical terminology is used consistently throughout.

**Formatting**:
- [ ] Markdown formatting is consistent and readable.
- [ ] Headings use `##` / `###` hierarchy correctly.
- [ ] Code blocks use fenced `` ``` `` blocks with optional language tag.
- [ ] Bullet lists use `-` or `*`; numbered lists use `1.`, `2.`, etc.
- [ ] Bold uses `**bold**`; italic uses `*italic*`.
- [ ] Horizontal rule after metadata table uses `---`.
- [ ] Links use `[text](url)` syntax.

**Completeness**:
- [ ] Optional sections are included only when they add value.
- [ ] Code samples and examples are accurate.
- [ ] The RFC is self-contained and actionable.

## Example: Notification Service Email Enhancement (Canonical)

A complete worked RFC that follows every section of the ORG-004 schema lives in [`examples/notification-service-email.md`](examples/notification-service-email.md). It is formatted in Markdown (CommonMark) and includes the mandatory metadata table. Read it after Step 4 (Section-by-Section Guidance) when you need a concrete reference for tone, depth, and section interplay.

## Best Practices

1. **Be Clear and Specific**: avoid jargon, or explain it when necessary.
2. **Provide Context**: do not assume readers have full background knowledge.
3. **Document Trade-offs**: explain why you chose one approach over another.
4. **Link to Related Work**: reference other RFCs, documentation, or decisions.
5. **Write for Diverse Audiences**: technical and non-technical readers should both follow.
6. **Be Concise but Complete**: provide sufficient detail without overwhelming.
7. **Use Visual Aids**: include diagrams, code samples, or wireframes when helpful.
8. **Get Early Feedback**: share drafts for review before finalizing.
9. **Update as You Learn**: RFCs can evolve based on discovery and feedback.
10. **Preserve Content on Refactor**: never remove or rewrite fundamental proposals from a source draft — reorganize and clarify only.

## What to Avoid

- Using jargon without explanation.
- Assuming readers have full context.
- Skipping required sections (Metadata Table, Background, Proposal).
- Providing only high-level platitudes without specifics.
- Forgetting to document why alternatives were abandoned.
- Including every optional section unnecessarily.
- Inventing technical details to fill gaps (refactor path).
- Resolving contradictions in a source draft by guessing — ask the author instead.

## Usage Guidelines

1. **Start with Step 1**: answer the "Do you have a draft?" question before proceeding.
2. **Fill required sections**: Title (page title), Metadata Table, Background, and Proposal are always required.
3. **Include optional sections selectively**: Implementation and Operationalization subsections only when they provide value.
4. **Use clear headings and Markdown formatting** (`##`/`###` headings, `**bold**`, fenced code blocks) for readability.
5. **Be specific and concise**: sufficient detail without unnecessary verbosity.
6. **Link to related documents**: reference other RFCs, documentation, or decisions.
7. **Keep it accessible**: write for someone unfamiliar with the context.
8. **Adapt to your needs**: not every RFC needs every section.
9. **Get feedback early**: share drafts for review before finalizing.
10. **Update as you learn**: RFCs are living documents that can evolve.

## Design Notes

**Section-5 resolution (Operationalization ⊇ Security)**: Security is rendered as a subsection of Operationalization, not a peer-level top-level section. Security is one of several production concerns alongside Logging, Monitoring, and Resilience — all operational. Promoting Security to peer level would require the same treatment for the others, inflating the schema. Refactor-path drafts with heavy security content render Security prominently as a well-developed `### Security` subsection under Operationalization; this is semantically correct and visually equivalent to a promoted section in a properly-formatted document. Predecessor skills disagreed on this point — `rfc-format` used Operationalization as top-level with Security as subsection; `rfc-refactor` used Security as top-level with Operationalization relegated to Addendum. The consolidated skill adopts the Operationalization-as-container form.
