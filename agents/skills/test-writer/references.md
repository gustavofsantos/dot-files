# Comprehensive Testing & Refactoring Reference

## 1. The Fast Feedback Principle
* **Engineering Quality:** Quality is defined by useful function, reliability, low cost, and easy maintainability.
* **The Tight Loop:** There is no room for slow tests in the inner loop of coding.
* **Microtests:** Prioritize tests that run in sub-one-minute periods, ideally less than 10 seconds.
* **Continuous Testing:** Use "auto-testers" that run tests whenever a file is saved to reduce the search space for defects.

## 2. The TDD Mantra (Red/Green/Refactor)
1.  **Red:** Write a test for a wishful requirement. It must fail.
2.  **Green:** Write the "Shameless Green" implementation—the minimum necessary code to pass, even if it uses hard-coded values initially.
3.  **Refactor:** Improve the design only when tests are green. Look for "code smells" like blank lines (signifying multiple responsibilities) or duplicated logic.

## 3. Test Construction: Arrange-Act-Assert (AAA)
Organize every test into three distinct sections to ensure readability and intent:
* **Arrange:** Set up inputs and preconditions.
* **Act:** Execute the specific method or behavior under test.
* **Assert:** Verify that the actual result matches the expected outcome.

## 4. Refactoring & Design Patterns
* **Avoid Primitives:** Instead of generic strings or numbers, use domain-specific classes (e.g., `PartIdentifier`) to add semantic checking and prevent data flow errors.
* **Listen to Change:** Do not abstract too soon. Only refactor existing code to be "open" to a new requirement once that requirement is clearly understood.
* **Fakes and Roles:** When using "fakes" to decouple tests from a context, programmatically verify that the fake correctly implements the required API (role-playing).
* **The Law of Demeter:** Loosen coupling by designing conversations that embody what the message sender wants, rather than chaining dependencies.

## 5. Clean Start Protocol
To avoid unnecessary struggle, never start work without these 5 steps:
1. **Git Status:** Confirm zero untracked files.
2. **Git Pull:** Ensure you are working on the current version of the code.
3. **Update:** Use the project's dependency tool (npm, pip, poetry, etc.) to keep the environment current.
4. **Build:** Run a clean build to remove artifacts from prior work.
5. **Test:** Confirm all existing tests pass before you type a single line of new code.
