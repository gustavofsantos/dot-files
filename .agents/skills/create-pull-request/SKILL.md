---
name: create-pull-request
description: Create a GitHub pull request with an executive-oriented description focused on the problem and why the change solves it, using the repository's PR template when present.
---

# Create Pull Request

1. Gather the base branch, the commits since base, and the full diff. Read the diff to
   understand the change, but don't narrate it in the PR.
2. Search the local knowledge base (`${ENGINEERING_HOME:-$HOME/engineering}`) for why the
   work was done: branch name, commit messages, touched modules.
3. Use the repository's PR template if one exists. Put the executive content in its opening
   section, or in a short paragraph before a leading checklist. Otherwise use
   [references/default-template.md](references/default-template.md).
4. The opening answers three things: the problem that existed, why this approach solves it,
   and the outcome. Fill the other sections from the diff and commits.
5. Title: at most 70 characters, imperative, no trailing period, describing the outcome
   rather than the mechanism.
6. **Scrub** the title and body. Nothing local-only reaches GitHub:
   - no filesystem paths
   - no bare local issue ids
   - no `[[wikilinks]]`
   - no author-only jargon
   - no code symbols unless they are meaningful publicly

   PR and issue URLs, external tickets, and public links are fine.
7. Show the title and body and wait for confirmation. Use a draft PR for work in progress or
   on request. Never push, merge, close, or label without an explicit instruction.
