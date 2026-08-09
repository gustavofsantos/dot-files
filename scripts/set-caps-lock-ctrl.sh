#!/usr/bin/env bash
set -euo pipefail

# Sets the "Caps Lock as Ctrl" keyboard option that GNOME Tweaks exposes
# under Keyboard > Additional Layout Options > Ctrl Position, without
# needing the gnome-tweaks package installed.

SCHEMA="org.gnome.desktop.input-sources"
KEY="xkb-options"
OPTION="ctrl:nocaps"

echo "Setting Caps Lock as Ctrl..."

if ! command -v gsettings >/dev/null 2>&1; then
  echo "Setting Caps Lock as Ctrl... SKIP (gsettings not found, not a GNOME session)"
  exit 0
fi

current="$(gsettings get "$SCHEMA" "$KEY")"

options=()
while IFS= read -r opt; do
  [ -n "$opt" ] || continue
  [[ "$opt" == ctrl:* ]] && continue
  options+=("$opt")
done < <(echo "$current" | tr -d "[]" | tr ',' '\n' | sed "s/^[ \t]*'//;s/'[ \t]*\$//")

options+=("$OPTION")

array="["
for i in "${!options[@]}"; do
  [ "$i" -gt 0 ] && array+=", "
  array+="'${options[$i]}'"
done
array+="]"

gsettings set "$SCHEMA" "$KEY" "$array"
echo "Setting Caps Lock as Ctrl... OK"
