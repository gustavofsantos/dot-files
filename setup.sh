#!/usr/bin/env bash
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")/scripts" && pwd)"

"$SCRIPTS_DIR/link-home-files.sh"
"$SCRIPTS_DIR/create-local-files.sh"
"$SCRIPTS_DIR/link-bin-files.sh"
"$SCRIPTS_DIR/link-xdg-config.sh"
"$SCRIPTS_DIR/install-skills.sh"
