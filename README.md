# Eightton Claude Code

MCP bridge service for Claude Code CLI integration.

## Overview

This service wraps Claude Code CLI as a containerized HTTP endpoint using supergateway as the stdio-to-HTTP bridge.

## Files

- `proxy.mjs` - MCP proxy that strips outputSchema from tool definitions
- `entrypoint.sh` - Container initialization script
- `agent-prompt.md` - Development workflow instructions
- `settings.json` - Claude Code settings; grants the MCP server all permissions

## Permissions

The MCP server (`claude mcp serve`) is granted **all permissions** so its tools
(Bash, Write, Edit, …) run without interactive approval prompts — the MCP host
has no way to answer them.

This is configured via `settings.json`, shipped to `$CLAUDE_CONFIG_DIR`
(`/root/.claude/settings.json`) by the Dockerfile:

- `permissions.defaultMode: "bypassPermissions"` — bypass all permission checks.
- `IS_SANDBOX=1` (env) — allows bypass mode while running as root in the pod.

`k8s/deployment.yaml` also declares `CLAUDE_CONFIG_DIR` and `IS_SANDBOX`
explicitly, so the requirement is visible at the deployment layer and survives
image overrides. The same behaviour is documented for agents in
`agent-prompt.md` (Claude Code server → Permissions).

> ⚠️ Run only in a trusted, isolated sandbox: the server can execute arbitrary
> commands and edit any file without prompting.

## Build & Deploy

```bash
make build    # Build container image
make deploy   # Apply k8s manifests
make restart  # Rolling restart
make all      # Build + deploy + restart
```
