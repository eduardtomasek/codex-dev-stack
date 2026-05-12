#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.codex" "$HOME/.config/opencode"

codex_config="$HOME/.codex/config.toml"
opencode_config="$HOME/.config/opencode/opencode.json"
codex_begin="# BEGIN AI-DEV RIPGREP"
codex_end="# END AI-DEV RIPGREP"

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
# BEGIN AI-DEV RIPGREP
[mcp_servers.ripgrep]
command = "npx"
args = ["-y", "mcp-ripgrep@latest"]

[mcp_servers.ripgrep.tools.advanced-search]
approval_mode = "approve"

[mcp_servers.ripgrep.tools.search]
approval_mode = "approve"

[mcp_servers.ripgrep.tools.list-files]
approval_mode = "approve"
# END AI-DEV RIPGREP
EOF

if [[ -f "$opencode_config" ]]; then
  jq '
    .mcp = (.mcp // {}) |
    .mcp.ripgrep = {
      "type": "local",
      "command": ["npx", "-y", "mcp-ripgrep@latest"],
      "enabled": true
    }
  ' "$opencode_config" > "${opencode_config}.tmp"
else
  jq -n '
    {
      mcp: {
        ripgrep: {
          type: "local",
          command: ["npx", "-y", "mcp-ripgrep@latest"],
          enabled: true
        }
      }
    }
  ' > "${opencode_config}.tmp"
fi

mv "${opencode_config}.tmp" "$opencode_config"
