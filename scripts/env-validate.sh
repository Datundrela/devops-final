#!/bin/bash
# env-validate.sh — Automated environment validation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

ERRORS=0

check() {
  if eval "$2"; then
    echo "  OK   $1"
  else
    echo "  FAIL $1"
    ERRORS=$((ERRORS + 1))
  fi
}

echo "Validating environment prerequisites..."

check "Node.js installed" "command -v node &> /dev/null"
check "npm installed" "command -v npm &> /dev/null"
check "package.json exists" "[ -f package.json ]"
check "app.js exists" "[ -f app.js ]"
check ".env.example exists" "[ -f .env.example ]"
check "Dockerfile exists" "[ -f Dockerfile ]"
check "docker-compose.yml exists" "[ -f docker-compose.yml ]"

if command -v docker &> /dev/null; then
  check "Docker daemon running" "docker info &> /dev/null"
else
  echo "  SKIP Docker (not installed — PM2 mode still available)"
fi

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "Validation failed with $ERRORS error(s)."
  exit 1
fi

echo "Environment validation passed."
