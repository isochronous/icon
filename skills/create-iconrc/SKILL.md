---
name: create-iconrc
description: >
  Use when `.context/iconrc.json` needs to be created or updated — whether initializing a repository for the first time or modifying an existing configuration. Called by all initialize-* skills; also invoke directly when a user requests `.iconrc` creation or reconfiguration.
user-invocable: true
---

# Create `.context/iconrc.json`

## Overview

This skill is the **sole owner** of `.context/iconrc.json`. All other skills that need this file call `create-iconrc` — they do not write it directly.

## Inputs

| Parameter | Required | Placeholder |
|-----------|----------|-------------|
| `repo_type` | **yes** | — |
| `local_task_id_prefix` | no | `LOCAL` |
| `forbidden_prefixes` | no | `[]` |
| `default_branch` | no | `main` |
| `cache_expires_after_days` | no | `30` |
| `excludes` | no | `[]` |

`repo_type` accepts: `project | monorepo | multi-module | workspace`.

If invoked directly by a user without `repo_type`, prompt for it before proceeding.

## Canonical Schema

> **Version source**: Always read `"version"` from `$TEMPLATE_DIR/context/iconrc.json` (where `$TEMPLATE_DIR` is set by the `find-context-template` skill — see Pre-requisite below). Do **not** hardcode the version string here — the canonical template is the single source of truth.

```json
{
  "version": "<read from $TEMPLATE_DIR/context/iconrc.json>",
  "repo_type": "project | monorepo | multi-module | workspace",
  "local_task_id_prefix": "LOCAL",
  "default_branch": "main",
  "cache_expires_after_days": 30,
  "excludes": []
}
```

**Field semantics:**
- `local_task_id_prefix` — prefix for locally-originated tasks only. GitHub issue references (and any other external tracker IDs) are always used as-is and are never prefixed by this field.
  - The prefix MUST NOT match (case-insensitive) any external issue-tracker prefix the project actually uses (GitHub issue references, or any other tracker the repo references). If an agent sees a task ID it cannot tell at a glance whether to chase it in the external tracker; a colliding local prefix wastes effort or hallucinates context for an external ticket that does not exist. Callers (the `initialize-*` skills) detect those prefixes from `git log` and pass them via `forbidden_prefixes`.
  - The default placeholder is `LOCAL`. Pick a real-feeling but unambiguous local prefix per project (e.g., `INT`, `OPS`, or stay with `LOCAL`).
  - Local task IDs MUST use the format `<PREFIX>-<NNN>` with a numeric suffix at least 3 digits wide and zero-padded (`LOCAL-001`, `LOCAL-042`, `LOCAL-128`). Repos may pad wider (e.g., 4-wide as `MKT-0092`) but MUST NOT use fewer than 3 digits or unpadded numerics.
- `forbidden_prefixes` — caller-supplied list of ticket prefixes (typically detected from `git log`) that `local_task_id_prefix` must not collide with. Compared case-insensitively. Used at validation time; not persisted in `.context/iconrc.json`.
- `excludes` — folder names relative to `.context/`; skills that sync from `context_template` skip these folders. Only active on re-runs — a fresh init has no `.iconrc` yet, so excludes cannot be applied.
- `branch_pattern` — deliberately absent. Branch detection is handled in other skills; do not add it back.

---

## create-iconrc: Pre-requisite: ensure `$TEMPLATE_DIR` is set

This skill reads the canonical version from the context template, located via `$TEMPLATE_DIR`. If `$TEMPLATE_DIR` is not already set in your session (callers like `context-specialist-impl-leaf` and `context-specialist-impl-root` set it before invoking this skill), invoke the `find-context-template` skill first:

```bash
[ -z "$TEMPLATE_DIR" ] && echo "Run find-context-template before continuing — \$TEMPLATE_DIR is not set" && exit 1
```

(Or in a shell session: simply load `find-context-template/SKILL.md`, run its Discovery Command for the active tool, then return here.)

---

## create-iconrc: Step 1: Detect existing file

```bash
[ -f ".context/iconrc.json" ] && ACTION="update" || ACTION="create"
```

---

## create-iconrc: Step 2: Create or update

### create-iconrc: Step 2 (create path): Write fresh file

Write `.context/iconrc.json` with the full canonical schema. Use provided values; fall back to placeholders for omitted optional fields:

