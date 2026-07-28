# Split Exemptions

The folder-split gates exist to keep **live guidance** findable: breaking a sprawling instructional doc into topic files gets a reader to the current rule faster. Some `.context/` files are not guidance at all, and against those the gates have nothing to act on. **One test decides it** — the historical-record and distributed-template arms that preceded it are worked cases, not separate rules.

## The Test

> **Does the file instruct, or does it record?**
>
> A file that tells an agent what to do — a rule, a convention, a procedure, or a description of a subject written so an agent can act on it — is **instructional**, and the gates apply in full.
>
> A file that states what happened, what was decided, or what exists — a **historical record** (a log, a snapshot, a decision) or an **operational record** (a folder's index, a description of what this repo contains and how it is configured, a scaffold that defines a required shape) — is a **record**, and the gates do not apply to it at any size.

The sharpening question, when a file sits on the line: **could this file be rewritten from scratch, better, with nothing lost?** A standards file can be — rewrite `error-handling.md` more clearly tomorrow and the rule survives, because the file *is* only the rule. A record cannot: rewriting destroys a chronology, a decision's warrant, or a file's correspondence with what it indexes. That loss is what the exemption protects.

**Normative force does not make a file instructional.** An ADR's Decision section binds, and the ADR is still a record — what binds is *that the decision was taken*, on a date, against named alternatives, by someone recording what they knew then. Preserving that event is the file's job, and a standards file carries no comparable warrant.

**Scope: this test governs `.context/` only.** No file under `skills/` or `.claude/skills/` is ever a record — a skill exists to tell an agent what to do, which is what invocation means — so ADR-016's byte caps admit no exemption from it. An oversized companion is not "reference material, therefore a record"; see **ADR-016, skill hot path / cold path**, which states the boundary from the other side.

## Why This Is Not a Loophole

The size rule earns its keep against an *instructional* file: it costs context on every read and buries its own rules, so a topic split is a real remedy. Against a record that remedy is unavailable or destructive, and the cost it addresses is smaller: a record's length tracks accumulation rather than authorial sprawl, and it is consulted by lookup rather than read end to end.

**Gate (2) independently fails for the historical arms.** A chronological log has zero peer topic sections; an ADR's `##` sections are the template's facets of one decision, not discrete topics. There the exemption is not bolted onto the gate — it is the gate's own "discrete topic" precondition restated so an author can apply it without measuring first.

**That coincidence stops at the operational arm.** `overview.md`, `rules-index.md` and `META.md` carry sections that *would* divide — "Tech stack" and "Marketplace consumption" are unrelated topics — so they rest on the record test alone. Latent, not live: at 4,088 / 5,919 / 7,027 B (2026-07-27) none is near the 16,000 B gate (1) that must fire first. Do not offer the coincidence as a warrant where it does not hold.

## Worked Cases

Illustrative, not a member list — apply the test, do not look the file up here. The one file the test does not decide is flagged below.

| File | Record of | Why the gate has nothing to act on |
|---|---|---|
| `retrospectives.md`, `retrospectives-archive.md` | what happened, in date order | Entries accumulate chronologically and are never reorganized; there is no topic axis. Exempt **even though it is skimmed at Session Start for live guidance** — readership is not the axis. |
| A task's snapshot artifact (e.g. `word-count-snapshot.md`) | what was measured, then | A point-in-time state; rewriting it makes it a different measurement. |
| Any `decisions/NNN-*.md` ADR | a decision, its date, and the alternatives weighed | Sections are the ADR template, and the `NNN-` number is immutable once assigned, so there is no folder to split into. Amendments and supersession are edits *to the record* — which is why an "append-only" test would wrongly miss ADRs. (`context-graph` calls `decision` a *content* kind; graph participation asks whether a file needs `## Related` edges, not whether it instructs.) |
| `README.md` at any depth | what this folder contains | A folder index; `context-graph` classifies it `folder-index`, a non-content kind. Splitting an index of a folder into a folder of indexes is incoherent. |
| `overview.md`, `rules-index.md` | what this repo contains, and where its rules live | Operational records — they state this instance's composition and where its rules live, not what a reader should go and do. Splitting one yields a folder of fragments of one description. |
| `workflows/task-plan/base.md` and its `phase-*.md` siblings | the required shape of a task plan | A fixed shape distributed by the plugin template — the shape *is* the content. Confirm one by resolving the template root with `find-context-template` and checking `$TEMPLATE_DIR/context/<same relative path>`; a bare `context_template/` path is meaningless inside an installed repo. |

**`META.md` is exempt, and this test does not derive it.** Its own first line says it explains *when and how* to update `.context/`; on the test alone it is instructional and gated. It is exempt on a separate ground: it is not authored guidance at all. The initializer copies it verbatim from the plugin template and forbids customization (`context-specialist-impl-root` Step 12), so its content is fixed upstream and splitting it diverges the repo from the file that `cp` writes. Stated as an exception, not folded into the table — a member an axis does not derive is the signal `skill-decomposition/boundary-axis-selection.md` names.

## Not Exempt

Topic-organized guidance: `domains/`, `standards/`, `workflows/` (other than the task-plan scaffold above), `architecture/`, `testing/`, `styling/`. These are what the gates exist for.

- **Dates do not make a file a record.** A `domains/` file with dated subsections under topic headings is still a set of subjects, and the subjects still divide.
- **A template origin does not make a file a record.** Most template-seeded content is a *seed* the consumer replaces, diverging by design on day one. Only files the initializer copies verbatim and forbids customizing are exempt on that ground.
- **A router is not an index.** "An index" above means a folder's own `README.md` — what `context-graph` classifies `folder-index`. A `<name>.md` router sitting beside its own `<name>/` directory under `standards/` is topic-organized guidance and is gated; the split's own output shape, `<name>/README.md`, is what would convert it into one.
- **"It feels historical" is not the test.** Prose tone, narrative voice, and record-keeping language elsewhere about the folder carry zero weight. Ask the two questions above honestly.

## Derivation, and one reversal recorded

ICON-0088 first drew this boundary on **readership**, then re-axised it to **shape** — time-ordered vs topic-ordered (`skill-decomposition/boundary-axis-selection.md`). Shape was right in direction but not general: it needed a carve-out declaring ADRs non-exempt unless superseded, and left `README.md` uncovered. A rule needing a special case for a member of its own domain signals a wrong axis, so ICON-0095 generalized it to record-vs-instruction.

**This reverses ICON-0088's ruling that "living in `decisions/` does not itself confer the exemption."** Live ADRs are now exempt: the rule an ADR carries is inseparable from the record of its having been decided. Recorded so the earlier position is not re-proposed as a fix.
