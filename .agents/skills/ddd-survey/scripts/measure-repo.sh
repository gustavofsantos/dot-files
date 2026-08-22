#!/usr/bin/env bash
# measure-repo.sh <repo-root> [subpath]
# Deterministic sizing of a repository. Emits JSON on stdout. No model judgment here.
set -euo pipefail

ROOT="${1:?usage: measure-repo.sh <repo-root> [subpath]}"
SUB="${2:-}"
TARGET="$ROOT${SUB:+/$SUB}"

[ -d "$TARGET" ] || { echo "{\"error\":\"not a directory: $TARGET\"}"; exit 1; }

cd "$TARGET"

SRC_EXT='clj|cljc|cljs|edn|java|kt|kts|scala|go|rb|py|ts|tsx|js|jsx|ex|exs|rs|sql|proto|avsc|graphql'
PRUNE='-name .git -o -name node_modules -o -name target -o -name build -o -name dist -o -name .gradle -o -name vendor -o -name __pycache__'

# Source files
FILES=$(find . \( $PRUNE \) -prune -o -type f -print 2>/dev/null \
  | grep -E "\.($SRC_EXT)$" || true)
FILE_COUNT=$(printf '%s' "$FILES" | grep -c . || true)

# LOC (cheap, non-blank lines)
if [ "$FILE_COUNT" -gt 0 ]; then
  LOC=$(printf '%s\n' "$FILES" | tr '\n' '\0' | xargs -0 grep -ch -v '^\s*$' 2>/dev/null | awk '{s+=$1} END{print s+0}')
else
  LOC=0
fi

# Build/manifest files -> multi-service / multi-module signal
BUILD_FILES=$(find . \( $PRUNE \) -prune -o -type f \( \
  -name 'deps.edn' -o -name 'project.clj' -o -name 'build.gradle' -o -name 'build.gradle.kts' \
  -o -name 'pom.xml' -o -name 'settings.gradle*' -o -name 'package.json' -o -name 'mix.exs' \
  -o -name 'Cargo.toml' -o -name 'go.mod' -o -name 'pyproject.toml' \) -print 2>/dev/null | sort || true)
BUILD_COUNT=$(printf '%s' "$BUILD_FILES" | grep -c . || true)

# Top-level modules with their file counts (candidate scopes for LARGE mode)
TOP_DIRS_JSON="["
FIRST=1
for d in $(find . -maxdepth 1 -mindepth 1 -type d ! -name '.*' ! -name node_modules ! -name target ! -name build ! -name dist | sort); do
  N=$(find "$d" \( $PRUNE \) -prune -o -type f -print 2>/dev/null | grep -cE "\.($SRC_EXT)$" || true)
  [ "$N" -eq 0 ] && continue
  [ $FIRST -eq 0 ] && TOP_DIRS_JSON+=","
  TOP_DIRS_JSON+="{\"dir\":\"${d#./}\",\"src_files\":$N}"
  FIRST=0
done
TOP_DIRS_JSON+="]"
MODULE_COUNT=$(echo "$TOP_DIRS_JSON" | grep -o '"dir"' | wc -l | tr -d ' ')

# Boundary-signal files (events, schemas, adapters) — cheap grep for later orientation
EVENT_HINTS=$(printf '%s\n' "$FILES" | grep -ciE '(event|topic|consumer|producer|listener|publisher)' || true)
ADAPTER_HINTS=$(printf '%s\n' "$FILES" | grep -ciE '(adapter|mapper|translator|gateway|client|anti.?corruption|acl)' || true)

cat <<JSON
{
  "target": "$TARGET",
  "src_files": $FILE_COUNT,
  "loc": $LOC,
  "build_manifests": $BUILD_COUNT,
  "top_level_modules": $MODULE_COUNT,
  "modules": $TOP_DIRS_JSON,
  "filename_hints": { "eventish": $EVENT_HINTS, "adapterish": $ADAPTER_HINTS }
}
JSON
