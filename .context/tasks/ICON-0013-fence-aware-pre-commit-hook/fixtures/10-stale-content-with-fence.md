# Fixture 10: Stale In-Block Content Containing a Fence

Real markers outside any fence. The stale content between them contains a
`` ``` `` fence opener and closer. The hook MUST drop the entire stale body
(fence and all) and emit the source content verbatim. Regression guard for
the in-block fence-leak bug: prior to the fix, a fence inside the to-be-
replaced block flipped fence state, and subsequent stale lines fell through
to output.

Preamble.

<!-- BEGIN: common-constraints -->
STALE PLACEHOLDER opening line.
```
stale fenced content
that should be dropped entirely
```
STALE PLACEHOLDER line after fence — also must be dropped.
<!-- END: common-constraints -->

Trailing text.
