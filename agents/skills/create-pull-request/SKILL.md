---
name: create-pull-request
description: >
  Create a GitHub pull request with an executive-oriented description that focuses on the
  problem and why the change solves it. Uses the repository's PR template when present.
  Triggers on: "create a PR", "open a pull request", "make a PR", "submit PR",
  "/create-pull-request", or any explicit request to open a pull request for the current branch.
---

Create a GitHub pull request with a clean, executive-oriented description built from the
branch's commits and local knowledge base context.

> **Citation rules suspended for PR output.** Local-only identifiers such as `[[wikilink]]`
> citations and bare issue numbers (`NNN`) must not appear in the PR title, body, or any
> field sent to GitHub. Allowed references include other PR URLs, GitHub issue URLs,
> external tracker tickets, and publicly accessible links.

1. **Identify the target branch.** Use the repository's default branch when known, otherwise
   fall back to the project's conventional base branch.

2. **Gather branch context.** Collect the current branch name, the commits introduced since
   the base branch, the files changed, and the full diff. Read the diff carefully to
   understand the change, but do not describe implementation details in the PR.

3. **Find the problem framing.** Search the local knowledge base for notes related to the
   branch name, commit messages, or touched modules. Read relevant sections to understand
   why the work was done, not what was coded. Translate that understanding into plain
   language and remove every local-only reference.

4. **Find and read the PR template.** Check the standard repository locations for a PR
   template. If found, use its structure. Map its opening section (Summary, Description,
   Overview, or similar) to the executive content. If the template starts with a checklist or
   metadata, prepend a short unnumbered executive paragraph before the first section marker.
   If no template exists, load [references/default-template.md](references/default-template.md).

5. **Build the description.** Explain the problem that existed and why this approach solves
   it. The opening section must answer:
   - What problem or need existed before this change?
   - Why is this the right approach?
   - What is the outcome for users or the system?
   Fill remaining sections (test plan, checklist, etc.) from the diff and commits. Do not
   describe implementation details that are already visible in the diff.

6. **Scrub the title and body.** Before creating the PR, re-read the assembled text and fix
   any violations:
   - No filesystem paths (`~/`, `/home/`, `/abs/path`)
   - No bare local issue IDs (`NNN`)
   - No `[[wikilink]]` citations
   - No branch-internal jargon only meaningful to the author
   - No source code descriptions (function names, file paths, class names) unless they are
     meaningful in a public/shared context

7. **Preview and create.** Show the assembled title and body to the user and ask for
   confirmation or adjustments. Once confirmed, create the PR with the assembled text. Use a
   draft PR if the branch is a work-in-progress or if the user requests it. Never push
   additional commits, merge, close, or label without explicit user instruction.

8. **Write the PR title.** Keep it short (≤70 chars), present-tense imperative, with no
   trailing period. Describe the outcome, not the mechanism. Examples:
   - "Allow users to export reports as PDF"
   - "Fix session expiry under concurrent requests"
   - "Remove deprecated v1 authentication endpoints"
