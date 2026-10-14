package game

import (
	"fmt"
	"time"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// prepareDoorCommand follows movement.cc:388-556. The source's easy_door
// default chooses a direction only when exactly one adjacent cell qualifies.
func (g *Game) prepareDoorCommand(
	command Command,
	position ecs.Position,
	level *Level,
) (preparedCommand, error) {
	glyph := byte('+')
	intentKind := ecs.IntentOpenDoor
	verb := "open"

	if command.Kind == CommandCloseDoor {
		glyph = '\''
		intentKind = ecs.IntentCloseDoor
		verb = "close"
	}

	dx, dy := command.DX, command.DY

	if dx == 0 && dy == 0 {
		choices := adjacentDoorCells(level, position, glyph)

		switch len(choices) {
		case 0:
			return freeCommand(g.noTime("There's nothing to " + verb + " nearby.")), nil

		case 1:
			dx = choices[0].x - position.X
			dy = choices[0].y - position.Y

		default:
			return freeCommand(g.noTime("Choose a direction to " + verb + ".")), nil
		}
	}

	if dx < -1 || dx > 1 || dy < -1 || dy > 1 ||
		(dx == 0 && dy == 0) {
		return freeCommand(g.noTime("Choose an adjacent direction.")), nil
	}

	target := point{
		x: position.X + dx,
		y: position.Y + dy,
	}

	if !level.inBounds(target.x, target.y) || level.terrain[target.y][target.x] != glyph {
		return freeCommand(g.noTime("There isn't a door to " + verb + " there.")), nil
	}

	intent := ecs.Intent{
		Kind: intentKind,
		DX:   dx,
		DY:   dy,
	}

	if command.Kind == CommandCloseDoor {
		group, err := level.doorGroup(target.x, target.y, glyph)

		if err != nil {
			return preparedCommand{}, err
		}

		message, spendsTime := g.doorCloseObstruction(level, group)

		if spendsTime {
			return spendingCommand(intent, 10), nil
		}

		if message != "" {
			return freeCommand(g.noTime(message)), nil
		}
	}

	return spendingCommand(intent, 10), nil
}

func adjacentDoorCells(level *Level, position ecs.Position, glyph byte) []point {
	var choices []point

	for dy := -1; dy <= 1; dy++ {
		for dx := -1; dx <= 1; dx++ {
			if dx == 0 && dy == 0 {
				continue
			}

			x := position.X + dx
			y := position.Y + dy

			if level.inBounds(x, y) && level.terrain[y][x] == glyph {
				choices = append(choices, point{
					x: x,
					y: y,
				})
			}
		}
	}

	return choices
}

// doorCloseObstruction follows player.cc:8036-8068. The source checks each
// door cell for a monster, jammed item, then the player before moving on.
func (g *Game) doorCloseObstruction(level *Level, group []point) (string, bool) {
	excluded := doorCellSet(group)

	for _, cell := range group {
		actor, occupied := level.ActorAt(cell.x, cell.y)

		if occupied && actor != g.player {
			visible := g.visibleLevelID == level.ID &&
				g.visible[cell.y*level.width+cell.x]

			if visible {
				return "There's a creature in the doorway!", false
			}

			return "", true
		}

		if len(g.floorItemsAt(level.ID, cell)) > 0 &&
			len(doorPushTargets(level, cell, excluded)) == 0 {
			return "There's something jamming the doorway.", false
		}

		if occupied && actor == g.player {
			return "There's a thick-headed creature in the doorway!", false
		}
	}

	return "", false
}

func (g *Game) doorGroupJammed(level *Level, group []point) bool {
	excluded := doorCellSet(group)

	for _, cell := range group {
		if len(g.floorItemsAt(level.ID, cell)) == 0 {
			continue
		}

		if len(doorPushTargets(level, cell, excluded)) == 0 {
			return true
		}
	}

	return false
}

func doorCellSet(cells []point) map[point]bool {
	set := make(map[point]bool, len(cells))

	for _, cell := range cells {
		set[cell] = true
	}

	return set
}

// doorPushTargets mirrors terrain.cc:2251-2313 for the current floor types.
func doorPushTargets(level *Level, from point, excluded map[point]bool) []point {
	var targets []point

	for dy := -1; dy <= 1; dy++ {
		for dx := -1; dx <= 1; dx++ {
			if dx == 0 && dy == 0 {
				continue
			}

			cell := point{
				x: from.x + dx,
				y: from.y + dy,
			}

			if !excluded[cell] && level.Walkable(cell.x, cell.y) {
				targets = append(targets, cell)
			}
		}
	}

	return targets
}

func (g *Game) floorItemsAt(levelID int, cell point) []akara.Entity {
	var items []akara.Entity

	for _, entity := range g.stores.Items.Entities() {
		position, found := g.stores.Positions.Get(entity)

		if found && position.LevelID == levelID &&
			position.X == cell.x && position.Y == cell.y &&
			!g.stores.CarriedBy.Has(entity) {
			items = append(items, entity)
		}
	}

	return items
}

// doorSystem changes terrain and item positions during the ordered turn.
// Position updates here change existing components, not entity structure.
type doorSystem struct {
	game    *Game
	intents *akara.Store[ecs.Intent]
	turn    *TurnContext
}

func (s *doorSystem) Update(_ *akara.World, _ time.Duration) error {
	intent, found := s.intents.Get(s.turn.Actor)

	if !found || (intent.Kind != ecs.IntentOpenDoor &&
		intent.Kind != ecs.IntentCloseDoor) {
		return nil
	}

	position, found := s.game.stores.Positions.Get(s.turn.Actor)

	if !found {
		return fmt.Errorf("door actor %d has no position", s.turn.Actor)
	}

	level := s.game.levels[position.LevelID]
	x := position.X + intent.DX
	y := position.Y + intent.DY

	message := "You open the door."

	if intent.Kind == ecs.IntentOpenDoor {
		if _, err := level.OpenDoor(x, y); err != nil {
			return err
		}
	} else {
		closed, moved, err := s.closeDoor(level, x, y)

		if err != nil {
			return err
		}

		if !closed {
			message = "Something is blocking the doorway!"
		} else if moved {
			message = "You close the door, pushing everything out of the way."
		} else {
			message = "You close the door."
		}
	}

	s.turn.Events = append(s.turn.Events, Event{
		Kind: "door",
		Text: message,
	})

	return nil
}

func (s *doorSystem) closeDoor(level *Level, x, y int) (bool, bool, error) {
	group, err := level.doorGroup(x, y, '\'')

	if err != nil {
		return false, false, err
	}

	for _, cell := range group {
		if _, occupied := level.ActorAt(cell.x, cell.y); occupied {
			return false, false, nil
		}
	}

	if s.game.doorGroupJammed(level, group) {
		return false, false, fmt.Errorf("door became jammed after command preparation")
	}

	excluded := doorCellSet(group)
	moved := false

	for _, cell := range group {
		targets := doorPushTargets(level, cell, excluded)

		for _, entity := range s.game.floorItemsAt(level.ID, cell) {
			choice := 0

			if len(targets) > 1 {
				choice, err = s.game.rng.Intn("door", len(targets))

				if err != nil {
					return false, false, err
				}
			}

			position, _ := s.game.stores.Positions.Get(entity)
			position.X = targets[choice].x
			position.Y = targets[choice].y
			moved = true
		}
	}

	_, err = level.CloseDoor(x, y)

	return true, moved, err
}
