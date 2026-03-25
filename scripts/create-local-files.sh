#!/usr/bin/env bash
set -euo pipefail

echo "Creating local override files..."
touch "$HOME/.gitconfig.local"
touch "$HOME/.zshlocal"
echo "Creating local override files... OK"
