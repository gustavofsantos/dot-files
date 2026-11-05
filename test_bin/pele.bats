#!/usr/bin/env bats

# Tests for bin/pele (Mermaid → SVG/PNG shim over Pele, run by Bun).
# Needs `bun`, and network on the first run so Bun can auto-install pele and resvg.

PELE="$BATS_TEST_DIRNAME/../bin/pele"

setup() {
  command -v bun >/dev/null || skip "bun not installed"
  WORK=$(mktemp -d)
  SRC=$'flowchart LR\n  A[Hello] --> B{Ok?}\n  B -->|yes| C((Done))\n'
  printf '%s' "$SRC" > "$WORK/flow.mmd"
}

teardown() {
  rm -rf "$WORK"
}

# PNG header: width and height are big-endian u32 at offsets 16 and 20.
png_size() {
  local w h
  read -r w h < <(od -An -t u1 -j16 -N8 "$1" | awk '{print $1*16777216+$2*65536+$3*256+$4, $5*16777216+$6*65536+$7*256+$8}')
  echo "$w x $h"
}

@test "svg goes to stdout by default" {
  run "$PELE" "$WORK/flow.mmd"
  [ "$status" -eq 0 ]
  [[ "$output" == "<svg "* ]]
}

@test "svg output is self-contained: no CSS variables or color-mix" {
  printf 'flowchart LR\n subgraph A\n subgraph B\n X-->Y\n end\n end\n' > "$WORK/nested.mmd"
  run "$PELE" "$WORK/nested.mmd"
  [ "$status" -eq 0 ]
  [[ "$output" != *"var("* ]]
  [[ "$output" != *"color-mix"* ]]
}

@test "--keep-vars keeps Pele's variables" {
  run "$PELE" --keep-vars "$WORK/flow.mmd"
  [ "$status" -eq 0 ]
  [[ "$output" == *"var(--pele-"* ]]
}

@test "reads the diagram from stdin and strips a markdown fence" {
  run bash -c "printf '\`\`\`mermaid\nflowchart LR\n A-->B\n\`\`\`\n' | '$PELE' -"
  [ "$status" -eq 0 ]
  [[ "$output" == "<svg "* ]]
}

@test "extension picks the format, and parent dirs are created" {
  run "$PELE" "$WORK/flow.mmd" -o "$WORK/deep/dir/out.png" -q
  [ "$status" -eq 0 ]
  [ "$(head -c 4 "$WORK/deep/dir/out.png" | tail -c 3)" = "PNG" ]
}

@test "png default scale is 2x the natural size" {
  "$PELE" "$WORK/flow.mmd" -o "$WORK/a.svg" -q
  w=$(grep -o ' width="[0-9.]*"' "$WORK/a.svg" | head -1 | grep -o '[0-9.]*')
  "$PELE" "$WORK/flow.mmd" -o "$WORK/a.png" -q
  read -r pw _ <<<"$(png_size "$WORK/a.png")"
  [ "$pw" -eq "$(awk "BEGIN{printf \"%d\", $w*2 + 0.5}")" ]
}

@test "--width fixes the png width" {
  "$PELE" "$WORK/flow.mmd" -o "$WORK/w.png" --width 1000 -q
  read -r pw _ <<<"$(png_size "$WORK/w.png")"
  [ "$pw" -eq 1000 ]
}

@test "--width and --height fit inside the box" {
  "$PELE" "$WORK/flow.mmd" -o "$WORK/box.png" --width 400 --height 400 -q
  read -r pw _ph <<<"$(png_size "$WORK/box.png")"
  [ "$pw" -eq 400 ]
}

@test "png is written to a pipe" {
  run bash -c "'$PELE' '$WORK/flow.mmd' -f png | head -c 4 | tail -c 3"
  [ "$output" = "PNG" ]
}

@test "dark theme with --background paints that color into the svg" {
  run "$PELE" "$WORK/flow.mmd" -f svg -t dark -b '#100f0f'
  [[ "$output" == *'fill="#100f0f"'* ]]
}

@test "--var overrides a Pele variable" {
  run "$PELE" "$WORK/flow.mmd" --var accent=#ff0000 --var surface=#00ff00
  [ "$status" -eq 0 ]
  [[ "$output" == *"#00ff00"* ]]
}

@test "--background adds a rect to svg; default svg has none" {
  run "$PELE" "$WORK/flow.mmd" -b '#abcdef'
  [[ "$output" == *'<rect width="100%" height="100%" fill="#abcdef"/>'* ]]
  run "$PELE" "$WORK/flow.mmd"
  [[ "$output" != *'height="100%"'* ]]
}

@test "--check on a valid diagram writes nothing and exits 0" {
  run "$PELE" --check --json "$WORK/flow.mmd"
  [ "$status" -eq 0 ]
  [[ "$output" == '{"ok":true,"type":"flowchart"'* ]]
}

@test "a syntax error exits 1 with line and column" {
  printf 'flowchart LR\n A-->\n' > "$WORK/bad.mmd"
  run "$PELE" --check "$WORK/bad.mmd"
  [ "$status" -eq 1 ]
  [[ "$output" == *"syntax (flowchart) at line"* ]]
}

@test "--json reports the error as JSON on stdout" {
  run bash -c "echo 'nonsense' | '$PELE' --check --json"
  [ "$status" -eq 1 ]
  [[ "$output" == *'"ok":false'*'"code":"unsupported-diagram"'* ]]
}

@test "--json with -o reports size and bytes" {
  run "$PELE" "$WORK/flow.mmd" -o "$WORK/j.png" --json
  [ "$status" -eq 0 ]
  [[ "$output" == *'"ok":true'*'"format":"png"'*'"bytes":'* ]]
}

@test "usage errors exit 2" {
  run "$PELE" "$WORK/missing.mmd"
  [ "$status" -eq 2 ]
  run "$PELE" "$WORK/flow.mmd" --theme neon
  [ "$status" -eq 2 ]
  run "$PELE" "$WORK/flow.mmd" -f png -w 999999 -o "$WORK/x.png"
  [ "$status" -eq 2 ]
  run "$PELE" "$WORK/flow.mmd" --json
  [ "$status" -eq 2 ]
}

@test "resvg is installed once into XDG_CACHE_HOME, and svg never needs it" {
  export XDG_CACHE_HOME="$WORK/cache"
  run "$PELE" "$WORK/flow.mmd" -o "$WORK/s.svg" -q
  [ "$status" -eq 0 ]
  [ ! -d "$XDG_CACHE_HOME/pele" ]
  run "$PELE" "$WORK/flow.mmd" -o "$WORK/s.png"
  [ "$status" -eq 0 ]
  [ -d "$XDG_CACHE_HOME/pele/resvg-2.6.2/node_modules/@resvg/resvg-js" ]
  # stderr is only the summary line: no registry errors from the loader's platform probe
  [ "$(echo "$output" | wc -l)" -eq 1 ]
}
