package game

import "github.com/google/uuid"

// RobotRole represents the role of a robot (guest or admin)
type RobotRole string

const (
	RoleGuest RobotRole = "guest"
	RoleAdmin RobotRole = "admin"
)

// Robot represents a player in the game
type Robot struct {
	ID    string     `json:"id"`
	Name  string     `json:"name"`
	Role  RobotRole  `json:"role"`
	Score int        `json:"score"`
}

// NewRobot creates a new robot with the given name and role
func NewRobot(name string, role RobotRole) *Robot {
	return &Robot{
		ID:    uuid.New().String(),
		Name:  name,
		Role:  role,
		Score: 0,
	}
}
