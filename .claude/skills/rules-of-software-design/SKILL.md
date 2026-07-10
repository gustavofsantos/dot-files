---
name: rules-of-suftware-design
description: Use when designing a softwarem either when in plan mode or execution mode.
---

# Design Defaults

- **Vertical slice first.** Build the thinnest end-to-end path for one real behavior. Hardcoding is valid to unblock the slice; generalize only when a second concrete case forces it. No utilities or infrastructure before behavior exists.
- **Interfaces at the consumer.** Define at the call site, named by what the consumer needs (`Reader`, `Notifier`) not the implementor (`UserService`, `Handler`). 1–2 methods max. Don't create one before two concrete implementations exist.
