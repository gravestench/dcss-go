package game

import (
	"reflect"
	"slices"
	"testing"
	"time"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
)

func TestAdderPoisonBiteAddsPlayerOwnedStatus(t *testing.T) {
	g := newStepGame(t)
	adder, err := ordinaryAnimal(g.catalog, "MONS_ADDER")

	if err != nil {
		t.Fatal(err)
	}

	system := newCombatSystem(g)
	system.roller = &combatRoller{
		rolls: []combatRoll{
			{
				bound: 3,
				value: 0,
			},

			{
				bound: 5,
				value: 4,
			},
		},
	}

	if err := system.applyPoisonBite(adder); err != nil {
		t.Fatal(err)
	}

	poison, found := g.stores.Poison.Get(g.player)

	if !found ||
		poison.AmountScaled != 8000 ||
		poison.SourceMonsterID != adder.ID {
		t.Fatalf("adder poison = %+v, present %v", poison, found)
	}
}

func TestAdderZeroDamageBiteStillPoisonsPlayer(t *testing.T) {
	g := newStepGame(t)
	adder, err := newOrdinaryMonsterFactory(g).Spawn("MONS_ADDER", 1, 2, 1)

	if err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Intents.Set(adder, ecs.Intent{
		Kind: ecs.IntentMelee,
		DX:   1,
	}); err != nil {
		t.Fatal(err)
	}

	g.turn.Actor = adder
	rolls := []combatRoll{
		{
			bound: 22,
			value: 21,
		},

		{
			bound: 10,
			value: 0,
		},

		{
			bound: 11,
			value: 0,
		},

		{
			bound: 100,
			value: 10,
		},

		{
			bound: 16,
			value: 15,
		},

		{
			bound: 18,
			value: 0,
		},

		{
			bound: 19,
			value: 0,
		},

		{
			bound: 4,
			value: 0,
		},

		{
			bound: 7,
			value: 6,
		},

		{
			bound: 3,
			value: 0,
		},

		{
			bound: 5,
			value: 4,
		},
	}

	system := newCombatSystem(g)
	system.roller = &combatRoller{rolls: rolls}
	health, _ := g.stores.Health.Get(g.player)
	before := health.Current

	if err := system.Update(nil, time.Duration(10)); err != nil {
		t.Fatal(err)
	}

	poison, found := g.stores.Poison.Get(g.player)

	if health.Current != before ||
		!found ||
		poison.AmountScaled != 8000 ||
		len(g.turn.Events) != 2 {
		t.Fatalf(
			"zero-damage bite: HP %d -> %d, poison %+v, events %+v",
			before,
			health.Current,
			poison,
			g.turn.Events,
		)
	}
}

func TestPoisonTicksAfterPlayerRegeneration(t *testing.T) {
	g := newStepGame(t)
	health, _ := g.stores.Health.Get(g.player)
	regeneration, _ := g.stores.Regeneration.Get(g.player)

	health.Current = 1
	regeneration.HPProgress = 99

	if _, err := g.stores.Poison.Set(g.player, ecs.Poison{
		AmountScaled:    1000,
		SourceMonsterID: "MONS_ADDER",
	}); err != nil {
		t.Fatal(err)
	}

	_, err := g.runAction(
		g.player,
		ecs.Intent{Kind: ecs.IntentWait},
		10,
		"test wait",
	)

	if err != nil {
		t.Fatal(err)
	}

	if health.Current != 1 || g.stores.Poison.Has(g.player) {
		t.Fatalf("regen-before-poison left health %+v and active poison", *health)
	}
}

func TestCuringClearsPoisonAtFullHealth(t *testing.T) {
	g := newStepGame(t)
	itemID := carryCuring(t, g)
	health, _ := g.stores.Health.Get(g.player)
	health.Current = health.Max

	if _, err := g.stores.Poison.Set(g.player, ecs.Poison{
		AmountScaled:    8000,
		SourceMonsterID: "MONS_ADDER",
	}); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:   CommandQuaff,
		ItemID: itemID,
	})

	if err != nil ||
		result.Spent != 10 || g.stores.Poison.Has(g.player) {
		t.Fatalf("full-HP curing = %+v, %v", result, err)
	}
}

