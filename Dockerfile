FROM node:20-slim

RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

# Claude Code CLI (install BEFORE python3 to avoid Kaniko GLIBC conflicts)
RUN npm install -g @anthropic-ai/claude-code

# stdio -> HTTP bridge
RUN npm install -g supergateway

# Python 3 (installed after npm packages; apt python3 deps may break
# node in Kaniko builder, but node/npm are already installed above)
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && apt-get install -y -o Dpkg::Options::="--force-confnew" python3 \
    && rm -rf /var/lib/apt/lists/*

# uv — Python dependency manager (replaces pip/venv/pytest manual installs)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && ln -sf /root/.local/bin/uv /usr/local/bin/uv \
    && ln -sf /root/.local/bin/uvx /usr/local/bin/uvx

# Create workspace directory
RUN mkdir -p /workspace && chown node:node /workspace

# === Claude Code permissions: grant the MCP server ALL permissions ===
# `claude mcp serve` reads its config from $CLAUDE_CONFIG_DIR. We ship a
# settings.json with permissions.defaultMode="bypassPermissions" (allow: ["*"])
# so every exposed tool (Bash, Write, Edit, ...) runs without interactive
# approval — required because the MCP host cannot answer permission prompts.
ENV CLAUDE_CONFIG_DIR=/root/.claude
RUN mkdir -p /root/.claude
COPY settings.json /root/.claude/settings.json

# `--dangerously-skip-permissions` / bypassPermissions normally refuse to run as
# root; this container runs as root, so mark it as a sandbox to allow it.
ENV IS_SANDBOX=1

# Reinforce full-permission mode (also set in k8s/deployment.yaml).
ENV CLAUDE_CODE_ACCEPT_PERMISSIONS=true
ENV NODE_ENV=production

WORKDIR /workspace

EXPOSE 8080

# MCP proxy (strips outputSchema from tool definitions)
COPY proxy.mjs /workspace/proxy.mjs

# Entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
