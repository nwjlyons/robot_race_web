package server

import (
	"encoding/json"
	"html/template"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
	"github.com/nwjlyons/robot_race_web/internal/game"
	"github.com/nwjlyons/robot_race_web/internal/hub"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins for now
	},
}

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 512
)

// Server represents the HTTP server
type Server struct {
	hub      *hub.Hub
	addr     string
	sessions map[string]*Session // session ID -> Session
}

// Session holds session data
type Session struct {
	GameID  string
	RobotID string
}

// NewServer creates a new server
func NewServer(addr string, h *hub.Hub) *Server {
	return &Server{
		hub:      h,
		addr:     addr,
		sessions: make(map[string]*Session),
	}
}

// Start starts the HTTP server
func (s *Server) Start() error {
	http.HandleFunc("/", s.handleIndex)
	http.HandleFunc("/create", s.handleCreate)
	http.HandleFunc("/join/", s.handleJoinForm)
	http.HandleFunc("/join-game", s.handleJoinGame)
	http.HandleFunc("/game/", s.handleGame)
	http.HandleFunc("/ws", s.handleWebSocket)
	http.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("static"))))

	log.Printf("Server starting on %s", s.addr)
	return http.ListenAndServe(s.addr, nil)
}

func (s *Server) handleIndex(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}

	tmpl := template.Must(template.New("index").Parse(indexHTML))
	tmpl.Execute(w, nil)
}

func (s *Server) handleCreate(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	g := s.hub.CreateGame(game.DefaultConfig())
	http.Redirect(w, r, "/join/"+g.ID, http.StatusSeeOther)
}

func (s *Server) handleJoinForm(w http.ResponseWriter, r *http.Request) {
	gameID := r.URL.Path[len("/join/"):]

	g, ok := s.hub.GetGame(gameID)
	if !ok {
		http.Error(w, "Game not found", http.StatusNotFound)
		return
	}

	data := struct {
		GameID string
		Game   *game.Game
	}{
		GameID: gameID,
		Game:   g,
	}

	tmpl := template.Must(template.New("join").Parse(joinHTML))
	tmpl.Execute(w, data)
}

func (s *Server) handleJoinGame(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	gameID := r.FormValue("game_id")
	name := r.FormValue("name")

	if name == "" {
		http.Error(w, "Name is required", http.StatusBadRequest)
		return
	}

	g, ok := s.hub.GetGame(gameID)
	if !ok {
		http.Error(w, "Game not found", http.StatusNotFound)
		return
	}

	// First player is admin
	role := game.RoleGuest
	if len(g.Robots) == 0 {
		role = game.RoleAdmin
	}

	robot := game.NewRobot(name, role)
	err := s.hub.JoinGame(gameID, robot)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Create session
	sessionID := generateSessionID()
	s.sessions[sessionID] = &Session{
		GameID:  gameID,
		RobotID: robot.ID,
	}

	// Set cookie
	http.SetCookie(w, &http.Cookie{
		Name:     "session_id",
		Value:    sessionID,
		Path:     "/",
		MaxAge:   86400, // 24 hours
		HttpOnly: true,
	})

	s.hub.BroadcastGameUpdate(gameID)
	http.Redirect(w, r, "/game/"+gameID, http.StatusSeeOther)
}

func (s *Server) handleGame(w http.ResponseWriter, r *http.Request) {
	gameID := r.URL.Path[len("/game/"):]

	cookie, err := r.Cookie("session_id")
	if err != nil {
		http.Redirect(w, r, "/join/"+gameID, http.StatusSeeOther)
		return
	}

	session, ok := s.sessions[cookie.Value]
	if !ok || session.GameID != gameID {
		http.Redirect(w, r, "/join/"+gameID, http.StatusSeeOther)
		return
	}

	g, ok := s.hub.GetGame(gameID)
	if !ok {
		http.Error(w, "Game not found", http.StatusNotFound)
		return
	}

	data := struct {
		Game    *game.Game
		RobotID string
		IsAdmin bool
		GameURL string
	}{
		Game:    g,
		RobotID: session.RobotID,
		IsAdmin: g.IsAdmin(session.RobotID),
		GameURL: r.Host + "/join/" + gameID,
	}

	tmpl := template.Must(template.New("game").Parse(gameHTML))
	tmpl.Execute(w, data)
}

func (s *Server) handleWebSocket(w http.ResponseWriter, r *http.Request) {
	cookie, err := r.Cookie("session_id")
	if err != nil {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	session, ok := s.sessions[cookie.Value]
	if !ok {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println(err)
		return
	}

	client := &hub.Client{
		ID:      generateSessionID(),
		GameID:  session.GameID,
		RobotID: session.RobotID,
		Send:    make(chan []byte, 256),
		Hub:     s.hub,
	}

	s.hub.RegisterClient(client)

	// Start goroutines for reading and writing
	go s.writePump(client, conn)
	go s.readPump(client, conn)

	// Send initial game state
	s.hub.BroadcastGameUpdate(session.GameID)
}

func (s *Server) readPump(client *hub.Client, conn *websocket.Conn) {
	defer func() {
		s.hub.UnregisterClient(client)
		conn.Close()
	}()

	conn.SetReadDeadline(time.Now().Add(pongWait))
	conn.SetPongHandler(func(string) error {
		conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, message, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("error: %v", err)
			}
			break
		}

		s.handleMessage(client, message)
	}
}

func (s *Server) writePump(client *hub.Client, conn *websocket.Conn) {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		conn.Close()
	}()

	for {
		select {
		case message, ok := <-client.Send:
			conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func (s *Server) handleMessage(client *hub.Client, message []byte) {
	var msg hub.Message
	if err := json.Unmarshal(message, &msg); err != nil {
		log.Printf("error unmarshaling message: %v", err)
		return
	}

	switch msg.Type {
	case "score_point":
		s.hub.ScorePoint(client.GameID, client.RobotID)
	case "start_countdown":
		g, _ := s.hub.GetGame(client.GameID)
		if g.IsAdmin(client.RobotID) {
			s.hub.StartCountdown(client.GameID)
		}
	case "play_again":
		g, _ := s.hub.GetGame(client.GameID)
		if g.IsAdmin(client.RobotID) {
			s.hub.PlayAgain(client.GameID)
		}
	}
}

func generateSessionID() string {
	return time.Now().Format("20060102150405") + "-" + randomString(16)
}

func randomString(n int) string {
	const letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	b := make([]byte, n)
	for i := range b {
		b[i] = letters[time.Now().UnixNano()%int64(len(letters))]
	}
	return string(b)
}
