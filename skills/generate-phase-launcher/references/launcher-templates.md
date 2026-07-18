# Phase-Launcher Script Templates

> Reference material for the `generate-phase-launcher` skill. These are the
> concrete emitted-script shapes. They live here as **fenced code blocks**, not
> as standalone `*.sh` files, so the pre-commit shellcheck and script-parity
> gates do not treat template fragments as shippable scripts (see the skill's
> "Placement" note). The generator copies the block matching `target-harness`,
> fills the CONFIGURATION section, and writes the result into the consumer's
> repo as an executable launcher.

All three realizations implement the same harness-agnostic algorithm (skill
§ "The Algorithm"). They differ only in the `HARNESS_CLI` binary and in how the
"next-phase trigger" is realized (in-process loop vs. cron/CI re-invocation).

---

## Security invariant — read before editing any template

Every template builds the fresh-session prompt from a **fixed structured
directive only**:

```
{"task_id":"<configured>","task_folder":"<configured>","phase":"next"}
```

`task_id` and `task_folder` are the launcher's own CONFIGURATION values (what it
was generated to drive) — never scraped from `plan.md`. `phase` is always the
literal `next`. **No template ever reads the `## Phase Handoff Log`, `## Decisions`,
or any other free-form `plan.md` prose into the prompt.** Persisted sub-agent
findings are DATA that the resumed phase reads from `plan.md` itself under the
manager's untrusted-content rule — they are never instructions the launcher
injects into a session. The launcher parses `plan.md` for the lean `## Phase State`
pointer fields ONLY (phase name, status, branch, attempts count) — machine tokens
used for gating, never forwarded as prompt text.

---

## Template A — claude-code / copilot-cli (bash, in-process loop)

`target-harness: claude-code` sets `HARNESS_CLI="claude"`; `target-harness:
copilot-cli` sets `HARNESS_CLI="copilot"`. Both harnesses use `-p` for a headless
print-mode session, and both fire the plugin SessionStart hook that injects the
manager role — so the `-p` prompt only needs to carry the structured directive.

