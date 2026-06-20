#!/usr/bin/env bash
# format-slack.sh — Convert markdown changelog text to Slack mrkdwn format.
#
# Usage: echo "$NOTES" | bash .claude/skills/release-plugin/scripts/format-slack.sh
#        echo "$NOTES" | ./format-slack.sh
#
# Reads from stdin and writes Slack-ready mrkdwn to stdout. Suitable for
# piping directly into a curl -d argument.
#
# Transformations applied (in order):
#   ## Heading    →  *Heading*   (mrkdwn bold)
#   ### Heading   →  *Heading*   (mrkdwn bold)
#   **bold**      →  *bold*      (mrkdwn bold)
#   "             →  \"          (JSON-safe double-quote escaping)
#   newlines      →  \n          (collapse to single-line JSON string)

set -euo pipefail

sed 's/^## \(.*\)/*\1*/' \
  | sed 's/^### \(.*\)/*\1*/' \
  | sed 's/\*\*/*/g' \
  | sed 's/"/\\"/g' \
  | sed ':a;N;$!ba;s/\n/\\n/g'
