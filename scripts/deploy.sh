#!/bin/bash
# deploy.sh — Blue-Green Deployment (PM2, local production)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

PRODUCTION_ROOT="$HOME/local-production"
ACTIVE_FILE="$PRODUCTION_ROOT/active_env.txt"

CURRENT_ENV=$(cat "$ACTIVE_FILE" 2>/dev/null || echo "green")

if [ "$CURRENT_ENV" = "green" ]; then
  TARGET_ENV="blue"
  TARGET_PORT=3001
else
  TARGET_ENV="green"
  TARGET_PORT=3002
fi

echo "------------------------------------------"
echo "Current Env: $CURRENT_ENV"
echo "Deploying to: $TARGET_ENV on port $TARGET_PORT"
echo "------------------------------------------"

echo "Step 1: Preparing directory..."
mkdir -p "$PRODUCTION_ROOT/$TARGET_ENV"
rm -rf "$PRODUCTION_ROOT/$TARGET_ENV"/*

echo "Step 2: Copying files..."
cp -r "$PROJECT_ROOT"/. "$PRODUCTION_ROOT/$TARGET_ENV/"
rm -rf "$PRODUCTION_ROOT/$TARGET_ENV/node_modules"

echo "Step 3: Installing dependencies in production..."
cd "$PRODUCTION_ROOT/$TARGET_ENV" || exit
npm ci --omit=dev

echo "Step 4: Starting application with PM2..."
pm2 stop "$TARGET_ENV" 2>/dev/null || true
pm2 delete "$TARGET_ENV" 2>/dev/null || true
PORT=$TARGET_PORT APP_ENV=$TARGET_ENV pm2 start app.js --name "$TARGET_ENV"

echo "Step 5: Running Health Check..."
sleep 5

if curl -sf "http://localhost:$TARGET_PORT/health" | grep -q "OK"; then
  echo "SUCCESS: Health check passed!"
  echo "$TARGET_ENV" > "$ACTIVE_FILE"

  echo "Stopping old environment ($CURRENT_ENV)..."
  pm2 stop "$CURRENT_ENV" 2>/dev/null || true
  echo "DEPLOYMENT COMPLETE! Active: $TARGET_ENV (port $TARGET_PORT)"

  bash "$SCRIPT_DIR/post-deploy-check.sh" "$TARGET_PORT"
else
  echo "FAILURE: Health check failed on http://localhost:$TARGET_PORT/health"
  echo "Initiating automatic rollback..."
  pm2 stop "$TARGET_ENV" 2>/dev/null || true
  pm2 delete "$TARGET_ENV" 2>/dev/null || true
  bash "$SCRIPT_DIR/rollback.sh"
  exit 1
fi