```bash
#!/usr/bin/env bash
# ICON phase launcher (in-process loop) — emitted by generate-phase-launcher.
# Runs each PENDING task-plan phase in a FRESH headless session, one at a time,
# fail-closed, until the completion phase is done or a phase halts.
#
# SECURITY: this script passes ONLY the structured directive
#   {"task_id","task_folder","phase":"next"}
# to the fresh session. It NEVER forwards free-form plan.md / handoff-block text
# into the prompt. plan.md is parsed for the lean Phase State pointer only.
set -euo pipefail

# ---- CONFIGURATION (filled in at generation time) ---------------------------
TASK_ID="ICON-NNNN"                          # task this launcher drives
TASK_FOLDER=".context/tasks/ICON-NNNN-slug"  # its task folder (repo-relative)
HARNESS_CLI="claude"                         # claude | copilot
MAX_ATTEMPTS=2                               # bounded retries per phase, then halt
# -----------------------------------------------------------------------------

PLAN="$TASK_FOLDER/plan.md"

# Emit only the lines inside the "## Phase State" section of plan.md.
phase_state() { awk '/^## Phase State/{f=1;next} /^## /{f=0} f' "$PLAN"; }

# Read one bold Phase State field value, e.g. field Current -> "implementation ...".
field() {
  phase_state | sed -n "s/^- \*\*$1\*\*:[[:space:]]*//p" | head -n1
}

# Phase-Handoff trailer on HEAD (empty string if none), whitespace-stripped.
head_handoff() {
  git log -1 --format='%(trailers:key=Phase-Handoff,valueonly=true)' | tr -d '[:space:]'
}

fail_count=0
while true; do
  [[ -f "$PLAN" ]] || { echo "[launcher] plan.md not found at $PLAN" >&2; exit 2; }

  current_raw="$(field 'Current')"
  current_phase="${current_raw%%[[:space:](]*}"
  current_status="$(printf '%s' "$current_raw" | sed -n 's/.*(status:[[:space:]]*\([a-z-]*\).*/\1/p')"
  next_phase="$(field 'Next')"
  branch="$(field 'Branch')"
  attempts_raw="$(field 'Attempts (current phase)')"; attempts="${attempts_raw//[^0-9]/}"; attempts="${attempts:-0}"
  completed_raw="$(field 'Completed')"
  last_completed="$(printf '%s' "$completed_raw" | awk -F', *' '{gsub(/^ +| +$/,"",$NF); print $NF}')"

  # 1/2. TERMINATION — completion done, or no pending phase remains.
  if [[ "$current_phase" == "completion" && "$current_status" == "done" ]] \
     || { [[ "$current_status" == "done" && -z "$next_phase" ]]; }; then
    echo "[launcher] $TASK_ID complete — no pending phase remains."
    exit 0
  fi

  # 3. FAILURE GATE — blocked, or persisted Attempts already at the cap. No advance.
  if [[ "$current_status" == "blocked" ]]; then
    echo "[launcher] phase '$current_phase' is BLOCKED — halting, no advance." >&2
    exit 3
  fi
  # NOTE: in this in-process loop the OPERATIVE retry bound is the in-process
  # fail_count below; this persisted-Attempts gate is a secondary guard that
  # catches a stale high Attempts left by a prior crashed run. (The single-shot
  # Template C has no in-process counter — there the launcher's pre-launch
  # Attempts increment is the real bound.)
  if (( attempts >= MAX_ATTEMPTS )); then
    echo "[launcher] phase '$current_phase' already at Attempts=$attempts (max $MAX_ATTEMPTS) — halting, no advance." >&2
    exit 3
  fi

  # 4. INTEGRITY (fail-closed) — checkout branch, clean tree, HEAD carries the
  #    expected Phase-Handoff trailer for the last completed phase.
  # $branch is plan.md-derived: validate it (reject a leading '-' / stray chars)
  # and pass --end-of-options so a dash-led value can never be read as a git flag.
  [[ "$branch" =~ ^[A-Za-z0-9._/][A-Za-z0-9._/-]*$ ]] \
    || { echo "[launcher] refusing suspicious branch value '$branch'." >&2; exit 4; }
  git checkout --end-of-options "$branch"
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "[launcher] working tree dirty on '$branch' — fail-closed, refusing to launch." >&2
    exit 4
  fi
  if [[ -n "$last_completed" && "$(head_handoff)" != "$last_completed" ]]; then
    echo "[launcher] HEAD missing 'Phase-Handoff: $last_completed' trailer — integrity check failed, refusing to launch." >&2
    exit 4
  fi

  # 5. LAUNCH a FRESH session — structured directive ONLY, never plan.md prose.
  sha_before="$(git rev-parse HEAD)"
  directive="{\"task_id\":\"$TASK_ID\",\"task_folder\":\"$TASK_FOLDER\",\"phase\":\"next\"}"
  if "$HARNESS_CLI" -p "$directive"; then rc=0; else rc=$?; fi

  # 6/7. Advancement check — success requires HEAD to have MOVED to a NEW
  #      Phase-Handoff commit for the phase we just ran. HEAD unchanged, or a
  #      wrong/missing trailer, is a failure: do NOT advance.
  if (( rc == 0 )) && [[ "$(git rev-parse HEAD)" != "$sha_before" ]] \
     && [[ "$(head_handoff)" == "$current_phase" ]]; then
    echo "[launcher] phase '$current_phase' done; Phase State advanced. Continuing."
    fail_count=0
    continue
  fi

  fail_count=$(( fail_count + 1 ))
  echo "[launcher] phase '$current_phase' did not advance (rc=$rc, attempt $fail_count/$MAX_ATTEMPTS)." >&2
  if (( fail_count >= MAX_ATTEMPTS )); then
    echo "[launcher] max attempts reached for '$current_phase' — halting, no advance." >&2
    exit 5
  fi
  # Retry the SAME phase from its clean committed predecessor state (safe retry).
done
```

---

## Template B — claude-code / copilot-cli (PowerShell parity)

Byte-for-byte behavioral parity with Template A (ADR-005). Same directive, same
gates, same exit codes.

