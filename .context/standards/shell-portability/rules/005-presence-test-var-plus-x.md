# Rule 5. Use `${VAR+x}` for presence tests, not `${VAR:-fallback}`

`${VAR+x}` is a POSIX **presence test**: it expands to `x` when `VAR` is set (even if set-but-empty) and to empty string when `VAR` is unset. Use it — e.g. `[ -z "${VAR+x}" ]` (unset) / `[ -n "${VAR+x}" ]` (set) — whenever distinguishing "unset" from "set-but-empty" is load-bearing.

`${VAR:-literal}` is a **fallback substitution**, not a presence test: it yields `literal` only when `VAR` is unset *or* empty, so an empty-but-set variable silently defeats a presence check written with it.

The live instance is the `MARKETPLACE_NAME` override in every Copilot CLI invocation block — `[ -n "${MARKETPLACE_NAME+x}" ] || MARKETPLACE_NAME="icon-marketplace"` in `skills/icon-init/SKILL.md`, `skills/find-context-template/SKILL.md`, and `skills/context-maintenance/SKILL.md`. A fork that deliberately sets `MARKETPLACE_NAME=""` must keep the empty value, which is exactly what `${VAR:-…}` would discard.

## Related

- Index: [shell portability rules](README.md)
- See also: [executable content](../../skill-decomposition/executable-content.md) § The Invocation Contract — the Copilot CLI fence this rule governs
