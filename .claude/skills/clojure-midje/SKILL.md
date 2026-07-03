---
name: clojure-midje
description: Guidance for editing Midje-based Clojure test files (test/**/*.clj, *_test.clj, *-test.clj). Activate only when a Clojure test file uses Midje — requires midje.sweet, or uses fact/facts/provided/=>.
---

When a Clojure file is a Midje test file, prefer Midje idioms over clojure.test idioms.

Detection:
- Strong signal: namespace requires `midje.sweet`.
- Secondary signals: use of `fact`, `facts`, `provided`, `against-background`, `=throws=>`.

Rules:
- Keep tests in Midje style; do not rewrite to `deftest`, `testing`, or `is` unless explicitly requested.
- For normal expectations, use `=>`.
- For exception assertions, prefer `=throws=>`.
- If the exception payload matters, use a predicate/checker approach that inspects the exception object or `ex-data`.
- For local mocks/prerequisites used by one fact, prefer `provided`.
- For shared prerequisites across checks or nested facts, consider `against-background`.
- Be careful: wrapping `against-background` only affects nested facts.
- Inside a single `fact`, the non-wrapping `against-background` form is often the right way to share prerequisites across multiple checks.
- Preserve existing Midje structure and wording when editing.

Examples:

```clj
(fact "computes value"
  (sut/run 2) => 4
  (provided
    (sut/dependency 2) => 3))

(fact "throws on invalid input"
  (sut/run nil) =throws=> RuntimeException)

(fact "checks exception details"
  (sut/fail) => (throws clojure.lang.ExceptionInfo
                        #(= :bad-input (-> % ex-data :reason))))

(fact "shared background for one fact"
  (sut/a 1) => 10
  (sut/b 1) => 20
  (against-background
    (sut/common 1) => 9))
```
