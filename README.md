<div align="center">
   <h1>RobotRaceWeb</h1>
   <p>Phoenix.LiveView racing game. First to the top wins.</p>
   <p>Now also available in <strong>Go</strong>!</p>
   <p><a href="https://robotrace.snowlion.io/">https://robotrace.snowlion.io</a></p>
   <img src="screenshot.png">
</div>

## Implementations

This repository contains **two implementations** of the same game:

1. **Elixir/Phoenix** (original) - Full LiveView implementation
2. **Go** (new) - WebSocket-based implementation with multi-server support

### Quick Start

#### Elixir/Phoenix Version
```bash
# Install dependencies
mix deps.get

# Start server
mix phx.server
```

Visit `http://localhost:4000`

#### Go Version
```bash
# Build
go build -o bin/robot-race ./cmd/server

# Run
./bin/robot-race -addr :8080
```

Visit `http://localhost:8080`

## Documentation

- [Go Implementation README](README_GO.md) - Complete guide for the Go version
- [Implementation Comparison](COMPARISON.md) - Detailed comparison between Elixir and Go versions
- [Original README sections below]

---
