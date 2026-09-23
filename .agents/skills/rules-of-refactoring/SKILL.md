---
name: rules-of-refactoring
description: After green tests and a behavior commit, flock alike code into a separate refactor commit
---

# Rules of Refactoring

Start only after tests are green and the behavior change is committed. If it isn't committed,
commit it first. Then apply Sandi Metz's flocking rules in small steps. Keep the scope to the
just-changed files and their direct neighbors. Keep tests green after every step and leave
asserted outcomes unchanged. If a test must change, you have left refactoring. Stop before you
invent a speculative abstraction.

Commit only the refactor diff as `refactor:` (`refactor(<JIRA>):` when the branch names a
key). Never amend the behavior commit.
