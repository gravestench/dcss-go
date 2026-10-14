package game

import "dcrawl-go/internal/ecs"

func adjacentActors(a, b ecs.Position) bool {
	if a.LevelID != b.LevelID {
		return false
	}

	dx := a.X - b.X
	dy := a.Y - b.Y

	return dx >= -1 &&
		dx <= 1 &&
		dy >= -1 &&
		dy <= 1 &&
		(dx != 0 || dy != 0)
}
