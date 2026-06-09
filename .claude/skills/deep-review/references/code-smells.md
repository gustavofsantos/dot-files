# Code Smells Catalog — Kerievsky / Fowler

Hunt these in the core change. For each: the tell → the refactor.

- **Primitive Obsession** — business concepts as raw strings/ints/floats → extract a Value Object that owns validation + behavior (e.g. `Money`).
- **Feature Envy** — a method calls another object's getters to compute what belongs to that object → move the method to the data it operates on.
- **Data Clumps** — the same parameter group recurs across signatures → extract a class for the cluster (`DateRange`, `TimeSlot`).
- **Message Chains** — `a.b.c.d` navigation through an object graph → apply Law of Demeter; introduce a delegating method that hides the traversal.
- **Inappropriate Intimacy** — two classes reach into each other's internals / depend bidirectionally → extract a shared concept, or move behavior to the data owner.
- **Speculative Generality** — abstract class with one impl, unused hooks, "future flexibility" interfaces → inline/delete; design for what's known now (Beck Rule 4).
- **Long Method, mixed abstraction levels** — orchestration interleaved with low-level detail → extract each level into a named method so the top reads as a narrative.
