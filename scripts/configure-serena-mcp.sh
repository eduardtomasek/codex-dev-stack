#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.codex" "$HOME/.config/opencode"

codex_config="$HOME/.codex/config.toml"
opencode_config="$HOME/.config/opencode/opencode.json"
codex_begin="# BEGIN AI-DEV SERENA"
codex_end="# END AI-DEV SERENA"

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

cat >> "$codex_config" <<'EOF'
# BEGIN AI-DEV SERENA
[mcp_servers.serena]
command = "serena"
args = ["start-mcp-server", "--context", "codex", "--project-from-cwd"]
startup_timeout_sec = 30.0
tool_timeout_sec = 240.0
# END AI-DEV SERENA
EOF

if [[ -f "$opencode_config" ]]; then
  jq '
    .mcp = (.mcp // {}) |
    .mcp.serena = {
      "type": "local",
      "command": ["serena", "start-mcp-server", "--context", "ide", "--project-from-cwd"],
      "enabled": true
    }
  ' "$opencode_config" > "${opencode_config}.tmp"
else
  jq -n '
    {
      mcp: {
        serena: {
          type: "local",
          command: ["serena", "start-mcp-server", "--context", "ide", "--project-from-cwd"],
          enabled: true
        }
      }
    }
  ' > "${opencode_config}.tmp"
fi

mv "${opencode_config}.tmp" "$opencode_config"
