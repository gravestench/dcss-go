package game

import (
	"fmt"

	"dcrawl-go/internal/ecs"
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
	dx, dy := sign(player.X-position.X), sign(player.Y-position.Y)
	for _, step := range [][2]int{{dx, 0}, {0, dy}} {
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

func sign(value int) int {
	if value < 0 {
		return -1
	}
	if value > 0 {
		return 1
	}
	return 0
}
