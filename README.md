# AI Dev Container

A detailed Docker-based development stack for AI-assisted software work. The goal of this project is to provide one isolated environment where the main coding CLIs, LLM provider settings, and code-intelligence tools are ready to use immediately after startup.

Included tools:

- `codex` for OpenAI Codex CLI
- `opencode` for OpenCode CLI
- `grepai` for semantic search and call tracing
- `serena` for symbol-aware navigation and MCP server support
- `gitnexus` for knowledge-graph-based code analysis
- standard developer utilities such as `git`, `rg`, `jq`, `node`, `npm`, and `python3`
- `bubblewrap` for Codex Linux sandbox prerequisites

This repository is designed so that:

- your projects stay on the host machine
- the container has a persistent home directory for logins and tool config
- switching between LLM providers is simple
- optional `agentmemory` wiring can be enabled for Codex and OpenCode
- GrepAI embeddings can run locally through Ollama
- the environment is usable immediately after container startup

## What this project solves

When using Codex, OpenCode, or similar AI coding agents, the same problems tend to repeat:

- your host machine ends up with a mix of CLI versions
- each project drifts into different local setup conventions
- switching between OpenAI, OpenRouter, and Ollama becomes messy
- semantic tooling such as GrepAI or GitNexus is often not initialized
- login state and local configuration are hard to carry across environments

This repository solves that with a single container image:

- the image installs the main tools
- [`docker-compose.yml`](./docker-compose.yml) passes provider settings through environment variables
- the entrypoint configures Codex for the selected provider
- the entrypoint installs bundled skills into the user's home directory
- the persistent `ai-dev-home` volume keeps login state and user config between runs
- when the container starts directly inside a Git repository, it can automatically prepare the GrepAI project config

## Architecture

### Runtime model

- `dev` is the interactive shell container for daily work
- `agentmemory` is an optional pinned `iii` sidecar for memory workflows
- host projects are mounted into `/workspaces`
- the `dev` user's home directory is persisted in `/home/dev`

### Persistent data

- `ai-dev-home`
  stores `~/.codex`, `~/.serena`, `~/.ssh`, npm/uv tool state, and other user config

### Why `/workspaces` and `/home/dev` are separate

- `/workspaces` contains your mounted host projects
- `/home/dev` contains persistent container-side user configuration

Practical consequences:

- `codex login` only needs to be done once
- Serena global initialization does not need to run every session
- your repositories remain on the host and are not baked into the image

## Repository layout

- [`./Dockerfile`](./Dockerfile)
  builds the image and installs the CLI tools
- [`./docker-compose.yml`](./docker-compose.yml)
  defines services, volumes, and environment variables
- [`./scripts/entrypoint.sh`](./scripts/entrypoint.sh)
  runs bootstrap logic when the container starts
- [`./scripts/configure-codex.sh`](./scripts/configure-codex.sh)
  generates `~/.codex/config.toml` for the selected provider
- [`./scripts/configure-agentmemory.sh`](./scripts/configure-agentmemory.sh)
  adds managed `agentmemory` MCP config for Codex and OpenCode when enabled
- [`./scripts/configure-grepai-mcp.sh`](./scripts/configure-grepai-mcp.sh)
  adds managed `grepai mcp-serve` MCP config for Codex and OpenCode
- [`./scripts/configure-serena-mcp.sh`](./scripts/configure-serena-mcp.sh)
  adds managed Serena MCP config for Codex and OpenCode
- [`./scripts/configure-gitnexus-mcp.sh`](./scripts/configure-gitnexus-mcp.sh)
  adds managed GitNexus MCP config for Codex and OpenCode
- [`./scripts/configure-grepai.sh`](./scripts/configure-grepai.sh)
  creates or updates `.grepai/config.yaml`
- [`./scripts/init-project.sh`](./scripts/init-project.sh)
  prepares GrepAI config in the root of the current Git repository
- [`./scripts/install-bundled-skills.sh`](./scripts/install-bundled-skills.sh)
  syncs bundled skills from `skills/.codex` and `skills/.agents` into the matching home directories
- [`./scripts/doctor.sh`](./scripts/doctor.sh)
  reports installed tools and active environment settings
- [`./skills/.agents/karpathy-guidelines/SKILL.md`](./skills/.agents/karpathy-guidelines/SKILL.md)
  bundled default skill available after startup
