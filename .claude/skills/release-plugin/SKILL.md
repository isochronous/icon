---
name: release-plugin
description: >
  Use when ready to cut a release of the ICON plugin
  after one or more rounds of changes have accumulated. Also use when changes have
  been pushed without a version bump and need to be retroactively released.
argument-hint: "[patch|minor|major] (override auto-detection)"
user-invocable: true
disable-model-invocation: false
---

# Release Plugin

## Overview

**Every release bumps one manifest file and one changelog, then tags `vX.Y.Z` and force-moves the `latest` tag.** This skill walks through that sequence so the marketplace listing (which consumes this repo at `ref: "latest"`) picks up the new version automatically.

Run all commands from the repository root.

**Canonical paths:**
- `.claude-plugin/plugin.json` — the single source of truth for the plugin version.
- `CHANGELOG.md` (repo root) — the authoritative changelog.

This repo uses a **`main`-only** branch model. Release housekeeping commits land directly on `main`; the release itself is the `vX.Y.Z` tag push plus the force-move of `latest`.

## Maintainer setup (one-time)

The only release step that needs machine-local configuration is the Slack
announcement (Step 10). **The Slack announcement is a personal/org-specific
integration (the AI-Council channel webhook) carried over from this plugin's
origin — you may want to reconfigure it to your own channel or remove it
entirely.** It reads the Slack incoming-webhook URL from the
`SLACK_WEBHOOK_URL` environment variable. **This is a shared secret — it is
deliberately not stored in the repo.** Without it the release still completes;
only the automated announcement is skipped (Step 10 degrades gracefully).

To enable the announcement on your machine, add the export to your shell profile
(`~/.bashrc`, or `~/.zshrc` on zsh) and restart your shell:

```bash
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/…"
```

Obtain the value from the **"shared" canvas in the AI-Council Slack channel**.
Do not paste the webhook URL into any committed file, commit message, or chat
transcript — only into your local shell profile.

Verify it is live in a new shell:

```bash
[[ -n "$SLACK_WEBHOOK_URL" ]] && echo "SLACK_WEBHOOK_URL: (set)" || echo "SLACK_WEBHOOK_URL: (not set)"
```

## release-plugin: Step 1: Confirm Ready State

Verify you are on `main` and the working tree is clean:

```bash
git rev-parse --is-inside-work-tree > /dev/null || { echo "error: not a git repository"; exit 1; }
git --no-pager branch --show-current
git --no-pager status --short
```

If not on `main`, **stop** — switch to `main` and complete release housekeeping there.

If any uncommitted changes exist, **stop** — do not release over a dirty working tree. Commit or discard all changes before proceeding.

Sweep user-facing docs (`README.md`, `.claude/claude.md`, `commands/*.md`) for behavioral drift vs. current-`main` since the last release tag — write any necessary corrections before authoring the CHANGELOG entry.

---

## release-plugin: Step 2: Find the Last Release Point

The last release is the commit the `latest` tag points at. `latest` is force-moved to every release commit by Step 9, and the marketplace consumes this repo with `ref: "latest"`, so it is the canonical "previous release" pointer. Because Step 9 has not run yet at this point in the flow, `latest` still points at the **previous** release throughout Steps 2–8 — exactly the baseline this release is measured against. The pre-commit template-version gate keys off the same `latest` tag, so the release process and the gate agree by construction.

```bash
git rev-parse --verify --quiet latest >/dev/null || {
  echo "error: 'latest' tag not found — fetch it with: git fetch origin 'refs/tags/latest:refs/tags/latest'"
  echo "(or, for a pre-first-release repo, use HEAD~20 as the base and note it in the changelog)"
  exit 1
}
echo "Last release: $(git rev-parse --short latest)  $(git --no-pager log -1 --oneline latest)"
```

If the `latest` tag cannot be fetched (e.g. a pre-first-release repo), fall back to `HEAD~20` in the diffs below and note this in the changelog entry.

---

## release-plugin: Step 3: Collect the Diff

