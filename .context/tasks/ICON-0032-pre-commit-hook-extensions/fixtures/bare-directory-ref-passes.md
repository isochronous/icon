# Fixture: bare-directory .context/ reference passes

References to a directory under `.context/` with no filename (just a folder)
are intentional pointers — they tell the reader to look inside a folder,
not to open a specific file. The ref-resolver regex requires a filename with
an extension suffix, so bare directory references do not match.

Examples that MUST NOT be flagged:
- `.context/architecture/`
- `.context/domains/`
- `.context/standards/`

Expected hook behavior:
  exit 0
  no findings
