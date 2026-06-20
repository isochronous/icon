# Branching

The ICON repository uses a **`main`-only** branch model. There is no `dev` or `develop` integration branch. All work converges on `main`; the release IS the `vX.Y.Z` tag push plus the force-move of the `latest` tag.

This deliberately differs from the marketplace monorepo's `feature → dev → main` model. The decision and trade-offs are recorded in `.context/decisions/002-main-only-branch-model.md`.

## Branch Types and Lifetimes

| Branch | Pattern | Base | Merge target | Notes |
|--------|---------|------|--------------|-------|
| Integration | `main` | — | — | The only protected branch. All releases tag a commit on `main`. |
| Feature | `feature/ICON-NNNN-short-description` | `main` | `main` | Created off `main`, merged back when complete. |
| Hotfix | (none — same as feature) | `main` | `main` | No separate `hotfix/` flow because there is no parallel release branch to back-port to. |

The `.context/workflows/prune-context.sh` script's `INTEGRATION_BRANCHES` regex is the runtime authority for "which branches are integration branches?" — for ICON, it is exactly `^main$`. If this branch model ever changes, update both this file AND that script in the same commit.

## Examples from this repo's history

Pull from `git branch -a --merged main` to verify; recent examples:

```
feature/ICON-0001-migrate-context-from-mkt-0095
feature/MKT-0093-remove-agent-model-pins        (marketplace task ID; pre-split)
feature/MKT-0092-local-task-prefix-requirements (marketplace task ID; pre-split)
feature/MKT-0091-manager-role-injection         (marketplace task ID; pre-split)
```

Task IDs `MKT-NNNN` originate from the marketplace repo and are grandfathered in pre-split commits and merged feature branches. New ICON-only work uses `ICON-NNNN` (see `.context/workflows/commit-conventions.md`).

## Feature Branch Workflow

Branch creation follows task start; for how a task is initiated (the `New task:` convention, Resume vs Reopen), see `.context/workflows/task-start-conventions.md`.

```bash
# 1. Start from a fresh main
git checkout main
git pull origin main

# 2. Create the feature branch using the next ICON-NNNN task ID
git checkout -b feature/ICON-0002-some-short-description

# 3. Work, commit using the convention in workflows/commit-conventions.md
git commit -m "ICON-0002: do the thing"

# 4. Push and open a pull request targeting main
git push -u origin feature/ICON-0002-some-short-description
```

There is no rebase-onto-`dev` step because there is no `dev`. Rebase onto `main` if `main` advances during your work:

```bash
git fetch origin
git rebase origin/main
```

## Stacked Branches for Dependent Task Sequences

When a user requests **multiple dependent tasks in one go**, do not branch every task off `main`. Branch each task off the **previous task's branch** (a stacked sequence), and merge the PRs **in order** to avoid the merge conflicts that arise when sibling branches each touch the same files from a stale `main` base.

