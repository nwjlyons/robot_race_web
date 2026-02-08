package game

// Config holds game configuration
type Config struct {
	WinningScore int `json:"winning_score"`
	MinRobots    int `json:"min_robots"`
	MaxRobots    int `json:"max_robots"`
	Countdown    int `json:"countdown"`
}

// DefaultConfig returns the default game configuration
func DefaultConfig() *Config {
	return &Config{
		WinningScore: 25,
		MinRobots:    2,
		MaxRobots:    10,
		Countdown:    3,
	}
}