- [`./skills/.agents/setup-matt-pocock-skills/SKILL.md`](./skills/.agents/setup-matt-pocock-skills/SKILL.md)
  repo-specific initializer for the bundled Matt Pocock engineering skills
- [`./docs/USAGE.md`](./docs/USAGE.md)
  shorter workflow reference

## Quick start

### 1. Create `.env`

```bash
cp .env.example .env
```

The most important values are:

```env
PROJECTS_DIR=/absolute/path/to/your/projects
LLM_PROVIDER=codex-login
TZ=Europe/Prague
AGENTMEMORY_ENABLED=0
```

`PROJECTS_DIR` should point to the host directory that contains the repositories you want to work with inside the container.

Example:

```env
PROJECTS_DIR=/path/to/your/projects
```

### 2. Build the image

```bash
docker compose build dev
```

If you change bundled skills under `skills/` or startup scripts under `scripts/`, rebuild the image again. `docker compose down` / `up` alone is not enough, because those files are baked into the image.

### 3. Start a shell

```bash
docker compose run --rm dev
```

Then move into a mounted project:

```bash
cd /workspaces/my-project
```

### 4. Optional: enable `agentmemory`

Enable it in `.env`:

```env
AGENTMEMORY_ENABLED=1
AGENTMEMORY_III_VERSION=0.11.2
```

Start the pinned `iii` sidecar:

```bash
docker compose up -d agentmemory
```

Then either start the upstream server as a Compose service:

```bash
docker compose up -d agentmemory-server
```

Or start your dev shell and run it manually:

```bash
docker compose run --rm -w /workspaces/my-project dev
start-agentmemory-server
```

When enabled, the image also installs both `@agentmemory/mcp` and `@agentmemory/agentmemory` globally, and the entrypoint wires `agentmemory-mcp` into both `~/.codex/config.toml` and `~/.config/opencode/opencode.json`. The viewer is expected at `http://localhost:3213` after the upstream server starts.

## Recommended startup pattern

If you want GrepAI project configuration to be prepared automatically, start the container directly in the repository you want to work on:

```bash
docker compose run --rm -w /workspaces/my-project dev
```

In that mode, the entrypoint will:

- sync bundled skills from `skills/.codex` and `skills/.agents` into the matching home directories
- configure Codex for the selected provider
- configure `agentmemory` MCP for Codex and OpenCode when `AGENTMEMORY_ENABLED=1`
- initialize Serena global config once, if it does not exist yet
- call `ai-dev-init-project` if the current directory is inside a Git repository
- create or update `.grepai/config.yaml` in the repository root

If you start only in `/workspaces`, project auto-init does not run because there is no single repository to target.

## LLM provider modes

The stack is driven by `LLM_PROVIDER`.

Supported values:

- `codex-login`
- `openai`
- `openrouter`
- `ollama`

### A) `codex-login`

Use this when you want Codex authenticated through your ChatGPT subscription login instead of an API key.

`.env`:

```env
LLM_PROVIDER=codex-login
```

After container startup, run once:

```bash
codex login
```

Behavior in this mode:

- `configure-codex` does not generate a provider config
- if an old `~/.codex/config.toml` exists from another provider, it is removed
- `configure-grepai-mcp` may then recreate `~/.codex/config.toml` with only managed MCP blocks
- authentication is then managed by `codex login`

This matters when switching back from API providers to login-based usage so stale provider config does not remain behind.

### B) `openai`

Use this for direct OpenAI API access.

`.env`:

```env
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-...
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-5.1-codex-max
```

On startup, the entrypoint creates `~/.codex/config.toml` with the `openai` provider.

Use this mode if:

- you want explicit API-key-based operation
- you do not want interactive login
- you need predictable CI-style configuration

### C) `openrouter`

Use this for OpenRouter-backed model access.

`.env`:

```env
LLM_PROVIDER=openrouter
OPENROUTER_API_KEY=sk-or-...
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
OPENROUTER_MODEL=anthropic/claude-sonnet-4.5
```

On startup, `~/.codex/config.toml` is generated with the `openrouter` provider.

Use this mode if:

- you want one gateway for multiple models
- you want access to non-OpenAI models through a single interface

### D) `ollama` on the host

Use this when Ollama is already running outside Compose, typically on the host machine.

`.env`:

```env
LLM_PROVIDER=ollama
OLLAMA_HOST=http://host.docker.internal:11434
OLLAMA_MODEL=qwen2.5-coder:32b
OLLAMA_API_KEY=
```

