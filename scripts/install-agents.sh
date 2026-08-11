#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
export DOTFILES_DIR

# ── rules-sync: derive .claude/rules and .cursor/rules from agents/rules ───────
#
# Subcommand usage: install-agents.sh rules-sync [--source DIR]
#   [--claude-dest DIR] [--cursor-dest DIR] [--dry-run]
#
# See the embedded module docstring below for the frontmatter-promotion and
# manifest-pruning rules this implements.
rules_sync() {
  python3 - "$@" <<'PYEOF'
"""
rules-sync -- derive .claude/rules and .cursor/rules from the generic agents/rules source.

The source of truth is one Markdown file per rule under agents/rules/, whose
frontmatter nests each harness's own config under a top-level key:

  ---
  claude:
    paths:
      - "**/*.sql"
  cursor:
    globs: "**/*.sql"
  ---

For each harness, rules-sync promotes that harness's block to the generated
file's own top-level frontmatter (dedented, verbatim -- no YAML round-trip, so
quoting and list formatting survive unchanged) and carries the body through
untouched. An empty block (`claude: {}`) means "no scoping" and generates a
file with no frontmatter at all -- this repo's convention for an always-apply
rule.

Each destination directory keeps a `.rules-sync-manifest` listing the
basenames a prior run generated there. When a source rule disappears, the
next run deletes only the destination files it previously generated for that
rule -- a file in the destination that was never in the manifest (hand-made,
or from another tool) is left untouched.

Usage:
  rules-sync [--source DIR] [--claude-dest DIR] [--cursor-dest DIR] [--dry-run]

Defaults (relative to the repo root):
  --source       agents/rules
  --claude-dest  .claude/rules
  --cursor-dest  .cursor/rules

Idempotent: re-running with unchanged sources reproduces the same output.
"""

import os
import re
import sys

DOTFILES_DIR = os.environ["DOTFILES_DIR"]
MANIFEST_NAME = ".rules-sync-manifest"

FRONTMATTER_RE = re.compile(r"\A---[ \t]*\n(.*?\n)---[ \t]*\n?(.*)\Z", re.S)
TOP_LEVEL_KEY_RE = re.compile(r"\A([A-Za-z0-9_-]+):(.*)")


def parse_args(argv):
    opts = {
        "source": os.path.join(DOTFILES_DIR, "agents", "rules"),
        "claude_dest": os.path.join(DOTFILES_DIR, ".claude", "rules"),
        "cursor_dest": os.path.join(DOTFILES_DIR, ".cursor", "rules"),
        "dry_run": False,
    }
    args = list(argv)
    while args:
        arg = args.pop(0)
        if arg == "--source":
            opts["source"] = args.pop(0)
        elif arg == "--claude-dest":
            opts["claude_dest"] = args.pop(0)
        elif arg == "--cursor-dest":
            opts["cursor_dest"] = args.pop(0)
        elif arg == "--dry-run":
            opts["dry_run"] = True
        elif arg in ("-h", "--help"):
            print(__doc__.strip())
            sys.exit(0)
        else:
            print(f"rules-sync: unknown argument {arg!r}", file=sys.stderr)
            sys.exit(2)
    return opts


def split_rule(text):
    """Split "---\\n<frontmatter>\\n---\\n<body>" into (frontmatter_text, body),
    where frontmatter_text keeps its trailing newline. Returns (None, text)
    when the file has no leading frontmatter block."""
    m = FRONTMATTER_RE.match(text)
    if not m:
        return None, text
    return m.group(1), m.group(2)


def top_level_key(line):
    """(key, inline_remainder) for a top-level frontmatter line (zero indent),
    or None for a continuation line: indented block content, list items,
    blanks."""
    m = TOP_LEVEL_KEY_RE.match(line)
    if not m:
        return None
    return m.group(1), m.group(2).strip()


def extract_block(frontmatter_text, harness):
    """Extract one harness's block from a frontmatter block of text, dedented
    by its 2-space indent. Returns "" for an empty block (`harness: {}`, or a
    key with no children) and None when the harness key is absent entirely."""
    lines = frontmatter_text.splitlines(keepends=True)
    key = None
    idx = None
    for i, line in enumerate(lines):
        k = top_level_key(line)
        if k and k[0] == harness:
            key, idx = k, i
            break
    if idx is None:
        return None

    inline = key[1]
    children = []
    j = idx + 1
    while j < len(lines) and re.match(r"\A[ \t]", lines[j]):
        children.append(lines[j])
        j += 1

    if not children and inline in ("", "{}"):
        return ""

    return "".join(line[2:] if line.startswith("  ") else line for line in children)


def render_rule(block, body):
    if not block:
        return body
    return f"---\n{block}---\n{body}"


def source_rule_files(source):
    return sorted(
        os.path.join(source, name)
        for name in os.listdir(source)
        if name.endswith(".md")
    )


def manifest_path(dest):
    return os.path.join(dest, MANIFEST_NAME)


def read_manifest(dest):
    try:
        with open(manifest_path(dest), encoding="utf-8") as f:
            return {line.strip() for line in f if line.strip()}
    except FileNotFoundError:
        return set()


def write_manifest(dest, names):
    with open(manifest_path(dest), "w", encoding="utf-8") as f:
        f.writelines(f"{name}\n" for name in sorted(names))


def prune_stale(dest, previous_names, live_names, dry_run):
    for name in sorted(previous_names - live_names):
        path = os.path.join(dest, name)
        if not os.path.isfile(path):
            continue
        print(f"  prune {name}")
        if not dry_run:
            os.remove(path)


def sync_harness(source, dest, harness, ext, dry_run, warn_on_empty=False):
    print(f"{harness} -> {dest}")
    if not dry_run:
        os.makedirs(dest, exist_ok=True)

    previous_names = read_manifest(dest)
    live_names = set()

    for path in source_rule_files(source):
        name = os.path.basename(path)
        stem = os.path.splitext(name)[0]
        with open(path, encoding="utf-8") as f:
            raw = f.read()
        frontmatter, body = split_rule(raw)
        if frontmatter is None:
            print(f"  skip  {name} (no frontmatter block)", file=sys.stderr)
            continue

        block = extract_block(frontmatter, harness)
        if block is None:
            print(f"  skip  {name} (no {harness}: block)", file=sys.stderr)
            continue
        if block == "" and warn_on_empty:
            print(
                f"  warn  {name} has an empty {harness}: block — will not auto-attach in Cursor",
                file=sys.stderr,
            )

        dest_name = f"{stem}.{ext}"
        live_names.add(dest_name)
        print(f"  gen   {dest_name}")
        if dry_run:
            continue

        with open(os.path.join(dest, dest_name), "w", encoding="utf-8") as f:
            f.write(render_rule(block, body))

    prune_stale(dest, previous_names, live_names, dry_run)
    if not dry_run:
        write_manifest(dest, live_names)


def main(argv):
    opts = parse_args(argv)

    if not os.path.isdir(opts["source"]):
        print(f"rules-sync: source not found: {opts['source']}", file=sys.stderr)
        return 1

    sync_harness(opts["source"], opts["claude_dest"], "claude", "md", opts["dry_run"])
    sync_harness(
        opts["source"],
        opts["cursor_dest"],
        "cursor",
        "mdc",
        opts["dry_run"],
        warn_on_empty=True,
    )
    return 0


sys.exit(main(sys.argv[1:]))
PYEOF
}

