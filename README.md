# Eightton Claude Code

MCP bridge service for Claude Code CLI integration.

## Overview

This service wraps Claude Code CLI as a containerized HTTP endpoint using supergateway as the stdio-to-HTTP bridge.

## Files

- `proxy.mjs` - MCP proxy that strips outputSchema from tool definitions and runs `claude mcp serve` with full permissions (`--dangerously-skip-permissions`)
- `entrypoint.sh` - Container initialization script
- `agent-prompt.md` - Development workflow instructions
- `settings.json` - Claude Code settings; grants the MCP server all permissions

## Permissions

The MCP server (`claude mcp serve`) is granted **all permissions** so its tools
(Bash, Write, Edit, …) run without interactive approval prompts — the MCP host
has no way to answer them. This is enforced through complementary layers:

- `proxy.mjs` starts `claude mcp serve --dangerously-skip-permissions`.
- `settings.json` (shipped to `$CLAUDE_CONFIG_DIR` = `/root/.claude` by the
  Dockerfile) sets `permissions.defaultMode: "bypassPermissions"` with
  `allow: ["*"]`.
- `IS_SANDBOX=1` (env) allows bypass mode while running as root in the pod.
- `CLAUDE_CODE_ACCEPT_PERMISSIONS=true` (Dockerfile + `k8s/deployment.yaml`)
  reinforces unattended acceptance.

> ⚠️ Run only in a trusted, isolated sandbox: the server can execute arbitrary
> commands and edit any file without prompting.

## Build & Deploy

```bash
make build    # Build container image
make deploy   # Apply k8s manifests
make restart  # Rolling restart
make all      # Build + deploy + restart
```

## License — MIT

This project is licensed under the MIT License.