```python
import json, os

# Read the canonical version from the context template — do not hardcode this
# value. The canonical template is the single source of truth.
template_dir = os.environ.get("TEMPLATE_DIR")
if not template_dir:
    raise RuntimeError(
        "TEMPLATE_DIR is not set; run find-context-template before create-iconrc"
    )
TEMPLATE_ICONRC = os.path.join(template_dir, "context", "iconrc.json")
with open(TEMPLATE_ICONRC) as _tf:
    _template_version = json.load(_tf)["version"]

os.makedirs(".context", exist_ok=True)

# Validate local_task_id_prefix does not collide with any project ticket prefix.
# `forbidden_prefixes` is supplied by the caller (typically detected from git log
# in context-specialist-impl-leaf Step 1a / impl-root). Compare case-insensitively.
_resolved_prefix = str(local_task_id_prefix or "LOCAL")
_forbidden = [str(p).upper() for p in (forbidden_prefixes or [])]
if _resolved_prefix.upper() in _forbidden:
    raise ValueError(
        f"local_task_id_prefix={_resolved_prefix!r} collides with a project "
        f"ticket prefix in forbidden_prefixes={sorted(set(_forbidden))}. "
        f"Pick a distinct prefix (default placeholder: 'LOCAL') and re-invoke."
    )

config = {
    "version": _template_version,
    "repo_type": repo_type,                               # required
    "local_task_id_prefix": _resolved_prefix,
    "default_branch": default_branch or "main",
    "cache_expires_after_days": cache_expires_after_days or 30,
    "excludes": excludes or [],
}

with open(".context/iconrc.json", "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
```

### create-iconrc: Step 2 (update path): Merge into existing file

Read the current file, preserve all existing fields, and apply only the fields **explicitly provided** by the caller:

```python
import json

with open(".context/iconrc.json") as f:
    config = json.load(f)

# Build overrides from only the fields that were explicitly passed
overrides = {k: v for k, v in {
    "repo_type": repo_type,
    "local_task_id_prefix": local_task_id_prefix,
    "default_branch": default_branch,
    "cache_expires_after_days": cache_expires_after_days,
    "excludes": excludes,
}.items() if v is not None}

# Validate prefix collision ONLY when the caller is explicitly setting
# local_task_id_prefix on this update — a no-op update that doesn't touch the
# field must not error on a pre-existing value.
if "local_task_id_prefix" in overrides:
    _forbidden = [str(p).upper() for p in (forbidden_prefixes or [])]
    _new_prefix = str(overrides["local_task_id_prefix"])
    if _new_prefix.upper() in _forbidden:
        raise ValueError(
            f"local_task_id_prefix={_new_prefix!r} collides with a project "
            f"ticket prefix in forbidden_prefixes={sorted(set(_forbidden))}. "
            f"Pick a distinct prefix (default placeholder: 'LOCAL') and re-invoke."
        )

config.update(overrides)

with open(".context/iconrc.json", "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
```

---

## create-iconrc: Step 3: Commit

Follow the project's commit conventions from `.context/workflows/commit-conventions.md` if it exists:

```bash
git add .context/iconrc.json
git commit -m "chore: create .context/iconrc.json"   # create path
git commit -m "chore: update .context/iconrc.json"   # update path
```

---

## Called By

| Caller | `repo_type` passed |
|--------|-------------------|
| `initialize-repo` | `project` |
| `initialize-monorepo` | `monorepo` (at repo root) |
| `initialize-workspace` | `workspace` (at workspace root) |
| `initialize-multimodule` | `multi-module` (at repo root) |
| User directly | prompt if not provided |

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Writing `.iconrc` from another skill | Only `create-iconrc` writes this file. Call this skill instead. |
| Resetting omitted fields on update | Merge into the existing object — only update explicitly provided fields. |
| Adding `branch_pattern` | This field is removed by design. Do not add it back. |
| Skipping the commit | Always commit after creating or updating the file. |
| Applying `excludes` during fresh init | `excludes` only applies on re-runs. A fresh init has no `.iconrc` to read from. |
| Choosing a prefix that matches a real external issue-tracker key (e.g., a GitHub issue reference convention) | Inspect `git log` for ticket prefixes; pick a distinct local prefix (default `LOCAL`). |
| Using fewer than 3 digits or unpadded numerics in task IDs | Format is `<PREFIX>-<NNN>` minimum, leading zeros (e.g., `LOCAL-001`, `LOCAL-042`). |
