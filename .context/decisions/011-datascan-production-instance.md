# ADR-011: This repo IS DataScan's production plugin instance

**Date**: 2026-06-12
**Status**: Accepted

## Context

`gitlab.com/onedatascan/ai-platform/plugins/icon` is simultaneously (a) the canonical, general-purpose ICON plugin and (b) the live plugin DataScan engineers consume in production via the marketplace `latest` tag. There is **no separate downstream DataScan fork** where org-specific content could live.

This creates a recurring audit ambiguity. Several shipped surfaces carry DataScan-specific body prose that acts as a working reference — most notably the live `onedatascan.atlassian.net` URL (e.g. in `skills/sprint-goals/SKILL.md`) and ORG-004 references. A portability-minded audit reads these as org-specific leaks and proposes replacing them with placeholders such as `your-org.example.com`. Applying that "fix" breaks DataScan's working reference, because there is no fork in which to host the org-specific version.

This was litigated during ICON-0048: the ICON-0046 audit's `m-U-net3` finding flagged the live Jira URL and proposed a placeholder; the fix was applied and then reverted (commit `f0408e5`) once the user clarified that this repo *is* the served plugin.

## Decision

Treat DataScan-specific **body-prose references** — `onedatascan.atlassian.net`, ORG-004, internal DataScan Confluence/Jira URLs, and similar surfaces acting as production reference links — as **intentional production content, not portability bugs**.

An audit finding of the shape "live org URL → replace with placeholder" is **wrong unless a downstream fork actually exists**. Such a finding requires the user to confirm a hosting fork before any replacement is applied; absent a fork, the live link stays.

## Consequences

**Positive:**
- The served plugin keeps working reference links for the org that consumes it.
- Audit cycles have a single consultation point: "live org URL → placeholder" findings are pre-dispositioned and should not be re-raised as defects.

**Negative:**
- The carve-out is org-coupled. A future plugin decomposition (P2 from ICON-0046's Plugin Decomposition Analysis) WOULD create a fork boundary where these links would need to relocate; until that decomposition lands, the live links stay and this ADR must be revisited if it does.

## Alternatives Considered

1. **Replace live org URLs with placeholders for portability.** Rejected — there is no fork to host the org-specific version, so the placeholder breaks the production reference rather than improving portability.
2. **Maintain a separate DataScan fork.** Rejected (for now) — no such fork exists and standing one up is out of scope; the decomposition that would justify it has not landed.

## Relationship to other ADRs

- **ADR-004 (tool-agnostic content)** requires *tool*-agnostic content — a skill must not couple to one runtime. This ADR is narrower and distinct: it concerns *org*-specific content, which is NOT required to be org-agnostic on surfaces that have no fork to host the org-specific version. Genuinely tool-coupling concerns remain in scope of ADR-004.
- **ADR-010 m9** already accepts DataScan-flavored *examples* (sample story titles, Jira prefix shapes) as intentional reference material. This ADR extends that acceptance from illustrative examples to **body prose acting as a live production reference link**.
