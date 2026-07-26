# Context-Specialist & Init Audit — Raw Findings

**Domain**: 03 — `@context-specialist` agent + the init/upgrade skill tree
**Audit**: ICON-0089 (2026-07-26) · plugin v2.0.0 + `[Unreleased]` (ICON-0088) · branch `feature/ICON-0089-icon-audit`
**Prior baseline**: ICON-0058 (2026-06-10, v1.19.0)

## Summary

The delegation chain is architecturally sound and every ICON-0058 finding in this domain except one is fixed: the two stale "the 15th" literals are gone, the three "plugin-lint Check A/B" phantom labels are gone, `impl-branch` gained its Verify step (ICON-0077), and `initialize-multimodule` gained a real root `context-specialist-impl-root` dispatch (ICON-0078), bringing the four init orchestrators to near-exact parity in their root-session prompts. Frontmatter is clean (`description: >` folded scalar) across all 15 in-scope skills and the agent. Both deterministic checkers pass on this tree (`context-graph.sh --check` → `OK: 49 nodes, no dangling references, no orphans`, exit 0; `check-rules-index.sh` → `OK: all rule units indexed and all index rows resolve`, exit 0), and `structural-check.sh` passes all five checks.

What the ICON-0058 lens did not cover is where the damage now is. Three **consumer-facing correctness defects** break a real `/icon-init` or `/upgrade-repo` run: `upgrade-repo`'s stock-vs-customized detection for `task-workflow-template.md` now misfires for *every* consumer installed before ICON-0080, because two later commits edited the deprecated file it diffs against; `initialize-monorepo`'s `.sln` project discovery uses GNU-only `grep -oP` and returns zero projects on macOS/BSD; and `context-specialist-impl-root` never creates the root-level `claude.md` redirect, so Copilot CLI users at a monorepo/workspace root get no project instructions at all — a file `upgrade-repo` Phase 4 then verifies as required. Underneath those sits a structural pattern: **`impl-root` has silently fallen five obligations behind `impl-leaf`**, and there is no mechanism that would ever notice. The v2.0.0 interval features land in `impl-leaf` and stop there — `rules-index.md` (ICON-0069), the `## Related` graph seam (ICON-0081), and `.gitattributes` all reached `impl-leaf`; only `.gitattributes` reached both siblings, and `upgrade-repo` never acquired a graph-seam step at all, so no existing consumer repo will ever get the ICON-0081 seam.

Finally, the ICON repo's own `.context/iconrc.json` is at schema **1.2** against a template at **1.12** — `/upgrade-repo`, the one skill whose entire job is keeping an installed `.context/` current, has never been run against ICON's own `.context/`. Every parity gap in this report is a gap that dogfooding would have surfaced.

---

## Defect Findings

### Critical

#### C-89-03-01 — `upgrade-repo` misclassifies every pre-ICON-0080 stock `task-workflow-template.md` as CUSTOMIZED

**Location:** `skills/upgrade-repo/SKILL.md:119-145` (bash + PowerShell branches); trigger commits `3418e84` (ICON-0080), `2866f2b` (ICON-0081)

**Finding:** Phase 1's deprecation check decides "stock vs customized" by diffing the consumer's installed file against the **current** `$TEMPLATE_DIR` copy:

```bash
if diff -q ".context/workflows/task-workflow-template.md" \
           "$TEMPLATE_DIR/context/workflows/task-workflow-template.md" > /dev/null 2>&1; then
```

`context_template/context/workflows/task-workflow-template.md` has been edited **twice since it was deprecated** (MKT-0090; `CHANGELOG.md:259-260`): `3418e84` for the GitHub conversion, and `2866f2b` which prepended two `context-graph:orphan-ok` comment lines purely to satisfy ICON's *own* pre-commit graph gate. A consumer who installed a byte-perfect stock copy at any earlier version therefore diffs non-empty and is classified `deprecated (CUSTOMIZED)`.

**Risk:** The misclassification cascades. Phase 2 (`:196-204`) invokes `merge-phase-templates`, which at Step 1 (`skills/merge-phase-templates/SKILL.md:28-34`) reads the delta backwards — the newer stock content is "in stock but not in the installed file", i.e. **custom deletions** — so Step 4 (`:60-66`) asks the user to adjudicate sections they never removed, and Step 5 (`:72`) withholds the deletion confirmation until they do. A routine `/upgrade-repo` becomes an interactive interrogation about a file the consumer never touched, and the deprecated file is not deleted. This affects the *entire* pre-2.0.0 installed base.

**Root cause (the reusable lesson):** "is this file stock?" was implemented as a diff against HEAD's template, which is only correct if the shipped template is frozen. It is not — and the file most likely to be edited-while-deprecated is exactly the one this check depends on. See **SO-5**.

---

#### C-89-03-02 — `initialize-monorepo` `.sln` project discovery uses GNU-only `grep -oP`; returns zero projects on macOS/BSD

**Location:** `skills/initialize-monorepo/SKILL.md:82`

```bash
  | grep -oP '"[^"]+\.csproj"' | tr -d '"' \
```

**Finding:** `grep -P` (PCRE) is a GNU extension. BSD/macOS `grep` rejects it (`grep: invalid option -- P`), as does busybox. This is the `.sln`-parsing path that enumerates the sub-projects a .NET monorepo init will initialize. On any non-GNU platform the pipeline yields an empty project list, and `initialize-monorepo` proceeds to dispatch per-area initialization for **zero areas** before running the root dispatch.

**Risk:** Consumer-facing and silent: a macOS user runs `/icon-init` on a `.sln`-rooted monorepo, confirms `monorepo` at `icon-init` Step 3, and gets a root `.context/` with an empty `projects.md` and no sub-project context — with no error to indicate why. `.context/standards/shell-portability.md` exists precisely to prevent this class and does not currently name `grep -P` among its six rules.

**Fix direction:** `grep -oE '"[^"]+\.csproj"'` is an exact POSIX ERE equivalent here (no PCRE feature is used). See **SO-4** for mechanizing the whole class.

---

#### C-89-03-03 — `context-specialist-impl-root` never creates the root-level `claude.md` redirect

**Locations:** `skills/context-specialist-impl-root/SKILL.md:94-107` (Step 4), `:289-303` (Step 15 verify) — zero occurrences of "redirect" in the file; compare `skills/context-specialist-impl-leaf/SKILL.md:42-59`, `:313`; verified against `skills/upgrade-repo/SKILL.md:624`

**Finding:** `impl-leaf` creates a root-level `claude.md` redirect and verifies it (Step 5 item 8) because, as it states at `:42-44`, "Copilot CLI loads a root-level `claude.md` when one exists, but does **not** automatically read `.claude/claude.md`." `impl-root` Step 4 handles `.claude/claude.md` only. `impl-root` is the skill every monorepo, workspace, and multi-module root runs (`initialize-monorepo` Step 5, `initialize-workspace` Step 6, `initialize-multimodule` Step 7 — all three dispatch prompts load it by name).

