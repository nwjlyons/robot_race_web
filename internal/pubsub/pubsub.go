package pubsub

import (
"context"
"encoding/json"
"fmt"
"log"
"time"

"github.com/redis/go-redis/v9"
)

// Message represents a pub/sub message
type Message struct {
Channel string
Data    []byte
}

// PubSub wraps Redis pub/sub functionality
type PubSub struct {
client    *redis.Client
ctx       context.Context
pubsub    *redis.PubSub
msgChan   chan *Message
isEnabled bool
}

// Config holds Redis configuration
type Config struct {
Addr     string
Password string
DB       int
Enabled  bool
}

// DefaultConfig returns default Redis configuration
func DefaultConfig() *Config {
return &Config{
Addr:     "localhost:6379",
Password: "",
DB:       0,
Enabled:  false, // Disabled by default for backward compatibility
}
}

// New creates a new PubSub instance
func New(cfg *Config) (*PubSub, error) {
if cfg == nil {
cfg = DefaultConfig()
}

// If Redis is not enabled, return a no-op pubsub
if !cfg.Enabled {
log.Println("Redis pub/sub disabled - running in single-server mode")
return &PubSub{
isEnabled: false,
msgChan:   make(chan *Message, 100),
}, nil
}

client := redis.NewClient(&redis.Options{
Addr:     cfg.Addr,
Password: cfg.Password,
DB:       cfg.DB,
})

ctx := context.Background()

// Test connection
if err := client.Ping(ctx).Err(); err != nil {
log.Printf("WARNING: Failed to connect to Redis at %s: %v", cfg.Addr, err)
log.Println("Falling back to single-server mode (no cross-server communication)")
return &PubSub{
isEnabled: false,
msgChan:   make(chan *Message, 100),
}, nil
}

log.Printf("Connected to Redis at %s - multi-server mode enabled", cfg.Addr)

return &PubSub{
client:    client,
ctx:       ctx,
msgChan:   make(chan *Message, 100),
isEnabled: true,
}, nil
}

// Subscribe subscribes to channels and starts receiving messages
func (p *PubSub) Subscribe(channels ...string) error {
if !p.isEnabled {
// No-op for disabled Redis
return nil
}

p.pubsub = p.client.Subscribe(p.ctx, channels...)

// Wait for confirmation
_, err := p.pubsub.Receive(p.ctx)
if err != nil {
return fmt.Errorf("failed to subscribe: %w", err)
}

// Start receiving messages
go p.receiveMessages()

log.Printf("Subscribed to Redis channels: %v", channels)
return nil
}

// receiveMessages receives messages from Redis and forwards them to the channel
func (p *PubSub) receiveMessages() {
ch := p.pubsub.Channel()
for msg := range ch {
p.msgChan <- &Message{
Channel: msg.Channel,
Data:    []byte(msg.Payload),
}
}
}

// Publish publishes a message to a channel
func (p *PubSub) Publish(channel string, data interface{}) error {
if !p.isEnabled {
// No-op for disabled Redis - message stays local
return nil
}

var payload []byte
var err error

switch v := data.(type) {
case []byte:
payload = v
case string:
payload = []byte(v)
default:
payload, err = json.Marshal(data)
if err != nil {
return fmt.Errorf("failed to marshal data: %w", err)
}
}

return p.client.Publish(p.ctx, channel, payload).Err()
}

// Messages returns the channel for receiving messages
func (p *PubSub) Messages() <-chan *Message {
return p.msgChan
}

// Close closes the pub/sub connection
func (p *PubSub) Close() error {
if !p.isEnabled {
return nil
}

if p.pubsub != nil {
if err := p.pubsub.Close(); err != nil {
return err
}
}

if p.client != nil {
return p.client.Close()
}

return nil
}

// IsEnabled returns whether Redis pub/sub is enabled
func (p *PubSub) IsEnabled() bool {
return p.isEnabled
}

// Set stores a value in Redis with optional expiration
func (p *PubSub) Set(key string, value interface{}, expiration time.Duration) error {
if !p.isEnabled {
return nil
}

var payload []byte
var err error

switch v := value.(type) {
case []byte:
payload = v
case string:
payload = []byte(v)
default:
payload, err = json.Marshal(value)
if err != nil {
return fmt.Errorf("failed to marshal value: %w", err)
}
}

return p.client.Set(p.ctx, key, payload, expiration).Err()
}

// Get retrieves a value from Redis
func (p *PubSub) Get(key string) ([]byte, error) {
if !p.isEnabled {
return nil, redis.Nil
}

return p.client.Get(p.ctx, key).Bytes()
}

// Delete removes a key from Redis
func (p *PubSub) Delete(key string) error {
if !p.isEnabled {
return nil
}

return p.client.Del(p.ctx, key).Err()
}
