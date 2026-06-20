# Fixture 04: Nested Backtick Fences

A `` ``` `` fence inside a ```` ```` ```` fence. CommonMark says the inner
3-backtick line is content of the outer 4-backtick fence — not a closer.
The markers, which sit inside the inner illustration, MUST be treated as
literal text. The hook MUST leave this file unchanged.

````markdown
Outer fence content. Here is an inner triple-backtick example:

```markdown
<!-- BEGIN: common-constraints -->
nested example content
<!-- END: common-constraints -->
```

Still inside the outer fence.
````

Trailing text outside both fences.
