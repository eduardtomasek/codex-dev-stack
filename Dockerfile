FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_MAJOR=22

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y \
    ca-certificates curl gnupg git sudo unzip jq ripgrep fd-find bubblewrap \
    build-essential pkg-config python3 python3-pip python3-venv python3-dev \
    bash-completion less nano vim openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Recent Node.js for Codex/OpenCode/GitNexus npm packages.
RUN install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev \
    && mkdir -p /workspaces \
    && chown -R dev:dev /workspaces

USER dev
WORKDIR /home/dev

ENV PATH="/home/dev/.local/bin:/home/dev/.cargo/bin:/home/dev/.npm-global/bin:${PATH}"
ENV PIPX_HOME="/home/dev/.local/pipx"
ENV PIPX_BIN_DIR="/home/dev/.local/bin"

RUN mkdir -p /home/dev/.npm-global \
    && npm config set prefix /home/dev/.npm-global

# uv for Serena installation.
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# AI coding CLIs. Some packages may change over time; rebuild image to update.
# OpenCode is distributed on npm as `opencode-ai`.
# Install the agentmemory MCP wrapper and server globally so clients can launch
# stable binaries instead of shelling through `npx` at request time.
RUN npm install -g @openai/codex opencode-ai@latest gitnexus @agentmemory/mcp @agentmemory/agentmemory

# Serena agent.
RUN uv tool install -p 3.13 serena-agent@latest --prerelease=allow

# grepai installer.
RUN curl -sSL https://raw.githubusercontent.com/yoanbernabeu/grepai/main/install.sh | sh

COPY --chown=dev:dev scripts/entrypoint.sh /usr/local/bin/ai-dev-entrypoint
COPY --chown=dev:dev scripts/configure-codex.sh /usr/local/bin/configure-codex
COPY --chown=dev:dev scripts/configure-agentmemory.sh /usr/local/bin/configure-agentmemory
COPY --chown=dev:dev scripts/configure-ripgrep-mcp.sh /usr/local/bin/configure-ripgrep-mcp
COPY --chown=dev:dev scripts/configure-grepai-mcp.sh /usr/local/bin/configure-grepai-mcp
COPY --chown=dev:dev scripts/configure-serena-mcp.sh /usr/local/bin/configure-serena-mcp
COPY --chown=dev:dev scripts/configure-gitnexus-mcp.sh /usr/local/bin/configure-gitnexus-mcp
COPY --chown=dev:dev scripts/configure-grepai.sh /usr/local/bin/configure-grepai
COPY --chown=dev:dev scripts/cleanup-codex-duplicate-skills.sh /usr/local/bin/cleanup-codex-duplicate-skills
COPY --chown=dev:dev scripts/start-agentmemory-server.sh /usr/local/bin/start-agentmemory-server
COPY --chown=dev:dev scripts/init-project.sh /usr/local/bin/ai-dev-init-project
COPY --chown=dev:dev scripts/install-bundled-skills.sh /usr/local/bin/install-bundled-skills
COPY --chown=dev:dev scripts/doctor.sh /usr/local/bin/ai-dev-doctor
COPY --chown=dev:dev skills /opt/ai-dev/skills

USER root
RUN chmod +x /usr/local/bin/ai-dev-entrypoint /usr/local/bin/configure-codex /usr/local/bin/configure-agentmemory /usr/local/bin/configure-ripgrep-mcp /usr/local/bin/configure-grepai-mcp /usr/local/bin/configure-serena-mcp /usr/local/bin/configure-gitnexus-mcp /usr/local/bin/configure-grepai /usr/local/bin/cleanup-codex-duplicate-skills /usr/local/bin/start-agentmemory-server /usr/local/bin/ai-dev-init-project /usr/local/bin/install-bundled-skills /usr/local/bin/ai-dev-doctor
USER dev

WORKDIR /workspaces
ENTRYPOINT ["ai-dev-entrypoint"]
CMD ["bash"]
