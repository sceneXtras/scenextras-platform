#!/bin/bash
# Example client script for testing the bug report API

API_URL="${API_URL:-http://localhost:8080}"

echo "Bug Report API Client Example"
echo "=============================="
echo ""

# Example 1: Submit a bug report with screenshot
echo "1. Submitting bug report with screenshot..."
RESPONSE=$(curl -s -X POST "$API_URL/api/reports" \
  -F "title=App crashes on startup" \
  -F "description=The application crashes immediately after opening when not connected to WiFi" \
  -F "stepsToReproduce=1. Disconnect from WiFi\n2. Open the app\n3. App crashes with error code 500" \
  -F "currentRoute=/(tabs)/home" \
  -F 'navigationHistory=["/(drawer)/(tabs)/index", "/(tabs)/home"]' \
  -F 'logs=[{"level":"error","message":"Network request failed: Connection timeout","timestamp":"2024-01-22T12:00:00Z","context":{"url":"https://api.scenextras.com/v1/characters"}},{"level":"warn","message":"Retry attempt 1 failed","timestamp":"2024-01-22T12:00:05Z"},{"level":"error","message":"Fatal: Unable to load character data","timestamp":"2024-01-22T12:00:10Z"}]' \
  -F 'deviceInfo={"platform":"iOS","os":"iOS","osVersion":"17.2.1","appVersion":"1.1.4","buildNumber":"93","deviceModel":"iPhone 15 Pro","manufacturer":"Apple"}' \
  -F 'userInfo={"userId":"user_abc123","username":"john_doe"}' \
  -F "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  -F "traceId=trace_$(uuidgen | tr '[:upper:]' '[:lower:]')")

echo "$RESPONSE" | jq '.'
REPORT_ID=$(echo "$RESPONSE" | jq -r '.reportId')
echo ""

# Example 2: List all reports
echo "2. Listing all bug reports..."
curl -s "$API_URL/api/reports" | jq '.'
echo ""

# Example 3: Get a specific report
if [ ! -z "$REPORT_ID" ]; then
  echo "3. Getting specific report ($REPORT_ID)..."
  curl -s "$API_URL/api/reports/$REPORT_ID" | jq '.'
  echo ""

  echo "4. View report in browser:"
  echo "   Open: $API_URL/reports/$REPORT_ID"
fi

# Example 4: Health check
echo "5. Health check..."
curl -s "$API_URL/health" | jq '.'
echo ""

echo "=============================="
echo "View all reports in browser:"
echo "   $API_URL/"
echo ""
