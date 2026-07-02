---
name: create-pull-request
description: >
  Create a GitHub pull request with an executive-oriented description that focuses on the
  problem and why the change solves it. Uses the repository's PR template when present.
  Triggers on: "create a PR", "open a pull request", "make a PR", "submit PR",
  "/create-pull-request", or any explicit request to open a pull request for the current branch.
---

# create-pull-request

Create a GitHub pull request with a clean, executive-oriented description built from the
branch's commits and local KB context.

## Protocol override

> **Citation rules suspended for PR output.** The global KB protocol instructs citing
> context as `[[Note Title]]` and issue numbers as bare `NNN`. Those are local-only
> identifiers — they have no meaning outside this machine. They MUST NOT appear in the
> PR title, body, or any field sent to GitHub. This skill explicitly overrides that protocol.
>
> Allowed references in the PR body: other PR URLs, GitHub issue URLs, external tracker
> tickets (Jira, Linear), publicly accessible documents or links.

## Operating loop

### 1. Detect base branch

```bash
# Prefer the remote default branch; fall back to local conventions
BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
[ -z "$BASE" ] && BASE=$(gh repo view --json defaultBranchRef -q '.defaultBranchRef.name' 2>/dev/null)
[ -z "$BASE" ] && BASE=main
```

### 2. Gather branch context

```bash
BRANCH=$(git branch --show-current)

# Commits on this branch
git log --oneline "$BASE..HEAD"

# Files changed
git diff --stat "$BASE...HEAD"

# Full diff for understanding (read carefully; describe none of it in the PR)
git diff "$BASE...HEAD"
```

### 3. Search KB for problem framing

Search `~/engineering/issues/` and `~/engineering/spikes/` for context related to the
branch name, commit messages, or touched modules:

```bash
# Extract keywords from branch name and recent commits
rg -il 'KEYWORD' ~/engineering/issues/ ~/engineering/spikes/ --include='*.md' -l 2>/dev/null
```

Read `## Objective`, `## Context`, `## Hypothesis`, and `## Answer` sections from hits.
Use this to understand **why** the work was done — not **what** was coded.
Translate that understanding into plain language; remove every local reference.

### 4. Find PR template

Check these paths in order (case-insensitive on file systems that need it):

```bash
find . \( \
  -path './.github/pull_request_template.md' \
  -o -path './.github/PULL_REQUEST_TEMPLATE.md' \
  -o -path './PULL_REQUEST_TEMPLATE.md' \
  -o -path './docs/pull_request_template.md' \
\) -print -quit 2>/dev/null

# Also check for multiple-template directory
ls .github/PULL_REQUEST_TEMPLATE/ 2>/dev/null
```

Read the template if found. Map its top-level section (Summary, Description, Overview, or
similar) to the executive content. If the template opens with a checklist or metadata,
prepend a short unnumbered executive paragraph before the first section marker.

### 5. Build the description

**Core principle:** reviewers read code; the PR description's job is to explain the
*problem that existed* and *why this approach solves it*. Describe zero implementation
details that are already visible in the diff.

**Structure when a template exists:**

Fill the template's structure. The opening section (Summary/Description/Overview) must
contain the executive framing:
- What problem or need existed before this change?
- Why is this the right approach?
- What is the outcome for users or the system?

Fill remaining template sections (test plan, checklist, etc.) from the diff and commits.

**Structure when no template exists:** load [references/default-template.md](references/default-template.md) and follow it.

### 6. Scrub pass

Before creating the PR, re-read the assembled title and body and verify:

- [ ] No filesystem paths (no `~/`, `/home/`, `/abs/path`)
- [ ] No bare issue IDs (`NNN` referencing the local tracker)
- [ ] No `[[wikilink]]` citations
- [ ] No branch-internal jargon that only makes sense to the author
- [ ] No source code descriptions (function names, file paths, class names) unless
      they are meaningful in a public/shared context (a library API, a config key)

Fix any violation before proceeding.

### 7. Preview and create

Show the assembled title and body to the user before opening the PR. Ask for confirmation
or adjustments. Then create:

```bash
gh pr create \
  --title "..." \
  --body "$(cat <<'EOF'
...
EOF
)"
```

Use `--draft` if the branch is a work-in-progress or if the user requests it. Never push
additional commits, merge, close, or label without explicit user instruction.

## PR title

Short (≤70 chars), present-tense imperative, no trailing period. Describe the outcome,
not the mechanism. Examples:
- "Allow users to export reports as PDF"
- "Fix session expiry under concurrent requests"
- "Remove deprecated v1 authentication endpoints"
