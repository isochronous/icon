# Third-Party Contribution Integration — Raw Findings

**Domain:** 07 — Custom cross-domain lens (third-party contribution integration)
**Audited state:** plugin v1.19.0 + `[Unreleased]` on branch `feature/ICON-0058-icon-audit` (HEAD).
**Delta baseline:** ICON-0046 (2026-05-27, v1.17.2, verdict STRONG) — `.context/tasks/ICON-0046-icon-audit/audit-report.md`.
**Yardsticks:** `skills/writing-skills/SKILL.md` (Quality Checklist + Where Skills Live), `skills/agent-evaluation/SKILL.md` (5-rule framework), ADR-004/007/009/010.
**Scope guard honored:** unmerged `dw/*` branches NOT read; only the merged contribution set evaluated; maintainer (Jeremy McLeod) commits excluded.

---

## Summary

The merged third-party contribution set is in **good integration health overall** — every new skill and edit is structurally sound, conformant to the folded-block-scalar frontmatter convention, and (with one exception) wired and registered. Conformance to the `writing-skills` Quality Checklist is strong: both new skills (`mr-feedback-triage`, `characterization-testing`) carry correct frontmatter, anti-rationalization tables, name-prefixed step headings, and tight trigger-only descriptions. No foreign authoring patterns were introduced; contributors matched ICON house style closely. The single material integration gap is that **`characterization-testing` (Arvind Yadav, ICON-0049) is wired into `using-skills` and `tester.agent.md` but was never added to the `README.md` Internal Skills table** — the same class of new-skill discoverability gap ICON-0046 flagged against `mcp-tools-first`, recurring on a new surface. The `rfc` metadata-table rewrite (Matthew Echeverria, ICON-0051) is functionally correct but introduced **two net-new internal documentation inconsistencies** (a stale "Confluence wiki markup" example descriptor and a `*bold*`-vs-`**bold**` syntax contradiction). CHANGELOG and retrospective hygiene is excellent across all four contributions — every task has a correctly-versioned CHANGELOG entry with one-bullet-per-change discipline and a retrospective entry. Movement vs ICON-0046: the prior cycle's `mr-feedback-triage` was net-new and clean; it remains clean and fully integrated here (no regressions). The prior `rfc` Design-Notes fix (m-U-F) holds. The recurring "new skill not registered in README" pattern is **still present** as a class, now manifested on `characterization-testing`.

---

## Per-Contribution Assessment

### Connor Ericson — ICON-0046 (`mr-feedback-triage` new skill, `mr-discipline` hardening, README row)

**Verdict: Up-to-standard.**

