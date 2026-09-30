#!/bin/bash

# Application URL
BASE_URL="${BASE_URL:-https://dev.example.com}"

echo "Starting dev tests"
echo "Target: $BASE_URL"

echo "Checking application health..."

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  --max-time 10 \
  "$BASE_URL/health")

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "Health check passed: HTTP $HTTP_STATUS"
else
    echo "Health check failed: HTTP $HTTP_STATUS"
    exit 1
fi

echo ""
echo "Checking homepage..."

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  --max-time 10 \
  "$BASE_URL/")

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "Homepage check passed: HTTP $HTTP_STATUS"
else
    echo "Homepage check failed: HTTP $HTTP_STATUS"
    exit 1
fi

echo "All dev tests passed"
exit 0
