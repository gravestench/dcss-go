package game

import (
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

func (s *monsterDecisionSystem) updateWanderTarget(
	actor akara.Entity,
	ai *ecs.MonsterAI,
	level *Level,
	position ecs.Position,
	visible []bool,
) error {
	retarget := ai.TargetX == 0 && ai.TargetY == 0
	leaderPosition, inBand := s.bandLeaderPosition(actor, position.LevelID)

	if inBand {
		distance := chebyshevDistance(
			position.X,
			position.Y,
			leaderPosition.X,
			leaderPosition.Y,
		)
		tooFar := distance >= 6
		leaderTargetWithinRange := ai.TargetX == leaderPosition.X &&
			ai.TargetY == leaderPosition.Y && distance < 6

		if tooFar || leaderTargetWithinRange {
			retarget = true
		}
	}

	if !retarget {
		roll, err := s.rng.Intn("ai", 20)

		if err != nil {
			return err
		}

		retarget = roll == 0
	}

	if retarget {
		return s.chooseWanderTarget(actor, ai, level, position.X, position.Y, visible)
	}

	return nil
}

// chooseWanderTarget follows Crawl's 150 attempts with offsets in [-6, 6].
// A failed search leaves the animal waiting until its next decision.
func (s *monsterDecisionSystem) chooseWanderTarget(
	actor akara.Entity,
	ai *ecs.MonsterAI,
	level *Level,
	x, y int,
	visible []bool,
) error {
	ai.TargetX = 0
	ai.TargetY = 0

	if leader, found := s.bandLeaderPosition(actor, level.ID); found {
		return s.chooseBandWanderTarget(ai, level, x, y, leader, visible)
	}

	for attempt := 0; attempt < 150; attempt++ {
		dx, err := s.rng.Intn("ai", 13)

		if err != nil {
			return err
		}

		dy, err := s.rng.Intn("ai", 13)

		if err != nil {
			return err
		}

		targetX, targetY := x+dx-6, y+dy-6

		if (targetX != x || targetY != y) && level.Walkable(targetX, targetY) {
			ai.TargetX = targetX
			ai.TargetY = targetY

			return nil
		}
	}

	return nil
}

func (s *monsterDecisionSystem) bandLeaderPosition(
	actor akara.Entity,
	levelID int,
) (ecs.Position, bool) {
	follower, found := s.followers.Get(actor)

	if !found {
		return ecs.Position{}, false
	}

	leader, alive := s.positions.Get(follower.Leader)

	if !alive || leader.LevelID != levelID {
		return ecs.Position{}, false
	}

	return *leader, true
}

// Follower wandering favors cells within the source six-cell comfort range.
// A separated follower heads toward the leader until that range is reachable.
func (s *monsterDecisionSystem) chooseBandWanderTarget(
	ai *ecs.MonsterAI,
	level *Level,
	x, y int,
	leader ecs.Position,
	visible []bool,
) error {
	if chebyshevDistance(x, y, leader.X, leader.Y) > 13 {
		ai.TargetX = leader.X
		ai.TargetY = leader.Y

		return nil
	}

	candidates := make([]point, 0)

	for candidateY := 0; candidateY < len(level.terrain); candidateY++ {
		for candidateX := 0; candidateX < level.width; candidateX++ {
			if !visible[candidateY*level.width+candidateX] ||
				!level.Walkable(candidateX, candidateY) ||
				chebyshevDistance(candidateX, candidateY, leader.X, leader.Y) >= 6 ||
				(candidateX == x && candidateY == y) {
				continue
			}

			if _, occupied := level.ActorAt(candidateX, candidateY); occupied {
				continue
			}

			candidates = append(candidates, point{
				x: candidateX,
				y: candidateY,
			})
		}
	}

	if len(candidates) == 0 {
		ai.TargetX = leader.X
		ai.TargetY = leader.Y

		return nil
	}

	choice, err := s.rng.Intn("ai", len(candidates))

	if err != nil {
		return err
	}

	ai.TargetX = candidates[choice].x
	ai.TargetY = candidates[choice].y

	return nil
}

func chebyshevDistance(x1, y1, x2, y2 int) int {
	dx := x1 - x2

	if dx < 0 {
		dx = -dx
	}

	dy := y1 - y2

	if dy < 0 {
		dy = -dy
	}

	return max(dx, dy)
}
