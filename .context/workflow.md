# Workflow

## Development Loop (CDD)
This project uses the **Context-Driven Development (CDD)** protocol.
1.  **Initialize:** Run `bin/cdd-init` to set up the environment.
2.  **Start Task:** Run `bin/cdd-start <track-name>` to create a new workspace.
3.  **Recite:** Run `bin/cdd-recite <track-name>` before every step to align with the plan.
4.  **Log Decisions:** Use `bin/cdd-log <track-name> "<message>"` to record permanent decisions.
5.  **Dump Context:** Use `bin/cdd-dump <track-name>` to pipe results to the scratchpad.
6.  **Archive:** Run `bin/cdd-archive <track-name>` when the task is complete.

## Testing & Validation
Custom scripts in `bin/` provide a unified interface for testing across different projects:
- **Test single file:** `bin/testfile <path>`
- **Test changed files:** `bin/testallchanged [--staged|--working|--branch]`
- **List changed tests:** `bin/listchangedtests`
- **Linter:** `bin/lint <path>` (supports Clojure via `clj-kondo`)
- **Lint changed files:** `bin/lintchanged [--staged|--working|--branch]`

## Git Workflow
A suite of scripts enhances the Git experience:
- **Worktrees:** `bin/git-add-worktree`, `bin/git-checkout-worktree`, `bin/git-remove-worktree`, `bin/git-prune-worktrees`.
- **Insights:** `bin/git-branch-log`, `bin/git-changed-files`, `bin/git-main-branch`, `bin/git-my-contributions`.

## Editor (Neovim)
- **Plugin Management:** `lazy.nvim` (see `config/nvim/lua/config/lazy.lua`).
- **Keymaps:** Defined in `config/nvim/lua/config/keymaps.lua`.
- **Project Bookmarks:** Custom plugin in `config/nvim/lua/personal-plugins/project-bookmarks.lua`.
- **Command Palette:** Custom Telescope-based picker in `config/nvim/lua/personal-plugins/cmd_palette.lua`.
