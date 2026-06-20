# ICON-0035 — Architecture Spec (init-orchestrator + context-resolution polish)

**Author**: @architect
**Date**: 2026-05-22
**Source ticket**: GitLab issue #20 (maintainer-revised 2026-05-22)
**Reads**: @coder (implementation), @reviewer (acceptance gates)

---

## 1. Summary

This task sweeps the init + context-resolution skill chain to close the maintainer-revised set of audit findings from issue #20. The architectural shape of the work has two threads:

- **Code edits**: extract two repeated inline-bash blocks into single canonical homes (O-S5 entry-point detection → `context-specialist-detect-tree-position` SKILL; O-S6+m10 sampling spec → `upgrade-repo` Phase 3), normalize the PowerShell separator in `find-context-template`, annotate the `.claude/claude.md` → `.github/copilot-instructions.md` fallback in the `resolve-repo-context` schema example, generalize organization-specific examples across four init/impl skills to abstract placeholders, and replace a stale `copilot-instructions.md` reference in the `initialize-workspace` MR template.
- **Won't-fix policy artifacts**: write ADR-009 (skill descriptions do not enumerate callers — m4 won't-fix), and prune Common Check Pattern 3 ("Caller-listing in description") from all five `plugin-audit/briefs/*.md` files plus add an explicit ADR-consultation step so the next audit cycle reads `.context/decisions/` (including ADR-007 for the m1 carry-forward and ADR-009 for this one) before tiering.

Out of scope (per maintainer revision): O-X3 `disable-model-invocation` propagation (deferred pending reproducible test), any change to historical audit research files under `.context/tasks/ICON-0003-*/` or `.context/tasks/ICON-0015-*/`, any change to `briefs/06-cross-cutting.md` or `synthesis-template.md`, and any refactor of `find-context-template`'s `$MARKETPLACE_NAME` parametrization logic.

---

## 2. Open-Question Resolutions

These are the six open questions surfaced by the pre-flight Explore. Each has one binding answer; @coder must use the answer below verbatim and may not relitigate.

### Q1 — m5: schema fallback annotation strategy (second example vs annotation)

**Resolution**: **Annotate the existing example**, do not add a second example.

**Reasoning**: The schema example at `skills/resolve-repo-context/SKILL.md:92-119` is the canonical return shape; adding a second example forks the contract and creates a "which is correct?" ambiguity for downstream agents that read the schema. The prose at `:121` already states the fallback rule ("use `.claude/claude.md` if present, otherwise fall back to `.github/copilot-instructions.md`"). The minimal fix is to upgrade the `"instructions"` line in the schema to an annotated placeholder that names both forms, keeping a single example block.

### Q2 — m9: placeholder token form (generic placeholder vs neutral example name)

**Resolution**: **Angle-bracketed abstract placeholders** of the shape `<your-domain>`, `<your-service>`, `<service-a>`, `<service-b>`, `<your-stack>`. Where a table currently has 10+ rows of organization-specific examples (e.g., `initialize-monorepo:119-133`), collapse to **2 rows** of `<service-a>` / `<service-b>` shape plus a notes column that names the underlying type (`<.NET solution group>`, `<Angular app>`, etc.).

**Reasoning**: ICON ships byte-equal into consumer plugin installs (see ADR-004 — tool-agnostic content). Concrete-org names train consumer agents on a specific stack's shape; an Angular-app + .NET-solution example primes a Go-monorepo consumer for the wrong path. Angle-bracketed placeholders carry the syntactic intent ("substitute the real value here") that bare neutral nouns ("Frontend", "Backend") do not.

### Q3 — m9: `find-context-template` `datascan-marketplace` default

**Resolution**: **Rename to `your-marketplace`**. Keep the `$MARKETPLACE_NAME` override mechanism unchanged.

**Reasoning**: Two competing facts: (a) `datascan-marketplace` IS the project's own marketplace slug — the default is operationally correct for the team that maintains ICON; (b) ICON is a consumer-facing plugin and the default value seeds consumer expectations. The user said "rewrite to be company-agnostic" without carving an exception for marketplace slug, so the consumer-facing fact wins. `your-marketplace` parallels the `<your-service>` placeholder shape from Q2, signaling "you must set this." Maintainers who fork the marketplace under the canonical name still get the override via `MARKETPLACE_NAME=datascan-marketplace` in their environment.

### Q4 — m-new-A: which surrounding prose to bring along when fixing `copilot-instructions.md` → `.claude/claude.md`

**Resolution**: Replace the single token `copilot-instructions.md` with `.claude/claude.md` on `skills/initialize-workspace/SKILL.md:336`. Do not rewrite surrounding prose; the sibling `initialize-multimodule/SKILL.md:400` line is already the target shape and the workspace line aligns with it after the single-token replacement.

**Reasoning**: ICON-0014 renumber-aware backref hazard cuts both ways — minimal change means minimal collateral. The pre-flight confirmed the sibling at `:400` reads "Review each sub-project's .claude/claude.md and .context/overview.md for accuracy." After the workspace fix it will read "Review each project's .claude/claude.md and .context/overview.md for accuracy" — parallel, no further alignment needed.

### Q5 — Pattern renumbering: renumber 4→3 / 5→4 or leave a numbered gap

**Resolution**: **Renumber 4→3 and 5→4.** Do not leave a gap.

