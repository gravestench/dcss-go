package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/save"
	"github.com/gravestench/akara"
)

func TestEnergySchedulerOrdersReadyMonstersByEnergy(t *testing.T) {
	world := akara.NewWorld()
	defer world.Close()

	stores := ecs.Register(world)
	g := newStepGame(t)
	scheduler := TurnScheduler{
		actors:    stores.Actors,
		positions: stores.Positions,
		energies:  stores.MonsterEnergy,
		policy:    g.scripts.Policy,
	}

	ids := make(map[string]akara.Entity)

	for _, animal := range []struct {
		id    string
		speed int
	}{
		{
			id:    "MONS_RAT",
			speed: 10,
		},

		{
			id:    "MONS_WORM",
			speed: 6,
		},

		{
			id:    "MONS_JACKAL",
			speed: 14,
		},
	} {
		entity, err := world.CreateEntity()

		if err != nil {
			t.Fatal(err)
		}

		ids[animal.id] = entity
		stores.Actors.Set(entity, ecs.Actor{
			KindID: animal.id,
			Speed:  animal.speed,
		})

		stores.Positions.Set(entity, ecs.Position{LevelID: 1})
		stores.MonsterEnergy.Set(entity, ecs.MonsterEnergy{
			Points: 70,
		})
	}

	if err := scheduler.Grant(1, 10); err != nil {
		t.Fatal(err)
	}

	jackal, _ := stores.MonsterEnergy.Get(ids["MONS_JACKAL"])
	worm, _ := stores.MonsterEnergy.Get(ids["MONS_WORM"])
	rat, _ := stores.MonsterEnergy.Get(ids["MONS_RAT"])

	if jackal.Points != 84 ||
		worm.Points != 76 ||
		rat.Points != 80 {
		t.Fatalf("energy after first turn: jackal %d, worm %d, rat %d",
			jackal.Points, worm.Points, rat.Points)
	}

	first, ready, err := scheduler.NextReady(1)

	if err != nil {
		t.Fatal(err)
	}

	if !ready || first != ids["MONS_JACKAL"] {
		t.Fatalf("first ready = %d/%v, want jackal", first, ready)
	}

	if err := scheduler.Spend(first, ecs.Intent{Kind: ecs.IntentWait}); err != nil {
		t.Fatal(err)
	}

	second, ready, err := scheduler.NextReady(1)

	if err != nil {
		t.Fatal(err)
	}

	if !ready || second != ids["MONS_RAT"] {
		t.Fatalf("second ready = %d/%v, want rat", second, ready)
	}

	if err := scheduler.Spend(second, ecs.Intent{Kind: ecs.IntentWait}); err != nil {
		t.Fatal(err)
	}

	next, ready, err := scheduler.NextReady(1)

	if err != nil {
		t.Fatal(err)
	}

	if ready {
		t.Fatalf("unexpected ready monster %d", next)
	}

	if err := scheduler.Grant(1, 10); err != nil {
		t.Fatal(err)
	}

	for _, want := range []akara.Entity{
		ids["MONS_JACKAL"],
		ids["MONS_WORM"],
		ids["MONS_RAT"],
	} {
		entity, ready, err := scheduler.NextReady(1)

		if err != nil {
			t.Fatal(err)
		}

		if !ready || entity != want {
			t.Fatalf("next ready = %d/%v, want %d", entity, ready, want)
		}

		if err := scheduler.Spend(entity, ecs.Intent{Kind: ecs.IntentWait}); err != nil {
			t.Fatal(err)
		}
	}
}

func TestMonsterEnergySurvivesSaveAndNextTurn(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	energy, _ := g.stores.MonsterEnergy.Get(rat)

	energy.Points = 75

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("monster energy changed across restore")
	}

	left, leftErr := g.Step(Command{Kind: CommandWait})
	right, rightErr := restored.Step(Command{Kind: CommandWait})

	if leftErr != nil ||
		rightErr != nil ||
		!reflect.DeepEqual(left, right) ||
		!reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatalf("energy continuation: %+v/%v versus %+v/%v",
			left, leftErr, right, rightErr)
	}
}

func TestRestoreRejectsMissingTimingRoleComponents(t *testing.T) {
	g := newStepGame(t)
	snapshot := g.Snapshot()

	for _, test := range []struct {
		name   string
		mutate func(*save.Snapshot)
	}{
		{
			name: "player clock",
			mutate: func(saved *save.Snapshot) {
				for index := range saved.Entities {
					if saved.Entities[index].Player != nil {
						saved.Entities[index].PlayerTurn = nil
					}
				}
			},
		},

		{
			name: "monster energy",
			mutate: func(saved *save.Snapshot) {
				for index := range saved.Entities {
					if saved.Entities[index].AI != nil {
						saved.Entities[index].MonsterEnergy = nil
					}
				}
			},
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			invalid := snapshot

			invalid.Entities = append([]save.EntityRecord(nil), snapshot.Entities...)
			test.mutate(&invalid)

			if restored, err := Restore(invalid); err == nil {
				restored.Close()
				t.Fatal("restored entity without its timing component")
			}
		})
	}
}

func TestRestoreAllowsReadyEnergyAfterPlayerDeath(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	playerHealth, _ := g.stores.Health.Get(g.player)
	ratEnergy, _ := g.stores.MonsterEnergy.Get(rat)

	// The player can die before the queued monsters spend their action energy.
	playerHealth.Current = 0
	ratEnergy.Points = 80

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("terminal monster energy changed across restore")
	}
}

func TestPoisonDeathPreservesReadyMonsterEnergyInSave(t *testing.T) {
	g := newPopulatedTestGame(t, 41)
	active := make([]akara.Entity, 0, 2)

	for _, entity := range g.stores.MonsterEnergy.Entities() {
		position, _ := g.stores.Positions.Get(entity)

		if position.LevelID != 1 {
			continue
		}

		energy, _ := g.stores.MonsterEnergy.Get(entity)

		energy.Points = 79
		active = append(active, entity)
	}

	if len(active) < 2 {
		t.Fatalf("population has %d active monsters, want at least two", len(active))
	}

	health, _ := g.stores.Health.Get(g.player)

	health.Current = 1

	if _, err := g.stores.Poison.Set(g.player, ecs.Poison{
		AmountScaled:    20000,
		SourceMonsterID: "MONS_ADDER",
	}); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	if !g.playerDead() {
		t.Fatalf("poison did not kill player: %+v", result)
	}

	for _, entity := range active {
		energy, _ := g.stores.MonsterEnergy.Get(entity)

		if energy.Points < 80 {
			t.Fatalf("monster %d lost ready energy after player death: %d",
				entity, energy.Points)
		}
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatalf("terminal snapshot did not restore: %v", err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("terminal snapshot changed during restore")
	}
}
