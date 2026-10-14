package game

import "github.com/gravestench/akara"

// RouteStep finds the first step on a shortest eight-way path across this
// level's walkable terrain. A goal actor may occupy the destination for melee.
// The route is derived from current terrain and occupancy, never saved.
func (l *Level) RouteStep(
	x, y, targetX, targetY int,
	goalActor akara.Entity,
) (int, int, bool) {
	if !l.Walkable(x, y) || !l.Walkable(targetX, targetY) || x == targetX && y == targetY {
		return 0, 0, false
	}

	start, goal := point{
		x: x,
		y: y,
	}, point{
		x: targetX,
		y: targetY,
	}

	visited := make([]bool, l.width*len(l.terrain))
	parents := make([]point, len(visited))
	index := func(p point) int {
		return p.y*l.width + p.x
	}
	queue := []point{start}
	visited[index(start)] = true

	for head := 0; head < len(queue); head++ {
		current := queue[head]

		for _, step := range [][2]int{
			{-1, -1},
			{0, -1},
			{1, -1},
			{-1, 0},
			{1, 0},
			{-1, 1},
			{0, 1},
			{1, 1},
		} {
			next := point{
				x: current.x + step[0],
				y: current.y + step[1],
			}

			if !l.Walkable(next.x, next.y) || visited[index(next)] {
				continue
			}

			if occupant, occupied := l.ActorAt(next.x, next.y); occupied &&
				!(next == goal && occupant == goalActor) {
				continue
			}

			visited[index(next)] = true
			parents[index(next)] = current

			if next == goal {
				for parents[index(next)] != start {
					next = parents[index(next)]
				}

				return next.x - x, next.y - y, true
			}

			queue = append(queue, next)
		}
	}

	return 0, 0, false
}