# ── agents-sync: derive .claude/agents and .claude/commands ────────────────────
#
# Subcommand usage: install-agents.sh agents-sync [--agents-source DIR]
#   [--agents-dest DIR] [--commands-source DIR] [--commands-dest DIR] [--dry-run]
agents_sync() {
  python3 - "$@" <<'PYEOF'
"""
agents-sync -- derive .claude/agents and .claude/commands from the generic
agents/agents and agents/commands sources.

Each source Markdown file's frontmatter carries shared top-level keys (e.g.
`name`, `description`) plus an optional harness-specific overlay nested under
a `claude:` key:

  ---
  name: clojure-advisor
  description: A second pair of eyes on Clojure code.
  claude:
    tools: Read, Grep, Glob
    model: inherit
  ---

agents-sync merges these into the destination file's own top-level
frontmatter -- shared keys first (in their original order), then the
claude: block's own keys (dedented, in their original order) -- and carries
the body through untouched. A source file with no claude: block generates a
destination with just the shared keys.

Each destination directory keeps a `.agents-sync-manifest` listing the
basenames a prior run generated there, so a removed source rule's generated
file is pruned on the next run without ever touching a file the script did
not itself generate.

Usage:
  agents-sync [--agents-source DIR] [--agents-dest DIR]
              [--commands-source DIR] [--commands-dest DIR] [--dry-run]

Defaults (relative to the repo root):
  --agents-source    agents/agents
  --agents-dest      .claude/agents
  --commands-source  agents/commands
  --commands-dest    .claude/commands

Idempotent: re-running with unchanged sources reproduces the same output.
"""

import os
import re
import sys

DOTFILES_DIR = os.environ["DOTFILES_DIR"]
MANIFEST_NAME = ".agents-sync-manifest"

FRONTMATTER_RE = re.compile(r"\A---[ \t]*\n(.*?\n)---[ \t]*\n?(.*)\Z", re.S)
TOP_LEVEL_KEY_RE = re.compile(r"\A([A-Za-z0-9_-]+):(.*)")

HARNESS_KEYS = {"claude", "cursor"}


def parse_args(argv):
    opts = {
        "agents_source": os.path.join(DOTFILES_DIR, "agents", "agents"),
        "agents_dest": os.path.join(DOTFILES_DIR, ".claude", "agents"),
        "commands_source": os.path.join(DOTFILES_DIR, "agents", "commands"),
        "commands_dest": os.path.join(DOTFILES_DIR, ".claude", "commands"),
        "dry_run": False,
    }
    args = list(argv)
    while args:
        arg = args.pop(0)
        if arg == "--agents-source":
            opts["agents_source"] = args.pop(0)
        elif arg == "--agents-dest":
            opts["agents_dest"] = args.pop(0)
        elif arg == "--commands-source":
            opts["commands_source"] = args.pop(0)
        elif arg == "--commands-dest":
            opts["commands_dest"] = args.pop(0)
        elif arg == "--dry-run":
            opts["dry_run"] = True
        elif arg in ("-h", "--help"):
            print(__doc__.strip())
            sys.exit(0)
        else:
            print(f"agents-sync: unknown argument {arg!r}", file=sys.stderr)
            sys.exit(2)
    return opts


def split_source(text):
    """Split "---\\n<frontmatter>\\n---\\n<body>" into (frontmatter_text, body),
    where frontmatter_text keeps its trailing newline. Returns (None, text)
    when the file has no leading frontmatter block."""
    m = FRONTMATTER_RE.match(text)
    if not m:
        return None, text
    return m.group(1), m.group(2)


def top_level_key(line):
    """(key, inline_remainder) for a top-level frontmatter line (zero indent),
    or None for a continuation line: indented block content, list items,
    blanks."""
    m = TOP_LEVEL_KEY_RE.match(line)
    if not m:
        return None
    return m.group(1), m.group(2).strip()


def merge_frontmatter(frontmatter_text, harness):
    """Merge the shared top-level keys with the named harness's nested
    overlay block, dedented by its 2-space indent. Shared keys keep their
    original order; the harness block's own keys follow, in their original
    order. A source with no block for this harness yields just the shared
    keys."""
    lines = frontmatter_text.splitlines(keepends=True)
    shared = []
    overlay = []
    i = 0
    while i < len(lines):
        key = top_level_key(lines[i])
        if key and key[0] in HARNESS_KEYS:
            i += 1
            children = []
            while i < len(lines) and re.match(r"\A[ \t]", lines[i]):
                children.append(lines[i])
                i += 1
            if key[0] == harness:
                overlay = children
            continue
        shared.append(lines[i])
        i += 1

    dedented = [line[2:] if line.startswith("  ") else line for line in overlay]
    return "".join(shared) + "".join(dedented)


def render(frontmatter, body):
    return f"---\n{frontmatter}---\n{body}"


def source_files(source):
    return sorted(
        os.path.join(source, name)
        for name in os.listdir(source)
        if name.endswith(".md")
    )


def manifest_path(dest):
    return os.path.join(dest, MANIFEST_NAME)


def read_manifest(dest):
    try:
        with open(manifest_path(dest), encoding="utf-8") as f:
            return {line.strip() for line in f if line.strip()}
    except FileNotFoundError:
        return set()


def write_manifest(dest, names):
    with open(manifest_path(dest), "w", encoding="utf-8") as f:
        f.writelines(f"{name}\n" for name in sorted(names))


def prune_stale(dest, previous_names, live_names, dry_run):
    for name in sorted(previous_names - live_names):
        path = os.path.join(dest, name)
        if not os.path.isfile(path):
            continue
        print(f"  prune {name}")
        if not dry_run:
            os.remove(path)


def sync_kind(source, dest, kind, dry_run):
    if not os.path.isdir(source):
        print(f"agents-sync: source not found: {source}", file=sys.stderr)
        return False

    print(f"{kind} -> {dest}")
    if not dry_run:
        os.makedirs(dest, exist_ok=True)

    previous_names = read_manifest(dest)
    live_names = set()

    for path in source_files(source):
        name = os.path.basename(path)
        with open(path, encoding="utf-8") as f:
            raw = f.read()
        frontmatter, body = split_source(raw)
        if frontmatter is None:
            print(f"  skip  {name} (no frontmatter block)", file=sys.stderr)
            continue

        merged = merge_frontmatter(frontmatter, "claude")
        live_names.add(name)
        print(f"  gen   {name}")
        if dry_run:
            continue

        with open(os.path.join(dest, name), "w", encoding="utf-8") as f:
            f.write(render(merged, body))

    prune_stale(dest, previous_names, live_names, dry_run)
    if not dry_run:
        write_manifest(dest, live_names)
    return True


def main(argv):
    opts = parse_args(argv)

    if not sync_kind(opts["agents_source"], opts["agents_dest"], "agents", opts["dry_run"]):
        return 1
    if not sync_kind(
        opts["commands_source"], opts["commands_dest"], "commands", opts["dry_run"]
    ):
        return 1
    return 0


sys.exit(main(sys.argv[1:]))
PYEOF
}

