# OOP Evaluation Criteria

## SOLID

- **SRP** — more than one reason to change? If you can't name the class without "and"/"or", it does too much.
- **Open-Closed** — can new behavior be added without editing existing classes? Type-dispatching conditionals as the extension mechanism = missing polymorphism.
- **Liskov** — is every subclass substitutable for its parent (no new exceptions, no incompatible contracts)?
- **Interface Segregation** — are classes forced to implement methods they don't use, or interfaces serving unrelated consumers?
- **Dependency Inversion** — do high-level modules depend on concretes? Internally constructed dependencies = hidden coupling; prefer injection.

## Law of Demeter

Call methods only on: `self`, objects you created, parameters, instance variables. Violation signal: more than one `.` crossing object boundaries (fluent builders excepted). Fix: Tell, Don't Ask — move behavior to the data, or add a delegation method.

## Encapsulation

Minimal public surface; constructors enforce valid initial state; mutation only through meaningful domain methods. Flag unrestricted setters and public interfaces that leak implementation rather than expose capabilities.

## Inheritance vs. composition

Inheritance only when "is-a" is genuine and stable, the subclass extends (not replaces) behavior, and the hierarchy is ≤2 levels deep. Prefer composition when behavior varies along multiple axes, the hierarchy grows to absorb variation, or you override methods to neutralize the parent.
