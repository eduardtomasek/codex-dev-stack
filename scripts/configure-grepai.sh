#!/usr/bin/env bash
set -euo pipefail

mkdir -p .grepai
CONFIG=.grepai/config.yaml
EMBEDDER="${GREPAI_EMBEDDER:-ollama}"
MODEL="${GREPAI_EMBED_MODEL:-nomic-embed-text-v2-moe}"
ENDPOINT="${GREPAI_EMBED_ENDPOINT:-http://host.docker.internal:11434}"
DIMENSIONS="${GREPAI_EMBED_DIMENSIONS:-}"

if [[ -z "$DIMENSIONS" ]]; then
  case "$EMBEDDER:$MODEL" in
    ollama:nomic-embed-text|ollama:nomic-embed-text-v2-moe|lmstudio:text-embedding-nomic-embed-text-v1.5)
      DIMENSIONS=768
      ;;
    openai:text-embedding-3-small)
      DIMENSIONS=1536
      ;;
    openai:text-embedding-3-large)
      DIMENSIONS=3072
      ;;
  esac
fi

if [[ ! -f "$CONFIG" ]] && command -v grepai >/dev/null 2>&1; then
  grepai init --yes --provider "$EMBEDDER" --model "$MODEL" >/dev/null
fi

TMP="$(mktemp)"
if [[ -f "$CONFIG" ]]; then
  awk '
    BEGIN { skip = 0 }
    /^embedder:/ { skip = 1; next }
    skip && /^[^[:space:]]/ { skip = 0 }
    !skip { print }
  ' "$CONFIG" > "$TMP"
else
  : > "$TMP"
fi

cat >> "$TMP" <<YAML
embedder:
  provider: "$EMBEDDER"
  model: "$MODEL"
  endpoint: "$ENDPOINT"
YAML

if [[ -n "$DIMENSIONS" ]]; then
  cat >> "$TMP" <<YAML
  dimensions: $DIMENSIONS
YAML
fi

mv "$TMP" "$CONFIG"

echo "Wrote $CONFIG"
