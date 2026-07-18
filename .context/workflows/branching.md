# Branching

The ICON repository uses a **`main`-only** branch model. There is no `dev`/`develop` integration branch. All work converges on `main`; the release IS the `vX.Y.Z` tag push plus the force-move of the `latest` tag.

This differs from the marketplace monorepo's `feature → dev → main` model; rationale and trade-offs are in `.context/decisions/002-main-only-branch-model.md`.

## Branch Types and Lifetimes

| Branch | Pattern | Base | Merge target | Notes |
|--------|---------|------|--------------|-------|
| Integration | `main` | — | — | The only protected branch. All releases tag a commit on `main`. |
| Feature | `feature/ICON-NNNN-short-description` | `main` | `main` | Created off `main`, merged back when complete. |
| Hotfix | (none — same as feature) | `main` | `main` | No separate `hotfix/` flow — no parallel release branch to back-port to. |

The `.context/workflows/prune-context.sh` `INTEGRATION_BRANCHES` regex is the runtime authority for "which branches are integration branches?" — for ICON, exactly `^main$`. If the branch model changes, update both this file AND that script in the same commit.

## Examples from this repo's history

Verify with `git branch -a --merged main`; recent examples:

```
feature/ICON-0001-migrate-context-from-mkt-0095
feature/MKT-0093-remove-agent-model-pins        (marketplace task ID; pre-split)
feature/MKT-0092-local-task-prefix-requirements (marketplace task ID; pre-split)
feature/MKT-0091-manager-role-injection         (marketplace task ID; pre-split)
```

`MKT-NNNN` task IDs originate from the marketplace repo and are grandfathered in pre-split commits and merged branches. New ICON-only work uses `ICON-NNNN` (see `.context/workflows/commit-conventions.md`).

## Feature Branch Workflow

For how a task is initiated (the `New task:` convention, Resume vs Reopen), see `.context/workflows/task-start-conventions.md`.

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

There is no rebase-onto-`dev` step (no `dev`). Rebase onto `main` if it advances during your work:

```bash
git fetch origin
git rebase origin/main
```

## Stacked Branches for Dependent Task Sequences

When a user requests **multiple dependent tasks in one go**, do not branch every task off `main`. Branch each task off the **previous task's branch** (a stacked sequence) and merge the PRs **in order**, to avoid the conflicts that arise when sibling branches each touch the same files from a stale `main` base.

