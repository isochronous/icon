---
name: icon-init
description: >
  Use when setting up ICON in a repo for the first time. Detects the repo type automatically and dispatches the correct initializer, or routes to /upgrade-repo if .context/ already exists. This is the sole user entry point for initialization.
user-invocable: true
---

# icon-init

## Overview

Single entry point for initialization. Detects your repo shape and dispatches to the correct `/initialize-*` skill, or to `/upgrade-repo` if the repo is already initialized.

`/icon-init` is the **sole user-facing entry point** for initialization — the four `/initialize-*` skills are agent-invoked only and do not appear in the slash-command menu. If auto-detection picks the wrong type, use the **override** option in Step 3 to select the correct initializer.

---

## icon-init: Step 1: Check for existing `.context/`

```bash
if [ -d .context ]; then
  echo "Repository already initialized — detected type per .context/iconrc.json."
  echo "Dispatching /upgrade-repo to bring .context/ current with the latest agent-system spec."
  echo "(To re-initialize from scratch instead, re-run with /icon-init --force.)"
fi
```

**Flag handling:** Accept a `--force` argument. If `--force` is present, skip this check and proceed to Step 2. If `.context/` already exists and `--force` was NOT passed, **invoke the `upgrade-repo` skill and halt this skill's further execution** — do not proceed to detection or dispatch in Step 2.

---

## icon-init: Step 2: Detect repo type

> Detection logic is **derived from** `skills/context-specialist-detect-tree-position/SKILL.md`, extended to distinguish `workspace` from `monorepo` and `project` from `multimodule` for per-skill dispatch. If that skill's detection signals change, update this step to match.

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
  # Check workspaces field exists and is a non-empty array
  WS_CHECK=$(python3 -c "
import json, sys
try:
    d = json.load(open('package.json'))
    ws = d.get('workspaces')
    print('yes' if ws and isinstance(ws, list) and len(ws) > 0 else 'no')
except Exception:
    print('no')
" 2>&1 | grep -v "^Traceback")
  if [ "$WS_CHECK" = "yes" ]; then
    DETECTED_TYPE="monorepo"
  fi
fi

# pom.xml with <modules> and no src/ sibling (project-as-parent pattern)
if [ -z "$DETECTED_TYPE" ] && [ -f pom.xml ]; then
  HAS_MODULES=$(grep -c '<modules>' pom.xml 2>&1 | grep -v "^grep:")
  HAS_SRC=0
  [ -d src ] && HAS_SRC=1
  if [ "$HAS_MODULES" -ge 1 ] && [ "$HAS_SRC" -eq 0 ]; then
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
# fallback: no signals matched — default to project with a warning
if [ -z "$DETECTED_TYPE" ]; then
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

After the dispatched skill returns successfully (a fresh init wrote `.context/iconrc.json`, or `/upgrade-repo` reports the repo is current), print the following hints in order. These are post-init affordances — do not block, retry, or delay completion based on them.

### icon-init: Step 5a: Next-step hint (always)

Emit a single unconditional line pointing the user at `/icon-status`:

```
Initialization complete. Run /icon-status to see where things stand.
```

### icon-init: Step 5b: MCP onboarding hint (conditional)

Suggest `/setup-mcp-servers` only when **both** `GITLAB_PERSONAL_ACCESS_TOKEN` and `JIRA_API_TOKEN` are unset. Use `${VAR+x}` presence checks (not a `${VAR:-literal}` fallback — see the **shell-portability** standard):

```bash
if [ -z "${GITLAB_PERSONAL_ACCESS_TOKEN+x}" ] && [ -z "${JIRA_API_TOKEN+x}" ]; then
  echo "Tip: run /setup-mcp-servers to configure GitLab or Atlassian MCP credentials."
fi
```

If either credential is already set, omit the tip — the user has at least one MCP server configured and does not need a fresh nudge.

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Running `/icon-init` on an already-initialized repo | The skill detects `.context/` and routes to `/upgrade-repo`. Do not stomp on existing initialization. |
| Counting a single subdirectory with a manifest as multimodule | Multimodule requires **2 or more** sibling subdirectories each containing a build manifest. One is not enough. |
| Treating `package.json` with an empty `"workspaces": []` as a monorepo | Check that the `workspaces` field is a non-empty array. An empty array is not a monorepo signal. |
| Dispatching before user confirms | Step 3 requires an explicit user response of "yes" or "override". Never dispatch speculatively. |
| Using `>/dev/null` for stderr suppression in bash blocks | Use `2>&1 | grep -v "^pattern"` instead. Output suppression is banned by the "Shell command self-check" rule in `shared/common-constraints.md`. |
