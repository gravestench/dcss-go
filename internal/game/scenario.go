package game

import (
	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

func NewScenario(seed uint64, catalog content.Catalog, weaponID, name string) (_ *Game, err error) {
	return newScenario(seed, catalog, weaponID, name, false)
}

// NewPopulatedScenario keeps the current fixed map while selecting its
// supported monsters from the committed Dungeon population table.
func NewPopulatedScenario(seed uint64, catalog content.Catalog, weaponID, name string) (_ *Game, err error) {
	return newScenario(seed, catalog, weaponID, name, true)
}

func newScenario(
	seed uint64,
	catalog content.Catalog,
	weaponID, name string,
	usePopulation bool,
) (_ *Game, err error) {
	if err := catalog.Validate(); err != nil {
		return nil, err
	}
	if err := character.ValidateName(name); err != nil {
		return nil, err
	}
	playerDef := catalog.Player()
	if err := character.ValidateWeaponChoice(catalog, playerDef.SpeciesID, playerDef.JobID, weaponID); err != nil {
		return nil, err
	}
	world := akara.NewWorld()
	defer func() {
		if err != nil {
			world.Close()
		}
	}()
	stores := ecs.Register(world)
	firstRows := []string{
		"#################",
		"#.......#.......#",
		"#.#.....#.......#",
		"#......>#.......#",
		"#...............#",
		"#.......#.......#",
		"#.......#.......#",
		"#.......#.......#",
		"#################",
	}
	first, err := NewLevel(1, firstRows, stores.Positions)
	if err != nil {
		return nil, err
	}
	secondRows := []string{
		"#################",
		"#<......#.......#",
		"#.......#.......#",
		"#.......#.......#",
		"#...............#",
		"#.......#.......#",
		"#.......#.......#",
		"#.......#.......#",
		"#################",
	}
	second, err := NewLevel(2, secondRows, stores.Positions)
	if err != nil {
		return nil, err
	}
	if err := first.AddStairLink(StairLink{
		X:         7,
		Y:         3,
		ToLevelID: 2,
		ToX:       1,
		ToY:       1,
	}); err != nil {
		return nil, err
	}
	if err := second.AddStairLink(StairLink{
		X:         1,
		Y:         1,
		ToLevelID: 1,
		ToX:       7,
		ToY:       3,
	}); err != nil {
		return nil, err
	}
	levels := map[int]*Level{
		1: first,
		2: second,
	}
	if err := validateStairLinks(levels); err != nil {
		return nil, err
	}
	scenarioID := ordinaryAnimalScenarioID
	if usePopulation {
		scenarioID = populationScenarioID
	}
	g := &Game{
		world:      world,
		stores:     stores,
		levels:     levels,
		catalog:    catalog,
		seed:       seed,
		rng:        NewRNGStreams(seed),
		scheduler:  TurnScheduler{actors: stores.Actors},
		scenarioID: scenarioID,
	}

	g.player, err = world.CreateEntity()
	if err != nil {
		return nil, err
	}
	if _, err = stores.Actors.Set(g.player, ecs.Actor{
		KindID: "player",
		Speed:  playerDef.Speed,
	}); err != nil {
		return nil, err
	}
	if _, err = stores.Combat.Set(g.player, ecs.Combatant{}); err != nil {
		return nil, err
	}
	if _, err = stores.Players.Set(g.player, ecs.PlayerControlled{
		Name:             name,
		SpeciesID:        playerDef.SpeciesID,
		JobID:            playerDef.JobID,
		StartingWeaponID: weaponID,
	}); err != nil {
		return nil, err
	}
	if err = first.PlaceActor(g.player, 1, 1); err != nil {
		return nil, err
	}
	if err = g.createStartingGear(playerDef.JobID, weaponID); err != nil {
		return nil, err
	}
	profile, err := character.BuildStartProfile(catalog, playerDef.SpeciesID, playerDef.JobID, weaponID)
	if err != nil {
		return nil, err
	}
	if _, err = stores.Attributes.Set(g.player, ecs.Attributes{
		Strength:     profile.Attributes.Strength,
		Intelligence: profile.Attributes.Intelligence,
		Dexterity:    profile.Attributes.Dexterity,
	}); err != nil {
		return nil, err
	}
	startSkills := ecs.Skills{Entries: append([]character.Skill(nil), profile.Skills...)}
	if _, err = stores.Skills.Set(g.player, startSkills); err != nil {
		return nil, err
	}
	if _, err = stores.Progression.Set(g.player, ecs.Progression{Level: 1}); err != nil {
		return nil, err
	}
	if _, err = stores.Durations.Set(g.player, ecs.Durations{}); err != nil {
		return nil, err
	}
	if _, err = stores.Regeneration.Set(g.player, ecs.Regeneration{}); err != nil {
		return nil, err
	}
	if _, err = stores.Health.Set(g.player, ecs.Health{
		Current: profile.MaxHP,
		Max:     profile.MaxHP,
	}); err != nil {
		return nil, err
	}
	if _, err = stores.Magic.Set(g.player, ecs.Magic{
		Current: profile.MaxMP,
		Max:     profile.MaxMP,
	}); err != nil {
		return nil, err
	}

	if usePopulation {
		err = g.populateDungeon()
	} else {
		err = g.spawnFixtureAnimals()
	}
	if err != nil {
		return nil, err
	}

	if _, err = catalog.Item("POT_CURING"); err != nil {
		return nil, err
	}
	potion, err := world.CreateEntity()
	if err != nil {
		return nil, err
	}
	if _, err = stores.Items.Set(potion, ecs.Item{
		KindID:   "POT_CURING",
		Quantity: 1,
	}); err != nil {
		return nil, err
	}
	if _, err = stores.Positions.Set(potion, ecs.Position{
		LevelID: 1,
		X:       4,
		Y:       2,
	}); err != nil {
		return nil, err
	}
	if _, err = catalog.Item("POT_HEAL_WOUNDS"); err != nil {
		return nil, err
	}
	healPotion, err := world.CreateEntity()
	if err != nil {
		return nil, err
	}
	if _, err = stores.Items.Set(healPotion, ecs.Item{
		KindID:   "POT_HEAL_WOUNDS",
		Quantity: 1,
	}); err != nil {
		return nil, err
	}
	if _, err = stores.Positions.Set(healPotion, ecs.Position{
		LevelID: 2,
		X:       2,
		Y:       1,
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

func registerSystems(g *Game) error {
	world, stores := g.world, g.stores
	g.corpseAging = corpseAgingSystem{
		world:     world,
		items:     stores.Items,
		corpses:   stores.Corpses,
		positions: stores.Positions,
		rng:       g.rng,
	}
	if _, err := world.AddSystem(newMonsterDecisionSystem(g)); err != nil {
		return err
	}
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
		turn:      &g.turn,
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
		rng:       g.rng,
		turn:      &g.turn,
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
	return nil
}
