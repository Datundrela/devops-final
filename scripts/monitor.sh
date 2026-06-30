#!/bin/bash
# monitor.sh — Periodic health check logging with alerting

PRODUCTION_ROOT="$HOME/local-production"
ACTIVE_FILE="$PRODUCTION_ROOT/active_env.txt"
LOG_FILE="health.log"
ALERT_FILE="alert.log"
FAILURE_THRESHOLD=3
CONSECUTIVE_FAILURES=0

echo "Starting Application Monitoring... Logging to $LOG_FILE"
echo "Alert threshold: $FAILURE_THRESHOLD consecutive failures → $ALERT_FILE"
echo "Press [CTRL+C] to stop."

while true; do
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

  if [ -f "$ACTIVE_FILE" ]; then
    ACTIVE_ENV=$(cat "$ACTIVE_FILE")
  else
    ACTIVE_ENV="none"
  fi

  if [ "$ACTIVE_ENV" = "blue" ]; then
    PORT=3001
  elif [ "$ACTIVE_ENV" = "green" ]; then
    PORT=3002
  else
    PORT=0
  fi

  if [ "$PORT" -ne 0 ]; then
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT/health" 2>/dev/null || echo "000")

    if [ "$STATUS" = "200" ]; then
      MESSAGE="SUCCESS - App is running on $ACTIVE_ENV (Port $PORT)"
      CONSECUTIVE_FAILURES=0
    else
      MESSAGE="FAILURE - $ACTIVE_ENV is down or unreachable (HTTP $STATUS)"
      CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
    fi
  else
    MESSAGE="WARNING - No active environment detected."
    CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
  fi

  echo "[$TIMESTAMP] $MESSAGE" | tee -a "$LOG_FILE"

  if [ "$CONSECUTIVE_FAILURES" -ge "$FAILURE_THRESHOLD" ]; then
    ALERT_MSG="[$TIMESTAMP] ALERT: $CONSECUTIVE_FAILURES consecutive failures on $ACTIVE_ENV (port $PORT)"
    echo "$ALERT_MSG" | tee -a "$ALERT_FILE"
    CONSECUTIVE_FAILURES=0
  fi

  sleep 5
done
