package game

import (
	"testing"
)

func TestNewGame(t *testing.T) {
	config := DefaultConfig()
	g := NewGame(config)

	if g.ID == "" {
		t.Error("Game ID should not be empty")
	}

	if g.WinningScore != config.WinningScore {
		t.Errorf("Expected winning score %d, got %d", config.WinningScore, g.WinningScore)
	}

	if g.State != StateSetup {
		t.Errorf("Expected state %s, got %s", StateSetup, g.State)
	}

	if len(g.Robots) != 0 {
		t.Errorf("Expected 0 robots, got %d", len(g.Robots))
	}
}

func TestJoinGame(t *testing.T) {
	g := NewGame(DefaultConfig())

	robot1 := NewRobot("Alice", RoleAdmin)
	err := g.Join(robot1)
	if err != nil {
		t.Errorf("Expected no error, got %v", err)
	}

	if len(g.Robots) != 1 {
		t.Errorf("Expected 1 robot, got %d", len(g.Robots))
	}

	robot2 := NewRobot("Bob", RoleGuest)
	err = g.Join(robot2)
	if err != nil {
		t.Errorf("Expected no error, got %v", err)
	}

	if len(g.Robots) != 2 {
		t.Errorf("Expected 2 robots, got %d", len(g.Robots))
	}
}

func TestJoinFullGame(t *testing.T) {
	config := &Config{
		WinningScore: 25,
		MinRobots:    2,
		MaxRobots:    2,
		Countdown:    3,
	}
	g := NewGame(config)

	g.Join(NewRobot("Alice", RoleAdmin))
	g.Join(NewRobot("Bob", RoleGuest))

	// Try to join a full game
	err := g.Join(NewRobot("Charlie", RoleGuest))
	if err != ErrGameFull {
		t.Errorf("Expected ErrGameFull, got %v", err)
	}
}

func TestJoinGameInProgress(t *testing.T) {
	g := NewGame(DefaultConfig())
	g.Join(NewRobot("Alice", RoleAdmin))
	g.StartCountdown()

	err := g.Join(NewRobot("Bob", RoleGuest))
	if err != ErrGameInProgress {
		t.Errorf("Expected ErrGameInProgress, got %v", err)
	}
}

func TestScorePoint(t *testing.T) {
	g := NewGame(DefaultConfig())
	robot := NewRobot("Alice", RoleAdmin)
	g.Join(robot)
	g.StartCountdown()
	g.Countdown = 0
	g.State = StatePlaying

	scored := g.ScorePoint(robot.ID)
	if !scored {
		t.Error("Expected to score a point")
	}

	if robot.Score != 1 {
		t.Errorf("Expected score 1, got %d", robot.Score)
	}
}

func TestWinningGame(t *testing.T) {
	config := &Config{
		WinningScore: 3,
		MinRobots:    2,
		MaxRobots:    10,
		Countdown:    3,
	}
	g := NewGame(config)
	robot := NewRobot("Alice", RoleAdmin)
	g.Join(robot)
	g.State = StatePlaying

	g.ScorePoint(robot.ID)
	g.ScorePoint(robot.ID)
	
	if g.State == StateFinished {
		t.Error("Game should not be finished yet")
	}

	g.ScorePoint(robot.ID)
	
	if g.State != StateFinished {
		t.Errorf("Game should be finished, state is %s", g.State)
	}

	winner := g.GetWinner()
	if winner.ID != robot.ID {
		t.Errorf("Expected winner to be %s, got %s", robot.ID, winner.ID)
	}
}

func TestCountdown(t *testing.T) {
	g := NewGame(DefaultConfig())
	g.Join(NewRobot("Alice", RoleAdmin))

	if g.State != StateSetup {
		t.Errorf("Expected state %s, got %s", StateSetup, g.State)
	}

	g.StartCountdown()
	if g.State != StateCountingDown {
		t.Errorf("Expected state %s, got %s", StateCountingDown, g.State)
	}

	initialCountdown := g.Countdown
	g.DecrementCountdown()
	
	if g.Countdown != initialCountdown-1 {
		t.Errorf("Expected countdown %d, got %d", initialCountdown-1, g.Countdown)
	}

	// Countdown to zero
	for g.Countdown > 0 {
		g.DecrementCountdown()
	}

	if g.State != StatePlaying {
		t.Errorf("Expected state %s, got %s", StatePlaying, g.State)
	}
}

func TestPlayAgain(t *testing.T) {
	config := &Config{
		WinningScore: 3,
		MinRobots:    2,
		MaxRobots:    10,
		Countdown:    3,
	}
	g := NewGame(config)
	robot1 := NewRobot("Alice", RoleAdmin)
	robot2 := NewRobot("Bob", RoleGuest)
	g.Join(robot1)
	g.Join(robot2)
	g.State = StatePlaying

	// Alice wins
	g.ScorePoint(robot1.ID)
	g.ScorePoint(robot1.ID)
	g.ScorePoint(robot1.ID)

	if g.State != StateFinished {
		t.Error("Game should be finished")
	}

	g.PlayAgain()

	if g.State != StateSetup {
		t.Errorf("Expected state %s, got %s", StateSetup, g.State)
	}

	if robot1.Score != 0 {
		t.Errorf("Expected robot1 score 0, got %d", robot1.Score)
	}

	if robot2.Score != 0 {
		t.Errorf("Expected robot2 score 0, got %d", robot2.Score)
	}

	if g.PreviousWins[robot1.ID] != 1 {
		t.Errorf("Expected 1 previous win for robot1, got %d", g.PreviousWins[robot1.ID])
	}
}

func TestIsAdmin(t *testing.T) {
	g := NewGame(DefaultConfig())
	admin := NewRobot("Admin", RoleAdmin)
	guest := NewRobot("Guest", RoleGuest)
	
	g.Join(admin)
	g.Join(guest)

	if !g.IsAdmin(admin.ID) {
		t.Error("Admin should be identified as admin")
	}

	if g.IsAdmin(guest.ID) {
		t.Error("Guest should not be identified as admin")
	}
}

func TestLeaderboard(t *testing.T) {
	config := &Config{
		WinningScore: 2,
		MinRobots:    2,
		MaxRobots:    10,
		Countdown:    3,
	}
	g := NewGame(config)
	robot1 := NewRobot("Alice", RoleAdmin)
	robot2 := NewRobot("Bob", RoleGuest)
	g.Join(robot1)
	g.Join(robot2)
	g.State = StatePlaying

	// Alice wins first round
	g.ScorePoint(robot1.ID)
	g.ScorePoint(robot1.ID)
	g.PlayAgain()

	// Bob wins second round
	g.State = StatePlaying
	g.ScorePoint(robot2.ID)
	g.ScorePoint(robot2.ID)

	leaderboard := g.GetLeaderboard()
	
	if len(leaderboard) != 2 {
		t.Errorf("Expected 2 entries in leaderboard, got %d", len(leaderboard))
	}

	// Both should have 1 win
	for _, entry := range leaderboard {
		if entry.WinCount != 1 {
			t.Errorf("Expected 1 win for %s, got %d", entry.Robot.Name, entry.WinCount)
		}
	}
}
