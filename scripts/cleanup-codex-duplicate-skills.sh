#!/usr/bin/env bash
set -euo pipefail

SRC_ROOT="/opt/ai-dev/skills"
CODEX_SKILLS_ROOT="$HOME/.codex/skills"
MARKER_FILE="$HOME/.codex/.ai-dev-cleanup-shared-skills-v1"

[[ -d "$SRC_ROOT/.agents" ]] || exit 0
[[ -d "$CODEX_SKILLS_ROOT" ]] || exit 0
[[ ! -e "$MARKER_FILE" ]] || exit 0

for shared_skill_dir in "$SRC_ROOT/.agents"/*; do
  [[ -d "$shared_skill_dir" ]] || continue

  skill_name="$(basename "$shared_skill_dir")"
  codex_specific_dir="$SRC_ROOT/.codex/$skill_name"
  installed_codex_dir="$CODEX_SKILLS_ROOT/$skill_name"

  if [[ -e "$installed_codex_dir" && ! -e "$codex_specific_dir" ]]; then
    rm -rf "$installed_codex_dir"
  fi
done

touch "$MARKER_FILE"
