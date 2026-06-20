# Fixture 08: Orphan BEGIN Outside Fence

Only a BEGIN marker, outside any fence. No matching END. The hook MUST
abort with an orphan-marker error.

<!-- BEGIN: common-constraints -->
this block was never closed