**Reasoning**: The pre-flight confirmed no inline backrefs by number ("see Pattern 3", "as in Pattern 4") exist anywhere in the five briefs. Mechanically safe. A numbered list with a gap ("1, 2, 4, 5") looks like a copy-paste accident to a future reader; the audit-finding-source preference is for clean numbering. Historical research files in `.context/tasks/ICON-0003-*/` and `.context/tasks/ICON-0015-*/` cite Pattern 3/4/5 by number — those are historical and out of scope per the plan, so the rename does not break them (they reference the patterns as they were at the audit-cycle date).

### Q6 — Where to insert the `.context/decisions/` consultation step in each brief

**Resolution**: Insert as a new H2 section **after** `## Prior-Audit Pointer` and **before** `## Forward-Looking Improvements Mandate`. Heading text: `## ADR / Decision-Log Pointer`.

**Reasoning**: The structural shape of `## Prior-Audit Pointer` is "consult prior thinking on this domain before any investigation"; the ADR/Decision-Log pointer is the exact same shape one level up ("consult prior repo-wide decisions before any investigation"). Placing them adjacent reinforces the "read prior thinking first" pattern in the brief's flow. Placing the new section before `## Forward-Looking Improvements Mandate` keeps the "read first → then audit → then improve" ordering intact.

---

## 3. Sub-Task Specs

Each sub-task below names files touched (path:line), before/after text, and any cross-references to add. @coder executes these in any order — sub-tasks are independent.

### Sub-task O-S5 — Entry-point detection primitive

**Files touched**:
- `skills/context-specialist-detect-tree-position/SKILL.md` (append new section)
- `skills/initialize-monorepo/SKILL.md:145-153, :251-266` (detection bash + verification bash)
- `skills/initialize-workspace/SKILL.md:152-160, :257-272` (detection + verification)
- `skills/initialize-multimodule/SKILL.md:146-154, :312-323` (detection + verification)

**Step A — Define the canonical primitive in `context-specialist-detect-tree-position/SKILL.md`.**

After the existing `## Return Value` section (current end of file at line 58), append a new H2 section:

```markdown
## Entry-Point Detection Primitive (callable)

This skill is also the canonical home for the entry-point detection pattern used
by the init orchestrators (`initialize-monorepo`, `initialize-workspace`,
`initialize-multimodule`). The pattern checks whether a directory has a
runtime-ready agent context (both an entry-point instructions file and a
`.context/` directory) and is used in two places per orchestrator: once when
classifying each area as `initialize-repo` vs `upgrade-repo`, and once during
post-run completeness verification.

**Detection form** — branches `initialize-repo` vs `upgrade-repo` for a single
directory:

```bash
# $dir is the directory to check
if { [ -f "$dir/.claude/claude.md" ] || [ -f "$dir/.github/copilot-instructions.md" ]; } && [ -d "$dir/.context" ]; then
  # Already initialized → upgrade-repo
  echo "upgrade-repo  $dir"
else
  # Not initialized → initialize-repo
  echo "initialize-repo  $dir"
fi
```

**Verification form** — used in post-run completeness checks:

```bash
# $dir is the directory to verify; $ok and FAILURES are caller-owned
{ [ -f "$dir/.claude/claude.md" ] || [ -f "$dir/.github/copilot-instructions.md" ]; } || { echo "MISSING entry point (.claude/claude.md or .github/copilot-instructions.md): $dir"; ok=false; }
```

**Why two forms**: detection is a binary route; verification is a soft-fail
check that accumulates into a `FAILURES` array the caller decides what to do
with. Both forms accept `.claude/claude.md` as canonical and
`.github/copilot-instructions.md` as the legacy fallback.

**How callers reference this**: orchestrators substitute the appropriate loop
variable (`$area`, `$folder`, `$project`, `$proj`) for `$dir` in the snippet
below and cross-reference this section rather than re-inlining the full check.
```

**Step B — Update each orchestrator to cross-reference.**

For each of the three orchestrators, replace the **detection** code block with a one-line cross-reference, and replace the **verification** line inside the loop with a one-line cross-reference. The surrounding prose stays.

`initialize-monorepo/SKILL.md` — current `:145-153`:

Before (the lines as they appear):
```bash
for area in "${AREA_LIST[@]}"; do
  if { [ -f "$area/.claude/claude.md" ] || [ -f "$area/.github/copilot-instructions.md" ]; } && [ -d "$area/.context" ]; then
    echo "upgrade-repo  $area"
  else
    echo "initialize-repo  $area"
  fi
done
```

After:
```bash
for area in "${AREA_LIST[@]}"; do
  # Apply the entry-point detection primitive (see
  # context-specialist-detect-tree-position → "Entry-Point Detection Primitive")
  # with $dir=$area.
  if { [ -f "$area/.claude/claude.md" ] || [ -f "$area/.github/copilot-instructions.md" ]; } && [ -d "$area/.context" ]; then
    echo "upgrade-repo  $area"
  else
    echo "initialize-repo  $area"
  fi
done
```

Same code (the runtime needs the literal bash; cross-reference is in a comment so future maintainers see the canonical home). Apply identical comment additions at:
- `initialize-monorepo:251-266` verification block — add the comment on the line above the `{ [ -f ... ]; }` check.
- `initialize-workspace:152-160` (loop var: `$folder`)
- `initialize-workspace:257-272` verification — comment above the `{ [ -f ... ]; }` line.
- `initialize-multimodule:146-154` (loop var: `$proj`)
- `initialize-multimodule:312-323` verification — comment above the `{ [ -f ... ]; }` line.

**Comment text to insert** (use verbatim, with the correct loop variable name in the trailing parenthetical):

For detection blocks:
```
  # Entry-point detection primitive — see
  # context-specialist-detect-tree-position → "Entry-Point Detection Primitive"
  # ($dir=$<loop-var>).
```

