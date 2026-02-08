#!/bin/bash
# Multi-server deployment demonstration
# This script shows how to run multiple instances of Robot Race on different ports

set -e

echo "=== Robot Race - Multi-Server Deployment Demo ==="
echo ""
echo "This demonstrates running Robot Race on multiple servers."
echo "Each server can host independent games, or you can configure"
echo "a load balancer to distribute traffic across servers."
echo ""

# Build if needed
if [ ! -f "bin/robot-race" ]; then
    echo "Building application..."
    go build -o bin/robot-race ./cmd/server
    echo "✓ Build successful"
    echo ""
fi

# Start multiple servers
echo "Starting 3 server instances..."
echo ""

./bin/robot-race -addr :8080 > /tmp/server-8080.log 2>&1 &
PID1=$!
echo "✓ Server 1 started on port 8080 (PID: $PID1)"

./bin/robot-race -addr :8081 > /tmp/server-8081.log 2>&1 &
PID2=$!
echo "✓ Server 2 started on port 8081 (PID: $PID2)"

./bin/robot-race -addr :8082 > /tmp/server-8082.log 2>&1 &
PID3=$!
echo "✓ Server 3 started on port 8082 (PID: $PID3)"

sleep 2

echo ""
echo "=== Servers Running ==="
echo ""
echo "Server 1: http://localhost:8080"
echo "Server 2: http://localhost:8081"
echo "Server 3: http://localhost:8082"
echo ""
echo "Each server maintains its own game instances independently."
echo "Games created on one server are isolated from other servers."
echo ""
echo "For production multi-server deployment, you would typically:"
echo "  1. Run servers behind a load balancer (e.g., nginx, HAProxy)"
echo "  2. Use sticky sessions to keep WebSocket connections stable"
echo "  3. Optionally add Redis for cross-server game state sharing"
echo ""
echo "Press Ctrl+C to stop all servers..."
echo ""

# Wait for interrupt
trap "echo ''; echo 'Stopping servers...'; kill $PID1 $PID2 $PID3 2>/dev/null; wait 2>/dev/null; echo 'All servers stopped.'; exit 0" INT TERM

wait
