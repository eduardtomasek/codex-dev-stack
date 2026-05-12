#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/.config" "$HOME/.codex" "$HOME/.serena" "$HOME/.ssh" /workspaces
chmod 700 "$HOME/.ssh" || true

if [[ -n "${GIT_AUTHOR_NAME:-}" ]]; then git config --global user.name "$GIT_AUTHOR_NAME" || true; fi
if [[ -n "${GIT_AUTHOR_EMAIL:-}" ]]; then git config --global user.email "$GIT_AUTHOR_EMAIL" || true; fi

install-bundled-skills || true
cleanup-codex-duplicate-skills || true
configure-codex
configure-grepai-mcp
configure-serena-mcp
configure-gitnexus-mcp
configure-agentmemory

# Initialize Serena global config once if supported by installed version.
if command -v serena >/dev/null 2>&1 && [[ ! -f "$HOME/.serena/serena_config.yml" ]]; then
  serena init >/dev/null 2>&1 || true
fi

if [[ "$PWD" != "/workspaces" ]]; then
  ai-dev-init-project >/dev/null 2>&1 || true
fi

cat <<'BANNER'

AI dev container ready.

Projects mount: /workspaces

Commands:
  codex                         # OpenAI Codex CLI
  opencode                      # OpenCode CLI
  cleanup-codex-duplicate-skills # Remove old shared-skill duplicates from ~/.codex/skills
  configure-grepai-mcp          # Wire GrepAI MCP for Codex and OpenCode
  configure-serena-mcp          # Wire Serena MCP for Codex and OpenCode
  configure-gitnexus-mcp        # Wire GitNexus MCP for Codex and OpenCode
  configure-agentmemory         # Wire agentmemory MCP for Codex and OpenCode
  start-agentmemory-server      # Start the upstream agentmemory server in this container
  ai-dev-init-project           # Initialize/configure current repo for GrepAI
  configure-grepai              # Generate/update .grepai/config.yaml in current repo
  gitnexus setup                # Configure GitNexus for current repo
  gitnexus analyze              # Analyze current repo
  serena start-mcp-server --context codex --project-from-cwd
  ai-dev-doctor                 # Check installed tools and env

LLM_PROVIDER options:
  codex-login | openai | openrouter | ollama

Agent memory:
  AGENTMEMORY_ENABLED=1         # Enable Codex/OpenCode MCP wiring
  docker compose up -d agentmemory
  docker compose up -d agentmemory-server
  start-agentmemory-server
  agentmemory-mcp              # MCP stdio wrapper installed in the image
  open http://localhost:3213

BANNER

exec "$@"
