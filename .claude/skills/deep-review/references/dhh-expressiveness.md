# DHH — Expressiveness & Conceptual Compression

- **Convention over configuration** — penalize hand-rolled re-implementations of what the framework/ecosystem provides (routing, persistence, validation, serialization). Reward code that embraces its abstraction layer.
- **Conceptual compression** — a good abstraction shrinks the caller's cognitive surface; they use it as a black box. An abstraction that *expands* the caller's required knowledge is leaky indirection — delete or redesign it.
- **Programmer happiness** — reading the code should feel like prose, not deciphering a machine.

## Comments as design smells

A comment explaining *what* the code does means the code failed to explain itself — extract a method whose name is the comment, then delete it.

- **Keep:** *why* a non-obvious decision was made, external-constraint references (legal/spec/third-party quirk), public-API docstrings.
- **Remove:** restating what the code does, section-header comments inside a method (the method needs splitting), `TODO` without a ticket.
