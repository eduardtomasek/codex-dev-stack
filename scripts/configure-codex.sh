#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.codex"
CONFIG="$HOME/.codex/config.toml"
PROVIDER="${LLM_PROVIDER:-codex-login}"

case "$PROVIDER" in
  codex-login)
    # Keep Codex managed auth/config. Run `codex login` manually once in the container.
    rm -f "$CONFIG"
    exit 0
    ;;
  openai)
    cat > "$CONFIG" <<TOML
model = "${OPENAI_MODEL:-gpt-5.1-codex-max}"
model_provider = "openai"

[model_providers.openai]
name = "OpenAI"
base_url = "${OPENAI_BASE_URL:-https://api.openai.com/v1}"
env_key = "OPENAI_API_KEY"
TOML
    ;;
  openrouter)
    cat > "$CONFIG" <<TOML
model = "${OPENROUTER_MODEL:-anthropic/claude-sonnet-4.5}"
model_provider = "openrouter"

[model_providers.openrouter]
name = "OpenRouter"
base_url = "${OPENROUTER_BASE_URL:-https://openrouter.ai/api/v1}"
env_key = "OPENROUTER_API_KEY"
TOML
    ;;
  ollama)
    cat > "$CONFIG" <<TOML
model = "${OLLAMA_MODEL:-qwen2.5-coder:32b}"
model_provider = "ollama"

[model_providers.ollama]
name = "Ollama"
base_url = "${OLLAMA_HOST:-http://host.docker.internal:11434}/v1"
env_key = "OLLAMA_API_KEY"
TOML
    ;;
  *)
    echo "Unknown LLM_PROVIDER: $PROVIDER" >&2
    exit 1
    ;;
esac
