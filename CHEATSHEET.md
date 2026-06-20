# ICON Cheat Sheet

A one-page reference for **using** ICON day-to-day: how to start work, what the agents do,
and — most usefully — how to steer ICON's behavior with plain-English instructions.

> Commands below are written for **GitHub Copilot CLI** (the supported surface). A short
> [Claude Code addendum](#claude-code-addendum) at the end notes where Claude differs.

---

## 1. First-time setup

| Goal | Do this |
|------|---------|
| Install ICON | `copilot plugin marketplace add https://gitlab.com/onedatascan/ai-platform/marketplace.git` then `copilot plugin install ICON@datascan-marketplace` |
| Set up a repo for ICON | `/icon-init` — auto-detects project / monorepo / workspace and builds `.context/` |
| Wire GitLab + Jira credentials | `/setup-mcp-servers` |
| Update an older ICON repo | `/upgrade-repo` |
| Update the plugin itself | `copilot plugin update ICON` |

`/icon-init` is the one command every new repo needs. Everything else flows from the
`.context/` directory it creates.

---

## 2. The agents at a glance

**You can only address two agents directly: `@manager` and `@product-manager`.** Everything
else is a specialist the **manager delegates to** — you never invoke them yourself.

**The two you talk to:**

| Agent | Use it for |
|-------|------------|
| `@manager` | Any development work — it plans, delegates, tracks, commits, opens MRs. Your default entry point. |
| `@product-manager` | Shaping/refining Jira-style stories (no code) |

**The specialists the manager routes to** (internal — not user-invocable):

| Agent | Does | Manager calls it when… |
|-------|------|------------------------|
| `@planner` | Breaks a feature into sequenced tasks | The work is non-trivial / multi-file |
| `@architect` | Designs structure, reviews architectural decisions | A change crosses module/service boundaries |
| `@coder` | Writes the production code | Any code change |
| `@tester` | Writes and runs tests | Coverage is needed or TDD |
| `@reviewer` | Reviews a diff for quality/correctness | Before closing a task |
| `@researcher` | Pulls current library/API docs | External facts / versions matter |
| `@context-specialist` | Builds/maintains `.context/` docs | Context is missing or needs updating |

To influence which specialists run, you don't call them — you **steer the manager** with the
instructions in [section 4](#4-steering-icon-with-plain-instructions-) (e.g. "do a design pass
first" pulls in the architect/design gate; "skip the review" drops the reviewer).

---

## 3. Starting work — the `New task:` convention

The recommended way to start any work is the **`New task:`** prefix. Three shapes:

```
New task: WSD-1234
New task: No Jira ticket. Fix the bug where user sessions expire too early.
New task: WSD-1234. Retry cap should be 3 — not in the ticket, confirmed with Dana.
```

| Shape | When to use |
|-------|-------------|
| `New task: <Jira ID>` | Manager pulls the ticket and plans from it |
| `New task: No Jira ticket. <description>` | Local work with no Jira ticket |
| `New task: <Jira ID>. <extra context>` | A ticket **plus** details that aren't written in it |

**Resuming an unfinished task** — just name it; the manager restores state and continues from the next incomplete step:

```
Resume ICON-0042          ← finds the task folder + branch, picks up where it left off
```

**Reopening a finished task** — a task that already completed, now needs more work. **You must say why in the same prompt:**

```
Reopen ICON-0042 — the MR review asked us to handle the null-tenant case.
Reopen ICON-0042: add the missing pagination tests the reviewer flagged.
```

> ⚠️ **When reopening a completed task, always include the reason.** If you just say "reopen
> ICON-0042", the manager opens `plan.md`, sees every step is done, and immediately runs a
> retrospective instead of doing more work. Stating *why* — the new bug, the review feedback, the
> missing piece — tells it there's fresh work to do.

**What happens when you start a tracked task:**

1. Reads `.context/` for project knowledge
2. Creates a task ID + feature branch, writes `.context/tasks/<id>/plan.md`
3. Plans (if non-trivial) → implements → tests → reviews
4. **Runs a retrospective**, commits everything, opens an MR

Small, unambiguous fixes skip the branch/breakdown ceremony automatically — but never the retrospective (see §4).

---

## 4. Steering ICON with plain instructions ⭐

This is the part people miss. ICON's manager has three tiers of behavior. You change what's
in the **Default** and **Optional** tiers just by saying so — no config file needed.

### 4a. Turn OFF a default step

These run automatically; disable per-task with a sentence:

| Say this | Effect |
|----------|--------|
| "Don't create a branch — work on the current one" | Skips feature-branch creation |
| "Skip the review, this is throwaway" | Skips the `@reviewer` pass |
| "Don't research — just implement it" | Skips the upfront `@researcher` gate |
| "Do these one at a time, not in parallel" | Serial instead of parallel delegation |
| "Don't open an MR / don't commit — leave it on the branch" | Stops before commit/MR |

> 🔴 **Never skip the retrospective.** It is the single most important step in the entire ICON
> workflow — it's how lessons get promoted into `.context/` so the system gets smarter over time.
> There is no "skip the retro" instruction. Do not ask for one; ICON will run it regardless.

### 4b. Steer how much *planning* happens

| Say this | Effect |
|----------|--------|
| "Don't bother with a full breakdown — go straight to implementing" | Skips the `@planner` decomposition |
| "Plan this out first / break it down before touching code" | Forces a `@planner` pass |
| "Treat this as a quick one-file fix" | Lightweight path |
| "This is a big change — be thorough" | Full breakdown + architecture review |

> These tune the **`@planner` breakdown** (optional), not **`plan.md`** (required). For any tracked
> task the manager always writes and maintains a `plan.md` — that's not something you can turn off.

### 4c. Turn ON an optional gate

Off by default; opt in when you want them:

| Say this | Triggers |
|----------|----------|
| "Do a design pass first — propose a couple of approaches" | `design-first` (alternatives + approval before coding) |
| "I'm editing this repo too, so isolate your work" | `start-worktree` (git worktree, no branch/file clashes) |
| "Research the current best practice for X before deciding" | `@researcher` upfront |
| "Walk through this methodically, it's a stubborn bug" | `systematic-debugging` (reproduce → root-cause → verify) |

### 4d. Constrain scope & demand evidence

| Say this | Effect |
|----------|--------|
| "Only touch the API layer — don't refactor anything else" | Hard scope boundary passed to specialists |
| "Don't add new dependencies" | Constraint enforced downstream |
| "Show me the actual test output, don't just say it passed" | Forces command-output evidence |
| "Match the existing pattern in `foo/bar.ts`" | Points specialists at the precedent to copy |

### 4e. What you **can't** turn off (hardcoded)

Saying "just do it yourself" or "skip verification" won't work — these are non-negotiable:

- The manager **always delegates** to a specialist; it never hand-edits code, even one line.
- **No success claim without evidence** — commands get run, output gets quoted.
- A **`plan.md` is written** for any medium/complex task before work begins.
- The **retrospective always runs** at task close — see the red callout above.
- An **MR/PR number is never treated as a Jira ticket** — you'll be asked for the real ID.
- It **won't investigate source by grepping** as the manager — that's delegated.

If you ask for one of these, ICON will tell you it can't and explain why, rather than silently complying.

---

## 5. Config-level levers (`.context/iconrc.json`)

Persistent settings, set once per repo (re-run `/icon-init` or `/create-iconrc` to change):

| Field | What it controls | Example |
|-------|------------------|---------|
| `local_task_id_prefix` | Prefix for non-Jira tasks | `"ICON"` → `ICON-0055` |
| `default_branch` | Branch MRs target | `"main"` |
| `cache_expires_after_days` | When `@researcher` cache goes stale | `30` |
| `excludes` | `.context/` folders to skip on template sync | `["styling","testing"]` |
| `repo_type` | `project` / `monorepo` / `multi-module` / `workspace` | `"project"` |

Local task IDs must be `PREFIX-NNN` (3+ zero-padded digits) and the prefix must **not** collide
with any real Jira prefix the repo uses.

---

## 6. Useful skills you can invoke directly

User-facing skills (type the `/name`); the manager pulls in the rest automatically.

| Skill | Use it to… |
|-------|------------|
| `/icon-status` | See active task, branch, recent retros, context health, MCP creds |
| `/rfc` | Draft or polish an RFC |
| `/jira-story` | Render content into Jira story format |
| `/sprint-goals` | Generate sprint goals from a Jira CSV export |
| `/post-meeting` | Turn a meeting transcript into summary + action items |
| `/post-incident-review` | Run a structured incident retro |
| `/mr-feedback-triage` | Triage open MR review threads into a resolution plan |
| `/migration-planning` | Plan a schema/flag/version migration with rollback criteria |
| `/dependency-management` | Plan a library upgrade or new-dependency adoption |
| `/deep-research` | Multi-source, fact-checked research report |
| `/plugin-design` | Scaffold or audit a Claude Code plugin |
| `/writing-skills` | Author a new ICON skill |
| `/ecological-impact` | Footprint of your session (trees/water equivalents) |

---

## 7. Claude Code addendum

Claude Code isn't the officially supported surface, but if you use it the differences are small:

- **Manager is automatic.** A `SessionStart` hook adopts `@manager` from turn 1 in any
  ICON-initialized repo — you don't address `@manager` explicitly. (Copilot users do.)
- **Role switching mid-session:** `/ICON:manager` and `/ICON:pm`.
- **Opt out of the default:** `/ICON:disable-manager-default` (re-enable with `/ICON:enable-manager-default`).
- Everything in sections 3–6 above works the same — you just drop the `@manager` prefix.

---

## TL;DR

1. `/icon-init` once per repo, `/setup-mcp-servers` for credentials.
2. Start work with `New task: <Jira ID or description>`; the manager plans, codes, tests,
   reviews, runs the retrospective, and opens the MR.
3. **Steer it with sentences** — "skip the review", "plan this first", "do a design pass",
   "only touch the API layer", "show me the test output".
4. Some things are non-negotiable (delegation, verification, `plan.md`, **the retrospective**) — ICON will say so.
