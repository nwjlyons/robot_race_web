package game

import (
	"errors"
	"sync"

	"github.com/google/uuid"
)

// GameState represents the current state of a game
type GameState string

const (
	StateSetup        GameState = "setup"
	StateCountingDown GameState = "counting_down"
	StatePlaying      GameState = "playing"
	StateFinished     GameState = "finished"
)

var (
	ErrGameInProgress = errors.New("game in progress")
	ErrGameFull       = errors.New("game full")
)

// Game represents a robot race game
type Game struct {
	mu            sync.RWMutex
	ID            string              `json:"id"`
	WinningScore  int                 `json:"winning_score"`
	MaxRobots     int                 `json:"max_robots"`
	Countdown     int                 `json:"countdown"`
	Config        *Config             `json:"config"`
	Robots        []*Robot            `json:"robots"`
	State         GameState           `json:"state"`
	PreviousWins  map[string]int      `json:"previous_wins"`
	InitialConfig *Config             `json:"-"`
}

// NewGame creates a new game with the given configuration
func NewGame(config *Config) *Game {
	if config == nil {
		config = DefaultConfig()
	}
	return &Game{
		ID:            uuid.New().String(),
		WinningScore:  config.WinningScore,
		MaxRobots:     config.MaxRobots,
		Countdown:     config.Countdown,
		Config:        config,
		Robots:        []*Robot{},
		State:         StateSetup,
		PreviousWins:  make(map[string]int),
		InitialConfig: config,
	}
}

// Join adds a robot to the game
func (g *Game) Join(robot *Robot) error {
	g.mu.Lock()
	defer g.mu.Unlock()

	if g.State != StateSetup {
		return ErrGameInProgress
	}

	if len(g.Robots) >= g.MaxRobots {
		return ErrGameFull
	}

	g.Robots = append(g.Robots, robot)
	return nil
}

// ScorePoint adds a point to the robot with the given ID
func (g *Game) ScorePoint(robotID string) bool {
	g.mu.Lock()
	defer g.mu.Unlock()

	if g.State != StatePlaying {
		return false
	}

	for _, robot := range g.Robots {
		if robot.ID == robotID {
			robot.Score++
			if robot.Score >= g.WinningScore {
				g.State = StateFinished
			}
			return true
		}
	}

	return false
}

// StartCountdown begins the countdown sequence
func (g *Game) StartCountdown() {
	g.mu.Lock()
	defer g.mu.Unlock()

	if g.State == StateSetup {
		g.State = StateCountingDown
	}
}

// DecrementCountdown decreases the countdown by 1
func (g *Game) DecrementCountdown() GameState {
	g.mu.Lock()
	defer g.mu.Unlock()

	if g.State != StateCountingDown {
		return g.State
	}

	g.Countdown--
	if g.Countdown <= 0 {
		g.State = StatePlaying
	}

	return g.State
}

// GetWinner returns the robot with the highest score
func (g *Game) GetWinner() *Robot {
	g.mu.RLock()
	defer g.mu.RUnlock()

	if len(g.Robots) == 0 {
		return nil
	}

	winner := g.Robots[0]
	for _, robot := range g.Robots[1:] {
		if robot.Score > winner.Score {
			winner = robot
		}
	}

	return winner
}

// GetLeaderboard returns robots sorted by total wins
func (g *Game) GetLeaderboard() []LeaderboardEntry {
	g.mu.RLock()
	defer g.mu.RUnlock()

	winner := g.GetWinner()
	entries := make([]LeaderboardEntry, 0, len(g.Robots))

	for _, robot := range g.Robots {
		winCount := g.PreviousWins[robot.ID]
		if winner != nil && robot.ID == winner.ID {
			winCount++
		}
		entries = append(entries, LeaderboardEntry{
			Robot:    robot,
			WinCount: winCount,
		})
	}

	// Sort by win count descending
	for i := 0; i < len(entries); i++ {
		for j := i + 1; j < len(entries); j++ {
			if entries[j].WinCount > entries[i].WinCount {
				entries[i], entries[j] = entries[j], entries[i]
			}
		}
	}

	return entries
}

// PlayAgain resets the game for another round
func (g *Game) PlayAgain() {
	g.mu.Lock()
	defer g.mu.Unlock()

	winner := g.GetWinner()
	if winner != nil {
		g.PreviousWins[winner.ID]++
	}

	for _, robot := range g.Robots {
		robot.Score = 0
	}

	g.WinningScore = g.InitialConfig.WinningScore
	g.Countdown = g.InitialConfig.Countdown
	g.State = StateSetup
}

// IsAdmin checks if the robot with the given ID is an admin
func (g *Game) IsAdmin(robotID string) bool {
	g.mu.RLock()
	defer g.mu.RUnlock()

	for _, robot := range g.Robots {
		if robot.ID == robotID && robot.Role == RoleAdmin {
			return true
		}
	}

	return false
}

// GetState returns the current game state (thread-safe)
func (g *Game) GetState() GameState {
	g.mu.RLock()
	defer g.mu.RUnlock()
	return g.State
}

// LeaderboardEntry represents an entry in the leaderboard
type LeaderboardEntry struct {
	Robot    *Robot `json:"robot"`
	WinCount int    `json:"win_count"`
}
