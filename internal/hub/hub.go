package hub

import (
	"encoding/json"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/nwjlyons/robot_race_web/internal/game"
	"github.com/nwjlyons/robot_race_web/internal/pubsub"
)

// Client represents a connected WebSocket client
type Client struct {
	ID     string
	GameID string
	RobotID string
	Send   chan []byte
	Hub    *Hub
}

// Message represents a message sent between client and server
type Message struct {
	Type    string          `json:"type"`
	Payload json.RawMessage `json:"payload,omitempty"`
}

// Hub manages game instances and client connections
type Hub struct {
	mu sync.RWMutex

	// Game instances
	games map[string]*game.Game

	// Clients connected to each game
	clients map[string]map[*Client]bool

	// Register client
	register chan *Client

	// Unregister client
	unregister chan *Client

	// Broadcast message to all clients in a game
	broadcast chan *BroadcastMessage

	// Redis pub/sub for cross-server communication
	pubsub *pubsub.PubSub
}

// BroadcastMessage contains a message to broadcast to a game
type BroadcastMessage struct {
	GameID string
	Data   []byte
}

// NewHub creates a new Hub
func NewHub(ps *pubsub.PubSub) *Hub {
	h := &Hub{
		games:      make(map[string]*game.Game),
		clients:    make(map[string]map[*Client]bool),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		broadcast:  make(chan *BroadcastMessage),
		pubsub:     ps,
	}

	// Subscribe to game updates channel if Redis is enabled
	if ps != nil && ps.IsEnabled() {
		if err := ps.Subscribe("game:*"); err != nil {
			log.Printf("Failed to subscribe to Redis channels: %v", err)
		}
	}

	return h
}

// Run starts the hub's main loop
func (h *Hub) Run() {
	// Start Redis message handler if enabled
	if h.pubsub != nil && h.pubsub.IsEnabled() {
		go h.handleRedisMessages()
	}

	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			if h.clients[client.GameID] == nil {
				h.clients[client.GameID] = make(map[*Client]bool)
			}
			h.clients[client.GameID][client] = true
			h.mu.Unlock()

		case client := <-h.unregister:
			h.mu.Lock()
			if clients, ok := h.clients[client.GameID]; ok {
				if _, ok := clients[client]; ok {
					delete(clients, client)
					close(client.Send)
				}
			}
			h.mu.Unlock()

		case message := <-h.broadcast:
			h.broadcastToLocalClients(message)
		}
	}
}

// handleRedisMessages processes messages from Redis pub/sub
func (h *Hub) handleRedisMessages() {
	for msg := range h.pubsub.Messages() {
		// Forward Redis messages to local clients
		h.broadcastToLocalClients(&BroadcastMessage{
			GameID: msg.Channel[5:], // Remove "game:" prefix
			Data:   msg.Data,
		})
	}
}

// broadcastToLocalClients sends a message to all local WebSocket clients for a game
func (h *Hub) broadcastToLocalClients(message *BroadcastMessage) {
	h.mu.RLock()
	clients := h.clients[message.GameID]
	h.mu.RUnlock()

	for client := range clients {
		select {
		case client.Send <- message.Data:
		default:
			close(client.Send)
			h.mu.Lock()
			delete(h.clients[message.GameID], client)
			h.mu.Unlock()
		}
	}
}

// CreateGame creates a new game with the given configuration
func (h *Hub) CreateGame(config *game.Config) *game.Game {
	h.mu.Lock()
	defer h.mu.Unlock()

	g := game.NewGame(config)
	h.games[g.ID] = g

	// Store game in Redis if enabled
	if h.pubsub != nil && h.pubsub.IsEnabled() {
		if err := h.storeGameInRedis(g); err != nil {
			log.Printf("Failed to store game in Redis: %v", err)
		}
	}

	return g
}

// storeGameInRedis stores game state in Redis
func (h *Hub) storeGameInRedis(g *game.Game) error {
	data, err := json.Marshal(g)
	if err != nil {
		return err
	}
	return h.pubsub.Set(fmt.Sprintf("game_state:%s", g.ID), data, 24*time.Hour)
}

// GetGame retrieves a game by ID
func (h *Hub) GetGame(gameID string) (*game.Game, bool) {
	h.mu.RLock()
	g, ok := h.games[gameID]
	h.mu.RUnlock()

	if ok {
		return g, true
	}

	// Try to load from Redis if enabled
	if h.pubsub != nil && h.pubsub.IsEnabled() {
		g, err := h.loadGameFromRedis(gameID)
		if err == nil && g != nil {
			h.mu.Lock()
			h.games[gameID] = g
			h.mu.Unlock()
			return g, true
		}
	}

	return nil, false
}