- **Confirm the topology at the start.** Ask whether the tasks are stacked (each depends on the prior one's changes) or independent (each branches off `main`, merges in any order). The answer sets the base for every branch; getting it wrong forces a mid-sequence rebase.
- **Each branch bases on its predecessor.** Task 2 branches off `feature/ICON-0002-...`, task 3 off `feature/ICON-0003-...`. Each PR targets the **prior task's branch**, not `main`.
- **GitHub auto-retargets as earlier PRs merge.** When task-1 merges to `main`, GitHub retargets task-2 to `main`; when task 2 merges, task 3 retargets. Merge in sequence so each retarget lands cleanly.
- **Enforce order mechanically, not by discipline.** Mark each stacked PR a draft until its predecessor merges (or note the blocking PR in the description), so a dependent PR is not merged ahead of its base. Re-mark ready once the base merges and GitHub retargets.
- **Independent (off-`main`) tasks** keep the default model: each branches off `main`, targets `main`, merge order does not matter.

This is the same merge-base sharing that lets stacked same-release branches ride a single template-version bump (see Template-Version Bump Cadence below).

## Session Start: Surface a Pending Branch Before Switching

At session start, if the current branch is **not `main`** AND has **commits ahead of `main`** (`git branch --show-current` ≠ `main` and `git log main..HEAD` non-empty), do not silently switch to `main` for a new task — the branch carries unmerged work a silent switch abandons.

Surface the state and let the user choose. For example:

> "Current branch `feature/ICON-NNNN-...` has N commits ahead of `main` not yet merged. Do you want me to (a) merge it first, (b) leave it for later and start the new task off `main`, or (c) use it as the new task's base?"

This holds even when the new-task prompt seems to assume an off-`main` start — defaulting to abandonment is rarely intended. The check is one git command, cheap insurance against a release that silently omits the prior branch's work. If the user does want it left for later, that is fine — confirm it explicitly rather than assuming.

## Merge Strategy

Merge to `main` may be fast-forward, merge commit, or squash — depending on feature size and reviewer preference. There is no automated linear-history enforcement; reviewers exercise judgement.

After merge:
- Delete the local branch: `git branch -d feature/ICON-NNNN-...`
- Delete the remote branch via the GitHub UI or `git push origin --delete feature/ICON-NNNN-...`
- `.context/workflows/prune-context.sh` also auto-prunes the per-task `.context/tasks/ICON-NNNN-.../` folders (after 90 days on `main`).

## Tag and Release Naming

| Tag | Mutability | Purpose |
|-----|-----------|---------|
| `vX.Y.Z` | Immutable | Pinned release. Marketplace consumers can pin to a specific version. |
| `latest` | **Mutable — force-moved at every release** | The marketplace references this repo with `ref: "latest"`; force-moving it propagates a new release to consumers. |

Recent tag history (`git tag | sort -V | tail`):

```
v1.15.0
v1.15.1
v1.15.2
v1.15.3
latest        ← currently points at v1.15.3
```

The `release-plugin` skill (maintainer-only, `.claude/skills/release-plugin/`) drives both tag operations in lockstep. **Never** create a `vX.Y.Z` tag without also force-moving `latest` in the same run — consumers would receive nothing.

## Template-Version Bump Cadence (release-aware gate)

ICON ships a consumer-facing context template under `context_template/`. Its version lives in `context_template/context/iconrc.json` (`version`), **separate** from the plugin version in `.claude-plugin/plugin.json` (plugin-version SSOT: `.context/decisions/003-version-source-of-truth.md`). The template version is the signal consumers' `/upgrade-repo` uses to decide whether to re-apply the template.

**Cadence rule: bump the template version once per release, not once per task.** Consumers apply a template update once per release, so a single release advances `context_template/context/iconrc.json` `version` **once total**, regardless of how many tasks touched `context_template/`. Per-task bumping within one release produces redundant churn (this caused the ICON-0059/0060 double-bump).

**The ICON-0044 pre-commit gate keys its baseline off the `latest` tag (ICON-0071, superseding both the ICON-0062 merge-base baseline and the interim `git describe` baseline).** When a commit stages any `context_template/` change, `.githooks/pre-commit` requires the staged template version to **differ from the version at the `latest` tag** — the release-maintained pointer the marketplace consumes (`ref: "latest"`) that `release-plugin` Step 9 force-moves to every release commit. `latest` is fixed for a whole release cycle (it only moves at the next release), so the baseline does not move as PRs merge; both the gate and `release-plugin` read this one tag and agree by construction. Behavior:

- **First template-touching PR of a release cycle** sees `staged == released` and must bump (`released -> released+1`). Preserves the "forgot to bump entirely" protection.
- **Every later PR in the same cycle** is already at `released+1 != released`, so it passes **without** a redundant re-bump — even after earlier PRs merged to `main`. This fixes the cross-PR accumulation the old merge-base baseline caused (each merged PR advanced `main`, so the next PR inherited the bumped value as its merge-base and was forced to bump again — ICON-0070 drift).
- **Stacked same-release branches / commits** also pass: once any commit in the stack bumps to `released+1`, later ones compare `released+1 != released` and ride the single bump.
- **Net effect:** exactly one template-version bump per release cycle, enforced automatically — no release-time consolidation (`release-plugin` Step 6 is now a verify, not a reset).
- **3-tier fail-safe fallback** (never weaker than prior behavior): if the `latest` tag is absent (not fetched, shallow clone, pre-first-release repo) or its iconrc version can't be read, the gate falls back to the **merge-base with the default branch** (ICON-0062 baseline); if that ref can't resolve or `git merge-base` fails, it falls back to the **HEAD comparison** (original ICON-0044). Uncertainty degrades to a stricter tier, never to "allow".
- **Branch open across a release boundary** (a new release lands on `main` while a feature branch is open and unrebased): `latest` advances, so the branch's baseline jumps forward. The gate still **fails safe** — worst case is a spurious "please bump this cycle" (it errors only on `staged == baseline` equality, never a false PASS that lets unbumped template content through), which `git rebase origin/main` reconciles.

The default branch (used only in the Tier-2 merge-base fallback) resolves from `.context/iconrc.json` (`default_branch`), then `main`, then `master`/`origin/master`. Gate logic lives in the ICON-0044/0062/0071 block of `.githooks/pre-commit`.

## Protected-Branch Rules

A **required setup prerequisite** a maintainer configures on the GitHub repository (Settings → Branches). ICON's workflow depends on this gate but does not configure it — it is a server-side control the maintainer enables once:

- `main` is protected — no direct pushes; changes land only via pull request.
- Require at least one approval from someone other than the author.
- Reject force-push to `main`.
- A human performs the merge. The agent opens the PR and pauses — it never self-merges or self-approves. GitHub enforces approval-required and author-restrictions server-side, so the rule holds across UI, API, and `gh` CLI alike.
- Keep the `latest` tag force-moveable (the release flow requires it).

## Commit Signing

The `ICON-NNNN:` prefix and the `Co-authored-by` trailer are plain-text provenance *claims* — forgeable. Cryptographic commit signing (GPG or SSH) gives verifiable *proof* GitHub checks server-side.

Enable signing locally. Two options:

**SSH signing (simplest):**

```bash
git config gpg.format ssh
git config user.signingkey <path-to-your-ssh-public-key>
git config commit.gpgsign true
```

Then add that key in GitHub (Settings → SSH and GPG keys → New SSH key) with **Key type** set to "Signing Key".

**GPG signing:**

```bash
git config user.signingkey <GPG-KEY-ID>
git config commit.gpgsign true
```

Then add the GPG public key in GitHub (Settings → SSH and GPG keys → New GPG key).

**Verification and enforcement.** GitHub shows a **Verified** badge on signed commits whose key it can validate. Enable a branch-protection rule that **requires signed commits** on `main` to enforce it. Enforcement is repo-side: ICON recommends signing and documents how to enable it, but adds no ICON-level signing gate.

## Why no `release/X.Y.Z` branches?

ICON is content-only (markdown + JSON + a single Node.js hook wrapper). There is no compile step that benefits from a release-branch stabilization window. The lightweight scope plus the maintainer-only `release-plugin` skill makes a separate release-branch flow pure overhead. See `.context/decisions/002-main-only-branch-model.md` for the full rationale.