**Risk:** Copilot CLI users working at a monorepo/workspace/multi-module root receive **no project instructions**, on exactly the repo shape where root-level orientation matters most. This also makes the init output structurally non-conformant with the project's own upgrade contract: `upgrade-repo` Phase 4 item 6 (`:624`) verifies "Root-level `claude.md` exists" — so a freshly initialized root fails its own verification the moment `/upgrade-repo` is run on it. ADR-004 (tool-agnostic content) is the governing decision this violates.

---

### Moderate

#### M-89-03-01 — `upgrade-repo` iconrc schema-version sync is GNU-only and fails **silently** off-GNU

**Location:** `skills/upgrade-repo/SKILL.md:491-500`

```bash
TEMPLATE_VER=$(grep '"version"' "$TEMPLATE_DIR/context/iconrc.json" | grep -oP '[\d.]+')
INSTALLED_VER=$(grep '"version"' .context/iconrc.json | grep -oP '[\d.]+')
if [ "$INSTALLED_VER" != "$TEMPLATE_VER" ]; then
  sed -i "s/\"version\": \"$INSTALLED_VER\"/\"version\": \"$TEMPLATE_VER\"/" .context/iconrc.json
```

**Finding:** Two GNU-isms in four lines. (a) `grep -oP` as in C-89-03-02. (b) `sed -i` without a backup-suffix argument is GNU-only; BSD/macOS `sed -i` consumes the next argument as the suffix. On macOS the failure is *silent and wrong*: both `grep -oP` calls error to stderr and produce empty strings, so `[ "" != "" ]` is false, the `else` branch fires, and the skill prints `iconrc.json version: already at ` — reporting success while the installed version never advances. The PowerShell branch immediately below (`:502-513`) is correct (`ConvertFrom-Json`), so the defect is bash-only.

**Risk:** This field is the gate `/upgrade-repo` Phase 2 uses to decide whether template updates apply (`.claude/CLAUDE.md` § Template version). A consumer on macOS never converges: every future `/upgrade-repo` re-reports the same drift and re-no-ops. Phase 4 item 7 ("`.context/iconrc.json` `version` field matches the template") would catch it — if it were checked with a working comparison.

**Suggestion:** Use the same `python3 -c`/`ConvertFrom-Json` shape used elsewhere, or POSIX `sed -n 's/.*"version": *"\([^"]*\)".*/\1/p'`, and write with `sed -i.bak … && rm -f .context/iconrc.json.bak` (portable) or a temp-file rewrite.

---

#### M-89-03-02 — `impl-root` has fallen four further obligations behind `impl-leaf` (beyond C-89-03-03)

**Locations:** `skills/context-specialist-impl-root/SKILL.md:22-40` (structure block), `:217-232` (Step 12 copy), `:235-244` (Step 13 hook), `:289-303` (Step 15 verify). Verified by grep: `rules-index`, `task-plan`, `INTEGRATION_BRANCHES` each return **zero** hits in the file.

| Obligation | `impl-leaf` | `impl-root` | Verified by `upgrade-repo`? |
|---|---|---|---|
| Generate `.context/rules-index.md` | Step 4.5 (`:275-284`), verify item 9 (`:314`) | **absent** | Yes — Phase 1 `:173`, Phase 4 item 8 `:626` |
| Copy the 6 `workflows/task-plan/*.md` phase templates | Step 2 (`:128-135`) | **absent** | Yes — Phase 1 `:176-179`, Phase 2 `:521-561` |
| Customize `INTEGRATION_BRANCHES` in `prune-context.sh` | Step 3 (`:191-202`) | **absent** (Step 12 `cp`s the generic default) | Yes — Phase 4 item 1 `:619` |
| Copy `decisions/README.md` from template | Step 2 (`cp -r …/decisions`, `:123`) | **absent** (Step 6 `:135` assumes the index exists) | — |

**Suggestion:** All four are consequential. The missing phase templates mean the `task-plan` template-override chain (`.context/workflows/task-plan/phase-<name>.md`) silently degrades to the shipped-skill fallback for every cross-project task run at a monorepo root. The un-customized `INTEGRATION_BRANCHES` means the post-commit prune guard is wrong at root — it either never prunes or prunes on the wrong branches. Note that `impl-branch` is *correctly* exempt from all four (a branch node has no `retrospectives.md`, no hook, no tasks/) — the ICON-0077 retro (`.context/retrospectives-archive.md:85`) already articulates the right rule here: template from the sibling whose **role** matches. See **SO-3**.

---

#### M-89-03-03 — `upgrade-repo` has no `## Related` graph-seam step; ICON-0081's seam is init-only

**Locations:** `skills/upgrade-repo/SKILL.md` (whole file — zero occurrences of `context-graph`, `## Related`, `Supersedes`); compare `skills/context-specialist-impl-leaf/SKILL.md:287-294` (Step 4.6) and `skills/context-specialist-impl-root/SKILL.md:206-213` (Step 11b)

**Finding:** ICON-0081 shipped the `.context/` knowledge graph: `## Related` footers on every content doc, ADR `**Supersedes**`/`**Superseded-by**` bold-fields, and `context-graph.sh --check` as a fail-closed gate. Both create-mode impl skills emit the seam. `upgrade-repo` does not: Phase 1's audit list (`:108-181`) never asks whether content docs have `## Related` footers, Phase 2 has no emit step, and Phase 4's nine verify items (`:619-627`) don't mention it. `upgrade-repo` Phase 3 explicitly delegates content currency to `context-maintenance`, but the graph seam is *structural authoring*, not content currency, and the sample check that gates that delegation (`:613-615` — "5 random class/function/type names") would never detect a missing footer.

**Suggestion:** Every repo initialized before v2.0.0 is permanently graph-blind. Since `context-graph --check` is the mechanism `context-maintenance` Phase 1 relies on to find dangling references (`skills/context-maintenance/SKILL.md:94`), those repos also lose that check's value. A Phase 2 step — run `context-graph --check`, and where content docs lack a `## Related` section, generate one per `context-document-guidelines § Related Section` — closes it and is symmetric with how `rules-index.md` is handled at `:603-607`.

---

#### M-89-03-04 — `context_template/context/workflows/commit-conventions.md` hardcodes `MKT` as the consumer's project prefix

**Locations:** `context_template/context/workflows/commit-conventions.md:12,15,20-23,55,58,63-65,74,77,84-85,93-94,121-124`; contrast `context_template/context/workflows/branching.md:10-12,34,40,52,63,67,74,100,103`

**Finding:** The shipped template asserts at `:58`:

> - `MKT` — fixed prefix for this project

and at `:74` gives an operative command:

```bash
   ls .context/tasks/ | grep -oP 'MKT-\K[0-9]+' | sort -n | tail -1
```

`MKT` is the predecessor marketplace repo's task prefix. The paired file `branching.md` is correctly generic throughout (`TICKET-123`), which is what makes this a defect rather than a style call: `.context/standards/skill-decomposition/process-doc-sweeps.md:40` (the ICON-0074 exception) names **these two files specifically** and states the contract — "the template copies are generic consumer scaffolds (Gitflow, `TICKET-NNN`, tier-agnostic phrasing) … do not cross-contaminate (no ICON-specific text into the generic scaffold)". `branching.md` honors it; `commit-conventions.md` does not.

