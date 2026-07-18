# ICON-0081 — Context Knowledge Graph: Design

**Author:** @architect (design-first pass)
**Status:** Signed off — **fuller build approved.** User accepted Mechanism 3 (script) **AND** the format seams (§7) **AND** the fail-closed pre-commit `--check` gate (§8) in this task. `tasks/*/plan.md` excluded (confirmed). ADR-012 promotion confirmed at the fuller scope.
**Scope of this document:** design only. No code, agent, skill, or template edits. A later @coder implements from this after sign-off.

> **Reading order:** §§1-3 and §4's model/rationale stand as originally designed. §4's *changed-file set* and §6's *ADR capture block* are **superseded by the fuller-scope versions** — see §7 (format-seam spec), §8 (pre-commit gate spec), §9 (revised changed-file set + backfill), and the revised risk table (§5) and ADR block (§6). Where the original §4 says "Reject Mechanism 2 for v1 / no `context_template/` touch / no iconrc bump," that is **overridden** by the sign-off: the format seam ships now, `context_template/` IS touched, and `iconrc.json` bumps 1.8 → 1.9.

---

## Architectural Assessment: In-memory, on-demand `.context/` knowledge graph

### Summary

Extend ICON's context read and write paths so a transitively-traversable graph of `.context/` — built on demand from *edge signals that already exist in the current document format* — is available at two points: **discovery** (manager reads the full reachable set, not a flat directory listing) and **maintenance** (the audit catches dangling links, orphaned/unreachable files, and index gaps across the whole tree, not just the three rule directories). The graph is materialized by a new plugin-local, portable script; it is never persisted.

### Recommendation

**Decision: Approve with modifications — Mechanism 3 (script-materialized), with a thin procedural layer. Reject Mechanism 2 (format-augmented) for v1.**

**Rationale (short form; full weighing in § Recommended Mechanism):** The edge signals needed for "full discoverability" already exist in the format (rules-index rows, prose `[text](path)` links, ADR supersedes, folder index tables, retrospective promotions). A script can extract them deterministically and hand the agent a compact adjacency list, which is far more reliable than asking an agent to "mentally build a graph" (Mechanism 1) and far cheaper in ripple than making edges first-class format seams (Mechanism 2, which forces the `context_template/` version-bump gate and ships a format change to every consumer). One script, two modes (`--emit` for read, `--check` for write) reuses a single parser and honors ADR-005 (committed source run in-place) and ADR-004 (bash + PowerShell parity).

---

## 1. Graph Model

### Node types (CLOSED set — all are existing `.context/` document types)

Every node is a file (or, for folder-split rules, a folder) already present in `.context/`. No new node kinds are invented.

| Node type | Path pattern | Role |
|---|---|---|
| `overview` | `overview.md` | Discovery root (leaf repo) |
| `projects` | `projects.md` | Discovery root (branch/root repo) — sub-project map |
| `rules-index` | `rules-index.md` | Index node — the existing edge table into the 3 rule dirs |
| `domain` | `domains/*.md` | Area knowledge |
| `standard` | `standards/*.md`, `standards/*/` | Convention (folder or file) |
| `workflow` | `workflows/*.md`, `workflows/*/` | Process (folder or file) |
| `decision` | `decisions/NNN-*.md` | ADR |
| `architecture` | `architecture/*.md` | System design |
| `testing` | `testing/*.md` | Test strategy |
| `styling` | `styling/*.md` | UI conventions |
| `folder-index` | any `*/README.md` | Folder split index table |
| `retrospective` | `retrospectives.md` (per-entry) | Lesson provenance source |
| `config` | `iconrc.json` | Coverage / excludes source |
| `task` | `tasks/*/plan.md` | Ephemeral — **excluded by default** (see note) |

*Note on `task` nodes:* task folders are transient and pruned at close. They are excluded from the default node set to avoid orphan-check noise; `--emit` may include them behind a flag if a task genuinely needs its plan in the reachable set, but the write-side check never flags a `tasks/*` file as an orphan.

### Edge types (CLOSED set — each derived from one existing format signal)

No edge type requires a format change. Each maps to a signal the exploration already confirmed present.

| Edge | Direction | Source signal (already in format) | Used by |
|---|---|---|---|
| `references` | source-doc → target-doc | prose Markdown `[text](path)` link resolving under `.context/` | read + write |
| `indexed-by` | rule-file → `rules-index` | a `rules-index.md` File-column row links to the rule file | write (completeness) |
| `supersedes` / `superseded-by` | ADR → ADR | ADR body `**Status**: Superseded by ADR-NNN` prose | read + write |
| `covers` | folder-index → child-doc | a `README.md` / `projects.md` index-table row links a child | read (containment) |
| `promoted-from` | retro-entry → target-doc | retrospective `Promoted to: <file>` note | write (provenance) |
| `excludes` | `config` → path | `iconrc.json` `excludes` glob | write (negative coverage) |

**`references` is the primary transitive edge** — it is what delivers "no related context is missed," and it is the one edge that reaches `domains/` (which has no rules-index rows today). The graph is a directed multigraph; traversal for discovery follows `references`, `covers`, and `supersedes` transitively.

### The one honest gap (and the only candidate format seam — deferred)

