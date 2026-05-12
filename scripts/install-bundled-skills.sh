#!/usr/bin/env bash
set -euo pipefail

SRC_ROOT="/opt/ai-dev/skills"

sync_skill_set() {
  local source_root="$1"
  local target_root="$2"

  [[ -d "$source_root" ]] || return 0

  mkdir -p "$target_root"

  for skill_dir in "$source_root"/*; do
    [[ -d "$skill_dir" ]] || continue

    skill_name="$(basename "$skill_dir")"
    target_dir="$target_root/$skill_name"
    staging_dir="${target_dir}.tmp.$$"

    rm -rf "$staging_dir"
    cp -R "$skill_dir" "$staging_dir"
    rm -rf "$target_dir"
    mv "$staging_dir" "$target_dir"
  done
}

sync_skill_set "$SRC_ROOT/.agents" "$HOME/.agents/skills"
sync_skill_set "$SRC_ROOT/.codex" "$HOME/.codex/skills"
