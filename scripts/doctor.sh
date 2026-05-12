#!/usr/bin/env bash
set +e

echo "== Environment =="
echo "LLM_PROVIDER=${LLM_PROVIDER:-}"
echo "AGENTMEMORY_ENABLED=${AGENTMEMORY_ENABLED:-}"
echo "AGENTMEMORY_BASE_URL=${AGENTMEMORY_BASE_URL:-}"
echo "AGENTMEMORY_STREAM_URL=${AGENTMEMORY_STREAM_URL:-}"
echo "AGENTMEMORY_VIEWER_URL=${AGENTMEMORY_VIEWER_URL:-}"
echo "OLLAMA_HOST=${OLLAMA_HOST:-}"
echo "GREPAI_EMBEDDER=${GREPAI_EMBEDDER:-}"
echo "GREPAI_EMBED_MODEL=${GREPAI_EMBED_MODEL:-}"
echo "GREPAI_EMBED_DIMENSIONS=${GREPAI_EMBED_DIMENSIONS:-}"
echo

echo "== Tools =="
for bin in node npm codex opencode gitnexus serena grepai agentmemory agentmemory-mcp uv git rg jq; do
  printf '%-12s' "$bin"
  if command -v "$bin" >/dev/null 2>&1; then
    echo "OK: $(command -v "$bin")"
  else
    echo "MISSING"
  fi
done

echo
if [[ -f "$HOME/.codex/config.toml" ]]; then
  echo "== ~/.codex/config.toml =="
  sed 's/API_KEY.*/API_KEY***REDACTED***/g' "$HOME/.codex/config.toml"
else
  echo "No ~/.codex/config.toml. This is normal when no managed MCP block has recreated it."
fi

echo
if [[ -f "$HOME/.config/opencode/opencode.json" ]]; then
  echo "== ~/.config/opencode/opencode.json =="
  cat "$HOME/.config/opencode/opencode.json"
else
  echo "No ~/.config/opencode/opencode.json."
fi