**ADR check:** ADR-010 m9 (DataScan-flavored *example shapes*) is marked **Closed (ICON-0080)**, and ADR-011 is **Superseded by ICON-0080**. Neither pre-dispositions this, and `:58` is a declarative assertion plus `:74` is executable code — not an illustrative shape. Tiering as Moderate is not a re-tier of an accepted carry-forward.

**Suggestion:** Replace with `TICKET` to match `branching.md`, and fix the `grep -oP … \K` (doubly non-portable: `-P` **and** `\K`) to `sed -n 's/^TICKET-\([0-9]*\).*/\1/p'`.

---

#### M-89-03-05 — `.context/cache/` is never created, and its TTL is stated three different ways

**Locations:** `skills/context-specialist-impl-leaf/SKILL.md:117` (mkdir list omits `cache`), `skills/context-specialist-impl-root/SKILL.md:217-229`; `context_template/context/META.md:70` ("3-day TTL"); `agents/researcher.agent.md:25,27,92`; `context_template/context/iconrc.json:5` (`"cache_expires_after_days": 30`); `skills/create-iconrc/SKILL.md:22,39,114`; `skills/resolve-repo-context/SKILL.md:48`

**Finding:** Two coupled problems.

1. **Never created.** `impl-leaf` Step 2 creates `standards, architecture, testing, tasks, workflows, domains, styling` — no `cache`. `impl-root` creates none of them. `context_template/` ships no `cache/` directory. Yet `context_template/context/META.md:70` documents `cache/` as part of the standard structure, `researcher.agent.md:25` instructs "look in `.context/cache/` for a document", and `CHANGELOG.md:62` records a `prune-context.sh` fix specifically to stop deleting `.context/cache/.gitkeep` — a marker file no init skill ever writes. ICON's own tree has `.context/cache/.gitkeep`; it was created by hand.
2. **Three TTLs.** `context_template/context/META.md:70` says 3 days. `researcher.agent.md:25` hardcodes "within **3 days**", ignoring iconrc entirely. `iconrc.json`/`create-iconrc` say 30. `.context/META.md:73` (ICON's customized copy) says "TTL from iconrc, default 30 days" — the correct statement, which never made it back to the template. `resolve-repo-context/SKILL.md:48` shows a fourth value (`7`) in its schema example.

**Suggestion:** Add `cache` to the `impl-leaf`/`impl-root` mkdir sets with a `.gitkeep`; make the template META and `researcher.agent.md` both defer to `cache_expires_after_days`; correct the `resolve-repo-context` example to `30`.

---

#### M-89-03-06 — `create-iconrc` is Python-only, and its code block is not executable as written

**Locations:** `skills/create-iconrc/SKILL.md:81-121` (create path), `:127-160` (update path); related: `skills/icon-init/SKILL.md:69-77`

**Finding:** `create-iconrc` is "the **sole owner** of `.context/iconrc.json`" (`:12`) and is called by all four init paths (`:176-184`). Every other init step in this domain ships bash **and** PowerShell branches; this one ships only Python. Two consequences:

- **Undeclared runtime dependency.** `python3` is not documented as an ICON prerequisite anywhere, and is absent by default on Windows and on minimal containers. With no fallback, the sole writer of `iconrc.json` has no path to execute.
- **Not runnable as written.** The `config = {…}` block at `:109-116` references bare names `repo_type`, `local_task_id_prefix`, `default_branch`, `cache_expires_after_days`, `excludes`, `forbidden_prefixes` that are never bound in the snippet. An agent that pastes and runs it gets `NameError`. It is pseudo-code presented in an executable fence.

The same dependency appears at `icon-init/SKILL.md:69-77`, where `python3` parses `package.json` for a `workspaces` field. If `python3` is missing, `WS_CHECK` is not `"yes"`, detection falls through to Step 2c, `package.json` matches, and a **yarn/npm-workspaces monorepo is detected as `project`**. Step 3's user confirmation is the only thing standing between that and `initialize-repo` running on a monorepo root — which is why this is Moderate and not Critical.

**Suggestion:** Either declare `python3` a prerequisite in `find-context-template`/README and mark the blocks as templates-with-bound-inputs, or replace both with the `jq`-free POSIX `sed`/`grep` shapes used elsewhere in the same skills.

---

#### M-89-03-07 — ICON's own `.context/iconrc.json` is at schema 1.2 against a 1.12 template: `/upgrade-repo` is not dogfooded

**Locations:** `.context/iconrc.json:2` (`"version": "1.2"`), `context_template/context/iconrc.json:2` (`"version": "1.12"`)

**Finding:** Ten schema versions of drift. `/upgrade-repo` has never been run against ICON's own `.context/`. The features that *did* land in ICON's tree (`rules-index.md`, root `.gitattributes`, `retrospectives-archive.md`) got there by hand, per-task — which is exactly why the gaps in M-89-03-02 and M-89-03-03 went unnoticed: nobody has ever executed the upgrade path against a real installed tree.

**Suggestion:** This is the single highest-value process change available to this domain. Running `/upgrade-repo` on ICON once per release cycle would have surfaced C-89-03-03, M-89-03-01, M-89-03-02, and M-89-03-03 as failing verify items rather than audit findings. See **SO-8** for the cheap enforcing version.

---

#### M-89-03-08 — `resolve-repo-context` topology-drift signal list is a subset of the detection signals

**Locations:** `skills/resolve-repo-context/SKILL.md:60-64`; compare `skills/context-specialist-detect-tree-position/SKILL.md:16-22` and `skills/icon-init/SKILL.md:54-91`

**Finding:** The cache-invalidation check watches four files:

> - `.code-workspace` · Root `package.json` · `nx.json` · `*.sln`

`detect-tree-position` and `icon-init` both additionally treat `turbo.json`, `go.work`, and `pom.xml` (with `<modules>`) as root signals. A turborepo, Go workspace, or Maven multi-module repo can therefore add or remove a module without ever invalidating `.topology-cache.json`, and the manager routes against stale topology until `cache_expires_after_days` (default 30) elapses.

Separately, `:48` shows `"cache_expires_after_days": 7` in the schema example while the template default is `30` (M-89-03-05).

**Suggestion:** Bring the drift list to parity with the three-way-shared signal set. This is the fourth place in the domain where the same signal list is restated in prose — see **SO-3**.

---

### Minor

#### m-89-03-01 — `upgrade-repo/SKILL.md:122` `> /dev/null 2>&1` — third consecutive cycle

Carried from ICON-0046 (`m-new-02`) → ICON-0058 (`m-58-03-03`) → here, unchanged. Agent-invoked bash block, so ADR-007's autonomous-script carve-out does **not** apply. The stderr suppression is materially load-bearing for C-89-03-01: when `$TEMPLATE_DIR` is unset or the template file is absent, `diff`'s error is swallowed and the file is silently classified CUSTOMIZED. Having now survived three cycles, this meets the ADR-010 Part B threshold — it should either be fixed (one character: drop `2>&1`) or formally entered in the carry-forward registry with a rationale, not carried silently into a fourth.

#### m-89-03-02 — `skills/task-plan-phase-completion/SKILL.md:76` cites `.context/architecture/patterns-template.md`

The Context Update Checklist instructs consumers to "update `.context/architecture/patterns-template.md`". No init skill ever creates that path; the file is `architecture/patterns.md` (`step-4-file-content.md:91`, `impl-root:297`). This is ICON-0046 `m-new-01`'s literal surviving in a sibling site — the fix landed in `impl-root` but not here. The `context_template/` counterpart (`context_template/context/workflows/task-plan/phase-completion.md`) is **correct**, so the shipped skill and its own template have diverged. (Cross-domain: the file is domain 02/04's, the wrong `.context/` path is this domain's.)

#### m-89-03-03 — Nine `context_template/` files are never copied or referenced by any skill

Cross-referenced every template file's basename against `skills/`, `agents/`, `commands/`, `hooks/`, `.claude/`, `.githooks/`:

| Template file | Referenced by |
|---|---|
| `context/architecture/migration-guide-template.md` | nothing |
| `context/architecture/patterns-template.md` | only the wrong-path cite in m-89-03-02 |
| `context/domains/entities.md`, `context/domains/glossary.md` | only each other |
| `context/styling/style-guide-template.md` | only `standards/code-style.md`'s `## Related` |
| `context/standards/{code-style,error-handling,naming-conventions}.md` | only as `###` headings in `step-4-file-content.md` |
| `context/testing/{unit,integration}-testing.md` | same |
| `context/workflows/ci-cd.md`, `commit-conventions.md`, `branching.md` | generated from git history, never copied |
| `UPDATE_LOG.md` | nothing |

`impl-leaf` Step 2 copies exactly seven paths; everything else in `context_template/context/` is either generated fresh (Step 4/4.5/4.6) or dead payload. `UPDATE_LOG.md` is additionally stale — dated 2026-02-17 and headed "Agent Definitions (all 7 rewritten)" against a current count of 9. Beyond the dead weight, each of these files is inside the `.githooks/pre-commit` template-version gate's scope, so editing one forces a schema bump that ships nothing. See **SO-1**/**SO-2**.

#### m-89-03-04 — `.context/standards/shell-portability.md:Rule 5` cites two mechanisms that no longer exist

Rule 5 closes with: "This is the rule the `icon-init` MCP-onboarding gate and `icon-status` credential check rely on — a `${VAR:-…}` there would misreport an empty-but-set token as 'set'." Grep for `MCP` in both `skills/icon-init/SKILL.md` and `skills/icon-status/SKILL.md` returns **zero** hits — both surfaces were removed in ICON-0080's GitHub-only conversion. The rule itself is still correct; its sole justifying example is now unfalsifiable. Exactly the staleness class **SO-7** targets: a by-name reference the graph parser cannot see because it isn't a Markdown link.

#### m-89-03-05 — `icon-init` Step 5 promises a list and delivers one item

`skills/icon-init/SKILL.md:211-221`: "print the following hints **in order**" is followed by a single sub-step, `5a`. Residue of a removed `5b` (the MCP-onboarding gate of m-89-03-04). Cosmetic, but it's the kind of orphaned scaffolding that reads as a truncated file.

#### m-89-03-06 — "copy verbatim, do not customize" is contradicted by ICON's own practice and by `upgrade-repo`

`impl-leaf:119` ("Template files — copy verbatim, do not customize"), `impl-root:231` ("Copy verbatim — do not customize template files"), and `impl-branch:26,29` all mark `META.md` as a verbatim copy. `diff .context/META.md context_template/context/META.md` shows **13 divergent hunks** — ICON's own `META.md` is substantially rewritten. And `upgrade-repo:611` explicitly excludes it: "Do not touch `META.md`, `retrospectives.md`, or `tasks/`". So `META.md` is in practice a seed that consumers are expected to customize and that upgrades will never overwrite — which is the right design, but the three impl skills state the opposite. (Self-reference check: this is the domain's one instance of a skill not following its own stated rule.)

