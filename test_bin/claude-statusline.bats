#!/usr/bin/env bats

# Tests for bin/claude-statusline
#
# Isolation strategy:
#   HOME        → fresh tmpdir so get_oauth_token finds no credentials (no network calls)
#   TMPDIR      → fresh tmpdir so USAGE_CACHE_DIR is test-local
#   USAGE_TTL   → huge value so any written cache file is always "fresh"

SCRIPT="$BATS_TEST_DIRNAME/../bin/claude-statusline"

setup() {
  TEST_HOME=$(mktemp -d)
  export HOME="$TEST_HOME"
  export TMPDIR="$TEST_HOME/tmp"
  mkdir -p "$TMPDIR"
  export CLAUDE_STATUSLINE_USAGE_TTL=9999999
  CACHE_DIR="$TMPDIR/claude-statusline-cache"
  mkdir -p "$CACHE_DIR"
}

teardown() {
  rm -rf "$TEST_HOME"
}

# Strip ANSI escape codes from stdin
strip_ansi() { sed $'s/\033\[[0-9;]*m//g'; }

# Write JSON to the OAuth cache file (piped from heredoc or stdin)
write_oauth_cache() { cat > "$CACHE_DIR/usage.json"; }

# ── Basics ────────────────────────────────────────────────────────────────────

@test "exits with status 0" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"}}'
  [ "$status" -eq 0 ]
}

@test "shows model display name" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"Claude Sonnet 4.6"}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"Claude Sonnet 4.6"* ]]
}

@test "strips parenthetical suffix from model name" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"Claude Sonnet 4.6 (latest)"}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"Claude Sonnet 4.6"* ]]
  [[ "$plain" != *"(latest)"* ]]
}

@test "falls back to Unknown Model when model field is absent" {
  run bash "$SCRIPT" <<< '{}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"Unknown Model"* ]]
}

# ── Context window ─────────────────────────────────────────────────────────────

@test "shows ctx bar when context_window.used_percentage is present" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":40}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"ctx"* ]]
}

@test "omits ctx bar when context_window is absent" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" != *"ctx"* ]]
}

@test "shows remaining percentage for context window" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":40}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"60%"* ]]
}

@test "fully filled ctx bar when 0% used" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":0}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"ctx ━━━━━ 100%"* ]]
}

@test "fully empty ctx bar when 100% used" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":100}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"ctx ╌╌╌╌╌ 0%"* ]]
}

@test "partial ctx bar reflects used fraction" {
  # 60% used → 40% remaining → filled = 40*5/100 = 2 → ━━╌╌╌
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":60}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"ctx ━━╌╌╌ 40%"* ]]
}

# ── Rate limits — stdin path ───────────────────────────────────────────────────

@test "shows 5h and 7d labels from stdin rate_limits" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"rate_limits":{"five_hour":{"used_percentage":60},"seven_day":{"used_percentage":15}}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"5h"* ]]
  [[ "$plain" == *"7d"* ]]
}

@test "shows remaining percentages for stdin rate limits" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"rate_limits":{"five_hour":{"used_percentage":60},"seven_day":{"used_percentage":15}}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"40%"* ]]
  [[ "$plain" == *"85%"* ]]
}

@test "shows mo and ses labels for non-standard billing models" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"rate_limits":{"monthly":{"used_percentage":42},"session":{"used_percentage":90}}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"mo"* ]]
  [[ "$plain" == *"ses"* ]]
}

@test "shows 1h label for one_hour limit" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"rate_limits":{"one_hour":{"used_percentage":20}}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"1h"* ]]
}

@test "omits rate section when rate_limits is an empty object" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"rate_limits":{}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" != *"5h"* ]]
  [[ "$plain" != *"7d"* ]]
}

@test "handles floating-point used_percentage from stdin" {
  # 34.7% used → 65% remaining (rounded) → filled = 65*5/100 = 3 → ━━━╌╌
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"rate_limits":{"five_hour":{"used_percentage":34.7}}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"5h"* ]]
  [[ "$plain" == *"65%"* ]]
}

# ── OAuth fallback path ────────────────────────────────────────────────────────

@test "falls back to OAuth cache when stdin has no rate_limits" {
  write_oauth_cache <<'EOF'
{"five_hour":{"utilization":30,"resets_at":"2099-12-31T23:59:59Z"},"seven_day":{"utilization":50,"resets_at":"2099-12-31T23:59:59Z"}}
EOF
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"5h"* ]]
  [[ "$plain" == *"7d"* ]]
}

@test "omits rate section when no stdin rate_limits and no OAuth cache" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" != *"5h"* ]]
  [[ "$plain" != *"7d"* ]]
}

@test "OAuth fallback shows remaining percentages from utilization field" {
  # utilization=30 → remaining=70
  write_oauth_cache <<'EOF'
{"five_hour":{"utilization":30,"resets_at":"2099-12-31T23:59:59Z"},"seven_day":{"utilization":50,"resets_at":"2099-12-31T23:59:59Z"}}
EOF
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"70%"* ]]
  [[ "$plain" == *"50%"* ]]
}

# ── Reset countdown (↻) ────────────────────────────────────────────────────────

@test "shows reset countdown when OAuth cache has resets_at for a stdin limit key" {
  write_oauth_cache <<'EOF'
{"five_hour":{"utilization":30,"resets_at":"2099-12-31T23:59:59Z"},"seven_day":{"utilization":50,"resets_at":"2099-12-31T23:59:59Z"}}
EOF
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"rate_limits":{"five_hour":{"used_percentage":30},"seven_day":{"used_percentage":50}}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"↻"* ]]
}

@test "omits reset countdown when OAuth cache is absent" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"rate_limits":{"five_hour":{"used_percentage":30}}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" != *"↻"* ]]
}

@test "OAuth fallback shows reset countdown from resets_at" {
  write_oauth_cache <<'EOF'
{"five_hour":{"utilization":30,"resets_at":"2099-12-31T23:59:59Z"},"seven_day":{"utilization":0,"resets_at":"2099-12-31T23:59:59Z"}}
EOF
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"↻"* ]]
}

# ── Layout ─────────────────────────────────────────────────────────────────────

@test "uses │ separator between model and ctx section" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":50}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"│"* ]]
}

@test "no │ separator when only model is shown" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" != *"│"* ]]
}

@test "all three sections present when context window and rate limits both provided" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"Claude Sonnet"},"context_window":{"used_percentage":20},"rate_limits":{"five_hour":{"used_percentage":40}}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"Claude Sonnet"* ]]
  [[ "$plain" == *"ctx"* ]]
  [[ "$plain" == *"5h"* ]]
}

@test "rate limits separated by ╱ divider" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"rate_limits":{"five_hour":{"used_percentage":30},"seven_day":{"used_percentage":20}}}'
  plain=$(echo "$output" | strip_ansi)
  [[ "$plain" == *"╱"* ]]
}
