---
name: generate-phase-launcher
description: >
  Use when a task's plan.md phases should run each in its own fresh, externally-launched session (headless / unattended / cron / CI) instead of one interactive session — i.e. when setting up automated phase-by-phase execution for an ICON task, generating a per-phase launcher script, or wiring session-per-phase cold-resume. Emits a harness-specific launcher for target-harness ∈ {claude-code, copilot-cli, generic}. Triggers include "run each phase in a fresh session", "unattended task runner", "cron the phases", "CI job per phase", "phase launcher".
user-invocable: true
---

# Generate Phase Launcher

## Overview

This skill is a **portable generator**. Given a `target-harness`, it emits a
harness-specific **per-phase launcher script** that drives one ICON task through
its `plan.md` phases — each phase in a **fresh, externally-launched session**,
with committed `plan.md` as the only cold-start carrier between runs (ICON-0082).

The ADR-004 split: **the generator (this skill) is portable instruction-content;
only the EMITTED launcher is harness-specific.** The launcher realizes the same
harness-agnostic algorithm below on top of `claude -p`, `copilot -p`, or a
cron/CI wrapper.

**This is a security-sensitive artifact.** The emitted launcher runs headless
git/shell with no human in the loop and sits on a cross-session prompt-injection
surface. The security rules in "Security — non-negotiable" are load-bearing, not
advisory. Route the emitted launcher through the ICON `security-review` skill
before it is trusted in an unattended pipeline.

**Prerequisite**: the task's `plan.md` must already carry the hardened
`## Phase State` section (ICON-0082 Phase 1). The launcher reads it; it does not
create it. Tasks whose `plan.md` predates the hardening cannot be launched until
their Phase State pointer exists.

## Inputs

**Required:**
- `target-harness` ∈ `{claude-code, copilot-cli, generic}` — the skill argument.
  Selects which template (below) is emitted.
- `task_id` and `task_folder` — the task the launcher will drive. These become
  fixed CONFIGURATION constants in the emitted script. They are the launcher's
  own identity — **never** re-derived from `plan.md` prose at runtime.

**Optional:**
- `output_path` — where to write the launcher (default: repo root, e.g.
  `phase-launcher.sh` / `phase-launcher.ps1`).
- A persisted default for `target-harness` MAY live in `.context/iconrc.json`
  under an **optional** `phase_launcher.target_harness` key. This field is
  optional and requires no `iconrc.json` schema change — if present, use it when
  the caller omits the argument; if absent, require the argument. Do not add or
  mandate the field; only honor it when a consumer has already set it.

## The Algorithm (harness-agnostic)

Every emitted launcher implements exactly this sequence. It is the contract the
per-harness templates realize — read it before editing any template.

1. **Parse** `plan.md` `## Phase State` → read the lean pointer fields
   (`Current` + its status, `Next`, `Branch`, `Completed`, `Attempts`). Determine
   the next `pending` phase.
2. **Terminate** if `completion` is `done`, or no `pending` phase remains → exit
   0, "task complete." This ends the loop.
3. **Failure gate** — if the current phase is `blocked`, OR `Attempts` ≥ max
   (default 2) → STOP, non-zero exit, alert, **do not advance.**
4. **Integrity (fail-closed)** — check out `Branch`; verify the working tree is
   clean AND `HEAD` carries the expected `Phase-Handoff: <last-completed-phase>`
   trailer. Any failure → refuse to launch, non-zero exit.
5. **Launch a FRESH session** via the manager entrypoint, passing **only** the
   structured directive `{task_id, task_folder, phase: "next"}`. `next` = "read
   Phase State and run the next pending phase" — the launcher stays dumb; the
   manager derives the phase.
6. **On success** (session exits 0 AND `HEAD` advanced to a NEW `Phase-Handoff`
   commit for the phase just run AND Phase State advanced) → trigger the next
   phase (loop again, or let cron/CI re-invoke).
7. **On failure** (non-zero exit, `HEAD` unchanged, or Phase State did NOT
   advance) → **do not advance**, surface the error, halt. Re-running a failed
   phase from its clean committed predecessor is a safe, bounded retry (see the
   `Attempts` ownership note below for what makes that bound real).

**Who owns the `Attempts` increment (this is what makes the bound real in every
mode):**

- **In-process loop (Templates A/B — `claude-code` / `copilot-cli`).** The
  operative bound is an in-process `fail_count` that increments on each failed
  iteration and halts at `MAX_ATTEMPTS` inside the one long-lived process. The
  top-of-loop persisted-`Attempts` gate is a **secondary** guard (it catches a
  stale high `Attempts` from a prior crashed run) — the in-process counter is the
  real bound.
- **Single-shot cron / CI (Template C).** There is NO in-process counter — cron
  re-invokes a fresh process each tick, and a bare cron entry re-runs regardless
  of exit code. So the **launcher owns the increment**: before launching it reads
  the persisted `Attempts`, halts if `Attempts ≥ MAX_ATTEMPTS`, otherwise
  increments `Attempts`, commits that one-line Phase State update (carrying the
  prior phase's `Phase-Handoff:` trailer forward so the fail-closed HEAD-trailer
  check still holds next tick), and only then launches. This is what makes bare
  cron genuinely bounded — the counter grows across ticks even when the launched
  session fails closed and commits nothing.
- **CI job-per-phase (Template C3).** A failed job halts every downstream job via
  the `needs:` edge — the pipeline dependency graph is the bound, independent of
  `Attempts`.
- **Reset.** A successful phase exit resets `Attempts` to `0` for the next phase
  (`base.md` Section Guidance; the `## Phase Exit / Handoff` step in each
  `phase-*.md`), so the launcher's next pre-launch increment starts a fresh count.