- `skills/mr-feedback-triage/SKILL.md:1-6` — frontmatter conformant: `description: >` folded block scalar, trigger-only (no workflow summary), `user-invocable: true` matches its `/mr-feedback-triage` exposure. Correct per `writing-skills/SKILL.md:155-165` and ADR-009 (no caller enumeration).
- `skills/mr-feedback-triage/SKILL.md:24,49,65,89` — step headings are skill-name-prefixed (`mr-feedback-triage: Phase N:`) per `writing-skills/SKILL.md:214-218`. Conformant.
- `skills/mr-feedback-triage/SKILL.md:85,127` — the non-action prohibition (never resolve/reply) is stated in both Phase 3 body and Common Mistakes with the `as part of this skill` qualifier, exactly the correction the ICON-0046/0050 retro records (`.context/retrospectives.md:37`). Well-integrated.
- **Registration:** `README.md:168` registers `mr-feedback-triage` in the consumer Skills table with an accurate purpose line. ✅
- **Genre fit:** Phase-structured technique skill with a necessity-tier table (`:71-75`) and guard-and-fetch prerequisite. Matches ICON house style for MCP-driven skills (mirrors `setup-mcp-servers` guard pattern). No foreign pattern.
- Minor observation: `mr-feedback-triage/SKILL.md:39` filter logic `notes[0].resolved == true` reads slightly imprecisely (resolution is a thread-level property in GitLab, expressed on the discussion's resolvable notes) — this is a behavioral-precision nuance, not an integration defect, and out of this brief's scope (domain 04 owns skill-internal logic).

### Connor Ericson — ICON-0042 (`manager.agent.md` Jira-ID guard, `commit-discipline`)

**Verdict: Up-to-standard.**

- `agents/manager.agent.md:51` — the Task ID Source rule is well-formed and lives in the agent PROMPT (decision logic), correct per `agent-evaluation` RULE 1 (PROMPT vs SKILL separation). It belongs in the orchestrator, not a skill.
- `agents/manager.agent.md:267` — the matching Anti-Rationalization row ("MR 2942 → WSD-2942") is intentional reinforcement, explicitly carved out of RULE 2 by `agent-evaluation/SKILL.md:40` (AR rows are load-bearing redundancy, not duplication). Not a violation.
- `skills/commit-discipline/SKILL.md:136,162` — the same rule is enforced at commit time via a Common Mistakes row and a Red Flags bullet. This is correct **three-layer enforcement** (Session Start gate + commit-time gate + AR reinforcement) for a fabrication-risk rule, not an SSOT violation — the two surfaces guard different lifecycle moments.
- **Genre fit:** matches the existing manager AR-table and commit-discipline Common-Mistakes/Red-Flags structure exactly. No drift.

### Arvind Yadav — ICON-0049 (`characterization-testing` new skill, `using-skills` routing, `tester.agent.md` Step 2)

**Verdict: Minor gaps.** (Authoring is up-to-standard; one integration registration gap.)

- `skills/characterization-testing/SKILL.md:1-6` — frontmatter conformant: `description: >` folded scalar, rich trigger-only description with symptoms, `user-invocable: false` (correct — it is agent-routed via `tester.agent.md`, never user-invoked). Per `writing-skills/SKILL.md:155-165`. ✅
- `skills/characterization-testing/SKILL.md:31,48,66,72,79` — step headings skill-name-prefixed per convention. Rationalization-Prevention table at `:98-105` is the right shape for a discipline skill (`writing-skills/SKILL.md:206`). High authoring quality.
- **Wiring into `using-skills`:** `skills/using-skills/SKILL.md:71` adds `characterization-testing` to the Process-skills priority list with explicit "use instead of `testing-discipline` when code already exists with no coverage" routing; `:77` adds a routing example; `:84` adds it to the Rigid list. Fully wired. ✅
- **Cross-reference from caller:** `agents/tester.agent.md:19` Step 2 routes legacy-code cases through `characterization-testing` before `testing-discipline`. The skill cross-references back to `testing-discipline` at `:83`. Bidirectional wiring is clean. ✅
- **❌ INTEGRATION GAP — not registered in README:** `characterization-testing` does **not** appear in the `README.md` Internal Skills table (`README.md:184-213`; `grep -c` returns 0). Every other agent-invoked internal skill (`commit-discipline`, `testing-discipline`, `verification-checklist`, `mr-discipline`, etc.) is listed there. `writing-skills/SKILL.md:255-256` ("Register the skill — Add it to the skills table in `README.md`") makes this a checklist miss. This is the **same defect class ICON-0046 raised against `mcp-tools-first`** (m-U-net2 / IO-CC-D1) — a new auto-invoked skill wired into routing but absent from the README discoverability surface. The ICON-0049 retro (`.context/retrospectives.md:24`) records the `tester.agent.md` wiring gap caught at MR review but does **not** mention the README registration gap — it shipped uncaught.
- **CHANGELOG:** `CHANGELOG.md:18` (Added) + `:24` (Changed) — two correctly-scoped bullets at v1.19.0, one-bullet-per-change discipline honored. ✅
- **Retro:** `.context/retrospectives.md:21-24` present and substantive. ✅

### Matthew Echeverria — ICON-0051 (`rfc` metadata-table schema rewrite, example, plugin.json version)

**Verdict: Minor gaps.** (Schema rewrite is correct; two net-new internal-doc inconsistencies introduced.)

- `skills/rfc/SKILL.md:140-172` — the new ORG-004 metadata-table schema is well-formed, single-canonical (does not vary by path), and both Step 2-S (`:70-80`) and Step 2-R (`:106-114`) collect/extract the table fields with "never invent" markers. Conformant and coherent.
- `skills/rfc/SKILL.md:1-6` — frontmatter unchanged, still conformant (`description: >`, `user-invocable: true`).
- `skills/rfc/examples/notification-service-email.md:3-9` — the example now leads with the mandatory metadata table using `**bold**` labels, matching the schema. The DataScan/SendGrid references in the example body are **intentional reference material** per ADR-010 m9 (`.context/decisions/010-...md:39`) — NOT flagged.
- **⚠️ NET-NEW DEFECT — stale format descriptor:** `skills/rfc/SKILL.md:312` states the example "is formatted in **Confluence wiki markup**." It is not — the example is pure Markdown/CommonMark (`##` headings, `**bold**`, Markdown pipe tables). This directly contradicts `:142` ("Output is **Markdown** (CommonMark)") and the example's own content. Likely residue from a predecessor `rfc-format` skill that targeted Confluence; the ICON-0051 rewrite updated the schema but not this descriptor.
- **⚠️ NET-NEW DEFECT — bold-syntax contradiction:** `skills/rfc/SKILL.md:182` says metadata-table labels use "`*bold*` syntax" (single asterisk = italic in Markdown), but the authoritative schema (`:149-153`), the worked example (`**Summary**`), and the Formatting checklist (`:301`, "Bold uses `**bold**`") all use double-asterisk `**bold**`. An author following `:182` literally would produce italic labels. Net-new inconsistency from the rewrite.
- **CHANGELOG:** `CHANGELOG.md:26` (Changed) — single accurate bullet at v1.19.0. ✅ (Note: a second redundant `### Changed` header exists in the `[Unreleased]` block at `CHANGELOG.md:22` and `:26` — two `### Changed` subsections under one version; cosmetic, see Minor.)
- **plugin.json version:** bumped to `1.19.0` (commit "feat(rfc): metadata table schema + CONTRIBUTING.md (1.19.0)"). Correct per ADR-003 (version SSOT in plugin.json). ✅
- **Retro:** `.context/retrospectives.md:16-19` present; honestly records the artifacts-created-retroactively process miss. ✅

### Tom Stear — `.mcp.json` (mcp-atlassian dependency version)

**Verdict: Up-to-standard (with an attribution nuance).**

- `.mcp.json:87` — `"args": ["mcp-atlassian==0.21.1"]`. Shape is correct (pinned version, `${VAR}` credential placeholders per ADR-006). ✅
- **Attribution nuance:** Tom Stear's original contribution ("Ran into a versioning issue, from a dependency in the mcp-atlassian package", 2026-04-10) was a version pin, but the line at HEAD was subsequently rewritten by the maintainer (MKT-0080, "replace tools:[\"*\"] with explicit MCP allowlists"). At current HEAD the `.mcp.json` atlassian block is maintainer-owned; the Stear contribution is no longer line-attributable. No defect — the manifest shape is correct and the pinned version is valid.
- `.mcp.json:1` — file still lacks a `$schema` field (ICON-0046 m-infra-1 / O-V2). This is a **pre-existing maintainer-surface gap**, not introduced by the Stear contribution; out of this brief's scope (do not re-audit unrelated pre-existing content). Noted for cross-reference only.

---

## Defect Findings

### Critical

None.

### Moderate

- **M-07-1 — `characterization-testing` absent from README Internal Skills table.** `README.md:184-213` lists every agent-invoked internal skill except `characterization-testing` (`grep -c` = 0). The skill is wired into `using-skills/SKILL.md:71,77,84` and `tester.agent.md:19` but invisible on the README discoverability surface that `writing-skills/SKILL.md:255-256` mandates registration on. Tiered Moderate (not Minor) because it is a **recurrence of a named ICON-0046 defect class** (mcp-tools-first registration gap) on a new contributed surface, and because the ICON-0049 retro shows the registration step was never on the task's radar — indicating a process gap, not a one-off slip. ADR carve-outs do not apply (ADR-009 governs caller-lists in frontmatter, not README registration).

### Minor

- **m-07-1 — `rfc/SKILL.md:312` stale "Confluence wiki markup" example descriptor.** Contradicts `:142` (Markdown/CommonMark) and the example file's actual format. Net-new from ICON-0051. No ADR carve-out.
- **m-07-2 — `rfc/SKILL.md:182` `*bold*` vs `**bold**` contradiction.** Single-asterisk label-syntax instruction conflicts with the schema (`:149-153`), example, and Formatting checklist (`:301`). Net-new from ICON-0051.
- **m-07-3 — Duplicate `### Changed` subsections in `CHANGELOG.md` `[Unreleased]` block.** `CHANGELOG.md:22` and `:26` are two separate `### Changed` headers under the same `[Unreleased]` version (the ICON-0049 changed-bullet and the ICON-0051 changed-bullet were appended as separate subsections rather than merged into one). Cosmetic — Keep-a-Changelog expects one `### Changed` per version. Low risk; surfaces only at release-note assembly. (Spans an Arvind + Matthew boundary; neither contribution is individually wrong, the merge of the two left two headers.)

---

## Integration-Completeness Matrix

| Skill / Agent (contribution) | Registered in README? | Wired in using-skills? | Cross-referenced by callers? | CHANGELOG entry? | Retro entry? | Conforms to authoring standard? |
|---|---|---|---|---|---|---|
| `mr-feedback-triage` (Connor, ICON-0046) | ✅ `README.md:168` | n/a (user-invocable; not in a routing chain) | n/a | ✅ `CHANGELOG.md:55` (v1.18.0) | ✅ `retrospectives.md:36` | ✅ |
| `mr-discipline` hardening (Connor, ICON-0046) | ✅ `README.md:202` (pre-existing) | n/a | ✅ referenced from `mr-feedback-triage:20` | ✅ `CHANGELOG.md:58` (v1.18.0) | ✅ `retrospectives.md:36` | ✅ |
| `manager.agent.md` Task-ID guard (Connor, ICON-0042) | n/a (agent, listed in Agents section) | n/a | ✅ enforced at `commit-discipline:136,162` | ✅ `CHANGELOG.md` v1.17.0 block | ✅ ICON-0042 (v1.17.0 bundle) | ✅ |
| `commit-discipline` row (Connor, ICON-0042) | ✅ `README.md:187` (pre-existing) | ✅ `using-skills:72,84` (pre-existing) | ✅ from manager Task-ID rule | ✅ `CHANGELOG.md` v1.17.0 | ✅ ICON-0042 | ✅ |
| `characterization-testing` (Arvind, ICON-0049) | ❌ **absent** — `README.md:184-213` (M-07-1) | ✅ `using-skills:71,77,84` | ✅ `tester.agent.md:19` | ✅ `CHANGELOG.md:18,24` (v1.19.0) | ✅ `retrospectives.md:21` | ✅ |
| `tester.agent.md` Step 2 (Arvind, ICON-0049) | n/a (agent) | ✅ routes per using-skills | ✅ invokes characterization-testing | ✅ `CHANGELOG.md:24` | ✅ `retrospectives.md:24` | ✅ |
| `rfc` schema rewrite (Matthew, ICON-0051) | ✅ `README.md:172` (pre-existing) | ✅ `using-skills:74,86` (pre-existing) | n/a | ✅ `CHANGELOG.md:26` (v1.19.0) | ✅ `retrospectives.md:16` | ⚠️ `SKILL.md:182,312` (m-07-1, m-07-2) |
| `rfc/examples/notification-service-email.md` (Matthew, ICON-0051) | n/a (example) | n/a | ✅ linked from `rfc/SKILL.md:312` | ✅ covered by ICON-0051 bullet | ✅ `retrospectives.md:16` | ✅ (m9-accepted DataScan refs) |
| `.claude-plugin/plugin.json` version (Matthew, ICON-0051) | n/a | n/a | n/a | n/a (version, not a behavior change) | ✅ ICON-0051 | ✅ |
| `.mcp.json` mcp-atlassian (Tom Stear) | n/a | n/a | n/a | n/a (dependency pin; superseded by maintainer at HEAD) | n/a | ✅ shape; `$schema` gap is pre-existing maintainer surface |

Every non-✅ cell carries a `<file>:<line>` note above. The single ❌ is M-07-1.

---

## Improvement Opportunities

### Category 1 — Token Efficiency / Slim the Always-Loaded Surface

**IO-07-T1 · Consolidate the two `### Changed` subsections in `CHANGELOG.md` `[Unreleased]`.** Merge `CHANGELOG.md:22` and `:26` into a single `### Changed` block (closes m-07-3) so release-note assembly does not emit a doubled header. **Effort: trivial. Impact: low.**

### Category 2 — Discoverability / Onboarding UX

**IO-07-D1 · Register `characterization-testing` in the README Internal Skills table.** Add a row to `README.md:184-213` (e.g., "`characterization-testing` | Lock the actual behavior of untested legacy code as tests before changing it; run before `testing-discipline` when no coverage exists"). Directly closes M-07-1. **Effort: trivial. Impact: medium.**

**IO-07-D2 · Fix the two `rfc/SKILL.md` internal contradictions.** Change `:312` "Confluence wiki markup" → "Markdown (CommonMark)" and `:182` "`*bold*`" → "`**bold**`" so the skill's instructions match its own schema and example (closes m-07-1, m-07-2). **Effort: trivial. Impact: low-medium** (an agent following `:182` literally emits italic labels).

### Category 3 — Consolidation / Structural Simplification

**IO-07-S1 · Reconcile the `mr-feedback-triage` resolution-detection note.** `mr-feedback-triage/SKILL.md:39` (`notes[0].resolved == true`) could state thread-resolution detection in GitLab-API-accurate terms to prevent a contributor from coding a brittle index-0 check. **Effort: trivial. Impact: low.**

### Category 4 — Missing Skills / Workflow Gaps

**IO-07-M1 · Add a contribution-intake checklist to `CONTRIBUTING.md` that mechanically catches the registration gap.** `CONTRIBUTING.md:44-53` ("Holistic review before the MR") is strong but prose-only; it does not enumerate "if you added a skill, it must appear in (a) `README.md` skills table, (b) `using-skills` routing if it participates in a chain, (c) the consuming agent's workflow." A 3-item "New-skill integration checklist" subsection would have caught M-07-1 at the contributor's self-review. **Effort: low. Impact: high** (this is the single highest-leverage prevention for the recurring new-skill-registration class — it has now fired on `mcp-tools-first` (ICON-0046) and `characterization-testing` (this cycle)).

### Category 5 — Self-Verification / Automate the Retrospective Wisdom

**IO-07-V1 · Extend `.githooks/pre-commit` with a skill-registration invariant.** Add a gate: for each `skills/<name>/SKILL.md` present, assert `<name>` appears in `README.md` (either Skills or Internal Skills table). This mechanically prevents the M-07-1 class at commit time rather than relying on contributor self-review or MR review (the ICON-0049 retro shows MR review caught the `tester.agent.md` wiring but missed README registration). Pairs with the ICON-0046 O-M1 literal-grep-gate recommendation — same hook, adjacent invariant. **Effort: low. Impact: high.**

**IO-07-V2 · Add a "skill instructions self-consistency" lint for bold/format descriptors.** A lightweight check (or a `writing-skills` checklist item) that flags when a skill body claims a label format (`*bold*`) that disagrees with its own schema/example would have caught m-07-1 and m-07-2. **Effort: medium. Impact: low-medium.**

---

## ICON-0046 Delta

### Fixed

- **m-U-F (rfc design-history mid-schema paragraph)** — confirmed still fixed; the ICON-0051 rewrite preserved the ICON-0037 relocation to `## Design Notes` (`rfc/SKILL.md:351-353`). The metadata-table rewrite did not regress it.
- **`mr-feedback-triage` (net-new and clean in ICON-0046)** — remains fully integrated and conformant here; no regression. Registered (`README.md:168`), non-action prohibition intact (`:85,:127`).

### Still present or partial

- **New-skill-not-registered-in-README class** — ICON-0046 raised this against `mcp-tools-first` (m-U-net2 / IO-CC-D1, since closed for that skill by ICON-0048). The **class is still unmitigated structurally** and recurred this cycle on `characterization-testing` (M-07-1). No pre-merge registration gate was added, so the pattern remained available to re-fire. See IO-07-V1 / IO-07-M1.
- **`.mcp.json` `$schema` gap (m-infra-1 / O-V2)** — still absent at `.mcp.json:1`. Pre-existing maintainer surface, not introduced by the Stear contribution; flagged only for cross-reference (out of this brief's scope to re-tier).

### Net-new

- **M-07-1** — `characterization-testing` README registration gap (new surface; new since ICON-0046 which predates the ICON-0049 skill).
- **m-07-1** — `rfc/SKILL.md:312` stale "Confluence wiki markup" descriptor (introduced by the ICON-0051 rewrite; the ICON-0046 cycle's rfc was pre-rewrite).
- **m-07-2** — `rfc/SKILL.md:182` `*bold*` vs `**bold**` contradiction (introduced by ICON-0051).
- **m-07-3** — duplicate `### Changed` subsections in `CHANGELOG.md` `[Unreleased]` (artifact of merging the ICON-0049 and ICON-0051 changed-bullets).

---

*Audit-process note:* All four contributions cleared the highest-stakes integration checks — frontmatter convention, routing wiring, CHANGELOG one-bullet-per-change, and retrospective coverage — which is a strong signal that `CONTRIBUTING.md`'s `New task: … / task complete` flow is being followed by outside contributors. The gaps that slipped (README registration, two intra-skill doc contradictions) are precisely the ones not yet mechanically enforced — supporting IO-07-V1/V2 as the leverage points.
