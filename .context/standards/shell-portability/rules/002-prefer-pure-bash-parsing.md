# Rule 2. Prefer pure bash for non-trivial parsing

When awk's pattern-action structure is not pulling its weight — multi-step capture, variable mutation, or conditional branching — prefer pure bash (`while IFS= read -r`, `[[ =~ ]]`, `BASH_REMATCH`). Simpler, more portable, and easier to live-test than an awk block embedded in a markdown fenced code block.

## Related

- Index: [shell portability rules](README.md)
- See also: [Rule 1](001-no-gawk-extensions.md) — the gawk extensions this rule routes around