- **Confirm the topology at the start of a multi-task sequence.** Ask whether the tasks are stacked (each depends on the prior one's changes) or independent (each can branch off `main` and merge in any order). The answer determines the base for every branch in the sequence; getting it wrong forces a rebase mid-sequence.
- **Each branch bases on its predecessor.** Task 2 branches off `feature/ICON-0002-...`, task 3 off `feature/ICON-0003-...`, and so on. Each PR targets the **prior task's branch**, not `main`.
- **GitHub auto-retargets as earlier PRs merge.** When the task-1 PR merges into `main`, GitHub retargets the task-2 PR to `main` automatically; when task 2 merges, task 3 retargets; and so on. Merge the PRs in sequence so each retarget lands cleanly.
- **Enforce the order mechanically, not by discipline.** Mark each stacked PR as a draft until its predecessor merges, or note the blocking PR in the description, so a dependent PR is not merged ahead of its base. Re-mark ready once the base has merged and GitHub has retargeted.
- **Independent (off-`main`) tasks** keep the default model above: each branches off `main` and targets `main`, and merge order does not matter.

This is the same merge-base sharing that lets stacked same-release branches ride a single template-version bump (see the Template-Version Bump Cadence section below).

## Session Start: Surface a Pending Branch Before Switching

At session start, if the current branch is **not `main`** AND has **commits ahead of `main`** (`git branch --show-current` ≠ `main` and `git log main..HEAD` is non-empty), do not silently switch to `main` to start a new task. The branch carries unmerged work that a silent switch abandons.

Surface the pending state and let the user choose. For example:

> "Current branch `feature/ICON-NNNN-...` has N commits ahead of `main` that are not yet merged. Do you want me to (a) merge it first, (b) leave it for later and start the new task off `main`, or (c) use it as the new task's base?"

This holds even when the new-task prompt seems to assume an off-`main` start — defaulting to abandonment is rarely what the user wants. The check is one git command and is cheap insurance against shipping a release that silently omits the prior branch's work. If the user does want the prior branch left for later, that is fine — just confirm it explicitly rather than assuming.

## Merge Strategy

Merge to `main` may be either a fast-forward, a merge commit, or a squash — depending on the size of the feature and the reviewer's preference. There is no automated linear-history enforcement; reviewers exercise judgement.

After merge:
- Delete the local feature branch: `git branch -d feature/ICON-NNNN-...`
- Delete the remote feature branch via the GitHub UI or `git push origin --delete feature/ICON-NNNN-...`
- Local cleanup is also covered by `.context/workflows/prune-context.sh` for the per-task `.context/tasks/ICON-NNNN-.../` folders (auto-pruned after 90 days on `main`).

## Tag and Release Naming

| Tag | Mutability | Purpose |
|-----|-----------|---------|
| `vX.Y.Z` | Immutable | Pinned release. Marketplace consumers can pin to a specific version with this. |
| `latest` | **Mutable — force-moved at every release** | The marketplace listing references this repo with `ref: "latest"`; force-moving this tag is what propagates a new release to consumers. |

Recent tag history (`git tag | sort -V | tail`):

```
v1.15.0
v1.15.1
v1.15.2
v1.15.3
latest        ← currently points at v1.15.3
```

The `release-plugin` skill (maintainer-only, at `.claude/skills/release-plugin/`) drives both tag operations in lockstep. **Never** create a `vX.Y.Z` tag without also force-moving `latest` in the same release run — consumers would receive nothing.

## Template-Version Bump Cadence (release-aware gate)

ICON ships a consumer-facing context template under `context_template/`. Its version lives in `context_template/context/iconrc.json` (`version` field) and is **separate** from the plugin version in `.claude-plugin/plugin.json` (see `.context/decisions/003-version-source-of-truth.md` for the plugin-version SSOT). The template version is the signal consumers' `/upgrade-repo` uses to decide whether to re-apply the template.

**Cadence rule: bump the template version once per release, not once per task.** Consumers apply a template update once per release, so a single release should advance `context_template/context/iconrc.json` `version` **once total**, regardless of how many tasks in that release touched `context_template/`. Bumping per-task within one release produces redundant churn (this caused the ICON-0059/0060 double-bump).

**The ICON-0044 pre-commit gate keys its baseline off the `latest` tag (ICON-0071, superseding both the ICON-0062 merge-base baseline and the interim `git describe` baseline).** When a commit stages any change under `context_template/`, the `.githooks/pre-commit` gate requires the staged template version to **differ from the version at the `latest` tag** — the release-maintained pointer that the marketplace consumes (`ref: "latest"`) and that `release-plugin` Step 9 force-moves to every release commit. Because `latest` is fixed for an entire release cycle (it only moves at the next release), the baseline does not move as PRs merge. Both the gate and the `release-plugin` flow read this one tag, so they agree by construction. Behavior:

- **First template-touching PR of a release cycle** sees `staged == released` and must bump (`released -> released+1`). This preserves the "forgot to bump entirely" protection.
- **Every later PR in the same cycle** is already at `released+1 != released`, so it passes **without** a redundant re-bump — even though earlier PRs already merged to `main`. This is the fix for the cross-PR accumulation that the old merge-base baseline caused (each merged PR advanced `main`, so the next PR inherited the bumped value as its merge-base and was forced to bump again — ICON-0070 drift).
- **Stacked same-release branches / commits** also pass: once any commit in the stack bumps to `released+1`, later ones compare `released+1 != released` and ride the single bump.
- **Net effect:** exactly one template-version bump per release cycle, enforced automatically — no release-time consolidation needed (`release-plugin` Step 6 is now a verify, not a reset).
- **3-tier fail-safe fallback** (never weaker than the prior behavior): if the `latest` tag is absent (not fetched, shallow clone, pre-first-release repo) or its iconrc version can't be read, the gate falls back to the **merge-base with the default branch** (the ICON-0062 baseline); if the default-branch ref can't be resolved or `git merge-base` fails, it falls back to the **HEAD comparison** (original ICON-0044). Uncertainty degrades to a stricter tier — never to "allow".
- **Branch open across a release boundary** (a new release lands on `main` while a feature branch is open and has not rebased): `latest` advances to the new release, so that branch's baseline jumps forward. The gate still **fails safe** — the worst case is a spurious "please bump this cycle" (it only errors on `staged == baseline` equality, never a false PASS that lets unbumped template content through), and a `git rebase origin/main` reconciles it.

The default branch (used only in the Tier-2 merge-base fallback) is resolved from `.context/iconrc.json` (`default_branch`), then `main`, then `master`/`origin/master`. The gate logic lives in the ICON-0044/0062/0071 block of `.githooks/pre-commit`.

## Protected-Branch Rules

This is a **required setup prerequisite** a maintainer configures on the GitHub repository (Settings → Branches → branch protection rules). ICON's workflow depends on this gate but does not itself configure it — it is a server-side control the maintainer must enable once:

- `main` is a protected branch — no direct pushes; changes land only via pull request.
- Require at least one approval from someone other than the author.
- Reject force-push to `main`.
- A human performs the merge. The agent opens the PR and pauses — it never self-merges or self-approves. GitHub enforces approval-required and author-restrictions server-side, so the rule holds across the UI, the API, and the `gh` CLI alike.
- Keep the `latest` tag force-moveable (the release flow requires it).

## Commit Signing

The `ICON-NNNN:` commit prefix and the `Co-authored-by` trailer are plain-text provenance *claims* — anyone can type them, so they are forgeable. Cryptographic commit signing (GPG or SSH) gives a verifiable *proof* of authorship that GitHub checks server-side.

Enable signing locally. Two options:

**SSH signing (simplest):**

```bash
git config gpg.format ssh
git config user.signingkey <path-to-your-ssh-public-key>
git config commit.gpgsign true
```

Then add that key in GitHub (Settings → SSH and GPG keys → New SSH key) with its **Key type** set to "Signing Key".

**GPG signing:**

```bash
git config user.signingkey <GPG-KEY-ID>
git config commit.gpgsign true
```

Then add the GPG public key in GitHub (Settings → SSH and GPG keys → New GPG key).

**Verification and enforcement.** GitHub shows a **Verified** badge on signed commits whose key it can validate. Enable a branch-protection rule that **requires signed commits** on `main` so signing is enforced. Enforcement is repo-side: ICON recommends signing and documents how to enable it, but does not add an ICON-level signing gate.

## Why no `release/X.Y.Z` branches?

ICON is content-only (markdown + JSON + a single Node.js hook wrapper). There is no compile-step gating that benefits from a release-branch stabilization window. The lightweight scope, combined with the maintainer-only `release-plugin` skill, makes a separate release-branch flow pure overhead. See `.context/decisions/002-main-only-branch-model.md` for the full rationale.
