# Clean Code Heuristics

## Functions and Classes
* Smallest Possible: Functions should rarely exceed 10 lines. Classes should do the "smallest useful thing" (SRP).
* Do One Thing: A function should have only one level of abstraction. If you can extract another function, it's doing too much.
* Arguments: Prefer 0-2 arguments. 3 is a crowd; 4+ requires a very strong justification.
* No Flag Arguments: Passing a boolean to a function is a sign it does two things.

## Naming and Readability
* Intention-Revealing: Use names that reveal why a variable exists, what it does, and how it is used.   
* Newspaper Metaphor: Code should read like a news article—top-level summary at the top, descending into low-level implementation details.
* Boy Scout Rule: Always leave the code a little cleaner than you found it.
* Ubiquitous Language: Use the terminology of the business domain, not the technical implementation (e.g., processPayment instead of updateSqlTable).

## Error Handling
* Exceptions over Codes: Prefer throwing exceptions to returning error codes to keep logic and error handling separate.
