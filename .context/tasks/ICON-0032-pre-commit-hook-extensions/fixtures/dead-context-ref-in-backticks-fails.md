# Fixture: dead .context/ reference inside backticks still fails

The ref resolver is FENCE-BLIND: a reference in backticks or inside a
triple-backtick fence is checked the same as one in plain prose. This is
because the most common citation style is backtick-quoted paths, and
exempting them would silently skip the most common case.

Inline-backtick form: `.context/missing-dir/dead-file.md` should be flagged.

Triple-backtick fenced form:

```
This block contains a literal .context/another-missing/another-dead.md
reference which the resolver MUST also flag.
```

Expected hook behavior:
  exit 1
  stderr contains: both dead refs are reported (the resolver is fence-blind)
