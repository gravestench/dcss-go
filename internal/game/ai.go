package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/visibility"
	"github.com/gravestench/akara"
)

// monsterDecisionSystem turns an active monster's saved AI state into its
// transient action intent before movement and combat systems run.
type monsterDecisionSystem struct {
	player    akara.Entity
	positions *akara.Store[ecs.Position]
	ai        *akara.Store[ecs.MonsterAI]
	intents   *akara.Store[ecs.Intent]
	levels    map[int]*Level
	rng       *RNGStreams
	clock     *Aut
	turn      *TurnContext
}

func newMonsterDecisionSystem(g *Game) *monsterDecisionSystem {
	return &monsterDecisionSystem{
		player:    g.player,
		positions: g.stores.Positions,
		ai:        g.stores.AI,
		intents:   g.stores.Intents,
		levels:    g.levels,
		rng:       g.rng,
		clock:     &g.currentAut,
		turn:      &g.turn,
	}
}

func (s *monsterDecisionSystem) Update(_ *akara.World, _ time.Duration) error {
	actor := s.turn.Actor
	if !s.ai.Has(actor) {
		return nil
	}

	if s.intents.Has(actor) {
		return fmt.Errorf("monster %d already has an intent", actor)
	}

	intent, err := s.chooseIntent(actor)
	if err != nil {
		return err
	}

	_, err = s.intents.Set(actor, intent)
	return err
}

func (s *monsterDecisionSystem) chooseIntent(actor akara.Entity) (ecs.Intent, error) {
	position, found := s.positions.Get(actor)
	if !found {
		return ecs.Intent{}, fmt.Errorf("monster %d has no position", actor)
	}

	player, found := s.positions.Get(s.player)
	if !found {
		return ecs.Intent{}, fmt.Errorf("player %d has no position", s.player)
	}

	if position.LevelID != player.LevelID {
		return ecs.Intent{Kind: ecs.IntentWait}, nil
	}

	ai, found := s.ai.Get(actor)
	if !found {
		return ecs.Intent{}, fmt.Errorf("monster %d has no AI", actor)
	}

	level := s.levels[position.LevelID]
	if level == nil {
		return ecs.Intent{}, fmt.Errorf("monster level %d is missing", position.LevelID)
	}

	visible, err := visibility.Compute(level.terrain, position.X, position.Y, 7)
	if err != nil {
		return ecs.Intent{}, err
	}

	if visible[player.Y*level.width+player.X] {
		memoryRoll, err := s.rng.Intn("ai", 301)
		if err != nil {
			return ecs.Intent{}, err
		}

		ai.Behavior, ai.TargetX, ai.TargetY = "seek", player.X, player.Y
		ai.MemoryUntilAut = int64(*s.clock) + int64(250+memoryRoll)
	} else if ai.Behavior == "seek" {
		if ai.MemoryUntilAut == 0 {
			// Earlier AI records carried a target but no deadline.
			ai.MemoryUntilAut = int64(*s.clock) + 250
		}

		if int64(*s.clock) >= ai.MemoryUntilAut {
			ai.Behavior, ai.TargetX, ai.TargetY, ai.MemoryUntilAut = "wander", 0, 0, 0
		}
	} else if ai.Behavior != "seek" && ai.Behavior != "wander" {
		// Earlier AI records used "chase" without a remembered target.
		ai.Behavior, ai.TargetX, ai.TargetY = "wander", 0, 0
	}

	if position.X == ai.TargetX && position.Y == ai.TargetY {
		ai.Behavior, ai.TargetX, ai.TargetY, ai.MemoryUntilAut = "wander", 0, 0, 0
	}

	if ai.Behavior == "wander" {
		retarget := ai.TargetX == 0 && ai.TargetY == 0
		if !retarget {
			roll, err := s.rng.Intn("ai", 20)
			if err != nil {
				return ecs.Intent{}, err
			}

			retarget = roll == 0
		}

		if retarget {
			if err := s.chooseWanderTarget(ai, level, position.X, position.Y); err != nil {
				return ecs.Intent{}, err
			}
		}

		if ai.TargetX == 0 && ai.TargetY == 0 {
			return ecs.Intent{Kind: ecs.IntentWait}, nil
		}
	}

	dx, dy := sign(ai.TargetX-position.X), sign(ai.TargetY-position.Y)
	goalActor := akara.Entity(0)
	if ai.TargetX == player.X && ai.TargetY == player.Y {
		goalActor = s.player
	}

	if !visible[ai.TargetY*level.width+ai.TargetX] {
		pathDX, pathDY, found := level.RouteStep(position.X, position.Y, ai.TargetX, ai.TargetY, goalActor)
		if !found {
			return ecs.Intent{Kind: ecs.IntentWait}, nil
		}

		return monsterStepIntent(position.X+pathDX, position.Y+pathDY, player.X, player.Y, pathDX, pathDY), nil
	}
	// DCSS aims toward the target along both axes first. Cardinal steps remain
	// useful when a diagonal is blocked by terrain or another actor.
	for _, step := range [][2]int{{dx, dy}, {dx, 0}, {0, dy}} {
		if step == [2]int{} {
			continue
		}

		x, y := position.X+step[0], position.Y+step[1]
		if x == player.X && y == player.Y {
			return ecs.Intent{
				Kind: ecs.IntentMelee,
				DX:   step[0],
				DY:   step[1],
			}, nil
		}

		if level.Walkable(x, y) {
			if _, occupied := level.ActorAt(x, y); !occupied {
				return ecs.Intent{
					Kind: ecs.IntentMove,
					DX:   step[0],
					DY:   step[1],
				}, nil
			}
		}
	}

	if pathDX, pathDY, found := level.RouteStep(position.X, position.Y, ai.TargetX, ai.TargetY, goalActor); found {
		return monsterStepIntent(position.X+pathDX, position.Y+pathDY, player.X, player.Y, pathDX, pathDY), nil
	}

	return ecs.Intent{Kind: ecs.IntentWait}, nil
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

// chooseWanderTarget follows Crawl's 150 attempts with offsets in [-6, 6].
// A failed search leaves the animal waiting until its next decision.
func (s *monsterDecisionSystem) chooseWanderTarget(ai *ecs.MonsterAI, level *Level, x, y int) error {
	ai.TargetX, ai.TargetY = 0, 0
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
			ai.TargetX, ai.TargetY = targetX, targetY
			return nil
		}
	}

	return nil
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