On startup, the entrypoint writes `~/.codex/config.toml` with the `ollama` provider and `base_url = "$OLLAMA_HOST/v1"`.

Use this mode if:

- you already run Ollama on the host
- you do not want an additional Compose service
- you want one Ollama instance shared by multiple dev containers

### E) Host-managed Ollama only

This stack no longer ships an Ollama service in `docker-compose.yml`.

If you want to use Ollama:

- run Ollama on the host
- pull the required models on the host
- point both Codex and GrepAI at `host.docker.internal`

Example:

```bash
ollama pull qwen2.5-coder:32b
ollama pull nomic-embed-text-v2-moe
```

```env
LLM_PROVIDER=ollama
OLLAMA_HOST=http://host.docker.internal:11434
OLLAMA_MODEL=qwen2.5-coder:32b
GREPAI_EMBED_ENDPOINT=http://host.docker.internal:11434
```

## agentmemory

### What is automatic and what is not

Automatic when `AGENTMEMORY_ENABLED=1`:

- the image installs the `agentmemory-mcp` stdio wrapper globally
- the image installs the `agentmemory` server CLI globally
- `configure-agentmemory` adds a managed MCP block to `~/.codex/config.toml`
- `configure-agentmemory` merges an `agentmemory` MCP entry into `~/.config/opencode/opencode.json`
- the Compose stack exposes a pinned `iiidev/iii:${AGENTMEMORY_III_VERSION:-0.11.2}` sidecar on local host ports
- the Compose stack can also run an `agentmemory-server` service that launches the upstream Node server on port `3213`

Not automatic:

- installing Claude/OpenClaw/Hermes-specific hook or plugin integrations
- exposing the viewer publicly outside localhost

### Why the `iii` image is pinned

The upstream project explicitly pins `iiidev/iii` to `0.11.2` because newer `0.11.x` worker behavior is not yet compatible with the current `agentmemory` worker model. Keep that pin until upstream documents support for a newer engine version.

### Why `agentmemory-server` is a separate service

The stack runs AgentMemory as two cooperating processes:

- `agentmemory` is the pinned `iii` engine container
- `agentmemory-server` is the upstream Node.js `agentmemory` server

They are split on purpose:

- `iii` has its own runtime and version pin
- the upstream `agentmemory` server is a separate process that connects to `iii`
- keeping the server in its own service lets memory stay online even when no interactive `dev` shell is running
- you can still run the same server manually inside `dev` with `start-agentmemory-server` if you prefer a single interactive session

Runtime flow:

```text
Codex / OpenCode
  -> agentmemory-mcp
  -> agentmemory server
  -> iii engine
```

Inside Compose, `agentmemory-server` connects to:

- `AGENTMEMORY_BASE_URL=http://agentmemory:3111`
- `AGENTMEMORY_STREAM_URL=ws://agentmemory:3112`

So the viewer and REST layer come from the upstream server, while state, streams, and engine execution live in the pinned `iii` container.

### Recommended workflow

1. Set `AGENTMEMORY_ENABLED=1` in `.env`.
2. Start the sidecar with `docker compose up -d agentmemory`.
3. Start the upstream server with `docker compose up -d agentmemory-server`.
4. Enter the dev shell with `docker compose run --rm -w /workspaces/my-project dev`.
5. Let Codex/OpenCode launch MCP via the preinstalled `agentmemory-mcp` binary.
6. Open `http://localhost:3213` for the viewer.

If you prefer running the upstream server inside the dev shell instead of a separate service, use:

```bash
start-agentmemory-server
```

Recommended first-session prompt for Codex/OpenCode:

```text
Use AgentMemory for this repository: inspect recent memory sessions, recall any existing project context, and use memory_recall or memory_smart_search before asking me to re-explain prior decisions.
```

### VS Code / GitHub Copilot note

If you run MCP tools from host-side VS Code on macOS, prefer the same direct binary pattern instead of `npx`:

```bash
npm install -g @agentmemory/mcp
```

Then point the MCP server config at:

```json
{
  "mcpServers": {
    "agentmemory": {
      "command": "agentmemory-mcp"
    }
  }
}
```

This avoids relying on `npx` process startup behavior for stdio JSON-RPC, which can confuse some clients and surface plain text instead of MCP JSON messages.

## GrepAI

### What is automatic and what is not

