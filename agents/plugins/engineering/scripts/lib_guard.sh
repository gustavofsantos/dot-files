#!/usr/bin/env bash
# Shared precondition for all gitbutler-provenance hooks.
# Source this, then call `is_gitbutler_repo || exit 0` at the top of each hook.
#
# Layered, cheapest-to-most-authoritative. Any failure => not our concern.

is_gitbutler_repo() {
  # 1. Is the `but` binary installed at all? Coarsest, fastest bail.
  command -v but >/dev/null 2>&1 || return 1

  # 2. Are we inside a git work tree? (cheap, no `but` invocation)
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1

  # 3. Does the GitButler workspace ref exist? Authoritative that this
  #    repo is under GitButler management, without paying for a `but` call.
  git rev-parse --verify --quiet gitbutler/workspace >/dev/null 2>&1 || return 1

  return 0
}
