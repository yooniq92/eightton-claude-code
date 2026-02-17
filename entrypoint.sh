#!/bin/bash
set -e

echo "=== Claude Code MCP Server ==="

# Node.js V8 힙 제한 (프로세스당 512MB, OOM 방지)
export NODE_OPTIONS="--max-old-space-size=512"

# Git 인증 설정 (GITHUB_TOKEN이 있으면)
if [ -n "$GITHUB_TOKEN" ]; then
  git config --global credential.helper store
  echo "https://x-access-token:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
  git config --global user.name "${GIT_USER_NAME:-claude-code-bot}"
  git config --global user.email "${GIT_USER_EMAIL:-claude-code-bot@noreply.github.com}"
  echo "Git credentials configured"
fi

# 기본 리포 클론 (GIT_REPO_URL이 있으면)
if [ -n "$GIT_REPO_URL" ]; then
  REPO_DIR="/workspace/$(basename "$GIT_REPO_URL" .git)"
  if [ ! -d "$REPO_DIR/.git" ]; then
    echo "Cloning $GIT_REPO_URL → $REPO_DIR"
    git clone "$GIT_REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
    git checkout "${GIT_DEFAULT_BRANCH:-develop}"
  else
    echo "Repo already exists at $REPO_DIR, pulling latest..."
    cd "$REPO_DIR"
    git pull
  fi

  # uv: 프로젝트 의존성 동기화
  if [ -f "pyproject.toml" ]; then
    echo "Running uv sync..."
    uv sync --dev 2>&1 || echo "Warning: uv sync failed (will retry on first use)"
  fi
fi

echo "Exposing claude mcp serve over Streamable HTTP on port 8080 (with outputSchema proxy)"

exec npx -y supergateway \
  --stdio "node /workspace/proxy.mjs" \
  --outputTransport streamableHttp \
  --port 8080 \
  --streamableHttpPath "/mcp" \
  --healthEndpoint /health \
  --cors \
  --logLevel info \
  --stateful
