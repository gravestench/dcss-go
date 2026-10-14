package character

// Skill is the stored level and training progress for one player skill.
type Skill struct {
	ID     string `json:"id"`
	Level  int    `json:"level"`
	Points int    `json:"points"`
}
