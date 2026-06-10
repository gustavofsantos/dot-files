export const meta = {
  name: 'issue-worker',
  description: 'Implement a ready vault issue autonomously: worktree → tasks → checks → PR',
  phases: [
    { title: 'Discover', detail: 'Find and lock a ready issue' },
    { title: 'Setup',    detail: 'Create worktree and branch' },
    { title: 'Implement', detail: 'Work through tasks sequentially' },
    { title: 'Verify',   detail: 'Run checks, fix failures' },
    { title: 'Ship',     detail: 'Commit, push, open PR, notify' },
  ],
}

// ── Schemas ──────────────────────────────────────────────────────────────────

const ISSUE_SCHEMA = {
  type: 'object',
  properties: {
    found:     { type: 'boolean' },
    id:        { type: 'string' },
    title:     { type: 'string' },
    path:      { type: 'string' },
    repo:      { type: 'string', description: 'Absolute path to the git repo for this issue' },
    objective: { type: 'string' },
    context:   { type: 'string' },
    tasks: {
      type: 'array',
      description: 'Ordered list of tasks from the ## Tasks section, preserving checkbox text exactly',
      items: {
        type: 'object',
        properties: {
          index: { type: 'number', description: '0-based position in the list' },
          text:  { type: 'string', description: 'Exact checkbox text, no leading "- [ ] " or "- [x] "' },
          done:  { type: 'boolean' },
        },
        required: ['index', 'text', 'done'],
      },
    },
  },
  required: ['found'],
}

const SETUP_SCHEMA = {
  type: 'object',
  properties: {
    worktreePath: { type: 'string' },
    branch:       { type: 'string' },
  },
  required: ['worktreePath', 'branch'],
}

const TASK_SCHEMA = {
  type: 'object',
  properties: {
    done:          { type: 'boolean' },
    blocked:       { type: 'boolean' },
    blockedReason: { type: 'string' },
  },
  required: ['done', 'blocked'],
}

const CHECKS_SCHEMA = {
  type: 'object',
  properties: {
    pass:     { type: 'boolean' },
    summary:  { type: 'string' },
    failures: { type: 'array', items: { type: 'string' } },
  },
  required: ['pass', 'summary'],
}

const PR_SCHEMA = {
  type: 'object',
  properties: {
    url:    { type: 'string' },
    number: { type: 'number' },
  },
  required: ['url'],
}

// ── Phase 1: Discover ─────────────────────────────────────────────────────────
phase('Discover')

const issuePrompt = (args && args.issuePath)
  ? `Read the vault issue at: ${args.issuePath}

     1. Parse its frontmatter (id, title, status, repo, branch fields)
     2. Parse its ## Tasks section — each line "- [ ] task text" or "- [x] task text"
     3. Parse its ## Objective and ## Context sections
     4. The issue MUST have a 'repo:' frontmatter field (absolute path to a git repo).
        If missing and no repoPath was given in args, return {found: false}.
     5. Set the frontmatter 'status' to 'active' (update the file)
     6. Return found=true with the full spec

     repo override from args: ${(args && args.repoPath) || 'none — use repo: from frontmatter'}`
  : `Find the next vault issue to work on autonomously:

     1. Run: rg -l 'status: ready' ~/engineering/issues/ -g '*.md' -g '!archive' 2>/dev/null | sort | head -1
     2. If no output: return {found: false}
     3. Read the file
     4. Parse frontmatter (id, title, status, repo, branch), ## Tasks, ## Objective, ## Context
     5. Must have a 'repo:' frontmatter field. If missing: return {found: false}
     6. Set frontmatter 'status' to 'active' (update the file)
     7. Return found=true with full spec`

const issue = await agent(issuePrompt, { phase: 'Discover', schema: ISSUE_SCHEMA, model: 'haiku' })

if (!issue || !issue.found) {
  log('No ready issues or missing repo: field.')
  return { status: 'idle' }
}

const repoPath   = (args && args.repoPath) || issue.repo
const allTasks   = issue.tasks || []
const pending    = allTasks.filter(t => !t.done)

log(`Issue ${issue.id}: "${issue.title}" — ${pending.length} of ${allTasks.length} tasks pending`)

// ── Phase 2: Setup ────────────────────────────────────────────────────────────
phase('Setup')

const setup = await agent(
  `Set up a git worktree for issue ${issue.id}.

   Repo:        ${repoPath}
   Issue file:  ${issue.path}
   Branch name: issue-${issue.id}
   Worktree:    ~/worktrees/${issue.id}

   Steps:
   1. mkdir -p ~/worktrees
   2. Check if ~/worktrees/${issue.id} already exists:
        git -C ${repoPath} worktree list | grep ${issue.id}
   3a. If the worktree exists, just use it as-is.
   3b. If the branch issue-${issue.id} already exists but no worktree:
        git -C ${repoPath} worktree add ~/worktrees/${issue.id} issue-${issue.id}
   3c. Neither exists:
        git -C ${repoPath} worktree add ~/worktrees/${issue.id} -b issue-${issue.id}
   4. Update the issue file frontmatter at ${issue.path}:
        - Set 'worktree: ~/worktrees/${issue.id}'
        - Set 'branch: issue-${issue.id}'
   5. Return the absolute worktreePath (expand ~) and branch name`,
  { phase: 'Setup', schema: SETUP_SCHEMA, model: 'haiku' }
)

const worktree = setup.worktreePath
const branch   = setup.branch
log(`Worktree: ${worktree}  branch: ${branch}`)

// ── Phase 3: Implement ────────────────────────────────────────────────────────
phase('Implement')

