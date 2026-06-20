# Contributing to ICON

How to report problems, suggest changes, and contribute code to the ICON plugin.

## Report a defect or suggest a feature

Open a GitLab work item:

- **Issues board:** https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/issues
- **New issue:** https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/issues/new

For defects, include the ICON version (from `.claude-plugin/plugin.json`), the agent or skill involved, and expected vs. observed behavior. For feature suggestions, describe the workflow problem before the implementation — alternatives are often available.

A well-framed issue is a real contribution; you do not need to write code yourself.

## Contribute code

ICON is authored using its own workflow. The fastest path to a mergeable MR is to use ICON itself to make the change.

### Requirements

1. **Claude Code or Copilot CLI.** ICON's agents, hooks, and skills are designed for these tools. Hand-edited contributions are accepted, but the tooling enforces several conventions automatically (branch naming, task folders, retrospectives, CHANGELOG entries) that are easy to miss otherwise.
2. **ICON installed in your tool of choice.** Either install path in the [README's Installation section](README.md#installation) works.
3. **The ICON task flow** — see below.
4. **Protected-branch configuration on `main`.** A maintainer must configure the GitLab project so `main` requires a merge request and at least one approval, rejects force-push, and is merged by a human — see `.context/workflows/branching.md`.
5. **Commit signing enabled (GPG or SSH).** Sign your commits so authorship is cryptographically verifiable rather than a forgeable text trailer — setup steps are in `.context/workflows/branching.md`.

### The ICON task flow

Open a session in this repo and start with the literal phrase:

```
New task: <short description of what you're changing>
```

`@manager` will pick the next `ICON-NNNN` task ID, create the feature branch (`feature/ICON-NNNN-<slug>`), create the task folder under `.context/tasks/` with a `plan.md`, route work to specialists (`@planner`, `@architect`, `@coder`, `@tester`, `@reviewer`), and track progress through to a `CHANGELOG.md` `[Unreleased]` entry and retrospective.

When the change is implemented and verified, close the session with:

```
task complete
```

This triggers the retrospective pass and prepares the branch for MR.

### Holistic review before the MR

ICON is a tightly-coupled system: a change in one skill can shift behavior in another, and a change to an agent definition can affect every workflow that agent routes through. Before opening the MR, do a broader review pass beyond the immediate diff:

- Ask `@reviewer` to cross-check changed files against adjacent skills and agents. Does anything else need updating for consistency?
- Re-read the relevant ADRs in `.context/decisions/`. Did the change introduce or violate any decision recorded there?
- The pre-commit hook at `.githooks/pre-commit` enforces several invariants (`shared/common-constraints.md` byte-equality across agents, dead-reference resolution, `iconrc.json` version-bump gate, script parity). Configure your local hooks path so it runs before push (`git config core.hooksPath .githooks`).
- Confirm the `CHANGELOG.md` `[Unreleased]` entry accurately describes user-visible behavior change. One entry per distinct change, not one per file touched.
- **If you added or renamed a skill**, complete the new-skill integration checklist before opening the MR:
  1. **README row** — add the skill to the `### Skills` or `#### Internal Skills` table in `README.md` (the pre-commit skill-registration gate enforces this).
  2. **`using-skills` routing** — wire the skill into the relevant trigger/routing guidance so an agent actually reaches it at the moment of need.
  3. **Consuming-agent wiring** — confirm at least one agent or skill invokes it, and that any skill it depends on is invoked in turn.
- **Placeholder sentinel** — write `<!-- ICON-PLACEHOLDER -->` anywhere a value must be filled in before commit. The pre-commit hook blocks any commit that still contains this marker.

A useful framing: imagine a different contributor opening this MR a month from now. Could they tell, from the description and the diff alone, what the change does and why? If not, the description needs more.

### Opening the MR

Follow `mr-discipline` (your ICON session can dispatch this for you). The MR description should include the originating issue or task ID, a short summary of behavior change, the verification steps you ran, and any decisions future contributors should know about.

A maintainer will review. Expect questions about cross-skill impact — come prepared to discuss them. Substantial architectural shifts may be asked to land an ADR draft as part of the MR.

## Maintainers: cutting a release

Releases are cut with the `release-plugin` skill. The only machine-local setup is the Slack announcement (the final step): export `SLACK_WEBHOOK_URL` in your shell profile (`~/.bashrc` or `~/.zshrc`) so the release can post to the channel automatically. The webhook is a shared secret — obtain its value from the **"shared" canvas in the AI-Council Slack channel**, and never commit it. If the variable is unset the release still completes; the skill skips the automated post and prints the notes for you to paste manually. See the *Maintainer setup (one-time)* section in `release-plugin` for details.
