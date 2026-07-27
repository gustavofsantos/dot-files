# Spec draft (clean)

A permitted value is about 10. This is enough for most cases we have seen in production over the last six months.

We used some extra checks before merging. This caught most regressions early.

Do not skip this step. It is not optional.

The operator can adjust the config. The daemon clears the cache on restart.

Make sure that the feature flag is enabled before you deploy this change to production.

We color-code the logs so operators can triage issues faster (for example, red for errors and yellow for warnings). This behavior is documented elsewhere.

This paragraph stays under the limit. Sentence two. Sentence three. Sentence four. Sentence five. Sentence six.

```python
def example():
    # code blocks should not trigger prose rules, even with semicolons; like this one
    pass
```

Inline code like `don't_trigger_here()` should also be skipped by Vale's default markdown scoping.

The indicator should be red. Short "-ed" lookalikes like this must not be flagged as passive voice.

- The first item ends with a period.
- The second item also ends with a period.
- The third item ends with a period too.
- The fourth item ends with a period.
- The fifth item ends with a period.
- The sixth item ends with a period.
- The seventh item ends with a period, testing the boundary.

