# Infrastructure and Distribution

Rules governing what ships with the plugin, why skills cannot share scripts across the filesystem, and what narrative is forbidden inside shipped surfaces.

## Skills Cannot Share Scripts

A script invoked from inside a skill must live under that skill's own `scripts/` folder. **Cross-skill filesystem references are forbidden** — a skill must never cite a path like `skills/<other-skill>/scripts/<file>` from its own `SKILL.md`, template, or brief.

**Why**: Skills are the unit of portability across runtimes. Both Claude Code and Copilot CLI load a single skill's directory; neither exposes a reliable cross-skill resource mechanism that works in both. A skill referencing a sibling skill's script silently breaks when copied, re-distributed, or loaded in isolation. The only mechanism that works in both runtimes is **co-locating the script with every skill that invokes it**.

**The duplication is the price**. If two skills both need `append-retrospective-entry.sh`, both get their own copy under their own `scripts/` folder. The bytes are duplicated; that cost is accepted in exchange for skill portability, isolation, and the absence of silent-breakage modes.

**What "references" means**: A skill references a script when its prose, checklist, or brief instructs the agent (or a delegated agent) to *invoke* the script. A skill that only *names* another skill's script in passing descriptive prose (e.g., "context-maintenance owns the append-retrospective-entry script") does not require its own copy — it is not invoking it.

**Allowed delegation pattern**: Skill A may delegate to `@context-specialist` or another agent that loads skill B; skill B then runs its own copy of the script. Skill A needs no copy because it never invokes the script — it routes the work.

**Forbidden pattern** (cross-skill filesystem reference):

```
# In skills/A/SKILL.md
Run skills/B/scripts/foo.sh ...
```

**Allowed pattern** (each skill self-contained):

```
# In skills/A/SKILL.md
Run ./scripts/foo.sh ...

# In skills/B/SKILL.md
Run ./scripts/foo.sh ...
```

**Verification rule**: Before committing a skill change that adds a script invocation, grep the skill folder for any `skills/<other>/` filesystem reference. If found, copy the target into the calling skill's own `scripts/` folder and rewrite the reference to a relative `./scripts/` path.

**Precedent**: MKT-0066 / MKT-0076 Phase 1 — `task-retrospective` previously cited `skills/context-maintenance/scripts/append-retrospective-entry.sh` from its own `SKILL.md`. The cross-skill reference was replaced with a local copy under `task-retrospective/scripts/` and a relative `./scripts/` path.

## Distribution Layout: What Ships with the Plugin

When a skill cross-references a reference file (e.g., a SSOT for a rule it enforces), the file's location decides whether the link works on installed plugin instances.

**What distributes with the plugin:**

- `agents/` — agent definitions
- `skills/<name>/` — skills, including any reference files inside the skill folder
- `commands/` — slash commands
- `hooks/` — Claude Code session hooks
- `shared/` — shared snippets (e.g., `common-constraints.md`)
- `.claude-plugin/plugin.json` — plugin manifest
- `.mcp.json` — MCP server configuration
- Top-level `README.md`, `CHANGELOG.md`

**What does NOT distribute:**

- `.context/` — the plugin's own internal documentation directory (this repo only)
- `.context/tasks/`, `.context/retrospectives.md`, `.context/standards/`, `.context/domains/`, `.context/workflows/`, `.context/decisions/`
- `context_template/` — template content used by `initialize-repo` to scaffold target repos (the template itself does not ship)
- `.githooks/`, `.git/` — repo metadata

**The rule**: A reference file consumed by a distributed skill (anything in `skills/`, `agents/`, `commands/`, `hooks/`, etc.) MUST live inside the consuming skill's folder. Cross-references from a distributed skill to `.context/...` are broken links on every installed plugin instance.

**Example**: `skills/task-plan-phase-completion/SKILL.md` cross-references its SSOT file. The SSOT lives at `skills/task-plan-phase-completion/agent-vs-skill-invocation.md` (relative `./agent-vs-skill-invocation.md` from the SKILL.md), not at `.context/standards/agent-vs-skill-invocation.md`.

**Anti-rationalization**:

| Excuse | Reality | Correct Action |
|---|---|---|
| "It's a 'standards' file — `.context/standards/` is the natural home" | "Standards" framing isn't a location indicator; only distribution path matters. | If a distributed skill references it, co-locate inside that skill's folder. |
| "I'll add a redirect note in `.context/` if someone needs it" | Installed plugin instances never see the redirect note either. | Co-locate; redirect notes are a dev-only luxury that doesn't ship. |
| "Cross-references inside the repo are usually fine" | Inside `.context/`, yes. Across the `.context/` ↔ distributed boundary, no. | Audit each link target: does it ship? If not, move it. |

