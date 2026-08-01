# Rule 10. Porting a shell construct to a Node API: match its semantics, not its shape

A shell test and the Node call that *looks* like it are not interchangeable. Reach for the API whose behaviour matches the construct being replaced, and check that **per construct** — there is no blanket mapping from "shell filesystem test" to "`fs` idiom", and adopting one silently changes what the program decides.

The case that produced this rule is enumerating immediate subdirectories:

| Construct | dot-entries | symlinks/junctions |
|---|---|---|
| shell `for d in */` + `[ -d "$d" ]` | **excluded** | **followed** |
| `readdirSync(cwd,{withFileTypes:true})` + `e.isDirectory()` | **included** | **not followed** |

They read as equivalent and are **inverted on both axes**. The `*/` glob never expands a leading dot, and `[ -d ]` stats *through* the link; a `Dirent` is built from the raw directory entry, so it reports the dot-directory and reports the link as a link, not as its target. The faithful port is therefore two pieces, not one: a **name filter** standing in for the glob, plus a **`statSync`-based `isDir()`** standing in for the test, which follows links exactly as `[ -d ]` does.

```javascript
entries.filter((e) => e.isDirectory())                          // BROKEN: counts .github/ as a module, and
                                                                // drops a module reached through a junction
entries.map((e) => e.name)
       .filter((name) => !name.startsWith(".") && isDir(name))  // correct: glob semantics, then [ -d ] semantics
```

**For other constructs the equivalence is real, which is what makes this non-obvious.** `find . -maxdepth 1 -name '*.sln' -type f` **does** correspond to `dirent.isFile()`: `find -name '*'` matches leading dots (unlike a glob), and `-type f` does not follow links (unlike `[ -f ]`). So a `find`-based probe ports to a dirent faithfully while a glob-based one does not — check each construct rather than adopt one mapping for the whole file. The asymmetry runs inside a single original: a **named** `[ -f "$x" ]` test *does* follow links, so it ports to `statSync`, not to a dirent. Two probes in one script can need two different Node idioms.

**A passing fixture set does not discharge this.** The defect below survived eleven fixtures, because in none of them was the divergent element *decisive* — a dot-directory alongside two real modules yields `multimodule` either way, so the bug only bites when the dot-directory is the tipping vote. **Design fixtures so the divergent element changes the answer**, not merely so it is present; and diff the port against the extracted pre-migration original (`git show HEAD:<path>`) rather than against prose.

(ICON-0098: the `readdirSync` + `isDirectory()` filter in `skills/icon-init/scripts/detect-repo-type.mjs` Step 2d shipped a false `multimodule` when `.github/package.json` was the tipping vote, and a false `project` when a module sat behind a junction. That file's Step 2d comment block states the inversion in place; a follow-on audit of every other probe found a third instance the review had not named.)

## Related

- Index: [shell portability rules](README.md)
- See also: [Rule 9](009-pass-values-as-arguments.md) — the other half of reviewing a language port: quoting is that rule, semantics is this one
- See also: [executable content](../../skill-decomposition/executable-content/README.md) — the authoring spec for the migrations this rule governs
