package game

import (
	"fmt"

	"crawl/internal/character"
	"crawl/internal/ecs"
	"crawl/internal/modfs"
	"crawl/internal/script"
	"github.com/gravestench/akara"
)

type startChoice struct {
	SpeciesID string
	JobID     string
	Speed     int
}

func NewScenario(
	seed uint64,
	weaponID, name string,
) (_ *Game, err error) {
	return newScenario(seed, startChoice{
		SpeciesID: "SP_HUMAN",
		JobID:     "JOB_FIGHTER",
	}, weaponID, name, ordinaryMonsterScenarioID)
}

// NewShopScenario starts the fixed Dungeon fixture with a playable shop.
func NewShopScenario(
	seed uint64,
	weaponID, name string,
) (_ *Game, err error) {
	return newScenario(seed, startChoice{
		SpeciesID: "SP_HUMAN",
		JobID:     "JOB_FIGHTER",
	}, weaponID, name, shopFixtureScenarioID)
}

// NewPopulatedScenario keeps the current fixed map while selecting its
// supported monsters from the committed Dungeon population table.
func NewPopulatedScenario(
	seed uint64,
	weaponID, name string,
) (_ *Game, err error) {
	return newScenario(seed, startChoice{
		SpeciesID: "SP_HUMAN",
		JobID:     "JOB_FIGHTER",
	}, weaponID, name, populationScenarioID)
}

// NewDungeonGame starts the live client with the bundled Lua ruleset.
func NewDungeonGame(
	seed uint64,
	speciesID, jobID, weaponID, name string,
) (_ *Game, err error) {
	rules, err := modfs.Load()

	if err != nil {
		return nil, err
	}

	return NewDungeonGameWithRules(
		seed,
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
	speciesID, jobID, weaponID, name string,
	rules modfs.Ruleset,
) (_ *Game, err error) {
	choice := startChoice{
		SpeciesID: speciesID,
		JobID:     jobID,
	}

	return newScenarioWithRules(
		seed,
		choice,
		weaponID,
		name,
		generatedDungeonScenarioID,
		rules,
	)
}

func newScenario(
	seed uint64,
	playerDef startChoice,
	weaponID, name string,
	scenarioID string,
) (_ *Game, err error) {
	rules, err := modfs.Load()

	if err != nil {
		return nil, err
	}

	return newScenarioWithRules(
		seed,
		playerDef,
		weaponID,
		name,
		scenarioID,
		rules,
	)
}

func newScenarioWithRules(
	seed uint64,
	playerDef startChoice,
	weaponID, name string,
	scenarioID string,
	rules modfs.Ruleset,
) (_ *Game, err error) {
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

		rules: rules,
		seed:  seed,
		rng:   rng,

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

	setup, err := g.buildScriptScenario(
		scenarioID,
		stores.Positions,
		playerDef.SpeciesID,
		name,
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

	speedProfile, err := g.scripts.Policy("character.actor_speed", map[string]any{
		"species_id": playerDef.SpeciesID,
	})

	if err != nil {
		return nil, err
	}

	playerDef.Speed, err = decisionInteger(speedProfile, "speed")

	if err != nil {
		return nil, err
	}

	if err = g.createPlayerActor(playerDef, weaponID, name, setup); err != nil {
		return nil, err
	}

	if err = g.initializeCharacter(playerDef, weaponID); err != nil {
		return nil, err
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		return nil, fmt.Errorf("new player has no starting position")
	}

	startingLevel := g.levels[position.LevelID]

	if startingLevel == nil {
		return nil, fmt.Errorf("new player starts on missing level %d", position.LevelID)
	}

	if err = g.runWorldPolicy("world.zot_clock", map[string]any{
		"level_id":    position.LevelID,
		"branch_id":   startingLevel.BranchID,
		"elapsed_aut": int64(0),
	}); err != nil {
		return nil, err
	}

	if err = g.populateFromScript(setup); err != nil {
		return nil, err
	}

	if err = g.runWorldPolicy("character.start_region", map[string]any{
		"job_id": playerDef.JobID,
	}); err != nil {
		return nil, err
	}

	position, found = g.stores.Positions.Get(g.player)

	if !found {
		return nil, fmt.Errorf("new player lost its starting position")
	}

	if err = g.runWorldPolicy("world.fog_machines", map[string]any{
		"source_level_id":      position.LevelID,
		"destination_level_id": position.LevelID,
		"elapsed_aut":          int64(0),
		"enter":                true,
	}); err != nil {
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

// createPlayerActor establishes identity and position before Lua starts the character.
func (g *Game) createPlayerActor(
	definition startChoice,
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
	g.noteEntity(player)

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

	return nil
}

// initializeCharacter runs the complete Lua-owned starting transaction.
func (g *Game) initializeCharacter(definition startChoice, weaponID string) error {
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
