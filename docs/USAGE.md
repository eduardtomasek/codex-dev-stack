# Typical Workflows

## New project

```bash
docker compose run --rm -w /workspaces/my-project dev
gitnexus setup
codex
```

If you start directly in the repository with `-w /workspaces/my-project`, the entrypoint will also prepare `.grepai/config.yaml` in the repository root.

The entrypoint also auto-wires ripgrep MCP for:

- `codex` in `~/.codex/config.toml`
- `opencode` in `~/.config/opencode/opencode.json`

The managed Codex block uses:

```toml
[mcp_servers.ripgrep]
command = "npx"
args = ["-y", "mcp-ripgrep@latest"]
```

The entrypoint also auto-wires GrepAI MCP for:

- `codex` in `~/.codex/config.toml`
- `opencode` in `~/.config/opencode/opencode.json`

The managed Codex block uses:

```toml
[mcp_servers.grepai]
command = "grepai"
args = ["mcp-serve"]
```

The entrypoint also auto-wires Serena MCP for:

- `codex` in `~/.codex/config.toml`
- `opencode` in `~/.config/opencode/opencode.json`

The managed Codex block uses:

```toml
[mcp_servers.serena]
command = "serena"
args = ["start-mcp-server", "--context", "codex", "--project-from-cwd"]
startup_timeout_sec = 30.0
tool_timeout_sec = 240.0
```

The entrypoint also auto-wires GitNexus MCP for:

- `codex` in `~/.codex/config.toml`
- `opencode` in `~/.config/opencode/opencode.json`

The managed Codex block uses:

```toml
[mcp_servers.gitnexus]
command = "gitnexus"
args = ["mcp"]
```

If you want to use the bundled Matt Pocock engineering skills, run `/setup-matt-pocock-skills` once in that repository before using `/diagnose`, `/tdd`, `/triage`, `/to-prd`, `/to-issues`, `/zoom-out`, or `/improve-codebase-architecture`.

## agentmemory

Enable it in `.env`:

```env
AGENTMEMORY_ENABLED=1
AGENTMEMORY_III_VERSION=0.11.2
```

Start the pinned iii runtime from the host:

```bash
docker compose up -d agentmemory
```

Then either start the upstream server as a Compose service:

```bash
docker compose up -d agentmemory-server
```

Or start the dev shell and launch it inside the container:

```bash
docker compose run --rm -w /workspaces/my-project dev
start-agentmemory-server
```

When `AGENTMEMORY_ENABLED=1`, the entrypoint auto-wires MCP config for:

- `codex` in `~/.codex/config.toml`
- `opencode` in `~/.config/opencode/opencode.json`

Those MCP configs now launch the globally installed `agentmemory-mcp` binary rather than `npx`.

Recommended first-session prompt for Codex/OpenCode:

```text
Use AgentMemory for this repository: inspect recent memory sessions, recall any existing project context, and use memory_recall or memory_smart_search before asking me to re-explain prior decisions.
```

If you are wiring host-side VS Code / GitHub Copilot on macOS, install the wrapper on the host too:

```bash
npm install -g @agentmemory/mcp
```

Then use:

```json
{
  "mcpServers": {
    "agentmemory": {
      "command": "agentmemory-mcp"
    }
  }
}
```

The viewer is expected at `http://localhost:3213` once the upstream server is running.

## Switching providers

Update `.env`, then start a new shell:

```bash
docker compose run --rm dev
```

At startup, the entrypoint regenerates `~/.codex/config.toml` for `openai`, `openrouter`, or `ollama`.

For `codex-login`, it does not generate a provider block and removes any stale provider config instead, because authentication is handled by `codex login`. Managed MCP blocks such as GrepAI may still create `~/.codex/config.toml`.
