package game

import (
	"fmt"

	"dcrawl-go/internal/script"
	"dcrawl-go/internal/visibility"
	"github.com/gravestench/akara"
)

// scriptServices exposes engine Akara components through one Lua API.
// Game-specific state and semantic rules can then move into Lua schemas.
func (g *Game) scriptServices() (script.Services, error) {
	stores := g.stores
	bindings := []script.HostBinding{
		script.Host("core.position", stores.Positions),
		script.Host("core.actor", stores.Actors),
		script.Host("core.player_turn", stores.PlayerTurn),
		script.Host("core.monster_energy", stores.MonsterEnergy),
		script.Host("core.health", stores.Health),
		script.Host("core.magic", stores.Magic),
		script.Host("core.skills", stores.Skills),
		script.Host("core.skill_training", stores.SkillTraining),

		script.Host("core.player", stores.Players),
		script.Host("core.progression", stores.Progression),
		script.Host("core.attributes", stores.Attributes),
		script.Host("core.durations", stores.Durations),
		script.Host("core.poison", stores.Poison),
		script.Host("core.regeneration", stores.Regeneration),
		script.Host("core.combat", stores.Combat),
		script.Host("core.constricted", stores.Constricted),
		script.Host("core.equipment_delay", stores.Equipment),

		script.Host("core.ai", stores.AI),
		script.Host("core.follower", stores.Followers),
		script.Host("core.item", stores.Items),
		script.Host("core.corpse", stores.Corpses),
		script.Host("core.carried_by", stores.CarriedBy),
		script.Host("core.equipped", stores.Equipped),
		script.Host("core.intent", stores.Intents),
	}

	components, err := script.BindHosts(bindings)

	if err != nil {
		return script.Services{}, err
	}

	return script.Services{
		ActiveActor: func() akara.Entity {
			return g.turn.Actor
		},
		PlayerEntity: func() akara.Entity {
			return g.player
		},
		CurrentAut: func() int64 {
			return int64(g.currentAut)
		},
		Random:     g.rng.Intn,
		RandomWord: g.rng.next,
		Emit: func(kind, message string) {
			g.turn.Events = append(g.turn.Events, Event{
				Kind: kind,
				Text: message,
			})
		},
		Grid:           scriptGrid{levels: g.levels},
		HostComponents: components,
	}, nil
}

type scriptGrid struct {
	levels map[int]*Level
}

func (grid scriptGrid) Cell(levelID, x, y int) (byte, bool) {
	level := grid.levels[levelID]

	if level == nil || !level.inBounds(x, y) {
		return 0, false
	}

	return level.terrain[y][x], true
}

func (grid scriptGrid) Walkable(levelID, x, y int) bool {
	level := grid.levels[levelID]

	return level != nil && level.Walkable(x, y)
}

func (grid scriptGrid) ActorAt(levelID, x, y int) (akara.Entity, bool) {
	level := grid.levels[levelID]

	if level == nil {
		return 0, false
	}

	return level.ActorAt(x, y)
}

func (grid scriptGrid) StairAt(levelID, x, y int) (script.Stair, bool) {
	level := grid.levels[levelID]

	if level == nil {
		return script.Stair{}, false
	}

	link, found := level.StairAt(x, y)

	return script.Stair{
		ToLevelID:   link.ToLevelID,
		ToX:         link.ToX,
		ToY:         link.ToY,
		Unavailable: link.Unavailable,
	}, found
}

func (grid scriptGrid) Visible(
	levelID, fromX, fromY, radius, targetX, targetY int,
) (bool, error) {
	level := grid.levels[levelID]

	if level == nil || !level.inBounds(targetX, targetY) {
		return false, nil
	}

	visible, err := visibility.Compute(level.terrain, fromX, fromY, radius)

	if err != nil {
		return false, err
	}

	return visible[targetY*level.width+targetX], nil
}

func (grid scriptGrid) RouteStep(
	levelID, fromX, fromY, toX, toY int,
	goal akara.Entity,
) (int, int, bool) {
	level := grid.levels[levelID]

	if level == nil {
		return 0, 0, false
	}

	return level.RouteStep(fromX, fromY, toX, toY, goal)
}

func (grid scriptGrid) ProjectileClear(
	levelID, fromX, fromY, toX, toY int,
) bool {
	level := grid.levels[levelID]

	return level != nil && level.ClearProjectilePath(fromX, fromY, toX, toY)
}

func (grid scriptGrid) SetCell(levelID, x, y int, glyph byte) error {
	level := grid.levels[levelID]

	if level == nil {
		return fmt.Errorf("missing level %d", levelID)
	}

	return level.SetCell(x, y, glyph)
}

func (grid scriptGrid) MoveActor(entity akara.Entity, levelID, x, y int) error {
	positioned := grid.levels[levelID]

	if positioned == nil {
		return fmt.Errorf("missing level %d", levelID)
	}

	position, found := positioned.positions.Get(entity)

	if !found {
		return fmt.Errorf("actor %d has no position", entity)
	}

	if position.LevelID == levelID {
		return positioned.MoveActor(entity, x, y)
	}

	from := grid.levels[position.LevelID]

	if from == nil {
		return fmt.Errorf("actor %d has missing origin level %d", entity, position.LevelID)
	}

	oldX, oldY := position.X, position.Y

	if err := from.RemoveActor(entity); err != nil {
		return err
	}

	if err := positioned.PlaceActor(entity, x, y); err != nil {
		_ = from.PlaceActor(entity, oldX, oldY)

		return err
	}

	return nil
}

func (grid scriptGrid) PlaceActor(entity akara.Entity, levelID, x, y int) error {
	level := grid.levels[levelID]

	if level == nil {
		return fmt.Errorf("missing level %d", levelID)
	}

	return level.PlaceActor(entity, x, y)
}

func (grid scriptGrid) RemoveActor(entity akara.Entity, levelID int) error {
	level := grid.levels[levelID]

	if level == nil {
		return fmt.Errorf("missing level %d", levelID)
	}

	return level.RemoveActor(entity)
}
