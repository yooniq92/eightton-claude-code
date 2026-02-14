# Eightton Claude Code

MCP bridge service for Claude Code CLI integration.

## Overview

This service wraps Claude Code CLI as a containerized HTTP endpoint using supergateway as the stdio-to-HTTP bridge.

## Files

- `proxy.mjs` - MCP proxy that strips outputSchema from tool definitions
- `entrypoint.sh` - Container initialization script
- `agent-prompt.md` - Development workflow instructions

## Build & Deploy

```bash
make build    # Build container image
make deploy   # Apply k8s manifests
make restart  # Rolling restart
make all      # Build + deploy + restart
```
