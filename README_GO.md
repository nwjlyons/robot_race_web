# RobotRace - Go Edition

A multiplayer racing game written in Go with WebSocket support. Players race robots to the top by pressing the spacebar or tapping the screen. First to reach the winning score wins!

## Features

- **Real-time multiplayer**: Multiple players can join the same game
- **WebSocket-based**: Real-time game state synchronization
- **Distributed architecture**: Can run on multiple servers with players connecting to different instances
- **Responsive design**: Works on desktop and mobile devices
- **Retro aesthetic**: Pixel art style with glowing robots

## Quick Start

### Prerequisites

- Go 1.21 or higher

### Installation

```bash
# Clone the repository
git clone https://github.com/nwjlyons/robot_race_web.git
cd robot_race_web

# Download dependencies
go mod tidy

# Build the server
go build -o bin/robot-race ./cmd/server
```

### Running the Server

```bash
# Run with default settings (port 8080)
./bin/robot-race

# Or specify a custom port
./bin/robot-race -addr :3000
```

Then open your browser to `http://localhost:8080`

## How to Play

1. **Create a game**: Click "Create New Game" on the home page
2. **Share the link**: Copy the invite link and share with other players
3. **Join the game**: Players enter their names and join
4. **Start**: The first player (admin) clicks "Start countdown"
5. **Race**: Press SPACEBAR (or tap on mobile) to move your robot up
6. **Win**: First robot to reach the winning score (default: 25) wins!
7. **Play again**: Admin can start a new round with the same players

## Game Configuration

Default settings:
- **Winning Score**: 25 points
- **Players**: 2-10 robots per game
- **Countdown**: 3 seconds

## Architecture

### Core Components

- **Game Engine** (`internal/game`): Core game logic, robot management, scoring
- **Hub** (`internal/hub`): Manages game instances and client connections
- **Server** (`internal/server`): HTTP and WebSocket server implementation
- **Main** (`cmd/server`): Application entry point

### Multi-Server Support

The application is designed to support distributed gameplay:

1. **Game State**: Each game instance runs independently
2. **WebSocket Sync**: All clients connected to a game receive real-time updates
3. **Session Management**: Cookies track player sessions across requests

For production deployment with multiple servers, you can:
- Run multiple instances behind a load balancer
- Use sticky sessions to ensure WebSocket connections stay with the same server
- Implement Redis-based pub/sub for cross-server game state synchronization (future enhancement)

## Development

### Project Structure

```
robot_race_web/
├── cmd/
│   └── server/          # Main application
│       └── main.go
├── internal/
│   ├── game/           # Game logic
│   │   ├── game.go
│   │   ├── robot.go
│   │   └── config.go
│   ├── hub/            # Connection & game management
│   │   └── hub.go
│   └── server/         # HTTP & WebSocket server
│       ├── server.go
│       └── templates.go
├── go.mod
├── go.sum
└── README_GO.md
```

### Building

```bash
# Build for current platform
go build -o bin/robot-race ./cmd/server

# Build for Linux
GOOS=linux GOARCH=amd64 go build -o bin/robot-race-linux ./cmd/server

# Build for macOS
GOOS=darwin GOARCH=amd64 go build -o bin/robot-race-macos ./cmd/server

# Build for Windows
GOOS=windows GOARCH=amd64 go build -o bin/robot-race.exe ./cmd/server
```

### Running Tests

```bash
go test ./...
```

## Docker Deployment

```bash
# Build the Docker image
docker build -t robot-race .

# Run the container
docker run -p 8080:8080 robot-race
```

## Original Implementation

This is a rewrite of the original Phoenix LiveView implementation. The original used:
- Elixir/Phoenix for the backend
- Phoenix LiveView for real-time updates
- Phoenix PubSub for message broadcasting

The Go version maintains the same gameplay while using:
- Pure Go for the backend
- WebSockets for real-time communication
- In-memory hub for message broadcasting

## License

Same as the original project.

## Credits

Original Phoenix LiveView version by nwjlyons
Go rewrite maintains the same game mechanics and visual design
