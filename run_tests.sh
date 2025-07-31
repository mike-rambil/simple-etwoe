#!/bin/bash

CONFIG_FILE="test_config.json"
FAIL=0

# Loop through each test in the config
jq -c '.tests[]' "$CONFIG_FILE" | while read -r test; do
  HOST=$(jq -r '.host' "$CONFIG_FILE")
  ENDPOINT=$(echo "$test" | jq -r '.endpoint')
  EXPECTED_JSON=$(echo "$test" | jq -c '.expectedResult')

  echo "🚀 Testing: ${HOST}${ENDPOINT}"

  # Get actual response
  curl -s "${HOST}${ENDPOINT}" | jq -S . > actual_sorted.json

  # Save expected to temp file
  echo "$EXPECTED_JSON" | jq -S . > expected_sorted.json

  # Compare
  if diff actual_sorted.json expected_sorted.json > /dev/null; then
    echo "✅ Passed: $ENDPOINT"
  else
    echo "❌ Failed: $ENDPOINT"
    echo "Diff:"
    diff actual_sorted.json expected_sorted.json
    FAIL=1
  fi

done

# Cleanup
rm -f actual_sorted.json expected_sorted.json

# Exit with failure if any test failed
if [ $FAIL -eq 1 ]; then
  echo "🔥 Some tests failed!"
  exit 1
else
  echo "🎉 All tests passed!"
  exit 0
fi

