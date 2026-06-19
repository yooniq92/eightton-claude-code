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

## Secrets

실제 secret(예: `ANTHROPIC_API_KEY`, `GITHUB_TOKEN`)은 절대 커밋하지 마세요.
운영에서는 CI/CD secret 변수 · [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) · External Secrets Operator 로 주입합니다.
하드코딩된 secret 패턴 커밋을 막으려면 pre-commit 훅을 활성화하세요:

```bash
git config core.hooksPath .githooks
```

## License — MIT

This project is licensed under the MIT License.
