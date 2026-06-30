#!/bin/bash
# deploy-docker.sh — Blue-Green deployment using Docker Compose

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ACTIVE_FILE="$PROJECT_ROOT/nginx/active-upstream.conf"
STATE_FILE="$PROJECT_ROOT/.docker-active-env"

cd "$PROJECT_ROOT"

if ! command -v docker &> /dev/null; then
  echo "ERROR: Docker is required."
  exit 1
fi

CURRENT_ENV=$(cat "$STATE_FILE" 2>/dev/null || echo "blue")

if [ "$CURRENT_ENV" = "blue" ]; then
  TARGET_ENV="green"
  TARGET_SERVICE="app-green"
  TARGET_PORT=3002
  UPSTREAM="server app-green:3000;"
else
  TARGET_ENV="blue"
  TARGET_SERVICE="app-blue"
  TARGET_PORT=3001
  UPSTREAM="server app-blue:3000;"
fi

echo "------------------------------------------"
echo "Docker Blue-Green Deploy"
echo "Current: $CURRENT_ENV → Target: $TARGET_ENV"
echo "------------------------------------------"

echo "Step 1: Building image..."
docker compose --profile blue-green build "$TARGET_SERVICE"

echo "Step 2: Starting $TARGET_SERVICE..."
docker compose --profile blue-green up -d "$TARGET_SERVICE"

echo "Step 3: Waiting for health check..."
RETRIES=12
for i in $(seq 1 $RETRIES); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$TARGET_PORT/health" 2>/dev/null || echo "000")
  if [ "$STATUS" = "200" ]; then
    break
  fi
  sleep 5
done

if [ "$STATUS" != "200" ]; then
  echo "FAILURE: Health check failed on port $TARGET_PORT"
  docker compose --profile blue-green stop "$TARGET_SERVICE"
  bash "$SCRIPT_DIR/rollback-docker.sh"
  exit 1
fi

echo "Step 4: Switching nginx upstream to $TARGET_ENV..."
echo "$UPSTREAM" > "$ACTIVE_FILE"
docker compose --profile blue-green up -d nginx

echo "$TARGET_ENV" > "$STATE_FILE"

echo "Step 5: Stopping previous environment ($CURRENT_ENV)..."
if [ "$CURRENT_ENV" = "blue" ]; then
  docker compose --profile blue-green stop app-blue 2>/dev/null || true
else
  docker compose --profile blue-green stop app-green 2>/dev/null || true
fi

echo "DEPLOYMENT COMPLETE! Traffic routed via http://localhost:8080"
bash "$SCRIPT_DIR/post-deploy-check.sh" "$TARGET_PORT"
