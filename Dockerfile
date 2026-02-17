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

# Pre-accept dangerous permissions (will be configured at runtime)
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