The per-harness realizations live in `references/launcher-templates.md`:

| `target-harness` | Emit | Fresh session | Next-phase trigger |
|------------------|------|---------------|--------------------|
| `claude-code` | Template A (bash) or B (pwsh), `HARNESS_CLI="claude"` | `claude -p "<directive>"` — fresh session; SessionStart hook injects manager role | in-process loop |
| `copilot-cli` | Template A (bash) or B (pwsh), `HARNESS_CLI="copilot"` | `copilot -p "<directive>"` | in-process loop |
| `generic` | Template C (single-shot bash + pwsh + CI sketch) | configured harness CLI, one phase per invocation | cron re-invocation, or CI job-per-phase with `needs:` |

## Security — non-negotiable

These rules define what makes the emitted launcher safe. State them explicitly in
any launcher you emit (the templates already embed them); do not weaken them.

1. **Structured directive only.** The fresh-session prompt is ALWAYS exactly
   `{"task_id":"…","task_folder":"…","phase":"next"}`, built from the launcher's
   own CONFIGURATION constants. **Never** read `## Phase Handoff Log`,
   `## Decisions`, `## Open Questions`, or any free-form `plan.md` text into the
   prompt. Persisted sub-agent findings are **DATA the resumed phase reads from
   `plan.md` itself** under the manager's untrusted-content rule — they are never
   instructions the launcher injects into a session. The launcher parses `plan.md`
   only for the lean Phase State machine tokens (phase name, status, branch,
   attempts) used to gate; those tokens are never forwarded as prompt text.
2. **Fail-closed on integrity.** A dirty working tree, a missing/ wrong
   `Phase-Handoff:` trailer, or a missing `plan.md` → refuse to launch, non-zero
   exit. Never "best-effort continue."
3. **Bounded attempts.** `Attempts`/`MAX_ATTEMPTS` caps retries so a persistently
   failing phase cannot spin forever. The increment is OWNED per mode (see "Who
   owns the `Attempts` increment"): an in-process `fail_count` bounds Templates
   A/B; the single-shot Template C launcher increments+commits `Attempts` BEFORE
   each launch so **bare cron is genuinely bounded** (not reliant on the session);
   CI `needs:` edges bound C3. A launcher whose bare-cron path never grows the
   persisted counter has NOT satisfied this rule.
4. **No auto-advance on failure.** A failed or `blocked` phase halts the loop and
   never triggers the next phase.
5. **No secrets, no extra network.** The launcher handles no credentials and
   makes no network calls beyond the single harness CLI invocation.
6. **Review before trust.** Run the ICON `security-review` skill against the
   emitted launcher before using it unattended (it is a script-class artifact
   that runs git/shell headless).

## Process

1. Resolve `target-harness` (argument, else optional `.context/iconrc.json`
   `phase_launcher.target_harness`, else ask).
2. Confirm the task's `plan.md` has a `## Phase State` section. If not, STOP and
   tell the caller to harden `plan.md` first (ICON-0082 Phase 1) — do not emit a
   launcher that would fail-closed on every run.
3. Copy the matching template from `references/launcher-templates.md`. For
   `claude-code`/`copilot-cli`, set `HARNESS_CLI` accordingly and pick bash or
   PowerShell (emit both for cross-platform parity when unsure — ADR-005).
4. Fill the CONFIGURATION block: `TASK_ID`, `TASK_FOLDER`, `HARNESS_CLI`,
   `MAX_ATTEMPTS`. Change nothing in the algorithm body.
5. Write the launcher to `output_path`; confirm the full path written.
6. Remind the caller to run `security-review` on the emitted launcher before
   unattended use.

## Common Mistakes

| Mistake | Why it's wrong | Correct |
|---------|----------------|---------|
| Passing a handoff summary or "context" string into the `-p` prompt | Opens the cross-session prompt-injection hole this design closes | Pass ONLY `{task_id, task_folder, phase:"next"}`; the phase reads plan.md itself |
| Continuing when the tree is dirty or the trailer is missing | Silently resumes from an unknown state | Fail-closed, non-zero exit, no launch |
| Auto-advancing after a non-zero session exit | Compounds a broken state across phases | Halt; increment attempts; require the safe retry / human review |
| Unbounded retry loop | A persistently failing phase spins forever headless | Bound per mode: in-process `fail_count` (A/B); the single-shot launcher increments + commits `Attempts` BEFORE each launch so bare cron is bounded even when the session commits nothing (C); CI `needs:` edges (C3) |
| Emitting a `scripts/*.sh` inside this skill | Trips shellcheck / parity gates and ships a half-configured script | Templates stay as fenced blocks in `references/`; the CONFIGURED launcher is written into the consumer repo |
| Generating for a `plan.md` with no `## Phase State` | Every run fails-closed | Require the hardened plan.md first |

## Placement (why templates are not standalone scripts)

The per-harness scripts live as **fenced code blocks** in
`references/launcher-templates.md`, NOT as `skills/generate-phase-launcher/scripts/*.sh`.
Rationale: the pre-commit shellcheck gate fires on any staged `*.sh`, and ADR-005
parity expects a byte-matched `.ps1` sibling for every real `.sh`. Template
fragments are not standalone runnable scripts (they carry `ICON-NNNN` placeholders) —
treating them as such would trip both gates on content never executed from this repo.
As reference blocks, the ONLY executable launcher is the CONFIGURED one written into
the consumer's repo, where that consumer's own review/security gates apply. If a
future need forces a real `.sh` into this skill, it MUST pass shellcheck and ship a
byte-parity `.ps1` sibling.

## Related

- `security-review` — run against every emitted launcher before unattended use.
- `task-plan` — defines the `## Phase State` / `## Phase Handoff Log` shape the
  launcher reads.
