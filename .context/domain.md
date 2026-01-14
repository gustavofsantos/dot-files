# Domain Model: Dotfiles Management

## Core Entities

### Configuration
A single dotfile or configuration artifact that defines behavior for a specific tool or shell.

**Attributes:**
- Name (e.g., ".zshrc", ".vimrc")
- Type (shell, editor, git, tool, system)
- Target Path (location in home directory or system)
- Dependencies (other configs or tools it depends on)

### Device
A machine (Linux or macOS) where configurations will be deployed.

**Attributes:**
- OS (Linux, macOS)
- Architecture (arm64, x86_64)
- Existing state (configs already present or not)

### Setup Process
The workflow of installing and linking configurations to a device.

**Steps:**
1. Clone repository
2. Run setup script
3. Detect OS and architecture
4. Install/update configurations
5. Symlink or copy configs to target paths
6. Verify installation

## Key Domain Events

- **RepositoryCloned**: User has cloned the dotfiles repository
- **SetupScriptExecuted**: User runs setup.sh
- **ConfigurationDetected**: System detects which OS it is running
- **ToolInstalled**: A tool is installed via package manager (Homebrew, apt, etc.)
- **ConfigurationLinked**: A dotfile is symlinked or copied to its target location
- **SetupCompleted**: All configurations are in place and verified

## Ubiquitous Language

- **Dotfile**: A configuration file that starts with a dot (.), typically stored in $HOME
- **Setup Script**: Automated deployment script that orchestrates installation and linking
- **Symlink**: Reference to a file in the repo instead of copying it (enables single-source-of-truth)
- **Bootstrap**: Initial setup process to prepare a device with all configurations
- **Source of Truth**: The repository itself; all configurations are defined here, not on individual machines
