# English Profile

Use STE-inspired principles without claiming ASD-STE100 compliance.

## Core rules

1. Put one main idea in each sentence.
2. Prefer explicit subjects.
3. Prefer strong verbs over noun-heavy constructions.
4. Prefer active voice when the actor matters.
5. Keep subject, verb, and object close together.
6. Avoid ambiguous pronouns.
7. Use one term for one concept.
8. Define unfamiliar acronyms on first use.
9. Avoid idioms, metaphors, slang, and decorative language.
10. Remove words that do not change meaning.
11. Prefer concrete values over vague terms when evidence exists.
12. Keep list items grammatically parallel.
13. Avoid deeply nested subordinate clauses.
14. Prefer direct instructions and statements.
15. Keep technical vocabulary when it is more precise than a simpler alternative.

## Sentence length

Prefer short sentences, but do not use a hard word limit.

A sentence above roughly 25-30 words is a signal to inspect, not an automatic error.

Do not split a sentence if splitting damages precision or creates repetition.

## Prefer direct verbs

Prefer:

- `implement`
- `validate`
- `configure`
- `measure`
- `compare`
- `decide`

over unnecessary nominalizations such as:

- `perform the implementation of`
- `carry out the validation of`
- `make a comparison of`

## Avoid false simplicity

Do not replace precise technical terms with vague words.

Bad:

`The system talks to the database.`

Better:

`The service queries PostgreSQL.`

when that statement is supported.

## Pronouns

Rewrite `it`, `this`, `that`, `they`, and similar references when the antecedent is ambiguous.

Prefer:

`The worker retries the job after the timeout.`

over:

`It retries it after this happens.`

## Absolute language

Treat these words with caution:

- always
- never
- ensure
- guarantee
- impossible
- safe
- secure
- optimal
- best

Use them only when the claim is actually supported.
