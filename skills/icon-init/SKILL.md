---
name: icon-init
description: >
  Use when setting up ICON in a repo for the first time. Detects the repo type automatically and dispatches the correct initializer, or routes to /upgrade-repo if .context/ already exists. This is the sole user entry point for initialization.
user-invocable: true
---

# icon-init

## Overview

Single entry point for initialization. Detects your repo shape and dispatches to the correct `/initialize-*` skill, or to `/upgrade-repo` if already initialized.

`/icon-init` is the **sole user-facing entry point** — the four `/initialize-*` skills are agent-invoked only and never appear in the slash-command menu. If auto-detection picks the wrong type, use the **override** option in Step 3.

---

## icon-init: Step 0: Node runtime pre-flight

Before anything else, **invoke the `check-node-runtime` skill** and report its result.

Initialization itself does not need Node — but ICON's session-start hook does, and that hook is
what injects the manager role. If `node` is not on PATH the hook never executes and cannot report
its own absence, so a fresh setup would otherwise complete looking healthy and only misbehave
later. Surfacing it here puts the problem in front of the user before it causes one.

**This is a report, not a gate.** Whatever `check-node-runtime` finds, continue to Step 1.

---

## icon-init: Step 1: Check for existing `.context/`

```bash
if [ -d .context ]; then
  echo "Repository already initialized — detected type per .context/iconrc.json."
  echo "Dispatching /upgrade-repo to bring .context/ current with the latest agent-system spec."
  echo "(To re-initialize from scratch instead, re-run with /icon-init --force.)"
fi
```

**Flag handling:** Accept a `--force` argument. If present, skip this check and proceed to Step 2. If `.context/` already exists and `--force` was NOT passed, **invoke the `upgrade-repo` skill and halt** — do not proceed to detection or dispatch in Step 2.

---

## icon-init: Step 2: Detect repo type

> Detection logic is **derived from** `skills/context-specialist-detect-tree-position/SKILL.md`, extended to distinguish `workspace` from `monorepo` and `project` from `multimodule` for per-skill dispatch. If that skill's signals change, update this step to match.

Run the following checks **in order**. Stop at the first match.

### icon-init: Step 2a: Workspace check

```bash
# workspace: a *.code-workspace file exists at CWD
WS_FILE=$(find . -maxdepth 1 -name '*.code-workspace' -type f | head -1)
if [ -n "$WS_FILE" ]; then
  DETECTED_TYPE="workspace"
fi
```

### icon-init: Step 2b: Monorepo check

```bash
# monorepo: explicit multi-project orchestration signals at CWD
if [ -z "$DETECTED_TYPE" ]; then

if [ -f nx.json ] || [ -f turbo.json ] || [ -f go.work ]; then
  DETECTED_TYPE="monorepo"
fi

# .sln file at CWD
if [ -z "$DETECTED_TYPE" ]; then
  SLN_FILE=$(find . -maxdepth 1 -name '*.sln' -type f | head -1)
  if [ -n "$SLN_FILE" ]; then
    DETECTED_TYPE="monorepo"
  fi
fi

# package.json with a non-empty "workspaces" array
if [ -z "$DETECTED_TYPE" ] && [ -f package.json ]; then
  # Three-valued on purpose: "yes", "no", or "" when the probe itself failed.
  # stderr is NOT merged into the capture — a parse error must stay a parse error
  # and must not read back as "no".
  WS_CHECK=$(node -e '
const fs = require("fs");
const ws = JSON.parse(fs.readFileSync("package.json", "utf8")).workspaces;
process.stdout.write(Array.isArray(ws) && ws.length > 0 ? "yes" : "no");
')
  if [ "$WS_CHECK" = "yes" ]; then
    DETECTED_TYPE="monorepo"
  elif [ "$WS_CHECK" != "no" ]; then
    # Fail closed. package.json exists but could not be read, which is exactly the
    # precondition of Step 2c's first manifest — falling through would report a
    # confident "project" for a repo whose shape is unknown.
    echo "ERROR: package.json is present but could not be probed (diagnostic above, on stderr)." >&2
    DETECTED_TYPE="undetermined"
  fi
fi

# pom.xml with <modules> and no src/ sibling (project-as-parent pattern)
if [ -z "$DETECTED_TYPE" ] && [ -f pom.xml ]; then
  # stderr is NOT merged into the capture, for the same reason as the probe above:
  # a read error must not read back as a count. An empty capture means the probe failed.
  HAS_MODULES=$(grep -c '<modules>' pom.xml)
  HAS_SRC=0
  [ -d src ] && HAS_SRC=1
  if [ -z "$HAS_MODULES" ]; then
    echo "ERROR: pom.xml is present but could not be probed (diagnostic above, on stderr)." >&2
    DETECTED_TYPE="undetermined"
  elif [ "$HAS_MODULES" -ge 1 ] && [ "$HAS_SRC" -eq 0 ]; then
    DETECTED_TYPE="monorepo"
  fi
fi

fi
```

### icon-init: Step 2c: Project (leaf) check

