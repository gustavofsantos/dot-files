#!/usr/bin/env bats

# Tests for scripts/link-bin-files.sh
#
# Runs the real script against a from-scratch fixture repo (not the real
# dotfiles checkout). DOTFILES_DIR is derived from the script's own location
# (dirname/..), so the fixture copies the script under fixture/scripts/ and
# mirrors bin/ beside it. Hook scripts live directly in bin/ (prefixed
# hooks-*), so there's no separate agents/hooks/ executable source to mirror.

REAL_REPO="$BATS_TEST_DIRNAME/.."

setup() {
  FIXTURE=$(mktemp -d)
  FAKE_HOME=$(mktemp -d)
  export HOME="$FAKE_HOME"

  mkdir -p "$FIXTURE/scripts" "$FIXTURE/bin"
  cp "$REAL_REPO/scripts/link-bin-files.sh" "$FIXTURE/scripts/link-bin-files.sh"
  chmod +x "$FIXTURE/scripts/link-bin-files.sh"

  printf '#!/usr/bin/env bash\necho demo\n' > "$FIXTURE/bin/demo-script"
  chmod +x "$FIXTURE/bin/demo-script"
  printf '#!/usr/bin/env bash\necho demo-hook\n' > "$FIXTURE/bin/hooks-demo-hook"
  chmod +x "$FIXTURE/bin/hooks-demo-hook"
}

teardown() {
  rm -rf "$FIXTURE" "$FAKE_HOME"
}

@test "links bin/ scripts, including hooks-* hook scripts, into ~/.bin" {
  bash "$FIXTURE/scripts/link-bin-files.sh" >/dev/null
  [ -L "$HOME/.bin/demo-script" ]
  [ -L "$HOME/.bin/hooks-demo-hook" ]
}

@test "prunes a dangling ~/.bin symlink when the source script is removed" {
  bash "$FIXTURE/scripts/link-bin-files.sh" >/dev/null
  [ -L "$HOME/.bin/hooks-demo-hook" ]

  rm "$FIXTURE/bin/hooks-demo-hook"
  bash "$FIXTURE/scripts/link-bin-files.sh" >/dev/null

  [ ! -e "$HOME/.bin/hooks-demo-hook" ]
}
