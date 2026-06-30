#!/bin/bash
# post-deploy-check.sh — Automated post-deployment verification

set -e

PORT=${1:-3000}
BASE_URL="http://localhost:$PORT"
FAILURES=0

check_endpoint() {
  local path=$1
  local expected=$2
  local url="$BASE_URL$path"

  if curl -sf "$url" | grep -q "$expected"; then
    echo "  PASS $path"
  else
    echo "  FAIL $path (expected: $expected)"
    FAILURES=$((FAILURES + 1))
  fi
}

echo "Post-deployment verification on $BASE_URL..."

check_endpoint "/health" "OK"
check_endpoint "/" "DevOps World"
check_endpoint "/user/1" "User ID: 1"

RESP=$(curl -sf -X POST "$BASE_URL/submit" -H "Content-Type: application/json" -d '{"data":"deploy-check"}')
if echo "$RESP" | grep -q "Received: deploy-check"; then
  echo "  PASS /submit"
else
  echo "  FAIL /submit"
  FAILURES=$((FAILURES + 1))
fi

if [ "$FAILURES" -gt 0 ]; then
  echo "Post-deployment checks FAILED ($FAILURES failures)"
  exit 1
fi

echo "All post-deployment checks passed."
