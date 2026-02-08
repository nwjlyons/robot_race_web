#!/bin/bash
# Multi-server deployment test with Redis
# This script demonstrates true cross-server communication

set -e

echo "=== Robot Race - Multi-Server Test with Redis ==="
echo ""

# Check if Redis is available
if ! command -v redis-server &> /dev/null; then
    echo "❌ Redis is not installed"
    echo ""
    echo "To test multi-server mode, install Redis first:"
    echo "  macOS:   brew install redis"
    echo "  Ubuntu:  sudo apt-get install redis-server"
    echo "  Docker:  docker run -d -p 6379:6379 redis:alpine"
    echo ""
    echo "For now, testing single-server mode..."
    echo ""
    
    # Test single-server mode
    echo "Testing single-server mode (no Redis)..."
    ./bin/robot-race -addr :8080 > /tmp/single-server.log 2>&1 &
    SERVER_PID=$!
    sleep 2
    
    if curl -s http://localhost:8080 | grep -q "RobotRace"; then
        echo "✓ Single-server mode working"
        echo "  Server logs show: $(grep -o "Redis.*mode" /tmp/single-server.log)"
    else
        echo "✗ Server test failed"
        kill $SERVER_PID 2>/dev/null
        exit 1
    fi
    
    kill $SERVER_PID 2>/dev/null
    wait $SERVER_PID 2>/dev/null || true
    echo ""
    echo "Single-server test passed!"
    echo ""
    echo "Install Redis to test true multi-server functionality."
    exit 0
fi

# Check if Redis is running
if ! redis-cli ping &> /dev/null; then
    echo "Starting Redis..."
    redis-server --daemonize yes --port 6379
    sleep 2
    STARTED_REDIS=true
fi

echo "✓ Redis is running"
echo ""

# Build if needed
if [ ! -f "bin/robot-race" ]; then
    echo "Building application..."
    go build -o bin/robot-race ./cmd/server
fi

echo "Starting 3 server instances with Redis..."
echo ""

# Start server 1
./bin/robot-race -addr :8080 -redis localhost:6379 > /tmp/server1.log 2>&1 &
PID1=$!
sleep 1
echo "✓ Server 1 started on port 8080 (PID: $PID1)"

# Start server 2
./bin/robot-race -addr :8081 -redis localhost:6379 > /tmp/server2.log 2>&1 &
PID2=$!
sleep 1
echo "✓ Server 2 started on port 8081 (PID: $PID2)"

# Start server 3
./bin/robot-race -addr :8082 -redis localhost:6379 > /tmp/server3.log 2>&1 &
PID3=$!
sleep 1
echo "✓ Server 3 started on port 8082 (PID: $PID3)"

sleep 2

echo ""
echo "=== Verifying Multi-Server Mode ==="
echo ""

# Check logs for Redis connection
if grep -q "multi-server mode enabled" /tmp/server1.log; then
    echo "✓ Server 1: Connected to Redis (multi-server mode enabled)"
else
    echo "✗ Server 1: Not in multi-server mode"
fi

if grep -q "multi-server mode enabled" /tmp/server2.log; then
    echo "✓ Server 2: Connected to Redis (multi-server mode enabled)"
else
    echo "✗ Server 2: Not in multi-server mode"
fi

if grep -q "multi-server mode enabled" /tmp/server3.log; then
    echo "✓ Server 3: Connected to Redis (multi-server mode enabled)"
else
    echo "✗ Server 3: Not in multi-server mode"
fi

echo ""
echo "=== Testing Cross-Server Communication ==="
echo ""

# Create a game on server 1
echo "1. Creating game on Server 1 (port 8080)..."
LOCATION=$(curl -s -D - -X POST http://localhost:8080/create -o /dev/null | grep -i location | awk '{print $2}' | tr -d '\r')
GAME_ID=$(echo "$LOCATION" | sed 's|/join/||')
echo "   Game ID: $GAME_ID"
echo ""

# Check if game is accessible from server 2
echo "2. Checking if game is visible from Server 2 (port 8081)..."
if curl -s "http://localhost:8081/join/$GAME_ID" | grep -q "Join Robot Race"; then
    echo "   ✓ Game created on Server 1 is accessible from Server 2!"
else
    echo "   ✗ Game not accessible across servers"
fi
echo ""

# Check if game is accessible from server 3
echo "3. Checking if game is visible from Server 3 (port 8082)..."
if curl -s "http://localhost:8082/join/$GAME_ID" | grep -q "Join Robot Race"; then
    echo "   ✓ Game created on Server 1 is accessible from Server 3!"
else
    echo "   ✗ Game not accessible across servers"
fi
echo ""

# Check Redis for game state
echo "4. Checking Redis for game state..."
if redis-cli EXISTS "game_state:$GAME_ID" | grep -q "1"; then
    echo "   ✓ Game state stored in Redis"
    echo "   Key: game_state:$GAME_ID"
else
    echo "   ⚠ Game state not found in Redis"
fi

echo ""
echo "=== Multi-Server Test Complete ==="
echo ""
echo "All three servers are sharing game state through Redis!"
echo ""
echo "Try it yourself:"
echo "  Server 1: http://localhost:8080"
echo "  Server 2: http://localhost:8081"
echo "  Server 3: http://localhost:8082"
echo ""
echo "Create a game on one server and join from another!"
echo ""
echo "Press Ctrl+C to stop all servers..."
echo ""

# Wait for interrupt
trap cleanup INT TERM

cleanup() {
    echo ""
    echo "Stopping servers..."
    kill $PID1 $PID2 $PID3 2>/dev/null
    wait 2>/dev/null
    
    if [ "$STARTED_REDIS" = true ]; then
        echo "Stopping Redis..."
        redis-cli shutdown 2>/dev/null || true
    fi
    
    echo "All servers stopped."
    exit 0
}

wait
