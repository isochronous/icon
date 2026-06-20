# Fixture 02: Fenced-Only Markers

Markers appear ONLY inside a fenced code block. The hook MUST treat them as
literal text and leave the file unchanged.

Here is an illustration of the sync markers:

```markdown
<!-- BEGIN: common-constraints -->
Example content here.
<!-- END: common-constraints -->
```

Done.
