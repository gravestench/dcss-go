package game

import (
	"fmt"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/visibility"
	"github.com/gravestench/akara"
)

func (g *Game) chooseMonsterIntent(actor akara.Entity) (ecs.Intent, error) {
	position, found := g.stores.Positions.Get(actor)
	if !found {
		return ecs.Intent{}, fmt.Errorf("monster %d has no position", actor)
	}
	player, found := g.stores.Positions.Get(g.player)
	if !found {
		return ecs.Intent{}, fmt.Errorf("player %d has no position", g.player)
	}
	if position.LevelID != player.LevelID {
		return ecs.Intent{Kind: ecs.IntentWait}, nil
	}
	ai, found := g.stores.AI.Get(actor)
	if !found {
		return ecs.Intent{}, fmt.Errorf("monster %d has no AI", actor)
	}
	level := g.levels[position.LevelID]
	if level == nil {
		return ecs.Intent{}, fmt.Errorf("monster level %d is missing", position.LevelID)
	}
	visible, err := visibility.Compute(level.terrain, position.X, position.Y, 7)
	if err != nil {
		return ecs.Intent{}, err
	}
	if visible[player.Y*level.width+player.X] {
		memoryRoll, err := g.rng.Intn("ai", 301)
		if err != nil {
			return ecs.Intent{}, err
		}
		ai.Behavior, ai.TargetX, ai.TargetY = "seek", player.X, player.Y
		ai.MemoryUntilAut = int64(g.currentAut) + int64(250+memoryRoll)
	} else if ai.Behavior == "seek" {
		if ai.MemoryUntilAut == 0 {
			// Pre-memory version-6 saves carried a target but no deadline.
			ai.MemoryUntilAut = int64(g.currentAut) + 250
		}
		if int64(g.currentAut) >= ai.MemoryUntilAut {
			ai.Behavior, ai.TargetX, ai.TargetY, ai.MemoryUntilAut = "wander", 0, 0, 0
		}
	} else if ai.Behavior != "seek" && ai.Behavior != "wander" {
		// Old version-6 saves used "chase" without a remembered target.
		ai.Behavior, ai.TargetX, ai.TargetY = "wander", 0, 0
	}
	if position.X == ai.TargetX && position.Y == ai.TargetY {
		ai.Behavior, ai.TargetX, ai.TargetY, ai.MemoryUntilAut = "wander", 0, 0, 0
	}
	if ai.Behavior == "wander" {
		retarget := ai.TargetX == 0 && ai.TargetY == 0
		if !retarget {
			roll, err := g.rng.Intn("ai", 20)
			if err != nil {
				return ecs.Intent{}, err
			}
			retarget = roll == 0
		}
		if retarget {
			if err := g.chooseWanderTarget(ai, level, position.X, position.Y); err != nil {
				return ecs.Intent{}, err
			}
		}
		if ai.TargetX == 0 && ai.TargetY == 0 {
			return ecs.Intent{Kind: ecs.IntentWait}, nil
		}
	}
	dx, dy := sign(ai.TargetX-position.X), sign(ai.TargetY-position.Y)
	// DCSS aims toward the target along both axes first. Cardinal steps remain
	// useful when a diagonal is blocked by terrain or another actor.
	for _, step := range [][2]int{{dx, dy}, {dx, 0}, {0, dy}} {
		if step == [2]int{} {
			continue
		}
		x, y := position.X+step[0], position.Y+step[1]
		if x == player.X && y == player.Y {
			return ecs.Intent{Kind: ecs.IntentMelee, DX: step[0], DY: step[1]}, nil
		}
		if g.levels[position.LevelID].Walkable(x, y) {
			if _, occupied := g.levels[position.LevelID].ActorAt(x, y); !occupied {
				return ecs.Intent{Kind: ecs.IntentMove, DX: step[0], DY: step[1]}, nil
			}
		}
	}
	return ecs.Intent{Kind: ecs.IntentWait}, nil
}

// chooseWanderTarget follows Crawl's 150 attempts with offsets in [-6, 6].
// A failed search leaves the animal waiting until its next decision.
func (g *Game) chooseWanderTarget(ai *ecs.MonsterAI, level *Level, x, y int) error {
	ai.TargetX, ai.TargetY = 0, 0
	for attempt := 0; attempt < 150; attempt++ {
		dx, err := g.rng.Intn("ai", 13)
		if err != nil {
			return err
		}
		dy, err := g.rng.Intn("ai", 13)
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
