package main

import (
"flag"
"log"
"os"

"github.com/nwjlyons/robot_race_web/internal/hub"
"github.com/nwjlyons/robot_race_web/internal/pubsub"
"github.com/nwjlyons/robot_race_web/internal/server"
)

func main() {
addr := flag.String("addr", ":8080", "HTTP server address")
redisAddr := flag.String("redis", os.Getenv("REDIS_URL"), "Redis server address (e.g., localhost:6379)")
redisPassword := flag.String("redis-password", os.Getenv("REDIS_PASSWORD"), "Redis password")
flag.Parse()

// Configure Redis pub/sub
redisCfg := &pubsub.Config{
Addr:     "localhost:6379",
Password: "",
DB:       0,
Enabled:  false,
}

// Enable Redis if address is provided
if *redisAddr != "" {
redisCfg.Addr = *redisAddr
redisCfg.Enabled = true
if *redisPassword != "" {
redisCfg.Password = *redisPassword
}
}

// Create pub/sub
ps, err := pubsub.New(redisCfg)
if err != nil {
log.Fatalf("Failed to create pub/sub: %v", err)
}
defer ps.Close()

// Create hub
h := hub.NewHub(ps)
go h.Run()

// Create and start server
srv := server.NewServer(*addr, h)
log.Fatal(srv.Start())
}
