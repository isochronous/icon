# Fixture: dead .context/ reference fails

The line below cites a path under `.context/` whose target does not
exist under `context_template/context/`. The ref resolver MUST flag it.

For an example of a missing target, see .context/this-directory-does-not-exist/missing-file.md
for details.

Expected hook behavior:
  exit 1
  stderr contains: `dead .context/ reference`
  stderr contains: `'.context/this-directory-does-not-exist/missing-file.md'`
