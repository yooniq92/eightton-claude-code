# Eightton Claude Code

MCP bridge service for Claude Code CLI integration.

## Overview

This service wraps Claude Code CLI as a containerized HTTP endpoint using supergateway as the stdio-to-HTTP bridge.

## Files

- `proxy.mjs` - MCP proxy that strips outputSchema from tool definitions and runs `claude mcp serve` with full permissions (`--dangerously-skip-permissions`)
- `entrypoint.sh` - Container initialization script
- `agent-prompt.md` - Development workflow instructions (all MCP servers run with full access)

## MCP Permissions

This container is a trusted, unattended dev agent, so every MCP tool runs with **full permissions and no interactive approval prompts**:

- `proxy.mjs` starts `claude mcp serve --dangerously-skip-permissions`.
- `k8s/deployment.yaml` sets `CLAUDE_CODE_ACCEPT_PERMISSIONS=true` to reinforce it.
- `k8s/ingress.yaml` opens CORS for all MCP transport methods/headers (`PATCH`, `Mcp-Session-Id`, …).

## Build & Deploy

```bash
make build    # Build container image
make deploy   # Apply k8s manifests
make restart  # Rolling restart
make all      # Build + deploy + restart
```