#### m-89-03-07 — `initialize-repo`'s dispatch prompt drops two "recommended" parameters and under-verifies

`skills/initialize-repo/SKILL.md` passes only `tree_position` and `working_directory`. `agents/context-specialist.agent.md:34-35` marks `git_root` and `feature_branch` **recommended**, and `context-specialist-create/SKILL.md:26-27` repeats that. The four orchestrators' root prompts all pass both. Its post-dispatch verification is three items (`.context/`, `overview.md`, `iconrc.json`) against `impl-leaf` Step 5's nine — it would pass a run that produced no hook wiring, no `rules-index.md`, no `claude.md`, and no `.gitattributes`.

#### m-89-03-08 — `retrospectives-archive.md` has no template and no init step

Introduced by ICON-0073, it is named in `.gitattributes`, in `impl-leaf:242,309`, `impl-root:266,303`, and `upgrade-repo:181,481,627` — all as though it is an expected file — but `context_template/` ships no copy and no init skill creates one. It is in fact created lazily by `append-retrospective-entry.sh:130` on first overflow, which is correct behavior; the finding is that four surfaces read as if it should pre-exist. A one-line note at the `.gitattributes` steps ("created on first prune; the attribute is set ahead of need") would resolve it.

---

## Improvement Opportunities

### IO-89-03-01 — Collapse the four restatements of "what a complete `.context/` contains" into one manifest

**Locations:** `skills/context-specialist-impl-leaf/SKILL.md:117-135,298-314`; `skills/context-specialist-impl-root/SKILL.md:22-40,217-229,289-303`; `skills/context-specialist-impl-branch/SKILL.md:19-43,120-130`; `skills/upgrade-repo/SKILL.md:108-181,619-627`

The required-file set is written out **four times in prose**, once per skill, plus a fifth time as `upgrade-repo`'s audit list and a sixth as its verify list. Every one of C-89-03-03, M-89-03-02, and M-89-03-08 is a divergence between two of these copies. A single machine-readable manifest keyed by `tree_position` (`leaf`/`branch`/`root`) — `{path, source: copy|generate, required: always|conditional}` — that all six surfaces read would make the parity question answerable by a script instead of by an auditor. This is the structural precondition for **SO-3**.

**Effort:** medium. **Impact:** high — retires an entire recurring finding class.

### IO-89-03-02 — Give `find-context-template` a `verify` contract that callers must run

`find-context-template/SKILL.md:59-99` documents excellent existence and unset checks — and then every caller ignores them. `impl-leaf:113`, `impl-root:219`, `impl-branch:108`, and `upgrade-repo:104` each say only "Invoke the `find-context-template` skill to locate `$TEMPLATE_DIR`" and proceed straight to `cp "$TEMPLATE_DIR/…"`. If `CLAUDE_PLUGIN_ROOT` is unset, those become `cp "/context/META.md" .context/` — and in `upgrade-repo`'s case, the failure is *swallowed* by m-89-03-01's `2>&1`. Promote the check from "If the Result Is Empty" advice to a mandatory Step 0 that exits non-zero, and have callers invoke it as a guard rather than a suggestion.

