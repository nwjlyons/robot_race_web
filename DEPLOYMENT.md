# Deployment Guide - Robot Race Go

This guide covers deploying the Go version of Robot Race to various platforms.

## Local Development

```bash
# Build and run
go build -o bin/robot-race ./cmd/server
./bin/robot-race -addr :8080
```

## Docker Deployment

### Build Image

```bash
docker build -f Dockerfile.golang -t robot-race:latest .
```

### Run Container

```bash
# Single instance
docker run -p 8080:8080 robot-race:latest

# With custom port
docker run -p 3000:3000 robot-race:latest ./robot-race -addr :3000
```

## Multi-Server Deployment

### Using Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  robot-race-1:
    build:
      context: .
      dockerfile: Dockerfile.golang
    ports:
      - "8080:8080"
    command: ["./robot-race", "-addr", ":8080"]
    
  robot-race-2:
    build:
      context: .
      dockerfile: Dockerfile.golang
    ports:
      - "8081:8080"
    command: ["./robot-race", "-addr", ":8080"]
    
  robot-race-3:
    build:
      context: .
      dockerfile: Dockerfile.golang
    ports:
      - "8082:8080"
    command: ["./robot-race", "-addr", ":8080"]

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - robot-race-1
      - robot-race-2
      - robot-race-3
```

Create `nginx.conf`:

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

Run:
```bash
docker-compose up
```

## Cloud Platforms

### Fly.io

1. Install flyctl: `curl -L https://fly.io/install.sh | sh`
2. Login: `fly auth login`
3. Create app: `fly launch`
4. Deploy: `fly deploy`

Example `fly.toml`:

```toml
app = "robot-race-go"

[build]
  dockerfile = "Dockerfile.golang"

[env]
  PORT = "8080"

[[services]]
  internal_port = 8080
  protocol = "tcp"

  [[services.ports]]
    handlers = ["http"]
    port = 80

  [[services.ports]]
    handlers = ["tls", "http"]
    port = 443
```

### Heroku

```bash
# Create Heroku app
heroku create robot-race-go

# Set buildpack
heroku buildpacks:set heroku/go

# Deploy
git push heroku main
```

Create `Procfile`:
```
web: ./bin/robot-race -addr :$PORT
```

### AWS EC2

1. Launch EC2 instance (Amazon Linux 2)
2. Install Go:
   ```bash
   wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
   sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
   echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
   source ~/.bashrc
   ```
3. Clone and build:
   ```bash
   git clone https://github.com/nwjlyons/robot_race_web.git
   cd robot_race_web
   go build -o robot-race ./cmd/server
   ```
4. Run with systemd:

Create `/etc/systemd/system/robot-race.service`:
```ini
[Unit]
Description=Robot Race Game Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/robot_race_web
ExecStart=/home/ec2-user/robot_race_web/robot-race -addr :8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable robot-race
sudo systemctl start robot-race
```

### Google Cloud Run

Create `cloudbuild.yaml`:
```yaml
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-f', 'Dockerfile.golang', '-t', 'gcr.io/$PROJECT_ID/robot-race', '.']
images:
  - 'gcr.io/$PROJECT_ID/robot-race'
```

Deploy:
```bash
gcloud builds submit --config cloudbuild.yaml
gcloud run deploy robot-race --image gcr.io/$PROJECT_ID/robot-race --platform managed
```

## Kubernetes

Create `k8s-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: robot-race
spec:
  replicas: 3
  selector:
    matchLabels:
      app: robot-race
  template:
    metadata:
      labels:
        app: robot-race
    spec:
      containers:
      - name: robot-race
        image: robot-race:latest
        ports:
        - containerPort: 8080
        args: ["-addr", ":8080"]
---
apiVersion: v1
kind: Service
metadata:
  name: robot-race
spec:
  type: LoadBalancer
  sessionAffinity: ClientIP  # Sticky sessions for WebSocket
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: robot-race
```

Deploy:
```bash
kubectl apply -f k8s-deployment.yaml
```

## Performance Tuning

### Environment Variables

The Go version currently uses command-line flags. For production, you might want to add environment variable support:

```go
addr := os.Getenv("PORT")
if addr == "" {
    addr = ":8080"
}
```

### Optimization Flags

Build with optimizations:
```bash
go build -ldflags="-s -w" -o bin/robot-race ./cmd/server
```

- `-s`: Omit symbol table
- `-w`: Omit DWARF debug info

### Resource Limits

For Docker:
```bash
docker run -m 512m --cpus 1 -p 8080:8080 robot-race:latest
```

## Monitoring

### Health Check Endpoint

Add to `server.go`:
```go
http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("OK"))
})
```

### Metrics

Consider adding Prometheus metrics:
```go
import "github.com/prometheus/client_golang/prometheus/promhttp"

http.Handle("/metrics", promhttp.Handler())
```

## Security

### HTTPS

For production, always use HTTPS:

1. Get SSL certificate (Let's Encrypt)
2. Use reverse proxy (nginx, Caddy)
3. Or use Go's TLS support:

```go
log.Fatal(http.ListenAndServeTLS(":443", "cert.pem", "key.pem", nil))
```

### Rate Limiting

Consider adding rate limiting middleware to prevent abuse.

## Troubleshooting

### WebSocket Connection Issues

- Ensure load balancer supports WebSocket upgrades
- Use sticky sessions (ip_hash in nginx)
- Check firewall rules for WebSocket ports

### High Memory Usage

- Monitor with: `go tool pprof http://localhost:8080/debug/pprof/heap`
- Implement game cleanup for inactive games
- Set timeouts for idle connections

### Connection Drops

- Increase WebSocket timeout settings
- Implement reconnection logic in client
- Check for proxy timeout settings

## Further Enhancements

Consider implementing:

1. **Redis Integration**: For cross-server game state
2. **Database**: Store game history and statistics  
3. **Metrics Dashboard**: Real-time monitoring
4. **Auto-scaling**: Based on active games
5. **CDN**: For static assets
6. **API Authentication**: For secure game creation