This stack installs GrepAI into the image automatically. It does not automatically index every repository, because indexing is expensive and repository-specific.

Automatic:

- the `grepai` binary is on `PATH`
- the entrypoint wires GrepAI MCP into `~/.codex/config.toml`
- the entrypoint wires GrepAI MCP into `~/.config/opencode/opencode.json`
- if the container starts directly inside a Git repository, `.grepai/config.yaml` is prepared
- the `embedder:` block is synchronized from `.env`

Not automatic:

- indexing the repository
- keeping `grepai watch` running
- configuring every possible editor client

### Default embedding configuration

Defaults:

```env
GREPAI_EMBEDDER=ollama
GREPAI_EMBED_MODEL=nomic-embed-text-v2-moe
GREPAI_EMBED_ENDPOINT=http://host.docker.internal:11434
GREPAI_EMBED_DIMENSIONS=768
```

Why `nomic-embed-text-v2-moe`:

- it is a better multilingual default than the older `nomic-embed-text`
- it keeps `768` dimensions
- it is a good fit for mixed English and Czech codebases or comments

### How project init works

When the container starts in a repository, it runs:

```bash
ai-dev-init-project
```

That command:

- finds the root of the current Git repository
- switches into that root
- runs `configure-grepai`

`configure-grepai` then:

- runs `grepai init --yes` if `.grepai/config.yaml` does not exist yet
- preserves the rest of the config file
- rewrites only the `embedder:` block

This is important because it avoids clobbering unrelated GrepAI settings.

### Manual initialization

If you are already inside the shell and want to initialize manually:

```bash
cd /workspaces/my-project
ai-dev-init-project
```

Or, if you only want to regenerate the embedding settings:

```bash
configure-grepai
```

### Recommended GrepAI workflow

```bash
docker compose run --rm -w /workspaces/my-project dev
grepai watch
```

Both `codex` and `opencode` are preconfigured to launch GrepAI MCP via:

```toml
[mcp_servers.grepai]
command = "grepai"
args = ["mcp-serve"]
```

In another shell:

```bash
docker compose run --rm -w /workspaces/my-project dev
grepai search "authentication flow"
grepai trace callers "Login"
```

## Serena

Serena is installed in the image with `uv tool install`.

At first container startup, the entrypoint attempts:

```bash
serena init
```

That creates Serena global config in `~/.serena` if it does not already exist.

The entrypoint also wires Serena MCP into both clients automatically:

- `codex` in `~/.codex/config.toml`
- `opencode` in `~/.config/opencode/opencode.json`

Typical MCP server startup for the current project:

```bash
cd /workspaces/my-project
serena start-mcp-server --context codex --project-from-cwd
```

Notes:

- `--context codex` is the expected default for Codex-oriented workflows
- `--project-from-cwd` matches Serena's recommendation for terminal clients started inside the project directory
- OpenCode is wired with Serena's generic `ide` context because it is a coding client with its own file and shell capabilities
- you do not need extra Serena-specific skills for tool discovery; once MCP is configured, the client can discover Serena tools directly
- if a client starts Serena from a global config without `--project-from-cwd`, Serena may require an explicit `activate_project` tool call

Recommended first-session prompt for Codex/OpenCode:

```text
Use Serena for this repository: activate the current project, read Serena's initial instructions, check whether onboarding was already performed, and if not, run onboarding.
```

This is mainly useful in the first chat for a repository, so Serena writes its project memories and establishes the expected workflow context.

## GitNexus

GitNexus is installed globally as a CLI.

The entrypoint also wires GitNexus MCP into both clients automatically:

- `codex` in `~/.codex/config.toml`
- `opencode` in `~/.config/opencode/opencode.json`

Basic workflow:

```bash
cd /workspaces/my-project
gitnexus setup
gitnexus analyze
```

Notes:

- the managed MCP command is `gitnexus mcp`
- `gitnexus analyze` is still required per repository before MCP tools have meaningful indexed data
- `gitnexus setup` remains useful if you also want GitNexus to configure external clients outside this container

Recommended first-use prompt for Codex/OpenCode after indexing:

```text
Use GitNexus for this repository: check which repos are indexed, inspect the current repo status, and use GitNexus MCP tools for architecture, impact, and route analysis when they fit better than plain text search.
```

In practice:

- `setup` prepares the editor or MCP integration
- `analyze` builds the knowledge graph for the current repository

GitNexus is not initialized automatically on each startup because analysis can be expensive and should happen explicitly per repository.