**Effort:** low. **Impact:** medium-high — the whole init tree depends on this one variable and nothing validates it.

### IO-89-03-03 — Document the 4→3 init-type collapse at both endpoints (carried from ICON-0058 IO-58-04)

`icon-init/SKILL.md:34` still says detection is "**derived from**" `context-specialist-detect-tree-position` without stating the mapping (workspace + monorepo → root; project → leaf; multimodule → branch), and `detect-tree-position`'s Detection Summary (`:44-54`) still doesn't mention `icon-init`'s vocabulary. Two cycles open. The cost is now concrete rather than theoretical: `icon-init` acquired a `python3` dependency (M-89-03-06) that `detect-tree-position` does not have, and `resolve-repo-context` acquired a third, narrower signal list (M-89-03-08) — three drifting copies of one algorithm, with no cross-reference to make the drift visible. A two-line footnote at each endpoint, plus a pointer from `resolve-repo-context:60`, closes it.

**Effort:** trivial. **Impact:** medium.

### IO-89-03-04 — Make `upgrade-repo`'s Phase 4 the executable definition of "conformant `.context/`", and run it at the end of init

`upgrade-repo` Phase 4 (`:617-627`) is already the most complete statement of what a finished `.context/` looks like — nine concrete, checkable items. Three of them (`claude.md`, `rules-index.md`, `INTEGRATION_BRANCHES`) are things `impl-root` does not produce. Rather than duplicating the list into `impl-root`'s Step 15, have every init path **end** by running the same checklist. Init and upgrade then converge on one definition by construction, and C-89-03-03 / M-89-03-02 become impossible to reintroduce. This pairs naturally with IO-89-03-01 (the checklist reads the manifest) and **SO-3** (the checklist is a script).

**Effort:** medium. **Impact:** high.

### IO-89-03-05 — Split `upgrade-repo` (659 lines / 29 KB) along the migration/infrastructure seam

`skills/upgrade-repo/SKILL.md` is the largest file in the domain by a factor of 1.5 and holds four distinct concerns: instructions-file migration (Phase 0), a stock/customized audit (Phase 1), ~220 lines of one-time `decisions.md` → `decisions/` migration shell in two languages (`:214-432`), and the actual infrastructure sync. The migration blocks are dead code for any repo initialized after MKT-0090 — which by now is nearly all of them — yet they are loaded in full on every upgrade. `context-document-guidelines`' folder-split rule (16,000-byte threshold + ≥3 peer `##` sections) is a `.context/`-doc rule, not a skill rule, so this is not a gate violation; it is a token-governance and reviewability observation, and it's relevant that C-89-03-01 and M-89-03-01 both live in this file, in blocks a reader is unlikely to reach. Extracting `upgrade-repo-migrations` as a conditionally-loaded companion (the `step-4-file-content.md` precedent) would cut the always-read surface roughly in half.

**Effort:** medium. **Impact:** medium.

---

## Architectural Coherence Observations

### The init tree has one entry point and no exit contract

`icon-init` successfully unified the front door — four `initialize-*` skills, all `user-invocable: false`, one confirmed dispatch. But there is no corresponding unification at the back: each of the three impl skills defines its own completion criteria in prose, and `upgrade-repo` defines a fourth. The result is that ICON can guarantee *which* initializer runs but cannot guarantee *what it produced*. Every Critical and Moderate parity finding in this report lives in that gap. A single entry point with four divergent exit contracts is a half-finished unification.

### Feature velocity lands in `impl-leaf` and stops

Tracing the v2.0.0 interval features through the three impl skills: `rules-index.md` (ICON-0069) → leaf only. `## Related` graph seam (ICON-0081) → leaf and root, not branch (correctly — branch has no content docs), and **not `upgrade-repo`**. Root `.gitattributes` (ICON-0073) → all three, correctly. `claude.md` redirect (pre-2.0.0) → leaf only. The pattern is that `impl-leaf` is where authors work, and propagation to siblings is a per-task judgment call that succeeds when someone remembers. ICON-0077 (`impl-branch` verify) and ICON-0078 (multimodule root parity) were each a whole task spent retroactively closing one instance of this. The retro for ICON-0077 (`.context/retrospectives-archive.md:85`) records the correct *heuristic* — template from the role-matching sibling — but a heuristic applied by memory is precisely the "reach-at-the-moment-of-need" failure the baseline preamble names as this cycle's anchor.

### `upgrade-repo` verifies obligations that no init path creates

Phase 4's nine items are the closest thing ICON has to a specification of a conformant `.context/`. Three of them are unreachable from `impl-root`. This is an inverted dependency: the *remediation* skill is the de facto spec, and the *creation* skills are the drift. It also explains why M-89-03-07 (schema 1.2 vs 1.12) matters beyond hygiene — the only routine that would ever evaluate the spec has never been run.

### Two divergence contracts govern `context_template/`, and only one is enforced

`.context/standards/skill-decomposition/process-doc-sweeps.md` establishes a byte-equal three-surface sweep rule with a per-file exception (ICON-0074) for `branching.md` and `commit-conventions.md`. That exception is enforced by nothing, and `commit-conventions.md` has drifted out of it (M-89-03-04) while `branching.md` has not. Meanwhile the `.githooks/pre-commit` template-version gate treats `context_template/` as an undifferentiated monolith — it fires identically for a file every consumer receives and for `UPDATE_LOG.md`, which no consumer has ever received. The repo has fine-grained *policy* about `context_template/` and coarse-grained *mechanism*, and the retrospective record (`.context/retrospectives-archive.md:16,36,51`) shows the mechanism generating friction across at least three tasks.

---

## Script-Offload Candidates

Ranked by leverage. Existing inventory checked first — **SO-2**, **SO-6**, and **SO-7** are extensions to `.githooks/pre-commit`, `check-rules-index.sh`, and `context-graph.sh` respectively rather than new tools.

### SO-1 — Template payload manifest: detect dead template files and broken `cp` targets

- **(a) LLM-carried today:** "does this template file reach a consumer, and does every `cp` in an init skill point at a file that exists?" — carried nowhere explicitly; inferred from reading `impl-leaf/SKILL.md:115-158`, `impl-root/SKILL.md:221-229`, `impl-branch/SKILL.md:108`.
- **(b) Observed failure:** m-89-03-03 — nine shipped template files reach no consumer, including a stale `UPDATE_LOG.md`. No retro records this; it has simply never been checked.
- **(c) Mechanization:** a `templates.manifest` data file (`{template_path, copied_by: [skill…], mode: copy|schema-reference|diff-only}`) plus a `.githooks/pre-commit` check that (i) every file under `context_template/context/` appears in the manifest, (ii) every `cp "$TEMPLATE_DIR/…"` line in `skills/**/SKILL.md` resolves to an existing template path, (iii) manifest entries marked `copied_by: []` are explicitly annotated with a reason. **Fail-closed.**
- **(d) Residual judgment:** whether a dead file should be deleted, kept as a documented schema reference, or wired into a copy step.
- **(e)** Low effort × **high** leverage.

