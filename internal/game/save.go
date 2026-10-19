package game

import (
	"fmt"
	"sort"

	"crawl/internal/character"
	"crawl/internal/ecs"
	"crawl/internal/modfs"
	"crawl/internal/save"
	"crawl/internal/script"
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

func copySkillTrainingComponent(
	store *akara.Store[ecs.SkillTraining],
	entity akara.Entity,
) *ecs.SkillTraining {
	value, found := store.Get(entity)

	if !found {
		return nil
	}

	copy := value.Clone()

	return &copy
}

func validateSavedItem(record save.EntityRecord) error {
	locations := 0

	if record.Position != nil {
		locations++
	}

	if record.CarriedBy != nil {
		locations++
	}

	if record.ReservedBy != nil {
		locations++
	}

	for _, component := range record.Dynamic {
		if component.Schema == "shop.stock" {
			locations++
		}
	}

	if locations > 1 {
		return fmt.Errorf("item %d has conflicting locations; it cannot be in both places", record.ID)
	}

	if locations != 1 || record.Actor != nil {
		return fmt.Errorf(
			"item %d must have exactly one position, carrier, reservation, or shop owner",
			record.ID,
		)
	}

	if record.ReservedBy != nil &&
		(record.ReservedBy.Owner == 0 ||
			uint64(record.ReservedBy.Owner) == record.ID) {
		return fmt.Errorf("item %d has invalid reservation owner", record.ID)
	}

	if savedItemHasActorComponents(record) {
		return fmt.Errorf("item %d has actor components", record.ID)
	}

	if record.Equipped == nil {
		return nil
	}

	if record.CarriedBy == nil ||
		record.CarriedBy.Holder == 0 ||
		record.Position != nil ||
		record.ReservedBy != nil ||
		record.Equipped.Slot == "" {
		return fmt.Errorf("item %d has invalid equipped slot or carrier", record.ID)
	}

	return nil
}

func savedItemHasActorComponents(record save.EntityRecord) bool {
	return record.Health != nil ||
		record.PlayerTurn != nil ||
		record.MonsterEnergy != nil ||
		record.Magic != nil ||
		record.Skills != nil ||
		record.SkillTraining != nil ||
		record.Progression != nil ||
		record.Durations != nil ||
		record.Poison != nil ||
		record.Constricted != nil ||
		record.Regeneration != nil ||
		record.Combatant != nil ||
		record.Player != nil ||
		record.AI != nil ||
		record.BandFollower != nil ||
		record.Attributes != nil ||
		record.Equipment != nil
}

func (g *Game) Snapshot() save.Snapshot {
	snapshot := save.Snapshot{
		Version:    save.Version,
		ScenarioID: g.scenarioID,

		RulesetHash:    g.rules.Hash(),
		LuaDialect:     luaDialect,
		RulesetFiles:   g.savedRulesetFiles(),
		RulesetChanges: g.rules.Changes(),
		LuaSchemas:     g.savedLuaSchemas(),

		PlayerID:   uint64(g.player),
		CurrentAut: int64(g.currentAut),
		Seed:       g.seed,
		RNG:        g.rng.States(),
		Messages:   append([]string(nil), g.messages...),
	}

	for id, level := range g.levels {
		record := save.LevelRecord{
			ID:       id,
			BranchID: level.BranchID,

			Cells:         level.Cells(),
			Known:         level.KnownCells(),
			Seen:          level.SeenCells(),
			DetectedItems: level.DetectedItems(),

			InitialMonsters: level.initialMonsters,
			InitialActors:   level.initialActors,

			VaultID:      level.VaultID(),
			VaultRecords: level.VaultRecords(),
			ShoalsTide:   level.shoalsTideRecord(),
		}

		for _, cell := range level.spawnExclusions {
			record.SpawnExclusions = append(record.SpawnExclusions,
				save.PointRecord{
					X: cell.x,
					Y: cell.y,
				})
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
			ID: uint64(entity),

			Position:      copyComponent(g.stores.Positions, entity),
			Actor:         copyComponent(g.stores.Actors, entity),
			PlayerTurn:    copyComponent(g.stores.PlayerTurn, entity),
			MonsterEnergy: copyComponent(g.stores.MonsterEnergy, entity),
			Health:        copyComponent(g.stores.Health, entity),

			Magic:         copyComponent(g.stores.Magic, entity),
			Skills:        copySkillsComponent(g.stores.Skills, entity),
			SkillTraining: copySkillTrainingComponent(g.stores.SkillTraining, entity),
			Progression:   copyComponent(g.stores.Progression, entity),
			Durations:     copyComponent(g.stores.Durations, entity),
			Poison:        copyComponent(g.stores.Poison, entity),
			Constricted:   copyComponent(g.stores.Constricted, entity),
			Regeneration:  copyComponent(g.stores.Regeneration, entity),
			Combatant:     copyComponent(g.stores.Combat, entity),

			Player:     copyComponent(g.stores.Players, entity),
			Attributes: copyComponent(g.stores.Attributes, entity),
			Equipment:  copyComponent(g.stores.Equipment, entity),

			AI:           copyComponent(g.stores.AI, entity),
			BandFollower: copyComponent(g.stores.Followers, entity),

			Item:       copyComponent(g.stores.Items, entity),
			Corpse:     copyComponent(g.stores.Corpses, entity),
			CarriedBy:  copyComponent(g.stores.CarriedBy, entity),
			ReservedBy: copyComponent(g.stores.ReservedBy, entity),
			Equipped:   copyComponent(g.stores.Equipped, entity),

			Dynamic: g.savedLuaComponents(entity),
		})
	}

	sort.Slice(snapshot.Entities, func(i, j int) bool {
		return snapshot.Entities[i].ID < snapshot.Entities[j].ID
	})

	return snapshot
}

