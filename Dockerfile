FROM node:20-slim

RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

# Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# stdio -> HTTP bridge
RUN npm install -g supergateway

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
