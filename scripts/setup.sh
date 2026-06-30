#!/bin/bash
# setup.sh — Single-command environment preparation (IaC + optional Docker)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
USE_DOCKER=false

for arg in "$@"; do
  case "$arg" in
    --docker) USE_DOCKER=true ;;
  esac
done

cd "$PROJECT_ROOT"

echo "=========================================="
echo " DevOps Final — Environment Setup"
echo "=========================================="

if ! command -v node &> /dev/null; then
  echo "ERROR: Node.js is required. Install from https://nodejs.org/"
  exit 1
fi

echo "[1/5] Installing npm dependencies..."
npm install

if [ ! -f .env ]; then
  echo "[2/5] Creating .env from .env.example..."
  cp .env.example .env
else
  echo "[2/5] .env already exists — skipping"
fi

echo "[3/5] Running environment validation..."
bash "$SCRIPT_DIR/env-validate.sh"

echo "[4/5] Provisioning local production directories (IaC)..."
bash "$SCRIPT_DIR/iac-setup.sh"

if [ "$USE_DOCKER" = true ]; then
  if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is required for --docker setup."
    exit 1
  fi
  echo "[5/5] Building Docker images and starting default stack..."
  docker compose --profile default build
  docker compose --profile default up -d
  echo ""
  echo "Docker app running at http://localhost:3000"
else
  echo "[5/5] Setup complete (PM2 mode). Run: npm run deploy"
fi

echo ""
echo "Environment ready. Next steps:"
echo "  npm test              — run tests"
echo "  npm run deploy        — PM2 blue-green deploy"
echo "  npm run deploy:docker — Docker blue-green deploy"
echo "  npm run monitor       — start health monitoring"
