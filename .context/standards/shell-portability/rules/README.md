# Shell Portability Rules

The numbered construct rules. Each names a construct, the direction it fails in, the portable form, and the precedent that produced it. **Rules are cited by number across this repo — the numbers are immutable once assigned.** The premise these rest on, that shipped shell runs in the consumer's environment rather than the maintainer's, is in the [index](../../shell-portability.md).

One rule per file, named `NNN-kebab-slug.md` with `NNN` matching the rule number.

| Rule | Covers |
|---|---|
| [Rule 1](001-no-gawk-extensions.md) | No gawk extensions in awk blocks — 3-argument `match()` and `printf -v` |
| [Rule 2](002-prefer-pure-bash-parsing.md) | Prefer pure bash for non-trivial parsing |
| [Rule 3](003-live-test-file-mutating-blocks.md) | Live-test shell blocks that write or delete files |
| [Rule 4](004-grep-dash-leading-patterns.md) | `grep` patterns that can start with `-`, and the `if grep` guard that masks its own breakage |
| [Rule 5](005-presence-test-var-plus-x.md) | `${VAR+x}` presence tests vs `${VAR:-fallback}` |
| [Rule 6](006-powershell-replace-in-method-args.md) | PowerShell `-replace` inside a .NET method-call argument list |
| [Rule 7](007-grep-pcre-mode.md) | `grep -P` PCRE mode and its three-way fix triage |
| [Rule 8](008-sed-i-backup-suffix.md) | `sed -i` backup suffixes on BSD/macOS |
| [Rule 9](009-pass-values-as-arguments.md) | Pass values as arguments — never interpolate them into a program body |
| [Rule 10](010-port-semantics-not-shape.md) | Porting a shell construct to a Node API: match its semantics, not its shape |
| [Rule 11](011-powershell-51-strips-embedded-quotes.md) | Windows PowerShell 5.1 strips embedded `"` from a native command's arguments — the hazard attached to ADR-017's inline `node -e` default |

## Related

- Index: [shell portability](../../shell-portability.md)
- See also: [testing pattern](../testing-pattern.md) — how to live-test the constructs these rules prescribe
- See also: [secure coding](../../secure-coding.md) § Rule 6 — cross-references Rule 4's `grep` dash-argument guidance