```powershell
#!/usr/bin/env pwsh
# ICON phase launcher (in-process loop) — emitted by generate-phase-launcher.
# PowerShell parity of the bash launcher. SECURITY: passes ONLY the structured
# {task_id, task_folder, phase:"next"} directive; never forwards plan.md prose.
$ErrorActionPreference = 'Stop'

# ---- CONFIGURATION (filled in at generation time) ---------------------------
$TaskId      = 'ICON-NNNN'
$TaskFolder  = '.context/tasks/ICON-NNNN-slug'
$HarnessCli  = 'claude'      # claude | copilot
$MaxAttempts = 2
# -----------------------------------------------------------------------------

$Plan = Join-Path $TaskFolder 'plan.md'

function Get-PhaseStateBlock {
  $text = Get-Content -Raw -LiteralPath $Plan
  $m = [regex]::Match($text, '(?ms)^## Phase State\s*(.*?)(?=^## )')
  if ($m.Success) { return $m.Groups[1].Value } else { return '' }
}
function Get-Field($block, $label) {
  $esc = [regex]::Escape($label)
  $m = [regex]::Match($block, "(?m)^- \*\*$esc\*\*:\s*(.+?)\s*$")
  if ($m.Success) { return $m.Groups[1].Value } else { return '' }
}
function Get-HeadHandoff {
  (git log -1 --format='%(trailers:key=Phase-Handoff,valueonly=true)').Trim()
}

$failCount = 0
while ($true) {
  if (-not (Test-Path -LiteralPath $Plan)) { Write-Error "[launcher] plan.md not found at $Plan"; exit 2 }

  $ps            = Get-PhaseStateBlock
  $currentRaw    = Get-Field $ps 'Current'
  $currentPhase  = ($currentRaw -split '[\s(]')[0]
  $currentStatus = ([regex]::Match($currentRaw, 'status:\s*([a-z-]+)')).Groups[1].Value
  $nextPhase     = Get-Field $ps 'Next'
  $branch        = Get-Field $ps 'Branch'
  $attempts      = 0; [void][int]::TryParse(((Get-Field $ps 'Attempts (current phase)') -replace '\D',''), [ref]$attempts)
  $completed     = Get-Field $ps 'Completed'
  $lastCompleted = if ($completed) { (($completed -split ',')[-1]).Trim() } else { '' }

  # 1/2. TERMINATION
  if (($currentPhase -eq 'completion' -and $currentStatus -eq 'done') -or
      ($currentStatus -eq 'done' -and [string]::IsNullOrWhiteSpace($nextPhase))) {
    Write-Host "[launcher] $TaskId complete — no pending phase remains."; exit 0
  }

  # 3. FAILURE GATE
  if ($currentStatus -eq 'blocked') {
    Write-Error "[launcher] phase '$currentPhase' is BLOCKED — halting, no advance."; exit 3
  }
  # NOTE: the OPERATIVE retry bound here is the in-process $failCount below; this
  # persisted-Attempts gate is a secondary guard for a stale high Attempts left by
  # a prior crashed run. (Single-shot Template C has no in-process counter — there
  # the launcher's pre-launch Attempts increment is the real bound.)
  if ($attempts -ge $MaxAttempts) {
    Write-Error "[launcher] phase '$currentPhase' already at Attempts=$attempts (max $MaxAttempts) — halting, no advance."; exit 3
  }

  # 4. INTEGRITY (fail-closed). $branch is plan.md-derived: validate (reject a
  #    leading '-' / stray chars) and pass --end-of-options so it can't be a flag.
  if ($branch -notmatch '^[A-Za-z0-9._/][A-Za-z0-9._/-]*$') {
    Write-Error "[launcher] refusing suspicious branch value '$branch'."; exit 4
  }
  git checkout --end-of-options $branch
  if (git status --porcelain) {
    Write-Error "[launcher] working tree dirty on '$branch' — fail-closed, refusing to launch."; exit 4
  }
  if ($lastCompleted -and (Get-HeadHandoff) -ne $lastCompleted) {
    Write-Error "[launcher] HEAD missing 'Phase-Handoff: $lastCompleted' trailer — integrity check failed, refusing to launch."; exit 4
  }

  # 5. LAUNCH — structured directive ONLY.
  $shaBefore = (git rev-parse HEAD).Trim()
  $directive = "{`"task_id`":`"$TaskId`",`"task_folder`":`"$TaskFolder`",`"phase`":`"next`"}"
  & $HarnessCli -p $directive
  $rc = $LASTEXITCODE

  # 6/7. Advancement check — HEAD must have MOVED to a NEW Phase-Handoff commit
  #      for the phase just run; HEAD unchanged or a wrong trailer is a failure.
  if ($rc -eq 0 -and (git rev-parse HEAD).Trim() -ne $shaBefore -and (Get-HeadHandoff) -eq $currentPhase) {
    Write-Host "[launcher] phase '$currentPhase' done; Phase State advanced. Continuing."
    $failCount = 0; continue
  }

  $failCount++
  Write-Error "[launcher] phase '$currentPhase' did not advance (rc=$rc, attempt $failCount/$MaxAttempts)."
  if ($failCount -ge $MaxAttempts) {
    Write-Error "[launcher] max attempts reached for '$currentPhase' — halting, no advance."; exit 5
  }
}
```

