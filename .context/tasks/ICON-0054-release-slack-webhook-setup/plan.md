# ICON-0054 — Release Slack webhook: provisioning docs + graceful skip

## Problem

`release-plugin` Step 9 ("Post release to Slack") reads `$SLACK_WEBHOOK_URL` from
the shell environment and **hard-stops** if it is unset. The variable is exported
only in the original releaser's local `~/.bashrc` — it was never documented and,
correctly, never committed (a Slack incoming-webhook URL is a secret). A second
maintainer attempting a release has no such variable, so Step 9 blocks with
"stop — set the env var and re-run," making a completed release (tag + `latest`
already pushed in Step 8) look like a failure.

Two defects:
1. **Onboarding gap** — nothing tells a maintainer the env var must exist or where
   to get the value.
2. **Wrong severity** — a missing announcement webhook hard-stops, even though the
   release itself is already complete after Step 8.

## Decisions (confirmed with user)

- **Provisioning mechanism:** shell-profile export (`export SLACK_WEBHOOK_URL=...`
  in `~/.bashrc` / `~/.zshrc`). Matches current setup. The secret is NOT committed;
  the value lives in the **"shared" canvas of the AI-Council Slack channel**.
- **Scope:** documentation + make Step 9 degrade gracefully (skip-with-warning,
  print notes for manual posting, state the release already succeeded). New branch.

## Changes

1. `release-plugin/SKILL.md`
   - New **"Maintainer setup (one-time)"** section near the top: export
     `SLACK_WEBHOOK_URL`, where to obtain the value, never commit it.
   - Rewrite **Step 9** so a missing/failed webhook does NOT hard-stop: announce
     that the release is already complete (Step 8), print the formatted notes for
     manual paste, and continue to Step 10.
   - Update the **Error Conditions** table: missing `SLACK_WEBHOOK_URL` is a
     non-blocking skip, not a stop.
2. `CONTRIBUTING.md` — short maintainer pointer to the one-time webhook setup.
3. `CHANGELOG.md` — **no entry** (legitimate skip per `changelog-entry`): only the
   maintainer-only `.claude/skills/release-plugin/` skill and repo-internal
   `CONTRIBUTING.md` changed; nothing in the consumer-shipped set ships via the
   `latest` tag, so there is nothing to tell consumers.

## Out of scope

- Committing the webhook value or any secret.
- Changing release mechanics (Steps 1–8) or the marketplace flow.
- Actually cutting a release (no version bump, no tag — see NEVER-release rule).

## Verification

- Subagent retrieval test: read revised Step 9 cold and confirm (a) it never
  reports a failed release when the webhook is absent, (b) it directs the user to
  the setup section, (c) it produces manual-post notes.
- `format-slack.sh` still receives `$NOTES` unchanged.

## Immediate (out-of-band, no repo change)

Share the existing webhook value from `~/.bashrc` with the second maintainer via
the team secret store; they add the same `export` line and restart their shell.
