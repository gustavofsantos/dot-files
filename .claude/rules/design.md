# Design Defaults

## Vertical slice first

Build the thinnest path through all layers that delivers one real behavior end-to-end. Hardcoding is valid to unblock the slice. Generalize only when a second concrete case forces it. Never build utilities, infrastructure, or helpers before behavior exists.

## Interfaces

Define interfaces at the consumer's call site, not next to the implementation. Name them by the behavior the consumer needs (`Reader`, `Notifier`, `Validator`) — not by the implementor's role (`UserService`, `Manager`, `Handler`). One or two methods is the ideal surface; every extra method burdens every future implementor.

Do not create an interface before two concrete implementations or a clear substitution need exist.