func TestAdderJoinsDungeonPopulationAndDeathRules(t *testing.T) {
	g := newStepGame(t)
	ids, err := scenarioAnimalIDs(generatedDungeonScenarioID)

	if err != nil ||
		!slices.Contains(ids, "MONS_ADDER") {
		t.Fatalf("generated Dungeon animal IDs = %v, %v", ids, err)
	}

	pool := g.catalog.DungeonMonsterPool(2, func(id string) bool {
		return !isOrdinaryAnimal(id)
	})

	foundAdder := false

	for roll := 0; roll < pool.TotalWeight(); roll++ {
		id, pickErr := pool.Pick(roll)

		if pickErr != nil {
			t.Fatal(pickErr)
		}

		if id == "MONS_ADDER" {
			foundAdder = true

			break
		}
	}

	if !foundAdder {
		t.Fatal("D:2 population cannot select the adder")
	}

	adderID, err := newOrdinaryMonsterFactory(g).Spawn("MONS_ADDER", 1, 2, 1)

	if err != nil {
		t.Fatal(err)
	}

	adder, err := g.catalog.Monster("MONS_ADDER")

	if err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(adderID)
	before := health.Max
	health.Current = 0
	g.turn.PlayerKill = adderID

	if err := newDeathSystem(g).Update(nil, 10); err != nil {
		t.Fatal(err)
	}

	wantXP, err := character.OrdinaryAnimalExperience(adder, before)

	if err != nil {
		t.Fatal(err)
	}

	progress, _ := g.stores.Progression.Get(g.player)
	training, _ := g.stores.SkillTraining.Get(g.player)

	if progress.TotalXP != wantXP || training.AvailableXP != 10*wantXP {
		t.Fatalf("adder death awarded %d XP and %d skill XP", progress.TotalXP, training.AvailableXP)
	}

	if err := g.placeCorpse(pendingCorpse{
		MonsterID: "MONS_ADDER",
		Position: ecs.Position{
			LevelID: 1,
			X:       2,
			Y:       1,
		},
		Appearance: 1,
	}); err != nil {
		t.Fatal(err)
	}
}

func TestPoisonWaitCanKillBeforeMonsterTurn(t *testing.T) {
	g := newStepGame(t)
	health, _ := g.stores.Health.Get(g.player)
	health.Current = 1

	if _, err := g.stores.Poison.Set(g.player, ecs.Poison{
		AmountScaled:    4000,
		SourceMonsterID: "MONS_ADDER",
	}); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{Kind: CommandWait})

	if err != nil ||
		!result.View.PlayerDead ||
		health.Current != 0 ||
		!containsEvent(result.Events, "You die.") {
		t.Fatalf("poison death = HP %d, dead %v, error %v", health.Current, result.View.PlayerDead, err)
	}
}

func TestMonsterActionDoesNotAdvancePlayerPoison(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	g.turn.Actor = rat

	if _, err := g.stores.Poison.Set(g.player, ecs.Poison{
		AmountScaled:    8000,
		SourceMonsterID: "MONS_ADDER",
	}); err != nil {
		t.Fatal(err)
	}

	if err := (&poisonSystem{
		player: g.player,
		health: g.stores.Health,
		poison: g.stores.Poison,
		turn:   &g.turn,
	}).Update(nil, 10); err != nil {
		t.Fatal(err)
	}

	status, _ := g.stores.Poison.Get(g.player)

	if status.AmountScaled != 8000 {
		t.Fatalf("monster action reduced poison to %d", status.AmountScaled)
	}
}

func TestPoisonContinuationMatchesRestoredRun(t *testing.T) {
	g := newStepGame(t)

	if _, err := g.stores.Poison.Set(g.player, ecs.Poison{
		AmountScaled:    8000,
		SourceMonsterID: "MONS_ADDER",
	}); err != nil {
		t.Fatal(err)
	}

	restored, err := Restore(g.Snapshot(), testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	for _, run := range []*Game{g, restored} {
		if _, err := run.runAction(
			run.player,
			ecs.Intent{Kind: ecs.IntentWait},
			10,
			"test wait",
		); err != nil {
			t.Fatal(err)
		}
	}

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("poison status or RNG diverged after restore")
	}
}
