# Shell Portability for Shipped Skills

Bash code shipped inside a `skills/*/SKILL.md` (or installed via `.claude-plugin/`) runs in the consumer's environment, not the maintainer's. Debian, Ubuntu, WSL, and Alpine all ship **mawk** as the default `awk`, not gawk. Code that compiles on a maintainer's gawk-equipped Mac can silently produce zero output — or silently delete files — on every consumer machine in the field.

The body of this standard lives in topic-scoped sub-files under [`./shell-portability/`](./shell-portability/); this file is the index.

## Topic Index

| Sub-file | Covers |
|----------|--------|
| [rules/](./shell-portability/rules/README.md) | The numbered construct rules 1–10, one per file: gawk extensions in awk blocks (1); pure-bash parsing (2); live-testing blocks that write or delete files (3); `grep` patterns that can start with `-`, and the `if grep` guard that masks its own breakage (4); `${VAR+x}` presence tests vs `${VAR:-fallback}` (5); PowerShell `-replace` inside a .NET method-call argument list (6); `grep -P` PCRE mode and its three-way fix triage (7); `sed -i` backup suffixes on BSD/macOS (8); passing values as arguments rather than interpolating them into a program body (9); matching a shell construct's semantics rather than its shape when porting it to a Node API (10) |
| [testing-pattern.md](./shell-portability/testing-pattern.md) | The live-fixture procedure and why a contents check beats an exit-code check; that a prescribed idiom must be executed rather than reviewed; how a portability fix can trade a loud failure for a quiet one; and the four measured shapes of PowerShell's fail-open generator behaviour |

## When to consult which file

- **Writing or reviewing a shell construct in a hook, script, or shipped skill block** → `rules/`, one file per rule. Rules are cited by number throughout this repo (`Rule 4`, `Rules 1-2`); the numbers are immutable, match each file's `NNN-` prefix, and must never be renumbered.
- **About to merge a shell snippet that writes, renames, or deletes files** → `rules/` Rule 3 for the obligation, then `testing-pattern.md § The Procedure` for how to discharge it.
- **Correcting a portability defect, or copying an idiom this standard prints** → `testing-pattern.md` before claiming the fix works. The corrected form is a hypothesis until it runs in the exact shape printed, and a fix can trade a loud failure on one platform for a silent one on another.
- **Porting shell from one language or interpreter to another** → `rules/` Rules 9 and 10 together — Rule 9 for quoting (a value interpolated into a program body is parsed as source, and the safe construct in the outgoing language can be the unsafe one in the incoming language), Rule 10 for semantics (an API that mirrors the construct's *shape* can be inverted against its *behaviour*).
- **Writing PowerShell that reports success or failure** → `testing-pattern.md § PowerShell Is a Fail-Open Generator` for the four measured shapes, then `rules/` Rule 6 for the `-replace` parsing trap.

## Related

- See also: [secure coding](secure-coding.md) § Rule 6 — cross-references this standard's `grep` dash-argument guidance
