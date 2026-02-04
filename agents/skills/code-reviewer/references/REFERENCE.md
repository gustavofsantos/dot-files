# Engineering Quality & Code Smell Reference

## 1. The Engineering Sense of Quality
Quality is not "aesthetic purity" or "luxury features". It is defined by:

* **Useful Function:** Does it solve the user's problem? 
* **Reliability:** Does it work consistently? 
* **Low Cost:** Is it affordable to build and run? 
* **Maintainability:** Is it easy to change later? 

## 2. Common Code Smells to Spot

### A. Obscured Intent
* **Incomprehensibly Concise:** Code that is too "clever" or short, hiding individual concepts and making naming impossible.
* **Speculative Generality:** Creating abstractions for "future use cases" that don't exist yet, which increases cost without adding value.
* **Blank Line Signals:** Blank lines often signify a "change of topic," which suggests the method has multiple responsibilities and should be split.

### B. Structural Fragility
* **Primitive Obsession:** Using strings or numbers to represent meaningful domain concepts (e.g., using a `string` for a `PartID`), which lacks semantic checking.
* **Chained Dependencies:** Violating the **Law of Demeter** by reaching through objects (e.g., `a.b.c.d()`). This creates tight coupling.
* **Data Clumps:** Groups of data that always appear together should likely be a class.

### C. Duplication & Logic
* **Masked Responsibility:** Methods that know too much about *how* something is done (like exact lyrics) rather than *who* should do it.
* **Conditionals over Polymorphism:** Large switch statements or if/else chains that could be simplified by injecting different "role players".

## 3. Refactoring Principles
* **Shameless Green:** It is acceptable to use "unambiguous abstractions" (like hardcoding a few examples) to reach a passing state quickly before generalising.
* **The Flocking Rules:** Fix the easy problems first, work horizontally across differences, and only refactor while under the safety of green tests.
* **Inversion of Control:** Instead of an object knowing its context, inject dependencies so the object becomes independent of its environment.

## 4. The Reviewer's Aesthetic
* **The Beacon of Light:** Code should be arranged to send signals to "hapless" future readers searching for clarity.
* **Wishful Thinking:** Design APIs based on what the sender *wants*, not what the receiver currently *does*.

## 5. Few-Shot Example: Primitive Obsession
* **Smell:** `function saveOrder(id, qty) { ... }` — Primitives have no meaning or constraints.
* **Refactor:** `function saveOrder(orderId, orderQuantity) { ... }` — Using specific types adds semantic checking to data flow.

## 6. Operational Principles
* **Fast Feedback:** Keep the "inner loop" of coding tight. Slow tests lead to fewer runs and more defects.
* **Clean Start Protocol:** Before starting, ensure zero untracked files, a clean build, and all tests passing.
* **The Law of Demeter:** If you want something from an object, just ask it. Don't reach through it.
