# Multi-Server Deployment with Redis

This guide explains how to deploy Robot Race across multiple servers with Redis-based pub/sub for cross-server communication.

## Overview

By default, Robot Race runs in **single-server mode** where games are isolated to each server instance. With Redis enabled, multiple servers can share game state and synchronize in real-time, allowing players on different servers to play together.

## Architecture

### Single-Server Mode (Default)
- Games stored in memory
- WebSocket connections only to local clients
- No cross-server communication
- Simpler deployment, no Redis required

### Multi-Server Mode (Redis Enabled)
- Games synchronized via Redis
- WebSocket updates distributed across all servers
- Players can join games created on any server
- Requires Redis instance

## Quick Start

### Without Redis (Single Server)
```bash
./bin/robot-race -addr :8080
```

### With Redis (Multi-Server)
```bash
./bin/robot-race -addr :8080 -redis localhost:6379
```

With password:
```bash
./bin/robot-race -addr :8080 -redis localhost:6379 -redis-password yourpassword
```

Using environment variables:
```bash
export REDIS_URL=localhost:6379
export REDIS_PASSWORD=yourpassword
./bin/robot-race -addr :8080 -redis $REDIS_URL
```

## Redis Setup

### Install Redis Locally
```bash
# macOS
brew install redis
brew services start redis

# Ubuntu/Debian
sudo apt-get install redis-server
sudo systemctl start redis

# Docker
docker run -d -p 6379:6379 redis:alpine
```

### Test Redis Connection
```bash
redis-cli ping
# Should return: PONG
```

## Multi-Server Deployment Example

### Using Docker Compose

Create `docker-compose-redis.yml`:

```yaml
version: '3.8'

services:
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data

  robot-race-1:
    build:
      context: .
      dockerfile: Dockerfile.golang
    ports:
      - "8080:8080"
    environment:
      - REDIS_URL=redis:6379
    command: ["./robot-race", "-addr", ":8080", "-redis", "redis:6379"]
    depends_on:
      - redis
    
  robot-race-2:
    build:
      context: .
      dockerfile: Dockerfile.golang
    ports:
      - "8081:8080"
    environment:
      - REDIS_URL=redis:6379
    command: ["./robot-race", "-addr", ":8080", "-redis", "redis:6379"]
    depends_on:
      - redis
    
  robot-race-3:
    build:
      context: .
      dockerfile: Dockerfile.golang
    ports:
      - "8082:8080"
    environment:
      - REDIS_URL=redis:6379
    command: ["./robot-race", "-addr", ":8080", "-redis", "redis:6379"]
    depends_on:
      - redis

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx-redis.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - robot-race-1
      - robot-race-2
      - robot-race-3

volumes:
  redis-data:
```

Create `nginx-redis.conf`:

```nginx
events {
    worker_connections 1024;
}

http {
    upstream robot_race {
        ip_hash;  # Sticky sessions for WebSocket
        server robot-race-1:8080;
        server robot-race-2:8080;
        server robot-race-3:8080;
    }

    server {
        listen 80;

        location / {
            proxy_pass http://robot_race;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

Start all services:
```bash
docker-compose -f docker-compose-redis.yml up
```

### Manual Multi-Server Setup

Terminal 1 - Redis:
```bash
redis-server
```

Terminal 2 - Server 1:
```bash
./bin/robot-race -addr :8080 -redis localhost:6379
```

Terminal 3 - Server 2:
```bash
./bin/robot-race -addr :8081 -redis localhost:6379
```

Terminal 4 - Server 3:
```bash
./bin/robot-race -addr :8082 -redis localhost:6379
```

Now:
1. Create a game on server 1 (http://localhost:8080)
2. Join from server 2 (http://localhost:8081/join/GAME_ID)
3. Join from server 3 (http://localhost:8082/join/GAME_ID)
4. All players can see each other and play together!

## How It Works

### Game State Synchronization

1. **Game Creation**: When a game is created, it's stored in Redis with key `game_state:{gameID}`
2. **Game Updates**: Every game state change (join, score, countdown) is:
   - Saved to Redis
   - Published to Redis channel `game:{gameID}`
3. **Cross-Server Updates**: Each server:
   - Subscribes to `game:*` channels
   - Receives updates from other servers
   - Broadcasts to its local WebSocket clients

### Data Flow

```
Player on Server A                    Player on Server B
       |                                      |
       | Press Space                          |
       ↓                                      |
  Server A Hub                                |
       |                                      |
       |---> Update Game State               |
       |---> Save to Redis                   |
       |---> Publish to Redis channel        |
       |                                      |
       |            Redis Pub/Sub             |
       |                 ↓                    |
       |          Server B Hub ←--------------┘
       |                 |
       |                 |---> Broadcast to local clients
       ↓                 ↓
  WebSocket          WebSocket
  Update            Update
