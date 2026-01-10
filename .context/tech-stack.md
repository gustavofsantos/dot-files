# Tech Stack

## Infrastructure & OS
- **OS:** Linux
- **Package Manager:** Homebrew (via `Brewfile`), GNU Stow (for symlink management)

## Languages & Runtimes
- **Shell:** Bash, Zsh
- **Lua:** Used for Neovim configuration
- **Node.js:** v22 (managed by Homebrew)
- **Python:** v3.9 (managed by Homebrew)
- **Java:** Maven (managed by Homebrew)

## Core Tools
- **Editor:** Neovim (lazy.nvim for plugin management)
- **Terminal Multiplexer:** tmux, tmuxinator
- **Search & Navigation:** ripgrep (rg), fd, fzf, zoxide, eza
- **Structural Search:** ast-grep (sg)
- **Version Control:** Git, lazygit, git-delta
- **CLI Utilities:** jq, gum, bat, btop, coreutils, findutils, gawk, gnu-sed, gnu-tar

## Custom Tooling
- **CDD Suite:** Custom scripts prefixed with `cdd-` in `bin/` for Context-Driven Development.
- **Git Helpers:** Custom scripts in `bin/` for git workflow management (worktrees, branch logs, etc.).