For verification blocks:
```
  # Entry-point verification primitive — see
  # context-specialist-detect-tree-position → "Entry-Point Detection Primitive"
  # ($dir=$<loop-var>).
```

**Architectural note**: this is comment-level cross-referencing rather than bash-level sourcing. The bash literal stays inline because (a) shipping a sourcing script would put a runtime dependency between orchestrator skills and a primitive file, violating the "skills are read-and-use markdown" contract; (b) the canonical home is a single grep-discoverable destination so future audit cycles read one canonical block; (c) the comment makes the canonical home visible to the next maintainer without forcing them to read all three orchestrators to deduce the shared shape.

### Sub-task O-S6 + m10 — Phase 3 sampling spec extraction

**Files touched**:
- `skills/upgrade-repo/SKILL.md:336-338` (Phase 3 — promote canonical spec)
- `skills/initialize-monorepo/SKILL.md:228-234` (orchestrator prompt — replace with cross-ref)
- `skills/initialize-workspace/SKILL.md:235-241` (same)
- `skills/initialize-multimodule/SKILL.md:287-293` (same)

**Step A — Promote the sampling spec inside `upgrade-repo/SKILL.md` Phase 3.**

Current `:336-338`:
```markdown
### upgrade-repo: Phase 3: Content Currency (delegate)

Infrastructure and content currency are separate concerns. After upgrading infrastructure, if documentation has also drifted from the codebase, invoke `context-maintenance` to handle it — that skill owns the content refresh workflow. Do not touch `META.md`, `retrospectives.md`, or `tasks/` as part of this delegation.
```

