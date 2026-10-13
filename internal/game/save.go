package game

import (
	"fmt"
	"sort"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
	"github.com/gravestench/akara"
)

func copyComponent[T any](store *akara.Store[T], entity akara.Entity) *T {
	value, found := store.Get(entity)
	if !found {
		return nil
	}
	copy := *value
	return &copy
}

func (g *Game) Snapshot() save.Snapshot {
	snapshot := save.Snapshot{Version: save.Version, SourceRevision: g.catalog.SourceRevision(),
		PlayerID: uint64(g.player), CurrentAut: int64(g.currentAut), Seed: g.seed,
		RNG: g.rng.States(), Messages: append([]string(nil), g.messages...)}
	for id, level := range g.levels {
		snapshot.Levels = append(snapshot.Levels, save.LevelRecord{ID: id, Rows: append([]string(nil), level.terrain...)})
	}
	sort.Slice(snapshot.Levels, func(i, j int) bool { return snapshot.Levels[i].ID < snapshot.Levels[j].ID })
	for _, entity := range g.world.Entities() {
		snapshot.Entities = append(snapshot.Entities, save.EntityRecord{
			ID: uint64(entity), Position: copyComponent(g.stores.Positions, entity),
			Actor: copyComponent(g.stores.Actors, entity), Health: copyComponent(g.stores.Health, entity),
			Combatant: copyComponent(g.stores.Combat, entity), Player: copyComponent(g.stores.Players, entity),
			AI: copyComponent(g.stores.AI, entity), Item: copyComponent(g.stores.Items, entity),
			CarriedBy: copyComponent(g.stores.CarriedBy, entity),
		})
	}
	sort.Slice(snapshot.Entities, func(i, j int) bool { return snapshot.Entities[i].ID < snapshot.Entities[j].ID })
	return snapshot
}

func (g *Game) Restore(snapshot save.Snapshot) (*Game, error) {
	return Restore(snapshot, g.catalog)
}