```bash
# project: a build manifest exists at CWD (single-project signals)
if [ -z "$DETECTED_TYPE" ]; then
  for MANIFEST in package.json go.mod Cargo.toml pyproject.toml requirements.txt Gemfile build.gradle; do
    if [ -f "$MANIFEST" ]; then
      DETECTED_TYPE="project"
      break
    fi
  done
fi

# Also check for *.csproj and pom.xml with src/ (leaf pom)
if [ -z "$DETECTED_TYPE" ]; then
  CSPROJ=$(find . -maxdepth 1 -name '*.csproj' -type f | head -1)
  if [ -n "$CSPROJ" ]; then
    DETECTED_TYPE="project"
  fi
fi

if [ -z "$DETECTED_TYPE" ] && [ -f pom.xml ] && [ -d src ]; then
  DETECTED_TYPE="project"
fi
```

### icon-init: Step 2d: Multimodule check

```bash
# multimodule: no root manifest, but 2+ immediate subdirs contain build manifests
if [ -z "$DETECTED_TYPE" ]; then
  MANIFEST_DIR_COUNT=0
  for SUBDIR in */; do
    [ -d "$SUBDIR" ] || continue
    FOUND=false
    for MANIFEST in package.json go.mod Cargo.toml pyproject.toml requirements.txt Gemfile build.gradle pom.xml; do
      if [ -f "${SUBDIR}${MANIFEST}" ]; then
        FOUND=true
        break
      fi
    done
    # Only check *.csproj if no standard manifest was found in this subdir
    if [ "$FOUND" = "false" ]; then
      CSPROJ_IN_SUB=$(find "${SUBDIR}" -maxdepth 1 -name '*.csproj' -type f | head -1)
      if [ -n "$CSPROJ_IN_SUB" ]; then
        FOUND=true
      fi
    fi
    if [ "$FOUND" = "true" ]; then
      MANIFEST_DIR_COUNT=$((MANIFEST_DIR_COUNT + 1))
    fi
  done
  if [ "$MANIFEST_DIR_COUNT" -ge 2 ]; then
    DETECTED_TYPE="multimodule"
  fi
fi
```

### icon-init: Step 2e: Fallback

```bash
# fallback: no signals matched, or a probe failed — never guess silently
if [ "$DETECTED_TYPE" = "undetermined" ]; then
  echo "WARNING: Repo type could not be determined — a detection probe failed."
  echo "Not defaulting to a type: the failed probe covers the same file the default would key on."
  echo "Step 3 must present the override list and wait for an explicit choice."
elif [ -z "$DETECTED_TYPE" ]; then
  DETECTED_TYPE="project"
  echo "WARNING: Repo type could not be determined from manifest signals. Defaulting to 'project'."
  echo "Review the result after initialization and re-run with a different type if needed."
fi
```

---

## icon-init: Step 3: Report detected type and confirm with user

Output the detected type and the skill that will be dispatched:

```
Detected repo type: [workspace | monorepo | multimodule | project]
Skill to invoke: /initialize-[workspace | monorepo | multimodule | repo]

Proceed? (yes / override / cancel)
```

**If `DETECTED_TYPE` is `undetermined`**, a detection probe failed and there is no detected type to
report. Do not print a "Skill to invoke" line and do not offer `yes` — say which probe failed and go
straight to the **override** list below. An explicit user choice is the only way forward.

**STOP HERE. Do not dispatch until the user responds.**

- **yes** — proceed to Step 4 with the detected skill.
- **cancel** — stop. Do not dispatch anything.
- **override** — list the four options and wait for the user to choose:
  ```
  Available options:
    1. workspace      → /initialize-workspace
    2. monorepo       → /initialize-monorepo
    3. multimodule    → /initialize-multimodule
    4. project        → /initialize-repo

  Which type should be used?
  ```
  Wait for the user's selection. Set `DETECTED_TYPE` to the chosen value and proceed to Step 4.

---

## icon-init: Step 4: Dispatch confirmed skill

Invoke the skill corresponding to the confirmed type:

| Detected type | Skill to invoke |
|---------------|-----------------|
| workspace | `/initialize-workspace` |
| monorepo | `/initialize-monorepo` |
| multimodule | `/initialize-multimodule` |
| project | `/initialize-repo` |

Load and execute the matched skill inline. Follow that skill's process from its first step.

---

## icon-init: Step 5: Post-init affordances

After the dispatched skill returns successfully (a fresh init wrote `.context/iconrc.json`, or `/upgrade-repo` reports the repo current), print the following hints in order. These are affordances — do not block, retry, or delay completion on them.

### icon-init: Step 5a: Next-step hint (always)

Emit a single unconditional line pointing the user at `/icon-status`:

```
Initialization complete. Run /icon-status to see where things stand.
```

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Running `/icon-init` on an already-initialized repo | The skill detects `.context/` and routes to `/upgrade-repo`. Do not stomp on existing initialization. |
| Counting a single subdirectory with a manifest as multimodule | Multimodule requires **2 or more** sibling subdirectories, each with a build manifest. One is not enough. |
| Treating `package.json` with an empty `"workspaces": []` as a monorepo | The `workspaces` field must be a non-empty array. An empty array is not a monorepo signal. |
| Dispatching before user confirms | Step 3 requires an explicit "yes" or "override". Never dispatch speculatively. |
| Using `>/dev/null` for stderr suppression in bash blocks | Use `2>&1 | grep -v "^pattern"` instead. Output suppression is banned by the "Shell command self-check" rule in `shared/common-constraints.md`. **Never apply it to a `$(…)` capture whose value is branched on** — folding a diagnostic into a value channel is what made Step 2b's `workspaces` probe fail open. Leave stderr on stderr and treat an empty capture as "probe failed". |
