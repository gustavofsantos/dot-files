---
name: setup-checks
description: Set up and maintain repository checks in ~/.checks.yml. Use when the user wants to enroll a new repo, add/remove individual checks, list what's configured, or unenroll a repo. Invoked via /setup-checks [path].
disable-model-invocation: true
---

# Setup Checks

This skill manages `~/.checks.yml` — the global registry that controls which
repositories run automated checks after each agent turn. It enrolls repos,
adds/removes checks, and verifies the config is wired correctly.

For reading check *results* during active work, run `checks-status` (in `~/.bin`) — this skill only manages the registry.

## Operations

| Command | What it does |
|---------|--------------|
| `/setup-checks` | Enroll the current repo (probe + propose) |
| `/setup-checks <path>` | Enroll a specific repo |
| `/setup-checks list` | Show current checks for the current (or specified) repo |
| `/setup-checks add <name> <command>` | Add one check by name and command |
| `/setup-checks remove <name>` | Remove a check by name |
| `/setup-checks unenroll` | Remove the current repo from the registry |

No argument defaults to enrolling the current directory's repo.

## Procedure: enrolling a new repo

### 1. Read the current registry

```bash
cat ~/.checks.yml 2>/dev/null || echo "(absent)"
```

If absent, scaffold it:

```yaml
repositories: []
```

Write this to `~/.checks.yml` with the Write tool before proceeding.

### 2. Check if already enrolled

```bash
checks-config --registered .    # exit 0 = enrolled, exit 1 = not enrolled
```

If enrolled, show the existing checks (`checks-config .`) and ask what to
change (add / remove / done). Don't re-enroll.

### 3. Probe for check candidates

Read the repo root and surface concrete command suggestions. Prefer fast
checks (lint, typecheck, config validation) over full builds or full test
suites — checks run after *every* agent turn.

| Signal file | Suggested check | Notes |
|-------------|----------------|-------|
| `package.json` with `scripts.typecheck` | `npm run typecheck` | Fast |
| `package.json` with `scripts.lint` | `npm run lint` | Fast |
| `package.json` with `scripts.test` | `npm test` | **Warn: may be slow** |
| `package.json` with `scripts.build` | `npm run build` | **Warn: slow** |
| `Cargo.toml` | `cargo clippy` | Fast |
| `Cargo.toml` | `cargo test` | **Warn: may be slow** |
| `go.mod` | `go vet ./...` | Fast |
| `go.mod` | `go test ./...` | **Warn: may be slow** |
| `pyproject.toml` or `setup.py` | `pytest -x -q` | **Warn: may be slow** |
| `.claude/settings.json` | `jq -e . .claude/settings.json >/dev/null` | Fast |
| `*.sh` files present | `shellcheck <files>` | Fast — limit to tracked files |
| `Makefile` with `lint` or `check` target | `make lint` / `make check` | Usually fast |

For shellcheck, scope to tracked changed files:
```bash
shellcheck $(git diff --name-only HEAD | grep '\.sh$') 2>/dev/null || shellcheck *.sh
```

**Run each candidate command once** from the repo root to smoke-test it.
The goal is to catch "command not found" or "missing config" errors — *not*
to require the check to pass. A check that reports test failures is still a
valid check; a check that errors with `command: npm: not found` is not.

```bash
# Distinguish runnable vs broken config
<command>; echo "exit: $?"
```

Exit code 127 = command not found (bad check).
Any other exit code (including 1, 2) = ran — keep it.

### 4. Propose and confirm

Present a short list:

```
Proposed checks for ~/Workplace/my-repo:

  ✓ typecheck   npm run typecheck
  ✓ lint        npm run lint
  ⚠ test        npm test  (runs after every turn — keep if fast, skip if slow)

Proceed with all? Or say which to skip.
```

Wait for the user's confirmation or adjustment before writing.

### 5. Write to ~/.checks.yml

Use Read + Edit (or Write for first-time creation) on the plain text of
`~/.checks.yml`. Do not use `yq -i` — it behaves differently across yq
flavors. The agent is the editor.

Add the repo entry using the repo's **absolute path** (not `~`-expanded
shorthand, and not a relative path):

```yaml
repositories:
  - path: /home/user/Workplace/my-repo
    checks:
      - name: typecheck
        command: npm run typecheck
      - name: lint
        command: npm run lint
```

Resolve the absolute path:
```bash
git rev-parse --show-toplevel
```

### 6. Verify enrollment

```bash
checks-config --registered .     # should exit 0
checks-config .                  # should emit the checks as JSON
```

If `checks-config .` returns your checks, enrollment is confirmed. The checks
won't *run* until the next agent turn fires the Stop hook — no further action
needed.

Tell the user: "Enrolled. Checks will run automatically after each agent turn.
Use `checks-status` to read results."

---

## Machine-specific checks

Everything goes into `~/.checks.yml` by default. If a check requires a
machine-local path, secret env var, or behaves differently per machine, add
it to `~/.checks.local.yml` instead (same shape). Local checks overlay the
base by name — same name replaces the base entry, new names append.

---

## Edge cases

- **Repo not a git worktree** — `checks-config` only matches registered paths
  against git working trees. Non-git directories can't be enrolled.
- **Worktrees** — enroll the *main* working tree path; worktrees are covered
  automatically because `checks-config` resolves via `--git-common-dir`.
- **Already enrolled, adding one check** — Read the file, Edit the relevant
  `checks:` block to append the new entry, then `checks-config .` to verify.
- **Removing a check** — Edit to delete the entry; verify with `checks-config .`.
- **Unenrolling** — Edit to remove the entire repo block from `repositories:`;
  confirm with `checks-config --registered .` (should exit 1 after).
