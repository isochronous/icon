## Task: ICON-0013
## Branch: feature/ICON-0013-fence-aware-pre-commit-hook
## Objective: Make the `.githooks/pre-commit` common-constraints sync hook fenced-code-block aware so it cannot destructively rewrite an agent file that illustrates the BEGIN/END marker strings inside a fenced markdown code block. Removes the doc-only mitigation shipped with ICON-0011.
## Folder: .context/tasks/ICON-0013-fence-aware-pre-commit-hook/

## Decisions
- Single awk pass with one combined state machine (`inside_block`, `inside_fence`): aligns with the GitLab issue's proposed approach and avoids the current dual-pass design (`grep -qF` precheck + awk rewrite) that would have to be made fence-aware twice. Rationale recorded in issue #11.
- Fence detection scope follows CommonMark §4.5: backtick AND tilde fences, opener may be indented up to 3 spaces, opener may have an info string (language tag) after the fence chars, closer must use the same fence char and >= the opener's run length. Edge cases enumerated in the issue body must each have a fixture.
- Fixtures committed under `.context/tasks/ICON-0013-fence-aware-pre-commit-hook/fixtures/` (per the issue's acceptance criterion). They double as documentation of which inputs the hook is guaranteed to handle.
- Doc-line removals in `.githooks/pre-commit` header comment AND `.context/domains/skill-system.md:48` are part of THIS task (issue acceptance) — they don't get split off, because removing them only makes sense once the hook is fence-aware.
- **Fix iteration (post-review):**
  - **In-block fence-leak (Critical) — Option B chosen.** When entering a real BEGIN/END block the awk resets fence state (`inside_fence = 0`, `fence_char = ""`, `fence_len = 0`) and the same reset happens on exit. The in-block drop predicate collapses to `inside_block == 1` alone — fence tracking is strictly an outside-block concern. Option B is cleaner than Option A: in-block content is replaced wholesale from the source file, so its apparent fence characters carry no semantic value and should not influence outside-block fence state. The in-block branch now also handles END_MARKER detection directly (mirroring the structure used by the outside-block marker handling).
  - **Stray END before any BEGIN (Moderate #3) — flag-based override.** Added `saw_stray_end` (set when END is seen with `inside_block == 0` outside a fence). Awk's END block now prefers `ORPHAN_END` over `OK` whenever the flag is set, so an `END … BEGIN … END` shape aborts even though begin/end counts look balanced. Pattern matches the existing orphan-flow (`saw_begin`/`saw_end` counters + decision in the awk END block) rather than introducing a mid-stream `exit 2`.
  - **Single-line BEGIN+END (Moderate #4) — distinct `SAME_LINE_MARKERS` status.** When a line outside any fence contains BOTH markers, awk sets `same_line_markers = 1` and `exit 0`s out so the END block reports `SAME_LINE_MARKERS`. The shell wrapper emits `"… has '$begin_marker' and '$end_marker' on the same line (not supported)"` — clear malformed-input message instead of misleading ORPHAN_BEGIN.
  - **Minor cleanups.** Renamed awk-internal `status` variable to `result` to avoid shadowing the shell `status`. Refined the header comment to read "fenced-code-block aware (CommonMark §4.5 block fences; inline code is still treated as content)" so the inline-code limitation is documented.
- **Test driver hardening.** When the expected outcome is `rewrite` and the fixture is in `strict_rewrite` (currently `01-plain-markers.md`, `03-mixed.md`, `10-stale-content-with-fence.md`), the driver extracts the lines strictly between BEGIN and END (exclusive of the markers) and `cmp`s byte-for-byte against `shared/common-constraints.md`. The extractor itself is fence-aware (mirrors the hook's CommonMark §4.5 logic) so an illustrative fenced BEGIN marker (like `03-mixed.md`'s) doesn't fool it.

## Key Files
- `.githooks/pre-commit` — replace `grep -qF` precheck + awk rewrite with single fence-aware awk pass. Remove the "Marker detection is line-presence-only" Behavior bullet.
- `.context/domains/skill-system.md` — remove the sentence at line 48 warning about fenced-code-block illustration risk; update to reflect the new fence-aware behavior.
- `.context/tasks/ICON-0013-fence-aware-pre-commit-hook/fixtures/` — input fixtures covering: plain markers, fenced-only markers, mixed, nested fences with differing backtick counts, indented fences, tilde fences, fence opener with language tag, marker-on-same-line-as-fence-opener edge cases.
- `.context/tasks/ICON-0013-fence-aware-pre-commit-hook/test-hook.sh` (or equivalent) — driver that runs the hook against each fixture and asserts the expected outcome (rewrite vs no-op vs abort).

## Progress
- [x] Branch + task folder + plan.md created
- [x] @architect: design fence-aware awk state machine; produce decision-table (state × line-kind → action)
- [x] @coder: rewrite `.githooks/pre-commit` per the architect's state machine; remove the Behavior bullet — single awk pass with combined fence-tracking + marker-handling + orphan detection; emits STATUS_FILE word (NONE/OK/ORPHAN_BEGIN/ORPHAN_END) consumed by the shell wrapper
- [x] @tester: author fixtures + driver script; verify all enumerated cases pass; verify orphan-marker detection remains symmetric and fence-aware — 9 fixtures cover plain/fenced-only/mixed/nested-backtick/indented/tilde/info-string/orphan-outside/orphan-inside; driver builds a per-fixture scratch repo, runs the real hook, asserts rewrite vs noop vs abort; full pass observed
- [x] @coder: remove the line-48 sentence in `.context/domains/skill-system.md`; verify wording flows — replaced the warning with a positive "fenced-code-block aware (CommonMark §4.5)" sentence that integrates into the surrounding "Sync mechanism" paragraph
- [x] @reviewer: review hook rewrite + fixtures + doc edits — found 1 Critical (in-block fence leak) + 3 Moderate (weak rewrite assertion, stray END tolerated, single-line BEGIN+END misreported) + 2 Minor issues
- [x] @coder (fix iteration): apply Option B for the Critical bug (reset fence state on block enter/exit), add `saw_stray_end` flag + `ORPHAN_END` override, add `SAME_LINE_MARKERS` status with dedicated shell error, rename awk `status` → `result`, refine header comment about inline code, add fixtures `10-stale-content-with-fence.md` / `11-stray-end-before-begin.md` / `12-single-line-begin-end.md`, strengthen driver with fence-aware byte-for-byte block extractor against the source file — 12/12 fixtures PASS, corruption sanity-check confirmed driver detects byte drift, real `agents/*.agent.md` still produces zero rewrites
- [x] @reviewer (second pass): APPROVED — all 4 prior findings closed; 2 Minor non-blocking notes flagged for future cleanup (pre-existing unquoted `$repo_root` parameter-expansion at `.githooks/pre-commit:255`; twinning hint comment for driver's fence-aware extractor)
- [x] Manager: committed artifacts (commit `411ed23` for implementation + `b8f618b` for retro entry); pushed branch; opened MR !9 closing #11 — https://gitlab.com/onedatascan/ai-platform/plugins/icon/-/merge_requests/9

## Open Questions / Blockers
- Both prior open questions resolved during execution:
  - Happy-path no-regression: verified across two reviewer-run zero-rewrite checks on the current `agents/*.agent.md` set.
  - Tilde/backtick interleave: not a concern — markers are HTML comments and BLOCK content (the synced source) cannot contain fence characters that would matter. The state machine handles each fence type independently per CommonMark §4.5.

## Constraints
- ICON is pure-content (no compile/test/package manager) — see ADR-005. Test driver must be a shell script.
- `.claude-plugin/plugin.json` is the version SSOT — see ADR-003. Hook changes do not require a version bump on their own (a release will bundle this with other changes).
- Hook must remain bash + POSIX awk (no gawk extensions) per the existing implementation style.
- After landing, the `Behavior` bullet warning in `.githooks/pre-commit` AND the corresponding sentence in `.context/domains/skill-system.md:48` MUST be removed — leaving them in place is a documented-but-unenforced acceptance failure.
