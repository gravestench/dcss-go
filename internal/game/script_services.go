package game

import (
	"fmt"
	"slices"

	"crawl/internal/ecs"
	"crawl/internal/script"
	"crawl/internal/terrain"
	"crawl/internal/vault"
	"crawl/internal/visibility"
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
		script.Host("core.reserved_by", stores.ReservedBy),
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

		EntityCreated: func(entity akara.Entity) {
			g.noteEntity(entity)
		},

		CurrentAut: func() int64 {
			return int64(g.currentAut)
		},

		Random:         g.rng.Intn,
		RandomWord:     g.rng.next,
		RandomSnapshot: g.rng.States,
		RestoreRandom:  g.rng.RestoreStates,

		SessionStates: map[string]script.SessionStateHost{
			abyssSessionStateName: g.abyssSessionStateHost(),
		},

		Emit: func(kind, message string) {
			g.turn.Events = append(g.turn.Events, Event{
				Kind: kind,
				Text: message,
			})
		},

		Grid: scriptGrid{
			levels: g.levels,
			opaque: g.opaqueClouds,
		},

		HostComponents: components,
	}, nil
}

type scriptGrid struct {
	levels map[int]*Level
	opaque func(levelID int) map[point]bool
}

// Only visited levels live in this map. A Lua off-floor effect must never
// create a new level merely to inspect possible item cells.
func (grid scriptGrid) LevelIDs() []int {
	ids := make([]int, 0, len(grid.levels))

	for id := range grid.levels {
		ids = append(ids, id)
	}

	slices.Sort(ids)

	return ids
}

func (grid scriptGrid) Size(levelID int) (int, int, bool) {
	level := grid.levels[levelID]

	if level == nil {
		return 0, 0, false
	}

	return level.width, len(level.terrain), true
}

func (grid scriptGrid) Branch(levelID int) (string, bool) {
	level := grid.levels[levelID]

	if level == nil || level.BranchID == "" {
		return "", false
	}

	return level.BranchID, true
}

// The level stores its own local depth; it is not inferred from its ID.
func (grid scriptGrid) Depth(levelID int) (int, bool) {
	level := grid.levels[levelID]

	if level == nil || level.LocalDepth < 1 {
		return 0, false
	}

	return level.LocalDepth, true
}

func (grid scriptGrid) Cell(levelID, x, y int) (terrain.ID, bool) {
	level := grid.levels[levelID]

	if level == nil || !level.inBounds(x, y) {
		return terrain.Unseen, false
	}

	return level.terrain[y][x], true
}

// Keep the level's stored record order while copying typed arguments into a
// generic view. Go exposes placement facts, never god-specific decisions.
func (grid scriptGrid) RecordsAt(levelID, x, y int) []script.SpatialRecord {
	level := grid.levels[levelID]

	if level == nil || !level.inBounds(x, y) {
		return nil
	}

	result := []script.SpatialRecord{}

	for _, record := range level.vaultRecords {
		if record.Overridden {
			continue
		}

		if record.X != x || record.Y != y {
			continue
		}

		result = append(result, script.SpatialRecord{
			Kind:       string(record.Kind),
			SourceID:   record.SourceID,
			Identity:   record.Identity,
			X:          record.X,
			Y:          record.Y,
			Pending:    record.Pending,
			Overridden: record.Overridden,
			Arguments:  vaultRecordArguments(record),
		})
	}

	return result
}

// The grid bridge only matches a saved record and replaces one typed
// string field. Lua decides what that field means to game rules.
func (grid scriptGrid) ReplaceRecordString(
	levelID, x, y int,
	sourceID, kind, identity, key, expected, replacement string,
) error {
	level := grid.levels[levelID]

	if level == nil {
		return fmt.Errorf("missing level %d", levelID)
	}

	return level.ReplaceVaultRecordString(
		x, y, sourceID, vault.Kind(kind), identity,
		key, expected, replacement)
}

func (grid scriptGrid) MarkerProperty(levelID, x, y int, key string) (string, bool) {
	level := grid.levels[levelID]

	if level == nil || !level.inBounds(x, y) {
		return "", false
	}

	for _, record := range level.vaultRecords {
		if record.Kind != vault.KindMarker ||
			record.X != x ||
			record.Y != y {
			continue
		}

		if value, found := record.MarkerProperty(key); found {
			return value, true
		}
	}

	return "", false
}

func (grid scriptGrid) Remembered(levelID, x, y int) (terrain.ID, bool) {
	level := grid.levels[levelID]

	if level == nil || !level.inBounds(x, y) {
		return terrain.Unseen, false
	}

	return level.remembered[y*level.width+x], true
}

