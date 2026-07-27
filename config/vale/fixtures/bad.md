# Spec draft (violations)

An acceptable value is approximately 10, and this is sufficient for the majority of cases we have seen so far in production over the last six months.

We utilized a number of additional checks prior to merging; this caught most regressions early.

Don't skip this step, it's not optional.

The config can be adjusted by the operator, and the cache is cleared by the daemon on restart.

Make sure the feature flag is enabled before you deploy this change to production.

We colour-code the logs so operators can triage issues faster (e.g., red for errors, yellow for warnings, etc.) and this behaviour is documented elsewhere.

This paragraph has too many sentences on purpose. Sentence two. Sentence three. Sentence four. Sentence five. Sentence six. Sentence seven pushes it over the limit.

The frontend calls the API first. Later, the front end retries on failure.