### SO-2 — Make the template-version gate scope-aware and monotonic

- **(a) LLM-carried today:** `.githooks/pre-commit:57-72` asserts only that the `version` *field changed*. Whether the bump is monotonic, and whether the change even warranted one, is entirely author judgment — restated as prose in `.claude/CLAUDE.md` § Template version and `.context/domains/hooks.md`.
- **(b) Observed failure:** three separate retro entries. `.context/retrospectives-archive.md:16` — an @architect design asserted no bump was needed and would have been blocked. `:36` — "the @architect spec's Key Files list omitted this coupling and the @coder hit the gate only at staging time, costing a follow-up round." `:51` — the gate's merge-base baseline generated per-MR churn that needed a whole release-time consolidation step, later root-caused to the baseline choice.
- **(c) Mechanization:** extend the existing check with (i) a numeric monotonicity assertion (`new > old`, not merely `≠`), and (ii) SO-1's manifest as the scope filter — a change touching only `copied_by: []` files does not require a bump; a change touching a consumer-reachable file does. **Fail-closed** on both.
- **(d) Residual judgment:** the size of the bump (minor vs. a schema-breaking change requiring an `upgrade-repo` migration step).
- **(e)** Low-medium effort × **high** leverage. Highest-confidence candidate: the failure is documented three times.

### SO-3 — `check-context-complete.sh`: one conformance checker for init and upgrade

- **(a) LLM-carried today:** the required-file set, restated in prose at six sites — `impl-leaf:298-314`, `impl-branch:120-130`, `impl-root:289-303`, `upgrade-repo:108-181` and `:619-627`, `initialize-repo`'s 3-item post-dispatch check.
- **(b) Observed failure:** C-89-03-03 and all four rows of M-89-03-02 — five obligations present in one copy and absent from another. Two prior whole tasks (ICON-0077, ICON-0078) were spent closing single instances of this same class.
- **(c) Mechanization:** `skills/context-maintenance/scripts/check-context-complete.sh [--position leaf|branch|root] [repo_root]`, reading IO-89-03-01's manifest, modeled directly on `check-rules-index.sh`'s existing shape (read-only, diagnostics to stderr, 0/1/2 exit contract, no `2>/dev/null`). Invoked as the final Verify step of all three impl skills and as `upgrade-repo` Phase 4. **Fail-closed** in the ICON repo's pre-commit; **advisory (exit-code-reported, non-blocking)** in consumer repos, matching the `rules-index` gate's "an absent index is not a blocker" precedent (`.context/retrospectives-archive.md:37`).
- **(d) Residual judgment:** whether a conditionally-required file was *intentionally* omitted (`decisions/` when no cross-project decisions exist; `excludes` in `iconrc.json`) — the checker reports, the agent adjudicates.
- **(e)** Medium effort × **high** leverage.

### SO-4 — Shipped-shell portability linter

