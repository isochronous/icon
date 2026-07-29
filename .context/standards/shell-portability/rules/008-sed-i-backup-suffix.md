# Rule 8. `sed -i` requires an explicit backup-suffix argument for BSD/macOS compatibility

GNU `sed -i` treats the backup suffix as **optional** — `sed -i 's/foo/bar/' file` edits in place with no backup. BSD/macOS `sed -i` treats the suffix as **mandatory**: it consumes whatever token comes next as that suffix. Given `sed -i "s/foo/bar/" file`, BSD/macOS `sed` reads the script as the suffix and `file` as the script — not valid `sed` syntax, so it errors out ("command garbled" or "unterminated address regex") rather than editing anything.

```bash
sed -i "s/foo/bar/" file        # BROKEN on BSD/macOS: consumes the script as the suffix, errors
sed -i.bak "s/foo/bar/" file    # correct everywhere — but leaves file.bak behind
```

Two portable forms, with a tradeoff between them:

- **`sed -i.bak "s/…/…/" file`** — works identically on GNU and BSD because the suffix is always explicit. Simple, but leaves a stray `file.bak` in the consumer's working tree that the skill must remember to clean up (or that pollutes `git status`).
- **Temp file + `mv`** — `sed "s/…/…/" file > file.tmp && mv file.tmp file || { rm -f file.tmp; exit 1; }` — avoids `-i` entirely, so the GNU/BSD divergence never applies, and leaves no backup artifact **provided the trailing cleanup runs**. Slightly more verbose, and both halves are load-bearing. The `mv` must be conditional on the `sed` succeeding (`&&`, not a separate statement): the redirect only ever writes to `file.tmp`, never to `file` itself, so a failed `sed` cannot truncate the original — but it can leave a partial or empty `file.tmp` behind, and an unconditional `mv` would then overwrite the good original with that broken temp file. The trailing `|| { rm -f file.tmp; exit 1; }` is what removes that leftover and preserves the failure; without it, "leaves no backup artifact" is false on the failure path. **Do not shorten it to `|| rm -f file.tmp`**, the obvious-looking fix: `rm -f` itself succeeds (with or without a file to remove), so its exit status becomes the whole list's and the construct exits 0 even though the `sed` failed and the edit never happened — under `set -euo pipefail` (how every shipped `.sh` in this repo runs) the script then continues past the failed edit as if it had succeeded.

(ICON-0093: `sed -i "s/…/…/" .context/iconrc.json` in `skills/upgrade-repo/SKILL.md` used the no-suffix GNU-only form.)

## Related

- Index: [shell portability rules](README.md)
- See also: [testing pattern](../testing-pattern.md) — this rule's own cleanup fence shipped fail-open for a full review round until a reviewer ran it
