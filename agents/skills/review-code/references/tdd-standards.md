# TDD and Testing Standards

## The Three Laws of TDD
1. The First Law: You may not write any production code until you have written a failing unit test.
2. The Second Law: You may not write more of a unit test than is sufficient to fail; and not compiling is failing.
3. The Third Law: You may not write more production code than is sufficient to make the currently failing unit test pass.

## F.I.R.S.T. Principles of Unit Testing
* Fast: Tests should run in milliseconds to prevent developers from skipping them.
* Independent: Tests should not depend on each other or shared state.
* Repeatable: Tests must yield the same result in any environment (local, CI, prod).
* Self-Validating: Tests should have a clear binary pass/fail output without manual inspection.
* Timely: Unit tests are written just before the production code.

## Structural Patterns
* AAA Pattern: Every test should follow Arrange (set up), Act (trigger behavior), and Assert (verify).
* Single Responsibility: Each test should focus on a single concept and ideally use a single assertion.

