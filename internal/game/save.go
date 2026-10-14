package game

import (
	"fmt"
	"slices"
	"sort"

	"dcrawl-go/internal/character"
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

func copySkillsComponent(store *akara.Store[ecs.Skills], entity akara.Entity) *ecs.Skills {
	copy := copyComponent(store, entity)

	if copy != nil {
		copy.Entries = append([]character.Skill(nil), copy.Entries...)
	}

	return copy
}

func validateSavedItem(
	record save.EntityRecord,
	catalog content.Catalog,
	player akara.Entity,
	occupied map[string]string,
) error {
	item := record.Item
	kind, err := catalog.Item(item.KindID)

	if err != nil {
		return err
	}

	if err := validateItemProperties(*item, kind); err != nil {
		return fmt.Errorf("item %d has %w", record.ID, err)
	}

	if (record.Position == nil) == (record.CarriedBy == nil) || record.Actor != nil {
		return fmt.Errorf("item %d must have exactly one of position or carrier, never both", record.ID)
	}

	corpseKind := item.KindID == "CORPSE_BODY" || item.KindID == "CORPSE_SKELETON"

	if corpseKind != (record.Corpse != nil) {
		return fmt.Errorf("item %d has mismatched corpse state", record.ID)
	}

	if corpseKind {
		if err := validateSavedCorpse(record, catalog); err != nil {
			return err
		}
	}

	if savedItemHasActorComponents(record) {
		return fmt.Errorf("item %d has actor components", record.ID)
	}

	if record.Equipped == nil {
		return nil
	}

	if record.CarriedBy == nil || record.CarriedBy.Holder != player ||
		record.Position != nil || kind.Slot == "" ||
		record.Equipped.Slot != kind.Slot {
		return fmt.Errorf("item %d has invalid equipped slot or carrier", record.ID)
	}

	if _, duplicate := occupied[kind.Slot]; duplicate {
		return fmt.Errorf("duplicate equipped slot %s", kind.Slot)
	}

	occupied[kind.Slot] = kind.ID

	return nil
}

func validateSavedCorpse(record save.EntityRecord, catalog content.Catalog) error {
	item := record.Item
	corpse := record.Corpse

	if record.Position == nil || record.CarriedBy != nil ||
		record.Equipped != nil || item.Quantity != 1 {
		return fmt.Errorf("item %d has invalid ordinary animal corpse state", record.ID)
	}

	if !isOrdinaryAnimal(corpse.MonsterID) ||
		corpse.Freshness < 1 || corpse.Freshness > 110 ||
		corpse.Appearance < 1 || corpse.Appearance > 255 {
		return fmt.Errorf("item %d has invalid ordinary animal corpse state", record.ID)
	}

	definition, err := ordinaryAnimal(catalog, corpse.MonsterID)

	if err != nil {
		return fmt.Errorf("item %d corpse: %w", record.ID, err)
	}

	if item.KindID == "CORPSE_SKELETON" &&
		slices.Contains(definition.Flags, "M_NO_SKELETON") {
		return fmt.Errorf("item %d has impossible %s skeleton", record.ID, corpse.MonsterID)
	}

	return nil
}

func savedItemHasActorComponents(record save.EntityRecord) bool {
	return record.Health != nil ||
		record.Magic != nil ||
		record.Skills != nil ||
		record.Progression != nil ||
		record.Durations != nil ||
		record.Regeneration != nil ||
		record.Combatant != nil ||
		record.Player != nil ||
		record.AI != nil ||
		record.Attributes != nil
}

func (g *Game) Snapshot() save.Snapshot {
	snapshot := save.Snapshot{
		Version:        save.Version,
		SourceRevision: g.catalog.SourceRevision(),
		ScenarioID:     g.scenarioID,
		PlayerID:       uint64(g.player),
		CurrentAut:     int64(g.currentAut),
		Seed:           g.seed,
		RNG:            g.rng.States(),
		Messages:       append([]string(nil), g.messages...),
	}

	for id, level := range g.levels {
		record := save.LevelRecord{
			ID:              id,
			Rows:            append([]string(nil), level.terrain...),
			Known:           level.KnownRows(),
			InitialMonsters: level.initialMonsters,
		}

		for _, link := range level.StairLinks() {
			record.Stairs = append(record.Stairs, save.StairRecord{
				X:           link.X,
				Y:           link.Y,
				ToLevelID:   link.ToLevelID,
				ToX:         link.ToX,
				ToY:         link.ToY,
				Unavailable: link.Unavailable,
			})
		}

		if level.awaySinceAut != nil {
			since := int64(*level.awaySinceAut)
			record.AwaySinceAut = &since
		}

		snapshot.Levels = append(snapshot.Levels, record)
	}

	sort.Slice(snapshot.Levels, func(i, j int) bool {
		return snapshot.Levels[i].ID < snapshot.Levels[j].ID
	})

	for _, entity := range g.world.Entities() {
		snapshot.Entities = append(snapshot.Entities, save.EntityRecord{
			ID:           uint64(entity),
			Position:     copyComponent(g.stores.Positions, entity),
			Actor:        copyComponent(g.stores.Actors, entity),
			Health:       copyComponent(g.stores.Health, entity),
			Magic:        copyComponent(g.stores.Magic, entity),
			Skills:       copySkillsComponent(g.stores.Skills, entity),
			Progression:  copyComponent(g.stores.Progression, entity),
			Durations:    copyComponent(g.stores.Durations, entity),
			Regeneration: copyComponent(g.stores.Regeneration, entity),
			Combatant:    copyComponent(g.stores.Combat, entity),
			Player:       copyComponent(g.stores.Players, entity),
			Attributes:   copyComponent(g.stores.Attributes, entity),
			AI:           copyComponent(g.stores.AI, entity),
			Item:         copyComponent(g.stores.Items, entity),
			Corpse:       copyComponent(g.stores.Corpses, entity),
			CarriedBy:    copyComponent(g.stores.CarriedBy, entity),
			Equipped:     copyComponent(g.stores.Equipped, entity),
		})
	}

	sort.Slice(snapshot.Entities, func(i, j int) bool {
		return snapshot.Entities[i].ID < snapshot.Entities[j].ID
	})

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

	scenarioAnimals, err := scenarioAnimalIDs(snapshot.ScenarioID)

	if err != nil {
		return nil, err
	}

	usesPopulation := snapshot.ScenarioID == populationScenarioID ||
		snapshot.ScenarioID == generatedDungeonScenarioID

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
	g := &Game{
		world:      world,
		stores:     stores,
		levels:     make(map[int]*Level),
		player:     akara.Entity(snapshot.PlayerID),
		catalog:    catalog,
		seed:       snapshot.Seed,
		scenarioID: snapshot.ScenarioID,
		rng:        RestoreRNGStreams(snapshot.Seed, snapshot.RNG),
		scheduler: TurnScheduler{
			actors:    stores.Actors,
			positions: stores.Positions,
		},
		currentAut: Aut(snapshot.CurrentAut),
		messages:   append([]string(nil), snapshot.Messages...),
	}

	if err := g.restoreLevels(snapshot.Levels, snapshot.CurrentAut); err != nil {
		return nil, err
	}

	if err := g.validateAndRegisterSavedEntities(snapshot, scenarioAnimals, usesPopulation); err != nil {
		return nil, err
	}

	if err := g.restoreEntityComponents(snapshot.Entities); err != nil {
		return nil, err
	}

	if err := g.validateRestoredPlacement(); err != nil {
		return nil, err
	}

	if err := registerSystems(g); err != nil {
		return nil, err
	}

	if err := g.refreshVisibility(); err != nil {
		return nil, err
	}

	return g, nil
}
