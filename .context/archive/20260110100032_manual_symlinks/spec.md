# Specification: manual_symlinks

## 1. User Intent (The Goal)
Update the `setup.sh` script to remove the dependency on GNU `stow` and instead symlink the configuration files manually.

## 2. Relevant Context (The Files)
- `setup.sh`: The main setup script.
- `config/`: Directory containing XDG configuration files.
- `config/.stowrc`: Current stow configuration (removed).
- `.context/tech-stack.md`: Documentation of the tech stack.

## 3. Context Analysis (Agent Findings)
- Current Behavior: `setup.sh` used `stow config`.
- Changes:
  - Replaced `stow config` in `setup.sh` with a manual linking loop.
  - Removed `stow` from documentation.
  - Deleted `config/.stowrc`.

## Test Reference
Manual verification performed by running `./setup.sh` and inspecting `~/.config` for correct symlinks.
