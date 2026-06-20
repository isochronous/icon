---
name: mcp-tools-first
description: >
  Use when about to access GitLab (issues, merge requests, pipelines, commits, files, wiki pages)
  or Atlassian Jira (tickets, sprints, boards, comments) or Confluence (pages, spaces, comments) —
  including when about to type `curl https://gitlab.com/api/...`, `gh issue view`, `glab mr view`,
  paste a web URL into a response, ask the user to paste content from one of those systems, or
  run `which gh` / `which glab` / `command -v <cli>` to check for a CLI alternative.
user-invocable: false
---

# MCP Tools First

The ICON plugin ships GitLab and Atlassian MCP servers (configured in `.mcp.json`). Use the
bundled GitLab tools for GitLab and the bundled Jira / Confluence tools for Atlassian. Tool-name
prefixes differ by harness — Claude Code surfaces them as `mcp__gitlab__*` and
`mcp__atlassian__jira_*` / `mcp__atlassian__confluence_*`; other harnesses (Copilot, etc.) surface
the same tools under their own naming (`gitlab-*`, `atlassian-jira-*`, …). Same servers, same
operations, different prefixes — match whatever your harness exposes. If a call fails with an
authentication error, invoke `setup-mcp-servers` to configure credentials.

## When the MCP Tool's Schema is Unknown

If the matching MCP tool has been confirmed to exist (via your harness's tool search, or because
its name appears in a deferred-tools system reminder) but you have not called it before in this
session and don't know its parameter shape: **load the schema, don't fall back.** Use whatever
schema-discovery mechanism your harness provides — Claude Code's `ToolSearch` with
`select:<exact_tool_name>`, Copilot's `tool_search_tool_regex` with the tool name as pattern, or
the equivalent in your environment — then call the tool with the parameters its schema requires.
Parameter-discovery is one extra tool call. CLI fallback to dodge it is a skill violation.

You do not need to check whether `gh`, `glab`, or any other CLI is installed. The MCP tool is the
path.

## Red Flags — STOP

If you catch yourself about to do any of these, stop and use the MCP tool instead:

- Running `which gh`, `which glab`, `command -v <cli>`, or any other "is the CLI available?" probe
- Typing `gh ...`, `glab ...`, or `curl https://gitlab.com/api/...` / `curl https://<host>/rest/api/...`
- Pasting a GitLab/Jira/Confluence URL into your reply and asking the user to read it
- Thinking "the MCP tool exists but I don't know the parameters — the CLI syntax I know is safer"
- Thinking "I'll just verify the CLI is available first, then decide"

All of these mean: the MCP tool is the path. If the schema is unknown, load it via your harness's
tool-schema discovery and call the MCP tool.

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I know the `glab`/`gh` syntax cold; the MCP tool's parameters are unknown" | Parameter-discovery is one schema-lookup call (whichever mechanism your harness exposes). CLI fallback to dodge it is the violation. |
| "I'll just check if `glab` is available first, then decide" | The check itself is the violation. The MCP tool's existence is already known — no decision remains. |
| "The MCP tool might fail on first call; CLI is the lower-risk path" | A failed MCP call returns an error you can fix. A CLI fallback bypasses the skill silently. |
| "Pasting the URL and asking the user to read it is faster" | It offloads the work the MCP tool exists to do. Read the resource with the MCP tool. |
| "This is just a one-off lookup, not worth the schema load" | One-off lookups are exactly what the MCP tools are scoped for. |
| "I'll use the MCP tool next time" | Next time has the same parameter-discovery cost. Pay it now or you'll dodge it forever. |

## On Auth Failure

If an MCP call returns an authentication error, invoke `setup-mcp-servers` — do not fall back to
CLI or URL paste.