---

## Template C — generic (cron / CI, single-shot)

`target-harness: generic` emits a **single-shot** runner: it evaluates the gates,
runs **at most one** phase, and exits. The loop is external — cron re-invokes on
a schedule, or a CI pipeline runs one job per phase. This is the fail-closed,
no-auto-advance model the design calls for: a non-zero exit halts downstream CI
jobs. But a **bare cron entry re-invokes on every tick regardless of exit code**,
so the bounded-retry guarantee cannot rely on the launched session (a fail-closed
session commits nothing). This single-shot runner therefore **OWNS the `Attempts`
bound**: it increments and commits `Attempts` in Phase State BEFORE each launch,
so a persistently failing phase trips the `Attempts ≥ MAX_ATTEMPTS` gate and
halts even under bare cron. A successful phase exit resets `Attempts` to `0` for
the next phase (see `base.md` Section Guidance).

### C1 — single-shot bash

```bash
#!/usr/bin/env bash
# ICON phase launcher (single-shot) — emitted by generate-phase-launcher.
# Runs AT MOST ONE pending phase, then exits. Intended for cron / CI, which owns
# the loop. SECURITY: structured directive ONLY; never forwards plan.md prose.
set -euo pipefail

TASK_ID="ICON-NNNN"
TASK_FOLDER=".context/tasks/ICON-NNNN-slug"
HARNESS_CLI="claude"     # any configured harness CLI (claude | copilot | ...)
MAX_ATTEMPTS=2
PLAN="$TASK_FOLDER/plan.md"

phase_state() { awk '/^## Phase State/{f=1;next} /^## /{f=0} f' "$PLAN"; }
field() { phase_state | sed -n "s/^- \*\*$1\*\*:[[:space:]]*//p" | head -n1; }
head_handoff() { git log -1 --format='%(trailers:key=Phase-Handoff,valueonly=true)' | tr -d '[:space:]'; }

[[ -f "$PLAN" ]] || { echo "[launcher] plan.md not found at $PLAN" >&2; exit 2; }

current_raw="$(field 'Current')"
current_phase="${current_raw%%[[:space:](]*}"
current_status="$(printf '%s' "$current_raw" | sed -n 's/.*(status:[[:space:]]*\([a-z-]*\).*/\1/p')"
next_phase="$(field 'Next')"
branch="$(field 'Branch')"
attempts_raw="$(field 'Attempts (current phase)')"; attempts="${attempts_raw//[^0-9]/}"; attempts="${attempts:-0}"
completed_raw="$(field 'Completed')"
last_completed="$(printf '%s' "$completed_raw" | awk -F', *' '{gsub(/^ +| +$/,"",$NF); print $NF}')"

# TERMINATION
if [[ "$current_phase" == "completion" && "$current_status" == "done" ]] \
   || { [[ "$current_status" == "done" && -z "$next_phase" ]]; }; then
  echo "[launcher] $TASK_ID complete — no pending phase remains."; exit 0
fi
# FAILURE GATE — persisted Attempts is the ONLY retry bound in this single-shot
# model: cron/CI re-invokes a fresh process each tick (no in-process counter), and
# a bare cron entry re-runs regardless of exit code. This launcher OWNS the
# increment — it bumps + commits Attempts BEFORE launching (below), so even a
# fail-closed session that commits nothing still advances the counter and this
# gate eventually fires.
[[ "$current_status" == "blocked" ]] && { echo "[launcher] '$current_phase' BLOCKED — halt, no advance." >&2; exit 3; }
(( attempts >= MAX_ATTEMPTS )) && { echo "[launcher] '$current_phase' at Attempts=$attempts (max $MAX_ATTEMPTS) — halt." >&2; exit 3; }
# INTEGRITY (fail-closed). $branch is plan.md-derived: validate (reject leading
# '-' / stray chars) and pass --end-of-options so it can't be read as a git flag.
[[ "$branch" =~ ^[A-Za-z0-9._/][A-Za-z0-9._/-]*$ ]] || { echo "[launcher] refusing suspicious branch value '$branch'." >&2; exit 4; }
git checkout --end-of-options "$branch"
[[ -n "$(git status --porcelain)" ]] && { echo "[launcher] dirty tree on '$branch' — fail-closed." >&2; exit 4; }
if [[ -n "$last_completed" && "$(head_handoff)" != "$last_completed" ]]; then
  echo "[launcher] HEAD missing 'Phase-Handoff: $last_completed' trailer — fail-closed." >&2; exit 4
fi
# PRE-LAUNCH ATTEMPT BUMP — persist attempts+1 into Phase State and commit it, so
# the bounded-retry gate above grows across cron re-invocations even when the
# launched session fails closed and commits nothing. The bump commit carries the
# last completed phase's Phase-Handoff trailer FORWARD so the fail-closed HEAD-
# trailer integrity check still holds on the next tick. A successful phase exit
# resets Attempts to 0 for the next phase (see base.md Section Guidance).
new_attempts=$(( attempts + 1 ))
tmp="$(mktemp)"
sed "s/^\(- \*\*Attempts (current phase)\*\*:\).*/\1 $new_attempts/" "$PLAN" > "$tmp" && mv "$tmp" "$PLAN"
git add -- "$PLAN"
if [[ -n "$last_completed" ]]; then
  git commit -q -m "$TASK_ID: pre-launch attempt $new_attempts for $current_phase" -m "Phase-Handoff: $last_completed"
else
  git commit -q -m "$TASK_ID: pre-launch attempt $new_attempts for $current_phase"
fi
# LAUNCH — structured directive ONLY.
sha_before="$(git rev-parse HEAD)"
directive="{\"task_id\":\"$TASK_ID\",\"task_folder\":\"$TASK_FOLDER\",\"phase\":\"next\"}"
if "$HARNESS_CLI" -p "$directive"; then rc=0; else rc=$?; fi
# ADVANCEMENT — success requires HEAD to have MOVED to a NEW Phase-Handoff commit
# for the phase just run. Non-zero exit, HEAD unchanged, or a wrong trailer
# signals cron/CI to halt (no auto-advance).
if (( rc == 0 )) && [[ "$(git rev-parse HEAD)" != "$sha_before" ]] && [[ "$(head_handoff)" == "$current_phase" ]]; then
  echo "[launcher] phase '$current_phase' done; Phase State advanced."; exit 0
fi
echo "[launcher] phase '$current_phase' did not advance (rc=$rc) — halting, no advance." >&2
exit 5
```

