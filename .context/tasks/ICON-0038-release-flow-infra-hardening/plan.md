## Task: ICON-0038
## Branch: feature/ICON-0038-release-flow-infra-hardening
## Objective: Release-flow + infrastructure hardening bundle from GitLab issue #23 — release-plugin guards/checks (O-M1, O-M4, m-U-H/m-7, m-U-K/m-4), policy decisions (O-M2), missing on-disk infrastructure (O-M3/m-n2 LICENSE), schema declarations (m-1), and template-doc gaps (m-n3). Bundles 9 audit findings carry-forwards + net-new from the ICON-0015 audit.
## Folder: .context/tasks/ICON-0038-release-flow-infra-hardening/

## Decisions
- Bundle scope follows issue #23: 8 sub-tasks (m-n1 auto-discharged by Pre-Flight Explore — ICON-0031 already removed the "Starting with ICON 1.16" phrase repo-wide).
- **O-M2 — DROP** (user: Option a verbatim): Remove the `consider /release-plugin` suggestion at `skills/icon-status/SKILL.md:161` entirely. Do not replace with a generic "consider tagging a release" phrasing. Rationale: `/release-plugin` is by-design maintainer-only post-split; consumer repos have no use for it.
- **O-M3 + m-n2 — REMOVE FIELD** (user: drop, do not add LICENSE file): Remove the `"license": "MIT",` line from `.claude-plugin/plugin.json:9`. Plugin is intentionally private internal — no open-source claim made.
- **m-1 — PARTIAL** (research result 2026-05-23): `.claude-plugin/plugin.json` gets `"$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json"` (verified live, Draft-07, covers all current fields; Anthropic's own `marketplace.json` uses the same SchemaStore host). `.mcp.json` is **deferred** — no authoritative published URL exists (SchemaStore has no MCP entry; MCP issue #292 is an open standardization request). Skip the `.mcp.json` half of m-1; do not invent a placeholder.
- Pre-Flight Explore complete: established pattern (5 precedents — ICON-0030/0032/0033/0035/0037) for audit-finding tasks. Citation-drift detection sub-pattern (per ICON-0037) ran — all citations verified; minor off-by-one on m-n3 line range (26-39 not 27-38, fence-inclusive vs fence-exclusive).
- Verbatim acceptance-gate checklist in @coder dispatch (per ICON-0037 — 4 precedents, mechanical-sweep variant when no @architect): per-sub-task `grep -nE` commands + expected output.
- Echo user decisions verbatim into @coder dispatch (per ICON-0037 — 5 precedents, user-clarification sub-pattern).
- No @architect pass: this is a mechanical-sweep bundle (Step-1 bullet add, line removal, line addition, field removal, file edits with specified content). Gates-at-dispatch-layer variant (per ICON-0037 retro) applies.

## Key Files
- `.claude/skills/release-plugin/SKILL.md` (lines 31, 40): m-U-H/m-7 `git rev-parse --is-inside-work-tree` guard added inside Step 1 bash block at line 31; O-M1 "Sweep user-facing docs" paragraph added at line 40 (within Step 1, before the Step 1→Step 2 horizontal rule).
- `.claude/skills/release-plugin/scripts/bump-versions.sh`: O-M4 `--dry-run` flag + per-component `ver_gt` monotonicity check (rejects downgrades AND equal versions). Initial implementation used `printf '%03d'`-padded concatenation; replaced with `IFS=. read` per-component comparison after reviewer flagged a Minor patch-≥-1000 collision.
- `.claude/skills/release-plugin/scripts/format-slack.sh:17`: m-U-K/m-4 `set -euo pipefail` added after the shebang/comment block.
- `skills/icon-status/SKILL.md`: O-M2 dropped — removed the entire 13-line Signal 2 conditional block (was emitting `consider /release-plugin`); Signals 1 and 3 preserved.
- `.claude-plugin/plugin.json`: m-1 `"$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json"` added as first key on line 2; O-M3/m-n2 `"license": "MIT"` field removed.
- `.mcp.json`: m-1 **NOT TOUCHED** (no authoritative URL exists per @researcher 2026-05-23; sub-task deferred).
- `context_template/README.md` (lines 29, 40): m-n3 added `├── iconrc.json` and `└── .gitignore` entries to the `context/` structure diagram; tree-branch alignment preserved (final entry is `└──`).
- `CHANGELOG.md`: four new `[Unreleased]` entries (1 Added, 1 Changed, 2 Removed) under ICON-0038.
- **m-n1 (commands/enable-manager-default.md, commands/disable-manager-default.md): NOT TOUCHED** — auto-discharged by Pre-Flight Explore confirming ICON-0031 already removed the "Starting with ICON 1.16" phrase repo-wide.
- **LICENSE file: NOT CREATED** — user chose to remove the manifest field instead.

## Progress
- [x] Create branch + task folder + initial plan.md
- [x] Pre-Flight Explore — all citations verified; m-n1 auto-discharged; only m-n3 has cosmetic line off-by-one (26-39 not 27-38)
- [x] Resolve open questions with user — O-M2 drop; O-M3 remove field; m-1 research-driven (claude-code URL → skip fallback)
- [x] @researcher located SchemaStore URL for plugin.json; .mcp.json deferred (no published URL)
- [x] @coder Pass 1 — all 8 sub-tasks implemented; gates G1–G8 + CC1–CC4 all PASS
- [x] @reviewer (Opus, single-pass with 9 named risk axes) — verdict GOOD with one Minor (printf-padding patch≥1000 collision)
- [x] @coder Pass 2 (Minor follow-up) — replaced `printf '%03d'` concatenation with `IFS=. read` per-component `ver_gt`; new G4e gate (5 boundary tests) all PASS; all previous gates re-verified
- [x] Manager repo-wide grep sweep — no stderr suppression in diff, no consumer-shipped `/release-plugin` mentions remain, no `license` field in either manifest, no semantically-equivalent "Starting with ICON" variants, both release-plugin scripts have `set -euo pipefail`
- [x] CHANGELOG entry — 4 entries added under [Unreleased] (1 Added, 1 Changed, 2 Removed); maintainer-only `.claude/skills/release-plugin/` changes skipped per `changelog-discipline.md` Rule 4
- [x] Reconcile plan.md against final state (phase-completion §0)
- [ ] Task retrospective (manager Stage 1, then @context-specialist Stage 2) ← IN PROGRESS
- [ ] Commit all artifacts
- [ ] Open MR

## Open Questions / Blockers
- None pending — researcher result will determine whether m-1 ships or defers.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005. Validation is "JSON parses" + "manifest validator accepts it".
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003. Do not introduce duplicate version literals.
- `main`-only repo. Feature branch merges to `main`; release IS the tag push (see `.claude/claude.md`).
- `.claude/skills/release-plugin/` is maintainer-only and NOT shipped to consumers — fixes there don't propagate via the marketplace `latest` tag.
- Cross-platform shell snippet rule (per ICON-0030): verify any GNU-only flags (`-V`, `-z`, etc.) against BSD man pages. `bump-versions.sh` already targets bash; check current portability before changes.
- No `2>/dev/null` or output suppression (per ICON-0030 / common-constraints).
- YAML frontmatter folded-block-scalar safety (per ICON-0031): if any frontmatter `description:` is touched and contains `:`, leading `~`/`*`/`&`/`!`, or unescaped quotes, use `description: >` folded form.
- Three-precedent rule for shell snippet portability: validate `--dry-run` and monotonicity check use POSIX or bash-only constructs that work in maintainer-only environment.
