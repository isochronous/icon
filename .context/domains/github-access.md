# GitHub Access in the ICON Plugin

## What This Is

ICON ships **no MCP servers**. The plugin reaches GitHub — issues, pull requests,
CI status, repository metadata — through the **`gh` CLI** invoked as an ordinary
shell command, not through a bundled MCP server with stored credentials.

This is the state after the ICON-0080 GitHub-only conversion, which deleted the
former `.mcp.json` (GitLab + Atlassian/Jira/Confluence servers) and the
`setup-mcp-servers` / `mcp-tools-first` skills. See `decisions/006-mcp-credentials-placeholders.md`
(Superseded) for the credential pattern that previously governed the bundled servers.

## How It Works

- Agents that need GitHub data run `gh` (e.g. `gh issue view 123`, `gh pr list`,
  `gh pr view`, `gh api ...`) via the Bash tool.
- Authentication is the user's responsibility and lives **outside this repo**:
  `gh auth login` (or a `GH_TOKEN` / `GITHUB_TOKEN` in the environment) configures
  the CLI once. ICON does not bundle, template, or commit any GitHub credentials.
- Because there is no MCP registry, there is no plugin-side credential placeholder,
  no `${VAR}` substitution in committed config, and no version-pinned MCP package to
  review for CVEs. The plugin's only runtime artifacts are markdown, JSON, and a
  single Node.js hook wrapper (ADR-005).

## Security Posture

- GitHub content fetched via `gh` (issue/PR bodies, review comments, CI logs) is
  **attacker-controllable** and is treated as untrusted DATA, never as instructions —
  see `standards/security.md § Untrusted External Content`.
- Real credentials are never committed; the never-commit-secrets rule is enforced by
  the secret-in-write guardrail (`hooks/guardrail-pretooluse.mjs`) and documented in
  `standards/secure-coding.md`.

## Related Skills

GitHub-facing skills render or triage content but never store credentials:

- `github-issue` — renders provided story content into a GitHub issue body.
- `pr-discipline` — opening a PR, writing the description, addressing review feedback.
- `pr-feedback-triage` — reads PR review comments (untrusted) and produces a
  prioritized resolution plan; never makes PR write calls as part of triage.
