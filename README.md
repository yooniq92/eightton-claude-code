# Eightton Claude Code

MCP bridge service for Claude Code CLI integration.

## Overview

This service wraps Claude Code CLI as a containerized HTTP endpoint using supergateway as the stdio-to-HTTP bridge.

## Files

- `proxy.mjs` - MCP proxy that strips outputSchema from tool definitions and runs `claude mcp serve` with full permissions (granted via `settings.json` `bypassPermissions`)
- `entrypoint.sh` - Container initialization script
- `agent-prompt.md` - Development workflow instructions (all MCP servers run with full access)
- `settings.json` - Claude Code config granting all permissions (`bypassPermissions`, all MCP servers enabled)

## MCP Permissions

This container is a trusted, unattended dev agent, so every MCP tool runs with **full permissions and no interactive approval prompts**. This is enforced at several layers:

- `settings.json` (shipped to `$CLAUDE_CONFIG_DIR=/root/.claude`) sets
  `permissions.defaultMode: "bypassPermissions"` with `allow: ["*"]`, and enables
  every MCP server (`enableAllProjectMcpServers`, `enabledMcpjsonServers: ["*"]`).
  This is the canonical Claude Code mechanism for granting all permissions.
- `Dockerfile` sets `IS_SANDBOX=1` — without it `bypassPermissions` is refused
  when running as root (the container runs as root) and would be downgraded.
- `proxy.mjs` starts `claude mcp serve --verbose`. (The `mcp serve` subcommand
  does **not** accept `--dangerously-skip-permissions` — that flag aborts the
  server with "unknown option"; settings.json `bypassPermissions` is the correct
  mechanism for this subcommand.)
- `Dockerfile` / `k8s/deployment.yaml` set `CLAUDE_CODE_ACCEPT_PERMISSIONS=true` to reinforce it.
- `k8s/ingress.yaml` opens CORS for all MCP transport methods/headers (`PATCH`, `Mcp-Session-Id`, …).

## Build & Deploy

```bash
make build    # Build container image
make deploy   # Apply k8s manifests
make restart  # Rolling restart
make all      # Build + deploy + restart
```