## OpenCode

OpenCode is available in the image as:

```bash
opencode
```

It is installed from the npm package `opencode-ai`, but the executable name is `opencode`.

That distinction matters if you later change the install logic in [`./Dockerfile`](./Dockerfile).

## Bundled skills

This repository contains a versioned local skill directory:

```text
skills/
  .agents/
  .codex/
```

These directories are the source of truth for skills that should be installed by default with the image:

- `skills/.agents` for shared agent skills
- `skills/.codex` for Codex-specific skills

At the moment, the bundled catalog lives under `skills/.agents`; `skills/.codex` is reserved for future Codex-only skills.

Currently bundled under `skills/.agents`:

- `karpathy-guidelines`
- `grepai-*`
- `setup-matt-pocock-skills`
- `diagnose`
- `tdd`
- `triage`
- `to-issues`
- `to-prd`
- `zoom-out`
- `improve-codebase-architecture`
- `grill-me`
- `grill-with-docs`

Example source files:

- [`./skills/.agents/karpathy-guidelines/SKILL.md`](./skills/.agents/karpathy-guidelines/SKILL.md)
- [`./skills/.agents/setup-matt-pocock-skills/SKILL.md`](./skills/.agents/setup-matt-pocock-skills/SKILL.md)

At each container startup, the entrypoint runs:

```bash
install-bundled-skills
```

That syncs bundled skills from the image into:

- `skills/.agents` -> `~/.agents/skills`
- `skills/.codex` -> `~/.codex/skills`

After syncing, the entrypoint also runs a one-time cleanup for existing home volumes:

- shared skills that used to be copied into `~/.codex/skills` are removed there if they do not exist under `skills/.codex`
- the cleanup writes a marker in `~/.codex/.ai-dev-cleanup-shared-skills-v1` so it does not run destructively on every startup

The copy behavior is intentionally image-managed:

- if the target skill does not exist yet, it is copied
- if it already exists, it is replaced with the bundled version from the image

This means:

- the skill is available by default after first startup
- rebuilding the image and starting a new container refreshes bundled skills in the home volume
- this repository acts as a managed catalog of default image skills

If you add or edit bundled skills in this repository, apply them with:

```bash
docker compose build dev
docker compose run --rm dev
```

Or:

```bash
docker compose up -d --build
```

### Matt Pocock skills: required first step

The bundled Matt Pocock engineering skills are available after startup, but they are not fully configured for a specific repository until you run:

```text
/setup-matt-pocock-skills
```

Run it once per repository before using:

- `/diagnose`
- `/tdd`
- `/triage`
- `/to-issues`
- `/to-prd`
- `/zoom-out`
- `/improve-codebase-architecture`

That setup skill configures repo-specific assumptions such as:

- where issues are tracked
- which triage labels are used
- where domain docs and ADRs live

Without that step, the skills are installed, but they may not know how your repository is organized.

### Recommended Matt Pocock workflow

1. Start the container directly in the repository:

```bash
docker compose run --rm -w /workspaces/my-project dev
```

2. Run `/setup-matt-pocock-skills`
3. Use the engineering skills as needed:

- `/diagnose` for bugs and regressions
- `/tdd` for test-driven changes
- `/triage` for issue intake
- `/to-prd` and `/to-issues` for planning workflows
- `/zoom-out` and `/improve-codebase-architecture` for system-level understanding

### Adding another bundled skill

1. Create a new directory under `skills/.agents/` or `skills/.codex/`, for example `skills/.agents/my-skill/`
2. Add `SKILL.md`
3. Rebuild the image:

```bash
docker compose build dev
```

4. Start a new container:

```bash
docker compose run --rm dev
```

On startup, the new skill will be copied only into the matching target:

- `skills/.agents/*` -> `~/.agents/skills`
- `skills/.codex/*` -> `~/.codex/skills`

## Codex

Codex CLI is available as:

```bash
codex
```

Provider config is generated into:

```bash
~/.codex/config.toml
```

The exception is `LLM_PROVIDER=codex-login`, where no provider block is generated and authentication is handled by the login flow. Managed MCP blocks may still create `~/.codex/config.toml`.

## Diagnostics

Quick environment check:

```bash
ai-dev-doctor
```

Or from the host:

```bash
docker compose run --rm dev ai-dev-doctor
```

The diagnostic output includes:

