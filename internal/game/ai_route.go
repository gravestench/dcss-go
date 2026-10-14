package game

import (
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

func (s *monsterDecisionSystem) followMonsterTarget(
	actor akara.Entity,
	ai ecs.MonsterAI,
	level *Level,
	position ecs.Position,
	player ecs.Position,
	visible []bool,
) ecs.Intent {
	goalActor := s.goalActorForTarget(actor, ai, position, player)

	if visible[ai.TargetY*level.width+ai.TargetX] {
		intent, found := directMonsterIntent(ai, level, position, player)

		if found {
			return intent
		}
	}

	if intent, found := s.routeMonsterIntent(ai, level, position, player, goalActor); found {
		return intent
	}

	return ecs.Intent{Kind: ecs.IntentWait}
}

func (s *monsterDecisionSystem) goalActorForTarget(
	actor akara.Entity,
	ai ecs.MonsterAI,
	position ecs.Position,
	player ecs.Position,
) akara.Entity {
	if ai.TargetX == player.X && ai.TargetY == player.Y {
		return s.player
	}

	follower, found := s.followers.Get(actor)

	if !found {
		return 0
	}

	leader, alive := s.positions.Get(follower.Leader)

	if alive &&
		leader.LevelID == position.LevelID &&
		ai.TargetX == leader.X && ai.TargetY == leader.Y {
		return follower.Leader
	}

	return 0
}

func directMonsterIntent(
	ai ecs.MonsterAI,
	level *Level,
	position ecs.Position,
	player ecs.Position,
) (ecs.Intent, bool) {
	dx := sign(ai.TargetX - position.X)
	dy := sign(ai.TargetY - position.Y)

	// DCSS aims toward the target along both axes first. Cardinal steps remain
	// useful when a diagonal is blocked by terrain or another actor.
	for _, step := range [][2]int{
		{dx, dy},
		{dx, 0},
		{0, dy},
	} {
		if step == [2]int{} {
			continue
		}

		x, y := position.X+step[0], position.Y+step[1]

		if x == player.X && y == player.Y {
			return ecs.Intent{
				Kind: ecs.IntentMelee,
				DX:   step[0],
				DY:   step[1],
			}, true
		}

		if level.Walkable(x, y) {
			if _, occupied := level.ActorAt(x, y); !occupied {
				return ecs.Intent{
					Kind: ecs.IntentMove,
					DX:   step[0],
					DY:   step[1],
				}, true
			}
		}
	}

	return ecs.Intent{}, false
}

func (s *monsterDecisionSystem) routeMonsterIntent(
	ai ecs.MonsterAI,
	level *Level,
	position ecs.Position,
	player ecs.Position,
	goalActor akara.Entity,
) (ecs.Intent, bool) {
	dx, dy, found := level.RouteStep(
		position.X,
		position.Y,
		ai.TargetX,
		ai.TargetY,
		goalActor,
	)

	if !found {
		return ecs.Intent{}, false
	}

	nextX := position.X + dx
	nextY := position.Y + dy

	// RouteStep may enter a goal actor's tile for melee. A band leader is
	// a navigation goal, never a valid attack target for its followers.
	if goalActor != 0 &&
		goalActor != s.player &&
		nextX == ai.TargetX && nextY == ai.TargetY {
		return ecs.Intent{Kind: ecs.IntentWait}, true
	}

	return monsterStepIntent(nextX, nextY, player.X, player.Y, dx, dy), true
}

func monsterStepIntent(nextX, nextY, playerX, playerY, dx, dy int) ecs.Intent {
	if nextX == playerX && nextY == playerY {
		return ecs.Intent{
			Kind: ecs.IntentMelee,
			DX:   dx,
			DY:   dy,
		}
	}

	return ecs.Intent{
		Kind: ecs.IntentMove,
		DX:   dx,
		DY:   dy,
	}
}

func sign(value int) int {
	if value < 0 {
		return -1
	}

	if value > 0 {
		return 1
	}

	return 0
}
