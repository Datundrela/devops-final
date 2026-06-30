#!/bin/bash
# rollback-docker.sh — Revert Docker blue-green traffic to previous environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ACTIVE_FILE="$PROJECT_ROOT/nginx/active-upstream.conf"
STATE_FILE="$PROJECT_ROOT/.docker-active-env"

cd "$PROJECT_ROOT"

CURRENT_ENV=$(cat "$STATE_FILE" 2>/dev/null || echo "blue")

if [ "$CURRENT_ENV" = "blue" ]; then
  PREV_ENV="green"
  PREV_SERVICE="app-green"
  PREV_PORT=3002
  UPSTREAM="server app-green:3000;"
else
  PREV_ENV="blue"
  PREV_SERVICE="app-blue"
  PREV_PORT=3001
  UPSTREAM="server app-blue:3000;"
fi

echo "Rolling back from $CURRENT_ENV to $PREV_ENV..."

docker compose --profile blue-green up -d "$PREV_SERVICE"

sleep 5
if ! curl -sf "http://localhost:$PREV_PORT/health" | grep -q "OK"; then
  echo "ERROR: Previous environment $PREV_ENV is not healthy."
  exit 1
fi

echo "$UPSTREAM" > "$ACTIVE_FILE"
echo "$PREV_ENV" > "$STATE_FILE"
docker compose --profile blue-green up -d nginx

docker compose --profile blue-green stop "app-$CURRENT_ENV" 2>/dev/null || true

echo "ROLLBACK SUCCESSFUL — Active: $PREV_ENV (http://localhost:8080)"