### C2 — single-shot PowerShell parity

```powershell
#!/usr/bin/env pwsh
# ICON phase launcher (single-shot) — PowerShell parity of C1.
$ErrorActionPreference = 'Stop'
$TaskId='ICON-NNNN'; $TaskFolder='.context/tasks/ICON-NNNN-slug'; $HarnessCli='claude'; $MaxAttempts=2
$Plan = Join-Path $TaskFolder 'plan.md'
function Get-PS { $t=Get-Content -Raw -LiteralPath $Plan; ([regex]::Match($t,'(?ms)^## Phase State\s*(.*?)(?=^## )')).Groups[1].Value }
function Get-F($b,$l){ $e=[regex]::Escape($l); $m=[regex]::Match($b,"(?m)^- \*\*$e\*\*:\s*(.+?)\s*$"); if($m.Success){$m.Groups[1].Value}else{''} }
function Get-HH { (git log -1 --format='%(trailers:key=Phase-Handoff,valueonly=true)').Trim() }

if (-not (Test-Path -LiteralPath $Plan)) { Write-Error "[launcher] plan.md not found at $Plan"; exit 2 }
$ps=Get-PS
$currentRaw=Get-F $ps 'Current'; $currentPhase=($currentRaw -split '[\s(]')[0]
$currentStatus=([regex]::Match($currentRaw,'status:\s*([a-z-]+)')).Groups[1].Value
$nextPhase=Get-F $ps 'Next'; $branch=Get-F $ps 'Branch'
$attempts=0; [void][int]::TryParse(((Get-F $ps 'Attempts (current phase)') -replace '\D',''), [ref]$attempts)
$completed=Get-F $ps 'Completed'; $lastCompleted= if($completed){(($completed -split ',')[-1]).Trim()}else{''}

if (($currentPhase -eq 'completion' -and $currentStatus -eq 'done') -or ($currentStatus -eq 'done' -and [string]::IsNullOrWhiteSpace($nextPhase))) {
  Write-Host "[launcher] $TaskId complete — no pending phase remains."; exit 0 }
# FAILURE GATE — persisted Attempts is the ONLY retry bound in this single-shot
# model. This launcher OWNS the increment: it bumps + commits Attempts BEFORE
# launching, so a fail-closed session that commits nothing still advances it.
if ($currentStatus -eq 'blocked') { Write-Error "[launcher] '$currentPhase' BLOCKED — halt."; exit 3 }
if ($attempts -ge $MaxAttempts) { Write-Error "[launcher] '$currentPhase' at Attempts=$attempts (max $MaxAttempts) — halt."; exit 3 }
# INTEGRITY (fail-closed). $branch is plan.md-derived: validate + --end-of-options.
if ($branch -notmatch '^[A-Za-z0-9._/][A-Za-z0-9._/-]*$') { Write-Error "[launcher] refusing suspicious branch value '$branch'."; exit 4 }
git checkout --end-of-options $branch
if (git status --porcelain) { Write-Error "[launcher] dirty tree on '$branch' — fail-closed."; exit 4 }
if ($lastCompleted -and (Get-HH) -ne $lastCompleted) { Write-Error "[launcher] HEAD missing 'Phase-Handoff: $lastCompleted' — fail-closed."; exit 4 }
# PRE-LAUNCH ATTEMPT BUMP — persist attempts+1 and commit it so the bounded-retry
# gate grows across cron re-invocations; carry the last handoff's trailer forward
# so the HEAD-trailer integrity check still holds next tick. Successful exit
# resets Attempts to 0 (see base.md Section Guidance).
$newAttempts = $attempts + 1
(Get-Content -Raw -LiteralPath $Plan) -replace '(?m)^(- \*\*Attempts \(current phase\)\*\*:).*', "`$1 $newAttempts" | Set-Content -NoNewline -LiteralPath $Plan
git add -- $Plan
if ($lastCompleted) { git commit -q -m "${TaskId}: pre-launch attempt $newAttempts for $currentPhase" -m "Phase-Handoff: $lastCompleted" }
else { git commit -q -m "${TaskId}: pre-launch attempt $newAttempts for $currentPhase" }
$shaBefore = (git rev-parse HEAD).Trim()
$directive = "{`"task_id`":`"$TaskId`",`"task_folder`":`"$TaskFolder`",`"phase`":`"next`"}"
& $HarnessCli -p $directive
$rc = $LASTEXITCODE
if ($rc -eq 0 -and (git rev-parse HEAD).Trim() -ne $shaBefore -and (Get-HH) -eq $currentPhase) { Write-Host "[launcher] phase '$currentPhase' done; advanced."; exit 0 }
Write-Error "[launcher] phase '$currentPhase' did not advance (rc=$rc) — halting, no advance."; exit 5
```

### C3 — CI job-per-phase (GitHub Actions sketch)

Each phase is one job; `needs:` edges make a failed job halt every downstream
phase — fail-closed and no-auto-advance-on-failure for free. Each job invokes the
single-shot runner (C1), which itself passes only the structured directive.

```yaml
# .github/workflows/task-phases.yml (sketch — one task, five phases)
name: task-phases
on: workflow_dispatch
jobs:
  investigation:
    runs-on: ubuntu-latest
    steps: [{ uses: actions/checkout@v4 }, { run: ./phase-launcher.sh }]
  architecture:
    needs: investigation
    runs-on: ubuntu-latest
    steps: [{ uses: actions/checkout@v4 }, { run: ./phase-launcher.sh }]
  implementation:
    needs: architecture
    runs-on: ubuntu-latest
    steps: [{ uses: actions/checkout@v4 }, { run: ./phase-launcher.sh }]
  testing:
    needs: implementation
    runs-on: ubuntu-latest
    steps: [{ uses: actions/checkout@v4 }, { run: ./phase-launcher.sh }]
  completion:
    needs: testing
    runs-on: ubuntu-latest
    steps: [{ uses: actions/checkout@v4 }, { run: ./phase-launcher.sh }]
```

---

## Exit-code contract (all templates)

| Exit | Meaning | Loop action |
|------|---------|-------------|
| 0 | Phase advanced, or task already complete | continue / stop cleanly |
| 2 | `plan.md` missing / unreadable | halt |
| 3 | Failure gate: phase `blocked` or `Attempts` ≥ max | halt, no advance |
| 4 | Integrity fail-closed: dirty tree or missing `Phase-Handoff` trailer | halt, no advance |
| 5 | Phase ran but did not advance (session failure) | halt, no advance |
