package main

import (
"flag"
"log"

"github.com/nwjlyons/robot_race_web/internal/hub"
"github.com/nwjlyons/robot_race_web/internal/server"
)

func main() {
addr := flag.String("addr", ":8080", "HTTP server address")
flag.Parse()

// Create hub
h := hub.NewHub()
go h.Run()

// Create and start server
srv := server.NewServer(*addr, h)
log.Fatal(srv.Start())
}