let blocked       = false
let blockedReason = ''

for (const task of pending) {
  log(`Task ${task.index + 1}/${allTasks.length}: ${task.text}`)

  const result = await agent(
    `Implement a task from vault issue ${issue.id}.

WORKING DIRECTORY
  ${worktree}
  All edits must stay within this path. Use absolute paths.

ISSUE
  Title:     ${issue.title}
  Objective: ${issue.objective}
  Context:   ${issue.context || '(none)'}

CURRENT TASK  (${task.index + 1} of ${allTasks.length})
  ${task.text}

RULES
- Read relevant source files before editing
- Implement the task
- After implementing, mark it done in ${issue.path} by changing:
    "- [ ] ${task.text}" → "- [x] ${task.text}"
- Do NOT commit (that happens in the Ship phase)
- If you genuinely cannot proceed (ambiguous spec, missing dependency,
  needs a decision only the human can make): set blocked=true with a precise,
  answerable blockedReason. Do not block for things you can figure out yourself.`,
    { phase: 'Implement', schema: TASK_SCHEMA, model: 'sonnet' }
  )

  if (!result || result.blocked) {
    blocked       = true
    blockedReason = (result && result.blockedReason) || 'Agent returned null'
    break
  }
}

if (blocked) {
  await agent(
    `Issue ${issue.id} got blocked during implementation. Update ${issue.path}:
     1. Set frontmatter status to 'blocked'
     2. Add or update a '## Blocked' section:
        ### Needs input
        ${blockedReason}
     Then send a notification:
        claude-notify "Issue blocked" "Issue ${issue.id}: ${blockedReason.slice(0, 80)}"`,
    { phase: 'Implement', model: 'sonnet' }
  )
  log(`Blocked: ${blockedReason}`)
  return { status: 'blocked', issue: issue.id, reason: blockedReason }
}

// ── Phase 4: Verify ───────────────────────────────────────────────────────────
phase('Verify')

let checksPass = false
const MAX_FIX  = 3

for (let attempt = 1; attempt <= MAX_FIX; attempt++) {
  const checks = await agent(
    `Run verification checks for the changes in ${worktree}.

     Step 1 — Is this repo enrolled in the checks system?
       cd ${worktree} && checks-config --registered 2>/dev/null && echo "enrolled" || echo "not enrolled"

     Step 2a — If enrolled:
       Read the check commands: cd ${worktree} && checks-config 2>/dev/null
       Run each command from the JSON output inside ${worktree}.

     Step 2b — If not enrolled, auto-detect and run the project's test suite:
       Cargo.toml  → cd ${worktree} && cargo test 2>&1
       package.json → cd ${worktree} && npm test 2>&1
       Makefile    → cd ${worktree} && make test 2>&1
       go.mod      → cd ${worktree} && go test ./... 2>&1
       pyproject/setup.py → cd ${worktree} && python -m pytest 2>&1
       (Pick whatever is present)

     Return:
       pass=true only if every command exits 0
       summary: one-line description of outcome
       failures: array of error lines or command names that failed`,
    { phase: 'Verify', schema: CHECKS_SCHEMA, model: 'sonnet' }
  )

  if (checks.pass) {
    checksPass = true
    log('Checks passed')
    break
  }

  log(`Checks failed (attempt ${attempt}/${MAX_FIX}): ${checks.summary}`)

  if (attempt === MAX_FIX) {
    await agent(
      `Issue ${issue.id} checks keep failing. Update ${issue.path}:
       1. Set frontmatter status to 'blocked'
       2. Add '## Blocked' section:
          ### Checks failing
          Failed after ${MAX_FIX} fix attempts.
          ${(checks.failures || []).join('\n          ')}
       Then: claude-notify "Issue blocked" "Issue ${issue.id}: checks failing"`,
      { phase: 'Verify', model: 'sonnet' }
    )
    return { status: 'blocked', issue: issue.id, reason: 'checks-failing' }
  }

  await agent(
    `Fix check failures in ${worktree}.

     Failures:
     ${(checks.failures || []).join('\n     ')}

     Rules:
     - Fix the implementation to make the checks pass
     - Never modify tests to pass around failures — fix the code under test
     - Stay within ${worktree}
     - Do NOT commit`,
    { phase: 'Verify', model: 'sonnet' }
  )
}

// ── Phase 5: Ship ─────────────────────────────────────────────────────────────
phase('Ship')

const pr = await agent(
  `Commit, push, and open a PR for issue ${issue.id} from worktree ${worktree}.

   1. cd ${worktree}
   2. git add -A
   3. git commit -m "$(printf '%s\n\n%s' "${issue.title}" "Implements vault issue ${issue.id}.")"
   4. git push -u origin ${branch}
   5. gh pr create \\
        --title "${issue.title}" \\
        --body "Implements vault issue ${issue.id}.

## Summary
${issue.objective}

🤖 Automated by issue-worker"
   6. Return the PR URL and number`,
  { phase: 'Ship', schema: PR_SCHEMA, model: 'haiku' }
)

await agent(
  `Finalize issue ${issue.id}. Update ${issue.path}:
   1. Set frontmatter status to 'review'
   2. Set frontmatter pr to '${pr.url}'
   3. Add a '## Resolution' section (or update if exists):
      PR opened: ${pr.url}

   Then notify: claude-notify "PR ready for review" "Issue ${issue.id}: ${pr.url}"`,
  { phase: 'Ship', model: 'haiku' }
)

log(`Done. PR: ${pr.url}`)
return { status: 'review', issue: issue.id, pr: pr.url }
