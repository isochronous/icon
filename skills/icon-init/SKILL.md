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

**Keep the finding.** Step 2's detector is Node-backed, and its precondition reuses this result
rather than running `node -v` a second time — so this step is a report here and a precondition
there.

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

Detection is **script-backed** — run the detector described in **Tooling: detect-repo-type**
below rather than hand-probing the repo. It prints one token on stdout; carry that token into
Step 3. Everything the detector decides, and what each answer means, is stated here so the
procedure is legible without opening the script.

### icon-init: Step 2 signals: what each type keys on

The detector applies these checks **in order and stops at the first match**. Precedence is
load-bearing: a repo can satisfy several rows at once (a workspace file next to a `package.json`,
a `pom.xml` beside subdirectories that each carry a manifest), and the first row that matches wins.

| Order | Type | Signals at the repo root |
|---|---|---|
| 1 | `workspace` | Any `*.code-workspace` file. |
| 2 | `monorepo` | `nx.json`, `turbo.json`, or `go.work`; **or** any `*.sln`; **or** a `package.json` whose `workspaces` field is a **non-empty array**; **or** a `pom.xml` that declares `<modules>` **and** has no `src/` sibling (the project-as-parent pattern). |
| 3 | `project` | Any of `package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `requirements.txt`, `Gemfile`, `build.gradle`; **or** any `*.csproj`; **or** a `pom.xml` **with** a `src/` sibling (a leaf pom, as distinct from the parent pom in the row above). |
| 4 | `multimodule` | No root manifest, but **2 or more** immediate subdirectories each contain a build manifest (the row-3 list plus `pom.xml`) or a `*.csproj`. One is not enough. |
| 5 | `project` (fallback) | Nothing above matched. Reported as a default, not as a detection. |

**`undetermined` is not a fifth shape — it is the refusal to guess.** It means a probe *failed*, and
the detector reports it from four places: the repo root could not be listed at all; a `package.json`
is present but could not be read or parsed; a `pom.xml` is present but could not be read; or any
other unanticipated error aborted detection. stderr names which. In every case the detector fails
closed rather than falling through — where a manifest failed, that file is the same one the next
check would key on, and where the failure is broader, no downstream check is trustworthy either.
Falling through would report a confident `project` for a repo whose shape is unknown.

---

## Tooling: detect-repo-type

`detect-repo-type.mjs` in `./scripts/` performs Step 2's detection. It takes no arguments and
probes the current working directory, so run it from the repo being initialized.

**Precondition — confirm Node is present before invoking.** Step 0 already established this;
**reuse `check-node-runtime`'s finding rather than probing a second time.** Only if that result is
not to hand, run `node -v` and **read its output, not its exit status** (`check-node-runtime`
Step 1 explains why the exit status lies in PowerShell). Either way, if Node is absent **do not run
the detector**: go to Step 3 and take the `undetermined` branch, which is also the Node-absent
degradation path. Do not attempt to hand-probe the repo as a substitute.

### Claude Code

```
node "${CLAUDE_SKILL_DIR}/scripts/detect-repo-type.mjs"
```

### Copilot CLI (Bash)

```bash
# Override via MARKETPLACE_NAME=<your-marketplace-slug>, or edit this line in forks.
[ -n "${MARKETPLACE_NAME+x}" ] || MARKETPLACE_NAME="icon-marketplace"
SKILL_DIR="${COPILOT_HOME:-$HOME/.copilot}/installed-plugins/${MARKETPLACE_NAME}/ICON/skills/icon-init"
node "$SKILL_DIR/scripts/detect-repo-type.mjs"
```

### Outcomes

**stdout carries exactly one token and nothing else. stderr carries warnings and probe-failure
reasons. Never merge the two** — folding a diagnostic into the value channel is what made the
previous inline `workspaces` probe fail open.

| stdout token | Exit | Meaning |
|---|---|---|
| `workspace` | 0 | Row 1 matched. |
| `monorepo` | 0 | Row 2 matched. |
| `project` | 0 | Row 3 matched, **or** row 5 — the fallback. stderr says which. |
| `multimodule` | 0 | Row 4 matched. |
| `undetermined` | 2 | A probe failed. No type was detected; stderr names the probe and the reason. |

The token and the exit code agree by design. If they ever disagree, or the token is anything other
than the five above, treat the run as `undetermined`.

---

## icon-init: Step 3: Report detected type and confirm with user

Output the detected type and the skill that will be dispatched:

```
Detected repo type: [workspace | monorepo | multimodule | project]
Skill to invoke: /initialize-[workspace | monorepo | multimodule | repo]

Proceed? (yes / override / cancel)
```

**If the detected type is `undetermined`**, there is no detected type to report. Do not print a
"Skill to invoke" line and do not offer `yes` — say why detection could not conclude and go straight
to the **override** list below. An explicit user choice is the only way forward.

**This branch is also the Node-absent degradation path.** If Step 2's precondition found no `node`
on PATH, the detector never ran, so there is no token at all — take this same branch, say that Node
is missing (and that `check-node-runtime` Step 5 guides installing it) rather than that a probe
failed, and present the override list. Initialization still completes on a user's explicit choice;
only automatic detection is lost.

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
  Wait for the user's selection. The chosen value replaces the detected type; proceed to Step 4.

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
| Using `>/dev/null` for stderr suppression in bash blocks | Use `2>&1 | grep -v "^pattern"` instead. Output suppression is banned by the "Shell command self-check" rule in `shared/common-constraints.md`. **Never apply it to a `$(…)` capture whose value is branched on** — folding a diagnostic into a value channel is what made the `workspaces` probe that Step 2 once inlined fail open. Leave stderr on stderr and treat an empty capture as "probe failed". |
