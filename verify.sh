#!/bin/bash
# Final verification script for Robot Race Go implementation

echo "=== Robot Race Go - Final Verification ==="
echo ""

# Check files exist
echo "Checking project files..."
FILES=(
    "go.mod"
    "go.sum"
    "cmd/server/main.go"
    "internal/game/game.go"
    "internal/game/robot.go"
    "internal/game/config.go"
    "internal/hub/hub.go"
    "internal/server/server.go"
    "internal/server/templates.go"
    "internal/game/game_test.go"
    "README_GO.md"
    "COMPARISON.md"
    "DEPLOYMENT.md"
    "SUMMARY.md"
    "test.sh"
    "run-multiserver.sh"
    "Dockerfile.golang"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file MISSING"
        exit 1
    fi
done
echo ""

# Check binary exists and is executable
echo "Checking binary..."
if [ -x "bin/robot-race" ]; then
    SIZE=$(ls -lh bin/robot-race | awk '{print $5}')
    echo "  ✓ bin/robot-race ($SIZE)"
else
    echo "  Building binary..."
    go build -o bin/robot-race ./cmd/server
    if [ $? -eq 0 ]; then
        echo "  ✓ Binary built successfully"
    else
        echo "  ✗ Build failed"
        exit 1
    fi
fi
echo ""

# Run unit tests
echo "Running unit tests..."
go test ./internal/game -v > /tmp/test-output.log 2>&1
if [ $? -eq 0 ]; then
    TESTS=$(grep -c "PASS: Test" /tmp/test-output.log)
    echo "  ✓ All tests passed ($TESTS tests)"
else
    echo "  ✗ Tests failed"
    cat /tmp/test-output.log
    exit 1
fi
echo ""

# Check Go code compiles
echo "Checking compilation..."
go build ./... > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "  ✓ All packages compile successfully"
else
    echo "  ✗ Compilation errors"
    exit 1
fi
echo ""

# Start server briefly to test
echo "Testing server startup..."
./bin/robot-race -addr :9999 > /tmp/server-verify.log 2>&1 &
SERVER_PID=$!
sleep 2

# Check if server is running
if ps -p $SERVER_PID > /dev/null; then
    echo "  ✓ Server started successfully"
    
    # Test endpoints
    echo "Testing endpoints..."
    
    # Homepage
    if curl -s http://localhost:9999 | grep -q "RobotRace"; then
        echo "    ✓ Homepage accessible"
    else
        echo "    ✗ Homepage failed"
        kill $SERVER_PID
        exit 1
    fi
    
    # Create game
    LOCATION=$(curl -s -I -X POST http://localhost:9999/create | grep -i location | tr -d '\r')
    if [ -n "$LOCATION" ]; then
        echo "    ✓ Game creation works"
    else
        echo "    ✗ Game creation failed"
        kill $SERVER_PID
        exit 1
    fi
    
    # Stop server
    kill $SERVER_PID
    wait $SERVER_PID 2>/dev/null
    echo "  ✓ Server stopped cleanly"
else
    echo "  ✗ Server failed to start"
    cat /tmp/server-verify.log
    exit 1
fi
echo ""

# Check documentation
echo "Checking documentation..."
DOCS=(
    "README_GO.md"
    "COMPARISON.md"
    "DEPLOYMENT.md"
    "SUMMARY.md"
)

for doc in "${DOCS[@]}"; do
    LINES=$(wc -l < "$doc")
    echo "  ✓ $doc ($LINES lines)"
done
echo ""

# Statistics
echo "=== Project Statistics ==="
echo "Go source files: $(find . -name '*.go' -not -path './vendor/*' | wc -l)"
echo "Total Go LOC: $(find . -name '*.go' -not -path './vendor/*' -exec cat {} \; | wc -l)"
echo "Test files: $(find . -name '*_test.go' | wc -l)"
echo "Documentation files: $(ls -1 *.md | wc -l)"
echo ""

echo "=== ✅ All Verifications Passed! ==="
echo ""
echo "The Robot Race Go implementation is complete and functional."
echo ""
echo "Quick Start:"
echo "  ./bin/robot-race -addr :8080"
echo "  Then visit http://localhost:8080"
echo ""
