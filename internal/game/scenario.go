package game

import (
	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"fmt"
	"github.com/gravestench/akara"
)

func NewScenario(seed uint64, catalog content.Catalog, weaponID, name string) (_ *Game, err error) {
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
	first, err := NewLevel(1, []string{"#################", "#.......#.......#", "#.#.....#.......#", "#......>#.......#", "#...............#", "#.......#.......#", "#.......#.......#", "#.......#.......#", "#################"}, stores.Positions)
	if err != nil {
		return nil, err
	}
	second, err := NewLevel(2, []string{"#################", "#<......#.......#", "#.......#.......#", "#.......#.......#", "#...............#", "#.......#.......#", "#.......#.......#", "#.......#.......#", "#################"}, stores.Positions)
	if err != nil {
		return nil, err
	}
	g := &Game{world: world, stores: stores, levels: map[int]*Level{1: first, 2: second}, catalog: catalog, seed: seed,
		rng: NewRNGStreams(seed), scheduler: TurnScheduler{actors: stores.Actors}}

	g.player, err = world.CreateEntity()
	if err != nil {
		return nil, err
	}
	if _, err = stores.Actors.Set(g.player, ecs.Actor{KindID: "player", Speed: playerDef.Speed}); err != nil {
		return nil, err
	}
	if _, err = stores.Combat.Set(g.player, ecs.Combatant{}); err != nil {
		return nil, err
	}
	if _, err = stores.Players.Set(g.player, ecs.PlayerControlled{Name: name, SpeciesID: playerDef.SpeciesID, JobID: playerDef.JobID, StartingWeaponID: weaponID}); err != nil {
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
	if _, err = stores.Attributes.Set(g.player, ecs.Attributes{Strength: profile.Attributes.Strength, Intelligence: profile.Attributes.Intelligence, Dexterity: profile.Attributes.Dexterity}); err != nil {
		return nil, err
	}
	if _, err = stores.Skills.Set(g.player, ecs.Skills{Entries: append([]character.Skill(nil), profile.Skills...)}); err != nil {
		return nil, err
	}
	if _, err = stores.Progression.Set(g.player, ecs.Progression{}); err != nil {
		return nil, err
	}
	if _, err = stores.Durations.Set(g.player, ecs.Durations{}); err != nil {
		return nil, err
	}
	if _, err = stores.Health.Set(g.player, ecs.Health{Current: profile.MaxHP, Max: profile.MaxHP}); err != nil {
		return nil, err
	}
	if _, err = stores.Magic.Set(g.player, ecs.Magic{Current: profile.MaxMP, Max: profile.MaxMP}); err != nil {
		return nil, err
	}

	ratDef, err := catalog.Monster("MONS_RAT")
	if err != nil {
		return nil, err
	}
	if ratDef.HD != 1 || ratDef.AC != 1 || ratDef.EV != 10 ||
		ratDef.Attacks[0] != (content.MonsterAttack{TypeID: "AT_BITE", FlavourID: "AF_PLAIN", Damage: 3}) {
		return nil, fmt.Errorf("fixed rat scenario expects the pinned ordinary bite and defense")
	}
	rat, err := world.CreateEntity()
	if err != nil {
		return nil, err
	}
	if _, err = stores.Actors.Set(rat, ecs.Actor{KindID: ratDef.ID, Speed: ratDef.Speed}); err != nil {
		return nil, err
	}
	const scenarioRatHP = 4
	if _, err = stores.Health.Set(rat, ecs.Health{Current: scenarioRatHP, Max: scenarioRatHP}); err != nil {
		return nil, err
	}
	if _, err = stores.Combat.Set(rat, ecs.Combatant{}); err != nil {
		return nil, err
	}
	if _, err = stores.AI.Set(rat, ecs.MonsterAI{Behavior: "chase"}); err != nil {
		return nil, err
	}
	if err = first.PlaceActor(rat, 4, 1); err != nil {
		return nil, err
	}

	if _, err = catalog.Item("POT_CURING"); err != nil {
		return nil, err
	}
	potion, err := world.CreateEntity()
	if err != nil {
		return nil, err
	}
	if _, err = stores.Items.Set(potion, ecs.Item{KindID: "POT_CURING", Quantity: 1}); err != nil {
		return nil, err
	}
	if _, err = stores.Positions.Set(potion, ecs.Position{LevelID: 1, X: 4, Y: 2}); err != nil {
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
	if _, err := world.AddSystem(&stairSystem{positions: stores.Positions, intents: stores.Intents, levels: g.levels, turn: &g.turn}); err != nil {
		return err
	}
	if _, err := world.AddSystem(&pickupSystem{positions: stores.Positions, items: stores.Items, carried: stores.CarriedBy, intents: stores.Intents, turn: &g.turn}); err != nil {
		return err
	}
	if _, err := world.AddSystem(&quaffSystem{game: g, turn: &g.turn}); err != nil {
		return err
	}
	if _, err := world.AddSystem(&movementSystem{positions: stores.Positions, intents: stores.Intents, levels: g.levels, turn: &g.turn}); err != nil {
		return err
	}
	if _, err := world.AddSystem(&combatSystem{game: g, roller: g.rng, turn: &g.turn}); err != nil {
		return err
	}
	if _, err := world.AddSystem(&deathSystem{game: g, health: stores.Health, player: g.player, turn: &g.turn}); err != nil {
		return err
	}
	if _, err := world.AddSystem(&durationSystem{game: g, turn: &g.turn}); err != nil {
		return err
	}
	return nil
}
