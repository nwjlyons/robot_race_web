#!/bin/bash
# Test script for Robot Race Go implementation

set -e

echo "=== Robot Race Go - Test Suite ==="
echo ""

# Build the application
echo "Building application..."
go build -o bin/robot-race ./cmd/server
echo "✓ Build successful"
echo ""

# Run unit tests
echo "Running unit tests..."
go test ./internal/... -v
echo "✓ Unit tests passed"
echo ""

# Start server for integration testing
echo "Starting server on port 8080..."
./bin/robot-race -addr :8080 &
SERVER_PID=$!
sleep 2

# Test homepage
echo "Testing homepage..."
RESPONSE=$(curl -s http://localhost:8080)
if echo "$RESPONSE" | grep -q "RobotRace"; then
    echo "✓ Homepage loaded successfully"
else
    echo "✗ Homepage test failed"
    kill $SERVER_PID
    exit 1
fi
echo ""

# Test game creation
echo "Testing game creation..."
LOCATION=$(curl -s -D - -X POST http://localhost:8080/create -o /dev/null | grep -i location | awk '{print $2}' | tr -d '\r')
if [ -n "$LOCATION" ]; then
    echo "✓ Game created successfully: $LOCATION"
    GAME_ID=$(echo "$LOCATION" | sed 's|/join/||')
    echo "  Game ID: $GAME_ID"
else
    echo "✗ Game creation failed"
    kill $SERVER_PID
    exit 1
fi
echo ""

# Test join page
echo "Testing join page..."
JOIN_RESPONSE=$(curl -s "http://localhost:8080/join/$GAME_ID")
if echo "$JOIN_RESPONSE" | grep -q "Join Robot Race"; then
    echo "✓ Join page loaded successfully"
else
    echo "✗ Join page test failed"
    kill $SERVER_PID
    exit 1
fi
echo ""

# Cleanup
echo "Stopping server..."
kill $SERVER_PID
wait $SERVER_PID 2>/dev/null || true
echo "✓ Server stopped"
echo ""

echo "=== All tests passed! ==="
echo ""
echo "To start the server manually, run:"
echo "  ./bin/robot-race -addr :8080"
echo ""
echo "Then open http://localhost:8080 in your browser"