// Actual sight is separate from magic-mapped memory. A missing level or
// out-of-bounds cell cannot claim exploration of a source Xom candidate.
func (grid scriptGrid) Seen(levelID, x, y int) (bool, bool) {
	level := grid.levels[levelID]

	if level == nil || !level.inBounds(x, y) {
		return false, false
	}

	return level.seen[y*level.width+x], true
}

// Detection markers are saved independently of seen and remembered terrain.
// Lua can request one marker without gaining access to the Level's slice.
func (grid scriptGrid) DetectedItem(levelID, x, y int) (bool, bool) {
	level := grid.levels[levelID]

	if level == nil || !level.inBounds(x, y) {
		return false, false
	}

	return level.detectedItems[y*level.width+x], true
}

func (grid scriptGrid) DetectItem(levelID, x, y int) error {
	level := grid.levels[levelID]

	if level == nil {
		return fmt.Errorf("missing level %d", levelID)
	}

	return level.DetectItem(x, y)
}

func (grid scriptGrid) RestoreDetectedItem(
	levelID, x, y int, detected bool,
) error {
	level := grid.levels[levelID]

	if level == nil {
		return fmt.Errorf("missing level %d", levelID)
	}

	return level.SetDetectedItem(x, y, detected)
}

func (grid scriptGrid) DetectedCreature(levelID, x, y int) (string, bool) {
	level := grid.levels[levelID]

	if level == nil || !level.inBounds(x, y) {
		return "", false
	}

	return level.detectedCreatures[y*level.width+x], true
}

func (grid scriptGrid) DetectedCreatures(levelID int) ([][]string, bool) {
	level := grid.levels[levelID]

	if level == nil {
		return nil, false
	}

	return level.DetectedCreatures(), true
}

func (grid scriptGrid) SetDetectedCreature(levelID, x, y int, kindID string) error {
	level := grid.levels[levelID]

	if level == nil {
		return fmt.Errorf("missing level %d", levelID)
	}

	return level.SetDetectedCreature(x, y, kindID)
}

func (grid scriptGrid) LoadDetectedCreatures(levelID int, cells [][]string) error {
	level := grid.levels[levelID]

	if level == nil {
		return fmt.Errorf("missing level %d", levelID)
	}

	return level.LoadDetectedCreatures(cells)
}

func (grid scriptGrid) MapCell(levelID, x, y int) error {
	level := grid.levels[levelID]

	if level == nil {
		return fmt.Errorf("missing level %d", levelID)
	}

	return level.MapCell(x, y)
}

