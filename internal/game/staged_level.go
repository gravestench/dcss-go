package game

import (
	"fmt"

	"crawl/internal/save"
	"github.com/gravestench/akara"
)

// stagedLevel keeps a generated floor reversible until its portal action
// commits. The new ID is distinct from the active floor, so population can
// use ordinary ECS placement without touching the current region.
type stagedLevel struct {
	game            *Game
	levelID         int
	entry           point
	priorEntities   map[akara.Entity]bool
	priorComponents map[akara.Entity][]save.DynamicComponentRecord
	priorRNG        map[string]uint64
	closed          bool
}

// rollback removes the staged floor and restores all dynamic components on
// actors that existed before staging. Population can claim a unique on the
// player before a later landing check rejects the floor; deleting only the
// new monsters would otherwise leave that claim behind.
func (stage *stagedLevel) rollback() error {
	if stage == nil || stage.closed {
		return nil
	}

	stage.game.scripts.DiscardPending()

	for _, entity := range stage.game.world.Entities() {
		if !stage.priorEntities[entity] {
			stage.game.world.DestroyEntity(entity)
		}
	}

	for _, store := range akara.DynamicStores(stage.game.world) {
		for entity := range stage.priorEntities {
			store.Remove(entity)
		}
	}

	for entity, records := range stage.priorComponents {
		if !stage.game.world.EntityExists(entity) {
			return fmt.Errorf("staged rollback lost prior entity %d", entity)
		}

		for _, record := range records {
			store, found := akara.GetDynamicStore(stage.game.world,
				record.Schema)

			if !found {
				return fmt.Errorf("staged rollback lost schema %s",
					record.Schema)
			}

			values, err := decodeLuaValues(store.Schema(), record.Values,
				stage.priorEntities)

			if err != nil {
				return fmt.Errorf("staged rollback %s entity %d: %w",
					record.Schema, entity, err)
			}

			if _, err := store.Set(entity, values); err != nil {
				return fmt.Errorf("staged rollback %s entity %d: %w",
					record.Schema, entity, err)
			}
		}
	}

	delete(stage.game.levels, stage.levelID)
	stage.game.rng.states = stage.priorRNG
	stage.closed = true

	return nil
}

// commit leaves the populated floor and its entities in the live world.
// The caller can now move the player and retire the previous region.
func (stage *stagedLevel) commit() {
	stage.closed = true
}

// stageGeneratedLevel decodes one Lua level, exposes its grid to the normal
// population policy, and rolls everything back if any step rejects it.
// The policy owns branch rules; Go only verifies the returned grid record.
func (g *Game) stageGeneratedLevel(
	policyID string,
	input map[string]any,
) (_ *stagedLevel, err error) {
	stage := &stagedLevel{
		game:            g,
		priorEntities:   make(map[akara.Entity]bool),
		priorComponents: make(map[akara.Entity][]save.DynamicComponentRecord),
		priorRNG:        g.rng.States(),
	}

	for _, entity := range g.world.Entities() {
		stage.priorEntities[entity] = true
		stage.priorComponents[entity] = g.savedLuaComponents(entity)
	}

	defer func() {
		if err != nil {
			if rollbackErr := stage.rollback(); rollbackErr != nil {
				err = fmt.Errorf("%w; rollback: %v", err, rollbackErr)
			}
		}
	}()

	result, err := g.scripts.Policy(policyID, input)

	if err != nil {
		return nil, err
	}

	record, okay := result["level"].(map[string]any)

	if !okay {
		return nil, fmt.Errorf("Lua generated level is not a record")
	}

	levelID, err := decisionInteger(record, "id")

	if err != nil {
		return nil, err
	}

	if levelID <= 0 || g.levels[levelID] != nil {
		return nil, fmt.Errorf("Lua generated level has an invalid or duplicate ID")
	}

	// Only now does this transaction own the ID for error cleanup.
	stage.levelID = levelID

	entries, _, links, err := g.decodeLuaLevelRecords([]any{record},
		g.stores.Positions)

	if err != nil {
		return nil, err
	}

	if len(links[stage.levelID]) != 0 {
		return nil, fmt.Errorf("staged level has unsupported stair links")
	}

	stage.entry = entries[stage.levelID]

	level := g.levels[stage.levelID]

	if level == nil || !level.Walkable(stage.entry.x, stage.entry.y) {
		return nil, fmt.Errorf("staged level %d entry (%d,%d) is not walkable",
			stage.levelID, stage.entry.x, stage.entry.y)
	}

	if err := g.runPopulation([]any{populationLevelRecord(level,
		stage.entry)}, nil); err != nil {
		return nil, err
	}

	landing, err := g.scripts.Policy("world.find_safe_landing",
		map[string]any{
			"level_id": stage.levelID,
			"x":        stage.entry.x,
			"y":        stage.entry.y,
		})

	if err != nil {
		return nil, err
	}

	stage.entry, err = luaScenarioPoint(landing)

	if err != nil {
		return nil, err
	}

	return stage, nil
}
