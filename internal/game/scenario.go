package game

import (
	"fmt"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/modfs"
	"dcrawl-go/internal/script"
	"github.com/gravestench/akara"
)

func NewScenario(
	seed uint64,
	catalog content.Catalog,
	weaponID, name string,
) (_ *Game, err error) {
	return newScenario(seed, catalog, catalog.Player(), weaponID, name, ordinaryMonsterScenarioID)
}

// NewPopulatedScenario keeps the current fixed map while selecting its
// supported monsters from the committed Dungeon population table.
func NewPopulatedScenario(
	seed uint64,
	catalog content.Catalog,
	weaponID, name string,
) (_ *Game, err error) {
	return newScenario(seed, catalog, catalog.Player(), weaponID, name, populationScenarioID)
}

// NewDungeonGame starts the live client with the bundled Lua ruleset.
func NewDungeonGame(
	seed uint64,
	catalog content.Catalog,
	speciesID, jobID, weaponID, name string,
) (_ *Game, err error) {
	rules, err := modfs.Load("")

	if err != nil {
		return nil, err
	}

	return NewDungeonGameWithRules(
		seed,
		catalog,
		speciesID,
		jobID,
		weaponID,
		name,
		rules,
	)
}

// NewDungeonGameWithRules starts the same game with an effective Lua tree.
func NewDungeonGameWithRules(
	seed uint64,
	catalog content.Catalog,
	speciesID, jobID, weaponID, name string,
	rules modfs.Ruleset,
) (_ *Game, err error) {
	// The source's base player speed is 10 aut for these playable species.
	definition := content.PlayerDef{
		SpeciesID: speciesID,
		JobID:     jobID,
		Speed:     10,
	}

	return newScenarioWithRules(
		seed,
		catalog,
		definition,
		weaponID,
		name,
		generatedDungeonScenarioID,
		rules,
	)
}

func newScenario(
	seed uint64,
	catalog content.Catalog,
	playerDef content.PlayerDef,
	weaponID, name string,
	scenarioID string,
) (_ *Game, err error) {
	rules, err := modfs.Load("")

	if err != nil {
		return nil, err
	}

	return newScenarioWithRules(
		seed,
		catalog,
		playerDef,
		weaponID,
		name,
		scenarioID,
		rules,
	)
}

func newScenarioWithRules(
	seed uint64,
	catalog content.Catalog,
	playerDef content.PlayerDef,
	weaponID, name string,
	scenarioID string,
	rules modfs.Ruleset,
) (_ *Game, err error) {
	if err := catalog.Validate(); err != nil {
		return nil, err
	}

	if err := character.ValidateName(name); err != nil {
		return nil, err
	}

	world := akara.NewWorld()
	defer func() {
		if err != nil {
			world.Close()
		}
	}()

	stores := ecs.Register(world)
	rng := NewRNGStreams(seed)
	setup, err := buildScenarioLevels(scenarioID, stores.Positions, rng)

	if err != nil {
		return nil, err
	}

	g := &Game{
		world:  world,
		stores: stores,
		levels: setup.levels,

		catalog: catalog,
		rules:   rules,
		seed:    seed,
		rng:     rng,

		scheduler: TurnScheduler{
			actors:    stores.Actors,
			positions: stores.Positions,
			energies:  stores.MonsterEnergy,
			catalog:   catalog,
			rng:       rng,
		},

		scenarioID: scenarioID,
	}

	g.scripts, err = script.New(world, rules, script.Services{
		ActiveActor: func() akara.Entity {
			return g.turn.Actor
		},
		Random: g.rng.Intn,
		Emit: func(kind, message string) {
			g.turn.Events = append(g.turn.Events, Event{
				Kind: kind,
				Text: message,
			})
		},
	})

	if err != nil {
		return nil, err
	}

	defer func() {
		if err != nil {
			g.scripts.Close()
		}
	}()

	g.catalog, err = g.catalog.WithCharacterDefinitions(
		g.scripts.SpeciesDefinitions(),
		g.scripts.JobDefinitions(),
	)

	if err != nil {
		return nil, err
	}

	choice, err := g.scripts.CharacterChoice(
		playerDef.SpeciesID,
		playerDef.JobID,
		true,
	)

	if err != nil {
		return nil, err
	}

	reverseChoice, err := g.scripts.CharacterChoice(
		playerDef.SpeciesID,
		playerDef.JobID,
		false,
	)

	if err != nil {
		return nil, err
	}

	supported := character.SupportedFighterStart(
		playerDef.SpeciesID,
		playerDef.JobID,
	)

	if !choice.Playable ||
		!reverseChoice.Playable ||
		!supported {
		return nil, fmt.Errorf(
			"Lua rules do not support the %s/%s start",
			playerDef.SpeciesID,
			playerDef.JobID,
		)
	}

	g.scheduler.catalog = g.catalog

	if err := character.ValidateWeaponChoice(
		g.catalog,
		playerDef.SpeciesID,
		playerDef.JobID,
		weaponID,
	); err != nil {
		return nil, err
	}

	if err = g.createPlayerActor(playerDef, weaponID, name, setup); err != nil {
		return nil, err
	}

	if err = g.initializeCharacter(playerDef, weaponID); err != nil {
		return nil, err
	}

	if scenarioID != ordinaryMonsterScenarioID {
		err = g.populateDungeon(setup.populationEntries)
	} else {
		err = g.spawnFixtureMonsters()
	}

	if err != nil {
		return nil, err
	}

	if err = g.createStartingFloorItems(setup); err != nil {
		return nil, err
	}

	if err = registerSystems(g); err != nil {
		return nil, err
	}

	if err = g.refreshVisibility(); err != nil {
		return nil, err
	}

	return g, nil
}

