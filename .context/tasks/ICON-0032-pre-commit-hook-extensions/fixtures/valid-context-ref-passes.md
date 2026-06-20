# Fixture: valid .context/ reference passes

A `.context/architecture/patterns-template.md` reference resolves against
`context_template/context/architecture/patterns-template.md`, which exists
in this repo. The hook MUST NOT flag it.

Other valid references:
- `.context/retrospectives.md`
- `.context/iconrc.json`
- `.context/workflows/task-plan/base.md`

Expected hook behavior:
  exit 0
  no findings
