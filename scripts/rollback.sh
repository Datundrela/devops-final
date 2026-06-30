#!/bin/bash
# rollback.sh — Reverts to the previous PM2 environment

set -e

PRODUCTION_ROOT="$HOME/local-production"
ACTIVE_FILE="$PRODUCTION_ROOT/active_env.txt"

if [ ! -f "$ACTIVE_FILE" ]; then
  echo "Error: No active environment file found. Cannot rollback."
  exit 1
fi

CURRENT_ENV=$(cat "$ACTIVE_FILE")

if [ "$CURRENT_ENV" = "blue" ]; then
  PREV_ENV="green"
  PREV_PORT=3002
else
  PREV_ENV="blue"
  PREV_PORT=3001
fi

echo "------------------------------------------"
echo "Rolling back from $CURRENT_ENV to $PREV_ENV..."
echo "------------------------------------------"

pm2 resurrect 2>/dev/null || true
pm2 start "$PREV_ENV" 2>/dev/null || pm2 restart "$PREV_ENV" 2>/dev/null || true

echo "$PREV_ENV" > "$ACTIVE_FILE"

pm2 stop "$CURRENT_ENV" 2>/dev/null || true

sleep 3
if curl -sf "http://localhost:$PREV_PORT/health" | grep -q "OK"; then
  echo "ROLLBACK SUCCESSFUL — Active: $PREV_ENV (port $PREV_PORT)"
else
  echo "WARNING: Rollback completed but health check on $PREV_ENV returned unexpected result."
  exit 1
fi
