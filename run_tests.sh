#!/bin/bash

# Exit on any error
set -e

CONFIG_FILE="test_config.json"
FAIL=0
TEMP_DIR=$(mktemp -d)
TESTS_FILE="$TEMP_DIR/tests.json"

# Function to cleanup and exit
cleanup_and_exit() {
    local exit_code=$1
    rm -rf "$TEMP_DIR"
    rm -f actual_sorted.json expected_sorted.json
    exit $exit_code
}

# Trap to ensure cleanup on script exit
trap 'cleanup_and_exit $?' EXIT

echo "🔍 Validating test configuration..."

# First, validate the JSON syntax
if ! jq . "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "❌ ERROR: Invalid JSON syntax in $CONFIG_FILE"
    jq . "$CONFIG_FILE" 2>&1 || true  # Show the error
    echo "🔥 Configuration validation failed!"
    exit 1
fi

echo "✅ Configuration is valid JSON"

# Extract tests array and validate structure
if ! jq -e '.tests' "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "❌ ERROR: Missing 'tests' array in $CONFIG_FILE"
    exit 1
fi

if ! jq -e '.host' "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "❌ ERROR: Missing 'host' field in $CONFIG_FILE"
    exit 1
fi

# Extract tests to temporary file for processing
jq -c '.tests[]' "$CONFIG_FILE" > "$TESTS_FILE" 2>/dev/null

HOST=$(jq -r '.host' "$CONFIG_FILE")
echo "🌐 Testing host: $HOST"
echo ""

# Process each test
while IFS= read -r test; do
    # Validate test structure
    if ! echo "$test" | jq -e '.endpoint' > /dev/null 2>&1; then
        echo "❌ ERROR: Test missing 'endpoint' field: $test"
        FAIL=1
        continue
    fi
    
    if ! echo "$test" | jq -e '.expectedResult' > /dev/null 2>&1; then
        echo "❌ ERROR: Test missing 'expectedResult' field: $test"
        FAIL=1
        continue
    fi
    
    ENDPOINT=$(echo "$test" | jq -r '.endpoint')
    
    echo "🚀 Testing: ${HOST}${ENDPOINT}"
    
    # Get expected result and validate it's valid JSON
    if ! EXPECTED_JSON=$(echo "$test" | jq -c '.expectedResult' 2>/dev/null); then
        echo "❌ ERROR: Invalid expectedResult JSON for $ENDPOINT"
        FAIL=1
        continue
    fi
    
    # Test the endpoint with timeout and error handling
    if ! curl -s --connect-timeout 10 --max-time 30 "${HOST}${ENDPOINT}" > "$TEMP_DIR/response.json" 2>/dev/null; then
        echo "❌ ERROR: Failed to connect to ${HOST}${ENDPOINT}"
        FAIL=1
        continue
    fi
    
    # Validate response is valid JSON
    if ! jq . "$TEMP_DIR/response.json" > /dev/null 2>&1; then
        echo "❌ ERROR: Response is not valid JSON for $ENDPOINT"
        echo "Response content:"
        cat "$TEMP_DIR/response.json" | head -5
        FAIL=1
        continue
    fi
    
    # Sort both JSON for comparison
    if ! jq -S . "$TEMP_DIR/response.json" > actual_sorted.json 2>/dev/null; then
        echo "❌ ERROR: Failed to process response JSON for $ENDPOINT"
        FAIL=1
        continue
    fi
    
    if ! echo "$EXPECTED_JSON" | jq -S . > expected_sorted.json 2>/dev/null; then
        echo "❌ ERROR: Failed to process expected JSON for $ENDPOINT"
        FAIL=1
        continue
    fi
    
    # Compare results
    if diff actual_sorted.json expected_sorted.json > /dev/null 2>&1; then
        echo "✅ Passed: $ENDPOINT"
    else
        echo "❌ Failed: $ENDPOINT"
        echo "Expected vs Actual diff:"
        diff expected_sorted.json actual_sorted.json || true
        FAIL=1
    fi
    echo ""
    
done < "$TESTS_FILE"

# Check final result
if [ $FAIL -eq 1 ]; then
    echo "🔥 Some tests failed!"
    exit 1
else
    echo "🎉 All tests passed!"
    exit 0
fi