# ── hooks-sync: compile agents/hooks/{claude.settings.json,cursor.hooks.json} ──
#
# Subcommand usage: install-agents.sh hooks-sync [--claude-source FILE]
#   [--claude-dest FILE] [--cursor-source FILE] [--cursor-dest FILE] [--dry-run]
hooks_sync() {
  python3 - "$@" <<'PYEOF'
"""
hooks-sync -- compile agents/hooks/{claude.settings.json,cursor.hooks.json}
into the real per-harness hook config.

Claude hooks live inside .claude/settings.json alongside permissions/env,
which stay hand-maintained: hooks-sync merges only the "hooks" key from
agents/hooks/claude.settings.json into the existing settings.json, leaving
every other key untouched.

Cursor hooks have their own dedicated file (nothing else lives in
.cursor/hooks.json), so hooks-sync generates it wholesale from
agents/hooks/cursor.hooks.json.

Usage:
  hooks-sync [--claude-source FILE] [--claude-dest FILE]
             [--cursor-source FILE] [--cursor-dest FILE] [--dry-run]

Defaults (relative to the repo root):
  --claude-source  agents/hooks/claude.settings.json
  --claude-dest    .claude/settings.json
  --cursor-source  agents/hooks/cursor.hooks.json
  --cursor-dest    .cursor/hooks.json

Idempotent: re-running with unchanged sources reproduces the same output.
"""

import json
import os
import sys

DOTFILES_DIR = os.environ["DOTFILES_DIR"]


def parse_args(argv):
    opts = {
        "claude_source": os.path.join(DOTFILES_DIR, "agents", "hooks", "claude.settings.json"),
        "claude_dest": os.path.join(DOTFILES_DIR, ".claude", "settings.json"),
        "cursor_source": os.path.join(DOTFILES_DIR, "agents", "hooks", "cursor.hooks.json"),
        "cursor_dest": os.path.join(DOTFILES_DIR, ".cursor", "hooks.json"),
        "dry_run": False,
    }
    args = list(argv)
    while args:
        arg = args.pop(0)
        if arg == "--claude-source":
            opts["claude_source"] = args.pop(0)
        elif arg == "--claude-dest":
            opts["claude_dest"] = args.pop(0)
        elif arg == "--cursor-source":
            opts["cursor_source"] = args.pop(0)
        elif arg == "--cursor-dest":
            opts["cursor_dest"] = args.pop(0)
        elif arg == "--dry-run":
            opts["dry_run"] = True
        elif arg in ("-h", "--help"):
            print(__doc__.strip())
            sys.exit(0)
        else:
            print(f"hooks-sync: unknown argument {arg!r}", file=sys.stderr)
            sys.exit(2)
    return opts


def read_json(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def write_json(path, data, dry_run):
    print(f"  gen   {path}")
    if dry_run:
        return
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def sync_claude(source, dest, dry_run):
    print(f"claude -> {dest}")
    if not os.path.isfile(source):
        print(f"  skip  source not found: {source}", file=sys.stderr)
        return

    src = read_json(source)
    dest_data = read_json(dest) if os.path.isfile(dest) else {}
    dest_data["hooks"] = src.get("hooks", {})
    write_json(dest, dest_data, dry_run)


def sync_cursor(source, dest, dry_run):
    print(f"cursor -> {dest}")
    if not os.path.isfile(source):
        print(f"  skip  source not found: {source}", file=sys.stderr)
        return

    write_json(dest, read_json(source), dry_run)


def main(argv):
    opts = parse_args(argv)
    sync_claude(opts["claude_source"], opts["claude_dest"], opts["dry_run"])
    sync_cursor(opts["cursor_source"], opts["cursor_dest"], opts["dry_run"])
    return 0


sys.exit(main(sys.argv[1:]))
PYEOF
}

# Symlink every file matching $1 into dir $2, then remove any symlink in $2
# whose source no longer exists (a file removed from the dotfiles repo).
install_and_prune_symlinks() {
  local glob="$1" dest="$2" file name
  mkdir -p "$dest"
  for file in $glob; do
    [ -f "$file" ] || continue
    name=$(basename "$file")
    ln -sf "$file" "$dest/$name"
  done
  find "$dest" -maxdepth 1 -type l | while read -r link; do
    [ -e "$link" ] || rm "$link"
  done
}

run_full_install() {
  echo "Compiling rules..."
  rules_sync >/dev/null \
    && echo "Compiling rules... OK" \
    || echo "Compiling rules... FAILED (non-fatal)"

  echo "Compiling agents and commands..."
  agents_sync >/dev/null \
    && echo "Compiling agents and commands... OK" \
    || echo "Compiling agents and commands... FAILED (non-fatal)"

  echo "Compiling hooks..."
  hooks_sync >/dev/null \
    && echo "Compiling hooks... OK" \
    || echo "Compiling hooks... FAILED (non-fatal)"

  # Every skill lives inside a plugin under agents/plugins/<name>/ -- installing
  # a plugin is the only way skills reach either harness. Symlinking the whole
  # plugin directory (rather than compiling/transforming its contents) makes it
  # a Claude Code skills-directory plugin (`<name>@skills-dir`, discovered in
  # place) and a Cursor local plugin, both live-edited from the one source.
  echo "Installing plugins..."
  mkdir -p "$HOME/.claude/skills" "$HOME/.cursor/plugins/local"
  for plugin in "$DOTFILES_DIR"/agents/plugins/*/; do
    [ -f "$plugin/.claude-plugin/plugin.json" ] || continue
    name=$(basename "${plugin%/}")
    ln -sfn "${plugin%/}" "$HOME/.claude/skills/$name"
    ln -sfn "${plugin%/}" "$HOME/.cursor/plugins/local/$name"
  done
  # prune dangling plugin symlinks (removed from dotfiles)
  find "$HOME/.claude/skills" "$HOME/.cursor/plugins/local" -maxdepth 1 -type l | while read -r link; do
    [ -e "$link" ] || rm "$link"
  done
  echo "Installing plugins... OK"

  echo "Installing custom subagents..."
  install_and_prune_symlinks "$DOTFILES_DIR/.claude/agents/*" "$HOME/.claude/agents"
  echo "Installing custom subagents... OK"

  echo "Installing custom commands..."
  mkdir -p "$HOME/.claude/commands"
  for cmd in "$DOTFILES_DIR"/.claude/commands/*.md; do
    [ -f "$cmd" ] || continue
    name=$(basename "$cmd")
    ln -sf "$cmd" "$HOME/.claude/commands/$name"
  done
  echo "Installing custom commands... OK"

  echo "Installing custom themes..."
  mkdir -p "$HOME/.claude/themes"
  for theme in "$DOTFILES_DIR"/.claude/themes/*.json; do
    [ -f "$theme" ] || continue
    name=$(basename "$theme")
    ln -sf "$theme" "$HOME/.claude/themes/$name"
  done
  echo "Installing custom themes... OK"

  echo "Installing custom rules..."
  install_and_prune_symlinks "$DOTFILES_DIR/.claude/rules/*.md" "$HOME/.claude/rules"
  echo "Installing custom rules... OK"

  echo "Installing custom workflows..."
  mkdir -p "$HOME/.claude/workflows"
  for wf in "$DOTFILES_DIR"/.claude/workflows/*; do
    [ -f "$wf" ] || continue
    name=$(basename "$wf")
    ln -sf "$wf" "$HOME/.claude/workflows/$name"
  done
  echo "Installing custom workflows... OK"

  echo "Installing Cursor rules..."
  install_and_prune_symlinks "$DOTFILES_DIR/.cursor/rules/*.mdc" "$HOME/.cursor/rules"
  echo "Installing Cursor rules... OK"

  echo "Installing Cursor hooks..."
  mkdir -p "$HOME/.cursor"
  if [ -f "$DOTFILES_DIR/.cursor/hooks.json" ]; then
    ln -sf "$DOTFILES_DIR/.cursor/hooks.json" "$HOME/.cursor/hooks.json"
    echo "Installing Cursor hooks... OK"
  else
    echo "Installing Cursor hooks... skipped (no .cursor/hooks.json)"
  fi

  echo "Merging Claude settings..."
  DOTFILES_SETTINGS="$DOTFILES_DIR/.claude/settings.json"
  GLOBAL_SETTINGS="$HOME/.claude/settings.json"

  if [ ! -f "$DOTFILES_SETTINGS" ]; then
    echo "Merging Claude settings... skipped (no dotfiles settings.json)"
  elif [ ! -f "$GLOBAL_SETTINGS" ]; then
    cp "$DOTFILES_SETTINGS" "$GLOBAL_SETTINGS"
    echo "Merging Claude settings... OK (installed fresh)"
  else
    # Global wins on scalar/object conflicts; permission arrays are unioned.
    # Hooks are compiled output (hooks-sync), not hand-edited per machine, so
    # dotfiles fully replaces global hooks per event rather than unioning —
    # a union can never drop an entry a rename superseded, so renaming a hook
    # in the repo would otherwise leave the old, now-broken command duplicated
    # in every machine's global settings.json forever.
    # .[0] = global (machine-specific), .[1] = dotfiles (baseline defaults).
    # Written via a same-directory temp file + mv (atomic rename) rather than a
    # direct `>` redirect, so a concurrent reader (another setup.sh run, or
    # Claude Code itself persisting a setting) can never observe a truncated
    # file mid-write. Same directory as GLOBAL_SETTINGS keeps mv on one
    # filesystem, since a cross-filesystem mv falls back to non-atomic copy.
    tmp=$(mktemp "$GLOBAL_SETTINGS.XXXXXX")
    if jq -s '
      .[0] as $g |
      .[1] as $d |
      $d * $g |
      .permissions.allow = (($g.permissions.allow // []) + ($d.permissions.allow // []) | unique | sort) |
      .permissions.deny  = (($g.permissions.deny  // []) + ($d.permissions.deny  // []) | unique | sort) |
      .permissions.ask   = (($g.permissions.ask   // []) + ($d.permissions.ask   // []) | unique | sort) |
      .hooks = ($d.hooks // {})
    ' "$GLOBAL_SETTINGS" "$DOTFILES_SETTINGS" > "$tmp"; then
      mv "$tmp" "$GLOBAL_SETTINGS"
      echo "Merging Claude settings... OK"
    else
      rm -f "$tmp"
      echo "Merging Claude settings... FAILED" >&2
      exit 1
    fi
  fi
}

case "${1:-}" in
  rules-sync)
    shift
    rules_sync "$@"
    ;;
  agents-sync)
    shift
    agents_sync "$@"
    ;;
  hooks-sync)
    shift
    hooks_sync "$@"
    ;;
  *)
    run_full_install
    ;;
esac