func (g *Game) Restore(snapshot save.Snapshot) (*Game, error) {
	return RestoreWithRules(snapshot, g.rules, RestorePolicy{})
}

// Restore builds a separate game using the bundled ruleset.
func Restore(snapshot save.Snapshot) (*Game, error) {
	rules, err := modfs.Load()

	if err != nil {
		return nil, err
	}

	return RestoreWithRules(snapshot, rules, RestorePolicy{})
}

// RestorePolicy makes a changed Lua ruleset an explicit load decision.
type RestorePolicy struct {
	AllowRulesetMismatch bool
}

// RestoreWithRules builds a separate game. The caller replaces its live game
// only after validation and registration succeed.
func RestoreWithRules(
	snapshot save.Snapshot,
	rules modfs.Ruleset,
	policy RestorePolicy,
) (_ *Game, err error) {
	if snapshot.Version != save.Version {
		return nil, fmt.Errorf("unsupported save version %d", snapshot.Version)
	}

	if snapshot.LuaDialect != luaDialect {
		return nil, fmt.Errorf("unsupported Lua dialect %q", snapshot.LuaDialect)
	}

	currentFiles := currentRulesetFiles(rules)

	if snapshot.RulesetHash != rules.Hash() {
		if !policy.AllowRulesetMismatch {
			return nil, fmt.Errorf(
				"save ruleset %s differs from current %s; changed Lua paths: %v",
				snapshot.RulesetHash,
				rules.Hash(),
				changedRulesetPaths(snapshot.RulesetFiles, currentFiles),
			)
		}
	} else if !rulesetFilesEqual(snapshot.RulesetFiles, currentFiles) {
		return nil, fmt.Errorf("save Lua manifest differs from its ruleset hash")
	}

	if snapshot.PlayerID == 0 ||
		snapshot.CurrentAut < 0 ||
		len(snapshot.Levels) == 0 {
		return nil, fmt.Errorf("invalid save header")
	}

	world := akara.NewWorld()
	defer func() {
		if err != nil {
			_ = world.Close()
		}
	}()

	stores := ecs.Register(world)
	rng := RestoreRNGStreams(snapshot.Seed, snapshot.RNG)
	g := &Game{
		world:  world,
		stores: stores,
		levels: make(map[int]*Level),
		player: akara.Entity(snapshot.PlayerID),

		rules:      rules,
		seed:       snapshot.Seed,
		scenarioID: snapshot.ScenarioID,
		rng:        rng,

		scheduler: TurnScheduler{
			actors:    stores.Actors,
			positions: stores.Positions,
			energies:  stores.MonsterEnergy,
		},

		currentAut: Aut(snapshot.CurrentAut),
		messages:   append([]string(nil), snapshot.Messages...),
	}

	services, err := g.scriptServices()

	if err != nil {
		return nil, err
	}

	g.scripts, err = script.New(world, rules, services)

	if err != nil {
		return nil, err
	}

	g.scheduler.policy = g.scripts.Policy

	defer func() {
		if err != nil {
			g.scripts.Close()
		}
	}()

	if err := g.validateSavedLuaSchemas(
		snapshot.LuaSchemas,
		policy.AllowRulesetMismatch,
	); err != nil {
		return nil, err
	}

	if err := g.restoreLevels(snapshot.Levels, snapshot.CurrentAut); err != nil {
		return nil, err
	}

	if err := g.validateAndRegisterSavedEntities(snapshot); err != nil {
		return nil, err
	}

	if err := g.restoreEntityComponents(snapshot.Entities); err != nil {
		return nil, err
	}

	if err := g.restoreLuaComponents(snapshot.Entities); err != nil {
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
