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

	g := &Game{
		world:  world,
		stores: stores,
		levels: make(map[int]*Level),

		catalog: catalog,
		rules:   rules,
		seed:    seed,
		rng:     rng,

		scheduler: TurnScheduler{
			actors:    stores.Actors,
			positions: stores.Positions,
			energies:  stores.MonsterEnergy,
		},

		scenarioID: scenarioID,
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

	setup, err := g.buildScriptScenario(scenarioID, stores.Positions)

	if err != nil {
		return nil, err
	}

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

	if !choice.Playable ||
		!reverseChoice.Playable {
		return nil, fmt.Errorf(
			"Lua rules do not support the %s/%s start",
			playerDef.SpeciesID,
			playerDef.JobID,
		)
	}

	if err = g.createPlayerActor(playerDef, weaponID, name, setup); err != nil {
		return nil, err
	}

	if err = g.initializeCharacter(playerDef, weaponID); err != nil {
		return nil, err
	}

	if err = g.populateFromScript(setup); err != nil {
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

	_, err = g.scripts.Policy("character.starting_gear", map[string]any{
		"job_id":    definition.JobID,
		"weapon_id": weaponID,
	})

	if err != nil {
		return err
	}

	return g.scripts.ApplyPending()
}

// initializeCharacter stores the source-derived Fighter state on the player.
func (g *Game) initializeCharacter(definition content.PlayerDef, weaponID string) error {
	_, err := g.scripts.Policy("character.start", map[string]any{
		"species_id": definition.SpeciesID,
		"job_id":     definition.JobID,
		"weapon_id":  weaponID,
	})

	if err != nil {
		return err
	}

	return g.scripts.ApplyPending()
}