- **(a) LLM-carried today:** `.context/standards/shell-portability.md` — six rules an agent must remember and apply while authoring fenced shell inside a SKILL.md. Rule 3 explicitly asks for live-testing, which is never evidenced in practice.
- **(b) Observed failure:** three live sites found this cycle — `initialize-monorepo:82` (C-89-03-02), `upgrade-repo:492-495` (M-89-03-01), `context_template/…/commit-conventions.md:74` (M-89-03-04) — none of which involve the gawk-isms the standard actually enumerates. The standard's own body records two prior escapes: ICON-0040 (a `git rm` that would have destroyed consumer data on mawk, caught only by a reviewer live-running the block) and ICON-0075 (a secret-scan pattern that "would have NEVER fired").
- **(c) Mechanization:** extract fenced ` ```bash ` blocks from `skills/**/SKILL.md`, `agents/*.agent.md`, and `context_template/**`, then grep the extracted text for a fixed deny-list: `grep -P`/`-oP`, `\K`, `sed -i` not followed by a suffix argument, `readlink -f`, `date -d`, `mktemp -p`, 3-arg `match(`, `printf -v` inside an awk block, and a pattern that can begin with `-` passed without `-e` (Rule 4). Runs as a `.githooks/pre-commit` check and as a `.github/workflows/` job beside the existing shellcheck stage. **Fail-closed.** Note the deny-list is a superset of the rules the standard states — SO-4 would also drive the standard to name `grep -P`, which it currently does not.
- **(d) Residual judgment:** choosing the portable *replacement* (POSIX ERE vs. `sed` vs. moving parsing into bash), and whether a block is genuinely maintainer-only.
- **(e)** Low effort × **high** leverage. Cheapest Critical-preventing candidate in this report.

### SO-5 — Per-release stock-template fingerprint registry

- **(a) LLM-carried today:** nothing — this is currently carried by a *diff against HEAD's template*, which is a script doing the wrong thing rather than an LLM doing anything. `upgrade-repo:119-145`.
- **(b) Observed failure:** C-89-03-01, affecting the entire pre-2.0.0 installed base. Commits `3418e84` and `2866f2b` are the proximate cause; `2866f2b`'s two added lines exist solely to satisfy ICON's own graph gate, making this a case of one gate breaking another skill.
- **(c) Mechanization:** `.claude/skills/release-plugin/scripts/bump-versions.sh` emits `context_template/STOCK-HASHES.json` — `{template_path: {schema_version: sha256}}`, append-only across releases. `upgrade-repo` Phase 1 then answers "is this file stock?" as "does its sha256 appear under *any* recorded schema version?" rather than "does it equal HEAD's copy?". Correct for every historical consumer, and it generalizes to every version-markered template file, not just the deprecated one. **Fail-closed** in the release script (refuse to release if a hash is missing); the consumer-side lookup is a straight improvement over the current diff.
- **(d) Residual judgment:** what to do once a file is correctly identified as genuinely customized — the `merge-phase-templates` routing decision is real judgment and stays.
- **(e)** Medium effort × **high** leverage.

### SO-6 — Encode the ICON-0088 split-gate exemption list as data

- **(a) LLM-carried today:** the exempt class is enumerated in prose at `skills/context-document-guidelines/SKILL.md:90`, and the 16,000-byte rule is separately restated at `skills/context-maintenance/SKILL.md:89,189,199` and `.context/standards/in-task-maintenance.md:21`.
- **(b) Observed failure:** `.context/retrospectives.md:2` documents this precisely, from ICON-0088 itself: "A parenthetical member enumeration at a **satellite** site (`in-task-maintenance.md`'s 'snapshots, closed archives') went stale the instant the exempt class widened — and it was the site an agent consults for exactly that obligation. Satellites point by reference; only the canonical site enumerates. **Caught by @reviewer, not by any gate.**" The same entry notes the split gate's ≥3-section precondition "coincides with a precondition the gate already enforces mechanically" — i.e. the rule was deliberately re-axed onto something mechanizable, and then not mechanized.
- **(c) Mechanization:** a `.context/doc-size-exempt` data file (glob list) plus `check-doc-size.sh` — walk `.context/`, flag files over 16,000 bytes with ≥3 peer `##` sections, skip anything matching the exempt globs. Wire into `.githooks/pre-commit` for ICON and expose via `context-maintenance § Tooling` for consumers. Prose satellites then cite the data file instead of re-enumerating. **Fail-closed** for ICON; advisory for consumers, matching SO-3.
- **(d) Residual judgment:** *where* to split an oversized doc (the boundary axis — precisely what `boundary-axis-selection.md` exists to guide), and whether pruning suffices instead.
- **(e)** Low effort × **medium-high** leverage. The retro entry reads as a specification for this script.

### SO-7 — `context-graph.sh --stale`: by-name reference rot

- **(a) LLM-carried today:** "does this doc still describe a thing that exists?" — carried by `context-maintenance` Phase 1's judgment plus `upgrade-repo:613-615`'s 5-sample spot check (which samples `domains/` only and needs 2 of 5 misses to trigger).
- **(b) Observed failure:** m-89-03-04 — `shell-portability.md` Rule 5's justifying example cites an `icon-init` MCP gate and an `icon-status` credential check, both removed in ICON-0080, undetected across two audit cycles. m-89-03-02 — a wrong `.context/` path inside backticks. Both are invisible to `--check` because neither is a Markdown link, and `.context/retrospectives.md:38` records the complementary hazard (a literal example link parsed as a real edge), showing the parser's link-shaped view is already understood to be incomplete in both directions.
- **(c) Mechanization:** a `--stale` mode on the existing `context-graph.sh`, reusing its single parse pass. Extract backticked tokens matching known shapes — `skills/<name>`, `agents/<name>.agent.md`, `.context/<path>`, `§ <Section Heading>` — and resolve each against the filesystem and against the target file's own headings. Same 0/1/2 exit contract. Advisory-first (report-only for a cycle), then **fail-closed** once the false-positive rate is known. Reuse the existing `<!-- pre-commit:dead-ref-ok-start/end -->` escape hatch verbatim.
- **(d) Residual judgment:** whether an unresolvable name is rot, a deliberate forward reference, or prose that merely resembles a path.
- **(e)** Medium effort × **medium** leverage.

### SO-8 — Dogfood gate on ICON's own installed schema version

- **(a) LLM-carried today:** nothing at all — "has anyone run `/upgrade-repo` on ICON lately?" is a question no surface asks.
- **(b) Observed failure:** M-89-03-07 — `.context/iconrc.json` at 1.2 vs. template 1.12. Not a failure *report*; a failure *silence*. Had this fired, C-89-03-03, M-89-03-01, M-89-03-02, and M-89-03-03 would each have surfaced as a failing Phase 4 verify item.
- **(c) Mechanization:** three lines in `.githooks/pre-commit` (or a CI job) comparing `.context/iconrc.json` `version` against `context_template/context/iconrc.json` `version`. Warn on any drift; **fail-closed** when the gap exceeds one minor version, with the remedy in the message: "run `/upgrade-repo` on this repo." Pairs with SO-3 — once `check-context-complete.sh` exists, run it against ICON's own `.context/` in CI, converting the entire init/upgrade parity class into a red build.
- **(d) Residual judgment:** resolving whatever the upgrade surfaces, and deciding whether an ICON-local deviation is intentional (`excludes: ["architecture","testing","styling"]` legitimately is).
- **(e)** Trivial effort × **medium** leverage — but it is the trigger that would have made most of this report unnecessary.

---

## ICON-0058 Delta

### Fixed since ICON-0058

| ICON-0058 ID | Description | Evidence |
|---|---|---|
| **m-58-03-01** | `upgrade-repo/SKILL.md:616` stale "the 15th" | Fixed. `skills/upgrade-repo/SKILL.md:645` now reads "older than the 10th." Repo-wide grep for `the 15th` / `cap (15)` / `last 15` returns zero hits outside `.context/tasks/`. |
| **m-58-03-02** | `context_template/context/retrospectives.md:1` stale "the 15th" | Fixed. File now reads `<!-- New entries go here, above older entries. Remove entries older than the 10th. -->` |
| **m-58-03-04** | "plugin-lint Check A/B" phantom labels at 3 sites | Fixed. Repo-wide grep for `plugin-lint Check` returns zero hits. |
| **IO-58-02** | `context-specialist-impl-branch` lacks a verification step | Fixed by ICON-0077. `skills/context-specialist-impl-branch/SKILL.md:120-130` is a full Step 9 Verify with six conditional checks and a "flag any gaps" clause. |
| **IO-58-03** | `initialize-multimodule` root-context asymmetry | Fixed by ICON-0078. `skills/initialize-multimodule/SKILL.md:319-350` (Step 7) now dispatches `context-specialist-impl-root` at the root with a prompt near-identical to `initialize-monorepo:262-285` and `initialize-workspace:274-295`. The three orchestrators are now at parity. |
| **IO-58-05 (component)** | Stale "the cap (15)" in all three `append-retrospective-entry.sh` copies | Fixed. Zero hits repo-wide. |

### Still present or partial

| ICON-0058 ID | Description | Status |
|---|---|---|
| **m-58-03-03** | `upgrade-repo/SKILL.md:122` `diff … > /dev/null 2>&1` (ADR-007 scope) | **Still present, third consecutive cycle** (ICON-0046 `m-new-02` → ICON-0058 → ICON-0089). Now materially load-bearing for C-89-03-01. See **m-89-03-01** — recommend a fix or a formal ADR-010 Part B entry, not a fourth silent carry. |
| **IO-58-04** | `icon-init` / `detect-tree-position` 4→3 mapping undocumented at both endpoints | **Still present, and worse.** `icon-init:34` still says only "derived from". A third divergent copy of the signal list now exists at `resolve-repo-context:60-64` (M-89-03-08), and `icon-init` acquired a `python3` dependency the primitive doesn't have (M-89-03-06). See **IO-89-03-03**. |
| **IO-58-01** | Formalize or replace "plugin-lint Check A/B" | Resolved by deletion rather than by the recommended rule-citation replacement — the labels are gone; no `common-constraints.md` citation was added in their place. Closed. |
| ICON-0046 **IO-05** | `upgrade-repo` Phase 0 Case 3 partial-state defensiveness | **Still present.** `skills/upgrade-repo/SKILL.md:69-73` still says "Continuing to Phase 1" without warning that Phase 2 can produce a fully-upgraded `.context/` with no entry point. The `:98` note ("Redirect not created — `.claude/claude.md` must exist first") is adjacent but addresses only the redirect. |

### Net-new

| ID | Tier | Description | Location |
|---|---|---|---|
| **C-89-03-01** | Critical | `upgrade-repo` stock-vs-customized diff misfires for the entire pre-ICON-0080 installed base | `skills/upgrade-repo/SKILL.md:119-145` |
| **C-89-03-02** | Critical | `grep -oP` in `.sln` discovery → zero projects on macOS/BSD | `skills/initialize-monorepo/SKILL.md:82` |
| **C-89-03-03** | Critical | `impl-root` never creates the root `claude.md` redirect | `skills/context-specialist-impl-root/SKILL.md:94-107,289-303` |
| **M-89-03-01** | Moderate | iconrc version sync GNU-only, fails silently off-GNU | `skills/upgrade-repo/SKILL.md:491-500` |
| **M-89-03-02** | Moderate | Four further `impl-root` ↔ `impl-leaf` parity gaps | `skills/context-specialist-impl-root/SKILL.md:22-40,217-244,289-303` |
| **M-89-03-03** | Moderate | `upgrade-repo` has no `## Related` graph-seam step (ICON-0081 is init-only) | `skills/upgrade-repo/SKILL.md` (whole file) |
| **M-89-03-04** | Moderate | Template `commit-conventions.md` hardcodes `MKT`, breaking the documented ICON-0074 generic-scaffold contract | `context_template/context/workflows/commit-conventions.md:58,74` |
| **M-89-03-05** | Moderate | `.context/cache/` never created; TTL stated four ways (3 / 3 / 7 / 30) | `impl-leaf:117`; `context_template/context/META.md:70`; `resolve-repo-context:48`; `create-iconrc:39` |
| **M-89-03-06** | Moderate | `create-iconrc` Python-only, snippet non-executable, `python3` undeclared | `skills/create-iconrc/SKILL.md:81-160`; `skills/icon-init/SKILL.md:69-77` |
| **M-89-03-07** | Moderate | ICON's own `.context/iconrc.json` at schema 1.2 vs template 1.12 | `.context/iconrc.json:2` |
| **M-89-03-08** | Moderate | `resolve-repo-context` topology-drift list omits `turbo.json`/`go.work`/`pom.xml` | `skills/resolve-repo-context/SKILL.md:60-64` |
| **m-89-03-02** | Minor | `patterns-template.md` wrong path — ICON-0046 `m-new-01`'s literal surviving in a sibling site | `skills/task-plan-phase-completion/SKILL.md:76` |
| **m-89-03-03** | Minor | Nine `context_template/` files reach no consumer; `UPDATE_LOG.md` stale | `context_template/` (enumerated above) |
| **m-89-03-04** | Minor | `shell-portability.md` Rule 5 cites two removed mechanisms | `.context/standards/shell-portability.md` § Rule 5 |
| **m-89-03-05** | Minor | `icon-init` Step 5 promises an ordered list, has one item | `skills/icon-init/SKILL.md:211-221` |
| **m-89-03-06** | Minor | "copy verbatim, do not customize" contradicted by practice and by `upgrade-repo:611` | `impl-leaf:119`; `impl-root:231`; `impl-branch:26,29` |
| **m-89-03-07** | Minor | `initialize-repo` drops `git_root`/`feature_branch`; verifies 3 of 9 items | `skills/initialize-repo/SKILL.md` |
| **m-89-03-08** | Minor | `retrospectives-archive.md` referenced at 4 surfaces as if pre-existing; no template, created lazily | `context_template/` (absent); `impl-leaf:242,309`; `impl-root:266,303`; `upgrade-repo:181,481,627` |

**Pattern observation.** ICON-0058 identified sweep-incompleteness (Pattern A) as the domain's recurring class and observed that a literal-grep gate would have caught it. That prediction held in the affirmative: all five "the 15th" instances and all three "plugin-lint Check" instances were swept clean this interval. But the class did not disappear — it **moved up a level of abstraction**. This cycle's equivalent findings are not stale literals; they are stale *obligations* (C-89-03-03, M-89-03-02, M-89-03-03), which no literal grep can see because there is no literal to grep for. The three checkers that exist (`context-graph.sh`, `check-rules-index.sh`, `structural-check.sh`) all pass cleanly on this tree, and none of them can express "root init must produce what leaf init produces." That is the gap SO-1 through SO-4 target, and it is the reason a manifest (IO-89-03-01) is the prerequisite rather than another gate.

---

## Common Check Patterns

Applied to every file in scope; findings or explicit no-instances noted.

1. **Self-reference violation** — one instance: **m-89-03-06** (three impl skills mandate "copy verbatim, do not customize" for `META.md`, which ICON's own `META.md` violates across 13 hunks and which `upgrade-repo:611` exempts from upgrades). All other in-scope skills follow their own stated rules. `structural-check.sh` passes all five checks (B.1–B.6).
2. **Template / standard cross-reference** — findings **M-89-03-04** (template `commit-conventions.md` violates the ICON-0074 contract recorded in `process-doc-sweeps.md:40`), **m-89-03-02** (`task-plan-phase-completion/SKILL.md:76` diverges from its own correct `context_template/` counterpart), **m-89-03-03** (nine template files cited by nothing). Positively: `impl-leaf:283` correctly cites `context_template/context/rules-index.md` as the schema reference, and both graph-seam steps correctly defer to `context-document-guidelines § Related Section` rather than restating it.
3. **Operational defensiveness** — `upgrade-repo` is strong here (audit-before-act, per-directory confirmation at Phase 0, "get confirmation before touching any existing file" at `:183`, `mktemp`+`trap` at `:238-239`, the idempotent grep-before-append `.gitattributes` guard at `:468-485`, never-auto-overwrite version-marker logic at `:526-531`). `merge-phase-templates` correctly stages all diffs and takes a single confirmation (`:58`). Gaps: **IO-89-03-02** (no caller validates `$TEMPLATE_DIR` before `cp`), **ICON-0046 IO-05** (Phase 0 Case 3 partial-state), and `impl-root`/`impl-branch` have no dry-run or idempotency statement despite both being re-runnable.
4. **Frontmatter parser-fragility** — **no instances.** All 15 in-scope `SKILL.md` files and `agents/context-specialist.agent.md` use `description: >` folded-scalar form with consistent two-space continuation indentation. `user-invocable` is present and correct on every file (`true` on `icon-init`, `upgrade-repo`, `create-iconrc`; `false` on the twelve internal skills and the agent). ADR-009 (skill `description` callers not required) applied — no findings tiered for missing caller enumeration.

## Verification Evidence

```
$ bash .claude/skills/icon-audit/scripts/structural-check.sh
B.1 — SKILL.md sections            OK
B.2 — Brief skeleton headings      OK
B.3 — synthesis-template.md        OK
B.4 — agent-evaluation one-way ref OK
B.6 — SKILL.md frontmatter         OK
All structural checks passed.

$ bash skills/context-maintenance/scripts/context-graph.sh --check .
[context-graph] OK: 49 nodes, no dangling references, no orphans     (exit 0)

$ bash skills/context-maintenance/scripts/check-rules-index.sh .
[check-rules-index] OK: all rule units indexed and all index rows resolve   (exit 0)
```

Prior-finding closure verified by grep (all return zero hits outside `.context/tasks/`): `the 15th|cap (15)|last 15`, `plugin-lint Check`. Template-payload reachability verified by cross-referencing every `context_template/` basename against `skills/ agents/ commands/ hooks/ .claude/ .githooks/`. Deprecated-template drift verified via `git log`/`git diff` on `context_template/context/workflows/task-workflow-template.md` (commits `3418e84`, `2866f2b`).