// createPlayerActor establishes identity, position, and starting equipment.
// These must exist before character rules project the starting profile.
func (g *Game) createPlayerActor(
	definition content.PlayerDef,
	weaponID, name string,
	setup scenarioLevels,
) error {
	player, err := g.world.CreateEntity()

	if err != nil {
		return err
	}

	if _, err := g.stores.PlayerTurn.Set(player, ecs.PlayerTurn{}); err != nil {
		return err
	}

	g.player = player

	_, err = g.stores.Actors.Set(player, ecs.Actor{
		KindID: "player",
		Speed:  definition.Speed,
	})

	if err != nil {
		return err
	}

	_, err = g.stores.Combat.Set(player, ecs.Combatant{})

	if err != nil {
		return err
	}

	_, err = g.stores.Players.Set(player, ecs.PlayerControlled{
		Name:             name,
		SpeciesID:        definition.SpeciesID,
		JobID:            definition.JobID,
		StartingWeaponID: weaponID,
	})

	if err != nil {
		return err
	}

	if err := setup.levels[1].PlaceActor(player, setup.entry.x, setup.entry.y); err != nil {
		return err
	}

	return g.createStartingGear(definition.JobID, weaponID)
}

// initializeCharacter stores the source-derived Fighter state on the player.
func (g *Game) initializeCharacter(definition content.PlayerDef, weaponID string) error {
	profile, err := character.BuildStartProfile(
		g.catalog,
		definition.SpeciesID,
		definition.JobID,
		weaponID,
	)

	if err != nil {
		return err
	}

	_, err = g.stores.Attributes.Set(g.player, ecs.Attributes{
		Strength:     profile.Attributes.Strength,
		Intelligence: profile.Attributes.Intelligence,
		Dexterity:    profile.Attributes.Dexterity,
	})

	if err != nil {
		return err
	}

	skills := append([]character.Skill(nil), profile.Skills...)
	_, err = g.stores.Skills.Set(g.player, ecs.Skills{
		Entries: skills,
	})

	if err != nil {
		return err
	}

	training, err := newPlayerSkillTraining(skills, g.rng)

	if err != nil {
		return err
	}

	_, err = g.stores.SkillTraining.Set(g.player, training)

	if err != nil {
		return err
	}

	_, err = g.stores.Progression.Set(g.player, ecs.Progression{Level: 1})

	if err != nil {
		return err
	}

	_, err = g.stores.Durations.Set(g.player, ecs.Durations{})

	if err != nil {
		return err
	}

	_, err = g.stores.Regeneration.Set(g.player, ecs.Regeneration{})

	if err != nil {
		return err
	}

	_, err = g.stores.Health.Set(g.player, ecs.Health{
		Current: profile.MaxHP,
		Max:     profile.MaxHP,
	})

	if err != nil {
		return err
	}

	_, err = g.stores.Magic.Set(g.player, ecs.Magic{
		Current: profile.MaxMP,
		Max:     profile.MaxMP,
	})

	return err
}

func (g *Game) createStartingFloorItems(setup scenarioLevels) error {
	if err := g.spawnScenarioPotion("POT_CURING", 1, setup.curing); err != nil {
		return err
	}

	if err := g.spawnScenarioPotion("POT_HEAL_WOUNDS", 2, setup.heal); err != nil {
		return err
	}

	return g.spawnScenarioPotion("POT_HASTE", 2, setup.haste)
}

func (g *Game) spawnScenarioPotion(kindID string, levelID int, cell point) error {
	if _, err := g.catalog.Item(kindID); err != nil {
		return err
	}

	entity, err := g.world.CreateEntity()

	if err != nil {
		return err
	}

	_, err = g.stores.Items.Set(entity, ecs.Item{
		KindID:   kindID,
		Quantity: 1,
	})

	if err != nil {
		return err
	}

	_, err = g.stores.Positions.Set(entity, ecs.Position{
		LevelID: levelID,
		X:       cell.x,
		Y:       cell.y,
	})

	return err
}