```bash
git --no-pager diff latest..HEAD --name-only
git --no-pager diff latest..HEAD
```

Also collect the commit log for the range, which provides human-readable summaries:

```bash
git --no-pager log latest..HEAD --oneline
```

Read the full diff of agent and skill files to understand *what* changed, not
just *which files* changed.

---

## release-plugin: Step 4: Determine Version Bump Scope

Read the current version from the plugin manifest:

```bash
CURRENT=$(grep '"version"' .claude-plugin/plugin.json | grep -oP '[\d.]+')
echo "Current version: $CURRENT"
```

If the user passed an explicit bump argument (`patch`, `minor`, or `major`), use
that. Otherwise, determine scope from the diff:

| Signal in diff | Bump |
|---------------|------|
| Breaking change to agent/skill contract (renamed fields, removed skills, restructured frontmatter) | `major` |
| New agent or skill added | `minor` |
| New section or significant behavior added to existing agent/skill | `minor` |
| Bug fix, clarification, wording, constraint tightening, small addition | `patch` |
| Documentation-only (CHANGELOG, README, META.md) | `patch` |

When in doubt, prefer the more conservative bump. Present your reasoning to the
user before proceeding.

Compute the new version by incrementing the appropriate segment and zeroing
all lower segments (e.g., minor bump of `1.4.5` → `1.5.0`).

---

## release-plugin: Step 5: Write the CHANGELOG Entry

Open `CHANGELOG.md`. **Rename** the existing `## [Unreleased]` header to
`## [X.Y.Z] - YYYY-MM-DD` (the accumulated entries underneath move into the
new versioned section), then **insert a fresh empty `## [Unreleased]`
section above it**. The result is an empty `[Unreleased]` on top, with the
fully-populated `[X.Y.Z]` block immediately below:

```markdown
## [Unreleased]

## [X.Y.Z] - YYYY-MM-DD

### Added
- [new agents, skills, or major sections]

### Changed
- [modified behavior, updated rules, refined guidance]

### Fixed
- [bug fixes, corrections]
```