func (grid scriptGrid) RestoreRemembered(
	levelID, x, y int,
	feature terrain.ID,
) error {
	level := grid.levels[levelID]

	if level == nil || !level.inBounds(x, y) {
		return fmt.Errorf("missing level %d cell (%d,%d)", levelID, x, y)
	}

	level.remembered[y*level.width+x] = feature

	return nil
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

func (grid scriptGrid) ActorsAt(levelID, x, y int) []akara.Entity {
	level := grid.levels[levelID]

	if level == nil {
		return nil
	}

	return level.ActorsAt(x, y)
}

func (grid scriptGrid) StairAt(levelID, x, y int) (script.Stair, bool) {
	level := grid.levels[levelID]

	if level == nil {
		return script.Stair{}, false
	}

	link, found := level.StairAt(x, y)

	return script.Stair{
		ToLevelID:      link.ToLevelID,
		ToX:            link.ToX,
		ToY:            link.ToY,
		Unavailable:    link.Unavailable,
		Exit:           link.Exit,
		TargetBranchID: link.TargetBranchID,
	}, found
}

// Xom can move directional portals as well as linked stairs. Shops use a
// separate interaction and are excluded by the terrain property owner.
func (grid scriptGrid) TravelFeatureAt(levelID, x, y int) bool {
	level := grid.levels[levelID]

	if level == nil || !level.inBounds(x, y) {
		return false
	}

	return terrain.IsMovableTravelFeature(level.terrain[y][x])
}

func (grid scriptGrid) Visible(
	levelID, fromX, fromY, radius, targetX, targetY int,
) (bool, error) {
	level := grid.levels[levelID]

	if level == nil || !level.inBounds(targetX, targetY) {
		return false, nil
	}

	blockers := grid.opaque(levelID)
	visible, err := visibility.ComputeWithOpacity(
		level.terrain, fromX, fromY, radius,
		func(x, y int) bool {
			cell := point{
				x: x,
				y: y,
			}

			return blockers[cell]
		},
	)

	if err != nil {
		return false, err
	}

	return visible[targetY*level.width+targetX], nil
}

// No-trans sight follows the source's wall and closed-door rule. Clear
// walls obstruct cries, while creatures between endpoints do not.
func (grid scriptGrid) VisibleNoTrans(
	levelID, fromX, fromY, radius, targetX, targetY int,
) (bool, error) {
	return grid.VisibleNoTransWithBlocked(
		levelID, fromX, fromY, radius, targetX, targetY, nil,
	)
}

// Hypothetical blockers allow Lua to compare a door group as closed while
// keeping the live level and its clouds untouched during spell planning.
func (grid scriptGrid) VisibleNoTransWithBlocked(
	levelID, fromX, fromY, radius, targetX, targetY int,
	blockedCells []script.VisibleCell,
) (bool, error) {
	level := grid.levels[levelID]

	if level == nil || !level.inBounds(targetX, targetY) {
		return false, nil
	}

	blockers := map[point]bool{}

	if grid.opaque != nil {
		blockers = grid.opaque(levelID)
	}

	closed := make(map[point]bool, len(blockedCells))

	for _, cell := range blockedCells {
		closed[point{
			x: cell.X,
			y: cell.Y,
		}] = true
	}

	visible, err := visibility.ComputeWithOpacity(
		level.terrain, fromX, fromY, radius,
		func(x, y int) bool {
			cell := point{
				x: x,
				y: y,
			}

			feature := level.terrain[y][x]

			return closed[cell] ||
				blockers[cell] ||
				feature == terrain.ClearRockWall ||
				feature == terrain.ClearStoneWall ||
				feature == terrain.ClearPermaRockWall
		},
	)

	if err != nil {
		return false, err
	}

	return visible[targetY*level.width+targetX], nil
}

func (grid scriptGrid) VisibleCells(
	levelID, fromX, fromY, radius int,
) ([]script.VisibleCell, error) {
	level := grid.levels[levelID]

	if level == nil {
		return nil, nil
	}

	blockers := grid.opaque(levelID)
	visible, err := visibility.ComputeWithOpacity(
		level.terrain, fromX, fromY, radius,
		func(x, y int) bool {
			cell := point{
				x: x,
				y: y,
			}

			return blockers[cell]
		},
	)

	if err != nil {
		return nil, err
	}

	cells := make([]script.VisibleCell, 0, (2*radius+1)*(2*radius+1))

	for y := max(0, fromY-radius); y <= min(len(level.terrain)-1, fromY+radius); y++ {
		for x := max(0, fromX-radius); x <= min(level.width-1, fromX+radius); x++ {
			if visible[y*level.width+x] {
				cells = append(cells, script.VisibleCell{
					X: x,
					Y: y,
				})
			}
		}
	}

	return cells, nil
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

func (grid scriptGrid) SetCell(levelID, x, y int, feature terrain.ID) error {
	level := grid.levels[levelID]

	if level == nil {
		return fmt.Errorf("missing level %d", levelID)
	}

	return level.SetCell(x, y, feature)
}

// Keep the linked destination beside the moved feature. Xom policy chooses
// the destination; the level owner performs the atomic terrain/link change.
func (grid scriptGrid) MoveStair(levelID, fromX, fromY, toX, toY int) error {
	level := grid.levels[levelID]

	if level == nil {
		return fmt.Errorf("missing level %d", levelID)
	}

	return level.MoveStair(fromX, fromY, toX, toY)
}

func (grid scriptGrid) CellColour(levelID, x, y int) (string, bool) {
	level := grid.levels[levelID]

	if level == nil {
		return "", false
	}

	return level.CellColour(x, y)
}

func (grid scriptGrid) SetCellColour(levelID, x, y int, colour string) error {
	level := grid.levels[levelID]

	if level == nil {
		return fmt.Errorf("missing level %d", levelID)
	}

	return level.SetCellColour(x, y, colour)
}

// Expose saved blood markings to Lua without assigning terrain semantics in Go.
func (grid scriptGrid) CellBlood(levelID, x, y int) (bool, bool) {
	level := grid.levels[levelID]

	if level == nil {
		return false, false
	}

	return level.CellBlood(x, y)
}

// Stage blood changes through the same grid owner as other cell mutations.
func (grid scriptGrid) SetCellBlood(levelID, x, y int, bloody bool) error {
	level := grid.levels[levelID]

	if level == nil {
		return fmt.Errorf("missing level %d", levelID)
	}

	return level.SetCellBlood(x, y, bloody)
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
	oldActors := from.ActorsAt(oldX, oldY)
	wasPrimary := len(oldActors) > 0 && oldActors[0] == entity

	if err := from.RemoveActor(entity); err != nil {
		return err
	}

	if err := positioned.PlaceActor(entity, x, y); err != nil {
		_ = from.PlaceActorShared(entity, oldX, oldY, wasPrimary)

		return err
	}

	return nil
}

// Shared movement is explicit. The Lua caller has already decided whether
// this actor may enter the occupied destination.
func (grid scriptGrid) MoveActorShared(
	entity akara.Entity,
	levelID, x, y int,
	primary bool,
) error {
	to := grid.levels[levelID]

	if to == nil {
		return fmt.Errorf("missing level %d", levelID)
	}

	position, found := to.positions.Get(entity)

	if !found {
		return fmt.Errorf("actor %d has no position", entity)
	}

	if position.LevelID == levelID {
		return to.MoveActorShared(entity, x, y, primary)
	}

	from := grid.levels[position.LevelID]

	if from == nil {
		return fmt.Errorf("actor %d has missing origin level %d", entity, position.LevelID)
	}

	oldX, oldY := position.X, position.Y
	oldActors := from.ActorsAt(oldX, oldY)
	wasPrimary := len(oldActors) > 0 && oldActors[0] == entity

	if err := from.RemoveActor(entity); err != nil {
		return err
	}

	if err := to.PlaceActorShared(entity, x, y, primary); err != nil {
		_ = from.PlaceActorShared(entity, oldX, oldY, wasPrimary)
		return err
	}

	return nil
}

// MoveActors validates the whole permutation before changing occupancy.
// It supports cycles, such as a vortex rotating actors around its caster.
func (grid scriptGrid) MoveActors(moves []script.ActorMove) error {
	type destination struct {
		levelID int
		x       int
		y       int
	}

	moving := make(map[akara.Entity]bool, len(moves))
	occupied := make(map[destination]bool, len(moves))
	positions := make(map[akara.Entity]*ecs.Position, len(moves))

	for _, move := range moves {
		level := grid.levels[move.LevelID]
		next := destination{
			levelID: move.LevelID,
			x:       move.X,
			y:       move.Y,
		}

		previousShared, destinationUsed := occupied[next]

		if level == nil ||
			!level.Walkable(move.X, move.Y) ||
			moving[move.Actor] ||
			(destinationUsed && (!move.Shared || !previousShared)) {
			return fmt.Errorf("invalid simultaneous actor move %d", move.Actor)
		}

		position, found := level.positions.Get(move.Actor)

		if !found {
			return fmt.Errorf("actor %d has no position", move.Actor)
		}

		moving[move.Actor] = true
		occupied[next] = move.Shared
		positions[move.Actor] = position
	}

	for _, move := range moves {
		position := positions[move.Actor]
		from := grid.levels[position.LevelID]
		to := grid.levels[move.LevelID]

		if from == nil || !from.hasActor(point{
			x: position.X,
			y: position.Y,
		}, move.Actor) {
			return fmt.Errorf("actor %d is not indexed", move.Actor)
		}

		for _, other := range to.ActorsAt(move.X, move.Y) {
			if !moving[other] && !move.Shared {
				return fmt.Errorf("actor %d destination is occupied", move.Actor)
			}
		}
	}

	for _, move := range moves {
		position := positions[move.Actor]
		from := grid.levels[position.LevelID]

		from.removeIndexedActor(point{
			x: position.X,
			y: position.Y,
		}, move.Actor)
	}

	for _, move := range moves {
		position := positions[move.Actor]
		to := grid.levels[move.LevelID]

		position.LevelID = move.LevelID
		position.X = move.X
		position.Y = move.Y
		to.insertActor(point{
			x: move.X,
			y: move.Y,
		}, move.Actor, move.Primary)
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

func (grid scriptGrid) PlaceActorShared(
	entity akara.Entity,
	levelID, x, y int,
	primary bool,
) error {
	level := grid.levels[levelID]

	if level == nil {
		return fmt.Errorf("missing level %d", levelID)
	}

	return level.PlaceActorShared(entity, x, y, primary)
}

func (grid scriptGrid) RemoveActor(entity akara.Entity, levelID int) error {
	level := grid.levels[levelID]

	if level == nil {
		return fmt.Errorf("missing level %d", levelID)
	}

	return level.RemoveActor(entity)
}