Replace with:
```markdown
### upgrade-repo: Phase 3: Content Currency (delegate)

Infrastructure and content currency are separate concerns. After upgrading infrastructure, run the **content-currency sample check** below; only invoke `context-maintenance` if the sample indicates real drift. Do not touch `META.md`, `retrospectives.md`, or `tasks/` as part of this delegation.

**Content-currency sample check** (canonical spec — orchestrators reference this section):

Spot-check 5 random class names, function names, type names, or file paths from `.context/domains/*.md` against the codebase using `grep`. If at least 2 of the 5 are absent from the codebase, invoke `context-maintenance` to run a full audit; otherwise skip the content refresh. `context-maintenance` owns the full content refresh workflow when invoked.
```

**Step B — Collapse the three orchestrator prompts to a one-line cross-reference.**

`initialize-monorepo/SKILL.md:228-234` (the `upgrade-repo` prompt's Phase 3 paragraph). Current text:
```
Load and execute the `upgrade-repo` skill:
complete Phase 1 (audit), Phase 2 (infrastructure upgrade), and Phase 4
(verify and commit). For Phase 3 (content currency): spot-check 5 random class names, function names, type names, or file paths from
`.context/domains/*.md` against the codebase using grep; if at least 2 of the 5
are absent from the codebase, invoke `context-maintenance` to run a full audit;
otherwise skip Phase 3.
Do not touch META.md, retrospectives.md, or tasks/.
```

Replace with:
```
Load and execute the `upgrade-repo` skill — Phase 1 (audit), Phase 2
(infrastructure upgrade), Phase 3 (content currency, per the canonical
sample-check spec inside `upgrade-repo` Phase 3), and Phase 4 (verify and
commit). Do not touch META.md, retrospectives.md, or tasks/.
```

Apply identical replacements to:
- `initialize-workspace/SKILL.md:235-241`
- `initialize-multimodule/SKILL.md:287-293`

**Architectural note**: this is true single-source-of-truth — the bash-like detail lives once in `upgrade-repo`, and orchestrators carry a reference. The orchestrator prompt is consumed by a sub-agent that will load `upgrade-repo` next anyway, so the reference is immediately resolvable.

### Sub-task m3 — `find-context-template` PowerShell separator

**Files touched**: `skills/find-context-template/SKILL.md:41-42`.

Current:
```powershell
$MarketplaceName = if ($env:MARKETPLACE_NAME) { $env:MARKETPLACE_NAME } else { "datascan-marketplace" }
$TEMPLATE_DIR = "$CopilotHome\installed-plugins\$MarketplaceName\ICON\context_template"
```

After (note: `datascan-marketplace` → `your-marketplace` from Q3; PowerShell `\` → `/`):
```powershell
$MarketplaceName = if ($env:MARKETPLACE_NAME) { $env:MARKETPLACE_NAME } else { "your-marketplace" }
$TEMPLATE_DIR = "$CopilotHome/installed-plugins/$MarketplaceName/ICON/context_template"
```

Also update `:40`:

Current:
```powershell
$CopilotHome = if ($env:COPILOT_HOME) { $env:COPILOT_HOME } else { "$HOME\.copilot" }
```

After:
```powershell
$CopilotHome = if ($env:COPILOT_HOME) { $env:COPILOT_HOME } else { "$HOME/.copilot" }
```

And `:108` (the post-discovery example):

Current:
```powershell
Copy-Item "$TEMPLATE_DIR\context\META.md" .context\
```

After:
```powershell
Copy-Item "$TEMPLATE_DIR/context/META.md" .context/
```

**Architectural note**: PowerShell on Windows tolerates `/` as a path separator across `Test-Path`, `Copy-Item`, and string interpolation. Normalizing to `/` makes bash + PowerShell snippets visually parallel, which reduces the cognitive cost of cross-shell maintenance. No functional change.

### Sub-task m5 — Schema fallback annotation

**Files touched**: `skills/resolve-repo-context/SKILL.md:99`.

Current:
```json
    "instructions": "/absolute/path/.claude/claude.md",
```

After (annotate inline with the fallback rule):
```json
    "instructions": "/absolute/path/.claude/claude.md",  // canonical; falls back to /absolute/path/.github/copilot-instructions.md if not present
```

The prose at `:121` already states the fallback rule and stays unchanged. The annotation keeps the JSON example a single canonical block (per Q1 resolution) and reduces the read-distance between schema and rule from ~25 lines to 0.

**Architectural note**: JSON examples in skills are read by sub-agents as the binding return shape. An annotated comment is `JSON-with-comments` style, which downstream parsers may reject — but this is a documentation example, not parsed input. The trailing `//` comment is the lowest-friction way to inline-annotate.

### Sub-task m9 — Generalize organization-specific examples

**Files touched**: `initialize-monorepo`, `initialize-workspace`, `initialize-multimodule`, `context-specialist-impl-root` SKILL.md files. Per Q2, use angle-bracketed placeholders.

**`skills/initialize-monorepo/SKILL.md:72`** — Rule 1 description:

Current:
```
solution group folders** — NOT individual `.csproj` files. In a .NET
solution the solution groups appear as top-level logical folders (e.g.,
`RestApi`, `Services`, `DataProvider`, `Integrations`) and each one maps
to a directory containing multiple related `.csproj` projects.
```

After:
```
solution group folders** — NOT individual `.csproj` files. In a .NET
solution the solution groups appear as top-level logical folders (e.g.,
`<service-a>`, `<service-b>`, `<data-provider>`, `<integrations>`) and each one
maps to a directory containing multiple related `.csproj` projects.
```

**`skills/initialize-monorepo/SKILL.md:119-133`** — replace the entire example table with a collapsed version:

Current (15 example rows of org-specific .NET + Angular names):
```markdown
| # | Area Path | Notes |
|---|-----------|-------|
| 1 | `src/RestApi` | .NET solution group |
| 2 | `src/Services` | .NET solution group |
| 3 | `src/DataProvider` | .NET solution group |
| 4 | `src/Infrastructure` | .NET solution group |
| 5 | `src/Integrations` | .NET solution group |
| 6 | `src/Importer` | .NET solution group |
| 7 | `src/NotificationService` | .NET solution group |
| 8 | `src/TaskRunner` | .NET solution group |
| 9 | `src/Tools` | .NET solution group |
| 10 | `src/DataScan.RiskGauge.WebApp` | Angular app |
| 11 | `src/DataScan.AdminDashboard.WebApp` | Angular app |
```

After (2 placeholder rows + a third labeled Angular-app row to preserve the "mixed types in one repo" hint):
```markdown
| # | Area Path | Notes |
|---|-----------|-------|
| 1 | `src/<service-a>` | <.NET solution group> |
| 2 | `src/<service-b>` | <.NET solution group> |
| 3 | `src/<your-webapp>` | <Angular app> |
```

**`skills/initialize-monorepo/SKILL.md:159-160`** — Step 2 example table:

Current:
```markdown
| Area Path | Action |
|-----------|--------|
| `src/RestApi` | `initialize-repo` |
| `src/Services` | `upgrade-repo` |
```

After:
```markdown
| Area Path | Action |
|-----------|--------|
| `src/<service-a>` | `initialize-repo` |
| `src/<service-b>` | `upgrade-repo` |
```

**`skills/initialize-monorepo/SKILL.md:355`** — Common Mistakes table row:

Current:
```
| Using individual `.csproj` files as project roots in a .NET solution | Use solution group directories (e.g., `src/RestApi`) — typically 8–12 groups, not 50+ files |
```

After:
```
| Using individual `.csproj` files as project roots in a .NET solution | Use solution group directories (e.g., `src/<service-a>`) — typically 8–12 groups, not 50+ files |
```

**`skills/initialize-workspace/SKILL.md:64-66`** — Step 0 example resolution table:

Current:
```markdown
| 1 | `/dev/workspace` | `.` (workspace root) |
| 2 | `/dev/ngWi` | `../ngWi` |
| 3 | `/dev/wi-ui-service` | `../wi-ui-service` |
| 4 | `/dev/seed_data` | `../seed_data` |
```

After:
```markdown
| 1 | `/dev/<workspace>` | `.` (workspace root) |
| 2 | `/dev/<service-a>` | `../<service-a>` |
| 3 | `/dev/<service-b>` | `../<service-b>` |
| 4 | `/dev/<resource-folder>` | `../<resource-folder>` |
```

**`skills/initialize-workspace/SKILL.md:128`** — Step 2 resource definition:

Current:
```
Examples: `seed_data`, locale files, WMS schema references, online help.
```

After:
```
Examples: seed-data folders, locale files, schema references, online help.
```

**`skills/initialize-workspace/SKILL.md:135-140`** — Step 2 decision table:

Current:
```markdown
| # | Folder | Classification | Action |
|---|--------|---------------|--------|
| 1 | `/dev/workspace` | workspace root | project-level context (Step 4) + workspace-level context (Step 6) |
| 2 | `/dev/ngWi` | project | initialize-repo or upgrade-repo |
| 3 | `/dev/wi-ui-service` | project | initialize-repo or upgrade-repo |
| 4 | `/dev/seed_data` | resource | skip |
```

After:
```markdown
| # | Folder | Classification | Action |
|---|--------|---------------|--------|
| 1 | `/dev/<workspace>` | workspace root | project-level context (Step 4) + workspace-level context (Step 6) |
| 2 | `/dev/<service-a>` | project | initialize-repo or upgrade-repo |
| 3 | `/dev/<service-b>` | project | initialize-repo or upgrade-repo |
| 4 | `/dev/<resource-folder>` | resource | skip |
```

**`skills/initialize-workspace/SKILL.md:326`** — MR summary example:

Current:
```markdown
- Added .claude/claude.md and .context/ for: ngWi, wi-ui-service
```

After:
```markdown
- Added .claude/claude.md and .context/ for: <service-a>, <service-b>
```

**`skills/initialize-multimodule/SKILL.md:160-161`** — Step 3 example decision table:

Current:
```markdown
| Sub-Project Path | Action |
|-----------------|--------|
| `wms-api/` | `initialize-repo` |
| `wms-frontend/` | `upgrade-repo` |
```

After:
```markdown
| Sub-Project Path | Action |
|-----------------|--------|
| `<service-a>/` | `initialize-repo` |
| `<service-b>/` | `upgrade-repo` |
```

**`skills/initialize-multimodule/SKILL.md:363`** — Step 7b README template:

Current:
```markdown
| wms-api | wms-api/ | <derived from overview.md> |
```

After:
```markdown
| <service-a> | <service-a>/ | <derived from overview.md> |
```

**`skills/context-specialist-impl-root/SKILL.md:64-65`** — Step 2 projects.md format example:

Current:
```markdown
| RestApi | src/RestApi | Main and admin REST APIs, API gateway | .NET 8 / C# |
| Services | src/Services | Business logic services layer | .NET 8 / C# |
```

After:
```markdown
| <service-a> | src/<service-a> | <one-sentence description from overview.md> | <language/stack> |
| <service-b> | src/<service-b> | <one-sentence description from overview.md> | <language/stack> |
```

**Architectural note**: m9 is purely a generalization sweep; no logic changes. The risk is missing an org-specific token. The pre-flight enumerated all the tokens — @coder treats the list above as the closed set, then runs the Acceptance Gate grep below to verify zero residue.

### Sub-task m-new-A — Workspace MR template stale ref

**Files touched**: `skills/initialize-workspace/SKILL.md:336`.

Current:
```
Review each project's copilot-instructions.md and .context/overview.md for
accuracy. Verify `projects.md` in .context/ lists all projects with correct paths.
```

After:
```
Review each project's .claude/claude.md and .context/overview.md for
accuracy. Verify `projects.md` in .context/ lists all projects with correct paths.
```

Per Q4: single-token replacement only.

### Sub-task ADR-009 — Won't-fix policy ADR

See **§4** below for the full ADR body. Two file actions:

1. Create `.context/decisions/009-skill-description-callers.md` with the body in §4.
2. Append one row to the Decision Log table in `.context/decisions/README.md:39` (immediately after the ADR-008 row):

```markdown
| [009](009-skill-description-callers.md) | Skill `description` frontmatter does not enumerate callers | Accepted | 2026-05-22 |
```

### Sub-task brief-edits — Common Check Pattern 3 removal + ADR pointer

**Files touched** (identical edit pattern × 5):
- `skills/plugin-audit/briefs/01-agents.md:48`
- `skills/plugin-audit/briefs/02-process-skills.md:47`
- `skills/plugin-audit/briefs/03-context-specialist-init.md:50`
- `skills/plugin-audit/briefs/04-utility-skills.md:55`
- `skills/plugin-audit/briefs/05-infrastructure.md:72`

**Edit 1 — Remove Pattern 3 and renumber 4→3, 5→4 (per Q5).**

Current shape of the Common Check Patterns list (varies in domain example wording but the 5 items are byte-identical across all 5 briefs):

```markdown
## Common Check Patterns

Apply each pattern below to every file in scope. Either report a finding or note "no instances" — silent omission is treated as missed coverage.

1. **Self-reference violation** — Does this skill or agent follow its own rules? (E.g., a `writing-skills` document that exceeds its own length cap.)
2. **Template / standard cross-reference** — Does this skill cite the template, standard, or workflow document that callers are expected to follow? Drift risk if the cited template diverges.
3. **Caller-listing in description** — Does the frontmatter `description` name every agent that invokes this skill? Missing callers reduce discoverability and obscure ownership.
4. **Operational defensiveness** — For any skill that writes, releases, or mutates state: is there a dry-run mode, idempotency guarantee, or partial-failure recovery path?
5. **Frontmatter parser-fragility** — Are descriptions in `>` folded scalar form, or do they mix indentation? Parser-fragile frontmatter breaks grep-based discovery and CI lint.
```

After:
```markdown
## Common Check Patterns

Apply each pattern below to every file in scope. Either report a finding or note "no instances" — silent omission is treated as missed coverage.

1. **Self-reference violation** — Does this skill or agent follow its own rules? (E.g., a `writing-skills` document that exceeds its own length cap.)
2. **Template / standard cross-reference** — Does this skill cite the template, standard, or workflow document that callers are expected to follow? Drift risk if the cited template diverges.
3. **Operational defensiveness** — For any skill that writes, releases, or mutates state: is there a dry-run mode, idempotency guarantee, or partial-failure recovery path?
4. **Frontmatter parser-fragility** — Are descriptions in `>` folded scalar form, or do they mix indentation? Parser-fragile frontmatter breaks grep-based discovery and CI lint.
```

**Edit 2 — Insert the `## ADR / Decision-Log Pointer` section.**

Per Q6: insert immediately after `## Prior-Audit Pointer` and before `## Forward-Looking Improvements Mandate`. Use the identical block in all 5 briefs:

```markdown
## ADR / Decision-Log Pointer

Read `.context/decisions/README.md` before any investigation. The Decision Log records ICON-wide architectural decisions including scope carve-outs for rules a naive grep would otherwise re-flag. Specifically:

- **ADR-007** (`2>/dev/null` ban scope) — the ban applies to agent-invoked commands only. Findings in autonomous scripts (`.githooks/*`, `context_template/context/workflows/*.sh`, `.claude/skills/*/scripts/*.sh`, `skills/*/scripts/*.sh`) are out of scope. Do not tier such findings as Minor.
- **ADR-009** (skill `description` callers) — skill frontmatter `description` fields are not required to enumerate callers; missing caller lists are not a defect. Do not tier such findings as Minor.

For any other ADR in the Decision Log that bears on this brief's domain, apply the same "consult before tiering" rule.
```

**Architectural note**: Edit 1 is a 1-line deletion plus 2-line renumber per brief. Edit 2 is a 7-line insertion per brief. Both edits sit inside `## Common Check Patterns` / `## Prior-Audit Pointer` neighborhoods so the ICON-0027 inverse-phrasing sweep gate (below) catches any remaining instance of "caller-listing" as a defect class elsewhere in the briefs.

---

## 4. ADR-009 Full Body

Drop the following verbatim into `.context/decisions/009-skill-description-callers.md`:

```markdown
# ADR-009: Skill `description` frontmatter does not enumerate callers

**Date**: 2026-05-22
**Status**: Accepted

## Context

Common Check Pattern 3 ("Caller-listing in description") has shipped in all five `skills/plugin-audit/briefs/*.md` files since the briefs were first written. The pattern instructs reviewers to flag any skill whose frontmatter `description` does not name every agent or skill that invokes it; missing callers were claimed to "reduce discoverability and obscure ownership." The pattern has been applied across multiple audit cycles (MKT-numbered, ICON-0003, ICON-0015) and has produced steady Minor-tier findings in each cycle — most of them carry-forwards from the prior cycle, because the underlying rule produces a maintenance burden the team has not opted into.

The maintainer's position (issue #20, 2026-05-22 comment) is direct: "what is the purpose of listing callers? It just takes up context for no value." The position is structurally sound for three reasons:

1. **Caller lists are read-rarely / write-often.** A skill's `description` is loaded by every agent that has the skill in its searchable catalog — that loading happens hundreds of times per release cycle. The caller list is read only when a maintainer is editing the skill. The token cost is paid every load; the discoverability benefit is realized once per edit cycle.
2. **Caller lists drift.** When a new agent starts using a skill, the skill's `description` has no automated reminder to add the new caller. Drift accumulates silently and the lists become stale, at which point they actively mislead — a worse outcome than no list at all.
3. **Discoverability is structurally elsewhere.** Skill discoverability is provided by the skill catalog (loaded by `using-skills` and by per-tool harness skill-search mechanisms), not by reading 50+ `description` fields looking for one's own agent name. Ownership, when it matters, is recorded in `.context/decisions/` and in retrospectives, not in skill frontmatter.

## Decision

Skill `description` frontmatter fields are **not required** to enumerate the agents or skills that invoke them.

Reviewers and audit briefs must not tier a missing caller list as a defect of any severity. Concretely:

- Common Check Pattern 3 ("Caller-listing in description") is removed from all five `plugin-audit/briefs/*.md` files in the same commit as this ADR is accepted.
- Future audit cycles that surface "skill X does not list its callers" findings are out of scope of the audit and should not be raised as Minor or higher.
- The remaining Common Check Patterns (Self-reference violation, Template / standard cross-reference, Operational defensiveness, Frontmatter parser-fragility) continue to apply unchanged.

This decision does not prohibit caller mentions in `description` — a skill author may name a primary caller if the relationship is load-bearing for the skill's purpose (e.g., "Internal @context-specialist skill. Do not invoke without explicit direction." is an ownership signal, not a caller enumeration). The prohibition is specifically on auditing for completeness of the list.

## Consequences

**Positive:**
- Audit cycles stop re-surfacing caller-list findings as carry-forward Minors.
- Skill authors do not need to maintain a hand-tracked list of callers that drifts the moment a new agent invokes the skill.
- The always-loaded surface stays smaller — `description` fields ship into every agent's catalog and skill-discovery context, so trimming optional content is a net token-budget win (see ADR-008 framing for the dispatcher token budget).

**Negative:**
- Discoverability of "who uses this skill?" falls back on grep across the repo (`grep -rn 'skill: <name>'` or `grep -rn 'Load and execute the .<name>. skill'`) rather than a frontmatter field. For maintainers actively touching the skill, this is a one-command lookup; for casual readers, the lookup never happened anyway.
- Authors who previously listed callers as documentation cannot rely on the audit to keep those lists honest. The lists either need to be removed proactively when they go stale, or the author accepts that staleness is now an unaudited surface.

## Alternatives Considered

1. **Soft-deprecate Pattern 3 (keep it in briefs, mark "advisory only").** Rejected — the audit briefs already produce too much "advisory only" output and reviewers cannot reliably distinguish advisory from binding when both appear in the same Common Check Patterns list. A hard delete is cleaner.
2. **Replace Pattern 3 with a "callers documented somewhere" rule.** Rejected — moves the maintenance burden from `description` to a separate doc surface without removing the underlying drift problem. The cost was the maintenance, not the location.
3. **Keep Pattern 3 but exempt specific skill categories.** Rejected — every category exemption adds a tiering decision per finding. The blanket removal aligns with the maintainer's stated rationale ("no value"), and any future exception can be a per-skill author decision rather than an audit-cycle policy.

## Cross-references

- Maintainer rationale: GitLab issue #20 comment, 2026-05-22.
- Sister scope-carveout ADR: [ADR-007](007-devnull-ban-scope.md) — both ADRs are scope carve-outs that prevent audit cycles from re-flagging findings the maintainer has consciously declined to act on. ADR-007 carves out a domain (autonomous scripts); ADR-009 carves out a check pattern (caller-listing).
- Affected briefs (all updated in the same commit):
  - `skills/plugin-audit/briefs/01-agents.md`
  - `skills/plugin-audit/briefs/02-process-skills.md`
  - `skills/plugin-audit/briefs/03-context-specialist-init.md`
  - `skills/plugin-audit/briefs/04-utility-skills.md`
  - `skills/plugin-audit/briefs/05-infrastructure.md`
- ADR-consultation step added to each brief above so the next audit cycle reads this ADR before tiering.
```

---

## 5. Acceptance Gates

After implementing all sub-tasks, @coder runs each of the following commands from the repo root and pastes the literal output into the completion report. @reviewer re-runs each command before approving. Every gate must produce the expected output character-equal; deviations are findings.

These commands run in the @coder's CLI session (agent-invoked), so the `2>/dev/null` ban applies — none of the commands below use it. (Per ADR-007, the ban is agent-invoked only; this gate set is firmly inside that scope.)

### Gate G1 — Org-specific tokens fully removed (m9 + Q3)

```bash
grep -rn -E '\b(RestApi|DataProvider|NotificationService|TaskRunner|RiskGauge|AdminDashboard|ngWi|wi-ui-service|seed_data|wms-api|wms-frontend|datascan-marketplace)\b' \
  skills/initialize-monorepo/ \
  skills/initialize-workspace/ \
  skills/initialize-multimodule/ \
  skills/context-specialist-impl-root/ \
  skills/find-context-template/
```

Expected output: **empty** (no matches). Any line returned is a residue token and a Critical finding.

### Gate G2 — Pattern 3 removed from all 5 briefs (won't-fix sweep)

```bash
grep -n "Caller-listing in description" skills/plugin-audit/briefs/*.md
```

Expected output: **empty**.

```bash
grep -c "^[0-9]\." skills/plugin-audit/briefs/01-agents.md \
                   skills/plugin-audit/briefs/02-process-skills.md \
                   skills/plugin-audit/briefs/03-context-specialist-init.md \
                   skills/plugin-audit/briefs/04-utility-skills.md \
                   skills/plugin-audit/briefs/05-infrastructure.md
```

Expected output: each file reports `4` numbered list items in `## Common Check Patterns` (the count includes the 4 surviving patterns; if any brief has other numbered lists in additional sections, expect that number plus 4). If a file reports a count that does not match Pattern-1..4 plus that brief's known other numbered lists, investigate.

### Gate G3 — ADR consultation step present in all 5 briefs

```bash
grep -c "^## ADR / Decision-Log Pointer$" skills/plugin-audit/briefs/01-agents.md \
                                          skills/plugin-audit/briefs/02-process-skills.md \
                                          skills/plugin-audit/briefs/03-context-specialist-init.md \
                                          skills/plugin-audit/briefs/04-utility-skills.md \
                                          skills/plugin-audit/briefs/05-infrastructure.md
```

Expected output: each file reports `1`.

### Gate G4 — ADR-009 file exists and is in the Decision Log

```bash
test -f .context/decisions/009-skill-description-callers.md && echo "ADR-009 PRESENT" || echo "ADR-009 MISSING"
grep -c "^| \[009\]" .context/decisions/README.md
```

Expected output: `ADR-009 PRESENT` and `1`.

### Gate G5 — Entry-point detection primitive section present

```bash
grep -n "^## Entry-Point Detection Primitive" skills/context-specialist-detect-tree-position/SKILL.md
grep -c "Entry-point detection primitive — see" skills/initialize-monorepo/SKILL.md \
                                                skills/initialize-workspace/SKILL.md \
                                                skills/initialize-multimodule/SKILL.md
grep -c "Entry-point verification primitive — see" skills/initialize-monorepo/SKILL.md \
                                                   skills/initialize-workspace/SKILL.md \
                                                   skills/initialize-multimodule/SKILL.md
```

Expected output:
- First command: one line, the line number of the new H2 (non-empty).
- Second and third commands: each file reports `1`.

### Gate G6 — Phase 3 canonical spec lives in upgrade-repo, orchestrators cross-reference it

```bash
grep -n "Content-currency sample check" skills/upgrade-repo/SKILL.md
grep -c "spot-check 5 random class names" skills/initialize-monorepo/SKILL.md \
                                          skills/initialize-workspace/SKILL.md \
                                          skills/initialize-multimodule/SKILL.md
grep -c "canonical sample-check spec inside .upgrade-repo. Phase 3" skills/initialize-monorepo/SKILL.md \
                                                                    skills/initialize-workspace/SKILL.md \
                                                                    skills/initialize-multimodule/SKILL.md
```

Expected output:
- First command: one line, the line number of the canonical spec in `upgrade-repo`.
- Second command: each orchestrator file reports `0` (the bash-like spec is no longer inlined).
- Third command: each orchestrator file reports `1` (the cross-reference is present).

### Gate G7 — PowerShell separator normalized in `find-context-template`

```bash
grep -n '\\' skills/find-context-template/SKILL.md
```

Expected output: **empty** (no remaining backslash literals in path strings). If any line returns, inspect whether it is a legitimate PowerShell escape (none should exist after this task) or a residue separator.

### Gate G8 — `resolve-repo-context` schema annotated

```bash
grep -n "falls back to" skills/resolve-repo-context/SKILL.md
```

Expected output: one line at `:99` containing the inline `// canonical; falls back to ...` annotation.

### Gate G9 — Workspace MR template fix landed

```bash
grep -n "copilot-instructions.md" skills/initialize-workspace/SKILL.md
```

Expected output: the only remaining matches should be the **legitimate** detection/verification references (lines `:149`, `:154`, `:261`) — never `:336`. If `:336` is in the output, the m-new-A fix did not land.

### Gate G10 — Inverse-phrasing sweep (ICON-0027 hazard)

```bash
grep -rn -i -E "(caller.list|enumerate.callers|name every (agent|skill) that)" \
  skills/plugin-audit/
```

Expected output: **empty**. If a brief or `synthesis-template.md` carries an inverse-phrased version of Pattern 3 (e.g., "name every agent that invokes this skill"), the sweep is incomplete.

### Gate G11 — Renumber-aware backref check (ICON-0014 hazard)

```bash
grep -rn -E "Pattern (3|4|5)\b" skills/plugin-audit/briefs/
```

Expected output: **empty** (no brief contains an inline backref to "Pattern 3", "Pattern 4", or "Pattern 5" by number outside the numbered list itself). If a brief references "Pattern 5" in prose, the renumber has stranded a backref.

### Gate G12 — BSD/GNU portability check (ICON-0030 hazard)

```bash
echo "skip — no new bash gates introduced by this task"
```

The task does not add any new `find` / `grep` / `sed` invocations to shipped skill files; all bash in scope is read-only `grep` in the gates above. BSD-vs-GNU `find -printf` and `sed -i ''` are not in play. Gate G12 is a named pass-through to document that the axis was considered.

### Gate G13 — Plugin lint passes

```bash
bash .claude/skills/release-plugin/scripts/plugin-lint.sh
```

Expected output: exit code 0, no `>/dev/null` findings, no manifest parse errors. (This is the pre-existing manifest validator; the task's edits stay inside the agent-invoked surface and should not trip the lint.)

---

## 6. Risk Axes Named For Reviewer

Per process-sweeps.md § Reviewer Pass Cadence, naming the cross-surface risk axes turns Pass 1 into a covering check. @reviewer must explicitly verify each axis below.

| Axis | What to verify | Pre-flight finding |
|---|---|---|
| **ICON-0014 renumber-aware backref** | After 4→3 / 5→4 renumber, no brief carries an inline backref by number ("Pattern 3", "Pattern 4", "Pattern 5") outside the numbered list. Gate G11 enforces. | Pre-flight confirmed zero inline backrefs in current state; the renumber is mechanically safe. |
| **ICON-0027 inverse-phrasing sweep** | Pattern 3 removal is complete only if no inverse phrasing of "name every caller" re-instantiates the rule elsewhere. Gate G10 enforces against `briefs/`, `synthesis-template.md`, and the rest of `skills/plugin-audit/`. | Pre-flight confirmed the phrase appears nowhere else in `skills/plugin-audit/`. Any new occurrence in the implementation diff is a regression. |
| **ICON-0030 BSD/GNU portability** | Any new bash gate must work on both BSD (macOS default) and GNU (Linux default) tooling. The task adds gates G1-G13 to this spec but no new bash to shipped skills — all gates use plain `grep`, `test`, `echo`, no `-printf`, no `sed -i ''`. Gate G12 is the documented pass-through. | No portability hazard introduced. |
| **ICON-0026 three-surface rule** | The task does not touch any `.context/workflows/` doc; per plan.md `## Constraints`, the three-surface check is N/A. Reviewer verifies the diff does not accidentally touch `context_template/context/workflows/*` or `.context/workflows/*` (it should not). | Pre-flight confirmed clear; do not invent enforcement. |
| **ADR-007 carveout active** | The acceptance gates above run from the @coder's CLI session and therefore live inside the `2>/dev/null` ban scope. None of the gates use suppression. | Verified in §5 by inspection. |
| **ADR-009 carveout active for next cycle** | After this task, the next audit cycle's brief reading must reach the `## ADR / Decision-Log Pointer` section before the `## Common Check Patterns` section. Gate G3 enforces the section exists; the structural placement (after Prior-Audit Pointer, before Forward-Looking Improvements Mandate per Q6) enforces the read order. | Verified by Q6 resolution and Edit 2 placement spec. |

---

## 7. Implementation Notes for @coder

- Work in any order across sub-tasks. They are independent.
- All path:line numbers in §3 are accurate as of the pre-flight Explore (2026-05-22 morning). If a file has shifted between the pre-flight and your edit pass, re-locate by the surrounding prose snippet rather than the line number.
- The Common Check Pattern list is byte-identical across all 5 briefs. A single sed-like edit per brief is acceptable; verify Gate G2 catches any miss.
- After all edits, run Gates G1-G13 in order. Paste each command's literal output into the completion report. Do not summarize the output ("all pass" is not acceptance evidence — the literal output is).
- Do not edit `.context/tasks/ICON-0003-*/`, `.context/tasks/ICON-0015-*/`, `briefs/06-cross-cutting.md`, or `synthesis-template.md`. These are explicitly out of scope and Gate G10 will catch incidental edits to `synthesis-template.md`.
- The plan.md `## Progress` checklist will be updated at the reconcile-plan step after @reviewer signs off. Do not check off items in plan.md during implementation.
