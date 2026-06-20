# Fixture 09: Orphan BEGIN Inside Fence

Only a BEGIN marker, but it's inside a fence. The hook MUST treat it as
literal text — this agent file simply has no real markers. No-op, no abort.

```markdown
<!-- BEGIN: common-constraints -->
imagine the block would go here, but this file is just documentation
```

Trailing text.
