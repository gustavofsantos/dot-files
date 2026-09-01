---
name: rules-of-software-design
description: Steer a change toward the smallest vertical design with boundaries justified by real consumers.
disable-model-invocation: true
---

# Design Defaults

- **Vertical slice first.** Build the thinnest end-to-end path for one real behavior.
  Generalize only when current behavior or a known next case requires it. Do not build
  utilities or infrastructure before the slice needs them.
- **Justified boundaries.** Introduce an interface when a real consumer needs
  substitutability or isolation. Define it in the consumer's vocabulary and keep it no
  wider than that consumer needs.