**Precedent (ICON-0006)**: The new `agent-vs-skill-invocation.md` SSOT was originally placed in `.context/standards/`. User feedback flagged that the cross-reference from `skills/task-plan-phase-completion/SKILL.md` would be a dead link on installed instances. The file was relocated via `git mv` to `skills/task-plan-phase-completion/agent-vs-skill-invocation.md` and the cross-reference paths in SKILL.md updated from `../../.context/standards/...` to `./agent-vs-skill-invocation.md`.

### Agents Cannot Reference `.context/` Either

The distribution rule applies to **`agents/*.agent.md` exactly as to skills**: a shipped agent must not cite a path under `.context/` except the small set of standardized files that `initialize-repo` guarantees to exist in every generated `.context/` — currently `retrospectives.md`, `META.md`, and `overview.md`. Anything under `.context/standards/`, `.context/workflows/`, `.context/domains/`, `.context/decisions/`, `.context/cache/`, etc. is generated per-repo (and may be excluded via `.iconrc.json`), so a consuming repo will not have it.

A reference such as `agents/manager.agent.md` pointing at `.context/standards/<file>.md` is a dead link on every installed instance even when a file with that name exists in *this* plugin's own `.context/` — the consumer's `.context/` was scaffolded independently and owns its own contents.

**The fix is removal or relocation, never creation.** When you find a non-standardized `.context/` reference in a shipped agent, do not "fix" it by creating the referenced `.context/` file. Either delete the reference or move the content it needs into a shipped surface — the agent body itself, `shared/`, or a `skills/<name>/` folder. The same restriction applies to any user-invocable skill an agent may load: its cross-references must resolve on a freshly installed plugin, where only the standardized `.context/` files exist.

## No Historical Notes in Shipped Surfaces

Skills, agents, commands, hooks, and other shipped surfaces (anything under `agents/`, `skills/`, `commands/`, `hooks/`, `shared/`, `context_template/`) describe **current behavior** to the reader. They are not change-history documents.

Do NOT write:

- "Historical note: prior versions of this section did X. The change was canonicalized in ICON-NNNN."
- "Previously the manager wrote this directly; now the specialist does."
- "**Resolved (ICON-NNNN)**: ..." blocks that re-state current behavior in past-tense framing.
- "We used to handle this via Y but switched to Z because ..."

Why the rule:

- **Change history already exists in three durable places**: `git log` + `CHANGELOG.md` (consumer-visible release entries) + `.context/retrospectives.md` (per-task lessons). A historical note in a SKILL.md duplicates one of those and rots faster than all three.
- **Shipped surfaces are read at task-execution time, not as a history lesson**. A consumer reading `context-maintenance/SKILL.md` to do retro insertion needs to know what to do now, not what prior versions did.
- **Past-tense framing invites scope creep**: future tasks read the note, decide their own change deserves a similar note, and the file accumulates strata.

What IS allowed in shipped surfaces:

- A `Source` / `Provenance` section listing the ticket or task that originated the rule, with one-line context (the pattern in `skills/task-plan-phase-completion/agent-vs-skill-invocation.md § Source`). This is bibliographic metadata, not narrative history. One bullet each.
- A rule + rationale + exception sentence describing current behavior, even when the rationale references a past failure mode (e.g., "specialist stages with `git add` only — running `git commit` here sweeps pre-staged manager work into the wrong author's commit"). The rationale describes a *condition that exists now*, not a *history of changes*.

**Anti-rationalization**:

| Excuse | Reality | Correct Action |
|---|---|---|
| "Future readers need to know we changed this" | Future readers of a SKILL.md are running the skill, not auditing its evolution. | Put the change story in the CHANGELOG entry and the retrospective. Delete the note. |
| "The historical context explains *why* the current rule exists" | If the *why* is load-bearing, encode it as a current-tense rationale ("because X happens"), not as change history ("because we used to do Y"). | Rewrite past-tense framing into present-tense rationale. |
| "It's just one short note" | One short note becomes a stratum; the next task adds another. Skills bloat. | Delete; trust the CHANGELOG + retro + git log. |

**Precedent (ICON-0027)**: A Pass-1 fix added "Historical note: prior versions of this section ran `git commit` here. The split was canonicalized in ICON-0027." to `skills/context-maintenance/SKILL.md` and a "**Resolved (ICON-0027)**: ..." block to `agent-vs-skill-invocation.md`. Both were removed in a follow-up commit on the same MR after user feedback. The CHANGELOG entry, retrospective entry (`.context/retrospectives.md`), and commit history already carried the change story.

---

See [`../skill-decomposition.md`](../skill-decomposition.md) for the full skill-decomposition index.
