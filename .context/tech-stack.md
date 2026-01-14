# Technical Architecture & Constraints

## Supported Platforms
- **Linux** (primary: Debian/Ubuntu, but shell-based approach supports most distributions)
- **macOS** (all recent versions with arm64 or x86_64 support)

## Core Technologies

### Shell Environments
- **Primary**: Zsh (.zshrc, .zprofile, .zshenv)
- **Fallback**: Bash support where needed

### Editors
- **Vim** (.vimrc)
- **Emacs** (.emacs)
- **JetBrains IDEs** (.ideavimrc for vim keybindings)

### Version Control
- **Git** (.gitconfig, .githelpers, .gitmessage)

### Tool Configuration Files
- **PostgreSQL** (.psqlrc)
- **Yarn** (.yarnrc.yml)
- **Todo.txt** (.todo.cfg)

### Package Management
- **macOS**: Homebrew (Brewfile for declarative tool installation)
- **Linux**: apt, yum, or equivalent (manual specification per distribution if needed)

## Deployment Mechanism

### Setup Script (setup.sh)
- Language: Bash (POSIX-compliant for maximum compatibility)
- Responsibility: Orchestrate symlinks, install tools, detect OS/architecture
- Idempotency: Should be safe to run multiple times

### Repository Structure
- Configuration files at root level (standard dotfile convention)
- `setup.sh` at root for execution
- `Brewfile` for macOS tool declarations
- Subdirectories for organization: `bin/`, `config/`, `prompts/`, `templates/`, `warp/`

## Key Constraints

1. **No External Dependencies in Setup**: Setup script should work with only shell and basic Unix tools (no Python, Node, Ruby dependencies for bootstrap)
2. **OS Detection**: setup.sh must detect OS (uname) and architecture and behave accordingly
3. **Non-Destructive**: Existing user configurations should not be overwritten without explicit user action
4. **Symlink Preference**: Where possible, symlink configs to maintain single source of truth; only copy when symlinks aren't supported
5. **Idempotent Execution**: Running setup.sh twice should produce the same result as running it once
6. **Public Repository**: No secrets, API keys, or sensitive data in version control

## Notable Patterns

- **Git Hooks**: .githelpers and .gitmessage enable consistent commit practices
- **Shell Initialization Order**: .zshenv → .zprofile → .zshrc ensures proper environment variable loading
- **Multi-Platform Configs**: Editor and shell configs use conditionals for OS-specific behaviors
