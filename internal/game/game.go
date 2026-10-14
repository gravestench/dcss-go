package game

import (
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/modfs"
	"dcrawl-go/internal/script"
	"github.com/gravestench/akara"
)

// Game owns one run. Other packages interact with it through commands and views.
type Game struct {
	world   *akara.World
	stores  ecs.Stores
	levels  map[int]*Level
	player  akara.Entity
	catalog content.Catalog
	rules   modfs.Ruleset
	scripts *script.Runtime

	seed       uint64
	scenarioID string
	rng        *RNGStreams
	scheduler  TurnScheduler
	currentAut Aut

	turn TurnContext

	messages       []string
	visible        []bool
	visibleLevelID int
}

func (g *Game) Close() error {
	if g == nil || g.world == nil {
		return nil
	}

	if g.scripts != nil {
		g.scripts.Close()
	}

	return g.world.Close()
}
