# Boundary Axis Selection — When a Special Case Signals the Wrong Axis

When drafting an exemption or classification rule (which files are exempt from a gate, which items belong to which tier, …), the axis the boundary is drawn on matters more than the boundary's placement on that axis.

## The Rule

If a rule needs a special case to explain **one member of its own domain**, the chosen boundary axis is probably wrong — re-axis before adding the carve-out, rather than patching the axis with a property list for the awkward member.

**Diagnostic**: does the exemption test require a multi-property special case (three or more independent properties, each true only for this one member) just to justify why a single file/item is "different enough" to exempt? That is the signal. A correctly-chosen axis classifies every member — including the awkward one — with the same single test, no per-member patch required.

**Secondary signal, once re-axised**: prefer a boundary test that **coincides with a mechanism the surrounding system already enforces mechanically**, over one that is orthogonal to any existing mechanism. A test that happens to line up with a precondition another gate already checks is more robust (two independent checks agreeing) than a test that adds a wholly new, unverified axis of judgement.

## Precedent (ICON-0088)

The `.context/` folder-split rule's historical-record exemption was first drafted on **readership** — "does an agent read this file to decide what to do *now*, or to look up what was true *then*?" `.context/retrospectives.md` is genuinely both: it is skimmed at Session Start for live guidance, and it is a chronological log. Readership couldn't classify it cleanly, so the first draft added a three-property special case (an entry cap + an append-only script + a "never hand-edit" rule) to explain why the file was exempt anyway — and shipped a self-contradiction (asserting the file was "not exempt, but governed instead by a different cap" — two claims that can't both be true of the same gate).

The maintainer's ruling re-axised the test to **shape**: is the file's organizing axis *time* (entries appended in sequence, never reorganized) or *topic* (sections grouping subject areas)? Shape resolves every case — including `retrospectives.md` — with one test and no special case. It also turned out to **coincide with a mechanism the gate already enforces**: a chronological log has zero peer `## ` sections, so the gate's own "≥ 3 peer-level sections" precondition independently blocks the split anyway. Readership was orthogonal to any mechanism in the system; shape was not.

## Anti-Rationalization

| Excuse | Reality | Correct Action |
|---|---|---|
| "This one file just needs a bit of extra explanation to fit the rule" | A multi-property carve-out for a single member is the symptom of a wrong axis, not a reasonable accommodation. | Ask what axis would classify this member the same way as every other member, with no patch. |
| "The new axis is basically equivalent, so it's not worth re-deriving" | An axis orthogonal to any enforced mechanism is unverified judgement every time it's applied; a coinciding axis gets a second, independent check for free. | Prefer the axis that lines up with a precondition the system already checks mechanically. |

See `context-document-guidelines § Folder Split Rule → Split Exemptions` for the shape-based test this precedent produced.

## Related

- Index: [skill-decomposition](../skill-decomposition.md)
