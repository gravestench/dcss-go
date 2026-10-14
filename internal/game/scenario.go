package game

import (
	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

func NewScenario(
	seed uint64,
	catalog content.Catalog,
	weaponID, name string,
) (_ *Game, err error) {
	return newScenario(seed, catalog, weaponID, name, ordinaryAnimalScenarioID)
}

// NewPopulatedScenario keeps the current fixed map while selecting its
// supported monsters from the committed Dungeon population table.
func NewPopulatedScenario(
	seed uint64,
	catalog content.Catalog,
	weaponID, name string,
) (_ *Game, err error) {
	return newScenario(seed, catalog, weaponID, name, populationScenarioID)
}

// NewDungeonGame starts the live client on generated D:1-2 basic layouts.
func NewDungeonGame(
	seed uint64,
	catalog content.Catalog,
	weaponID, name string,
) (_ *Game, err error) {
	return newScenario(seed, catalog, weaponID, name, generatedDungeonScenarioID)
}

func newScenario(
	seed uint64,
	catalog content.Catalog,
	weaponID, name string,
	scenarioID string,
) (_ *Game, err error) {
	if err := catalog.Validate(); err != nil {
		return nil, err
	}

	if err := character.ValidateName(name); err != nil {
		return nil, err
	}

	playerDef := catalog.Player()

	if err := character.ValidateWeaponChoice(
		catalog,
		playerDef.SpeciesID,
		playerDef.JobID,
		weaponID,
	); err != nil {
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
		seed:    seed,
		rng:     rng,

		scheduler: TurnScheduler{
			actors:    stores.Actors,
			positions: stores.Positions,
		},

		scenarioID: scenarioID,
	}

	if err = g.createPlayerActor(playerDef, weaponID, name, setup); err != nil {
		return nil, err
	}

	if err = g.initializeCharacter(playerDef, weaponID); err != nil {
		return nil, err
	}

	if scenarioID != ordinaryAnimalScenarioID {
		err = g.populateDungeon(setup.populationEntries)
	} else {
		err = g.spawnFixtureAnimals()
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

	return g.spawnScenarioPotion("POT_HEAL_WOUNDS", 2, setup.heal)
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

// Registration order is the action resolution order in Akara. Keep these
// groups in turn order when adding a new system.
func registerSystems(g *Game) error {
	world, stores := g.world, g.stores

	g.corpseAging = corpseAgingSystem{
		world:     world,
		items:     stores.Items,
		corpses:   stores.Corpses,
		positions: stores.Positions,
		catalog:   g.catalog,
		rng:       g.rng,
	}

	g.monsterCatchup = monsterCatchupSystem{
		actors:    stores.Actors,
		health:    stores.Health,
		positions: stores.Positions,
		ai:        stores.AI,
		catalog:   g.catalog,
		rng:       g.rng,
	}

	if err := registerMonsterSystems(g); err != nil {
		return err
	}

	if err := registerTravelAndItemSystems(g); err != nil {
		return err
	}

	if err := registerInteractionAndCombatSystems(g); err != nil {
		return err
	}

	return registerEndTurnSystems(g)
}

func registerMonsterSystems(g *Game) error {
	world, stores := g.world, g.stores

	if _, err := world.AddSystem(&monsterRegenerationSystem{
		actors:  stores.Actors,
		health:  stores.Health,
		ai:      stores.AI,
		catalog: g.catalog,
		rng:     g.rng,
		turn:    &g.turn,
	}); err != nil {
		return err
	}

	if _, err := world.AddSystem(newMonsterDecisionSystem(g)); err != nil {
		return err
	}

	return nil
}

func registerTravelAndItemSystems(g *Game) error {
	world, stores := g.world, g.stores

	if _, err := world.AddSystem(&stairSystem{
		positions: stores.Positions,
		intents:   stores.Intents,
		levels:    g.levels,
		turn:      &g.turn,
	}); err != nil {
		return err
	}

	if _, err := world.AddSystem(&pickupSystem{
		positions: stores.Positions,
		items:     stores.Items,
		corpses:   stores.Corpses,
		carried:   stores.CarriedBy,
		intents:   stores.Intents,
		catalog:   g.catalog,
		turn:      &g.turn,
	}); err != nil {
		return err
	}

	if _, err := world.AddSystem(&dropSystem{
		items:   stores.Items,
		carried: stores.CarriedBy,
		intents: stores.Intents,
		catalog: g.catalog,
		turn:    &g.turn,
	}); err != nil {
		return err
	}

	if _, err := world.AddSystem(&wieldSystem{
		items:   stores.Items,
		carried: stores.CarriedBy,
		intents: stores.Intents,
		catalog: g.catalog,
		turn:    &g.turn,
	}); err != nil {
		return err
	}

	if _, err := world.AddSystem(&quaffSystem{
		player:    g.player,
		intents:   stores.Intents,
		items:     stores.Items,
		carried:   stores.CarriedBy,
		health:    stores.Health,
		durations: stores.Durations,
		poison:    stores.Poison,
		rng:       g.rng,
		turn:      &g.turn,
	}); err != nil {
		return err
	}

	return nil
}

func registerInteractionAndCombatSystems(g *Game) error {
	world, stores := g.world, g.stores

	if _, err := world.AddSystem(&doorSystem{
		game:    g,
		intents: stores.Intents,
		turn:    &g.turn,
	}); err != nil {
		return err
	}

	if _, err := world.AddSystem(&movementSystem{
		positions: stores.Positions,
		intents:   stores.Intents,
		levels:    g.levels,
		turn:      &g.turn,
	}); err != nil {
		return err
	}

	if _, err := world.AddSystem(newCombatSystem(g)); err != nil {
		return err
	}

	if _, err := world.AddSystem(newDeathSystem(g)); err != nil {
		return err
	}

	return nil
}

func registerEndTurnSystems(g *Game) error {
	world, stores := g.world, g.stores

	if _, err := world.AddSystem(newSkillTrainingSystem(g)); err != nil {
		return err
	}

	advancement, err := newAdvancementSystem(g)

	if err != nil {
		return err
	}

	g.advancement = advancement

	if _, err := world.AddSystem(advancement); err != nil {
		return err
	}

	if _, err := world.AddSystem(&durationSystem{
		player:    g.player,
		durations: stores.Durations,
		turn:      &g.turn,
	}); err != nil {
		return err
	}

	if _, err := world.AddSystem(&regenerationSystem{
		player:       g.player,
		health:       stores.Health,
		magic:        stores.Magic,
		regeneration: stores.Regeneration,
		rng:          g.rng,
		turn:         &g.turn,
	}); err != nil {
		return err
	}

	if _, err := world.AddSystem(&poisonSystem{
		player: g.player,
		health: stores.Health,
		poison: stores.Poison,
		turn:   &g.turn,
	}); err != nil {
		return err
	}

	return nil
}