// loadGameFromRedis loads game state from Redis
func (h *Hub) loadGameFromRedis(gameID string) (*game.Game, error) {
	data, err := h.pubsub.Get(fmt.Sprintf("game_state:%s", gameID))
	if err != nil {
		return nil, err
	}

	var g game.Game
	if err := json.Unmarshal(data, &g); err != nil {
		return nil, err
	}

	return &g, nil
}

// JoinGame adds a robot to a game
func (h *Hub) JoinGame(gameID string, robot *game.Robot) error {
	h.mu.RLock()
	g, ok := h.games[gameID]
	h.mu.RUnlock()

	if !ok {
		// Try to load from Redis
		if h.pubsub != nil && h.pubsub.IsEnabled() {
			loadedGame, err := h.loadGameFromRedis(gameID)
			if err == nil && loadedGame != nil {
				h.mu.Lock()
				h.games[gameID] = loadedGame
				g = loadedGame
				h.mu.Unlock()
				ok = true
			}
		}

		if !ok {
			return game.ErrGameInProgress
		}
	}

	err := g.Join(robot)
	if err == nil {
		// Update game in Redis if enabled
		if h.pubsub != nil && h.pubsub.IsEnabled() {
			if err := h.storeGameInRedis(g); err != nil {
				log.Printf("Failed to update game in Redis after join: %v", err)
			}
		}
	}

	return err
}

// BroadcastGameUpdate sends the current game state to all connected clients
func (h *Hub) BroadcastGameUpdate(gameID string) {
	h.mu.RLock()
	g, ok := h.games[gameID]
	h.mu.RUnlock()

	if !ok {
		return
	}

	// Update game state in Redis if enabled
	if h.pubsub != nil && h.pubsub.IsEnabled() {
		if err := h.storeGameInRedis(g); err != nil {
			log.Printf("Failed to update game in Redis: %v", err)
		}
	}

	msg := Message{
		Type: "game_update",
		Payload: mustMarshal(map[string]interface{}{
			"game": g,
		}),
	}

	data := mustMarshal(msg)

	// Publish to Redis for cross-server distribution
	if h.pubsub != nil && h.pubsub.IsEnabled() {
		channel := fmt.Sprintf("game:%s", gameID)
		if err := h.pubsub.Publish(channel, data); err != nil {
			log.Printf("Failed to publish to Redis: %v", err)
		}
	}

	// Broadcast to local clients
	h.broadcast <- &BroadcastMessage{
		GameID: gameID,
		Data:   data,
	}
}

// StartCountdown begins the countdown for a game
func (h *Hub) StartCountdown(gameID string) {
	h.mu.RLock()
	g, ok := h.games[gameID]
	h.mu.RUnlock()

	if !ok {
		return
	}

	g.StartCountdown()
	h.BroadcastGameUpdate(gameID)

	// Start countdown timer
	go h.runCountdown(gameID)
}

func (h *Hub) runCountdown(gameID string) {
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	for range ticker.C {
		h.mu.RLock()
		g, ok := h.games[gameID]
		h.mu.RUnlock()

		if !ok {
			return
		}

		state := g.DecrementCountdown()
		h.BroadcastGameUpdate(gameID)

		if state == game.StatePlaying {
			return
		}
	}
}

// ScorePoint scores a point for a robot in a game
func (h *Hub) ScorePoint(gameID, robotID string) {
	h.mu.RLock()
	g, ok := h.games[gameID]
	h.mu.RUnlock()

	if !ok {
		return
	}

	if g.ScorePoint(robotID) {
		h.BroadcastGameUpdate(gameID)
	}
}

// PlayAgain resets a game for another round
func (h *Hub) PlayAgain(gameID string) {
	h.mu.RLock()
	g, ok := h.games[gameID]
	h.mu.RUnlock()

	if !ok {
		return
	}

	g.PlayAgain()
	h.BroadcastGameUpdate(gameID)
}

// RegisterClient registers a client with the hub
func (h *Hub) RegisterClient(client *Client) {
	h.register <- client
}

// UnregisterClient unregisters a client from the hub
func (h *Hub) UnregisterClient(client *Client) {
	h.unregister <- client
}

func mustMarshal(v interface{}) json.RawMessage {
	data, err := json.Marshal(v)
	if err != nil {
		panic(err)
	}
	return data
}
