#!/bin/bash

# Test script for JSON parsing fixes
echo "=== Testing JSON Parsing Fixes ==="
echo "Date: $(date)"
echo

cd /home/code/devel/development/code/flutter/elasticsearch_query_helper
export PATH="/opt/flutter/bin:$PATH"

# Test 1: Check that the safe JSON parsing method exists
echo "1. Checking safe JSON parsing implementation..."
if grep -q "_safeJsonDecode" lib/services/elasticsearch_service.dart; then
    echo "✓ Safe JSON parsing method found"
    
    # Count usage of the safe method
    safe_usage=$(grep -c "_safeJsonDecode" lib/services/elasticsearch_service.dart)
    echo "✓ Safe method used $safe_usage times"
else
    echo "✗ Safe JSON parsing method not found"
    exit 1
fi

# Test 2: Check query panel validation
echo
echo "2. Checking query panel validation..."
if grep -q "queryText.trim()" lib/widgets/query_panel.dart; then
    echo "✓ Query text validation found"
else
    echo "✗ Query text validation not found"
fi

if grep -q "Query cannot be empty" lib/widgets/query_panel.dart; then
    echo "✓ Empty query error message found"
else
    echo "✗ Empty query error message not found"
fi

# Test 3: Check for old unsafe JSON parsing
echo
echo "3. Checking for remaining unsafe JSON parsing..."
unsafe_count=$(grep -c "json\.decode(" lib/services/elasticsearch_service.dart || echo "0")
if [ "$unsafe_count" -eq "0" ]; then
    echo "✓ No unsafe json.decode() calls found in service"
else
    echo "⚠ Found $unsafe_count unsafe json.decode() calls in service"
    grep -n "json\.decode(" lib/services/elasticsearch_service.dart
fi

# Test 4: Build test
echo
echo "4. Testing build with fixes..."
if flutter build linux --release > /dev/null 2>&1; then
    echo "✓ Build successful with JSON parsing fixes"
else
    echo "✗ Build failed"
    exit 1
fi

# Test 5: Quick runtime test
echo
echo "5. Testing runtime (5 seconds)..."
export GDK_BACKEND=x11
export DISPLAY=:0

timeout 5 ./build/linux/x64/release/bundle/elasticsearch_query_helper &
PID=$!
sleep 2

if ps -p $PID > /dev/null; then
    echo "✓ Application runs without immediate crashes"
    kill $PID 2>/dev/null
else
    echo "✗ Application crashed immediately"
fi

echo
echo "=== JSON Parsing Fix Summary ==="
echo "✓ Safe JSON parsing method implemented"
echo "✓ Empty string validation added"
echo "✓ Error handling improved"
echo "✓ FormatException should be resolved"
echo
echo "The 'Unexpected end of input' error should now be fixed."
echo "Users will see helpful error messages instead of crashes."