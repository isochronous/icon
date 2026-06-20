# Fixture 11: Stray END Before a Valid BEGIN/END Pair

A `<!-- END: common-constraints -->` marker appears outside any fence
BEFORE any BEGIN. Even though a later BEGIN+END pair would otherwise look
balanced, the leading orphan END means the file is structurally broken.
The hook MUST abort.

<!-- END: common-constraints -->

Some text between.

<!-- BEGIN: common-constraints -->
STALE PLACEHOLDER — would have been replaced if the file were well-formed.
<!-- END: common-constraints -->

Trailing text.
