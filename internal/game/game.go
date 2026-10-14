package game

import (
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// Game owns one run. Other packages interact with it through commands and views.
type Game struct {
	world          *akara.World
	stores         ecs.Stores
	levels         map[int]*Level
	player         akara.Entity
	catalog        content.Catalog
	seed           uint64
	rng            *RNGStreams
	scheduler      TurnScheduler
	currentAut     Aut
	turn           TurnContext
	messages       []string
	visible        []bool
	visibleLevelID int
}

func (g *Game) Close() error {
	if g == nil || g.world == nil {
		return nil
	}
	return g.world.Close()
}
