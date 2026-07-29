# Rule 3. Live-test shell blocks that write or delete files

Any shipped shell snippet that writes, renames, or deletes files must be live-tested against the platform-default toolchain before merge. Diff-reading is not sufficient — mawk failures produce empty output with exit 0, invisible to reviewers.

## Related

- Index: [shell portability rules](README.md)
- See also: [testing pattern](../testing-pattern.md) § The Procedure — how to discharge this obligation