// Restore builds a separate game. The caller replaces its live game only after success.
func Restore(snapshot save.Snapshot, catalog content.Catalog) (_ *Game, err error) {
	if snapshot.Version != save.Version {
		return nil, fmt.Errorf("unsupported save version %d", snapshot.Version)
	}
	if err := catalog.Validate(); err != nil {
		return nil, err
	}
	if snapshot.SourceRevision != catalog.SourceRevision() {
		return nil, fmt.Errorf("save source revision %q does not match catalog", snapshot.SourceRevision)
	}
	if snapshot.PlayerID == 0 || snapshot.CurrentAut < 0 || len(snapshot.Levels) == 0 {
		return nil, fmt.Errorf("invalid save header")
	}
	world := akara.NewWorld()
	defer func() {
		if err != nil {
			_ = world.Close()
		}
	}()
	stores := ecs.Register(world)
	g := &Game{world: world, stores: stores, levels: make(map[int]*Level), player: akara.Entity(snapshot.PlayerID),
		catalog: catalog, seed: snapshot.Seed, rng: RestoreRNGStreams(snapshot.Seed, snapshot.RNG),
		scheduler: TurnScheduler{actors: stores.Actors}, currentAut: Aut(snapshot.CurrentAut),
		messages: append([]string(nil), snapshot.Messages...)}
	for _, record := range snapshot.Levels {
		if _, duplicate := g.levels[record.ID]; duplicate {
			return nil, fmt.Errorf("duplicate level %d", record.ID)
		}
		level, levelErr := NewLevel(record.ID, record.Rows, stores.Positions)
		if levelErr != nil {
			return nil, levelErr
		}
		g.levels[record.ID] = level
	}
	if g.levels[1] == nil || g.levels[2] == nil {
		return nil, fmt.Errorf("save is missing a Dungeon floor")
	}
	seen := make(map[uint64]bool)
	playerCount := 0
	var playerNext int64
	var playerAlive bool
	var earliestID uint64
	var earliestAut int64
	for _, record := range snapshot.Entities {
		if record.ID == 0 || seen[record.ID] {
			return nil, fmt.Errorf("duplicate or zero entity ID %d", record.ID)
		}
		seen[record.ID] = true
		if record.Item != nil {
			if _, err := catalog.Item(record.Item.KindID); err != nil {
				return nil, err
			}
			if record.Item.Quantity <= 0 || (record.Position == nil) == (record.CarriedBy == nil) || record.Actor != nil {
				return nil, fmt.Errorf("item %d must have exactly one of position or carrier, never both", record.ID)
			}
			if record.Health != nil || record.Combatant != nil || record.Player != nil || record.AI != nil {
				return nil, fmt.Errorf("item %d has actor components", record.ID)
			}
		} else if record.CarriedBy != nil {
			return nil, fmt.Errorf("non-item %d has carrier", record.ID)
		}
		if record.Actor == nil && record.Item == nil {
			return nil, fmt.Errorf("entity %d has no actor or item role", record.ID)
		}
		if record.Player != nil && record.AI != nil {
			return nil, fmt.Errorf("entity %d is both player and monster", record.ID)
		}
		if record.Player != nil {
			playerCount++
			definition := catalog.Player()
			if record.ID != snapshot.PlayerID || record.Actor == nil || record.Position == nil || record.Health == nil ||
				record.Player.SpeciesID != definition.SpeciesID || record.Player.JobID != definition.JobID {
				return nil, fmt.Errorf("invalid player entity %d", record.ID)
			}
			playerNext = record.Actor.NextAut
			playerAlive = record.Health.Current > 0
		}
		if record.AI != nil {
			if record.Actor == nil || record.Health == nil || record.Position == nil {
				return nil, fmt.Errorf("invalid monster entity %d", record.ID)
			}
			if _, err := catalog.Monster(record.Actor.KindID); err != nil {
				return nil, err
			}
		}
		if record.Actor != nil && (record.Actor.Speed <= 0 || record.Actor.NextAut < 0 || record.Health == nil || record.Combatant == nil || record.Position == nil) {
			return nil, fmt.Errorf("invalid actor %d", record.ID)
		}
		if record.Combatant != nil && (record.Actor == nil || record.Combatant.BaseDamage < 0 || record.Combatant.BaseDamage == int(^uint(0)>>1)) {
			return nil, fmt.Errorf("invalid combat stats for entity %d", record.ID)
		}
		if record.Actor != nil && record.Player == nil && record.AI == nil {
			return nil, fmt.Errorf("actor %d has no player or monster role", record.ID)
		}
		if record.Actor != nil {
			if record.Actor.NextAut < snapshot.CurrentAut {
				return nil, fmt.Errorf("actor %d deadline precedes save clock", record.ID)
			}
			if earliestID == 0 || record.Actor.NextAut < earliestAut || (record.Actor.NextAut == earliestAut && record.ID < earliestID) {
				earliestID, earliestAut = record.ID, record.Actor.NextAut
			}
		}
		if record.Health != nil && (record.Health.Current < 0 || record.Health.Max <= 0 || record.Health.Current > record.Health.Max) {
			return nil, fmt.Errorf("invalid health for entity %d", record.ID)
		}
		if err := world.CreateEntityWithID(akara.Entity(record.ID)); err != nil {
			return nil, err
		}
	}
	if playerCount != 1 {
		return nil, fmt.Errorf("save requires exactly one player, found %d", playerCount)
	}
	// Between live turns the player is next at the displayed clock. A dead
	// player can retain a later deadline after a monster's killing action.
	if playerAlive && (playerNext != snapshot.CurrentAut || earliestID != snapshot.PlayerID) {
		return nil, fmt.Errorf("save clock does not match the next player turn")
	}
	for _, record := range snapshot.Entities {
		entity := akara.Entity(record.ID)
		if record.Actor != nil {
			if _, err := stores.Actors.Set(entity, *record.Actor); err != nil {
				return nil, err
			}
		}
		if record.Health != nil {
			if _, err := stores.Health.Set(entity, *record.Health); err != nil {
				return nil, err
			}
		}
		if record.Combatant != nil {
			if _, err := stores.Combat.Set(entity, *record.Combatant); err != nil {
				return nil, err
			}
		}
		if record.Player != nil {
			if _, err := stores.Players.Set(entity, *record.Player); err != nil {
				return nil, err
			}
		}
		if record.AI != nil {
			if _, err := stores.AI.Set(entity, *record.AI); err != nil {
				return nil, err
			}
		}
		if record.Item != nil {
			if _, err := stores.Items.Set(entity, *record.Item); err != nil {
				return nil, err
			}
		}
		if record.Position != nil {
			level, found := g.levels[record.Position.LevelID]
			if !found || !level.Walkable(record.Position.X, record.Position.Y) {
				return nil, fmt.Errorf("entity %d has invalid position %+v", record.ID, *record.Position)
			}
			if record.Actor != nil {
				if err := level.PlaceActor(entity, record.Position.X, record.Position.Y); err != nil {
					return nil, err
				}
			} else if _, err := stores.Positions.Set(entity, *record.Position); err != nil {
				return nil, err
			}
		}
		if record.CarriedBy != nil {
			if record.CarriedBy.Holder != g.player {
				return nil, fmt.Errorf("item %d has unsupported carrier %d", record.ID, record.CarriedBy.Holder)
			}
			if _, err := stores.CarriedBy.Set(entity, *record.CarriedBy); err != nil {
				return nil, err
			}
		}
	}
	if err := registerSystems(g); err != nil {
		return nil, err
	}
	return g, nil
}