```

## Configuration Options

### Command Line Flags

- `-addr` - HTTP server address (default: `:8080`)
- `-redis` - Redis server address (e.g., `localhost:6379`)
- `-redis-password` - Redis password (optional)

### Environment Variables

- `REDIS_URL` - Redis server address
- `REDIS_PASSWORD` - Redis password

## Cloud Deployments

### Heroku

Add Redis add-on:
```bash
heroku addons:create heroku-redis:hobby-dev
```

The `REDIS_URL` environment variable is automatically set.

### AWS

Use Amazon ElastiCache for Redis:
1. Create ElastiCache cluster
2. Set `REDIS_URL` environment variable to cluster endpoint
3. Ensure EC2 instances can reach ElastiCache (security groups)

### Google Cloud

Use Cloud Memorystore:
1. Create Redis instance
2. Connect from Compute Engine or GKE
3. Set `REDIS_URL` to instance IP

## Monitoring

### Redis Keys

View game states:
```bash
redis-cli KEYS "game_state:*"
```

View specific game:
```bash
redis-cli GET "game_state:YOUR_GAME_ID"
```

### Pub/Sub Channels

Monitor messages:
```bash
redis-cli PSUBSCRIBE "game:*"
```

### Server Logs

When Redis is enabled, you'll see:
```
Connected to Redis at localhost:6379 - multi-server mode enabled
Subscribed to Redis channels: [game:*]
```

When Redis is disabled or unavailable:
```
Redis pub/sub disabled - running in single-server mode
```

## Fallback Behavior

If Redis connection fails:
- Server automatically falls back to single-server mode
- Games work normally on that server
- No cross-server communication
- Logged as WARNING in server output

This ensures high availability - servers continue working even if Redis is down.

## Performance Considerations

### Redis Memory Usage

Each game stores approximately 1-5 KB in Redis. With 1000 concurrent games:
- Memory: ~5 MB
- Redis handles this easily

### Pub/Sub Latency

- Local Redis: <1ms latency
- Same datacenter: 1-5ms latency
- Cross-region: 50-200ms latency

For best performance, keep Redis in the same datacenter as your servers.

## Troubleshooting

### Connection Refused

```
WARNING: Failed to connect to Redis at localhost:6379: dial tcp: connection refused
```

**Solution**: Ensure Redis is running on the specified address.

### Authentication Failed

```
WARNING: Failed to connect to Redis: NOAUTH Authentication required
```

**Solution**: Provide Redis password with `-redis-password` flag.

### Games Not Syncing

**Check**:
1. All servers connected to same Redis instance
2. Redis pub/sub working: `redis-cli PSUBSCRIBE "game:*"`
3. Server logs show "multi-server mode enabled"

### High Latency

**Solutions**:
1. Use Redis in same datacenter
2. Increase Redis resources
3. Monitor network latency between servers and Redis

## Scaling

With Redis, you can scale horizontally:

1. **Add more servers**: Each new server automatically participates in game distribution
2. **Redis Cluster**: For very high scale, use Redis Cluster for data sharding
3. **Redis Sentinel**: For high availability, use Sentinel for automatic failover

## Security

### Redis Security

1. **Password Protection**:
   ```bash
   redis-server --requirepass yourpassword
   ```

2. **Network Isolation**: Only allow connections from app servers

3. **TLS/SSL**: Use Redis with TLS for encryption in transit

4. **Firewall Rules**: Restrict Redis port (6379) to known IPs

## Comparison: With vs Without Redis

| Feature | Without Redis | With Redis |
|---------|--------------|------------|
| Setup Complexity | Low | Medium |
| Cross-Server Games | ❌ No | ✅ Yes |
| Scalability | Single server | Multi-server |
| State Persistence | Memory only | Redis (optional persistence) |
| Failover | N/A | Automatic fallback |
| Deployment Cost | Low | Medium (Redis instance) |
| Latency | Lowest | Very low (<5ms) |

## Best Practices

1. **Development**: Run without Redis for simplicity
2. **Production**: Use Redis for multi-server deployments
3. **Monitoring**: Set up Redis monitoring and alerts
4. **Backups**: Enable Redis persistence (AOF or RDB)
5. **Testing**: Test failover scenarios (Redis down)

## Next Steps

- Set up Redis Sentinel for high availability
- Implement Redis Cluster for horizontal scaling
- Add Redis monitoring with Prometheus
- Configure Redis persistence for game state recovery
