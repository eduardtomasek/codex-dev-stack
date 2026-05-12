#!/usr/bin/env bash
set -euo pipefail

enabled="${AGENTMEMORY_ENABLED:-0}"

if [[ "$enabled" != "1" ]]; then
  exit 0
fi

mkdir -p "$HOME/.codex" "$HOME/.config/opencode"

codex_config="$HOME/.codex/config.toml"
opencode_config="$HOME/.config/opencode/opencode.json"
codex_begin="# BEGIN AI-DEV AGENTMEMORY"
codex_end="# END AI-DEV AGENTMEMORY"
mcp_command="agentmemory-mcp"

if [[ -x "/home/dev/.npm-global/bin/agentmemory-mcp" ]]; then
  mcp_command="/home/dev/.npm-global/bin/agentmemory-mcp"
fi

strip_managed_codex_block() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    return 0
  fi

  awk -v begin="$codex_begin" -v end="$codex_end" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    skip != 1 { print }
  ' "$file" > "${file}.tmp"

  mv "${file}.tmp" "$file"
}

strip_managed_codex_block "$codex_config"

if [[ -s "$codex_config" ]]; then
  printf '\n' >> "$codex_config"
fi

cat >> "$codex_config" <<EOF
# BEGIN AI-DEV AGENTMEMORY
[mcp_servers.agentmemory]
command = "$mcp_command"
# END AI-DEV AGENTMEMORY
EOF

if [[ -f "$opencode_config" ]]; then
  jq --arg cmd "$mcp_command" '
    .mcp = (.mcp // {}) |
    .mcp.agentmemory = {
      "type": "local",
      "command": [$cmd],
      "enabled": true
    }
  ' "$opencode_config" > "${opencode_config}.tmp"
else
  jq -n --arg cmd "$mcp_command" '
    {
      mcp: {
        agentmemory: {
          type: "local",
          command: [$cmd],
          enabled: true
        }
      }
    }
  ' > "${opencode_config}.tmp"
fi

mv "${opencode_config}.tmp" "$opencode_config"
