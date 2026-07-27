# Infrastructure Audit — Raw Findings

**Domain 05 — Manifests, scripts, hooks, CI, documentation** | ICON-0089 | plugin v2.0.0 + `[Unreleased]` (ICON-0088) | baseline: ICON-0058

---

## Summary

Infrastructure has changed more between ICON-0058 and ICON-0089 than in any prior interval: CI now exists (three-job GitHub Actions `security` workflow, ported from `.gitlab-ci.yml`), a second harness hook shipped (`hooks/guardrail-pretooluse.mjs`), and `.githooks/pre-commit` grew from 3 invariants to **10**. Mechanically, the new machinery is sound — the GitLab→GitHub conversion left almost no residue (no `.gitlab-ci.yml`, no `glab`, two stale prose references), script parity holds byte-for-byte, `context-graph --check` passes clean (`49 nodes, no dangling references, no orphans`), the `structural-check.sh` suite passes all five checks, all five JSON files parse, and every ICON-0058 Minor except one is fixed.

The problem this cycle is **not defective machinery — it is unguarded seams around it.** Three findings rank Critical or near it and all three share one shape: *the release path, which force-moves `latest` into every consumer's plugin cache, has no mechanical gate on it at all.* Step 9 tags and force-pushes without ever asking whether CI is green — and ICON-0087's retrospective records that the `security` workflow was **RED on every PR and on `main` for many cycles, unnoticed until the user asked**. The manifest is mutated by `sed -i` on JSON and verified by `grep`, which passes on a syntactically-broken file; the one documented JSON-parse validation (`.claude/claude.md:14`, ADR-005) is prose-only and, verified on this machine, does not even execute (`python3` resolves to the Windows Store stub). Meanwhile the pre-commit gate stack — the repo's actual enforcement layer — is entirely opt-in per clone (`git config core.hooksPath .githooks`), fully bypassable with `--no-verify`, and **not backstopped by a single CI job**. CI lints shell and scans secrets; it does not re-run one of the ten invariants.

Documentation of the infrastructure has drifted proportionally to its growth: the hook's own header documents 3 of its 10 gates, `CONTRIBUTING.md` documents 4, `.context/domains/hooks.md` still says "ICON currently ships one hook" and omits the security guardrail entirely, and **ADR-005 — the governing decision this audit's script-offload focus is measured against — still describes ICON as "markdown + JSON + two shell hooks" with "no CI flakiness"**, which is now false in both clauses.

**Defect counts this cycle: 2 Critical, 8 Moderate, 11 Minor.** **Improvement Opportunities: 5.** **Script-Offload Candidates: 8.**

---

## Verbatim tool output (domain-owned tooling)

`bash .claude/skills/icon-audit/scripts/structural-check.sh`:

```
B.1 — SKILL.md sections
  OK
B.2 — Brief skeleton headings
  OK
B.3 — synthesis-template.md sections
  OK
B.4 — agent-evaluation one-way reference
  OK
B.6 — SKILL.md frontmatter
  OK
All structural checks passed.
EXIT CODE: 0
```

`bash skills/context-maintenance/scripts/context-graph.sh .context --check`:

```
[context-graph] OK: 49 nodes, no dangling references, no orphans
exit=0
```

JSON parse (via `node`, because `python3` is inoperable here — see M-I-5):

```
OK  .claude-plugin/plugin.json
OK  hooks/hooks.json
OK  context_template/context/iconrc.json
OK  .context/iconrc.json
OK  .claude/settings.json
```

Script parity (`diff -q`, `.sh` and `.ps1` across all three copies): `parity OK`.