By-name prose references — `skill § Section`, or "the auth pattern in `domains/auth.md`" written without a Markdown link — are **not reliably machine-parseable** and will be missed by any non-LLM parser. The script captures explicit `[text](path)` links only. This is acceptable because (a) the thin procedural layer keeps light semantic linking as the agent's job, and (b) the fix, if ever needed, is a *format seam* (a convention or lint that prefers Markdown links over bare by-name prose). That seam is Mechanism 2 territory — it touches `context-document-guidelines`, the generators, and `context_template/` (forcing the iconrc bump). **Deferred to a follow-up gated on evidence** that link coverage is materially incomplete. Do not build it in v1 (YAGNI — no measured consumer yet).

---

## 2. Read Side — On-demand build + transitive traversal

**Insertion point:** `agents/manager.agent.md:88-103` (§ Context Discovery), step 2, after the existing "read `rules-index.md` first" line. **The heavy logic goes into an on-demand skill, not into the always-loaded manager prose** (ADR-008 — see cost bound below).

### Build

A new portable script `context-graph.{sh,ps1}` (default `--emit` mode) parses every `.context/` file once and writes a compact adjacency listing to stdout:

```
# NODES
domains/github-access.md
standards/security.md
...
# EDGES
references	domains/github-access.md	standards/security.md
supersedes	decisions/006-...md	(superseded)
covers	workflows/task-plan/README.md	workflows/task-plan/phase-architecture.md
...
```

Paths and edge types only — **never file contents.** The agent reads this listing, seeds from the nodes the task points at (rules-index rows + files named in the task description), and does a bounded breadth-first traversal over `references`/`covers`/`supersedes` out-edges, collecting the reachable set, then reads *those* files. That is the transitive step absent today.

### Always, or only when discovery would otherwise miss something? (ADR-008)

**On-demand, gated by task complexity — never at every task start.** The trigger reuses the manager's existing planning heuristic:

- **Simple tasks** (single-file fix, unambiguous scope): skip the graph. The current flat browse + single rules-index lookup is sufficient; a graph adds cost with no discoverability gain.
- **Medium / complex tasks** (the same set that already invokes @planner): invoke `--emit` once during Context Discovery, after reading rules-index, and traverse.

This keeps the graph out of the always-loaded surface entirely: the manager gains ~2-3 lines of prose (invoke-and-traverse instruction pointing at an on-demand skill), which is negligible against the ADR-008 manager cap; the parsing work and traversal guidance live in the script and an on-demand skill, which ADR-008 explicitly excludes from the budget ("Phase skills, sub-agent files, and on-demand skills are NOT in the always-loaded set").

### Cost bound

