# Fixture 12: BEGIN and END on the Same Line

Both markers appear on a single line, outside any fence. This is malformed
input — there is no body to rewrite, and a single line cannot be unambiguously
treated as either an empty block or an orphan. The hook MUST abort with a
clear "same line not supported" message.

Preamble.

<!-- BEGIN: common-constraints --><!-- END: common-constraints -->

Trailing text.