Local tool availability: `node v24.17.0` present; **`shellcheck` NOT installed** (the pre-commit shellcheck gate silently skips on the maintainer's own machine); `python3` on `PATH` resolves to `/c/Users/thegr/AppData/Local/Microsoft/WindowsApps/python3` (Store stub), real Python only at `/c/Python314/python`.

---

## Defect Findings

### Critical

#### C-I-1 (net-new): the release flow tags and force-moves `latest` with no CI-status gate

`.claude/skills/release-plugin/SKILL.md:244-253` — Step 9 is:

```bash
git tag "v$NEW"
git tag -f latest
git push origin main "v$NEW"
git push -f origin latest
```

There is no preceding check that the `security` workflow passed on the release commit. A repo-wide grep for `gh run` / `gh workflow` / `check-runs` across `.claude/skills/release-plugin/` and `CONTRIBUTING.md` returns **nothing**. The Error Conditions table (`.claude/skills/release-plugin/SKILL.md:281-289`) covers "not on main", "dirty tree", "push fails" — it has no row for "CI is red".

**Observed failure mode (documented, not hypothetical):** `.context/retrospectives.md:12` — *"The `security` CI (semgrep SAST) had been RED on every PR and on `main` for many cycles, unnoticed until the user asked… 3 real findings, not a config error."* Any release cut in that window would have force-moved `latest` onto a commit with three live SAST findings, and nothing in the flow would have said so.

**Risk:** `latest` is the marketplace's `ref`. Force-moving it is the propagation mechanism into every consumer's plugin cache on their next update (`.claude/claude.md` § Marketplace consumption; ADR-003). A release is a one-way broadcast with no staged rollout and no documented rollback, and the flow's only quality signal is the releasing agent's judgment — which ICON-0087 proved does not reliably notice a red check.

**Compounding:** Step 8 (`:213-230`) commits directly to `main`, and Step 9 pushes immediately. There is no window in which CI could run on the release commit *before* `latest` moves even if someone wanted to look.

---

#### C-I-2 (net-new): no mechanical JSON-validity gate exists anywhere for `.claude-plugin/plugin.json`

The manifest is mutated by a regex text edit on JSON — `.claude/skills/release-plugin/scripts/bump-versions.sh:104`:

```bash
sed -i "s/\"version\": \"${OLD_ESC}\"/\"version\": \"${NEW}\"/" "$PRIMARY"
```

The only post-write verification is `.claude/skills/release-plugin/SKILL.md:203-209`, which greps for the version line. **A grep for `"version"` succeeds on a file that no longer parses as JSON** (unbalanced brace, stray byte, truncation from a failed write). Coverage elsewhere:

- `.githooks/pre-commit` — 975 lines, 10 gates, **no JSON gate** (grep for `JSON.parse`/`json.load`/`jq` returns nothing in `.githooks/`).
- `.github/workflows/security.yml:13-54` — three jobs (gitleaks, semgrep, shellcheck). **No JSON gate.**
- `.claude/claude.md:11-14` and `.context/decisions/005-no-build-step.md:19` both declare `python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))"` to be *the* validation for this repo. It is prose in a doc, invoked by nobody, and — verified above — **does not run on the maintainer's own machine**.

**Risk:** an unparseable `plugin.json` force-moved to `latest` breaks plugin load for every consumer with no detection anywhere in the pipeline. Probability per release is low (`sed` on a stable one-line pattern is not fragile); detection probability is **zero**; blast radius is total and automatic. That combination is what makes it Critical under the brief's rule ("anything that could… ship a broken `latest` to consumers"). The fix is one line in a hook — see SO-1.

---

### Moderate

#### M-I-1 (net-new; regression of the ICON-0046 m-infra-2 class): the pre-commit header documents 3 of its 10 gates

`.githooks/pre-commit:19-40` reads *"Additional invariants (ICON-0032, ICON-0044) — in script-execution order: 1. iconrc.json version-bump gate / 2. Script-parity check / 3. Dead-ref resolver."* The script's actual gate sequence is:

| # | Gate | Line |
|---|------|------|
| 1 | iconrc version-bump gate | `:57-224` |
| 2 | common-constraints byte-equality sync | `:226-463` |
| 3 | script-parity check | `:579` |
| 4 | O-M1a placeholder sentinel | `:618` |
| 5 | O-M1b cap-literal consistency | `:649` |
| 6 | O-V1 skill-registration | `:704` |
| 7 | rules-index freshness | `:737` |
| 8 | ICON-0081 context-graph `--check` (fail-closed) | `:758` |
| 9 | dead-ref resolver | `:821` |
| 10 | ICON-0075 secret-scan | `:910` |
| 11 | ICON-0075 shellcheck | `:949` |

Seven gates are undocumented in the header, and the one gate the header numbers "3" (dead-ref) actually runs ninth. ICON-0046 raised exactly this class (m-infra-2, header ordering wrong); ICON-0058 confirmed it fixed. It has regressed at four times the original magnitude because every gate added since (ICON-0069, 0075, 0081, plus O-M1a/O-M1b/O-V1) appended code without touching the header.

**Risk:** the header is the first thing a maintainer reads before editing a 975-line gate stack. Editing under a 3-gate mental model — particularly around the fail-closed contract documented at `:775-781` — is how the ICON-0075 fail-open class reappears.

---

#### M-I-2 (net-new): `.context/domains/hooks.md` says ICON ships one hook; the security guardrail is absent from the registry

`.context/domains/hooks.md:52` — *"ICON currently ships one hook:"* — followed by a single-row table at `:54-56` listing only `inject-manager-role`. `hooks/guardrail-pretooluse.mjs` (the `PreToolUse` secret-write / pipe-to-shell guardrail shipped in 2.0.0 via ICON-0073, wired at `hooks/hooks.json:15-27`) **does not appear**. Two further drifts in the same table and section:

- `:56` gives the matcher as `startup\|resume`; `hooks/hooks.json:5` is `startup|resume|clear`. The `clear` source was added deliberately (`hooks/inject-manager-role.mjs:16-18`: *"re-establishes the manager role after the user runs `/clear`"*) and the domain doc never caught up.
- `:117` describes the iconrc gate as *"release-aware against the `main` merge-base baseline per ICON-0062"*. The hook (`.githooks/pre-commit:108-210`) now resolves the baseline through a **3-tier chain whose Tier 1 is the `latest` tag** (ICON-0071); merge-base is only Tier 2. `release-plugin` Step 6 (`.claude/skills/release-plugin/SKILL.md:152-159`) correctly describes the `latest`-tag behavior — so the two authorities disagree.

`.context/domains/hooks.md:113` bills itself as *"Where the Authoritative Reference Lives."* A security-relevant hook missing from the authoritative registry is how a future change to `hooks.json` drops or breaks it without anyone noticing.

---

#### M-I-3 (net-new): `.github/workflows/security.yml` declares no `permissions:` block

`.github/workflows/security.yml:9-54` — neither workflow-level nor job-level `permissions:` is set, so all three jobs receive the repository's default `GITHUB_TOKEN` scope. All three run **third-party container images** (`zricethezav/gitleaks`, `semgrep/semgrep`, `koalaman/shellcheck-alpine`) with that token present in the environment, and the `sast` job additionally pulls an unpinned remote ruleset over the network at run time (`:35`, `--config p/ci`).

None of these jobs needs any write scope — they read the tree and exit. `permissions: contents: read` at the workflow level costs one line and removes push/issue/package write from a supply-chain-exposed surface. This is the same defense class the repo already argued for itself in `secure-coding.md:29` (Rule 12, action pinning); the token-scope half was never applied.

---

#### M-I-4 (net-new): container images are pinned by mutable tag while `uses:` are SHA-pinned — Rule 12's own completeness grep can't see them

ICON-0087 pinned every `uses:` to a 40-char SHA and codified it as `secure-coding.md:29` Rule 12, with the completeness grep `uses:\s*\S+@(v?[0-9]+|main|master)`. All three `uses:` are correctly pinned (`.github/workflows/security.yml:20,31,43` — `actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5`).

But every job body runs inside a container pinned by **tag**, not digest:

- `:18` — `image: zricethezav/gitleaks:v8.30.1`
- `:29` — `image: semgrep/semgrep:1.167.0`
- `:41` — `image: koalaman/shellcheck-alpine:v0.11.0`

A Docker tag is repointable exactly like a git tag — the identical supply-chain property Rule 12 exists to eliminate. The rule's text scopes itself to `uses:`, and its completeness grep matches `uses:` only, so `image:` is invisible to both the rule and its verification step. The scanner *containers* are where arbitrary code actually executes against the checkout, so this is the higher-value half of the pin.

**Fix shape:** `image: semgrep/semgrep:1.167.0@sha256:<digest>` and widen Rule 12 + the grep to `(uses:|image:)`.

---

#### M-I-5 (net-new): the `python3` the repo depends on does not exist on a stock Windows box — including for consumer-shipped skills

Verified on this machine: `command -v python3` → `/c/Users/thegr/AppData/Local/Microsoft/WindowsApps/python3`. That is the **Microsoft Store app-execution-alias stub**, not an interpreter; invoking it prints *"Python was not found; run without arguments to install from the Microsoft Store…"* and exits non-zero. Real Python is installed at `/c/Python314/python` — with no `python3` alias. So `python3 -c …` fails on a Windows dev box *even when Python is installed*, and fails with a message that does not resemble a JSON error.

This is not confined to maintainer tooling. `python3` is load-bearing in **8 consumer-shipped files**:

- `skills/icon-status/SKILL.md:108` — reads the installed `.context/iconrc.json` version (`/icon-status` core path)
- `skills/icon-init/SKILL.md:69` — workspace detection
- `skills/initialize-workspace/SKILL.md:44` — `.code-workspace` parsing
- `skills/create-iconrc/SKILL.md:93,131`
- `skills/plugin-design/audit-phase-structure.md:24,43`, `audit-phase-consistency.md:19,53,110`, `create-phase-basic-info.md:44,84,117`, `create-phase-boilerplate.md:137`, `create-phase-marketplace.md:18`

Node — already a hard prerequisite of both harnesses, and the runtime of both shipped hooks — is present (`v24.17.0`) and would serve every one of these. `.context/standards/shell-portability.md` has six rules and none of them covers "don't assume `python3`".

---

#### M-I-6 (net-new): ADR-005 materially misdescribes the infrastructure it governs — and reads as forbidding this audit's own focus

`.context/decisions/005-no-build-step.md` is **Status: Accepted** with no `**Superseded-by**` field, and four of its statements are now false:

- `:8` — *"ICON is pure content (markdown + JSON + **two shell hooks**)."* Actual: two Node `.mjs` harness hooks, two git hooks (one 975 lines), 12 skill/maintainer scripts, one CI workflow.
- `:19` — *"**No CI flakiness** — the only runtime check is `python3 -c …`."* Actual: a three-job GitHub Actions workflow exists, and ICON-0087 records it silently red for many cycles — the precise outcome this line claims is structurally absent.
- `:23` — *"relies on `plugin-audit` skill."* Renamed `icon-audit` (the rename is old enough that `structural-check.sh:137` carries a legacy-name check for it).
- `:28` — rejects a Node-based validator because it *"would introduce a Node toolchain that contradicts ADR-004's tool-agnostic stance."* Two Node hooks now ship and Node is a de facto prerequisite; the stated rejection rationale no longer holds.

**Why this is Moderate rather than a doc nit:** ADR-005 is the decision every "should ICON add a mechanical check?" proposal is measured against — including all eight candidates in this report. As written it reads as a standing prohibition on the exact class of work the user directed this cycle, justified by facts that are no longer true. It needs a superseding or amending ADR before the offload work lands, not after.

---

#### M-I-7 (net-new): the secret-pattern list is duplicated across two enforcement surfaces with a prose-only sync obligation

The same seven credential regexes exist twice:

- `hooks/guardrail-pretooluse.mjs:106-114` (`SECRET_PATTERNS`, runtime `PreToolUse` deny)
- `.githooks/pre-commit:920-928` (`secret_patterns`, commit-time gate)

`.githooks/pre-commit:917` states the obligation in prose: *"If a pattern is tuned, keep it in sync with the guardrail RULES array."* There is **no mechanical parity check**. I verified the two lists are currently equivalent (the only difference is `[A-Za-z0-9_=.\-]` vs `[A-Za-z0-9_=.-]` in `atlassian-token`, semantically identical), so this is a latent defect, not an active one.

**Why it's Moderate:** the repo already proved it knows how to mechanize this class — `append-retrospective-entry.{sh,ps1}` gets a *byte-identity* pre-commit gate (`.githooks/pre-commit:579-617`) across three copies. A retrospective-append helper is guarded; the credential-detection list that gates secret leakage is not. The protection is inverted relative to consequence, and drift here means a pattern tightened in one surface silently leaves the other permissive.

---

#### M-I-8 (still present, widened): GNU-only `grep -oP` and `sed -i` ship to consumers

`grep -P` is a GNU extension absent from BSD/macOS `grep`; `sed -i` requires an argument on BSD `sed`. Both appear in **consumer-executed** content:

- `skills/upgrade-repo/SKILL.md:492-493` — `grep -oP '[\d.]+'` on the template and installed `iconrc.json` (this is the version comparison `/upgrade-repo` Phase 2 gates on)
- `skills/upgrade-repo/SKILL.md:495` — `sed -i "s/\"version\"…"` writing the consumer's `.context/iconrc.json`
- `context_template/context/workflows/commit-conventions.md:74` — `grep -oP 'MKT-\K[0-9]+'` (also carries a stale `MKT-` prefix in the shipped template)
- `skills/initialize-monorepo/SKILL.md:82` — `grep -oP '"[^"]+\.csproj"'`

Maintainer-only instances (`.claude/skills/release-plugin/SKILL.md:84,162,163`; `bump-versions.sh:104`) are lower-risk but identical in shape. On macOS, `/upgrade-repo` Phase 2 fails or silently produces an empty version, and `sed -i` errors out mid-write. `.context/standards/shell-portability.md` Rule 1 bans gawk extensions but says nothing about PCRE grep or in-place sed.

---

### Minor

#### m-I-1 (net-new): GitLab residue in `icon-audit/SKILL.md` — the audit skill still routes to GitLab issues

- `.claude/skills/icon-audit/SKILL.md:124` — *"Offer to file Suggested Follow-up Tasks as **GitLab** issues"*
- `.claude/skills/icon-audit/SKILL.md:151` — *"Suggested follow-up tasks are filed as **GitLab** issues"*

ICON has been GitHub-only since 2.0.0 (ICON-0080). These are the *only* two live prose GitLab references outside the CHANGELOG's historical entries, the `security.yml` port comment (`:1-5`, legitimately historical), and the `glpat-` pattern name. **This is precisely the ICON-0086 lesson unlearned** — *"a feature removal is complete only when its dependent references are swept"* (`.context/retrospectives.md:8`). The ICON-0089 dispatch plan (`plan.md:38`) says "file follow-up tasks as **GitHub** issues" — the manager silently corrected for a skill the skill itself gets wrong, which is exactly the LLM-carries-the-fix pattern this cycle is auditing for.

Also under this class: `context_template/context/workflows/commit-conventions.md:74` ships `MKT-\K[0-9]+` — a task prefix from ICON's pre-split history, in a consumer template.

---

#### m-I-2 (carry-forward from ICON-0058 IO-I-E, unchanged): `Co-authored-by: Copilot` hardcoded in the release commit template

`.claude/skills/release-plugin/SKILL.md:229` still contains `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>` in the Step 8 commit template. ICON-0058 raised this; recent release commits are Claude Code-authored. A releaser following the template literally misattributes the release commit. `CONTRIBUTING.md:26` now *requires* cryptographically-signed commits precisely because the `Co-authored-by` trailer is forgeable — shipping a hardcoded false trailer in the canonical template cuts against that.

---

#### m-I-3 (net-new): `CONTRIBUTING.md` documents 4 of 10 pre-commit gates

`CONTRIBUTING.md:52` — *"The pre-commit hook… enforces several invariants (`shared/common-constraints.md` byte-equality across agents, dead-reference resolution, `iconrc.json` version-bump gate, script parity)."* Missing: placeholder sentinel, cap-literal, skill-registration, rules-index, context-graph, secret-scan, shellcheck. (Two of the missing seven *are* described elsewhere in the file — skill-registration at `:55`, placeholder at `:58` — but not in the invariant list a contributor reads to know what will block them.) Same staleness class as M-I-1.

---

#### m-I-4 (net-new): `CHEATSHEET.md` is an orphan and is framed Copilot-only

`CHEATSHEET.md` exists at repo root but is referenced from **nowhere** — a grep for `CHEATSHEET` across all Markdown outside `.context/` returns zero hits. `README.md`'s "What do you want to do?" intent index (`:38-48`) is the natural entry point and doesn't link it. Its own framing is also stale: `CHEATSHEET.md:6-7` — *"Commands below are written for **GitHub Copilot CLI** (the supported surface)"* with Claude Code relegated to an addendum — whereas the `/ICON:*` command set, `hooks/hooks.json` SessionStart wiring, and the manager-default are Claude-Code-first features.

---

#### m-I-5 (net-new): `hooks/hooks.json` — asymmetric `bash` key, no `$schema`

`hooks/hooks.json:23` gives the `PreToolUse` entry a `"bash"` sibling to `args`; the `SessionStart` entry (`:6-12`) has no such key. If `bash` is the Copilot-CLI invocation form, then `inject-manager-role.mjs` never fires under Copilot — which matches its file header (*"SessionStart hook for **Claude Code**"*, `:1`) and is presumably intentional, but nothing in `hooks.json` or `.context/domains/hooks.md` records the asymmetry as deliberate. The file also has no `$schema` key, while `.claude-plugin/plugin.json:2` does — so hook wiring gets no editor validation and no CI validation.

---

#### m-I-6 (net-new): `security.yml` has no `concurrency` group — every PR commit runs the suite twice

`.github/workflows/security.yml:9-11` triggers on both `push:` and `pull_request:` with no branch filter and no `concurrency:` block. Every commit on a PR branch fires both events against the same SHA — three duplicated jobs, each pulling a container image. Adding `concurrency: { group: ${{ github.workflow }}-${{ github.ref }}, cancel-in-progress: true }` halves the run count and cancels superseded runs. (Doubled noise is also a plausible contributor to how ICON-0087's red status went unread for so long.)

---

#### m-I-7 (net-new): semgrep runs an unpinned remote ruleset

`.github/workflows/security.yml:35` — `semgrep scan --config p/ci --error .`. `p/ci` is fetched from semgrep.dev at run time. The scanner binary is version-pinned (`:29`) but the *rules* are not, so CI's pass/fail behavior can change with no commit to this repo, and the job hard-depends on network egress from inside the container. Pinning to a vendored ruleset (or a registry snapshot) makes the gate reproducible; today a green run is not evidence a re-run will be green.

---

#### m-I-8 (net-new): gitleaks scans the working tree only, never history

`.github/workflows/security.yml:23` — `gitleaks detect --source . --no-git --redact --verbose --exit-code 1`. `--no-git` scans checked-out files and skips commit history entirely. Combined with `actions/checkout`'s default `fetch-depth: 1`, a credential that was committed and later removed is invisible to both the CI scan and the pre-commit gate (which only sees the current staged blob, `.githooks/pre-commit:929-938`). Nothing in the repo scans history. `--redact` is correctly applied, and the working-tree scan is the right *fast* check — this is a coverage note, not a defect in what it does.

---

#### m-I-9 (net-new): no PowerShell lint parity — `.ps1` files get zero automated checking

`.github/workflows/security.yml:51-54` shellchecks every `*.sh` plus both git hooks. There is **no PSScriptAnalyzer job**, and `.githooks/pre-commit:953-973` arms `shellcheck_needed` for `*.sh` only. Three `.ps1` files ship (`append-retrospective-entry.ps1` ×3, `context-graph.ps1`) and are held to byte-parity with each other but never linted. The `.sh` half of every pair is checked; the `.ps1` half is not — so a PowerShell defect can only be found by a consumer running it.

---

#### m-I-10 (net-new): `.github/` contains only the workflow — no PR template, CODEOWNERS, issue templates, or dependabot

`find .github -type f` returns exactly one file: `.github/workflows/security.yml`. `CONTRIBUTING.md:62-66` specifies what a PR description must contain (originating issue/task ID, behavior-change summary, verification steps, decisions) — none of it is scaffolded as `.github/pull_request_template.md`, so the requirement is carried entirely by whether the author read CONTRIBUTING. Same for `:12` (defect reports must include the ICON version, agent/skill involved, expected vs observed) with no issue template. `CONTRIBUTING.md:25` requires protected-branch config with human merge, but no `CODEOWNERS` routes review.

---

#### m-I-11 (accepted per ADR-010; not counted): `2>/dev/null` in autonomous scripts

`context_template/context/workflows/prune-context.sh` retains its instances; `.githooks/pre-commit:89,94,95,196,954` and `.claude/skills/icon-audit/scripts/structural-check.sh` also use the idiom. All are autonomous scripts under ADR-007's carve-out and ADR-010's accepted carry-forward (m1). **Not re-tiered as Minor.** Noted only to record that the pattern was checked, per the brief's "no silent omission" rule. The pre-commit hook is explicit and correct about this at `:745` and `:790` (*"No `2>/dev/null`: diagnostics stay visible (ADR-007)"*) for the delegated-script invocations, where it matters.

---

## Improvement Opportunities

*(Positive-design suggestions. Where an item overlaps a script-offload candidate, the candidate below carries the mechanization detail.)*

### IO-I-A — Give the release flow a pre-flight `--check` block, and a documented rollback

**Problem:** Steps 1–9 are nine prose steps whose gates (on `main`, clean tree, `latest` resolves, template version sane, manifest bumped) are each verified by a separate human/agent reading of separate command output. Nothing composes them, nothing blocks on the composite, and `.claude/skills/release-plugin/SKILL.md:281-289` has no row for "the release you just pushed was wrong."

**Proposed:** a single `release-preflight.mjs` run as Step 0 that asserts all of {on `main`, tree clean, local `main` == `origin/main`, `latest` resolves, CI green on `HEAD` via `gh run list --branch main --limit 1 --json conclusion`, `plugin.json` parses, template version == released+1, no duplicate CHANGELOG headings} and exits non-zero with a per-assertion report. Plus an **Emergency rollback** section: how to re-point `latest` at the prior release tag (`git tag -f latest <prev-sha> && git push -f origin latest`) and what consumers see in the interim.

**Effort:** Medium. **Impact:** High — collapses eight judgment checkpoints into one fail-closed gate on the repo's only irreversible operation. Closes C-I-1 and C-I-2.

---

### IO-I-B — Generate the hook's documentation from the hook

**Problem:** M-I-1, m-I-3, and M-I-2 are one failure: four surfaces describe the pre-commit gate stack (`.githooks/pre-commit:19-40`, `CONTRIBUTING.md:52`, `.context/domains/hooks.md:120-128`, and the gate comments themselves) and three have drifted, because adding a gate means remembering four edits.

**Proposed:** make the gate *sections* the SSOT. Each gate already opens with a banner comment (`# ---- \n# <Name> \n# ----`). A small generator parses those banners in source order and emits the header table plus the `CONTRIBUTING.md` and `hooks.md` lists between marker comments — the same `<!-- BEGIN -->/<!-- END -->` mechanism the hook already uses for `common-constraints`. Then a `--check` mode in the hook fails the commit when the generated block is stale.

**Effort:** Medium. **Impact:** High — retires an entire recurring finding class (it has now recurred in ICON-0046, ICON-0058, and ICON-0089) rather than re-fixing its instances.

---

### IO-I-C — `$schema` coverage and a JSON-shape gate across all four JSON surfaces

**Problem:** `.claude-plugin/plugin.json:2` has `$schema`; `hooks/hooks.json`, `context_template/context/iconrc.json`, and `.context/iconrc.json` have none. No JSON file in the repo is validated by any automated process (C-I-2). ICON-0058's IO-I-B proposed this for `.mcp.json`, which has since been removed — the opportunity survived the file.

**Proposed:** (1) add `$schema` to `hooks/hooks.json` if a Claude Code hooks schema is published; (2) author a small hand-written schema for `iconrc.json` under `context_template/` and reference it from both copies — it is ICON's own format, so ICON can define it; (3) wire a parse-plus-shape gate into the pre-commit hook and a CI job (SO-1).

**Effort:** Low–Medium. **Impact:** Medium–High — turns the repo's *stated* validation policy (ADR-005) into an executed one.

---

### IO-I-D — Amend or supersede ADR-005 to describe the infrastructure that actually exists

**Problem:** M-I-6. The governing ADR says "two shell hooks" and "no CI flakiness", and rejects Node tooling on grounds that two shipped Node hooks have already overtaken. Every mechanization proposal in this report currently has to argue against a stale ADR.

**Proposed:** a new ADR (016) that scope-supersedes ADR-005's *Consequences* and *Alternatives* while leaving its Decision prose intact as the historical record — the `**Supersedes**` / `**Superseded-by**` bold-field pattern ICON-0085 established (`.context/retrospectives.md:20`). It should state the current position explicitly: *no package manager, no build artifacts, no test framework — but Node is an assumed runtime (both harnesses ship it), and deterministic gates in Node/bash are in scope.* That single sentence is the license the offload program needs.

**Effort:** Low. **Impact:** High — unblocks the whole offload class and closes a live contradiction in the decision log.

---

### IO-I-E — Scaffold `.github/`: PR template, issue templates, CODEOWNERS, dependabot

**Problem:** m-I-10. `CONTRIBUTING.md` specifies PR and issue content requirements that nothing scaffolds, and the repo has no dependency-update automation for its pinned actions and scanner images (which, per M-I-4, will need periodic re-pinning as digests move).

**Proposed:** `.github/pull_request_template.md` mirroring `CONTRIBUTING.md:62-66`; `.github/ISSUE_TEMPLATE/{bug,feature}.yml` mirroring `:12`; `CODEOWNERS` routing `agents/`, `skills/`, `.githooks/`, `hooks/`, and `.github/` to the maintainer; `.github/dependabot.yml` with `package-ecosystem: github-actions` (and `docker` once images are digest-pinned) so the pins get maintained rather than aging.

**Effort:** Low. **Impact:** Medium — moves four prose requirements into the surfaces where contributors actually encounter them.

---

## Script-Offload Candidates

*Ranked by leverage. Class refers to the four hosting options assessed in § Mechanization Architecture Recommendation: **(i)** `.githooks/pre-commit`, **(ii)** GitHub Actions, **(iii)** skill-invoked script, **(iv)** harness hook.*

---

### SO-1 — JSON validity + manifest shape gate — **Class (i)+(ii), fail-closed**

**(a) Current LLM-carried obligation.** `.claude/claude.md:11-14` — *"Validation means 'the JSON parses'"* — and `.context/decisions/005-no-build-step.md:19`, restating the same command as *"the only runtime check."* `.claude/skills/release-plugin/SKILL.md:203-209` asks the releasing agent to eyeball `grep '"version"'` output. Every one of these is an instruction to a model, executed only if the model chooses to.

**(b) Observed failure mode.** No JSON-corruption incident on record. But the *documented command does not execute at all* on the maintainer's primary machine (M-I-5, verified), so the stated control has been inert for an unknown period — the same silent-inertness shape as ICON-0087's unread CI. Say: no observed corruption yet; observed inertness of the control.

**(c) Mechanization.** `scripts/check-json.mjs`: `JSON.parse` every tracked `.json`, then assert `plugin.json` has `name`/`version`/`description`, `version` matches `^\d+\.\d+\.\d+$`, and `$schema` is present. Hooks in **twice**: `.githooks/pre-commit` armed when any `*.json` is staged (fast, local), and a CI job in `security.yml` on every push (unbypassable, and the one that actually guards the release commit). Fail-closed in both: non-zero exit blocks.

**(d) Residual judgment.** Whether the *value* is right — is `2.1.0` the correct bump for this diff (Step 4's semantics table). A script can enforce well-formedness and monotonicity; it cannot decide minor-vs-major.

**(e)** **Low effort × High leverage.** ~40 lines of Node. Closes C-I-2 and makes ADR-005's own claim true for the first time.

---

### SO-2 — Release pre-flight: CI-green + sync + version assertions — **Class (iii), fail-closed, invoked by a Class (i) reminder**

**(a) Current LLM-carried obligation.** `.claude/skills/release-plugin/SKILL.md:26-41` (on `main`, clean tree), `:44-57` (`latest` resolves), `:145-188` (template version == released+1, with three prose interpretation branches the agent must choose between), `:203-209` (manifest bumped). **CI-green is not even stated as an obligation** — it is absent from all nine steps and from the Error Conditions table at `:281-289`.

**(b) Observed failure mode.** `.context/retrospectives.md:12` — *"The `security` CI (semgrep SAST) had been RED on every PR and on `main` for many cycles, unnoticed until the user asked… Don't treat a persistently-red CI check as noise."* The remedy recorded in that retro was a *lesson* (`secure-coding.md:29` Rule 12, about pinning) — no mechanism was added that would make the *next* red streak visible, and none exists on the release path today.

**(c) Mechanization.** `.claude/skills/release-plugin/scripts/release-preflight.mjs`, run as Step 0 and again immediately before Step 9's `git push -f origin latest`. Assertions: branch == `main`; `git status --porcelain` empty; `git rev-list --count origin/main..HEAD` == 0 after fetch; `latest` resolves; `gh run list --branch main --commit $(git rev-parse HEAD) --json conclusion` shows success for `security`; `check-json.mjs` passes; template version == released+1 (mechanizing the three-branch prose at `:170-188` into one comparison); CHANGELOG dup-heading awk (`:138`) returns empty. Exit non-zero with a per-assertion table. Fail-closed.

**(d) Residual judgment.** Bump scope (patch/minor/major) from the diff; CHANGELOG *prose* quality; and the genuinely human call of whether now is the right moment to broadcast to consumers — the release guard in `.claude/claude.md` is correct that this stays with the user.

**(e)** **Medium effort × Very high leverage.** This is the highest-consequence unguarded path in the repo. Closes C-I-1.

---

### SO-3 — Generate the pre-commit gate documentation from the gate source — **Class (i), fail-closed**

**(a) Current LLM-carried obligation.** Whoever adds a gate must remember to update `.githooks/pre-commit:19-40`, `CONTRIBUTING.md:52`, and `.context/domains/hooks.md:120-128`. This obligation is written down **nowhere** — it is pure convention.

**(b) Observed failure mode.** Directly observed, three cycles running: ICON-0046 m-infra-2 (header order wrong) → fixed → ICON-0089 M-I-1 (header lists 3 of 10, order wrong again) plus m-I-3 (CONTRIBUTING lists 4 of 10) plus M-I-2 (`hooks.md` lists 1 of 2 hooks, wrong matcher, wrong baseline tier). Seven gates were added across ICON-0069/0075/0081 and O-M1a/O-M1b/O-V1; **zero** of them updated all three surfaces.

**(c) Mechanization.** `scripts/gen-gate-docs.mjs` parses gate banner comments from `.githooks/pre-commit` in source order (the banners are already uniform: `# ---- / # <Name> / # ----`) plus `hooks/hooks.json` for the harness-hook table, and rewrites marker-delimited blocks in the three consumer surfaces — reusing the `<!-- BEGIN: … -->/<!-- END: … -->` mechanism the hook already implements for `common-constraints` (`:54-55`). `--check` mode in the pre-commit hook, armed when `.githooks/pre-commit` or `hooks/hooks.json` is staged; fail-closed on stale.

**(d) Residual judgment.** The *prose rationale* for each gate — why it exists, what the exemption markers are for, the fail-closed contract narrative at `:775-781`. Generate the inventory (what/where/order); keep the reasoning hand-written.

**(e)** **Medium effort × High leverage.** Retires a class with three confirmed recurrences instead of patching its third instance.

---

### SO-4 — Extend script-parity to the secret-pattern lists (and generalize the parity gate) — **Class (i), fail-closed**

**(a) Current LLM-carried obligation.** `.githooks/pre-commit:917` — *"If a pattern is tuned, keep it in sync with the guardrail RULES array."* One sentence, in a comment, addressed to a future editor.

**(b) Observed failure mode.** No observed drift yet — I verified the two lists are equivalent today. The relevant evidence is *class* evidence: the identical prose-sync obligation on `append-retrospective-entry` drifted repeatedly (the 15→10 cap literal, ICON-0048's partial sweep, ICON-0058 m-infra-5) until it was replaced by a byte-parity gate — after which it has held clean, including in this audit's `diff -q` run.

**(c) Mechanization.** Promote the patterns to one SSOT data file (`shared/secret-patterns.json`), have `guardrail-pretooluse.mjs` import it and the hook read it via `node -e`; *or*, if a runtime read is unwanted in the guardrail's fail-open path, keep both literals and add an extraction-and-compare check to the existing parity block (`.githooks/pre-commit:579-617`), armed when either file is staged. Fail-closed. Same move generalizes the parity gate from a hardcoded triple to a declarative `parity-groups.json`.

**(d) Residual judgment.** Whether a *new* pattern belongs in the set at all, and whether its regex is tight enough to avoid false positives — `guardrail-pretooluse.mjs:100-102` documents that judgment explicitly. Mechanize sameness, not membership.

**(e)** **Low effort × Medium-High leverage.** Closes M-I-7; the generalized version is the reusable half.

---

### SO-5 — Removal-sweep completeness gate (banned-literal grep) — **Class (i) armed + (ii) authoritative, fail-closed**

**(a) Current LLM-carried obligation.** `.context/retrospectives.md:8` (ICON-0086) — *"A repo-wide grep for the feature's own identifiers…, not just the owning skill, is what makes the removal complete. Same whole-tree-grep-mandate class as ICON-0080."* Also `:43` — *"give sweep coders a whole-tree grep mandate, not just a hand-curated file list."* This is a lesson recorded twice in the live retrospective log and promoted to `skill-decomposition/process-doc-sweeps.md`. It is enforced by nothing.

**(b) Observed failure mode.** ICON-0080 (GitHub conversion) and ICON-0086 (Slack removal) both record incomplete first-pass sweeps. And it has failed **again in this very audit**: M-I-8 / m-I-1 — `.claude/skills/icon-audit/SKILL.md:124,151` still say "GitLab issues" two releases after the GitHub-only conversion, and `context_template/context/workflows/commit-conventions.md:74` still ships the pre-split `MKT-` prefix. ICON-0058 flagged the same class as *"the ICON-0015 O-V4 literal-grep gate… remains unimplemented across 3+ cycles"* — it is now 4+.

**(c) Mechanization.** `shared/banned-literals.json`: `[{ pattern, reason, since, allow: [globs] }]`, seeded with `gitlab`/`glab`/`merge request`/`\bMR\b`, `MKT-`, `SLACK_WEBHOOK_URL`/`format-slack`, `mcp-tools-first`, `jira-story`, `mr-discipline`. `scripts/check-banned-literals.mjs` greps the tracked tree, honoring allowlists (needed for the legitimate historical cases: CHANGELOG entries, `security.yml:1-5`'s port comment, the `glpat-` pattern name, `.mr-2` CSS in the style template). Armed in pre-commit on staged files for fast feedback; authoritative as a CI job over the whole tree, because the whole point is catching sites the current commit does *not* touch. Fail-closed.

**(d) Residual judgment.** Deciding a literal is now banned, and writing the allowlist entry that distinguishes a live reference from a historical record. Both are one-time human calls per removal; the sweep is not.

**(e)** **Low effort × High leverage.** The single most-recurring finding class in ICON's audit history, and the cheapest to mechanize.

---

### SO-6 — Portability lint: `grep -P`, `sed -i`, `python3`, bash-4-isms in shipped content — **Class (ii) authoritative + (i) armed, fail-closed**

**(a) Current LLM-carried obligation.** `.context/standards/shell-portability.md` — six hand-written rules (gawk extensions, pure-bash parsing, live-testing, `grep -e`, `${VAR+x}`, PowerShell `-replace`), each of which an authoring agent must recall at the moment it writes a shell block in a skill. `skills/icon-init/SKILL.md` and `skills/icon-status/SKILL.md` cite the standard by name (ICON-0079), which is reach-by-hyperlink, not enforcement.

**(b) Observed failure mode.** M-I-5 and M-I-8, both net-new this cycle and both in **consumer-executed** paths: `skills/upgrade-repo/SKILL.md:492-495` (`grep -oP` + `sed -i` in the Phase-2 version gate) and `skills/icon-status/SKILL.md:108` (`python3` — broken on stock Windows, verified). The standard exists, is cited by name from two skills, and the violations shipped anyway. `.context/retrospectives.md:49-50` records ICON-0079 trimming the inline convention *to* a by-name cite — reach was traded for terseness with no mechanism backstopping it.

**(c) Mechanization.** `scripts/check-portability.mjs` scanning fenced `bash`/`sh` blocks in `skills/**/*.md`, `commands/**/*.md`, `context_template/**/*.md` and all `*.sh`, flagging `grep -[a-zA-Z]*P`, `sed -i` without a backup arg, bare `python3`, `mapfile`/`readarray`, `declare -A`, and `${var^^}`. CI job (authoritative — this must see the whole tree, since the violation is usually in a file the current commit doesn't touch), plus pre-commit arming on staged skills for fast feedback. Fail-closed, with `# portability-ok: <reason>` inline escapes. Extend `shell-portability.md` with the two new rules the findings imply.

**(d) Residual judgment.** Whether a flagged construct is genuinely unavoidable, and what the portable rewrite should be (`grep -oP '"version":\s*"\K[\d.]+'` → a `node -e` JSON read is the right answer here, not a POSIX regex contortion).

**(e)** **Medium effort × High leverage.** These are consumer-facing breakages on a platform ICON claims to support.

---

### SO-7 — Supply-chain pin completeness across `uses:` **and** `image:` — **Class (ii), fail-closed**

**(a) Current LLM-carried obligation.** `.context/standards/secure-coding.md:29` (Rule 12) — pin every `uses:` to a 40-char SHA, verify via `gh api`, confirm completeness with the grep `uses:\s*\S+@(v?[0-9]+|main|master)`. The rule *names* its own enforcement (the semgrep `github-actions-mutable-action-tag` rule), which is genuinely mechanized — but only for the half of the surface the rule's author thought of.

**(b) Observed failure mode.** M-I-4: all three `container: image:` values are tag-pinned (`security.yml:18,29,41`) and both the rule text and its completeness grep are structurally incapable of seeing them. The meta-failure is ICON-0087's own: a supply-chain control was written, mechanized, and left with a blind spot that the same retro's "completeness grep" step did not reveal because the grep encoded the same blind spot.

**(c) Mechanization.** Widen the semgrep rule (or add a `check-workflow-pins.mjs` CI job) to match `image:\s*\S+:(?!.*@sha256:)` alongside the existing `uses:` rule, and update `secure-coding.md:29` to say "every `uses:` **and every `container.image:`**". Add `.github/dependabot.yml` (`github-actions` + `docker`) so pins are maintained rather than frozen. Fail-closed — a mutable pin already fails CI today for `uses:`; extend the same behavior.

**(d) Residual judgment.** Whether to accept a specific upstream digest (the `gh api` dereference-and-verify step at `secure-coding.md:29` is genuine review work), and whether a Dependabot bump is safe to merge.

**(e)** **Low effort × Medium leverage.** Small diff; closes a security control's blind spot on the surface where third-party code actually executes.

---

### SO-8 — Retrospective log integrity check (`merge=union` coalescing detector) — **Class (i), fail-closed**

**(a) Current LLM-carried obligation.** The ICON-0088 CHANGELOG entry describes *"a `merge=union` coalescing hazard in retrospective logs — two branches that each prepend an entry can merge into a single paragraph record, silently undercounting the entry cap — along with the heading-count-vs-paragraph-count check that detects it"*, shipped as prose into `context_template/context/workflows/task-plan/phase-completion.md`. It is a **manual counting check a closing agent is asked to perform**, and it is now shipped to every consumer repo in that form. `.gitattributes:10-11` applies `merge=union` unconditionally to `retrospectives.md` and `retrospectives-archive.md`.

**(b) Observed failure mode.** `.context/retrospectives.md:4` records the hazard as *"discovered post-insertion"* — i.e. it already happened once and was caught by inspection, not by tooling. The failure is silent by construction: a coalesced entry looks like a valid file, and the cap enforcement in `append-retrospective-entry.sh` (`ENTRY_CAP=10`, `:41`) counts the wrong thing afterwards.

**(c) Mechanization.** Extend `append-retrospective-entry.{sh,ps1}` — or better, add a `--check` mode invoked from `.githooks/pre-commit` when `retrospectives*.md` is staged — that asserts `count(^### )` equals `count(blank-line-separated records)` and that every record begins with `### `. This is a 5-line check and it is exactly the shape of `context-graph --check` (`.githooks/pre-commit:758-819`), which the repo already proved out with a 3-value exit contract. Fail-closed; the same check ships in `context_template/` so consumers get it too.

**(d) Residual judgment.** How to *repair* a coalesced entry (which text belongs to which task) — genuinely a human/agent read. Detection is arithmetic.

**(e)** **Low effort × Medium leverage.** Small, and it converts a shipped-to-consumers manual counting instruction into arithmetic — the cleanest example in this list of prose that should never have been prose.

---

### Leverage ranking

| Rank | ID | Effort × Leverage | Class | Fail-closed |
|---|---|---|---|---|
| 1 | SO-2 release pre-flight (CI-green gate) | Med × Very high | (iii) invoked, (i) reminder | Yes |
| 2 | SO-5 banned-literal sweep gate | Low × High | (i) + (ii) | Yes |
| 3 | SO-1 JSON validity gate | Low × High | (i) + (ii) | Yes |
| 4 | SO-3 gate-doc generator | Med × High | (i) | Yes |
| 5 | SO-6 portability lint | Med × High | (ii) + (i) | Yes |
| 6 | SO-4 secret-pattern parity | Low × Med-High | (i) | Yes |
| 7 | SO-7 `image:` pin completeness | Low × Med | (ii) | Yes |
| 8 | SO-8 retrospective integrity check | Low × Med | (i) | Yes |

---

## Mechanization Architecture Recommendation

**One-paragraph recommendation.** ICON should adopt a **two-tier default — arm in `.githooks/pre-commit` for fast local feedback, and make GitHub Actions the authority for anything whose correctness depends on the whole tree or on the state being pushed** — and should write every new check as a **single portable `.mjs`**, invoked from both tiers, rather than as a Bash/PowerShell pair.

**Why the two tiers, and against what.** The four options are not interchangeable, and the deciding property is *reach at the moment of need* — the meta-finding ICON-0058 named and ICON-0060/0069/0088 have each attacked with more prose. **(i) `.githooks/pre-commit`** is fast, runs on every commit, and already hosts ten gates that demonstrably work; its two defects are that it is **opt-in per clone** (`git config core.hooksPath .githooks` — documented at `CONTRIBUTING.md:52` and `README.md:247`, but a clone without it silently enforces nothing) and **bypassable with `--no-verify`**. Today nothing anywhere re-checks those ten invariants, so both failure modes are total. **(ii) GitHub Actions** is unbypassable and sees the whole tree and the pushed state — which is why SO-5 (sweep completeness) and SO-6 (portability) *must* live there: their whole value is catching a site the current commit does not touch, which a staged-file-scoped hook structurally cannot do. Its costs are latency and the ICON-0087 failure mode: a red check nobody reads is worth nothing, so any new job must be paired with SO-2's release-time consumption of `gh run` status. **(iii) skill-invoked scripts** run only when an agent remembers to invoke them, which **reintroduces the exact reach problem the offload is meant to solve** — they are appropriate only where the trigger is genuinely a workflow moment rather than a file change, which in practice means the release flow alone (SO-2), and even there the invocation should be reinforced by a pre-commit reminder armed on `plugin.json`. **(iv) harness hooks** (`SessionStart`/`PreToolUse`) are unbypassable in-session and are the right home for *runtime* controls — `guardrail-pretooluse.mjs` is correctly placed — but they are harness-specific (ADR-004 pressure: every control must work under both Claude Code and Copilot CLI, and `hooks/hooks.json:23`'s asymmetric `bash` key is already evidence of that friction) and must fail **open** (`guardrail-pretooluse.mjs:6-11`), which disqualifies them as correctness gates. The rule: **runtime safety → (iv), fail-open; repo correctness → (i)+(ii), fail-closed; workflow-moment procedures → (iii), and only with a (i) reminder behind them.**

**Cross-platform cost, and the `.sh`/`.ps1` question.** The pair convention is already a demonstrated drift source and a doubled maintenance cost: three `append-retrospective-entry.{sh,ps1}` copies plus `context-graph.{sh,ps1}` are held together only by a byte-parity gate that exists *because* they drifted, and SO-4 exists because a second duplication was left unguarded. Worse, the parity is asymmetric in *quality*: `.github/workflows/security.yml:51-54` shellchecks every `.sh` and there is no PowerShell linter anywhere (m-I-9), so half of each pair is verified and half is not. Meanwhile the `python3` the repo leans on for JSON work is not reliably present (M-I-5, verified broken on the maintainer's own Windows box), while **Node is a hard prerequisite of both harnesses and is already the runtime of both shipped hooks** — ICON-0012 already made exactly this call once, collapsing an `inject-manager-role.{sh,ps1}` pair into a single `.mjs`, and `.context/domains/hooks.md:25` documents it as the standing pattern. **A single portable `.mjs` should therefore be the default for every new deterministic check**: it is one file, one lint surface, cross-platform by construction, needs no `python3`, and can be invoked identically from a git hook, a CI job, and a skill. The implication for the existing pairs is *not* a rewrite campaign — they work, they are parity-gated, and churning them buys little. It is a **one-way door going forward**: no new `.sh`/`.ps1` pair, `.mjs` for anything new, and the existing pairs migrate opportunistically when they are next substantively edited (`context-graph.{sh,ps1}` being the natural first candidate, since SO-3 and SO-8 both want to call into it). ADR-005 must be amended first (IO-I-D / M-I-6) — as written, it rejects "a Node toolchain" on grounds two shipped Node hooks have already overtaken, and no offload proposal should have to argue past a stale ADR.

---

## Infrastructure-Specific Structural Observations

### 1. The GitLab→GitHub conversion is ~98% complete

Discovery pass results: **no `.gitlab-ci.yml` anywhere**; no `glab` invocations; no GitLab MCP config; no `.github/plugin/plugin.json` and no repo-root `plugin.json` (one manifest only, `.claude-plugin/plugin.json`); no sibling `-beta`/`-dev`/`-staging` repo. The full residue set outside `.context/` and `CHANGELOG.md` is seven hits, of which **five are legitimate**: `security.yml:1-5` (a historical port comment, correctly framed), `guardrail-pretooluse.mjs:107` and `.githooks/pre-commit:921` (the `glpat-` GitLab-PAT *detection* pattern, which must stay), and `context_template/.../style-guide-template.md:624` (a `.mr-2` CSS utility class — a false positive on the `MR` grep). The two genuine ones are m-I-1. **No release-script step assumes GitLab**; `release-plugin/SKILL.md` is clean throughout. This is a notably clean large conversion.

### 2. Every gate the repo *has* is working; the gaps are all where no gate exists

Verified live this audit: script parity byte-identical across all six copies (`.sh` and `.ps1`); `context-graph --check` clean at 49 nodes; `structural-check.sh` 5/5; all five JSON files parse; the CHANGELOG duplicate-heading `awk` (`release-plugin/SKILL.md:138`) returns empty; README's skills table is in **exact** 50/50 sync with `skills/` (zero drift in either direction — the O-V1 registration gate is earning its keep). The fail-closed contract at `.githooks/pre-commit:775-781` is correctly implemented with the `|| { …; exit 1; }` form and explicitly documents why `if …; then` would fail open. **This is the strongest argument in the report for the offload program**: where ICON has built a mechanical gate, that class of finding has gone to zero and stayed there.

### 3. Two ICON-0058 recommendations were implemented and are confirmed working

`release-plugin/SKILL.md:135-141` now carries the CHANGELOG dedup guard (ICON-0058 IO-I-C) with a runnable `awk` command and an explicit "must print nothing" assertion. `README.md:247` now carries the hooks-path instruction (ICON-0058 IO-I-D). Both are exactly what was recommended, and IO-I-C in particular is a good model for the offload program: a named failure mode converted into a one-line runnable check placed at the step where it applies.

### 4. Systemic pattern: enforcement strength is inversely correlated with consequence

Four instances, all documented above. The `append-retrospective-entry` triple (a logging helper) gets a byte-parity gate; the secret-pattern lists (credential detection) get a comment (M-I-7). `.sh` files get shellcheck in CI and locally; `.ps1` files get nothing (m-I-9). Skill registration in README is gate-enforced; command registration is not (m-I-5 context). And the release path — the only irreversible, all-consumers-at-once operation in the repo — has **zero** mechanical gates (C-I-1, C-I-2), while ordinary commits pass through ten. Gates were added where a failure was *annoying and recent*, not where a failure would be *worst*. SO-1 and SO-2 invert that.

### 5. Discovery-pass items audited but not enumerated in the brief's `## Inputs`

- `hooks/hooks.json` — audited (m-I-5).
- `hooks/guardrail-pretooluse.mjs` — audited; fail-open design is correct and well-documented (`:6-11`), the audit log never writes secret values (`:149-156`, correctly logging only the pattern *name*). **One latent concern noted for Domain 06 cross-check rather than tiered here**: `:61` lowercases `toolName` for the `isBash` test, but `:71` and `:104` test `writeTools.includes(toolName)` **case-sensitively**. If either harness ever emits a lowercase or differently-named write tool, `secret-in-write` silently never fires — a fail-open with no signal. Currently correct for both harnesses' known tool names; flagged as a fragility, not a live defect.
- `.githooks/post-commit` — audited; 6 lines, delegates to `prune-context.sh`. No issues.
- `CHEATSHEET.md`, `CONTRIBUTING.md`, `LICENSE`, `.gitattributes`, `.gitignore` — audited (m-I-3, m-I-4; `.gitattributes` feeds SO-8). `LICENSE` present, unreferenced from README — noted, not tiered.
- `context_template/README.md` — in scope per the brief's README discovery; no infrastructure findings.
- `skills/writing-skills/render-graphs.js` — the one `.js` (not `.mjs`) skill script; noted for extension consistency only, no defect.

---

## ICON-0058 Delta

### Fixed since ICON-0058

| ICON-0058 ID | Description | Evidence |
|---|---|---|
| **m-infra-3** | `release-plugin` Step 1 doc-sweep omitted the `context_template/iconrc.json` version check | **Fixed and exceeded** — promoted to a dedicated Step 6 (`.claude/skills/release-plugin/SKILL.md:145-188`) with a `latest`-tag baseline, an expected-value computation, and three explicit interpretation branches |
| **m-infra-4** | Duplicate `### Changed` heading in the `[1.19.0]` CHANGELOG block | **Fixed** — the block is gone with the 2.0.0 promotion, and the recurrence is now guarded: the `awk` dedup check at `:138` returns empty on the current `CHANGELOG.md` |
| **m-infra-5** | `append-retrospective-entry.sh:6` header said "cap (15)" while `ENTRY_CAP=10` | **Fixed** — `:6` now reads "reaches the cap (10)"; verified in the parity-canonical copy, and parity holds across all three |
| **m-infra-1 / IO-I-B** | `.mcp.json` lacked `$schema` | **Moot** — `.mcp.json` was removed entirely in the 2.0.0 GitHub-only conversion (ICON-0080). The underlying opportunity survives as IO-I-C for `hooks/hooks.json` and the two `iconrc.json` copies |
| **IO-I-C** | No CHANGELOG dedup guard in release Step 5 | **Fixed** — implemented verbatim as recommended at `:135-141` |
| **IO-I-D** | `README.md` had no hooks-path installation instruction | **Fixed** — `README.md:247` |
| **m-infra-7 / IO-I4** | No comment at the agent-file early exit noting the iconrc gate already ran | **Fixed** — `.githooks/pre-commit:60` carries the forward note and the gate now precedes the exit at `:231-233` with the ordering documented at `:57-73` |

### Still present or partial

| ICON-0058 ID | Status |
|---|---|
| **IO-I-E** | `Co-authored-by: Copilot` hardcode — **unchanged**, now at `.claude/skills/release-plugin/SKILL.md:229` (this cycle: m-I-2) |
| **m-infra-7 / IO-I5** | Short-circuit guard comments — **partial**. The gates added since (rules-index `:737-745`, context-graph `:758-790`, secret-scan `:910-917`) are extensively commented, but the original script-parity `:579` and dead-ref `:821` blocks still lack an explicit skip-condition note. Net improvement; not closed |
| **m-infra-8** | `prune-context.sh` `2>/dev/null` — **unchanged, accepted per ADR-010**; not re-tiered (this cycle: m-I-11) |
| **ICON-0058 § "no CI config present"** | **Superseded** — CI now exists (`.github/workflows/security.yml`). The prior audit's observation that "all mechanical validation is hook-enforced at commit time" is *still true of the invariants*: CI added scanning, not invariant enforcement. That gap is this cycle's central architectural finding |
| **ICON-0015 O-V4 literal-grep gate** | **Still unimplemented — now 4+ cycles.** ICON-0058 named it as the fix for sweep-incompleteness; m-I-1 is this cycle's instance. Proposed as SO-5 |

### Net-new

| ID | Description |
|---|---|
| **C-I-1** | Release flow tags and force-moves `latest` with no CI-status gate (`release-plugin/SKILL.md:244-253`); ICON-0087 documents CI red-for-many-cycles unnoticed |
| **C-I-2** | No JSON-validity gate anywhere; manifest mutated by `sed -i` (`bump-versions.sh:104`) and verified by `grep` (`SKILL.md:203-209`); the documented `python3` check is inert |
| **M-I-1** | Pre-commit header documents 3 of 10 gates in wrong order (`.githooks/pre-commit:19-40`) — regression of the ICON-0046 m-infra-2 class at 4× magnitude |
| **M-I-2** | `.context/domains/hooks.md:52-56` — "ships one hook", guardrail absent, matcher and baseline-tier drift (`:56`, `:117`) |
| **M-I-3** | `security.yml:9-54` — no `permissions:` block on three jobs running third-party containers |
| **M-I-4** | `security.yml:18,29,41` — container images tag-pinned while `uses:` are SHA-pinned; `secure-coding.md:29` Rule 12 and its grep cover `uses:` only |
| **M-I-5** | `python3` in 8 consumer-shipped files is broken on stock Windows (Store stub shadows real Python) |
| **M-I-6** | ADR-005 (`005-no-build-step.md:8,19,23,28`) materially misdescribes shipped infrastructure and reads as forbidding this cycle's offload focus |
| **M-I-7** | Secret patterns duplicated (`guardrail-pretooluse.mjs:106-114` / `pre-commit:920-928`) with prose-only sync obligation and no parity gate |
| **M-I-8** | GNU-only `grep -oP` / `sed -i` in consumer-executed paths (`upgrade-repo/SKILL.md:492-495`, `commit-conventions.md:74`) |
| **m-I-1** | GitLab residue in `.claude/skills/icon-audit/SKILL.md:124,151`; `MKT-` prefix in `commit-conventions.md:74` |
| **m-I-3** | `CONTRIBUTING.md:52` documents 4 of 10 gates |
| **m-I-4** | `CHEATSHEET.md` unreferenced anywhere; Copilot-only framing at `:6-7` |
| **m-I-5** | `hooks/hooks.json:23` asymmetric `bash` key, undocumented; no `$schema` |
| **m-I-6** | `security.yml:9-11` no `concurrency` group — every PR commit runs the suite twice |
| **m-I-7** | `security.yml:35` unpinned remote semgrep ruleset (`--config p/ci`) |
| **m-I-8** | `security.yml:23` gitleaks `--no-git` — working tree only, history never scanned |
| **m-I-9** | No PowerShell lint parity — `.ps1` files linted nowhere |
| **m-I-10** | `.github/` has only the workflow — no PR template, issue templates, CODEOWNERS, or dependabot |