- **Latency:** one pass over `.context/` (tens of files at expected repo size) — sub-second; comparable to the existing `check-rules-index.sh` run.
- **Tokens:** the emitted listing is paths + edge tags, no content. For a repo of the size the user expects (dozens of `.context/` files), this is a few hundred tokens — read once, not per file. The agent then reads only the reachable content set it would eventually need anyway; the graph changes *which* files it reads (complete) not *how many extra* (near-zero overhead vs. today's browse).

---

## 3. Write Side — Graph-powered consistency pass

**Insertion point:** `skills/context-maintenance/SKILL.md` Phase 1 audit table (`:46-56`) and the Tooling section (`:196-228`), generalizing the existing `check-rules-index` wiring.

The same script in `--check` mode consumes its own node/edge extraction and reports structural defects, generalizing `check-rules-index.sh`'s forward+backward checks from the 3 rule directories to the **whole** graph:

| Check | Generalizes | New coverage |
|---|---|---|
| **Dangling reference** | `check-rules-index.sh` backward check (`:127-142`, rules-index rows only) | every `references` edge in **all** `.context/` docs (incl. `domains/`, `architecture/`, prose links) whose target does not resolve on disk |
| **Orphan / unreachable node** | *(none today)* | a node with no in-edges that is not a known discovery root (`overview.md`, `projects.md`, `rules-index.md`) — e.g. a `domains/` file nothing links to and no index covers |
| **Index-coverage gap** | `check-rules-index.sh` forward check | **kept in `check-rules-index.sh` unchanged** (see below) — `--check` reports it by delegating, not by reimplementing |
| **Missing cross-reference** | *(none today)* | low-confidence: surface *candidate* pairs (two nodes citing the same slug without an edge) for agent judgment — flagged, never auto-fixed |
| **Drift** (content changed) | — | **out of scope for the graph** — this stays the existing content-audit Phase 2 job; a structural graph cannot detect semantic drift |

### Relationship to the existing gates — extend vs. leave alone

Two existing consistency mechanisms must not be destabilized:

1. **`check-rules-index.sh`** — wired into `.githooks/pre-commit` as a hard gate and shared with maintenance. **Leave it alone.** It is a narrow, fast SSOT for the rule-index invariant. `context-graph.sh --check` **delegates** rule-index completeness to it (calls it / defers to it) rather than reimplementing, so the pre-commit contract is untouched and there is no duplicate forward-check logic.

2. **`.githooks/pre-commit` `.context/` dead-ref resolver (`:744-831`)** — this validates that `.context/<path>` references in *ICON's own plugin docs* resolve under `context_template/context/`. It enforces ICON's dual-tree (docs ↔ template) consistency — a **different invariant** from general graph reachability. **Leave it alone.** The new graph dangling-check operates on a live consumer's `.context/` at maintenance time; the pre-commit resolver operates on ICON's template mirror at commit time. They do not overlap.

**Do NOT gate `--check` (orphan/dangling-across-all-dirs) in pre-commit initially.** Orphan detection has legitimate-root false positives and the check is heavier; run it maintenance-time only (Phase 1 audit). Promoting it to a pre-commit gate is a future decision once its false-positive rate is known.

---

## 4. Recommended Mechanism — full weighing

### The three candidates against the constraints

| Criterion | 1. Procedural-only | 2. Format-augmented | 3. Script-materialized *(recommended)* |
|---|---|---|---|
| **Reliability** | Low — "agent mentally builds a graph" is non-deterministic; the exact failure this task exists to fix | High — edges are explicit | High — deterministic parse of existing signals |
| **ADR-008 (token budget)** | Worst — graph-building instructions must be always-loaded to fire at discovery | Neutral | Best — logic in on-demand script/skill; ~2-3 lines added to manager |
| **ADR-005 (pure-content)** | OK (no script) | OK | OK — committed script run in-place, no build step |
| **ADR-004/007 (portability)** | OK | OK | Requires bash + PowerShell parity (standard for ICON scripts) |
| **`context_template/` bump gate** | None | **Forced** — format change ships to every consumer via `/upgrade-repo`, forces `iconrc.json` version bump (currently 1.8) | **None** — plugin-local script, no template touch |
| **Ripple** | Low files, high behavioral risk | **Highest** — guidelines + all `context-specialist-impl-*` generators + `context_template/` mirror + validators + every existing consumer `.context/` file | Moderate, contained — new script + 2 wiring points |

### Why not Mechanism 1

It re-creates the exact reliability gap the task is chartered to close, and to fire at discovery its instructions must live in the always-loaded manager surface — the one place ADR-008 most tightly budgets, and where the manager is *already* over its 40% per-component cap (accepted overage, ADR-008 Consequences).

### Why not Mechanism 2 (for v1)

Highest ripple for marginal gain: the edges *already exist* as signals. Making them first-class format seams touches the document guidelines, every `context-specialist-impl-*` generator, the `context_template/` mirror, and forces the `context_template/context/iconrc.json` version bump — shipping a format change into every consumer repo on their next `/upgrade-repo`. This is only justified if the script proves the existing-signal edge set is materially incomplete (the by-name-prose gap in §1). Defer it; do not preclude it (the node/edge model above is forward-compatible with a future explicit `references:` block).

### Why Mechanism 3 + thin procedural layer

Deterministic where it matters (parsing/validation), cheap where the budget is tight (on-demand, not always-loaded), zero consumer ripple (plugin-local, no template touch, no iconrc bump), and it *reuses and generalizes* the existing `check-rules-index.sh` pattern rather than inventing a parallel one. The thin procedural layer (short instructions in manager + maintenance skill) does only what a script cannot: seed selection, bounded traversal judgment, and light semantic linking for by-name refs.

### Concrete file set the recommendation changes

**New:**
- `skills/context-maintenance/scripts/context-graph.sh` — parser; `--emit` (adjacency to stdout) and `--check` (structural defects, exit codes mirroring `check-rules-index.sh`: 0 clean / 1 defects / 2 environment error).
- `skills/context-maintenance/scripts/context-graph.ps1` — PowerShell parity (ADR-004).
- (Optional) `skills/context-maintenance/context-graph.md` — sibling reference doc, matching the existing `append-retrospective-entry.md` / `check-rules-index` documentation pattern.

**Modified:**
- `agents/manager.agent.md` (§ Context Discovery, `:88-103`) — ~2-3 lines: on medium/complex tasks, run `--emit` after rules-index and traverse the reachable set. (ADR-008 delta is negligible; confirm against the manager cap at implementation.)
- `skills/context-maintenance/SKILL.md` — add graph checks to the Phase 1 audit table (`:46-56`) and a Tooling subsection for `context-graph --check` alongside the existing `check-rules-index` one (`:196-228`), noting the delegation to `check-rules-index.sh` for rule-index completeness.
- `README.md` — register the new script per the pre-commit skill/script-parity + shellcheck registration the repo already enforces.

**Explicitly NOT changed:** `context_template/` (⇒ **no `iconrc.json` version bump**), `check-rules-index.sh`, the pre-commit dead-ref resolver, the `context-specialist-impl-*` generators, and the document format itself.

### Portability & security notes (design-first checks)

- **Portability:** the read side runs inside the manager, which executes in both runtimes; scripts resolve via the same `${CLAUDE_SKILL_DIR}` / `COPILOT_HOME` fallback the maintenance skill already documents. Bash + PowerShell parity is mandatory (ADR-004); no `2>/dev/null` (ADR-007).
- **Security (60-second check):** the script reads local, trusted repo markdown, emits paths, and **must not execute or `eval` link targets**. Constrain resolved targets to stay under `.context/` (reuse the existing dead-ref resolver's `.context/`-prefix discipline) to avoid path-traversal reads outside the tree. No network, no external input — minimal surface.

---

## 5. Risks & Open Questions (for go/no-go)

| Risk / question | Likelihood | Impact | Mitigation / needed decision |
|---|---|---|---|
| By-name prose refs (`skill § Section`) missed by the parser | High | Medium | Thin procedural layer keeps semantic linking as agent's job; format-seam fix deferred to a Mechanism-2 follow-up if link coverage proves inadequate |
| Orphan check false-positives on legitimate roots | Medium | Low | Whitelist known roots (`overview.md`, `projects.md`, `rules-index.md`); keep the check maintenance-only (not a pre-commit gate) until FP rate is known |
| PowerShell parity drift from the bash parser | Medium | Medium | Parity is enforced by the existing pre-commit script-parity check; treat `.ps1` as a first-class deliverable, not an afterthought |
| ADR-008 manager delta | Low | Low | Keep the manager addition to a pointer + trigger; measure against the cap at implementation and record in the word-count snapshot if it approaches the 5% re-inventory trigger |
| `--emit` output format churn between read and write modes | Low | Low | Single script, single parser, two output modes — one source of truth for node/edge extraction |

**NEW risks introduced by the fuller scope (§7 seam + §8 gate):**

| Risk / question | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `## Related` authoring inconsistency across all content docs → noisy/incomplete graph | Medium | Medium | Generators emit it (§7.3); `context-document-guidelines` is the authority (§7.4); the gate's orphan check enforces the minimum (a doc with no in-edges must either gain one or carry an opt-out marker) |
| `## Related` peer `## ` section inflates the folder-split section count → spurious split triggers | Medium | Low | `context-document-guidelines` documents `## Related` as a **navigational footer, not a discrete topic** — excluded from the ≥3-peer-section split gate (§7.2) |
| Pre-commit gate blocks legitimate context-touching commits (parser bug or over-eager orphan check) | Medium | Medium | Fail-closed-but-not-fail-open exit-code contract (§8.1); conservative orphan definition (only content docs with zero in-edges that are not roots); escape-hatch markers (§8.4) |
| Parser fails OPEN on malformed input (the ICON-0075 class: `if grep` swallows exit-2; mawk empty-output-exit-0) | Medium | **High** | Exit-code contract 0/1/2 with **any non-zero blocks** (`\|\| exit 1` invocation, never `if script`); zero-nodes-on-non-empty-tree ⇒ exit 2; pure-bash parsing, no gawk-only awk; `grep -e`/`--` on dash-leading patterns (§8.1) |
| iconrc bump 1.8 → 1.9 ships the seam to every consumer via `/upgrade-repo`; consumer docs lack `## Related` | Medium | Low | The pre-commit gate is **ICON-repo-local** (`.githooks/` does not ship — see hook header); consumers receive the script + maintenance-skill wiring only, so they run `--check` at **maintenance time**, never blocked at their own commit (§8.5) |
| Backfilling THIS repo's `.context/` to pass the new fail-closed gate is now mandatory in-scope | High | Medium | Scope the backfill to **minimum-to-green** (resolve orphans/dangling refs the gate blocks); exhaustive `## Related` curation is a follow-up (§9) |

**Open questions — RESOLVED by sign-off:**
1. ~~Confirm Mechanism 3 vs. reject Mechanism 2~~ → **Both approved.** Script + format seam ship together this task.
2. ~~Task nodes~~ → **Excluded** (`tasks/*/plan.md` not in the graph; never orphan-flagged).
3. ~~Pre-commit gating~~ → **Approved as a fail-closed pre-commit gate** (§8), not maintenance-only.

**Remaining open question (for @planner/@coder, not blocking sign-off):** exact minimum-to-green backfill list for ICON's own `.context/` — enumerated during implementation once `--check` runs against the live tree (§9).

---

## 6. Architecture Decision Capture

> **Revised for the fuller scope** (supersedes the lean-v1 block previously drafted here).

```markdown
### Architecture Decision — Context knowledge graph: on-demand script + first-class edge seams + fail-closed gate
**Date:** 2026-07-17
**Decision:** Approve (fuller build)
**Rationale:** Full discoverability and consistency need a deterministic graph over
`.context/`. A portable, plugin-local script (`context-graph.{sh,ps1}`, `--emit` for the
read side / `--check` for the write side) extracts nodes and edges — more reliable than an
agent-built graph (Mechanism 1). The edges that are LOSSY to parse from prose today
(by-name `skill § Section` refs; cross-doc relations that keep `domains/` reachable; ADR
supersede links) are promoted to first-class, human-authorable seams NOW (Mechanism 2),
rather than deferred: a trailing `## Related` links section in content docs, plus
`**Supersedes**` / `**Superseded-by**` bold-fields in ADRs. No YAML frontmatter is
introduced and the `rules-index` table is NOT extended — the seam stays inside the existing
Markdown-and-bold-field idiom. The write-side `--check` runs as a FAIL-CLOSED
`.githooks/pre-commit` gate (ICON-repo-local), with an exit-code contract (0 clean / 1
violation / 2 parser-error) where any non-zero blocks — closing the ICON-0075 fail-OPEN
class.
**Modifications required:** Format seam ships this task ⇒ `context_template/` scaffold docs
demonstrate the seam ⇒ forced `context_template/context/iconrc.json` bump **1.8 → 1.9**.
`context-specialist-impl-leaf` and `-impl-root` emit the seam on create; `-impl-branch`
unchanged (navigational-only; its `projects.md`/`overview.md` index tables are already
`covers` edges). `context-document-guidelines` becomes the seam authority. Keep
`check-rules-index.sh` and the pre-commit `.context/` dead-ref resolver UNCHANGED; the new
gate owns a DISJOINT edge set (content-doc→content-doc links incl. `## Related`, and ADR
supersede targets) and ingests rules-index rows without re-validating them. Backfill of
ICON's own `.context/` is minimum-to-green (whatever the fail-closed gate blocks);
exhaustive `## Related` curation is a follow-up.
**Risks flagged:** parser fail-OPEN (ICON-0075 class) — mitigated by the exit-code contract
and pure-bash/no-gawk/`grep -e` discipline; `## Related` authoring inconsistency and
folder-split section-count inflation — mitigated by generator emission + guidelines footer
exemption; consumer ripple from the iconrc bump — bounded because `.githooks/` is
repo-local (consumers get maintenance-time `--check`, never a blocked commit).
**Promote to ADR?:** yes — ADR-012, at the fuller scope (script + seam + gate). Durable,
project-wide, format-touching, and consumer-shipping; needs a `rules-index.md` row
(`Applies when: building or validating the .context knowledge graph, or authoring the
## Related / ADR supersede seam`). Draft ADR-012 during implementation.
```

**ADR recommendation:** promote to **ADR-012** at the fuller scope. The decision is durable, project-wide, changes the document FORMAT (a consumer-shipping change gated by the iconrc bump), and stands up a new fail-closed enforcement gate — comfortably above the ADR bar. It needs a `rules-index.md` row, and fittingly the new `--check` mode would then verify its own index coverage. This is *eligibility* for the next release, not authorization — the release guard still applies (no `plugin.json` bump, no tag, no `/release-plugin` this task).

---

## Implementation Notes (for @planner / @coder, post-sign-off)

- Build `context-graph.sh` first as the SSOT parser; derive `.ps1` for parity (shell-portability standard: parsing logic stays in shell, not `awk`, per the `check-rules-index.sh` precedent).
- `--check` exit codes must mirror `check-rules-index.sh` (0/1/2) for consistency with the maintenance skill's existing expectations.
- Reuse the `.context/`-prefix constraint from the pre-commit dead-ref resolver for path-traversal safety.
- The manager edit is a pointer, not an algorithm — the traversal procedure belongs in the on-demand skill/sibling reference, keeping the always-loaded surface flat (ADR-008).
- Register the new script in `README.md` and confirm the pre-commit script-parity + shellcheck gates pass before commit.
- **Fuller scope (per sign-off):** `context_template/` IS touched (§7.5) ⇒ **bump `context_template/context/iconrc.json` 1.8 → 1.9 in the same commit** (pre-commit gate). See §7 (seam), §8 (gate), §9 (file set + backfill) below.

---

## 7. Format-Seam Spec (approved — ships this task)

### 7.1 What becomes first-class metadata vs. what stays prose-parsed

Only the edges that are **lossy or impossible to parse from prose today** get a seam. Edges that are already reliably machine-extractable stay as-is — adding a seam for them would be redundant format churn.

| Edge signal | Today | Decision | Why |
|---|---|---|---|
| `references` via inline `[text](path)` | machine-parseable | **stays prose-parsed** — no seam | already reliable; the script's link regex handles it |
| by-name `skill § Section` / "the X pattern in `domains/Y`" prose refs | **not parseable** (the honest gap from §1) | **SEAM — `## Related` block** | author converts the by-name mention into an explicit `## Related` link; this is the priority target |
| `domains/` reachability (no rules-index rows; reachable only if something links to them) | implicit, fragile | **SEAM — `## Related` block** | every content doc gains a curated out-edge set, so no domain is a silent orphan |
| ADR `supersedes` | `**Status**: Superseded by ADR-NNN` prose — semi-parseable, forward-only, target is `ADR-NNN` not a path | **SEAM — `**Supersedes**` / `**Superseded-by**` bold-fields** | makes the edge bidirectional and unambiguous; keys `ADR-NNN` → `decisions/NNN-*.md` deterministically |
| `covers` (folder README / `projects.md` index tables) | index-table links | **stays prose-parsed** — no seam | index tables are already structured link tables; the script reads them as `covers` edges |
| `promoted-from` (retro `Promoted to:`), `excludes` (iconrc) | structured enough | **stays as-is** | already a fixed textual convention the script keys on |

**Net: two seams — a `## Related` links section (content docs) and ADR `**Supersedes**`/`**Superseded-by**` bold-fields.** No frontmatter; no rules-index extension.

### 7.2 The exact seam format

**Decision: a MIX — a trailing `## Related` section + structured ADR bold-fields. NO YAML frontmatter. NO rules-index extension.** Justification against `context-document-guidelines` follows each.

**(a) `## Related` section** — appended as the LAST `## ` section of every content doc under `domains/`, `standards/`, `workflows/`, `architecture/`, `testing/`, `styling/`:

```markdown
## Related

- Extends: [naming conventions](../standards/naming-conventions.md)
- See also: [payments domain](../domains/payments.md)
- Governed by: [ADR-004 tool-agnostic content](../decisions/004-tool-agnostic-content.md)
```

- **Pure Markdown, human-authorable, renders cleanly** — no new parsing surface (frontmatter would be a *second* surface agents must parse separately from the body).
- **The relation label (`Extends:`, `See also:`, `Governed by:`) is free-text for humans; the graph keys on the LINK only.** All `## Related` links are `references` edges — the CLOSED edge set from §1 is unchanged (no new edge types). The label is documentation, not graph vocabulary.
- **Against one-facet-per-file:** `## Related` is a **navigational footer** — metadata about the doc's relationships, not a second topic — directly analogous to the folder-README index tables and `rules-index` rows the format already blesses. It does **not** violate one-facet-per-file.
- **Against the folder-split rule:** `context-document-guidelines` must state that `## Related` is a footer **excluded from the "≥ 3 discrete peer `## ` sections" logical-splittability gate** — otherwise adding it could nudge a doc past the split trigger. (Byte threshold is unaffected: the block is a few links.)
- **Placement is fixed (last section)** so the generator and any future tooling find it deterministically.

**(b) ADR `**Supersedes**` / `**Superseded-by**` bold-fields** — extend the ADR's existing bold-field metadata idiom (ADRs already use `**Date**:` and `**Status**:`), so this is NOT a new surface for ADRs:

```markdown
# ADR-012: ...
**Date**: 2026-07-17
**Status**: Accepted
**Supersedes**: none            <!-- or: ADR-006 -->
```
```markdown
# ADR-006: ...
**Status**: Superseded by ADR-012
**Superseded-by**: ADR-012      <!-- machine-readable mirror of the Status prose -->
```

- **Bold-field, not frontmatter** — consistent with the ADR format that exists today; `**Superseded-by**` is the parseable mirror of the human `**Status**: Superseded by …` prose. Value is `ADR-NNN` (or `none`), which maps deterministically to `decisions/NNN-*.md`.
- The script reads `**Supersedes**` / `**Superseded-by**` as the `supersedes`/`superseded-by` edges; the `**Status**` prose stays for humans.

**Rejected format options and why:**
- **YAML frontmatter on content docs** — rejected. Content docs have none today; introducing it across all node types is a large shift and adds a distinct parse surface, fighting the human-authorable-prose character of `.context/`.
- **Extending the `rules-index` edge table to `domains/`** — rejected. `rules-index` is a router for *governing rules* (standards/workflows/decisions); `domains/` are not rules, and extending it would blur the router's purpose and collide with `check-rules-index.sh`'s scope. `## Related` gives domains reachability without overloading the index.

### 7.3 How each generator emits the seam on create

| Generator | Emits domains/content docs? | Seam emission |
|---|---|---|
| `context-specialist-impl-leaf` (`SKILL.md`) | yes — `domains/`, `standards/`, `workflows/`, etc. + `rules-index.md` (Step 4.5) | **new sub-step (Step 4.6):** after populating each content doc, append a `## Related` section built from the cross-references identified while scanning (the same links it would otherwise bury in prose). When generating ADRs, emit `**Supersedes**`/`**Superseded-by**` where a supersede relationship exists. |
| `context-specialist-impl-root` (`SKILL.md`) | yes — `domains/`, `decisions/`, `architecture/patterns.md`, `workflows/` | same: emit `## Related` in each generated content doc; emit ADR bold-fields in `decisions/`. |
| `context-specialist-impl-branch` (`SKILL.md`) | **no** — navigational only (`overview.md` + `projects.md`) | **unchanged.** Its `projects.md` / `overview.md` index tables are already `covers`-edge sources the script reads; no `## Related` needed on a pure index doc. |

### 7.4 Format authority — `context-document-guidelines/SKILL.md`

`context-document-guidelines` becomes the single authority for the seam. Add a section (e.g. `## Related Section (graph seam)`) that specifies: placement (last `## ` section), format (bulleted `label: [text](path)` links), that links are the graph's `references` edges, that the block is a **navigational footer excluded from the folder-split section count**, and the ADR `**Supersedes**`/`**Superseded-by**` bold-field convention. The generators and `context-maintenance` reference this section rather than restating the rule (thin-router discipline).

### 7.5 `context_template/` mirror set + forced iconrc bump

The seam is a consumer-shipping format change, so the template scaffold docs must demonstrate it (and `/upgrade-repo` Phase 2 keys off the template version). Mirror set under `context_template/context/`:

- **Content scaffold docs get a `## Related` section:** `domains/entities.md`, `domains/glossary.md`, `standards/code-style.md`, `standards/error-handling.md`, `standards/naming-conventions.md`, `testing/unit-testing.md`, `testing/integration-testing.md`, `architecture/patterns-template.md`, `architecture/migration-guide-template.md`, `styling/style-guide-template.md`. (A scaffold `## Related` may use placeholder links or a commented example — it demonstrates the shape.)
- **`decisions/README.md`:** document the `**Supersedes**`/`**Superseded-by**` ADR bold-field convention (the template ships no numbered ADRs, so there is nothing to retrofit — only the README guidance).
- **`rules-index.md`, `iconrc.json` (except the bump), workflows infra:** **unchanged** — no seam applies to the index or the config.

**Forced bump:** any staged change under `context_template/` trips the pre-commit gate at `.githooks/pre-commit:57-220`, which requires `context_template/context/iconrc.json` `version` to advance. **Bump 1.8 → 1.9** in the same commit.

---

## 8. Pre-commit Gate Spec (`--check` as a fail-closed gate)

### 8.1 Exit-code contract — fail-closed on violations, and NOT fail-OPEN on parser error

This is the load-bearing defense against the ICON-0075 class (an `if grep` guard reading grep's exit-2 as "no match" → a silently-disabled gate) and the shell-portability mawk trap (gawk-only awk → empty output, exit 0 → silent pass).

`context-graph.sh --check` uses a THREE-value exit contract:

| Exit | Meaning | Hook action |
|---|---|---|
| `0` | parsed cleanly, **no violations** | allow |
| `1` | parsed cleanly, **violations found** (dangling `references`, orphan node, bad ADR supersede target) — all accumulated and printed to stderr | **BLOCK** (fail-closed on real violations) |
| `2` | **parser / environment error** — unreadable file, structural assumption broken, or **zero nodes discovered when the context tree exists and is non-empty** | **BLOCK** (fail-closed on uncertainty — never conflated with "no violations") |

Hook invocation MUST mirror the existing `check-rules-index` call — `bash "$script" "$root" || exit 1` — so **any non-zero (1 OR 2) aborts the commit.** It must NOT be written as `if context-graph …; then` (which is exactly the construct that swallows exit 2 in the ICON-0075 failure).

In-script defenses (shell-portability standard):
- **Pure-bash parsing** (`while IFS= read -r`, `[[ =~ ]]`, `BASH_REMATCH`) — no gawk-only `match($0,/re/,arr)` or `printf -v` (Rules 1-2); same discipline `check-rules-index.sh` already follows.
- **`grep -e <pat>` / `--`** on any pattern that could begin with `-` (Rule 4), and never trust an `if grep` guard for control flow.
- **Empty-output trap:** discovering zero nodes while `.context/` (or `context_template/context/`) exists and contains `.md` files is treated as a parser failure → `exit 2`, not a clean pass. Closes the "mawk emitted nothing, exit 0" hole.
- **Accumulate-then-report** for violations (like the dead-ref resolver), but **fail-fast to exit 2** the moment a parse invariant breaks.

### 8.2 Interplay with the two existing gates — disjoint edge ownership

The new gate owns an edge set **disjoint** from the two gates left unchanged, so no dangling ref is ever reported twice with conflicting messages:

| Gate | Owns | Source docs |
|---|---|---|
| `check-rules-index.sh` (unchanged) | rules-index **forward** completeness + **backward** row resolution | `rules-index.md` rows only |
| pre-commit `.context/` dead-ref resolver (unchanged) | plugin-doc → `.context/x` refs resolve under `context_template/context/x` | `agents/`, `skills/`, `shared/`, `commands/` files |
| **`context-graph --check` (new)** | **content-doc → content-doc** links (incl. `## Related`) + **ADR supersede targets** | `.context/` (or template) content docs — **excluding `rules-index.md` rows** |

Boundary rules enforced in the script:
- `--check` **ingests** `rules-index.md` rows as `indexed-by`/reachability edges (needed for the orphan check — a rule file reachable via the index is not an orphan) but **does NOT emit dangling-ref violations for them** — that resolution is `check-rules-index.sh`'s backward check. One dead index row ⇒ reported once, by `check-rules-index`.
- `--check` does not touch plugin-doc→`.context` refs (the dead-ref resolver's domain).
- **Ordering:** run `check-rules-index` first (fast, narrow, authoritative), then `context-graph --check`. If the former fails, the commit aborts before the latter runs — and even when both run, their edge sets are disjoint, so verdicts cannot conflict.

### 8.3 Gate scope + performance

- **Runs only when context files are staged.** Compute `context_graph_check_needed` from the staged-file list (the same pattern as `rules_index_check_needed` / `ref_check_files`): true if any staged path is under `.context/` OR `context_template/context/`. Otherwise skip entirely — most commits pay nothing.
- **Which tree(s):** run `--check` against `$repo_root/.context` when `.context/` files are staged, and against `$repo_root/context_template/context` when template context files are staged (both are graphs of the same shape; two invocations of one script).
- **Performance:** one pass over the context tree (dozens of files at expected size) — sub-second, on par with the existing `check-rules-index.sh` run. Whole-tree parse is acceptable because it is gated behind the staged-file trigger.

### 8.4 False-positive escape hatches

Mirror the existing `<!-- pre-commit:dead-ref-ok-start/end -->` marker idiom; keep the vocabulary minimal:

- **Intentionally-dangling ref** (e.g. a link to a doc a follow-up will add): **reuse the existing `<!-- pre-commit:dead-ref-ok-start --> … <!-- pre-commit:dead-ref-ok-end -->` region markers** — same concept ("this ref is intentionally unresolvable"), one marker family. `--check` honors them for its dangling-ref check.
- **Intentional orphan** (a stub doc deliberately not linked yet): a **new file-level marker `<!-- context-graph:orphan-ok -->`** placed in the doc excludes it from the orphan check (there is no existing equivalent).
- Markers are **opt-outs, not general escape hatches** (same wording as the existing dead-ref markers) — document sparing use in `context-document-guidelines` and the `context-maintenance` tooling note.

### 8.5 PowerShell parity (ADR-004 / shell-portability)

- The `context-graph` **script ships bash + PowerShell** (`.sh` + `.ps1`), because it is invoked on surfaces where a consumer may be on PowerShell: the read side (manager Context Discovery) and maintenance-time `--check`. Both variants are first-class deliverables; the `.ps1` must be verified against the parser's own fixtures, not diff-read (shell-portability Rule 3).
- The **`.githooks/pre-commit` hook itself stays bash** and calls `context-graph.sh` — exactly as it already calls `check-rules-index.sh`. Git runs hooks through the bundled Git-Bash on Windows, so **Windows contributors run the identical gate** with no PowerShell port of the hook required; `.githooks/` is repo-local infra that already assumes bash (see the hook header). The `.ps1` exists for the non-hook (read + consumer-maintenance) invocation paths.
- **Consumer blast-radius note:** because `.githooks/` does not ship to consumers, the fail-closed *gate* is ICON-repo-only. Consumers receive the script and the `context-maintenance` wiring and run `--check` at maintenance time — they are never blocked at their own commit by this gate.

---

## 9. Revised Changed-File Set + Backfill (fuller scope)

**New (unchanged from §4):**
- `skills/context-maintenance/scripts/context-graph.sh` — `--emit` / `--check`, exit contract 0/1/2 (§8.1).
- `skills/context-maintenance/scripts/context-graph.ps1` — parity (§8.5).
- (Optional) `skills/context-maintenance/context-graph.md` — sibling reference doc.

**Modified — read/write wiring (from §4):**
- `agents/manager.agent.md` — §Context Discovery: invoke `--emit` + traverse on medium/complex tasks (ADR-008-safe pointer).
- `skills/context-maintenance/SKILL.md` — Phase 1 audit rows + `context-graph --check` tooling subsection (note the disjoint-ownership boundary, §8.2).
- `README.md` — register the new script (skill/script-parity + shellcheck).

**Modified — NEW for the fuller scope:**
- `skills/context-document-guidelines/SKILL.md` — **seam authority** (§7.4): `## Related` spec + folder-split footer exemption + ADR bold-field convention + escape-hatch markers.
- `skills/context-specialist-impl-leaf/SKILL.md` — emit `## Related` + ADR bold-fields on create (new sub-step; §7.3).
- `skills/context-specialist-impl-root/SKILL.md` — emit `## Related` + ADR bold-fields on create (§7.3).
- `.githooks/pre-commit` — add the fail-closed `context-graph --check` gate (§8): staged-file trigger, `|| exit 1` invocation, disjoint-ownership ordering after `check-rules-index`.
- `context_template/context/` scaffold docs — `## Related` demonstration set + `decisions/README.md` ADR-supersede guidance (§7.5).
- **`context_template/context/iconrc.json` — version bump `1.8 → 1.9`** (forced by the template touch).

**Explicitly NOT changed:** `check-rules-index.sh`, the pre-commit `.context/` dead-ref resolver, `context-specialist-impl-branch/SKILL.md`, `context_template/context/rules-index.md` (format), `.claude-plugin/plugin.json` (release guard — no release this task).

**Backfill of ICON's own `.context/`:** because §8's gate is fail-closed and runs when `.context/` is staged, THIS repo's tree must pass `--check` at commit time. **Minimum-to-green backfill is in-scope for ICON-0081** — resolve any orphan or dangling ref the gate blocks (add a `## Related` link, fix a broken path, or apply an escape-hatch marker for a genuine intentional gap). **Exhaustive `## Related` curation across every existing ICON doc is a follow-up**, not this task — the escape-hatch markers cover deliberate gaps in the interim. @coder enumerates the exact minimum list by running `--check` against the live tree during implementation.

### 9.1 P1 orphan ruling (live `--check`: exit 1, 0 dangling, 10 orphans — all resolved with real edges, zero markers)

The verified parser flagged 10 orphans against ICON's live `.context/` — all genuine latent gaps, none false positives, none intentional stubs. Resolution:

**Group B — 6 `workflows/task-plan/*.md` phase files → PARSER AMENDMENT (P1, coder still warm).**
The `rules-index.md` row targets the directory `workflows/task-plan/`, not each phase file, so the parser saw no in-edge. This must be fixed in the parser, not by backfill, so the graph agrees with `check-rules-index.sh` on what "indexed" means (otherwise: freshness-check says fully indexed, graph says 6 orphans — split-brain).

> **Rule:** a `rules-index.md` File-column link target that ends in `/` **or** resolves to a directory on disk emits a `covers` edge from `rules-index.md` to **each `*.md` directly under that directory** (non-recursive). `rules-index.md` is a root, so those children are reachable → not orphans.

This mirrors `check-rules-index.sh`'s parent-row granularity ("a file inside an already-indexed sub-directory is covered by that directory's parent row"). The "could mask an orphan dropped into an indexed folder" risk is not a real loss — such a file IS covered by the parent row, by the rule the repo already codifies. **Rejected:** (B) adding `workflows/task-plan/README.md` — misrepresents a phase-file set as a folder-split-of-one-doc, forces a `context_template/` mirror, and collides with the ICON-0074 intentionally-divergent-template rule; (C) `orphan-ok` markers — the files are genuinely indexed, not intentional orphans, so markers would misrepresent.

**Group A — 4 `domains/*.md` → INBOUND LINK FROM the `overview.md` root hub (P2 backfill).**
`github-access.md`, `hooks.md`, `plugin-resource-paths.md`, `skill-system.md` are mentioned inbound only as **backtick-prose / bare paths** (`` `domains/hooks.md` ``, `.context/domains/github-access.md`) — the §1 gap — so no `references` edge exists. Minimum-to-green is an **inbound** edge (a link FROM a source doc TO each domain), NOT `## Related` on the domain (that adds out-edges, not the in-edge orphan-resolution needs).

> **Concrete minimal edit:** in `overview.md` `## Status of .context/`, the `domains/` bullet (line ~38) already enumerates all four in prose ("skill system, GitHub access (`gh` CLI), plugin resource paths, hooks"). Linkify that existing enumeration: `[skill system](domains/skill-system.md)`, `[GitHub access](domains/github-access.md)`, `[plugin resource paths](domains/plugin-resource-paths.md)`, `[hooks](domains/hooks.md)`.

One root hub, four links, all four cleared — and it IS the §1 seam use-case (backtick/by-name prose → explicit link). `overview.md` is a root, so each domain gains a root-sourced in-edge. (`phase-investigation.md:13-15` also lists three of them as backtick paths; linkifying it is optional follow-up curation, not required for green.)

**No `orphan-ok` markers this task** — all 10 resolve to real edges (6 via the parser rule, 4 via the `overview.md` hub links). The result validates the model: the graph surfaced 10 real latent gaps with zero false positives.
