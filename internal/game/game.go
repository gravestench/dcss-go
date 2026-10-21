package game

import (
	"crawl/internal/ecs"
	"crawl/internal/modfs"
	"crawl/internal/save"
	"crawl/internal/script"
	"github.com/gravestench/akara"
)

// Game owns one run. Other packages interact with it through commands and views.
type Game struct {
	world   *akara.World
	stores  ecs.Stores
	levels  map[int]*Level
	player  akara.Entity
	rules   modfs.Ruleset
	scripts *script.Runtime

	seed           uint64
	scenarioID     string
	rng            *RNGStreams
	scheduler      TurnScheduler
	currentAut     Aut
	entityCursor   uint64
	branchSchedule *save.BranchScheduleRecord
	templePlan     *save.TemplePlanRecord
	panState       *save.PanStateRecord
	hellState      *save.HellStateRecord

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