Rules for writing the entry — follow `.context/standards/changelog-discipline.md` (one sentence per entry, no fenced code blocks, ticket IDs at the end in parentheses) plus:
- Use the **file and section name** as the subject (e.g., `manager`, `researcher`, `commit-discipline`), not vague descriptions like "updated docs"
- Lead with what changed; the ticket reference at the end ties it to the rationale in the task plan / retrospective
- Omit sections that have no entries (don't include an empty `### Fixed`)

**Dedup guard — run after the rename + fresh-`[Unreleased]` insert.** Renaming `[Unreleased]` into a version block can leave two of the same `### Added`/`### Changed`/`### Fixed`/`### Removed` heading inside one version block if a heading was authored twice. Verify no version block contains a duplicate heading:

```bash
awk '/^## \[/{blk=$0; delete seen} /^### /{if(seen[$0]++) print "DUP in " blk ": " $0}' CHANGELOG.md
```

This must print **nothing**. If it prints a `DUP in …` line, open `CHANGELOG.md` and merge the two same-named headings within that block into one (move the bullets together, delete the second heading) before continuing.

---

## release-plugin: Step 6: Verify the Template Version (one bump per cycle)

ICON ships a consumer-facing context template whose version lives in
`context_template/context/iconrc.json` (`version` field). The cadence rule is
**one template-version bump per release, not per task** — see the
*Template-Version Bump Cadence* section of `.context/workflows/branching.md`.

As of ICON-0071 the pre-commit gate enforces this automatically: its baseline is
the **last release tag's** template version, so the first template-touching PR of
a cycle bumps `released -> released+1` and every later PR in the same cycle passes
unchanged. `main` can therefore no longer drift above `released+1` within a cycle,
and there is **nothing to consolidate**. This step is now a cheap safety check
that the gate is behaving — not a reset.

Read the template version at the last release (the `latest` tag, the same baseline the gate uses) and on current `main`, then confirm `main == released + 1`:

```bash
LAST_TEMPLATE_VER=$(git show "latest:context_template/context/iconrc.json" | grep -oP '"version":\s*"\K[\d.]+')
CURRENT_TEMPLATE_VER=$(grep -oP '"version":\s*"\K[\d.]+' context_template/context/iconrc.json)
echo "Template version — last release: $LAST_TEMPLATE_VER   current main: $CURRENT_TEMPLATE_VER"

EXPECTED_TEMPLATE_VER=$(awk -F. -v v="$LAST_TEMPLATE_VER" 'BEGIN{n=split(v,a,"."); if(n!=2){print "ERR:non-MAJOR.MINOR:"v > "/dev/stderr"; exit 1} print a[1]"."a[2]+1}')
echo "Expected template version this release: $EXPECTED_TEMPLATE_VER"
```

Interpret the result:

- **`$CURRENT_TEMPLATE_VER` == `$EXPECTED_TEMPLATE_VER`** — correct; exactly one
  bump rode this release. Proceed to Step 7.
- **`$CURRENT_TEMPLATE_VER` == `$LAST_TEMPLATE_VER`** — no template change this
  cycle. Valid only if **no file under `context_template/` changed since the last
  release**. Confirm with
  `git --no-pager diff latest..HEAD --name-only -- context_template/`;
  if that is empty, proceed unchanged. If it is non-empty, the gate should have
  forced a bump and did not — **stop and investigate the gate** (see below).
- **Any other value** (`> released+1`, `< released`, or multi-segment) — the
  `latest`-tag-baseline gate has malfunctioned: `main` should never reach these
  states under ICON-0071. **Stop and investigate** — do NOT auto-reset. Report
  the observed `$LAST_TEMPLATE_VER` / `$CURRENT_TEMPLATE_VER` / `$EXPECTED_TEMPLATE_VER`
  and inspect the baseline-resolution block in `.githooks/pre-commit` (verify
  `git rev-parse --verify --quiet latest` resolves and that
  `git show latest:context_template/context/iconrc.json` reads the expected version).
  Fixing the gate, not editing the
  version by hand, is the correct response.

---

## release-plugin: Step 7: Bump the Manifest

Only one file carries the version — `.claude-plugin/plugin.json`. Run the
companion script:

```bash
NEW="X.Y.Z"  # from Step 4

bash .claude/skills/release-plugin/scripts/bump-versions.sh "$NEW"
```

**Verify it was updated:**

```bash
grep '"version"' .claude-plugin/plugin.json
```

The line must show `"version": "X.Y.Z"`. If it still shows the old version, stop and fix it before continuing.

---

## release-plugin: Step 8: Commit on main

Stage the changed files and commit on `main`:

```bash
git add .claude-plugin/plugin.json CHANGELOG.md
git diff --cached --quiet -- context_template/context/iconrc.json || git add context_template/context/iconrc.json

# Replace <SUMMARY> with your release summary before running. Follow the
# conventional-commit pattern: <type>[optional scope]: <short description>
# Examples (from recent release commits):
#   feat: add @context-specialist agent and thin-router refactor
#   fix(manager): Turn Start plan currency check and plan.md delegation carveout
#   chore: restrict specialist agents to manager-only invocation
git commit -m "<SUMMARY> ($NEW)

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

The commit subject should be a brief one-line summary of the release content
followed by the version in parentheses, matching the convention visible in
`git log --oneline`. Examples:

```
feat: sub-agent isolation and research caching (1.4.4)
fix(marketplace): bump plugin version reference (1.4.1)
chore: restrict specialist agents to manager-only invocation (1.4.4)
```

---

## release-plugin: Step 9: Tag and push (this is the release)

Create the version tag, force-move the `latest` tag, and push everything:

```bash
git tag "v$NEW"
git tag -f latest
git push origin main "v$NEW"
git push -f origin latest
```

The marketplace listing references this repo with `ref: "latest"` — force-moving
the `latest` tag to the new release commit is what causes consumers to pick up
the new version on their next `/plugin update`.

Confirm the push succeeded and report the final commit SHA and version to the user:

```
Released: X.Y.Z (commit: <sha>)
Files bumped: .claude-plugin/plugin.json + CHANGELOG.md
Tags pushed: vX.Y.Z, latest (force-moved)
Changes included: [one-line summary]
```

---

## release-plugin: Step 10: Post release to Slack (announcement — non-blocking)

**The release is already complete after Step 9.** This step is the Slack
announcement only. A missing webhook or a failed post does **not** invalidate the
release and must **not** be reported as a release failure — fall through to the
manual-post fallback and continue to Step 11.

Always extract the latest versioned section from the changelog first:

```bash
NOTES=$(awk '/^## \[[0-9]/{if(found){exit}; found=1} found{print}' CHANGELOG.md)
```

If `$NOTES` is empty, the changelog section was not found — skip the automated
post and tell the user to announce manually; the release still stands.

Check whether the webhook is configured:

```bash
[[ -n "$SLACK_WEBHOOK_URL" ]] && echo "SLACK_WEBHOOK_URL: (set)" || echo "SLACK_WEBHOOK_URL: (not set)"
```

**If `$SLACK_WEBHOOK_URL` is not set** — do not stop. The webhook is a shared
secret that lives in your local shell profile (see *Maintainer setup (one-time)*
at the top of this skill); a maintainer who has not configured it yet can still
release. Print the formatted announcement so the user can paste it into the
channel by hand, then proceed to Step 11:

```bash
echo "Slack: SLACK_WEBHOOK_URL not set — skipping automated post (release is complete)."
echo "To enable automated posts, see 'Maintainer setup (one-time)' in this skill."
echo "--- paste this into the release channel manually ---"
echo "🚀"; echo "$NOTES"
```

**If `$SLACK_WEBHOOK_URL` is set**, post to Slack:

```bash
curl -s -X POST "$SLACK_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d "{\"text\": \"🚀 $(echo "$NOTES" | bash .claude/skills/release-plugin/scripts/format-slack.sh)\"}" \
  && echo "Slack: posted successfully" \
  || echo "Slack: curl failed — release still stands; post manually (check SLACK_WEBHOOK_URL and network)"
```

A "posted successfully" line confirms the announcement. If the post failed,
report that the announcement needs a manual post — **not** that the release
failed.

---

## release-plugin: Step 11: Verify marketplace pickup

No marketplace edit is required. The marketplace listing's marketplace.json
references this repo with `ref: "latest"`, and Step 9 force-moved the
`latest` tag to the new release commit. The marketplace listing will resolve
to the new version automatically on the next `/plugin update` from a consumer.

Tell the user explicitly: "The `latest` tag now points at `vX.Y.Z`. No
marketplace repo edit is required — consumers will pick up the new version on
their next plugin update."

---

## Error Conditions

| Condition | Action |
|-----------|--------|
| Not on `main` branch | Stop. Instruct user to switch to `main` and complete housekeeping there before releasing |
| Dirty working tree | Stop. List untracked/modified files and ask user to resolve |
| No versioned commit found in history | Use `HEAD~20` as base, flag in report |
| Manifest not updated after Step 7 | Stop. Check the `bump-versions.sh` exit code; run `git diff .claude-plugin/plugin.json` to see what (if anything) was changed |
| `git push` fails | Report the error verbatim; do not retry silently |
| `git push -f origin latest` fails | Stop. Report verbatim — without the moved `latest` tag, marketplace consumers will not see the new version |
| User-supplied bump arg is not `patch`/`minor`/`major` | Stop and ask for a valid value |
| `SLACK_WEBHOOK_URL` not set (Step 10) | **Do not stop** — the release is already complete. Skip the automated post, print the notes for manual posting, point the user at *Maintainer setup (one-time)*, and continue |
| Slack post (`curl`) fails (Step 10) | **Do not stop** — report that the announcement needs a manual post; the release still stands |