- active environment values
- whether the main CLI tools are present
- the current `~/.codex/config.toml`, if it exists
- the current `~/.config/opencode/opencode.json`, if it exists

Use it whenever:

- something behaves differently than expected
- you change provider settings
- you modify [`./Dockerfile`](./Dockerfile)
- you want to validate a fresh setup

## Typical scenarios

### Scenario 1: Codex with ChatGPT subscription login

```bash
cp .env.example .env
```

Set:

```env
PROJECTS_DIR=/path/to/projects
LLM_PROVIDER=codex-login
```

Then:

```bash
docker compose build dev
docker compose run --rm -w /workspaces/my-project dev
codex login
codex
```

### Scenario 2: OpenAI API key

```env
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-5.1-codex-max
```

Then:

```bash
docker compose run --rm -w /workspaces/my-project dev
codex
```

### Scenario 3: Host Ollama plus GrepAI embeddings

On the host:

```bash
ollama pull qwen2.5-coder:32b
ollama pull nomic-embed-text-v2-moe
```

In `.env`:

```env
LLM_PROVIDER=ollama
OLLAMA_HOST=http://host.docker.internal:11434
OLLAMA_MODEL=qwen2.5-coder:32b
GREPAI_EMBEDDER=ollama
GREPAI_EMBED_MODEL=nomic-embed-text-v2-moe
GREPAI_EMBED_ENDPOINT=http://host.docker.internal:11434
GREPAI_EMBED_DIMENSIONS=768
```

Then:

```bash
docker compose run --rm -w /workspaces/my-project dev
grepai watch
codex
```

### Scenario 4: Codex/OpenCode with agentmemory

In `.env`:

```env
LLM_PROVIDER=codex-login
AGENTMEMORY_ENABLED=1
AGENTMEMORY_III_VERSION=0.11.2
```

Then:

```bash
docker compose up -d agentmemory
docker compose run --rm -w /workspaces/my-project dev
npx -y @agentmemory/agentmemory
codex
```

## Troubleshooting

### `docker compose build dev` fails

Try:

```bash
docker compose build --no-cache dev
```

If the problem comes from an upstream installer or package rename, inspect:

- [`./Dockerfile`](./Dockerfile)
- current upstream installation instructions for the affected tool

### Codex uses the wrong provider

Check:

```bash
ai-dev-doctor
```

If you switched back to `codex-login`, confirm that:

- `LLM_PROVIDER=codex-login`
- any `~/.codex/config.toml` content only contains managed MCP blocks, not a stale provider block

### GrepAI cannot reach the embedding backend

Check:

- `GREPAI_EMBED_ENDPOINT`
- that Ollama is actually running
- that the embedding model has been pulled

For host Ollama:

```bash
curl http://localhost:11434/api/tags
```

### `.grepai/config.yaml` was not created

Auto-init only happens if:

- the container starts directly in the repository using `-w /workspaces/my-project`
- that directory is a Git repository

Otherwise, run manually:

```bash
cd /workspaces/my-project
ai-dev-init-project
```

### agentmemory does not respond on `localhost:3211`

Check:

- `docker compose ps agentmemory`
- `AGENTMEMORY_ENABLED=1`
- that you started `npx -y @agentmemory/agentmemory` inside the `dev` shell
- that `agentmemory-mcp` exists on `PATH` for the client process starting MCP

Quick checks:

```bash
docker compose logs agentmemory
docker compose run --rm dev ai-dev-doctor
```

### I want a clean start

Stop the stack:

```bash
docker compose down
```

Remove volumes only if you intentionally want to reset personal config and login state:

```bash
docker volume rm ai-dev-container_ai-dev-home
```

This is destructive:

- you lose `codex login`
- you lose Serena global config

## Security and operational notes

- `host.docker.internal` is explicitly mapped for Linux through `host-gateway`
- the `dev` user has passwordless sudo inside the container
- this image is intended for local development workflows, not hardened production runtime use
- API keys are passed through environment variables, so treat `.env` as a secret-bearing file

## Recommended defaults

If you want the simplest stable setup:

1. use `LLM_PROVIDER=codex-login` if you have Codex access through your ChatGPT plan
2. use `nomic-embed-text-v2-moe` for embeddings
3. start the shell directly in the repository with `-w /workspaces/my-project`
4. run `grepai watch` and `gitnexus analyze` when you want deeper code intelligence
5. validate the environment with `ai-dev-doctor` if something looks off
